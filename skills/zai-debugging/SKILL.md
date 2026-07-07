---
name: zai-debugging
id: ZAI-DEV-004
author: StsDev
version: 1.0.0
description: Systematic debugging for Z.ai sandbox. Use this skill whenever code fails at runtime, "tests are failing", a build step errors out, or the user says "fix this bug", "debug", "why is this broken", "it doesn't work".
related:
  - STD-ERR-001
  - STD-META-001
---

# Skill: Zai Debugging v1.0.0

Four-phase debugging workflow for Z.ai sandbox.

## Phase 1: Read the Error

1. Run the failing command again to get fresh error output
2. Copy exact error text — file path, line number, error type
3. Don't infer from memory — read the actual output

**Bad:** "The test fails, let me refactor the whole function"
**Good:** "The test fails with `ReferenceError: userId is not defined` on line 42"

## Phase 2: Narrow the Scope

Find the smallest code region that produces the error.

- Run just the failing test (not the whole suite)
- Isolate the specific endpoint or component
- Binary search: comment out half the code path, check which half has the bug

**Bad:** Reading all 20 files looking for "the problem"
**Good:** `pytest tests/test_auth.py::test_login_invalid_password -v`

## Phase 3: Form a Hypothesis

Before changing code, state what you think is wrong:

- What is expected behavior?
- What is actual behavior?
- Why is there a gap?

**Bad:** Adding `try/catch` around everything
**Good:** "Hypothesis: `fetchUser()` returns `null` when user doesn't exist, but caller assumes object. Fix: add null check."

## Phase 4: Fix and Verify

1. Make minimal change addressing the hypothesis
2. Run the failing test/command again
3. If passes — run broader suite for regressions
4. If fails — hypothesis wrong, go back to Phase 2

## Z.ai Sandbox Pitfalls

| Situation | What to check |
|-----------|--------------|
| `EADDRINUSE :3000` | Run `cat .zscripts/dev.sh` to see actual server command, then `lsof -i :3000` to find process. Kill with `kill -9 <PID>`. Do NOT run `bun run dev` yourself — let `.zscripts/dev.sh` manage it |
| `Module not found` | Check `package.json`, run `npm install` |
| `Permission denied` | Use `/tmp/` for temporary files |
| `Git fails` | Check if inside worktree, run `git status` |
| `Timeout` | Z.ai has 10-min bash timeout; background long tasks |
| `Font/image missing` | Z.ai fonts: `/usr/share/fonts/`; project images: `public/` |
| `Port conflict` | Check `.zscripts/dev.sh` first — it sets port. Don't assume 3000 |
| Build errors | Run `npm run build` to see full error output |
