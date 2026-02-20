extends Node2D
## Prototype 7: Bridge Scene — Scene Flow Test
## A father and daughter watch a bridge being constructed from behind a fence.
## Player taps bridge sections to complete it. Camera pans to gradually reveal
## the characters. Tests: narrative visual → integrated interaction → resolution.

const SCREEN_W: float = 1080.0
const SCREEN_H: float = 1920.0

# ── State ──
var _config: Dictionary = {}
var _current_stage: int = 0
var _is_animating: bool = false
var _total_pan: float = 0.0

# ── Panel ──
var _panel_w: float = 1000.0
var _panel_h: float = 1750.0
var _panel_x: float = 0.0
var _panel_y: float = 0.0

# ── Scene nodes ──
var _panel_clip: Control
var _scene_container: Control
var _sky_bg: ColorRect
var _bridge_sections: Array = []   # [{node, ghost, built}]
var _father: Panel
var _daughter: Panel
var _family_kneeling: Panel
var _speech_bubble: Control
var _bubble_thumbnail: Panel
var _bubble_tail: Polygon2D
var _advance_arrow: Button

# ── Parallax ──
var _parallax_layers: Array = []   # [{node, factor, base_y}]

# ── Config values ──
var _tints: Array = []
var _pan_per_stage: float = 150.0
var _final_zoom: float = 0.92
var _bubble_sides: Array = []
var _section_colors: Array = []


func _ready() -> void:
	_panel_x = (SCREEN_W - _panel_w) / 2.0
	_panel_y = (SCREEN_H - _panel_h) / 2.0

	_load_config()
	_build_background()
	_build_panel_clip()
	_build_scene_container()
	_build_sky()
	_build_landscape()
	_build_construction()
	_build_bridge()
	_build_fence()
	_build_characters()
	_build_speech_bubble()
	_build_advance_arrow()
	_build_panel_border()
	_apply_tint(0, true)

	# Opening pause, then first speech bubble
	await get_tree().create_timer(0.8).timeout
	_show_bubble(0)


# ── Config ──

func _load_config() -> void:
	var file := FileAccess.open(
		"res://prototypes/07_bridge_scene/bridge_scene.json", FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_as_text())
	_config = json.data

	_tints = _config.tints
	_pan_per_stage = _config.get("pan_per_stage", 150.0)
	_final_zoom = _config.get("final_zoom", 0.92)
	_bubble_sides = _config.bubbles

	for c in _config.get("section_colors", []):
		_section_colors.append(Color(c[0], c[1], c[2]))


# ── Background (outside panel) ──

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(SCREEN_W, SCREEN_H)
	bg.color = Color(0.94, 0.92, 0.88)   # Off-white paper
	bg.z_index = -20
	add_child(bg)


# ── Panel Clip & Scene Container ──

func _build_panel_clip() -> void:
	_panel_clip = Control.new()
	_panel_clip.position = Vector2(_panel_x, _panel_y)
	_panel_clip.size = Vector2(_panel_w, _panel_h)
	_panel_clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	add_child(_panel_clip)


func _build_scene_container() -> void:
	_scene_container = Control.new()
	_scene_container.position = Vector2.ZERO
	_scene_container.size = Vector2(_panel_w, _panel_h + 600)
	_scene_container.pivot_offset = Vector2(_panel_w / 2, _panel_h / 2)
	_panel_clip.add_child(_scene_container)


# ── Parallax helper ──

func _register_parallax(node: Control, factor: float) -> void:
	_parallax_layers.append({
		"node": node,
		"factor": factor,
		"base_y": node.position.y
	})


# ── Visual Layers ──

func _build_sky() -> void:
	# sky_bg.png — 1000×1200, sky with horizon
	_sky_bg = ColorRect.new()
	_sky_bg.position = Vector2(0, -200)
	_sky_bg.size = Vector2(_panel_w, 1600)
	_sky_bg.color = Color(0.7, 0.78, 0.9)
	_scene_container.add_child(_sky_bg)
	_register_parallax(_sky_bg, 0.0)


