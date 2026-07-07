# Standard: Orchestration Standard v1.1 (EN)

> ID: STD-AGENT-002
> Version: 1.1
> Level: **[C] Critical**
> Last Updated: 2026-06
> Related: STD-AGENT-001 (subagent), STD-ERR-001 (error handling), STD-META-001 (ID system)

---

## 1. Purpose

This standard defines the orchestration layer: how the main agent coordinates multiple subagents, manages task dependencies, and ensures that complex workflows produce consistent, reproducible results. While STD-AGENT-001 defines the contract for individual subagents, this standard defines how they work together.

Without orchestration rules, multi-subagent workflows suffer from:
- Race conditions when parallel subagents modify the same files
- Lost work when subagent results are not committed before the next subagent starts
- Circular dependencies when subagents wait for each other's output
- Inconsistent state when the main agent fails to validate intermediate results

---

## 2. Orchestration Patterns

### 2.1 Sequential Pipeline

```text
Main Agent
  |
  +-- Task 1 (Explore) --> Result 1
  |                          |
  +-- Task 2 (Plan)   <------+  (uses Result 1)
  |                          |
  +-- Task 3 (Code)  <------+  (uses Result 2)
                             |
  +-- Commit + Push  <------+
```

**When to use:** Tasks have strict dependencies; each task needs the output of the previous one.

**Rules:**
- Wait for each subagent to complete before invoking the next
- Validate each result before passing it forward
- Commit + push after any subagent that modifies files

### 2.2 Parallel Fan-Out

```text
Main Agent
  |
  +-- Task 1-a (Explore) --+--> Result 1-a
  +-- Task 1-b (Explore) --+--> Result 1-b
  +-- Task 1-c (Explore) --+--> Result 1-c
  |                         |
  +-- Aggregate <-----------+
  +-- Task 2 (Plan) <-------+  (uses aggregated results)
```

**When to use:** Multiple independent subtasks can run simultaneously, and their results need to be combined before the next step.

**Rules:**
- Subtasks MUST operate on different files or directories
- No shared mutable state between parallel subagents
- Main agent aggregates results before proceeding
- Each parallel subagent gets a unique Task ID (e.g., "2-a", "2-b")

### 2.3 Map-Reduce

```text
Main Agent
  |
  +-- Map Phase (parallel)
  |     +-- Subagent A processes files 1-5
  |     +-- Subagent B processes files 6-10
  |     +-- Subagent C processes files 11-15
  |
  +-- Reduce Phase (sequential)
        +-- Main agent combines all results
        +-- Commit + push final output
```

**When to use:** A large task can be divided into independent chunks that are processed in parallel, then combined.

**Rules:**
- Each chunk must be non-overlapping (no file processed by two subagents)
- The reduce phase must handle missing or failed chunks gracefully
- Chunk size should be balanced to avoid stragglers

### 2.4 Retry with Fallback

```text
Main Agent
  |
  +-- Task 1 (primary subagent) --> Result
  |     |
  |     +-- Success --> Continue
  |     +-- Failure --> Task 1b (fallback subagent) --> Result
  |                         |
  |                         +-- Success --> Continue
  |                         +-- Failure --> Log blocker, ask user
```

**When to use:** Tasks that may fail due to external dependencies (network, API limits, resource availability).

**Rules:**
- Maximum 1 retry with a different approach or subagent type
- Fallback MUST be logged in WORKLOG with reason for primary failure
- If fallback also fails, report blocker to user instead of infinite retry

---

## 3. Task Dependency Management

### 3.1 Dependency Declaration

Every multi-task workflow MUST declare dependencies explicitly:

```text
Task 1:  No dependencies (root task)
Task 2:  Depends on Task 1
Task 3-a: Depends on Task 2
Task 3-b: Depends on Task 2 (parallel with 3-a)
Task 4:  Depends on Task 3-a AND Task 3-b
```

### 3.2 Dependency Validation

Before executing a task, the main agent MUST verify:

1. All dependent tasks have completed successfully
2. Their results are available (WORKLOG entries exist)
3. No blockers were reported in dependent tasks

If any dependency is unmet:
- Do NOT execute the task
- Log the unmet dependency in WORKLOG
- Report to user for resolution

### 3.3 Circular Dependency Prevention

```text
FORBIDDEN:
  Task A depends on Task B
  Task B depends on Task A

ALLOWED:
  Task A depends on Task B
  Task B has no dependencies
```

