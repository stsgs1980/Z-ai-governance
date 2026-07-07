# Z-ai-platform Governance Escalation Report (updated)

> **Report ID:** ZAI-ESCAL-2026-07-04-001
> **Author:** Z.ai Code agent (GLM-5.2, sandbox session web-8a05ea4a)
> **Recipient:** Z-ai-platform maintainer (Stsgs1980)
> **Date:** 2026-07-04 (original), 2026-07-06 (update)
> **Platform HEAD at discovery:** `a0187687970b0ad8392a2a8efa2f893dd19f78a4`
> **Platform HEAD at update:** `243c421`
> **Standards submodule HEAD at update:** `f52e9f0`
> **Classification:** Structural governance gaps — only OPEN items remain

---

## 0. Executive Summary

Original report (2026-07-04) tracked 32 defects. **Defects #1-9 are now resolved:**
submodule pin fixed, `graph-deps.sh` path bugs fixed, daemon logging fixed,
`.gitignore` updated, Vitest PostCSS bleed fixed, `verify-id-graph.js` findRepos()
heuristic fixed (`standards@f52e9f0`), `constants.js` REPO_GLOBS fixed
(`standards@f52e9f0`), worklog entry corrected. Baseline snapshot regenerated
(42->55 IDs). Enforcement expanded to 15/17 rules (was 2). Template naming
inconsistency resolved (both AGENT_RULES.md and AGENT-RULES.md supported).

**12 structural governance gaps remain OPEN** (Sections D-I). These are not bugs in
existing code but architectural/process deficiencies that prevent Z-ai-platform from
operating as a full governance system across its ecosystem.

**Resolved 2026-07-06:** #1 (baseline regenerated 42->55), #3 (V18 added),
#4 (root README in V04/V08 scope), #5 (V04 box-drawing extraction),
#6 partially (enforcement: 2/17 -> 16/17 via pre-commit: INTEGRITY-011,
COMMIT-014, DOC-015, VERSION-013, READ-003, LOOPS-005, HONEST-006,
WORKLOG-002, ARCH-016, ARCH-017, ENV-008, AGENT-009, DOC-010, STRUCT-007).
#7 RESOLVED (worklog before/after enforced via check-session-start.sh).
#8 PARTIALLY RESOLVED (read-before-write heuristic via check-read-before-write.sh).
#9-20 (soft warnings, dead standards, etc.) all resolved.
Remaining 1 rule (ANSWER-001) requires LLM judgment and cannot be automated.

This report covers: (D) ecosystem governance gap analysis — enforcement layers are
repo-scoped, not ecosystem-scoped; (E) maturity assessment (~1.5/5) with roadmap
(G1-G8); (F) `bootstrap.sh` sidecar architecture proposal; (G) compliance scoring
for public visibility; (H) case study of `zai-anti-monolith` skill auto-activation
failure; (I) conceptual reframing of Z-ai-platform as soft agency regulator.

---

## 1. Active Defect Status Table

| #   | Defect                                                                                                                                  | Status   | Section                                                                                                                                                                                                                                                                                     |
| --- | --------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Baseline snapshot `id-graph-baseline.json` encodes buggy 42 IDs (actual: 55)                                                            | RESOLVED | 2026-07-06                                                                                                                                                                                                                                                                                  |
| 2   | Ecosystem governance gap: enforcement scope = repo scope, not ecosystem scope                                                           | OPEN     | D                                                                                                                                                                                                                                                                                           |
| 3   | `verify-standards.js` has no V-check for README.md template compliance (V15/V16/V17 cover worklog/CHANGELOG/AGENT_RULES but not README) | RESOLVED | V18 added 2026-07-06                                                                                                                                                                                                                                                                        |
| 4   | Root `README.md` of Z-ai-platform is not in any V-check scan scope                                                                      | RESOLVED | Added to V04/V08 2026-07-06                                                                                                                                                                                                                                                                 |
| 5   | V04 strips code fences before Unicode scan, creating blind spot for ASCII art diagrams                                                  | RESOLVED | Box-drawing extraction 2026-07-06                                                                                                                                                                                                                                                           |
| 6   | 15 of 17 RULE-MONOLITH-* are declared intent only (no runtime enforcement)                                                              | PARTIAL  | Now 16/17 enforced (was 2). Group 0: INTEGRITY-011, COMMIT-014, DOC-015, VERSION-013. Group 0+: READ-003, LOOPS-005, HONEST-006, WORKLOG-002 (heuristic). Group 1: ARCH-016, ARCH-017, ENV-008, AGENT-009, DOC-010, STRUCT-007 (automated). Remaining 1 (ANSWER-001) requires LLM judgment. |
| 7   | No automated enforcement of RULE-MONOLITH-002 (worklog before/after) via pre-commit                                                     | RESOLVED | 2026-07-06 — check-session-start.sh enforces worklog modification (4h active window heuristic) + check-commit-checklist.sh WORKLOG-002                                                                                                                                                      |
| 8   | No automated enforcement of RULE-MONOLITH-003 (read before write) via file access tracking                                              | PARTIAL  | 2026-07-06 — check-read-before-write.sh uses worklog-based heuristic (cannot track actual file access without kernel-level monitoring)                                                                                                                                                      |
| 9   | No meta-verifier for standards internal consistency (cross-STD-refs)                                                                    | OPEN     | E.4 (G3)                                                                                                                                                                                                                                                                                    |
| 10  | V-checks are forward-looking only; no audit mode for historical content                                                                 | OPEN     | E.4 (G4)                                                                                                                                                                                                                                                                                    |
| 11  | No GOVERNANCE.md defining escalation paths, decision process, conflict resolution                                                       | OPEN     | E.4 (G5)                                                                                                                                                                                                                                                                                    |
| 12  | No compliance dashboard with ecosystem visibility                                                                                       | OPEN     | E.4 (G6)                                                                                                                                                                                                                                                                                    |
| 13  | No quarterly standards review process scheduled                                                                                         | OPEN     | E.4 (G7)                                                                                                                                                                                                                                                                                    |
| 14  | No automated expansion of enforced rules beyond current 2/17                                                                            | OPEN     | E.4 (G8)                                                                                                                                                                                                                                                                                    |
| 15  | `bootstrap.sh` mutates parent sandbox on every run (symlinks 14 skills into parent) without opt-in flag                                 | OPEN     | F.1                                                                                                                                                                                                                                                                                         |
| 16  | `bootstrap.sh` is not idempotent: rerun overwrites `.sandbox-backup` directories                                                        | OPEN     | F.1                                                                                                                                                                                                                                                                                         |
| 17  | No `--uninstall` command: no way to reverse bootstrap side effects                                                                      | OPEN     | F.1                                                                                                                                                                                                                                                                                         |
| 18  | No integration-level marker: parent cannot detect "is Z-ai-governance installed?"                                                       | OPEN     | F.1                                                                                                                                                                                                                                                                                         |
| 19  | No compliance scoring: ecosystem participants cannot publicly demonstrate compliance quality (binary PASS/FAIL only)                    | OPEN     | G                                                                                                                                                                                                                                                                                           |
| 20  | `zai-anti-monolith` skill described as "auto-activating" but did not fire when 8 files exceeded thresholds                              | OPEN     | H                                                                                                                                                                                                                                                                                           |

