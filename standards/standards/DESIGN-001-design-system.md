# Design System Standard

> ID: STD-DESIGN-001
> Version: 3.1.1
> Level: **[C] Critical** + **[W] Warning**
> Related: Markdown Standard v2.3 (STD-DOC-002), Unicode Policy v2.3 (STD-DOC-003), STD-META-001 (ID system)
> Companion files: `DESIGN-001-profile-terminal-dashboard.md` (Terminal Dashboard example Profile, §14-§26 except §19), `DESIGN-001-profile-cards.md` (§19 Card Archetypes, sub-companion added in v3.1.1)

This standard consists of two layers: **Core** (framework-agnostic, design-language-agnostic rules that apply to any project) and **Profile** (product-specific token values, component maps, and design language choices). The Core is universal; the Profile is a concrete instantiation that is swapped per project.

**v3.1.0 structural change:** The Terminal Dashboard example Profile (§14-§26) has been moved to a companion file `DESIGN-001-profile-terminal-dashboard.md` to bring this standard under the 1500-line hard cap (W11 CRITICAL closure). See §14 below for the pointer. All section numbers are preserved verbatim in the companion file, so cross-references to "STD-DESIGN-001 §N" (N in 14-26) remain stable.

**v3.1.1 structural change:** §19 Card Archetypes (168 lines) further extracted from the profile companion to `DESIGN-001-profile-cards.md` to bring the profile file under the 1000-line soft cap (W11 soft warning closure). Section number preserved verbatim. The companion chain is now: STD-DESIGN-001 (parser-bound) -> profile-terminal-dashboard.md (companion) -> profile-cards.md (sub-companion).

---

## 0. Scope

### Covers

Any **DOM-based UI with CSS**, regardless of component framework or design language:

| Dimension | Coverage |
|-----------|----------|
| Component frameworks | React, Vue, Svelte, Angular, Solid, vanilla JS |
| CSS approaches | Tailwind, UnoCSS, CSS Modules, Vanilla CSS, SASS/SCSS, CSS-in-JS (Styled Components, Emotion, vanilla-extract) |
| Design languages | Terminal, corporate, editorial, SaaS, immersive (via Profile) |
| Themes | Light, dark, custom presets (via CSS custom properties cascade) |
| Platforms | Browser, SSR, static site generation |

### Does NOT Cover

Environments where **CSS custom properties do not exist** or where the rendering model is fundamentally different from DOM + CSS:

| Environment | Why | Coverage |
|-------------|-----|----------|
| **React Native / Flutter / SwiftUI** | No DOM, no CSS custom properties. Tokens must be JS objects consumed via `StyleSheet.create()` or platform theming. The token *naming* and *semantic structure* from this standard apply, but the delivery mechanism is entirely different. | ~50% (naming + semantics only) |
| **Canvas / WebGL without DOM** (Three.js, PIXI.js, raw WebGL) | No DOM, no CSS. Tokens must be passed as JS constants into shaders, material properties, or renderer config. | ~40% (JS constants from P12/P13; visual tokens need per-renderer adaptation) |
| **Print / PDF design** | No light/dark themes, no animations, no interactivity. Color model is CMYK, not oklch/RGB. Typography units are points, not pixels. | ~10% (typography scale concept only; values and color model incompatible) |
| **Terminal TUI applications** | No CSS. Only 256 ANSI colors, no custom properties, no font families beyond terminal defaults. | ~5% (semantic naming concept only) |
| **Embedded / microcontrollers** | No CSS, no DOM, no rendering pipeline compatible with web tokens. | 0% |

### Boundary Rule

**If the project renders UI through a DOM with CSS**, this standard applies fully. The token delivery mechanism (CSS custom properties) is the hard boundary. Projects outside this boundary may adopt the *naming conventions and semantic structure* from this standard, but must implement their own delivery mechanism and must document the adaptation in their Profile.

---

## 1. Introduction and Goals

This standard defines the design token system that governs all visual output. Tokens are the atomic units of the design system. Every color, font size, spacing value, and card style must resolve to a named token. Hardcoded values are prohibited in production code.

**Goals:**

- Ensure visual consistency across all UI blocks and views
- Maintain a single source of truth for typography, color, and spacing decisions
- Guarantee theme adaptability (light/dark) through semantic tokens
- Eliminate hardcoded hex values, arbitrary font sizes, and ad-hoc spacing
- Enable systematic enforcement through linting and code review
- Separate universal rules from product-specific decisions so the standard applies across project types and design languages

**Conformance levels:**

| Level | Context | Action on violation |
|-------|---------|---------------------|
| **[C] Critical** | UI components, production code | Blocks merge |
| **[W] Warning** | Documentation, prototypes, internal tools | Comment in review, request to fix |

---

## 2. Architecture: Core + Profile

### 2.1. Core (Universal)

The Core defines **rules, structure, and constraints** that apply regardless of project type, design language, or CSS framework. It says *what must exist* and *how tokens are organized*, but not *what the specific values are*.

Core rules are marked with `[CORE]` throughout this document.

### 2.2. Profile (Product-Specific)

A Profile is a concrete instantiation of the Core for a specific project. It fills in the values: which fonts, which colors, which card archetypes, which component-to-token mappings. A project must have exactly one active Profile.

Profile-specific content is marked with `[PROFILE]` throughout this document.

### 2.3. Relationship

```text
Core (Sections 3-13 of this document)
  |
  +-- Profile A: [name] (Sections P1-P11, any project)
  +-- Profile B: [name] (Sections P1-P11, any project)
  +-- Profile N: ... (each project creates its own)
```

Each Profile must satisfy all Core constraints. If a Core rule says "you must have at least 2 font roles", the Profile defines which 2. If a Core rule says "color tokens must have light and dark variants", the Profile provides those variants. A project must have exactly one active Profile; the Core alone is incomplete for implementation because it contains no concrete values.

---

## 3. [CORE] Typography Rules

### 3.1. Font Roles

Every project must define at least **two** font roles:

| Role | Token | Requirements |
|------|-------|-------------|
| Primary | `font-sans` (or project-defined name) | Variable weight support (400-700 minimum); high legibility at the project's body text range |
| Monospace | `font-mono` (or project-defined name) | Tabular-nums mandatory if used for data; ligatures controlled; clear glyph distinction (0/O, 1/l/I) |

