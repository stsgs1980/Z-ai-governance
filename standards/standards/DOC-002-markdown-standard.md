# Standard: Markdown Formatting v2.4.4 (EN)

> ID: STD-DOC-002
> Version: 2.4.4
> Level: **[C] Critical** (unified with STD-DOC-003 — same rule = same severity)
> Related: STD-META-001 (ID system), STD-META-002 (language policy), STD-ARCH-002 (implementation order — DOC-002 is installed at position #4, after ARCH-002 defines the install sequence)
> Last Updated: 2026-07-03
> Effective Date: 2026-07-03
> Note: Character rules (emoji, box-drawing, etc.) are delegated to STD-DOC-003. Per ARCH-002 install order, DOC-003 is read after DOC-002. The dependency edge is therefore DOC-003 -> DOC-002 (DOC-003 depends on DOC-002's markdown scope).
> Entry point: `bash scripts/check-md.sh [path]` — see §0 (TL;DR) and §10 (now in companion `DOC-002-eslint-integration.md`).
> Companion file: `DOC-002-eslint-integration.md` (§10 ESLint Integration, extracted in v2.4.3 for W11 soft-cap cleanup).

---

## 0. TL;DR — Quick Reference

**Check your file in 30 seconds (recommended):**

```bash
bash scripts/check-md.sh path/to/file.md
```

The wrapper runs three layers — static checks (bash only), ESLint (if installed), and `lint-md.js` (if present) — and exits non-zero on any violation. See §10.7 for the full stage table.

**Or run the underlying tools directly (same effect):**

```bash
npx eslint path/to/file.md --plugin markdown --max-warnings=0
node lint-md.js --level=C path/to/file.md
```

Both must exit 0. Any error blocks the commit. The wrapper script exists so contributors do not have to remember the exact flags.

**5 things you must NOT do (all [C] Critical — block commit):**

1. No emoji anywhere (use `[OK]`, `[FAIL]`, `[TODO]` text tags instead)
2. No Unicode icons (use text tags or SVG via `![]()`)
3. No typographic symbols in headings, tables, or code (em dash `—`, copyright, degree — allowed only in plain prose)
4. No table pseudographics outside code blocks (use Markdown tables `| ... |`)
5. No closing `#` on headings, no `*` or `+` for unordered lists (use `-` only)

**5 things you MUST do:**

1. One H1 per document, at the top
2. Every fenced code block specifies a language (use `text` or `bash` if unknown)
3. Root README of an application repo ends with `---\nBuilt with: <stack>`
4. Use `(ref)` marker only when a character is the _object of demonstration_ (e.g. in a "prohibited characters" table)
5. Run ESLint + `lint-md.js` before commit (husky + lint-staged automate this)

**Where to look:**

| Need                      | Section |
| ------------------------- | ------- |
| What's prohibited         | §3      |
| What's allowed            | §4      |
| Formatting rules          | §5      |
| Stack signature scope     | §8      |
| ESLint config             | §10     |
| Pre-merge checklist       | §13     |
| Full before/after example | §12.4   |

---

## 1. Introduction and Goals

This standard establishes rules for Markdown documentation formatting to ensure visual consistency and professional product quality.

**Goals:**

- Ensure visual consistency of documentation
- Maintain professional product quality
- Guarantee control through design system
- Eliminate uncontrolled visual artifacts
- Enforce standards automatically via ESLint where possible

---

## 2. Scope

| Level            | Context                                               | Action on violation                 |
| ---------------- | ----------------------------------------------------- | ----------------------------------- |
| **[C] Critical** | README.md, CHANGELOG.md, docs/, project documentation | Blocks commit (husky + lint-staged) |

**See also:**

- **Unicode Policy v2.3** — for UI components [C], production code [C], AI-communication [W], prototypes [I]

---

## 3. Prohibited Elements

Character prohibitions are defined in **Unicode Policy v2.3** (STD-DOC-003) sections 4-5. Level **[C] Critical** applies to documentation files — same severity as source code (same rule = same severity).

**Summary (authoritative rules in STD-DOC-003):**

| Category                      | Level | Note                                         |
| ----------------------------- | ----- | -------------------------------------------- |
| Emoji                         | [C]   | No exceptions                                |
| Unicode icons                 | [C]   | Use text tags                                |
| Table pseudographics          | [W]   | Use Markdown syntax                          |
| Typographics in headings/code | [W]   | Allowed in plain text only (see scope below) |

**Prohibition scope (for Typographics in .md files):**

- Headings and subheadings
- Tables (except reference tables - see below)
- Inline code and code blocks (comments, strings)
- File and folder names

**`(ref)` exception for reference tables and code blocks:** If the purpose of a table cell or a code block line is to identify a specific character (to show what is prohibited or allowed), the character may be included with a `(ref)` marker. This does not violate the spirit of the standard: the character is used as the object of description, not as formatting. Without the actual symbol, the example loses clarity: "Incorrect: `—` (ref) in heading" is demonstrative; "Incorrect: em dash in heading" is blind.

**Where `(ref)` is appropriate:**

- In a table cell whose purpose is to identify the character (e.g. the "Incorrect" column of §4.4 Text Tags)
- In a fenced code block line whose purpose is to demonstrate the character (e.g. `Incorrect: # Heading — (ref) Subtitle` in §5.1)
- In a documentation paragraph that explicitly discusses the character as an object (e.g. "The `—` (ref) character is U+2014")

**Where `(ref)` is NOT appropriate:**

- In normal prose where the character is used as formatting (e.g. "Install the dependencies — then run the build" — this is just an em dash, no marker needed... but it IS still prohibited in headings/tables/code, see §3)
- In a heading or table cell that is not about the character itself
- As a way to sneak a prohibited character into a heading by appending `(ref)` — the marker does not grant immunity, the cell's _purpose_ must be to identify the character

---

## 4. Allowed Elements

### 4.1. Text Rules

Allowed character sets are defined in **STD-DOC-003 section 6.1**. For .md files at level [W]:

- All characters from the STD-DOC-003 basic set are allowed
- **Typographic symbols** (em dash, en dash, degree, copyright, plus-minus) are allowed in **plain text only** — prohibited in headings, tables, code blocks, and file names (see Section 3)

### 4.2. ASCII Diagrams

The whitelist for technical diagrams in documentation is defined in **STD-DOC-003 section 6.2**. Level [I] applies within code blocks; level [W] applies in plain text documentation.

### 4.3. Markdown Syntax

| Element        | Syntax           |
| -------------- | ---------------- |
| Headings       | `#`, `##`, `###` |
| Bold           | `**text**`       |
| Italic         | `*text*`         |
| Inline code    | `` `code` ``     |
| Code block     | ` ```language `  |
| Blockquote     | `>`              |
| Unordered List | `-` (strictly)   |
| Ordered List   | `1.`             |
| Link           | `[text](url)`    |
| Image          | `![alt](url)`    |

### 4.4. Text Tags for Statuses

Use text labels instead of Unicode symbols:

| Correct     | Incorrect    |
| ----------- | ------------ |
| `[OK]`      | [v] (ref)    |
| `[FAIL]`    | [x] (ref)    |
| `[DONE]`    | [OK] (ref)   |
| `[TODO]`    | (ref)        |
| `[WARNING]` | [WARN] (ref) |
| `[INFO]`    | (ref)        |

---

## 5. Formatting Rules

### 5.1. Headings

- Use `#` for H1, `##` for H2, etc.
- Do not use closing `#` symbols
- Only one H1 per document
- Do not use typographic symbols (like em dash) in headings

```text
Correct:      # Heading
Incorrect:    # Heading #
Incorrect:    # Heading — (ref) Subtitle
```

The `—` (ref) symbol in the example above is a demonstration of the prohibited character; the `(ref)` marker indicates reference usage.

### 5.2. Lists

**Unordered:**

- Always use `-` as the single marker for unordered lists.
- Do not mix with `*` or `+`.

```text
Correct:      - Item 1
Incorrect:    * Item 1
Incorrect:    -> Item 1
```

**Ordered:**

```text
1. First item
2. Second item
```

### 5.3. Text Emphasis

| Format        | Syntax     |
| ------------- | ---------- |
| Bold          | `**text**` |
| Italic        | `*text*`   |
| Strikethrough | `~~text~~` |

### 5.4. Code Formatting

**Inline code** (within text):

```markdown
Use the `processFile()` function for processing.
```

**Code block** (with language specified):

````markdown
```
const config = {
  encoding: "utf-8",
  strict: true,
};
```text
````

**Unknown Languages Rule:**
If the exact programming language or format is not supported by the renderer or is unknown, always specify `text` or `bash` instead of leaving the block blank.

````text
Correct:      ```text
Incorrect:    ```text
````

**Rules:**

| Element     | Format          | Purpose                                    |
| ----------- | --------------- | ------------------------------------------ |
| Inline code | `` `code` ``    | Functions, variables, commands within text |
| Code block  | ` ```language ` | Multi-line code, examples, configs         |

**Do NOT use custom colors:**

- Markdown does not natively support colors
- HTML tags like `<span style="color:red">` may be blocked on GitHub
- Syntax highlighting is applied automatically by the renderer
- Color is the responsibility of the theme (GitHub, VS Code), not the document

---

## 6. Visual Elements

### 6.1. Visual Elements in Markdown

Icon and graphic rules are defined in **STD-DOC-003 section 7**. For .md files:

- Any visual symbol = **SVG only** or **text alternative** (STD-DOC-003 section 7.1)
- SVG insertion uses standard Markdown image syntax. Raw `<svg>...</svg>` HTML tags are prohibited:

```markdown
![Icon description](./path/to/icon.svg)
```

### 6.2. Icon Library

See **STD-DOC-003 section 7.2** for icon library requirements. In documentation, use text descriptions instead of icons.

### 6.3. Brand Logos

See **STD-DOC-003 section 7.4** for brand logo requirements. When mentioning technologies in documentation, use official SVG via Markdown image syntax.

---

## 7. Badges

Badges are graphical indicators of project metadata (version, build status, license). Place them at the beginning of README.md after the heading.

### 7.1. Allowed Sources

| Source     | Usage                                         |
| ---------- | --------------------------------------------- |
| shields.io | Recommended — generates PNG/SVG without emoji |
| custom SVG | Allowed if compliant with Unicode Policy      |

### 7.2. Prohibited

- Emoji in badges (shields.io supports it, but do not use)
- External icons inside badges
- Badges with statuses that do not reflect reality

### 7.3. Typical Badges for npm Package

```markdown
[![npm version](https://img.shields.io/npm/v/zai-agent-toolkit.svg)](https://www.npmjs.com/package/zai-agent-toolkit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
```

### 7.4. Placeholders (for projects without CI)

If CI is not configured, use static badges:

```markdown
[![Status: Draft](https://img.shields.io/badge/Status-Draft-yellow.svg)]()
[![Version: 1.9.5](https://img.shields.io/badge/Version-1.9.5-blue.svg)]()
```

When CI is configured, replace with dynamic ones.

---

## 8. Stack Signature

**Application** README files must contain a stack signature at the end of the file.

**Scope (applies to):**

- `README.md` at the root of an **application repository** (a repo that ships runnable code — e.g. a Next.js app, a library, a CLI tool)
- `CHANGELOG.md` at the root of an application repository (optional but recommended)

**Scope (does NOT apply to):**

- **Standards** (`standards/standards/*.md`) — they describe rules, not "built with" anything
- **Rules** (`guard/rules/*.md`) — same
- **Templates** (`templates/*.md`) — meta-docs, not applications
- **Governance repos** (e.g. `Z-ai-governance`) — they define standards and rules, they do not ship an application stack
- **Nested docs** (`docs/**/*.md`) — optional, not required

If a file is unclear, the test is: "Does this repo ship a runnable application whose stack a reader would care about?" If yes, the root README must have a Stack Signature. If no (governance, standards, meta-repos), the Stack Signature is forbidden — it would be cargo cult. Skills are **permitted** to include a Stack Signature to indicate their runtime stack.

**Format:**

```markdown
---

Built with: <project technologies>
```

The specific stack is determined by the project, not the standard. Example for Next.js projects:

```markdown
---

Built with: Next.js 16 + TypeScript + Tailwind CSS
```

For the default value in this stack, see `templates/README_TEMPLATE.md`.

**Rules:**

- Placement: end of file
- Separator: three dashes `---`
- Content: letters, digits, `+` and `:` signs
- Graphics prohibited

---

## 9. Control and Enforcement

### 9.1. Level [C] Critical - Enforcement Policy

| Stage       | Action                                 | Blocks merge?   |
| ----------- | -------------------------------------- | --------------- |
| Editor      | Inline error in VS Code                | n/a (real-time) |
| Pre-commit  | husky + lint-staged aborts commit      | **Yes**         |
| CI Pipeline | Job fails on `eslint --max-warnings=0` | **Yes**         |
| Pre-merge   | GitHub status check fails              | **Yes**         |

**Rule:** Level [C] blocks merge automatically. To land a PR with a [C] violation, the author must:

1. Fix the violation (preferred), OR
2. Add an inline `eslint-disable-next-line <rule-name>` with a justification comment, AND
3. Get Tech Lead approval on the PR

**Escalation:** Disabling [C]-level rules in production code or documentation without Tech Lead approval is prohibited. The `lint-md.js --level=W` override exists for one-off triage (e.g. auditing a newly-imported codebase); it must not be wired into CI.

**Soft-opt-out for legacy projects:** A project that is not yet ready for [C] enforcement may set `lint-md.js --level=W` in its local `package.json` script during a migration window. This decision is per-project, time-boxed, and must be documented in the project's README with a target cutover date. The default remains [C].

### 9.2. Mandatory Validation of All .md Files

**Rule:** Any created or added `.md` file in the project **must** pass validation and editing according to this standard.

| Action                           | When          | Responsible |
| -------------------------------- | ------------- | ----------- |
| Creating new .md                 | Before commit | Author      |
| Adding external .md              | Before merge  | Reviewer    |
| Copying .md from another project | Before commit | Author      |

**Process:**

1. Validation by checklist (see section 12)
2. Fix violations
3. Add stack signature (if root file)
4. Review in Code Review

---

## 10. ESLint Integration for Markdown Linting

> **Moved to companion file** `DOC-002-eslint-integration.md` in v2.4.3
> (W11 soft-cap cleanup). The full ESLint setup guide — dependencies,
> flat config, rule mappings, sample workflows — lives there. Section
> numbers (§10.1 through §10.7) preserved verbatim.

**Quick summary** (full guide in companion):

- **Why ESLint?** — Immediate editor feedback, pre-commit hooks, CI enforcement. ESLint is the automated executor of STD-DOC-002 + STD-DOC-003 rules.
- **Dependencies:** `eslint`, `eslint-plugin-markdown`, custom `unicode-policy.js` rule
- **Config:** flat config (`eslint.config.js`) mapping §3 prohibited elements to warnings and STD-DOC-003 character rules to errors
- **Entry point:** `bash scripts/check-md.sh [path]` (wrapper that runs static checks + ESLint + `lint-md.js`)
- **CI integration:** GitHub Actions workflow example in companion §10.6
- **Pre-commit hook:** husky + lint-staged config in companion §10.7

## 11. Exceptions

### 11.1. Unconditionally Allowed

See **STD-DOC-003 section 11.1** for the complete list of unconditionally allowed characters. For .md files, typographic symbols are additionally allowed in plain text (level [W]).

### 11.2. Exceptions by Agreement

| Situation             | Requirement                                 |
| --------------------- | ------------------------------------------- |
| External requirements | Email campaigns - coordinate with marketing |
| Localization          | Languages with non-ASCII characters         |

---

## 12. ASCII Diagram Examples

ASCII diagrams are **allowed** in documentation (README, docs/).

### 12.1. Architecture Diagram Example

```text
+-------------------+
|    Component A    |
+---------+---------+
          |
          v
+-------------------+
|    Component B    |
+---------+---------+
          |
          +-----> Component C
```

### 12.2. Flow Diagram Example

```text
User Request --> API Gateway --> Auth Service
                                      |
                                      v
                                 Database
                                      |
                                      v
                               Response --> User
```

### 12.3. Sequence Diagram Example

```text
Client          Server          Database
  |                |               |
  +----request---->|               |
  |                +----query----->|
  |                |<---result-----+
  |<---response----+               |
```

### 12.4. Full Before/After Example

This section shows a small README snippet that violates multiple rules, then the corrected version. Use this as a calibration reference when reviewing PRs.

**Before (violates 7 rules — would be blocked by `lint-md.js --level=C`):**

````markdown
# Project Alpha [SPARKLES]

> Fast, reliable, and _beautiful_ API client.

## Status

- [v] Build passing
- [x] Docs outdated

## Install — Quick Start

```
npm install alpha
```text

## Components

+-------------------+
| HTTP Client |
+-------------------+
|
v
+-------------------+
| Retries |
+-------------------+

## Notes

Copyright (c) 2026 Alpha Corp. All rights reserved.

---

Built with: Next.js 16 + TypeScript + Tailwind CSS
````

Violations:

1. Emoji `[STAR]` (ref) in H1 — §3
2. `*` instead of `-` for unordered list (line 5) — §5.2
3. `[v]` and `[x]` Unicode icons instead of `[OK]` / `[FAIL]` — §4.4
4. Em dash `—` (ref) in H2 heading "Install — Quick Start" — §3
5. Table pseudographics in plain Markdown (should be a Markdown table or fenced `text` block) — §3
6. `Copyright (c)` typographic in plain Markdown — actually allowed in plain prose per §4.1, BUT the lowercase `(c)` is ambiguous; prefer `Copyright (c) 2026`
7. Code block at line 4 uses `*beautiful*` — italic syntax is fine, but the line mixes italic inside a blockquote which renders inconsistently across viewers

**After (compliant):**

````markdown
# Project Alpha

> Fast, reliable, and beautiful API client.

## Status

- [OK] Build passing
- [FAIL] Docs outdated

## Install: Quick Start

```
npm install alpha
```text

## Components

```
+-------------------+
|    HTTP Client    |
+-------------------+
          |
          v
+-------------------+
|    Retries        |
+-------------------+
```None

## Notes

Copyright (c) 2026 Alpha Corp. All rights reserved.

---

Built with: Next.js 16 + TypeScript + Tailwind CSS
````

What changed:

1. Emoji removed from H1
2. `*` list marker replaced with `-`
3. `[v]` / `[x]` replaced with `[OK]` / `[FAIL]`
4. Em dash in H2 replaced with colon (`:`)
5. ASCII diagram wrapped in a fenced `text` code block (so it is no longer "table pseudographics in plain Markdown" — it is now an allowed ASCII diagram per §4.2 / §12)
6. Italic inside blockquote replaced with plain text (blockquote + italic is not prohibited by rule, but is fragile across renderers; the safer pattern is shown here)
7. Copyright line kept (typographics in plain prose are allowed per §4.1)

**Verification:**

```bash
npx eslint README.md --plugin markdown --max-warnings=0
node lint-md.js README.md
```

Both exit 0. The PR is now mergeable.

---

## 13. Pre-merge Checklist

- [ ] No emoji or Unicode icons in documentation (STD-DOC-003 sections 4-5)
- [ ] No typographic symbols (em dash, copyright, etc.) in code blocks or headings
- [ ] Status indicators — text tags `[OK]`, `[FAIL]`
- [ ] Unordered lists use strictly `-` marker
- [ ] Unknown code blocks use `text` or `bash` fallback
- [ ] Stack signature present in root files
- [ ] Formatting matches standard
- [ ] Diagrams use whitelist characters
- [ ] ESLint runs without errors on source code (`--max-warnings=0`)
- [ ] ESLint runs without errors on .md files (same severity — see §10.6)
- [ ] `bash scripts/check-md.sh <file-or-dir>` exits 0 (wraps ESLint + `lint-md.js` + static checks — see §0)
- [ ] Any `eslint-disable` for [C]-level rules has Tech Lead approval (§10.8)

---

## 14. Version History

| Version | Date       | Changes                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| ------- | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0     | 2024-Q4    | Initial version                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| 2.0     | 2025-01    | Level [W], link to Unicode Policy v2.0, ASCII diagram whitelist, [W] blocking policy, linting stages, code formatting rules                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| 2.1     | 2025-01    | Allowed typographics in plain text; fixed `-` as sole list marker; clarified SVG via `![]()`; limited Stack Signature to root files; added `text/bash` fallback rule; removed redundant `v` from CI regex                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| 2.1.1   | 2025-01    | Updated references from Unicode Policy v2.0 to v2.1; CI config updated with eslint-plugin-markdown; Unicode symbols in section 4.4 replaced with text descriptions (document must not violate its own standard); code blocks without language replaced with `text`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| 2.1.2   | 2025-01    | Introduced `(ref)` exception for reference tables: characters in identifier cells allowed with marker; restored specific Unicode characters in prohibited/allowed element tables; `Incorrect` examples again show the actual prohibited character                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| 2.1.3   | 2025-01    | Extended `(ref)` exception to code blocks: identifier characters allowed with marker in code blocks too; `Incorrect` examples in code blocks now contain the actual symbol with `(ref)`; restored Unicode symbols in EN table 4.4                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| 2.1.4   | 2025-01    | Stack signature parameterized: format `Built with: <technologies>`, specific stack is project responsibility; default value moved to README_TEMPLATE                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| 2.1.5   | 2025-05    | Added section 7 "Badges" with shields.io rules, placeholders for projects without CI; section numbering shifted                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| 2.2.0   | 2026-05    | Deduplication: removed 7 elements duplicated with STD-DOC-003 (prohibited elements table, allowed characters, ASCII diagram whitelist, icon library, brand logos, sanitization regex, unconditionally allowed). Replaced with cross-references. Kept .md-specific rules: typographics scope, (ref) exception, SVG insertion, badges, stack signature, formatting rules, text tags                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| 2.3.0   | 2026-06    | Added comprehensive section 10 "ESLint Integration for Markdown Linting": flat config and legacy config examples, custom rules (code-block-language, no-emoji-in-md), nested standards mapping table, application stages with lint-staged and CI workflows, inline disable policy, manual run commands, troubleshooting; updated pre-merge checklist with ESLint items; updated references from STD-DOC-003 v2.1 to v2.2                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| 2.3.1   | 2026-06    | Updated in-body references from STD-DOC-003 v2.2 to v2.3 (header Related field, §3, §4.1, §4.2, §6.1, §6.2, §6.3, §7.2, §7.4, §11.1, §13 checklist). Added §14A Known Issues documenting MD-001 through MD-003.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| 2.3.2   | 2026-06    | §8 Stack Signature scope clarified: applies only to application repository README/CHANGELOG, NOT to standards/rules/skills/templates/meta-repos. Removed cargo-cult `Built with:` footer from this file (it is a governance doc, not an application). Project-wide cleanup documented in worklog task stack-signature-cleanup-2026-06-18.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| 2.4.0   | 2026-06    | Resolved MD-001 and MD-003 (both open since v2.3.1). **MD-001:** footer updated from `(level [W])` to `(level [C])`; §9.1 rewritten from `[W] non-blocking` to `[C] blocking` policy with `eslint-disable` + Tech Lead approval workflow and a per-project legacy soft-opt-out clause; §10.5.2 description updated from `[W] Warning` to `[C] Critical`; §10.8 rule 3 collapsed (no more `[W]`-in-docs carve-out); §10.9 comment updated; §13 checklist updated. ARCH-002 §1 Group B table and STD-META-001 §4.4 registry entry updated to `[C]`. **MD-003:** §10.3 flat config and §10.4 legacy config — `no-emoji-in-md` and `no-unicode-graphics-in-md` changed from `"warn"` to `"error"` (aligned with §10.6 mapping table). **New content:** §0 TL;DR with 5 must-not / 5 must / where-to-look table; §3 `(ref)` scope clarified with concrete appropriate / not-appropriate examples; §12.4 full before/after README example with 7 violations and verification commands. **Header:** Version 2.3.2 -> 2.4.0. |
| 2.4.1   | 2026-06    | Added `scripts/check-md.sh` — bash wrapper that runs three layers in sequence: (1) bash-only static checks for the most common §5 violations (bare code fences, `*`/`+` list markers, closing `#` on headings, multiple H1, table pseudographics outside code blocks); (2) ESLint via `eslint-plugin-markdown` if installed; (3) `lint-md.js` if present at repo root. Layers 2 and 3 degrade gracefully to `[skip]` when their tools are missing, so the script works in fresh clones without `npm install`. §0 TL;DR updated to recommend `bash scripts/check-md.sh [path]` as the primary entry point. §10.7 Application Stages table extended with a new "Manual check" row. §13 Pre-merge checklist extended with a `check-md.sh` bullet. §14A new MD-004 issue documents the 5 pre-existing bare-fence violations the script discovered in `README.md` and `docs/verify-id-graph-spec-v1.0.md`.                                                                                                                |
| 2.4.3   | 2026-06-21 | W11 soft-cap cleanup. Extracted §10 ESLint Integration (354 lines, reference implementation detail) to companion file `DOC-002-eslint-integration.md`. Companion is NOT parser-bound — inherits parent ID via "Companion to: STD-DOC-002" header line, same pattern as DESIGN-001-profile-terminal-dashboard. §10 replaced with stub (quick summary + pointer to companion). File size: 1012 -> 658 lines. W11 soft warning cleared. Section numbers (§10.1 through §10.7) preserved verbatim; external refs resolve to companion. §0 TL;DR entry point note updated to mention §10 lives in companion. No new IDs. No graph edge changes.                                                                                                                                                                                                                                                                                                                                                                           |
| 2.4.4   | 2026-07-03 | §8 Stack Signature scope reversal: skills (`skills/*/SKILL.md`) removed from the "does NOT apply to" list. Skills are now permitted to include a Stack Signature to indicate their runtime stack. Rationale: user decision to keep Stack Signature footer in skills (see worklog stack-signature-cleanup-2026-06-18). §8 "test" paragraph updated to note skill permission.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |

---

## 14A. Known Issues and Proposed Solutions

This section documents discovered inconsistencies, missing content, and proposed corrections. Each issue has an ID, status, and proposed action. Issues resolved in the current version are marked `[RESOLVED]`; outstanding issues are marked `[OPEN]`.

### MD-001 `[RESOLVED in v2.4.0]` — Level `[C]` vs `[W]` contradiction

**Problem:** The header of this file (§0) said `Level: **[C] Critical** (unified with STD-DOC-003 — same rule = same severity)`. The footer said `Document complies with MARKDOWN_STANDARD v2.3 (level [W])`. The registry in `META-001-standard-id-system.md` (STD-META-001 §4.4) listed this standard as `[W] Warning`. `ARCH-002-implementation-order.md` §1 Group B table also listed it as `[W]`. There was a three-way contradiction: header said `[C]`, footer/registry/IMPLEMENTATION_ORDER said `[W]`.

**Resolution (v2.4.0):** Adopted `[C] Critical` as the authoritative level. Rationale: (1) the "same rule = same severity" principle from STD-DOC-003 §3 is the v2.3.0 design intent; (2) the ESLint configuration in §10 already treated Markdown emoji/Unicode graphics as `error` (not `warn`) per §10.6; (3) `lint-md.js` defaults to `--level=C`. All four locations now say `[C]`:

1. This file's header (§0) — unchanged, was already `[C]`.
2. This file's footer — updated to `(level [C])`.
3. STD-META-001 §4.4 registry entry — updated to `[C]`.
4. STD-ARCH-002 §1 Group B table — updated to `[C]`.

In addition, §9.1 was rewritten from a `[W] non-blocking` policy to a `[C] blocking` policy with `eslint-disable` + Tech Lead approval workflow and a per-project legacy soft-opt-out clause. §10.5.2 description, §10.8 rule 3, §10.9 comment, and §13 checklist were updated to match.

### MD-002 `[RESOLVED in v2.3.1]` — In-body references to STD-DOC-003 cited v2.2

**Problem:** Prior to v2.3.1, the header `Related:` field said "Unicode Policy v2.2 (STD-DOC-003)". In-body references in §3, §4.1, §4.2, §6.1, §6.2, §6.3, §7.2, §7.4, §11.1, and §13 also cited v2.2. The actual version of STD-DOC-003 at the time of audit was v2.3.0.

**Resolution:** Header `Related:` field updated to "No-Unicode Policy v2.3 (STD-DOC-003)". All in-body references to STD-DOC-003 v2.2 updated to v2.3.

### MD-003 `[RESOLVED in v2.4.0]` — §10.3 ESLint config sets Markdown emoji to `warn`, contradicts §10.6 mapping table

**Problem:** Prior to v2.4.0, §10.3 (ESLint Configuration — Flat Config) set `unicode-policy/no-emoji-in-md` to `"warn"` and `unicode-policy/no-unicode-graphics-in-md` to `"warn"` for `**/*.md` files. However, §10.6 (Nested Standards mapping table) listed these same rules with severity `error` for STD-DOC-002 §3 (Prohibited: Emoji and Unicode icons). The §10.6 table footnote said "A rule originating from STD-DOC-003 ([C] Critical) applies with the same severity regardless of context — source code or documentation." This was internally inconsistent: §10.3 used `warn`, §10.6 said `error`.

**Resolution (v2.4.0):** Aligned §10.3 and §10.4 with §10.6 by changing both `no-emoji-in-md` and `no-unicode-graphics-in-md` from `"warn"` to `"error"` in both the flat config (§10.3) and the legacy config (§10.4). Added a note in §10.3 explaining: "Severity: error ([C] Critical) — same rule, same severity as source code. To soften enforcement for a legacy project migration, override in the project's local eslint.config.js to `warn` with a documented cutover date." This is consistent with MD-001's resolution (keep [C]).

### MD-004 `[OPEN]` — `scripts/check-md.sh` discovered 5 pre-existing bare-fence violations

**Problem:** The new `scripts/check-md.sh` wrapper added in v2.4.1 runs static checks across the whole repo when invoked without arguments. Its first full-repo run surfaced 5 bare code fences (fenced blocks without a language tag, violating §5.4):

- `README.md:14`
- `docs/verify-id-graph-spec-v1.0.md:32`
- `docs/verify-id-graph-spec-v1.0.md:60`
- `docs/verify-id-graph-spec-v1.0.md:337`
- `docs/verify-id-graph-spec-v1.0.md:452`

These violations pre-date the wrapper script — they were not introduced by v2.4.1, only discovered by it. They are in governance / spec docs (not standards corpus), which is why they slipped past the v2.3.0 deduplication audit that focused on `standards/*.md`.

**Proposed resolution (separate PR):** For each violation, add the appropriate language tag — `bash` for shell snippets, `text` for plain preformatted blocks, or the actual language (`javascript`, `yaml`, etc.) where applicable. The fix is mechanical and does not change semantics. Until then, the wrapper reports these failures on a full-repo run but passes on `bash scripts/check-md.sh standards/` (the standards corpus itself is clean).

---

**Document complies with MARKDOWN_STANDARD v2.4.4 (level [C])**

---

## 15. Cross-References

| Standard     | Relationship                                                                                                                                                                                                                                                                                                       |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| STD-DOC-003  | Unicode Policy: single source of truth for character rules. Sections 4-5 (prohibited elements), 6.1 (allowed characters), 6.2 (ASCII diagrams), 7 (icons/logos), 8.2-8.3 (sanitization regex), 10.1 (ESLint custom rule unicode-policy.js), 11.1 (unconditionally allowed) are cross-referenced from this standard |
| STD-META-001 | Standard ID System: registry entry for STD-DOC-002 must be kept in sync with the version in this document's header. See MD-001 for the level-ambiguity issue that requires registry attention.                                                                                                                     |
| STD-META-002 | Language Policy: documentation in English                                                                                                                                                                                                                                                                          |