The main agent MUST detect and reject circular dependencies before execution. This applies to both direct and transitive circular dependencies.

---

## 4. State Management

### 4.1 State Transitions

```text
PENDING --> IN_PROGRESS --> COMPLETED
   |              |
   |              +--> BLOCKED
   |              |
   |              +--> FAILED
   |
   +--> CANCELLED
```

| State | Meaning | Next Action |
|-------|---------|-------------|
| PENDING | Task defined, not started | Check dependencies, then start |
| IN_PROGRESS | Subagent is executing | Wait for result |
| COMPLETED | Task finished successfully | Process result, start dependent tasks |
| BLOCKED | External blocker prevents completion | Log blocker, try fallback or report |
| FAILED | Task failed, no fallback | Log failure, report to user |
| CANCELLED | Task no longer needed | Skip, start next task |

### 4.2 State Tracking

All task states MUST be tracked in WORKLOG using the standard entry format. The main agent maintains a todo list (via TodoWrite tool) that reflects the current state of all tasks.

### 4.3 State Recovery After Interruption

If the main agent session is interrupted:

1. On restart, read WORKLOG to determine which tasks completed
2. Mark incomplete tasks as PENDING again
3. Re-execute only tasks that were IN_PROGRESS (their results may be partial)
4. Skip tasks that were already COMPLETED
5. Resume the workflow from the point of interruption

---

## 5. Git Coordination

### 5.1 Commit Points

A commit + push MUST occur at these points in any orchestrated workflow:

1. **After each file-modifying subagent completes** (not at the end of the workflow)
2. **Before invoking a subagent that depends on the previous subagent's files**
3. **At the end of each orchestration phase** (e.g., after all parallel tasks complete)

### 5.2 Parallel Git Safety

When multiple subagents run in parallel:

- Each subagent MUST operate on a disjoint set of files
- The main agent MUST NOT commit while subagents are still running
- After all parallel subagents complete, the main agent commits once
- If a subagent modifies `.gitignore`, it runs ALONE (not parallel with others)

### 5.3 Conflict Prevention

| Scenario | Prevention Strategy |
|----------|---------------------|
| Two subagents modify same file | Never assign overlapping file sets |
| Subagent modifies WORKLOG while main agent reads | Subagent appends only (never overwrites) |
| Subagent modifies package.json | Run package.json modifications sequentially |
| Subagent creates files in same directory | Assign different subdirectories or filename prefixes |

---

## 6. Error Propagation

### 6.1 Error Escalation Ladder

```text
Level 1: Subagent self-recovery (retry within subagent)
  |
  +-- Failed --> Level 2: Main agent fallback (different subagent type or approach)
                   |
                   +-- Failed --> Level 3: User intervention (report blocker)
```

### 6.2 Error Classification for Orchestration

| Error Type | Orchestration Response |
|------------|----------------------|
| Network timeout | Retry once (same subagent) |
| File not found | Fallback to Explore subagent for discovery |
| Permission denied | Report to user (cannot auto-fix) |
| Dependency not met | Wait for dependency, then retry |
| Result validation failure | Fallback to different subagent type |
| Git conflict | Abort workflow, run deadlock recovery (STD-GIT-002) |

### 6.3 Partial Failure Handling

When a parallel task group has some failures:

1. Collect all successful results
2. Log which subtasks failed and why
3. Determine if partial results are sufficient to proceed
4. If sufficient: proceed with available results, note gaps
5. If insufficient: abort workflow, report to user

---

## 7. Workflow Templates

### 7.1 Standard Development Workflow

```text
Phase 1: Analysis (parallel)
  Task 1-a: Explore codebase structure
  Task 1-b: Explore existing patterns and conventions

Phase 2: Planning (sequential, depends on Phase 1)
  Task 2: Design implementation plan based on analysis

Phase 3: Implementation (sequential, depends on Phase 2)
  Task 3: full-stack-developer implements the plan
  Commit + push

Phase 4: Verification (sequential, depends on Phase 3)
  Task 4: Explore subagent verifies implementation
  Commit + push (if fixes needed)
```

### 7.2 Audit and Restructuring Workflow

```text
Phase 1: Discovery (parallel)
  Task 1-a: Explore all standards files
  Task 1-b: Analyze cross-references and dependencies
  Task 1-c: Identify contradictions and orphans

Phase 2: Remediation (sequential, depends on Phase 1)
  Task 2-a: Fix contradiction K-01
  Commit + push
  Task 2-b: Fix contradiction K-02
  Commit + push
  ...

Phase 3: Verification (sequential, depends on Phase 2)
  Task 3: Verify all fixes, check cross-references
  Commit + push
```

