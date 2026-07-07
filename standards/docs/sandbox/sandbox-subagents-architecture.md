# How Super Z + Subagents Work

> Educational document on multi-agent system architecture
>
> Author: Z.ai Code Platform
>
> Date: March 2025
>
> z.ai

## Table of Contents

1. [Introduction](#1-introduction)
   - 1.1 [Why Multi-Agent Architecture](#11-why-multi-agent-architecture)
2. [System Architecture](#2-system-architecture)
   - 2.1 [Interaction Diagram](#21-interaction-diagram)
   - 2.2 [Execution Flow](#22-execution-flow)
3. [Subagent Types](#3-subagent-types)
   - 3.1 [Key Distinction: Orchestrator vs Executor](#31-key-distinction-orchestrator-vs-executor)
4. [Orchestration Principles](#4-orchestration-principles)
   - 4.1 [Parallel Execution](#41-parallel-execution)
   - 4.2 [Statelessness](#42-statelessness)
   - 4.3 [Unified Worklog](#43-unified-worklog)
   - 4.4 [One-Direction Subagents](#44-one-direction-subagents)
5. [Communication Protocol](#5-communication-protocol)
   - 5.1 [Subagent Prompt Structure](#51-subagent-prompt-structure)
6. [Practical Examples](#6-practical-examples)
   - 6.1 [Creating a Dashboard from Scratch](#61-creating-a-dashboard-from-scratch)
   - 6.2 [Refactoring a Large File](#62-refactoring-a-large-file)
   - 6.3 [Simple Question (Without Subagents)](#63-simple-question-without-subagents)
7. [Skills System](#7-skills-system)
   - 7.1 [How Skill Activation Works](#71-how-skill-activation-works)
   - 7.2 [SKILL.md Structure](#72-skillmd-structure)
8. [Anti-Patterns](#8-anti-patterns)
9. [Key Takeaways](#9-key-takeaways)

---

## 1. Introduction

Super Z is the main orchestrator in the Z.ai multi-agent system. It does not do all the work itself -- it coordinates a team of specialized subagents, each responsible for their own area of expertise. This architecture is similar to a CTO who does not write code but distributes tasks among frontend developers, backend engineers, and DevOps specialists.

Key principle: Super Z delegates, does not execute. It analyzes the user's request, determines which subagents are needed, launches them (sequentially or in parallel), collects results, and presents them to the user in a consolidated form.

### 1.1. Why Multi-Agent Architecture

A single agent (LLM) is limited by its context window. When a task simultaneously requires code search, UI layout, database setup, and deployment -- one agent cannot handle it efficiently. A multi-agent system solves this problem through specialization and parallel execution.

---

## 2. System Architecture

Z.ai architecture is built on the principle of hierarchical delegation: the orchestrator (Super Z) at the top, specialized subagents at the bottom. Each subagent has its own tools, its own context, and its own limitations. The orchestrator does not interfere with the subagents' work -- it only launches them and collects results.

### 2.1. Interaction Diagram

```text
User
    |
    v
Super Z (orchestrator)
    |
    +----> general-purpose (search, research, multi-step tasks)
    |
    +----> Explore (fast codebase search)
    |
    +----> Plan (architecture design)
    |
    +----> full-stack-developer (Next.js + Prisma + API)
    |
    +----> frontend-styling-expert (CSS, responsiveness, UI/UX)
```

### 2.2. Execution Flow

1. User sends a request
2. Super Z analyzes the request and creates a plan
3. Super Z launches subagents (parallel or sequential)
4. Each subagent performs its part and returns a result
5. Super Z collects results and forms a response
6. User receives the final result

---

## 3. Subagent Types

Subagents are specialized sub-processes that Super Z launches via the Task Tool. Each type has its own set of tools and area of responsibility.

| Subagent Type | Tools | Purpose |
|---------------|-------|---------|
| `general-purpose` | All tools | Complex multi-step tasks, code search, research |
| `Explore` | All tools | Fast codebase search (glob, grep, read) |
| `Plan` | All tools | Architecture design, implementation planning |
| `full-stack-developer` | All tools | Next.js 16, React, Prisma, API routes, full stack |
| `frontend-styling-expert` | All tools | CSS, Tailwind, responsiveness, UI/UX, animations |

### 3.1. Key Distinction: Orchestrator vs Executor

Super Z is not a super-intellect that does everything better than others. It is a manager that knows when to delegate and when to do things itself. Simple tasks (answering a question, minor refactoring) Super Z handles itself. Complex tasks (creating a dashboard from scratch, full refactoring) it delegates to subagents.

---

## 4. Orchestration Principles

### 4.1. Parallel Execution

When tasks do not depend on each other, Super Z launches them simultaneously. For example, code search and architecture design can run in parallel -- one subagent searches for files, another designs the structure. This saves time: instead of 2+ minutes sequentially -- 1 minute in parallel.

Practical rule: if subagent B does not need the result of subagent A -- run in parallel. If it does -- only sequentially.

### 4.2. Statelessness

Subagents have no memory between calls. Each launch is a blank slate. Super Z passes all necessary information via the prompt (`prompt` parameter in the Task Tool). This guarantees that the subagent always has current context and does not depend on previous launches.

Practical consequence: Super Z must include all necessary information in the subagent's prompt. You cannot rely on the subagent remembering a previous launch.

### 4.3. Unified Worklog

All subagents write their work results to a single shared file `worklog.md`. This is the only way to coordinate between sequential subagents. The first subagent writes, the second reads and continues from where the first left off.

The format of entries in `worklog.md` is strictly regulated: Task ID, Agent, Task, Work Log, Stage Summary. This ensures reproducibility and transparency.

### 4.4. One-Direction Subagents

A subagent returns exactly one message -- its final report. It cannot send an additional message after completion, nor can it communicate with other subagents directly. All coordination goes through Super Z.

---

## 5. Communication Protocol

Communication between Super Z and subagents occurs through the Task Tool with three key parameters:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `subagent_type` | Subagent type (determines toolset) | `full-stack-developer` |
| `description` | Brief task description (3-5 words) | `Build dashboard page` |
| `prompt` | Full task context (everything goes here) | Detailed description with 10+ items |

### 5.1. Subagent Prompt Structure

The subagent's prompt is its only source of information. It must contain:

- **Task ID** -- task identifier in global order (e.g., 2-a, 2-b)
- **Link to worklog.md** -- where to read previous agents' results
- **Assignment** -- what exactly needs to be done
- **Constraints** -- what should not be done
- **Response Format** -- how to format the result

---

## 6. Practical Examples

### 6.1. Creating a Dashboard from Scratch

Task: user asks to create a dashboard with charts and tables.

Super Z plan:

```text
1. [Plan] -> design architecture
2. [Explore] -> find existing components
3. [parallel]
   [full-stack] -> create API + DB + UI
   [frontend-styling] -> configure styles + responsiveness
```

### 6.2. Refactoring a Large File

Task: user asks to split a 500-line monolith into modules.

Super Z plan:

```text
1. [Explore] -> analyze file structure
2. [Plan] -> create splitting plan
3. [full-stack] -> perform refactoring
```

### 6.3. Simple Question (Without Subagents)

Task: user asks "how to use Prisma?".

Solution: Super Z answers itself, without launching subagents. Delegation is a tool for complex tasks, not for every request. Launching a subagent to answer a question is a waste of resources.

---

## 7. Skills System

Skills are specialized instructions that automatically activate upon certain signals. Each skill is a `SKILL.md` file with YAML frontmatter, where the `description` field contains triggers for activation.

### 7.1. How Skill Activation Works

1. User writes: "rate my prompt"
2. Super Z scans the `description` of all skills
3. Finds a match: "rate" = trigger for `prompt-engineering`
4. Activates the skill and loads `SKILL.md`
5. The entire skill methodology becomes context

### 7.2. SKILL.md Structure

| Area | Purpose |
|------|---------|
| YAML frontmatter (`name`, `description`) | Activation: trigger words, phrases, conditions |
| Main content | Methodology, techniques, examples, constraints |
| Response Format | Response templates (scoring, improvement, comparison) |
| Hard Constraints | Non-negotiable rules |
| Communication Style | Response style (tags, format) |

Critical: the `description` in YAML frontmatter is not text for humans, but a signal for the machine. The more triggers (words + phrases + conditions) -- the more accurate the activation.

---

## 8. Anti-Patterns

Common mistakes when working with a multi-agent system:

| Anti-Pattern | Why It Is Bad | Correct Approach |
|--------------|---------------|------------------|
| Launching a subagent for every request | Waste of resources, slowdown | Delegate only complex tasks |
| Sequential launch of independent tasks | Time loss (2x slower) | Parallel launch of independent tasks |
| Insufficient subagent prompt | Subagent lacks context | Pass all necessary information |
| External files in a skill (`references/`) | System will not load them automatically | All methodology inline in SKILL.md |
| Too few triggers in `description` | Skill does not activate | EN + RU triggers + phrases + conditions |

---

## 9. Key Takeaways

- **Super Z** is an orchestrator, not an executor. It delegates, does not do things itself.
- **Parallelism** -- when possible. Independent tasks run simultaneously.
- **Statelessness** -- subagents have no memory. All information in the prompt.
- **Worklog** -- the only coordination channel between sequential agents.
- **Skills** activate via triggers in `description`. More triggers = more accurate activation.
- **Delegation** -- a tool for complex tasks. Simple ones -- Super Z handles itself.
- **A skill** is a single SKILL.md. Everything inline, no external files.

---

Built with: Next.js 16 + TypeScript + Tailwind CSS
