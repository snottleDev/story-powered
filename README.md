# Story-Powered

Interactive story game for mobile (Android/iOS) built with Godot.

## Overview

Story-Powered is a data-driven interactive story system featuring:
- Chapter-based narrative progression
- Visual storytelling with animated scenes
- Reusable mini-game interaction mechanics
- Portrait-mode mobile optimization
- Cross-platform (Android & iOS)

## Project Structure

```
story-powered/
├── .claude/              # Claude session management
├── data/                 # Story content (JSON)
├── assets/               # Visual and audio assets
├── scenes/               # Godot scene files
├── scripts/              # GDScript code
├── docs/                 # Documentation
└── builds/               # Export builds (gitignored)
```

## Getting Started

### Prerequisites
- Godot 4.x
- Android SDK (for Android export)
- Xcode (for iOS export, macOS only)

### Setup
1. Clone this repository
2. Open `project.godot` in Godot
3. Read `docs/data_format.md` for story authoring

### Development Workflow
1. Read `.claude/BOOT.md` when starting a session with Claude
2. Work on current milestone (see `docs/milestones.md`)
3. Test on mobile device or emulator
4. Commit changes with descriptive messages

## Architecture

**Data-Driven Design**: Stories are defined in JSON files, not hardcoded in scenes. This allows rapid content iteration without code changes.

**Reusable Interactions**: Mini-game mechanics are implemented as modular components that can be configured via JSON for any scene.

**Percentage-Based Coordinates**: All positions use 0.0-1.0 range for device-independent layout.

## Documentation

- `docs/game_design.md` - Game concept and design
- `docs/data_format.md` - JSON structure reference
- `docs/interaction_library.md` - Available interaction types
- `docs/milestones.md` - Development roadmap

## Development Status

**Current Milestone**: Setup & Planning  
**Proof of Concept**: 2 chapters

## Repository

https://github.com/snottleDev/story-powered

## Credits

Created by M. Reerink
