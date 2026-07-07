---
id: PROC-UPDATE-002
title: Project update procedure
version: 2.1
level: [C]
status: ACTIVE
implements: null
calls: []
owning-standard: STD-META-001 v2.0.4
last-updated: 2026-06-22
---

# PROC-UPDATE-002: Project update procedure

> ID: PROC-UPDATE-002
> Version: 2.1
> Level: **[C] Critical**
> Last Updated: 2026-06-22
> Related: STD-META-001 (ID system), RULE-AGENT-009 (session start protocol — update runs at session start), PROC-SETUP-001 (setup runs before update)

> **Status:** ACTIVE. Implemented by `guard/scripts/update-002.sh`.
> Three platform-side procedures (PROC-PLATFORM-005/006/007) were retired
> 2026-06-19 because `bootstrap.sh` covers install + update + restore.
> This procedure remains planned for guard-side update steps.

## When this procedure fires

Triggered manually by an agent or operator when bringing an existing
Z-ai-guard workspace up to date after a `git pull` that updates guard/ files.

Typical trigger:

```bash
bash guard/scripts/update-002.sh
```

## What it does (planned scope)

1. Re-parse `guard/rules/INDEX.md` to detect new or retired RULE entries
2. Regenerate `guard/registry.json` if `guard/rules/INDEX.md` is newer
3. Diff new vs old registry, print summary of changes
4. Validate that all ACTIVE rules have corresponding files in `guard/rules/`
5. Run `verify-id-graph.js` to ensure new rules don't break the ID graph
6. Print onboarding summary referencing AGENT_RULES.md §1

## Inputs

- None required. Optional `--check-only` to perform diff without writing
  registry.json.

## Outputs

- Stdout: human-readable change summary + verification result
- Exit 0: success
- Exit 1: update failed (new rule missing file, ID-graph broken, etc.)

## Calls

- TOOL-VERIFY-004 (`verify-id-graph.js`) — to confirm ID-graph integrity
  after rule additions

## Relationship to other procedures

| Procedure          | Relationship                                               |
| ------------------ | ---------------------------------------------------------- |
| PROC-SETUP-001     | Runs first on a fresh workspace; this one runs after pulls |
| PROC-COCHANGE-003  | Pre-commit check, not part of update                       |
| PROC-LINECOUNT-004 | Pre-commit check, not part of update                       |

## Open questions (resolve when implementing)

- Should this procedure auto-commit `registry.json` if it changed, or
  leave that to the operator?
- Should it call `co-change-check.sh` after update to ensure the update
  itself didn't violate docs-sync?

## Change history

| Version | Date       | Change                                                |
| ------- | ---------- | ----------------------------------------------------- |
| 2.1     | 2026-06-19 | Re-scoped after PROC-PLATFORM-005/006/007 retirement. |
| 2.0     | 2026-06-18 | Initial scope alignment with META-001 v2.0.4.         |
| 1.0     | 2026-05    | Initial registration in META-001 §4.14.               |
