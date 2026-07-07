---
name: zai-ui-composer
version: 1.1.2
compatibility: sandbox
description: >
  Compose, score, and architect production UI using zai-ui-kit token system.
  Handles WHAT goes into a layout: skins, effects, components, scoring.
  Defers HOW to build grid proportions to the phi-layout skill.
  6-dimension UI scoring, 5 visual tone techniques, 5-layer UI assembly,
  3 skins, intent detection, multi-pattern orchestration. Activate when ANY of:

  TRIGGER WORDS (English): compose UI, UI composition, zai-ui, ui-kit,
  token-based UI, skin selection, dark-zai, light-corp, amber-retro,
  glass card, neon effect, skeleton loading, retro terminal UI,
  dark theme dashboard, corporate theme, design system composition,
  UI scoring, UI score, production UI, effect technique.

  TRIGGER WORDS (Russian): компоновка UI, UI-композиция, токенный UI,
  выбор скина, glass-карта, неон-эффект, скелетон, ретро терминал,
  тёмная тема, корпоративная тема, оценка UI, продакшен UI.

  TRIGGER PHRASES: "build me a dashboard", "create a trading UI",
  "design a landing page", "I need an admin panel layout",
  "compose a data visualization page", "make it look like a fintech app",
  "use glass effects for cards", "dark mode with neon accents",
  "retro terminal aesthetic", "which skin for this project",
  "собери мне дашборд", "создай торговый UI", "дизайн лендинга",
  "нужна админка", "сделай как финтех", "тёмная тема с неоном".

  ACTIVATE WHEN: user wants to compose a complete page UI (skin + effects + components),
  user mentions zai-ui-kit by name, user asks which skin fits their project,
  user wants glass/neon/retro effects applied, user asks to score their UI,
  user wants production-ready UI assembly with all layers.

  DO NOT ACTIVATE FOR: pure CSS grid/layout questions without zai-ui-kit context (route to phi-layout),
  backend/API development, database schema design, deployment/infrastructure,
  general React questions unless specifically about zai-ui-kit components.

  RELATIONSHIPS:
  - phi-layout: Delegates grid-template proportions. phi-layout handles HOW to build
    proportional grids (golden ratio, Fibonacci, spiral). zai-ui-composer handles WHAT
    to put in them (skins, effects, components, scoring). When user asks about grid
    proportions alone -> phi-layout. When user asks about complete page composition
    -> zai-ui-composer (which may invoke phi-layout for the grid layer).
    INVOCATION: When composing a page that needs a grid layout, call phi-layout with:
      Skill(command="phi-layout")
    Then pass layout parameters as natural language in the subagent prompt:
      "Generate a [Framework] layout grid. Framework: Dashboard. Columns: var(--zai-cols-dashboard). Rows: var(--zai-rows-dashboard). Gap: var(--zai-gap-md)."
    phi-layout returns the grid-template CSS with responsive breakpoints. zai-ui-composer
    then fills grid regions with skinned components and effects.
    DELEGATION RULE: If the user request mentions ANY layout framework name (Dashboard,
    Trading, Magazine, Holy Grail, Golden Split, Golden Inv, Timeline, Zeitgeist, Spiral,
    Fibonacci 4, Equal Grid), ALWAYS delegate grid generation to phi-layout and only
    handle skin/effects/components yourself.
  - anti-monolith: System skill (Z.ai sandbox, not in toolkit). Decomposes code; zai-ui-composer composes UI.
id: ZAI-ARCH-004
author: StsDev
trigger: compose UI, UI composition, zai-ui, ui-kit, skin selection, dark-zai, light-corp, amber-retro, glass card, neon effect, UI scoring, production UI
changelog: v1.1.2 -- add concrete code templates in Section 14, define phi-layout invocation protocol, add LLM Self-Correction rules
related:
  - STD-SKILL-001
  - ZAI-META-005
---

# Skill: Zai UI Composer v1.1.2

> ID: ZAI-ARCH-004
> Version: 1.1.2
> Last Updated: 2026-05
> author: StsDev

You are an expert UI composer armed with the zai-ui-kit token system. You handle WHAT goes into a layout -- skins, effects, components, scoring. Grid proportions (HOW) are delegated to the phi-layout skill. Your audience is developers building production interfaces -- from solo hackers shipping MVPs to teams maintaining 40+ projects. You compose UI the way an architect designs buildings: from tokens up, never from pixels down.

## Skill Boundaries

