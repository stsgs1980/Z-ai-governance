# Standard: README Template v3.0

> ID: STD-DOC-004
> Version: 3.0
> Level: **[W] Warning**
> Related: Markdown Standard (STD-DOC-002), Unicode Policy (STD-DOC-003)

This template defines the structure for all project README files.

---

## 1. Language Rule

Default language is **English**. Russian is allowed only when the project task is in Russian or the target audience is Russian-speaking. One language per README - no mixing.

## 2. Size Rules

| Rule | Threshold | Action |
|------|-----------|--------|
| TOC required | README > 150 lines | Add Table of Contents after Badges |
| TOC recommended | README 50-150 lines | Add Table of Contents |
| TOC not needed | README < 50 lines | Skip |
| Soft limit | README > 300 lines | Move details to `/docs/`, keep README as entry point |
| Section overflow | Section > 40 lines | Candidate for extraction to `/docs/` |

## 3. Section Map

| # | Section | Status | When to Include |
|---|---------|--------|-----------------|
| 1 | Title + Description | **Required** | Always |
| 2 | Badges | **Required** | Always (at least: status or license) |
| 3 | Table of Contents | Conditional | Required if >150 lines, recommended if >50 |
| 4 | Features | **Required** | Always |
| 5 | Tech Stack | **Required** | Always |
| 6 | Getting Started | **Required** | Always (Prerequisites + Installation + Run) |
| 7 | Architecture | Optional | Non-trivial projects. Paragraph + link to `docs/` |
| 8 | Project Structure | Optional | Repos with non-obvious layout. List format only |
| 9 | API Reference | Conditional | Only if the project has API endpoints |
| 10 | Screenshots | Recommended | UI applications and visual tools |
| 11 | Scripts | Optional | Non-obvious commands beyond dev/build/lint |
| 12 | Configuration | Conditional | Only if env vars or settings exist |
| 13 | Status / Roadmap | Optional | WIP projects with phases or milestones |
| 14 | Contributing | Optional | Brief inline + link to `CONTRIBUTING.md` |
| 15 | Agent Rules | Conditional | Only if `AGENT_RULES.md` exists in project root |
| 16 | License | **Required** | Always |
| 17 | Stack Signature | Conditional | Required for app repos, forbidden for governance |

### Section Order

Sections appear in the order listed above. Omit sections that do not apply. The order is strict for included sections.

### Governance Exclusion

Stack Signature is **forbidden** in governance documents (standards, rules, skills, templates, orchestrator/meta-repos). Scope test: "Does this repo ship a runnable application whose stack a reader would care about?" If no, omit the footer. See STD-DOC-002 section 8.

---

## 4. Format Rules

These rules supplement STD-DOC-002 and STD-DOC-003. All [C] Critical rules from those standards apply.

| Rule | Correct | Incorrect |
|------|---------|-----------|
| `#` usage | One H1 for project name only | `# Clone`, `# Install` as H1 |
| List marker | `-` (dash) only | `*`, `+`, `->` |
| Project Structure | List format | Tree with Unicode pseudographics |
| Package manager | One (bun or npm) | `npm / yarn / pnpm / bun` alternatives |
| Code fences | Language always specified | Empty code fence without language |
| Separators | No `---` between sections | `---` after every H2 |
| Description length | 1-2 sentences after H1 | Full paragraph or missing |

### What Belongs in README vs /docs/

| In README (entry point) | In /docs/ (details) |
|--------------------------|---------------------|
| What the project does | Architecture diagrams |
| How to install and run | API request/response examples |
| Key features (5-10 bullets) | Component API documentation |
| High-level tech stack | DXF format specifications |
| Brief architecture (1-3 sentences) | Canvas tool reference |
| Project structure (list, 5-10 items) | Development rules and constraints |
| Status overview | CADSoftTools link collection |
| Screenshots | Workflow guides |

---

## 5. Template

````markdown
# Project Name

Brief description of the project (1-2 sentences). What it does and why it exists.

