extends Node2D
## Reusable painting-reveal engine.
## Player brushes away an opaque cover layer to reveal a hidden image.
## Uses an Image-based mask: white = covered, black = revealed.
## Auto-completes when reveal_threshold is reached.

const SCREEN_W: float = 1080.0
const SCREEN_H: float = 1920.0

signal puzzle_completed

@export_file("*.json") var puzzle_data_path: String

var _puzzle_data: Dictionary = {}

# Canvas area (where the image + cover live)
var _canvas_area: Rect2 = Rect2(40, 280, 1000, 1200)

# Mask (half resolution for performance)
var _mask_image: Image
var _mask_texture: ImageTexture
var _mask_w: int = 0
var _mask_h: int = 0
var _mask_scale: float = 0.5  # Mask resolution relative to canvas

# Brush
var _brush_radius: int = 20  # In mask pixels
var _brush_radius_sq: int = 400

# Reveal tracking
var _pixels_cleared: int = 0
var _total_pixels: int = 0
var _reveal_threshold: float = 0.65
var _is_complete: bool = false

# Touch state
var _is_painting: bool = false
var _last_paint_pos: Vector2 = Vector2(-1, -1)

# Nodes
var _image_rect: TextureRect
var _cover_rect: ColorRect
var _shader_mat: ShaderMaterial
var _title_label: Label
var _progress_label: Label
var _success_label: Label


# ── Public API ──

func set_canvas_area(rect: Rect2) -> void:
	_canvas_area = rect


func load_puzzle(path: String = "") -> void:
	if path != "":
		puzzle_data_path = path
	assert(puzzle_data_path != "", "painting_engine: No puzzle_data_path set.")

	var file := FileAccess.open(puzzle_data_path, FileAccess.READ)
	assert(file != null, "painting_engine: Could not open: " + puzzle_data_path)

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	assert(err == OK, "painting_engine: JSON parse error: " + json.get_error_message())
	_puzzle_data = json.data

	_reveal_threshold = _puzzle_data.get("reveal_threshold", 0.65)
	var brush_screen: int = int(_puzzle_data.get("brush_radius", 38))
	_brush_radius = int(brush_screen * _mask_scale)
	_brush_radius_sq = _brush_radius * _brush_radius

	_init_mask()
	_build_title()
	_build_image()
	_build_cover()
	_build_progress_label()
	_build_success_label()
	_build_restart_button()


# ── Mask ──

func _init_mask() -> void:
	_mask_w = int(_canvas_area.size.x * _mask_scale)
	_mask_h = int(_canvas_area.size.y * _mask_scale)
	_total_pixels = _mask_w * _mask_h

	_mask_image = Image.create(_mask_w, _mask_h, false, Image.FORMAT_L8)
	_mask_image.fill(Color.WHITE)

	_mask_texture = ImageTexture.create_from_image(_mask_image)


func _stamp_circle(center: Vector2) -> void:
	# center is in mask coordinates
	var cx := int(center.x)
	var cy := int(center.y)
	var r := _brush_radius

	for y in range(maxi(0, cy - r), mini(_mask_h, cy + r + 1)):
		for x in range(maxi(0, cx - r), mini(_mask_w, cx + r + 1)):
			var dx := x - cx
			var dy := y - cy
			if dx * dx + dy * dy <= _brush_radius_sq:
				if _mask_image.get_pixel(x, y).r > 0.5:
					_mask_image.set_pixel(x, y, Color.BLACK)
					_pixels_cleared += 1


func _paint_at_screen_pos(screen_pos: Vector2) -> void:
	if _is_complete:
		return

	# Convert screen position to mask coordinates
	var local := screen_pos - _canvas_area.position
	var mask_pos := Vector2(
		local.x * _mask_scale,
		local.y * _mask_scale
	)

	# Bounds check
	if mask_pos.x < 0 or mask_pos.x >= _mask_w or mask_pos.y < 0 or mask_pos.y >= _mask_h:
		return

	# Interpolate between last position and current to avoid gaps
	if _last_paint_pos.x >= 0:
		var dist := mask_pos.distance_to(_last_paint_pos)
		var step := maxf(float(_brush_radius) * 0.4, 2.0)
		if dist > step:
			var steps := int(dist / step)
			for i in range(1, steps):
				var t := float(i) / float(steps)
				var interp := _last_paint_pos.lerp(mask_pos, t)
				_stamp_circle(interp)

	_stamp_circle(mask_pos)
	_last_paint_pos = mask_pos

	# Update the texture
	_mask_texture.update(_mask_image)
	_update_progress()

	# Check threshold
	var reveal_pct := float(_pixels_cleared) / float(_total_pixels)
	if reveal_pct >= _reveal_threshold:
		_auto_complete()


func _auto_complete() -> void:
	_is_complete = true
	_is_painting = false

	# Fade away remaining cover
	var tween := create_tween()
	tween.tween_property(_cover_rect, "modulate:a", 0.0, 0.6) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_callback(_play_success)


# ── Title ──

