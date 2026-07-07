---
id: RULE-COMMIT-014
title: Pre-commit mandatory checklist
version: 1.1
level: [C]
status: ACTIVE
source: Z-ai-governance v1.3.0 (RULE-COMMIT-014)
owning-standard: STD-META-001 v2.0
last-updated: 2026-06-17
related:
  - RULE-WORKLOG-002
  - RULE-COMMIT-004
  - TOOL-MONOLITH-VERIFY
  - STD-SEC-002
---

# RULE-COMMIT-014: Pre-commit mandatory checklist

Before EVERY commit, verify ALL of these items:

- [ ] Code written and tested
- [ ] worklog.md updated (hook will verify freshness)
- [ ] If version changed: ahg bump used (not manual edit)
- [ ] If new files added: documented in README/ARCHITECTURE
- [ ] If files deleted: no stale references remain
- [ ] cascade-state.json: task statuses current (auto-sync in hook)
- [ ] verify-docs passes (or discover shows no errors)

If ANY item is unclear: run "bash scripts/ahg.sh discover" first.
Do NOT commit with known documentation drift.
