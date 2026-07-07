# AGENT_RULES.md Template v1.0

> ID: STD-DOC-007
> Version: 1.0
> Level: **[W] Warning**
> Related: META-001-standard-id-system, ARCH-001-architecture

This template defines the structure for project `AGENT_RULES.md` files.

---

## 1. Purpose

AGENT_RULES.md is the **single orchestration entry point** for any agent
operating in the project. It tells the agent what to read, in what order,
what overrides what, and what is prohibited.

---

## 2. Rules

| Rule                | Description                                     |
| ------------------- | ----------------------------------------------- |
| Single entry point  | If agent reads only one file, it should be this |
| Priority order      | Define conflict resolution between sources      |
| Onboarding protocol | Sequential steps for session start              |
| Prohibitions        | What agents must never do                       |

---

## 3. File Structure

```markdown
# AGENT_RULES.md -- Single Entry Point for [Project] Agents

> **Owner**: [maintainer]
> **Target**: [project version]
> **Status**: ACTIVE

This file is the single orchestration entry point for any agent
operating in [project]. If you read only one file at session start,
read this one.

---

## Section 1. Onboarding Protocol (run at session start)

Sequential. Each step depends on the previous.

Step 1. Read this file (AGENT_RULES.md)
Step 2. Read standards (if any)
Step 3. Load skill catalog (if any)
Step 4. Load rule registry (if any)
Step 5. Run sanity verifiers (if any)

---

## Section 2. Priority Order (Conflict Resolution)

When two sources disagree, the higher one wins.

Priority 1 (highest) Standards
Priority 2 Rules
Priority 3 AGENT_RULES.md (this file)
Priority 4 (lowest) Skills

---

## Section 3. Prohibitions

What agents must never do:

- Never push to upstream repos without approval
- Never modify standards without PR
- Never skip pre-commit checks
```text

---

## 4. Sections

| Section             | Required    | Description                         |
| ------------------- | ----------- | ----------------------------------- |
| Onboarding Protocol | yes         | Sequential steps for session start  |
| Priority Order      | yes         | Conflict resolution between sources |
| Prohibitions        | yes         | What agents must never do           |
| Rule Registry       | conditional | If project has runtime rules        |
| Skill Catalog       | conditional | If project has agent skills         |
| Verifiers           | conditional | If project has CI checks            |

---

## 5. HTML-Comment Style

Use HTML comments for metadata inside AGENT_RULES.md:

```markdown
<!-- RULE-ANSWER-001: Answer before act -->

Do not start work without confirming the task.

<!-- RULE-WORKLOG-002: Worklog before/after -->

Append to worklog.md before AND after every action.
```

---

## 6. Example

```markdown
# AGENT_RULES.md -- Single Entry Point for My-Project Agents

> **Owner**: maintainer@example.com
> **Target**: v1.0.0
> **Status**: ACTIVE

---

## 1. Onboarding Protocol

Step 1. Read this file
Step 2. Read README.md
Step 3. Check .env for configuration

---

## 2. Priority Order

Priority 1: README.md (project overview)
Priority 2: AGENT_RULES.md (this file)
Priority 3: docs/ (detailed documentation)

---

## 3. Prohibitions

- Never commit directly to main
- Never skip tests
- Never expose secrets
```text

---

## 7. Anti-patterns

- [FAIL] Multiple entry points (agent confused about what to read)
- [FAIL] Missing priority order (conflicts unresolved)
- [FAIL] No prohibitions (agent does dangerous things)
- [FAIL] Using emoji instead of text tags
- [FAIL] Mixing languages within same file