[![Status: Draft](https://img.shields.io/badge/Status-Draft-yellow.svg?style=flat-square)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)]()

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)

## Features

- **Feature 1** - description
- **Feature 2** - description
- **Feature 3** - description

## Tech Stack

- **Framework** - description
- **Language** - description
- **Database** - description
- **Other** - description

## Getting Started

### Prerequisites

- Node.js 18+ or Bun
- Other requirements

### Installation

```bash
git clone https://github.com/owner/repo.git
cd repo
bun install
```

### Run

```bash
bun run dev
```

## Architecture

Brief architecture description (1-3 sentences). See [docs/architecture.md](docs/architecture.md) for full details.

## Project Structure

- `src/app/` - Application routes and pages
- `src/components/` - UI components
- `src/lib/` - Utilities and shared logic
- `prisma/` - Database schema

## API Reference

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/resource` | GET | List all resources |
| `/api/resource` | POST | Create resource |
| `/api/resource/[id]` | GET, PUT, DELETE | Read / Update / Delete |

## Screenshots

> Add screenshots of the key screens.

## Scripts

| Script | Description |
|--------|-------------|
| `bun run dev` | Development server |
| `bun run build` | Production build |
| `bun run lint` | Lint check |

## Configuration

### Environment Variables

See `.env.example`:

```env
DATABASE_URL="file:./db/dev.db"
```

## Status

| Phase | Status | Description |
|-------|--------|-------------|
| Phase 1 | Done | Core feature |
| Phase 2 | In Progress | Enhancement |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. PRs are welcome.

## Agent Rules

Any AI agent working on this project MUST read and follow `AGENT_RULES.md` before performing any operations.

## License

MIT

---
Built with: Next.js 16 + TypeScript + Tailwind CSS
````

### Template Notes

- Sections 7-15 are optional/conditional - remove what does not apply
- Badges: at minimum one badge (status or license). Use shields.io with `style=flat-square`
- Stack Signature: required for app repos, forbidden for governance (see section 3)
- Format: `Built with: <technologies>` - components separated by `+` (see STD-DOC-002 section 8)

---

## 6. Checklist

Before submitting, verify:

- [ ] One language throughout (EN default, RU only if task requires)
- [ ] One H1 for project name only
- [ ] Badges present (at minimum: status or license)
- [ ] All 5 required sections included (Title, Features, Tech Stack, Getting Started, License)
- [ ] TOC present if README > 150 lines
- [ ] No section > 40 lines (extract to `/docs/` if so)
- [ ] README < 300 lines (soft limit)
- [ ] Project Structure in list format (no tree)
- [ ] One package manager in install instructions
- [ ] Code blocks have language specified
- [ ] No emoji, no Unicode icons (STD-DOC-003)
- [ ] No em dash or typographic characters in headings (STD-DOC-002)
- [ ] Unordered lists use `-` marker only
- [ ] No `---` separators between sections
- [ ] Agent Rules section present if `AGENT_RULES.md` exists
- [ ] Stack Signature present for app repos, absent for governance

---

## 7. Cross-References

| Standard | Relationship |
|----------|-------------|
| STD-DOC-002 | Markdown Standard: formatting rules for README content |
| STD-DOC-003 | Unicode Policy: character rules (no emoji, no Unicode icons) |
| STD-ARCH-001 | Implementation Order: README assembly is Step 6 |

---

## 8. Version History

| Version | Date | Changes |
|--------|------|---------|
| 2.0 | 2026-05 | Restructured: mandatory sections table, template, checklist |
| 2.1 | 2026-05 | Added Stack Signature format note; added Agent Rules section |
| 2.2 | 2026-06 | Updated STD-DOC-002 citations. Added Known Issues (RMT-001 to RMT-004). Added Cross-References. |
| 2.3 | 2026-06 | Stack Signature scope cleanup. Removed 3-component format restriction. |
| 3.0 | 2026-06 | Major revision based on audit of 46 repositories. Changes: Badges promoted to Required. Added Language Rule (EN default). Added Size Rules (TOC thresholds, 300-line soft limit, 40-line section overflow). Added 5 new optional sections (Architecture, Screenshots, Status, Contributing, TOC). Added Format Rules table with correct/incorrect examples. Added "README vs /docs/" decision matrix. Added Project Structure format rule (list only, no tree). Added single package manager rule. Template rewritten with all 17 sections and inline comments. RMT-003 RESOLVED (section numbering now matches between table and template). RMT-002 deferred (AGENT_RULES.md governance left to future standard). Checklist expanded from 9 to 16 items. |

---

## 9. Known Issues

### RMT-002 `[OPEN]` - `AGENT_RULES.md` is referenced but never defined

Carried from v2.3. No governing standard defines the structure, creation process, or relationship of `AGENT_RULES.md`. Section 15 in this template references it conditionally. Decision deferred: will be addressed by a dedicated standard (STD-DOC-006) or by merging into an existing standard.

### RMT-003 `[RESOLVED in v3.0]` - Section numbering mismatch between table and template

The v2.3 template did not preserve the numbering from the sections table, making verification difficult. Resolved in v3.0: the template now follows the exact order from the Section Map table (section 3), and each template section implicitly corresponds to its row number.

### RMT-005 `[OPEN]` - No automated validation for size rules

TOC threshold (150 lines) and soft limit (300 lines) are defined but not checked by `check-md.sh` or `lint-md.js`. These are currently manual checklist items. Proposed: add line-count checks to `check-md.sh` in a future version.
