# Design System Profile: Terminal Dashboard (EXAMPLE) — Companion to STD-DESIGN-001

> Companion to: STD-DESIGN-001 v3.1.0 (Design System Standard)
> Profile ID: PROFILE-TERMINAL-001
> Type: Reference appendix, NOT a separate standard
> Last Updated: 2026-06-18
> Status: ILLUSTRATIVE EXAMPLE

This file is a **companion reference** to `DESIGN-001-design-system.md`
(STD-DESIGN-001 v3.1.0). It contains the full Terminal Dashboard example
Profile — concrete token values, component maps, ESLint rule example,
and AI agent context template.

**This file is NOT a separate standard.** It does not have an `STD-` ID
of its own and does not participate in the ID graph. It is referenced
from STD-DESIGN-001 §13 (Profile Requirements) as the canonical
illustrative example of a fully populated Profile.

## Why this file exists

In STD-DESIGN-001 v3.0.x, the Terminal Dashboard Profile (sections
§14-§26) lived inline in the main standard file. The combined file was
1781 lines, exceeding the 1500-line hard cap (W11 CRITICAL warning from
`verify-id-graph.js`). In v3.1.0, the Profile content was moved to this
companion file to bring STD-DESIGN-001 under the cap while preserving
all section numbers and content verbatim.

The Core (universal rules, §0-§13) lives in
`DESIGN-001-design-system.md`. The Profile (concrete Terminal Dashboard
example, §14-§26) lives here. Both files together constitute the full
content of STD-DESIGN-001 v3.0.1 + the v3.1.0 split.

## How cross-references resolve

External references to "STD-DESIGN-001 §N" where N is in 14-26 resolve
to this companion file. References where N is in 0-13 resolve to
`DESIGN-001-design-system.md`. The section numbers are preserved
verbatim (no renumbering) to keep all existing references stable.

---

## PROFILE: Terminal Dashboard (EXAMPLE)

> Profile ID: PROFILE-TERMINAL-001
> Design Language: Terminal-inspired developer dashboard
> Project Type: Knowledge base / documentation tool with CLI aesthetic
> Integration Pattern: Pattern A (Theme Extension with Tailwind CSS)
> Adoption Phase: Phase 3 (Full Enforcement)

**IMPORTANT: This is an EXAMPLE Profile, not the standard itself.** The Core (Sections 3-13) defines the universal rules. Everything below is one possible instantiation of those rules for a specific design language (terminal aesthetic). If your project has a different visual language, you create your own Profile following the same P1-P11 structure. The Core remains unchanged; only the Profile changes.

This example Profile serves a dual purpose:

1. **Working profile** for projects that match this design language (terminal-style developer tools). Use as-is.

2. **Reference template** for understanding how a Profile is structured. Each section below maps to a required P-section from the Core (Section 13). When creating a new Profile, follow the same structure but replace all token values, component names, and design language choices with your own.

**How to create a new Profile:**

- Copy all P-sections below (P1-P11)
- Change Profile ID, Design Language, Project Type
- Replace ALL token values (fonts, colors, spacing, archetypes, component map) with your project's values
- Replace ALL Profile-specific rules with rules appropriate for your design language
- Verify against the Profile Validation Checklist (Section 13.1)
- Remove this instructional preamble from the new Profile

**Key principle:** The structural skeleton (P1-P11) is the same for every Profile. The values inside are different for each project.

**Section-to-P mapping in this example:**

| Document Section | P-Section | Content |
|-----------------|-----------|---------|
| (header) | -- | Profile Identity |
| 14 | P1 | Font Roles & Default Implementation |
| 15 | P2 | Typography Scale |
| 16 | P3 | Color Tokens |
| 17 | P4 | Syntax Highlighting Tokens |
| 18 | P5 | Spacing Scale |
| 19 | P6 | Card Archetypes |
| 20 | P7 | Component Token Map |
| 21 | P8 | Prohibited Patterns |
| 22 | P9 | CSS Custom Properties |
| 23 | P10 | Enforcement Rule |
| 24 | P11 | Agent Context |

Note: Sections 25-26 (Version History, Cross-References) are document infrastructure shared by Core and Profile. They are not Profile-specific.

---

## 14. [PROFILE P1] Font Roles & Default Implementation

| Role | Token | Default Font | Rationale |
|------|-------|-------------|-----------|
| Sans-serif | `font-sans` | Inter | Variable weight, optimized for screen legibility, wide language support |
| Monospace | `font-mono` | JetBrains Mono | Designed for code, ligatures available, clear at small sizes |

A project may substitute fonts provided the replacement meets the Core role requirements (Section 3.1). Substitution must be documented in the project configuration and approved by Tech Lead.

---

## 15. [PROFILE P2] Typography Scale

Ten tokens. The monospace role dominates chrome elements (labels, badges, prompts, metadata), which is characteristic of the terminal aesthetic.

### 15.1. Token Definitions

