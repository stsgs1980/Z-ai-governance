# Card Archetypes — Companion to DESIGN-001 Profile

> Companion to: `DESIGN-001-profile-terminal-dashboard.md` (Terminal Dashboard
> example Profile, itself companion to STD-DESIGN-001 v3.1.1)
> Type: Reference appendix, NOT a separate standard
> Last Updated: 2026-06-21
> Status: ILLUSTRATIVE EXAMPLE

This file is a **sub-companion reference** to
`DESIGN-001-profile-terminal-dashboard.md`, which is itself a companion
to `DESIGN-001-design-system.md` (STD-DESIGN-001 v3.1.1). It contains
§19 Card Archetypes — concrete code examples for the 5 card types used
in the Terminal Dashboard example Profile.

**This file is NOT a separate standard.** It does not have an `STD-` ID
of its own and does not participate in the ID graph. The companion chain
is:

    STD-DESIGN-001 (parser-bound, in DESIGN-001-design-system.md)
      -> DESIGN-001-profile-terminal-dashboard.md (companion, profile tokens)
        -> DESIGN-001-profile-cards.md (THIS FILE, card archetype examples)

## Why this file exists

In STD-DESIGN-001 v3.1.0, the Terminal Dashboard Profile (§14-§26) was
moved from the main standard to a companion file. The companion was
1098 lines, exceeding the 1000-line soft cap (W11 warning from
`verify-id-graph.js`). In v3.1.1, §19 Card Archetypes (168 lines, the
largest single section in the profile) was moved to this sub-companion
to bring the profile file under the soft cap.

## How cross-references resolve

External references to "STD-DESIGN-001 §19" or "[PROFILE P6] Card
Archetypes" resolve to this sub-companion file. All other §N references
in 14-26 (except 19) resolve to `DESIGN-001-profile-terminal-dashboard.md`.
Section number preserved verbatim.

---

## 19. [PROFILE P6] Card Archetypes

### 19.1. Terminal Card

- Border: `border-dashed`
- Wrapper: Terminal-style frame component (default implementation: `TerminalFrame`)
- Background: Default (no tint)
- Content: Command output, terminal prompts, interactive shell, dashboard stats
- Typography: `font-mono` for chrome, `font-sans` for titles

**Requirements for the wrapper component:**

- Renders a dashed border container
- Provides consistent terminal-style framing (header bar with dots, prompt prefix)
- Supports light/dark theme via semantic tokens

```tsx
// [OK] Terminal card (using default TerminalFrame wrapper, Pattern A)
<TerminalFrame>
  <div className="border-dashed p-md">
    <span className="text-badge font-mono">dashboard</span>
    <span className="text-accent-primary">$</span>
    <span className="text-code font-mono">ls ~/documents</span>
  </div>
</TerminalFrame>
```None

### 19.2. Content Card

- Border: `solid` (default)
- Wrapper: Content card component (default implementation: `Card`)
- Background: Default (no tint)
- Content: Prose, descriptions, translations, explanatory text
- Typography: `font-sans` for all text, `font-mono` only for code snippets

**Requirements for the wrapper component:**

- Renders a solid border container
- Supports padding via spacing tokens
- Does not add terminal-style chrome (no dashed borders, no prompt prefixes)

```tsx
// [OK] Content card (using default Card wrapper, Pattern A)
<Card>
  <div className="p-md">
    <h3 className="text-h3 font-sans">
      Deployment Guide
    </h3>
    <p className="text-body font-sans">
      Instructions for configuring the environment and launching
      in production mode.
    </p>
    <span className="text-badge font-mono">devops</span>
  </div>
</Card>
```

### 19.3. Stat Card

- Border: None
- Background: `--muted-alpha` (50% opacity muted surface via `color-mix()`)
- Content: Single metric, number + label
- Typography: `font-mono` for value (tabular-nums), `font-mono` for label

The Stat Card uses a semi-transparent muted background. This is implemented via a dedicated `--muted-alpha` CSS custom property that uses `color-mix()` to produce 50% opacity of the muted surface color. This approach satisfies Core 4.4 (all colors must resolve to CSS custom properties) without relying on framework-specific opacity modifiers like `bg-muted/50` which bypass the custom property layer.

```css
/* In :root and .dark (see Section 22 for full block) */
:root {
  --muted-alpha: color-mix(in oklch, var(--muted) 50%, transparent);
}
.dark {
  --muted-alpha: color-mix(in oklch, var(--muted) 50%, transparent);
}
```None

