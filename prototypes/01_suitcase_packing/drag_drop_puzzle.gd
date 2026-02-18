extends Node2D
## Reusable drag-drop puzzle engine.
## Reads a JSON config, creates zones and draggable items, tracks completion.
## The parent scene controls where things appear via set_puzzle_area / set_items_area.

const DraggableItem = preload("res://prototypes/01_suitcase_packing/draggable_item.gd")

const SCREEN_W: float = 1080.0
const SCREEN_H: float = 1920.0

@export_file("*.json") var puzzle_data_path: String

signal puzzle_completed

var _puzzle_data: Dictionary = {}
var _puzzle_area: Rect2 = Rect2(0, 0, SCREEN_W, SCREEN_H)
var _items_area: Rect2 = Rect2(0, SCREEN_H * 0.6, SCREEN_W, SCREEN_H * 0.4)

var _packed_count: int = 0
var _total_items: int = 0
var _items: Array[Node2D] = []
var _zones: Array[Node2D] = []

var _progress_label: Label
var _success_label: Label
var _title_label: Label


func set_puzzle_area(rect: Rect2) -> void:
	_puzzle_area = rect


func set_items_area(rect: Rect2) -> void:
	_items_area = rect


func load_puzzle(path: String = "") -> void:
	if path != "":
		puzzle_data_path = path
	assert(puzzle_data_path != "", "No puzzle_data_path set")

	var file := FileAccess.open(puzzle_data_path, FileAccess.READ)
	assert(file != null, "Could not open: " + puzzle_data_path)
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	assert(err == OK, "JSON parse error: " + json.get_error_message())
	_puzzle_data = json.data

	_total_items = _puzzle_data.zones.size()
	_build_title()
	_build_zones()
	_build_items()
	_build_progress_label()
	_build_success_label()
	_build_restart_button()


# ── Title ──

func _build_title() -> void:
	_title_label = Label.new()
	_title_label.text = _puzzle_data.get("title", "")
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.size = Vector2(SCREEN_W, 100)
	_title_label.position = Vector2(0, 120)
	_title_label.add_theme_font_size_override("font_size", 64)
	_title_label.add_theme_color_override("font_color", Color(0.25, 0.2, 0.15))
	add_child(_title_label)

	var subtitle_text: String = _puzzle_data.get("subtitle", "")
	if subtitle_text != "":
		var sub := Label.new()
		sub.text = subtitle_text
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.size = Vector2(SCREEN_W, 60)
		sub.position = Vector2(0, 220)
		sub.add_theme_font_size_override("font_size", 32)
		sub.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4))
		add_child(sub)


# ── Zones ──

func _build_zones() -> void:
	var zone_defs: Array = _puzzle_data.zones
	for zone_def in zone_defs:
		var zone := _create_zone(zone_def)
		_zones.append(zone)
		add_child(zone)


func _create_zone(zone_def: Dictionary) -> Node2D:
	var pos_pct: Array = zone_def.position
	var zone_size := Vector2(zone_def.size[0], zone_def.size[1])

	# Convert percentage position to pixel position within the puzzle area
	var pos := Vector2(
		_puzzle_area.position.x + _puzzle_area.size.x * pos_pct[0],
		_puzzle_area.position.y + _puzzle_area.size.y * pos_pct[1]
	)

	# Find the matching item def to get the hint color
	var hint_color := Color(0.5, 0.5, 0.5, 0.2)
	var hint_label_text: String = zone_def.id.capitalize()
	var item_size := zone_size  # Fallback
	for item_def in _puzzle_data.items:
		if item_def.id == zone_def.id:
			var c: Array = item_def.color
			hint_color = Color(c[0], c[1], c[2], 0.2)
			hint_label_text = item_def.get("label", item_def.id.capitalize())
			item_size = Vector2(item_def.size[0], item_def.size[1])
			break

	var zone := Node2D.new()
	zone.global_position = pos

	# Zone background
	var bg := ColorRect.new()
	bg.size = zone_size
	bg.position = -zone_size / 2
	bg.color = Color(0.85, 0.75, 0.65, 0.4)
	zone.add_child(bg)

	# Border
	var border := ColorRect.new()
	border.size = zone_size + Vector2(4, 4)
	border.position = -zone_size / 2 - Vector2(2, 2)
	border.color = Color(0.6, 0.5, 0.4, 0.5)
	border.z_index = -1
	zone.add_child(border)

	# Silhouette hint
	var hint := ColorRect.new()
	hint.name = "Hint"
	hint.size = item_size
	hint.position = -item_size / 2
	hint.color = hint_color
	zone.add_child(hint)

	# Hint label
	var hint_label := Label.new()
	hint_label.name = "HintLabel"
	hint_label.text = hint_label_text
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.size = item_size
	hint_label.position = -item_size / 2
	hint_label.add_theme_font_size_override("font_size", 22)
	hint_label.add_theme_color_override("font_color", Color(hint_color, 0.3))
	zone.add_child(hint_label)

	# Store the drop rect for hit detection
	zone.set_meta("drop_rect", Rect2(pos - zone_size / 2, zone_size))

	return zone


