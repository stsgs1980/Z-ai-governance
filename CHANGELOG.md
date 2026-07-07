# CHANGELOG

## Changelog for Z-ai-governance

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/) and this project adheres to [Semantic Versioning](https://semver.org/).

---

## [1.3.0] - 2026-07-07

### Changed

- **Repository structure**: flat repository with guard/, standards/, skills/ as regular directories
- **Governance unification**: 14 duplicate implementations removed
  (6 emoji, 4 line-count, 4 worklog) without loss of functionality
- **Single source of truth**: `.zai/config.json` now the authoritative
  threshold config for all governance checks
- **`.zai/verify`**: rewritten as orchestrator that delegates to canonical
  implementations in guard/scripts/ and standards/scripts/
- **`.zai/setup.sh`**: rewritten with 4-phase approach, does not modify
  pre-commit hooks
- **Pre-commit hook**: all 13 check-*.sh scripts in Group 0
  (was 3 in comment block, now matches actual execution)

### Removed

- **`.zai/lib/check-emoji.sh`**: duplicate of eslint-rules/ enforcement
- **`.zai/lib/check-line-count.sh`**: duplicate of guard/scripts/line-count-check.sh
- **`guard/eslint-rules/`** and **`guard/eslint.config.js`**: dead code, never called
- **`standards/eslint-rules/`** and **`standards/eslint.config.js`**: dead code, never called

### Fixed

- **`check-commit-checklist.sh`**: removed emoji (Check 1) and worklog
  (Check 3) -- now only checks large files and honesty
- **`check-version-bump.sh`**: fixed bump.sh path, removed skills/package.json
- **Emoji check**: skips when node_modules/eslint not installed
- **All documents**: updated to reflect flat repository structure
  (README, AGENT_RULES, CONTRIBUTING, HANDBOOK, guard/README, standards/README)

### Statistics

| Metric | 1.2.0 | 1.3.0 | Delta |
| --- | --- | --- | --- |
| Duplicate implementations | 14 | 0 | -14 |
| Guard scripts | 18 | 18 | = |
| Governance check sources | 8 | 3 | -5 |

---

## [1.2.0] - 2026-07-06

### Added

- **3 new governance scripts** in `guard/scripts/`:
  - `check-work-cycle.sh` (RULE-STRUCT-007): detects commits without worklog touch (2+ consecutive = violation)
  - `check-snapshot-sync.sh`: catches ID graph snapshot drift before push
- **1 new skill**: `zai-answer-before-act` (ZAI-DEV-006) — RULE ZERO for RULE-ANSWER-001
  - Decision algorithm: question → ANSWER, task → EXECUTE, unsure → ASK
  - 8 worked examples, 8 test cases in `evals/evals.json`, fact-check report
- **AGENT_RULES.md §0**: RULE ZERO at top of file — answer questions, don't act unsolicited
- **skills/INDEX.md**: new catalog file with 14 skills, IDs, versions, loading order
- **Sandbox Workflow section** in `README.md` — bootstrap + troubleshooting
- **Worklog cycle enforcement** via pre-commit hook (last 5 commits must have worklog touch)
- **Snapshot drift detection** via pre-commit + CI (block commits when baseline stale)

### Changed

- **Enforcement coverage**: 15/17 → 16/17 rules enforced via pre-commit (was 2/17 at 1.1.1)
- **Soft warnings**: 34 → 0 (all W04, W08, W13, S06 resolved)
- **Verifier snapshot**: 53 IDs, 97 edges (was 42 IDs, 92 edges at 1.1.1)
- **`verify-skills.js`**: added `DEVTOOLS` to valid skill domains (for sandbox-variant zai-skill-creator)
- **Pre-commit hook**: now runs 10 scripts (was 8): +check-work-cycle, +check-snapshot-sync
- **CI workflow**: governance enforcement step now includes all 6 scripts
- **Worklog**: compressed 2026-07-02 to 2026-07-05 entries (1125 → 255 lines, -77%)

### Removed

- **`STD-ERR-002`** (`ERR-002-error-recovery.md`): dead standard, no RULE/ZAI referenced it
  - Recovery strategies folded into `ERR-001 §4-§5`
- **`STD-TEST-001`** (`TEST-001-testing.md`): dead standard, no RULE/ZAI referenced it
  - ARCH-002 install order: 21 → 19 standards
- **Legacy `Aligned_with` references** in STD-SKILL-001 (to SUPERSEDED ZAI-META-001/002)
- **8 soft warnings** in W04 (rogue skills) and W08 (unreciprocated Aligned_with) — all resolved

### Fixed

- **`check-commit-checklist.sh`**: WORKLOG-002 false positive — now only requires worklog.md staged when it has actual changes
- **`check-work-cycle.sh`**: 10-commit lookback caught historical drift; reduced to 5 commits
- **`check-ahg-integrity.sh`**: skip `core.fileMode` check on CI (only enforce in sandbox)
- **`check-session-start.sh`**: unbound `RECENT_WORKLOG` variable crash on first run
- **`scripts/line-count-check.sh`**: CRLF line endings (was 119 CRLF chars) → LF
- **`verify-standards.js`**: V17 now accepts both `AGENT_RULES.md` and `AGENT-RULES.md` naming
- **Rogue skill frontmatter**: 4 skills (`zai-debugging`, `zai-md-std`, `zai-sandbox-rules`, `zai-skill-creator`) had empty `Related:` — all filled in

### Statistics

| Metric                      | 1.1.1 | 1.2.0 | Delta      |
| --------------------------- | ----- | ----- | ---------- |
| Rules enforced              | 2/17  | 16/17 | +14 (700%) |
| Soft warnings               | 36    | 0     | -36 (100%) |
| Standards (ARCH-002)        | 21    | 19    | -2 (dead)  |
| Verifier IDs                | 42    | 54    | +12        |
| Verifier edges              | 92    | 109   | +17        |
| Skills (ZAI-*)              | 11    | 14    | +3         |
| Governance scripts          | 5     | 10    | +5         |
| Sandbox tests (integration) | 17/20 | 20/20 | +3         |
| Sandbox tests (behavior)    | 8/10  | 10/10 | +2         |
| Unit tests (vitest)         | 33/33 | 33/33 | =          |
| Maturity score (out of 5)   | ~1.5  | ~2.0  | +0.5       |

### Breaking changes

None. All changes are additive or corrective.

---

## [1.1.1] - 2026-07-04

### Fixed

- `sandbox-integration-test.sh`: trailing slash from glob pattern `*/` defeated `[ -L ]` symlink check in Test 7 and Summary, causing false "0 symlinks" even when symlinks exist
- `vitest.config.ts`: prevent parent sandbox PostCSS config bleed (add `css.postcss.plugins: []`)
- `.zai/verifier-daemon.sh`: fix false [VIOLATION] logging — grep -q "FAIL" was matching summary line "FAIL: 0", changed to grep -q "\[FAIL\]"
- `.gitignore`: add `.zai/.verifier-daemon.pid` (was untracked, causing noise in git status)
- `skills/zai-project-clone/SKILL.md`: remove broken references to non-existent ZAI-DEV-002 and ZAI-DEV-003

### Added

- `AGENT_RULES.md`: language setting — all agent communication in Russian (Cyrillic), no emojis
- `SESSION-HANDOFF.md`: Sandbox Agent Limitations section documenting which commands sandbox agents block/allow
