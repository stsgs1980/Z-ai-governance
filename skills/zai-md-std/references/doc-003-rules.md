# STD-DOC-003 Rules Summary (No-Unicode Policy v2.3)

This is a condensed reference extracted from the full standard for quick edge-case lookups.
The full document is `standards/standards/DOC-003-unicode-policy.md`.

## Scope

- Applies to UI, production code, AI-chat, prototypes, and documentation
- Three strictness levels: [C] Critical, [W] Warning, [I] Info
- For markdown documents (.md), see also STD-DOC-002 which delegates character rules to this standard

## Strictness Levels

| Level | Notation | Context | Action |
|-------|----------|---------|--------|
| Critical | [C] | UI, production code, documentation | Blocks merge |
| Warning | [W] | AI-chat only | Warning in review |
| Info | [I] | Internal notes, prototypes | Recommendation |

## Prohibited Character Categories

| Category | Level | Examples |
|----------|-------|----------|
| Emoji | [C] | Any pictograms: emotions, objects, UI-symbols, flags |
| Unicode icons | [C] | Status symbols, action icons, notification glyphs |
| Decorative symbols | [W] | Pseudographics, markers, highlights used as decoration |

## Allowed Character Set (Basic)

| Category | Characters |
|----------|-----------|
| ASCII letters | a-z, A-Z |
| Cyrillic | Full range (a-ya, A-YA) |
| Digits | 0-9 |
| Punctuation | `.` `,` `;` `:` `!` `?` `-` `_` `(` `)` `[` `]` `{` `}` |
| Whitespace | space, tab, newline |

## Diagram Whitelist (Level [I])

Allowed only inside fenced code blocks:

```
->   right arrow
<-   left arrow
=>   implication
<=   reverse implication
|    vertical line
+    line junction
-    horizontal line
v    down arrow
^    up arrow
>    pointer
<    reverse pointer
```

## Icon Standard

- Any visual symbol in UI = SVG only
- SVG must be part of Design System, use design tokens, support theming
- Primary icon library: Lucide
- Brand logos: official SVG only (Next.js, TypeScript, Tailwind CSS, Prisma, etc.)
- In documentation, use text descriptions or SVG via `![](path/to/icon.svg)`

## AI Chat Rules (Level [W])

Character set for AI-agent chat output:
- ASCII letters, digits, standard punctuation: allowed
- Cyrillic: allowed
- Typographic characters (em dash, en dash, degree, plus-minus): allowed in plain text only
- Status text tags: `[OK]`, `[FAIL]`, `[TODO]`, `[WARNING]`, `[INFO]`, `[DRAFT]`, `[BLOCKED]`, `[DEPRECATED]`
- Diagram symbols (`->`, `|`, `+`, `-`, `v`, `^`): allowed inside code blocks only

Prohibited in chat:
- Emoji (any range including ZWJ sequences)
- Unicode pictographs (arrows as decoration, stars, checkmarks)
- Dingbats, Miscellaneous Symbols, Mathematical Operators as decoration
- Box-drawing characters for trees (use ASCII `+--`, `|`, `\-` inside `text` blocks)
- Unicode horizontal rules (use Markdown `---`)

## Sanitization Regex

For [C] level (code/UI) -- ASCII + Cyrillic only:
```javascript
text.replace(/[^\x20-\x7E\u0400-\u04FF]/g, '')
```

For [I] level -- with diagram whitelist:
```javascript
text.replace(/[^\x20-\x7E\u0400-\u04FF\-\>\<\=\|\+\^]/g, '')
```

Note: [W] level (documentation) is regulated by STD-DOC-002. Typographic characters are
allowed in plain text of .md files, so the strict sanitization is NOT applied to .md files.

## ESLint Custom Rule: no-unicode-policy.js

Four sub-rules:

| Rule | Context | Level | What it detects |
|------|---------|-------|-----------------|
| `no-emoji` | Production code (.ts, .tsx, .js, .jsx) | [C] error | Emoji in string literals, template literals, JSX text |
| `no-unicode-graphics` | Production code | [C] error | Box-drawing, block elements, geometric shapes, arrows |
| `no-emoji-in-md` | Markdown files (.md) | [C] error | Emoji in .md text (excluding code blocks) |
| `no-unicode-graphics-in-md` | Markdown files (.md) | [C] error | Unicode graphics in .md text (excluding code blocks) |

### Unicode Ranges Detected

**Emoji:**
- U+1F600-U+1F64F (Emoticons)
- U+1F300-U+1F5FF (Misc Symbols and Pictographs)
- U+1F680-U+1F6FF (Transport and Map)
- U+1F1E0-U+1F1FF (Flags)
- U+2600-U+27BF (Misc Symbols)
- U+FE00-U+FEFF (Variation Selectors)
- U+1F900-U+1F9FF (Supplemental Symbols)
- U+1FA00-U+1FA6F (Chess Symbols)
- U+1FA70-U+1FAFF (Symbols Extended-A)
- U+2702-U+27B0 (Dingbats)

**Unicode Graphics:**
- U+2500-U+257F (Box Drawing)
- U+2580-U+259F (Block Elements)
- U+25A0-U+25FF (Geometric Shapes)
- U+2190-U+21FF (Arrows)
- U+2200-U+22FF (Mathematical Operators)
- U+2300-U+23FF (Misc Technical)
- U+2800-U+28FF (Braille Patterns)

## Exceptions

### Unconditionally Allowed

- ASCII letters (a-z, A-Z), Cyrillic, digits, standard punctuation
- Diagram whitelist symbols inside code blocks

### By Agreement (requires approval)

- Email campaigns with emoji (coordinate with marketing)
- Localization (non-ASCII languages like Chinese, Arabic)
- Accessibility (Unicode for screen readers)

### Approval Process

1. Create issue with justification
2. Get Tech Lead approval
3. Document exception in code
4. Add to whitelist if necessary

## Known Issues (from v2.3.0)

- UNI-002 [OPEN]: ESLint rule does not cover chat output (chat is not a file)
- UNI-003 [OPEN]: Stale version reference in DESIGN-001
- UNI-004 [OPEN]: Registry version mismatch in META-001