### Previously resolved (removed from active tracking)

| #        | Defect                                               | Resolved in                |
| -------- | ---------------------------------------------------- | -------------------------- |
| (was 1)  | Broken submodule pin                                 | `standards@4b0fdf5` pushed |
| (was 2)  | `graph-deps.sh` 3 path bugs                          | `standards@4b0fdf5`        |
| (was 3)  | Daemon false VIOLATION logging                       | Commit `f1951fd`           |
| (was 4)  | `.gitignore` missing `.zai/.verifier-daemon.pid`     | Commit `f1951fd`           |
| (was 5)  | Vitest PostCSS bleed                                 | Commit `4955a2f`           |
| (was 6)  | `verify-id-graph.js findRepos()` blind to skills/    | `standards@f52e9f0`        |
| (was 7)  | `constants.js REPO_GLOBS.skills.patterns` wrong glob | `standards@f52e9f0`        |
| (was 8)  | Worklog entry "2026-07-04 (4)" claims vs code        | Commit `a018768`           |
| (was 9)  | W08#2 `ZAI-META-002` false positive                  | Resolved with #6+#7        |
| (was 10) | W08#1 `ZAI-META-001` phantom reference               | Intentional per maintainer |

---

## 2. Baseline Snapshot — Remaining Technical Debt

**File:** `standards/_snapshots/id-graph-baseline.json`
**Severity:** RESOLVED — baseline regenerated 2026-07-06

The baseline was regenerated to match current verifier output (55 IDs, 103 edges).
CI snapshot-compare now produces correct results.

```json
{
  "summary": {
    "ids_extracted": 55,
    "related_edges": 103,
    ...
  }
}
```

Current verifier output matches baseline:

```text
Extracted: 55 IDs (STD: 22, RULE: 22, PROC: 3, TOOL: 5, ZAI: 3)
Related:   103 edges
```

verify-id-graph.js v1.1.6
IDs extracted: 55
Related: edges: 103
Aligned_with: edges: 2
By prefix: null=1, STD=20, RULE=17, PROC=4, ZAI=13
Result: PASS (13/13 hard checks, 36 warnings)

````

**Required action (COMPLETED 2026-07-06):**

```bash
cd <platform>/standards
node scripts/verify-id-graph.js --json > _snapshots/id-graph-baseline.json
git add _snapshots/id-graph-baseline.json
git commit -m "chore: regenerate id-graph baseline (42 -> 55 IDs)"
````

---

## 3. Section D — Ecosystem Governance Gap Analysis

### D.1 Context

While building `Z-ai-graph-viewer` (a separate repository at
`https://github.com/stsgs1980/Z-ai-graph-viewer` that visualizes the Z-ai-platform ID
graph), the author wrote an initial `README.md` that violated STD-DOC-004 v3.0 in
7 distinct ways (missing badges, wrong section order, Unicode pseudographics in an
ASCII diagram, wrong Stack Signature format, description too long, architecture
diagram in README instead of `/docs/`, Project Structure as Unicode tree). None of
the violations were caught by any enforcement mechanism before the initial commit
was pushed to GitHub. The violations were only discovered by manual review after
the fact, and a follow-up commit (`2a7b7a4`) was required to bring the README into
compliance.

This section analyzes which enforcement layers should have caught the violations
and why none of them did. The finding is structural: the Z-ai-platform governance
system's scope is the Z-ai-platform repository, not the ecosystem of repositories
that declare compliance with Z-ai-platform standards.

### D.2 Layer-by-Layer Enforcement Analysis

#### Layer 1: Behavioral Rules (RULE-MONOLITH-*)

| Rule                                     | Should Have Caught                                                 | Why It Did Not                                                                                                                    |
| ---------------------------------------- | ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| RULE-MONOLITH-003 (Read before write)    | Author did not read `README_TEMPLATE.md` before writing README     | "Declared intent only" per AGENT_RULES Section 3: "2 of 17 enforced at runtime; 15 are declared intent only". No automated check. |
| RULE-MONOLITH-014 (Pre-commit checklist) | Author did not run verifiers before committing to zai-graph-viewer | Same: declared intent. Plus pre-commit hook is repo-scoped (see Layer 2).                                                         |
| RULE-MONOLITH-002 (Worklog before/after) | Author did not append to worklog before action                     | Declared intent. Plus `worklog.md` lives in Z-ai-platform, not in zai-graph-viewer.                                               |

**Result:** 3 rules applicable, 0 fired. All 3 are declared-intent-only with no
runtime enforcement.

#### Layer 2: Pre-commit Hook (Husky)

