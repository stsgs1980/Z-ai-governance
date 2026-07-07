---
id: RULE-READ-003
title: Read before write
version: 1.0
level: [C]
status: ACTIVE
source: Z-ai-guard v3.0.0 (RULE-READ-003)
owning-standard: STD-META-001 v2.0
last-updated: 2026-06-17
related:
  - RULE-DOC-010
---

# RULE-READ-003: Read before write

- NEVER write a file without reading it first (Read tool)
- Exception: if file does not exist (verify via LS/Glob)
- Reason: without reading, agent risks destroying existing code
