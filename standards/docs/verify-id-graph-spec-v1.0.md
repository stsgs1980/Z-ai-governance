# verify-id-graph.js — Specification v1.0

> ID: TOOL-VERIFY-004
> Version: 1.0.0
> Layer: L1 Standards (lives in `Z-ai-standards/scripts/`)
> Owning repo: Z-ai-standards
> Last Updated: 2026-06-17
> Effective Date: 2026-06-17
> Status: **APPROVED**
> Related: STD-META-001 v2.0, STD-SKILL-001 v1.0, TOOL-VERIFY-002 (verify-standards.js)
> Implements invariants: G01–G15 from STD-META-001 §10.2 and STD-SKILL-001 §13.2

> **Status: APPROVED.** This specification defines the cross-repo ID graph
> validator that enforces DAG invariants, layer-edge rules, compatibility
> constraints, and bidirectional `Aligned_with:` symmetry across the four
> Z-ai repositories.
>
> **Key principle:** Two-level strictness — HARD checks (G01-G15) apply
> always to STD/RULE/PROC/TOOL and only to ZAI skills that declare an `id`;
> SOFT warnings (W01-W10) report issues without failing the build.

---

## 1. Purpose

`verify-id-graph.js` is the cross-repository invariant checker for the ID
system defined in STD-META-001 v2.0 and STD-SKILL-001 v1.0. Where
`verify-standards.js` checks the format and internal consistency of a
single repo, `verify-id-graph.js` checks the **dependency graph** spanning
all four repositories of the Z-ai ecosystem:

```text
Z-ai-platform  (meta — no IDs declared, scanned for references only)
Z-ai-standards (L1: STD-*)
Z-ai-guard     (L2: RULE-*, PROC-*, TOOL-*)
Z-ai-skills    (L3: ZAI-*)
```text

It builds a directed graph of `<ID> -> <ID>` edges from the `Related:`
fields of every artifact's header, plus an undirected graph of
`<ID> <-> <ID>` edges from the `Aligned_with:` fields, then validates that:

1. The `Related:` graph has no duplicate IDs across repos (G01)
2. All `Related:` references resolve (G02)
3. The `Related:` graph is acyclic (G03, G11)
4. All `Related:` edges conform to the layer-dependency matrix (G04–G10)
5. No deprecated ID referenced outside migration window (G05)
6. No orphan rules or dead standards (G06, G13, warnings)
7. `Aligned_with:` declarations have a corresponding `Related:` edge (G15)
8. `Aligned_with:` declarations are reciprocated (W08)
9. ZAI- skills' `compatibility` field forms a valid DAG (G14)
10. ZAI- skills' YAML frontmatter agrees with their blockquote (W07)

---

## 2. Location & Invocation

### 2.1. File Location

```text
Z-ai-standards/scripts/verify-id-graph.js
```

Lives in Z-ai-standards (Layer 1) because it validates standards
(STD-META-001 v2.0 and STD-SKILL-001 v1.0). Although it scans all 4
repos, it is itself owned by the standards repo — same as
`verify-standards.js`.

### 2.2. Invocation

```bash
# From the Z-ai-governance repository root:
node standards/scripts/verify-id-graph.js

# CI mode (skips network checks, fails fast):
node standards/scripts/verify-id-graph.js --ci

# JSON output for CI integration:
node standards/scripts/verify-id-graph.js --json

# Verbose (prints full graph):
node standards/scripts/verify-id-graph.js --verbose

# Limit to specific repos (debug):
node standards/scripts/verify-id-graph.js --only=standards,guard

# Fail on warnings too:
node standards/scripts/verify-id-graph.js --fail-on-warnings
```None

### 2.3. Exit Codes

| Code | Meaning |
|---|---|
| 0 | All G01–G15 pass. W01–W08 may be present (unless `--fail-on-warnings`). |
| 1 | At least one G-check failed. |
| 2 | Configuration error (missing repos, missing `MIGRATIONS.md`, parse error). |

---

## 3. Inputs

### 3.1. Repository Discovery

The script discovers the four repos via the following priority order:

1. **`--root=<path>`** CLI argument (overrides everything)
2. **`ZAI_PLATFORM_ROOT`** environment variable
3. **Auto-detect from script location**: walk up from `__dirname` until a
   `.gitmodules` file is found containing entries for `Z-ai-standards`,
   `Z-ai-guard`, `Z-ai-skills`. That directory is the platform root.
