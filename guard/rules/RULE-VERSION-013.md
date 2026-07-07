---
id: RULE-VERSION-013
title: Use ahg bump for version updates
version: 1.1
level: [C]
status: ACTIVE
source: Z-ai-guard v3.0.0 (RULE-VERSION-013)
owning-standard: STD-META-001 v2.0
last-updated: 2026-06-17
related:
  - TOOL-MONOLITH-BUMP
  - RULE-WORKLOG-002
---

# RULE-VERSION-013: Use ahg bump for version updates

When changing the project version, use the atomic bump command:
bash scripts/ahg.sh bump X.Y.Z

This command:

- Auto-discovers ALL files containing version numbers
- Updates them atomically (no file forgotten)
- Adds CHANGELOG entry if CHANGELOG exists
- Supports --dry-run for preview

Do NOT update versions manually in individual files.
Manual updates cause version drift -- one file gets updated,
another is forgotten. ahg bump eliminates this class of errors.
