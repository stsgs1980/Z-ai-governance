> **DEPRECATED (v1.3.0):** This rule was written for the multi-repo submodule architecture (Z-ai-platform with 3 git submodules). The repository is now a flat copy (Z-ai-governance) with no submodules. The core principle — do not restructure the governance layer's relationship to consumer projects — remains valid, but submodule-specific mechanics (pointer bumps, `.gitmodules`, `git submodule update`) no longer apply.

---
id: RULE-ARCH-016
title: AHG submodule is immutable architecture (no removal, no inlining)
version: 1.0
level: [C]
status: ACTIVE
source: Z-ai-guard v3.0.0 (RULE-ARCH-016)
owning-standard: STD-META-001 v2.0
last-updated: 2026-06-17
related:
  - RULE-INTEGRITY-011
  - STD-ARCH-001
---

# RULE-ARCH-016: AHG submodule is immutable architecture (no removal, no inlining)

The anti-hallucination-guard git submodule is a structural component of this
project, not an optional dependency. Agents MUST NOT propose or execute any
action that removes, inlines, or restructures the AHG submodule relationship.

**What the submodule provides (single source of truth):**

- Pre-commit hook: worklog freshness + verify-docs consistency
- Pre-push hook: repository purity + doc consistency enforcement
- setup.sh: idempotent deployment of hooks, scripts, and rules
- update.sh: one-command update (git pull + re-deploy)
- validate.sh: purity enforcement (only AHG files in AHG repo)
- verify-docs: documentation drift detection engine
- cascade-state.json: cross-project version tracking
- AGENT_RULES.md: this rule set (deployed, not hand-written)

**Why a submodule (not inline files):**

1. **Version synchronization**: bugfixes in AHG reach ALL consumer projects
   via `git submodule update`. Inlined copies diverge within days.
2. **Purity validation**: validate.sh can only verify a module repo, not a
   folder mixed with consumer project files. Inlining makes purity checks
   impossible.
3. **Atomic updates**: update.sh pulls + redeploys in one step. With inlined
   files, each project manually copies scripts -- versions drift, fixes are
   lost, hooks silently stop working.
4. **Protected upstream**: the AHG repo has branch protection. Consumer
   projects cannot accidentally push broken changes to the guard system.
5. **Cross-project consistency**: every consumer project runs the SAME version
   of the same hooks. No "HH-Copilot has v2.1 hooks, ProjectB has v1.8 hooks".

**Forbidden actions (this rule extends Rule 11):**

1. Proposing to remove the git submodule and inline AHG files
2. Moving AHG scripts to `scripts/ahg/`, `.ahg/`, or any local path
3. Copying hook files into the project and deleting the submodule reference
4. Suggesting that AHG is "just scripts that could live in the project"
5. Creating a parallel local copy of any AHG-managed file
6. Removing `.gitmodules` entries for anti-hallucination-guard

**What to do when something breaks:**

- If hooks block a push: fix the underlying issue (update worklog, fix docs)
- If validate.sh fails in wrong context: run `bash anti-hallucination-guard/update.sh`
  to update hooks to the latest version with bugfixes
- If a hook has a bug: report it, fix it IN the AHG submodule repo, then
  update the submodule pointer. Do NOT patch hooks locally.
- If the submodule seems unnecessary: re-read this rule. It IS necessary.

**The submodule is not causing problems -- bugs in context detection were.
Those bugs are fixed in the AHG repo. Update the submodule to get fixes.**