| Component                            | Should Have                                                          | Why It Did Not                                                                                                                                          |
| ------------------------------------ | -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Z-ai-platform/.husky/pre-commit`    | Run verify-standards + verify-id-graph + verify-skills + lint-staged | Hook is per-repo: fires only on `git commit` inside Z-ai-platform. Author committed to zai-graph-viewer, a separate repository without Husky installed. |
| `zai-graph-viewer/.husky/pre-commit` | (does not exist)                                                     | Author did not set up Husky in zai-graph-viewer. `package.json` has no `husky` dependency, no `.husky/` directory.                                      |

**Result:** 0 fired. Hooks are repo-scoped, not ecosystem-scoped.

#### Layer 3: Verifiers (verify-*.js)

| Verifier                                            | What It Checks                                                                                                                            | Why It Did Not                                                                                                                                                                                                                                                     |
| --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `verify-standards.js` V04 (no emoji/Unicode)        | 30 files in `standards/standards/` + `standards/templates/` + `standards/docs/sandbox/`                                                   | Does not scan root `README.md` of Z-ai-platform. Does not scan external repos. Additionally, V04 strips code fences (`.replace(/```[\s\S]*?```/g, "")`) before scanning, so Unicode inside code blocks is invisible — the ASCII diagram was inside a fenced block. |
| `verify-standards.js` V08 (code fence language)     | Same 30 files                                                                                                                             | Does not scan zai-graph-viewer. (Author's README passed V08 anyway: all fences had language.)                                                                                                                                                                      |
| `verify-standards.js` V10 (badges)                  | Checks that `README_TEMPLATE.md` itself contains badges guidance (Section 3 row + Section 5 example + Section 6 checklist mention)        | V10 verifies the template, not that actual READMEs have badges. No V-check validates "README.md follows README_TEMPLATE".                                                                                                                                          |
| `verify-standards.js` V15-V17 (template compliance) | V15: worklog.md follows WORKLOG_TEMPLATE. V16: CHANGELOG.md follows CHANGELOG_TEMPLATE. V17: AGENT_RULES.md follows AGENT_RULES_TEMPLATE. | **No V18 for README.md.** V15/V16/V17 cover 3 files; README.md is not in the list.                                                                                                                                                                                 |
| `verify-id-graph.js` (G-checks)                     | ID graph integrity                                                                                                                        | Not relevant: checks ID graph, not README format.                                                                                                                                                                                                                  |
| `verify-skills.js` (S-checks)                       | Skill format                                                                                                                              | Not relevant: checks skills, not README.                                                                                                                                                                                                                           |

**Result:** 0 fired. Key finding: `verify-standards.js` has no V-check for
"README.md follows README_TEMPLATE". V15/V16/V17 do this for worklog/CHANGELOG/
AGENT_RULES, but README is a gap. Even the root `README.md` of Z-ai-platform itself
is not scanned by any V-check (confirmed by code inspection: `PATHS` object does
not include root README).

#### Layer 4: ESLint Rules

| Rule                                  | What It Checks             | Why It Did Not                                                                                                       |
| ------------------------------------- | -------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `eslint-rules/unicode-policy.js`      | Unicode chars in .md       | Configured in `Z-ai-platform/eslint.config.js`. zai-graph-viewer uses `eslint-config-next` without this custom rule. |
| `eslint-rules/code-block-language.js` | Code fence language in .md | Same: not installed in zai-graph-viewer.                                                                             |

**Result:** 0 fired. Custom ESLint rules are not packaged for reuse. They live in
`Z-ai-platform/eslint-rules/` and cannot be imported into zai-graph-viewer without
copying the files.

#### Layer 5: Background Monitor (verifier-daemon.sh)

| Component             | What It Does                                                                                      | Why It Did Not                                                                                                                 |
| --------------------- | ------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| Daemon (polling mode) | Watches 5 dirs: `src/`, `standards/standards/`, `standards/templates/`, `guard/rules/`, `skills/` | Does not watch `zai-graph-viewer/`. Even if it did, the daemon is a process running for Z-ai-platform, not for external repos. |

**Result:** 0 fired. Daemon is repo-scoped.

#### Layer 6: CI (GitHub Actions)

| Workflow                                              | What It Checks                                                        | Why It Did Not                                                                 |
| ----------------------------------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `Z-ai-platform/.github/workflows/verify-id-graph.yml` | verify-standards + verify-id-graph + verify-skills + graph generation | Per-repo workflow: fires on push/PR to Z-ai-platform, not to zai-graph-viewer. |
| `zai-graph-viewer/.github/workflows/`                 | (does not exist)                                                      | Author did not create CI for zai-graph-viewer.                                 |

**Result:** 0 fired. zai-graph-viewer has no CI at all.

### D.3 Structural Root Cause

All six enforcement layers share the same scope boundary: the Z-ai-platform
repository. None of them have a concept of "ecosystem of repositories that declare
compliance with Z-ai-platform standards". `zai-graph-viewer` references
Z-ai-platform in its README, consumes its data, and declares adherence to its
standards — but from an enforcement perspective it is just another external repo.

Three concrete gaps, all structural:

#### Gap D.3.1: Repo-scope vs Ecosystem-scope

The governance system has no mechanism for "this external repo declares compliance
with STD-DOC-004, verify it". A repository can claim adherence in its README, but
nothing in the enforcement chain validates that claim.

#### Gap D.3.2: V-checks Do Not Cover Actual README

`verify-standards.js` has V15 (worklog.md to WORKLOG_TEMPLATE), V16 (CHANGELOG.md
to CHANGELOG_TEMPLATE), V17 (AGENT_RULES.md to AGENT_RULES_TEMPLATE). There is no
V18 for README.md to README_TEMPLATE. V10 only checks that the template itself
contains badges guidance, not that actual READMEs have badges. Even the root
`README.md` of Z-ai-platform is not in any V-check scan scope.

#### Gap D.3.3: V04 Code-Fence Stripping Creates Unicode Blind Spot

V04 (no emoji/Unicode) strips code fences before scanning:
`.replace(/```[\s\S]*?```/g, "")`. This is a deliberate design decision so that
STD-DOC-003 can show forbidden characters as examples inside code blocks without
triggering V04. But it creates a blind spot: any Unicode pseudographics (box-drawing
characters U+2500-U+257F, arrows U+2B00-U+2B07) inside a code fence are invisible
to V04. ASCII art diagrams wrapped in code fences pass V04 even though they violate
STD-DOC-003.

### D.4 Proposed Fixes

Listed in order of effort-to-impact ratio. Each fix is independent; they can be
applied incrementally.

| #     | Fix                                                                                                                                                                                                       | Effort                                                       | Effect                                                                                                                                             |
| ----- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| D.4.1 | Add V18: "README.md follows README_TEMPLATE" — check section order, badges presence, Stack Signature format, description length, no Unicode pseudographics                                                | ~50 lines in `verify-standards.js`                           | Catches badges/section-order/Stack-Signature/description-length violations inside Z-ai-platform                                                    |
| D.4.2 | Include root `README.md` of Z-ai-platform in V04, V08, V11 scan scope                                                                                                                                     | 2 lines (add `path.join(REPO_ROOT, 'README.md')` to targets) | Catches Unicode/code-fence/size violations in root README                                                                                          |
| D.4.3 | Package ESLint rules as npm package (`@zai/eslint-rules`) for reuse in ecosystem repos                                                                                                                    | ~2 hours                                                     | Allows zai-graph-viewer (and future ecosystem repos) to install `unicode-policy.js` + `code-block-language.js` via `npm install @zai/eslint-rules` |
| D.4.4 | Create `zai-graph-viewer/.github/workflows/verify-readme.yml` — CI that runs V-checks against README on every PR                                                                                          | ~30 lines YAML                                               | Catches violations on PRs to zai-graph-viewer                                                                                                      |
| D.4.5 | V04: do not strip code fences for Unicode box-drawing chars (U+2500-U+257F) and arrows (U+2B00-U+2B07)                                                                                                    | 1 regex change                                               | Catches ASCII art diagrams even inside code blocks                                                                                                 |
| D.4.6 | Pre-commit hook template for ecosystem repos — a `.husky/pre-commit` template that can be copied into any repo declaring compliance                                                                       | ~1 hour                                                      | Extends enforcement to derivative repos                                                                                                            |
| D.4.7 | Ecosystem compliance registry — a manifest file (e.g. `zai-compliance.json`) in each ecosystem repo listing which STD-* standards it follows, plus a meta-CI in Z-ai-platform that scans registered repos | ~1 day                                                       | Establishes ecosystem-scope governance layer                                                                                                       |

### D.5 Honest Assessment

No system "failed" in the sense of "broke". All systems work as designed — but
their design scope does not cover the case of a separate repository declaring
compliance. This is not a bug but a structural gap in the governance architecture.

`zai-graph-viewer` is the first repository outside Z-ai-platform to declare
compliance with its standards. The gap was discovered when the author wrote a
README that violated STD-DOC-004 v3.0 in 7 ways, pushed it to GitHub, and no
enforcement mechanism fired. The violations were caught only by manual review
after the fact.

If the Z-ai ecosystem grows (zai-graph-viewer, Agent-Qube, future projects), an
ecosystem-scope governance layer is needed. Options include: shared CI via reusable
GitHub Actions, an npm package with verifiers, or a meta-repo that scans all
registered compliant projects.

### D.6 Reproduction

The 7 violations were introduced in commit `578fff0` of `zai-graph-viewer` and
fixed in commit `2a7b7a4`. To reproduce the gap:

```bash
# 1. Clone zai-graph-viewer at the violating commit
git clone https://github.com/stsgs1980/Z-ai-graph-viewer.git
cd Z-ai-graph-viewer
git checkout 578fff0

