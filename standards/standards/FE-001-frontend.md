# Standard: Frontend Development v2.4 (EN)

> ID: STD-FE-001
> Version: 2.4
> Level: **[C] Critical**
> Last Updated: 2026-06
> Related: Design System Standard (STD-DESIGN-001), Environment (STD-ENV-001), Markdown (STD-DOC-002), Standard ID System (STD-META-001)

## 1. Scope

### Covers

This standard is mandatory for the development of all User Interfaces built on the **React ecosystem**.

**Coverage:**
-   **Frameworks:** Next.js (App Router / Pages Router), Remix, Vite, Pure React.
-   **Language:** TypeScript (Strict Mode).
-   **Runtimes & Tools:** The rules are agnostic to package managers (npm, yarn, pnpm, bun) and runtimes (Node.js, Bun), provided they support the target framework.

### Partially Covers (with adaptation)

The FSD layer structure (tokens/ -> ui/ -> sections/ -> features/ -> hooks/ -> providers/) and the design token integration rules (Section 11) are applicable to other component frameworks with adaptation:

| Framework | What applies | What must change |
|-----------|-------------|------------------|
| Vue | FSD layers, token integration, size limits, exception format | `useState` -> `ref`/`reactive`; `useReducer` -> Pinia store; `dynamic()` -> `defineAsyncComponent`; Server Components -> SSR directives |
| Svelte | FSD layers, token integration, size limits | `useState` -> Svelte stores; `useReducer` -> stores; `dynamic()` -> `{#await}`; hooks -> `.svelte.ts` modules |
| Angular | FSD layers, token integration, size limits | `useState` -> signals/services; `dynamic()` -> lazy loading modules; barrel exports -> NgModules or standalone |
| Solid | FSD layers, token integration, size limits | `useState` -> `createSignal`; `useReducer` -> `createStore`; hooks -> solid primitives |

### Does NOT Cover

| Environment | Why |
|-------------|-----|
| **React Native** | No DOM, no CSS. Styling via `StyleSheet.create()`. Component model differs (no Server Components, no `dynamic()`). Design tokens apply via STD-DESIGN-001 React Native adaptation. |
| **Flutter / SwiftUI / native mobile** | Different component model, different styling system, different language. |
| **Canvas / WebGL without DOM** | No DOM components. Three.js/PIXI.js render to canvas, not to React tree. |
| **Terminal TUI** | No React, no CSS. |

**Boundary rule:** This standard governs **React + DOM + CSS** projects. For other DOM-based frameworks, the FSD architecture and design token integration (Section 11) apply; the React-specific rules (hooks, dynamic imports, Server Components) must be adapted. For non-DOM environments, only the token naming and semantic structure from STD-DESIGN-001 apply.

---

## 2. Code Complexity Metrics
These limits are hard thresholds. Code exceeding limits must not be merged without documented exception.

### 2.1. Size Constraints

| Unit | Recommended | Hard limit | Action if exceeded |
|------|------------|-----------|-------------------|
| **Component function** | 100 lines | 200 lines | Extract sub-components |
| **File (Module)** | 150 lines | 250 lines | Split into multiple files |
| **Page / Route** | 30 lines | 50 lines | Composition Roots only |
| **Custom hook** | 50 lines | 100 lines | Split into smaller hooks |
| **Barrel index.ts** | 30 lines | 50 lines | Group into sub-barrels |

**How to count:** Lines of code excluding blank lines and comments.

**Exception documentation:** When a component reaches 150+ lines but cannot be reasonably split, document the reason:

```typescript
// [ANTI-MONOLITH EXCEPTION] This component has 170 lines because it renders
// 12 conditional columns in a data table. Extracting each column into a separate
// component would fragment the table API. Revisit if complexity grows.
function DataTable({ columns, data, sortConfig, filters }: DataTableProps) {
```None

