---
name: zai-prompt-engineering
author: StsDev
compatibility: both
description: >
  Score, analyze, improve, and architect AI prompts using a 6-dimension evaluation framework,
  20 prompting techniques, 11 structured frameworks, 5-layer system prompt architect, and
  20 cognitive formulas. Activate this skill when ANY of the following signals appear:

  TRIGGER WORDS (English): prompt, prompts, prompting, system prompt, system instruction,
  prompt engineering, prompt score, prompt rating, prompt quality, prompt review, prompt audit,
  prompt improvement, prompt optimization, prompt refactor, prompt rewrite, prompt fix,
  prompt template, prompt structure, prompt format, prompt design, prompt architecture,
  chain of thought, few-shot, zero-shot, CoT, RTF, RISE, CARE, STONE, CREATE, TRACE,
  SCOPE, PACKED, CO-STAR, RAG, CHAIN framework, role assignment, structured output,
  negative constraint, delimiter pattern, prompt comparison, A/B test prompts.

  TRIGGER WORDS (Russian): promprt, promt, promprty, promty, sistemnyj promprt, inzheneriya promprtov,
  ocenka promprta, rejting promprta, kachestvo promprta, uluchshit' promprt, optimizirovat' promprt,
  perepisat' promprt, ispravit' promprt, shablon promprta, struktura promprta, format promprta,
  cepochka myslej, few-shot, promprt-inzhiniring, sravnit' promprty.

  TRIGGER PHRASES: "help me write a prompt", "my prompt sucks", "my prompt is not working",
  "how do I prompt for X", "AI is not following instructions", "output is not what I expected",
  "make my prompt better", "improve this prompt", "score this prompt", "rate my prompt",
  "build a system prompt", "design an agent prompt", "which prompting technique should I use",
  "compare these two prompts", "why is my prompt failing", "prompt keeps hallucinating".

  ACTIVATE WHEN: user mentions prompt quality/structure/scoring/optimization, user asks how to
  write better prompts, user complains about AI output quality (often a prompt issue), user
  wants to build or improve a system prompt for an agent/chatbot, user asks about prompting
  techniques or frameworks (RTF, CoT, few-shot, etc.), user wants to compare two prompts,
  user is designing multi-agent orchestration and needs agent-level prompts, user asks
  "which framework/technique should I use for X".

  DO NOT ACTIVATE FOR: general coding questions (not about prompts), UI/UX design requests,
  debugging code errors (unless explicitly about prompt engineering), database queries,
  deployment/infrastructure questions.
id: ZAI-META-003
version: 1.1
trigger: prompt, prompt engineering, improve prompt, system prompt, CoT, few-shot
related:
  - STD-SKILL-001
---

# Skill: Zai Prompt Engineering v1.1

> ID: ZAI-META-003
> Version: 1.1
> Last Updated: 2026-05

Expert prompt engineering with scoring, techniques, and frameworks.

---

## 1. Prompt Scoring (6 Dimensions)

[C] Always score before improving. Scoring is your diagnostic tool -- without it you are guessing.

| Dimension | Weight | What It Measures |
|---|---|---|
| Specificity | 0.25 | How specific and unambiguous the request is |
| Clarity | 0.20 | Ease of understanding, action verbs, structure |
| Context | 0.15 | Sufficient background, role, audience, domain |
| Completeness | 0.15 | All necessary info: input/output, edge cases, criteria |
| Constraint Control | 0.15 | Effective output constraining, negative constraints, limits |
| Actionability | 0.10 | Leads to implementable, verifiable response |

**Grading:** S (95+) > A (80+) > B (65+) > C (50+) > D (35+) > F (<35)

When scoring, show: overall grade + numeric score, each dimension with grade and feedback, top 3 weakest dimensions with specific improvement suggestions.

---

## 2. Prompt Improvement Workflow

1. **Score** the current prompt (baseline + diagnosis)
2. **Identify** the weakest 2-3 dimensions (targets)
3. **Select** the most relevant technique(s) from Section 4
4. **Apply** one technique at a time, rewrite the prompt
5. **Re-score** to verify improvement (show before/after)
6. **Explain** what changed and why it matters
7. **Stop** when score reaches B+ (70+) or after 3 iterations, whichever comes first

[C] Never apply more than 2 techniques in a single improvement iteration. Stacking too many makes the prompt unreadable.

[W] Stop improving when the score reaches A-grade (80+). Further gains are marginal and the prompt is production-ready.

