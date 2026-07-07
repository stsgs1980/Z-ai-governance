# Standard: Skill Format & Identification v1.1 (EN)

> ID: STD-SKILL-001
> Version: 1.1.0
> Level: **[B] Recommended**
> Last Updated: 2026-06-18
> Effective Date: 2026-06-17
> Status: **APPROVED**
> verified_by: scripts/verify-standards.js#V05,V11,V13,V14, scripts/verify-id-graph.js#G01,G02,G14 (when ID present)
> Related: STD-META-001, STD-DOC-002
> Aligned_with: (none — legacy alignment entries removed 2026-07-06; see §12 migration history)
> Implemented_by: RULE-MONOLITH-012 (anti-monolith line limit — see rule for the 250-line cap)

> **Status: APPROVED.** This standard defines the **minimum required format**
> for skills in the Z-ai ecosystem and an **optional** identification system
> for skills that participate in cross-references.
>
> **Key principle:** IDs are **OPTIONAL** for skills.

---

## 1. Purpose

This standard defines:

1. **Required format** for every `SKILL.md` — what fields MUST be present
   for a skill to be valid in the Z-ai ecosystem
2. **Optional identification system** — `ZAI-<DOMAIN>-<NNN>` IDs for skills
   that participate in cross-references or shared registries
3. **Compatibility model** — `both` / `sandbox` / `ade` field that
   declares which runtimes can execute the skill
4. **Trigger conventions** — how `description` and `trigger` should be
   written for accurate skill matching

This standard does **NOT** require every skill to have an ID. The 24
existing `ZAI-*` IDs from toolkit v2.0.5 are preserved unchanged, but
new skills may be created without IDs unless they need to be referenced
from external artifacts.

---

## 2. Two Layers: Required Format vs Optional Identification

```text
┌──────────────────────────────────────────────┐
│  REQUIRED FORMAT (every SKILL.md must have)  │
│  ─────────────────────────────────────────── │
│  • name:        (matches folder name)        │
│  • description: (primary trigger)            │
│  • version:     (SemVer)                     │
│                                              │
│  -> Validated by verify-standards.js V11/V13  │
└──────────────────────────────────────────────┘
                    v
┌──────────────────────────────────────────────┐
│  OPTIONAL IDENTIFICATION                     │
│  ─────────────────────────────────────────── │
│  • id: ZAI-<DOMAIN>-<NNN>                    │
│  • compatibility: both|sandbox|ade           │
│  • trigger: keyword1, keyword2, ...          │
│  • author: <signature>                       │
│                                              │
│  Required only when:                         │
│  • Skill is referenced by ID from STD/RULE   │
│  • Skill is published to shared registry     │
│  • Skill will be deprecated with migration   │
│                                              │
│  -> Validated by verify-id-graph.js           │
│    (only when id is present)                 │
└──────────────────────────────────────────────┘
```

---

## 3. Skill Header Format

### 3.1. Canonical Format

```markdown
---
name: skill-name
description: "Short description with trigger phrases. Use this skill when user asks for X, mentions Y, or needs Z. Also activate on: 'keyword1', 'keyword2'."
version: 1.0
---

# Skill: <Name> v<Version>

> Version: <Version>
> Last Updated: <YYYY-MM>
```

### 3.2. Extended Format (with ID and graph fields)

Use this format when the skill participates in cross-references:

```markdown
---
name: skill-name
description: "..."
id: ZAI-<DOMAIN>-<NUMBER>
version: 1.0
compatibility: both | sandbox | ade
trigger: keyword1, keyword2, keyword3
author: <signature>
license: MIT
---

# Skill: <Name> v<Version>

> ID: ZAI-<DOMAIN>-<NUMBER>
> Version: <Version>
> Last Updated: <YYYY-MM>
> Related: <comma-separated IDs> (optional)
> Aligned_with: <comma-separated IDs> (optional)
```

### 3.3. Field Requirements

| Field           | Required        | Notes                                                                                   |
| --------------- | --------------- | --------------------------------------------------------------------------------------- |
| `name`          | **yes**         | Must match folder name exactly (see §9.1)                                               |
| `description`   | **yes**         | Primary trigger; full sentences with context                                            |
| `version`       | **yes**         | SemVer                                                                                  |
| `id`            | **conditional** | Required if skill is referenced by ID externally; format: `ZAI-<DOMAIN>-<NNN>` (see §4) |
| `compatibility` | **conditional** | Required if `id` present; one of `both` / `sandbox` / `ade` (see §6)                    |
| `trigger`       | recommended     | Comma-separated keywords, 5–15 items max                                                |
| `author`        | optional        | Signature of skill creator; if set to `STS`, the skill follows §9 conventions           |
| `license`       | optional        | Default: MIT                                                                            |

