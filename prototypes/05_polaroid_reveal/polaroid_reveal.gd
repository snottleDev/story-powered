extends Node2D
## Polaroid reveal puzzle — thin visual wrapper.
## Builds a wall with a pinned map/board and hands off to the engine.

const PolaroidEngineScene = preload("res://prototypes/05_polaroid_reveal/polaroid_engine.tscn")

const SCREEN_W: float = 1080.0
const SCREEN_H: float = 1920.0


func _ready() -> void:
	_build_background()
	_start_puzzle()


# ── Background ──

func _build_background() -> void:
	# Wall
	var wall := ColorRect.new()
	wall.size = Vector2(SCREEN_W, SCREEN_H)
	wall.color = Color(0.35, 0.30, 0.25)
	wall.z_index = -10
	add_child(wall)

	# Corkboard / map board
	var board := ColorRect.new()
	board.size = Vector2(SCREEN_W - 50, SCREEN_H * 0.55)
	board.position = Vector2(25, SCREEN_H * 0.12)
	board.color = Color(0.55, 0.42, 0.28)
	board.z_index = -9
	add_child(board)

	# Board border
	var border := ColorRect.new()
	border.size = Vector2(SCREEN_W - 40, SCREEN_H * 0.55 + 10)
	border.position = Vector2(20, SCREEN_H * 0.12 - 5)
	border.color = Color(0.30, 0.22, 0.14)
	border.z_index = -10
	add_child(border)

	# Subtle desk/shelf area at the bottom
	var shelf := ColorRect.new()
	shelf.size = Vector2(SCREEN_W, SCREEN_H * 0.28)
	shelf.position = Vector2(0, SCREEN_H * 0.72)
	shelf.color = Color(0.30, 0.25, 0.20)
	shelf.z_index = -9
	add_child(shelf)


# ── Puzzle Engine ──

func _start_puzzle() -> void:
	var engine := PolaroidEngineScene.instantiate()

	engine.load_puzzle("res://prototypes/05_polaroid_reveal/polaroid_reveal.json")
	engine.puzzle_completed.connect(_on_puzzle_completed)
	add_child(engine)


func _on_puzzle_completed() -> void:
	pass  # Hook for scene-specific celebration later