Additional roles (e.g., `font-serif` for editorial) are allowed but must be defined in the Profile with the same requirements structure.

### 3.2. Typography Scale

Every project must define a **named typography scale** with the following constraints:

- Minimum **5** levels (small + body + subheading + heading + page heading)
- Maximum **12** levels (prevents uncontrolled proliferation)
- Each level must specify: size (px or rem), weight, font role, and optional extras (tracking, transform)
- Every font size used in the interface must map to a named token in the scale
- Arbitrary font sizes (`text-[9px]`, `text-[13px]` outside of named tokens) are prohibited at level [C]
- The scale range must match the project context: dense dashboards typically use 10-24px; immersive and editorial projects may extend to 48-72px for page headings. The range is a Profile decision; the requirement for a named scale is Core

### 3.3. Font Convention Rules

- Font family is referenced by role token, never by font name in component code
- The mapping from role to concrete font lives in the CSS framework configuration, not in components
- A heading must never use a monospace role unless the Profile explicitly documents this as an exception
- A project may substitute fonts provided the replacement meets the role requirements. Substitution must be documented and approved by Tech Lead

---

## 4. [CORE] Color Token Rules

### 4.1. Semantic Naming

All color tokens must use **semantic or functional names**, not color names:

| Correct | Incorrect |
|---------|-----------|
| `--accent-primary` | `--green-500` |
| `--brand-color` | `--coral` |
| `--semantic-search` | `--violet-600` |
| `--destructive` | `--red` |

### 4.2. Light/Dark Variants

Every color token used in the interface must have **both** a light and a dark variant. The only exception is brand tokens that are intentionally identical across themes (must be documented in the Profile).

### 4.3. Token Aliasing

Aliases are allowed to provide convenience names, but each alias must resolve to a primary token. Two aliases must not define the same color independently; they must share a single source of truth.

### 4.4. Prohibition of Hardcoded Colors

- Direct `text-X dark:text-Y` pairs (framework-specific color pairs) are prohibited at level [C]
- Hardcoded hex/rgb/hsl values in component code are prohibited at level [C]
- All colors must resolve to CSS custom properties or their framework equivalent

### 4.5. Token Integration Patterns

A design system that relies on CSS custom properties must define how those properties integrate with the project's styling framework. Without an explicit integration pattern, developers are forced into hybrid approaches that mix `className` utilities with inline `style` attributes, degrading both performance and readability. This section defines four integration patterns; a Profile must adopt one and document the choice.

**Pattern A: Theme Extension (for utility-first CSS frameworks)**

The CSS custom properties are registered in the framework's theme configuration. Components use framework utilities exclusively; no inline `style` attributes are needed.

```css
/* tailwind.config.ts -- register tokens as theme values */
export default {
  theme: {
    extend: {
      colors: {
        'accent-primary': 'var(--terminal-accent)',
        'brand': 'var(--neuro-brand)',
        'star': 'var(--star-color)',
        'semantic-search': 'var(--semantic-violet)',
        'destructive': 'var(--accent-red)',
      },
      spacing: {
        'xs': 'var(--space-xs)',
        'sm': 'var(--space-sm)',
        'md': 'var(--space-md)',
        'lg': 'var(--space-lg)',
        'xl': 'var(--space-xl)',
      }
    }
  }
}
```

```tsx
// Component code -- clean, no inline styles
<span className="text-accent-primary">$</span>
<div className="p-md gap-sm">
  <h1 className="text-2xl font-bold font-sans">Title</h1>
</div>
```

This pattern keeps all styling in the utility layer, avoids `style={{}}` in JSX, and works correctly with SSR. It applies to projects using Tailwind CSS v3+, UnoCSS, or any utility-first CSS framework with theme extension support. The pattern is framework-agnostic: replace `tailwind.config.ts` with the equivalent configuration file for your utility framework (e.g., `uno.config.ts` for UnoCSS, `windi.config.ts` for Windi CSS). The principle remains the same: register CSS custom properties as theme values, consume via utility classes.

**Important:** Theme extension requires access to the framework's configuration file. In some setups (Create React App without eject, certain corporate build pipelines, locked managed platforms), modifying the theme configuration may be impossible or require admin access. In such cases, **Pattern B or Pattern C is the appropriate choice** -- they provide full token compliance without requiring framework configuration changes. No Profile should mandate Pattern A when the project's build system does not support it.

**Pattern B: CSS Modules**

The CSS custom properties are referenced directly in `.module.css` files. Components apply class names from the module.

```css
/* Dashboard.module.css */
.prompt {
  color: var(--terminal-accent);
  font-size: var(--text-label-size);
  font-weight: var(--text-label-weight);
  font-family: var(--font-mono);
}

.container {
  padding: var(--space-md);
  gap: var(--space-sm);
}
```

```tsx
// Component code
import styles from './Dashboard.module.css';

<span className={styles.prompt}>$</span>
<div className={styles.container}>
  <h1 className={styles.heading}>Title</h1>
</div>
```

This pattern is the natural choice for projects using CSS Modules, CSS-in-JS libraries that support custom properties (Styled Components, Emotion), or any framework without utility-first conventions.

**Pattern C: Vanilla CSS / Global Stylesheets**

The CSS custom properties are referenced directly in global or scoped CSS files. This is the simplest pattern with zero framework dependencies.

```css
/* styles.css */
.prompt {
  color: var(--terminal-accent);
  font: var(--text-label-weight) var(--text-label-size) var(--font-mono);
}

.container {
  padding: var(--space-md);
  display: flex;
  gap: var(--space-sm);
}
```

This pattern is suitable for projects using plain CSS, SASS/SCSS, PostCSS, or any build system that processes standard CSS. It has no framework coupling and works universally.

**Pattern D: CSS-in-JS (Styled Components, Emotion, vanilla-extract, Stitches)**

The CSS custom properties are referenced inside styled components or CSS-in-JS template literals. This pattern applies to projects using Styled Components, Emotion, vanilla-extract, Stitches, or any CSS-in-JS library that supports `var()` references within template literals or style objects.