**Auto-flag in CI:** Any component exceeding the hard limit (200 lines) triggers an automated PR comment requesting decomposition.

### 2.2. State Management

**Rule:** A single React component (Client Component) MUST contain **no more than 2 `useState` hooks**. The 3rd `useState` triggers extraction into a custom hook.

**Escalation path:**

| useState count | Action |
|----------------|--------|
| 1-2 | Fine, keep in component |
| 3 | Extract into custom hook OR use `useReducer` |
| 4+ | Mandatory custom hook extraction |

**Example — BAD:**

```typescript
function Dashboard() {
  const [query, setQuery] = useState('')
  const [category, setCategory] = useState('all')
  const [favorites, setFavorites] = useState([])
  const [selected, setSelected] = useState(null)
  const [sortBy, setSortBy] = useState('name')
  const [viewMode, setViewMode] = useState('grid')
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState(null)
  // 8 useState -- VIOLATION (limit is 2)
}
```

**Example — GOOD:**

```typescript
function Dashboard() {
  const filters = useDashboardFilters()    // query, category, sortBy, viewMode
  const { items, isLoading, error } = useDashboardData(filters)
  const { favorites, toggleFavorite } = useFavorites()
  const [selected, setSelected] = useState(null)  // 1 local useState -- OK (limit is 2)
}
```text

---

## 3. Architectural Constraints

### 3.1. Data Isolation

**Principle:** Strict separation between Smart (Container) and Dumb (Presentational) components.

**Prohibitions:**
-   Direct API calls (`fetch`, `axios`, `trpc`) inside Client Components are PROHIBITED.
-   Direct access to global stores (Zustand, Redux, Context) in leaf UI components is discouraged.

**Next.js Implementation:**
-   Server Components: Data fetching is permitted and recommended.
-   Client Components: Data arrives via props or custom hooks.

**Recommended: TanStack Query**

```typescript
// Hook wraps useQuery -- component only sees the return value
function useUsers() {
  return useQuery({
    queryKey: ['users'],
    queryFn: () => fetch('/api/users').then(r => r.json()),
  })
}
```

### 3.2. Modularity & Exports

**Requirement:** Every module (folder) MUST have a Public API (Barrel Export) via `index.ts`.

**Explicit exports preferred:**

```typescript
// PREFERRED -- better for Fast Refresh, tree-shaking, IDE support
export { Button } from './Button'
export { Card } from './Card'

// AVOID in directories with 10+ components
export * from './ui'
```text

**Prohibition:** Deep imports are PROHIBITED.

| Violation | Compliance |
|-----------|------------|
| `import { Button } from 'shared/ui/Button/Button'` | `import { Button } from 'shared/ui'` |

### 3.3. Layer Separation

**Methodology:** Feature-Sliced Design (FSD) with sections/features distinction.

**Note on applicability:** The FSD layer structure (tokens/ -> ui/ -> sections/ -> features/ -> hooks/ -> providers/) is framework-agnostic in principle. While this standard governs its implementation for React, the same layer separation applies to Vue (composables instead of hooks), Svelte (stores instead of hooks), and Angular (services instead of hooks). The `tokens/` layer is fully universal; it is defined by STD-DESIGN-001 and does not depend on any component framework. The framework-specific rules in this standard (useState limits, dynamic imports, Server Components) are React/Next.js specific and must be adapted for other frameworks.

```text
tokens/       <- Design tokens: CSS custom properties, spacing scale, typography (STD-DESIGN-001 Profile)
  ^
ui/           <- Button, Card, Input (pure presentation, no state, no hooks)
  ^
sections/     <- HeroSection, NavigationSection (compose ui/, NO own state)
  ^
features/     <- FlowCanvas, AgentHierarchy (complex, HAVE own state)
  ^
hooks/        <- useTheme, useMediaQuery (stateful logic, no JSX)
  ^
providers/    <- ThemeProvider, ErrorBoundary (wrap the app)
```

