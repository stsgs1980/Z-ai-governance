# ID Assignment Guide

This reference provides detailed guidance on assigning IDs to new skills.

---

## Quick Reference

### ID Format

```text
ZAI-<DOMAIN>-<NUMBER>
```

### Domain Selection

Choose the domain that BEST fits the skill's primary purpose:

| Domain | When to Use |
|--------|-------------|
| `MEM` | Memory operations: store, query, delete, export records |
| `FS` | File system: folder indexing, file scanning |
| `SESSION` | Session management: handoff, resume, context, logging |
| `DEV` | Development: project clone, commit, schema design |
| `ARCH` | Architecture: diagrams, C4, mermaid, database schemas |
| `QA` | Testing: test plans, validation, quality checks |
| `REQ` | Requirements: PRD, clarity, specifications |
| `META` | Meta-skills: skill creation, ID system, toolkit itself |
| `DEVTOOLS` | Developer tools and utilities |
| `GIT` | (reserved) Git operations: clone, branch, checkpoint |
| `SDK` | (reserved) API integration: z-ai-web-dev-sdk |
| `SEC` | (reserved) Security: input validation, sanitization |
| `DOC` | (reserved) Documents: PDF, DOCX, PPT generation |
| `HEALTH` | (reserved) Monitoring: API health, fallback, circuit breaker |

---

## Number Assignment

### Finding Next Number

1. Search all `SKILL.md` files in `skills/` directory for `id: ZAI-<DOMAIN>-` pattern
2. Find the highest number in that domain
3. Add 1 for the new skill

### Example

Current MEM skills found in SKILL.md files:
- ZAI-MEM-001: memory-store
- ZAI-MEM-002: memory-query
- ZAI-MEM-003: memory-delete
- ZAI-MEM-004: memory-export

Next MEM skill: ZAI-MEM-005

---

## User-Created Skills (DEVTOOLS Domain)

**IMPORTANT:** Skills created by the user should ALWAYS use `ZAI-DEVTOOLS-XXX`.

This distinguishes them from toolkit skills and prevents conflicts.

### Naming Convention

- Folder name: `my-skill/` (no special suffix required)
- ID uses `DEVTOOLS` domain: `ZAI-DEVTOOLS-XXX`

### Current DEVTOOLS Registry

| ID | Skill Name | Status |
|----|------------|--------|
| ZAI-DEVTOOLS-001 | skill-creator | Active |

When creating a user skill:
1. Find first available ZAI-DEVTOOLS-XXX
2. Assign to new skill
3. Create folder with skill name
4. Update registry with skill name

---

## Conflicts

### What if domain is unclear?

If a skill could fit multiple domains:
1. Choose the PRIMARY function
2. If equal, prefer: MEM > FS > SESSION > DEV > ARCH > QA > REQ > META > DEVTOOLS > GIT > SDK > SEC > DOC > HEALTH

### What if number is taken?

Check the registry carefully. If a number is skipped, use the first available.

---

## Updating the Registry

After creating a skill with an ID:

1. The skill is automatically registered via its SKILL.md frontmatter
2. No separate registry update needed
3. Commit changes

---

## Examples

### Example 1: API Testing Skill

**Skill purpose:** Automated API endpoint testing

**Domain analysis:**
- Could be QA (testing)
- Could be SDK (API integration)
- Primary function: testing

**Decision:** QA

**ID:** ZAI-QA-002 (next after ZAI-QA-001 qa-test-planner)

### Example 2: User's Custom Report Generator

**Skill purpose:** Weekly report generation from Jira

**Domain analysis:**
- Could be DOC (documentation)
- Could be DEVTOOLS (user-created)

**Decision:** DEVTOOLS (user-created takes priority for custom skills)

**ID:** ZAI-DEVTOOLS-002, folder: `weekly-report/`

### Example 3: Memory Backup Skill

**Skill purpose:** Backup memory database to file

**Domain analysis:**
- Could be MEM (memory operations)
- Could be FS (file system)

**Decision:** MEM (primary function is memory)

**ID:** ZAI-MEM-005 (next available)

---

## Verification Checklist

Before finalizing ID:

- [ ] Searched SKILL.md files for current skills
- [ ] Confirmed domain selection
- [ ] Verified number is available
- [ ] Updated SKILL.md frontmatter

---

Built with: Z.ai Agent Toolkit
