extends Node2D

signal item_packed(item_id: String)

@export var item_id: String = ""
@export var target_zone_id: String = ""
@export var item_color: Color = Color.WHITE
@export var item_size: Vector2 = Vector2(160, 160)

var home_position: Vector2
var is_dragging: bool = false
var is_locked: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_z_index: int = 0

var _visual: ColorRect
var _label: Label
var _target_zone: Node2D = null


func _ready() -> void:
	home_position = position
	original_z_index = z_index
	_build_visual()


func _build_visual() -> void:
	# Item body
	_visual = ColorRect.new()
	_visual.size = item_size
	_visual.position = -item_size / 2  # Center the rect on the node
	_visual.color = item_color
	add_child(_visual)

	# Rounded corners via a StyleBoxFlat
	var style := StyleBoxFlat.new()
	style.bg_color = item_color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = item_color.darkened(0.3)
	_visual.add_theme_stylebox_override("panel", style)

	# Name label
	_label = Label.new()
	_label.text = item_id.capitalize()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.size = item_size
	_label.position = -item_size / 2
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_label)


func set_target_zone(zone: Node2D) -> void:
	_target_zone = zone


func _input(event: InputEvent) -> void:
	if is_locked:
		return

	# Handle touch
	if event is InputEventScreenTouch:
		if event.pressed and _is_point_inside(event.position):
			_start_drag(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and is_dragging:
			_end_drag()
			get_viewport().set_input_as_handled()

	elif event is InputEventScreenDrag and is_dragging:
		_update_drag(event.position)
		get_viewport().set_input_as_handled()

	# Handle mouse (for desktop testing)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _is_point_inside(event.position):
				_start_drag(event.position)
				get_viewport().set_input_as_handled()
			elif not event.pressed and is_dragging:
				_end_drag()
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and is_dragging:
		_update_drag(event.position)
		get_viewport().set_input_as_handled()


func _is_point_inside(point: Vector2) -> bool:
	var rect := Rect2(global_position - item_size / 2 * scale, item_size * scale)
	return rect.has_point(point)


func _start_drag(pos: Vector2) -> void:
	is_dragging = true
	drag_offset = global_position - pos
	z_index = 100  # Render on top

	# Scale up
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1).set_ease(Tween.EASE_OUT)


func _update_drag(pos: Vector2) -> void:
	global_position = pos + drag_offset + Vector2(0, -40)  # Offset above finger


func _end_drag() -> void:
	is_dragging = false

	# Check if over correct target zone
	if _target_zone and _is_over_zone():
		_snap_to_zone()
	else:
		_bounce_back()


func _is_over_zone() -> bool:
	if not _target_zone:
		return false
	if _target_zone.has_meta("drop_rect"):
		var zone_rect: Rect2 = _target_zone.get_meta("drop_rect")
		return zone_rect.has_point(global_position)
	return false


func _snap_to_zone() -> void:
	is_locked = true
	var target_pos: Vector2 = _target_zone.global_position

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", target_pos, 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2) \
		.set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(_on_snap_complete)


func _on_snap_complete() -> void:
	z_index = original_z_index + 1
	# Hide the silhouette hint in the target zone
	var hint := _target_zone.get_node_or_null("Hint")
	if hint:
		hint.visible = false
	var hint_label := _target_zone.get_node_or_null("HintLabel")
	if hint_label:
		hint_label.visible = false
	item_packed.emit(item_id)


func _bounce_back() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", home_position, 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2) \
		.set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(func(): z_index = original_z_index)


func play_success_bounce() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.15) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15) \
		.set_ease(Tween.EASE_IN)
