extends Node2D
## Bring-into-focus puzzle — thin visual wrapper.
## Builds a simple backdrop and hands off to the focus engine.

const FocusEngineScene = preload("res://prototypes/03_bring_into_focus/focus_engine.tscn")

const SCREEN_W: float = 1080.0
const SCREEN_H: float = 1920.0


func _ready() -> void:
	_build_background()
	_start_puzzle()


# ── Background ──

func _build_background() -> void:
	# Dark, slightly warm background — like a dim room
	var bg := ColorRect.new()
	bg.size = Vector2(SCREEN_W, SCREEN_H)
	bg.color = Color(0.12, 0.11, 0.13)
	bg.z_index = -10
	add_child(bg)

	# Subtle lighter area behind the image
	var frame := ColorRect.new()
	frame.size = Vector2(SCREEN_W - 40, 1040)
	frame.position = Vector2(20, 230)
	frame.color = Color(0.18, 0.17, 0.19)
	frame.z_index = -9
	add_child(frame)


# ── Puzzle Engine ──

func _start_puzzle() -> void:
	var engine := FocusEngineScene.instantiate()

	# Image area — centered, square-ish
	var image_rect := Rect2(60, 260, SCREEN_W - 120, 960)
	engine.set_image_area(image_rect)

	engine.load_puzzle("res://prototypes/03_bring_into_focus/bring_into_focus.json")
	engine.puzzle_completed.connect(_on_puzzle_completed)
	add_child(engine)


func _on_puzzle_completed() -> void:
	pass  # Hook for scene-specific celebration later