4. **Fallback**: assume the script lives at
   `<platform>/standards/scripts/verify-id-graph.js` and the other repos
   are at `<platform>/guard/` and `<platform>/skills/`.

If discovery fails, exit 2 with a diagnostic.

### 3.2. Files Scanned Per Repo

| Repo | Glob patterns | What's extracted |
|---|---|---|
| Z-ai-standards | `standards/**/*.md`, `STANDARDS.md`, `*.md` (root) | All `STD-*` IDs + headers |
| Z-ai-guard | `AGENT_RULES.md`, `rules/**/*.md`, `instructions/**/*.md`, `scripts/**/*.{sh,js,ts}`, `tools/**/*.{md,ts,js}` | All `RULE-*`, `PROC-*`, `TOOL-*` IDs |
| Z-ai-skills | `skills/**/SKILL.md`, `skills/**/*.md` | All `ZAI-*` IDs (from YAML frontmatter + blockquote) |
| Z-ai-governance | `*.md`, `docs/**/*.md`, `templates/**/*.md` | No IDs declared (platform is meta); scanned for **references** only |

### 3.3. Migrations File

Each repo MAY have a `MIGRATIONS.md` at its root. The format is defined
in STD-META-001 §8.3. The script parses it to resolve references to
deprecated IDs during the migration window.

### 3.4. Configuration File (optional)

`<platform>/.verify-id-graph.json` (optional, all fields have defaults):

```json
{
  "repos": {
    "standards": "standards/",
    "guard": "guard/",
    "skills": "skills/"
  },
  "fail_on_warnings": false,
  "skip_checks": [],
  "extra_globs": {
    "guard": ["wiki/**/*.md"]
  }
}
```

---

## 4. Algorithm

### 4.1. Phase 1: Extract IDs (parallel per repo)

For each repo, run the unified extractor (STD-META-001 §5.4) on every
matching file. The extractor handles three header formats:

**Format A — YAML frontmatter** (used by ZAI- skills):

```yaml
---
name: skill-name
id: ZAI-ARCH-002
version: 1.0
compatibility: both
trigger: keyword1, keyword2
---

# Skill: <Name> v<Version>

> ID: ZAI-ARCH-002
> Version: 1.0
> Related: STD-FE-001, STD-DESIGN-001
> Aligned_with: STD-FE-001, STD-DESIGN-001
```text

Extractor reads:
- Frontmatter: `id`, `version`, `compatibility`, `trigger`, `author`
- Blockquote below H1: `Related:`, `Aligned_with:`, `Last Updated:`

**Format B — Blockquote** (used by STD-* standards and top-level guard docs):

```markdown
# Standard: <Name> v<Version> (<Language>)

> ID: STD-FE-001
> Version: 2.5
> Level: **[C] Critical**
> Last Updated: 2026-06
> Related: STD-ARCH-001, STD-DOC-002
> Aligned_with: ZAI-ARCH-002
> verified_by: scripts/verify-standards.js#V01
```

**Format C — HTML-comment** (used by rules inside AGENT_RULES.md):

```markdown
<!-- ID: RULE-ENV-008 | ver:1.0 | Level: C | Related: STD-ENV-001,STD-ENV-002 | Aligned_with: -->
```None

### 4.2. Phase 1 Output: Declaration Records

Each declaration produces a record:

```js
{
  id: "RULE-ENV-008",
  prefix: "RULE",
  domain: "ENV",
  number: 8,
  version: "1.0",
  level: "C",            // null for ZAI- skills (no level)
  related: ["STD-ENV-001", "STD-ENV-002"],
  aligned_with: [],      // empty if not declared
  compatibility: null,   // only for ZAI- skills: "both" | "sandbox" | "ade"
  trigger: null,         // only for ZAI- skills: string[]
  file: "guard/AGENT_RULES.md",
  line: 142,
  repo: "guard",
  header_format: "html-comment"  // "yaml" | "blockquote" | "html-comment"
}
```

### 4.3. Phase 2: Build the ID Catalog

Concatenate all declarations. Detect duplicate IDs across repos (G01).
A duplicate is any ID appearing in more than one declaration. The only
exception: an ID marked `[DEPRECATED]` or `[SUPERSEDED]` in one repo and
`[ACTIVE]` in another is treated as the active one; the deprecated entry
is recorded as a tombstone.

