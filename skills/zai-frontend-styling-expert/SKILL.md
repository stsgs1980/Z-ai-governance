---
name: zai-frontend-styling-expert
version: 1.0
compatibility: both
description: "CSS, styling, responsive design, accessibility, and UI/UX polish specialist. Use this skill when you need help with CSS, styling frameworks, responsive design, UI/UX implementation, animations, layout systems, or any visual/presentational aspects of web development. Examples: responsive navigation menus, button hover effects, centering layouts, accessibility improvements, cross-browser fixes, mobile optimization, Tailwind CSS utilities, CSS Grid and Flexbox layouts, animation choreography, design system implementation, visual polish, dark mode theming. Make sure to use this skill whenever the user mentions CSS, styling, responsive, accessibility, animation, hover effects, layout, positioning, spacing, typography rendering, or wants to improve the visual quality of any web element."
id: ZAI-DEV-003
author: StsDev
trigger: CSS, styling, responsive, accessibility, animation, hover effects, layout, centering, dark mode, Tailwind, Flexbox, Grid, mobile, polish UI, fix layout
license: MIT
related:
  - STD-SKILL-001
  - STD-FE-001
  - STD-DESIGN-001
  - STD-A11Y-001
---

# Skill: Zai Frontend Styling Expert v1.0

> ID: ZAI-DEV-003
> Version: 1.0
> Last Updated: 2026-05

This skill is a dedicated specialist for every visual and presentational aspect of frontend development. It transforms rough layouts into polished, accessible, responsive interfaces through deep CSS expertise, systematic design patterns, and rigorous accessibility compliance.

---

## When to Use This Skill (Trigger Patterns)

**MUST apply this skill when:**

- User asks about CSS properties, selectors, specificity, or layout
- User needs responsive design adjustments or mobile optimization
- User wants to implement or fix animations and transitions
- User mentions accessibility (WCAG, ARIA, keyboard navigation, screen readers)
- User needs help with CSS Grid, Flexbox, or positioning systems
- User wants to polish UI elements (hover effects, focus states, shadows)
- User is working with Tailwind CSS, CSS Modules, SCSS, or other styling tools
- User needs dark mode / theme implementation
- User wants to fix cross-browser rendering issues
- User mentions visual bugs: overflow, alignment, spacing, z-index stacking

**Trigger phrases:**
- "make this responsive"
- "fix the layout"
- "add hover effects"
- "center this element"
- "improve accessibility"
- "polish the UI"
- "dark mode"
- "animation not working"
- "mobile layout broken"
- "CSS Grid / Flexbox"

**DO NOT use for:**
- Backend logic or API development - use **fullstack-dev** instead
- Database schemas or server configuration - use **fullstack-dev** instead
- Full application architecture - use **fullstack-dev** instead
- Creative design direction (choosing aesthetic, building token system) - use **visual-design-foundations** (system skill) instead

---

## Companion Skills

This skill handles CSS polish, responsive design, accessibility, and visual refinement. For other layers, delegate to:

| Companion Skill | When to Use | What It Covers |
|----------------|-------------|----------------|
| **fullstack-dev** | When the project needs backend, database, API routes, or full app scaffolding | Next.js 16 architecture, Prisma schemas, API routes, WebSocket, authentication, deployment |
| **visual-design-foundations** | When starting from scratch and needing a visual direction and design token system | Design tokens, aesthetic direction, typography choices, color palettes, layout composition, creative execution |

**Typical combinations:**
- **Full project**: Use `fullstack-dev` for architecture -> `visual-design-foundations` for visual system -> `frontend-styling-expert` for polish
- **Landing page / portfolio**: Use `visual-design-foundations` for creative direction -> `frontend-styling-expert` for responsive + accessibility
- **CSS fix / responsive tweak**: Use `frontend-styling-expert` alone (no companion needed)
- **CRUD admin panel**: Use `fullstack-dev` for schema/API -> `frontend-styling-expert` for layout and accessibility

