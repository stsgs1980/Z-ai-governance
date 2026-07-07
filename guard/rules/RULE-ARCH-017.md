> **DEPRECATED (v1.3.0):** This rule was written for the multi-repo submodule architecture. The repository is now a flat copy (Z-ai-governance) with no submodules. Upstream write protection for the governance layer is still conceptually valid (do not modify governance files in consumer projects), but submodule-specific mechanics no longer apply.

---
id: RULE-ARCH-017
title: Upstream write protection (no consumer agent may push to AHG)
version: 1.0
level: [C]
status: ACTIVE
source: Z-ai-guard v3.0.0 (RULE-ARCH-017)
owning-standard: STD-META-001 v2.0
last-updated: 2026-06-17
related:
  - RULE-INTEGRITY-011
  - RULE-ARCH-016
  - STD-ARCH-001
---

# RULE-ARCH-017: Upstream write protection (no consumer agent may push to AHG)

No agent running in a consumer project context may push, merge, create PRs,
or modify the AHG upstream repository in any way. The AHG repository is
maintained exclusively by its owner. Consumer projects are READ-ONLY consumers
of the AHG submodule.

**The problem this rule solves:**
Consumer project agents (e.g. HH-Copilot, ProjectB-agent) have access to the
AHG submodule directory inside their project. Without this rule, an agent can:

- Push branches to the AHG upstream repository
- Create pull requests against AHG main
- Claim "my fix is already merged via PR #N" and update the submodule pointer
- Merge their own PRs if branch protection is not configured

This is NOT a theoretical risk -- it has already happened. A consumer project
agent pushed branch `fix/pre-commit-bun-path` and merged it as PR #8 into
AHG main, bypassing review. The fix was incorrect (used `git rev-parse
--show-toplevel` which returns wrong path in submodules) and had to be
superseded by a proper fix in PR #9.

**Forbidden actions for consumer project agents (this extends Rule 16):**

1. `git push` from inside the AHG submodule directory
2. Creating branches in the AHG upstream repository
3. Creating pull requests against the AHG repository
4. Merging or approving PRs in the AHG repository
5. Claiming a fix has been merged into AHG upstream without owner confirmation
6. Updating the submodule pointer to an unverified commit
7. Running `AHG_MODULE_PUSH=1 git push` from a consumer project context
8. Modifying AHG files and committing them directly (not via submodule update)

**What consumer project agents MUST do instead:**

- If AHG has a bug: report it to the owner, do NOT fix it yourself in the upstream
- If AHG hooks block a push: fix the consumer project, do NOT patch AHG
- If AHG seems to need an update: ask the owner, do NOT merge PRs yourself
- If you need a newer version of AHG: `git submodule update --remote` after
  the owner publishes a release

**Enforcement layers (defense in depth):**

1. **Rule 16 + Rule 17**: Agent-level prohibition in AGENT_RULES.md
2. **CODEOWNERS**: Only @stsgs1980 can approve changes (requires GitHub
   branch protection with "Require review from Code Owners")
3. **pr-guard.yml workflow**: CI-level check that blocks PRs from forks,
   non-collaborators, and tampering attempts (removing Rule 16/17 or CODEOWNERS)
4. **validate.sh**: Blocks push from inside submodule unless AHG_MODULE_PUSH=1
5. **GitHub branch protection**: Must be configured by owner (see below)

**GitHub branch protection (MUST be configured by owner):**

```
Repository Settings > Branches > Branch protection rules > main
  [x] Require a pull request before merging
  [x] Require approvals (1)
  [x] Require review from Code Owners
  [x] Restrict who can push to matching branches (only @stsgs1980)
  [x] Do not allow bypassing the above settings
```

---