### 4.4. Phase 3: Build the Edge Lists

Two separate edge lists are built:

**Directed edges (`Related:`):**

For each declaration `D` with `related: [R1, R2, ...]`, create edges:
- `D.id -> R1`
- `D.id -> R2`
- ...

Each edge carries:
- `source`: declaring ID
- `target`: referenced ID
- `source_file`, `source_line`: where the declaration lives
- `kind`: `STD->STD`, `RULE->STD`, `PROC->ZAI`, etc. (computed from prefixes)

**Undirected edges (`Aligned_with:`):**

For each declaration `D` with `aligned_with: [A1, A2, ...]`, create edges:
- `D.id <-> A1`
- `D.id <-> A2`
- ...

Each edge carries:
- `left`, `right`: the two IDs (lexicographically ordered for dedup)
- `declared_by`: which side declared it (D.id)
- `reciprocated`: boolean — true if the other side also declares `Aligned_with:` back

### 4.5. Phase 4: Validate References (G02, G05, G12)

For every directed edge `S -> T`:
- If `T` exists in the catalog: OK.
- If `T` is a deprecated/superseded ID with `superseded_by` in `MIGRATIONS.md`:
  - If the migration window is still open (per repo version): warning W01.
  - If the migration window has closed: hard error G05.
- If `T` matches the ID format but no such ID exists anywhere: hard error G02.
- If `T` does not even match the ID format (typo like `STD-ENVIROMENT-001`): hard error G12.

### 4.6. Phase 5: Validate Layer Edges (G04–G10)

For every directed edge `S -> T`, look up the allowed-edge matrix
(STD-META-001 §6.1). If the edge kind is forbidden, emit the corresponding
G-check failure:

| Edge kind | Check |
|---|---|
| STD -> (RULE/PROC/TOOL/ZAI) | G07 |
| PROC -> ZAI | G08 |
| TOOL -> PROC | G09 |
| TOOL -> ZAI | G10 |

### 4.7. Phase 6: Detect Cycles in `Related:` Graph (G03, G11)

Run Tarjan's SCC algorithm on the directed `Related:` graph. Any SCC of
size > 1 is a cycle (G03). Any self-loop `S -> S` is G11.

The undirected `Aligned_with:` graph is **not** subject to cycle checks
(STD-META-001 §6.3 rule 3). Bidirectional alignments may form cycles
without violating any invariant.

### 4.8. Phase 7: Validate `Aligned_with:` Symmetry (G15, W08)

For every undirected `Aligned_with:` edge `A <-> B`:

**G15 check:** Is there a corresponding `Related:` edge in either direction?
- Acceptable: `A -> B` exists in directed edges
- Acceptable: `B -> A` exists in directed edges
- Acceptable: both exist (rare but valid)
- Fail G15 if neither direction exists in `Related:` edges.

Rationale (STD-META-001 §6.3 rule 5): alignment is a synchronization
mechanism on top of an existing dependency, not a substitute for one.

**W08 check:** Did both sides declare `Aligned_with:`?
- If A declares `Aligned_with: B` AND B declares `Aligned_with: A`: OK.
- If A declares `Aligned_with: B` but B does NOT declare `Aligned_with: A`:
  warning W08 (non-reciprocal declaration; should add for human readability).
- If both declare but with different additional IDs (A declares `B,C` and
  B declares `A,D`): each individual edge is checked separately. The
  asymmetry of additional IDs is not a warning.

### 4.9. Phase 8: Compatibility DAG Validation (G14)

This phase applies only to `ZAI-` skills (those with non-null
`compatibility` field in their declaration).

Build a subgraph containing only `ZAI -> ZAI` directed edges.

For each edge `ZAI-A -> ZAI-B`:
- Look up `compatA = A.compatibility` and `compatB = B.compatibility`.
- Check the compatibility matrix (STD-SKILL-001 §7.2):

| Source | May depend on |
|---|---|
| `both` | `both` only |
| `sandbox` | `both`, `sandbox` |
| `ade` | `both`, `ade` |

- If the pair is not in the allowed table: hard error G14.

Example failure:
```text
G14: ZAI-DEV-001 (compatibility=sandbox) depends on ZAI-STS-005 (compatibility=both)
  -> OK (sandbox may depend on both)

G14: ZAI-STS-005 (compatibility=both) depends on ZAI-DEV-001 (compatibility=sandbox)
  -> FAIL (both may only depend on both)
```text

