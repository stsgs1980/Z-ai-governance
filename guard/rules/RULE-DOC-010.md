---
id: RULE-DOC-010
title: Documentation sync (no code without docs)
version: 1.0
level: [C]
status: ACTIVE
source: Z-ai-guard v3.0.0 (RULE-DOC-010)
owning-standard: STD-META-001 v2.0
last-updated: 2026-06-17
related:
  - TOOL-MONOLITH-VERIFY
  - STD-DOC-002
---

# RULE-DOC-010: Documentation sync (no code without docs)

When changing the codebase, documentation MUST be kept in sync:

1. **New file** -> add to ARCHITECTURE.md (modules section) + update file counts in README
2. **New functionality** -> remove from "not working" / "stubs" section + add to "working" section
3. **Deleted/renamed file** -> update all references in all docs
4. **Version change** -> update ONLY the source of truth (e.g. manifest.json);
   all other docs must read from there (verified by verify-docs Section 3)

Pre-commit checklist:

- [ ] manifest.json version updated?
- [ ] ARCHITECTURE.md reflects new/changed modules?
- [ ] README.md does not contain stale "stubs"?
- [ ] task state file statuses are current?
- [ ] verify-docs passes without errors?
