extends Node2D
## A single polaroid photo with development mechanic.
## Swipe down to develop — white overlay fades in stages.
## Supports optional texture; falls back to colored placeholder.

signal developed(card: Node2D)
signal swipe_registered(card: Node2D)

@export var card_id: String = ""
@export var face_color: Color = Color(0.5, 0.5, 0.5)
@export var face_label: String = ""
@export var photo_size: Vector2 = Vector2(560, 560)

var face_texture: Texture2D = null
var swipes_to_develop: int = 4
var pin_position: Vector2 = Vector2.ZERO
var pin_rotation_deg: float = 0.0

var _swipe_count: int = 0
var _is_developed: bool = false
var _is_active: bool = false          # Only the active card accepts input
var _is_animating: bool = false

# Swipe tracking
var _touch_start: Vector2 = Vector2.ZERO
var _is_touching: bool = false
const SWIPE_MIN_DISTANCE: float = 120.0  # Minimum vertical drag to count
const SWIPE_MAX_HORIZONTAL: float = 200.0  # Max horizontal drift allowed

# Polaroid frame dimensions
const FRAME_PADDING: float = 24.0
const FRAME_BOTTOM: float = 80.0      # Thicker bottom like a real polaroid

var _overlay: ColorRect
var _frame: Panel


func _ready() -> void:
	_build_frame()
	_build_photo()
	_build_overlay()


func set_active(active: bool) -> void:
	_is_active = active


# ── Visuals ──

func _build_frame() -> void:
	var frame_size := Vector2(
		photo_size.x + FRAME_PADDING * 2,
		photo_size.y + FRAME_PADDING + FRAME_BOTTOM
	)

	_frame = Panel.new()
	_frame.size = frame_size
	_frame.position = -Vector2(frame_size.x / 2, frame_size.y / 2)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.94, 0.90)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 8
	style.shadow_offset = Vector2(3, 5)
	_frame.add_theme_stylebox_override("panel", style)
	add_child(_frame)


func _build_photo() -> void:
	if face_texture != null:
		var sprite := TextureRect.new()
		sprite.texture = face_texture
		sprite.size = photo_size
		sprite.position = Vector2(FRAME_PADDING, FRAME_PADDING)
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_frame.add_child(sprite)
	else:
		# Colored placeholder
		var photo := ColorRect.new()
		photo.size = photo_size
		photo.position = Vector2(FRAME_PADDING, FRAME_PADDING)
		photo.color = face_color
		_frame.add_child(photo)

		# Label on the photo
		var label := Label.new()
		label.text = face_label
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size = photo_size
		label.position = Vector2(FRAME_PADDING, FRAME_PADDING)
		label.add_theme_font_size_override("font_size", 40)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		_frame.add_child(label)


func _build_overlay() -> void:
	# White overlay that fades as the photo develops
	_overlay = ColorRect.new()
	_overlay.size = photo_size
	_overlay.position = Vector2(FRAME_PADDING, FRAME_PADDING)
	_overlay.color = Color(0.95, 0.93, 0.88, 1.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(_overlay)


# ── Input ──

func _input(event: InputEvent) -> void:
	if not _is_active or _is_developed or _is_animating:
		return

	# Touch
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_point_inside(event.position):
				_touch_start = event.position
				_is_touching = true
				get_viewport().set_input_as_handled()
		else:
			if _is_touching:
				_check_swipe(event.position)
				_is_touching = false
				get_viewport().set_input_as_handled()

	# Mouse fallback
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _is_point_inside(event.position):
					_touch_start = event.position
					_is_touching = true
					get_viewport().set_input_as_handled()
			else:
				if _is_touching:
					_check_swipe(event.position)
					_is_touching = false
					get_viewport().set_input_as_handled()


func _is_point_inside(point: Vector2) -> bool:
	var frame_size := Vector2(
		photo_size.x + FRAME_PADDING * 2,
		photo_size.y + FRAME_PADDING + FRAME_BOTTOM
	)
	var half := frame_size / 2
	var rect := Rect2(global_position - half, frame_size)
	return rect.has_point(point)


func register_external_swipe() -> void:
	## Called by the engine when a device shake is detected.
	if not _is_active or _is_developed or _is_animating:
		return
	_register_swipe()


func _check_swipe(end_pos: Vector2) -> void:
	var delta := end_pos - _touch_start
	# Must swipe downward with enough distance, not too much horizontal drift
	if delta.y > SWIPE_MIN_DISTANCE and absf(delta.x) < SWIPE_MAX_HORIZONTAL:
		_register_swipe()


func _register_swipe() -> void:
	_swipe_count += 1
	swipe_registered.emit(self)

	# Animate overlay fade
	var progress := float(_swipe_count) / float(swipes_to_develop)
	var target_alpha := clampf(1.0 - progress, 0.0, 1.0)

	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", target_alpha, 0.2) \
		.set_ease(Tween.EASE_OUT)

	# Subtle shake feedback
	_play_shake_feedback()

	if _swipe_count >= swipes_to_develop:
		_is_developed = true
		tween.tween_callback(func(): developed.emit(self))


func _play_shake_feedback() -> void:
	# Quick horizontal wiggle to feel like a shake
	var tween := create_tween()
	var orig_x := position.x
	tween.tween_property(self, "position:x", orig_x + 12, 0.03)
	tween.tween_property(self, "position:x", orig_x - 10, 0.03)
	tween.tween_property(self, "position:x", orig_x + 6, 0.03)
	tween.tween_property(self, "position:x", orig_x, 0.03)


# ── Pin Animation ──

func animate_to_pin(target_pos: Vector2, target_rot: float, target_scale: Vector2) -> void:
	_is_animating = true

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", target_pos, 0.5) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", target_scale, 0.5) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "rotation_degrees", target_rot, 0.5) \
		.set_ease(Tween.EASE_IN_OUT)

	await tween.finished
	_is_animating = false