func _build_landscape() -> void:
	# landscape_mid.png — 1000×400, silhouetted distant hills
	var landscape := ColorRect.new()
	landscape.position = Vector2(0, 1050)
	landscape.size = Vector2(_panel_w, 350)
	landscape.color = Color(0.30, 0.32, 0.28)
	_scene_container.add_child(landscape)
	_register_parallax(landscape, 0.3)


func _build_construction() -> void:
	# construction_fg.png — 1000×500, construction crew silhouettes with crane
	var construction := ColorRect.new()
	construction.position = Vector2(0, 850)
	construction.size = Vector2(_panel_w, 400)
	construction.color = Color(0.35, 0.33, 0.30, 0.85)
	_scene_container.add_child(construction)
	_register_parallax(construction, 0.6)

	# Crane mast
	var mast := ColorRect.new()
	mast.position = Vector2(650, 550)
	mast.size = Vector2(18, 400)
	mast.color = Color(0.25, 0.23, 0.20)
	_scene_container.add_child(mast)
	_register_parallax(mast, 0.6)

	# Crane arm
	var arm := ColorRect.new()
	arm.position = Vector2(540, 550)
	arm.size = Vector2(200, 10)
	arm.color = Color(0.25, 0.23, 0.20)
	_scene_container.add_child(arm)
	_register_parallax(arm, 0.6)


func _build_bridge() -> void:
	# Bridge container — holds all 4 sections at parallax 0.5
	var bridge_container := Control.new()
	bridge_container.position = Vector2(0, 0)
	bridge_container.size = Vector2(_panel_w, 2350)
	_scene_container.add_child(bridge_container)
	_register_parallax(bridge_container, 0.5)

	# bridge_section_N_ghost.png / bridge_section_N_built.png — ×4
	var section_w: float = 210.0
	var section_h: float = 130.0
	var positions: Array = [
		Vector2(80, 1000),
		Vector2(290, 990),
		Vector2(510, 1000),
		Vector2(720, 990)
	]

	for i in 4:
		var color: Color = _section_colors[i] if i < _section_colors.size() \
			else Color(0.55, 0.52, 0.48)

		var section_node := Control.new()
		section_node.position = positions[i]
		section_node.size = Vector2(section_w, section_h)
		section_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bridge_container.add_child(section_node)

		# Ghost — transparent fill, light border (blueprint/outline look)
		var ghost := Panel.new()
		ghost.position = Vector2.ZERO
		ghost.size = Vector2(section_w, section_h)
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var gs := StyleBoxFlat.new()
		gs.bg_color = Color(0.8, 0.78, 0.75, 0.15)
		gs.border_color = Color(0.7, 0.68, 0.65, 0.4)
		for side in ["left", "top", "right", "bottom"]:
			gs.set("border_width_" + side, 2)
		for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
			gs.set("corner_radius_" + corner, 4)
		ghost.add_theme_stylebox_override("panel", gs)
		section_node.add_child(ghost)

		# Built — solid with border
		var built := Panel.new()
		built.position = Vector2.ZERO
		built.size = Vector2(section_w, section_h)
		built.modulate.a = 0.0
		built.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bs := StyleBoxFlat.new()
		bs.bg_color = color
		bs.border_color = color.darkened(0.25)
		for side in ["left", "top", "right", "bottom"]:
			bs.set("border_width_" + side, 2)
		for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
			bs.set("corner_radius_" + corner, 4)
		built.add_theme_stylebox_override("panel", bs)
		section_node.add_child(built)

		_bridge_sections.append({
			"node": section_node,
			"ghost": ghost,
			"built": built
		})


