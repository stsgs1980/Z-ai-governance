# CI and Testing — Z-ai-governance

> **NOTE (v1.3.0):** This document was written for the multi-repo submodule architecture. The repository is now a flat copy (Z-ai-governance) with no submodules. CI/CD references to submodule init, pointer bumps, and cross-repo workflows describe a setup that no longer exists. The testing methodology and verifier concepts remain valid.

> Source: Merge of two draft documents ("Полный CI/CD Pipeline" and
> "Уровни тестирования Z-ai-platform") plus an audit of 12 bugs in the
> drafts against the actual repo state on 2026-06-21.
> Owning standard: STD-META-001 (this is a project doc, not a standard).
> Last Updated: 2026-06-21

This document is the canonical reference for the CI pipeline and the
testing layer model of Z-ai-platform. It supersedes the two earlier
drafts (which contained 12 factual bugs against actual repo state —
see §11 for the audit table).

The 4-repo architecture is documented in `README.md` and
`CONTRIBUTING.md`. This document covers only the testing and CI layers.

---

## 1. Architecture overview

Z-ai-platform is an orchestrator repo with 3 submodules:

```text
Z-ai-platform/                  (orchestrator)
├── .github/workflows/          (CI pipelines)
├── .githooks/                  (pre-commit, commit-msg)
├── standards/                  (submodule: STD-* standards + verifiers)
│   └── scripts/
│       ├── verify-standards.js     (V01-V11, content-level invariants)
│       ├── verify-id-graph.js      (G01-G15, cross-repo ID graph)
│       ├── check-md.sh             (3-layer markdown compliance)
│       └── graph-deps.sh           (dot/svg graph generator)
├── guard/                      (submodule: RULE-*)
├── skills/                     (submodule: 36 skills + CONTRACT.md pilot)
│   └── skills/commit-work/
│       ├── CONTRACT.md             (5-tuple execution contract, Phase B)
│       └── scripts/run-contract.sh (callable runtime, dry-run / commit)
└── worklog.md                  (append-only session log)
```

Three verifier layers run at different times:

| Layer                               | When                                           | What                                                                                         | Blocks?                          |
| ----------------------------------- | ---------------------------------------------- | -------------------------------------------------------------------------------------------- | -------------------------------- |
| **L0 — pre-commit**                 | Every `git commit`                             | Worklog freshness (Phase 0), `verify-standards.js` (Phase 1), `verify-id-graph.js` (Phase 2) | YES (Phase 1+2) / WARN (Phase 0) |
| **L0.5 — commit-msg**               | Every `git commit` (after pre-commit)          | Conventional Commits format (RULE-COMMIT-004)                                                | YES                              |
| **L1 — commit-work contract**       | On demand (`run-contract.sh --commit '<msg>'`) | All L0 + L0.5 checks + creates the commit atomically                                         | YES                              |
| **L2 — GitHub Actions**             | Push to main, PR, nightly                      | Same as L0 + L0.5, plus graph/svg generation + PR comment on failure                         | YES (PR blocking)                |
| **L3 — skill validation**           | Manual                                         | `quick_validate.py` (only on `skill-creator` today)                                          | No (manual)                      |
| **L4 — bootstrap on clean sandbox** | Manual, recommended weekly                     | Full clone + bootstrap + verify                                                              | No (manual)                      |

---

## 2. L0 — pre-commit hook

### 2.1 What runs

The hook at `.githooks/pre-commit` (122 lines) runs in three phases:

| Phase   | Check                                          | Level                                                                                |
| ------- | ---------------------------------------------- | ------------------------------------------------------------------------------------ |
| Phase 0 | Worklog freshness: `find worklog.md -mmin -60` | WARN only (false positives common; commit may legitimately not need a worklog entry) |
| Phase 1 | `node standards/scripts/verify-standards.js`   | BLOCK (exit 1 on V01-V11 fail)                                                       |
| Phase 2 | `node standards/scripts/verify-id-graph.js`    | BLOCK (exit 1 on G01-G15 fail)                                                       |

Phase 1 verifies **content-level invariants** (V01-V11, currently 8
active checks after V11 was promoted from W11 soft warning on
2026-06-21):

- V04: All standards have frontmatter `ID:` field
- V05: All standards have `version:` field
- V06: All standards have `level:` field
- V07: STD-FE-001 §2 anti-monolith thresholds present
- V08: All 3-backtick code fences have a language tag
- V09: All `.md` files in `upload/` are English-only
- V10: STD-DOC-004 README_TEMPLATE has Badges guidance
- V11: No `.md` file in `standards/` + `docs/sandbox/` + `templates/` exceeds 1000 lines (HARD, since 2026-06-21 — was W11 soft warning)

Phase 2 verifies **cross-repo ID graph invariants** (G01-G15, 13 HARD
checks + 2 soft warnings). The 2 soft warnings (W01-W15 family) do NOT
block commits; they are reported but exit 0.

### 2.2 Installation

```bash
cd /home/z/my-project/Z-ai-platform
./install-hooks.sh
```None

This sets `core.hooksPath = .githooks` (git config, local to this
clone). The same script must be re-run after any fresh clone.

### 2.3 Recommended workflow

Run verifiers **before AND after** every change to `standards/`:

```bash
# Before edit (establish baseline)
node standards/scripts/verify-standards.js
node standards/scripts/verify-id-graph.js

# ... edit a standard ...

# After edit (catch regressions)
node standards/scripts/verify-standards.js
node standards/scripts/verify-id-graph.js
```

**Red flags:**

- Baseline PASS -> after edit FAIL: you broke something. Investigate.
- Baseline FAIL -> after edit PASS: you accidentally fixed something
  while editing. Investigate — the fix may be unintentional and revert
  on the next contributor.

Both scenarios are equally suspicious. Never commit on a FAIL.

### 2.4 Conventional Commits (commit-msg hook)

The hook at `.githooks/commit-msg` (131 lines) validates commit
message format per RULE-COMMIT-004 + STD-GIT-001 §1.1-1.4:

| Check | Pattern                             | Level |
| ----- | ----------------------------------- | ----- |
| G4    | Conventional Commits regex: `^(feat | fix   | docs | style | refactor | test | chore | build | ci  | perf | revert)(\(.+\))?!?: .+` | BLOCK |
| G5    | Subject line <=72 characters        | BLOCK |
| G6    | Body wrapped at 72 chars            | WARN  |

**Skipped automatically:** merge commits, revert commits, squash
commits, fixup commits — git generates these messages and they cannot
be made to conform.

---

## 3. L1 — commit-work contract runtime (Phase B)

The contract layer wraps L0 + L0.5 into a single callable command:

```bash
# Preview all checks without committing
skills/skills/commit-work/scripts/run-contract.sh --dry-run

# Validate message + create commit (atomic — commits only if 0 FAIL)
skills/skills/commit-work/scripts/run-contract.sh --commit 'feat(scope): description'

# Help
skills/skills/commit-work/scripts/run-contract.sh --help
```text

The runtime implements the 5-tuple contract from
`skills/skills/commit-work/CONTRACT.md`:

| Tuple element         | Implementation                                                                                          |
| --------------------- | ------------------------------------------------------------------------------------------------------- |
| **trigger**           | `git commit` event OR `run-contract.sh --commit` invocation                                             |
| **hook**              | `.githooks/pre-commit` (Phase 0+1+2) + `.githooks/commit-msg` (G4-G6)                                   |
| **guard-check**       | G1-G6 (worklog freshness, repo state, conventional commits, line length, body wrap, no merge conflicts) |
| **standard-check**    | S1=verify-standards.js V01-V11, S2=verify-id-graph.js G01-G15, S3=check-md.sh                           |
| **success-criterion** | Commit created; all guards PASS or WARN-only; 0 FAIL                                                    |

The contract layer is the **dogfood consumer** of Phase B. Every
commit on Z-ai-platform itself runs through it. The runtime logs to
stderr and exits non-zero on any FAIL.

---

## 4. L2 — GitHub Actions workflow

The workflow at `.github/workflows/verify-id-graph.yml` (250 lines)
runs on:

- Push to `main` (covers submodule pointer bumps)
- Pull request to `main`
- Nightly schedule: `0 3 * * *` UTC (= 06:00 Europe/Moscow)
- Manual `workflow_dispatch`

### 4.1 What it runs

1. **Checkout** with `fetch-depth: 0` (full history needed for graph
   generation).
2. **Submodule init** — `git submodule update --init --recursive`.
3. **Node.js 20** setup.
4. **verify-standards.js** — captured to `$GITHUB_STEP_SUMMARY` for
   the PR review UI. Exits non-zero on V01-V11 failure.
5. **verify-id-graph.js** — same. Exits non-zero on G01-G15 failure.
6. **Graphviz install** — apt first, conda-forge fallback (added
   2026-06-19 after apt-mirror degradation caused a 10m timeout).
7. **Puppeteer Chrome cache** — keyed by mermaid-cli + puppeteer-core
   versions. Saves ~7 minutes on cache hit.
8. **Mermaid CLI install** — `@mermaid-js/mermaid-cli` for `.mmd` ->
   `.svg` rendering.
9. **Graph generation** — `standards/scripts/graph-deps.sh` produces
   `docs/_graph/id-graph.{svg,png,dot}`.
10. **Diagram generation** — `standards/scripts/render-diagrams.sh`
    renders `.mmd` process diagrams to `.svg`.
11. **Artifact upload** — graph + diagrams, 30-day retention.
12. **Failure artifact** — verifier output, 7-day retention.
13. **PR comment** — on failure only, lists which verifier(s) failed
    and the local command to reproduce.

### 4.2 Concurrency control

```yaml
concurrency:
  group: verify-id-graph-${{ github.ref }}
  cancel-in-progress: true
```

A new push to the same ref cancels any in-progress run. Cancelled
runs are marked "cancelled", not "failure" — they do NOT block PR
merge.

### 4.3 Permissions

```yaml
permissions:
  contents: read
```text

The workflow has read-only content access by default. The PR comment
step uses the implicit `GITHUB_TOKEN` with `pull-requests: write`
inherited from the workflow's `permissions` block (GitHub Actions
auto-grants write to issues/PRs for `GITHUB_TOKEN` when the workflow
runs on a PR).

**Note:** if you add a step that needs to push commits, create
releases, or modify protected branches, you must explicitly add
`contents: write` or `packages: write` to the `permissions` block.

---

## 5. L3 — skill validation

### 5.1 What exists today

Only **1 of 36 skills** has a `scripts/quick_validate.py`: `skill-creator`.

```bash
# Validate a skill (only works if skill has quick_validate.py)
python skills/skills/skill-creator/scripts/quick_validate.py \
       skills/skills/<skill-name>
```

The other 35 skills have no callable validator. The Phase A1 catalog
(see `skills/docs/CATALOG.md` §5) records this gap.

### 5.2 What to do for skills without `quick_validate.py`

For now, manual smoke test:

```bash
# 1. SKILL.md is well-formed (has frontmatter, valid YAML)
head -10 skills/skills/<skill-name>/SKILL.md

# 2. Skill loads in runtime
# (in agent session) Skill(command="<skill-name>")

# 3. Optional: re-run catalog to confirm classification
python /home/z/my-project/scripts/catalog_skills.py
```text

Phase D1 (planned in O-017 cascade) will produce
`verify-skills.js` — a skills-side verifier analogous to
`verify-standards.js`. Until then, skill validation is manual.

---

## 6. L4 — bootstrap on clean sandbox

Recommended cadence: weekly, OR after any change to `bootstrap.sh`.

### 6.1 Test procedure

```bash
# 1. Clean sandbox (NEVER use the live working tree — use a tmp path)
SANDBOX="/tmp/Z-ai-platform-bootstrap-test-$(date +%s)"
mkdir -p "$SANDBOX"
cd "$SANDBOX"

# 2. Run bootstrap (clone + submodule init + symlink setup)
bash <(curl -fsSL https://raw.githubusercontent.com/stsgs1980/Z-ai-platform/main/bootstrap.sh)

# 3. Verify standards are present
ls "$SANDBOX/Z-ai-platform/standards/standards/" | wc -l   # expect ~20 files

# 4. Verify skills are linked (not broken symlinks)
find "$SANDBOX/skills" -type l ! -exec test -e {} \; -print | wc -l   # expect 0

# 5. Verify ID graph passes
node "$SANDBOX/Z-ai-platform/standards/scripts/verify-id-graph.js"

# 6. Cleanup
rm -rf "$SANDBOX"
```