**sections/ vs features/ distinction:**

| | sections/ | features/ |
|---|-----------|-----------|
| **Own state** | No — only props | Yes — useState, useReducer, hooks |
| **Calls hooks** | No | Yes |
| **Purpose** | Layout composition | Self-contained interactive blocks |
| **Example** | HeroSection, FooterSection | FlowCanvas, SearchPanel |

**When unsure:** "Does this component manage its own state?" If yes -> features/. If only props -> sections/.

**Layer rules:**

| Layer | Can import from |
|-------|-----------------|
| `tokens` | Nothing from other layers |
| `ui` | Only from `tokens` |
| `sections` | From `ui` and `tokens` — never hooks or state |
| `features` | From `sections`, `ui`, `hooks`, `tokens` |
| `hooks` | Only from `tokens` (or external libraries) |
| `providers` | From `hooks`, `ui`, `tokens` |

**No upward imports. Ever.**

---

## 4. Dynamic Imports

If a component exceeds 200 lines OR imports a heavy dependency (Three.js, Recharts, Monaco, D3), use dynamic import:

```typescript
const FlowCanvas = dynamic(() => import('@/components/features/FlowCanvas'), {
  loading: () => <CanvasSkeleton />,
  ssr: false,
})
```text

**When to use:**

| Condition | Dynamic import? |
|-----------|----------------|
| Component < 200 lines, no heavy deps | No |
| Imports Three.js, D3, Recharts, Monaco | Yes |
| Below the fold (not visible on first paint) | Yes |
| Used in a modal/tab that opens on click | Yes |
| Critical for first paint (hero, navigation) | No |

---

## 5. File Naming Convention

| Type | Pattern | Example |
|------|---------|---------|
| Component | PascalCase.tsx | `HeroSection.tsx` |
| Hook | camelCase.ts | `useTheme.ts` |
| Provider | PascalCase.tsx | `ThemeProvider.tsx` |
| Barrel | index.ts | `index.ts` |
| Types | PascalCase.types.ts | `Button.types.ts` |
| Utils | camelCase.ts | `formatDate.ts` |

**Co-location principle:** A hook that serves only one feature lives in the same directory as that feature. Shared hooks go in `hooks/`.

---

## 6. Enforcement

### 6.1. ESLint Configuration

```javascript
module.exports = {
  rules: {
    'max-lines': ['warn', { max: 250, skipBlankLines: true, skipComments: true }],
    'max-lines-per-function': ['warn', { max: 200, skipBlankLines: true, skipComments: true }],
    'react-hooks/exhaustive-deps': 'error',
  },
  overrides: [
    {
      files: ['**/components/**/*.tsx', '**/sections/**/*.tsx', '**/features/**/*.tsx'],
      rules: {
        'max-lines-per-function': ['error', { max: 150 }],
      },
    },
  ],
}
```

### 6.2. Layer Boundary Enforcement

```javascript
'boundaries/element-types': [
  'error',
  {
    default: 'allow',
    rules: [
      { from: 'ui', disallow: ['sections', 'features', 'hooks', 'providers'] },
      { from: 'sections', disallow: ['features', 'hooks', 'providers'] },
      { from: 'features', disallow: ['providers'] },
    ],
  },
]
```None

### 6.3. Code Review Policy

Any violation not caught by linter is grounds for **Request Changes**.

---

## 7. Refactoring Strategy

When encountering a monolith (e.g., 1200-line `page.tsx`):

1. **Identify sub-components** — Extract functions returning JSX.
2. **Identify state clusters** — Group `useState`, extract into hooks.
3. **Identify data loading** — Move to hooks or Server Components.
4. **Classify each** — sections/ (no state) or features/ (has state).
5. **Add dynamic imports** — For heavy dependencies.
6. **Create barrel exports** — Use explicit exports.
7. **Verify layer separation** — Run ESLint boundaries check.
8. **Test** — Ensure identical behavior.

