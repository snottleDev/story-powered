# Data Format

## Overview

Story-Powered uses a data-driven architecture where JSON files define all story content. This separates content from code, enabling rapid iteration.

## Coordinate System

All positions use **percentage-based coordinates** in the range `0.0` to `1.0` for device-independent layout:
- `(0.0, 0.0)` = top-left corner
- `(1.0, 1.0)` = bottom-right corner
- `(0.5, 0.5)` = center of screen

## Directory Structure

```
data/
  chapters/          # Chapter definition files
    chapter_01.json
    chapter_02.json
  interactions/      # Interaction configuration templates
```

## Chapter JSON Structure

```json
{
  "id": "chapter_01",
  "title": "Chapter Title",
  "scenes": [
    {
      "id": "scene_01",
      "background": "backgrounds/forest_clearing.png",
      "elements": [
        {
          "type": "character",
          "asset": "characters/fox.png",
          "position": { "x": 0.5, "y": 0.7 },
          "scale": 1.0
        }
      ],
      "interaction": {
        "type": "tap_target",
        "config": {
          "target_position": { "x": 0.5, "y": 0.3 },
          "target_size": 0.15
        }
      },
      "on_complete": {
        "animation": "fade_out",
        "next_scene": "scene_02"
      }
    }
  ]
}
```

## Key Conventions

- Asset paths are relative to `assets/`
- All coordinates are percentage-based (0.0-1.0)
- Interaction types reference the interaction library
- Scene transitions are defined in `on_complete`