| Token | Size | Weight | Family | Extras | Usage |
|-------|------|--------|--------|--------|-------|
| `--text-h1` | 24px | Bold (700) | `font-sans` | -- | Page heading |
| `--text-h2` | 18px | Bold (700) | `font-sans` | -- | Section heading |
| `--text-h3` | 14px | Semibold (600) | `font-sans` | -- | Card / element heading |
| `--text-body` | 14px | Regular (400) | `font-sans` | -- | Descriptions, notes, explanations |
| `--text-body-sm` | 12px | Regular (400) | `font-sans` | -- | Secondary text, subtitles, dates |
| `--text-label` | 11px | Regular (400) | `font-mono` | -- | Field labels, breadcrumbs, terminal titles |
| `--text-badge` | 10px | Regular (400) | `font-mono` | -- | Count badges, tiny labels |
| `--text-section` | 10px | Regular (400) | `font-mono` | Uppercase, tracking-wider | Section headers, category labels |
| `--text-code` | 13px | Regular (400) | `font-mono` | -- | Code blocks, terminal output |
| `--text-code-label` | 11px | Medium (500) | `font-mono` | -- | Terminal title bar labels |

### 15.2. Default Implementation (Tailwind CSS) -- Informational

| Token | Tailwind Class |
|-------|---------------|
| `--text-h1` | `text-2xl font-bold font-sans` |
| `--text-h2` | `text-lg font-bold font-sans` |
| `--text-h3` | `text-sm font-semibold font-sans` |
| `--text-body` | `text-sm font-sans` |
| `--text-body-sm` | `text-xs font-sans` |
| `--text-label` | `text-[11px] font-mono` |
| `--text-badge` | `text-[10px] font-mono` |
| `--text-section` | `text-[10px] font-mono uppercase tracking-wider` |
| `--text-code` | `text-[13px] font-mono` |
| `--text-code-label` | `text-[11px] font-mono font-medium` |

A project using a different CSS framework must map these tokens to the framework's equivalent utility classes or custom CSS. The token definitions (size, weight, family) in Section 15.1 are normative; this Tailwind mapping is informational and only applies if this CSS framework is used.

### 15.3. Profile-Specific Font Rules

- `font-sans` is mandatory for all headings (`h1`, `h2`, `h3`). Headings must never use `font-mono`.
- `font-mono` is reserved for terminal chrome: labels, badges, buttons, metadata, footer, sidebar, prompts.
- `font-sans` is for readable text: headings, descriptions, body content, card text.
- Stat card values use `font-mono` with `tabular-nums` (exception to the "mono is for chrome" rule, justified by tabular data alignment).

### 15.4. Typography Usage Examples

```tsx
// [OK] Heading uses font-sans via token
<h1 className="text-2xl font-bold font-sans">Page Title</h1>

// [FAIL] Heading uses font-mono
<h1 className="text-2xl font-bold font-mono">Page Title</h1>

// [OK] Terminal label uses font-mono via token
<span className="text-[11px] font-mono">$</span>

// [FAIL] Arbitrary font size not in scale
<span className="text-[9px]">Label</span>
```

### 15.5. Alternative Implementation: CSS Modules (Pattern B)

The Tailwind mapping above is the default for this Profile. If the project uses CSS Modules instead (Integration Pattern B, Section 4.5), the typography tokens would be consumed as follows:

```css
/* typography.module.css */
.h1 {
  font-size: 24px;
  font-weight: 700;
  font-family: var(--font-sans);
}

.h2 {
  font-size: 18px;
  font-weight: 700;
  font-family: var(--font-sans);
}

.body {
  font-size: 14px;
  font-weight: 400;
  font-family: var(--font-sans);
}

.label {
  font-size: 11px;
  font-weight: 400;
  font-family: var(--font-mono);
}

.code {
  font-size: 13px;
  font-weight: 400;
  font-family: var(--font-mono);
}
```

```tsx
// Component code with CSS Modules
import typo from './typography.module.css';

<h1 className={typo.h1}>Page Title</h1>
<span className={typo.label}>$</span>
```

The token values (size, weight, family) are the same regardless of integration pattern. Only the consumption mechanism changes.

---

## 16. [PROFILE P3] Color Tokens

### 16.1. Primary Tokens

| Token | Light Value | Dark Value | Purpose |
|-------|-------------|------------|---------|
| `--terminal-accent` | `oklch(0.65 0.2 145)` | `oklch(0.75 0.18 145)` | Green for `$` prompts, active nav cursor |
| `--neuro-brand` | `#FA3913` | `#FA3913` | Coral for brand mark, dividers |
| `--star-color` | `oklch(0.78 0.16 75)` | (auto dark variant) | Amber for stars, bookmarks, AI sparkles |
| `--semantic-violet` | `oklch(0.55 0.25 295)` | `oklch(0.65 0.22 295)` | Violet for semantic search, AI badges |
| `--accent-red` | `#dc2626` | `#f87171` | Destructive actions, errors |

### 16.2. Accent Aliases

| Alias Token | Resolves To | Light | Dark | When to use |
|-------------|-------------|-------|------|-------------|
| `--accent-green` | `var(--terminal-accent)` | `#16a34a` | `#4ade80` | When referencing "green accent" in a new context |
| `--accent-amber` | `var(--star-color)` | `#b45309` | `#fbbf24` | When referencing "amber accent" for warnings |
| `--accent-violet` | `var(--semantic-violet)` | `#7c3aed` | `#a78bfa` | When referencing "violet accent" in a new context |
| `--accent-red` | (primary token) | `#dc2626` | `#f87171` | Destructive, error states |

