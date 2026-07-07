---
id: RULE-COMMIT-004
title: One logical block -- one commit
version: 1.0
level: [C]
status: ACTIVE
source: Z-ai-guard v3.0.0 (RULE-COMMIT-004)
owning-standard: STD-META-001 v2.0
last-updated: 2026-06-17
related:
  - RULE-WORKLOG-002
---

# RULE-COMMIT-004: One logical block -- one commit

- Finished a meaningful chunk of work -> git add -A && git commit
- Commit message: specific description (not "update", not "fix")
- Commit without updated worklog -> ERROR (pre-commit hook will block)
