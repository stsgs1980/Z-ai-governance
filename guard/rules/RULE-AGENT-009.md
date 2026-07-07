---
id: RULE-AGENT-009
title: Session Start Protocol (drift prevention)
version: 1.0
level: [C]
status: ACTIVE
source: Z-ai-guard v3.0.0 (RULE-AGENT-009)
owning-standard: STD-META-001 v2.0
last-updated: 2026-06-17
related:
  - RULE-DOC-010
  - TOOL-MONOLITH-VERIFY
---

# RULE-AGENT-009: Session Start Protocol (drift prevention)

Before ANY work in a new session, the agent MUST:

1. **Scan project structure**: list source files to understand what exists
2. **Read version source of truth** (manifest.json, package.json, etc.)
3. **Compare actual structure with documentation** (ARCHITECTURE.md, README)
4. **If drift > 3 items**: UPDATE DOCUMENTATION FIRST, then do the task
5. **Record scan results** in worklog.md

Detection of drift (automatic flags):

- New files not in ARCHITECTURE.md or docCoverage targets -> flag
- Stub markers in docs but implementation files exist -> flag
- Version in docs != version in source of truth -> flag
- Files mentioned in docs that no longer exist -> flag

This rule prevents the most common documentation decay pattern:
an agent writes code but does not update docs, causing documentation
to gradually become misleading and unreliable.