### 16.3. CSS Implementation

```css
:root {
  /* Primary tokens with light values */
  --terminal-accent: oklch(0.65 0.2 145);
  --neuro-brand: #FA3913;
  --star-color: oklch(0.78 0.16 75);
  --semantic-violet: oklch(0.55 0.25 295);
  --accent-red: #dc2626;

  /* Aliases resolve to primaries */
  --accent-green: var(--terminal-accent);
  --accent-amber: var(--star-color);
  --accent-violet: var(--semantic-violet);
}

.dark {
  --terminal-accent: oklch(0.75 0.18 145);
  --semantic-violet: oklch(0.65 0.22 295);
  --accent-red: #f87171;
}
```

### 16.4. Profile-Specific Color Rules

- Replace all `text-green-600 dark:text-green-400` pairs with `var(--terminal-accent)`.
- Replace all `text-amber-500` (star color) with `var(--star-color)`.
- Replace all `text-violet-600` / `text-violet-500` with `var(--semantic-violet)`.
- Never hardcode hex colors in component code.
- `--neuro-brand` is the same value in both themes (intentional brand consistency).

**Template note for new Profiles:** This Profile defines only accent and brand colors because the terminal aesthetic relies on the framework's default neutral palette (`foreground`, `muted-foreground`, `border`, `muted`) for surface and text colors. A Profile with a richer visual language (e.g., immersive, editorial, marketing) should define additional semantic tokens for neutral surfaces and text layers. Examples:

| Token | Purpose | Why it matters |
|-------|---------|----------------|
| `--surface-primary` | Main background | Deeper than default for immersive sites |
| `--surface-elevated` | Card/panel background | Visual depth without borders |
| `--text-primary` | Main text | Higher contrast than default foreground |
| `--text-secondary` | Supporting text | Softer than primary, but not muted |
| `--divider` | Lines and separators | Distinct from border, subtler |

These are optional at the Core level, but strongly recommended for any project that cannot rely on the framework's default neutral palette.

### 16.5. Color Token Usage Examples

```tsx
// [FAIL] Hardcoded color pair
<span className="text-green-600 dark:text-green-400">$</span>

// [OK] Semantic token via theme extension (Pattern A, Section 4.5)
<span className="text-accent-primary">$</span>

// [FAIL] Hardcoded violet
<button className="bg-violet-600">Search</button>

// [OK] Semantic token via theme extension (Pattern A, Section 4.5)
<button className="bg-semantic-search">Search</button>
```

---

## 17. [PROFILE P4] Syntax Highlighting Tokens

Eight tokens for code block syntax coloring in the terminal aesthetic.

### 17.1. Token Definitions

| Token | Light | Dark | Demo |
|-------|-------|------|------|
| `--syntax-comment` | `#6b7280` | `#78716c` | `// comment` |
| `--syntax-keyword` | `#16a34a` | `#4ade80` | `POST` |
| `--syntax-string` | `#b45309` | `#fbbf24` | `"value"` |
| `--syntax-function` | `#7c3aed` | `#c084fc` | `/api/backup` |
| `--syntax-path` | `#0891b2` | `#22d3ee` | `/path/to/file` |
| `--syntax-flag` | `#2563eb` | `#60a5fa` | `--verbose` |
| `--syntax-number` | `#c2410c` | `#fb923c` | `42` |
| `--syntax-env` | `#0d9488` | `#2dd4bf` | `DATABASE_URL=` |

### 17.2. CSS Implementation

```css
:root {
  --syntax-comment: #6b7280;
  --syntax-keyword: #16a34a;
  --syntax-string: #b45309;
  --syntax-function: #7c3aed;
  --syntax-path: #0891b2;
  --syntax-flag: #2563eb;
  --syntax-number: #c2410c;
  --syntax-env: #0d9488;
}

.dark {
  --syntax-comment: #78716c;
  --syntax-keyword: #4ade80;
  --syntax-string: #fbbf24;
  --syntax-function: #c084fc;
  --syntax-path: #22d3ee;
  --syntax-flag: #60a5fa;
  --syntax-number: #fb923c;
  --syntax-env: #2dd4bf;
}
```

### 17.3. Default Syntax Highlighter: Prism.js -- Informational

```css
/* [OK] Prism theme using design tokens */
.token.comment { color: var(--syntax-comment); }
.token.keyword { color: var(--syntax-keyword); }
.token.string  { color: var(--syntax-string); }
.token.function { color: var(--syntax-function); }

/* [FAIL] Prism theme with hardcoded values */
.token.comment { color: #6b7280; }
.token.keyword { color: #16a34a; }
```

A project may use an alternative syntax highlighter (Shiki, Highlight.js, etc.) provided it maps token classes to the same `--syntax-*` custom properties.

---

## 18. [PROFILE P5] Spacing Scale

### 18.1. Token Definitions

| Token | Pixels | Usage |
|-------|--------|-------|
| `--space-xs` | 6px | Inside badges, tight groups |
| `--space-sm` | 8px | Within groups, icon gaps |
| `--space-md` | 12px | Within cards, sections |
| `--space-lg` | 16px | Between sections, card padding |
| `--space-xl` | 24px | Page-level padding, view margins |