### 6.2 What this tests

- Submodule recursive clone does not fail (network stability)
- Symlinks created correctly (not broken links)
- Backup mechanism works if a skill with same name already exists
- Verification scripts find all files in the new location

### 6.3 Critical safety note

**NEVER run `rm -rf /home/z/my-project/Z-ai-platform`** as a "clean
sandbox" step. That is the live working tree; you will lose
uncommitted changes. Always use `/tmp/...` with a timestamp suffix.
This is the same trap as `git reset --hard` wiping uncommitted work.

---

## 7. Migration resilience test

Recommended cadence: monthly, OR after any change to `MIGRATIONS.md`.

```bash
# 1. Confirm legacy IDs still resolve (migration window open)
node standards/scripts/verify-id-graph.js   # should PASS

# 2. Close a migration window (set end_date in the past)
#    Edit standards/MIGRATIONS.md — set the relevant entry's end_date
#    to a date in the past.

# 3. Re-run verifier
node standards/scripts/verify-id-graph.js
#    Legacy IDs from that migration should now FAIL (G05)

# 4. Revert MIGRATIONS.md change
git checkout standards/MIGRATIONS.md
```text

This verifies that migration deadlines are actually enforced, not
just documented.

---

## 8. Test cadence cheat sheet

| Event                                     | What to run                                                     |
| ----------------------------------------- | --------------------------------------------------------------- |
| Every `git commit`                        | L0 pre-commit + L0.5 commit-msg (automatic via `.githooks/`)    |
| After editing `standards/`                | `node standards/scripts/verify-standards.js` (before AND after) |
| After editing `guard/rules/` or `skills/` | `node standards/scripts/verify-id-graph.js`                     |
| Before `git push`                         | L1 `run-contract.sh --dry-run` (preview all checks)             |
| Every push to main / PR                   | L2 GitHub Actions (automatic)                                   |
| Weekly                                    | L4 bootstrap on clean sandbox                                   |
| Monthly                                   | L7 migration resilience test                                    |
| After `bootstrap.sh` edit                 | L4 immediately                                                  |
| After `MIGRATIONS.md` edit                | L7 immediately                                                  |

**The cardinal rule:** if `verify-id-graph.js` does not pass, do not
push. 13/13 HARD PASS is a gate, not a recommendation. One missed
cross-ref in production = downstream agents work with stale standards
and you will not know about it.

---

## 9. Recommended additions (not yet implemented)

### 9.1 Implementation priority matrix

| Test                                             | Priority | Owner      | Target  | Dependencies     |
| ------------------------------------------------ | -------- | ---------- | ------- | ---------------- |
| Snapshot test for `verify-id-graph.js`           | **P0**   | @tech-lead | Q3 2026 | Phase D1         |
| End-to-end test: modify standard -> verify -> CI | **P0**   | @devops    | Q3 2026 | Phase D2         |
| `verify-skills.js`                               | **P0**   | @backend   | Q3 2026 | Phase D1 (O-017) |
| Symlink integrity check in CI                    | **P1**   | @devops    | Q4 2026 | Phase D2         |
| `run-contract.sh` in CI                          | **P1**   | @devops    | Q4 2026 | Phase C          |
| `registry.json` consistency test                 | **P2**   | @backend   | Q1 2027 | Phase E          |
| Version-bump detection                           | **P2**   | @tech-lead | Q1 2027 | Phase D1         |
| `--help` flag for verifiers                      | **P2**   | @backend   | Q1 2027 | Phase D1         |

Priority semantics:

| Priority | Meaning                        | Action                            |
| -------- | ------------------------------ | --------------------------------- |
| **P0**   | Critical — blocks next release | Must be implemented before v2.5.0 |
| **P1**   | Important — Q4 2026            | Scheduled for Phase D2            |
| **P2**   | Nice to have — Q1 2027         | Roadmap backlog                   |

### 9.2 P0 — Critical (blocks v2.5.0 release)

> **Status as of 2026-06-21:** All three P0 items below are
> **IMPLEMENTED**. See per-item status badges. The remaining
> remediation work (flip `verify-skills.js` from soft-default to
> `--strict` mode) is tracked in §9.2.2 below.

#### 9.2.1 Snapshot test for `verify-id-graph.js` — IMPLEMENTED

**Status:** [OK] IMPLEMENTED in `verify-id-graph.js` v1.1.4 + CI step
in `.github/workflows/verify-id-graph.yml`.

**Why:** Without this, refactoring `verify-id-graph.js` risks silent
regressions. The graph structure is deterministic — same input must
produce same output. A snapshot test makes any change in the output
loud and reviewable.

**Implementation (shipped):**

- Added `--snapshot=<file>`, `--compare=<file>`, `--update-snapshot`
  flags to `verify-id-graph.js` (v1.1.4).
- Snapshot file format: same JSON structure as `--json` output, plus
  `snapshot_meta` block with `script_version` and `created_at`.
- Comparison is structural: summary block (exact match), checks block
  (id+status+description+details-as-sorted-set), warnings block
  (sorted set of `{code, message}` pairs).
- Baseline file: `standards/_snapshots/id-graph-baseline.json`
  (committed, 61 IDs / 115 edges / 2 warnings as of 2026-06-21).
- CI step added to `.github/workflows/verify-id-graph.yml` after the
  `verify-id-graph.js` run.
- Smoke-tested locally: self-compare PASS, modified baseline FAIL
  with 4-diff output, `--update-snapshot` round-trips.

**Workflow:**

```bash
# Create baseline (one-time, or after intentional graph change)
node standards/scripts/verify-id-graph.js --snapshot=standards/_snapshots/id-graph-baseline.json

# CI check (every push — automatic)
node standards/scripts/verify-id-graph.js --compare=standards/_snapshots/id-graph-baseline.json
# Exits 1 if current graph differs from baseline.

# Update baseline (after intentional change, reviewed in PR)
node standards/scripts/verify-id-graph.js --update-snapshot \
  --compare=standards/_snapshots/id-graph-baseline.json
```