```tsx
// [OK] Stat card (Pattern A: Theme Extension)
<div className="bg-muted-alpha p-md">
  <span className="text-code font-mono tabular-nums">42</span>
  <span className="text-badge font-mono">documents</span>
</div>

// [OK] Stat card (Pattern B: CSS Modules)
<div className={styles.statCard}>
  <span className={styles.statValue}>42</span>
  <span className={styles.statLabel}>documents</span>
</div>

/* stat.module.css */
.statCard { background: var(--muted-alpha); padding: var(--space-md); }
.statValue { font: 400 13px/1 var(--font-mono); font-variant-numeric: tabular-nums; }
.statLabel { font: 400 10px/1 var(--font-mono); }
```

**For Profiles using Pattern A with Tailwind CSS:** Register `muted-alpha` in the theme configuration alongside other tokens. Do not use the `bg-muted/50` opacity modifier syntax, as it generates opacity at the utility layer rather than resolving through a CSS custom property, which violates Core 4.4.

**Browser compatibility note:** `color-mix(in oklch, ...)` requires Chrome/Edge 111+, Firefox 113+, Safari 16.4+. For projects that must support older browsers (Safari 15, legacy environments), define a static fallback value alongside the `color-mix()` declaration. The fallback must be documented as a Profile-specific exception:

```css
:root {
  /* Fallback for browsers without color-mix() support */
  --muted-alpha: rgba(128, 128, 128, 0.05);
  /* Modern definition -- overrides fallback when supported */
  --muted-alpha: color-mix(in oklch, var(--muted) 50%, transparent);
}
```None

CSS custom properties follow the cascade: browsers that support `color-mix()` will use the second declaration; older browsers will fall back to the first. The static fallback value must be visually verified by the design team and documented in the Profile.

### 19.4. Interactive / Canvas Card

- Border: None or `solid` (Profile-specific)
- Background: Transparent or `--muted-alpha` (Profile-specific)
- Content: Full-viewport interactive areas: canvas renderers (Three.js, D3, Konva), flow editors, drag-and-drop boards, map views, animation playgrounds
- Typography: `font-sans` for overlay controls; `font-mono` for coordinate/data readouts

This archetype is for components where the primary visual output is not prose or metrics but an interactive canvas or viewport. Unlike Terminal, Content, and Stat cards which display information, the Interactive/Canvas card provides a drawing surface or interaction area. The card itself is a thin wrapper; the visual weight comes from the rendered content (3D scene, diagram, chart, map), not from border or background treatments.

**Requirements for the wrapper component:**

- Renders a boundary container for the interactive content
- Supports an optional overlay for controls (toolbar, zoom controls, legend)
- Must not add padding that clips the canvas/viewport content (padding applies to overlay only)
- Must handle resize events to keep the interactive content responsive

```tsx
// [OK] Interactive/Canvas card (Pattern A)
<CanvasCard>
  <Canvas3DRenderer data={sceneData} />
  <CanvasOverlay position="top-right">
    <ZoomControls />
    <AxisToggle />
  </CanvasOverlay>
</CanvasCard>

// [OK] Interactive/Canvas card (Pattern B)
<CanvasCard>
  <FlowEditor data={flowData} />
  <CanvasOverlay position="bottom-left">
    <span className={styles.readout}>x: 142 y: 87</span>
  </CanvasOverlay>
</CanvasCard>
```

**Animation tokens (Section P12):** Components within an Interactive/Canvas card that use transitions, spring physics, or keyframe animations must reference animation tokens (`--duration-*`, `--easing-*`) rather than hardcoded millisecond values or cubic-bezier strings. This ensures animation timing is consistent with the rest of the design system and can be adjusted per Profile (e.g., slower animations for accessibility, faster for power-user tools).

### 19.5. Profile-Specific Card Rules

- A Content Card must never use `border-dashed`.
- A Terminal Card must always use `border-dashed` and be wrapped in a terminal-style frame component.
- A Stat Card uses `--muted-alpha` (color-mix 50% muted) with minimal visual weight. No heavy borders.

```tsx
// [FAIL] Content card with terminal style
<Card className="border-dashed">
  <p className="text-sm font-sans">Prose content here</p>
</Card>

// [FAIL] Terminal card with solid border
<div className="border-solid p-3">
  <span>$</span> ls
</div>
```bash

Note: These rules are specific to the Terminal Dashboard Profile. A different Profile may define entirely different archetype constraints (e.g., an immersive Profile might require glass backgrounds for feature cards and no borders on any card type).

---