```typescript
// Styled Components example
import styled from 'styled-components'

const Prompt = styled.span`
  color: var(--terminal-accent);
  font-size: var(--text-label-size);
  font-weight: var(--text-label-weight);
  font-family: var(--font-mono);
`

const Container = styled.div`
  padding: var(--space-md);
  gap: var(--space-sm);
`
```

```typescript
// Emotion example
import { css } from '@emotion/react'

const promptStyle = css`
  color: var(--terminal-accent);
  font: var(--text-label-weight) var(--text-label-size) var(--font-mono);
`
```

This pattern preserves all the benefits of CSS custom properties (theming via `:root`/`.dark`, no inline `style={{}}`) while leveraging the scoped styling and co-location features of CSS-in-JS. It avoids the runtime cost of JavaScript-based theming by using native CSS custom properties for theme switching instead of JavaScript theme context objects.

**Important:** CSS-in-JS libraries that use JavaScript objects for theming (e.g., `ThemeProvider` with a JS theme object) must still register tokens as CSS custom properties in a global stylesheet and reference them via `var()`. This ensures theme switching works through the CSS cascade (`:root`/`.dark`) rather than requiring JavaScript re-renders, which is consistent with how Patterns A, B, and C handle theming.

**Requirement:** The Profile must state which integration pattern it uses and provide the corresponding theme configuration or stylesheet structure. Mixed patterns (e.g., Pattern A for spacing and Pattern B for colors) are allowed but must be documented with a clear rule for which pattern applies to which token category.

---

## 5. [CORE] Syntax Highlighting Rules

Projects that render code blocks must define syntax highlighting tokens with the following constraints:

- Each syntax role (comment, keyword, string, function, etc.) must be a named token with light and dark variants
- The syntax highlighter must be configured to consume these tokens, not hardcoded colors
- The highlighter must support custom CSS class mapping and theme overrides via CSS custom properties
- The highlighter must not inject inline `style` attributes with hardcoded colors

Minimum required syntax roles (a project may define more):

| Role | Purpose |
|------|---------|
| `--syntax-comment` | Code comments |
| `--syntax-keyword` | Language keywords, HTTP methods |
| `--syntax-string` | String literals, URLs |
| `--syntax-function` | Function names, API paths |

---

## 6. [CORE] Spacing Rules

### 6.1. Spacing Scale

Every project must define a **named spacing scale** with the following constraints:

- Minimum **4** levels (tight + small + medium + large)
- Maximum **8** levels (prevents uncontrolled proliferation)
- Each level must specify a pixel or rem value
- Every `gap`, `padding`, and `margin` must use a named token from the scale
- Arbitrary spacing values are prohibited at level [C]
- The scale range must match the project context: dense dashboards typically use 4-24px; immersive sites with 3D, parallax, and full-bleed content may use 8-64px or wider. The range is a Profile decision; the requirement for a named scale is Core

### 6.2. Spacing Convention

- Spacing tokens must be progressive (each step is the next logical increment)
- Card-to-content padding and card-to-card spacing must be documented in the Profile
- If responsive spacing overrides are needed, they must be documented as a named pattern in the Profile, not ad-hoc

---

## 7. [CORE] Card Style Rules

### 7.1. Card Archetypes

Every project must define **at least one** card archetype. Each archetype must specify:

- Border treatment (e.g., dashed, solid, none, gradient, glow)
- Background treatment (e.g., transparent, tinted, muted, glass/blur, gradient, elevated)
- Padding (reference to spacing token)
- Typography rules (which font role for which content type)
- Content scope (what type of content belongs in this archetype)

The treatments listed above are illustrative, not exhaustive. A Profile may define any visual treatment that serves its design language, provided the treatment is documented and consistent across all cards of that archetype.

**Common archetypes (a Profile may define additional ones):**

| Archetype | Purpose | Typical content |
|-----------|---------|-----------------|
| Terminal | CLI-style display | Command output, prompts, dashboard stats |
| Content | Prose and descriptions | Articles, instructions, documentation |
| Stat | Single metric display | Numbers, KPIs, counters |
| Interactive / Canvas | Full-viewport interaction | 3D renderers, flow editors, maps, drag-and-drop boards |

A Profile must define at least one archetype. Projects with interactive visual content (3D, diagrams, maps) should define an Interactive/Canvas archetype to separate viewport-based content from information-display cards.

### 7.2. Card Style Constraints

- A card must be classified into exactly one archetype
- Mixing visual treatments from different archetypes on the same card is prohibited at level [C]
- The visual contract of an archetype (border style + background + typography rules) is normative; the component name is implementation

---

## 8. [CORE] Icon and Graphics Rules

Character and icon rules follow **No-Unicode Policy v2.3** (STD-DOC-003).

### 8.1. Icon Standard

- Any visual symbol in the interface must be **SVG only**
- Icons use a project icon library that must satisfy: SVG components or files; stroke/fill customization via design tokens; comprehensive UI icon set; SVGO-optimized
- Brand logos use official SVG via Markdown image syntax
- All icons must support theming and use design tokens for stroke/fill colors
- Fallback must exist for critical icons (text alternative via `aria-label`)

### 8.2. Prohibited Icon Patterns

| Pattern | Level | Replacement |
|---------|-------|-------------|
| Emoji as icons | [C] | SVG from icon library |
| Unicode symbols as status | [C] | Text tags: `[OK]`, `[FAIL]`, `[TODO]` |

---

## 9. [CORE] Markdown Compliance

Documentation files must comply with **Markdown Standard v2.3** (STD-DOC-002):

- Unordered lists use `-` marker strictly
- Code blocks specify a language; `text` or `bash` as fallback
- One `H1` per document; no closing `#` symbols on headings
- No typographic symbols in headings or code blocks
- Status indicators use text tags: `[OK]`, `[FAIL]`, `[TODO]`, `[WARNING]`
- Stack signature in root files: `Built with: <project technologies>`

Character prohibitions follow **STD-DOC-003 sections 4-5** at level `[W]`.

---

## 10. [CORE] Control and Enforcement

### 10.1. Level [C] Critical - Blocks Merge

