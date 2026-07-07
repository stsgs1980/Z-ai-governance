---
name: zai-phi-layout
version: 3.0
compatibility: both
description: "Proportional CSS Grid layouts using phi and Fibonacci spacing. Use when users want bento layouts, masonry grids, asymmetric grids, timeline layouts, staggered layouts, Linear/Vercel-style zeitgeist pages, harmonious page compositions, nature-inspired proportions, or any layout beyond standard symmetric grids. Triggers: bento grid, bento layout, bento box, masonry, masonry grid, timeline layout, asymmetric grid, asymmetric layout, staggered layout, Linear-style, Vercel-style, zeitgeist, harmonious layout, nature-inspired grid, organic grid, proportional layout, Fibonacci, Fibonacci layout, Fibonacci spacing, phi grid, phi layout, golden ratio, divine proportion, sacred geometry, modular scale grid, neutral palette, dark mode grid, accessible grid, container query grid."
id: ZAI-ARCH-003
author: StsDev
trigger: phi layout, golden ratio, Fibonacci, bento, masonry, zeitgeist, asymmetric, timeline, sacred geometry, golden grid, Linear-style, Vercel-style, container query
related:
  - STD-SKILL-001
  - STD-FE-001
  - STD-DESIGN-001
---

# Skill: Zai Phi Layout v3.0

> ID: ZAI-ARCH-003
> Version: 3.0
> Last Updated: 2026-05

Phi Layout builds proportional CSS Grid compositions using phi (approximately 1.618) and the Fibonacci sequence. While standard grids default to equal-width columns, this skill creates layouts with deliberate proportional relationships - the same ratios found in nature, architecture, and art. The result is compositions where visual weight is distributed intentionally, guiding the eye along designed focal paths rather than arbitrary divisions.

## Severity Tags

Rules in this skill are tagged with severity levels:

- **[C] Critical** -- Mandatory. Violation is an error. Agent MUST follow this rule.
- **[W] Warning** -- Recommended. Violation triggers a warning. Agent SHOULD follow unless there is a justified reason to deviate.
- **[I] Informational** -- Supplementary. Useful context, not enforced. Agent considers when applicable.

## Priority and Compatibility

When this skill is active alongside other styling skills (ui-ux-pro-max [system skill], visual-design-foundations [system skill]), phi-layout takes priority for:

- **Grid layout structure** (`grid-template-columns`, `grid-template-rows`) -- phi-layout always wins
- **Spacing values** -- Fibonacci scale replaces the 8-point grid when golden proportions are requested
- **Token naming** -- use `--fib-*` and `--phi-*` tokens instead of `--space-*` tokens

Other skills retain priority for:
- **Component styling** (borders, shadows, typography outside the grid system)
- **Color palette** (if the project has an existing chromatic brand palette, use it; phi-layout only provides the neutral subset)
- **Interaction patterns** (hover states, transitions beyond Fibonacci timing)

[C] When phi-layout is invoked, its spacing and grid tokens MUST override conflicting tokens from other skills. Document the override in a comment: `/* phi-layout override: Fib-val 5 replaces default gap */`

## FORBIDDEN

The following practices are explicitly forbidden when using this skill:

- FORBIDDEN: Using fixed pixel widths in `grid-template-columns` when golden proportions are requested. Use `fr` units with `1.618` multipliers instead.
- FORBIDDEN: Equal-width columns (e.g., `repeat(3, 1fr)`) when the user requests golden ratio or Fibonacci proportions. Equal columns contradict the asymmetric balance principle.
- FORBIDDEN: Arbitrary gap values (e.g., `gap: 20px`, `gap: 15px`) when Fibonacci spacing is specified. Use the Fibonacci scale: `0.75rem`, `1.5rem`, `2.5rem`, `4rem`.
- FORBIDDEN: Relying solely on color (neutral tone differences) to convey information. Always pair with text labels, patterns, or icons for accessibility.
- FORBIDDEN: Omitting responsive behavior. Every golden grid must define at least a mobile collapse strategy.
- FORBIDDEN: Using `float` or `flexbox` for primary layout structure when CSS Grid is available and the pattern calls for explicit grid tracks.