---

## Core Expertise Areas

### 1. CSS Layout Systems

**Flexbox Mastery:**
- One-dimensional layouts (row/column flow)
- Alignment: `justify-content`, `align-items`, `align-self`, `gap`
- Flex grow/shrink/basis for proportional sizing
- `flex-wrap` for responsive wrapping
- Order and visual reordering

**CSS Grid Mastery:**
- Two-dimensional layouts with `grid-template-columns` / `grid-template-rows`
- Named grid areas for semantic layout definition
- `minmax()`, `auto-fill`, `auto-fit` for responsive grids
- Grid gap, alignment, and placement
- Subgrid for nested alignment

**Positioning:**
- Relative/Absolute for overlays and tooltips
- Fixed for persistent UI (headers, FABs)
- Sticky for scroll-aware elements
- Stacking context and z-index management

### 2. Responsive Design

**Mobile-First Strategy [W]:**
```text
Base styles -> Mobile (375px)
sm: -> Small tablets (640px)
md: -> Tablets (768px)
lg: -> Desktops (1024px)
xl: -> Large screens (1280px)
2xl: -> Ultra-wide (1536px)
```

**Critical Responsive Patterns:**
- Navigation: hamburger menu on mobile, horizontal on desktop
- Cards: single column -> 2 columns -> 3+ columns
- Typography: fluid sizing with `clamp()`
- Images: `srcset`, `sizes`, `object-fit`
- Touch targets: minimum 44x44px on mobile
- Safe areas: `env(safe-area-inset-*)` for notched devices
- Container queries: `@container` for component-level responsiveness

**Fluid Typography:**
```css
:root {
  --font-sm: clamp(0.875rem, 0.8rem + 0.2vw, 1rem);
  --font-base: clamp(1rem, 0.9rem + 0.3vw, 1.125rem);
  --font-lg: clamp(1.125rem, 1rem + 0.4vw, 1.25rem);
  --font-xl: clamp(1.25rem, 1.1rem + 0.5vw, 1.5rem);
  --font-2xl: clamp(1.5rem, 1.3rem + 0.7vw, 2rem);
  --font-3xl: clamp(1.875rem, 1.5rem + 1vw, 2.5rem);
}
```

### 3. Animations & Transitions

**Transition Best Practices:**
- Duration: 150ms (micro-interactions), 220ms (standard), 300ms (complex)
- Easing: `ease-out` for enter, `ease-in` for exit, `ease-in-out` for toggles
- [W] Properties: Only animate `transform` and `opacity` for 60fps
- [W] Avoid animating: `width`, `height`, `top`, `left`, `margin`, `padding`

**Hover Effects Catalog:**

```css
/* Lift effect */
.card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

/* Scale effect */
.button:hover {
  transform: scale(1.02);
}

/* Glow effect */
.input:focus {
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.3);
}

/* Underline reveal */
.link::after {
  content: '';
  position: absolute;
  width: 0;
  height: 2px;
  bottom: 0;
  transition: width 220ms ease-out;
}
.link:hover::after {
  width: 100%;
}
```

**Animation Patterns:**
- Staggered entrance: incremental `animation-delay` on list items
- Skeleton shimmer: `@keyframes` with gradient translation
- Page transitions: fade + slide with `animation` or Framer Motion
- Micro-interactions: button press scale, toggle flip, checkbox bounce
- Scroll-triggered: Intersection Observer + CSS class toggle

**Respecting User Preferences:**
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

### 4. Accessibility (WCAG 2.1 AA+)

**Color Contrast:**
- [C] Normal text (< 18px): minimum 4.5:1 contrast ratio
- [C] Large text (>= 18px or 14px bold): minimum 3:1 contrast ratio
- UI components and graphical objects: minimum 3:1 contrast ratio
- [C] Never rely on color alone to convey information

