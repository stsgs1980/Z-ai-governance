# Z-ai-platform

Orchestrator for the Z-ai ecosystem — pins two submodules (standards, guard) and contains 14 skills as a monorepo. Enforces cross-repo ID-graph integrity in CI.

[![Status: LIVE](https://img.shields.io/badge/Status-LIVE-brightgreen.svg?style=flat-square)]()
[![License: Private](https://img.shields.io/badge/License-Private-red.svg?style=flat-square)]()
[![CI: Verify ID Graph](https://img.shields.io/github/actions/workflow/status/stsgs1980/Z-ai-platform/verify-id-graph.yml?style=flat-square&label=CI)](https://github.com/stsgs1980/Z-ai-platform/actions)

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

- **3-layer architecture** — platform (L0) + standards (L1) + guard (L2) with 14 inline skills (L3)
- **Cross-repo ID graph** — 55 IDs with 103 Related: edges and 2 Aligned_with: edges, verified by 13/13 HARD checks
- **Governance enforcement** — 15/17 rules enforced via pre-commit hooks (8 scripts) + CI (4 scripts + 5 verifiers)
- **Nightly + push CI** — `verify-standards.js`, `verify-id-graph.js`, `verify-skills.js`, and snapshot compare run automatically
- **Pre-commit hooks** — Husky runs guard PROC checks + governance scripts + verify-standards/id-graph/skills + lint-staged on every commit (auto-installed via `npm install`)
- **Bootstrap script** — one command restores all 14 custom skills into any fresh Z.ai sandbox session

## Tech Stack

- **Language** - JavaScript (Node.js 20, ESLint 9 flat config)
- **CI** - GitHub Actions (verify-id-graph.yml, e2e-verifiers.yml)
- **Submodules** - git submodules for standards, guard (skills are inline monorepo)
- **Verification** - Custom Node.js scripts (verify-standards.js, verify-id-graph.js, verify-skills.js)

## Getting Started

### Prerequisites

- Node.js 20+
- Git with submodule support
- (For CI) SSH deploy key with read access to standards and guard submodule repos

### Installation

```bash
git clone --recurse-submodules https://github.com/stsgs1980/Z-ai-platform.git
cd Z-ai-platform
```

### Run

```bash
# Verify the ID graph locally
node standards/scripts/verify-standards.js
node standards/scripts/verify-id-graph.js

# Pre-commit hooks install automatically via npm install (Husky)
# To verify they are active:
git config --get core.hooksPath   # should print .husky/_

# Bootstrap skills into a Z.ai sandbox
bash <(curl -fsSL https://raw.githubusercontent.com/stsgs1980/Z-ai-platform/main/bootstrap.sh)
```

## Sandbox Workflow

### Fresh Session (after sandbox restart)

```bash
# 1. Clone with submodules
cd /home/z/my-project
git clone --recurse-submodules https://github.com/stsgs1980/Z-ai-platform.git

# 2. Set git config for sandbox
cd /home/z/my-project/Z-ai-platform
git config core.fileMode false
git submodule foreach --recursive 'git config core.fileMode false'

# 3. Install dependencies (auto-enables Husky hooks)
npm install

# 4. Verify everything works
ls .husky/                          # Should show: pre-commit pre-push commit-msg
git config core.hooksPath           # Should show: .husky/_
node standards/scripts/verify-standards.js    # Should show: 15/15 PASS
node standards/scripts/verify-id-graph.js     # Should show: 13/13 HARD PASS
```

### What Runs Automatically

| When              | What                                                                | Where          |
| ----------------- | ------------------------------------------------------------------- | -------------- |
| `git commit`      | Pre-commit hooks (8 governance scripts + 4 verifiers + lint-staged) | Local          |
| `git push`        | CI workflow (governance checks + verifiers + graph generation)      | GitHub Actions |
| Nightly 03:00 UTC | CI workflow (same as push)                                          | GitHub Actions |

### Pre-commit Hook Chain

```
Group 0 (HARD): 8 governance scripts
  check-no-bypass.sh       (INTEGRITY-011: no hook tampering)
  check-commit-checklist.sh (COMMIT-014: emoji, large files)
  check-version-bump.sh    (VERSION-013: version via ahg.sh)
  check-read-before-write.sh (READ-003: read before write)
  check-no-loops.sh        (LOOPS-005: loop detection)
  check-ahg-integrity.sh   (ARCH-016/017: submodule immutability)
  check-sandbox-env.sh     (ENV-008: sandbox verification)
  check-session-start.sh   (AGENT-009: session start protocol)

Group 1 (HARD): co-change + worklog
Group 2 (HARD): verify-standards.js + verify-id-graph.js + verify-skills.js
Group 3 (SOFT): line-count-check.sh
Group 4:        lint-staged (eslint + prettier)
```

### Troubleshooting

| Problem                      | Fix                                                                                               |
| ---------------------------- | ------------------------------------------------------------------------------------------------- |
| Hooks not working            | `npm install` or `git config core.hooksPath .husky/_`                                             |
| `core.fileMode` noise        | `git config core.fileMode false`                                                                  |
| Snapshot mismatch            | `node verify-id-graph.js --update-snapshot --compare=standards/_snapshots/id-graph-baseline.json` |
| `check-sandbox-env.sh` fails | Normal — sandbox manages dev server via `.zscripts/dev.sh`                                        |
| Skills not found             | Run `bootstrap.sh` to symlink skills into sandbox                                                 |

## Architecture

The platform uses a 3-layer repository architecture with an inline skills monorepo. Standards (L1) and guard (L2) are submodules that evolve independently. Skills (L3) live directly in this repo for easier development and iteration. The ID graph (G01-G15) enforces that changes in one layer do not silently break references in another. See `standards/standards/META-001-id-registry.md` for the full ID catalogue and layer matrix.

## Project Structure

- `standards/` - Z-ai-standards submodule (L1): STD-* files, verifier scripts, snapshots
- `guard/` - Z-ai-guard submodule (L2): RULE-* rules, procedures, tools
- `skills/` - Monorepo (L3): 14 skill directories with ZAI-* IDs
- `.github/workflows/` - CI workflows (verify-id-graph.yml, e2e-verifiers.yml)
- `eslint-rules/` - Custom ESLint rules for STD-DOC-003 compliance
- `eslint-processors/` - Custom markdown processor for code-snippet linting
- `docs/` - Generated ID-graph diagrams and session documentation

## Scripts

| Script                                             | Description                                          |
| -------------------------------------------------- | ---------------------------------------------------- |
| `node standards/scripts/verify-standards.js`       | Content-level invariants (V04-V11)                   |
| `node standards/scripts/verify-id-graph.js`        | Cross-repo ID-graph invariants (G01-G15)             |
| `node standards/scripts/verify-skills.js --strict` | Skills-side format verifier (S01-S09)                |
| `bash standards/scripts/graph-deps.sh`             | Render ID dependency graph (dot/svg/png)             |
| `npm install`                                      | Install deps + auto-enable Husky pre-commit hooks    |
| `./bootstrap.sh`                                   | One-command skill restore for fresh sandbox sessions |

## CI Behavior

The `verify-id-graph.yml` workflow triggers on push to `main`, pull requests, nightly at 03:00 UTC, and manual dispatch. It runs four verification steps in sequence: `verify-standards.js`, `verify-id-graph.js`, snapshot compare against the committed baseline, and `verify-skills.js --strict`. All must pass for the workflow to succeed. On failure, verifier output is uploaded as an artifact (7-day retention) and a comment is posted on the PR. The ID graph (dot/svg/png) is always uploaded as a 30-day artifact for review.

## Agent Rules

Any AI agent working on this project MUST read and follow `AGENT_RULES.md` before performing any operations.

## License

Private. See individual submodules for any additional terms.
