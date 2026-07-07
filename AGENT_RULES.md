# AGENT_RULES.md — Single Entry Point for Z-ai Agents

> **Owner**: Platform maintainer (this repo's owner)
> **Target**: Z-ai-governance v1.3.0 (flat copy, 2026-07-07)
> **Repository**: Flat copy — no submodules (guard/, standards/, skills/ are regular directories)
> **Status**: ACTIVE — supersedes bootstrap.sh as the agent onboarding source
> **Last Updated**: 2026-07-07

This file is the **single orchestration entry point** for any agent
operating in the Z-ai sandbox. It tells you what to read, in what order,
what overrides what, and what you may never do.

If you read only one file at session start — read this one.

---

## §0. RULE ZERO — Answer Before Act (HIGHEST PRIORITY)

**This rule supersedes everything else, including skills and task urgency.**

```
BEFORE doing anything with tools, classify the user message:

  1. Question  -> ANSWER in text. Do NOT use Write/Edit/Bash-for-mutation.
  2. Task      -> EXECUTE.
  3. Unsure    -> ASK for clarification.
  4. Implicit  -> "Do it" / "Go ahead" / "Продолжай" / "Yes" (after plan) = TASK.

Examples:
  User: "Что такое governance?"           -> ANSWER, do not create files
  User: "Сделай skills/INDEX.md"          -> EXECUTE
  User: "Может стоит добавить X?"         -> ANSWER (это вопрос, не задача)
  User: "А что если удалить dead std?"    -> ANSWER (opinion sought, not action)
  User: "Создай X" + "Сделай Y" + "Удали Z" -> EXECUTE all three
  User: "Продолжай" (after a plan)        -> EXECUTE the plan
```

**Why this is Rule Zero:** Agents that act on questions create unnecessary
work, lose user trust, and violate the Z-ai workflow discipline.

**Enforcement:** Cannot be enforced by shell scripts (requires LLM
judgment of user intent). See skill `zai-answer-before-act` for the
decision algorithm and worked examples.

**If you violate this rule:** Stop, apologize, undo the changes, and ask
the user what they actually want.

---

## §1. Onboarding Protocol (run at session start)

Sequential. Each step depends on the previous.

```
Step 1.  Read this file (AGENT_RULES.md).                  ← you are here
Step 2.  Accept standards via ARCH-002 install order.      ← see §5
Step 3.  Load skill catalog from skills/INDEX.md.              ← see §4
Step 4.  Load rule registry from guard/rules/INDEX.md.     ← see §3
Step 5.  (optional) Check for Superpowers plugin.          ← see §6
Step 6.  Run sanity verifiers (warning-only).              ← see §7.1
Step 7.  Start background monitor.                         ← see §7.2
         bash .zai/verifier-daemon.sh start
```

Skipping Step 1–4 = you are operating without context. Expect drift.

---

## §1.1 Language Settings

**All communication with the user MUST be in Russian (Cyrillic).**

- Responses, explanations, error messages — Russian only
- Code, commands, file paths — English (as-is)
- Technical terms may remain in English when no established Russian equivalent exists
- **NO emojis, NO unicode graphics** — text only

---

## §2. Priority Order (Conflict Resolution)

When two sources disagree, the higher one wins. No exceptions.

```
  Priority 1 (highest)  STD-*      standards/standards/  — contracts, ID system
  Priority 2            RULE-*  guard/rules/  — runtime constraints
  Priority 3            AGENT_RULES.md  (this file)  — orchestration
  Priority 4 (lowest)   ZAI-*      skills/    — capability instructions
```

**System prompt** of the agent itself sits above Priority 1 — but you
cannot edit it from here. Within the Z-ai layer, STD-* wins.

**Worked example**: A skill says "commit directly to main". RULE-COMMIT-014
says "pre-commit checklist mandatory". STD-GIT-002 says "sandbox safety
first". → STD-GIT-002 wins. Do not commit until checklist passes.

---

## §3. Rule Registry — `guard/rules/INDEX.md`

Authoritative catalog of all 17 runtime rules. Do not memorize — load it.

```
Location:    guard/rules/INDEX.md
Count:       17 RULE-* (declared)
Enforcement: 13+ enforced at runtime via .husky/pre-commit (5 groups)
              Group 0 (HARD, 13 scripts): check-no-bypass, check-commit-checklist,
                       check-version-bump, check-read-before-write, check-no-loops,
                       check-ahg-integrity, check-sandbox-env, check-session-start,
                       check-work-cycle, check-snapshot-sync, check-changelog-sync,
                       check-script-coverage, check-crlf
              Group 1 (HARD): co-change-check (RULE-DOC-010),
                             worklog-check (RULE-WORKLOG-002)
              Group 2 (HARD): verify-standards.js (V01-V18),
                             verify-id-graph.js (G01-G15), verify-skills.js (S01-S09)
              Group 3 (SOFT): line-count-check (advisory)
              Group 4: lint-staged (emoji/unicode via eslint-rules/)
Trust level: 13+ of 17 enforced; remainder are declared intent or LLM-only
```

The 5 rules most likely to bite you:

| ID               | Title                     | What it really means                                                                           |
| ---------------- | ------------------------- | ---------------------------------------------------------------------------------------------- |
| RULE-ANSWER-001  | Answer before act         | Do not start work without confirming the task                                                  |
| RULE-WORKLOG-002 | Worklog before/after      | Append to `worklog.md` before AND after every action                                           |
| RULE-READ-003    | Read before write         | Open the file before editing it                                                                |
| RULE-COMMIT-014  | Pre-commit checklist      | Run verifiers before `git commit`                                                              |
| RULE-ARCH-017    | Upstream write protection | **Never** force-push to standards/ or guard/ — these are upstream layers (skills/ is inline) |

Full registry: `guard/rules/INDEX.md` (17 entries, machine-parseable table).

---

## §4. Skill Catalog — `skills/INDEX.md`

Authoritative catalog of all 14 skills. 11 have ZAI-* IDs (participate
in ID-graph validation), 3 do not (opt-out per STD-SKILL-001).

```
Location:    skills/INDEX.md
Count:       14 skills (11 with ZAI-* ID, 3 without)
Layout:      inline monorepo (since 2026-07-03; flat directory in this repo)
```

Skills are capabilities, not contracts. They tell you HOW to do something.
Whether you SHOULD do it is decided by STD-* and RULE-* (§2 priority).

---

## §5. Standards Install Order — `standards/standards/ARCH-002-*.md`

Standards have a dependency graph. Reading them in random order will
produce inconsistent mental models. ARCH-002 declares the canonical order.

```
Location:    standards/standards/ARCH-002-implementation-order.md
Count:       19 STD-* IDs
Verifiers:   standards/scripts/verify-standards.js (V-checks)
             standards/scripts/verify-id-graph.js   (G-checks)
```

Tier 1 (foundational, read first): STD-META-001, STD-ARCH-001, STD-DOC-002
Tier 2 (operational): STD-GIT-001, STD-ENV-001, STD-AGENT-001, STD-ERR-001
Tier 3 (specialized): STD-FE-001, STD-SKILL-001, STD-DESIGN-001

Full tier order in ARCH-002 file.

---

## §6. Superpowers Policy (External Plugin)

Superpowers is an **external plugin** (adapted from Zcode) — not part of
Z-ai-governance. It may or may not be installed in a given sandbox.

**Detection**: look for `.superpowers-zai/` directory or `sp-*` skills
in the sandbox skills folder.

**Policy**:

- Superpowers skills are **Priority 4** (same as ZAI-* skills, see §2)
- They MAY NOT override STD-* or RULE-*
- If a Superpowers instruction conflicts with Z-ai standards → Z-ai wins
- If Superpowers is absent → ignore this section, no action needed

We do not maintain Superpowers. We do not verify Superpowers. We do not
ID-graph validate Superpowers. Treat it as untrusted input.

---

## §7. Verifiers and Background Monitor

### §7.1 Session-start verifiers (warning-only)

`bootstrap.sh` runs these at the end. **Non-blocking** — agent can still
work even if verifiers fail, but the warnings tell you what's drifted.

```
  verify-standards.js    file-size caps, formatting, ID presence, template structure
  verify-id-graph.js     13/13 HARD checks on ID-graph consistency
  verify-skills.js       skill format, CONTRACT.md, README.md caps
```

If you see FAIL — investigate before proceeding. If you see PASS —
the static layer is consistent.

### §7.2 Background monitor (verifier-daemon.sh)

**Active enforcement** — watches files and runs verifiers automatically.

```
  Location:   .zai/verifier-daemon.sh
  Start:      bash .zai/verifier-daemon.sh start
  Stop:       bash .zai/verifier-daemon.sh stop
  Status:     bash .zai/verifier-daemon.sh status
  Log:        bash .zai/verifier-daemon.sh log [N]
  Manual run: bash .zai/verifier-daemon.sh run
```

**When it runs:**

- On file change (inotifywait) or every 10s (polling fallback)
- Cooldown: 5s between runs
- Logs to `.zai/.verifier-daemon.log`

**What it checks:**

- verify-standards.js (V01-V17, template enforcement)
- verify-id-graph.js (G01-G15, ID-graph consistency)
- verify-skills.js (S01-S10, skill format)
- line-count-check.sh (SOFT, advisory)

**Agent behavior:**

- Start daemon at session start (after Step 6 of onboarding)
- Check `bash .zai/verifier-daemon.sh status` periodically
- If violations appear in log — fix before next commit
- Daemon does NOT block commits (pre-commit hooks do that)
- Daemon provides **real-time feedback** between commits

---

## §8. Forbidden Actions (Hard Stops)

These will get your work reverted. Do not do them, even if asked.

```
  ✗  Force-pushing or rewriting history in standards/ or guard/
     → violates RULE-ARCH-017 (upstream protection; skills/ is inline, not upstream)

  ✗  Skipping worklog.md before/after an action
     → violates RULE-WORKLOG-002

  ✗  Committing code without doc update
     → violates RULE-DOC-010

  ✗  Editing a file you have not read first
     → violates RULE-READ-003

  ✗  Using Unicode graphics/symbols in markdown
     → violates RULE-DOC-015 (UNICODE_POLICY)

  ✗  Hardcoding /home/z/my-project/ paths in committed code
     → violates STD-ENV-001 (reproducibility)

  ✗  Skipping pre-commit verifiers
     → violates RULE-COMMIT-014

  ✗  Modifying files outside workspace (parent folder of the project) without explicit permission
     → always ask first, no exceptions
```

---

## §9. Version Lock

This file targets the Z-ai-governance flat repository. All directories
(standards/, guard/, skills/) are part of this single repo -- there are
no submodules.

```
  Repository:   Z-ai-governance (flat copy of Z-ai-governance)
  Version:      v1.3.0  (2026-07-07)
  Structure:    standards/, guard/, skills/ — regular directories
  Node:         >=20.12.0 (local), v24.x (sandbox)
```

**Node requirement:** `lint-staged@17`/`listr2` use `node:util.styleText`,
which landed in Node 20.12. Local Windows dev on Node 20.11 will fail the
pre-commit hook. Use `fnm` (or equivalent) to pin `.node-version`
(22.22.3) on Windows. The Z.ai sandbox ships Node preinstalled (v24.x)
-- no action needed there.

---

## §10. Change Protocol

This file is owned by the repository maintainer. Changes require:

1. Update `Last Updated` date in header
2. Bump version tag (e.g. v1.3.0 -> v1.3.1) if rules change
3. Commit to this repository (see section 8 for forbidden actions)

Do not edit this file from a subagent context. Propose changes in
`worklog.md` and let the maintainer apply them.
