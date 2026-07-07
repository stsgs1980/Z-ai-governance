---
name: zai-answer-before-act
id: ZAI-DEV-006
author: StsDev
version: 1.0.0
description: "ALWAYS load this skill before responding to ANY user message. Enforces RULE-ANSWER-001: questions get answers, tasks get executed. Load this on session start, after every long pause, and before any new user input. Triggers on: any user message, question, task, request, command, prompt, 'what is', 'how do', 'why', 'can you', 'make', 'create', 'fix', 'change', 'do this', Russian: 'что', 'как', 'почему', 'зачем', 'когда', 'сделай', 'создай', 'исправь', 'измени'."
trigger: "user input, question, task, request, prompt, anything from user"
compatibility: both
related:
  - STD-META-001
  - RULE-ANSWER-001
---

# Skill: Zai Answer Before Act v1.0.0

## Purpose

Enforce `RULE-ANSWER-001`: distinguish questions from tasks, and only act when explicitly asked.

## The Rule (memorize this)

```bash
1. Question  -> ANSWER, do NOT create files, do NOT modify code, do NOT commit
2. Task      -> EXECUTE
3. Unsure    -> ASK for clarification
4. Implicit  -> "Do it" / "Go ahead" / "Make it so" / "Yes" / "Продолжай" = TASK, execute
```

## Decision Algorithm (apply to EVERY user message)

```bash
User message arrives
        |
        v
+---------------------------+
| Is this a question?       |
+---------------------------+
        |
   +----+----+
   |         |
  YES        NO (imperative, request, command)
   |         |
   v         v
ANSWER   +---------------------------+
only      | Is it a task?             |
no        | (create/make/fix/change)  |
action    +---------------------------+
                |
           +----+----+
           |         |
          YES        NO (ambiguous)
           |         |
           v         v
       EXECUTE    ASK user
                  "Вы имеете в виду...?"
```

## Question Patterns (default: ANSWER, do not act)

| Pattern | Example | Action |
|---------|---------|--------|
| "Что такое X?" | "Что такое governance?" | ANSWER |
| "Как работает X?" | "Как работает pre-commit?" | ANSWER |
| "Почему X?" | "Почему тест упал?" | ANSWER (use Read/Grep, not Write) |
| "Когда X?" | "Когда будет готов?" | ANSWER |
| "Зачем X?" | "Зачем нужен worklog?" | ANSWER |
| "What is X?" | "What is Z-ai-governance?" | ANSWER |
| "How does X work?" | "How does verify-id-graph work?" | ANSWER |
| "Why X?" | "Why did CI fail?" | ANSWER |
| "Show me X" | "Show me the worklog" | ANSWER (use Read, not Edit) |
| "Explain X" | "Explain RULE-STRUCT-007" | ANSWER |
| "Расскажи про X" | "Расскажи про governance" | ANSWER |
| "Объясни X" | "Объясни worklog" | ANSWER |

## Task Patterns (default: EXECUTE)

| Pattern | Example | Action |
|---------|---------|--------|
| "Сделай X" | "Сделай INDEX.md" | EXECUTE |
| "Создай X" | "Создай skills/INDEX.md" | EXECUTE |
| "Исправь X" | "Исправь CRLF" | EXECUTE |
| "Измени X" | "Измени worklog" | EXECUTE |
| "Удали X" | "Удали dead standards" | EXECUTE |
| "Make X" | "Make a plan" | EXECUTE |
| "Create X" | "Create a test" | EXECUTE |
| "Fix X" | "Fix the bug" | EXECUTE |
| "Change X" | "Change the threshold" | EXECUTE |
| "Delete X" | "Delete the file" | EXECUTE |
| "Build X" | "Build the project" | EXECUTE |
| "Deploy X" | "Deploy to production" | EXECUTE |
| "Add X" | "Add a check" | EXECUTE |
| "Update X" | "Update the snapshot" | EXECUTE |
| "Implement X" | "Implement check-work-cycle.sh" | EXECUTE |
| "Закоммить" | "Закоммить изменения" | EXECUTE |
| "Запушь" | "Запушь в main" | EXECUTE |
| "Прогони" | "Прогони тесты" | EXECUTE |

## Implicit Task Patterns (default: EXECUTE)

