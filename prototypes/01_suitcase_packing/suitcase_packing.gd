extends Node2D

const DraggableItem = preload("res://prototypes/01_suitcase_packing/draggable_item.gd")

# Layout constants (1080x1920 portrait)
const SCREEN_W: float = 1080.0
const SCREEN_H: float = 1920.0
const SUITCASE_MARGIN: float = 60.0
const SUITCASE_TOP: float = 340.0
const SUITCASE_HEIGHT: float = 800.0
const ZONE_PADDING: float = 40.0
const ZONE_SIZE: Vector2 = Vector2(200, 200)
const ITEM_SIZE: Vector2 = Vector2(160, 160)

var packed_count: int = 0
var total_items: int = 5
var items: Array[Node2D] = []
var zones: Array[Node2D] = []

var _progress_label: Label
var _title_label: Label
var _success_label: Label

# Item definitions: id, color, zone_index
var item_defs: Array = [
	{ "id": "shirt", "color": Color(0.3, 0.5, 0.85), "zone": 0 },
	{ "id": "hat", "color": Color(0.85, 0.3, 0.3), "zone": 1 },
	{ "id": "book", "color": Color(0.55, 0.35, 0.2), "zone": 2 },
	{ "id": "socks", "color": Color(0.3, 0.7, 0.4), "zone": 3 },
	{ "id": "camera", "color": Color(0.9, 0.75, 0.2), "zone": 4 },
]


func _ready() -> void:
	_build_background()
	_build_title()
	_build_suitcase()
	_build_zones()
	_build_items()
	_build_progress_label()
	_build_success_label()


# ── Background ──

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(SCREEN_W, SCREEN_H)
	bg.color = Color(0.92, 0.90, 0.85)  # Warm light beige
	bg.z_index = -10
	add_child(bg)


# ── Title ──

func _build_title() -> void:
	_title_label = Label.new()
	_title_label.text = "Pack Your Suitcase!"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.size = Vector2(SCREEN_W, 100)
	_title_label.position = Vector2(0, 120)
	_title_label.add_theme_font_size_override("font_size", 64)
	_title_label.add_theme_color_override("font_color", Color(0.25, 0.2, 0.15))
	add_child(_title_label)

	# Subtitle
	var sub := Label.new()
	sub.text = "Drag each item to its spot"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(SCREEN_W, 60)
	sub.position = Vector2(0, 220)
	sub.add_theme_font_size_override("font_size", 32)
	sub.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4))
	add_child(sub)


# ── Suitcase ──

func _build_suitcase() -> void:
	var suitcase_w: float = SCREEN_W - SUITCASE_MARGIN * 2

	# Suitcase body
	var body := ColorRect.new()
	body.size = Vector2(suitcase_w, SUITCASE_HEIGHT)
	body.position = Vector2(SUITCASE_MARGIN, SUITCASE_TOP)
	body.color = Color(0.45, 0.3, 0.2)  # Brown leather
	add_child(body)

	# Suitcase interior (slightly inset)
	var interior := ColorRect.new()
	var inset: float = 20.0
	interior.size = Vector2(suitcase_w - inset * 2, SUITCASE_HEIGHT - inset * 2 - 30)
	interior.position = Vector2(SUITCASE_MARGIN + inset, SUITCASE_TOP + inset + 30)
	interior.color = Color(0.75, 0.65, 0.55)  # Lighter interior
	add_child(interior)

	# Suitcase lid line
	var lid := ColorRect.new()
	lid.size = Vector2(suitcase_w, 30)
	lid.position = Vector2(SUITCASE_MARGIN, SUITCASE_TOP)
	lid.color = Color(0.35, 0.22, 0.13)  # Darker rim
	add_child(lid)

	# Handle
	var handle := ColorRect.new()
	handle.size = Vector2(180, 16)
	handle.position = Vector2(SCREEN_W / 2 - 90, SUITCASE_TOP - 16)
	handle.color = Color(0.35, 0.22, 0.13)
	add_child(handle)


# ── Target Zones ──

func _build_zones() -> void:
	var suitcase_w: float = SCREEN_W - SUITCASE_MARGIN * 2
	var interior_x: float = SUITCASE_MARGIN + 20
	var interior_y: float = SUITCASE_TOP + 50
	var interior_w: float = suitcase_w - 40
	var interior_h: float = SUITCASE_HEIGHT - 70

	# Zone positions: 2x2 grid + 1 center
	var zone_positions: Array[Vector2] = [
		# Top-left
		Vector2(interior_x + ZONE_PADDING + ZONE_SIZE.x / 2,
				interior_y + ZONE_PADDING + ZONE_SIZE.y / 2),
		# Top-right
		Vector2(interior_x + interior_w - ZONE_PADDING - ZONE_SIZE.x / 2,
				interior_y + ZONE_PADDING + ZONE_SIZE.y / 2),
		# Bottom-left
		Vector2(interior_x + ZONE_PADDING + ZONE_SIZE.x / 2,
				interior_y + interior_h - ZONE_PADDING - ZONE_SIZE.y / 2),
		# Bottom-right
		Vector2(interior_x + interior_w - ZONE_PADDING - ZONE_SIZE.x / 2,
				interior_y + interior_h - ZONE_PADDING - ZONE_SIZE.y / 2),
		# Center
		Vector2(interior_x + interior_w / 2,
				interior_y + interior_h / 2),
	]

	for i in range(total_items):
		var zone := _create_zone(item_defs[i], zone_positions[i])
		zones.append(zone)
		add_child(zone)