### 18.2. Default Implementation (Tailwind CSS) -- Informational

| Token | Tailwind Class |
|-------|---------------|
| `--space-xs` | `gap-1.5` / `p-1.5` |
| `--space-sm` | `gap-2` / `p-2` |
| `--space-md` | `gap-3` / `p-3` |
| `--space-lg` | `gap-4` / `p-4` |
| `--space-xl` | `gap-6` / `p-6` |

### 18.3. Profile-Specific Spacing Rules

- Spacing between a card border and its content is `--space-md` (12px).
- Spacing between cards in a list is `--space-sm` (8px).
- Page-level containers use `--space-xl` (24px).

### 18.4. Responsive Spacing Pattern

Terminal-archetype cards follow a unified responsive margin pattern:

```tsx
// Outer margin: responsive
<div className="m-3 sm:m-4 md:m-6">

// Inner padding: responsive
<div className="p-3 sm:p-4">
```

This is the only spacing pattern that uses responsive breakpoints. All other spacing values are static tokens. Other Profiles may define different responsive patterns appropriate to their design language.

---

## 19. [PROFILE P6] Card Archetypes

> **Moved to sub-companion file** `DESIGN-001-profile-cards.md` in v3.1.1
> (W11 soft-cap cleanup). The full card archetype catalog — Terminal Card,
> Content Card, Stat Card, KPI Card, Chart Card — with code examples and
> wrapper component requirements lives there. Section number preserved
> verbatim.

**Quick summary** (full catalog in sub-companion):

- **Terminal Card** (§19.1): `border-dashed`, `TerminalFrame` wrapper, `font-mono` chrome. For command output, prompts, dashboard stats.
- **Content Card** (§19.2): `solid` border, `Card` wrapper, `font-sans`. For prose, descriptions, explanatory text.
- **Stat Card** (§19.3): Compact numeric display with label + value + delta indicator. Uses `text-accent-primary` for positive deltas.
- **KPI Card** (§19.4): Stat Card + sparkline / trend visualization. Combines numeric + graphical elements.
- **Chart Card** (§19.5): Wrapper for chart libraries (Recharts, etc.). Provides consistent frame + legend area.

Each archetype has: border style, wrapper component, background, content type, typography rules, and a code example showing the recommended usage pattern.

## 20. [PROFILE P7] Component Token Map

This map is specific to the Terminal Dashboard layout (sidebar + header + footer + views). A different project will have a different component structure and a different token map. The requirement is that every major UI block is mapped; the specific blocks and elements are Profile-specific.

### 20.1. Shell Components

| Block | Element | Typography Token | Color Token | Card Style |
|-------|---------|-----------------|-------------|------------|
| Sidebar | Brand title | `--text-h3` | `foreground` | -- |
| Sidebar | Brand label | `--text-badge` | `--neuro-brand` | -- |
| Sidebar | Nav item label | `--text-label` | `muted-foreground` | -- |
| Sidebar | Active arrow `>` | `--text-badge` | `--terminal-accent` | -- |
| Sidebar | Count badge | `--text-badge` | `muted-foreground` | -- |
| Header | Breadcrumb path | `--text-label` | `foreground` | -- |
| Header | App name + `$` prompt | `--text-label` | `--terminal-accent` | -- |
| Header | Semantic button | -- | `--semantic-violet` | -- |
| Header | Search border (active) | -- | `--semantic-violet / 50%` | -- |
| Footer | Prompt `//>` | `--text-label` | `--terminal-accent` | -- |
| Footer | App name | `--text-label` | `foreground` | -- |
| Footer | Version | `--text-badge` | `muted-foreground` | -- |
| Footer | Brand divider | -- | `--neuro-brand` | -- |

### 20.2. View Components

| Block | Element | Typography Token | Color Token | Card Style |
|-------|---------|-----------------|-------------|------------|
| Dashboard | Stat value | `--text-code` (mono, tabular) | `foreground` | Terminal |
| Dashboard | Stat label | `--text-badge` | `muted-foreground` | Terminal |
| Dashboard | Prompt `$` | `--text-label` | `--terminal-accent` | Terminal |
| Dashboard | Section header | `--text-section` | `muted-foreground` | Terminal |
| Dashboard | Doc title | `--text-h3` | `foreground` | Terminal |
| Dictionary | Term name | `--text-h3` | `foreground` | Content |
| Dictionary | Translation | `--text-body` | `muted-foreground` | Content |
| Dictionary | Explanation | `--text-body-sm` | `muted-foreground / 70%` | Content |
| Dictionary | Category badge | `--text-badge` | `category.color` | Content |
| Documents | Doc title | `--text-h3` | `foreground` | Terminal |
| Documents | Star icon | -- | `--star-color` | Terminal |
| Documents | Date | `--text-badge` | `muted-foreground / 60%` | Terminal |
| Documents | Category badge | `--text-badge` | `category.color` | Terminal |
| Doc Viewer | Prose headings | `--text-h1` / `--text-h2` / `--text-h3` | `foreground` | Content |
| Doc Viewer | Prose body | `--text-body` | `foreground` | Content |
| Doc Viewer | Code blocks | `--text-code` | `syntax-*` tokens | Terminal |
| Doc Viewer | Blockquote | `--text-body` | `muted-foreground` | Content |
| Notes | Note title | `--text-h3` | `foreground` | Terminal |
| Notes | Note preview | `--text-body-sm` | `muted-foreground` | Terminal |
| Notes | AI badge | `--text-badge` | `--semantic-violet` | Terminal |
| Notes | Prompt `$` | `--text-label` | `--terminal-accent` | Terminal |
| Instructions | Search input | `--text-label` | `muted-foreground` | Terminal |
| Instructions | Prompt `$` | `--text-label` | `--terminal-accent` | Terminal |
| Instructions | Step title | `--text-h3` | `foreground` | Terminal |
| Instructions | Step description | `--text-body` | step-type accent | Terminal |
| Upload | Drop zone title | `--text-h2` | `foreground` | Terminal |
| Upload | Drop zone description | `--text-body` | `muted-foreground` | Terminal |
| Upload | Status label | `--text-label` | `--terminal-accent` | Terminal |