### 3.4. Frontmatter vs Blockquote Consistency

The blockquote header (below H1) is a redundant copy of selected
frontmatter fields for human readability. The frontmatter is canonical.

`verify-standards.js` V14 verifies that (when both are present):

- `id` in frontmatter matches `ID:` in blockquote
- `version` in frontmatter matches `Version:` in blockquote

### 3.5. Where `Related:` and `Aligned_with:` Go

These two fields go in the blockquote below the H1, NOT in YAML
frontmatter. They are graph edges consumed only by `verify-id-graph.js`.

If a skill has no `Related:` or `Aligned_with:`, omit the line entirely.

---

## 4. Optional ID System

### 4.1. ID Format

```text
ZAI-<DOMAIN>-<NUMBER>
```

| Component  | Description                                                                             |
| ---------- | --------------------------------------------------------------------------------------- |
| `ZAI`      | Prefix (Z.ai Agent Toolkit — preserved for backward compatibility with 24 existing IDs) |
| `<DOMAIN>` | Skill domain (2–6 letters, see §4.3)                                                    |
| `<NUMBER>` | Sequential number in domain (3 digits, 001–999)                                         |

### 4.2. When an ID Is Required

A skill **MUST** have an `id` field when ANY of the following is true:

| Condition                                         | Example                                                       |
| ------------------------------------------------- | ------------------------------------------------------------- |
| Referenced by ID from a standard                  | `STD-FE-001 §7: "Use ZAI-ARCH-002 for threshold enforcement"` |
| Referenced by ID from a rule                      | `RULE-MONOLITH-012 enforced_by: ZAI-ARCH-002`                 |
| Referenced by ID from another skill's `Related:`  | `> Related: ZAI-ARCH-002, ZAI-QA-001`                         |
| Listed in change history (deprecated/superseded) | `ZAI-MEM-001 -> ZAI-MEM-101 (renamed)`                        |
| Published to shared registries                   | Multi-author teams, public skill packs                        |

A skill **MAY** have an `id` field when none of the above apply, but
it is not required. Most personal skills do not need an ID.

### 4.3. Reserved Skill Domains (Reference)

Domains are **only** relevant if the skill has an ID. New domains
require a PR to this section.

| Domain    | Expansion                | Scope                                            |
| --------- | ------------------------ | ------------------------------------------------ |
| `MEM`     | Memory                   | Store, query, delete, export memory records      |
| `FS`      | File System              | Folder indexing, file scanning                   |
| `SESSION` | Session Management       | Session logging, context consolidation, handoff  |
| `DEV`     | Development              | Project clone, commit workflow, DB schema design |
| `ARCH`    | Architecture             | Mermaid diagrams, C4, anti-monolith              |
| `QA`      | Quality Assurance        | Test planning                                    |
| `REQ`     | Requirements             | Clarity, PRD generation                          |
| `META`    | Meta-skills              | skill-creator, ID system (legacy)                |
| `STS`     | User-Created (signature) | Skills created by user STS                       |
| `SDK`     | SDK Integration          | z-ai-web-dev-sdk wrapper skills                  |
| `DOC`     | Documentation            | PDF, DOCX, PPT generation                        |
| `HEALTH`  | Health Monitoring        | API health, retry, fallback                      |
| `CHART`   | Charts                   | Visualization skills                             |

> **Note.** `GIT` and `SEC` are NOT skill domains — these are sandbox
> built-in categories and never receive `ZAI-` IDs.

### 4.4. Existing ID Registry (Reference Only)

The 24 existing `ZAI-*` IDs from toolkit v2.0.5 are listed in
**Appendix A**. This registry is maintained for reference; new IDs are
assigned only when a skill meets §4.2 criteria.

---

## 5. Sandbox System Skills (NO ZAI- PREFIX)

The Z.ai sandbox provides system skills in `/home/z/my-project/skills/`.
These skills do **not** receive `ZAI-` prefix IDs because:

1. They are managed by the sandbox runtime, not by the skills/ directory
2. They may change without a PR to skills/
3. Their identity is established by folder name, not by ID

