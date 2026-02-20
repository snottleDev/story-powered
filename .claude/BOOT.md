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
**Last Session**: 2026-02-20
**Last Commit**: Add P7 bridge scene — scene flow prototype with parallax and interaction

---

## Next Priority

**Current Focus**: Scene flow prototype, then Milestone 1

**Prototype Sprint — Build Order** (all complete):
- [x] Prototype 1: Suitcase packing — drag & drop to target zones (refactored into reusable engine)
- [x] Prototype 2: Cleaning room — tap to remove/tidy objects
- [x] Prototype 3: Bring into focus — slider(s), 3 difficulty levels
- [x] Prototype 4: Memory game — flip & match pairs (auto-sizing grid)
- [x] Prototype 5: Polaroid reveal — swipe/shake to develop, pin to board
- [x] Prototype 6: Painting reveal — brush away cover layer with mask shader

**Scene Flow Prototype**:
- [x] Prototype 7: Bridge scene — narrative visuals + integrated interaction + parallax camera

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
**Rules**: Each prototype is self-contained in its folder. Shared drag-drop engine lives in `prototypes/01_suitcase_packing/` and can be reused by other prototypes. Feel over structure.
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
- Session log filenames include time to avoid same-day conflicts: `YYYY-MM-DD_HHMM_session_##.md`
- Claude Code is the sole writer to the repository — Claude.ai (browser) does not commit or push
- Stretch aspect "keep" for consistent 1080x1920 layout across devices
- Drag-drop puzzles: JSON config + reusable engine + visual wrapper per puzzle
- Items support optional textures with colored placeholder fallback

**Technical Approach**:
- Godot 4.x for mobile (Android & iOS)
- ~12 reusable interaction types initially
- Autoload singletons for core systems
- Assets organized by type, not by chapter

---

## Tool Responsibilities

**IMPORTANT — One writer rule**: To prevent files getting out of sync, only Claude Code (terminal) makes commits and pushes to GitHub. Claude.ai (browser) is read-only on the repository.

**IMPORTANT — No code in browser**: Claude.ai (browser) must NEVER write full implementation code — no complete scripts, no file contents ready to paste. It should discuss architecture, describe approaches, list what files/functions are needed, and explain logic in plain English. When the conversation reaches the point where code needs to be written, Claude.ai should stop and tell the user: "Hand this off to Claude Code now — here's a summary of what to build." The summary should describe *what* to implement, not provide the literal code. This prevents awkward copy-paste workflows and keeps Claude Code as the sole author of all project files.

| Task | Claude.ai (browser) | Claude Code (terminal) |
|------|-------------------|----------------------|
| Planning & decisions | ✅ Yes | — |
| Architecture & approach discussion | ✅ Yes | — |
| Writing implementation code | ❌ No | ✅ Yes |
| Reading files for context | ✅ Yes | ✅ Yes |
| Writing session log content | ✅ Drafts it | ✅ Creates & commits it |
| Updating BOOT.md | ❌ No | ✅ Yes |
| Creating/editing project files | ❌ No | ✅ Yes |
| Git commits & pushes | ❌ No | ✅ Yes |

---

## Session Workflow

**At Session Start**:
1. User says: "Read `.claude/BOOT.md`"
2. Claude loads context and confirms understanding
3. User states what they want to work on
4. Claude activates relevant team roles and begins

**At Session End**:
1. Claude asks: "Should I create a session log?"
2. If yes, Claude drafts the summary here in the browser
3. User switches to Claude Code to create, commit and push the log
4. Filename format: `YYYY-MM-DD_HHMM_session_##.md` (e.g. `2026-02-17_1430_session_03.md`)
5. Claude Code also updates BOOT.md with current status and commits it

---

*Last Updated: 2026-02-20 (evening)*
