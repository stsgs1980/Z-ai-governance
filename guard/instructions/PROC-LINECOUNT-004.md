---
id: PROC-LINECOUNT-004
title: Line count check (anti-monolith enforcement)
version: 1.1
level: [C]
status: ACTIVE
implements: RULE-MONOLITH-012
calls: [TOOL-VERIFY-002, TOOL-VERIFY-004, TOOL-VERIFY-005, TOOL-VERIFY-007]
owning-standard: STD-META-001 v2.0.4
last-updated: 2026-07-07
---

# PROC-LINECOUNT-004: Line count check (anti-monolith enforcement)

> ID: PROC-LINECOUNT-004
> Version: 1.1
> Level: **[C] Critical**
> Last Updated: 2026-07-07
> Related: RULE-MONOLITH-012 (anti-monolith — this procedure implements it), STD-META-001 (ID system, §4.18 canonical matrix)

> **Status:** ACTIVE. File `guard/scripts/line-count-check.sh` exists.
> Implements RULE-MONOLITH-012 (anti-monolith, file size by category).
> Matrix source: STD-META-001 §4.18.1 (canonical).

## When this procedure fires

Pre-commit hook (HARD for source code, SOFT for .md). Three verifiers run:

1. **TOOL-VERIFY-007** `verify-source-line-count.cjs` — source code and test caps
   (HARD, blocks commit)
2. **TOOL-VERIFY-002** `verify-standards.js` — V11 .md cap (HARD, already in
   Group 2 of pre-commit)
3. **TOOL-VERIFY-005** `verify-skills.js` — S10a/b/c skill file caps (HARD,
   already in Group 2 of pre-commit)

## What it checks

| Verifier | Category | Hard cap | Soft cap | Pre-commit |
|---|---|---|---|---|
| verify-source-line-count.cjs | Source (.ts/.tsx/.js/.jsx/.py/.sh/.css) | 250 | 150 | HARD |
| verify-source-line-count.cjs | Tests (.test.*/.spec.*) | 400 | 250 | HARD |
| verify-standards.js V11 | standards/ + docs/sandbox/ + templates/ .md | 1000 | - | HARD (Group 2) |
| verify-skills.js S10a | skills/*/SKILL.md | 800 | - | HARD (Group 2) |
| verify-skills.js S10b | skills/*/CONTRACT.md | 500 | - | HARD (Group 2) |
| verify-skills.js S10c | skills/*/README.md | 400 | - | HARD (Group 2) |
| Config (.json/.yml/.toml/.ini) | exempt | - | - | - |

### Exclusions (source code only)

- `node_modules/`, `.next/`, `dist/`, `build/`, `.cache/`, `.turbo/`, `.vercel/`
- `src/components/ui/` (shadcn/ui — third-party, not our code)
- `Z-ai-governance/` (historical artifact exclusion)
- `.git/`, `coverage/`

## Inputs

- `--soft` (verify-source-line-count.cjs): warn-only, exit 0 even on hard violations
- `--json` (verify-source-line-count.cjs): JSON output for CI
- `--root=<path>` (verify-source-line-count.cjs): override repository root
- `--hard` (line-count-check.sh): hard fail on any offender

## Outputs

- Stdout: per-category pass/fail + summary
- Exit 0: PASS or SOFT-WARN
- Exit 1: FAIL (hard cap exceeded in hard mode)

## Calls

- **TOOL-VERIFY-007** (`verify-source-line-count.cjs`) — source + test file caps (v1.1)
- **TOOL-VERIFY-002** (`verify-standards.js`) — V11 .md cap enforcement
- **TOOL-VERIFY-005** (`verify-skills.js`) — S10a/b/c skill file caps
- **TOOL-VERIFY-004** (`verify-id-graph.js`) — structural companion (not size-related)

## Integration with pre-commit hook

```bash
# .husky/pre-commit Group 3 (HARD)
VERIFY_SRC_LINECOUNT="scripts/verify-source-line-count.cjs"
if command -v node >/dev/null 2>&1 && [ -f "$VERIFY_SRC_LINECOUNT" ]; then
  if ! node "$VERIFY_SRC_LINECOUNT" --root="$REPO_ROOT"; then
    echo "FAIL: source file exceeds hard cap. Split before commit."
    exit 1
  fi
fi
```

## Relationship to other procedures

| Procedure | Relationship |
|---|---|
| PROC-SETUP-001 | Sets up the guard workspace this procedure runs in |
| PROC-COCHANGE-003 | Companion pre-commit check (docs sync, not file size) |

## Change history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-06-22 | Initial implementation. Delegated to verify-standards.js V11 + verify-skills.js S10a/b/c. |
| 1.1 | 2026-07-07 | Added TOOL-VERIFY-007 (verify-source-line-count.cjs): source code 250-line and test 400-line HARD caps. Pre-commit Group 3 upgraded from SOFT to HARD for source files. Closes the gap where .ts/.py/.sh files were completely unverified. |