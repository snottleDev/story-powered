extends Node2D
## A single tappable clutter item.
## Mode "remove": tap → pop-and-disappear animation → emits item_removed.
## Mode "tidy":   tap → swap to tidy graphic + slide to tidy position → emits item_removed.
## Supports an optional texture; falls back to a colored placeholder with label.

signal item_removed(item_id: String)

@export var item_id: String = ""
@export var item_color: Color = Color.WHITE
@export var item_size: Vector2 = Vector2(160, 160)

## "remove" (disappear on tap) or "tidy" (swap graphic + reposition)
var item_mode: String = "remove"

## Optional texture — set by the engine after load. If null, uses placeholder.
var item_texture: Texture2D = null

## Tidy-mode target state (ignored when mode == "remove")
var tidy_position: Vector2 = Vector2.ZERO
var tidy_color: Color = Color.WHITE
var tidy_size: Vector2 = Vector2(160, 160)
var tidy_texture: Texture2D = null

var _is_done: bool = false  # Guard against double-taps during animation


func _ready() -> void:
	_build_visual()


# ── Visual ──

func _build_visual() -> void:
	if item_texture != null:
		_build_sprite_visual()
	else:
		_build_placeholder_visual()


func _build_sprite_visual() -> void:
	# Derive size from the texture so layout is accurate
	item_size = item_texture.get_size()
	var sprite := Sprite2D.new()
	sprite.texture = item_texture
	# Sprite2D centers on its parent Node2D automatically
	add_child(sprite)


func _build_placeholder_visual() -> void:
	# Colored rounded rectangle
	var panel := Panel.new()
	panel.size = item_size
	panel.position = -item_size / 2  # Center on this node

	var style := StyleBoxFlat.new()
	style.bg_color = item_color
	style.corner_radius_top_left    = 14
	style.corner_radius_top_right   = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_left   = 3
	style.border_width_top    = 3
	style.border_width_right  = 3
	style.border_width_bottom = 3
	style.border_color = item_color.darkened(0.25)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	# Label centered in the rectangle
	var label := Label.new()
	label.text = item_id.capitalize()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	label.size     = item_size
	label.position = -item_size / 2
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)


# ── Input ──

func _input(event: InputEvent) -> void:
	if _is_done:
		return

	var tapped := false

	# Touch (device)
	if event is InputEventScreenTouch and event.pressed:
		if _is_point_inside(event.position):
			tapped = true
			get_viewport().set_input_as_handled()

	# Mouse (desktop testing)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if _is_point_inside(event.position):
				tapped = true
				get_viewport().set_input_as_handled()

	if tapped:
		if item_mode == "tidy":
			_play_tidy_animation()
		else:
			_play_remove_animation()


func _is_point_inside(point: Vector2) -> bool:
	# Hit area is the item rectangle centered on this node's global position
	var half := item_size / 2
	var rect := Rect2(global_position - half, item_size)
	return rect.has_point(point)


# ── Animation ──

func _play_remove_animation() -> void:
	_is_done = true  # Block further taps immediately

	# Quick pop: scale up slightly, then shrink to nothing while fading out
	var tween := create_tween()
	tween.set_parallel(true)
	# Pop up
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.08) \
		.set_ease(Tween.EASE_OUT)
	# Then shrink to zero and fade out
	tween.chain().tween_property(self, "scale", Vector2(0.0, 0.0), 0.18) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.chain().tween_property(self, "modulate:a", 0.0, 0.15) \
		.set_ease(Tween.EASE_IN)
	# Emit signal after animation finishes
	tween.chain().tween_callback(_on_remove_complete)


func _play_tidy_animation() -> void:
	_is_done = true

	# Quick bounce, then rebuild with tidy visuals and slide to tidy position
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.06) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_callback(_swap_to_tidy_visual)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", tidy_position, 0.25) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(_on_tidy_complete)


func _swap_to_tidy_visual() -> void:
	# Remove all current visual children
	for child in get_children():
		child.queue_free()

	# Apply tidy state
	item_color = tidy_color
	item_size = tidy_size
	item_texture = tidy_texture
	_build_visual()


func _on_tidy_complete() -> void:
	item_removed.emit(item_id)
	# Item stays in the scene — it's now tidy


func _on_remove_complete() -> void:
	item_removed.emit(item_id)
	queue_free()  # Remove from scene tree — it's gone