**Result:** A 40-line `page.tsx` that composes testable, reusable components.

---

## 8. Pre-merge Checklist

- [ ] File is under 250 lines (recommended under 150)
- [ ] No component exceeds 200 lines (recommended under 150)
- [ ] No more than 2 `useState` per component (3rd -> custom hook)
- [ ] No direct `fetch`/`axios` in Client Components
- [ ] Every component directory has `index.ts` barrel
- [ ] No upward layer imports
- [ ] sections/ have no state; features/ may have state
- [ ] Heavy components use dynamic imports
- [ ] Barrel exports are explicit (not `export *`) for 10+ files
- [ ] Exception documented with `[ANTI-MONOLITH EXCEPTION]` or `// DESIGN-EXCEPTION: <reason>` comment

---

## 9. Exception Handling

Deviations require:
1. Tech Debt ticket (tagged `tech-debt`)
2. Tech Lead approval
3. Exception comment in code using the appropriate format:
   - Code complexity violations: `// [ANTI-MONOLITH EXCEPTION] <reason>`
   - Design token violations: `// DESIGN-EXCEPTION: <reason>` (per STD-DESIGN-001 Section 11.3)

**Exception ceilings (aligned with ZAI-ARCH-002 Anti-Monolith Skill):**

| File type | With documented exception | Absolute ceiling |
|-----------|--------------------------|------------------|
| Component function | Up to 300 lines | 400 lines -- no exceptions, must decompose |
| File (Module) | Up to 300 lines | 400 lines -- no exceptions, must decompose |
| Page / Route | Up to 80 lines | 100 lines -- no exceptions, must decompose |

**Exception is valid when:**
- File is under 300 lines AND well-organized with clear sections
- Decomposition would harm readability (linear flows, wizards)
- Component is temporary/throwaway (prototype, demo)
- Auto-generated code (Prisma client, OpenAPI types)

**Exception is NOT valid when:**
- File exceeds 400 lines (no excuses, decompose)
- Multiple developers need to edit the same file
- Component has 5+ useState
- Any test file for this component is also monolithic

---

## 10. API Route Standard (Next.js App Router)

### 10.1. Route Handler Structure

Each route handler MUST be a single file with maximum 80 lines of logic:

```text
src/app/api/
+-- users/
|   +-- route.ts          <- GET (list), POST (create)
|   +-- [id]/
|       +-- route.ts      <- GET (detail), PATCH (update), DELETE (remove)
+-- documents/
|   +-- route.ts
|   +-- [id]/
|       +-- route.ts
```

### 10.2. Response Format

All API responses MUST follow a consistent structure:

```typescript
// Success response
return NextResponse.json({ success: true, data: result })

// Error response
return NextResponse.json(
  { success: false, error: { code: 'VALIDATION_ERROR', message: 'Invalid input' } },
  { status: 400 }
)
```None

### 10.3. Input Validation

All input MUST be validated with Zod before processing. For comprehensive validation schemas and security considerations, see **STD-SEC-001 Section 3.1** (validation schemas, SQL injection prevention) and **STD-FE-001 Section 10.4** (error handling).

```typescript
import { z } from 'zod'

const CreateUserSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email().max(255),
})

export async function POST(request: Request) {
  const body = await request.json()
  const result = CreateUserSchema.safeParse(body)

  if (!result.success) {
    return NextResponse.json(
      { success: false, error: { code: 'VALIDATION_ERROR', message: 'Invalid input', details: result.error.errors } },
      { status: 400 }
    )
  }

  // Process validated data
  const user = await db.user.create({ data: result.data })
  return NextResponse.json({ success: true, data: user }, { status: 201 })
}
```

### 10.4. Error Handling

API routes MUST NOT leak internal error details to clients. For complete error handling patterns, see **STD-ERR-001 Section 5.2** (error handler middleware) and **STD-SEC-001 Section 8** (sandbox core checklist).

