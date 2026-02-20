extends Node2D
## Reusable memory/matching engine.
## Reads a JSON config, lays out cards in a grid, handles flip logic,
## match checking, and emits puzzle_completed when all pairs are found.

const MemoryCard = preload("res://prototypes/04_memory_game/memory_card.gd")

const SCREEN_W: float = 1080.0
const SCREEN_H: float = 1920.0

signal puzzle_completed

@export_file("*.json") var puzzle_data_path: String

var _puzzle_data: Dictionary = {}
var _cards: Array[Node2D] = []
var _flipped: Array[Node2D] = []    # Currently face-up (0, 1, or 2)
var _total_pairs: int = 0
var _matched_count: int = 0
var _is_checking: bool = false       # Lock input during match check

var _grid_area: Rect2 = Rect2(40, 350, 1000, 1200)
var _columns: int = 4

var _title_label: Label
var _progress_label: Label
var _success_label: Label


# ── Public API ──

func set_grid_area(rect: Rect2) -> void:
	_grid_area = rect


func load_puzzle(path: String = "") -> void:
	if path != "":
		puzzle_data_path = path
	assert(puzzle_data_path != "", "memory_engine: No puzzle_data_path set.")

	var file := FileAccess.open(puzzle_data_path, FileAccess.READ)
	assert(file != null, "memory_engine: Could not open: " + puzzle_data_path)

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	assert(err == OK, "memory_engine: JSON parse error: " + json.get_error_message())
	_puzzle_data = json.data

	_total_pairs = _puzzle_data.pairs.size()
	var total_cards := _total_pairs * 2
	# Auto-calculate columns if not specified: ceil(sqrt(n)) gives a near-square grid
	_columns = int(_puzzle_data.get("columns", ceili(sqrt(float(total_cards)))))

	_build_title()
	_build_cards()
	_build_progress_label()
	_build_success_label()
	_build_restart_button()


# ── Title ──

func _build_title() -> void:
	_title_label = Label.new()
	_title_label.text = _puzzle_data.get("title", "Memory")
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
		subtitle.add_theme_font_size_override("font_size", 32)
		subtitle.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4))
		add_child(subtitle)


# ── Cards ──

func _build_cards() -> void:
	# Flatten pairs into individual card definitions and shuffle
	var card_defs: Array = []
	var back_color_arr: Array = _puzzle_data.get("card_back_color", [0.25, 0.30, 0.45])
	var back_color := Color(back_color_arr[0], back_color_arr[1], back_color_arr[2])

	for pair in _puzzle_data.pairs:
		var pair_id: String = pair.id
		var idx := 0
		for card_def in pair.cards:
			card_defs.append({
				"pair_id": pair_id,
				"card_id": pair_id + "_" + str(idx),
				"label": card_def.get("label", ""),
				"color": card_def.get("color", [0.5, 0.5, 0.5]),
				"texture": card_def.get("texture", ""),
				"back_color": back_color
			})
			idx += 1

	# Shuffle
	card_defs.shuffle()

	# Calculate card size and spacing from grid area and column count
	var total_cards := card_defs.size()
	var rows := ceili(float(total_cards) / float(_columns))
	var gap := 20.0
	var card_w := (_grid_area.size.x - gap * (_columns - 1)) / _columns
	var card_h := (_grid_area.size.y - gap * (rows - 1)) / rows
	# Cap aspect ratio — cards shouldn't be too tall
	card_h = minf(card_h, card_w * 1.4)

	for i in card_defs.size():
		var def: Dictionary = card_defs[i]
		var col := i % _columns
		var row := i / _columns

		var px := Vector2(
			_grid_area.position.x + col * (card_w + gap) + card_w / 2,
			_grid_area.position.y + row * (card_h + gap) + card_h / 2
		)

		var c: Array = def.color
		var card := Node2D.new()
		card.set_script(MemoryCard)
		card.position = px
		card.card_id = def.card_id
		card.pair_id = def.pair_id
		card.card_size = Vector2(card_w, card_h)
		card.face_color = Color(c[0], c[1], c[2])
		card.back_color = def.back_color
		card.face_label = def.label

		if def.texture != "" and ResourceLoader.exists(def.texture):
			card.face_texture = load(def.texture)

		card.card_tapped.connect(_on_card_tapped)
		add_child(card)
		_cards.append(card)


# ── Flip & Match Logic ──

func _on_card_tapped(card: Node2D) -> void:
	if _is_checking:
		return
	if card.is_face_up or card.is_matched:
		return
	if _flipped.size() >= 2:
		return

	card.flip_up()
	_flipped.append(card)

	if _flipped.size() == 2:
		_is_checking = true
		# Short delay before checking
		await get_tree().create_timer(0.5).timeout
		_check_match()


func _check_match() -> void:
	var card_a: Node2D = _flipped[0]
	var card_b: Node2D = _flipped[1]

	if card_a.pair_id == card_b.pair_id:
		# Match!
		card_a.play_match_animation()
		card_b.play_match_animation()
		_matched_count += 1
		_update_progress()

		if _matched_count >= _total_pairs:
			await get_tree().create_timer(0.3).timeout
			_play_success()
	else:
		# No match — flip both back
		await get_tree().create_timer(0.3).timeout
		card_a.flip_down()
		card_b.flip_down()

	_flipped.clear()
	_is_checking = false


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
	var remaining := _total_pairs - _matched_count
	_progress_label.text = "%d pair%s left" % [remaining, "s" if remaining != 1 else ""]


# ── Success ──

func _build_success_label() -> void:
	var success_text: String = _puzzle_data.get("success_text", "Done!")
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