| Stage | Action | Blocks merge? |
|-------|--------|---------------|
| Code Review | PR rejected | **Yes** |
| CI Pipeline | Error in logs | **Yes** |
| Linting | Error report | **Yes** |

Violations at level [C]:

- Hardcoded hex colors in component code
- Framework-specific color pairs instead of semantic tokens
- Font role violations (e.g., mono on headings where Profile forbids it)
- Arbitrary font sizes outside the named scale
- Card archetype misuse
- Emoji or Unicode icons in UI

### 10.2. Level [W] Warning - Does Not Block Merge

| Stage | Action | Blocks merge? |
|-------|--------|---------------|
| Code Review | Comment requesting fix | **No** |
| CI Pipeline | Warning in logs | **No** |
| Repeated violation | Escalation to Tech Lead | **Possible** |

Violations at level [W]:

- Missing stack signature in root documentation
- Typographic symbols in headings or code blocks
- Documentation not matching Markdown Standard

### 10.3. Enforcement Rule Template

Each project must implement an automated rule (ESLint, Stylelint, or equivalent) that:

- Detects hardcoded hex/rgb/hsl values in component code
- Detects framework-specific color utility classes that bypass semantic tokens
- Reports violations at the appropriate level ([C] = error, [W] = warning)

The specific prohibited patterns (which color classes, which hex values) are defined by the Profile (P9), not by the Core. Each Profile must provide its own enforcement rule template or configuration. The Core only requires that an enforcement mechanism exists.

### 10.4. Adoption Levels

Enforcing the full standard at [C] level from day one creates an unreasonably high barrier for existing teams and projects. This standard defines a **three-phase adoption process** that gradually raises enforcement levels. New projects may start at Phase 2 or Phase 3 if the team is already familiar with token-based design systems.

**Phase 1: Foundation (Weeks 1-2)**

All [C]-level violations are temporarily reported as [W]. No merge blocks. The goal is awareness, not compliance.

- Colors: [W] hardcoded hex values, [W] framework color pairs instead of semantic tokens
- Typography: [W] arbitrary font sizes, [W] font role violations
- Spacing: [W] arbitrary spacing values
- CI: Warnings only; zero merge blocks

During this phase, the team installs the Profile, configures CSS custom properties in the global stylesheet, and begins learning the token names. Speed impact is minimal because nothing blocks work.

**Phase 2: Color Lock (Weeks 3-4)**

Color rules escalate to [C] and block merge. Typography and spacing remain at [W], but their violations **must be logged and visible in CI dashboards** even though they do not block merge.

- Colors: **[C]** hardcoded hex values, **[C]** framework color pairs -- blocks merge
- Typography: **[W+]** arbitrary font sizes, font role violations -- logged in CI, visible in dashboards, does not block merge
- Spacing: **[W+]** arbitrary spacing values -- logged in CI, visible in dashboards, does not block merge
- CI: Color violations are errors; typography and spacing are warnings with a persistent count report

The **[W+]** level means the violation is tracked and reported alongside a running total (e.g., "34 spacing violations, 12 typography violations") so the team can see their debt accumulating and address it incrementally before Phase 3 activates full enforcement. Without this visibility, teams that ignore [W] violations for 4 weeks will face an overwhelming number of blocking errors when Phase 3 begins.

This phase is prioritized because color is the most visible inconsistency and the hardest to fix retroactively. By week 4, the team should be comfortable with semantic color tokens and should have made visible progress on reducing typography and spacing debt.

**[W+] CI integration example (GitHub Actions):**

```yaml
# .github/workflows/design-debt.yml
name: Design System Debt Tracker
on: [push, pull_request]
jobs:
  debt-report:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Count spacing violations
        run: |
          SPACING=$(grep -rn 'p-[0-9.]\+\|gap-[0-9.]\+\|m-[0-9.]\+' src/ | grep -v 'var(--' | wc -l)
          echo "::warning file=design-debt::Spacing violations: $SPACING (does not block merge)"
          echo "SPACING_DEBT=$SPACING" >> $GITHUB_ENV
      - name: Count typography violations
        run: |
          TYPO=$(grep -rn 'text-\[.*px\]\|text-xs\|text-sm\|text-lg\|text-xl\|text-2xl' src/ | grep -v 'var(--\|font-mono\|font-sans' | wc -l)
          echo "::warning file=design-debt::Typography violations: $TYPO (does not block merge)"
          echo "TYPO_DEBT=$TYPO" >> $GITHUB_ENV
      - name: Debt summary
        if: always()
        run: |
          echo "### Design System Debt Report" >> $GITHUB_STEP_SUMMARY
          echo "| Category | Violations |" >> $GITHUB_STEP_SUMMARY
          echo "|----------|-----------|" >> $GITHUB_STEP_SUMMARY
          echo "| Spacing  | $SPACING_DEBT |" >> $GITHUB_STEP_SUMMARY
          echo "| Typography | $TYPO_DEBT |" >> $GITHUB_STEP_SUMMARY
```

This workflow produces a persistent count in the PR summary. The team sees debt trending up or down each week. The exact grep patterns must be adapted to the Profile's token names and prohibited patterns (P8).

**Phase 3: Full Enforcement (Week 5+)**

All Core rules are enforced at their designated levels. This is the steady state.

- Colors: [C] as designated
- Typography: [C] as designated
- Spacing: [C] as designated
- Cards, icons, markdown: [C] or [W] as designated in Sections 3-9
- CI: Full enforcement with the Profile's linting rules

**For existing projects with large codebases**, Phase 1 may extend to 4 weeks and Phase 2 to 6 weeks. The timeline is a recommendation, not a mandate; the Tech Lead decides when to advance based on team readiness.

**MVP and prototype projects** may remain at Phase 1 indefinitely, provided the deviation is documented in the project's README or architecture decision record.

---

## 11. [CORE] Exceptions

### 11.1. Unconditionally Allowed

- Brand tokens with identical light/dark values (intentional, must be documented in Profile)
- Tabular-nums on data values (exception to font role rules, justified by alignment needs)
- Named responsive spacing patterns (documented in Profile, not ad-hoc)

### 11.2. Exceptions by Agreement

