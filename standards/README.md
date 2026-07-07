# Z-ai-standards

Normative standards, templates, and guides for the Z-ai ecosystem. Standards describe what is true in a domain -- they are slower-moving, more stable, and may be referenced by rules, procedures, tools, and skills in lower layers.

[![Next.js](https://img.shields.io/badge/Next.js-black?style=flat-square)](https://nextjs.org)
[![React](https://img.shields.io/badge/React-61DAFB?style=flat-square)](https://react.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](https://opensource.org/licenses/MIT)

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Installation Order](#installation-order)
- [Released Standards](#released-standards)
- [Cross-Domain Navigation](#cross-domain-navigation)
- [Scripts](#scripts)
- [Contributing](#contributing)
- [Status](#status)
- [License](#license)

## Features

- 18 normative standards across 12 domains with defined installation order and prerequisite chain
- verify-standards.js enforcing V01-V10 per-repo invariants on every PR
- verify-id-graph.js enforcing G01-G15 cross-repo ID graph integrity
- Cross-domain navigation map linking related standards across domains
- Non-normative templates (README_TEMPLATE.md) and guides (CODE_EXAMPLES_GUIDE.md)
- Migration tracking via MIGRATIONS.md (M001 through M004)
- Structured standard headers with ID, Version, Level, Status, verified_by, and Related fields

## Tech Stack

- **Runtime** - Node.js (verification scripts)
- **CI** - GitHub Actions

## Getting Started

### Prerequisites

- Git
- Node.js 20+

### Installation

```bash
git clone https://github.com/stsgs1980/Z-ai-standards.git
cd Z-ai-standards
```None

### Run

```bash
# Verify per-repo invariants
node scripts/verify-standards.js

# Verify cross-repo ID graph
node scripts/verify-id-graph.js
```

## Project Structure

- `standards/` - 19 normative standards in flat `<DOMAIN>-<NNN>-<name>.md` layout
  - Architecture: META-001, ARCH-001, ARCH-002
  - Documentation: DOC-002, DOC-003
  - Skills: SKILL-001
  - Environment: ENV-001, ENV-002
  - GitHub: GIT-001, GIT-002
  - Design/Frontend: DESIGN-001, FE-001, A11Y-001
  - Errors: ERR-001
  - Security: SEC-001, SEC-002
  - Agents: AGENT-001, AGENT-002
- `templates/` - Non-normative README template (STD-DOC-004)
- `guides/` - Non-normative code examples guide (STD-DOC-005)
- `scripts/` - verify-standards.js (V01-V18), verify-id-graph.js (G01-G15), verify-skills.js (S01-S10)
- `docs/` - Tool specifications
- `MIGRATIONS.md` - ID migration log

## Installation Order

When onboarding a new project or agent, install (read + accept) the 18 standards in this exact order. Each standard depends on concepts introduced by earlier standards. The authoritative spec is `standards/ARCH-002-implementation-order.md`.

| # | ID | File | Prerequisites |
|---|---|---|---|
| 1 | STD-META-001 | META-001-standard-id-system.md | -- |
| 2 | STD-ARCH-001 | ARCH-001-architecture-and-repo-layout.md | META-001 |
| 3 | STD-ARCH-002 | ARCH-002-implementation-order.md | META-001, ARCH-001 |
| 4 | STD-DOC-002 | DOC-002-markdown-standard.md | META-001, ARCH-002 |
| 5 | STD-DOC-003 | DOC-003-unicode-policy.md | DOC-002 |
| 6 | STD-SKILL-001 | SKILL-001-skill-format.md | META-001, DOC-002 |
| 7 | STD-ENV-001 | ENV-001-reproducibility.md | ARCH-001, DOC-002 |
| 8 | STD-ENV-002 | ENV-002-zai-integration.md | ENV-001 |
| 9 | STD-GIT-001 | GIT-001-github.md | ENV-001, DOC-002 |
| 10 | STD-GIT-002 | GIT-002-github-sandbox.md | GIT-001, ENV-002 |
| 11 | STD-DESIGN-001 | DESIGN-001-design-system.md | DOC-002, DOC-003 |
| 12 | STD-FE-001 | FE-001-frontend.md | ENV-001, DOC-002, DESIGN-001 |
| 13 | STD-A11Y-001 | A11Y-001-wcag-2-1-aa.md | FE-001, DESIGN-001 |
| 14 | STD-ERR-001 | ERR-001-error-handling.md | FE-001, DOC-002 |
| 15 | STD-SEC-001 | SEC-001-security-core.md | ENV-001, GIT-001, DOC-002 |
| 16 | STD-SEC-002 | SEC-002-security-extended.md | SEC-001 |
| 17 | STD-AGENT-001 | AGENT-001-subagent.md | ENV-001, GIT-001, DOC-002 |
| 18 | STD-AGENT-002 | AGENT-002-orchestration.md | AGENT-001, ERR-001 |

Non-normative companions (not in install order):

| ID | File | Purpose |
|---|---|---|
| STD-DOC-004 | templates/README_TEMPLATE.md | README template applied during project setup |
| STD-DOC-005 | guides/CODE_EXAMPLES_GUIDE.md | Code block formatting guide |

## Released Standards

| ID | Name | Version | Effective Date | Level |
|---|---|---|---|---|
| STD-META-001 | Standard ID System | 2.0.0 | 2026-06-17 | [C] Critical |
| STD-ARCH-001 | Architecture and Repo Layout | 1.0.0 | 2026-06-17 | [C] Critical |
| STD-ARCH-002 | Implementation Order | 2.4.0 | 2026-06-18 | [C] Critical |
| STD-SKILL-001 | Skill Format and Identification | 1.0.0 | 2026-06-17 | [B] Recommended |
| STD-DOC-002 | Markdown Formatting | 2.3.1 | 2026-06-18 | [W] Warning |
| STD-DOC-003 | Unicode Policy | 2.3.0 | 2026-06-18 | [C]+[W]+[I] |
| STD-DOC-004 | README Template | 2.2.0 | 2026-06-18 | [W] (non-normative) |
| STD-DOC-005 | Code Examples Guide | 1.3.0 | 2026-06-18 | [W] (non-normative) |
| STD-ENV-001 | Reproducibility | 2.1.0 | 2026-06-18 | [C] Critical |
| STD-ENV-002 | Z.ai Integration | 1.2.0 | 2026-06-18 | [C] Critical |
| STD-GIT-001 | GitHub Core | 2.1.0 | 2026-06-18 | [C] Critical |
| STD-GIT-002 | GitHub Sandbox | 1.1.0 | 2026-06-18 | [C] Critical |
| STD-DESIGN-001 | Design System | 3.0.1 | 2026-06-18 | [C]+[W] |
| STD-FE-001 | Frontend Development | 2.4.0 | 2026-06-18 | [C] Critical |
| STD-A11Y-001 | WCAG 2.1 AA Accessibility | 1.2.0 | 2026-06-18 | [C] Critical |
| STD-ERR-001 | Error Handling Core | 2.1.0 | 2026-06-18 | [C] Critical |
| STD-SEC-001 | Security Core | 2.1.0 | 2026-06-18 | [C] Critical |
| STD-SEC-002 | Security Extended | 1.1.0 | 2026-06-18 | [C] Critical |
| STD-AGENT-001 | Subagent | 1.1.0 | 2026-06-18 | [C] Critical |
| STD-AGENT-002 | Orchestration | 1.1.0 | 2026-06-18 | [C] Critical |

## Cross-Domain Navigation

| When working on... | Also check... |
|---|---|
| **Frontend** (FE-001) | A11Y-001 (WCAG), DESIGN-001 (tokens), ERR-001 (boundary patterns) |
| **Errors** (ERR-001) | AGENT-002 (error propagation), FE-001 (Error Boundary) |
| **Security** (SEC-001, SEC-002) | ENV-001 (secrets, env), GIT-001 (push protection) |
| **GitHub** (GIT-001, GIT-002) | ENV-002 (sandbox git rules) |
| **Documentation** (DOC-002, DOC-003) | templates/, guides/ -- apply rules via these artifacts |
| **Design** (DESIGN-001) | FE-001 (token consumption), A11Y-001 (contrast) |
| **Agents** (AGENT-001, AGENT-002) | ERR-001 (recovery) |
| **Environment** (ENV-001, ENV-002) | GIT-001 (sandbox git ops), SEC-001 (secrets) |
| **Meta** (META-001) | Every other file -- meta defines the ID system all use |
| **Architecture** (ARCH-001, ARCH-002) | Every other file -- ARCH-002 defines the install order |

## Scripts

Every PR that touches a `.md` file MUST pass:

```bash
node scripts/verify-standards.js   # V04-V10 per-repo invariants
node scripts/verify-id-graph.js    # G01-G15 cross-repo invariants
```None

The pre-commit hook (`.husky/pre-commit` in repo root) runs all three verify-*.js scripts in Group 2.

## Contributing

To add a new standard:

1. Pick the next available ID in the appropriate domain (see STD-META-001 s4)
2. Determine install position from ARCH-002-implementation-order.md s1
3. Create `standards/<DOMAIN>-<NNN>-<name>.md` with proper header (ID, Version, Level, Status, verified_by, Related)
4. Add entry to the "Installation Order" table above
5. Add entry to the "Released Standards" table above
6. Run `node scripts/verify-standards.js` -- must pass
7. Commit with message: `feat(std): STD-<DOMAIN>-<NNN> v1.0 <name>`

## Status

Active migrations tracked in MIGRATIONS.md:

- **M001**: ZAI-META-001 to STD-SKILL-001 (superseded) -- window open until Z-ai-skills v2.0.0
- **M002**: RULE-001..RULE-017 to RULE-<DOMAIN>-NNN (renamed) -- window NOT YET OPEN
- **M003**: legacy/ flat layout to standards/ flat layout with <DOMAIN>-<NNN>-<name>.md naming -- completed 2026-06-18
- **M004**: ARCH-002-implementation-order.md (was STD-ARCH-001) to new ID STD-ARCH-002 -- completed 2026-06-18

| Version | Date | Change |
|---|---|---|
| 2.1.0 | 2026-06-18 | Flat layout: renamed all 18 standards to <DOMAIN>-<NNN>-<name>.md convention. Merged 3 STUBs with working drafts. Split ARCH into ARCH-001 + ARCH-002. Updated README with install order table for all 18 standards |
| 2.0.1 | 2026-06-18 | Restructured standards/ into per-domain subfolders. Moved templates/ and guides/ |
| 2.0.0 | 2026-06-17 | Initial formalized release. 6 standards formalized as STD-*-vX.Y.md |

## License

MIT