### 10.5. Auto-Backup Before Mutations

Write mutations (POST, PATCH, DELETE) SHOULD create a backup before execution. The backup implementation MUST follow these rules:

1. Non-blocking: backup failure MUST NOT prevent the mutation (log error, continue)
2. Location: `/tmp/` directory (system temp, not committed to git)
3. Format: `{entity}-{timestamp}.json` (e.g., `user-20260518T120000.json`)
4. Retention: cleanup backups older than 24 hours on next backup call

```typescript
export async function DELETE(request: Request, { params }: { params: { id: string } }) {
  try {
    await autoBackup()  // Non-critical -- failure logged but does not block
    await db.user.delete({ where: { id: params.id } })
    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error deleting user:', error)
    return NextResponse.json(
      { success: false, error: { code: 'NOT_FOUND', message: 'User not found' } },
      { status: 404 }
    )
  }
}
```None

### 10.6. Deduplication on Create

All POST endpoints MUST check for existing records before creating:

```typescript
const existing = await db.user.findFirst({
  where: { email: { equals: result.data.email } }
})
if (existing) {
  return NextResponse.json({ success: true, data: existing }, { status: 200 })
}
```

### 10.7. Pre-merge Checklist for API Routes

- [ ] Input validated with Zod
- [ ] Response format is { success, data? / error? }
- [ ] No internal error details in responses
- [ ] Write mutations call autoBackup()
- [ ] Create endpoints check for duplicates
- [ ] File is under 80 lines of logic
- [ ] DELETE requires confirmation (client-side AlertDialog)

---

## 11. Design Token Integration

This section defines how the project's frontend code integrates with the **Design System Standard (STD-DESIGN-001)**. All visual token rules -- color naming, dark/light variants, typography scales, spacing scales, card archetypes -- are governed by STD-DESIGN-001. This standard (STD-FE-001) governs how React components consume those tokens.

### 11.1. Design Token Authority

**Rule:** Where STD-FE-001 and STD-DESIGN-001 overlap on visual token rules (colors, typography, spacing, card styles), **STD-DESIGN-001 takes precedence.** This standard (STD-FE-001) does not define token names, token values, or color palettes; it defines how the React component layer accesses them.

The project's active Profile (STD-DESIGN-001, Section 13) is the single source of truth for:
- Color token names and values (light + dark variants)
- Typography scale tokens
- Spacing scale tokens
- Card archetype definitions (Terminal, Content, Stat, Interactive/Canvas)
- Syntax highlighting tokens
- Animation tokens (duration, easing)
- Breakpoint tokens
- Prohibited patterns and enforcement rules

### 11.2. Token Layer in FSD Architecture

The `tokens/` layer (Section 3.3) is where the active Profile's CSS custom properties are registered. This layer must contain **no React code, no hooks, no component logic** -- only CSS custom property definitions (`:root` and `.dark` blocks) and, if the Profile uses Pattern A (Theme Extension), the framework theme configuration.

```text
tokens/
  +-- globals.css          <- :root and .dark blocks from Profile P9 (STD-DESIGN-001)
  +-- animations.ts         <- duration/easing constants from Profile P12 (STD-DESIGN-001)
  +-- breakpoints.ts        <- breakpoint constants from Profile P13 (STD-DESIGN-001)
  +-- tailwind.config.ts   <- theme.extend from Profile Integration Pattern (if Pattern A)
  +-- index.ts             <- barrel (re-exports token constants if needed by hooks)
```None

**Layer constraint (from Section 3.3):** The `tokens/` layer imports nothing from other layers. All other layers (`ui/`, `sections/`, `features/`, `hooks/`, `providers/`) import from `tokens/`.

### 11.3. Integration Pattern Alignment

The project's Integration Pattern (STD-DESIGN-001, Section 4.5) determines how components consume tokens. The frontend codebase must follow the chosen pattern consistently:

| Pattern | Component Consumption | Example |
|---------|----------------------|---------|
| A: Theme Extension | Framework utility classes only; no `style={{}}` | `<span className="text-accent-primary">` |
| B: CSS Modules | `.module.css` classes referencing `var(--token)` | `<span className={styles.prompt}>` |
| C: Vanilla CSS | Global/scoped CSS referencing `var(--token)` | `<span className="prompt">` |
| D: CSS-in-JS | Styled components or `css` template literals referencing `var(--token)` | `<Prompt>text</Prompt>` or `css\`color: var(--terminal-accent)\`` |

**Prohibition:** Mixing patterns within the same token category is not allowed unless documented in the Profile. For example, using Pattern A for colors and Pattern C for spacing must be explicitly documented with a clear rule for which pattern applies to which category.

**Framework-locked environments:** When theme extension (Pattern A) is unavailable (e.g., Create React App without eject, locked corporate build pipelines), Pattern B or Pattern C is the appropriate choice. No project should be blocked by the build system's inability to extend the theme configuration.

### 11.4. Adoption Phase Alignment

The project's Adoption Phase (STD-DESIGN-001, Section 10.4) determines what the CI pipeline enforces. The frontend team must align its ESLint configuration and CI workflows with the current phase:

| Phase | CI Behavior | Frontend Action |
|-------|-------------|-----------------|
| Phase 1 | All [C] reported as [W] | Install Profile tokens, begin learning token names |
| Phase 2 | Colors [C] (blocks merge); Spacing/Typography [W+] (tracked, not blocked) | Fix color violations; reduce spacing/typography debt incrementally |
| Phase 3 | Full [C] enforcement | All token rules block merge; P11 auto-generation script mandatory in CI |

The [W+] level (Phase 2) means spacing and typography violations are logged with persistent count reports in the CI dashboard so the team can track debt before Phase 3 activates full enforcement.

### 11.5. WCAG Contrast Compliance

All color tokens defined in the Profile must meet **WCAG 2.1 AA contrast requirements**. Contrast validation is the responsibility of the Profile author; the frontend team verifies compliance during code review.

- Default palettes must pass the automated contrast audit (`npx stsgs a11y audit`, per STD-A11Y-001 §7)
- Custom theme presets (e.g., Champagne, Cyan Night, Zinc) must document contrast ratios for all token pairs before use — attach the audit report as a CI artifact on the PR
- Non-default palettes require manual contrast verification per STD-A11Y-001 §1.1

**Note:** Prior to A11Y-001 v1.3, this section referenced "STD-A11Y-001 section 7 contrast requirements" which was an empty hand-maintained table. A11Y-001 v1.3 replaced that table with an automated-report reference. This section was updated in sync.

### 11.6. Anti-Fragility: Error Isolation

Non-critical operations (backup, AI analysis, background sync) MUST NOT break the main user flow. If a non-critical operation fails, log the error and continue.

Critical operations (save, delete, submit) MUST show the error to the user via toast notification with a clear, actionable message.

```typescript
// Non-critical: failure is logged, does not block
try {
  await autoBackup()  // non-blocking
} catch (e) {
  console.error('Backup failed:', e)
  // continue main flow
}

// Critical: failure must reach the user
try {
  await saveDocument(data)
} catch (e) {
  toast({ title: 'Save failed', description: 'Please try again', variant: 'destructive' })
}
```

### 11.7. Deletion UI Patterns

All destructive actions MUST require explicit user confirmation via AlertDialog before execution.

| Entity | Location | Trigger | Confirmation |
|--------|----------|---------|-------------|
| Note | List + Editor | Trash2 button | AlertDialog |
| Extracted instruction | List | Trash2 button | AlertDialog |
| Built-in instruction | List | Trash2 button | AlertDialog (with localStorage persistence) |
| Document | View | Trash2 button | AlertDialog |
| Category | Sidebar | Trash2 button (hover) | AlertDialog |
| Tag | Sidebar | X button (hover) | AlertDialog |
| Term | Dictionary | Trash2 button (hover) | AlertDialog |
| Bulk items | List | Bulk select + delete | AlertDialog with count |