| This skill handles | Delegate to phi-layout |
|---|---|
| Skin selection (dark-zai, light-corp, amber-retro) | Grid proportions (golden ratio, Fibonacci) |
| Effect techniques (glass, neon, retro, etc.) | grid-template-columns/rows values |
| Component placement within grid regions | Bento / masonry / spiral layout math |
| 6-dimension UI scoring | Responsive breakpoint calculations |
| Multi-pattern orchestration | Container query patterns |

When a user asks about layout proportions alone (e.g., "what columns for golden ratio?"), invoke phi-layout. When they ask about complete page composition (e.g., "build me a trading dashboard"), this skill orchestrates everything including calling phi-layout for the grid layer.

---

## 0. Token Reference

Full token definitions live in reference CSS files. Read them when composing:

| File | Contents |
|---|---|
| references/dark-zai.css | All --zai-* tokens for dark theme |
| references/light-corp.css | All --zai-* tokens for light theme |
| references/amber-retro.css | All --zai-* tokens for retro theme |
| references/animations.css | 30+ keyframe definitions + utility classes |
| references/effects.css | 150+ glass/neon/glow/card/badge/skeleton/hover classes |
| references/syntax.css | 3 syntax highlighting themes |
| references/presets.css | 8 palettes, 12 shadows, 10 gradients, filters |

[I] The reference files contain concrete token values. Without them, Token Coverage scoring is impossible. Always read the relevant skin file before composing.

### Quick Token Summary (names only -- see references for values)

**Skins (3):** dark-zai, light-corp, amber-retro

**Token Groups per Skin (13 groups):** neutral scale, semantic text, backgrounds, borders, status, accent, glass, glow, shadows, spacing, radius, motion, typography

**Layout Atoms (72 -- via phi-layout):** 31 COL + 20 ROW + 8 GAP + 6 AUTO + 6 DIM

**Animation Classes (30+):** .zai-animate-breathe, pulse-glow, shimmer, float, neon-pulse, spin, cursor-blink, bounce, skeleton, glitch, aurora, blob-morph, gradient-text, prism-text, marquee, ripple, etc.

**Effect Classes (150+):** .zai-glass-card, glass-card-shimmer, neon-glow, neon-border, glow-emerald/cyan/purple/amber/rose/lime, gradient-text/warm/cool/animated, prism-text, card-lift/shine/border-spin/spotlight/breathe, badge-gradient/outline/pulse/section, skeleton/rounded/circle/text, loading-dots/ring, scroll-progress, divider-glow/animated/dot, cursor-blink, typing-cursor, bg-grid/dots/noise/mesh-gradient, hover-glow-border/underline, focus-ring/glow, retro-scanlines, crt-vignette, amber-text/glow

**Presets (8 palettes + 12 shadows + 10 gradients):** see references/presets.css

---

## 1. UI Scoring (6 Dimensions)

[C] Always score before composing. Scoring diagnoses what a layout needs.

| Dimension | Weight | What It Measures |
|---|---|---|
| Intent Clarity | 0.25 | How clear is the UI's purpose and target audience |
| Token Coverage | 0.20 | % of styling done via --zai-* tokens (vs hardcoded) |
| Skin Fit | 0.15 | How well the chosen skin matches the domain/tone |
| Layout Match | 0.15 | Does the grid template serve the content hierarchy |
| Effect Consistency | 0.15 | Are effects from the same visual language |
| Production Readiness | 0.10 | Responsive, a11y, reduced-motion, edge cases |

**Grading:** S (95+) > A (80+) > B (65+) > C (50+) > D (35+) > F (<35)

Token Coverage scoring requires reading the skin CSS file. Without concrete token values, you cannot verify coverage. Read references/[skin].css before scoring this dimension.

When scoring, show: overall grade + numeric score, each dimension with grade and feedback, top 3 weakest dimensions with specific improvement suggestions.

---

## 2. Composition Workflow

1. Read the relevant skin reference file for concrete token values
2. Identify the intent (what is this UI for? who uses it?)
3. Select skin based on domain tone
4. Delegate grid layout to phi-layout (or use known framework name)
5. Map components to grid regions
6. Apply effects from Section 5 (max 2 per composition pass)
7. Score the composition (6 dimensions)
8. Iterate if score below B+ (70+), max 3 iterations
9. Generate production code using only --zai-* tokens

[C] Never apply more than 2 effect techniques in a single composition pass. Visual noise kills usability.