### 20.3. Token Map Usage Example

```tsx
// Sidebar > Nav item label: --text-label, muted-foreground
<nav>
  <a className="text-[11px] font-mono text-muted-foreground">
    Documents
  </a>
</nav>

// Sidebar > Active arrow: --text-badge, --terminal-accent (Pattern A)
<span className="text-badge font-mono text-accent-primary">
  &gt;
</span>
```

---

## 21. [PROFILE P8] Prohibited Patterns

The patterns below are specific to this Profile (Terminal Dashboard). Each Profile must list its own prohibited patterns based on its token choices and design language. The structure of the table (Pattern / Violation / Replacement) is reusable; the content is not.

### 21.1. Hardcoded Colors

| Pattern | Violation | Replacement (Pattern A: Theme Extension) |
|---------|-----------|------------------------------------------|
| `text-green-600 dark:text-green-400` | Color pair instead of token | `text-accent-primary` |
| `text-amber-500 fill-amber-500` | No dark variant, hardcoded | `text-star fill-star` |
| `bg-violet-600` | Hardcoded violet | `bg-semantic-search` |
| `text-red-500` | Hardcoded red | `text-destructive` |
| `text-[#FA3913]` | Hardcoded hex | `text-brand` |
| `bg-zinc-900 text-zinc-400` | Theme-inflexible | `--muted-alpha` (60% variant) + semantic tokens |
| `#f5f5f4` / `#292524` in prose pre | Hardcoded pre background | `bg-muted` / `border-border` |

### 21.2. Arbitrary Typography

| Pattern | Violation | Replacement |
|---------|-----------|-------------|
| `text-[9px]` | Below scale minimum | `--text-badge` (10px) |
| `font-mono font-bold` on heading | Mono heading | `font-sans` via `--text-h1/h2/h3` |
| `text-xs sm:text-sm` | Inconsistent responsive sizing | Choose one token |
| Heading without `font-sans` | Browser default serif | Explicit `font-sans` |

### 21.3. Card Style Violations

| Pattern | Violation | Replacement |
|---------|-----------|-------------|
| `border-dashed` on prose card | Terminal style on Content card | `solid` border + Content Card |
| `border-solid` on terminal card | Content style on Terminal card | `border-dashed` + Terminal Card |
| Heavy border on stat card | Over-styled stat | `--muted-alpha` minimal |

---

## 22. [PROFILE P9] CSS Custom Properties Summary

Complete copy-paste reference. Add to the project's global stylesheet.

```css
/*
 * DESIGN SYSTEM TOKENS
 * Profile: Terminal Dashboard (PROFILE-TERMINAL-001)
 * Add to project's global stylesheet.
 * Framework-specific class mappings are in Section 15.2 and Section 18.2 (if applicable).
 */
:root {
  /* Typography: size/weight/family values are in Section 15.1; framework class mappings in Section 15.2 (if applicable) */

  /* Semantic Color Tokens (Section 16) */
  --terminal-accent: oklch(0.65 0.2 145);
  --neuro-brand: #FA3913;
  --star-color: oklch(0.78 0.16 75);
  --semantic-violet: oklch(0.55 0.25 295);
  --accent-red: #dc2626;

  /* Accent Aliases (Section 16.2) */
  --accent-green: var(--terminal-accent);
  --accent-amber: var(--star-color);
  --accent-violet: var(--semantic-violet);

  /* Surface Alpha Tokens (Section 19.3) */
  --muted-alpha: color-mix(in oklch, var(--muted) 50%, transparent);

  /* Syntax Highlighting (Section 17) */
  --syntax-comment: #6b7280;
  --syntax-keyword: #16a34a;
  --syntax-string: #b45309;
  --syntax-function: #7c3aed;
  --syntax-path: #0891b2;
  --syntax-flag: #2563eb;
  --syntax-number: #c2410c;
  --syntax-env: #0d9488;

  /* Spacing: pixel values are in Section 18.1; framework class mappings in Section 18.2 (if applicable) */
}

.dark {
  --terminal-accent: oklch(0.75 0.18 145);
  --semantic-violet: oklch(0.65 0.22 295);
  --accent-red: #f87171;

  --syntax-comment: #78716c;
  --syntax-keyword: #4ade80;
  --syntax-string: #fbbf24;
  --syntax-function: #c084fc;
  --syntax-path: #22d3ee;
  --syntax-flag: #60a5fa;
  --syntax-number: #fb923c;
  --syntax-env: #2dd4bf;
}
```