**Acceptance:** CI fails if current graph differs from baseline
unless `--update-snapshot` is explicitly passed (and the diff is
reviewed in the PR).

#### 9.2.2 `verify-skills.js` — IMPLEMENTED + REMEDIATED (`--strict` since 2026-06-21)

**Status:** [OK] IMPLEMENTED in `standards/scripts/verify-skills.js`
v1.0.0 + Phase 3 in `.githooks/pre-commit` (HARD, `--strict`) + CI
step in `.github/workflows/verify-id-graph.yml` (HARD, `--strict`).
**All 15 pre-existing violations closed** in the same patch that
clarified STD-SKILL-001 §3.3 (name must match folder name exactly,
including `_sts` suffix) and §10.1 V11c (STS-suffix rule is
author+folder driven, not folder-only).

**Why:** 35 of 36 skills had no validator. `SKILL.md` files could
have broken frontmatter, invalid `Related:` edges, or contract
violations without any automated check. The only existing validator
(`skill-creator/scripts/quick_validate.py`) was skill-specific and
not pluggable.

**Scope (shipped):**

9 checks (S01-S09), mapping to STD-SKILL-001 §10.1 V11a-V14b:

| Check | Source | Strictness                                 | Description                                                        |
| ----- | ------ | ------------------------------------------ | ------------------------------------------------------------------ |
| S01   | V11a   | HARD                                       | SKILL.md exists in every skills/skills/{name}/ folder              |
| S02   | V11b   | HARD (`--strict` default since 2026-06-21) | frontmatter name matches folder name exactly (incl. `_sts` suffix) |
| S03   | V11c   | HARD (`--strict` default since 2026-06-21) | STS skills (with `author: STS`) have `_sts` folder suffix          |
| S04   | V13a   | HARD                                       | YAML frontmatter parses                                            |
| S05   | V13b   | HARD (`--strict` default since 2026-06-21) | Required fields: name, description, version                        |
| S06   | V05a   | SOFT                                       | id format: ZAI-<DOMAIN>-<NNN>                                      |
| S07   | V13c   | SOFT                                       | compatibility: both\|sandbox\|ade                                  |
| S08   | V14a   | SOFT                                       | frontmatter id matches blockquote ID:                              |
| S09   | V14b   | HARD                                       | frontmatter version matches blockquote Version:                    |

**Remediation log (closed 2026-06-21, all 15 violations):**

| #   | Skill                            | Was                                        | Now                               |
| --- | -------------------------------- | ------------------------------------------ | --------------------------------- |
| 1   | `phi-layout`                     | `name: golden-grid`                        | `name: phi-layout` (v2.2 -> v2.3) |
| 2   | `frontend-styling-expert_sts`    | (false-positive due to verifier bug)       | unchanged; verifier fixed         |
| 3   | `performance-code-generator_sts` | (false-positive due to verifier bug)       | unchanged; verifier fixed         |
| 4   | `phi-layout_sts`                 | (false-positive due to verifier bug)       | unchanged; verifier fixed         |
| 5   | `prompt-engineering_sts`         | (false-positive due to verifier bug)       | unchanged; verifier fixed         |
| 6   | `sync-toolkit_sts`               | (false-positive due to verifier bug)       | unchanged; verifier fixed         |
| 7   | `workflow-discipline_sts`        | (false-positive due to verifier bug)       | unchanged; verifier fixed         |
| 8   | `zai-ui-composer_sts`            | (false-positive due to verifier bug)       | unchanged; verifier fixed         |
| 9   | `anti-monolith`                  | `author: STS` (system skill, not personal) | `author:` field removed           |
| 10  | `session-experience`             | `author: STS` (system skill, not personal) | `author:` field removed           |
| 11  | `session-log`                    | `author: STS` (system skill, not personal) | `author:` field removed           |
| 12  | `gepetto`                        | missing `version:`                         | `version: 1.0` added              |
| 13  | `reducing-entropy`               | missing `version:`                         | `version: 1.0` added              |
| 14  | `session-handoff`                | missing `version:`                         | `version: 1.0` added              |
| 15  | `skill-creator`                  | missing `version:`                         | `version: 1.0` added              |

**Root-cause finding (verifier bug, not data bug):**

