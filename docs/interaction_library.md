# Interaction Library

## Overview

Interactions are reusable mini-game mechanics that can be configured via JSON for any scene. Each interaction type is implemented as a modular Godot scene with a corresponding script.

## Interaction Types

The following ~12 interaction types are planned for the proof of concept:

| # | Type | Description |
|---|------|-------------|
| 1 | `tap_target` | Tap a specific area to proceed |
| 2 | `drag_drop` | Drag an element to a target position |
| 3 | `swipe` | Swipe in a direction to trigger action |
| 4 | `hold` | Press and hold for a duration |
| 5 | `sequence_tap` | Tap multiple targets in order |
| 6 | `shake` | Shake the device to trigger effect |
| 7 | `tilt` | Tilt device to move/reveal elements |
| 8 | `pinch_zoom` | Pinch to zoom in/out |
| 9 | `draw_path` | Trace a path with finger |
| 10 | `reveal` | Scratch/wipe to reveal hidden content |
| 11 | `rotate` | Rotate an element with gesture |
| 12 | `multi_tap` | Tap rapidly to fill a meter |

## Implementation Pattern

Each interaction type follows this pattern:
- Scene file: `scenes/interactions/<type>.tscn`
- Script file: `scripts/interactions/<type>.gd`
- Configured via JSON parameters at runtime
- Emits `interaction_completed` signal when done
- Supports percentage-based positioning (0.0-1.0)

## JSON Configuration

Each interaction type accepts a `config` object in the scene JSON. See `data_format.md` for the full schema.