When possible, prefer soft-delete (archive) over hard-delete. See STD-FE-001 section 10.5 for auto-backup before mutations.

---

## 12. Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2023-10 | Initial version |
| 1.1 | 2023-10 | Added Page/Route limit (40 lines) |
| 1.2 | 2025-01 | Merged anti-monolith patterns, examples, refactoring strategy |
| 1.3 | 2025-01 | Added Recommended/Hard limits, sections/features distinction, ESLint config, dynamic imports rules, co-location principle, exception documentation format |
| 1.4 | 2026-05 | Relocated from STD-ENV-001: dark theme (11.1), color palette (11.2), anti-fragility/error isolation (11.3), deletion UI patterns (11.4). Added Related: STD-ERR-001. |
| 1.5 | 2026-05 | K-06/K-07: replaced duplicated error handling (10.4) and Zod validation (10.3) with cross-references to STD-ERR-001 and STD-SEC-001. K-08: added autoBackup() specification (10.5). K-09: added custom theme preset validation rule (11.2). |
| 2.0 | 2026-06 | **Design System integration:** Section 11 rewritten to delegate all visual token rules (colors, typography, spacing, card styles, dark theme) to STD-DESIGN-001; added token authority rule (STD-DESIGN-001 takes precedence on visual tokens); added Integration Pattern Alignment (Pattern A/B/C); added Adoption Phase Alignment (Phase 1-3 CI behavior); expanded `tokens/` layer description to reference Profile P9; unified exception format (`ANTI-MONOLITH EXCEPTION` + `DESIGN-EXCEPTION`); added STD-DESIGN-001 to Related and Cross-References |
| 2.1 | 2026-06 | **Anti-Monolith alignment (ZAI-ARCH-002):** Page/Route limits changed from 40/40 to 30 recommended/50 hard; useState limit reduced from 3 to 2 (3rd triggers extraction); added exception ceilings (300 lines with exception, 400 absolute); added exception validity rules aligned with Anti-Monolith Skill |
| 2.2 | 2026-06 | **Stack universality sync:** Added Pattern D (CSS-in-JS) to Integration Pattern Alignment table (Section 11.3); added Interactive/Canvas archetype to token authority list (Section 11.1); added animation tokens (P12) and breakpoint tokens (P13) to token authority and tokens/ layer structure (Section 11.2); added framework-agnostic FSD note (Section 3.3); synchronized with STD-DESIGN-001 v3.0.0 |
| 2.3 | 2026-06 | **Explicit scope boundaries:** Section 1 expanded with "Covers / Partially Covers / Does NOT Cover" tables; added per-framework adaptation guide (Vue, Svelte, Angular, Solid); added boundary rule (React + DOM + CSS); aligned with STD-DESIGN-001 Section 0 Scope |
| 2.4 | 2026-06 | Added §12A Known Issues documenting FE-001 through FE-003 (ZAI-ARCH-002 skill vs standard distinction, K-NN notation in v1.5 Version History, no automated 150-line check). Added STD-META-001 to Related and Cross-References. No normative rule changes. |

---

## 12A. Known Issues and Proposed Solutions

This section documents discovered inconsistencies, missing content, and proposed corrections. Each issue has an ID, status, and proposed action. Issues resolved in the current version are marked `[RESOLVED]`; outstanding issues are marked `[OPEN]`.

### FE-001 `[OPEN]` — §13 Cross-References lists `ZAI-ARCH-002` (a skill, not a standard)

