# Standard: Subagent Standard v1.1 (EN)

> ID: STD-AGENT-001
> Version: 1.1
> Level: **[C] Critical**
> Last Updated: 2026-06
> Related: STD-ENV-001 (environment), STD-GIT-001 (github), STD-DOC-002 (markdown), STD-META-001 (ID system), STD-META-002 (language policy)

---

## 1. Purpose

This standard defines the contract, lifecycle, and constraints for AI subagents operating within the Z.ai sandbox ecosystem. Subagents are specialized, stateless workers launched by a main agent to perform well-defined subtasks autonomously.

Without this standard, subagent behavior is unregulated: there is no guarantee of result format, no timeout enforcement, no context isolation, and no structured handoff between agents. This leads to unpredictable outputs, lost work, and coordination failures.

### 1.1 Problems Solved

| Problem | Without This Standard | With This Standard |
|---------|-----------------------|---------------------|
| No result format guarantee | Subagents return arbitrary text | Structured result with mandatory fields |
| No timeout enforcement | Subagents run indefinitely | Max 10 minutes per subtask |
| No context isolation | Subagents see full conversation | Only receive explicit prompt |
| No structured handoff | Work lost between sessions | WORKLOG + result template |
| No recursion limit | Subagents spawn subagents infinitely | Max depth = 1 (no nesting) |
| No access control | Subagents can modify any file | File scope restricted per type |

---

## 2. Subagent Types

### 2.1 Registry of Types

| Type | Purpose | File Access | Max Runtime | Output |
|------|---------|-------------|-------------|--------|
| `Explore` | Codebase search, file discovery | Read-only | 5 min | Findings report |
| `Plan` | Architecture design, implementation planning | Read-only | 10 min | Step-by-step plan |
| `full-stack-developer` | Next.js web development | Read + Write (project dir only) | 10 min | Code + summary |
| `general-purpose` | Multi-step research, data processing | Read + Write (project dir only) | 10 min | Structured result |

### 2.2 Type Constraints

Each subagent type has specific constraints that MUST be enforced by the calling agent:

**Explore:**
- MUST NOT modify any files
- MUST NOT execute write operations
- MUST return findings in structured format (files found, search results, analysis)
- SHOULD use quick/medium/thorough search levels appropriately

**Plan:**
- MUST NOT modify any files
- MUST NOT execute write operations
- MUST return a step-by-step plan with identified files, dependencies, and trade-offs
- SHOULD consider architectural implications before proposing changes

**full-stack-developer:**
- MAY read and write files within `/home/z/my-project/` only
- MUST NOT access files outside project directory
- MUST call `Complete` tool when development is finished
- MUST document work in `/home/z/my-project/worklog.md`

**general-purpose:**
- MAY read and write files within `/home/z/my-project/` only
- MUST NOT access files outside project directory
- MUST return results in a structured format

---

## 3. Subagent Contract

### 3.1 Input Contract

Every subagent invocation MUST include:

```text
1. Task ID (global order identifier, e.g., "3", "4-a", "4-b")
2. Task description (clear, unambiguous, self-contained)
3. WORKLOG instruction (read previous + append own entry)
4. Subagent type (from registry in Section 2.1)
5. Any file paths or data needed (no references to conversation context)
```None

**Critical Rule:** Subagents do NOT have access to the full conversation context. They only receive the prompt passed to them. Therefore, all necessary information MUST be included in the prompt explicitly.

### 3.2 Output Contract

Every subagent MUST return:

```text
1. Result summary (what was accomplished)
2. Files created (list of absolute paths)
3. Files modified (list of absolute paths)
4. Key decisions (design choices made and why)
5. Errors encountered (if any, with resolution)
6. WORKLOG entry appended to /home/z/my-project/worklog.md
```

### 3.3 Failure Contract

If a subagent cannot complete its task:

1. It MUST still append a WORKLOG entry with status `failed` or `blocked`
2. It MUST describe the blocker clearly
3. It MUST NOT silently fail without logging
4. It MUST NOT leave the project in a broken state (rollback if possible)

