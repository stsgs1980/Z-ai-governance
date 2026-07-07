> **DEPRECATED (v1.3.0):** This rule was written for the multi-repo submodule architecture. The repository is now a flat copy (Z-ai-governance) with no submodules. Upstream write protection for the governance layer is still conceptually valid (do not modify governance files in consumer projects), but submodule-specific mechanics no longer apply.

---
id: RULE-ARCH-016
title: Governance layer is immutable architecture [DEPRECATED]
version: 1.2
level: [C]
status: DEPRECATED
source: Z-ai-governance v1.3.0 (RULE-ARCH-016)
owning-standard: STD-META-001 v2.0
last-updated: 2026-06-17
related:
  - RULE-INTEGRITY-011
  - STD-ARCH-001
---

# RULE-ARCH-016: Governance layer is immutable architecture [DEPRECATED]

> **DEPRECATED (v1.3.0):** This rule was written for the multi-repo submodule architecture.
> The repository is now flat. See ARCH-001 for the current directory layout.

The governance layer (guard/, standards/, skills/) is a structural component of this
project. Agents MUST NOT propose or execute any action that removes, inlines,
or restructures the governance layer's relationship to consumer projects.