func _create_zone(item_def: Dictionary, pos: Vector2) -> Node2D:
	var zone := Node2D.new()
	zone.global_position = pos

	# Zone background (dashed-border feel)
	var bg := ColorRect.new()
	bg.size = ZONE_SIZE
	bg.position = -ZONE_SIZE / 2
	bg.color = Color(0.85, 0.75, 0.65, 0.4)  # Subtle lighter area
	zone.add_child(bg)

	# Border
	var border := ColorRect.new()
	border.size = ZONE_SIZE + Vector2(4, 4)
	border.position = -ZONE_SIZE / 2 - Vector2(2, 2)
	border.color = Color(0.6, 0.5, 0.4, 0.5)
	border.z_index = -1
	zone.add_child(border)

	# Silhouette hint (faint colored shape matching the item)
	var hint := ColorRect.new()
	hint.name = "Hint"
	hint.size = ITEM_SIZE
	hint.position = -ITEM_SIZE / 2
	hint.color = Color(item_def.color, 0.2)  # Same color, very transparent
	zone.add_child(hint)

	# Hint label
	var hint_label := Label.new()
	hint_label.name = "HintLabel"
	hint_label.text = item_def.id.capitalize()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.size = ITEM_SIZE
	hint_label.position = -ITEM_SIZE / 2
	hint_label.add_theme_font_size_override("font_size", 22)
	hint_label.add_theme_color_override("font_color", Color(item_def.color, 0.3))
	zone.add_child(hint_label)

	# Store the drop rect for hit detection
	zone.set_meta("drop_rect", Rect2(pos - ZONE_SIZE / 2, ZONE_SIZE))

	return zone


# ── Draggable Items ──

func _build_items() -> void:
	# Scatter items below the suitcase
	var items_y: float = SUITCASE_TOP + SUITCASE_HEIGHT + 100
	var spacing: float = SCREEN_W / (total_items + 1)

	# Shuffle positions for variety
	var positions: Array[Vector2] = []
	for i in range(total_items):
		var x: float = spacing * (i + 1)
		var y: float = items_y + randf_range(-20, 40)
		positions.append(Vector2(x, y))
	positions.shuffle()

	for i in range(total_items):
		var def: Dictionary = item_defs[i]
		var item := Node2D.new()
		item.set_script(DraggableItem)
		item.position = positions[i]
		item.item_id = def.id
		item.target_zone_id = def.id
		item.item_color = def.color
		item.item_size = ITEM_SIZE
		item.set_target_zone(zones[def.zone])
		item.item_packed.connect(_on_item_packed)
		add_child(item)
		items.append(item)


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
	_progress_label.text = "%d / %d packed" % [packed_count, total_items]


# ── Success ──

func _build_success_label() -> void:
	_success_label = Label.new()
	_success_label.text = "All Packed!"
	_success_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_success_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_success_label.size = Vector2(600, 120)
	_success_label.position = Vector2(SCREEN_W / 2 - 300, SCREEN_H / 2 - 60)
	_success_label.add_theme_font_size_override("font_size", 80)
	_success_label.add_theme_color_override("font_color", Color(0.2, 0.65, 0.3))
	_success_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.3))
	_success_label.add_theme_constant_override("shadow_offset_x", 3)
	_success_label.add_theme_constant_override("shadow_offset_y", 3)
	_success_label.modulate.a = 0.0  # Hidden initially
	_success_label.z_index = 200
	add_child(_success_label)


func _on_item_packed(item_id: String) -> void:
	packed_count += 1
	_update_progress()

	if packed_count >= total_items:
		_play_success()


func _play_success() -> void:
	# Brief pause, then celebrate
	await get_tree().create_timer(0.3).timeout

	# Bounce all items
	for item in items:
		if item.has_method("play_success_bounce"):
			item.play_success_bounce()

	# Fade in success label
	await get_tree().create_timer(0.2).timeout
	var tween := create_tween()
	tween.tween_property(_success_label, "modulate:a", 1.0, 0.4) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(_success_label, "scale", Vector2(1.05, 1.05), 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_success_label, "scale", Vector2(1.0, 1.0), 0.15)
