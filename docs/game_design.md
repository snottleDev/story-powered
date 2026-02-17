# Game Design

## Concept

Story-Powered is an interactive story game with chapter-based progression. Players experience visual storytelling through animated scenes and engage with reusable mini-game interactions.

## Core Principles

- **Pure visual storytelling**: No text in scenes, text only in menus
- **Portrait mode**: Designed for mobile, portrait orientation only
- **Data-driven**: All story content defined in JSON, not hardcoded
- **Auto-advance**: Scenes progress automatically after interaction completion + animation

## Proof of Concept Scope

- 2 chapters
- ~12 reusable interaction types
- Android & iOS targets

## Player Experience

1. Player opens app and selects a chapter
2. Scenes play out visually with animated elements
3. At key moments, the player interacts (tap, drag, swipe, etc.)
4. After completing an interaction, the scene animates a result and auto-advances
5. Chapter completes when all scenes are finished

## Interaction Design

Interactions are modular mini-games that can be configured via JSON for any scene context. See `interaction_library.md` for the full catalog.
