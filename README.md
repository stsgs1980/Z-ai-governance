# Z-ai-governance

Unified governance layer for the Z-ai ecosystem. Flat copy of Z-ai-governance
with deduplicated enforcement: guard rules, normative standards, and 14
skills in a single repository. No submodules.

[![Status: ACTIVE](https://img.shields.io/badge/Status-ACTIVE-brightgreen.svg?style=flat-square)]()
[![License: Private](https://img.shields.io/badge/License-Private-red.svg?style=flat-square)]()

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Sandbox Workflow](#sandbox-workflow)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Scripts](#scripts)
- [CI Behavior](#ci-behavior)
- [Agent Rules](#agent-rules)
- [License](#license)

## Features

- **Flat repository** -- guard, standards, and 14 skills in one repo (no submodules)
- **Cross-repo ID graph** -- 55 IDs with 103 Related: edges and 2 Aligned_with: edges, verified by 13/13 HARD checks
- **Governance enforcement** -- 13+ of 17 rules enforced via pre-commit hooks (13 check scripts + 2 PROC + 3 verifiers) + CI
- **Pre-commit hooks** -- Husky runs 5 groups on every commit (auto-installed via `npm install`):
  - Group 0: 13 guard integrity/checklist scripts (HARD)
  - Group 1: co-change + worklog (HARD)
  - Group 2: verify-standards.js + verify-id-graph.js + verify-skills.js (HARD)
  - Group 3: line-count-check (advisory)
  - Group 4: lint-staged (eslint + prettier)
- **Single source of truth** -- `.zai/config.json` for thresholds, canonical check implementations in guard/scripts/ and standards/scripts/
- **Deduplicated governance** -- 14 duplicate implementations removed (6 emoji, 4 line-count, 4 worklog) without loss of functionality

## Tech Stack

- **Language** - JavaScript (Node.js 20, ESLint 9 flat config)
- **Enforcement** - Bash scripts (guard/scripts/), Node.js verifiers (standards/scripts/)
- **Hooks** - Husky v9
- **CI** - GitHub Actions (verify-id-graph.yml, e2e-verifiers.yml)
- **Verification** - Custom Node.js scripts (verify-standards.js, verify-id-graph.js, verify-skills.js)

## Getting Started

### Prerequisites

- Node.js 20+
- Git

### Installation

```bash
git clone https://github.com/stsgs1980/Z-ai-governance.git
cd Z-ai-governance
npm install
```

### Run

```bash
# Verify the ID graph locally
node standards/scripts/verify-standards.js
node standards/scripts/verify-id-graph.js

# Run all governance checks
bash .zai/verify

# Pre-commit hooks install automatically via npm install (Husky)
# To verify they are active:
git config --get core.hooksPath   # should print .husky/_
```

## Sandbox Workflow

### Fresh Session (after sandbox restart)

```bash
# 1. Clone
cd /home/z/my-project
git clone https://github.com/stsgs1980/Z-ai-governance.git
cd Z-ai-governance

# 2. Set git config for sandbox
git config core.fileMode false

# 3. Install dependencies (auto-enables Husky hooks)
npm install

# 4. Verify everything works
ls .husky/                          # Should show: pre-commit pre-push commit-msg
git config core.hooksPath           # Should show: .husky/_
node standards/scripts/verify-standards.js    # Should show: PASS
node standards/scripts/verify-id-graph.js     # Should show: 13/13 HARD PASS
```

### What Runs Automatically

| When              | What                                                                   | Where          |
| ----------------- | ---------------------------------------------------------------------- | -------------- |
| `git commit`      | Pre-commit: 13 check scripts + 2 PROC + 3 verifiers + lint-staged      | Local          |
| `git push`        | CI workflow (governance checks + verifiers + graph generation)         | GitHub Actions |
| Nightly 03:00 UTC | CI workflow (same as push)                                             | GitHub Actions |

### Pre-commit Hook Chain

```
Group 0 (HARD): 13 guard integrity + checklist scripts
  check-no-bypass.sh         (RULE-INTEGRITY-011: no hook tampering)
  check-commit-checklist.sh  (RULE-COMMIT-014: large files, honesty)
  check-version-bump.sh      (RULE-VERSION-013: version via bump.sh)
  check-read-before-write.sh (RULE-READ-003: read before write)
  check-no-loops.sh          (RULE-LOOPS-005: loop detection)
  check-ahg-integrity.sh     (RULE-ARCH-016/017: directory integrity)
  check-sandbox-env.sh       (RULE-ENV-008: sandbox verification)
  check-session-start.sh     (RULE-AGENT-009: session start protocol)
  check-work-cycle.sh        (RULE-STRUCT-007: work structure cycle)
  check-snapshot-sync.sh     (ID graph snapshot drift detection)
  check-changelog-sync.sh    (CHANGELOG freshness)
  check-script-coverage.sh   (pre-commit vs CI coverage drift)
  check-crlf.sh              (LF line ending enforcement)

Group 1 (HARD): co-change + worklog
  co-change-check.sh    (RULE-DOC-010: code + docs sync)
  worklog-check.sh      (RULE-WORKLOG-002: worklog entry required)

Group 2 (HARD): verify-*.js verifiers
  verify-standards.js   (V01-V18: content-level invariants)
  verify-id-graph.js    (G01-G15: cross-repo ID-graph invariants)
  verify-skills.js      (S01-S09: skill format invariants)

Group 3 (SOFT): line-count advisory
  line-count-check.sh   (RULE-MONOLITH-012: per-category file-size caps)

Group 4: lint-staged (eslint + prettier)
  emoji, unicode, code-block-lang via eslint-rules/
```

### Troubleshooting

| Problem                      | Fix                                                                                               |
| ---------------------------- | ------------------------------------------------------------------------------------------------- |
| Hooks not working            | `npm install` or `git config core.hooksPath .husky/_`                                             |
| `core.fileMode` noise        | `git config core.fileMode false`                                                                  |
| Snapshot mismatch            | `node standards/scripts/verify-id-graph.js --update-snapshot --compare=standards/_snapshots/id-graph-baseline.json` |
| `check-sandbox-env.sh` fails | Normal -- sandbox manages dev server via `.zscripts/dev.sh`                                       |
| Skills not found             | Skills are inline in `skills/` directory                                                          |

## Architecture

The project uses a flat repository architecture. Standards, guard rules, and
skills are all directories in this repo (not submodules). The ID graph
(G01-G15) enforces that changes in one layer do not silently break
references in another. See `standards/standards/META-001-id-registry.md`
for the full ID catalogue and layer matrix.

**Governance architecture (single layer):**

- `guard/scripts/*.sh` -- integrity, commit, version, env, worklog (pre-commit Group 0-1, 3)
- `standards/scripts/verify-*.js` -- content, id-graph, skills (pre-commit Group 2)
- `eslint-rules/` -- emoji, unicode, code-block-lang (pre-commit Group 4 via lint-staged)
- `.zai/config.json` -- single source of truth for thresholds

**Canonical check implementations (no duplicates):**

| Check      | Canonical source                              | Delegated by         |
| ---------- | --------------------------------------------- | -------------------- |
| Emoji      | `eslint-rules/unicode-policy.js` (lint-staged) | `.zai/verify`       |
| Line-count | `guard/scripts/line-count-check.sh`           | `.zai/verify`       |
| Worklog    | `guard/scripts/worklog-check.sh`              | `.zai/lib/check-worklog.sh` |

## Project Structure

- `standards/` - Normative standards (L1): 19 STD-* files, verifier scripts, snapshots
- `guard/` - Enforcement layer (L2): 17 RULE-* rules, 4 PROC procedures, 2 TOOLS, 18 shell scripts
- `skills/` - Skills (L3): 14 skill directories with ZAI-* IDs (inline monorepo)
- `.github/workflows/` - CI workflows (verify-id-graph.yml, e2e-verifiers.yml)
- `eslint-rules/` - Custom ESLint rules for STD-DOC-003 compliance
- `eslint-processors/` - Custom markdown processor for code-snippet linting
- `.zai/` - Governance config, setup, verify orchestrator
- `.husky/` - Git hooks (pre-commit, commit-msg, pre-push)

## Scripts

| Script                                             | Description                                          |
| -------------------------------------------------- | ---------------------------------------------------- |
| `bash .zai/verify`                                  | Run all governance checks (orchestrator)             |
| `bash .zai/verify --check worklog`                  | Run a specific check                                 |
| `node standards/scripts/verify-standards.js`        | Content-level invariants (V01-V18)                   |
| `node standards/scripts/verify-id-graph.js`         | Cross-repo ID-graph invariants (G01-G15)             |
| `node standards/scripts/verify-skills.js --strict`  | Skills-side format verifier (S01-S09)                |
| `npm install`                                       | Install deps + auto-enable Husky pre-commit hooks    |

## CI Behavior

The `verify-id-graph.yml` workflow triggers on push to `main`, pull
requests, nightly at 03:00 UTC, and manual dispatch. It runs four
verification steps in sequence: `verify-standards.js`,
`verify-id-graph.js`, snapshot compare against the committed baseline,
and `verify-skills.js --strict`. All must pass for the workflow to
succeed. On failure, verifier output is uploaded as an artifact
(7-day retention) and a comment is posted on the PR. The ID graph
(dot/svg/png) is always uploaded as a 30-day artifact for review.

## Agent Rules

Any AI agent working on this project MUST read and follow
`AGENT_RULES.md` before performing any operations.

## License

Private.