---
name: zai-md-std
id: ZAI-DOC-001
author: StsDev
version: 1.0.0
description: >
  Create and edit Markdown (.md) files compliant with Z.ai Markdown Standard (STD-DOC-002 v2.4)
  and No-Unicode Policy (STD-DOC-003 v2.3). Trigger on ANY request to create, write, draft,
  generate, edit, fix, validate, or lint a .md file, README, CHANGELOG, tech spec, design doc,
  API reference, guide, RFC, ADR, runbook, postmortem, release notes, or any documentation --
  even if the user does not say ".md" or "markdown" explicitly (e.g. "write docs for this
  project", "create a README"). Also trigger on compliance checks: "fix markdown violations",
  "validate .md", "check doc standard", "lint documentation". Russian: "напиши
  документацию", "сделай changelog", "подготовь спек", "напиши гайд", "оформи
  документ", "сделай worklog проекта", "проверь markdown", "приведи .md в порядок".
related:
  - STD-DOC-002
  - STD-DOC-003
  - STD-META-001
---

# Skill: Zai Markdown Standard v1.0.0

Create markdown documents that are fully compliant with STD-DOC-002 (Markdown Formatting v2.4)
and STD-DOC-003 (No-Unicode Policy v2.3). These standards exist because Unicode characters render
inconsistently across platforms, break visual hierarchy, and cannot be centrally controlled by
the design system. Following them produces documentation that is professional, predictable, and
machine-lintable.

## Quick Reference: 5 Must-Not / 5 Must

**Do NOT do these (all Critical -- blocks merge):**

1. No emoji anywhere (use `[OK]`, `[FAIL]`, `[TODO]` text tags instead)
2. No Unicode icons (status symbols, arrows, checkmarks used as decoration)
3. No typographic symbols in headings, tables, or code blocks (em dash, copyright, degree, plus-minus are allowed only in plain prose)
4. No table pseudographics outside fenced code blocks (use Markdown pipe tables `| ... |`)
5. No closing `#` on headings, no `*` or `+` for unordered lists (use `-` only)

**Always do these:**

1. One H1 per document, at the very top
2. Every fenced code block specifies a language (use `text` or `bash` if unknown)
3. Application repo root README ends with `---\nBuilt with: <stack>` (not for standards, skills, meta-repos)
4. Use `(ref)` marker only when a character is the *object of demonstration*
5. Use status text tags: `[OK]`, `[FAIL]`, `[TODO]`, `[WARNING]`, `[INFO]`, `[DRAFT]`, `[BLOCKED]`, `[DEPRECATED]`

## Allowed Character Set

The document body may contain:

| Category | Examples |
|----------|----------|
| ASCII letters | a-z, A-Z |
| Cyrillic | a-ya, A-YA |
| Digits | 0-9 |
| Punctuation | `.` `,` `;` `:` `!` `?` `-` `_` `(` `)` `[` `]` `{` `}` |
| Whitespace | space, tab, newline |

**Typographic symbols** (em dash, en dash, degree sign, copyright, plus-minus, etc.) are
permitted in **plain prose paragraphs only**. They are prohibited in headings, table cells,
inline code, code blocks, and file/folder names.

**Code block diagram whitelist** (level [I], only inside fenced `text` blocks):

```
->  <-  =>  <=  |  +  -  v  ^  >  <
```

## Document Structure Rules

### Headings

- Use `#` for H1, `##` for H2, `###` for H3, and so on.
- Exactly one H1 per document, placed at the top as the title.
- Do not use closing `#` symbols (e.g., `# Title #` is wrong).
- Do not use typographic symbols in headings. Replace em dashes with colons or commas.

```text
Correct:   ## Installation: Quick Start
Correct:   ## Configuration
Incorrect: ## Configuration #
Incorrect: ## Install -- Quick Start
```

### Lists

Unordered lists use strictly the `-` marker. Never mix with `*` or `+`.

```text
Correct:
- First item
- Second item
- Third item

Incorrect:
* First item
+ Second item
```

Ordered lists use the `1.` format:

```text
1. First step
2. Second step
3. Third step
```

### Code Blocks

Every fenced code block must specify a language identifier. If the language is unknown or
not supported by the renderer, use `text` or `bash` as a fallback.

```text
Correct:
```bash
npm install
```

```text
Some preformatted content
```

Incorrect:
```
Bare fence without language
```
```

Inline code uses single backticks:

```markdown
Use the `processFile()` function for processing files.
```

Do not use HTML tags for syntax coloring. Color is the responsibility of the renderer theme.

### Tables

Use standard Markdown pipe syntax. Never use Unicode box-drawing characters (U+2500-U+257F)
to simulate table borders outside of fenced code blocks.

```markdown
| Column A | Column B |
|----------|----------|
| Value 1  | Value 2  |
| Value 3  | Value 4  |
```

### Text Emphasis

| Format | Syntax |
|--------|--------|
| Bold | `**text**` |
| Italic | `*text*` |
| Strikethrough | `~~text~~` |

### Links and Images

```markdown
[Link text](https://example.com)
![Alt description](./path/to/image.svg)
```

## Visual Elements

### Icons and Graphics

Any visual symbol in documentation must be one of:

1. **SVG via Markdown image syntax** -- `![description](./path/to/icon.svg)`
2. **Text alternative** -- a descriptive word or phrase

Raw `<svg>...</svg>` HTML tags are prohibited in markdown. SVG files must be separate files
referenced through the standard image syntax.

### Badges

Use shields.io for project metadata badges. Place them after the H1 in README.md.

```markdown
[![npm version](https://img.shields.io/npm/v/package.svg)](https://www.npmjs.com/package/package)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
```

For projects without CI, use static badges:

```markdown
[![Status: Draft](https://img.shields.io/badge/Status-Draft-yellow.svg)]()
```

Emoji in badges are prohibited (even though shields.io supports them).

### ASCII Diagrams

ASCII diagrams are allowed inside fenced `text` code blocks. They use only the whitelisted
characters listed in the Allowed Character Set section above.

```text
+-------------------+
|    Component A    |
+---------+---------+
          |
          v
+-------------------+
|    Component B    |
+---------+---------+
```

Do not place ASCII diagrams directly in the markdown flow -- always wrap them in a code block.

## Stack Signature

Application repository root `README.md` (and optionally `CHANGELOG.md`) must end with a
stack signature. The format is:

```markdown
---
Built with: <project technologies>
```

Example:

```markdown
---
Built with: Next.js 16 + TypeScript + Tailwind CSS
```

The specific technologies are determined by the project, not by this skill.

**Stack signature does NOT apply to:**
- Standards documents (`standards/*.md`)
- Rules documents (`guard/rules/*.md`)
- Skills (`skills/*/SKILL.md`)
- Templates (`templates/*.md`)
- Orchestrator / meta-repositories

**Stack signature rules:**
- Placement: end of file
- Separator: three dashes `---`
- Content: letters, digits, `+` and `:` signs only
- No graphics, no emoji

## The (ref) Marker Convention

When you need to show a prohibited character in a table cell, code block, or paragraph that
is specifically about identifying that character, append `(ref)` after it. The `(ref)` marker
means "this character appears here as the object of description, not as formatting."

**Where (ref) is appropriate:**
- A table cell whose purpose is to identify the character (e.g., an "Incorrect" column showing a prohibited symbol)
- A code block line demonstrating the character
- A paragraph that explicitly discusses the character (e.g., "The `--` (ref) character is U+2014")

**Where (ref) is NOT appropriate:**
- Normal prose where the character is used as formatting
- Headings or table cells that are not about the character itself
- As a way to sneak a prohibited character into a heading by appending `(ref)`

## Status Text Tags

Replace all Unicode status symbols with text tags:

| Use this | Not this |
|----------|----------|
| `[OK]` | checkmark or check icon |
| `[FAIL]` | cross mark or x icon |
| `[DONE]` | checkmark with circle |
| `[TODO]` | open circle or checkbox |
| `[WARNING]` | warning sign or triangle |
| `[INFO]` | info circle or i icon |
| `[DRAFT]` | pencil icon |
| `[BLOCKED]` | lock icon |
| `[DEPRECATED]` | strikethrough or warning |

## Writing Workflow

When the user asks you to create or edit a markdown document, follow these steps:

1. **Understand the context.** What kind of document is this? README, technical spec, CHANGELOG,
   internal doc, or a standard/rule itself? The type determines whether a stack signature is needed.
2. **Plan the structure.** Decide on headings (one H1 at top, then H2/H3 as needed). Outline the
   sections before writing content.
3. **Write the content.** Follow all rules from this skill. Use the Quick Reference as a mental
   checklist while writing.
4. **Review before saving.** Run through the Validation Checklist below. Fix any violations.
5. **Save the file.** Write the `.md` file to the requested path.

## Validation Checklist

Before finalizing any markdown document, verify every item:

- [ ] No emoji or Unicode pictographs anywhere in the file
- [ ] No Unicode icons (checkmarks, crosses, arrows used as decoration, box-drawing characters outside code blocks)
- [ ] No typographic symbols (em dash, degree, copyright, etc.) in headings, table cells, code blocks, or file names
- [ ] Status indicators use text tags: `[OK]`, `[FAIL]`, `[TODO]`, etc.
- [ ] Exactly one H1, at the top of the document
- [ ] No closing `#` on any heading
- [ ] All unordered lists use `-` marker (no `*` or `+`)
- [ ] Every fenced code block has a language specifier (`text` or `bash` as fallback)
- [ ] Tables use Markdown pipe syntax, not Unicode borders
- [ ] ASCII diagrams are wrapped in fenced `text` code blocks
- [ ] Icons use SVG via `![]()` syntax, not raw HTML
- [ ] Badges use shields.io, no emoji in badges
- [ ] Stack signature present if this is an application repo root README (absent if it is a standard, rule, skill, template, or meta-repo)
- [ ] No HTML color tags (`<span style="color:...">`)
- [ ] Any `(ref)` markers are used correctly -- only when the character is the object of demonstration

## Common Mistakes and Corrections

**Mistake 1: Em dash in heading**

```text
Before:    ## Authentication -- Quick Start
After:     ## Authentication: Quick Start
```

**Mistake 2: Asterisk as list marker**

```text
Before:    * Item one
After:     - Item one
```

**Mistake 3: Bare code fence**

```text
Before:    ```
           some text
           ```

After:     ```text
           some text
           ```
```

**Mistake 4: Unicode status icons**

```text
Before:    - [v] Build passing
After:     - [OK] Build passing
```

**Mistake 5: ASCII diagram outside code block**

```text
Before:    (diagram with +---+ directly in markdown flow)
After:     Wrap in a ```text fenced block
```

**Mistake 6: Copyright symbol in code block**

```text
Before:    // Copyright (c) 2026
           (where (c) is the Unicode copyright sign U+00A9)
After:     // Copyright (c) 2026
           (where (c) is the ASCII letters 'c' in parentheses -- this is allowed)
```

Note: The typographic copyright sign is prohibited in code blocks. The ASCII text
"(c)" is a valid substitute.

## Detailed Reference

For edge cases, detailed ESLint configuration, known issues, and the full normative
specification, consult the bundled reference files:

- `references/doc-002-rules.md` -- condensed rules from STD-DOC-002 (Markdown Formatting Standard)
- `references/doc-003-rules.md` -- condensed rules from STD-DOC-003 (No-Unicode Policy)

These are concise summaries. For the complete standards with all version history, known
issues, and ESLint implementation details, refer to the original full documents in the
project's `standards/` directory.