## Workflow

When applying this skill, follow this structured workflow:

### Step 1: Identify the Pattern

Analyze the user's request to determine the appropriate layout pattern from the 18 available:

```text
User request                    -> Pattern
---------------------------------------------------------
"two columns, golden ratio"     -> 01 Golden Split
"sidebar + content"             -> 01 or 07 Holy Grail
"dashboard with charts"         -> 12 Dashboard Golden
"bento, card grid"              -> 05 or 06 Bento
"Pinterest-style"               -> 13 Masonry Golden
"timeline, roadmap"             -> 14 Golden Timeline
"Linear/Vercel style"           -> 15 Zeitgeist Grid
"complex mixed content"         -> 16 Masonry Bento
"hero with diagonal emphasis"   -> 17 Golden Triangle
"centered focal point"          -> 18 Sacred Geometry
"magazine, editorial"           -> 11 Magazine Layout
"multi-column data"             -> 02 Fibonacci Columns
"compatible with design system" -> 03 Phi Grid 12-col
"portfolio, spiral"             -> 04 Spiral Grid
"card catalog"                  -> 08 Golden Card Grid
"diagonal visual flow"          -> 09 Diagonal Fibonacci
"nested components"             -> 10 Nested Grids
"news, blog"                    -> 11 Magazine Layout
```

### Step 2: Apply Fibonacci Spacing

Select gaps from the Fibonacci scale:
- `gap: 0.75rem` (12px) -- tight, inside cards
- `gap: 1.5rem` (24px) -- default, standard grid
- `gap: 2.5rem` (40px) -- relaxed, section-level
- `gap: 4rem` (64px) -- loose, major divisions

### Step 3: Build the Grid

1. Define `grid-template-columns` with golden/Fibonacci `fr` values
2. Define `grid-template-rows` if needed (same principle)
3. Place items with `grid-column` and `grid-row` spans
4. Apply Fibonacci gap values

### Step 4: Add Responsive Behavior

- **Desktop (>1024px)**: Full golden proportions
- **Tablet (768-1024px)**: Simplified golden split
- **Mobile (<768px)**: Single column, retain Fibonacci spacing
- [C] Use container queries (`@container`) for component-level responsive. Use media queries for page-level.

### Step 5: Add Dark Mode

Apply dark mode tokens from `references/fibonacci-scale.md`:
- Swap `--color-surface` to `#1a1a1a`
- Invert border depth coding
- [C] Always provide `prefers-color-scheme: dark` overrides when the project supports dark mode.

### Step 6: Verify Accessibility

- Tab order follows visual order (grid source order matches layout)
- Focus rings visible on interactive grid cells
- `prefers-reduced-motion` disables animations
- Color contrast meets WCAG AA (4.5:1 for text)
- Semantic landmarks (`<nav>`, `<main>`, `<aside>`, `<footer>`) used instead of generic `<div>`

### Step 7: Validate Golden Proportions

- Primary content occupies approximately 61.8% of layout area
- Secondary content occupies approximately 38.2%
- Column ratios use `1.618fr` or Fibonacci `fr` values
- Gaps follow Fibonacci spacing scale

## Core Principles

### The Golden Ratio in Layout

The golden ratio divides space so that the ratio of the larger part to the smaller equals the ratio of the whole to the larger. In a 1440px viewport:

- Larger section: `1440 / 1.618 = 890px`
- Smaller section: `1440 - 890 = 550px`
- Verify: `890 / 550 = 1.618`

[C] When creating golden-proportioned columns, use `1fr 1.618fr` (or the inverse) in `grid-template-columns` rather than fixed pixel values. This maintains proportions at every viewport width.

### Fibonacci Spacing Scale

The Fibonacci sequence (0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144) maps directly to pixel/rem values for padding, margins, and gaps. Each Fibonacci VALUE multiplied by the 8px base unit produces the spacing scale. Comments use `Fib-val N` notation to indicate which Fibonacci value is used:

| Fib-val | Calculation | px | rem | Use |
|---------|-------------|-----|-----|-----|
| 3       | 3 x 8       | 24px  | 1.5rem  | Standard grid gap |
| 5       | 5 x 8       | 40px  | 2.5rem  | Section-level gap |
| 8       | 8 x 8       | 64px  | 4rem    | Major layout gap |
| 13      | 13 x 8      | 104px | 6.5rem  | Page area spacing |
| 21      | 21 x 8      | 168px | 10.5rem | Large-scale spacing |
| 34      | 34 x 8      | 272px | 17rem   | Max practical spacing |

[I] The 0.75rem (12px) gap used in tight/bento layouts is a derived step (between 8px and 16px), not a direct Fibonacci value. It is practical but not part of the Fib-val scale.

[W] Use Fibonacci-based gaps (`gap: 1.5rem`, `gap: 2.5rem`, `gap: 4rem`) instead of arbitrary values. This creates consistent visual rhythm.

[I] For very large layouts, Fibonacci values beyond 34 become impractical in pixels. Switch to a modular scale at that point.

## Quick-Start Patterns

### Pattern 01: Golden Split (2-column)

```css
.golden-split {
  display: grid;
  grid-template-columns: 1fr 1.618fr;
  gap: 2.5rem; /* 40px = Fib-val 5 */
  min-height: 100vh;
}
```

Left column is the focal anchor (sidebar, hero text). Right column is the content flow. The eye naturally lands on the larger area first, then the smaller anchor provides contrast.

### Pattern 02: Fibonacci Columns (multi-column)

```css
.fib-columns {
  display: grid;
  grid-template-columns: 1fr 2fr 3fr 5fr;
  gap: 1.5rem; /* 24px = Fib-val 3 */
}
```

Each column follows the Fibonacci ratio. The progressive widening creates a natural reading hierarchy: narrow sidebar, medium aside, wide content.

### Pattern 03: Phi Grid (12-column with golden breakpoints)

```css
.phi-grid {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  gap: 1.5rem;
}

/* Golden cut at column 7/12 (7:5 ratio = 1.4, close to phi) */
.phi-grid .main-content { grid-column: 1 / 8; }
.phi-grid .sidebar { grid-column: 8 / 13; }
```

A 12-column grid lets you approximate the golden ratio at 7:5 columns. The 12-column base remains compatible with standard design systems while embedding golden proportions.

### Pattern 04: Fibonacci Spiral Grid

```css
.spiral-grid {
  display: grid;
  grid-template-columns: 34fr 21fr 13fr 8fr 5fr 3fr 2fr 1fr;
  grid-template-rows: 34fr 21fr 13fr;
  gap: 1.5rem;
}

.spiral-grid .hero {
  grid-column: 1 / 3; /* 34+21 = 55 total */
  grid-row: 1 / 3;    /* 34+21 = 55 total */
}
```

This creates a layout where content blocks shrink according to the Fibonacci spiral, producing a natural visual flow from the dominant hero down to smaller accent elements.

### Pattern 05: Bento Grid (Golden)

Bento Grid borrows from the Japanese lunch box: each compartment has a different size and purpose. Combined with golden proportions, the largest compartment occupies approximately 61.8% of the area while smaller compartments fill the remaining 38.2% in decreasing Fibonacci ratios.

```css
.golden-bento {
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  grid-auto-rows: minmax(120px, auto);
  gap: 1.5rem; /* 24px = Fib-val 3 */
}

/* Hero: 4 of 6 cols = 66.7%, 2 rows */
.golden-bento .hero { grid-column: 1 / 5; grid-row: 1 / 3; }

/* Stats: 2 cols each */
.golden-bento .stat-1 { grid-column: 5 / 7; grid-row: 1; }
.golden-bento .stat-2 { grid-column: 5 / 7; grid-row: 2; }

/* Mid-band: 3 cols */
.golden-bento .mid-band { grid-column: 1 / 4; grid-row: 3; }

/* Accent: 1 col */
.golden-bento .accent { grid-column: 4 / 5; grid-row: 3; }
```

The 6-column bento grid naturally supports golden proportions: 4:2 (2:1), 3:1:2, and 4:1:1 all approximate the 61.8/38.2 split at different scales.

