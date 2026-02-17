# Claude Session Boot

**Quick Start**: At the beginning of each session, tell Claude: "Read `.claude/BOOT.md`"

---

## Load Order (Claude reads these automatically)

1. **`.claude/user_profile.md`** - Your skills, preferences, and how Claude should help
2. **`.claude/team_roles.md`** - Active virtual team member roles for this project
3. **`.claude/session_logs/README.md`** - Context from previous sessions

---

## Project Overview

**Project Name**: Story-Powered
**Type**: Interactive Story Game (Portrait, Mobile)
**Platform**: Android & iOS via Godot
**Architecture**: Data-driven story system with reusable interaction mechanics

---

## Current Status

**Current Milestone**: Prototype Sprint (before Milestone 1)
**Active Branch**: `dev`
**Last Session**: 2026-02-17
**Last Commit**: Prototype 1 — suitcase packing scene built and committed

---

## Next Priority

**Current Focus**: Prototype Sprint — 6 standalone interaction experiments in `/prototypes`

**Prototype Sprint — Build Order**:
- [x] Prototype 1: Suitcase packing — drag & drop to target zones
- [ ] Prototype 2: Cleaning room — tap to remove objects
- [ ] Prototype 3: Bring into focus — slider(s)
- [ ] Prototype 4: Memory game — sequential tap + match logic
- [ ] Prototype 5: Polaroid map — shake/swipe gesture + reveal animation
- [ ] Prototype 6: Painting reveal — continuous brush stroke + progressive image reveal

**iOS Testing**:
- [x] Install Xcode & partial iOS export setup
- [ ] Connect iPhone via USB, provision device in Xcode
- [ ] Test prototypes on device — validate touch feel

**After Sprint**:
- [ ] Review what felt good, decide final ~12 interaction types
- [ ] Finalize JSON data format → `docs/data_format.md`
- [ ] Create game design document → `docs/game_design.md`
- [ ] Begin Milestone 1: Core Framework

---

## Prototype Sprint Notes

**Goal**: Discover what interactions feel right before locking down architecture or data format.
**Rules**: Each prototype is fully self-contained — one Godot scene, no shared code, no architecture. Feel over structure.
**Each prototype should have**: A rough story context + a simple success state (input → response → feedback).
**Location**: `/prototypes` folder in the repo.
**Build order rationale**: Start simple (drag, tap) and work up to complex (brush reveal, shake).

---

## Quick Reference Links

**Repository**: https://github.com/snottleDev/story-powered
**Key Documents**:
- Game Design: `docs/game_design.md`
- Data Format: `docs/data_format.md`
- Milestones: `docs/milestones.md`
- Interaction Library: `docs/interaction_library.md`
- Prototype 1: `prototypes/01_suitcase_packing/`

---

## Project-Specific Notes

**Story Concept**: Interactive story game with chapter-based progression, visual storytelling through animated scenes, and reusable mini-game interactions.

**Key Decisions Made**:
- Data-driven architecture (JSON defines scenes/chapters)
- Percentage-based coordinates (0.0-1.0 range) for device independence
- Portrait mode only
- One repository per game
- Two chapters for proof of concept
- Pure visual storytelling (no text in scenes, text in menus only)
- Auto-advance scenes after interaction completion + animation
- Use `gh auth setup-git` to bypass macOS keychain for Git pushes
- Prototype Sprint before Milestone 1 — build 6 interaction experiments first
- Prototypes use rough story context (suitcase, cleaning, focus, memory, polaroids, painting)

**Technical Approach**:
- Godot 4.x for mobile (Android & iOS)
- ~12 reusable interaction types initially
- Autoload singletons for core systems
- Assets organized by type, not by chapter

---

## Session Workflow

**At Session Start**:
1. User says: "Read `.claude/BOOT.md`"
2. Claude loads context and confirms understanding
3. User states what they want to work on
4. Claude activates relevant team roles and begins

**At Session End**:
1. Claude asks: "Should I create a session log?"
2. If yes, Claude generates summary in `.claude/session_logs/`
3. Claude updates this BOOT.md with current status
4. User commits changes

---

*Last Updated: 2026-02-17*
