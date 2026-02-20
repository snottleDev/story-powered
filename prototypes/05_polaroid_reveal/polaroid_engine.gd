extends Node2D
## Reusable polaroid reveal engine.
## Presents polaroids one at a time — swipe to develop, then pin to board.
## Emits puzzle_completed when all polaroids are pinned.

const PolaroidCard = preload("res://prototypes/05_polaroid_reveal/polaroid_card.gd")

const SCREEN_W: float = 1080.0
const SCREEN_H: float = 1920.0

signal puzzle_completed

@export_file("*.json") var puzzle_data_path: String

var _puzzle_data: Dictionary = {}
var _polaroid_defs: Array = []
var _current_index: int = -1
var _active_card: Node2D = null
var _total_count: int = 0
var _pinned_count: int = 0

# Board area in pixels (where pinned polaroids go)
var _board_area: Rect2 = Rect2(30, 230, 1020, 1060)

# Active card display position (large, centered, below board)
var _active_position: Vector2 = Vector2(SCREEN_W / 2, 1450)
var _active_photo_size: Vector2 = Vector2(560, 560)

# Pinned card scale relative to active
var _pin_scale: float = 0.38

var _swipes_to_develop: int = 4

# Shake detection (accelerometer)
var _prev_accel: Vector3 = Vector3.ZERO
var _shake_cooldown: float = 0.0
const SHAKE_THRESHOLD: float = 18.0    # Acceleration delta to count as shake
const SHAKE_COOLDOWN_TIME: float = 0.4  # Seconds between shake triggers

var _title_label: Label
var _progress_label: Label
var _success_label: Label
var _hint_label: Label


# ── Public API ──

func set_board_area(rect: Rect2) -> void:
	_board_area = rect


func set_active_position(pos: Vector2) -> void:
	_active_position = pos


func load_puzzle(path: String = "") -> void:
	if path != "":
		puzzle_data_path = path
	assert(puzzle_data_path != "", "polaroid_engine: No puzzle_data_path set.")

	var file := FileAccess.open(puzzle_data_path, FileAccess.READ)
	assert(file != null, "polaroid_engine: Could not open: " + puzzle_data_path)

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	assert(err == OK, "polaroid_engine: JSON parse error: " + json.get_error_message())
	_puzzle_data = json.data

	_polaroid_defs = _puzzle_data.polaroids
	_total_count = _polaroid_defs.size()
	_swipes_to_develop = int(_puzzle_data.get("swipes_to_develop", 4))

	# Parse board area from JSON if provided (percentage-based)
	if _puzzle_data.has("board_area"):
		var ba: Array = _puzzle_data.board_area
		_board_area = Rect2(
			ba[0] * SCREEN_W, ba[1] * SCREEN_H,
			ba[2] * SCREEN_W, ba[3] * SCREEN_H
		)

	_build_title()
	_build_progress_label()
	_build_hint_label()
	_build_success_label()
	_build_restart_button()

	# Start with the first polaroid
	_show_next_polaroid()


# ── Shake Detection ──

func _process(delta: float) -> void:
	if _active_card == null:
		return

	_shake_cooldown = maxf(0.0, _shake_cooldown - delta)

	var accel := Input.get_accelerometer()
	if _prev_accel != Vector3.ZERO and _shake_cooldown <= 0.0:
		var delta_accel := (accel - _prev_accel).length()
		if delta_accel > SHAKE_THRESHOLD:
			_shake_cooldown = SHAKE_COOLDOWN_TIME
			_active_card.register_external_swipe()
	_prev_accel = accel


# ── Title ──

func _build_title() -> void:
	_title_label = Label.new()
	_title_label.text = _puzzle_data.get("title", "Memories")
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.size = Vector2(SCREEN_W, 100)
	_title_label.position = Vector2(0, 40)
	_title_label.add_theme_font_size_override("font_size", 56)
	_title_label.add_theme_color_override("font_color", Color(0.9, 0.87, 0.82))
	add_child(_title_label)