**Done criteria** -- improvement is complete when:
- Overall score is B+ (70+) or higher
- No dimension scores below C (50)
- The user confirms the output matches their intent

If after 3 iterations the score is still below B+, explain the structural limitations and suggest a different framework.

---

## 3. Framework Selection

| Framework | Best For | Complexity |
|---|---|---|
| **RTF** (Role-Task-Format) | Code gen, content writing, data extraction -- 80% of needs | Simple |
| **RISE** (Role-Input-Steps-Expectation) | Data processing, reports, code review | Simple |
| **CARE** (Context-Action-Result-Example) | Data transformation, format conversion | Simple |
| **STONE** (Setup-Task-Objective-Notes-Extras) | Quick questions, debugging, brainstorming | Simple |
| **CREATE** (Context-Request-Explanation-Action-Tone-Extras) | Blog posts, marketing, emails | Moderate |
| **TRACE** (Task-Request-Action-Context-Example) | Complex code gen, system design | Moderate |
| **SCOPE** (Specific-Context-Objective-Persona-Execution) | API dev, DB schemas, infrastructure | Moderate |
| **PACKED** (Purpose-Audience-Context-Key-Emotion-Detail) | Notifications, release notes, onboarding | Moderate |
| **CO-STAR** (Context-Objective-Style-Tone-Audience-Response) | Policy docs, guidelines, formal communication | Moderate |
| **RAG** (Retrieval-Augmented Generation) | Doc search, knowledge Q&A, legal/compliance | Complex |
| **CHAIN** (Multi-Agent Chain) | Code pipelines, content workflows, CI/CD | Complex |

[C] Start with RTF. Upgrade to TRACE/SCOPE only if more structure is needed. CREATE/PACKED for creative content. CHAIN for multi-step pipelines.

[C] Never recommend the 5-layer system prompt architect for tasks solvable with RTF. If a simple Role-Task-Format prompt gets the job done (80% of cases), do not over-engineer.

---

## 4. Technique Selection + Examples

### Prompt is too vague

**Explicit Instruction** -- add specificity first. Replace vague words with concrete requirements.

> Before: "Write a summary of this article."
> After: "Write a 3-paragraph summary of this article. Paragraph 1: main argument. Paragraph 2: supporting evidence. Paragraph 3: implications for software teams. Maximum 200 words total."

**Precision Drill** -- replace every vague term with a measurable one.

> Before: "Make the response faster."
> After: "Reduce API response time from 800ms to under 200ms at the 95th percentile."

**Definition Lock** -- lock key term definitions before reasoning starts.

> Before: "Analyze the security of this system."
> After: "Analyze the security of this system. By 'security' I mean: resistance to SQL injection, XSS, CSRF, and unauthorized access to admin endpoints. Do not evaluate availability or performance."

### Need better reasoning

**Chain of Thought** -- step-by-step reasoning for math/logic/multi-step tasks.

> Before: "What is 15% of 340?"
> After: "What is 15% of 340? Think step by step: 1) Convert 15% to decimal, 2) Multiply by 340, 3) State the final answer."

**Plan and Solve** -- plan first, then execute. Prevents jumping to wrong solutions.

> Before: "Refactor this function."
> After: "Refactor this function. First, identify the 3 code smells. Then, for each smell, describe the refactoring technique you will apply. Finally, show the refactored code with comments marking each change."

### Need to control output

**Structured Output** -- specify exact format.

> Before: "List the errors in this code."
> After: "List the errors in this code as a JSON array. Each entry must have: `severity` (critical|high|medium|low), `line` (number), `type` (syntax|logic|security|performance), `fix` (one-sentence suggestion)."

**Negative Constraint** -- list what NOT to include.

> Before: "Review this pull request."
> After: "Review this pull request. Do NOT comment on: code style, formatting, naming conventions, or import ordering. Focus ONLY on logic errors, security vulnerabilities, and performance regressions."

### Need domain expertise

**Role Assignment** -- frame the AI as a domain expert.

> Before: "Is this API design good?"
> After: "You are a principal API architect with 15 years of experience designing RESTful systems at scale. Evaluate this API design against industry best practices (OpenAPI 3.0, REST constraints, backward compatibility)."

**Few-Shot Learning** -- provide examples of desired input/output.

> Before: "Generate a commit message for my changes."
> After: "Generate a commit message for my changes. Examples of good commit messages:
> - `feat(auth): add JWT refresh token rotation`
> - `fix(api): handle null response from payment gateway`
> - `refactor(db): extract connection pooling into shared module`"

