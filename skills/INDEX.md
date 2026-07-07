# Skills Index

> Index of all skills shipped with Z-ai-platform.
> Auto-loaded by agents via `Skill(command="...")` in the Z.ai sandbox.
> Source: `skills/zai-*/SKILL.md` (monorepo, not a submodule)

---

## 1. Available skills (14)

| Skill | ID | Version | Purpose |
|-------|-----|---------|---------|
| [zai-anti-monolith](./zai-anti-monolith/SKILL.md) | ZAI-ARCH-002 | 1.0 | Modular architecture enforcement. Auto-activates when files > 250 lines, components > 200 lines, or FSD violations are detected. |
| [zai-answer-before-act](./zai-answer-before-act/SKILL.md) | ZAI-DEV-006 | 1.0.0 | **RULE ZERO: Always load first.** Enforces RULE-ANSWER-001: questions get answers, tasks get executed. Decision algorithm with 8 worked examples. |
| [zai-debugging](./zai-debugging/SKILL.md) | ZAI-DEV-004 | 1.0.0 | Systematic debugging methodology for agents. Root-cause analysis, hypothesis testing, log analysis. |
| [zai-frontend-styling-expert](./zai-frontend-styling-expert/SKILL.md) | — | — | Frontend styling guidance: CSS, Tailwind, design tokens, responsive layout. |
| [zai-md-std](./zai-md-std/SKILL.md) | ZAI-DOC-001 | 1.0.0 | Markdown standards enforcement. STD-DOC-002/003 compliance: code fences, no emoji, language tags. |
| [zai-mermaid-diagrams](./zai-mermaid-diagrams/SKILL.md) | — | — | Mermaid diagram creation and validation for documentation. |
| [zai-performance-code-generator](./zai-performance-code-generator/SKILL.md) | — | — | Performance-aware code generation. Algorithmic complexity, memory layout, hot path awareness. |
| [zai-phi-layout](./zai-phi-layout/SKILL.md) | — | — | Phi-based layout and proportions for UI design. Golden ratio, Fibonacci spacing. |
| [zai-project-clone](./zai-project-clone/SKILL.md) | — | — | Project cloning and setup procedure. Handles submodules, dependencies, env. |
| [zai-prompt-engineering](./zai-prompt-engineering/SKILL.md) | — | — | Prompt engineering best practices. Few-shot, chain-of-thought, structured prompts. |
| [zai-sandbox-rules](./zai-sandbox-rules/SKILL.md) | ZAI-DEV-005 | 1.5.0 | **CRITICAL: Load BEFORE any dev server command.** Sandbox rules, port handling, EADDRINUSE, idle timeout. |
| [zai-skill-creator](./zai-skill-creator/SKILL.md) | ZAI-DEVTOOLS-001 | 1.0 | Create, modify, and benchmark skills. Eval, variance analysis, description optimization. |
| [zai-ui-composer](./zai-ui-composer/SKILL.md) | — | — | UI composition patterns. Component design, props API, accessibility, semantic HTML. |
| [zai-workflow-discipline](./zai-workflow-discipline/SKILL.md) | — | — | Workflow discipline: TDD, checkpoints, worklog maintenance, drift prevention. |

---

## 2. When to load which skill

| Scenario | Load first |
|----------|------------|
| ANY dev server command (`bun run dev`, `npm run dev`, `next dev`) | **zai-sandbox-rules** (BLOCKING) |
| File > 250 lines, component > 200 lines, FSD violation | zai-anti-monolith |
| Creating a new skill | zai-skill-creator |
| Writing documentation with diagrams | zai-md-std + zai-mermaid-diagrams |
| Frontend UI work | zai-ui-composer + zai-frontend-styling-expert |
| Debugging an issue | zai-debugging |
| Starting a new project | zai-project-clone + zai-sandbox-rules |
| Writing prompts for LLMs | zai-prompt-engineering |
| Performance-critical code | zai-performance-code-generator |
| Any task in a sandbox | zai-workflow-discipline |

---

## 3. Skill loading order

The agent should load skills **on demand**, not all at once. Priority:

1. **zai-answer-before-act** — at session start, before EVERY user message (RULE ZERO)
2. **zai-sandbox-rules** — always, before any command
3. **zai-workflow-discipline** — at session start
4. **Domain-specific skills** — when the task requires them
5. **zai-anti-monolith** — auto-activates on threshold violations

---

## 4. Adding a new skill

1. Create `skills/zai-<name>/SKILL.md` with required frontmatter
2. Add entry to this INDEX.md
3. Run `node standards/scripts/verify-skills.js` to validate
4. Commit via pre-commit hook (auto-validates)

See `zai-skill-creator` for the full creation workflow.