func _build_hint_label() -> void:
	_hint_label = Label.new()
	_hint_label.text = _puzzle_data.get("subtitle", "Swipe down to develop")
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.size = Vector2(SCREEN_W, 50)
	_hint_label.position = Vector2(0, SCREEN_H - 220)
	_hint_label.add_theme_font_size_override("font_size", 28)
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.50))
	add_child(_hint_label)


# ── Polaroid Flow ──

func _show_next_polaroid() -> void:
	_current_index += 1
	if _current_index >= _total_count:
		_play_success()
		return

	var def: Dictionary = _polaroid_defs[_current_index]
	var c: Array = def.get("color", [0.5, 0.5, 0.5])

	var card := Node2D.new()
	card.set_script(PolaroidCard)
	card.card_id = def.id
	card.face_color = Color(c[0], c[1], c[2])
	card.face_label = def.get("label", "")
	card.photo_size = _active_photo_size
	card.swipes_to_develop = _swipes_to_develop

	# Store pin target info
	var pin_pct: Array = def.get("pin_position", [0.5, 0.5])
	card.pin_position = Vector2(
		_board_area.position.x + _board_area.size.x * pin_pct[0],
		_board_area.position.y + _board_area.size.y * pin_pct[1]
	)
	card.pin_rotation_deg = def.get("pin_rotation", 0.0)

	if def.has("texture") and ResourceLoader.exists(def.texture):
		card.face_texture = load(def.texture)

	# Position large and centered
	card.position = _active_position
	card.z_index = 100  # Above pinned cards

	# Fade in
	card.modulate.a = 0.0

	card.developed.connect(_on_card_developed)
	card.swipe_registered.connect(_on_swipe_registered)
	add_child(card)

	# Activate after adding to tree
	_active_card = card
	var tween := create_tween()
	tween.tween_property(card, "modulate:a", 1.0, 0.3) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): card.set_active(true))


func _on_swipe_registered(_card: Node2D) -> void:
	# Could add board-level feedback here (e.g. counter update)
	pass


func _on_card_developed(card: Node2D) -> void:
	card.set_active(false)

	# Brief pause to admire the photo
	await get_tree().create_timer(0.4).timeout

	# Animate to pin position on the board
	var target_scale := Vector2(_pin_scale, _pin_scale)
	card.z_index = _pinned_count  # Stack order on board
	await card.animate_to_pin(card.pin_position, card.pin_rotation_deg, target_scale)

	_pinned_count += 1
	_update_progress()

	# Brief pause, then next
	await get_tree().create_timer(0.3).timeout
	_show_next_polaroid()


# ── Progress ──

func _build_progress_label() -> void:
	_progress_label = Label.new()
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.size = Vector2(SCREEN_W, 60)
	_progress_label.position = Vector2(0, SCREEN_H - 160)
	_progress_label.add_theme_font_size_override("font_size", 36)
	_progress_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4))
	add_child(_progress_label)
	_update_progress()


func _update_progress() -> void:
	var remaining := _total_count - _pinned_count
	_progress_label.text = "%d photo%s left" % [remaining, "s" if remaining != 1 else ""]


# ── Success ──

func _build_success_label() -> void:
	var success_text: String = _puzzle_data.get("success_text", "All Remembered")
	_success_label = Label.new()
	_success_label.text = success_text
	_success_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_success_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_success_label.size = Vector2(800, 120)
	_success_label.position = Vector2(SCREEN_W / 2 - 400, SCREEN_H / 2 - 60)
	_success_label.add_theme_font_size_override("font_size", 80)
	_success_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.75))
	_success_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
	_success_label.add_theme_constant_override("shadow_offset_x", 3)
	_success_label.add_theme_constant_override("shadow_offset_y", 3)
	_success_label.modulate.a = 0.0
	_success_label.z_index = 300
	add_child(_success_label)


func _play_success() -> void:
	_hint_label.visible = false
	_progress_label.visible = false

	await get_tree().create_timer(0.3).timeout

	var tween := create_tween()
	tween.tween_property(_success_label, "modulate:a", 1.0, 0.5) \
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
	button.z_index = 300
	button.pressed.connect(_on_restart)
	add_child(button)


func _on_restart() -> void:
	get_tree().reload_current_scene()
