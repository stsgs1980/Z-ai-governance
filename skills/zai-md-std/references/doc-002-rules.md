# STD-DOC-002 Rules Summary (Markdown Formatting Standard v2.4)

This is a condensed reference extracted from the full standard for quick edge-case lookups.
The full document is `standards/standards/DOC-002-markdown-standard.md`.

## Scope

- Applies to all `.md` files in the project
- Level: [C] Critical (violations block merge)
- Enforcement: ESLint + lint-staged + CI

## Prohibited Elements (Critical)

| Element | Details |
|---------|---------|
| Emoji | Any pictograms in any context |
| Unicode icons | Status symbols, arrows as decoration, checkmarks, crosses |
| Typographics in structured contexts | Em dash, en dash, degree, copyright, plus-minus -- prohibited in headings, tables, code blocks, file names. Allowed in plain prose paragraphs only. |
| Table pseudographics outside code blocks | Box-drawing characters used to draw tables in plain markdown |
| Closing `#` on headings | `# Title #` is prohibited |
| `*` or `+` for unordered lists | Only `-` is the valid unordered list marker |
| Bare code fences | Every ```` ``` ```` must be followed by a language identifier |
| HTML color tags | `<span style="color:...">` is prohibited |
| Raw SVG HTML | `<svg>...</svg>` tags directly in markdown are prohibited |

## Allowed Elements

### Markdown Syntax

| Element | Syntax |
|---------|--------|
| Headings | `#`, `##`, `###` (one H1 at top) |
| Bold | `**text**` |
| Italic | `*text*` |
| Strikethrough | `~~text~~` |
| Inline code | `` `code` `` |
| Code block | ```` ```language ```` |
| Blockquote | `>` |
| Unordered list | `-` (strictly) |
| Ordered list | `1.` |
| Link | `text` |
| Image | `alt` |

### Text Tags for Statuses

| Correct | Purpose |
|---------|---------|
| `[OK]` | Success, complete, passing |
| `[FAIL]` | Failure, error, broken |
| `[DONE]` | Task completed |
| `[TODO]` | Not yet done |
| `[WARNING]` | Caution, potential issue |
| `[INFO]` | Informational note |
| `[DRAFT]` | Work in progress |
| `[BLOCKED]` | Waiting on dependency |
| `[DEPRECATED]` | No longer recommended |

### Typographic Symbols Scope

**Allowed in:** Plain prose paragraphs only.

**Prohibited in:**
- Headings (H1-H6)
- Table cells (both headers and data)
- Inline code (`` `...` ``)
- Code blocks (fenced or inline)
- File and folder names

## Stack Signature

**Format:**
```markdown
---
Built with: <technologies>
```

**Applies to:**
- Root `README.md` of application repositories (repos that ship runnable code)
- Root `CHANGELOG.md` (optional but recommended)

**Does NOT apply to:**
- Standards, rules, skills, templates
- Meta-repos / orchestrator repos (e.g., Z-ai-governance, standards/)
- Nested docs (`docs/**/*.md`)

**Test:** "Does this repo ship a runnable application whose stack a reader would care about?"
If yes, add stack signature. If no, do not.

## Badges

- Source: shields.io (recommended) or custom SVG
- Place after H1 in README.md
- No emoji in badges
- For projects without CI, use static badges with `Status: Draft` / `Version: X.Y.Z`

## ESLint Integration

- `eslint-plugin-markdown` parses `.md` files
- Custom rules in `eslint-rules/no-unicode-policy.js` (from STD-DOC-003)
- Custom rule `code-block-language.js` enforces language tags on code fences
- Pre-commit: husky + lint-staged runs `node lint-md.js` on `*.md`
- CI: `npx eslint '**/*.md' --plugin markdown --max-warnings=0`
- Manual: `bash scripts/check-md.sh path/to/file.md`

## Inline Disabling

```markdown
<!-- eslint-disable-next-line no-unicode-policy/no-emoji-in-md -->
This line intentionally contains an emoji for demonstration purposes.
```

Rules:
1. Each disable must include a justification comment
2. Disabling [C]-level rules requires Tech Lead approval
3. Always specify the rule name (no bare `eslint-disable`)
4. Prefer `eslint-disable-next-line` over `eslint-disable` (smallest scope)

## (ref) Marker Convention

Use `(ref)` after a character only when that character is the **object of demonstration** --
i.e., the purpose of the cell/code line/paragraph is to identify and discuss the character itself.

Appropriate: A table showing "Incorrect" examples where the cell needs to display the actual
prohibited character so the reader can see it.

Not appropriate: Appending `(ref)` to a heading to sneak an em dash past the rules. The
marker reflects purpose, not permission.

## Known Issues (from v2.4.1)

- MD-004 [OPEN]: 5 pre-existing bare-fence violations in `README.md` and `docs/verify-id-graph-spec-v1.0.md` -- need language tags added