---

## 4. Lifecycle

### 4.1 Subagent Lifecycle Phases

```text
1. SPAWN     Main agent invokes Task tool with type, description, and prompt
2. INITIALIZE Subagent reads WORKLOG to understand previous work
3. EXECUTE   Subagent performs the assigned task
4. REPORT    Subagent returns result + appends WORKLOG entry
5. COMPLETE  Main agent receives result and integrates into workflow
```None

### 4.2 Statelessness

Subagents are **stateless**:
- Each invocation is independent
- No memory persists between invocations
- If context from a previous subagent run is needed, it MUST be read from WORKLOG
- The main agent is responsible for orchestrating sequence and passing context

### 4.3 Concurrency

Multiple subagents MAY run in parallel when:
- They operate on different files or directories
- They have no dependencies on each other's output
- The main agent explicitly requests parallel execution

Subagents MUST NOT run in parallel when:
- They modify the same file
- One depends on the output of another
- They share a resource that is not concurrency-safe (e.g., git operations)

---

## 5. Constraints

### 5.1 Recursion Depth

```text
Main Agent
  +-- Subagent (depth 1)     ALLOWED
       +-- Sub-subagent (depth 2)   FORBIDDEN
```

Subagents MUST NOT spawn further subagents. Maximum depth = 1. If a subagent needs to delegate work, it MUST return to the main agent with a recommendation instead.

### 5.2 Timeout

| Subagent Type | Max Runtime | Action on Timeout |
|---------------|-------------|-------------------|
| Explore | 5 minutes | Return partial findings |
| Plan | 10 minutes | Return partial plan |
| full-stack-developer | 10 minutes | Commit work-in-progress, return summary |
| general-purpose | 10 minutes | Return partial result |

### 5.3 File Scope

Subagents MUST NOT access files outside the project directory:

```text
ALLOWED:   /home/z/my-project/**/*
FORBIDDEN: /etc/**, /root/**, /home/<other-user>/**, ~/.ssh/**
```None

### 5.4 Network Access

Subagents MAY:
- Fetch web resources when explicitly tasked
- Access Z.ai SDK endpoints (chat.z.ai, image generation, web search)

Subagents MUST NOT:
- Expose authentication tokens in logs or output
- Make unauthorized API calls
- Download executables or scripts from untrusted sources

---

## 6. Context Handoff

### 6.1 WORKLOG-Based Handoff

The primary mechanism for context transfer between subagents is the shared WORKLOG file at `/home/z/my-project/worklog.md`.

**Protocol:**

1. Before starting work, subagent reads `/home/z/my-project/worklog.md`
2. After completing work, subagent appends its entry using the standard template
3. The next subagent reads the updated WORKLOG to understand what was done

### 6.2 Structured Handoff Template

For complex multi-session work, use the structured handoff template from `agents/templates/context-handoff-template.md`:

```text
## Handoff Document

### Session Info
- Task ID: <id>
- Date: <date>
- Agent: <type>

### What Was Done
- <completed items>

### What Remains
- <pending items>

### Blockers
- <current blockers>

### Key Decisions
- <decisions made>

### File Map
- <files created/modified>
```

### 6.3 Memory System Integration (FUTURE — not yet implemented)

Subagents MAY interact with the Memory System skills for persistent knowledge storage. The following skills are **planned** but **not yet implemented** in the project — their ZAI-MEM IDs are reserved for future use and should not be relied upon in current subagent code.

| Skill | ID (reserved) | Use Case | Status |
|-------|---------------|----------|--------|
| memory-store | ZAI-MEM-001 | Store findings, decisions, patterns | PLANNED — not implemented |
| memory-query | ZAI-MEM-002 | Retrieve previously stored knowledge | PLANNED — not implemented |
| memory-delete | ZAI-MEM-003 | Remove outdated entries | PLANNED — not implemented |
| memory-export | ZAI-MEM-004 | Export knowledge for handoff | PLANNED — not implemented |