7 of the 8 S02 violations were false-positives caused by an
ambiguity in STD-SKILL-001 §3.3 vs §9.1. §3.3 said "name must match
folder name (without `_sts` suffix for STS skills)" while §9.1 and
the §11 checklist said "name matches folder name (with `_sts`
suffix for STS)". The verifier v1.0.0 implemented the §3.3 wording
literally — `expected = folder.replace(/_sts$/, '')` — which
contradicted §9.1. The same patch that closes the violations
clarifies §3.3 ("name must match folder name exactly, including
`_sts` suffix for STS skills; see §9.1") and fixes the verifier to
compare without stripping the suffix. Only 1 of 8 S02 violations
(`phi-layout` -> `name: golden-grid`) was a real data bug.

The 3 S03 violations (`anti-monolith`, `session-experience`,
`session-log`) were genuine semantic errors: these skills had
`author: STS` set despite being system skills (with ZAI-ARCH/SESSION
IDs, not ZAI-STS-XXX). Per §9, the `author: STS` field is the marker
that triggers the `_sts` folder-suffix requirement; system skills
must not set it. Fix: drop the `author:` field — git history
preserves attribution.

The 4 S05 violations were genuine missing-`version` fields; added
`version: 1.0` to each (these skills predate the v1.1 requirement).

**Integration (shipped):**

- `.githooks/pre-commit` Phase 3: runs `verify-skills.js --strict`.
  HARD failures (any of S01/S02/S03/S04/S05/S09) block the commit.
- `.github/workflows/verify-id-graph.yml`: runs `verify-skills.js
--strict`. HARD failures block CI.
- `.github/workflows/e2e-verifiers.yml` Test 3+4: validates that
  `--strict` mode catches S02 violations, and that cleanup restores
  PASS.

#### 9.2.3 End-to-end test: modify standard -> verify -> CI — IMPLEMENTED

**Status:** [OK] IMPLEMENTED in
`.github/workflows/e2e-verifiers.yml` (5 tests, smoke-tested
locally).

**Why:** The manual test scenarios in §6 should be automated to
catch regressions before they reach production. Without this, each
verifier change is reviewed by hand, which does not scale.

**Implementation (shipped):**

Reusable workflow in `.github/workflows/e2e-verifiers.yml` with 5
tests:

1. **Test 1**: creates a 1004-line `_e2e_test_v11.md` in
   `standards/standards/`, runs `verify-standards.js`, expects exit
   1 with V11 in output. Cleans up.
2. **Test 2**: runs `verify-standards.js` after cleanup, expects
   PASS.
3. **Test 3**: creates a `_e2e-test-skill/` folder with a SKILL.md
   whose `name` field does not match the folder name, runs
   `verify-skills.js --strict`, expects exit 1 with S02 in output.
   Cleans up.
4. **Test 4**: runs `verify-skills.js` after cleanup, expects PASS.
5. **Test 5**: modifies `id-graph-baseline.json` (in-memory, not
   committed), runs `verify-id-graph.js --compare`, expects exit 1
   with MISMATCH in output. Restores baseline, re-runs, expects
   PASS.

**Triggers:** `workflow_dispatch` (manual), `pull_request` to main
(only when `standards/scripts/**` or the e2e workflow itself
changes — avoids wasted runner minutes on unrelated PRs).

**Local smoke test:** all 5 tests verified PASS in the development
session before commit.

### 9.3 P1 — Important (Q4 2026)

#### 9.3.1 Symlink integrity check in CI

**Why:** `bootstrap.sh` creates symlinks from `skills/` into the
sandbox runtime. A broken link is silent until a user hits it at
runtime, at which point the failure mode is confusing ("skill not
found" rather than "symlink broken").

**Implementation:** Add to `verify-id-graph.yml`:

```bash
find skills -type l ! -exec test -e {} \; -print | wc -l   # expect 0
```text

If count != 0, fail the workflow with a list of broken links.

**Owner:** @devops. **Target:** Q4 2026.

#### 9.3.2 `run-contract.sh` in CI

**Why:** Local hooks may diverge from CI checks. A developer who runs
`git commit --no-verify` bypasses L0/L0.5 locally; L2 CI catches
verifier regressions but NOT contract-layer drift. Running
`run-contract.sh --dry-run` in CI ensures the two stay in sync.

**Implementation:** Add to `verify-id-graph.yml`:

```bash
- name: L1 contract check (Phase B)
  run: |
    skills/skills/commit-work/scripts/run-contract.sh --dry-run
```

The `--dry-run` flag is already implemented (run-contract.sh §1, modes
block) and performs no mutation — it only runs the guard and standard
checks. Safe to run in CI without side effects.

**Owner:** @devops. **Target:** Q4 2026.

#### 9.3.3 Tiered hard caps for skills/ (V12) — IMPLEMENTED + EXTENDED (2026-06-21, O-017 Phase D2; S10c added 2026-06-22)

**Status:** [OK] IMPLEMENTED in `verify-skills.js` v1.1.1 (S10a + S10b + S10c checks).

**What was added:**

| Check       | Cap                      | Scope                     | Rationale                                                                                                                         |
| ----------- | ------------------------ | ------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| S10a (V12a) | SKILL.md <= 800 lines    | all 36 skill folders      | META-001 §4.18.1 SKILL.md row (existing ceiling, NEW runtime enforcement — replaces deferred `PROC-LINECOUNT-004`)                |
| S10b (V12b) | CONTRACT.md <= 500 lines | 2 skills with CONTRACT.md | META-001 §4.18.1 CONTRACT.md row (added 2026-06-21)                                                                               |
| S10c (V12c) | README.md <= 400 lines   | 10 skills with README.md  | META-001 §4.18.1 README.md row (existing ceiling, NEW runtime enforcement — added 2026-06-22 after gepetto+react-dev remediation) |

**Why tiered, not flat (per O-015 + LESSON-001):** A flat 1000-line cap
(like V11 in `verify-standards.js`) doesn't fit the heterogeneous skills/
corpus. SKILL.md is a trigger surface (must load in one read, 800 cap).
CONTRACT.md is a structural document (10 mandatory sections per
`skills/docs/CONTRACT-TEMPLATE.md`, 500 cap). README.md is an
onboarding/overview document (400 cap — detailed examples belong in
`references/`). References are loaded on demand and exempt per §4.18.1 —
no cap.

**Why 500 for CONTRACT.md (not 200 as O-017 originally proposed):** The
original O-017 proposal suggested 200 lines, but both pilot contracts
violate a 200-line cap by 1.8×–2.3× (`commit-work/CONTRACT.md` 368 lines,
`session-handoff/CONTRACT.md` 466 lines). Per LESSON-001 (root-cause fix
scales as O(1), symptom/whitelist fix scales as O(N)), the cap was
adjusted to fit measured reality rather than compressing the structural
10-section shape. The 500-line cap gives ~7% headroom over the largest
pilot. See `META-001 §4.18.6` for the full rationale.

**Why S10c was activated on 2026-06-22 (not 2026-06-21 with S10a/S10b):**
The 400-line README.md cap existed in §4.18.1 since 2026-06-21, but 2
pre-existing violations blocked HARD enforcement from day 1
(`gepetto/README.md` 485 lines, `react-dev/README.md` 404 lines). Both
were remediated on 2026-06-22 (gepetto 485->302 via consolidating 3
overlapping integration sections; react-dev 404->392 via condensing one
multi-item bullet list into a paragraph), unblocking S10c as HARD from
day 1. See `META-001 §4.18.7` for the full rationale.

**What was NOT added:**

- **References cap.** References are exempt per §4.18.1 — no cap. The
  O-017 proposal's "references <= 2000" was wrong (contradicts §4.18.1);
  corrected in this implementation.

**Companion standard changes:**

- `META-001 §4.18.1` — README.md row pre-existing; CONTRACT.md row added 2026-06-21
- `META-001 §4.18.5` — added cross-links to STD-SKILL-001 §8.2 for CONTRACT.md (2026-06-21) and README.md (2026-06-22)
- `META-001 §4.18.6` — CONTRACT.md cap rationale (added 2026-06-21)
- `META-001 §4.18.7` — README.md cap rationale (added 2026-06-22)
- `STD-SKILL-001 §8.2` — added CONTRACT.md ceiling line (2026-06-21) + README.md ceiling line (2026-06-22)
- `STD-SKILL-001 §10.1` — replaced deferred `PROC-LINECOUNT-004` row with active `verify-skills.js S10a/S10b/S10c` rows
- `verify-skills.js` — v1.0.0 -> v1.1.0 (2026-06-21, S10a+S10b) -> v1.1.1 (2026-06-22, +S10c)

**Verification (post-S10c implementation, 2026-06-22):**

```bash
verify-skills.js --strict: 9/9 HARD PASS (incl. S10a + S10b + S10c)
  S10a: all 36 SKILL.md files <= 800 lines
  S10b: all 2 CONTRACT.md files <= 500 lines
  S10c: all 10 README.md files <= 400 lines (max: 392, react-dev)
verify-standards.js: 8/8 PASS (META-001 = 962 lines after §4.18.7 addition + §4.18.4 exempt-list compression)
verify-id-graph.js: 13/13 HARD + snapshot OK
```

**Owner:** @tech-lead. **Status:** COMPLETE 2026-06-22 (S10a+S10b on 2026-06-21, S10c on 2026-06-22).

### 9.4 P2 — Nice to have (Q1 2027)

#### 9.4.1 `registry.json` consistency test

When `registry.json` is created (Phase E), test that it matches actual
`skills/` contents. Prevents drift between catalog and filesystem.

**Owner:** @backend. **Target:** Q1 2027.

#### 9.4.2 Version-bump detection

If a standard's content changed but `version:` was not bumped, emit a
WARN. Catches content drift without version tracking. This is the
soft-warning counterpart to V05 (which only checks that `version:` is
present, not that it is current).

**Owner:** @tech-lead. **Target:** Q1 2027.

#### 9.4.3 `--help` flag for verifiers

Add `--help` to `verify-standards.js` and `verify-id-graph.js` so
contributors can discover usage without reading the full doc:

```bash
node standards/scripts/verify-standards.js --help
# Usage: node verify-standards.js [mode]
#   mode: 'strict' (default) | 'permissive' | 'ci'
```None

Low effort, high UX. **Owner:** @backend. **Target:** Q1 2027.

#### 9.4.4 `verify-id-graph.js` modularization — IMPLEMENTED (2026-06-21, O-018)

**Status:** [OK] COMPLETE — `verify-id-graph.js` v1.1.5 -> v1.1.6.

**What was done:**

Previous O-018 attempt (2026-06-21) extracted 4 lib/ files (constants, graph-algorithms, parsers, snapshot — 500 lines), reducing main file from 1593 -> 1354 lines. This continuation extracted 4 more blocks:

| New lib/ file            | Lines | Content                                                                                                   |
| ------------------------ | ----- | --------------------------------------------------------------------------------------------------------- |
| `lib/health-warnings.js` | 349   | Phase 10 W11-W15 (size anomaly, missing §XA, broken refs, OPEN issues, naming drift) + W13 root-cause fix |
| `lib/declarations.js`    | 251   | extractDeclaration (3 header formats) + parseMigrations (YAML blocks)                                     |
| `lib/output.js`          | 152   | emitHumanReadable + emitJSON (pure functions, take results as param)                                      |
| `lib/file-scanner.js`    | 138   | listFiles + globFiles + matchesPattern (zero-dep glob)                                                    |

**Main file size:** 1355 -> 829 lines (-526 lines, -39%). Under 1000-line target.

**W13 root-cause fix (LESSON-001 applied):**

Previous W13 implementation maintained a whitelist of ~30 known false-positive references — every new prose mention of a skills/ file path in a standards/ doc required a new whitelist entry (unbounded growth, LESSON-001 anti-pattern).

Root-cause fix in this iteration:

1. **Expanded candidates list** to include `path.join(platformRoot, 'skills', 'skills', refPath)` — resolves path-like refs (`commit-work/CONTRACT.md`, `session-handoff/CONTRACT.md`, `gepetto/README.md`, `react-dev/README.md`) to actual files in skills/skills/ tree.
2. **Fixed submodule path resolution** — submodules are mounted INSIDE `Z-ai-platform/` (per `.gitmodules`: skills/ at `Z-ai-platform/skills/`, guard/ at `Z-ai-platform/guard/`), NOT as siblings at `../Z-ai-skills/` or `../Z-ai-guard/`. Original candidates list used `../Z-ai-skills/` which never resolved. Added correct paths `path.join(platformRoot, 'skills', ...)` and `path.join(platformRoot, 'guard', ...)`.

**W13 false-positive count: 11 -> 0.** All 11 prior false positives now resolve correctly through the candidates list. Whitelist kept small (~15 entries) for genuinely planned/historical/generic refs (planned scripts like `validate.sh`, `install.sh`; historical extraction sources like `AGENT_RULES.md`; generic file-type names like `SKILL.md`, `CONTRACT.md`).

**Honest finding:** Total code footprint grew slightly (verify-id-graph.js 829 + lib/ 1390 = 2219 lines vs previous 1354 + lib/ 500 = 1854 lines, +365 lines / +20%). This is because new lib/ files have comprehensive JSDoc docstrings (every function gets a block explaining semantics + edge cases + dependencies). The docstrings are the test plan for future unit tests. Pure line-count reduction was NOT the goal — modularization for testability and isolation was. The main file being under 1000 lines means a reader can scan it end-to-end in one sitting.

**Verification:**

```text
verify-standards.js: 8/8 PASS
verify-id-graph.js: 13/13 HARD + 0 warnings + snapshot OK
  (was: 13/13 HARD + 11 warnings before W13 fix)
verify-skills.js --strict: 8/8 HARD PASS
Snapshot baseline: 61 IDs, 115 edges, 0 warnings (was 11)
```

**Owner:** @tech-lead. **Status:** COMPLETE 2026-06-21.

---

## 10. Known limitations and gotchas

### 10.1 `core.fileMode=false` is required on sandbox clones

Sandbox fs mount sets +x bit on all files (so .sh can run without
per-file chmod). Git's default `core.fileMode=true` flags the index
vs working-tree mode bit mismatch as "modified" — 17+ files appear
modified with 0 line changes. Fix: `git config core.fileMode false`
per clone. `bootstrap.sh` Step 2 does this automatically.

### 10.2 Worklog freshness (Phase 0) is WARN-only

The Phase 0 check `find worklog.md -mmin -60` produces
false positives — many commits legitimately do not need a worklog
entry (typo fixes, dependency bumps). Do not promote to BLOCK without
a more nuanced check.

### 10.3 `--timeout` flag does not exist on verifiers

Both `verify-standards.js` and `verify-id-graph.js` take a single
optional positional `mode` argument (`process.argv[2]`). They do not
parse `--timeout`, `--verbose`, or any other flag. Pass no arguments
for default mode. If you need a timeout, use `timeout(1)`:

```bash
timeout 30s node standards/scripts/verify-id-graph.js
```

### 10.4 `quick_validate.py` is not universal

Only `skill-creator` has it. Running the script on other skills will
fail with `No such file or directory`. See §5.

### 10.5 Emoji regex requires PCRE mode

If you write a custom check for emoji in markdown, use `grep -P`
(PCRE mode) with the `\u{XXXX}` syntax. `grep -E` (POSIX ERE) does
NOT interpret `\u{XXXX}` — it matches the literal characters
`\`, `u`, `{`, etc.

```bash
# Correct (PCRE)
grep -P '[\x{1F600}-\x{1F64F}\x{2600}-\x{27BF}]' file.md

# WRONG (POSIX ERE — matches literal '\u{1F600}' characters)
grep -E '[\u{1F600}-\x{1F64F}\u{2600}-\x{27BF}]' file.md
```None

### 10.5.1 W13 false positive on cross-submodule references

`verify-id-graph.js` W13 (broken cross-doc reference) scans only the
`standards/` tree. References to files in `skills/` or `guard/`
submodules (e.g. `` `run-contract.sh` ``, `` `CONTRACT.md` ``) fire
W13 even when the file exists in its submodule. This is a known
architectural limitation of the verifier, not a bug in the document.

Workaround options (in order of preference):

1. **Reference by full submodule-relative path** (e.g.
   `` `skills/skills/commit-work/scripts/run-contract.sh` ``) — W13
   still fires because the path does not exist in `standards/`, but
   the reader can follow the path manually.
2. **Add to `W13_WHITELIST`** in `verify-id-graph.js` (see lines
   ~1130-1169 for the existing whitelist) — O(N) fix, acceptable for
   stable cross-submodule paths.
3. **Extend W13 to scan all submodules** — proper root-cause fix,
   scheduled for Phase D1 when `verify-skills.js` is built (the two
   verifiers will share a common path-resolution module).

This document currently uses option 1 (full submodule-relative
paths) where practical, and accepts W13 warnings for short basename
references in narrative text.

### 10.6 Performance benchmark threshold

The drafts proposed a 3.0s threshold for `verify-id-graph.js` on
GitHub runners. This is **arbitrary** — no baseline measurement
exists. Before adopting such a threshold, run the script 5× on a
GitHub runner and record the actual median. Set the threshold to
`median × 1.5` to allow for runner variance. Local runs (sandbox) are
typically <1s; GitHub runners vary 1-4s depending on load.

### 10.7 Adversarial test files in `standards/standards/` race the verifier

If you write an L5 adversarial test that creates temporary files in
`standards/standards/` and then runs `verify-id-graph.js`, the
verifier may FAIL on a check unrelated to what you are testing (e.g.
the temp file's ID syntax violates G12). Use a separate temp
directory and copy in only the well-formed test fixtures.

### 10.8 LESSON-004: `git reset --hard` is destructive

Before ANY `git reset --hard <ref>`, stash the working tree:

```bash
git stash push -u -m "pre-reset-safety"
git reset --hard HEAD~1
git stash pop
```

`git reset --hard` is a TWO-axis destructive operation: it moves the
branch pointer AND overwrites the working tree. Triggered twice in
Phase B smoke testing.

### 10.8.1 LESSON-004a: automated guard layer for destructive scripts

LESSON-004's stash-then-reset recipe depends on operator discipline.
For scripts in the repo that perform destructive operations
(`bootstrap.sh`, `run-contract.sh`, future CI workflows), the safety
should be **encoded in the script itself**, not relied upon as a
manual habit.

**Two-layer guard (refined from the CI/CD audit):**

```bash
# Layer 1 (root cause): refuse if uncommitted changes exist.
# Catches the actual failure mode — losing work the operator
# did not realise was uncommitted.
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "[ERROR] Uncommitted changes detected. Stash or commit first." >&2
  exit 1
fi

# Layer 2 (defense in depth): require explicit --force flag for
# any rm -rf on tracked or top-level paths. Converts accidental
# invocation from 'silent catastrophe' to 'loud refusal'.
if [[ "$1" != "--force" ]]; then
  echo "[ERROR] Destructive operations require --force flag." >&2
  exit 1
fi
```text

The two layers are independent and complementary:

- Layer 1 catches the common case (forgot to commit).
- Layer 2 catches the rare case (wrong working directory or wrong
  script invoked).
- Either alone is insufficient: Layer 1 without Layer 2 still allows
  `--force` workflows to wipe a clean tree; Layer 2 without Layer 1
  still allows a `--force` invocation to wipe uncommitted work.

**What this is NOT:** This is not a `$PWD`-prefix check (the initial
audit proposal). `$PWD` matching is fragile — clone paths vary across
machines and sandboxes, and any prefix that matches the live tree also
matches legitimately similar sandbox paths (e.g.
`/home/z/sandbox/Z-ai-platform-test`). The uncommitted-state check is
path-independent and catches the root cause directly.

**Candidate for promotion:** Phase C may encode this as guard check G0
in `skills/skills/commit-work/CONTRACT.md`, subsuming the manual
stash-then-reset recipe from LESSON-004 into automated enforcement.

---

## 11. Bug audit of the original drafts

The two draft documents ("Полный CI/CD Pipeline" and "Уровни
тестирования Z-ai-platform") contained 12 factual bugs against the
actual repo state. This section documents them so future contributors
do not re-introduce them.

| #   | Bug                                                            | Reality                                                                                                                       | Where fixed                        |
| --- | -------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| 1   | L1 matrix lists `[standards, rules, zai-standards, zai-rules]` | Actual submodules: `standards`, `guard`, `skills` (+ orchestrator). 2 of 4 listed repos do not exist.                         | §1 architecture                    |
| 2   | `verify-standards.js --timeout=30s` flag                       | Script takes only `process.argv[2]` as mode string. No `--timeout` parsing.                                                   | §10.3                              |
| 3   | `scripts/check-md.sh` path                                     | Actual path is `standards/scripts/check-md.sh`. Root-level `scripts/` does not exist.                                         | §1 architecture                    |
| 4   | `eslint-rules/` "no-op" criticism                              | The `if [ -d "eslint-rules" ]` check is a forward-compatible defensive guard, not a bug. Real issue is no `.eslintrc` exists. | §9 recommendations                 |
| 5   | `quick_validate.py` called for all skills                      | Only 1 of 36 skills (`skill-creator`) has it.                                                                                 | §5.1, §10.4                        |
| 6   | Emoji regex `grep -E '[\u{1F600}-...]'`                        | Requires `grep -P` (PCRE). `grep -E` matches literal characters.                                                              | §10.5                              |
| 7   | L5 adversarial tests create files in `standards/standards/`    | Race condition — verifier may FAIL on unrelated G-check.                                                                      | §10.7                              |
| 8   | L4 threshold 3.0s                                              | Arbitrary, no baseline.                                                                                                       | §10.6                              |
| 9   | L8 chat compliance checks `chat-logs/agent-responses.log`      | File does not exist anywhere in the repo.                                                                                     | Removed (speculative test deleted) |
| 10  | No `permissions:` block in workflow                            | PR comment step needs `pull-requests: write`.                                                                                 | §4.3                               |
| 11  | `npm install -g yq` in L2                                      | `verify-id-graph.js` does not use `yq`. Wasted install time.                                                                  | Not in actual workflow (§4)        |
| 12  | `rm -rf /home/z/my-project/Z-ai-platform` in L6 bootstrap test | Wipes the live working tree. Same trap as LESSON-004. Automated two-layer guard proposed in §10.8.1 (LESSON-004a).            | §6.1, §10.8, §10.8.1               |

---

## 12. Change history

| Date       | Change                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2026-06-21 | Initial creation. Merges two draft documents ("Полный CI/CD Pipeline" and "Уровни тестирования Z-ai-platform") into one canonical reference. Documents the actual existing workflow (`.github/workflows/verify-id-graph.yml`, 250 lines) instead of a hypothetical one. Includes §11 bug audit table documenting 12 factual errors in the drafts against actual repo state.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| 2026-06-21 | Rewrite of §9 — expanded from a flat 7-row table into a structured priority matrix (§9.1) with P0/P1/P2 sections (§9.2/9.3/9.4), each item carrying explicit owner, target quarter, and dependencies. Adds §9.2.2 `verify-skills.js` scope (35/36 skills have no validator — formalised as P0 blocker for v2.5.0). Adds §9.3.2 `run-contract.sh --dry-run` in CI (the `--dry-run` flag already exists in `run-contract.sh` §1, so this is a one-step CI addition with no script-side prerequisite). Adds §9.4.3 `--help` flag for verifiers (P2 UX improvement). Adds §10.8.1 LESSON-004a — refined two-layer guard (uncommitted-state check + `--force` flag) replacing the audit's initial `$PWD`-prefix proposal, which is fragile across clone paths and sandbox configurations. Updates §11 #12 to point at §10.8.1.                                                                                                                                                                                                                                                                                                                                                                     |
| 2026-06-21 | **All three P0 items in §9.2 marked IMPLEMENTED.** (1) §9.2.1 snapshot test: `verify-id-graph.js` v1.1.4 adds `--snapshot`/`--compare`/`--update-snapshot` flags, baseline at `standards/_snapshots/id-graph-baseline.json`, CI step in `verify-id-graph.yml`. (2) §9.2.2 `verify-skills.js` v1.0.0: new skills-side verifier with 9 checks (S01-S09 mapping to V11a-V14b), soft-default mode (S02/S03/S05 are SOFT until 15 pre-existing violations remediated, then `--strict` flip), Phase 3 in `.githooks/pre-commit`, CI step in `verify-id-graph.yml`. (3) §9.2.3 e2e test: `.github/workflows/e2e-verifiers.yml` with 5 tests (V11 violation, cleanup PASS, S02 violation, cleanup PASS, snapshot compare mismatch), smoke-tested locally. Remediation backlog for `--strict` flip: 6 STS skills with `name: foo_sts`, 1 `phi-layout` wrong name, 3 skills missing `_sts` suffix, 4 skills missing `version:` field.                                                                                                                                                                                                                                                                   |
| 2026-06-21 | **§9.2.2 REMEDIATED — `verify-skills.js` flipped to `--strict` default.** All 15 pre-existing violations closed in a single remediation patch. Root-cause analysis revealed 7 of 8 S02 violations were false-positives caused by a contradiction in STD-SKILL-001 §3.3 ("name must match folder name without `_sts` suffix") vs §9.1 + §11 checklist ("name matches folder name with `_sts` suffix"). Verifier v1.0.0 had implemented the §3.3 wording literally. Same patch clarifies §3.3 to defer to §9.1, fixes verifier S02 to compare without stripping suffix, and fixes the one real S02 violation (`phi-layout` `name: golden-grid` -> `name: phi-layout`). S03 violations (`anti-monolith`, `session-experience`, `session-log`) were genuine: these system skills had `author: STS` field set despite having canonical ZAI-ARCH/SESSION IDs (not ZAI-STS-XXX); `author:` field dropped. S05 violations were 4 skills missing `version:` (`gepetto`, `reducing-entropy`, `session-handoff`, `skill-creator`); `version: 1.0` added. After remediation: `verify-skills.js --strict` 6/6 HARD PASS, 0 SOFT warnings. `.githooks/pre-commit` Phase 3 + CI step promoted to `--strict`. |
