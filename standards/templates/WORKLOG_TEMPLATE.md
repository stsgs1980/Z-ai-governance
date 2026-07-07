# Worklog Template v1.0

> ID: STD-DOC-005
> Version: 1.0
> Level: **[W] Warning**
> Related: META-001-standard-id-system

This template defines the structure for project `worklog.md` files.

---

## 1. Purpose

Worklog is an **append-only chronological log** of all significant actions.
It provides an audit trail for debugging, handoffs, and session recovery.

---

## 2. Rules

| Rule                 | Description                                         |
| -------------------- | --------------------------------------------------- |
| Append-only          | Never edit or reorder existing entries              |
| Before/After         | Read before action, update after (RULE-WORKLOG-002) |
| One entry per action | Each meaningful action gets its own entry           |
| No deletion          | Entries are permanent; mark as superseded if needed |

---

## 3. Entry Format

```markdown
## [YYYY-MM-DD HH:MM] Action Title

**Status:** [OK] completed / [FAIL] failed / [WIP] in progress
**Files:** list of files touched (optional)

### What was done

Description of the action.

### Result

Outcome of the action.

### Follow-up (if any)

Next steps or TODOs.
```

---

## 4. Entry Rules

| Element     | Required | Format                          |
| ----------- | -------- | ------------------------------- |
| Timestamp   | yes      | `[YYYY-MM-DD HH:MM]`            |
| Title       | yes      | Short description of the action |
| Status      | yes      | `[OK]`, `[FAIL]`, or `[WIP]`    |
| Description | yes      | What was done                   |
| Result      | yes      | Outcome                         |
| Follow-up   | no       | Next steps if any               |

---

## 5. Example

```markdown
## [2026-07-04 15:30] Fix snapshot path normalization

**Status:** [OK]
**Files:** standards/scripts/lib/snapshot.js, standards/scripts/lib/output.js

### What was done

Fixed greedy regex for cross-platform path normalization.
Lazy ._? matched up to first Z-ai-platform/ on Linux (two occurrences),
while greedy ._ matches up to last occurrence, giving same result on both OS.

### Result

CI Verify ID Graph workflow passes on both Windows and Linux.

### Follow-up

None.
```

---

## 6. Anti-patterns

- [FAIL] Editing previous entries instead of appending
- [FAIL] Skipping entries for "small" changes
- [FAIL] Using emoji instead of text tags
- [FAIL] Writing entries in different languages within same file
