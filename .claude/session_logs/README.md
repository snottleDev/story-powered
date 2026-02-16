# Session Logs Index

This directory contains a log of each Claude session spent working on this project.

---

## How to Use

**At Start of Session**:
- Claude reads `.claude/BOOT.md` which references this index
- Most recent session provides context for what was last accomplished

**At End of Session**:
- Claude asks: "Should I create a session log?"
- If yes, Claude generates a new session file using the template
- New session is added to the index below

---

## Sessions

### Session 01: [2026-02-16] - Repository Planning & Setup
**File**: `../../../Godot/2026-02-16_session_01.md` (in planning folder)  
**Milestone**: Pre-Project Setup  
**Summary**: Created user profile, defined team roles, designed repository structure, finalized JSON data format with percentage-based coordinates, created GitHub repository  
**Status**: ✅ Complete

**Key Decisions**:
- Data-driven architecture (JSON defines scenes)
- Percentage-based coordinates (0.0-1.0)
- Portrait mode only
- Pure visual storytelling
- Auto-advance after interactions
- Two chapters proof of concept

---

## Quick Stats

**Total Sessions**: 1  
**Current Milestone**: Milestone 1 - Core Framework (starting)  
**Project Start Date**: 2026-02-16  
**Repository**: https://github.com/snottleDev/story-powered

---

## Session Index Format

When adding new sessions, use this format:

```markdown
### Session ##: [Date] - [Brief Title]
**File**: `YYYY-MM-DD_session_##.md`  
**Milestone**: Milestone X: [Name]  
**Summary**: [One-sentence summary of what was accomplished]  
**Status**: ✅ Complete / 🔄 In Progress / ⏸️ Paused
```

---

*Last Updated: 2026-02-16*
