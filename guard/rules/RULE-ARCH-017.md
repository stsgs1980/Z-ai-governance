> **DEPRECATED (v1.3.0):** This rule was written for the multi-repo submodule architecture. The repository is now a flat copy (Z-ai-governance) with no submodules. Upstream write protection for the governance layer is still conceptually valid (do not modify governance files in consumer projects), but submodule-specific mechanics no longer apply.

---
id: RULE-ARCH-017
title: No direct push to governance source [DEPRECATED]
version: 1.1
level: [C]
status: DEPRECATED
source: Z-ai-governance v1.3.0 (RULE-ARCH-017)
owning-standard: STD-META-001 v2.0
last-updated: 2026-06-17
related:
  - RULE-INTEGRITY-011
  - RULE-ARCH-016
  - STD-ARCH-001
---

# RULE-ARCH-017: No direct push to governance source [DEPRECATED]

> **DEPRECATED (v1.3.0):** This rule was written for the multi-repo submodule architecture.
> The repository is now flat. See ARCH-001 for the current directory layout.

All changes to the governance layer must go through the standard git workflow
(clone, branch, commit, PR, review, merge). Bypassing this process is prohibited.