| Situation | Requirement |
|-----------|-------------|
| Third-party component requires inline styles | Document exception in code comment |
| External design requirement (marketing) | Coordinate with design lead |
| Prototype / MVP | Level [I] applies; document deviation |

### 11.3. Approval Process

1. Create issue with justification
2. Get approval from Tech Lead
3. Document exception in code with `// DESIGN-EXCEPTION: <reason>` comment
4. Add to whitelist in linting rule if necessary

### 11.4. Creating a New Profile

To create a new Profile:

1. Copy the Profile template (Sections P1-P11 as defined in Section 13) or use any existing Profile as a starting point
2. Replace the Profile Identity header (Profile ID, Design Language, Project Type)
3. Fill in all 11 required sections (P1-P11) with your project's values
4. Verify every Core constraint is satisfied (see Section 13.1: Profile Validation Checklist)
5. Submit for review alongside the project's design documentation
6. Once approved, the Profile becomes the authoritative token source for that project

A Profile may be stored in the same document as the Core (for single-project repositories) or in a separate document (for multi-project organizations). When stored separately, the Profile document must reference the Core version it complies with.

### 11.5. Agent Context Generation

When code is generated by AI agents (coding assistants, automated scaffolding tools), the full standard document is too large for a system prompt. A **compressed agent context** must be derived from the Profile to fit within prompt token limits while preserving all information the agent needs to produce compliant code.

**Why this is necessary:** Core rules tell an agent what *not* to do ("no hardcoded colors"), but without Profile values the agent has no idea what *to* do (which token to use instead). An agent without Profile context will default to framework conventions (e.g., Tailwind `text-blue-500`) that almost certainly violate the standard.

**Agent context format:**

Every Profile must be able to produce a compressed agent context containing four sections:

```markdown
# Design System Context (for AI agent)

## Typography
<token-name>: <size> <weight> <family> [<extras>]
(one line per token)

## Colors
<token-name>: <light-value> / dark: <dark-value>
(one line per token; aliases marked with "= <primary-token>")

## Spacing
<token-name>: <value>
(all tokens on one or two lines)

## Rules
- <rule 1>
- <rule 2>
(concise list of constraints the agent must follow)
```

**Requirements for the agent context:**

- Must fit within 3500 characters (approximately 900 tokens) when rendered
- Must include every typography token, every color token, every spacing token
- Must include all [C]-level rules that the agent is likely to violate
- Must NOT include prose explanations, rationale, version history, or cross-references
- Token values must be the actual values (hex, oklch, px), not references to sections
- The Profile must provide a concrete example of the rendered agent context
- **Compression is allowed:** Token names may be shortened in the agent context (e.g., `--ta` for `--terminal-accent`, `--sv` for `--semantic-violet`) provided a mapping table is included at the top of the context. This allows larger Profiles to fit within the limit without omitting tokens

**Auto-generation requirement:** The agent context (P11) must be generated from the Profile's token definitions (P1-P5) by a script, not written manually. Manual maintenance of P11 is impractical because any change to P1-P5 must be reflected in P11 immediately; without automation, P11 will drift out of sync and produce stale instructions for AI agents.

**Adoption-phase alignment:**

| Adoption Phase | P11 Script Requirement |
|---------------|----------------------|
| Phase 1 | Optional. Manual generation is acceptable. The team may maintain P11 by hand during the initial adoption period. |
| Phase 2 | Recommended. A script should be written or adapted, but CI enforcement is not required yet. |
| Phase 3 | **Mandatory.** The script must run as part of the CI pipeline or as a pre-commit hook. A build must fail if the generated P11 does not match the committed P11 (preventing drift). |

This phased requirement avoids overburdening small teams (2-3 developers) that are still learning the token system. The script becomes mandatory only when the project reaches full enforcement, by which point the team has enough familiarity to write or adapt one in a few hours.

The generation script must:
- Read token definitions from P2 (Typography Scale), P3 (Color Tokens), P4 (Syntax Highlighting), and P5 (Spacing Scale)
- Render each token in the compact format defined above
- Append the [C]-level rules from the Profile
- Verify the output fits within 3500 characters (fail the build if it does not)
- (Phase 3 only) Run as part of the CI pipeline or as a pre-commit hook

A Profile may provide the generation script in any language (shell, Node.js, Python). The script must be committed alongside the Profile document.

**Target audience:** This context is written for an AI code generator, not a human. Prioritize completeness and precision over readability.

---

## 12. [CORE] Pre-merge Checklist

### Before merge (code [C]):

- [ ] No hardcoded hex colors in component code
- [ ] No framework-specific color pairs (use semantic tokens)
- [ ] No font role violations per Profile rules
- [ ] No arbitrary font sizes outside the named scale
- [ ] Card styles match their archetype per Profile definition
- [ ] All colors resolve to CSS custom properties or framework equivalent
- [ ] Syntax highlighting uses named tokens (not hardcoded colors)
- [ ] Spacing uses only the named scale tokens
- [ ] Icons use SVG (from project icon library) with fallback

### Before merge (documentation [W]):

- [ ] No emoji or Unicode icons (STD-DOC-003 sections 4-5)
- [ ] No typographic symbols in headings or code blocks
- [ ] Status indicators use text tags: `[OK]`, `[FAIL]`
- [ ] Unordered lists use `-` marker strictly
- [ ] Code blocks specify language or `text`/`bash` fallback
- [ ] Stack signature present in root files
- [ ] Diagrams use whitelist characters only (STD-DOC-003 section 6.2)

---

## 13. [CORE] Profile Requirements

Every Profile must include the following sections. If a section is not applicable (e.g., a project without syntax highlighting), it must state "Not applicable" with a justification.

The Profile Identity (name, project type, design language) is stated in the Profile header preamble and does not have a separate numbered section.

