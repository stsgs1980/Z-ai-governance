# Contributing to Z-ai-platform

This document describes how to make changes to the Z-ai 4-repository
architecture without breaking the ID graph.

## 1. Repository layout

```text
Z-ai-platform/      (orchestrator, L0 — this repo)
--- standards/      (submodule -> Z-ai-standards, L1)
--- guard/          (submodule -> Z-ai-guard, L2)
--- skills/         (monorepo — 14 skills, L3)
--- .gitmodules     (clean HTTPS URLs, no PAT)
--- .github/workflows/verify-id-graph.yml   (CI for the ID graph)
--- README.md
--- install-hooks.sh
```

The 4-repo split exists so that:

- **Standards** (L1) can evolve without forcing rule/skill updates
- **Guard** (L2) can ship rule changes on its own cadence
- **Skills** (L3) can be consumed standalone by the sandbox runtime

The ID graph (G01-G15) enforces that changes in one layer do not silently
break references in another layer.

## 2. Local development

Clone with submodules:

```bash
git clone --recurse-submodules https://github.com/stsgs1980/Z-ai-platform.git
cd Z-ai-platform
```

If you forgot `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

To update a submodule to its latest `main`:

```bash
cd standards
git checkout main
git pull
cd ..
git add standards
git commit -m "Bump standards submodule"
```

## 3. Pre-commit checks

### 3.1. Install git hooks (one-time, after cloning)

```bash
bash install-hooks.sh
```

This sets `core.hooksPath` to `.githooks/` and marks the hooks executable.
The `pre-commit` hook runs **both** verifiers on every commit:

- `verify-standards.js` — content-level invariants (V04-V10): no emoji,
  fence language tags, English-only, anti-monolith thresholds, design-system
  delegation, README template structure. Fast (<1s).
- `verify-id-graph.js` — cross-repo ID-graph invariants (G01-G15): no
  duplicate IDs, Related-edge resolution, layer matrix, cycle detection,
  typo-IDs, ZAI DAG. Slower (~2-3s, scans all 4 repos).

Soft warnings (W01-W15) do not block commits — they are advisory and
surface in CI summaries.

The standards submodule has its own `.githooks/pre-commit` (runs
`verify-standards.js` only — the cross-repo check needs parent context).
Run `bash standards/install-hooks.sh` after cloning the submodule
standalone.

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

### 3.3. Line ending policy

**All shell scripts and config files MUST use LF line endings.**

CRLF line endings will cause bash on Linux to fail silently. The Z-ai-platform
enforces this through three layers:

| Layer            | File            | Behavior                                                         |
| ---------------- | --------------- | ---------------------------------------------------------------- |
| `.gitattributes` | Git attributes  | `*.sh text eol=lf`, `*.json text eol=lf`, `.husky/* text eol=lf` |
| `.editorconfig`  | Editor settings | `end_of_line = lf` for `*`, `*.sh`, `.husky/*`                   |
| `check-crlf.sh`  | Pre-commit hook | Detects any CRLF in shell scripts, fails if found                |

**Windows developers:** set `git config core.autocrlf false` to prevent Git from
converting LF to CRLF on checkout.

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

You must see `Result: PASS (13/13 hard checks, N warnings)` from
`verify-id-graph.js` and `Total: 8 | PASS: 8 | FAIL: 0` from
`verify-standards.js`. If any HARD check fails, the CI on GitHub will
also fail and the PR cannot merge.

Soft warnings (W01-W15) are non-blocking, but please read them —
some indicate real cleanup opportunities.

## 4. ID graph — quick reference

| Prefix | Layer | Lives in   | Example              |
| ------ | ----- | ---------- | -------------------- |
| STD    | L1    | standards/ | STD-META-001         |
| RULE   | L2    | guard/     | RULE-WORKLOG-002     |
| PROC   | L2    | guard/     | PROC-MONOLITH-SETUP  |
| TOOL   | L2    | guard/     | TOOL-MONOLITH-VERIFY |
| ZAI    | L3    | skills/    | ZAI-META-001         |

**Related:** directed edges, must respect the layer matrix (see
`standards/standards/STD-META-001-v2.0.md` §6.1). Cross-layer STD->RULE
is FORBIDDEN (use the reverse direction).

**Aligned_with:** undirected edges, can cross layers (e.g. STD ↔ ZAI).
Must be reciprocated (both sides must declare it).

## 5. Making changes — common patterns

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
   last-updated: 2026-06-17
   related:
      - RULE-WORKLOG-002
     - STD-META-001
   ---
   ```

2. Update `guard/rules/INDEX.md`.
3. Run `node standards/scripts/verify-id-graph.js` locally.
4. Commit and push **inside the submodule** (`cd guard && git push`).
5. Bump the submodule pointer in Z-ai-platform:
   `cd .. && git add guard && git commit -m "Bump guard: add RULE-NEW-018"`.

### 5.2 Add a new skill

1. Create `skills/<name>/SKILL.md` with YAML frontmatter.
2. Add an ID only if the skill will be referenced from elsewhere:
   `id: ZAI-<DOMAIN>-NNN`. Otherwise omit `id:`.
3. Update `skills/INDEX.md`.
4. Run verifier, commit, push inside submodule, bump pointer.

### 5.3 Add a new standard

1. Create `standards/standards/STD-<DOMAIN>-<NNN>-v<MAJOR>.<MINOR>.md`.
2. Use the blockquote header format (see existing standards).
3. Run verifier, commit, push inside submodule, bump pointer.

## 6. Handling PAT (Personal Access Tokens)

- **Never** commit a PAT in any tracked file.
- **Never** embed a PAT in `.git/config` or `.gitmodules`.
- Use `~/.git-credentials` (mode 600) via `git config --global
credential.helper store`.
- After a push, delete the PAT from disk and revoke it on GitHub.
- Prefer **fine-grained PATs** (e.g. `github_pat_...`) over classic
  PATs (`ghp_...`) — they are less prone to auto-revocation.

## 7. CI behavior

The `.github/workflows/verify-id-graph.yml` workflow runs:

- On every push to `main` in Z-ai-platform
- On every PR to `main`
- Nightly at 03:00 UTC
- On manual dispatch

It checks out Z-ai-platform with all submodules and runs the verifier.
Failures block PR merges and post a comment on the PR.

## 8. Recovery from a broken ID graph

If CI fails on a PR:

1. Read the verifier output (posted to `$GITHUB_STEP_SUMMARY`).
2. Identify which G-check failed (G01-G15).
3. Fix the offending file(s) in the appropriate submodule.
4. Re-run the verifier locally until `13/13 PASS`.
5. Push the submodule fix, then bump the pointer in Z-ai-platform.