The compatibility DAG is independent of the layer DAG. A ZAI skill may
pass G04–G10 (layer matrix) but fail G14 (compatibility matrix). Both
must pass.

### 4.10. Phase 9: Frontmatter/Blockquote Consistency (W07)

For every declaration with `header_format: "yaml"`:
- Compare frontmatter `id` with blockquote `ID:`. If different: W07.
- Compare frontmatter `version` with blockquote `Version:`. If different: W07.

(W07 is a soft warning. Hard failures on this are caught by
`verify-standards.js` V14a/V14b, which run per-repo before
`verify-id-graph.js`.)

### 4.11. Phase 10: Orphan & Dead-Code Warnings (W02–W06)

- For every RULE with `related: []`: warning W02 (possibly orphan).
- For every STD that is **not** the target of any `Related:` edge AND not
  the endpoint of any `Aligned_with:` edge: warning W03 (possibly dead
  standard).
- For every ZAI skill with `related: []` AND `aligned_with: []`: warning
  W04 (possibly rogue skill).
- For every PROC with `related: []`: warning W05 (orphan procedure).
- For every TOOL with `related: []`: warning W06 (orphan tool).

### 4.12. Phase 11: Emit Results

Produce a report listing each G-check and W-warning with:
- check id (G01, G02, ..., W01, W02, ...)
- status (PASS/FAIL/WARN)
- description
- offending edge(s) or node(s), with `file:line` references

---

## 5. Check Catalog

### 5.1. Hard Errors (exit 1 if any fail)

These checks ALWAYS apply to STD/RULE/PROC/TOOL artifacts (which require IDs).
For ZAI skills, they apply only when the skill has an `id` field.

| ID | Description | Phase | Applies to |
|---|---|---|---|
| G01 | No duplicate IDs across repos | 2 | All artifacts WITH IDs |
| G02 | All `Related:` references resolve to existing IDs | 4 | All artifacts (edges) |
| G03 | No cycles in the `Related:` ID graph | 6 | All artifacts (edges) |
| G04 | All `Related:` edges conform to §6.1 matrix (umbrella) | 5 | All artifacts (edges) |
| G05 | No deprecated ID referenced outside migration window | 4 | All artifacts (edges) |
| G06 | (reserved — currently a warning alias for W02) | 9 | — |
| G07 | No `STD -> (RULE/PROC/TOOL/ZAI)` `Related:` edges | 5 | STD sources |
| G08 | No `PROC -> ZAI` `Related:` edges | 5 | PROC sources |
| G09 | No `TOOL -> PROC` `Related:` edges | 5 | TOOL sources |
| G10 | No `TOOL -> ZAI` `Related:` edges | 5 | TOOL sources |
| G11 | No self-references (`S -> S`) | 6 | All artifacts |
| G12 | No reference to non-existent ID in any prefix (catches typos like `STD-ENVIROMENT-001`) | 4 | All artifacts |
| G13 | (reserved — currently a warning alias for W03) | 9 | — |
| G14 | Compatibility DAG valid for ZAI- skills (per STD-SKILL-001 §7.2). Only applies when both endpoints have `id` field. | 8 | ZAI skills WITH IDs |
| G15 | Every `Aligned_with:` declaration has a corresponding `Related:` edge | 7 | All artifacts |

### 5.2. Soft Warnings (do not fail the build unless `--fail-on-warnings`)

| ID | Description | Phase | Applies to |
|---|---|---|---|
| W01 | Reference to a `[DEPRECATED]` / `[SUPERSEDED]` ID inside migration window | 4 | All artifacts |
| W02 | RULE with empty `Related:` (orphan) | 9 | RULE |
| W03 | STD referenced by zero rules/skills AND zero `Aligned_with:` (dead standard) | 9 | STD |
| W04 | ZAI skill (WITH ID) with empty `Related:` AND empty `Aligned_with:` (rogue skill with ID but no graph role) | 9 | ZAI WITH IDs |
| W05 | PROC with empty `Related:` (orphan procedure) | 9 | PROC |
| W06 | TOOL with empty `Related:` (orphan tool) | 9 | TOOL |
| W07 | ZAI skill's YAML frontmatter disagrees with blockquote (`id` or `version` mismatch) — only when `id` field exists | 8 | ZAI WITH IDs |
| W08 | `Aligned_with:` declaration is not reciprocated by the other side | 7 | All artifacts |
| W09 | ZAI skill declares `compatibility` field but no `id` field (compatibility is meaningless without ID for graph tracking) | 8 | ZAI WITHOUT IDs |
| W10 | ZAI skill WITHOUT `id` field is referenced by ID from elsewhere (should add `id` to satisfy the reference) | 4 | ZAI referenced externally |