### 5.1. Categories

| Category      | Examples                                                             |
| ------------- | -------------------------------------------------------------------- |
| Documents     | `docx`, `pdf`, `xlsx`, `pptx`                                        |
| Visualization | `charts`                                                             |
| Images        | `image-generation`, `image-edit`, `image-search`, `image-understand` |
| AI Media      | `ASR`, `TTS`, `VLM`, `LLM`                                           |
| Development   | `fullstack-dev`, `react-dev`                                         |
| Browser       | `agent-browser`                                                      |
| Web           | `web-search`, `web-reader`                                           |
| Meta          | `skill-creator`                                                      |

The canonical list is whatever exists in `/home/z/my-project/skills/`
at runtime. This section is informational only.

### 5.2. ZCode Desktop Built-ins

ZCode Desktop has its own built-in skills without `ZAI-` prefix (e.g.
`background-process-manager`, `code-analyzer`, `context-manager`).
These are out of scope for this standard.

---

## 6. Compatibility Field

The `compatibility` field declares which runtimes can execute the skill.
It is **required when `id` is present** and optional otherwise.

| Value     | Meaning                                                                           |
| --------- | --------------------------------------------------------------------------------- |
| `both`    | Works in both Z.ai Sandbox and ZCode Desktop ADE                                  |
| `sandbox` | Only works in Z.ai Sandbox (requires z-ai-web-dev-sdk or sandbox-specific tokens) |
| `ade`     | Only works in ZCode ADE                                                           |

### 6.1. How to Determine Compatibility

1. Does the skill require `z-ai-web-dev-sdk`? -> `sandbox`
2. Does the skill use Z.ai-specific tokens / UI / API? -> `sandbox`
3. Does the skill use ZCode-Desktop-only APIs? -> `ade`
4. Otherwise -> `both`

### 6.2. Compatibility DAG (checked by G14 when ID present)

See STD-META-001 §6.4 for the full DAG rules. Summary:

| Source    | May depend on     |
| --------- | ----------------- |
| `both`    | `both` only       |
| `sandbox` | `both`, `sandbox` |
| `ade`     | `both`, `ade`     |

A `both` skill that depends on a `sandbox` skill is a hard error (G14)
because the dependency would break in ZCode ADE.

---

## 7. Triggers and Hot Commands

### 7.1. Description as Primary Trigger

The `description` field is the **primary** trigger. The sandbox matches
user requests against it. Pattern:

```text
description: "Use this skill when user asks for X, mentions Y, or needs Z.
Also activate on: 'keyword1', 'keyword2', 'phrase example'."
```

### 7.2. Trigger Field (Optional Supplement)

The `trigger` field is a comma-separated list of keywords (5–15 items
recommended). These supplement `description` for quick matching.

```yaml
trigger: monolith, refactor, file too long, decompose, split component
```

### 7.3. Trigger Quality Rules

**GOOD triggers:**

- Specific: `cache miss` not just `cache`
- Action-oriented: `optimize code` not just `optimize`
- Domain terms: `Big O`, `SIMD`, `lock-free`

**BAD triggers:**

- Too generic: `code`, `help`, `fix`
- Ambiguous: `fast` (fast what?)
- Overlapping: `git` (too broad, use `git checkpoint`, `git safe`)

### 7.4. Hot Commands

Hot commands are short phrases user can type to quickly invoke a skill.
They are documented in the skill's "When to Use" section (not in
frontmatter).

| Skill                      | Hot Commands                                      |
| -------------------------- | ------------------------------------------------- |
| prompt-engineering         | "score prompt", "improve prompt", "prompt review" |
| performance-code-generator | "optimize", "performance", "slow code"            |
| sync-toolkit               | "sync toolkit", "obnovit" (Russian)               |

---

## 8. Progressive Disclosure

Skills load in three levels:

| Level                | What loads                              | When                                  |
| -------------------- | --------------------------------------- | ------------------------------------- |
| 1. Metadata          | `name` + `description` from frontmatter | Always (loaded by sandbox at startup) |
| 2. SKILL.md body     | Full markdown instructions              | When skill triggers                   |
| 3. Bundled resources | `references/`, `scripts/`, `assets/`    | When SKILL.md body references them    |

### 8.1. File Structure

```text
skill-name/
├── SKILL.md           (required — frontmatter + instructions)
├── references/        (optional — detailed docs loaded on demand)
│   └── detailed-docs.md
├── scripts/           (optional — helper scripts)
│   └── helper-script.py
└── assets/            (optional — templates, images, etc.)
    └── templates/
```