---

## 23. [PROFILE P10] Enforcement: ESLint Rule (Example)

The prohibited patterns below are specific to this Profile (Terminal Dashboard). Each Profile must define its own set of prohibited patterns based on its token choices. The structure of the rule is reusable; the pattern list is not.

```javascript
// eslint-rules/design-tokens.js
module.exports = {
  meta: {
    type: 'problem',
    docs: { description: 'Enforce design system token usage' }
  },
  create(context) {
    const prohibitedColorPatterns = [
      /text-green-\d+/,
      /text-amber-\d+/,
      /text-violet-\d+/,
      /text-red-\d+(?!\s)/,
      /bg-violet-\d+/,
      /border-violet-\d+/
    ];

    const prohibitedHexInJsx = /#[0-9a-fA-F]{3,8}/;

    return {
      JSXAttribute(node) {
        if (node.name?.name !== 'className') return;
        const value = node.value?.value || '';
        for (const pattern of prohibitedColorPatterns) {
          if (pattern.test(value)) {
            context.report({
              node,
              message: 'Hardcoded Tailwind color detected. '
                + 'Use a semantic token instead (see DESIGN_SYSTEM_STANDARD).'
            });
          }
        }
      },
      StringLiteral(node) {
        if (prohibitedHexInJsx.test(node.value)) {
          context.report({
            node,
            message: 'Hardcoded hex color detected. '
              + 'Use a CSS custom property instead.'
          });
        }
      }
    };
  }
};
```

### CI Pipeline Integration

```yaml
# .github/workflows/design-lint.yml
name: Design System Lint
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm install eslint-plugin-markdown
      - run: npx eslint --rule 'design-tokens: error' 'src/**/*.{tsx,jsx}'
      - run: npx eslint --plugin markdown '**/*.md' --rule 'no-irregular-whitespace: error'
```

---

## 24. [PROFILE P11] Agent Context

Compressed design system context derived from this Profile for use in AI agent system prompts.

```markdown
# Design System Context (for AI agent)

## Typography
--text-h1: 24px Bold font-sans
--text-h2: 18px Bold font-sans
--text-h3: 14px Semibold font-sans
--text-body: 14px Regular font-sans
--text-body-sm: 12px Regular font-sans
--text-label: 11px Regular font-mono
--text-badge: 10px Regular font-mono
--text-section: 10px Regular font-mono Uppercase tracking-wider
--text-code: 13px Regular font-mono
--text-code-label: 11px Medium font-mono

## Colors
--terminal-accent: oklch(0.65 0.2 145) / dark: oklch(0.75 0.18 145)
--neuro-brand: #FA3913 (same both themes)
--star-color: oklch(0.78 0.16 75) / dark: auto
--semantic-violet: oklch(0.55 0.25 295) / dark: oklch(0.65 0.22 295)
--accent-red: #dc2626 / dark: #f87171
--accent-green = var(--terminal-accent)
--accent-amber = var(--star-color)
--accent-violet = var(--semantic-violet)
--syntax-comment: #6b7280 / dark: #78716c
--syntax-keyword: #16a34a / dark: #4ade80
--syntax-string: #b45309 / dark: #fbbf24
--syntax-function: #7c3aed / dark: #c084fc
--syntax-path: #0891b2 / dark: #22d3ee
--syntax-flag: #2563eb / dark: #60a5fa
--syntax-number: #c2410c / dark: #fb923c
--syntax-env: #0d9488 / dark: #2dd4bf

## Spacing
--space-xs: 6px | --space-sm: 8px | --space-md: 12px | --space-lg: 16px | --space-xl: 24px

## Rules
- All colors via CSS custom properties; never hardcoded hex or Tailwind color classes (text-green-*, bg-violet-*, etc.)
- Headings (h1-h3): font-sans ONLY, never font-mono
- font-mono is for: labels, badges, prompts, code, metadata, terminal chrome
- Every gap/padding/margin must use spacing scale tokens; no arbitrary values
- Icons: SVG only (from project icon library); never emoji or Unicode symbols
- Cards: Terminal=border-dashed+TerminalFrame | Content=border-solid+Card | Stat=--muted-alpha
- Syntax highlighting: use --syntax-* tokens, never hardcoded colors
- No text-X dark:text-Y pairs; use semantic tokens with auto light/dark
```

**Compressed variant (short-code mapping):**

When the full context above exceeds the character limit for larger Profiles, token names may be shortened using a mapping table. The agent reads the map first, then resolves short codes throughout the rest of the context. This typically reduces size by 30-40%.

