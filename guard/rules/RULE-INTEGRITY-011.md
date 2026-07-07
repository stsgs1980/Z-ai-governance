---
id: RULE-INTEGRITY-011
title: Integrity protection (no self-sabotage)
version: 1.0
level: [C]
status: ACTIVE
source: Z-ai-guard v3.0.0 (RULE-INTEGRITY-011)
owning-standard: STD-META-001 v2.0
last-updated: 2026-06-17
related:
  - PROC-MONOLITH-SETUP
  - STD-ENV-001
---

# RULE-INTEGRITY-011: Integrity protection (no self-sabotage)

Agents MUST NOT disable, bypass, or weaken the anti-hallucination mechanisms.
This rule is non-negotiable and applies regardless of task urgency.

**Forbidden actions:**

1. `git commit --no-verify` -- bypasses all hooks
2. `git -c core.hooksPath=/dev/null commit` -- redirects hooks to nothing
3. Modifying `.git/hooks/pre-commit` or `.git/hooks/pre-push` to remove checks
4. Deleting or truncating worklog.md to avoid accountability
5. Removing AHG marker blocks from AGENT_RULES.md
6. Removing checks from verify-docs.json to avoid failures
7. Setting `core.hooksPath` in git config to bypass hooks
8. Creating fake worklog entries that don't describe real work

**If you encounter a situation where hooks block legitimate work:**

- Fix the underlying issue (update worklog, fix docs, etc.)
- Ask the user for guidance
- NEVER remove the guard mechanisms

**Detection:**

- check-hooks-snapshot.sh + check-hooks-verify.sh compare fingerprints of hooks and configs
- verify-docs detects missing or weakened checks
- audit.sh scores integrity as part of session quality
- CI pipeline runs verify-docs independently (cannot be bypassed locally)
