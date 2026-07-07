# Z-ai-governance Structure Handbook

> Quick reference for every directory and key file in the project root.
> For full specifications, see the corresponding standards in `standards/`.

---

## Directories

### `.husky/`

Git hooks (Husky v9). Run automatically on `git commit`.

| Hook          | Purpose                                                                                                      | Level                    |
| ------------- | ------------------------------------------------------------------------------------------------------------ | ------------------------ |
| `pre-commit`  | co-change check + worklog + verify-standards + verify-id-graph + verify-skills + line-count + lint-staged     | HARD (blocks the commit) |
| `commit-msg`  | Conventional Commits validation (G4/G5/G6)                                                                   | HARD                     |

Override: `git commit --no-verify` (emergency use only).

---

### `.github/workflows/`

GitHub Actions CI pipelines.

| Workflow              | Purpose                                                                                    |
| --------------------- | ------------------------------------------------------------------------------------------ |
| `verify-id-graph.yml` | verify-standards.js + verify-id-graph.js + verify-skills.js + line-count-check + graph gen |
| `e2e-verifiers.yml`   | E2E verifier validation                                                                    |

Triggered on push/PR to main + nightly (03:00 UTC).

---

### `.zai/`

Internal Z.ai sandbox configuration.

| File          | Purpose                     |
| ------------- | --------------------------- |
| `config.json` | Sandbox configuration        |
| `setup.sh`    | Primary sandbox setup        |
| `lib/`        | Wrappers: check-worklog.sh (delegates to guard/scripts/) |
| `verify`      | Configuration verification   |

---

### `eslint-rules/`

Custom ESLint rules for Markdown.

| File                     | Rule                                                        |
| ------------------------ | ----------------------------------------------------------- |
| `code-block-language.js` | Code blocks must specify a language (STD-DOC-002 4.3)       |
| `unicode-policy.js`      | Prohibits emoji/Unicode graphics in .md files (STD-DOC-003) |

---

### `eslint-processors/`

ESLint processors for extracting code from Markdown.

| File                   | Purpose                                            |
| ---------------------- | -------------------------------------------------- |
| `markdown-snippets.js` | Extracts code blocks from .md for ESLint checking  |

---

### `guard/`

Enforcement rules and procedures.

| Directory/file  | Purpose                                                                                                        |
| --------------- | -------------------------------------------------------------------------------------------------------------- |
| `rules/`        | 17 rules RULE-001..017 (atomic rules)                                                                          |
| `scripts/`      | 18 scripts: 13 check-*.sh (integrity), co-change-check + worklog-check + line-count-check (PROC), setup-001 + update-002 (setup) |
| `instructions/` | Procedure instructions                                                                                         |
| `tools/`        | Tools (verify-docs, bump)                                                                                      |
| `registry.json` | Rule registry with statuses                                                                                    |

---

### `standards/`

Normative standards + verifiers.

| Directory/file  | Purpose                                                              |
| --------------- | --------------------------------------------------------------------- |
| `standards/`    | 19 .md standards (STD-FE-001, STD-DOC-002, ...)                      |
| `templates/`    | Templates: README, WORKLOG, CHANGELOG, AGENT_RULES                   |
| `guides/`       | Optional guides (CODE_EXAMPLES_GUIDE)                                 |
| `docs/sandbox/` | Sandbox documentation (hooks, commands)                                |
| `scripts/`      | Verifiers: verify-standards.js, verify-id-graph.js, verify-skills.js  |
| `_snapshots/`   | Baseline for ID graph snapshot comparison                             |

---

### `skills/`

Skills directory (monorepo, not submodules).

| Skill                            | Purpose                                          |
| -------------------------------- | ------------------------------------------------ |
| `zai-anti-monolith`              | Automatic decomposition when thresholds exceeded |
| `zai-debugging`                  | Systematic debugging                             |
| `zai-frontend-styling-expert`    | CSS/Tailwind styling                             |
| `zai-md-std`                     | Markdown standard                                |
| `zai-mermaid-diagrams`           | Mermaid diagrams                                 |
| `zai-performance-code-generator` | Code optimization                                |
| `zai-phi-layout`                 | Golden ratio layout                              |
| `zai-project-clone`              | Project cloning                                  |
| `zai-prompt-engineering`         | Prompt engineering                               |
| `zai-sandbox-rules`              | Sandbox rules                                    |
| `zai-skill-creator`              | Skill creation                                   |
| `zai-ui-composer`                | UI composition                                   |
| `zai-workflow-discipline`        | Workflow discipline                              |

