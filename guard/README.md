# Guard

Enforcement layer for the Z-ai ecosystem: rules (what agents must do), procedures (what runs when a rule fires), and tools (the scripts rules call). All 17 RULE, 4 PROC, and 2 TOOL are ACTIVE with M003 + M004 migrations complete.

![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Status](#status)
- [Project Structure](#project-structure)
- [Migration Plan](#migration-plan)
- [Procedures](#procedures)
- [Tools](#tools)
- [Known Issues](#known-issues)
- [License](#license)

## Features

- 17 enforcement rules (RULE-ANSWER-001 through 017) covering agent behavior, documentation, integrity, and work structure
- 4 active procedures with executable scripts: SETUP-001, UPDATE-002, COCHANGE-003, LINECOUNT-004
- 2 active tools: verify-docs.sh (integrity checks) and bump.sh (version management)
- 5-group pre-commit hook: Group 0 (integrity + checklist, HARD), Group 1 (co-change + worklog, HARD), Group 2 (standards verify-*.js, HARD), Group 3 (line-count, SOFT), Group 4 (lint-staged eslint)
- Auto-generated registry.json tracking all 23 IDs across RULE, PROC, and TOOL namespaces
- Cross-reference verification composing platform verifiers with guard-specific checks
- Complete M002/M003/M004 migration from legacy AHG IDs to monolith naming convention

## Tech Stack

- **Scripts** - Bash
- **Tooling** - Python (build-registry.py)
- **Verification** - Shell (pre-commit hooks)

## Getting Started

### Prerequisites

- Git
- Bash
- Python 3

### Installation

This directory is part of the [Z-ai-governance](https://github.com/stsgs1980/Z-ai-governance) repository. Clone that repo to get guard/:

```bash
git clone https://github.com/stsgs1980/Z-ai-governance.git
cd Z-ai-governance
```

### Run

```bash
# Verify document integrity
bash tools/verify-docs.sh

# Rebuild the ID registry
python scripts/build-registry.py --output registry.json
```

## Status

| Component     | Count | Status                                                                                  |
| ------------- | ----- | --------------------------------------------------------------------------------------- |
| RULE-*        | 17/17 | Migrated (M002). Files in `rules/`, index in `rules/INDEX.md`                           |
| PROC-*        | 4/4   | COMPLETE (M003). All 4 PROC ACTIVE: SETUP-001, UPDATE-002, COCHANGE-003, LINECOUNT-004  |
| TOOL-*        | 2/2   | COMPLETE (M004). TOOL-VERIFY-001 + TOOL-BUMP-005 ACTIVE                                 |
| instructions/ | 4     | COMPLETE. 4 PROC-*.md spec files, all marked ACTIVE                                     |
| scripts/      | 18    | 18 shell scripts (13 check-*, 3 PROC, 2 setup) |
| tools/        | 2     | verify-docs.sh (TOOL-VERIFY-001), bump.sh (TOOL-BUMP-005)                               |
| registry.json | 1     | Auto-generated. 23 IDs (17 RULE + 4 PROC + 2 TOOL)                                      |

Pre-commit hook runs 5 groups managed by .husky/pre-commit:
  - Group 0: guard/scripts/check-*.sh (13 integrity + checklist + env scripts, HARD)
  - Group 1: co-change-check.sh + worklog-check.sh (HARD)
  - Group 2: verify-standards.js, verify-id-graph.js, verify-skills.js (HARD)
  - Group 3: line-count-check.sh (SOFT, advisory)
  - Group 4: lint-staged -> eslint (emoji, unicode, code-block-lang, HARD)

Emoji/Unicode enforcement was unified: 3 duplicate implementations removed.
Canonical source: root eslint-rules/unicode-policy.js via lint-staged (STD-DOC-003).

## Project Structure

- `rules/` - 15 RULE- rule files + INDEX.md catalog
  - 15 active rules (RULE-ANSWER-001 through RULE-DOC-015) covering: answer before act, worklog, read before write, commit structure, no loops, honest reporting, work structure, sandbox verification, session start, documentation sync, integrity protection, anti-monolith, version bumping, pre-commit checklist, no Unicode graphics
- `instructions/` - 4 PROC-*.md spec files (SETUP-001, UPDATE-002, COCHANGE-003, LINECOUNT-004)
- `scripts/` - 18 shell scripts: 13 check-*.sh (integrity, commit, version, env), co-change-check.sh, worklog-check.sh, line-count-check.sh, setup-001.sh, update-002.sh; plus build-registry.py
- `tools/` - verify-docs.sh (TOOL-VERIFY-001), bump.sh (TOOL-BUMP-005)
- `registry.json` - Auto-generated registry of enforcement IDs (RULE/PROC/TOOL)

## Migration Plan

Per STD-META-001 §11.2:

### M002 - RULE-001..RULE-015 to RULE-ANSWER-001..RULE-DOC-015 (COMPLETE)

| Legacy   | New ID             | Rule Name                    |
| -------- | ------------------ | ---------------------------- |
| RULE-001 | RULE-ANSWER-001    | Answer Before Act            |
| RULE-002 | RULE-WORKLOG-002   | Worklog before/after         |
| RULE-003 | RULE-READ-003      | Read before write            |
| RULE-004 | RULE-COMMIT-004    | One logical block per commit |
| RULE-005 | RULE-LOOPS-005     | No loops                     |
| RULE-006 | RULE-HONEST-006    | Honest reporting             |
| RULE-007 | RULE-STRUCT-007    | Work structure               |
| RULE-008 | RULE-ENV-008       | Sandbox verification         |
| RULE-009 | RULE-AGENT-009     | Session start protocol       |
| RULE-010 | RULE-DOC-010       | Documentation sync           |
| RULE-011 | RULE-INTEGRITY-011 | Integrity protection         |
| RULE-012 | RULE-MONOLITH-012  | Anti-monolith (250 lines)    |
| RULE-013 | RULE-VERSION-013   | Use verify-docs bump         |
| RULE-014 | RULE-COMMIT-014    | Pre-commit checklist         |
| RULE-015 | RULE-DOC-015       | No Unicode graphics          |

### M003 - AHG PROC-XXX to PROC-MONOLITH-XXX (COMPLETE 2026-06-25)

| ID                 | File                        | Version | Level | Implements        |
| ------------------ | --------------------------- | ------- | ----- | ----------------- |
| PROC-SETUP-001     | scripts/setup-001.sh        | 2.0     | [C]   | RULE-ENV-008      |
| PROC-UPDATE-002    | scripts/update-002.sh       | 2.1     | [C]   | RULE-VERSION-013  |
| PROC-COCHANGE-003  | scripts/co-change-check.sh  | 1.0     | [C]   | RULE-DOC-010      |
| PROC-LINECOUNT-004 | scripts/line-count-check.sh | 1.0     | [C]   | RULE-MONOLITH-012 |

### M004 - AHG TOOL-XXX to TOOL-MONOLITH-XXX (COMPLETE 2026-06-25)

| ID              | File                 | Version | Level | Used by rules            |
| --------------- | -------------------- | ------- | ----- | ------------------------ |
| TOOL-VERIFY-001 | tools/verify-docs.sh | 2.1     | [C]   | RULE-AGENT-009, 010, 014 |
| TOOL-BUMP-005   | tools/bump.sh        | 2.1     | [C]   | RULE-VERSION-013         |

## Procedures

| ID                 | File                        | Version | Level | Status        |
| ------------------ | --------------------------- | ------- | ----- | ------------- |
| PROC-SETUP-001     | scripts/setup-001.sh        | 2.0     | [C]   | ACTIVE (M003) |
| PROC-UPDATE-002    | scripts/update-002.sh       | 2.1     | [C]   | ACTIVE (M003) |
| PROC-COCHANGE-003  | scripts/co-change-check.sh  | 1.0     | [C]   | ACTIVE (M003) |
| PROC-LINECOUNT-004 | scripts/line-count-check.sh | 1.0     | [C]   | ACTIVE (M003) |

## Tools

| ID              | File                 | Version | Level | Status        |
| --------------- | -------------------- | ------- | ----- | ------------- |
| TOOL-VERIFY-001 | tools/verify-docs.sh | 2.1     | [C]   | ACTIVE (M004) |
| TOOL-BUMP-005   | tools/bump.sh        | 2.1     | [C]   | ACTIVE (M004) |

TOOL-VERIFY-002 (`verify-standards.js`), TOOL-VERIFY-004 (`verify-id-graph.js`), and TOOL-CHECKUPDATES-006 (`check-updates.sh`) live in **standards/scripts/** and are already implemented and active. TOOL-VERIFY-003 was retired 2026-06-18.

## Known Issues

### Phantom IDs in STD-META-001

STD-META-001 lists PROC and TOOL IDs with status ACTIVE pointing at `guard/...` paths. Until M003/M004 land formally, those rows should read `ACTIVE (planned)` or `PENDING migration`.

### Dangling Related: edges in 6 rules

Six rules reference IDs that do not match the ID format (`<PREFIX>-<DOMAIN>-<NNN>` requires 3 digits) and are silently dropped by `verify-id-graph.js`:

| Rule               | Dangling reference        | Should resolve to    |
| ------------------ | ------------------------- | -------------------- |
| RULE-AGENT-009     | `TOOL-MONOLITH-VERIFY`    | `TOOL-VERIFY-001`    |
| RULE-DOC-010       | `TOOL-MONOLITH-VERIFY`    | `TOOL-VERIFY-001`    |
| RULE-INTEGRITY-011 | `PROC-MONOLITH-SETUP`     | `PROC-SETUP-001`     |
| RULE-MONOLITH-012  | `PROC-MONOLITH-LINECOUNT` | `PROC-LINECOUNT-004` |
| RULE-VERSION-013   | `TOOL-MONOLITH-BUMP`      | `TOOL-BUMP-005`      |
| RULE-COMMIT-014    | `TOOL-MONOLITH-VERIFY`    | `TOOL-VERIFY-001`    |

The ID-graph verifier reports 13/13 HARD PASS on the graph that survived filtering, not on the rules as written. Fixing requires landing M003/M004 with proper IDs and updating the rule Related: lists.

Note: These issues were documented during the legacy multi-repo era and may no longer apply.

## License

MIT