| # | Required Section | Content |
|---|-----------------|---------|
| P1 | Font Roles & Default Implementation | Concrete fonts mapped to each role |
| P2 | Typography Scale | Named tokens with size, weight, family, extras |
| P3 | Color Tokens | Semantic tokens with light/dark values + aliases |
| P4 | Syntax Highlighting Tokens | If applicable; otherwise "N/A" with justification |
| P5 | Spacing Scale | Named tokens with pixel/rem values |
| P6 | Card Archetypes | At least one archetype with border, background, padding, typography rules |
| P7 | Component Token Map | Archetype-level token mapping (mandatory); element-level mapping (optional, see below) |
| P8 | Prohibited Patterns | Product-specific patterns to flag in linting |
| P9 | CSS Custom Properties | Copy-paste `:root` / `.dark` block |
| P10 | Enforcement Rule | Automated rule template (ESLint, Stylelint, or equivalent) |
| P11 | Agent Context | Compressed context for AI code generation (see Section 11.5) |

In addition to P1-P11, every Profile must include:

- **Integration Pattern Statement**: Which Token Integration Pattern (A, B, or C from Section 4.5) the Profile uses, with the corresponding theme configuration or stylesheet structure
- **Adoption Phase Statement**: Which Adoption Level (Phase 1, 2, or 3 from Section 10.4) the project is currently targeting, and the planned escalation timeline

**P7 granularity levels:**

The Component Token Map supports two levels of detail. A Profile must include at least Level 1; Level 2 is optional.

**Level 1: Archetype Mapping (mandatory).** Maps each card archetype to the typography and color tokens it uses, without enumerating individual elements. This is compact and maintainable.

Example:
```markdown
| Archetype | Typography Tokens | Color Tokens | Spacing Tokens |
|-----------|-------------------|-------------|----------------|
| Terminal | --text-label, --text-badge, --text-section, --text-code | --terminal-accent, --neuro-brand, --semantic-violet | --space-xs, --space-sm, --space-md |
| Content | --text-h1, --text-h2, --text-h3, --text-body, --text-body-sm | foreground, muted-foreground, --star-color | --space-md, --space-lg, --space-xl |
| Stat | --text-code, --text-badge | foreground, muted-foreground | --space-sm, --space-md |
```

**Level 2: Element Mapping (optional).** Maps individual UI elements to specific tokens. This is useful for large projects with dedicated platform teams, but impractical for small teams because it grows linearly with the number of UI elements and requires continuous maintenance. If maintained manually, Level 2 maps often become stale within weeks.

A Profile that chooses Level 2 should also provide a mechanism for keeping the map in sync (e.g., a script that extracts token usage from component code, or a design token tool that generates the map from Figma Tokens). Without such a mechanism, Level 2 is not recommended.

### 13.1. Profile Validation Checklist

Before a Profile is approved, verify it satisfies every Core constraint. Each item below maps to a Core section:

- [ ] **Header**: Profile ID, design language, and project type are stated in the Profile preamble
- [ ] **Integration Pattern**: Integration Pattern Statement present (Section 4.5); theme configuration or stylesheet structure provided
- [ ] **Adoption Phase**: Adoption Phase Statement present (Section 10.4); current phase and escalation timeline documented
- [ ] **P1 Font Roles**: At least 2 roles defined (Core Section 3.1); each role has requirements and a default implementation
- [ ] **P2 Typography Scale**: 5-12 levels defined (Core Section 3.2); each level has size, weight, family, extras; scale range matches project context
- [ ] **P3 Color Tokens**: All tokens use semantic names (Core Section 4.1); every interface token has light and dark variants (Core Section 4.2); aliases resolve to primary tokens (Core Section 4.3); no hardcoded colors in the Profile's own examples
- [ ] **P4 Syntax Highlighting**: If applicable, all minimum roles defined (Core Section 5); if not applicable, "N/A" stated with justification
- [ ] **P5 Spacing Scale**: 4-8 levels defined (Core Section 6.1); scale range matches project context
- [ ] **P6 Card Archetypes**: At least 1 archetype defined (Core Section 7.1); each archetype specifies border, background, padding, typography rules, content scope
- [ ] **P7 Component Token Map**: Archetype-level mapping provided (mandatory Level 1); element-level mapping is optional (Level 2) and only recommended if a sync mechanism exists
- [ ] **P8 Prohibited Patterns**: Profile-specific patterns listed with violation type and replacement; patterns cover the Profile's own token replacements
- [ ] **P9 CSS Custom Properties**: Complete `:root` and `.dark` blocks provided; all tokens from P1-P5 are present
- [ ] **P10 Enforcement Rule**: Automated rule template provided (Core Section 10.3); rule covers patterns from P8
- [ ] **P11 Agent Context**: Compressed context fits within 3500 characters (compression via short codes allowed); includes all typography, color, and spacing tokens; includes [C]-level rules; no prose or rationale (Core Section 11.5); auto-generation script provided (mandatory in Phase 3, optional in Phase 1-2)
- [ ] **Cross-cutting**: No framework bindings in normative sections (bindings allowed only in "Default Implementation" subsections and marked as informational); Profile-specific rules do not contradict Core constraints; SVG-only icon standard (Core Section 8); Markdown compliance (Core Section 9)

---


## 14. Profile Example Location (moved to companion file)

> The Terminal Dashboard example Profile (P1-P11, previously §14-§26
> in this file) has been moved to the companion file
> `DESIGN-001-profile-terminal-dashboard.md` in v3.1.0 to bring this
> standard under the 1500-line hard cap (W11 CRITICAL closure).
>
> In v3.1.1, §19 Card Archetypes was further extracted from the profile
> companion to `DESIGN-001-profile-cards.md` to bring the profile file
> under the 1000-line soft cap (W11 soft warning closure). References to
> "§19" or "[PROFILE P6] Card Archetypes" resolve to that sub-companion.

> All cross-references to "STD-DESIGN-001 §N" where N is in 14-26
> resolve to that companion file. Section numbers are preserved
> verbatim — no renumbering was performed, so existing citations
> (in A11Y-001, ARCH-002, FE-001, etc.) remain stable.

> See §13 (Profile Requirements) for the structural skeleton that any
> Profile must follow, and §13.1 (Profile Validation Checklist) for
> the acceptance criteria. The Terminal Dashboard example in the
> companion file is one fully populated instance of that structure.

For convenience, the companion file's section-to-P mapping:

| Document Section (in companion file) | P-Section | Content |
|-------------------------------------|-----------|---------|
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
| 25 | -- | Animation Tokens (P12, added in v3.0.0) |
| 26 | -- | Breakpoint Tokens (P13, added in v3.0.0) |

---
## 26A. Known Issues and Proposed Solutions

This section documents discovered inconsistencies, missing content, and proposed corrections. Each issue has an ID, status, and proposed action. Issues resolved in the current version are marked `[RESOLVED]`; outstanding issues are marked `[OPEN]`.

### DES-001 `[RESOLVED in v3.0.1]` — Stale version references to STD-DOC-003 and STD-DOC-002

**Problem:** Prior to v3.0.1, the header `Related:` line and §8 referenced "No-Unicode Policy v2.1" (STD-DOC-003), and §9 referenced "Markdown Standard v2.2" (STD-DOC-002). The actual versions at the time of audit were STD-DOC-003 v2.3.0 and STD-DOC-002 v2.3.0.

**Resolution:** Header `Related:` line updated to cite v2.3 for both standards. §8 updated to "No-Unicode Policy v2.3". §9 updated to "Markdown Standard v2.3".

### DES-002 `[RESOLVED in v3.0.1]` — Standard not registered in STD-META-001

**Problem:** STD-DESIGN-001 was not present in the ID registry (STD-META-001 §4). The `DESIGN` domain was not listed in §3 (Reserved Domains). A shipped, actively-maintained standard had no registered ID — citations in other standards (e.g., STD-FE-001 §11) referenced an ID that the registry did not recognize.

**Resolution:** STD-META-001 v1.2 added `DESIGN` to §3 and created §4.11 "Design System (DESIGN)" with the `STD-DESIGN-001` entry (v3.0.0 -> v3.0.1, [C]+[W], ACTIVE). Cross-reference between STD-META-001 and STD-DESIGN-001 is now bidirectional.

### DES-003 `[OPEN]` — Cross-References section omits STD-META-001

**Problem:** §28 (Cross-References) lists STD-FE-001, STD-DOC-002, STD-DOC-003, and ZAI-ARCH-002, but does not list STD-META-001 — the registry that defines this standard's ID. This breaks the bidirectional link convention: STD-META-001 now references STD-DESIGN-001 (after DES-002), but STD-DESIGN-001 does not reference back.

**Proposed solution:** Add a row to §28: `STD-META-001 | Standard ID System: registers this standard's ID (STD-DESIGN-001) in §4.11`.

### DES-004 `[OPEN]` — `ZAI-ARCH-002` is a skill, not a standard

**Problem:** §28 Cross-References lists `ZAI-ARCH-002 | Anti-Monolith Skill`. The `ZAI-ARCH-` prefix follows the skill ID convention, not the `STD-` standard convention. The Cross-References section of a standard should reference other standards (with `STD-` IDs); skills are operational artifacts, not governance documents.

**Proposed solution:** Either (a) move the ZAI-ARCH-002 reference to a new "Related Skills" section separate from Cross-References, or (b) annotate the existing row with "(skill, not standard)" to make the distinction explicit. Option (b) is the lighter touch; option (a) is the cleaner separation. Decision deferred to project owner.

### DES-005 `[OPEN]` — Profile example uses project-specific tokens without flagging them as illustrative

**Problem:** §13 "Profile Requirements" and §14-24 show a concrete "Terminal Dashboard" Profile with specific tokens (`--terminal-accent`, `--neuro-brand`, `--star-color`, `--semantic-violet`). The header §13 header says "(EXAMPLE)" but the individual sections (§15-§24) do not repeat the disclaimer. A reader landing on §16 (Color Tokens) directly may mistake the specific token names for Core requirements.

**Proposed solution:** Add a one-line note at the top of each P1-P11 section: "This section shows the Terminal Dashboard example Profile. Values are illustrative; substitute your project's values." Alternatively, wrap the entire Profile example in a single `<details>` block so its illustrative nature is structurally obvious.

**Update (v3.1.0):** The Terminal Dashboard example Profile has been moved to the companion file `DESIGN-001-profile-terminal-dashboard.md`. The companion file's header now explicitly states "Type: Reference appendix, NOT a separate standard" and "Status: ILLUSTRATIVE EXAMPLE", which structurally addresses DES-005 at the file level. Per-section disclaimers inside the companion file are still recommended for direct section landings; tracked here as still-OPEN until those per-section notes are added in a future minor version.

### DES-006 `[RESOLVED in v3.1.0]` — File exceeded 1500-line hard cap (W11 CRITICAL)

**Problem:** DESIGN-001-design-system.md v3.0.1 was 1781 lines, exceeding the 1500-line hard cap defined in `verify-id-graph.js` W11. This was the only CRITICAL warning in the entire standards repo and the only remaining W11 CRITICAL across all 4 repos.

**Resolution:** In v3.1.0, the Terminal Dashboard example Profile (sections §14-§26, ~960 lines) was moved to a companion file `DESIGN-001-profile-terminal-dashboard.md`. The main standard file is now 816 lines (under both the 1000-line soft cap and the 1500-line hard cap). The companion file is 1047 lines (over the 1000-line soft cap, but under the 1500-line hard cap — acceptable for a reference appendix that is not normative). W11 CRITICAL warning for DESIGN-001 closed; W11 soft warnings remain for the companion file and for one other long reference file in the standards tree (sandbox hooks cookbook, ~1011 lines — tracked separately, out of scope for this standard).

**Implementation notes:**
- Section numbers preserved verbatim in the companion file (no renumbering) so all external cross-references to "STD-DESIGN-001 §N" (N in 14-26) remain stable.
- The companion file has no `> ID:` blockquote header, so `verify-id-graph.js` does not pick it up as a separate ID declaration. It is treated as a reference document, not a normative standard.
- The companion file matches the `<DOMAIN>-<NNN>-<name>.md` naming pattern (DESIGN-001-profile-terminal-dashboard.md), so W15 (naming drift) does not fire.
- The companion file has no §XA Known Issues section because it is not normative; W12 does not fire on it.

---