### 5.3. Strictness Model

The validator uses a two-level strictness model:

| Level | Behavior | Applies to |
|---|---|---|
| **HARD** (G01–G15) | Fails the build (exit 1) | STD/RULE/PROC/TOOL always; ZAI skills only when `id` present |
| **SOFT** (W01–W10) | Reports warning, does not fail unless `--fail-on-warnings` | All artifacts |

**Key principle:** A skill without an ID is valid and passes all HARD
checks. The skill layer is opt-in for ID graph participation.

This means:
- A new personal `_sts` skill with just `name`, `description`, `version`
  passes validation cleanly
- A skill with `id` field triggers additional checks (G14 compatibility
  DAG, W07 frontmatter consistency, W04 orphan-with-ID)
- A skill referenced by ID from a standard/rule but missing its own `id`
  field triggers W10 (should add `id` to satisfy external reference)

### 5.4. Reserved for Future

| ID | Description | Target version |
|---|---|---|
| G13 (reused) | Semantic duplicate detection (fuzzy match of rule text under two IDs) | v1.1.0 |

---

## 6. Output Format

### 6.1. Human-Readable (default)

```text
verify-id-graph.js v1.0.0
Platform root: /home/user/Z-ai-governance
Repos scanned: 4 (standards, guard, skills, platform)
IDs extracted: 73 (20 STD, 17 RULE, 7 PROC, 6 TOOL, 24 ZAI [incl. 1 SUPERSEDED])
Related: edges: 142
Aligned_with: edges: 8 (6 reciprocated, 2 non-reciprocal)

Phase 1:  Extract IDs ..................... PASS (73 IDs, 3 header formats)
Phase 2:  Catalog .......................... PASS (no duplicates)
Phase 3:  Build edges ...................... PASS (142 Related, 8 Aligned_with)
Phase 4:  Validate references .............. PASS (all resolve)
Phase 5:  Validate layer edges ............. PASS (matrix OK)
Phase 6:  Cycle detection (Related) ........ PASS (DAG confirmed)
Phase 7:  Aligned_with symmetry ............ PASS (G15) + 2 warnings (W08)
Phase 8:  Compatibility DAG ................ PASS (G14, ZAI->ZAI only)
Phase 9:  Frontmatter consistency .......... PASS (no W07)
Phase 10: Orphan & dead-code warnings ...... WARN (3 warnings)

Checks:
  G01 No duplicate IDs ............... PASS
  G02 References resolve .............. PASS
  G03 No cycles ........................ PASS
  G04 Layer matrix .................... PASS
  G05 Migration windows ............... PASS
  G07 No STD->lower edges .............. PASS
  G08 No PROC->ZAI ..................... PASS
  G09 No TOOL->PROC .................... PASS
  G10 No TOOL->ZAI ..................... PASS
  G11 No self-references .............. PASS
  G12 No typo-IDs ..................... PASS
  G14 Compatibility DAG ............... PASS
  G15 Aligned_with has Related ........ PASS

Warnings:
  W01 ZAI-META-001 referenced by 3 files; migration window open until Z-ai-skills v2.0.0
  W02 RULE-FOO-001 has empty Related:  guard/AGENT_RULES.md:142
  W03 STD-DOC-004 is not referenced by any RULE/ZAI
  W08 ZAI-ARCH-002 declares Aligned_with STD-DESIGN-001; STD-DESIGN-001 does not reciprocate
  W08 STD-FE-001 declares Aligned_with ZAI-ARCH-002; ZAI-ARCH-002 does not reciprocate (file: skills/anti-monolith/SKILL.md:7)

Result: PASS (13/13 hard checks, 5 warnings)
```

### 6.2. JSON (`--json`)