| Phrase | Meaning |
|--------|---------|
| "Do it" | TASK |
| "Go ahead" | TASK |
| "Make it so" | TASK |
| "Yes" / "OK" / "Sure" (after a plan) | TASK |
| "Продолжай" | TASK |
| "Делай" | TASK |
| "Давай" | TASK |
| "Согласен" (after a plan) | TASK |
| "Approve" / "LGTM" (after a plan) | TASK |
| "Поехали" | TASK |
| "Погнали" | TASK |
| "Make it so" | TASK |

## Anti-Patterns (DO NOT DO)

### Anti-Pattern 1: Act on a question

```bash
User: "Что такое worklog?"
BAD:  Создаёт worklog.md с описанием
GOOD: Отвечает текстом: "Worklog — это append-only лог..."
```

### Anti-Pattern 2: Pre-emptive implementation

```bash
User: "Может стоит добавить X?"
BAD:  Сразу создаёт файлы для X
GOOD: "Да, это хорошая идея. Сделать? Подтвердите — и я добавлю."
```

### Anti-Pattern 3: Acting on silence

```bash
User: "..."
User: "..."
User: "..."
BAD:  Решает что user хочет и действует
GOOD: "Чем могу помочь? Жду вашу задачу."
```

### Anti-Pattern 4: Mid-task planning expansion

```bash
User: "Сделай X"
BAD:  Создаёт X + Y + Z "пока я тут"
GOOD: Создаёт только X, спрашивает про Y и Z
```

## Forbidden Actions When User Asked a Question

If the user message is classified as a QUESTION, you MUST NOT:

1. Use `Write` tool to create new files
2. Use `Edit`/`MultiEdit` tools to modify code
3. Use `Bash` to run `git commit`, `git push`, `npm install`
4. Use `Bash` to create files via `cat > X` or `echo > X`
5. Make any state-changing action

You MAY:

1. Use `Read` to examine files
2. Use `Grep` to search
3. Use `Glob` to find files
4. Respond in text only

## Self-Check Before Acting

Before ANY tool call that mutates state, ask yourself:

```bash
1. What did the user ask?
2. Is this a question or a task?
3. If question -> STOP, answer in text
4. If task -> proceed
5. If unsure -> ask "Подтвердите: сделать X?"
```

## Examples

### Example 1: Pure Question

```bash
User: "Что такое check-work-cycle.sh?"

Correct response:
"check-work-cycle.sh — это guard-script для RULE-STRUCT-007.
Он проверяет что каждые 2+ последовательных коммита сопровождаются
обновлением worklog.md. Если обнаружен drift — fails в pre-commit."

WRONG (do not do this):
- Reads check-work-cycle.sh
- Updates README to mention it
- Commits the change
```

### Example 2: Task

```bash
User: "Создай skills/INDEX.md"

Correct response:
- Reads skills/ directory
- Creates skills/INDEX.md
- Updates related worklog
- Commits

WRONG (do not do this):
- "Хотите чтобы я создал INDEX.md? Уточните формат."
  (User already said CREATE — это task, не вопрос)
```

### Example 3: Ambiguous

```bash
User: "А что если добавить новый rule?"

Correct response:
"Вы хотите чтобы я:
1. Создал новый rule (задача)
2. Обсудить что за rule нужен (вопрос)

Уточните, пожалуйста."

WRONG (do not do this):
- Сразу создаёт RULE-FOO-001.md
```

## Edge Cases

### "Yes/No" follow-up to a plan

```bash
Agent: "Я предлагаю обновить STD-ARCH-001. Подтверждаете?"
User: "Да"

Classified as: IMPLICIT TASK (execution of proposed plan)
Action: EXECUTE
```

### Mixed: question + suggestion

```bash
User: "Не плохо бы иметь X. Что думаешь?"

Classified as: QUESTION (asking for opinion)
Action: ANSWER with text, do NOT create X
```

### Code review request

```bash
User: "Проверь этот код"

Classified as: TASK (review = read + analyze + report)
Action: Read code, write text analysis, do NOT modify code
```

### "Покажи" / "Show me"

```bash
User: "Покажи worklog"

Classified as: QUESTION (display, not modify)
Action: Use Read tool to display, do NOT create new worklog entry
```

## Related Skills

- `zai-workflow-discipline` — general work cycle (Read -> Plan -> Execute -> Record -> Commit)
- `zai-debugging` — systematic debugging (Read error -> Hypothesize -> Test -> Fix)
- `zai-skill-creator` — create new skills following this template

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-07-06 | Initial release. Implements RULE-ANSWER-001 with decision algorithm, question/task patterns, anti-patterns, and 3 worked examples. |
