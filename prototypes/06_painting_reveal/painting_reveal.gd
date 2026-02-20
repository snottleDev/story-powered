extends Node2D
## Painting reveal puzzle — thin visual wrapper.
## Builds a canvas/easel backdrop and hands off to the painting engine.

const PaintingEngineScene = preload("res://prototypes/06_painting_reveal/painting_engine.tscn")

const SCREEN_W: float = 1080.0
const SCREEN_H: float = 1920.0


func _ready() -> void:
	_build_background()
	_start_puzzle()


# ── Background ──

func _build_background() -> void:
	# Studio wall
	var wall := ColorRect.new()
	wall.size = Vector2(SCREEN_W, SCREEN_H)
	wall.color = Color(0.22, 0.20, 0.18)
	wall.z_index = -10
	add_child(wall)

	# Easel / frame behind the canvas
	var frame := ColorRect.new()
	frame.size = Vector2(SCREEN_W - 50, 1250)
	frame.position = Vector2(25, 255)
	frame.color = Color(0.40, 0.32, 0.22)
	frame.z_index = -9
	add_child(frame)

	# Inner frame border
	var inner := ColorRect.new()
	inner.size = Vector2(SCREEN_W - 70, 1230)
	inner.position = Vector2(35, 265)
	inner.color = Color(0.30, 0.24, 0.16)
	inner.z_index = -8
	add_child(inner)


# ── Puzzle Engine ──

func _start_puzzle() -> void:
	var engine := PaintingEngineScene.instantiate()

	# Canvas area — within the frame
	var canvas_rect := Rect2(50, 280, SCREEN_W - 100, 1200)
	engine.set_canvas_area(canvas_rect)

	engine.load_puzzle("res://prototypes/06_painting_reveal/painting_reveal.json")
	engine.puzzle_completed.connect(_on_puzzle_completed)
	add_child(engine)


func _on_puzzle_completed() -> void:
	pass  # Hook for scene-specific celebration later
