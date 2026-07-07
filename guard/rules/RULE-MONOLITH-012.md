---
id: RULE-MONOLITH-012
title: Anti-monolith (file size by category)
version: 1.4
level: [C]
status: ACTIVE
source: Z-ai-governance v1.3.0 (RULE-MONOLITH-012), revised 2026-06-19 (canonical promoted to META-001)
owning-standard: STD-META-001 v2.0.4
last-updated: 2026-06-19
related:
  - RULE-COMMIT-004
  - STD-SKILL-001
  - STD-DOC-002
  - STD-FE-001
---

# RULE-MONOLITH-012: Anti-monolith (file size by category)

Every file MUST stay under the line limit for its category. When a file
crosses its threshold, the agent MUST stop writing, split the file, and
continue with smaller modules.

> **v1.3 change (2026-06-19):** The limits matrix and exempt list are
> now canonical in **STD-META-001 §4.18** (L1 standard). This rule (L2)
> retains a compact mirror below for enforcement context, but defers to
> §4.18 for the source of truth. v1.2 had the matrix inline; promoting
> it to L1 fixes a layering violation where L2 was defining WHAT
> (limits) instead of just HOW (enforcement).

## 1. Compact mirror (canonical: STD-META-001 §4.18.1)

| Category                                                | Hard   | Soft | Notes          |
| ------------------------------------------------------- | ------ | ---- | -------------- |
| Source code (`.ts`/`.tsx`/`.js`/`.py`/`.sh`)            | 250    | 150  |                |
| Tests (`.test.*`/`.spec.*`)                             | 400    | 250  |                |
| Config (`.json`/`.yml`/`.toml`/`.ini`)                  | exempt | —    | Naturally flat |
| `SKILL.md`                                              | 800    | 400  |                |
| `README.md`                                             | 400    | 250  |                |
| `INDEX.md`                                              | exempt | —    | Router         |
| `STD-*.md`/`META-*.md`                                  | 1200   | 800  |                |
| `RULE-*.md`                                             | 200    | 120  |                |
| `PROC-*.md`/`TOOL-*.md`                                 | 400    | 250  |                |
| `references/**.md`                                      | exempt | —    | Externalised   |
| Append-only logs (worklog/DECISIONS/SESSION/MIGRATIONS) | exempt | —    | Chronological  |
| Other `.md`                                             | 400    | 250  | Default        |

> For the full matrix (rationale column, exempt list of 44 files / 18 579
> lines, how-to-pick-category rules, parser-bound files explanation),
> see **STD-META-001 §4.18**. The mirror here is for fast lookup during
> enforcement; the canonical is the only source for changes.

## 2. Auto-activation (MUST NOT wait to be asked)

1. Agent writes a file that approaches its category limit -> STOP, split, continue.
2. Agent opens a file that already exceeds its category limit -> split before editing (unless exempt or parser-bound; see §4.18.3).
3. Agent plans a new file that will clearly exceed limits -> plan decomposition upfront.

## 3. When threshold is crossed

1. STOP writing immediately.
2. Announce: `[ANTI-MONOLITH] <file> is N lines (limit L for <category>)`.
3. Identify sub-responsibilities within the file (look at H2 sections).
4. For each sub-responsibility, extract into a separate file with a clear single purpose.
5. Keep the original as a thin orchestrator that imports / links to extracted modules.
6. Continue the task with the decomposed structure.

### 3.1 Split pattern: `INDEX.md + chapters/`

For files with many independent sections (cheatsheets, cookbooks, catalogs):

```text
long-file.md           -> INDEX.md (router, links to chapters)
                          chapters/
                            01-topic.md
                            02-topic.md
                            ...
```

Works when: sections have no cross-references between them.
Does NOT work for: narrative docs (worklog, standards with `Related:` edges).

### 3.2 Split pattern: inline references

For `SKILL.md` files that exceed 800 lines, push reference material to
`references/` subdirectory and link from the SKILL.md body. The skill
loader only needs the trigger surface and core procedure.

## 4. Exceptions (must be documented)

**Valid exceptions** (require inline comment in the file explaining why):

- Auto-generated code (Prisma schema, OpenAPI types) -- exempt, not split.
- Configuration files that are naturally flat -- exempt by category.
- Files in the explicit exempt list (§4.18.4) -- no comment needed, the rule covers them.

**Invalid exceptions:**

- "I'll refactor later" (later never comes).
- "It's easier to read in one file" (that's what imports / `references/` are for).
- "It's a parser-bound file with an ID" -- parser-bound does NOT exempt from the category limit; it only exempts from the blanket 250. If a `STD-*.md` exceeds 1200 lines, it still must split (and the parser concern is handled by the ID migration protocol in STD-META-001 §8).

## 5. Enforcement

- **Source code / tests (v1.4):** HARD via `scripts/verify-source-line-count.cjs`
  (TOOL-VERIFY-007). Blocks pre-commit. Runs in CI. Covers .ts/.tsx/.js/.jsx/
  .py/.sh/.css (hard 250 / soft 150) and .test.*/.spec.* (hard 400 / soft 250).
  Excludes node_modules, .next, src/components/ui/, config files, build
  artifacts.
- **Markdown files (v1.3):** HARD via `verify-standards.js` V11 (1000-line cap)
  and `verify-skills.js` S10a/b/c (800/500/400 caps). Both block pre-commit
  and CI.
- **Orchestration:** `guard/scripts/line-count-check.sh` (PROC-LINECOUNT-004)
  runs all three verifiers and aggregates results. Supports `--hard` (CI) and
  default (soft warn) modes.

## 6. Relationship to other rules / standards

- **STD-META-001 §4.18** -- canonical source of truth for all file-size limits and the exempt list. This rule is its L2 enforcer.
- **RULE-MONOLITH-004** -- function size limit (50 lines). Orthogonal to this rule (file-level vs function-level).
- **STD-SKILL-001 §8.2 / §10.1 / §13** -- references META-001 §4.18 for the SKILL.md ceiling.
- **STD-DOC-002 §11** -- Markdown standard exceptions (separate concern; cross-link if conflict).
- **STD-FE-001 §6** -- frontend file-size table (code: 150/250). Consistent with §4.18.1 (source-code row); future revisions should cross-link.

## 7. Change history

| Version | Date       | Change                                                                                                                                                                                                                                                                                                                                                          |
| ------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0     | 2026-05    | Initial port from AHG v2.5.0. Blanket 250-line rule.                                                                                                                                                                                                                                                                                                            |
| 1.1     | 2026-06-17 | Verifier header `Related:` cleanup.                                                                                                                                                                                                                                                                                                                             |
| 1.2     | 2026-06-19 | Truthfulness fix: blanket 250 -> per-category matrix + full exempt list (44 files, 18 579 lines). Parser-bound files get their own ceiling, not the blanket. PROC-LINECOUNT-004 deferred.                                                                                                                                                                       |
| 1.3     | 2026-06-19 | Layering fix: canonical matrix + exempt list promoted to STD-META-001 §4.18 (L1). This rule retains a compact mirror for enforcement context but defers to §4.18 for source of truth. STD-SKILL-001 §8.2/§10.1/§13 updated to reference §4.18 instead of this rule. Net delta: ~70 lines removed from this rule, ~80 lines added to META-001. No graph changes. |
| 1.4     | 2026-07-07 | Enforcement gap closed: TOOL-VERIFY-007 (verify-source-line-count.cjs) now enforces source code (250 hard) and test (400 hard) caps in pre-commit (HARD) and CI. PROC-LINECOUNT-004 v1.1 updated. Section 5 rewritten from "deferred" to active enforcement. |
