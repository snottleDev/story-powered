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

**Current Milestone**: Milestone 1 - Core Framework  
**Active Branch**: `main` (will create `dev` branch when starting development)  
**Last Session**: 2026-02-16  
**Last Commit**: Initial project structure setup

---

## Next Priority

**Current Focus**: Complete Step 3 - Set up .claude/ folder structure

**Immediate Tasks**:
- [x] Create GitHub repository
- [x] Add core project files (.gitignore, README, CHANGELOG, project.godot)
- [ ] Complete .claude/ folder setup
- [ ] Clone repository locally
- [ ] Create directory structure
- [ ] Begin Milestone 1: Core Framework

---

## Quick Reference Links

**Repository**: https://github.com/snottleDev/story-powered  
**Key Documents**:
- Game Design: `docs/game_design.md` (to be created)
- Data Format: `docs/data_format.md` (to be created)
- Milestones: `docs/milestones.md` (to be created)
- Interaction Library: `docs/interaction_library.md` (to be created)

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

*Last Updated: 2026-02-16*
