# ID Registry — Companion to STD-META-001

> Companion to: STD-META-001 v2.0.5 (Standard ID System)
> Type: Reference appendix, NOT a separate standard
> Last Updated: 2026-06-21
> Status: ACTIVE (reference material)

This file is a **companion reference** to `META-001-standard-id-system.md`
(STD-META-001 v2.0.5). It contains the full ID Registry tables for
RULE-_, PROC-_, TOOL-_, and ZAI-_ IDs (§4.13-§4.17 of the parent standard).

**This file is NOT a separate standard.** It does not have an `STD-` ID of
its own and does not participate in the ID graph. It is referenced from
STD-META-001 §4 as the canonical registry dump.

## Why this file exists

In STD-META-001 v2.0.4, the ID Registry tables (§4.13-§4.17) lived inline
in the main standard file. Combined with §4.18 (File Size Limits, canonical
source) and §12 FAQ, the file exceeded the 1000-line soft cap (W11 warning
from `verify-id-graph.js`). In v2.0.5, the registry tables and FAQ were
moved to companion files to bring STD-META-001 under the soft cap while
preserving all section numbers and content verbatim.

§4.18 (File Size Limits) STAYS in the parent standard because it is the
active enforcement source for RULE-MONOLITH-012 (unchanged) and PROC-LINECOUNT-004 —
it must be in the parser-bound file.

## How cross-references resolve

External references to "STD-META-001 §4.13" through "§4.17" resolve to
this companion file. References to §4.1-§4.12 or §4.18 resolve to
`META-001-standard-id-system.md`. The section numbers are preserved
verbatim (no renumbering) to keep all existing references stable.

---

## 4.13-4.17. ID Registry (extracted from parent §4)

> **Status**: `ACTIVE` = maintained; `FROZEN` = kept for reference;
> `DEPRECATED` = obsolete, do not reference in new content.

### 4.13. Rules (RULE-)

| ID                 | Document                              | Version | Level | Status | File                                  |
| ------------------ | ------------------------------------- | ------- | ----- | ------ | ------------------------------------- |
| RULE-ANSWER-001    | Answer Before Act                     | 1.0     | [C]   | ACTIVE | guard/AGENT_RULES.md             |
| RULE-WORKLOG-002   | Worklog before/after                  | 1.0     | [C]   | ACTIVE | guard/AGENT_RULES.md             |
| RULE-READ-003      | Read before write                     | 1.0     | [C]   | ACTIVE | guard/AGENT_RULES.md             |
| RULE-COMMIT-004    | One logical block per commit          | 1.0     | [C]   | ACTIVE | guard/AGENT_RULES.md             |
| RULE-LOOPS-005     | No loops                              | 1.0     | [C]   | ACTIVE | guard/AGENT_RULES.md             |
| RULE-HONEST-006    | Honest reporting                      | 1.0     | [C]   | ACTIVE | guard/AGENT_RULES.md             |
| RULE-STRUCT-007    | Work structure                        | 1.0     | [W]   | ACTIVE | guard/AGENT_RULES.md             |
| RULE-ENV-008       | Sandbox verification                  | 1.0     | [C]   | ACTIVE | guard/AGENT_RULES.md             |
| RULE-AGENT-009     | Session start protocol                | 1.0     | [C]   | ACTIVE | guard/AGENT_RULES.md             |
| RULE-DOC-010       | Documentation sync                    | 1.0     | [C]   | ACTIVE | guard/AGENT_RULES.md             |
| RULE-INTEGRITY-011 | Integrity protection                  | 1.0     | [C]   | ACTIVE | guard/AGENT_RULES.md             |
| RULE-MONOLITH-012  | Anti-monolith (file size by category) | 1.3     | [C]   | ACTIVE | guard/rules/RULE-MONOLITH-012.md |
| RULE-VERSION-013   | Use verify-docs bump                  | 1.1     | [C]   | ACTIVE | guard/AGENT_RULES.md             |
| RULE-COMMIT-014    | Pre-commit checklist                  | 1.1     | [C]   | ACTIVE | guard/AGENT_RULES.md             |
| RULE-DOC-015       | No Unicode graphics                   | 1.0     | [W]   | ACTIVE | guard/AGENT_RULES.md             |
### 4.14. Procedures (PROC-)