### 8.2. Size Guidelines

- `SKILL.md` hard ceiling: 800 lines (META-001 §4.18.1, SKILL.md row); soft warn at 400 — see canonical for full matrix
- `CONTRACT.md` hard ceiling: 500 lines (META-001 §4.18.1, CONTRACT.md row); soft warn at 300 — added 2026-06-21 (O-017 Phase D2), validated against 2 pilot contracts (commit-work 368 lines, session-handoff 466 lines). See META-001 §4.18.6 for rationale.
- `README.md` hard ceiling: 400 lines (META-001 §4.18.1, README.md row); soft warn at 250 — added 2026-06-22 (S10c activation after gepetto 485->302 + react-dev 404->392 remediation). See META-001 §4.18.7 for rationale.
- Use `references/` for content that doesn't need to load at trigger time — these files are exempt per META-001 §4.18.1 (references/**.md row)
- Use `scripts/` for repetitive tasks that can be extracted

---

## 9. User-Created Skills

Skills created by users follow the same format as built-in skills.
The `ZAI-STS-XXX` ID is **optional** — required only if the skill is
referenced externally.

### 9.1. Naming Convention

| Type                  | Format                         | Example              |
| --------------------- | ------------------------------ | -------------------- |
| Folder name           | `<skill-name>`                 | `prompt-engineering` |
| ID (if any)           | `ZAI-STS-XXX`                  | `ZAI-STS-001`        |
| `name` in frontmatter | Must match folder name exactly | `prompt-engineering` |

### 9.2. Creating User Skills

Use `skill-creator` (sandbox built-in or ZAI-META-002 toolkit variant)
to create new skills. The skill-creator will:

1. Guide through skill creation
2. Optionally assign ID (`ZAI-STS-XXX` for user skills that need one)
3. If ID assigned, update Appendix A registry via PR

> The `STS` domain is reserved for user STS specifically. Other users
> should use their own signature (e.g. `ZAI-JDO-XXX` for user JDO).

---

## 10. Validation

### 10.1. Per-Skill Checks (in CI)

| Check                                                          | Tool                  | Check ID | Strictness                                                                                              |
| -------------------------------------------------------------- | --------------------- | -------- | ------------------------------------------------------------------------------------------------------- |
| `SKILL.md` exists                                              | `verify-standards.js` | V11a     | **HARD** (all skills)                                                                                   |
| `name` matches folder name                                     | `verify-standards.js` | V11b     | **HARD** (all skills)                                                                                   |
| `name` matches folder name (V11b)                              | `verify-skills.js`    | V11b     | **HARD** (all skills)                                                                                   |
| YAML frontmatter parses                                        | `verify-standards.js` | V13a     | **HARD** (all skills)                                                                                   |
| Required fields (`name`, `description`, `version`)             | `verify-standards.js` | V13b     | **HARD** (all skills)                                                                                   |
| `id` format valid (if present)                                 | `verify-standards.js` | V05a     | **SOFT** (only if `id` field exists)                                                                    |
| `id` exists in registry (if present)                           | `verify-standards.js` | V05b     | **SOFT** (only if `id` field exists)                                                                    |
| `compatibility` valid enum (if present)                        | `verify-standards.js` | V13c     | **SOFT** (only if `compatibility` field exists)                                                         |
| Frontmatter `id` matches blockquote `ID:`                      | `verify-standards.js` | V14a     | **SOFT** (only if both present)                                                                         |
| Frontmatter `version` matches blockquote `Version:`            | `verify-standards.js` | V14b     | **HARD** (always)                                                                                       |
| `SKILL.md` <= 800 lines (META-001 §4.18.1, SKILL.md row)       | `verify-skills.js`    | V12a     | **HARD** (all skills) — added 2026-06-21 (O-017 Phase D2)                                               |
| `CONTRACT.md` <= 500 lines (META-001 §4.18.1, CONTRACT.md row) | `verify-skills.js`    | V12b     | **HARD** (all skills with CONTRACT.md) — added 2026-06-21 (O-017 Phase D2)                              |
| `README.md` <= 400 lines (META-001 §4.18.1, README.md row)     | `verify-skills.js`    | V12c     | **HARD** (all skills with README.md) — added 2026-06-22 (S10c activation, gepetto+react-dev remediated) |