**Until these skills are implemented**, subagents MUST use the WORKLOG-based handoff mechanism (§6.1, §6.2) for all context transfer. Any subagent code that references `ZAI-MEM-*` skills will fail at runtime. See SAG-001 in §11A for the tracking issue.

When using Memory System (once implemented), subagents MUST:
- Use semantic, descriptive entry names
- Include relevant tags for searchability
- Not store sensitive data (tokens, passwords, API keys)

---

## 7. Integration with Other Standards

See Cross-References section at the end of this document for the full relationship table.

### 7.1 Compliance Rules

Subagent outputs MUST comply with:
- **STD-DOC-003** (Unicode Policy): No emoji or Unicode graphics in results
- **STD-DOC-002** (Markdown Standard): Proper formatting in all .md output
- **STD-ENV-001** (Reproducibility): No hardcoded personal paths in generated code

---

## 8. Anti-Patterns

### 8.1 Forbidden Patterns

| Anti-Pattern | Why Forbidden | Correct Approach |
|--------------|---------------|------------------|
| Mega-prompt: sending entire conversation to subagent | Exceeds token limits, loses focus | Extract only relevant context |
| Sequential calls for independent tasks | Wastes time | Parallelize independent subagents |
| Ignoring subagent failure | Silent data loss | Always check result, handle failure |
| Subagent modifying WORKLOG format | Breaks handoff protocol | Use standard template only |
| Subagent spawning another subagent | Unbounded recursion, unpredictable behavior | Return to main agent for delegation |
| Hardcoded paths in subagent prompt | Non-reproducible | Use project-relative paths |

### 8.2 Best Practices

1. **One task per subagent**: Do not combine unrelated work in a single invocation
2. **Include all context**: Subagents cannot read the main conversation
3. **Specify output format**: Tell the subagent exactly what to return
4. **Validate results**: Main agent must check subagent output before using it
5. **Log everything**: Every subagent invocation and result must be in WORKLOG
6. **Commit after each subagent**: If files were modified, commit + push before next task

---

## 9. Checklist

### Before Invoking a Subagent

- [ ] Task is well-defined and self-contained
- [ ] Task ID assigned and included in prompt
- [ ] WORKLOG instruction included in prompt
- [ ] Correct subagent type selected
- [ ] All necessary context included (no references to conversation)
- [ ] File paths are absolute and project-relative
- [ ] Expected output format specified

### After Subagent Returns

- [ ] Result summary received and reviewed
- [ ] Files created/modified verified to exist
- [ ] WORKLOG entry present and well-formed
- [ ] No compliance violations in output (Unicode, paths, formatting)
- [ ] If files modified: commit + push to git
- [ ] Next task can proceed based on result

---

## 10. Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-05 | Initial version: subagent types, contract, lifecycle, constraints, context handoff |
| 1.1 | 2026-06 | §6.3 Memory System Integration marked as FUTURE — the four ZAI-MEM-* skills are not yet implemented in the project; IDs are reserved. Added explicit instruction to use WORKLOG-based handoff (§6.1, §6.2) until the Memory System is built. Added §10A Known Issues documenting SAG-001 through SAG-003. Added STD-META-001 row to §11 Cross-References. |

---

## 10A. Known Issues and Proposed Solutions

This section documents discovered inconsistencies, missing content, and proposed corrections. Each issue has an ID, status, and proposed action. Issues resolved in the current version are marked `[RESOLVED]`; outstanding issues are marked `[OPEN]`.

### SAG-001 `[OPEN]` — §6.3 references skills `ZAI-MEM-001..004` that are not implemented

**Problem:** Prior to v1.1, §6.3 (Memory System Integration) listed four skills (`memory-store`, `memory-query`, `memory-delete`, `memory-export`) with IDs `ZAI-MEM-001` through `ZAI-MEM-004` as if they were available for use. None of these skills exist in the project's `skills/` directory. A subagent following §6.3 would attempt to call non-existent skills and fail at runtime.

