extends Node2D
## Memory game puzzle — thin visual wrapper.
## Builds a table/desk backdrop and hands off to the memory engine.

const MemoryEngineScene = preload("res://prototypes/04_memory_game/memory_engine.tscn")

const SCREEN_W: float = 1080.0
const SCREEN_H: float = 1920.0


func _ready() -> void:
	_build_background()
	_start_puzzle()


# ── Background ──

func _build_background() -> void:
	# Desk surface
	var bg := ColorRect.new()
	bg.size = Vector2(SCREEN_W, SCREEN_H)
	bg.color = Color(0.28, 0.22, 0.16)
	bg.z_index = -10
	add_child(bg)

	# Felt/cloth area where cards are laid out
	var felt := ColorRect.new()
	felt.size = Vector2(SCREEN_W - 40, 1300)
	felt.position = Vector2(20, 300)
	felt.color = Color(0.18, 0.32, 0.22)
	felt.z_index = -9
	add_child(felt)

	# Subtle border around felt
	var border := ColorRect.new()
	border.size = Vector2(SCREEN_W - 32, 1308)
	border.position = Vector2(16, 296)
	border.color = Color(0.35, 0.28, 0.20)
	border.z_index = -10
	add_child(border)


# ── Puzzle Engine ──

func _start_puzzle() -> void:
	var engine := MemoryEngineScene.instantiate()

	# Grid area — within the felt surface
	var grid_rect := Rect2(60, 340, SCREEN_W - 120, 1220)
	engine.set_grid_area(grid_rect)

	engine.load_puzzle("res://prototypes/04_memory_game/memory_game.json")
	engine.puzzle_completed.connect(_on_puzzle_completed)
	add_child(engine)


func _on_puzzle_completed() -> void:
	pass  # Hook for scene-specific celebration later