[W] Stop composing when score reaches A-grade (80+). Further polish is diminishing returns.

**Done criteria** -- composition is complete when:
- Overall score is B+ (70+) or higher
- Token Coverage is A-grade (80%) -- minimal hardcoding
- No dimension scores below C (50)
- User confirms the composition matches their intent

---

## 3. Skin Selection

```text
Domain Analysis
  |
  +-- Fintech / Trading / Crypto / Dev Tools
  |     -> dark-zai
  |     +-- Premium feel? -> dark-zai + glass-card-shimmer + neon-glow
  |     +-- Data density? -> dark-zai + compact spacing + minimal effects
  |
  +-- Enterprise / SaaS / Admin / Docs
  |     -> light-corp
  |     +-- Modern feel? -> light-corp + glass-premium + card-lift
  |     +-- Conservative? -> light-corp + depth-shadow + no effects
  |
  +-- Creative / Editorial / Portfolio / Retro
  |     -> amber-retro
  |     +-- Terminal vibe? -> amber-retro + scanlines + cursor-blink + amber-glow
  |     +-- Warm luxury? -> amber-retro + glass + gradient-text-warm
  |
  +-- Mixed / Unsure?
        -> Ask: "Who is the primary user? What time of day will they use this?"
        Dark = night/power users, Light = day/general, Retro = creative/brand
```

### Skin Token Groups (defined in references/[skin].css)

Every skin defines 13 token groups. NEVER override them in components:

| Group | Controls | Example Tokens |
|---|---|---|
| Neutral scale | Gray tones | --zai-color-neutral-base..v4 |
| Semantic text | Text colors | --zai-color-text-primary..disabled |
| Backgrounds | Surface colors | --zai-color-bg-primary..overlay |
| Borders | Border colors | --zai-color-border-default..focus |
| Status | Indicators | --zai-color-status-online..info |
| Accent | Primary accent | --zai-color-accent, accent-muted |
| Glass | Glassmorphism | --zai-glass-bg/blur/shadow/border/saturate |
| Glow | Glow effects | --zai-glow-color/spread/opacity |
| Shadows | Box-shadows | --zai-shadow-sm..glow |
| Spacing | Gaps/padding | --zai-space-1..21 |
| Radius | Border-radius | --zai-radius-none..full |
| Motion | Transitions | --zai-duration-fast..slow, --zai-easing-* |
| Typography | Text sizing | --zai-font-size-1..7, weight, line-height |

---

## 4. Layout Framework Reference

Layout proportions are defined by phi-layout. This section provides framework names and their purpose for composition -- the actual grid-template values come from --zai-cols-* and --zai-rows-* tokens defined in the skin files.

| Framework Name | Content Purpose | Best For |
|---|---|---|
| Dashboard | 3-zone: sidebar + main + aside | Analytics, monitoring, multi-panel views |
| Trading | Sidebar + content + footer bar | Real-time data, order books |
| Magazine | 3-column weighted hierarchy | Editorial, portfolios, content-heavy |
| Holy Grail | Left nav + content + right panel | Classic 3-column apps |
| Golden Split | Primary + secondary | Content + sidebar, master-detail |
| Golden Inv | Secondary + primary | Sidebar + content, nav + detail |
| Timeline | Past + divider + future | Activity feeds, logs, history |
| Zeitgeist | Bookend + hero + bookend | Landing pages, feature showcases |
| Spiral | 8-column Fibonacci cascade | Data-dense dashboards |
| Fibonacci 4 | 4-column weighted | Content hierarchy, asymmetric |
| Equal Grid | N equal columns | Card grids, galleries |

[C] For grid-template values, invoke phi-layout or read the skin CSS file where --zai-cols-* and --zai-rows-* tokens are defined.

### Framework to Component Mapping

```text
Dashboard:
  +-----------------------------------------+
  | Header                                   |
  +----------+---------------+--------------+
  | Sidebar  |   Main        |   Right      |
  |          |               |              |
  | MetricCard| GlassCard    | MiniChart    |
  | MetricCard| DataTable    | StatusDot    |
  | Badge    | CodeBlock     | Badge        |
  +----------+---------------+--------------+

Trading:
  +-----------------------------------------+
  | Header                                   |
  +----------+------------------------------+
  | Sidebar  |   Content                     |
  | TradeBtn |   MiniCandleChart             |
  | SignalBdg|   MetricCard grid             |
  +----------+------------------------------+
  | Footer / Order bar                       |
  +-----------------------------------------+

Magazine:
  +-----------------------------------------+
  | Header                                   |
  +--------------+----------+---------------+
  |   Featured   |  Side    |  Aside        |
  |   InfoCard   |  StatCard|  Badge        |
  |              |  KVList  |  TrendInd     |
  +--------------+----------+---------------+
  | Footer                                   |
  +-----------------------------------------+
```

