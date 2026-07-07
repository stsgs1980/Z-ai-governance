# Contributing to Z-ai-governance

This document describes how to make changes to the governance
repository without breaking the ID graph.

## 1. Repository layout

```text
Z-ai-governance/       (flat repo — guard, standards, skills in one repo)
--- standards/          (L1): normative standards, verifier scripts, snapshots
--- guard/              (L2): rules, procedures, enforcement scripts, tools
--- skills/             (L3): 14 skills (inline monorepo)
--- eslint-rules/       (L4): custom ESLint rules for STD-DOC-003 compliance
--- eslint-processors/  (L4): markdown code-block processor
--- .github/workflows/  (CI: verify-id-graph.yml, e2e-verifiers.yml)
--- .zai/               (governance config, setup, verify orchestrator)
--- .husky/             (git hooks: pre-commit, commit-msg, pre-push)
```

The repository is a flat copy of Z-ai-platform. All directories are
regular directories -- there are no submodules.

The ID graph (G01-G15) enforces that changes in one layer do not silently
break references in another layer.

## 2. Local development

Clone:

```bash
git clone https://github.com/stsgs1980/Z-ai-governance.git
cd Z-ai-governance
npm install
```

## 3. Pre-commit checks

### 3.1. Install git hooks (one-time, after cloning)

Hooks install automatically via `npm install` (Husky `prepare` script).

To verify hooks are active:

```bash
git config --get core.hooksPath   # should print .husky/_
ls .husky/                        # should show: pre-commit commit-msg pre-push
```

The `pre-commit` hook runs 5 groups on every commit:

**Group 0 (HARD, 13 scripts):** guard integrity checks
- check-no-bypass.sh (RULE-INTEGRITY-011)
- check-commit-checklist.sh (RULE-COMMIT-014: large files, honesty)
- check-version-bump.sh (RULE-VERSION-013)
- check-read-before-write.sh (RULE-READ-003)
- check-no-loops.sh (RULE-LOOPS-005)
- check-ahg-integrity.sh (RULE-ARCH-016/017)
- check-sandbox-env.sh (RULE-ENV-008)
- check-session-start.sh (RULE-AGENT-009)
- check-work-cycle.sh (RULE-STRUCT-007)
- check-snapshot-sync.sh (ID graph drift)
- check-changelog-sync.sh (CHANGELOG freshness)
- check-script-coverage.sh (pre-commit vs CI drift)
- check-crlf.sh (LF line ending enforcement)

**Group 1 (HARD):** guard PROC checks
- co-change-check.sh (RULE-DOC-010: code + docs sync)
- worklog-check.sh (RULE-WORKLOG-002: worklog entry required)

**Group 2 (HARD):** standards verifiers
- verify-standards.js (V01-V18: content-level invariants)
- verify-id-graph.js (G01-G15: cross-repo ID-graph invariants)
- verify-skills.js (S01-S09: skill format invariants)

**Group 3 (SOFT):** line-count check (advisory)

**Group 4:** lint-staged (eslint + prettier on staged files)

To bypass a hook for a single commit (emergencies only):

```bash
git commit --no-verify
```

### 3.2. Run the verifier manually

Before pushing any change, run the verifier locally:

```bash
node standards/scripts/verify-id-graph.js
node standards/scripts/verify-standards.js
```

Or run all governance checks at once:

```bash
bash .zai/verify
```

### 3.3. Line ending policy

**All shell scripts and config files MUST use LF line endings.**

CRLF line endings will cause bash on Linux to fail silently. The project
enforces this through three layers:

| Layer            | File            | Behavior                                                         |
| ---------------- | --------------- | ---------------------------------------------------------------- |
| `.gitattributes` | Git attributes  | `*.sh text eol=lf`, `*.json text eol=lf`, `.husky/* text eol=lf` |
| `.editorconfig`  | Editor settings | `end_of_line = lf` for `*`, `*.sh`, `.husky/*`                   |
| `check-crlf.sh`  | Pre-commit hook | Detects any CRLF in shell scripts, fails if found                |