**Problem:** §13 (Cross-References) lists `ZAI-ARCH-002 | Anti-Monolith Skill: auto-activates when thresholds exceeded...`. The `ZAI-ARCH-` prefix follows the skill ID convention, not the `STD-` standard convention. Cross-References is meant to list relationships to other standards; skills are operational artifacts, not governance documents. This is the same pattern flagged in STD-DESIGN-001 DES-004.

**Proposed solution:** Either (a) move the ZAI-ARCH-002 reference to a new "Related Skills" section separate from Cross-References, or (b) annotate the existing row with "(skill, not standard)" to make the distinction explicit. Option (b) is the lighter touch; option (a) is the cleaner separation. Decision deferred to project owner — same decision should be applied to STD-DESIGN-001 DES-004 for consistency.

### FE-002 `[OPEN]` — Version History v1.5 references K-06/K-07/K-08/K-09 — undefined notation

**Problem:** The v1.5 entry in §12 Version History says "K-06/K-07: replaced duplicated error handling... K-08: added autoBackup()... K-09: added custom theme preset validation rule". The `K-NN` notation is used as if it were a well-known convention, but no standard in the project defines it. New contributors encountering "K-06" cannot look it up.

This is the same issue as ORC-001 in `AGENT-002-orchestration.md` — the `K-NN` notation is used across multiple standards but never defined.

**Proposed solution:** Adopt the resolution chosen for ORC-001. If option 2 (replace K-NN with `<PREFIX>-NN`) is chosen, update this Version History entry to: "FE-001: replaced duplicated error handling (10.4) and Zod validation (10.3) with cross-references to STD-ERR-001 and STD-SEC-001. FE-002: added autoBackup() specification (10.5). FE-003: added custom theme preset validation rule (11.2)." The substantive content is preserved; only the notation changes.

### FE-003 `[OPEN]` — §2.1 says "Auto-flag in CI: Any component exceeding the hard limit (200 lines) triggers an automated PR comment", but no such automation is documented

**Problem:** §2.1 (Size Constraints) says "Auto-flag in CI: Any component exceeding the hard limit (200 lines) triggers an automated PR comment requesting decomposition." This is stated as an existing CI feature, but no GitHub Action, ESLint rule, or script in the project implements it. A team reading §2.1 would expect the auto-flag to exist; in reality, the limit is enforced only by manual code review and the ESLint `max-lines-per-function` rule (§6.1) which is set to `warn` not `error`.

**Proposed solution:** Either (a) implement the auto-flag as a GitHub Action that runs ESLint with `--max-warnings=0` on `**/components/**/*.tsx` and posts a PR comment on failure, or (b) soften §2.1 to: "Recommended: configure CI to auto-flag components exceeding 200 lines via ESLint `max-lines-per-function: ['error', { max: 200 }]`. See §6.1 for the ESLint configuration." Option (b) is honest about the current state; option (a) actually delivers the feature.

---

## 13. Cross-References

| Standard | Relationship |
|----------|-------------|
| **STD-DESIGN-001** | **Design System Standard: single source of truth for all visual tokens (colors, typography, spacing, card archetypes). Section 11 delegates to this standard.** |
| **ZAI-ARCH-002** | **Anti-Monolith Skill (not a standard — see FE-001 in §12A): auto-activates when thresholds exceeded; 7-step decomposition strategy. Section 2 limits and Section 9 exception ceilings aligned with this skill.** |
| STD-A11Y-001 | WCAG accessibility: theme contrast validation (Section 11.5), component keyboard/screen reader patterns |
| STD-ERR-001 | Error handling: error boundaries, API error responses (cross-ref from Section 10.4) |
| STD-SEC-001 | Input validation: Zod schemas, sanitization (cross-ref from Section 10.3) |
| STD-GIT-001 | Git commit format for frontend code changes |
| STD-ENV-001 | Reproducibility: .env.example for theme tokens, path.resolve() for DB |
| STD-META-001 | Standard ID System: registry entry for STD-FE-001 must be kept in sync with the version in this document's header |