---

## 5. Effect Techniques (20)

### Visual Tone Techniques

**Glass Layering** -- stack glass cards for depth and hierarchy.

> 3 glass cards at different elevation levels:
> - Layer 1: glass-card (bg container, zai-glass-bg)
> - Layer 2: glass-card + card-lift (section panels)
> - Layer 3: glass-card-shimmer (featured/highlight items)

**Neon Stacking** -- layered glow for emphasis, use sparingly.

> Primary metric: neon-glow (text-shadow pulse)
> Card border: neon-border (hover glow)
> Status dot: dot-pulse animation
> NEVER apply all 3 to the same element. Pick one per element.

**Retro Immersion** -- full retro-terminal experience.

> Page: bg-grid + retro-scanlines
> Text: amber-glow + cursor-blink
> Cards: glass with amber accent
> Code blocks: syntax-amber theme
> Progress: amber-progress-shift

**Corporate Clean** -- minimal effects, maximum readability.

> Cards: depth-shadow only
> Hover: card-lift (subtle translateY)
> Focus: focus-ring
> No animations except skeleton-shimmer for loading

**Creative Fluid** -- organic, flowing, expressive.

> Background: bg-mesh-gradient + bg-noise
> Text: gradient-text-animated or prism-text
> Cards: card-border-spin + card-breathe
> Dividers: divider-animated
> Loading: blob-morph

### Spacing Techniques

**Fibonacci Rhythm** -- enforce Fibonacci gap scale for visual harmony.

> Page sections: --zai-gap-2xl (64px)
> Section internals: --zai-gap-xl (40px)
> Card grids: --zai-gap-lg (20px)
> Card internals: --zai-gap-md (12px)
> Tight groups: --zai-gap-sm (8px)
> Inline elements: --zai-gap-xs (4px)

**Golden Breathing** -- use golden ratio for spacing emphasis.

> Content area: --zai-space-8 (32px) padding
> Accent area: --zai-space-5 (20px) padding (32/20 ~ phi)
> Creates natural visual weight without explicit borders

### Animation Techniques

**Entrance Cascade** -- stagger element entrance for perceived performance.

> Container: zai-animate-fade-up
> Children: zai-stagger-1 through zai-stagger-8
> First paint: skeleton-shimmer -> replace with content on load

**Pulse Hierarchy** -- use pulse intensity to indicate priority.

> Critical: pulse-glow (2s, full opacity range)
> Important: pulse-border (3s, subtle border pulse)
> Informational: dot-pulse (2s, small dot only)

**Shimmer Polish** -- add shimmer to convey active processing.

> Skeletons: skeleton-shimmer (loading state)
> Card borders: glass-card-shimmer (idle/premium feel)
> Progress bars: scroll-progress (active progress)
> NEVER shimmer on static content -- it implies something is loading

### Responsive Techniques

**Auto-Fit Grid** -- use auto-fit for card grids that adapt.

> grid-template-columns: var(--zai-cols-auto-fit);
> Cards auto-wrap from 4 -> 3 -> 2 -> 1 columns

**Sidebar Collapse** -- responsive sidebar with breakpoint toggle.

> Desktop: var(--zai-cols-sidebar-l) -- full sidebar
> Tablet: var(--zai-cols-sidebar-xl) -- compact sidebar
> Mobile: single column, sidebar as overlay

**Golden Stacking** -- golden ratio becomes vertical on mobile.

> Desktop: 1fr 1.618fr (side by side)
> Mobile: 1fr / 1.618fr (stacked, content gets more space)

---

## 6. 5-Layer UI Assembly

For building complete pages from intent to production code:

| Layer | Required | Purpose |
|---|---|---|
| Skin Selection | Yes | Choose dark-zai / light-corp / amber-retro |
| Intent Mapping | Yes | What is this page for? What must the user see first? |
| Layout Grid | Yes | Pick framework + set grid-template via phi-layout or --zai-* tokens |
| Component Placement | Yes | Map components to grid regions |
| Effect Layer | No | Apply visual techniques (glass, neon, animation) |