### Need structure

**Delimiter Pattern** -- separate instructions from data with markers.

> Before: "Translate this text to French: Hello world"
> After: "Translate the text between <input> tags to French.
> <input>
> Hello world
> </input>"

---

## 5. System Prompt Architecture (5 Layers)

For AI agents and chatbots, use the 5-layer architect:

| Layer | Weight | Required | Purpose |
|---|---|---|---|
| **Identity** | 0.9 | Yes | Role, domain, tone, language, audience |
| **Context** | 0.7 | Yes | Environment, domain knowledge, tools |
| **Constraints** | 1.0 | Yes | Numbered hard rules, forbidden actions |
| **Output** | 0.95 | Yes | Format-specific instructions |
| **Behavior** | 0.6 | No | Tone mapping, quality standards, edge cases |

[I] Simple tasks: Identity + Output (2 layers). Production agents: all 5 layers.

When building: start with Identity, add Context, set Constraints (number them, use NEVER), specify Output format exactly, optionally add Behavior with tone mapping and edge case handling.

---

## 6. Intent Detection

| Intent | Signals | Best Framework | Best Technique |
|---|---|---|---|
| Code generation | "write code", "implement", "build" | RTF or TRACE | Structured Output |
| Code review | "review", "analyze code", "refactor" | RISE | Adversarial Reviewer |
| Debugging | "bug", "error", "fix", "crash" | STONE | Chain of Thought |
| Explanation | "explain", "what is", "how does" | RTF | Few-Shot |
| Data analysis | "analyze", "statistics", "metrics" | SCOPE | Structured Output |
| Creative writing | "write", "story", "article", "copy" | CREATE or PACKED | Role Assignment |
| Layout/UI | "layout", "grid", "dashboard" | SCOPE | Few-Shot |
| Translation | "translate", "convert to", "localize" | CARE | Delimiter Pattern |
| Refactoring | "refactor", "restructure", "simplify" | TRACE | Plan and Solve |
| Testing | "test", "spec", "unit test", "coverage" | RTF | Few-Shot |

[W] If unsure which technique to pick, default to Explicit Instruction -- it is the safest starting point.

---

## 7. Decision Tree

```text
User request
  |
  +-- "Improve my prompt" -> Score (Section 1) -> Identify weak dimensions -> Apply technique (Section 4) -> Re-score
  |
  +-- "Build a system prompt" -> Simple task? -> Yes -> RTF + 2 layers (Identity + Output)
  |                                       -> No  -> 5-layer architect (Section 5)
  |
  +-- "Compare prompts" -> Score both -> Side-by-side table with deltas -> Declare winner
  |
  +-- "Which technique/framework?" -> Detect intent (Section 6) -> Match framework (Section 3) + technique (Section 4)
  |
  +-- "Design multi-agent system" -> Choose pattern (Section 8) -> Define agent roles -> Map data flow
  |
  +-- "Think through a decision" -> Select cognitive formula (Section 9) -> Apply step by step
```

---

## 8. Multi-Agent Orchestration

| Pattern | Topology | Best For |
|---|---|---|
| Sequential Chain | sequential | Plan -> Code -> Review |
| Parallel Experts | parallel | Multi-perspective review |
| Hierarchical Delegate | hierarchical | Manager -> specialists -> integrate |
| Debate Adversarial | mesh | Architecture decisions |
| Iterative Refinement | sequential | Generate -> Criticize -> Refine |
| Ensemble Voting | parallel | Answer validation |
| Diamond | hierarchical | Diverge-then-converge |
| Supervisor-Workers | hierarchical | Batch processing at scale |

---

## 9. Cognitive Formulas

Use these when the user needs to think through a problem, not when they just need a better prompt.

**Bias Mitigation:** Anchoring Break (3 approaches before choosing), Confirmation Discount (argue FOR + AGAINST), Status Quo Challenge (when are assumptions FALSE?)

**Reasoning:** First Principles (strip to fundamentals), Inversion ("How would I guarantee failure?"), Pre-Mortem ("It failed. Why?")

**Creativity:** Constraint-Driven Creativity (add artificial constraints), SCAMPER (7 transformations), Random Input (map unrelated concept)

**Precision:** Precision Drill (replace vague with measurable), Boundary Check (KNOW / SUSPECT / DO NOT KNOW / NEED MORE INFO)

