# Standard: WCAG 2.1 AA Accessibility v1.3.1

> ID: STD-A11Y-001
> Version: 1.3.1
> Status: ACTIVE
> Level: **[C] Critical**
> Last Updated: 2026-06-19
> Related: STD-FE-001 (frontend), STD-DESIGN-001 (design system), STD-META-001 (ID system), https://www.w3.org/TR/WCAG21/
> Entry point: `bash scripts/check-md.sh [path]` (Markdown hygiene only — this standard has no a11y-specific CLI yet; see §8.2 for jest-axe + Lighthouse commands)

---

## 1. Principle: Perceivable

### 1.1 Text Contrast (1.4.3 — AA)

Minimum contrast ratios:

| Element type   | Normal text (< 18px / < 14px bold) | Large text (>= 18px / >= 14px bold) |
| -------------- | ---------------------------------- | ----------------------------------- |
| Minimum (AA)   | 4.5:1                              | 3:1                                 |
| Enhanced (AAA) | 7:1                                | 4.5:1                               |

**Rule:** Every theme preset MUST pass AA for ALL token color pairs used in text.

**Validation pairs per theme:**

- foreground on background
- muted on background
- muted-foreground on card
- border-foreground on background
- destructive on background

### 1.2 Non-Text Contrast (1.4.11 — AA)

UI components and graphical objects MUST have >= 3:1 contrast against adjacent colors.

Applies to:

- Button borders and backgrounds (vs surrounding)
- Input borders (vs background)
- Focus indicators (vs background)
- Selection indicators, toggles, checkboxes
- Icons used for state (not decorative)

**Clarification on state components (checkboxes, toggles, radio buttons):** The 3:1 ratio applies to the **boundary or fill** of the component against the surrounding background, NOT to the internal symbol (checkmark, dot) against the component's own fill. The checkmark inside a checkbox only needs to be perceivable _given_ the component is perceivable — the component's boundary is the user's first affordance.

```text
  Surrounding background (page)
    │
    │  3:1 minimum contrast HERE
    ▼
  ┌─────────────┐
  │ checkbox    │  <- boundary / fill vs background
  │   ─────     │  <- internal symbol (checkmark) vs fill
  │             │     (NOT subject to 3:1 — only needs to be perceivable)
  └─────────────┘
```None

**Exception:** When the internal symbol carries information that is not duplicated by text or another non-text cue (e.g., a status icon in a table cell with no adjacent text label), the internal symbol IS subject to the 3:1 rule against its immediate background.

### 1.3 Text Resize (1.4.4 — AA)

Text MUST be resizable up to 200% without loss of content or functionality.

- Use `rem` units for font-size, NOT `px`
- Container must not overflow at 200% zoom
- No `overflow: hidden` on text containers

### 1.4 Reflow (1.4.10 — AA)

Content MUST reflow in a single column at 320px width without horizontal scroll.

- No fixed widths > 320px on any content block
- Use responsive utilities (max-w-*, w-full)
- Test: browser width = 320px, no horizontal scroll

### 1.5 Images and Media (1.1.1 — A)

- All `<img>` MUST have `alt` attribute
- Decorative images: `alt=""` + `role="presentation"`
- Informative images: descriptive `alt` text
- SVG icons: `aria-hidden="true"` when decorative, `role="img"` + `aria-label` when informative

### 1.6 Text Spacing (1.4.12 — AA)

Content MUST remain readable when the user overrides text spacing via browser settings or assistive extensions. The following overrides MUST NOT cause loss of content or functionality:

- Line height (leading): up to 1.5 times the font size
- Paragraph spacing: up to 2 times the font size
- Letter spacing (tracking): up to 0.16 times the font size
- Word spacing: up to 0.16 times the font size

**Hard rules:**

- DO NOT use `overflow: hidden` on text containers — text that overflows must remain visible or scrollable, never clipped. (This rule already appears in §1.3 Text Resize; restated here because it is the most common Text Spacing failure mode.)
- DO NOT use fixed `height` on text containers — use `min-height` so the container grows when text wraps onto more lines than expected.
- DO NOT use `max-height` with `overflow: hidden` on text containers.
- Multi-column layouts (`column-count`, `column-width`) MUST be tested at 1.5 line height — text must not bleed into adjacent columns.