# ── Items ──

func _build_items() -> void:
	var item_defs: Array = _puzzle_data.items

	# Build zone lookup: id -> zone node
	var zone_lookup: Dictionary = {}
	var zone_defs: Array = _puzzle_data.zones
	for i in range(zone_defs.size()):
		zone_lookup[zone_defs[i].id] = _zones[i]

	# Build start positions with slight randomness
	var positions: Array[Vector2] = []
	for item_def in item_defs:
		var pct: Array = item_def.start_position
		var x: float = _items_area.position.x + _items_area.size.x * pct[0]
		var y: float = _items_area.position.y + _items_area.size.y * pct[1] + randf_range(-20, 40)
		positions.append(Vector2(x, y))
	positions.shuffle()

	for i in range(item_defs.size()):
		var def: Dictionary = item_defs[i]
		var c: Array = def.color
		var sz := Vector2(def.size[0], def.size[1])

		# Try loading a texture if specified in the JSON
		var texture: Texture2D = null
		if def.has("texture") and ResourceLoader.exists(def.texture):
			texture = load(def.texture)

		var item := Node2D.new()
		item.set_script(DraggableItem)
		item.position = positions[i]
		item.item_id = def.id
		item.target_zone_id = def.id
		item.item_color = Color(c[0], c[1], c[2])
		item.item_size = sz
		item.item_texture = texture
		item.set_target_zone(zone_lookup[def.id])
		item.item_packed.connect(_on_item_packed)
		add_child(item)
		_items.append(item)


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
	_progress_label.text = "%d / %d packed" % [_packed_count, _total_items]


# ── Success ──

func _build_success_label() -> void:
	var success_text: String = _puzzle_data.get("success_text", "Complete!")
	_success_label = Label.new()
	_success_label.text = success_text
	_success_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_success_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_success_label.size = Vector2(600, 120)
	_success_label.position = Vector2(SCREEN_W / 2 - 300, SCREEN_H / 2 - 60)
	_success_label.add_theme_font_size_override("font_size", 80)
	_success_label.add_theme_color_override("font_color", Color(0.2, 0.65, 0.3))
	_success_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.3))
	_success_label.add_theme_constant_override("shadow_offset_x", 3)
	_success_label.add_theme_constant_override("shadow_offset_y", 3)
	_success_label.modulate.a = 0.0
	_success_label.z_index = 200
	add_child(_success_label)


# ── Restart Button ──

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


# ── Callbacks ──

func _on_item_packed(_item_id: String) -> void:
	_packed_count += 1
	_update_progress()

	if _packed_count >= _total_items:
		_play_success()


func _play_success() -> void:
	await get_tree().create_timer(0.3).timeout

	for item in _items:
		if item.has_method("play_success_bounce"):
			item.play_success_bounce()

	await get_tree().create_timer(0.2).timeout
	var tween := create_tween()
	tween.tween_property(_success_label, "modulate:a", 1.0, 0.4) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(_success_label, "scale", Vector2(1.05, 1.05), 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_success_label, "scale", Vector2(1.0, 1.0), 0.15)

	puzzle_completed.emit()