### 7.3 Multi-File Refactoring Workflow

```text
Phase 1: Analysis
  Task 1: Explore identifies files to refactor

Phase 2: Refactoring (map-reduce)
  Task 2-a: full-stack-developer refactors files 1-5
  Task 2-b: full-stack-developer refactors files 6-10
  Commit + push (after both complete)

Phase 3: Integration Testing
  Task 3: Verify refactored code compiles and tests pass
  Commit + push
```

---

## 8. Metrics and Observability

### 8.1 Metrics to Track

| Metric | What It Measures | Target |
|--------|-----------------|--------|
| Subagent success rate | % of subagents that complete without failure | > 95% |
| Average subagent runtime | Time from spawn to result | < 5 minutes |
| Workflow completion rate | % of workflows that complete all phases | > 90% |
| Fallback activation rate | % of tasks requiring fallback | < 10% |
| Commit frequency | Commits per orchestration phase | >= 1 per phase |

### 8.2 WORKLOG Analysis

The WORKLOG file provides a natural audit trail. After workflow completion:

1. Count task entries: should match planned task count
2. Verify each entry has Stage Summary
3. Check that COMPLETED tasks have result summaries
4. Check that FAILED/BLOCKED tasks have blocker descriptions
5. Verify commit hashes are recorded for file-modifying tasks

---

## 9. Integration with Other Standards

See Cross-References section at the end of this document for the full relationship table.

---

## 10. Checklist

### Before Starting Orchestration

- [ ] All tasks have unique IDs
- [ ] Dependencies are declared and acyclic
- [ ] Subagent types are appropriate for each task
- [ ] File scope is non-overlapping for parallel tasks
- [ ] Expected output format defined for each task

### During Orchestration

- [ ] Each completed subagent result is validated
- [ ] Commit + push after file-modifying subagents
- [ ] WORKLOG updated after each subagent
- [ ] Failed subagents are handled (fallback or escalation)
- [ ] Parallel subagents operate on disjoint file sets

### After Orchestration

- [ ] All tasks completed or explicitly blocked
- [ ] WORKLOG contains entries for all tasks
- [ ] All commits pushed to remote
- [ ] No orphaned or incomplete files
- [ ] Final state recorded in WORKLOG

---

## 11. Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-05 | Initial version: orchestration patterns, dependency management, state management, git coordination, error propagation |
| 1.1 | 2026-06 | Added §11A Known Issues documenting ORC-001 through ORC-003 (K-NN notation, workflow template ambiguity, no metrics automation). Added STD-META-001 to Related and Cross-References. |

---

## 11A. Known Issues and Proposed Solutions

This section documents discovered inconsistencies, missing content, and proposed corrections. Each issue has an ID, status, and proposed action. Issues resolved in the current version are marked `[RESOLVED]`; outstanding issues are marked `[OPEN]`.

### ORC-001 `[OPEN]` — `K-NN` contradiction notation is used in §7.2 example but never defined

**Problem:** §7.2 (Audit and Restructuring Workflow) shows an example workflow with tasks labeled "Fix contradiction K-01", "Fix contradiction K-02", etc. The `K-NN` notation also appears in the Version History of several other standards:
- `ENV-001-reproducibility.md` v1.1: "K-01 fix: replaced categorical absolute path ban..."
- `FE-001-frontend.md` v1.5: "K-06/K-07: replaced duplicated error handling... K-08: added autoBackup()... K-09: added custom theme preset validation rule..."

However, no standard in the project defines what the `K-NN` notation is, who assigns the numbers, where they are tracked, or what their lifecycle is. The notation is used as if it were a well-known convention, but it has no governing document. New contributors encountering "K-01" cannot look it up anywhere.

**Proposed solution:** One of:
1. Add a §11B "Contradiction Tracking (K-NN Notation)" subsection to this standard defining: "K-NN is the project's notation for tracked cross-standard contradictions. Each K-NN identifier is assigned sequentially when a contradiction is discovered during audit. The identifier is referenced in (a) the standard's Version History entry that resolves it, (b) the standard's Known Issues section as the cross-reference, and (c) the audit workflow in §7.2. The K-NN registry is maintained in `standards/known-issues.md` (or this standard's appendix)."
2. Replace the `K-NN` notation with the explicit `<PREFIX>-NN` notation used in this standard's §11A (e.g., ORC-001, REP-001). This unifies all known-issues tracking under one convention.
3. Remove the `K-NN` references from §7.2 and the Version History entries of other standards, replacing them with descriptive text.