func _build_fence() -> void:
	# fence.png — 1000×200, fence with transparent top
	# Horizontal rail
	var rail := ColorRect.new()
	rail.position = Vector2(0, 1480)
	rail.size = Vector2(_panel_w, 28)
	rail.color = Color(0.28, 0.25, 0.20)
	_scene_container.add_child(rail)
	_register_parallax(rail, 1.0)

	# Fence posts
	for i in 8:
		var post := ColorRect.new()
		post.position = Vector2(55 + i * 125, 1455)
		post.size = Vector2(10, 75)
		post.color = Color(0.28, 0.25, 0.20)
		_scene_container.add_child(post)
		_register_parallax(post, 1.0)

	# Lower rail
	var lower_rail := ColorRect.new()
	lower_rail.position = Vector2(0, 1530)
	lower_rail.size = Vector2(_panel_w, 20)
	lower_rail.color = Color(0.32, 0.28, 0.22)
	_scene_container.add_child(lower_rail)
	_register_parallax(lower_rail, 1.0)


# ── Characters ──

func _make_silhouette(pos: Vector2, sz: Vector2, head_r: int) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = sz
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.10, 0.08)
	style.corner_radius_top_left = head_r
	style.corner_radius_top_right = head_r
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _build_characters() -> void:
	# father_standing.png — 300×800, full silhouette
	# Head barely visible at bottom of initial viewport (1750 - 1680 = 70px)
	_father = _make_silhouette(Vector2(330, 1680), Vector2(220, 700), 55)
	_scene_container.add_child(_father)
	_register_parallax(_father, 1.0)

	# daughter_standing.png — 200×700, full silhouette
	# Initially hidden below viewport
	_daughter = _make_silhouette(Vector2(580, 1790), Vector2(160, 560), 42)
	_daughter.modulate.a = 0.0
	_scene_container.add_child(_daughter)
	_register_parallax(_daughter, 1.0)

	# family_kneeling.png — 500×600, father kneeling with arm around daughter
	_family_kneeling = _make_silhouette(Vector2(310, 1750), Vector2(400, 430), 45)
	_family_kneeling.modulate.a = 0.0
	_scene_container.add_child(_family_kneeling)
	_register_parallax(_family_kneeling, 1.0)

	# Add a second "head" shape for the daughter in the kneeling group
	var kid_head := Panel.new()
	kid_head.position = Vector2(250, 35)
	kid_head.size = Vector2(90, 100)
	var khs := StyleBoxFlat.new()
	khs.bg_color = Color(0.12, 0.10, 0.08)
	khs.corner_radius_top_left = 40
	khs.corner_radius_top_right = 40
	khs.corner_radius_bottom_left = 10
	khs.corner_radius_bottom_right = 10
	kid_head.add_theme_stylebox_override("panel", khs)
	kid_head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_family_kneeling.add_child(kid_head)


# ── Speech Bubble ──

func _build_speech_bubble() -> void:
	_speech_bubble = Control.new()
	_speech_bubble.size = Vector2(220, 170)
	_speech_bubble.pivot_offset = Vector2(110, 85)
	_speech_bubble.visible = false
	_speech_bubble.z_index = 50
	_panel_clip.add_child(_speech_bubble)

	# Bubble body — white rounded rectangle
	var body := Panel.new()
	body.size = Vector2(220, 140)
	body.position = Vector2.ZERO
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(1.0, 1.0, 1.0, 0.95)
	bs.shadow_color = Color(0, 0, 0, 0.12)
	bs.shadow_size = 4
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		bs.set("corner_radius_" + corner, 16)
	body.add_theme_stylebox_override("panel", bs)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speech_bubble.add_child(body)

	# Tail — triangle
	_bubble_tail = Polygon2D.new()
	_bubble_tail.color = Color(1.0, 1.0, 1.0, 0.95)
	_speech_bubble.add_child(_bubble_tail)

	# Thumbnail — colored rectangle representing the bridge section
	_bubble_thumbnail = Panel.new()
	_bubble_thumbnail.size = Vector2(100, 70)
	_bubble_thumbnail.position = Vector2(60, 35)
	_bubble_thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(_bubble_thumbnail)