**Windows developers:** set `git config core.autocrlf false` to prevent
Git from converting LF to CRLF on checkout.

**If you accidentally introduce CRLF:**

```bash
# Check what has CRLF
bash guard/scripts/check-crlf.sh --hard

# Fix all files
for f in $(git ls-files '*.sh' '*.bash' '.husky/*'); do
  sed -i 's/\r$//' "$f"
  git add "$f"
done
```

**Excluded files** (Windows-native, CRLF is correct): `*.cmd`, `*.bat`, `*.ps1`

You must see `RESULT: ALL CHECKS PASSED` from `verify-id-graph.js` and
all checks pass from `verify-standards.js`. If any HARD check fails,
the CI on GitHub will also fail and the PR cannot merge.

## 4. ID graph -- quick reference

| Prefix | Layer | Lives in                | Example          |
| ------ | ----- | ----------------------- | ---------------- |
| STD    | L1    | standards/standards/    | STD-META-001     |
| RULE   | L2    | guard/rules/            | RULE-WORKLOG-002 |
| PROC   | L2    | guard/instructions/     | PROC-COCHANGE-003|
| TOOL   | L2    | guard/tools/            | TOOL-VERIFY-001  |
| ZAI    | L3    | skills/                 | ZAI-DEV-006      |

**Related:** directed edges, must respect the layer matrix (see
`standards/standards/STD-META-001-standard-id-system.md` section 6.1).

**Aligned_with:** undirected edges, can cross layers. Must be
reciprocated (both sides must declare it).

## 5. Making changes -- common patterns

### 5.1 Add a new rule

1. Create `guard/rules/RULE-NEW-018.md` with YAML frontmatter:

   ```yaml
   ---
   id: RULE-NEW-018
   title: <short title>
   version: 1.0
   level: [C]
   status: ACTIVE
   source: <origin>
   owning-standard: STD-META-001 v2.0
   last-updated: 2026-07-07
   related:
      - RULE-WORKLOG-002
      - STD-META-001
   ---
   ```

2. Update `guard/rules/INDEX.md`.
3. Run `node standards/scripts/verify-id-graph.js` locally.
4. Commit: `git commit -m "feat(guard): add RULE-NEW-018 <title>"`.

### 5.2 Add a new skill

1. Create `skills/<name>/SKILL.md` with YAML frontmatter.
2. Add an ID only if the skill will be referenced from elsewhere:
   `id: ZAI-<DOMAIN>-NNN`. Otherwise omit `id:`.
3. Update `skills/INDEX.md`.
4. Run verifier, commit.

### 5.3 Add a new standard

1. Create `standards/standards/STD-<DOMAIN>-<NNN>-v<MAJOR>.<MINOR>.md`.
2. Use the blockquote header format (see existing standards).
3. Update `standards/standards/ARCH-002-implementation-order.md` if
   needed (position in install order).
4. Run verifier, commit.

## 6. Handling PAT (Personal Access Tokens)

- **Never** commit a PAT in any tracked file.
- **Never** embed a PAT in `.git/config` or `.gitmodules`.
- Use `~/.git-credentials` (mode 600) via `git config --global
  credential.helper store`.
- After a push, delete the PAT from disk and revoke it on GitHub.
- Prefer **fine-grained PATs** (e.g. `github_pat_...`) over classic
  PATs (`ghp_...`) -- they are less prone to auto-revocation.

## 7. CI behavior

The `.github/workflows/verify-id-graph.yml` workflow runs:

- On every push to `main`
- On every PR to `main`
- Nightly at 03:00 UTC
- On manual dispatch

It runs the verifier scripts (verify-standards.js, verify-id-graph.js,
verify-skills.js, snapshot compare). Failures block PR merges and
post a comment on the PR.

## 8. Recovery from a broken ID graph

If CI fails on a PR:

1. Read the verifier output (posted to `$GITHUB_STEP_SUMMARY`).
2. Identify which G-check failed (G01-G15).
3. Fix the offending file(s) in the appropriate directory.
4. Re-run the verifier locally until all checks pass.
5. Push the fix.