**Keyboard Navigation:**
- [C] All interactive elements must be keyboard-reachable (Tab/Shift+Tab)
- [C] Visible focus indicators (never `outline: none` without replacement)
- Logical tab order matching visual flow
- [C] Escape key closes modals, dropdowns, and overlays
- [C] Enter/Space activate buttons and links
- Arrow keys for menus, tabs, and carousels

**Focus Management:**
```css
/* Visible focus ring */
:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: 2px;
}

/* Remove focus ring for mouse users */
:focus:not(:focus-visible) {
  outline: none;
}

/* Skip-to-content link */
.skip-link {
  position: absolute;
  top: -100%;
  left: 0;
  z-index: 9999;
  padding: 1rem;
  background: var(--primary);
  color: var(--primary-foreground);
}
.skip-link:focus {
  top: 0;
}
```

**ARIA & Semantics:**
- Use semantic HTML first: `<button>`, `<nav>`, `<main>`, `<article>`
- `aria-label` for icon-only buttons and links
- `aria-describedby` for form field instructions
- `aria-expanded` for disclosure widgets
- `aria-live` for dynamic content updates
- `role` only when semantic HTML is insufficient
- `aria-hidden="true"` for decorative elements

**Screen Reader Patterns:**
- `.sr-only` / `.visually-hidden` for text only screen readers see
- Live regions for dynamic updates
- Landmark regions for page structure
- Proper heading hierarchy (h1 -> h2 -> h3, no skips)

### 5. Tailwind CSS Patterns

**Utility-First Guidelines:**
- Prefer utilities over custom CSS
- Use `@apply` sparingly - only for repeated patterns
- Layer custom styles: `@layer base`, `@layer components`, `@layer utilities`

**Common Responsive Patterns:**
```html
<!-- Responsive grid -->
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-6">

<!-- Responsive text -->
<h1 class="text-2xl md:text-3xl lg:text-4xl font-bold">

<!-- Responsive spacing -->
<section class="px-4 md:px-6 lg:px-8 py-8 md:py-12 lg:py-16">

<!-- Mobile menu / desktop nav -->
<nav class="hidden md:flex md:items-center">
<button class="md:hidden" aria-label="Toggle menu">
```

**Dark Mode with Tailwind:**
```html
<!-- Class-based dark mode -->
<div class="bg-white dark:bg-gray-900">
  <h1 class="text-gray-900 dark:text-gray-100">
  <p class="text-gray-600 dark:text-gray-400">
```

**Custom Theme Extensions:**
```js
// tailwind.config.ts
module.exports = {
  theme: {
    extend: {
      colors: {
        primary: 'var(--color-primary)',
        surface: 'var(--color-surface)',
      },
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
      },
      borderRadius: {
        '4xl': '2rem',
      },
    },
  },
}
```

### 6. CSS Architecture & Organization

**Layer System:**
```css
@layer reset {
  /* Box-sizing, margins, etc. */
}
@layer base {
  /* Element defaults: body, h1-h6, a, button, input */
}
@layer components {
  /* Reusable patterns: .card, .btn, .input */
}
@layer utilities {
  /* Single-purpose: .text-balance, .grid-auto-fill */
}
```

**Custom Properties (Design Tokens) [W]:**
```css
:root {
  /* Colors */
  --color-primary: oklch(55% 0.2 260);
  --color-surface: oklch(98% 0.005 260);
  --color-text: oklch(20% 0.02 260);
  --color-border: oklch(85% 0.01 260);

  /* Spacing (8px base) */
  --space-1: 0.25rem;  /* 4px */
  --space-2: 0.5rem;   /* 8px */
  --space-3: 0.75rem;  /* 12px */
  --space-4: 1rem;     /* 16px */
  --space-6: 1.5rem;   /* 24px */
  --space-8: 2rem;     /* 32px */

  /* Typography */
  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.125rem;
  --line-height-normal: 1.5;
  --line-height-relaxed: 1.625;

  /* Radius */
  --radius-sm: 0.25rem;  /* 4px */
  --radius-md: 0.375rem; /* 6px */
  --radius-lg: 0.5rem;   /* 8px */
  --radius-xl: 0.75rem;  /* 12px */

  /* Shadows */
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.07);
  --shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1);

  /* Motion */
  --duration-fast: 150ms;
  --duration-base: 220ms;
  --duration-slow: 300ms;
  --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-in: cubic-bezier(0.7, 0, 0.84, 0);
}

/* Dark mode overrides */
@media (prefers-color-scheme: dark) {
  :root {
    --color-primary: oklch(70% 0.2 260);
    --color-surface: oklch(15% 0.01 260);
    --color-text: oklch(95% 0.01 260);
    --color-border: oklch(30% 0.01 260);
  }
}
```