```markdown
# Design System Context (compressed)
## Map
ta=terminal-accent | nb=neuro-brand | sc=star-color | sv=semantic-violet
ar=accent-red | ag=accent-green | ab=accent-amber | av=accent-violet
sx=syntax | h1-h3=text-h1..h3 | bd=text-body | bs=text-body-sm
lb=text-label | bg=text-badge | sn=text-section | cd=text-code | cl=text-code-label
ma=muted-alpha

## Typography
h1:24px B sans|h2:18px B sans|h3:14px Sb sans|bd:14px R sans|bs:12px R sans
lb:11px R mono|bg:10px R mono|sn:10px R mono UC tw|cd:13px R mono|cl:11px M mono

## Colors
ta:oklch(.65 .2 145)/d:oklch(.75 .18 145) | nb:#FA3913 | sc:oklch(.78 .16 75)/d:auto
sv:oklch(.55 .25 295)/d:oklch(.65 .22 295) | ar:#dc2626/d:#f87171 | ma:color-mix
ag=ta|ab=sc|av=sv
sx-cmt:#6b7280/d:#78716c|sx-kw:#16a34a/d:#4ade80|sx-str:#b45309/d:#fbbf24
sx-fn:#7c3aed/d:#c084fc|sx-pth:#0891b2/d:#22d3ee|sx-fl:#2563eb/d:#60a5fa
sx-num:#c2410c/d:#fb923c|sx-env:#0d9488/d:#2dd4bf

## Spacing
xs:6|sm:8|md:12|lg:16|xl:24

## Rules
- Colors: CSS vars only; no hex/Tailwind colors in code
- Headings: sans ONLY; mono for labels/badges/prompts/code
- Spacing: tokens only; no arbitrary values
- Icons: SVG only; no emoji/Unicode
- Cards: Terminal=dashed+Frame | Content=solid+Card | Stat=ma
- Syntax: sx-* tokens; no hardcoded colors
```

The generation script (Section 11.5) may output either format. The compressed format is recommended when the full format exceeds 3000 characters.

---

## 25. [PROFILE P12] Animation Tokens

Projects that use CSS transitions, JavaScript-driven animations, spring physics, or keyframe animations must define animation tokens to ensure timing and easing consistency across the interface. Hardcoded `transition-duration`, `animation-duration`, or `cubic-bezier()` values in component code are prohibited at level [W] (level [C] for Interactive/Canvas archetype components).

### 25.1. Duration Tokens

| Token | Milliseconds | Usage |
|-------|-------------|-------|
| `--duration-instant` | 100ms | Micro-interactions: button press, toggle, checkbox |
| `--duration-fast` | 150ms | Hover effects, focus rings, tooltip appear |
| `--duration-normal` | 250ms | Panel expand/collapse, dropdown open, tab switch |
| `--duration-slow` | 400ms | Page transitions, modal open/close, drawer slide |
| `--duration-slower` | 600ms | Complex morphing, multi-step reveals |

### 25.2. Easing Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `--easing-default` | `cubic-bezier(0.4, 0, 0.2, 1)` | Most transitions (standard ease-out) |
| `--easing-in` | `cubic-bezier(0.4, 0, 1, 1)` | Elements leaving the viewport (collapse, dismiss) |
| `--easing-out` | `cubic-bezier(0, 0, 0.2, 1)` | Elements entering the viewport (expand, appear) |
| `--easing-spring` | `cubic-bezier(0.175, 0.885, 0.32, 1.275)` | Playful overshoot (bouncing badge, spring toggle) |
| `--easing-linear` | `linear` | Progress bars, continuous rotation, loading spinners |

### 25.3. Usage Rules

- Every CSS `transition` property must reference `--duration-*` and `--easing-*` tokens, not hardcoded values
- Every JavaScript animation (Framer Motion, React Spring, GSAP) must use values derived from these tokens, not arbitrary numbers
- The `tokens/` layer must export these values as JavaScript constants for use in JS animation libraries:

```typescript
// tokens/animations.ts
export const duration = {
  instant: 100,
  fast: 150,
  normal: 250,
  slow: 400,
  slower: 600,
} as const

export const easing = {
  default: [0.4, 0, 0.2, 1] as const,
  in: [0.4, 0, 1, 1] as const,
  out: [0, 0, 0.2, 1] as const,
  spring: [0.175, 0.885, 0.32, 1.275] as const,
} as const
```

This dual registration (CSS custom properties for CSS transitions, JS constants for JS animations) is the recommended pattern. It satisfies the single source of truth principle: the canonical values live in `tokens/animations.ts`, and the CSS custom properties in `:root` are derived from the same source.

### 25.4. Profile-Specific Rules

- A Profile may adjust duration values (e.g., 2x slower for accessibility-focused products, 2x faster for power-user tools)
- A Profile must document any deviation from the default values
- Interactive/Canvas archetype components must use these tokens at level [C]; other components at level [W]

---

## 26. [PROFILE P13] Breakpoint Tokens

Projects that implement responsive layouts must define breakpoint tokens to ensure viewport boundary consistency across the codebase. Hardcoded pixel values in `@media` queries or JavaScript `matchMedia` calls are prohibited at level [W].

### 26.1. Breakpoint Definitions

| Token | Pixels | Target |
|-------|--------|--------|
| `--bp-xs` | 480px | Mobile (portrait) |
| `--bp-sm` | 640px | Mobile (landscape) / small tablet |
| `--bp-md` | 768px | Tablet |
| `--bp-lg` | 1024px | Small desktop / large tablet |
| `--bp-xl` | 1280px | Desktop |
| `--bp-2xl` | 1536px | Large desktop |