func _show_bubble(index: int) -> void:
	if index >= _bubble_sides.size():
		return

	var side: String = _bubble_sides[index].side
	var color: Color = _section_colors[index] if index < _section_colors.size() \
		else Color.GRAY

	# Position & tail based on speaker side
	if side == "left":
		_speech_bubble.position = Vector2(60, _panel_h - 380)
		_bubble_tail.polygon = PackedVector2Array([
			Vector2(35, 140), Vector2(65, 140), Vector2(15, 170)
		])
	else:
		_speech_bubble.position = Vector2(_panel_w - 280, _panel_h - 360)
		_bubble_tail.polygon = PackedVector2Array([
			Vector2(155, 140), Vector2(185, 140), Vector2(205, 170)
		])

	# Thumbnail color
	var ts := StyleBoxFlat.new()
	ts.bg_color = color
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		ts.set("corner_radius_" + corner, 6)
	_bubble_thumbnail.add_theme_stylebox_override("panel", ts)

	# Pop-in animation
	_speech_bubble.scale = Vector2.ZERO
	_speech_bubble.visible = true
	var tween := create_tween()
	tween.tween_property(_speech_bubble, "scale", Vector2(1.05, 1.05), 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_speech_bubble, "scale", Vector2(1.0, 1.0), 0.1)


# ── Advance Arrow ──

func _build_advance_arrow() -> void:
	_advance_arrow = Button.new()
	_advance_arrow.text = "→"
	_advance_arrow.size = Vector2(80, 80)
	_advance_arrow.position = Vector2(_panel_w - 120, _panel_h - 120)
	_advance_arrow.pivot_offset = Vector2(40, 40)
	_advance_arrow.add_theme_font_size_override("font_size", 48)
	_advance_arrow.modulate.a = 0.0
	_advance_arrow.z_index = 100
	_advance_arrow.pressed.connect(_on_advance_pressed)
	_panel_clip.add_child(_advance_arrow)


func _show_advance_arrow() -> void:
	var fade := create_tween()
	fade.tween_property(_advance_arrow, "modulate:a", 1.0, 0.5)

	# Breathing pulse loop
	var pulse := create_tween()
	pulse.set_loops()
	pulse.tween_property(_advance_arrow, "scale", Vector2(1.08, 1.08), 0.75) \
		.set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(_advance_arrow, "scale", Vector2(1.0, 1.0), 0.75) \
		.set_ease(Tween.EASE_IN_OUT)


func _on_advance_pressed() -> void:
	print("ADVANCE TO NEXT SCENE")


# ── Panel Border ──

func _build_panel_border() -> void:
	var border := Panel.new()
	border.position = Vector2(_panel_x, _panel_y)
	border.size = Vector2(_panel_w, _panel_h)
	border.z_index = 100
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)   # Transparent fill
	style.border_color = Color(0.15, 0.1, 0.08)
	for side in ["left", "top", "right", "bottom"]:
		style.set("border_width_" + side, 5)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 8)
	style.shadow_color = Color(0, 0, 0, 0.2)
	style.shadow_size = 6
	style.shadow_offset = Vector2(3, 4)
	border.add_theme_stylebox_override("panel", style)

	add_child(border)


# ── Input ──

func _input(event: InputEvent) -> void:
	if _is_animating or _current_stage >= 4:
		return

	var tap_pos := Vector2.ZERO
	var tapped := false

	if event is InputEventScreenTouch and event.pressed:
		tap_pos = event.position
		tapped = true
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			tap_pos = event.position
			tapped = true

	if not tapped:
		return

	# Must be within the panel
	var panel_rect := Rect2(_panel_x, _panel_y, _panel_w, _panel_h)
	if not panel_rect.has_point(tap_pos):
		return

	# Only the currently active section responds
	var section_data: Dictionary = _bridge_sections[_current_stage]
	var section_node: Control = section_data.node
	var global_rect := Rect2(section_node.global_position, section_node.size)
	if global_rect.has_point(tap_pos):
		get_viewport().set_input_as_handled()
		_advance_stage()


# ── Stage Advancement ──