| ID                        | File                                   | Version | Level | Status                                                                                                   |
| ------------------------- | -------------------------------------- | ------- | ----- | -------------------------------------------------------------------------------------------------------- |
| PROC-SETUP-001            | guard/setup.sh                    | 2.0     | [C]   | ACTIVE (planned) — file not yet created                                                                  |
| PROC-UPDATE-002           | guard/update.sh                   | 2.1     | [C]   | ACTIVE (planned) — file not yet created                                                                  |
| PROC-COCHANGE-003         | guard/scripts/co-change-check.sh  | 1.0     | [C]   | ACTIVE — file created 2026-06-22 (implements RULE-DOC-010)                                               |
| PROC-LINECOUNT-004        | guard/scripts/line-count-check.sh | 1.0     | [C]   | ACTIVE — file created 2026-06-22 (implements RULE-MONOLITH-012, delegates to TOOL-VERIFY-002/004)        |
| PROC-PLATFORM-INSTALL-005 | install.sh               | 1.0     | [C]   | RETIRED 2026-06-19 (functions covered by `bootstrap.sh`) |
| PROC-PLATFORM-UPDATE-006  | update.sh                | 1.0     | [C]   | RETIRED 2026-06-19 (superseded by `bootstrap.sh`)                                                        |
| PROC-PLATFORM-DOCTOR-007  | doctor.sh                | 1.0     | [C]   | RETIRED 2026-06-19 (functions covered by `status.sh`) |

> **PROC-PLATFORM-005/006/007 retirement (2026-06-19):**
> Three platform-side procedures were planned but never implemented. The
> functions they would have provided are covered by `bootstrap.sh` (install
> + update + restore in one entry point) and `status.sh` (diagnostic).
> The three IDs are RETIRED with supersession notes; they will not be
> re-used (per §9.2 no-reassignment rule).

### 4.15. Tools (TOOL-)

| ID                    | File                                       | Version | Level | Status                                                                                            |
| --------------------- | ------------------------------------------ | ------- | ----- | ------------------------------------------------------------------------------------------------- |
| TOOL-VERIFY-001       | guard/tools/verify-docs/              | 2.1     | [C]   | ACTIVE (planned) — file not yet created                                                           |
| TOOL-VERIFY-002       | standards/scripts/verify-standards.js | 2.2.0   | [C]   | ACTIVE                                                                                            |
| TOOL-VERIFY-003       | standards/scripts/verify-cascade.js   | 2.2.0   | [C]   | RETIRED 2026-06-18 (one-shot v1.0 cascade check; superseded by TOOL-VERIFY-002 + TOOL-VERIFY-004) |
| TOOL-VERIFY-004       | standards/scripts/verify-id-graph.js  | 1.0.0   | [C]   | ACTIVE (planned) — file exists, status promotes to ACTIVE on first green CI run post-v2.0.2       |
| TOOL-BUMP-005         | guard/tools/verify-docs/src/bump.ts   | 2.1     | [C]   | ACTIVE (planned) — file not yet created                                                           |
| TOOL-CHECKUPDATES-006 | standards/scripts/check-updates.sh    | 2.2.0   | [W]   | ACTIVE                                                                                            |

> **Phantom-ID fix (META v2.0.2, 2026-06-19):** Rows previously marked
> `ACTIVE` for TOOL-VERIFY-001 and TOOL-BUMP-005 referenced files that do
> not exist in guard/. Status is now `ACTIVE (planned)` to reflect
> reality.

### 4.16. Skills (ZAI-)

> **Full registry lives in STD-SKILL-001.** This section is a summary;
> conflicts are resolved in favor of STD-SKILL-001.

#### 4.16.1. Memory (MEM)

| ID          | Skill         | Version | Status |
| ----------- | ------------- | ------- | ------ |
| ZAI-MEM-001 | memory-store  | 1.0     | ACTIVE |
| ZAI-MEM-002 | memory-query  | 1.0     | ACTIVE |
| ZAI-MEM-003 | memory-delete | 1.0     | ACTIVE |
| ZAI-MEM-004 | memory-export | 1.0     | ACTIVE |

#### 4.16.2. File System (FS)

| ID         | Skill          | Version | Status |
| ---------- | -------------- | ------- | ------ |
| ZAI-FS-001 | folder-indexer | 1.0     | ACTIVE |

#### 4.16.3. Session (SESSION)

| ID              | Skill                 | Version | Status |
| --------------- | --------------------- | ------- | ------ |
| ZAI-SESSION-001 | session-log           | 1.1     | ACTIVE |
| ZAI-SESSION-002 | context-consolidation | 1.0     | ACTIVE |
| ZAI-SESSION-003 | session-experience    | 4.0     | ACTIVE |