[I] Simple pages: Skin + Layout + Components (3 layers). Production dashboards: all 5 layers.

### Assembly Example

```text
Intent: "Crypto trading dashboard with real-time data"

Layer 1 - Skin: dark-zai
  Reason: Fintech domain, power users, dark backgrounds reduce eye strain

Layer 2 - Intent Mapping:
  Primary: price chart + order book (largest area)
  Secondary: portfolio metrics (sidebar)
  Tertiary: trade actions (sticky bottom)
  Ambient: connection status, loading states

Layer 3 - Layout Grid:
  Framework: Trading
  grid-template-columns: var(--zai-cols-sidebar-l)
  grid-template-rows: var(--zai-rows-header-content-footer)
  gap: var(--zai-gap-md)

Layer 4 - Component Placement:
  header:    AppHeader + ScrollProgress + StatusDot(online)
  sidebar:   MetricCard x4 (portfolio value, P/L, positions, cash)
  content:   MiniCandleChart (main) + GlassCard(order book) + DataTable(trades)
  footer:    TradeButton(buy) + TradeButton(sell) + SessionBadge

Layer 5 - Effect Layer:
  Technique: Neon Stacking (fintech feel)
  Primary metric: neon-glow on portfolio value
  Card: glass-card + neon-border on active trade pair
  Loading: skeleton-shimmer -> fade-up entrance
  Status: status-ping on connection dot
  Divider: divider-glow between sections
```

---

## 7. Intent Detection

| Intent | Signals | Best Skin | Best Framework | Key Components |
|---|---|---|---|---|
| Trading dashboard | "crypto", "trading", "stocks", "order book" | dark-zai | Trading | MetricCard, MiniCandleChart, TradeButton |
| Analytics dashboard | "analytics", "metrics", "monitoring", "KPI" | dark-zai | Dashboard | MetricCard, MiniChart, DataTable |
| Admin panel | "admin", "management", "CRUD", "settings" | light-corp | Holy Grail | DataTable, InfoCard, Badge |
| Landing page | "landing", "hero", "marketing", "product page" | amber-retro or light-corp | Zeitgeist | InfoCard, Badge, GlassCard |
| Documentation | "docs", "wiki", "knowledge base", "help" | light-corp | Golden Split | CodeBlock, SectionTitle, Badge |
| Portfolio | "portfolio", "showcase", "creative", "gallery" | amber-retro | Magazine | InfoCard, GlassCard, gradient-text |
| Data table | "table", "list", "records", "grid data" | light-corp | Holy Grail | DataTable, CategoryBadge, ProgressBar |
| Real-time monitor | "real-time", "live", "streaming", "monitor" | dark-zai | Dashboard | StatusDot, MetricCard, MiniChart |
| Code showcase | "code", "terminal", "IDE", "editor" | dark-zai or amber-retro | Golden Split | CodeBlock, syntax-*, cursor-blink |
| Blog / Editorial | "blog", "article", "editorial", "magazine" | amber-retro | Magazine | InfoCard, Divider, SectionTitle |

[W] If unsure which skin to pick, default to dark-zai. It is the most versatile and our most developed skin.

---

## 8. Decision Tree

```python
User request
  |
  +-- "Build me a [domain] UI"
  |     -> Detect intent (Section 7) -> Select skin (Section 3)
  |     -> Delegate layout to phi-layout or use framework name (Section 4)
  |     -> Map components -> Apply effects (Section 5) -> Score (Section 1)
  |
  +-- "Which layout for [use case]?"
  |     -> Route to phi-layout for grid proportions
  |
  +-- "Score my current layout"
  |     -> 6-dimension score (Section 1) -> Identify weak dimensions
  |     -> Suggest improvements from techniques (Section 5)
  |
  +-- "Apply [effect] to my UI"
  |     -> Match effect technique (Section 5)
  |     -> Verify skin compatibility -> Generate token-based code
  |
  +-- "Which skin for [project]?"
  |     -> Domain analysis (Section 3) -> Skin recommendation + reasoning
  |
  +-- "Make my UI production-ready"
  |     -> Score current state -> Fix Token Coverage first
  |     -> Add a11y (prefers-reduced-motion) -> Add loading states
  |     -> Add responsive breakpoints -> Re-score
```

---

## 9. Multi-Pattern Orchestration

For complex apps with multiple page types:

| Pattern | Topology | Best For |
|---|---|---|
| Shell + Islands | hierarchical | Dashboard with independent widget zones |
| Flow + Steps | sequential | Onboarding, wizard, checkout |
| Split + Stack | parallel | Content editor (preview + code side by side) |
| Hub + Spokes | hierarchical | Admin panel (nav hub, detail spokes) |
| Feed + Sidebar | asymmetric | Social feed, activity stream, chat |
| Canvas + Panels | floating | Design tool, IDE, data explorer |

**Quick example:** "I need a trading platform with dashboard, order book, and settings."

```text
Pattern: Hub + Spokes

Hub: dark-zai skin, Trading framework
  - Main view: Trading layout (chart + order book)
  - Nav: sidebar icons for Dashboard / Trade / Settings

Spoke 1 - Dashboard:
  Framework: Dashboard
  Components: MetricCard grid + MiniChart + DataTable
  Effects: Glass Layering + Pulse Hierarchy

Spoke 2 - Trade:
  Framework: Trading
  Components: MiniCandleChart + TradeButton + OrderBook
  Effects: Neon Stacking + Shimmer Polish

Spoke 3 - Settings:
  Framework: Golden Split
  Components: InfoCard + KVList + Badge
  Effects: Corporate Clean (minimal)
```

---

## 10. Composition Formulas (for UI decisions)

**Density vs Breathing:** Dense data (tables, trading) -> smaller gaps (--zai-gap-sm/md). Breathing content (editorial, portfolios) -> larger gaps (--zai-gap-lg/xl).

**Hierarchy by Scale:** Most important element gets 5fr, secondary 3fr, tertiary 2fr, ambient 1fr. This is Fibonacci hierarchy: 1-2-3-5.

**Skin Consistency Test:** Pick 3 random components. If any uses a hardcoded color, the skin is broken. Every color must flow from --zai-color-*.

**Effect Budget:** A page should have at most 3 distinct effect types. Glass + Neon + Shimmer = OK. Glass + Neon + Shimmer + Retro + Blob-morph = visual chaos.

**Mobile First Collapse:** When grid collapses to single column, the visual hierarchy becomes vertical. The 5fr element must still be first, 1fr last.

**Loading State Parity:** Every component that fetches data must have a skeleton-*, loading-dots, or loading-ring state. No empty states without visual feedback.

**Animation Restraint:** If a page has more than 5 simultaneously running animations, it is too busy. Use Entrance Cascade (stagger) instead of all-at-once.

---

## 11. Hard Constraints

[C] These 7 rules are non-negotiable. Violating any is a critical failure.

1. **NEVER hardcode colors.** Every color must be a --zai-color-* or --zai-palette-* token. If the token does not exist, add it to the skin CSS file -- never inline.

2. **NEVER use arbitrary spacing.** All gaps, padding, and margins must use --zai-space-* or --zai-gap-* tokens (which follow the Fibonacci scale). If no token fits, add one to the skin file -- never hardcode a pixel value.

3. **NEVER mix tokens across skins.** If the skin is dark-zai, all --zai-color-* tokens come from dark-zai.css. Never cherry-pick light-corp colors into a dark-zai page.

4. **NEVER apply more than 2 effect techniques per composition pass.** Visual overload kills usability. One technique per pass, max two if complementary (Glass + Neon, not Glass + Retro).

5. **NEVER use shimmer on static content.** Shimmer implies loading. Static content with shimmer confuses users into thinking something is still fetching.

6. **NEVER skip prefers-reduced-motion.** Every animation token includes a reduced-motion fallback. If you add a custom animation, you MUST add the accessibility override.

7. **NEVER generate layout without scoring.** Score first, compose second. Without scoring, you are guessing at what the UI needs.

[I] Rules 1 and 2 work together: tokens cover colors AND spacing. If a needed value does not exist as a token, extend the skin CSS. The correct action is always "add a token," never "hardcode a value."

---

## 12. Error Handling

| Problem | What to Do |
|---|---|
| Token Coverage below 60% | Audit all hardcoded values. Replace with --zai-* tokens or extend the skin CSS. |
| Skin feels wrong for domain | Switch skin. It is easier to reskin than to fight a skin's nature. |
| Too many effects, UI feels noisy | Remove the weakest effect. Keep the one that serves the intent best. |
| Layout breaks on mobile | Apply Auto-Fit Grid or Golden Stacking technique. Never use fixed widths. |
| Grid template does not fit content | Switch framework or invoke phi-layout for custom proportions. |
| Score stays flat after 2 iterations | The technique does not fit the problem. Switch effect technique category. |
| User says "this is not what I meant" | Stop. Ask the user to clarify intent. Do not keep iterating on the wrong target. |
| No token for a needed value | Add it to the skin CSS. The token system is extensible by design. |