Recommended: option 2 — unify under the `<PREFIX>-NN` convention. This is the convention used by all §XA Known Issues sections added in the 2026-06 audit pass.

### ORC-002 `[OPEN]` — §7.1 "Standard Development Workflow" Phase 1 uses parallel Explore subagents, but §4.3 of STD-AGENT-001 forbids parallel subagents modifying the same file

**Problem:** §7.1 Phase 1 (Analysis) runs Task 1-a and Task 1-b as parallel Explore subagents. STD-AGENT-001 §4.3 (Concurrency) says "Subagents MUST NOT run in parallel when they modify the same file." Explore subagents are read-only (per STD-AGENT-001 §2.2), so they do not modify files — but the WORKLOG file is shared. If both Explore subagents attempt to append to `/home/z/my-project/worklog.md` simultaneously, they may conflict.

§5.3 (Conflict Prevention) of this standard addresses WORKLOG conflicts: "Subagent modifies WORKLOG while main agent reads | Subagent appends only (never overwrites)". But it does not address two subagents appending simultaneously — the append-only rule prevents data loss but not interleaved writes.

**Proposed solution:** Add a §5.4 "WORKLOG Write Serialization" subsection: "When multiple subagents run in parallel, each MUST append its WORKLOG entry atomically. Use a file lock (`flock` on Linux) or write to a per-subagent temporary file then concatenate. The main agent MUST NOT read the WORKLOG until all parallel subagents have completed and their entries are committed." Alternatively, mandate that parallel subagents write their WORKLOG entries sequentially after completion, not during execution.

### ORC-003 `[OPEN]` — §8.1 Metrics to Track has no automation; metrics must be computed manually from WORKLOG

**Problem:** §8.1 lists five metrics (subagent success rate, average subagent runtime, workflow completion rate, fallback activation rate, commit frequency). §8.2 (WORKLOG Analysis) describes a manual 5-step process for computing these from the WORKLOG file. There is no script or tool that automates this — every metric computation is a manual read-and-count exercise.

**Proposed solution:** Add a §8.3 "Metrics Automation" subsection with a reference implementation:

```bash
# scripts/orchestration-metrics.sh
# Computes the §8.1 metrics from worklog.md
WORKLOG=/home/z/my-project/worklog.md

total_tasks=$(grep -c "^Task ID:" "$WORKLOG")
completed_tasks=$(grep -c "Status: COMPLETED" "$WORKLOG")
failed_tasks=$(grep -c "Status: FAILED\|Status: BLOCKED" "$WORKLOG")
fallback_tasks=$(grep -c "Fallback:" "$WORKLOG")
commits=$(grep -c "Commit:" "$WORKLOG")

echo "Subagent success rate: $(echo "scale=2; $completed_tasks * 100 / $total_tasks" | bc)%"
echo "Workflow completion rate: $(echo "scale=2; $completed_tasks * 100 / $total_tasks" | bc)%"
echo "Fallback activation rate: $(echo "scale=2; $fallback_tasks * 100 / $total_tasks" | bc)%"
echo "Commit frequency: $(echo "scale=2; $commits / $total_tasks" | bc) commits per task"
```

Add the script to the project's `scripts/` directory and reference it in the CI dashboard. Until the script exists, mark the metrics as "manual computation required — see §8.2".

---

## 12. Cross-References

| Standard | Relationship |
|----------|-------------|
| STD-AGENT-001 | Subagent contract: types, constraints, lifecycle (referenced in orchestration patterns) |
| STD-GIT-001 | Commit format and push frequency (commit point rules in Section 5.1) |
| STD-GIT-002 | Sandbox git safety: deadlock prevention for parallel subagents (Section 5.2-5.3) |
| STD-ERR-001 | Error classification for propagation (escalation ladder in Section 6) |
| STD-ENV-002 | Z.ai sandbox constraints affecting subagent execution |
| STD-ARCH-001 | Implementation order: where orchestration fits in project setup |
| STD-META-001 | Standard ID System: registry entry for STD-AGENT-002 must be kept in sync with the version in this document's header |
