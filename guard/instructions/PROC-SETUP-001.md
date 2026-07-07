---
id: PROC-SETUP-001
title: Project installer procedure
version: 2.0
level: [C]
status: ACTIVE
implements: null
calls: []
owning-standard: STD-META-001 v2.0.4
last-updated: 2026-06-22
---

# PROC-SETUP-001: Project installer procedure

> ID: PROC-SETUP-001
> Version: 2.0
> Level: **[C] Critical**
> Last Updated: 2026-06-22
> Related: STD-META-001 (ID system), RULE-ENV-008 (sandbox verification — setup must verify)

> **Status:** ACTIVE. Implemented by `guard/scripts/setup-001.sh`.
> Three platform-side procedures (PROC-PLATFORM-005/006/007) were retired
> 2026-06-19 because `bootstrap.sh` covers install + update + restore as a
> single entry point. This procedure remains planned for guard-side
> installation steps that bootstrap.sh does not cover.

## When this procedure fires

Triggered manually by an agent or operator when initializing a new
Z-ai-guard workspace. NOT called by `bootstrap.sh` (which is the
platform-side installer and supersedes the retired PROC-PLATFORM-005).

Typical trigger:

```bash
bash guard/scripts/setup-001.sh
```

## What it does (planned scope)

1. Verify `guard/rules/INDEX.md` is present and parses (17 RULE entries)
2. Verify `guard/registry.json` is up to date (regenerate if stale)
3. Create `guard/instructions/` if missing
4. Create `guard/scripts/` if missing
5. Create `guard/tools/` if missing (for future TOOL-VERIFY-001, TOOL-BUMP-005)
6. Print onboarding summary referencing AGENT_RULES.md §1

## Inputs

- None required. Optional `--force` to overwrite existing dirs.

## Outputs

- Stdout: human-readable progress + summary
- Exit 0: success
- Exit 1: setup failed (missing prerequisites, permission denied, etc.)

## Calls

None. (When TOOL-VERIFY-001 is built, this procedure will call it for
post-install verification.)

## Relationship to other procedures

| Procedure          | Relationship                                                  |
| ------------------ | ------------------------------------------------------------- |
| PROC-UPDATE-002    | Runs after this one to bring an existing workspace up to date |
| PROC-COCHANGE-003  | Pre-commit check, not part of setup                           |
| PROC-LINECOUNT-004 | Pre-commit check, not part of setup                           |

## Open questions (resolve when implementing)

- Should this procedure create symlinks from `guard/scripts/*.sh` into
  `.git/hooks/`? Or should that be a separate `install-hooks.sh`?
  (Platform already has `install-hooks.sh` — coordination needed.)
- Should this procedure regenerate `registry.json` automatically, or
  require explicit `--regenerate` flag?

## Change history

| Version | Date       | Change                                                                  |
| ------- | ---------- | ----------------------------------------------------------------------- |
| 2.0     | 2026-06-19 | Re-scoped after PROC-PLATFORM-005/006/007 retirement. Guard-only scope. |
| 1.0     | 2026-05    | Initial registration in META-001 §4.14.                                 |