func _build_title() -> void:
	_title_label = Label.new()
	_title_label.text = _puzzle_data.get("title", "Uncover")
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.size = Vector2(SCREEN_W, 100)
	_title_label.position = Vector2(0, 80)
	_title_label.add_theme_font_size_override("font_size", 64)
	_title_label.add_theme_color_override("font_color", Color(0.2, 0.18, 0.15))
	add_child(_title_label)

	var subtitle_text: String = _puzzle_data.get("subtitle", "")
	if subtitle_text != "":
		var subtitle := Label.new()
		subtitle.text = subtitle_text
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle.size = Vector2(SCREEN_W, 60)
		subtitle.position = Vector2(0, 190)
		subtitle.add_theme_font_size_override("font_size", 30)
		subtitle.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4))
		add_child(subtitle)


# ── Image (hidden layer) ──

func _build_image() -> void:
	_image_rect = TextureRect.new()
	_image_rect.position = _canvas_area.position
	_image_rect.size = _canvas_area.size
	_image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	var image_path: String = _puzzle_data.get("image", "res://icon.svg")
	if ResourceLoader.exists(image_path):
		_image_rect.texture = load(image_path)

	add_child(_image_rect)


# ── Cover (top layer with mask shader) ──

func _build_cover() -> void:
	var c: Array = _puzzle_data.get("cover_color", [0.35, 0.32, 0.28])

	_cover_rect = ColorRect.new()
	_cover_rect.position = _canvas_area.position
	_cover_rect.size = _canvas_area.size
	_cover_rect.color = Color(c[0], c[1], c[2])

	var shader := load("res://prototypes/06_painting_reveal/cover_shader.gdshader") as Shader
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = shader
	_shader_mat.set_shader_parameter("mask_texture", _mask_texture)
	_cover_rect.material = _shader_mat

	add_child(_cover_rect)


# ── Input ──

func _input(event: InputEvent) -> void:
	if _is_complete:
		return

	# Touch
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_in_canvas(event.position):
				_is_painting = true
				_last_paint_pos = Vector2(-1, -1)
				_paint_at_screen_pos(event.position)
				get_viewport().set_input_as_handled()
		else:
			_is_painting = false
			_last_paint_pos = Vector2(-1, -1)

	elif event is InputEventScreenDrag:
		if _is_painting:
			_paint_at_screen_pos(event.position)
			get_viewport().set_input_as_handled()

	# Mouse fallback
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _is_in_canvas(event.position):
					_is_painting = true
					_last_paint_pos = Vector2(-1, -1)
					_paint_at_screen_pos(event.position)
					get_viewport().set_input_as_handled()
			else:
				_is_painting = false
				_last_paint_pos = Vector2(-1, -1)

	elif event is InputEventMouseMotion:
		if _is_painting:
			_paint_at_screen_pos(event.position)
			get_viewport().set_input_as_handled()


func _is_in_canvas(point: Vector2) -> bool:
	return _canvas_area.has_point(point)


# ── Progress ──

func _build_progress_label() -> void:
	_progress_label = Label.new()
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.size = Vector2(SCREEN_W, 60)
	_progress_label.position = Vector2(0, SCREEN_H - 160)
	_progress_label.add_theme_font_size_override("font_size", 36)
	_progress_label.add_theme_color_override("font_color", Color(0.4, 0.35, 0.3))
	add_child(_progress_label)
	_update_progress()


func _update_progress() -> void:
	var pct := float(_pixels_cleared) / float(_total_pixels) * 100.0
	_progress_label.text = "%d%% revealed" % int(pct)


# ── Success ──

func _build_success_label() -> void:
	var success_text: String = _puzzle_data.get("success_text", "Revealed!")
	_success_label = Label.new()
	_success_label.text = success_text
	_success_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_success_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_success_label.size = Vector2(800, 120)
	_success_label.position = Vector2(SCREEN_W / 2 - 400, SCREEN_H / 2 - 60)
	_success_label.add_theme_font_size_override("font_size", 80)
	_success_label.add_theme_color_override("font_color", Color(0.2, 0.65, 0.3))
	_success_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.3))
	_success_label.add_theme_constant_override("shadow_offset_x", 3)
	_success_label.add_theme_constant_override("shadow_offset_y", 3)
	_success_label.modulate.a = 0.0
	_success_label.z_index = 200
	add_child(_success_label)


func _play_success() -> void:
	await get_tree().create_timer(0.2).timeout

	var tween := create_tween()
	tween.tween_property(_success_label, "modulate:a", 1.0, 0.4) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(_success_label, "scale", Vector2(1.05, 1.05), 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_success_label, "scale", Vector2(1.0, 1.0), 0.15)

	puzzle_completed.emit()


# ── Restart ──

func _build_restart_button() -> void:
	var button := Button.new()
	button.text = "Restart"
	button.size = Vector2(180, 70)
	button.position = Vector2(SCREEN_W - 180 - 40, SCREEN_H - 70 - 40)
	button.add_theme_font_size_override("font_size", 28)
	button.z_index = 200
	button.pressed.connect(_on_restart)
	add_child(button)


func _on_restart() -> void:
	get_tree().reload_current_scene()