#### 4.16.4. Development (DEV)

| ID          | Skill                    | Version | Status |
| ----------- | ------------------------ | ------- | ------ |
| ZAI-DEV-001 | project-clone            | 1.0     | ACTIVE |
| ZAI-DEV-002 | commit-work              | 1.0     | ACTIVE |
| ZAI-DEV-003 | database-schema-designer | 1.0     | ACTIVE |

#### 4.16.5. Architecture (ARCH)

| ID           | Skill            | Version | Status |
| ------------ | ---------------- | ------- | ------ |
| ZAI-ARCH-001 | mermaid-diagrams | 1.0     | ACTIVE |
| ZAI-ARCH-002 | anti-monolith    | 1.0     | ACTIVE |

#### 4.16.6. Quality Assurance (QA)

| ID         | Skill           | Version | Status |
| ---------- | --------------- | ------- | ------ |
| ZAI-QA-001 | qa-test-planner | 1.0     | ACTIVE |

#### 4.16.7. Requirements (REQ)

| ID          | Skill                | Version | Status |
| ----------- | -------------------- | ------- | ------ |
| ZAI-REQ-001 | requirements-clarity | 1.0     | ACTIVE |

#### 4.16.8. Meta-skills (META)

| ID           | Skill           | Version | Status               | Note                                                                           |
| ------------ | --------------- | ------- | -------------------- | ------------------------------------------------------------------------------ |
| ZAI-META-001 | skill-id-system | 1.0     | ACTIVE -> SUPERSEDED | Content migrated to STD-SKILL-001 in v2.0; skill itself becomes a thin pointer |
| ZAI-META-002 | skill-creator   | 1.1     | ACTIVE               | Reads STD-SKILL-001 for ID system; no longer defines its own domains           |

#### 4.16.9. User-Created (STS)

| ID          | Skill                      | Version | Status |
| ----------- | -------------------------- | ------- | ------ |
| ZAI-STS-001 | prompt-engineering         | 1.1     | ACTIVE |
| ZAI-STS-002 | sync-toolkit               | 1.0     | ACTIVE |
| ZAI-STS-003 | performance-code-generator | 1.0     | ACTIVE |
| ZAI-STS-004 | frontend-styling-expert    | 1.0     | ACTIVE |
| ZAI-STS-005 | phi-layout                 | 3.0     | ACTIVE |
| ZAI-STS-006 | zai-ui-composer            | 1.1.2   | ACTIVE |
| ZAI-STS-007 | workflow-discipline        | 2.0     | ACTIVE |

#### 4.16.10. Sandbox System Skills (NO ZAI- PREFIX)

Per ZAI-META-001 §4 (preserved in STD-SKILL-001 §6), the following skills
live in the Z.ai sandbox at `/home/z/my-project/skills/` and do **not**
receive ZAI- prefix IDs. They are tracked by folder name only. The list
below is informational; the canonical list is maintained in STD-SKILL-001
§6. They include: `api-retry`, `dev-watchdog`, `fallback`, `gepetto`,
`health-check`, `humanizer`, `phi-layout`, `react-dev`, `reducing-entropy`,
`session-handoff`, `z-ai-web-dev-sdk`, plus sandbox-native skills such as
`fullstack-dev`, `docx`, `pdf`, `xlsx`, `pptx`, `charts`, etc.

### 4.17. Skill System Standard (STD-SKILL-001)

| ID            | Document                 | Version | Level | Status               |
| ------------- | ------------------------ | ------- | ----- | -------------------- |
| STD-SKILL-001 | Skill ID System Standard | 1.0.0   | [C]   | ACTIVE (new in v2.0) |

> New standard hosted at `standards/standards/SKILL-001-skill-format.md`.
> Supersedes the content of ZAI-META-001 (which becomes a thin pointer).
> See §8 for the migration map.

### 4.18. File Size Limits (Canonical Source)

> **Source of truth for RULE-MONOLITH-012 (L2 enforcement).**
> All line-count limits for `.md`, `.ts`, `.tsx`, `.js`, `.py`, `.sh`
> and similar text artifacts are defined HERE. RULE-MONOLITH-012 mirrors
> this table for enforcement; PROC-LINECOUNT-004 (when created) reads
> this section. Domain standards (STD-SKILL-001 §8.2, STD-FE-001 §6,
> STD-DOC-002 §11) reference this section instead of duplicating.