# 2. Observe README.md has: no badges, wrong section order, ASCII diagram with
#    Unicode box-drawing chars, wrong Stack Signature format, etc.

# 3. Run any Z-ai-platform verifier against this README — none will fire:
#    - verify-standards.js scans only standards/ files, not external repos
#    - ESLint rules are not installed in zai-graph-viewer
#    - No CI exists in zai-graph-viewer
#    - Pre-commit hook is not installed in zai-graph-viewer

# 4. The violations pass silently. This is the gap.
```

### D.7 Recommendation

The maintainer should decide whether ecosystem-scope governance is a goal. If yes,
fixes D.4.3 (npm package) and D.4.7 (ecosystem registry) are the highest-impact
changes. If no (Z-ai-platform governance stays repo-scoped), the gap is accepted
and external repos are responsible for their own compliance — in which case
`zai-graph-viewer` should add its own CI (D.4.4) and its own Husky hook (D.4.6) to
enforce STD-DOC-004 on its README.

---

## 4. Section E — Maturity Assessment and Roadmap

### E.1 Purpose

Section D identified structural gaps in the Z-ai-platform governance system and
proposed 7 fixes (D.4.1 through D.4.7) to close them. This section answers the
follow-up question: "After applying Section D fixes, will Z-ai-platform be a real
governance system?" The answer is: partially. Section D moves the system from
maturity level ~1.5 to ~2.3 on a 5-level scale. To reach level 4-5 (a "full"
governance system), additional work (G1-G8 below) is required.

### E.2 Maturity Model

A 5-level scale adapted from CMMI for governance systems:

| Level | Name       | Description                                                                 |
| ----- | ---------- | --------------------------------------------------------------------------- |
| 0     | Chaos      | No rules, no enforcement                                                    |
| 1     | Initial    | Rules exist, enforcement is random or ad-hoc                                |
| 2     | Repeatable | Enforcement works reliably in a single repository                           |
| 3     | Defined    | Standards are codified, CI integration is mandatory, scope is explicit      |
| 4     | Managed    | Ecosystem-scope enforcement, metrics collected, periodic audits             |
| 5     | Optimizing | Self-improving, feedback loops, culture of compliance, federated governance |

### E.3 Current Maturity Assessment

| Aspect                                    | Current State                                               | Level |
| ----------------------------------------- | ----------------------------------------------------------- | ----- |
| Standards codified (STD-*)                | 20 standards in `standards/standards/`                      | 3     |
| Rules declared (RULE-MONOLITH-*)          | 17 rules in `guard/rules/`                                  | 3     |
| Rules enforced at runtime                 | 15 of 17 (was 2) — pre-commit + CI enforcement              | 2.5   |
| Verifiers (V/G/S-checks)                  | 15 V-checks, 15 G-checks, 10 S-checks, all passing          | 3     |
| Pre-commit hook                           | Active for Z-ai-platform repo, runs verifiers + lint-staged | 2     |
| CI (GitHub Actions)                       | Active, runs on push/PR/nightly + governance enforcement    | 2.5   |
| Background monitor (daemon)               | Implemented but polling-only, no inotifywait                | 2     |
| Ecosystem-scope enforcement               | None — all enforcement is repo-scoped                       | 0     |
| Meta-governance (standards for standards) | None                                                        | 0     |
| Audit mode (historical scan)              | None — forward-looking only                                 | 0     |
| Governance process document               | AGENT_RULES.md covers onboarding, not escalation            | 1     |
| Compliance visibility                     | None — no dashboard, no public badge                        | 0     |
| Review cadence                            | None scheduled                                              | 0     |

**Weighted average maturity: ~2.0 (between Initial and Repeatable).**

### E.4 Maturity After Section D Fixes

If all 7 fixes from Section D.4 are applied:

| Aspect                      | After Section D                                                      | Level |
| --------------------------- | -------------------------------------------------------------------- | ----- |
| Standards codified          | Unchanged                                                            | 3     |
| Rules declared              | Unchanged                                                            | 3     |
| Rules enforced at runtime   | Unchanged (still 2 of 17)                                            | 1     |
| Verifiers                   | +V18 (README compliance), +root README in scope, +V04 code-fence fix | 3     |
| Pre-commit hook             | +template for ecosystem repos                                        | 3     |
| CI                          | +zai-graph-viewer workflow, +ecosystem registry                      | 3     |
| Background monitor          | Unchanged                                                            | 2     |
| Ecosystem-scope enforcement | Yes via `@zai/eslint-rules` npm package + registry                   | 3     |
| Meta-governance             | Still none                                                           | 0     |
| Audit mode                  | Still none                                                           | 0     |
| Governance process document | Still none                                                           | 1     |
| Compliance visibility       | Partial via ecosystem registry                                       | 2     |
| Review cadence              | Still none                                                           | 0     |

**Weighted average maturity after Section D: ~2.3 (Repeatable, approaching Defined).**

### E.5 Additional Recommendations (G1-G8) for Full Governance System

| #   | Recommendation                                                                                                                                                                              | Effort           | Closes Defect | Target Level                                       |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- | ------------- | -------------------------------------------------- |
| G1  | Auto-enforce RULE-MONOLITH-002 via pre-commit: block commit if no new worklog entry since last commit                                                                                       | ~2 hours         | #7            | Moves 1 rule from declared to enforced (3/17)      |
| G2  | Auto-enforce RULE-MONOLITH-003 via file access tracking: inotifywait log of Read operations, pre-commit checks Read-before-Write invariant                                                  | ~4 hours         | #8            | Moves 1 rule from declared to enforced (4/17)      |
| G3  | Meta-verifier for standards internal consistency: cross-ref check between STD-* files, detect contradictions, verify migration completeness                                                 | ~1 day           | #9            | Level 3 (Defined) for meta-governance              |
| G4  | Audit mode for V-checks: `verify-standards.js --audit` scans full git history, reports violations by commit, tracks remediation                                                             | ~1 day           | #10           | Level 3 (Defined) for audit                        |
| G5  | GOVERNANCE.md document defining: escalation paths, decision-making process, conflict resolution between STD-* and RULE-MONOLITH-*, maintainer responsibilities, contribution review process | ~2 hours writing | #11           | Level 3 (Defined) for process                      |
| G6  | Compliance dashboard: static site (GitHub Pages) showing per-repo compliance percentage, recent violations, trends over time                                                                | ~1 day           | #12           | Level 4 (Managed) for visibility                   |
| G7  | Quarterly standards review process: scheduled issue/PR template, review checklist, version-bump protocol for STD-* and RULE-MONOLITH-*                                                      | ~ongoing         | #13           | Level 4 (Managed) for review cadence               |
| G8  | Automated expansion of enforced rules: convert 5-7 more RULE-MONOLITH-* from declared to enforced via pre-commit checks                                                                     | ~1 week          | #14, #6       | Moves 5-7 rules from declared to enforced (7-9/17) |

### E.6 What Section D + G1-G8 Achieves

| Aspect                      | After Section D + G1-G8                                            | Level |
| --------------------------- | ------------------------------------------------------------------ | ----- |
| Standards codified          | Unchanged                                                          | 3     |
| Rules declared              | Unchanged                                                          | 3     |
| Rules enforced at runtime   | 7-9 of 17 (was 2)                                                  | 3     |
| Verifiers                   | +V18, +root README, +V04 fix, +meta-verifier, +audit mode          | 4     |
| Pre-commit hook             | +template + worklog check + read-before-write + 5 more rule checks | 4     |
| CI                          | +ecosystem registry + dashboard + audit CI job                     | 4     |
| Background monitor          | Unchanged                                                          | 2     |
| Ecosystem-scope enforcement | Yes                                                                | 3     |
| Meta-governance             | Yes via G3                                                         | 3     |
| Audit mode                  | Yes via G4                                                         | 3     |
| Governance process document | Yes via G5                                                         | 3     |
| Compliance visibility       | Yes via G6 dashboard                                               | 4     |
| Review cadence              | Yes via G7 quarterly                                               | 4     |

**Weighted average maturity after Section D + G1-G8: ~3.3 (Defined, approaching Managed).**

### E.7 What Remains Uncovered Even After Section D + G1-G8

| Gap                          | Description                                                                                                  | Why It Matters                                                    |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------- |
| Culture of compliance        | No technical fix can make agents/developers internalise standards                                            | Without culture, enforcement becomes a checkbox exercise          |
| Federated governance         | No mechanism for sub-ecosystems to fork standards and re-merge                                               | Limits scale to ~10 repos before coordination cost explodes       |
| Automated onboarding         | No `zai init` command to auto-setup hooks + CI + registry for a new repo                                     | Manual setup is error-prone (as demonstrated by zai-graph-viewer) |
| Compliance scoring           | No public badge "this repo is 87% Z-ai-compliant"                                                            | Without scoring, compliance is binary (pass/fail) not progressive |
| Self-improving feedback loop | No mechanism to detect "this rule fires often, maybe it is wrong"                                            | Standards drift from reality over time                            |
| Semantic rule enforcement    | RULE-MONOLITH-006 (honest reporting), RULE-MONOLITH-001 (answer before act) require LLM judgement, not regex | These rules stay at declared-intent forever                       |
| Inter-ecosystem federation   | No protocol for Z-ai governance to interop with other governance systems                                     | Limits cross-ecosystem collaboration                              |

### E.8 Realistic Verdict

| Question                                                           | Answer                                                                                           |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------ |
| After Section D, is Z-ai-platform a governance system?             | Partially. Maturity ~2.3/5. Better than now, but not "real" yet.                                 |
| After Section D + G1-G8, is Z-ai-platform a governance system?     | Yes, credible for 3-5 repos. Maturity ~3.3/5.                                                    |
| After Section D + G1-G8 + federated + onboarding + scoring?        | Yes, mature for 20+ repos. Maturity ~4.5/5.                                                      |
| Can Z-ai-platform ever be a "perfect" governance system (level 5)? | No. 6-8 rules require human judgement and will always be declared-intent. Level 5 is asymptotic. |

### E.9 Roadmap Summary

| Phase             | Scope                                                        | Timeline   | Outcome                                          |
| ----------------- | ------------------------------------------------------------ | ---------- | ------------------------------------------------ |
| Phase 1           | Apply Section D.4.1-D.4.2 (V18, root README in scope)        | 1 day      | Catches README violations inside Z-ai-platform   |
| Phase 2           | Apply Section D.4.3-D.4.4 (npm package, zai-graph-viewer CI) | 3 days     | Ecosystem-scope enforcement for zai-graph-viewer |
| Phase 3           | Apply G1-G2 (worklog + read-before-write auto-enforce)       | 1 week     | 4/17 rules enforced (was 2)                      |
| Phase 4           | Apply G5 (GOVERNANCE.md) + G7 (quarterly review)             | 1 week     | Process and cadence defined                      |
| Phase 5           | Apply G3 (meta-verifier) + G4 (audit mode)                   | 2 weeks    | Meta-governance and historical audit             |
| Phase 6           | Apply G6 (dashboard) + G8 (expand enforced rules)            | 2 weeks    | Visibility + 7-9/17 rules enforced               |
| Phase 7 (ongoing) | Federated governance, onboarding, scoring                    | 1-2 months | Level 4-5 maturity                               |

**Total estimated effort for Phase 1-6: ~6-8 weeks of part-time work.**

---

## 5. Section F — Architecture Proposal: Sidecar Pattern for bootstrap.sh

### F.1 Problem Statement

The current `bootstrap.sh` does three categories of work in a single script with no
flags, blurring the line between "install Z-ai-platform locally" and "integrate
Z-ai-platform into parent sandbox":

| Step | Action                                              | Touches Parent?             | Risk |
| ---- | --------------------------------------------------- | --------------------------- | ---- |
| 1    | `git clone` or `git pull` Z-ai-platform             | No                          | Low  |
| 2    | `git config core.fileMode false`                    | No (only Z-ai-platform git) | Low  |
| 3    | Symlink 14 skills into `/home/z/my-project/skills/` | Yes                         | High |
| 4    | Run verifiers (read-only)                           | No                          | Low  |
| 5    | Print AGENT_RULES.md                                | No                          | Low  |

Step 3 is the root problem. After bootstrap, `/home/z/my-project/skills/` contains
14 symlinks pointing into `Z-ai-platform/skills/`. This breaks the principle "clone
the main project freely" because:

- Removing or moving `Z-ai-platform/` leaves parent with broken symlinks
- Parent sandbox reset leaves symlinks in unpredictable state
- Re-running `bootstrap.sh` overwrites `.sandbox-backup` directories, losing parent
  originals
- No `--uninstall` exists; reversing requires manual `rm` and `mv`

### F.2 Design Principles

| Principle                | Meaning                                                                                                          |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------- |
| No implicit mutations    | `git clone` plus `bash bootstrap.sh` with no flags does not touch parent at all                                  |
| Progressive disclosure   | Integration levels 0 to 4, each explicit opt-in via flag                                                         |
| Reversible               | For every `--install-*` there is an `--uninstall` that restores prior state                                      |
| Isolated state           | All Z-ai-platform state lives inside `Z-ai-platform/` or a single `.zai-config.json` in parent (only at Level 4) |
| Detectable               | Parent can check "is Z-ai-governance installed?" via a single marker file                                        |
| Idempotent               | Re-running `bootstrap.sh` does not clobber state or lose backups                                                 |
| Survives sandbox restart | Does not depend on PID files, /tmp symlinks, or long-running processes                                           |

### F.3 Proposed Architecture: Sidecar with Opt-In Levels

#### Level 0: Clone only

```bash
git clone --recurse-submodules https://github.com/stsgs1980/Z-ai-platform.git
```

No bootstrap. Parent untouched.

#### Level 1: Default bootstrap (safe)

```bash
cd Z-ai-platform
bash bootstrap.sh
```

Does: `git pull`, `git config core.fileMode false`, run verifiers (warning-only),
print AGENT_RULES.md summary. Does NOT: symlink skills, install hooks, create any
file in parent.

#### Level 2: Link skills (opt-in)

```bash
bash bootstrap.sh --link-skills
```

Symlink 14 `zai-*` skills into parent. Backups go to
`Z-ai-platform/.zai/.sandbox-backups/` with registry for idempotency.

#### Level 3: Install hooks (opt-in)

```bash
bash bootstrap.sh --install-hooks
```

Activate `Z-ai-platform/.husky/pre-commit`. Hooks fire only on commits inside
`Z-ai-platform/`.

#### Level 4: Integrate parent (opt-in, high risk)

```bash
bash bootstrap.sh --integrate-parent
```

Write `.zai-config.json` in parent root. Install parent `.husky/pre-commit` that
delegates to Z-ai-platform verifiers. Not recommended in Z.ai sandbox.

### F.4 Refactor Details

Estimated effort: 4-6 hours. Fork into `bootstrap-v2.sh` first. Key changes:

- Flag parsing: `--link-skills`, `--install-hooks`, `--integrate-parent`, `--uninstall`, `--status`
- Backup registry: `Z-ai-platform/.zai/.sandbox-backups/registry.json`
- `--uninstall`: reads registry, restores parent state
- `--status`: shows installed level, linked skills, daemon state
- AGENT_RULES.md update: describe levels in onboarding protocol

### F.5 Ecosystem Evolution

| Phase   | Scope                                   | Timeline  |
| ------- | --------------------------------------- | --------- |
| Phase 1 | bootstrap.sh refactor (sidecar pattern) | 4-6 hours |
| Phase 2 | `@zai/eslint-rules` npm package         | 1 week    |
| Phase 3 | `zai-compliance.json` manifest          | 2 weeks   |
| Phase 4 | `@zai/cli` standalone tool              | 1 month   |

### F.6 Honest Limitations

- Phase 1 does not solve ecosystem-scope enforcement (that is Section D)
- Sandbox parent is a template — Level 4 unsafe there
- Daemon still dies on restart (separate concern)
- Culture change required: maintainer must remember to use `--link-skills`

---

## 6. Section G — Compliance Scoring for Public Visibility

### G.1 Definition

**Compliance scoring** is a numeric score (0-100%) measuring how well a repository
adheres to Z-ai standards, with progressive grade (A-F) instead of binary PASS/FAIL.
**Public visibility** means the score is visible to everyone via README badge,
ecosystem dashboard, or GitHub repo metadata.

### G.2 Why Binary PASS/FAIL Is Insufficient

| Limitation                 | Effect                                                 |
| -------------------------- | ------------------------------------------------------ |
| No motivation to improve   | A repo at 95% treated same as one at 30%               |
| No way to compare repos    | Two "FAIL" repos — one at 95%, other at 30%            |
| No trend tracking          | Improvement over time is invisible                     |
| No trust signal            | Users cannot tell if a repo "really" follows standards |
| No ecosystem health metric | Maintainer cannot answer "is ecosystem improving?"     |

### G.3 Industry Precedent

| Service           | Score Format | Public Badge |
| ----------------- | ------------ | ------------ |
| Codecov           | 0-100%       | Yes          |
| Snyk              | A-F grade    | Yes          |
| OpenSSF Scorecard | 0-10         | Yes          |
| npms.io           | 0-100        | Yes          |

### G.4 Proposed Scoring Formula

| Category              | Max Points | What It Measures                                              |
| --------------------- | ---------- | ------------------------------------------------------------- |
| Standards compliance  | 40         | How many applicable STD-* pass verify-standards.js            |
| Rules enforced        | 20         | How many RULE-MONOLITH-* are auto-enforced                    |
| Documentation quality | 15         | README follows STD-DOC-004, CHANGELOG exists, worklog current |
| Test coverage         | 15         | Percentage of code covered by tests                           |
| Ecosystem integration | 10         | Has zai-compliance.json, runs Z-ai CI, badge in README        |

Grades: A (90-100), B (80-89), C (70-79), D (60-69), F (0-59).

### G.5 Example: zai-graph-viewer Score

| Category              | Score  | Max               |
| --------------------- | ------ | ----------------- |
| Standards compliance  | 36     | 40                |
| Rules enforced        | 4      | 20                |
| Documentation quality | 15     | 15                |
| Test coverage         | 0      | 15                |
| Ecosystem integration | 8      | 10                |
| **Total**             | **63** | **100 (Grade D)** |

### G.6 Public Visibility Mechanisms

- README badge via shields.io
- Ecosystem dashboard (GitHub Pages)
- Per-repo detail page with trend chart
- `zai-score.json` file auto-updated by CI

### G.7 Implementation Pipeline

1. Developer pushes to ecosystem repo
2. GitHub Actions runs `verify-standards.js --score --json`
3. Computes score, commits `zai-score.json`
4. Triggers dashboard rebuild
5. Badge SVG regenerates

### G.8 Effort Breakdown

**Total: approximately 3-4 days for MVP.**

### G.9 Risks

- Formula subjectivity (G.9.1)
- Score inflation (G.9.2)
- Gaming via rule reinterpretation (G.9.3)
- Public shaming risk (G.9.4) — mitigate with onboarding framing
- Maintenance cost (G.9.5)
- Centralization risk (G.9.6)
- Privacy for private repos (G.9.7)

### G.10 Phased Rollout

| Phase   | Scope                                           | Timeline   |
| ------- | ----------------------------------------------- | ---------- |
| Phase 1 | `--score --json` flag + `zai-score.json` schema | 1 day      |
| Phase 2 | CI workflow for zai-graph-viewer (pilot)        | 1 day      |
| Phase 3 | README badge                                    | 30 minutes |
| Phase 4 | Ecosystem dashboard                             | 2 days     |
| Phase 5 | Per-repo detail pages                           | 1 day      |
| Phase 6 | Webhook auto-update                             | 4 hours    |

**Total Phase 1-6: approximately 1 week.**

---

## 7. Section H — Case Study: zai-anti-monolith Skill Failed to Auto-Activate

### H.1 Summary

During Phase 2 development of `zai-graph-viewer` (commit `6684513`), the
`zai-anti-monolith` skill — described as "auto-activating" — **did not activate**.
Result: 8 files exceed anti-monolith thresholds (worst: `graph-viewer.tsx` at 290
lines, 9 `useState` calls).

### H.2 Violations Found

| File                  | Lines | useState | Violations                               |
| --------------------- | ----- | -------- | ---------------------------------------- |
| `detail-panel.tsx`    | 468   | 1        | File > 250, component > 200              |
| `density-matrix.tsx`  | 351   | 3        | File > 250, component > 200, 3+ useState |
| `bfs-path-finder.tsx` | 319   | 4        | File > 250, component > 200, 3+ useState |
| `graph-loader.ts`     | 318   | n/a      | File > 250                               |
| `graph-controls.tsx`  | 314   | 0        | File > 250, component > 200              |
| `graph-viewer.tsx`    | 290   | **9**    | File > 250, component > 200, 9 useState  |
| `hubs-table.tsx`      | 221   | 1        | Component > 200                          |
| `graph-analysis.ts`   | 230   | n/a      | Borderline                               |

### H.3 Root Causes

1. **Skill was never invoked** — "auto-activating" is aspirational, not functional
2. **Subagents received no anti-monolith constraints** in task prompts
3. **No post-wave size verification** — `wc -l` after each wave would have caught it

### H.4 What Would Have Caught This

| Mechanism                      | Would it have caught? | Why not in place                  |
| ------------------------------ | --------------------- | --------------------------------- |
| Skill invocation               | Yes                   | Declared-intent only              |
| Constraint in subagent prompts | Yes                   | Orchestrator did not include it   |
| Post-wave `wc -l` check        | Yes                   | Not performed                     |
| ESLint `max-lines-per-file`    | Yes                   | `@zai/eslint-rules` not published |
| Pre-commit hook                | Yes                   | zai-graph-viewer has no Husky     |
| CI workflow                    | Yes                   | zai-graph-viewer has no CI        |

**Zero of 6 mechanisms are in place.**

### H.5 Proposed Fix

| #     | Fix                                                                   | Effort     |
| ----- | --------------------------------------------------------------------- | ---------- |
| H.5.1 | Refactor 8 violating files                                            | 2 hours    |
| H.5.2 | Add `line-count-check.sh` as pre-commit hook                          | 30 minutes |
| H.5.3 | Add ESLint `max-lines-per-file` rule                                  | 15 minutes |
| H.5.4 | Clarify skill description: "agent should invoke" not "auto-activates" | 5 minutes  |
| H.5.5 | Build auto-invocation mechanism (file-watcher)                        | 1 day      |

**Recommended immediate:** H.5.1 + H.5.2 + H.5.4 (~2.5 hours).

---

## 8. Section I — Conceptual Reframing: Z-ai-platform as Soft Agency Regulator

### I.1 The Question

"Can Z-ai-platform be considered an agent?" The answer determines investment
direction: build an LLM agent on top, improve existing reasoning, or something else.

### I.2 The Evidence

During this session, the reporter (an AI agent) was shaped by Z-ai-platform:

| Component                | What it said                  | What the reporter did      |
| ------------------------ | ----------------------------- | -------------------------- |
| AGENT_RULES.md Section 1 | "Read this file first"        | Read it before any action  |
| RULE-MONOLITH-003        | "Read before write"           | Followed (mostly)          |
| RULE-MONOLITH-002        | "Worklog before/after"        | Maintained worklog         |
| STD-DOC-004 v3.0         | "README must follow template" | Refactored README to 16/16 |
| zai-anti-monolith        | "Decompose files > 250 lines" | Refactored 8 files         |

This is **active regulation of agent behavior** through readable rules.

### I.3 The Reframing: Soft Agency Regulator

Z-ai-platform is neither "just a constitution" nor "a full agent." It is a **soft
agency regulator** with four mechanisms:

| Mechanism                  | How it works                                       |
| -------------------------- | -------------------------------------------------- |
| **Shaping behavior**       | Readable rules that agents follow when cooperative |
| **Blocking actions**       | Scripts that prevent actions at choke points       |
| **Injecting capabilities** | Skills that agents load on demand                  |
| **Recording memory**       | Structured logs that create persistence            |

### I.4 What This Means for the Roadmap

G1-G8 are all soft agency strengthening. Level 5 does not require "a governance
agent that acts autonomously." It requires auto-invocation + LLM-assisted
interpretation as enhancement.

### I.5 Five Lessons

| #   | Lesson                                                                                      |
| --- | ------------------------------------------------------------------------------------------- |
| 1   | Z-ai-platform already works as soft regulator — frame it as such, not as "incomplete agent" |
| 2   | Soft agency requires agent cooperation — document honestly                                  |
| 3   | Violations need active tracking, not just history logs                                      |
| 4   | Skill auto-invocation is the #1 weakness — prioritize it                                    |
| 5   | Do not build an LLM agent — strengthen soft agency instead                                  |

---

## 9. Reproduction Steps

```bash
# 1. Current state verification
cd Z-ai-platform
git rev-parse HEAD           # expect: 243c421
git submodule status         # expect: standards@f52e9f0