**Resolution taken in v1.1:** §6.3 heading now includes "(FUTURE — not yet implemented)". The skill table has a new "Status" column showing "PLANNED — not implemented" for all four entries. The section body explicitly states: "Until these skills are implemented, subagents MUST use the WORKLOG-based handoff mechanism (§6.1, §6.2) for all context transfer."

**Remaining open work:** The four skills need to be either (a) implemented as actual skills in the project's `skills/` directory, or (b) formally removed from this standard. Until then, §6.3 documents intent but cannot be operationalized.

**Proposed solution (long-term):** Implement the Memory System as a set of four skills with the reserved IDs. Suggested locations: `skills/memory-store/`, `skills/memory-query/`, `skills/memory-delete/`, `skills/memory-export/`. Each skill should expose a CLI that subagents can call from their prompts. Once implemented, update §6.3 to remove the "FUTURE" marker and add concrete usage examples.

### SAG-002 `[OPEN]` — §2.1 subagent type registry does not include `general-purpose` (it does, but inconsistency in naming)

**Problem:** §2.1 (Registry of Types) lists `Explore`, `Plan`, `full-stack-developer`, `general-purpose` as the four subagent types. The first two use PascalCase (`Explore`, `Plan`); the last two use kebab-case (`full-stack-developer`, `general-purpose`). This naming inconsistency makes type lookups error-prone (is it `GeneralPurpose` or `general-purpose`?).

**Proposed solution:** Standardize on one convention. Recommended: kebab-case for all four (`explore`, `plan`, `full-stack-developer`, `general-purpose`), matching the `subagent_type` parameter convention in the Task tool. Update §2.1 table and all in-body references. If the change is too disruptive (e.g., existing prompts use PascalCase), add a note: "Type names are case-sensitive; the canonical form is kebab-case, but PascalCase aliases (`Explore`, `Plan`) are accepted for backward compatibility."

### SAG-003 `[OPEN]` — §3.1 Input Contract does not specify the prompt-size limit

**Problem:** §3.1 lists 5 mandatory components of a subagent input (Task ID, description, WORKLOG instruction, subagent type, file paths/data). It does not state a maximum prompt size. §5.2 (Timeout) limits runtime but not input size. A subagent invoked with a 50,000-token prompt will hit context-window limits before doing useful work, with no warning in this standard.

**Proposed solution:** Add a §3.1.1 "Prompt Size Limits" subsection: "Subagent input MUST be under 8,000 tokens. If the task requires more context, the calling agent MUST split the work into multiple subagent invocations (per §4.3 Concurrency) or write context to a file in `/home/z/my-project/` and pass the file path instead of the content." The 8,000-token figure matches typical subagent context windows and aligns with the §8.2 best practice "Include all context: Subagents cannot read the main conversation".

---

## 11. Cross-References

| Standard | Relationship |
|----------|-------------|
| STD-AGENT-002 | Orchestration rules: who calls whom, in what order |
| STD-ENV-002 | Z.ai sandbox constraints and SDK integration |
| STD-GIT-001 | Commit + push after subagent completes file modifications |
| STD-GIT-002 | Sandbox git safety: deadlock prevention for parallel subagents |
| STD-ERR-001 | Error classification and recovery in subagent results |
| STD-META-001 | Standard ID System: registry entry for STD-AGENT-001 must be kept in sync with the version in this document's header. Also tracks the planned ZAI-MEM-* skill IDs once implemented (see SAG-001). |
| STD-META-002 | Language Policy: subagent prompts, results, and WORKLOG in English |
| STD-DOC-003 | Unicode Policy: no emoji or Unicode graphics in subagent output (includes §8.4 chat dialogue rules) |
| STD-DOC-002 | Markdown Standard: proper formatting in all .md output from subagents |
| STD-ENV-001 | Reproducibility: no hardcoded personal paths in generated code |
