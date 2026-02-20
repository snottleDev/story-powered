extends Node2D
## Suitcase packing puzzle — thin visual wrapper.
## Builds the suitcase backdrop, then hands off to the reusable drag-drop engine.

const DragDropPuzzleScene = preload("res://prototypes/01_suitcase_packing/drag_drop_puzzle.tscn")

# Layout constants (1080x1920 portrait)
const SCREEN_W: float = 1080.0
const SCREEN_H: float = 1920.0
const SUITCASE_MARGIN: float = 60.0
const SUITCASE_TOP: float = 340.0
const SUITCASE_HEIGHT: float = 800.0


func _ready() -> void:
	_build_background()
	_build_suitcase()
	_start_puzzle()


# ── Background ──

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(SCREEN_W, SCREEN_H)
	bg.color = Color(0.92, 0.90, 0.85)
	bg.z_index = -10
	add_child(bg)


# ── Suitcase Visual ──

func _build_suitcase() -> void:
	var suitcase_w: float = SCREEN_W - SUITCASE_MARGIN * 2

	# Suitcase body
	var body := ColorRect.new()
	body.size = Vector2(suitcase_w, SUITCASE_HEIGHT)
	body.position = Vector2(SUITCASE_MARGIN, SUITCASE_TOP)
	body.color = Color(0.45, 0.3, 0.2)
	add_child(body)

	# Suitcase interior (slightly inset)
	var interior := ColorRect.new()
	var inset: float = 20.0
	interior.size = Vector2(suitcase_w - inset * 2, SUITCASE_HEIGHT - inset * 2 - 30)
	interior.position = Vector2(SUITCASE_MARGIN + inset, SUITCASE_TOP + inset + 30)
	interior.color = Color(0.75, 0.65, 0.55)
	add_child(interior)

	# Suitcase lid line
	var lid := ColorRect.new()
	lid.size = Vector2(suitcase_w, 30)
	lid.position = Vector2(SUITCASE_MARGIN, SUITCASE_TOP)
	lid.color = Color(0.35, 0.22, 0.13)
	add_child(lid)

	# Handle
	var handle := ColorRect.new()
	handle.size = Vector2(180, 16)
	handle.position = Vector2(SCREEN_W / 2 - 90, SUITCASE_TOP - 16)
	handle.color = Color(0.35, 0.22, 0.13)
	add_child(handle)


# ── Puzzle Engine ──

func _start_puzzle() -> void:
	var puzzle := DragDropPuzzleScene.instantiate()

	# Puzzle area = the suitcase interior
	var inset: float = 20.0
	var suitcase_w: float = SCREEN_W - SUITCASE_MARGIN * 2
	var interior_rect := Rect2(
		SUITCASE_MARGIN + inset,
		SUITCASE_TOP + 50,
		suitcase_w - inset * 2,
		SUITCASE_HEIGHT - 70
	)
	puzzle.set_puzzle_area(interior_rect)

	# Items area = below the suitcase
	var items_rect := Rect2(
		0,
		SUITCASE_TOP + SUITCASE_HEIGHT + 60,
		SCREEN_W,
		200
	)
	puzzle.set_items_area(items_rect)

	puzzle.load_puzzle("res://prototypes/01_suitcase_packing/suitcase_puzzle.json")
	puzzle.puzzle_completed.connect(_on_puzzle_completed)
	add_child(puzzle)


func _on_puzzle_completed() -> void:
	pass  # Hook for scene-specific celebration if needed