### 10.2. Cross-Directory Checks (in CI)

| Check                              | Tool                 | Check ID | Strictness                                  |
| ---------------------------------- | -------------------- | -------- | ------------------------------------------- |
| All `ZAI-` IDs unique across directories | `verify-id-graph.js` | G01      | **SOFT** (only skills with IDs)             |
| All `Related:` references resolve  | `verify-id-graph.js` | G02      | **HARD** (when edges exist)                 |
| Compatibility DAG valid            | `verify-id-graph.js` | G14      | **SOFT** (only skills with `compatibility`) |
| No `SKILL -> PROC` edges           | `verify-id-graph.js` | G10      | **HARD** (when edges exist)                 |

### 10.3. What This Means in Practice

- A skill with just `name`, `description`, `version` is **valid** and
  passes all HARD checks
- A skill with `id` field triggers additional SOFT checks for that ID
- A skill referenced by ID from elsewhere **MUST** have the `id` field
  (otherwise the referencing artifact fails G02)

---

## 10A. Known Issues and Proposed Solutions

This section documents discovered inconsistencies, missing content, and
proposed corrections. Each issue has an ID, status, and proposed action.
Issues resolved in the current version are marked `[RESOLVED]`; outstanding
issues are marked `[OPEN]`.

### SKILL-001-001 `[OPEN]` — §3.5 says Related: goes in blockquote only, but all 17 RULE files and 24 ZAI skills actually use YAML frontmatter `related:` field

**Problem:** §3.5 (line 139-145) states:

> These two fields go in the blockquote below the H1, NOT in YAML
> frontmatter. They are graph edges consumed only by `verify-id-graph.js`.

This rule was correct when the standard was written (v1.0, 2026-06-17),
but actual practice has diverged. As of 2026-06-18:

- All 17 RULE files in `guard/rules/RULE-*.md` declare
  their `related:` edges as a YAML list in frontmatter (e.g.
  `RULE-ANSWER-001` has `related: [RULE-HONEST-006, RULE-STRUCT-007]`
  in YAML, no `> Related:` blockquote line at all).
- All 24 ZAI skills in `skills/<name>/SKILL.md` declare their
  `related:` edges as a YAML list in frontmatter. The blockquote header
  carries `> ID:`, `> Version:`, `> Last Updated:` but typically omits
  `> Related:`.

`verify-id-graph.js` handles both formats: `parseYAMLFrontmatter()` is
tried first, and if `related:` is present there it takes precedence
(`extractDeclaration()` lines 524-547). So the verifier works either way,
but the standard's normative text is wrong.

**Proposed solution:** Update §3.5 to acknowledge both formats. Preferred
format: YAML frontmatter `related:` (matches repo practice and the
frontmatter-first principle). Blockquote `> Related:` remains valid for
backward compatibility with older standards that have no YAML frontmatter
(e.g. `META-001-standard-id-system.md`). When both are present, YAML wins.

### SKILL-001-002 `[OPEN]` — `$STANDARDS_ROOT` environment variable used in Appendix B example but not formally defined

**Problem:** Appendix B (ZAI-META-001 thin pointer template) shows:

```bash
cat $STANDARDS_ROOT/standards/STD-SKILL-001-v1.0.md
```

But `$STANDARDS_ROOT` is not formally defined in:

- This standard (SKILL-001)
- `ENV-001-reproducibility.md` (environment variables section)
- `ENV-002-zai-integration.md` (sandbox bootstrap procedure)

Skills that copy this example verbatim will produce an empty string
expansion if the variable is unset, leading to a `cat /standards/...`
path that does not exist.

**Proposed solution:** Add `$STANDARDS_ROOT` to ENV-001 §3 (environment
variables) with the definition:
`STANDARDS_ROOT=/home/z/my-project/Z-ai-governance/standards` (or the
equivalent path in non-sandbox deployments). Document that the variable
MUST be set by the bootstrap procedure (ENV-002 §3.0 step 4) before any
skill that references it is invoked.

### SKILL-001-003 `[OPEN]` — Appendix B template shows ZAI-META-001 v1.1 but actual skill-id-system/SKILL.md is at v1.0

**Problem:** Appendix B (line 654) shows the target state of
`skills/skill-id-system/SKILL.md` after migration to v1.1:

```yaml
id: ZAI-META-001
version: 1.1
```