```json
{
  "version": "1.0.0",
  "platform_root": "/home/user/Z-ai-governance",
  "repos_scanned": ["standards", "guard", "skills", "platform"],
  "summary": {
    "ids_extracted": 73,
    "related_edges": 142,
    "aligned_with_edges": 8,
    "hard_pass": 13,
    "hard_fail": 0,
    "warnings": 5
  },
  "checks": [
    { "id": "G01", "status": "PASS", "description": "No duplicate IDs" },
    { "id": "G02", "status": "PASS", "description": "References resolve" },
    { "id": "G14", "status": "PASS", "description": "Compatibility DAG valid" },
    { "id": "G15", "status": "PASS", "description": "Aligned_with has Related" },
    ...
  ],
  "warnings": [
    {
      "id": "W01",
      "referenced_id": "ZAI-META-001",
      "message": "Referenced by 3 files; migration window open until Z-ai-skills v2.0.0",
      "referencing_files": ["standards/STANDARDS.md", "guard/AGENT_RULES.md", "skills/skill-creator/SKILL.md"]
    },
    {
      "id": "W08",
      "left": "ZAI-ARCH-002",
      "right": "STD-DESIGN-001",
      "declared_by": "ZAI-ARCH-002",
      "message": "ZAI-ARCH-002 declares Aligned_with STD-DESIGN-001; STD-DESIGN-001 does not reciprocate",
      "file": "skills/anti-monolith/SKILL.md",
      "line": 7
    },
    ...
  ],
  "failures": []
}
```text

---

## 7. Integration Points

### 7.1. pre-commit Hook (in Z-ai-governance)

`Z-ai-governance/install-hooks.sh` installs a pre-commit hook that runs:

```bash
# Fast checks first (per-repo):
standards/scripts/verify-standards.js --ci || exit 1
guard/scripts/run-pre-commit.sh || exit 1

# Cross-repo check (slower, only if any .md/.sh/.js/.ts changed):
if git diff --cached --name-only | grep -qE '\.(md|sh|js|ts)$'; then
  standards/scripts/verify-id-graph.js --ci || exit 1
fi
```

The `--ci` flag skips network-dependent checks (e.g. fetching latest
`MIGRATIONS.md` from upstream) and runs only local invariants.

### 7.2. Per-Repo CI (GitHub Actions, in each repo's `.github/workflows/`)

```yaml
- name: verify-id-graph
  run: |
    # Each repo's CI clones the other 3 repos as shallow submodules,
    # then runs the graph checker.
    node ../standards/scripts/verify-id-graph.js --ci --json > result.json
    # Upload result.json as artifact for cross-repo CI to consume.
```None

### 7.3. Cross-Repo CI (in Z-ai-governance `.github/workflows/cross-repo.yml`)

Runs nightly at 06:00 UTC. Checks out all four repos at their pinned
versions, runs `verify-id-graph.js` in full mode (not `--ci`), uploads
the JSON result. Opens a GitHub issue if any check fails.

### 7.4. doctor.sh Integration

`Z-ai-governance/doctor.sh` calls `verify-id-graph.js` as part of its
diagnostic suite. If the script exits 2 (config error), doctor reports
"ID graph checker misconfigured"; if exits 1, "ID graph has violations —
see report".

---

## 8. Implementation Notes

### 8.1. Language & Dependencies

- **Language**: Node.js (ESM), no external dependencies. Pure stdlib
  (`fs`, `path`, `readline`).
- **YAML parsing**: hand-rolled mini-parser for the limited subset used
  in skill frontmatter (key: value, no nesting, no anchors). Avoids
  pulling in `js-yaml` for a 50-line parser.
- **Node version**: >= 18 (uses native `fetch` if network mode is ever
  added; v1.0.0 has no network code).
- **Lines of code estimate**: ~750 (extractor ~250, graph builders ~150,
  validators ~250, output formatters ~100).

### 8.2. Extractor Reuse

The unified extractor (STD-META-001 §5.4) is shared with
`verify-standards.js`. Refactor `verify-standards.js` to import the
extractor from `verify-id-graph.js` (or extract to a shared
`lib/id-extractor.js`). This prevents format drift between the two
checkers.

### 8.3. Performance

- Expected ID count across all repos: ~75 (20 STD + 17 RULE + 7 PROC + 6 TOOL + 24 ZAI + 1 STD-SKILL)
- Expected `Related:` edge count: ~150
- Expected `Aligned_with:` edge count: ~10
- Tarjan's SCC on `Related:` graph: <10ms
- Compatibility DAG check: <5ms
- Total runtime: <700ms (excluding file I/O)