### 7. Cross-Browser & Performance

**Browser Compatibility:**
- Use `@supports` for progressive enhancement
- Provide fallbacks for `gap` in Flexbox (older Safari)
- `-webkit-` prefixes for `text-fill-color`, `box-decoration-break`
- `appearance: none` for custom form controls
- Test: Chrome, Firefox, Safari, Edge (Chromium)

**CSS Performance:**
- [W] Prefer `transform` and `opacity` for animations (GPU-accelerated)
- Use `will-change` sparingly - only before animations, remove after
- `contain: layout style paint` for isolated components
- `content-visibility: auto` for off-screen content
- Reduce layout thrashing: batch DOM reads then writes

**Critical Rendering:**
- Inline critical CSS; defer non-critical
- Use `font-display: swap` for custom fonts
- Preload critical fonts: `<link rel="preload" as="font">`
- Avoid `@import` - use `<link>` or bundler imports

---

## Implementation Workflow

### Step 1: Analyze the Styling Problem

```text
- What element(s) need styling?
- What is the current behavior vs. desired behavior?
- Is this a layout, visual, animation, or accessibility issue?
- What breakpoints are relevant?
- Are there browser compatibility requirements?
```

### Step 2: Choose the Right Approach

| Problem Type | Approach |
|-------------|----------|
| Layout | Flexbox (1D) or Grid (2D) |
| Alignment | Flexbox alignment properties |
| Positioning | Relative/Absolute/Fixed/Sticky |
| Spacing | Consistent scale from design tokens |
| Colors | Semantic tokens only, check contrast |
| Typography | Scale system with `clamp()` for fluidity |
| Animation | `transform` + `opacity`, proper easing |
| Responsive | Mobile-first, progressive enhancement |
| Accessibility | Semantic HTML, ARIA, keyboard, contrast |

### Step 3: Implement with Best Practices

1. Use design tokens / CSS custom properties (no magic numbers)
2. Mobile-first responsive approach
3. Semantic HTML with ARIA where needed
4. Smooth transitions with GPU-friendly properties
5. Focus-visible states for keyboard navigation
6. Dark mode support where applicable
7. Cross-browser testing considerations

### Step 4: Quality Checklist

- [ ] Layout correct at all breakpoints (375, 768, 1024, 1280px)
- [ ] No horizontal overflow on any screen size
- [ ] Touch targets at least 44x44px on mobile
- [ ] Hover/focus/active states implemented
- [ ] Color contrast meets WCAG AA (4.5:1 normal text)
- [ ] Keyboard navigation works (Tab, Enter, Escape)
- [ ] Focus indicators visible
- [ ] Animations respect `prefers-reduced-motion`
- [ ] Dark mode renders correctly
- [ ] No layout shift or jank
- [ ] CSS is DRY and maintainable

---

## Common Solutions Library

### Centering

```css
/* Center anything (the holy grail) */
.center {
  display: grid;
  place-items: center;
}

/* Flexbox center */
.center-flex {
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Absolute center (when position: relative on parent) */
.center-absolute {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
}
```

### Sticky Footer

```css
/* Flexbox approach */
.page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}
.page-content {
  flex: 1;
}

/* Grid approach */
.page {
  min-height: 100vh;
  display: grid;
  grid-template-rows: auto 1fr auto;
}
```