### 26.2. Usage Rules

**CSS media queries:** CSS custom properties cannot be used directly in `@media` query conditions (this is a CSS specification limitation). Instead, breakpoints are defined as JavaScript constants and used via one of these approaches:

```typescript
// tokens/breakpoints.ts
export const breakpoints = {
  xs: 480,
  sm: 640,
  md: 768,
  lg: 1024,
  xl: 1280,
  '2xl': 1536,
} as const
```

**Approach 1 -- Utility-first framework (Pattern A):** Register breakpoints in the framework configuration. Tailwind and UnoCSS use these values in `screens`/`breakpoints` config, enabling responsive prefixes (`sm:`, `md:`, `lg:`) that match the design system breakpoints.

```css
/* tailwind.config.ts or uno.config.ts */
export default {
  theme: {
    screens: {
      xs: '480px',
      sm: '640px',
      md: '768px',
      lg: '1024px',
      xl: '1280px',
      '2xl': '1536px',
    }
  }
}
```

**Approach 2 -- CSS preprocessor (Pattern B/C):** Use SASS/SCSS variables or PostCSS custom media to keep breakpoint values in sync:

```scss
// _breakpoints.scss
$bp-xs: 480px;
$bp-sm: 640px;
$bp-md: 768px;
$bp-lg: 1024px;
$bp-xl: 1280px;
$bp-2xl: 1536px;

@mixin md-up {
  @media (min-width: $bp-md) { @content; }
}
```

**Approach 3 -- JavaScript (React hooks):** Use the breakpoint constants with `matchMedia` or a responsive hook:

```typescript
import { breakpoints } from '@/tokens/breakpoints'

function useIsDesktop() {
  const [isDesktop, setIsDesktop] = useState(false)
  useEffect(() => {
    const mq = window.matchMedia(`(min-width: ${breakpoints.lg}px)`)
    setIsDesktop(mq.matches)
    const handler = (e: MediaQueryListEvent) => setIsDesktop(e.matches)
    mq.addEventListener('change', handler)
    return () => mq.removeEventListener('change', handler)
  }, [])
  return isDesktop
}
```

### 26.3. Profile-Specific Rules

- A Profile may add or remove breakpoints to match its target devices
- A Profile must document which breakpoints it uses and which responsive strategy (mobile-first or desktop-first) it follows
- The default approach is mobile-first (`min-width` queries)

---

## 26A. Known Issues and Proposed Solutions

This section documents discovered inconsistencies and proposed corrections
specific to this companion file. Issues that pertain to the parent
standard (STD-DESIGN-001) are tracked in DESIGN-001-design-system.md §26A
(DES-001 through DES-006).

### TDP-001 `[OPEN]` — Per-section "illustrative" disclaimer not yet added

**Problem:** STD-DESIGN-001 DES-005 (OPEN) calls for a one-line note at
the top of each P1-P11 section clarifying that the values shown are
illustrative. The companion file's header now states "Status:
ILLUSTRATIVE EXAMPLE" at the file level (DES-005 update in v3.1.0), but
per-section disclaimers inside §14-§24 are still missing. A reader who
lands directly on §16 (Color Tokens) via a deep link may still mistake
the specific token names for Core requirements.

**Proposed solution:** Add a one-line italic note at the top of each
section §14 through §24: *"Illustrative example from the Terminal
Dashboard Profile. Substitute your project's values."*. Bulk edit in a
future minor version (v3.1.1 or v3.2.0).

### TDP-002 `[OPEN]` — File exceeds 1000-line soft cap (W11 soft warning)

**Problem:** This companion file is 1047 lines, exceeding the 1000-line
soft cap defined in `verify-id-graph.js` W11. It is under the 1500-line
hard cap, so this is a SOFT warning (not CRITICAL), but it does appear
in the W11 warning list.

**Proposed solution:** If the soft warning becomes noisy, two options:
(a) split this companion file further — e.g., extract §19 (Card
Archetypes, ~169 lines) into a second companion file
`DESIGN-001-cards-reference.md`; or (b) accept the soft warning as the
cost of keeping all Profile content in one browsable file. Lean towards
(b) until the file grows past 1200 lines, at which point option (a)
becomes warranted. Track via line-count monitoring.

### TDP-003 `[OPEN]` — Version History not maintained in this companion file

**Problem:** STD-DESIGN-001 §27 (Version History) tracks changes to the
main standard but does not track changes specific to this companion
file. As the companion file evolves independently (e.g., when TDP-001
and TDP-002 are resolved), there is no record of when those changes
landed.

**Proposed solution:** Add a "## 27. Version History (companion file)"
section at the end of this file, starting with v3.1.0 (2026-06-18):
"Initial creation — content moved from DESIGN-001-design-system.md v3.0.1
§14-§26. No content changes; only file location changed." Subsequent
companion-only changes (TDP-001, TDP-002 resolutions) would get their
own rows. Track as low-priority cleanup.

---

*End of DESIGN-001 Profile: Terminal Dashboard (EXAMPLE) — companion to STD-DESIGN-001 v3.1.0. Content moved here from DESIGN-001-design-system.md in v3.1.0 to bring the main standard under the 1500-line hard cap. Section numbering preserved for cross-reference stability.*