No caching needed at v1.0.0.

### 8.4. Testing

Test fixtures live in `Z-ai-standards/tests/verify-id-graph/`:

| Fixture | What it tests | Expected |
|---|---|---|
| `fixtures/valid/` | Miniature 4-repo setup, all checks pass | exit 0, 0 warnings |
| `fixtures/cycle/` | `Related:` cycle RULE->RULE->RULE | G03 fails, exit 1 |
| `fixtures/forbidden-edge/` | STD->ZAI `Related:` edge | G07 fails, exit 1 |
| `fixtures/dangling/` | Reference to non-existent ID | G02 fails, exit 1 |
| `fixtures/deprecated/` | Reference to deprecated ID in window | W01, exit 0 |
| `fixtures/deprecated-closed/` | Reference to deprecated ID past window | G05 fails, exit 1 |
| `fixtures/aligned-without-related/` | `Aligned_with:` without corresponding `Related:` | G15 fails, exit 1 |
| `fixtures/aligned-non-reciprocal/` | One-sided `Aligned_with:` | W08, exit 0 |
| `fixtures/compat-violation/` | `both` skill depends on `sandbox` skill | G14 fails, exit 1 |
| `fixtures/frontmatter-mismatch/` | YAML frontmatter `id` != blockquote `ID:` | W07, exit 0 |
| `fixtures/yaml-only/` | Skill with YAML frontmatter but missing blockquote | W07 (no blockquote to compare), exit 0 |

Each fixture has an expected `exit-code` and `expected-warnings.json` file.
CI runs the script against each fixture and compares.

---

## 9. Open Questions (to resolve before implementation)

1. **Should Z-ai-governance declare its own IDs?** Currently §3.2 says
   "platform is meta; scanned for references only". But platform has
   `install.sh`, `doctor.sh`, etc. — should those be `PROC-PLATFORM-005`?
   *Resolution (v2): yes, they're already in STD-META-001 §4.14. Platform
   just doesn't have its own prefix; it reuses PROC-*.

2. **Should `MIGRATIONS.md` be machine-readable JSON instead of Markdown?**
   *Resolution (v2): keep Markdown; parse with a simple regex per
   STD-META-001 §8.3 format. Add JSON sidecar `migrations.json` only if
   parsing becomes a bottleneck.

3. **What happens when a repo is missing entirely** (e.g. user installed
   only `core` profile = standards + guard, no skills)?
   *Resolution (v2): `verify-id-graph.js --ci` skips missing repos
   silently and notes "ZAI- checks skipped: skills repo not present" in
   summary. ZAI-specific checks (G14) are skipped. Cross-repo CI
   (full mode) requires all four.

4. **Versioning of the script itself.** It declares `TOOL-VERIFY-004 v1.0.0`.
   *Resolution (v2): SemVer. G-checks added = MINOR. G-checks removed/renamed
   = MAJOR. W-checks added = PATCH.

5. **NEW in v2:** Should `Aligned_with:` be allowed to form cycles?
   *Resolution (v2): yes, per STD-META-001 §6.3 rule 3. `Aligned_with:`
   is undirected and explicitly excluded from cycle checks. Three skills
   may all be `Aligned_with:` each other without violating any invariant.

6. **NEW in v2:** How to handle ZAI-META-001 during the migration window?
   *Resolution (v2): ZAI-META-001 is marked `[SUPERSEDED]` in the catalog.
   References to it produce W01 (during window) or G05 (after window).
   The thin-pointer file in Z-ai-skills continues to declare ZAI-META-001
   so it remains in the catalog as a tombstone until v2.0.0 of Z-ai-skills.

---

## 10. Roadmap

| Version | Target | Key changes |
|---|---|---|
| 1.0.0 | Initial implementation | G01–G15, W01–W08, YAML/blockquote/HTML-comment extractor, basic CLI |
| 1.1.0 | Semantic duplicate detection | G13 reused for fuzzy match of rule text under two IDs |
| 1.2.0 | Migration map visualization | `--dot` flag emits Graphviz output for the ID graph |
| 1.3.0 | Partial-repo mode | `--only=guard,skills` runs only relevant subgraph (faster CI per PR) |
| 2.0.0 | Network mode | Fetch upstream `MIGRATIONS.md` from GitHub API |

---

*End of verify-id-graph.js specification v1.0 — APPROVED 2026-06-17.*