**Perspective:** Stakeholder Map (N viewpoints), Time Machine (now / 6mo / 2yr / 5yr)

**Self-Critique:** Self-Audit (accuracy/completeness/clarity/relevance/consistency), Devil's Advocate (case FOR, then AGAINST, then verdict)

---

## Hard Constraints

[C] These 5 rules are non-negotiable. Violating any is a critical failure.

1. **NEVER assign grade S (95+) if two or more dimensions score below B (65).** S-tier means excellence across the board, not just high average.
2. **NEVER recommend the 5-layer system prompt architect for tasks solvable with RTF.** If a simple Role-Task-Format prompt gets the job done (80% of cases), do not over-engineer.
3. **NEVER use Chain of Thought for formatting tasks.** CoT is for reasoning (math, logic, multi-step analysis). Using it for "format this as JSON" wastes tokens and confuses the model.
4. **NEVER apply more than 2 techniques in a single improvement iteration.** Stack too many techniques and the prompt becomes unreadable.
5. **NEVER replace the user's prompt entirely.** Improve it, don't rewrite from scratch. Keep their voice, intent, and domain-specific terminology intact.

---

## Error Handling

| Problem | What to Do |
|---|---|
| Score stays flat after 2 iterations | The technique doesn't fit the problem. Switch to a different category. |
| User says "this isn't what I meant" | Stop. Ask the user to clarify their intent. |
| Improved prompt scores higher but user dislikes it | You optimized for the framework, not the user. Revert and adjust. |
| Two dimensions conflict | Prioritize based on the user's stated goal. |
| Prompt is already A-grade (80+) | Stop improving. Explain that further gains are marginal. |
| Unsure which technique to pick | Use the intent detection table (Section 6). Default to Explicit Instruction. |

---

## Checklist

- [ ] Intent detected -- you identified what the user actually needs
- [ ] Framework selected -- you picked the right framework (default: RTF)
- [ ] 6-dimension score shown -- every scoring response includes all 6 dimensions
- [ ] Technique applied with before/after -- every improvement shows the technique used
- [ ] Hard Constraints respected -- none of the 5 rules were violated
- [ ] User's voice preserved -- the improved prompt keeps the user's terminology
- [ ] Stop condition checked -- improvement stops at B+ (70+) or 3 iterations

---

## Response Format

### Scoring:
```text
## Prompt Score: [Grade] ([numeric]/100)

| Dimension | Score | Grade | Feedback |
|---|---|---|---|
| Specificity | XX/25 | X | ... |
| Clarity | XX/20 | X | ... |
| Context | XX/15 | X | ... |
| Completeness | XX/15 | X | ... |
| Constraint Control | XX/15 | X | ... |
| Actionability | XX/10 | X | ... |

### Top 3 Improvements:
1. [Dimension]: [specific actionable suggestion]
2. [Dimension]: [specific actionable suggestion]
3. [Dimension]: [specific actionable suggestion]
```

### Improvement:
```text
## Before: Grade [X] (XX/100) -> After: Grade [Y] (YY/100)

### Improved Prompt:
[the improved prompt]

### Technique Applied:
[technique name]: [why it helps this specific weakness]

### What Changed:
- [concrete change and its impact]
```

### System Prompt:
```text
## System Prompt (5-Layer Architecture)

### Layer 1: Identity
[role, domain, tone, language, audience]

### Layer 2: Context
[environment, tools, project context]

### Layer 3: Constraints
1. [NEVER rule]
2. [NEVER rule]
...

### Layer 4: Output Format
[format specification with examples]

### Layer 5: Behavior
[tone mapping, quality standards, edge cases]
```

### Comparison:
```text
## Prompt Comparison

| | Prompt A | Prompt B | Delta |
|---|---|---|---|
| Overall | Grade X (YY) | Grade Y (ZZ) | +/-NN |
| Specificity | XX | XX | +/-NN |
| Clarity | XX | XX | +/-NN |
| ... | ... | ... | ... |

### Winner: [A/B/Tie]
### Reason: [why, referencing specific dimension advantages]
### Next Step: [how to improve the winner further]
```

---

## Communication Style

- No emoji or Unicode graphics in responses
- Use text tags for status: [OK], [FAIL], [TODO], [WARNING]
- Use severity tags for rules: [C] (Critical), [W] (Warning), [I] (Info)
- Use ASCII diagrams for flows: ->, |, +, v, ^