---

### `src/`

Project source code (infrastructure tests).

| File                     | Purpose                                                                     |
| ------------------------ | --------------------------------------------------------------------------- |
| `infrastructure.test.ts` | Infrastructure check: package.json, tsconfig, .gitignore, .husky            |

---

### `tests/`

Sandbox integration tests (bash).

| File                          | Purpose                          |
| ----------------------------- | -------------------------------- |
| `sandbox-integration-test.sh` | 20 sandbox integration tests     |
| `sandbox-behavior-test.sh`    | 10 sandbox behavior tests        |
| `edge-case-tests.sh`          | 15 edge-case tests               |

---

### `graph/`

ID graph data (generated by CI).

| File                     | Purpose                                   |
| ------------------------ | ----------------------------------------- |
| `id-graph.json`          | Full graph in JSON (for graph-viewer)     |
| `id-graph-summary.json`  | Graph summary (for dashboards/health)     |
| `README.md`              | API documentation for external tools      |

---

### `eslint.config.js`

ESLint flat config (v9+). Maps rules from `eslint-rules/` and `eslint-processors/`.

---

### `vitest.config.ts`

Vitest configuration for TypeScript tests.

---

### `tsconfig.json`

TypeScript configuration (strict mode, ES2022+, ESNext modules).

---

## Key Root Files

| File                              | Purpose                                                        |
| --------------------------------- | --------------------------------------------------------------- |
| `AGENT_RULES.md`                  | Agent entry point: onboarding protocol, priorities, prohibitions |
| `README.md`                       | Project description                                            |
| `CHANGELOG.md`                    | Changelog (Keep a Changelog format)                            |
| `CONTRIBUTING.md`                 | Contributor guide                                              |
| `worklog.md`                      | Append-only action log (STD-DOC-008)                           |
| `bootstrap.sh`                    | Single entry point: install + update + restore                 |
| `scripts/status.sh`               | Project health diagnostics                                     |
| `scripts/build-skills-registry.cjs`| Build skills registry JSON from SKILL.md frontmatter            |
| `scripts/validate-skills.cjs`    | Validate skills registry and connections                       |
| `package.json`                    | NPM configuration: scripts, dependencies                       |
| `.prettierrc`                     | Prettier: LF, 100 chars, double quotes                         |
| `.zai/config.json`                | Single source of thresholds for governance                     |
| `.env.example`                    | Environment variable example                                   |

---

## npm Scripts

| Command                 | Action                   |
| ----------------------- | ------------------------ |
| `npm run lint`          | ESLint for .ts/.tsx      |
| `npm run lint:fix`      | ESLint + auto-fix        |
| `npm run format`        | Prettier formatting      |
| `npm run format:check`  | Prettier check           |
| `npm run typecheck`     | TypeScript check         |
| `npm run test`          | Vitest run               |
| `npm run test:watch`    | Vitest in watch mode     |
| `npm run test:coverage` | Vitest + coverage        |
| `npm run check:md`      | Markdown check           |
| `npm run check:graph`   | verify-id-graph.js       |
| `npm run validate`      | lint + typecheck + test  |
| `npm run prepare`       | Husky install            |

---

## Data Flows

```bash
git commit
  -> .husky/pre-commit
       -> Group 0: guard/scripts/check-*.sh (13 integrity scripts, HARD)
       -> Group 1: guard/scripts/co-change-check.sh + worklog-check.sh (HARD)
       -> Group 2: standards/scripts/verify-*.js (V01-V18, G01-G15, S01-S09, HARD)
       -> Group 3: guard/scripts/line-count-check.sh (SOFT)
       -> npx lint-staged (eslint + prettier)
  -> .husky/commit-msg
       -> Conventional Commits check (G4/G5/G6)

git push -> .github/workflows/verify-id-graph.yml
  -> verify-standards.js
  -> verify-id-graph.js
  -> verify-skills.js
  -> line-count-check.sh
  -> graph generation (mermaid)
```