### Pattern 06: Bento Grid (5-column Asymmetric)

```css
.bento-5col {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  grid-auto-rows: minmax(100px, auto);
  gap: 1.5rem;
}

/* 3:2 split -- close to phi (1.5 vs 1.618) */
.bento-5col .main { grid-column: 1 / 4; grid-row: 1 / 3; }
.bento-5col .feature { grid-column: 4 / 6; grid-row: 1; }
.bento-5col .small-a { grid-column: 4 / 5; grid-row: 2; }
.bento-5col .small-b { grid-column: 5 / 6; grid-row: 2; }
```

### Pattern 07: Asymmetric Holy Grail

```css
.holy-grail-golden {
  display: grid;
  grid-template-columns: 3fr 13fr 5fr;  /* Fib proportions */
  grid-template-rows: auto 1fr auto;
  gap: 1.5rem;
  min-height: 100vh;
}

.holy-grail-golden header  { grid-column: 1 / -1; }
.holy-grail-golden nav     { grid-column: 1; grid-row: 2; }
.holy-grail-golden main    { grid-column: 2; grid-row: 2; }
.holy-grail-golden aside   { grid-column: 3; grid-row: 2; }
.holy-grail-golden footer  { grid-column: 1 / -1; }
```

### Pattern 08: Golden Card Grid

```css
.golden-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 2.5rem;
}

.golden-card {
  display: grid;
  grid-template-rows: 1.618fr 1fr;
  gap: 1.5rem;
}
```

### Pattern 09: Diagonal Fibonacci

```css
.diagonal-fib {
  display: grid;
  grid-template-columns: 1fr 2fr 3fr 5fr;
  grid-template-rows: 5fr 3fr 2fr 1fr;
  gap: 1.5rem;
}
```

### Pattern 10: Nested Golden Grids

```css
.outer-golden {
  display: grid;
  grid-template-columns: 1fr 1.618fr;
  gap: 2.5rem;
}

.outer-golden .sidebar {
  display: grid;
  grid-template-rows: 1.618fr 1fr;
  gap: 1.5rem;
}

.outer-golden .content {
  display: grid;
  grid-template-columns: 1fr 2fr 3fr;
  gap: 1.5rem;
}

/* Subgrid variant: child aligns with parent tracks */
.parent-golden {
  display: grid;
  grid-template-columns: 1fr 1.618fr;
  gap: 1.5rem;
}

.nested-card {
  display: grid;
  grid-template-columns: subgrid; /* inherits 1fr and 1.618fr from parent */
  grid-column: span 2;            /* occupies both parent columns */
}
```

[W] Use `subgrid` when child elements must align with parent grid tracks. Use independent nested grids when the child needs its own proportion system. Subgrid browser support: Chrome 117+, Firefox 71+, Safari 16+. Provide a nested grid fallback for older browsers.

### Pattern 11: Magazine Layout

```css
.magazine-layout {
  display: grid;
  grid-template-columns: 5fr 3fr 2fr;  /* Consecutive Fibonacci: 5:3:2 ~ 2.5:1.5:1 ~ golden hierarchy */
  grid-template-rows: 8fr 5fr 3fr;     /* Same Fibonacci sequence for rows: 8:5:3 ~ 2.67:1.67:1 */
  gap: 1.5rem;
}

.magazine-layout .lead-story { grid-column: 1; grid-row: 1 / 3; }
.magazine-layout .feature { grid-column: 2 / 4; grid-row: 1; }
.magazine-layout .side-story { grid-column: 2; grid-row: 2; }
.magazine-layout .quick-read { grid-column: 3; grid-row: 2 / 4; }
.magazine-layout .bottom-row { grid-column: 1 / 3; grid-row: 3; }
```

### Pattern 12: Dashboard Golden

