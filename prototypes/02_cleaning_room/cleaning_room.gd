extends Node2D
## Cleaning room puzzle — thin visual wrapper.
## Builds a simple room backdrop, then hands off to the tap-to-clear engine.

const TapToClearEngineScene = preload("res://prototypes/02_cleaning_room/tap_to_clear_engine.tscn")

const SCREEN_W: float = 1080.0
const SCREEN_H: float = 1920.0

# Room layout — the floor/wall area where clutter is scattered
const ROOM_TOP:    float = 300.0   # Below the title area
const ROOM_BOTTOM: float = 1750.0  # Above the progress label


func _ready() -> void:
	_build_background()
	_start_puzzle()


# ── Background ──

func _build_background() -> void:
	# Wall (upper portion)
	var wall := ColorRect.new()
	wall.size = Vector2(SCREEN_W, ROOM_BOTTOM * 0.55)
	wall.position = Vector2(0, 0)
	wall.color = Color(0.88, 0.84, 0.78)
	wall.z_index = -10
	add_child(wall)

	# Floor (lower portion) — slightly warmer/darker tone
	var floor_rect := ColorRect.new()
	floor_rect.size = Vector2(SCREEN_W, SCREEN_H - ROOM_BOTTOM * 0.55)
	floor_rect.position = Vector2(0, ROOM_BOTTOM * 0.55)
	floor_rect.color = Color(0.72, 0.62, 0.50)
	floor_rect.z_index = -10
	add_child(floor_rect)

	# Baseboard — thin line where wall meets floor
	var baseboard := ColorRect.new()
	baseboard.size = Vector2(SCREEN_W, 12)
	baseboard.position = Vector2(0, ROOM_BOTTOM * 0.55 - 6)
	baseboard.color = Color(0.55, 0.48, 0.40)
	baseboard.z_index = -9
	add_child(baseboard)


# ── Puzzle Engine ──

func _start_puzzle() -> void:
	var engine := TapToClearEngineScene.instantiate()

	# Clutter area = the full room, below the title, above the progress label
	var clutter_rect := Rect2(
		80,          # Left margin
		ROOM_TOP,    # Below title
		SCREEN_W - 160,                   # Right margin
		ROOM_BOTTOM - ROOM_TOP            # Full room height
	)
	engine.set_clutter_area(clutter_rect)

	engine.load_puzzle("res://prototypes/02_cleaning_room/cleaning_room.json")
	engine.puzzle_completed.connect(_on_puzzle_completed)
	add_child(engine)


func _on_puzzle_completed() -> void:
	pass  # Hook for scene-specific celebration later