func _advance_stage() -> void:
	_is_animating = true
	var stage := _current_stage

	# 1. Hide speech bubble
	if _speech_bubble.visible:
		var hide_tween := create_tween()
		hide_tween.tween_property(_speech_bubble, "scale", Vector2.ZERO, 0.15) \
			.set_ease(Tween.EASE_IN)
		hide_tween.tween_callback(func(): _speech_bubble.visible = false)
		await hide_tween.finished

	# 2. Build bridge section (ghost → built)
	var section: Dictionary = _bridge_sections[stage]
	var build_tween := create_tween()
	build_tween.set_parallel(true)
	build_tween.tween_property(section.ghost, "modulate:a", 0.0, 0.3)
	build_tween.tween_property(section.built, "modulate:a", 1.0, 0.5)
	await build_tween.finished

	# 3. Camera pan + tint
	if stage < 3:
		await _animate_pan_and_tint(stage + 1)
	else:
		await _animate_final_reveal()

	_current_stage += 1

	# 4. Show next bubble or finish
	if _current_stage < 4:
		await get_tree().create_timer(0.3).timeout
		_show_bubble(_current_stage)
		_is_animating = false


# ── Pan & Tint Animation ──

func _animate_pan_and_tint(tint_index: int) -> void:
	_total_pan += _pan_per_stage

	var tween := create_tween()
	tween.set_parallel(true)

	# Move scene container up
	tween.tween_property(_scene_container, "position:y", -_total_pan, 0.6) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

	# Counter-offset parallax layers
	for data in _parallax_layers:
		if data.factor < 1.0:
			var target_y: float = data.base_y + _total_pan * (1.0 - data.factor)
			tween.tween_property(data.node, "position:y", target_y, 0.6) \
				.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

	# Reveal daughter during stage 1→2 transition
	if tint_index == 2:
		tween.tween_property(_daughter, "modulate:a", 1.0, 0.6)

	# Daylight tint
	_apply_tint(tint_index, false)

	await tween.finished


# ── Final Reveal (Stage 4) ──

func _animate_final_reveal() -> void:
	_total_pan += _pan_per_stage

	# Update pivot to center of current viewport for zoom
	_scene_container.pivot_offset = Vector2(_panel_w / 2, _panel_h / 2 + _total_pan)

	var tween := create_tween()
	tween.set_parallel(true)

	# Pan
	tween.tween_property(_scene_container, "position:y", -_total_pan, 0.8) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

	# Zoom out
	tween.tween_property(
		_scene_container, "scale",
		Vector2(_final_zoom, _final_zoom), 0.8
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

	# Parallax
	for data in _parallax_layers:
		if data.factor < 1.0:
			var target_y: float = data.base_y + _total_pan * (1.0 - data.factor)
			tween.tween_property(data.node, "position:y", target_y, 0.8) \
				.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

	# Reveal daughter if not already visible
	if _daughter.modulate.a < 0.5:
		tween.tween_property(_daughter, "modulate:a", 1.0, 0.8)

	# Golden hour tint
	_apply_tint(4, false)

	await tween.finished

	# Character swap: standing → kneeling
	await get_tree().create_timer(0.5).timeout

	var swap_tween := create_tween()
	swap_tween.set_parallel(true)
	swap_tween.tween_property(_father, "modulate:a", 0.0, 1.0)
	swap_tween.tween_property(_daughter, "modulate:a", 0.0, 1.0)
	swap_tween.tween_property(_family_kneeling, "modulate:a", 1.0, 1.2)
	await swap_tween.finished

	# Advance arrow
	await get_tree().create_timer(0.8).timeout
	_show_advance_arrow()
	_is_animating = false


# ── Tint ──

func _apply_tint(index: int, instant: bool) -> void:
	if index >= _tints.size():
		return
	var t: Array = _tints[index]
	var color := Color(t[0], t[1], t[2])

	if instant:
		_sky_bg.color = color
	else:
		var tween := create_tween()
		tween.tween_property(_sky_bg, "color", color, 0.8) \
			.set_ease(Tween.EASE_IN_OUT)
