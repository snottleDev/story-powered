extends Node2D
## A single memory card with flip animation.
## Face-down by default. Tap to flip. Engine controls match logic.

signal card_tapped(card: Node2D)

@export var card_id: String = ""       # Which pair this card belongs to
@export var pair_id: String = ""       # Shared by both cards in a pair
@export var card_size: Vector2 = Vector2(200, 260)
@export var face_color: Color = Color.WHITE
@export var back_color: Color = Color(0.25, 0.30, 0.45)
@export var face_label: String = ""

var face_texture: Texture2D = null
var is_face_up: bool = false
var is_matched: bool = false

var _is_animating: bool = false
var _face_node: Node = null
var _back_node: Node = null


func _ready() -> void:
	_build_back()
	_build_face()
	_show_back()


# ── Visuals ──

func _build_back() -> void:
	_back_node = _make_card_panel(back_color, "?")
	_back_node.name = "Back"
	add_child(_back_node)


func _build_face() -> void:
	if face_texture != null:
		_face_node = _make_card_sprite()
	else:
		_face_node = _make_card_panel(face_color, face_label)
	_face_node.name = "Face"
	add_child(_face_node)


func _make_card_panel(color: Color, text: String) -> Panel:
	var panel := Panel.new()
	panel.size = card_size
	panel.position = -card_size / 2

	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = color.darkened(0.3)
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = card_size
	label.position = Vector2.ZERO
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	panel.add_child(label)

	return panel


func _make_card_sprite() -> Control:
	# Wrap sprite in a container sized to card_size
	var container := Control.new()
	container.size = card_size
	container.position = -card_size / 2
	var sprite := TextureRect.new()
	sprite.texture = face_texture
	sprite.size = card_size
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	container.add_child(sprite)
	return container


func _show_back() -> void:
	_back_node.visible = true
	_face_node.visible = false
	is_face_up = false


func _show_face() -> void:
	_back_node.visible = false
	_face_node.visible = true
	is_face_up = true


# ── Input ──

func _input(event: InputEvent) -> void:
	if _is_animating or is_matched or is_face_up:
		return

	var tapped := false

	if event is InputEventScreenTouch and event.pressed:
		if _is_point_inside(event.position):
			tapped = true
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if _is_point_inside(event.position):
				tapped = true
				get_viewport().set_input_as_handled()

	if tapped:
		card_tapped.emit(self)


func _is_point_inside(point: Vector2) -> bool:
	var half := card_size / 2
	var rect := Rect2(global_position - half, card_size)
	return rect.has_point(point)


# ── Flip Animation ──

func flip_up() -> void:
	if is_face_up or _is_animating:
		return
	_is_animating = true

	var tween := create_tween()
	# Squash horizontally
	tween.tween_property(self, "scale:x", 0.0, 0.12) \
		.set_ease(Tween.EASE_IN)
	# Swap at midpoint
	tween.tween_callback(_show_face)
	# Expand back
	tween.tween_property(self, "scale:x", 1.0, 0.12) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): _is_animating = false)


func flip_down() -> void:
	if not is_face_up or _is_animating:
		return
	_is_animating = true

	var tween := create_tween()
	tween.tween_property(self, "scale:x", 0.0, 0.12) \
		.set_ease(Tween.EASE_IN)
	tween.tween_callback(_show_back)
	tween.tween_property(self, "scale:x", 1.0, 0.12) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): _is_animating = false)


func play_match_animation() -> void:
	is_matched = true
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1) \
		.set_ease(Tween.EASE_IN)