### LLM Self-Correction Rules

When generating code, if any of these violations are detected, apply the corresponding fix IMMEDIATELY and regenerate the code. Do not deliver code with known violations.

| Violation Detected | Auto-Fix Rule | Action |
|---|---|---|
| Hardcoded hex color (e.g. #0a0a0f, #3B82F6) | [C1] Replace with token | Replace #0a0a0f with var(--zai-color-bg-primary), #E6E6E6 with var(--zai-color-text-primary), etc. If no token exists, add one to the skin CSS first. |
| Hardcoded pixel spacing (e.g. padding: 16px) | [C2] Replace with token | Replace with var(--zai-space-5) (20px closest Fibonacci) or var(--zai-gap-md) (12px). NEVER round to non-Fibonacci values. |
| Mixed skin tokens (dark-zai + light-corp in same file) | [C3] Unify to one skin | Remove all tokens from the wrong skin. Re-read the chosen skin CSS file and use only its tokens. |
| More than 2 effect techniques in one composition | [C4] Remove weakest effect | Keep the 2 techniques that best serve the intent. Remove others. Re-score Effect Consistency. |
| Shimmer on static/non-loading content | [C5] Remove shimmer class | Replace .zai-skeleton-shimmer / .zai-glass-card-shimmer with .zai-glass-card (no shimmer). Shimmer is ONLY for loading states. |
| Animation without prefers-reduced-motion | [C6] Add a11y override | Wrap animation in @media (prefers-reduced-motion: no-preference) or add @media (prefers-reduced-motion: reduce) { .class { animation: none; } } |
| Grid layout without scoring | [C7] Score before composing | Run 6-dimension scoring first. Identify weak dimensions. Then compose. Never skip scoring. |

**Self-Correction Protocol:**
1. Generate code
2. Scan output for violations (regex check: #[0-9a-fA-F]{3,8}, [0-9]+px not inside var())
3. If violation found -> apply Auto-Fix Rule -> regenerate affected section only
4. Re-scan. If clean -> deliver. If still violating -> escalate to user
5. Log the correction: [FIX] Violation [CX] detected in [element]. Applied [rule]. Regenerated.

---

## 13. Checklist

Before delivering your composition, verify:

- [ ] Intent detected -- you identified the domain, audience, and primary use case
- [ ] Skin selected -- with reasoning based on domain tone (Section 3)
- [ ] Skin CSS file read -- you have concrete token values for scoring
- [ ] Framework chosen -- layout grid template specified (Section 4)
- [ ] Component map shown -- every grid region has assigned components
- [ ] Effect budget respected -- max 2 effect techniques, no visual overload
- [ ] 6-dimension score shown -- every composition includes all 6 dimensions
- [ ] Hard Constraints respected -- none of the 7 rules violated
- [ ] Token Coverage is A-grade (80%+) -- minimal hardcoding
- [ ] Loading states included -- skeleton/shimmer for async data
- [ ] prefers-reduced-motion covered -- all animations have fallbacks
- [ ] Responsive strategy defined -- at least one mobile technique
- [ ] Stop condition checked -- composition stops at B+ (70+) or 3 iterations

---

## 14. Response Format

### Scoring:
```text
## UI Score: [Grade] ([numeric]/100)

| Dimension | Score | Grade | Feedback |
|---|---|---|---|
| Intent Clarity | XX/25 | X | ... |
| Token Coverage | XX/20 | X | ... |
| Skin Fit | XX/15 | X | ... |
| Layout Match | XX/15 | X | ... |
| Effect Consistency | XX/15 | X | ... |
| Production Readiness | XX/10 | X | ... |

### Top 3 Improvements:
1. [Dimension]: [specific actionable suggestion]
2. [Dimension]: [specific actionable suggestion]
3. [Dimension]: [specific actionable suggestion]
```

### Composition:
```tsx
import '@zai/ui-kit/skins/dark-zai.css'
import '@zai/ui-kit/tokens/effects.css'
import '@zai/ui-kit/tokens/animations.css'

export default function Page() {
  return (
    <div className="page-shell" style={{
      display: 'grid',
      gridTemplateColumns: 'var(--zai-cols-[framework])',  // e.g. var(--zai-cols-dashboard)
      gridTemplateRows:    'var(--zai-rows-[framework])',    // e.g. var(--zai-rows-dashboard)
      gap:                 'var(--zai-gap-md)',
      minHeight:           '100vh',
      background:          'var(--zai-color-bg-primary)',
      color:               'var(--zai-color-text-primary)',
      padding:             'var(--zai-space-5)',
    }}>
      {/* Header region */}
      <header style={{ gridColumn: '1 / -1', padding: 'var(--zai-space-3)' }}>
        {/* AppHeader component */}
      </header>

      {/* Sidebar region */}
      <aside className="zai-glass-card" style={{ padding: 'var(--zai-space-5)' }}>
        {/* MetricCard x4 */}
        <div style={{ display: 'grid', gap: 'var(--zai-gap-sm)' }}>
          <MetricCard label="Portfolio" value="$12,847" />
          <MetricCard label="P/L" value="+$1,203" className="zai-neon-glow" />
        </div>
      </aside>

      {/* Main region */}
      <main className="zai-glass-card" style={{ padding: 'var(--zai-space-5)' }}>
        {/* Chart / DataTable */}
      </main>

      {/* Right aside region */}
      <aside style={{ display: 'grid', gap: 'var(--zai-gap-sm)', alignContent: 'start' }}>
        <StatusDot status="online" />
        <Badge label="Active" className="zai-badge-gradient" />
      </aside>
    </div>
  )
}

/* Component patterns (use these as building blocks): */

/* MetricCard -- glass card with label + value */
<div className="zai-glass-card zai-card-lift" style={{
  padding:     'var(--zai-space-5)',
  borderRadius: 'var(--zai-radius-xl)',
}}>
  <span style={{
    fontSize:   'var(--zai-font-size-2)',
    color:      'var(--zai-color-text-muted)',
  }}>Label</span>
  <span style={{
    fontSize:   'var(--zai-font-size-6)',
    fontWeight: 'var(--zai-font-weight-bold)',
    color:      'var(--zai-color-text-primary)',
  }}>Value</span>
</div>

/* GlassCard -- generic container */
<div className="zai-glass-card" style={{
  padding: 'var(--zai-space-5)',
}}>
  {/* content */}
</div>

/* Badge -- tag/label */
<span className="zai-badge-gradient" style={{
  fontSize: 'var(--zai-font-size-1)',
}}>Active</span>

/* StatusDot -- online/offline indicator */
<span style={{
  width:  'var(--zai-dot-size)',
  height: 'var(--zai-dot-size)',
  borderRadius: 'var(--zai-radius-full)',
  background: 'var(--zai-color-status-online)',
}} />

/* Loading skeleton */
<div className="zai-skeleton" style={{
  height: 'var(--zai-font-size-6)',
  width: '60%',
}} />
```

### Token-to-CSS cheat sheet (dark-zai skin):

| Token | Resolved Value | Use For |
|---|---|---|
| var(--zai-color-bg-primary) | #0a0a0f | Page background |
| var(--zai-color-bg-card) | #15151f | Card surfaces |
| var(--zai-color-text-primary) | #E6E6E6 | Headings, primary text |
| var(--zai-color-text-muted) | #878992 | Labels, secondary text |
| var(--zai-color-border-default) | #5C6070 | Card borders |
| var(--zai-glass-bg) | rgba(3,3,8,0.8) | Glass card background |
| var(--zai-glow-color) | 230,230,230 | Glow RGB (use with rgba()) |
| var(--zai-space-5) | 20px | Standard padding |
| var(--zai-gap-md) | 12px | Card grid gaps |
| var(--zai-font-size-6) | 2rem | Metric values |
| var(--zai-radius-xl) | 12px | Card border-radius |

### Quick Recommendation:
```text
## Quick: [domain] UI

Skin: [name] | Layout: [framework] | Effects: [technique]

Components: [list]
Key tokens: --zai-cols-*, --zai-gap-*, --zai-glow-*
```

---

## Communication Style

This skill communicates in a professional style:

- No emoji or Unicode graphics in responses
- Use text tags for status: [OK], [FAIL], [TODO], [WARNING]
- Use severity tags for rules: [C] (Critical), [W] (Warning), [I] (Info)
- Use ASCII diagrams for layouts: +, -, |, corner chars
- Token names always prefixed: --zai-* (never bare variable names)
- Class names always prefixed: .zai-* (never bare class names)