But the actual file at `skills/skill-id-system/SKILL.md`
(as of 2026-06-18) is still at v1.0 — the migration window described in
§12.4 has not started. Readers who copy the template expecting it to
match the current file will find a version mismatch.

**Proposed solution:** Either (a) bump `skills/skill-id-system/SKILL.md`
to v1.1 to match the template (preferred — closes the migration window's
first phase), or (b) add a note to Appendix B clarifying that the template
shows the target state, not the current state. Option (a) requires a PR
to skills/; option (b) is a one-line edit here.

---

## 11. ID Assignment Procedure (Optional)

### 11.1. When to Assign

Assign an ID only when the skill meets §4.2 criteria. Most personal
personal skills do not need an ID.

### 11.2. Process

1. **Open Issue** in `skills/` proposing the new skill with tentative ID
2. Maintainer reviews; assigns final ID from Appendix A registry
3. PR adds the skill folder with `SKILL.md` conforming to §3.2
4. PR updates Appendix A registry in this standard
5. CI runs `verify-standards.js` and `verify-id-graph.js`
6. PR cannot merge if any HARD check fails

### 11.3. Numbering Rules

- Numbers go sequentially within domain: 001, 002, 003...
- Gaps not allowed (no `ZAI-MEM-005` if `ZAI-MEM-004` doesn't exist)
- Deleted skill: ID marked `[DEPRECATED]`, number not reassigned
- Next available STS ID: `ZAI-STS-008`

---

## 12. Migration From ZAI-META-001 v1.0

### 12.1. What Moves

| Content             | From                        | To                                          |
| ------------------- | --------------------------- | ------------------------------------------- |
| ID format spec      | ZAI-META-001 §2             | This standard §4.1                          |
| Domain list         | ZAI-META-001 §3 (9 domains) | This standard §4.3 (13 domains, reconciled) |
| Header format       | ZAI-META-001 §6             | This standard §3                            |
| STS convention      | ZAI-META-001 §7             | This standard §9                            |
| ID registry         | ZAI-META-001 §5             | This standard Appendix A                    |
| Sandbox skills list | ZAI-META-001 §4             | This standard §5                            |

### 12.2. What Stays

| Content                        | Stays in                              | Why                                                     |
| ------------------------------ | ------------------------------------- | ------------------------------------------------------- |
| `skill-id-system` folder       | `skills/skill-id-system/` | Trigger phrases need to resolve during migration window |
| `ZAI-META-001` ID              | Registry (Appendix A)                 | Marked `SUPERSEDED`                                     |
| `skill-creator` (ZAI-META-002) | `skills/skill-creator/`   | Updated to read this standard                           |

### 12.3. ZAI-META-001 After Migration

The file becomes a thin pointer (~20 lines) referencing this standard.
See Appendix B for the pointer template.

### 12.4. Migration Window

- **v1.0.0**: ZAI-META-001 marked `SUPERSEDED`; this standard published; references produce warning W01
- **v1.x**: thin pointer remains in place
- **v2.0.0**: ZAI-META-001 file deleted; references produce hard error G05

---

## 13. FAQ

### Q: I'm creating a new personal skill. Do I need an ID?

A: **No.** Just use `name`, `description`, `version` in frontmatter.
Add an ID only if you plan to reference this skill from a standard,
rule, or another skill's `Related:` field.

### Q: I'm creating a skill that enforces a standard threshold. Do I need an ID?

A: **Yes.** The standard will reference your skill by ID (e.g.
`enforced_by: ZAI-ARCH-002`), so the ID must exist and be stable.

### Q: What happens to the 24 existing ZAI-* IDs?

A: **Nothing.** They are preserved unchanged. The registry in
Appendix A is the reference. No migration, no rename.

### Q: My skill works in both sandbox and ZCode Desktop. Do I need `compatibility`?

A: Only if your skill has an ID. If it has an ID, `compatibility` is
required. If no ID, `compatibility` is optional (defaults to `both`).

### Q: Can I add an ID later?

A: Yes. Adding an `id` field to an existing skill is a non-breaking
change. Just update Appendix A via PR.

### Q: Can I remove an ID?

A: Only if nothing references it. Check `verify-id-graph.js` G02 first.
If references exist, mark the ID `[DEPRECATED]` in Appendix A with a
migration entry in change history instead of removing it.

### Q: Why is `skill-creator` different in sandbox vs toolkit?

A: The sandbox version (Z.ai official, Apache 2.0) focuses on
eval-driven skill improvement. The toolkit version (ZAI-META-002)
focuses on ID-assignment workflow. They can coexist or be merged;
see Appendix C for the hybrid pattern.

### Q: Why is `phi-layout` (sandbox) different from `phi-layout` (ZAI-STS-005)?

A: They are toolkit twins. The sandbox version is maintained by the
sandbox runtime; the user version is the customized variant.
They may declare an `Aligned_with:` edge if drift becomes a problem.

---

## 14. Cross-References

| ID                           | Relationship                                                              |
| ---------------------------- | ------------------------------------------------------------------------- |
| STD-META-001 v2.0            | Defines the umbrella ID system; this standard specializes it for skills   |
| STD-DOC-002                  | Markdown standard — `SKILL.md` body must conform                          |
| RULE-MONOLITH-012            | 250-line file ceiling applies to `SKILL.md`                               |
| ZAI-META-001                 | SUPERSEDED by this standard; thin pointer remains during migration window |
| ZAI-META-002 (skill-creator) | Reads this standard; toolkit variant of sandbox skill-creator             |
| ZAI-ARCH-002 (anti-monolith) | Aligned_with STD-FE-001, STD-DESIGN-001                                   |

---

## 15. Checklist Before Publishing New Skill

**Minimum (no ID):**

- [ ] Skill folder created at `skills/<name>/`
- [ ] `SKILL.md` present with YAML frontmatter + H1 + blockquote per §3.1
- [ ] Required fields present: `name`, `description`, `version`
- [ ] `name` matches folder name
- [ ] Frontmatter `version` matches blockquote `Version:` (V14b)
- [ ] `SKILL.md` under 800 lines (META-001 §4.18.1, SKILL.md row; soft warn at 400)
- [ ] `verify-standards.js` V11/V13/V14b pass

**Extended (with ID):**

- [ ] All minimum checks pass
- [ ] `id` conforms to §4.1 format and exists in Appendix A registry
- [ ] `compatibility` is one of `both` / `sandbox` / `ade`
- [ ] Frontmatter `id` matches blockquote `ID:` (V14a)
- [ ] Appendix A registry updated
- [ ] `verify-standards.js` V05/V13c pass
- [ ] `verify-id-graph.js` G01/G02/G14 pass (if any edges declared)

---

## Appendix A: Existing ZAI-* ID Registry

> **Status**: `ACTIVE` = maintained; `FROZEN` = kept for reference;
> `DEPRECATED` = obsolete; `SUPERSEDED` = content moved elsewhere.

### A.1. Memory (MEM)

| ID          | Skill Name    | Version | Compatibility | Status |
| ----------- | ------------- | ------- | ------------- | ------ |
| ZAI-MEM-001 | memory-store  | 1.0     | both          | ACTIVE |
| ZAI-MEM-002 | memory-query  | 1.0     | both          | ACTIVE |
| ZAI-MEM-003 | memory-delete | 1.0     | both          | ACTIVE |
| ZAI-MEM-004 | memory-export | 1.0     | both          | ACTIVE |

### A.2. File System (FS)

| ID         | Skill Name     | Version | Compatibility | Status |
| ---------- | -------------- | ------- | ------------- | ------ |
| ZAI-FS-001 | folder-indexer | 1.0     | both          | ACTIVE |

### A.3. Session Management (SESSION)

| ID              | Skill Name            | Version | Compatibility | Status |
| --------------- | --------------------- | ------- | ------------- | ------ |
| ZAI-SESSION-001 | session-log           | 1.1     | both          | ACTIVE |
| ZAI-SESSION-002 | context-consolidation | 1.0     | both          | ACTIVE |
| ZAI-SESSION-003 | session-experience    | 4.0     | both          | ACTIVE |

### A.4. Development (DEV)

| ID          | Skill Name               | Version | Compatibility | Status |
| ----------- | ------------------------ | ------- | ------------- | ------ |
| ZAI-DEV-001 | project-clone            | 1.0     | sandbox       | ACTIVE |
| ZAI-DEV-002 | commit-work              | 1.0     | both          | ACTIVE |
| ZAI-DEV-003 | database-schema-designer | 1.0     | both          | ACTIVE |

### A.5. Architecture (ARCH)

| ID           | Skill Name       | Version | Compatibility | Status |
| ------------ | ---------------- | ------- | ------------- | ------ |
| ZAI-ARCH-001 | mermaid-diagrams | 1.0     | both          | ACTIVE |
| ZAI-ARCH-002 | anti-monolith    | 1.0     | both          | ACTIVE |

### A.6. Quality Assurance (QA)

| ID         | Skill Name      | Version | Compatibility | Status |
| ---------- | --------------- | ------- | ------------- | ------ |
| ZAI-QA-001 | qa-test-planner | 1.0     | both          | ACTIVE |

### A.7. Requirements (REQ)

| ID          | Skill Name           | Version | Compatibility | Status |
| ----------- | -------------------- | ------- | ------------- | ------ |
| ZAI-REQ-001 | requirements-clarity | 1.0     | both          | ACTIVE |

### A.8. Meta-skills (META)

| ID           | Skill Name      | Version | Compatibility | Status                        |
| ------------ | --------------- | ------- | ------------- | ----------------------------- |
| ZAI-META-001 | skill-id-system | 1.0     | both          | SUPERSEDED (by this standard) |
| ZAI-META-002 | skill-creator   | 1.1     | both          | ACTIVE                        |

### A.9. User-Created (STS)

| ID          | Skill Name                 | Version | Compatibility | Status |
| ----------- | -------------------------- | ------- | ------------- | ------ |
| ZAI-STS-001 | prompt-engineering         | 1.1     | both          | ACTIVE |
| ZAI-STS-002 | sync-toolkit               | 1.0     | sandbox       | ACTIVE |
| ZAI-STS-003 | performance-code-generator | 1.0     | sandbox       | ACTIVE |
| ZAI-STS-004 | frontend-styling-expert    | 1.0     | both          | ACTIVE |
| ZAI-STS-005 | phi-layout                 | 3.0     | both          | ACTIVE |
| ZAI-STS-006 | zai-ui-composer            | 1.1.2   | sandbox       | ACTIVE |
| ZAI-STS-007 | workflow-discipline        | 2.0     | both          | ACTIVE |

---

## Appendix B: ZAI-META-001 Thin Pointer Template

After migration, `skills/skill-id-system/SKILL.md` becomes:

```markdown
---
name: skill-id-system
description: ID system for Z.ai skills. The authoritative specification has moved to STD-SKILL-001 in `standards/standards/`. This skill remains so trigger phrases ('skill id', 'create skill') continue to resolve during the migration window.
id: ZAI-META-001
version: 1.1
compatibility: both
trigger: skill id, create skill, new skill
---

# Skill: Skill ID System v1.1 (SUPERSEDED)

> ID: ZAI-META-001
> Version: 1.1
> Status: SUPERSEDED
> Superseded_by: STD-SKILL-001
> Last Updated: 2026-07

**This skill's content has moved to STD-SKILL-001** in `standards/standards/`.

For the authoritative skill format and identification specification, see:

- `standards/standards/SKILL-001-skill-format.md`
- Or run: `cat $STANDARDS_ROOT/standards/STD-SKILL-001-v1.0.md`

This file remains in place so trigger phrases continue to resolve during
the v1.x -> v2.0.0 migration window. It will be removed when the
migration window closes.
```

---

## Appendix C: Hybrid skill-creator Pattern (Reference)

The Z.ai sandbox ships an official `skill-creator` (Apache 2.0, ~485
lines) focused on **eval-driven skill improvement** — test prompts,
baselines, benchmark viewer, description optimization.

The toolkit variant `ZAI-META-002` (~370 lines) focuses on
**ID-assignment workflow** — domains, registry, STS convention,
trigger quality rules.

A **hybrid** skill-creator can be built by:

1. Starting from the Z.ai official version (preserve Apache 2.0 license)
2. Adding a section "ID Assignment (Optional)" that references this standard
3. Adding trigger quality rules from §7.3 of this standard
4. Keeping eval-viewer, agents/, scripts/ intact

This hybrid pattern is **not required** by this standard; it is a
reference for maintainers who want a single unified skill-creator.

---

_End of STD-SKILL-001 v1.1 — APPROVED 2026-06-17, §10A added 2026-06-18, §8.2/§10.1 V12a/V12b added 2026-06-21 (O-017 Phase D2: tiered hard caps for SKILL.md <=800 + CONTRACT.md <=500, replacing deferred PROC-LINECOUNT-004 with active `verify-skills.js` S10 enforcement), §8.2/§10.1 V12c added 2026-06-22 (S10c: README.md <=400, gepetto+react-dev remediated, HARD from day 1)._
