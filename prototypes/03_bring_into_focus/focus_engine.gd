extends Node2D
## Reusable focus-puzzle engine.
## Reads a JSON config with multiple levels, each having 1–3 shader effects
## controlled by sliders. Completes when all sliders are within tolerance.

const SCREEN_W: float = 1080.0
const SCREEN_H: float = 1920.0

signal level_completed(level_index: int)
signal puzzle_completed

@export_file("*.json") var puzzle_data_path: String

var _puzzle_data: Dictionary = {}
var _current_level: int = 0
var _levels: Array = []

# Shader effect ↔ slider wiring
var _image_rect: TextureRect
var _shader_mat: ShaderMaterial
var _sliders: Dictionary = {}          # effect_id → HSlider
var _targets: Dictionary = {}          # effect_id → { target, tolerance }
var _all_correct_timer: float = 0.0    # Must stay correct for this duration
const HOLD_DURATION: float = 0.4       # Seconds all sliders must be in tolerance

var _title_label: Label
var _level_label: Label
var _success_label: Label
var _slider_container: VBoxContainer

var _image_area: Rect2 = Rect2(40, 250, 1000, 1000)
var _is_level_done: bool = false


# ── Public API ──

func set_image_area(rect: Rect2) -> void:
	_image_area = rect


func load_puzzle(path: String = "") -> void:
	if path != "":
		puzzle_data_path = path
	assert(puzzle_data_path != "", "focus_engine: No puzzle_data_path set.")

	var file := FileAccess.open(puzzle_data_path, FileAccess.READ)
	assert(file != null, "focus_engine: Could not open: " + puzzle_data_path)

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	assert(err == OK, "focus_engine: JSON parse error: " + json.get_error_message())
	_puzzle_data = json.data
	_levels = _puzzle_data.levels

	_build_title()
	_build_image()
	_build_level_label()
	_build_slider_container()
	_build_success_label()
	_build_restart_button()
	_load_level(0)


# ── Title ──

func _build_title() -> void:
	_title_label = Label.new()
	_title_label.text = _puzzle_data.get("title", "Focus")
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.size = Vector2(SCREEN_W, 100)
	_title_label.position = Vector2(0, 80)
	_title_label.add_theme_font_size_override("font_size", 64)
	_title_label.add_theme_color_override("font_color", Color(0.2, 0.18, 0.15))
	add_child(_title_label)


func _build_level_label() -> void:
	_level_label = Label.new()
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.size = Vector2(SCREEN_W, 50)
	_level_label.position = Vector2(0, 180)
	_level_label.add_theme_font_size_override("font_size", 32)
	_level_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4))
	add_child(_level_label)


# ── Image ──

func _build_image() -> void:
	_image_rect = TextureRect.new()
	_image_rect.position = _image_area.position
	_image_rect.size = _image_area.size
	_image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_image_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL

	# Load texture
	var image_path: String = _puzzle_data.get("image", "res://icon.svg")
	if ResourceLoader.exists(image_path):
		_image_rect.texture = load(image_path)

	# Apply shader
	var shader := load("res://prototypes/03_bring_into_focus/focus_shader.gdshader") as Shader
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = shader
	_image_rect.material = _shader_mat

	add_child(_image_rect)


# ── Sliders ──

func _build_slider_container() -> void:
	_slider_container = VBoxContainer.new()
	_slider_container.position = Vector2(80, _image_area.end.y + 60)
	_slider_container.size = Vector2(SCREEN_W - 160, 500)
	_slider_container.add_theme_constant_override("separation", 20)
	add_child(_slider_container)


func _clear_sliders() -> void:
	for child in _slider_container.get_children():
		child.queue_free()
	_sliders.clear()
	_targets.clear()


func _create_slider(effect: Dictionary) -> void:
	var effect_id: String = effect.id

	# Label
	var label := Label.new()
	label.text = effect.get("label", effect_id.capitalize())
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color(0.3, 0.27, 0.22))
	_slider_container.add_child(label)

	# Slider
	var slider := HSlider.new()
	slider.min_value = effect.get("min", 0.0)
	slider.max_value = effect.get("max", 1.0)
	slider.step = 0.005
	slider.value = effect.get("start", 0.5)
	slider.custom_minimum_size = Vector2(0, 60)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider_container.add_child(slider)

	# Wire slider to shader uniform
	var uniform_name: String = effect_id + "_amount"
	_shader_mat.set_shader_parameter(uniform_name, slider.value)
	slider.value_changed.connect(func(val: float):
		_shader_mat.set_shader_parameter(uniform_name, val)
		_all_correct_timer = 0.0  # Reset hold timer on any change
	)

	_sliders[effect_id] = slider
	_targets[effect_id] = {
		"target": effect.get("target", 0.0),
		"tolerance": effect.get("tolerance", 0.05)
	}


# ── Level Management ──

func _load_level(index: int) -> void:
	_current_level = index
	_is_level_done = false
	_all_correct_timer = 0.0

	var level: Dictionary = _levels[index]
	_level_label.text = "Level %d — %s" % [index + 1, level.get("label", "")]

	_clear_sliders()

	# Reset all shader params to defaults (no effect)
	_shader_mat.set_shader_parameter("blur_amount", 0.0)
	_shader_mat.set_shader_parameter("offset_amount", 0.0)
	_shader_mat.set_shader_parameter("distortion_amount", 0.0)

	for effect in level.effects:
		_create_slider(effect)
		# Set shader to start value
		var uniform_name: String = effect.id + "_amount"
		_shader_mat.set_shader_parameter(uniform_name, effect.get("start", 0.5))


func _advance_level() -> void:
	_is_level_done = true
	level_completed.emit(_current_level)

	if _current_level + 1 < _levels.size():
		# Brief pause, then next level
		await get_tree().create_timer(0.8).timeout
		_load_level(_current_level + 1)
	else:
		_play_success()


# ── Completion Check ──

func _process(delta: float) -> void:
	if _is_level_done or _sliders.is_empty():
		return

	var all_ok := true
	for effect_id in _sliders:
		var slider: HSlider = _sliders[effect_id]
		var info: Dictionary = _targets[effect_id]
		if absf(slider.value - info.target) > info.tolerance:
			all_ok = false
			break

	if all_ok:
		_all_correct_timer += delta
		if _all_correct_timer >= HOLD_DURATION:
			_advance_level()
	else:
		_all_correct_timer = 0.0


# ── Success ──

func _build_success_label() -> void:
	_success_label = Label.new()
	_success_label.text = "Crystal Clear!"
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