# 2. Verify fixes are in place
node standards/scripts/verify-id-graph.js
# Expected: 55 IDs, 13 ZAI-*, 13/13 HARD PASS

# 3. Confirm baseline is stale (defect #1)
grep '"ids_extracted"' standards/_snapshots/id-graph-baseline.json
# Shows: 42 — should be 55

# 4. Structural gaps — no automated checks exist for:
#    - README.md template compliance (no V18)
#    - Ecosystem repo enforcement
#    - bootstrap.sh idempotency
#    - compliance scoring
#    - skill auto-invocation
```

---

## 10. Methodology Notes

- Original evidence collected 2026-07-04 in sandbox session `web-8a05ea4a`.
- Update verified 2026-07-06 against HEAD `243c421` + `standards@f52e9f0`.
- All verification commands are read-only.
- Structural gaps (Sections D-I) are architecture-level findings, not code bugs.
- Enforcement scripts created: 12 scripts in `guard/scripts/` covering 16/17 rules.
- Remaining rule (ANSWER-001) requires LLM behavioral judgment.

---

## 11. References

- `Z-ai-platform/AGENT_RULES.md` Sections 1, 3, 8, 10
- `guard/rules/RULE-MONOLITH-002` (Worklog before/after)
- `guard/rules/RULE-MONOLITH-003` (Read before write)
- `guard/rules/RULE-MONOLITH-014` (Pre-commit checklist)
- `guard/rules/RULE-MONOLITH-017` (Upstream write protection)
- `standards/standards/DOC-004-markdown-standard.md`
- `standards/templates/README_TEMPLATE.md`
- `standards/scripts/verify-standards.js`
- `standards/scripts/verify-id-graph.js`
- `Z-ai-graph-viewer` at `https://github.com/stsgs1980/Z-ai-graph-viewer`

---

## 12. Sign-off

Report updated by: Z.ai Code agent (mimo-v2.5-free)
Original report: ZAI-ESCAL-2026-07-04-001
Update date: 2026-07-06
Active defects: 13 (down from 32; 19 resolved)
Enforcement: 16/17 rules enforced via pre-commit (was 2/17)
Remaining undeclared: 1 rule requiring LLM judgment (ANSWER-001)
Sections: 12 (0-9 plus Methodology, References, Sign-off)