### Equal-Height Cards

```css
.cards {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1.5rem;
  align-items: stretch; /* default, but explicit for clarity */
}
```

### Scroll Shadows

```css
.scroll-container {
  overflow: auto;
  background:
    linear-gradient(white 30%, transparent),
    linear-gradient(transparent, white 70%) 0 100%,
    radial-gradient(farthest-side at 50% 0, rgba(0,0,0,.2), transparent),
    radial-gradient(farthest-side at 50% 100%, rgba(0,0,0,.2), transparent) 0 100%;
  background-repeat: no-repeat;
  background-size: 100% 40px, 100% 40px, 100% 14px, 100% 14px;
  background-attachment: local, local, scroll, scroll;
}
```

### Truncate Text

```css
/* Single line */
.truncate {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* Multi-line (line-clamp) */
.line-clamp-3 {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Balanced text wrapping */
.text-balance {
  text-wrap: balance;
}
```

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It's Bad | Fix |
|-------------|-------------|-----|
| `!important` everywhere | Specificity wars, unmaintainable | Use proper specificity, CSS layers |
| `outline: none` alone | Removes keyboard focus indicator | Replace with custom `:focus-visible` style |
| Inline styles | No specificity control, can't override | Use CSS classes, tokens, utilities |
| Magic numbers (`margin-top: 37px`) | Inconsistent, breaks on resize | Use spacing scale from tokens |
| `position: absolute` for layout | Fragile, doesn't adapt | Use Flexbox/Grid for layout |
| Fixed pixel widths | Breaks on different screens | Use relative units, `min()`, `max()`, `clamp()` |
| Animating layout properties | Janky, causes reflow | Animate only `transform` and `opacity` |
| Color-only indicators | Inaccessible to colorblind users | Add icons, text, or patterns |
| `z-index: 99999` | Stacking context chaos | Use documented z-index scale |
| `@import` in CSS | Blocking, serial loading | Use bundler or `<link>` tags |

---

## Tailwind CSS Specific Tips

### Custom Scrollbar
```css
/* Styled scrollbar */
.custom-scroll::-webkit-scrollbar {
  width: 6px;
}
.custom-scroll::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scroll::-webkit-scrollbar-thumb {
  background: var(--color-border);
  border-radius: 3px;
}
.custom-scroll::-webkit-scrollbar-thumb:hover {
  background: var(--color-text-muted);
}
```

### Group Hover Patterns
```html
<div class="group cursor-pointer">
  <img class="group-hover:scale-105 transition-transform duration-300" />
  <h3 class="group-hover:text-primary transition-colors">Title</h3>
</div>
```

### Container Queries (Modern)
```css
/* Define a containment context */
.card-wrapper {
  container-type: inline-size;
  container-name: card;
}

/* Style based on container width, not viewport */
@container card (min-width: 400px) {
  .card-content {
    flex-direction: row;
  }
}
```

---

## Debugging Tips

1. **Layout debugging**: Use browser DevTools Layout panel for Grid/Flexbox overlays
2. **Specificity issues**: Check computed styles, use DevTools specificity calculator
3. **Z-index problems**: Inspect stacking contexts with DevTools 3D view
4. **Animation jank**: Use Performance panel, check for layout thrashing
5. **Cross-browser**: Test in BrowserStack or use `@supports` for progressive enhancement
6. **Responsive**: Use Chrome DevTools device emulation + real device testing
7. **Accessibility** [I]: Run Lighthouse audit, axe DevTools, keyboard-only navigation test

---

## Communication style

This skill communicates in a professional style:
- No emoji or Unicode graphics in responses
- Use text tags for status: [OK], [FAIL], [TODO], [WARNING]
- Use ASCII diagrams for flows: ->, |, +, v, ^
- Use severity tags for rules: [C] (Critical), [W] (Warning), [I] (Info)
- If you must reference a Unicode character as the object of description, mark it with (ref)
