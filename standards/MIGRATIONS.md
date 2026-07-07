# MIGRATIONS.md

> Owning standard: STD-META-001 v2.0 §8
> Last Updated: 2026-06-17
> Status: ACTIVE

This file tracks ID migrations, deprecations, and supersessions across the
four Z-ai repositories. The file format follows [Keep a Changelog](https://keepachangelog.com/)
adapted for ID lifecycle events.

`verify-id-graph.js` reads this file to:
- Resolve deprecated IDs during the migration window (G05)
- Warn on references to deprecated IDs (W01)
- Hard-fail on references to removed IDs after the window closes (G05)

---

## Migration Map Format

Each migration entry has the following fields:

| Field | Required | Description |
|---|---|---|
| `old_id` | yes | The ID being deprecated/superseded |
| `new_id` | yes (if superseded) | The replacement ID (omit if just removed) |
| `action` | yes | One of: `renamed`, `superseded`, `removed`, `split`, `merged` |
| `from_version` | yes | Version where the change was introduced |
| `window_close_version` | yes | Version after which the old ID is hard-removed |
| `reason` | yes | Short explanation |
| `notes` | no | Optional longer explanation |

---

## Active Migrations

### M001: ZAI-META-001 -> STD-SKILL-001 (superseded)

```yaml
old_id: ZAI-META-001
new_id: STD-SKILL-001
action: superseded
from_version: Z-ai-standards v2.0.0
window_close_version: Z-ai-skills v2.0.0
reason: Skill ID system content moved from skill layer to standards layer
notes: |
  ZAI-META-001 was a skill (skill-id-system) defining the ID format.
  Its content has moved to STD-SKILL-001 (a standard). The ZAI-META-001
  file remains in Z-ai-skills as a thin pointer during the migration
  window so trigger phrases ('skill id', 'create skill') continue to
  resolve. After Z-ai-skills v2.0.0, the file is deleted and references
  to ZAI-META-001 produce hard error G05.
```text

**Status**: Migration window OPEN. References to ZAI-META-001 produce W01
warning. File remains resolvable.

---

### M002: AHG RULE-001..RULE-017 -> RULE-<DOMAIN>-NNN (renamed)

```yaml
old_id: RULE-001 through RULE-017
new_id: RULE-ANSWER-001 through RULE-ARCH-017
action: renamed
from_version: Z-ai-guard v3.0.0
window_close_version: Z-ai-guard v4.0.0
reason: Flat numbering replaced with domain-prefixed numbering for clarity
notes: |
  Mapping table (17 entries):
    RULE-001  -> RULE-ANSWER-001
    RULE-002  -> RULE-WORKLOG-002
    RULE-003  -> RULE-READ-003
    RULE-004  -> RULE-COMMIT-004
    RULE-005  -> RULE-LOOPS-005
    RULE-006  -> RULE-HONEST-006
    RULE-007  -> RULE-STRUCT-007
    RULE-008  -> RULE-ENV-008
    RULE-009  -> RULE-AGENT-009
    RULE-010  -> RULE-DOC-010
    RULE-011  -> RULE-INTEGRITY-011
    RULE-012  -> RULE-MONOLITH-012
    RULE-013  -> RULE-VERSION-013
    RULE-014  -> RULE-COMMIT-014
    RULE-015  -> RULE-DOC-015
    RULE-016  -> RULE-ARCH-016
    RULE-017  -> RULE-ARCH-017
```

**Status**: Migration window NOT YET OPEN. Z-ai-guard repository not yet
created. This entry is a placeholder until AHG is migrated.

---

## Migration Lifecycle

```text
   ┌─────────────────┐
   │  ID is ACTIVE   │
   │  (in registry)  │
   └────────┬────────┘
            │
            │  PR introduces new ID + adds migration entry
            ▼
   ┌──────────────────────┐
   │  MIGRATION WINDOW    │  <- Old ID still resolvable
   │  (this file)         │  <- References produce W01 warning
   │  old_id: ACTIVE      │  <- new_id: ACTIVE
   └────────┬─────────────┘
            │
            │  window_close_version released
            ▼
   ┌──────────────────────┐
   │  POST-WINDOW         │  <- Old ID REMOVED from registry
   │                      │  <- References produce G05 hard error
   │  old_id: REMOVED     │  <- new_id: ACTIVE
   └──────────────────────┘
```text

---

## How to Add a New Migration

1. Assign the next migration number (M003, M004, ...)
2. Add a YAML block under "## Active Migrations" with all required fields
3. Update the registry in the owning standard (STD-META-001 §4 or STD-SKILL-001 §4)
4. Mark the old ID's status as `[DEPRECATED]` or `[SUPERSEDED]` in the registry
5. Run `node scripts/verify-id-graph.js` — must still pass
6. Commit with message: `chore(migrations): M0XX <old_id> -> <new_id> (<action>)`

---

## Archive

Migrations whose window has closed are moved to "## Archive" section below
with the close date. They are kept for historical reference and to detect
stale references in old branches.

### (none yet)

---

*End of MIGRATIONS.md.*
