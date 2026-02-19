extends Node2D
## Reusable tap-to-clear engine.
## Reads a JSON config, spawns tappable clutter items across a defined area,
## tracks how many have been removed, and emits puzzle_completed when all are gone.

const TappableItem = preload("res://prototypes/02_cleaning_room/tappable_item.gd")

const SCREEN_W: float = 1080.0
const SCREEN_H: float = 1920.0

signal puzzle_completed

## Path to the JSON config file — can also be passed to load_puzzle() directly.
@export_file("*.json") var puzzle_data_path: String

var _puzzle_data: Dictionary = {}

## The area within which items are positioned (percentage-based in JSON → pixels here).
var _clutter_area: Rect2 = Rect2(0, 0, SCREEN_W, SCREEN_H)

var _total_items: int = 0
var _removed_count: int = 0

var _progress_label: Label
var _success_label: Label


# ── Public API ──

func set_clutter_area(rect: Rect2) -> void:
	## Define the pixel area where items will be placed.
	## Call this before load_puzzle().
	_clutter_area = rect


func load_puzzle(path: String = "") -> void:
	## Load the puzzle from a JSON file and build the scene.
	if path != "":
		puzzle_data_path = path
	assert(puzzle_data_path != "", "tap_to_clear_engine: No puzzle_data_path set.")

	var file := FileAccess.open(puzzle_data_path, FileAccess.READ)
	assert(file != null, "tap_to_clear_engine: Could not open: " + puzzle_data_path)

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	assert(err == OK, "tap_to_clear_engine: JSON parse error: " + json.get_error_message())
	_puzzle_data = json.data

	_total_items = _puzzle_data.items.size()

	_build_title()
	_build_items()
	_build_progress_label()
	_build_success_label()
	_build_restart_button()


# ── Title ──

func _build_title() -> void:
	var title := Label.new()
	title.text = _puzzle_data.get("title", "")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(SCREEN_W, 100)
	title.position = Vector2(0, 120)
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.25, 0.2, 0.15))
	add_child(title)

	var subtitle_text: String = _puzzle_data.get("subtitle", "")
	if subtitle_text != "":
		var subtitle := Label.new()
		subtitle.text = subtitle_text
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle.size = Vector2(SCREEN_W, 60)
		subtitle.position = Vector2(0, 220)
		subtitle.add_theme_font_size_override("font_size", 32)
		subtitle.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4))
		add_child(subtitle)


# ── Items ──

func _build_items() -> void:
	for item_def in _puzzle_data.items:
		var item := _create_item(item_def)
		add_child(item)


func _create_item(item_def: Dictionary) -> Node2D:
	# Convert percentage position to pixel position within the clutter area
	var pct: Array = item_def.position
	var px := Vector2(
		_clutter_area.position.x + _clutter_area.size.x * pct[0],
		_clutter_area.position.y + _clutter_area.size.y * pct[1]
	)

	# Try loading a texture if the JSON specifies one
	var texture: Texture2D = null
	if item_def.has("texture") and ResourceLoader.exists(item_def.texture):
		texture = load(item_def.texture)

	var c: Array = item_def.color
	var sz: Array = item_def.size

	var item := Node2D.new()
	item.set_script(TappableItem)
	item.position = px
	item.item_id    = item_def.id
	item.item_color = Color(c[0], c[1], c[2])
	item.item_size  = Vector2(sz[0], sz[1])
	item.item_texture = texture  # null is fine — triggers placeholder
	item.item_removed.connect(_on_item_removed)

	return item


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
	var remaining := _total_items - _removed_count
	_progress_label.text = "%d item%s left" % [remaining, "s" if remaining != 1 else ""]


# ── Success ──

func _build_success_label() -> void:
	var success_text: String = _puzzle_data.get("success_text", "Done!")
	_success_label = Label.new()
	_success_label.text = success_text
	_success_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_success_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_success_label.size     = Vector2(600, 120)
	_success_label.position = Vector2(SCREEN_W / 2 - 300, SCREEN_H / 2 - 60)
	_success_label.add_theme_font_size_override("font_size", 80)
	_success_label.add_theme_color_override("font_color", Color(0.2, 0.65, 0.3))
	_success_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.3))
	_success_label.add_theme_constant_override("shadow_offset_x", 3)
	_success_label.add_theme_constant_override("shadow_offset_y", 3)
	_success_label.modulate.a = 0.0   # Hidden until success
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


# ── Callbacks ──

func _on_item_removed(_item_id: String) -> void:
	_removed_count += 1
	_update_progress()
	if _removed_count >= _total_items:
		_play_success()