## 27. Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-06 | Initial version |
| 1.0.1 | 2026-06 | Font families restructured: roles with requirements separated from default implementation |
| 1.1.0 | 2026-06 | Removed all framework-specific bindings; Tailwind/Prism/Lucide/TerminalFrame/globals.css abstracted |
| 2.0.0 | 2026-06 | **Architectural split**: Core (universal rules, Sections 3-13) separated from Profile (product-specific values, Sections 14-24). Profile system introduced (Section 13). Terminal Dashboard as default Profile and editable template (PROFILE-TERMINAL-001). Profile creation process documented (Section 11.4). Agent context generation documented (Section 11.5). Concrete agent context example added (Section 24) |
| 2.1.0 | 2026-06 | **Universality polish**: removed all remaining framework bindings from normative Core text; added Profile Validation Checklist (Section 13.1); expanded card archetype treatment options (Section 7.1) to include glass/gradient/glow/elevated; added spacing and typography scale range context notes (Sections 3.2, 6.1) for immersive and editorial projects; replaced hardcoded section references with P-references (Section 11.4); added Profile-specific disclaimers to Component Token Map, Prohibited Patterns, ESLint Rule, and Card Rules sections; removed "Built with" footer (framework binding); added note about Profile versioning when stored separately; updated Section 2.3 diagram to remove project-specific labels; clarified that enforcement patterns are Profile-specific (Section 10.3); updated Profile header from "PROFILE: Terminal Dashboard" to "PROFILE: Terminal Dashboard (EXAMPLE)" |
| 2.2.0 | 2026-06 | **Practical adoption**: added Adoption Levels with three-phase enforcement (Section 10.4); added Token Integration Patterns with three patterns (Theme Extension, CSS Modules, Vanilla CSS) to eliminate inline style anti-pattern (Section 4.5); required auto-generation script for Agent Context P11 instead of manual writing (Section 11.5); split P7 Component Token Map into mandatory Level 1 (archetype mapping) and optional Level 2 (element mapping); added CSS Modules mapping example (Section 15.5); added neutral/surface token template note for non-terminal Profiles (Section 16.4); replaced all `style={{}}` examples with Pattern A theme extension classes; added Integration Pattern and Adoption Phase statements to Profile requirements and Validation Checklist; updated Prohibited Patterns table to show Pattern A replacements |
| 2.3.0 | 2026-06 | **Adoption polish**: added [W+] level in Phase 2 for spacing/typography CI visibility with persistent count reports, preventing debt shock at Phase 3 transition; made P11 auto-generation script optional in Phase 1-2 and mandatory only in Phase 3 (reduces barrier for small teams); clarified that Pattern B and Pattern C are equal alternatives to Pattern A when theme extension is unavailable (CRA without eject, locked build pipelines); replaced `bg-muted/50` Stat Card background with `--muted-alpha` CSS custom property using `color-mix()` to satisfy Core 4.4 compliance; increased P11 character limit from 2000 to 3500 and added compression via short-code mapping |
| 2.3.1 | 2026-06 | **Edge case polish**: added `color-mix()` browser compatibility note with cascade-based fallback pattern (Safari 15, legacy browsers); added [W+] CI integration example with GitHub Actions workflow showing persistent debt count in PR summaries; added P11 compressed variant example with short-code mapping table showing 30-40% size reduction |
| 3.0.0 | 2026-06 | **Stack and design universality**: added Pattern D CSS-in-JS (Styled Components, Emotion, vanilla-extract, Stitches) to Section 4.5; added Interactive/Canvas card archetype (Section 7.1 archetype table, Section 19.4); added P12 Animation Tokens (duration, easing, dual CSS+JS registration); added P13 Breakpoint Tokens (responsive layout consistency); made Pattern A framework-agnostic (utility-first CSS, not just Tailwind); added UnoCSS/Windi CSS configuration references; added Section 0 Scope with explicit Covers / Does NOT Cover / Boundary Rule |
| 3.0.1 | 2026-06 | **Cross-reference sync**: updated header `Related:` to cite No-Unicode Policy v2.3 (was v2.1) and Markdown Standard v2.3 (was v2.2). Updated §8 in-body reference to STD-DOC-003 v2.3. Updated §9 in-body reference to STD-DOC-002 v2.3. Added §26A Known Issues documenting DES-001 through DES-005. |
| 3.1.0 | 2026-06-18 | **W11 CRITICAL closure (file split)**: moved Terminal Dashboard example Profile (§14-§26, ~960 lines) to companion file `DESIGN-001-profile-terminal-dashboard.md`. Main file reduced from 1781 -> 816 lines (under both 1000-line soft cap and 1500-line hard cap). Section numbers preserved verbatim in companion file — no renumbering, all cross-references stable. Added §14 pointer block in main file. Added `Companion file:` line to header. Added DES-006 (RESOLVED in v3.1.0) to §26A. Updated DES-005 with v3.1.0 progress note (file-level disclaimer added in companion header; per-section disclaimers still tracked as OPEN). |

---

## 28. Cross-References

| Standard | Relationship |
|----------|-------------|
| **STD-FE-001** | **Frontend Development: governs how React components consume design tokens. Section 11 delegates to this standard for all visual token rules; this standard takes precedence on token names, values, and enforcement.** |
| STD-DOC-002 | Markdown Standard: formatting rules for documentation files |
| STD-DOC-003 | No-Unicode Policy: character rules, icon standard, sanitization |
| STD-META-001 | Standard ID System: registers this standard's ID (STD-DESIGN-001) in §4.11 (added in META-001 v1.2 per DES-002) |
| ZAI-ARCH-002 | Anti-Monolith Skill: auto-decomposition when thresholds exceeded; Section 2 limits and Section 9 exception ceilings in STD-FE-001 are aligned with this skill |

**Companion file:** `DESIGN-001-profile-terminal-dashboard.md` — Terminal Dashboard example Profile (§14-§26, moved to companion in v3.1.0 for W11 CRITICAL closure). This is a reference appendix, not a separate standard; it has no `STD-` ID of its own.

**Scope and applicability:** See Section 0 for the authoritative scope definition (Covers / Does NOT Cover / Boundary Rule). The design token layer applies to any DOM-based UI with CSS; React-specific constraints are governed by STD-FE-001; non-DOM environments require documented adaptation.