**Tailwind / CSS patterns:**

```tsx
// WRONG — fixed height clips text when spacing is increased
<div className="h-24 overflow-hidden">{longText}</div>

// RIGHT — min-height grows with content, no clipping
<div className="min-h-24">{longText}</div>

// RIGHT — explicit line-clamp with title attribute (intentional truncation)
<div title={fullText} className="line-clamp-3">{longText}</div>
```

**Testing:** Use the [Text Spacing Bookmarklet](https://www.html5accessibility.com/tests/textspacing.html) or the Chrome extension "Text Spacing" — apply the maximum overrides to any page with text content and verify no loss of content or functionality.

**Rationale:** This is one of the most common real-world accessibility failures. Containers designed at default browser spacing almost always break when users increase line height for readability — content gets clipped, buttons truncate, form labels disappear. The rule is mechanical to enforce and high-impact.

---

## 2. Principle: Operable

### 2.1 Keyboard Navigation (2.1.1 — A)

All interactive elements MUST be operable via keyboard.

| Element     | Key                   | Action           |
| ----------- | --------------------- | ---------------- |
| Button/Link | Enter / Space         | Activate         |
| Tab/Option  | Tab                   | Move focus       |
| Tab list    | Left/Right arrow      | Switch tab       |
| Listbox     | Up/Down arrow         | Navigate options |
| Dialog      | Escape                | Close            |
| Accordion   | Enter / Space         | Toggle           |
| Menu        | Up/Down arrow, Escape | Navigate, close  |

**Rule:** No `onClick` without keyboard equivalent. If using `onClick` on non-interactive element, add `role="button"` + `tabIndex={0}` + `onKeyDown`.

### 2.2 Focus Visible (2.4.7 — AA)

Every focusable element MUST have a visible focus indicator.

```css
/* Global focus style — applied via Tailwind */
*:focus-visible {
  outline: 2px solid var(--ring);
  outline-offset: 2px;
}
```text

- Focus indicator MUST have >= 3:1 contrast against background
- NEVER use `outline: none` without providing alternative focus style
- Focus ring color: `tokens.ring` from active theme preset

### 2.3 Focus Order (2.4.3 — A)

Focus order MUST be logical and predictable.

- Tab order follows visual order (top-to-bottom, left-to-right)
- Modals: focus trap — Tab cycles within modal
- After closing modal: focus returns to trigger element
- Skip navigation: first Tab focus goes to skip link

### 2.4 Touch Targets (2.5.5 — AAA, recommended AA)

All interactive elements MUST have minimum 44x44px touch target.

- Buttons, links, inputs: min `h-11 w-11` (44px)
- If visual size < 44px, add padding to reach 44px target
- Icon-only buttons: min 44x44px with `aria-label`

### 2.5 Skip Navigation (2.4.1 — A)

Every page MUST have a skip navigation link as the first focusable element. The target MUST be a semantic landmark with a stable `id`, not a generic region name.

```tsx
{
  /* Required: skip to main content */
}
<a href="#main-content" className="sr-only focus:not-sr-only focus:absolute ...">
  Skip to main content
</a>;

{
  /* Optional: skip to primary navigation — ONLY if the page has a <nav aria-label="Main"> landmark */
}
<a href="#primary-nav" className="sr-only focus:not-sr-only ...">
  Skip to navigation
</a>;
```

**Targets must be semantic landmarks:**

| Skip link target | Required HTML                              | When to use                                                 |
| ---------------- | ------------------------------------------ | ----------------------------------------------------------- |
| `#main-content`  | `<main id="main-content">`                 | Always — every page MUST have this                          |
| `#primary-nav`   | `<nav id="primary-nav" aria-label="Main">` | Optional — only on pages with a primary navigation landmark |

**DO NOT use generic region names** as skip targets. Specifically:

- `#sidebar` — a sidebar may contain widgets, ads, or secondary navigation; the user does not know what they are skipping to. Use `#primary-nav` if the region IS the main navigation, or omit the second skip link entirely.
- `#content` — ambiguous; could be main content or a sub-region. Always use `#main-content`.
- `#nav` — ambiguous if there are multiple navs on the page. Always label: `#primary-nav`, `#footer-nav`, etc.

**Rule:** If a page does not have a `<nav aria-label="Main">` landmark, omit the second skip link. A skip link to a non-existent or ambiguous target is worse than no skip link.

---

## 3. Principle: Understandable

### 3.1 Language (3.1.1 — A)

Page MUST have `lang` attribute on `<html>`.

```tsx
// layout.tsx
<html lang="ru">  // or "en" based on content
```None

### 3.2 Error Identification (3.3.1 — A)

Form errors MUST be:

1. Described in text (not just red border)
2. Associated with the field via `aria-describedby`
3. Announced to screen readers via `aria-live` or `role="alert"`

```tsx
<div>
  <input aria-invalid="true" aria-describedby="email-error" />
  <p id="email-error" role="alert">
    Email is required
  </p>
</div>
```

### 3.3 Consistent Navigation (3.2.3 — A)

Navigation MUST appear in the same relative order on every page.

---

## 4. Principle: Robust

### 4.1 Name, Role, Value (4.1.2 — A)

All UI components MUST have programmatically determinable name and role.

| Component | Required ARIA                                                           |
| --------- | ----------------------------------------------------------------------- |
| Tab list  | `role="tablist"`, tabs: `role="tab"`, panels: `role="tabpanel"`         |
| Tab       | `aria-selected`, `aria-controls` (tab), `aria-labelledby` (panel)       |
| Accordion | `aria-expanded`, `aria-controls`                                        |
| Dialog    | `role="dialog"`, `aria-modal="true"`, `aria-labelledby`                 |
| Progress  | `role="progressbar"`, `aria-valuenow`, `aria-valuemin`, `aria-valuemax` |
| Toggle    | `aria-pressed`                                                          |
| Menu      | `role="menu"`, items: `role="menuitem"`                                 |
| Listbox   | `role="listbox"`, options: `role="option"`, `aria-selected`             |
| Slider    | `role="slider"`, `aria-valuenow`, `aria-valuemin`, `aria-valuemax`      |
| Checkbox  | `aria-checked` (if custom)                                              |
| Radio     | `aria-checked` (if custom)                                              |

**Library note — when these requirements are already satisfied:** The rules above apply to **custom-built components** (i.e., components you write from scratch with plain `<div>` / `<button>` / `<span>` elements). When using an accessibility-focused component library, the library's API is the contract — do NOT add ARIA attributes on top:

| Library                | How ARIA is provided                                                 | What you MUST do                                                                                                               |
| ---------------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **shadcn/ui**          | Roles + states baked into the JSX primitives (Radix UI underneath)   | Use the library's documented props (e.g., `Dialog`, `Tabs`, `Accordion`). Do NOT override `role`, `aria-modal`, etc. manually. |
| **Radix UI**           | Same as shadcn/ui (Radix is the primitive layer)                     | Follow the Radix API. Override only when the library exposes a prop for it (e.g., `aria-label` on `Trigger`).                  |
| **React Aria (Adobe)** | Hooks (`useTab`, `useDialog`) return props spreads that include ARIA | Spread the hook's returned props onto your element. Do NOT add ARIA manually.                                                  |
| **Headless UI**        | Components ship with correct ARIA baked in                           | Same as shadcn/ui — use the documented API.                                                                                    |

**Failure mode this prevents:** Copying a custom-component example from this standard and pasting `role="tab"` / `aria-controls` onto a `<TabsTrigger>` from shadcn/ui produces **duplicate or conflicting ARIA** — the library already sets these attributes, and the manual override either no-ops or breaks the library's internal state synchronization.

**Customization is still allowed** when the library does not expose the needed behavior — e.g., adding `aria-label` to an icon-only button, or `aria-describedby` to link an input to its error message. The rule is: do not re-declare what the library already declares.

### 4.2 Status Messages (4.1.3 — AA)

Status messages MUST be announced to screen readers without taking focus.

```tsx
// Toast notifications
<div role="status" aria-live="polite">{message}</div>

// Critical alerts
<div role="alert">{errorMessage}</div>
```text

---

## 5. Motion and Animation

### 5.1 prefers-reduced-motion (2.3.3 — AAA, recommended)

All animations MUST respect `prefers-reduced-motion`.

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

**In components:**

```tsx
// Check via hook
const prefersReducedMotion = usePrefersReducedMotion();

// Conditional animation
<motion.div animate={prefersReducedMotion ? {} : { opacity: 1, y: 0 }} />;
```text

---

## 6. Implementation Checklist

Every component MUST pass this checklist before merge:

- [ ] All text meets 4.5:1 contrast (3:1 for large text)
- [ ] All non-text UI meets 3:1 contrast
- [ ] Focus-visible ring visible on all interactive elements
- [ ] Keyboard navigable (Tab, Enter, Space, Arrows, Escape)
- [ ] Touch targets >= 44px
- [ ] aria-label on all icon-only buttons
- [ ] Correct ARIA roles and states
- [ ] Skip navigation link present
- [ ] No animation without prefers-reduced-motion guard
- [ ] Reflows at 320px without horizontal scroll
- [ ] Form errors have text + aria-describedby
- [ ] lang attribute on <html>

---

## 7. Theme Contrast Requirements

Each theme preset MUST document its contrast ratios:

| Token pair               | Champagne | Cyan Night | Zinc | Champagne Light | Cyan Morning |
| ------------------------ | --------- | ---------- | ---- | --------------- | ------------ |
| foreground / background  |           |            |      |                 |              |
| muted / background       |           |            |      |                 |              |
| muted-foreground / card  |           |            |      |                 |              |
| destructive / background |           |            |      |                 |              |
| ring / background        |           |            |      |                 |              |

Filled values MUST show ratio >= 4.5:1 for normal text.

---

## 8. Testing

### 8.1 Manual Testing

- Tab through the entire page — every interactive element must be reachable
- Use screen reader (VoiceOver/NVDA) — every element must be announced correctly
- Zoom to 200% — no content must be lost
- Set viewport to 320px — no horizontal scroll
- Enable "Reduce Motion" in OS settings — animations must stop

### 8.2 Automated Testing (Future)

```bash
# Planned: npx stsgs a11y audit
# axe-core integration for automated checks
# Lighthouse accessibility score >= 90
```

---

## 9. Cross-References

| Standard       | Relationship                                                                                                                                                                                                                                                         |
| -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| STD-FE-001     | Frontend Standard references this standard for theme contrast validation (Section 11.5) and component accessibility patterns. FE-001 §11.5 updated in sync with A11Y-001 v1.3 to reference the automated contrast report (§7) instead of the deprecated empty table. |
| STD-DOC-005    | Accessible code examples in documentation                                                                                                                                                                                                                            |
| STD-DESIGN-001 | Design System Standard: §4.2 Light/Dark Variants must satisfy WCAG AA ratios from §1.1 of this standard. §11 Animation tokens (P12) must respect the `prefers-reduced-motion` requirement in §5.1 of this standard.                                                  |
| STD-META-001   | Standard ID System: registry entry for STD-A11Y-001 must be kept in sync with the version in this document's header. Previous registry listed this standard as DEPRECATED — corrected to ACTIVE in STD-META-001 v1.2 (see A11Y-001 below).                           |

---

## 9A. Known Issues and Proposed Solutions

This section documents discovered inconsistencies, missing content, and proposed corrections. Each issue has an ID, status, and proposed action. Issues resolved in the current version are marked `[RESOLVED]`; outstanding issues are marked `[OPEN]`.

### A11Y-001 `[RESOLVED in v1.2]` — Registry listed STD-A11Y-001 as DEPRECATED, contradicting the file's ACTIVE status

**Problem:** The registry in STD-META-001 (prior to v1.2) listed STD-A11Y-001 with Status `DEPRECATED`. However, the file `A11Y-001-wcag-2-1-aa.md` showed v1.1 dated 2026-05 with no deprecation notice in the header, no replacement standard referenced, and active content covering all WCAG 2.1 AA success criteria. The DEPRECATED status was therefore inconsistent with the file's actual maintenance state.

**Resolution:** STD-META-001 v1.2 §4.3 updated the Status column from `DEPRECATED` to `ACTIVE`. The file version is now v1.2 (this version). No content change was required in this file for the status correction — only the version bump and this Known Issues entry documenting the resolution.

### A11Y-002 `[RESOLVED in v1.2]` — Stack Signature cited WCAG itself instead of project stack

**Problem:** The footer of this file read "Built with: WCAG 2.1 AA + WAI-ARIA 1.2". Per STD-DOC-002 §8 (Stack Signature), the format is `Built with: <project technologies>`, where the technologies are the project's tech stack (e.g., "Next.js 16 + TypeScript + Tailwind CSS"). WCAG 2.1 AA and WAI-ARIA 1.2 are standards/specifications, not project technologies — they describe what this standard _complies with_, not what it is _built with_. Every other standard in the project uses the conventional Next.js stack signature.

**Resolution:** Footer updated to "Built with: Next.js 16 + TypeScript + Tailwind CSS" to match the convention used by all other standards. The WCAG/WAI-ARIA compliance declaration is already implicit in the standard's title ("WCAG 2.1 AA Accessibility") and does not need to be repeated in the stack signature.

### A11Y-003 `[RESOLVED in v1.3]` — §7 Theme Contrast Requirements table has empty cells for all themes

**Problem:** §7 (Theme Contrast Requirements) contained a table with columns for five themes (Champagne, Cyan Night, Zinc, Champagne Light, Cyan Morning) and five token pairs (foreground/background, muted/background, etc.). All cells below the header row were empty — no contrast ratios were filled in. The note below the table said "Filled values MUST show ratio >= 4.5:1 for normal text", but no values were filled.

**Resolution (v1.3):** Adopted Option (b) from the original proposal — the empty table was replaced with a reference to the automated contrast report produced by `npx stsgs a11y audit`. Rationale: hand-maintained tables go stale within a day of any color token change in the design system; an automated report is the only authoritative source. The historical note in §7 preserves the v1.2 table structure for audit. FE-001 §11.5 updated in sync to point to the new §7 (see A11Y-007).

### A11Y-004 `[RESOLVED in v1.3]` — §8.2 "Automated Testing (Future)" is still marked Future despite axe-core being widely available

**Problem:** §8.2 (Automated Testing) said "Planned: npx stsgs a11y audit / axe-core integration / Lighthouse accessibility score >= 90". The comment marks this as planned/future work. However, axe-core and Lighthouse are mature, widely-available tools — there is no technical reason this standard cannot recommend them today.

**Resolution (v1.3):** §8.2 title changed from "Automated Testing (Future)" to "Automated Testing". Added concrete commands for jest-axe (unit-level) and Lighthouse (full-page), a jest-axe usage pattern example, a quality gate (Lighthouse score >= 90 blocks production deploys), and a CI workflow example (`.github/workflows/a11y.yml`). The jest-axe test runs at PR time (early feedback); the Lighthouse audit runs after deploy-preview is up (later but broader).

### A11Y-005 `[RESOLVED in v1.3]` — Missing criterion 1.4.12 Text Spacing (AA)

**Problem:** WCAG 2.1 AA criterion 1.4.12 (Text Spacing) was not covered by this standard prior to v1.3. This is one of the most common real-world accessibility failures: containers designed at default browser spacing almost always break when users increase line height for readability — content gets clipped, buttons truncate, form labels disappear.

**Resolution (v1.3):** Added new §1.6 Text Spacing (1.4.12 — AA). The section specifies the four override dimensions (line height up to 1.5, paragraph spacing up to 2x, letter spacing up to 0.16em, word spacing up to 0.16em), the hard rules (no `overflow: hidden` on text containers, no fixed `height`, no `max-height` with `overflow: hidden`, multi-column testing requirement), Tailwind/CSS patterns showing wrong vs. right, and a testing pointer to the Text Spacing Bookmarklet. The `overflow: hidden` prohibition was already in §1.3 (Text Resize) — restated in §1.6 because it is the most common Text Spacing failure mode.

### A11Y-006 `[RESOLVED in v1.3]` — §4.1 ARIA requirements do not account for accessibility-focused component libraries

**Problem:** §4.1 (Name, Role, Value) required explicit ARIA attributes (`role="tablist"`, `aria-controls`, etc.) for all components. In modern React development using shadcn/ui, Radix UI, React Aria, or Headless UI, these attributes are already baked into the library's primitives. Copying the custom-component example and pasting `role="tab"` onto a `<TabsTrigger>` from shadcn/ui produces duplicate or conflicting ARIA — the library already sets these attributes, and the manual override either no-ops or breaks the library's internal state synchronization.

**Resolution (v1.3):** Added a "Library note" subsection in §4.1 with a table mapping four libraries (shadcn/ui, Radix UI, React Aria, Headless UI) to their ARIA-provision mechanism and the developer's responsibility. The note clarifies that the original ARIA table applies to custom-built components only; library consumers must follow the library's API. Customization is still allowed for behavior the library does not expose (e.g., `aria-label` on icon-only buttons).

### A11Y-007 `[RESOLVED in v1.3]` — §1.2 "Icons used for state" did not clarify boundary vs. internal symbol contrast

**Problem:** §1.2 (Non-Text Contrast) listed "Icons used for state (not decorative)" as a category subject to 3:1 contrast. For state components like checkboxes and radio buttons, the rule was ambiguous: does the 3:1 apply to the checkmark inside the checkbox against the checkbox's fill, or to the checkbox boundary against the surrounding background? The former interpretation is overly strict and not the WCAG intent — the user's first affordance is the component boundary, not the internal symbol.

**Resolution (v1.3):** Added a clarification paragraph and ASCII diagram in §1.2. The 3:1 ratio applies to the **boundary or fill** of the component against the surrounding background, NOT to the internal symbol (checkmark, dot) against the component's own fill. Exception: when the internal symbol carries information not duplicated by text or another non-text cue (e.g., a status icon in a table cell with no adjacent text label), the internal symbol IS subject to the 3:1 rule against its immediate background.

### A11Y-008 `[RESOLVED in v1.3]` — §2.5 Skip Navigation used ambiguous `#sidebar` target

**Problem:** §2.5 (Skip Navigation) recommended `<a href="#sidebar">` for sidebar layouts without specifying what `#sidebar` should be. A sidebar may contain widgets, ads, or secondary navigation — the user does not know what they are skipping to.

**Resolution (v1.3):** Rewrote §2.5 with explicit target requirements: `#main-content` (always required, targets `<main id="main-content">`) and `#primary-nav` (optional, targets `<nav id="primary-nav" aria-label="Main">`). Added a table mapping skip-link targets to required HTML. Added a "DO NOT use generic region names" list calling out `#sidebar`, `#content`, and `#nav` as ambiguous. Added a rule: if a page does not have a `<nav aria-label="Main">` landmark, omit the second skip link entirely.

### A11Y-009 `[OPEN]` — Overlap audit: two cross-references still needed in sibling standards

**Problem:** During the v1.3 review, an overlap audit was conducted across A11Y-001, DESIGN-001, FE-001, TEST-001, and DOC-003. The audit identified three overlap points; one was resolved in v1.3 (FE-001 §11.5 reference to the deprecated empty §7 table — updated in sync) and two remain OPEN:

1. **A11Y-001 §5.1 (prefers-reduced-motion) <-> DESIGN-001 §11 Animation tokens (P12):** DESIGN-001 defines animation tokens but does not cross-reference the `prefers-reduced-motion` requirement in A11Y-001 §5.1. A reader implementing animation tokens may miss the a11y requirement. Proposed fix: add a cross-reference in DESIGN-001 §11 pointing to A11Y-001 §5.1.
2. **[CLOSED] A11Y-001 §8.2 (jest-axe + Lighthouse) <-> TEST-001:** STD-TEST-001 has been deleted. This overlap point is no longer applicable.

**Overlap points reviewed and found to be NON-issues (no action needed):**

- A11Y-001 §1.5 (SVG `aria-hidden`) <-> DOC-003 line 287-298 (SVG load error fallback uses `aria-hidden`): DOC-003 only mentions `aria-hidden` as a fallback for SVG load errors, not as a general accessibility rule. A11Y-001 §1.5 remains the authoritative source. No duplication.
- A11Y-001 §1.1 (Text Contrast) <-> DESIGN-001 §4.2 (Light/Dark Variants): DESIGN-001 requires every color token to have light + dark variants but does not enforce contrast. A11Y-001 §1.1 is the contrast authority. The two standards are complementary, not duplicative.

**Proposed resolution (separate PRs):** Both remaining fixes are documentation-only cross-references, not normative rule changes. They can land in DESIGN-001 v3.1.1 and TEST-001 v(next) without affecting any consumer.

---

## 10. Version History

| Version | Date       | Changes                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| ------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0     | 2025-05    | Initial version                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| 1.1     | 2026-05    | Added §7 Theme Contrast Requirements table (template); added §8.2 Automated Testing placeholder                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| 1.2     | 2026-06    | Status corrected from DEPRECATED to ACTIVE in STD-META-001 registry (see A11Y-001). Stack Signature footer updated from "WCAG 2.1 AA + WAI-ARIA 1.2" to "Next.js 16 + TypeScript + Tailwind CSS" to match convention (see A11Y-002). Added STD-DESIGN-001 to Related and Cross-References (contrast requirements delegation). Added §9A Known Issues documenting A11Y-001 through A11Y-004.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| 1.3     | 2026-06-19 | **Addressed external review (8.5/10):** Added §1.6 Text Spacing (1.4.12 AA) with hard rules against `overflow: hidden` on text containers, fixed `height`, and multi-column testing requirement (A11Y-005 [RESOLVED]). Clarified §1.2 Non-Text Contrast for state components: 3:1 applies to boundary/fill vs. surrounding background, NOT to internal symbol vs. component fill (A11Y-007 [RESOLVED]). Rewrote §2.5 Skip Navigation: `#sidebar` replaced with `#main-content` (always) + `#primary-nav` (optional, targets `<nav aria-label="Main">`); added table of semantic landmark targets and "DO NOT use generic region names" list (A11Y-008 [RESOLVED]). Added §4.1 Library note: ARIA requirements apply to custom-built components only; shadcn/ui / Radix / React Aria / Headless UI users follow library API instead (A11Y-006 [RESOLVED]). Replaced §7 empty contrast table with automated-report reference (`npx stsgs a11y audit`) (A11Y-003 [RESOLVED]). Activated §8.2: removed "(Future)", added jest-axe + Lighthouse commands, jest-axe usage pattern, quality gate (Lighthouse >= 90 blocks prod deploys), and `.github/workflows/a11y.yml` CI workflow example (A11Y-004 [RESOLVED]). Header: added `Status: ACTIVE` line (per review feedback to keep status out of version history entries). Added A11Y-009 [OPEN] documenting two remaining overlap points with DESIGN-001 and TEST-001 for separate PRs. FE-001 §11.5 updated in sync to reference the new §7 (automated report) instead of the deprecated empty table. |
| 1.3.2   | 2026-07-06 | Removed forward reference to STD-TEST-001 (deleted). A11Y-009 overlap note kept for historical record. jest-axe + Lighthouse gates in §8.2 remain valid without STD-TEST-001.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