```css
.dashboard-golden {
  display: grid;
  grid-template-columns: 3fr 5fr 2fr;
  grid-template-rows: auto 1fr 1.618fr;
  gap: 1.5rem;
  min-height: 100vh;
}

.dashboard-golden .kpi-bar { grid-column: 1 / -1; grid-row: 1; }
.dashboard-golden .filters { grid-column: 1; grid-row: 2 / 4; }
.dashboard-golden .chart-primary { grid-column: 2 / -1; grid-row: 2; }
.dashboard-golden .data-table { grid-column: 2 / -1; grid-row: 3; }
```

### Pattern 13: Masonry Golden

Pinterest-style variable-height grid where items have Fibonacci-proportioned row spans. Uses `grid-auto-rows` with a 40px unit and `span` values from the Fibonacci sequence (2, 3, 5, 8, 13) to approximate masonry with full CSS Grid support. Visual weight distribution follows the golden ratio: 61.8% compact items, 23.6% features, 14.6% heroes.

```css
.masonry-golden {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  grid-auto-rows: minmax(40px, auto);
  gap: 1.5rem;
}

.masonry-golden .item-xs  { grid-row: span 2; }
.masonry-golden .item-sm  { grid-row: span 3; }
.masonry-golden .item-md  { grid-row: span 5; }
.masonry-golden .item-lg  { grid-row: span 8; }
.masonry-golden .item-xl  { grid-row: span 13; }
```

### Pattern 14: Golden Timeline

Vertical timeline with a center axis at the golden section (38.2% from left). Events alternate left/right with Fibonacci-scaled vertical spacing.

```css
.golden-timeline {
  display: grid;
  grid-template-columns: 3.82fr 1fr 5.18fr;
  gap: 0;
}

.golden-timeline .event-left { grid-column: 1; text-align: right; padding-right: 2.5rem; }
.golden-timeline .event-axis { grid-column: 2; }
.golden-timeline .event-right { grid-column: 3; text-align: left; padding-left: 2.5rem; }
```

[W] In RTL languages, swap left/right alignment and padding directions for timeline events.

### Pattern 15: Zeitgeist Grid

The layout pattern popularized by Linear, Vercel, and Stripe: three-column grid (`1fr 1.618fr 1fr`) where content occupies the golden center column and breath/negative space fills the sides.

```css
.zeitgeist-grid {
  display: grid;
  grid-template-columns: 1fr 1.618fr 1fr;
  gap: 2.5rem;
  max-width: 1440px;
  margin: 0 auto;
}

.zeitgeist-grid .feature { grid-column: 2; }
.zeitgeist-grid .feature-extended { grid-column: 2 / 4; }
.zeitgeist-grid .hero-full { grid-column: 1 / -1; }
```

### Pattern 16: Golden Masonry Bento

The most complex hybrid: masonry variable heights + bento explicit spans + golden proportions.

```css
.masonry-bento {
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  grid-auto-rows: 40px;
  gap: 1.5rem;
}

.masonry-bento .hero { grid-column: 1 / 5; grid-row: span 8; }
.masonry-bento .stat-tall { grid-column: 5 / 7; grid-row: span 5; }
.masonry-bento .stat-short { grid-column: 5 / 7; grid-row: span 3; }
.masonry-bento .band-medium { grid-column: 1 / 4; grid-row: span 5; }
.masonry-bento .accent { grid-column: 4 / 5; grid-row: span 3; }
```

### Pattern 17: Golden Triangle

Diagonal compositional layout where sides form golden proportions. Creates dramatic diagonal visual weight.

```css
.golden-triangle {
  display: grid;
  grid-template-columns: 1.618fr 1fr;
  grid-template-rows: 1.618fr 1fr;
  gap: 1.5rem;
}

.golden-triangle .dominant { grid-column: 1 / -1; grid-row: 1; }
.golden-triangle .support-a { grid-column: 1; grid-row: 2; }
.golden-triangle .support-b { grid-column: 2; grid-row: 2; }
```

### Pattern 18: Sacred Geometry

Three-zone layout where the center zone is the golden rectangle, flanked by breath zones. The center carries 61.8% of both width and height.

```css
.sacred-grid {
  display: grid;
  grid-template-columns: 1fr 1.618fr 1fr;
  grid-template-rows: 1fr 1.618fr 1fr;
  gap: 1.5rem;
}

.sacred-grid .center { grid-column: 2; grid-row: 2; }
```

## 18 Patterns Summary

| # | Pattern | Key CSS | Best For |
|---|---------|---------|----------|
| 01 | Golden Split | `1fr 1.618fr` | Landing pages, editorials |
| 02 | Fibonacci Columns | `1fr 2fr 3fr 5fr` | Dashboards, comparisons |
| 03 | Phi Grid 12-col | 7:5 golden cut | Design systems, CMS |
| 04 | Spiral Grid | `34fr 21fr 13fr 8fr` | Portfolios, magazines |
| 05 | Bento 6-col | hero 4:2 | SaaS, product pages |
| 06 | Bento 5-col | 3:2 asymmetric | App features, teams |
| 07 | Asymmetric Holy Grail | `3fr 13fr 5fr` | Docs, web apps |
| 08 | Golden Card Grid | `1.618fr 1fr` cards | Catalogs, blogs |
| 09 | Diagonal Fibonacci | cols grow, rows shrink | Creative, storytelling |
| 10 | Nested Golden Grids | recursive `display:grid` | Complex dashboards |
| 11 | Magazine Layout | `5fr 3fr 2fr` | News, editorial |
| 12 | Dashboard Golden | `3fr 5fr 2fr` + KPI | Analytics, admin |
| 13 | Masonry Golden | Fib row spans | Galleries, feeds |
| 14 | Golden Timeline | 38.2% axis | Roadmaps, changelog |
| 15 | Zeitgeist Grid | `1fr 1.618fr 1fr` | SaaS marketing, premium |
| 16 | Golden Masonry Bento | masonry + bento + phi | Mixed-content dashboards |
| 17 | Golden Triangle | `1.618fr 1fr` diagonal | Compositional accents |
| 18 | Sacred Geometry | `1fr 1.618fr 1fr` center | Focal-point layouts |

## Reference Files

For detailed implementations, read the reference files:

- `references/fibonacci-scale.md` -- Complete Fibonacci spacing/sizing system, design tokens, neutral palette, dark mode tokens, accessibility tokens, container query tokens
- `references/grid-patterns.md` -- Full CSS for all 18 grid patterns with responsive variants and dark mode
- `references/golden-ratio-layouts.md` -- Layout composition theory, visual weight distribution, nesting rules, animation patterns, subgrid integration
- `references/react-components.md` -- INDEX file (6 sub-files: split-column, bento, grid, tailwind, server, dark-mode). Load on demand.

## Skill Relationships

**Closest ally:** `visual-design-foundations` (system skill)
- `visual-design-foundations` = layout theory, visual hierarchy, color theory
- `phi-layout` = precise proportional grid implementation using phi/Fibonacci
- Use together: `visual-design-foundations` determines WHAT and WHY, `phi-layout` determines HOW by phi

**Compatible with:** `$fullstack-dev`
- No overlap -- `fullstack-dev` handles app architecture, routing, data
- `phi-layout` handles visual grid layout
- Use together naturally, no conflicts

**Overlap zone with:** `$frontend-styling-expert`
- BOTH define spacing scales and grid patterns -> potential conflict
- Resolution: when phi-layout is active, `--fib-*` tokens override `--spacing-*` tokens
- When phi-layout is NOT active, `frontend-styling-expert` is the default
- Critical override comment required: `/* phi-layout override: Fib-val N replaces default spacing */`

**Priority rule:**
1. When user explicitly requests golden ratio / Fibonacci / phi / bento / masonry / asymmetric / timeline -> phi-layout wins
2. When user asks for general layout -> visual-design-foundations wins
3. When user asks CSS technique questions -> frontend-styling-expert wins
4. `fullstack-dev` never conflicts -- different domain entirely

## Communication style

This skill communicates in a professional, design-oriented style:
- No emoji or Unicode graphics in responses
- Use text tags for status: [OK], [FAIL], [TODO], [WARNING]
- Use ASCII diagrams for layout flows: ->, |, +, v, ^
- If you must reference a Unicode character as the object of description, mark it with (ref)
