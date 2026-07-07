# Standard: GitHub Sandbox Safety v1.1 (EN)

> ID: STD-GIT-002
> Version: 1.1
> Level: **[C] Critical**
> Last Updated: 2026-06
> Related: STD-GIT-001 (github core), STD-ENV-002 (zai integration), STD-META-001 (ID system)

---

## 1. Introduction

This standard covers **sandbox-specific git operations** for Z.ai environments. It addresses the unique constraints, risks, and recovery procedures that arise when working with git inside a sandboxed cloud development environment.

For **core git rules** (commit format, branching, push policy, versioning, GitHub-specific rules), see **STD-GIT-001**.

The sandbox introduces risks not present in normal git workflows:
- Middleware hooks that can cause complete tool deadlock
- Session mortality that risks data loss
- Network instability that can corrupt repository state
- Shared filesystem constraints across chat sessions

---

## 2. Sandbox Constraints

The Z.ai sandbox has specific constraints:

- **Shared filesystem**: All chat sessions share the same filesystem
- **Process mortality**: Background processes die when chat ends
- **No cross-chat process sharing**: Cannot control processes from other chats
- **Local changes = data loss risk**: Always push before session ends

### 2.1 Deadlock Problem

Sandbox performs automatic `git pull` / `git merge` on session restart. If local repository state diverges from remote (unpushed commits, uncommitted files, dirty working tree) — a merge conflict occurs.

Merge conflict blocks `git status` (exit code != 0). Infrastructure uses `git status` as pre-check before executing ANY tool (Bash, Read, Write, Edit, Glob, Grep, etc.). Result: **complete deadlock** — no tool can execute, including tools to fix the conflict itself.

**Vicious cycle:**
```bash
git status -> merge conflict -> exit code != 0
-> tool pre-check fails -> tool blocked
-> cannot fix merge -> git status still fails
-> DEADLOCK
```

### 2.2 Signs of Standard Violation

| Sign | Meaning | Action |
|------|---------|--------|
| `git status` != clean before restart | Deadlock risk | Immediate commit + push |
| `git log origin/main..HEAD` != empty | Unpushed commits | Immediate push |
| Commits without push at session end | Conflict on restart | Push before ending |
| `git status` shows "needs merge" | Deadlock already started | Recovery procedure (see Section 5) |

---

## 3. Session Management

### 3.1 Session Start Checklist

```bash
# Check if git is in a blocked state
ls .git/rebase-merge/ 2>/dev/null && echo "REBASE BLOCKED"
git status

# If blocked, recover
rm -rf .git/rebase-merge .git/rebase-apply
git reset --hard HEAD
```

### 3.2 Session End Checklist

```bash
# Commit everything
git add -A
git commit -m "chore: session checkpoint"

# Push always
git push --force-with-lease origin main
```

---

## 4. Deadlock Prevention

### 4.1 Rule 1: Push After Every Stage

Each completed stage of work = commit + push. No exceptions.

```bash
git add -A
git commit -m "stage: description"
git push origin main
```

**Forbidden:**
- Accumulating multiple stages in one commit
- Making commit without subsequent push
- Leaving uncommitted files when moving to next task

### 4.2 Rule 2: Checklist Before Session End

Before session closes / breaks / restarts:

```bash
# 1. All changes committed?
git status
# Expected: "nothing to commit, working tree clean"

# 2. All commits pushed?
git log --oneline -5
# Compare with remote:
git log origin/main..HEAD
# Expected: empty (no unpushed commits)

# 3. Final push
git push origin main

# 4. Re-check
git status
# Expected: "nothing to commit, working tree clean"
```

### 4.3 Rule 3: Dirty Working Tree = No Stop

If `git status` shows uncommitted changes — session MUST NOT interrupt without prior commit + push. If session breaks unexpectedly — first command on next start: `git status` to check.

### 4.4 Rule 4: One Task = One Commit + Push

```bash
Task -> code -> test -> git add -> git commit -> git push -> next task
```

Not "10 tasks -> 1 commit -> push", but "1 task -> 1 commit -> 1 push".

---

## 5. Deadlock Recovery

### 5.1 Standard Recovery Procedure

If deadlock already occurred (all tools blocked):

**Level 1 - Manual Terminal (if available):**
```bash
rm -f .git/MERGE_HEAD .git/MERGE_MSG .git/MERGE_MODE
git reset --hard HEAD
git status  # check if clean
git push origin main --force  # if needed to sync with remote
```

**Level 2 - Sandbox Restart:**
- All code is on GitHub (if push rules were followed)
- Sandbox will clone fresh repository on clean start
- Merge conflict won't occur since starting state = remote

**Level 3 - Nuclear Reset (if Level 1 and 2 don't help):**
```bash
mv .git .git.broken
git init
git remote add origin <remote-url>
git fetch origin
git reset origin/main
```

### 5.2 Rebase Deadlock Recovery

If rebase deadlock occurred (middleware blocked all commands):

**You CANNOT recover without session restart.**

Before restart, remember:
- All local uncommitted work WILL be lost
- Unpushed commits MAY be lost

**After restart (fresh session):**
```bash
# 1. Check state
ls .git/rebase-merge/ 2>/dev/null && echo "REBASE STILL EXISTS"

# 2. Abort rebase immediately
git rebase --abort 2>/dev/null || rm -rf .git/rebase-merge .git/rebase-apply

# 3. Reset to clean state
git reset --hard HEAD

# 4. Sync with remote
git fetch origin
git reset --hard origin/main

# 5. Verify clean
git status

# 6. Push if needed
git push --force-with-lease origin main
```

---

## 6. Network Failure Recovery

Network interruptions during git operations can leave the repository in a locked or inconsistent state. This section describes how to recover safely.

### 6.1 Signs of Network Failure During Git Operation

| Sign | Meaning | Detection |
|------|---------|-----------|
| Command hangs > 30 seconds | Network timeout | No output, process stuck |
| `fatal: unable to access` | Connection lost | Error message with URL |
| `Connection timed out` | Server unreachable | Error message |
| `index.lock` exists | Interrupted operation | `ls .git/index.lock` |
| `Could not resolve host` | DNS failure | Error message |

### 6.2 Safe Interruption of Hung Git Operations

If a git command hangs (no response for 30+ seconds):

```bash
# Step 1: Do NOT force-kill the process immediately
# Wait 10-15 seconds more, it might recover

# Step 2: If still stuck, find the process
ps aux | grep git

# Step 3: Graceful termination first
kill <pid>  # SIGTERM

# Step 4: Wait 5 seconds
sleep 5

# Step 5: Force kill only if still running
kill -9 <pid>  # SIGKILL (last resort)
```

**CRITICAL:** Never use `kill -9` as first action — it leaves `.lock` files.

### 6.3 Removing Git Lock Files

After interrupting a git operation, lock files may remain:

```bash
# Check for lock files
ls -la .git/*.lock 2>/dev/null
ls -la .git/objects/*.lock 2>/dev/null
ls -la .git/refs/*.lock 2>/dev/null

# Remove index lock (safe if no other git process running)
rm -f .git/index.lock

# Remove object locks
rm -f .git/objects/*.lock

# Remove ref locks
rm -f .git/refs/**/*.lock

# Verify no git processes running
ps aux | grep git
```

**Rule:** Only remove `.lock` files when NO other git process is running.

### 6.4 Repository Integrity Check After Failure

After network recovery, verify repository integrity:

```bash
# Step 1: Check repository integrity
git fsck --full

# Expected output:
# "dangling commit" or "dangling blob" = OK (orphaned objects)
# "missing blob" or "corrupt" = PROBLEM (requires repair)

# Step 2: Check if HEAD is valid
git rev-parse HEAD

# Step 3: Verify working tree
git status

# Step 4: If status shows errors, re-read index
git read-tree HEAD

# Step 5: Hard reset if needed (WARNING: loses uncommitted changes)
git reset --hard HEAD
```

### 6.5 Recovery Scenarios

**Scenario A: Push interrupted mid-transfer**

```bash
# 1. Check what was pushed
git log origin/main..HEAD

# 2. Remove any partial upload locks
rm -f .git/objects/pack/*.lock

# 3. Retry push
git push origin main

# If push fails with "non-fast-forward":
git push --force-with-lease origin main
```

**Scenario B: Fetch/Pull interrupted**

```bash
# 1. Remove fetch locks
rm -f .git/FETCH_HEAD
rm -f .git/objects/pack/*.lock

# 2. Re-fetch (safe — does not modify working tree)
git fetch origin

# 3. Reset to remote state (SAFE for sandbox — no merge conflict risk)
git reset --hard origin/main

# IMPORTANT: Do NOT use `git merge origin/main` or `git rebase origin/main`
# in Z.ai sandbox. These can create merge conflicts that trigger middleware
# deadlock. Always use `git reset --hard origin/main` instead.
```

**Scenario C: Clone interrupted**

```bash
# If clone was interrupted, delete partial clone and restart
cd ..
rm -rf <repo-name>
git clone <url>
```

**Scenario D: Merge interrupted by network (during pull)**

```bash
# 1. Check merge state
ls .git/MERGE_HEAD

# 2. If exists and you want to abort:
rm -f .git/MERGE_HEAD .git/MERGE_MSG .git/MERGE_MODE
git reset --hard HEAD

# 3. If you want to continue:
git merge --continue
```

### 6.6 Git Timeout Configuration

Configure git to fail faster on network issues instead of hanging indefinitely:

```bash
# Set timeout for git operations (seconds)
git config --global http.lowSpeedLimit 1000
git config --global http.lowSpeedTime 10

# Connection timeout (seconds)
# Note: git uses curl, so this helps:
git config --global http.postBuffer 524288000

# For SSH connections, add to ~/.ssh/config:
# Host github.com
#     ConnectTimeout 10
#     ServerAliveInterval 5
#     ServerAliveCountMax 3
```

### 6.7 Offline Work Protocol

When you know internet is unstable or unavailable:

```bash
# Before going offline:
git fetch --all
git status  # ensure clean

# Work offline (commits are local)
git add -A
git commit -m "work offline checkpoint"

# When back online:
git push origin main
```

**Critical:** Never end session with uncommitted work + no internet. Wait for connection or document the risk.

### 6.8 Network Failure Prevention Checklist

```bash
[ ] Git timeouts configured
[ ] No `.lock` files present before starting work
[ ] Clean working tree (git status) before network operations
[ ] SSH config has timeouts set
[ ] Working on feature branch (not main) for risky operations
[ ] Recovery tag created before large operations
```

---

## 7. Sandbox Safety Rules

This section covers additional safety rules specific to Z.ai sandbox environment, addressing the middleware hook mechanism and other sandbox-specific risks.

### 7.1 Middleware Hook Deadlock Mechanism

Z.ai sandbox infrastructure uses a **pre-command hook** that intercepts ALL shell commands. This hook:

1. Runs `git status` before executing ANY command
2. If `git status` returns non-zero (merge conflict, rebase in progress, dirty state) — **command is BLOCKED**
3. Blocking applies to ALL tools: Bash, Read, Write, Edit, Glob, Grep, etc.
4. Even `echo`, `ls`, `rm` are blocked when git is in conflict state

**This creates absolute deadlock:**
```bash
git conflict -> middleware blocks all commands
-> cannot run recovery commands
-> cannot fix conflict
-> DEADLOCK
```

**Recovery from middleware deadlock is ONLY possible via:**
- Session restart (if code was pushed to remote)
- Manual intervention by platform administrators
- Using a bypass terminal (if available in UI)

### 7.2 Absolute Prohibitions for Z.ai Sandbox

These operations are **ABSOLUTELY FORBIDDEN** in Z.ai sandbox:

| Operation | Why | Consequence |
|-----------|-----|-------------|
| `git pull --rebase` | Creates rebase conflict | Middleware deadlock |
| `git pull` (without prior fetch) | Unexpected merge conflict | Middleware deadlock |
| `git rebase` on dirty tree | Cannot abort, conflict stuck | Middleware deadlock |
| `git stash` with conflict markers | Stash apply fails | Potential deadlock |
| `git merge` without commit | Leaves merge state | Middleware deadlock |
| Long-running rebase | Session timeout = stuck rebase | Middleware deadlock |
| Editing files during rebase/merge | Conflict resolution required | Extended deadlock risk |

**When in doubt, the safe path is ALWAYS:**
```bash
git push --force-with-lease origin main
```

### 7.3 Pre-Command Checklist (MUST run before any git operation)

Before executing ANY git operation, verify:

```bash
# 1. Check current state
git status
# Expected: "nothing to commit, working tree clean" OR known changes

# 2. Check for lock files
ls .git/*.lock 2>/dev/null && echo "LOCK EXISTS - remove first"
ls .git/rebase-merge/ 2>/dev/null && echo "REBASE IN PROGRESS - abort first"

# 3. Check remote state
git fetch origin
git log HEAD..origin/main --oneline
# If output NOT empty: remote is ahead

# 4. Check for uncommitted work
git diff --stat
# If output NOT empty: working tree dirty
```

**Decision matrix:**

| State | Action |
|-------|--------|
| Clean tree, remote up-to-date | Safe to proceed |
| Dirty tree, no remote changes | Commit + push, then proceed |
| Remote ahead, clean tree | `git push --force-with-lease` (your project) |
| Remote ahead, dirty tree | Commit + `git push --force-with-lease` |
| Lock files exist | Remove locks, verify clean, then proceed |
| Rebase/merge in progress | ABORT first: `git rebase --abort` or `git merge --abort` |

### 7.4 Remote Ahead Decision Tree

When `git log HEAD..origin/main` shows remote has commits:

```bash
REMOTE AHEAD?
    |
    v
Is this YOUR project (solo work)?
    |
    +-- YES --> git push --force-with-lease origin main
    |           (your local state is authoritative)
    |
    +-- NO --> Is remote change important?
                |
                +-- YES --> git fetch origin
                |           git log origin/main
                |           # Review changes
                |           git reset --hard origin/main
                |           # Then reapply your work
                |
                +-- NO --> git push --force-with-lease origin main
                           (your work overrides)
```

### 7.5 Auto-Generated Files Conflict Prevention

Files like `*.log`, `dev.log`, `*.db` often cause merge conflicts because they change automatically.

**Prevention:**
```bash
# Add to .gitignore
echo "*.log" >> .gitignore
echo "dev.log" >> .gitignore
echo "*.db" >> .gitignore

# If already tracked, remove from git
git rm --cached *.log
git rm --cached dev.log

# Commit the fix
git add .gitignore
git commit -m "chore: ignore auto-generated files"
git push origin main
```

**If conflict already happened on auto-generated file:**
```bash
# Accept your version (usually safe for logs)
git checkout --ours dev.log
git add dev.log
git commit -m "fix: resolve log file conflict"
git push origin main
```

### 7.6 Stash Safety in Sandbox

`git stash` can create problems in sandbox:

| Stash Risk | Why | Prevention |
|------------|-----|------------|
| Stash with conflict | Apply fails | Never stash during conflict |
| Stash + session end | Stash lost | Push instead of stash |
| Stash pop on dirty tree | Unexpected merge | Clean tree before pop |

**Safe stash workflow:**
```bash
# Only stash clean changes
git status  # verify what will be stashed
git stash push -m "descriptive message"

# Immediately commit to preserve
git stash pop
git add -A
git commit -m "wip: stashed changes"
git push origin main
```

### 7.7 Detached HEAD Recovery

Detached HEAD can occur after:
- Checking out a specific commit
- Checking out a tag
- Failed rebase continuation

**Recovery:**
```bash
# 1. Identify current state
git branch -v
git log --oneline -5

# 2. If work needs saving
git checkout -b rescue-branch
git push origin rescue-branch

# 3. Return to main
git checkout main
git pull origin main

# 4. Merge or reapply work
git merge rescue-branch
# OR manually reapply
```

### 7.8 Git Hooks Interference

Git hooks in `.git/hooks/` can interfere with automated operations:

| Hook | Potential Issue | Solution |
|------|-----------------|----------|
| `pre-commit` | Blocks automated commits | Disable or make idempotent |
| `pre-push` | Blocks force push | Accept or modify hook |
| `commit-msg` | Rejects commit format | Follow format or disable |

**Bypass hooks when necessary:**
```bash
git commit --no-verify -m "message"
git push --no-verify origin main
```

**Warning:** Only bypass hooks when you understand the consequences.

### 7.9 GPG Signing in Sandbox

GPG signing may block commits in sandbox if not configured:

```bash
# Check if GPG signing is enabled
git config commit.gpgsign

# If "true" and causing issues:
git config --global commit.gpgsign false

# Or configure GPG properly
git config --global gpg.program gpg2
git config --global user.signingkey <key-id>
```

### 7.10 Comprehensive Pre-Operation Checklist

Run this before ANY complex git operation:

```bash
# === STATE CHECK ===
echo "=== Git State Check ==="
git status
ls .git/*.lock 2>/dev/null && echo "WARNING: Lock files exist"
ls .git/rebase-merge/ 2>/dev/null && echo "WARNING: Rebase in progress"
ls .git/MERGE_HEAD 2>/dev/null && echo "WARNING: Merge in progress"

# === REMOTE SYNC ===
echo "=== Remote Sync Check ==="
git fetch origin
git log HEAD..origin/main --oneline
git log origin/main..HEAD --oneline

# === WORKING TREE ===
echo "=== Working Tree ==="
git diff --stat
git diff --cached --stat

# === DECISION ===
echo "=== Safe to proceed? ==="
echo "If ANY warnings above: RESOLVE FIRST"
```

### 7.11 Emergency Recovery Summary

| Situation | Immediate Action | Recovery Command |
|-----------|-----------------|------------------|
| Rebase deadlock | Session restart | `git rebase --abort` |
| Merge deadlock | Session restart | `git merge --abort` |
| Lock files | Remove locks | `rm -f .git/*.lock` |
| Remote ahead (solo) | Force push | `git push --force-with-lease origin main` |
| Detached HEAD | Create branch | `git checkout -b rescue && git push` |
| Auto-file conflict | Accept ours | `git checkout --ours <file>` |
| Hook blocking | Bypass hook | `git commit --no-verify` |

---

## 8. Post-Deadlock Recovery

After a git deadlock, another agent might clone the repository **inside** the broken project instead of **replacing** it. This creates a nested structure that breaks everything.

### 8.1 The Nested Project Trap

```text
WRONG (nested project - NOTHING WORKS):
/home/z/my-project/                          <- old broken project (git deadlock)
  +-- .git/                                  <- BLOCKED rebase
  +-- src/
  +-- package.json
  +-- Z.Code-Guide-Coding-Tool-Helper/       <- clone INSIDE old project!
       +-- .git/                             <- clean git
       +-- src/
       +-- package.json

CORRECT (clean replacement):
/home/z/my-project/                          <- clean clone (replacement)
  +-- .git/                                  <- clean git
  +-- src/
  +-- package.json
```

**Why nested projects fail:**
- Dev server won't find correct paths
- Port 3000 won't bind correctly
- Imports resolve to wrong node_modules
- Environment files not found
- Git operations affect wrong repository

### 8.2 Correct Procedure After Deadlock

**Step 1: Verify if project is corrupted**

```bash
# Check for deadlock state
ls /home/z/my-project/.git/rebase-merge/ 2>/dev/null && echo "DEADLOCKED"
ls /home/z/my-project/.git/MERGE_HEAD 2>/dev/null && echo "DEADLOCKED"

# Check for nested project (WRONG structure)
ls -d /home/z/my-project/*/  # should show src/, not another project!
```

**Step 2: If corrupted, DELETE ENTIRE directory and re-clone**

```bash
# DELETE the entire corrupted project
rm -rf /home/z/my-project

# Clone DIRECTLY to the target path (NOT as subdirectory)
git clone https://<token>@github.com/<owner>/<repo>.git /home/z/my-project

# Verify correct structure
ls /home/z/my-project/
# Should show: src/, package.json, .git/ — NOT another project folder!

# Setup
cd /home/z/my-project
bun install
cp .env.example .env
bun run db:push  # if applicable
npx next dev -p 3000
```

### 8.3 The Critical Difference

| Wrong | Correct |
|-------|---------|
| `git clone <url>` (creates subdirectory) | `git clone <url> /home/z/my-project` |
| `cd /home/z/my-project && git clone <url>` | `rm -rf /home/z/my-project && git clone <url> /home/z/my-project` |

**Key insight:** Always specify the target directory explicitly when cloning after deadlock:

```bash
# WRONG - creates nested project
git clone https://github.com/user/repo.git
# Result: /home/z/my-project/repo/  <- WRONG!

# CORRECT - replaces old project
git clone https://github.com/user/repo.git /home/z/my-project
# Result: /home/z/my-project/  <- CORRECT!
```

### 8.4 Cleanup Checklist After Deadlock Recovery

```text
[ ] Old directory completely removed (rm -rf)
[ ] Clone command specifies target path explicitly
[ ] No nested project structure exists
[ ] .git/ is at correct level (/home/z/my-project/.git/)
[ ] package.json is at correct level
[ ] bun install runs successfully
[ ] npx next dev -p 3000 starts on correct port
```

---

## 9. AI Agent Checklist

Mandatory before each stage:

```bash
[ ] Code written/changed
[ ] git add -A
[ ] git commit -m "description"
[ ] git push origin main
[ ] git status -> clean
[ ] Logged to worklog.md
[ ] git add worklog.md && git commit && git push (if worklog updated)
```

**Integration with other standards:**

- **STD-FE-001** (Frontend Standard): after file refactoring -> commit + push
- **Worklog**: after updating worklog.md -> commit + push
- **New skill/documentation**: after creation -> commit + push

**Principle:** any action changing filesystem must end with commit + push before moving to next action.

---

## 10. Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-05 | Extracted from STD-GIT-001 v1.5. Contains sandbox-specific content: sandbox constraints, session management, deadlock prevention and recovery, network failure recovery, sandbox safety rules, post-deadlock clone recovery, AI agent checklist. |
| 1.1 | 2026-06 | Stack Signature footer updated from "Git + Conventional Commits + SemVer 2.0 + GitHub" to "Next.js 16 + TypeScript + Tailwind CSS" to match STD-DOC-002 §8 convention (see GSB-001 in §10A). Added §10A Known Issues documenting GSB-001 through GSB-003. Added STD-META-001 to Related and Cross-References. |

---

## 10A. Known Issues and Proposed Solutions

This section documents discovered inconsistencies, missing content, and proposed corrections. Each issue has an ID, status, and proposed action. Issues resolved in the current version are marked `[RESOLVED]`; outstanding issues are marked `[OPEN]`.

### GSB-001 `[RESOLVED in v1.1]` — Stack Signature cited Git concepts instead of project stack

**Problem:** Prior to v1.1, the footer read "Built with: Git + Conventional Commits + SemVer 2.0 + GitHub". Per STD-DOC-002 §8 (Stack Signature), the format is `Built with: <project technologies>`, where the technologies are the project's tech stack. Git, Conventional Commits, SemVer, and GitHub are tools/specifications used by this standard — they describe what the standard *governs*, not what the project is *built with*. Every other standard in the project uses the conventional Next.js stack signature.

**Resolution:** Footer updated to "Built with: Next.js 16 + TypeScript + Tailwind CSS". The Git/Conventional Commits/SemVer/GitHub conventions are already implicit in the standard's title and body. The same fix was applied to STD-GIT-001 (see GIT-001 in that file's Known Issues).

### GSB-002 `[OPEN]` — §5.1 "Standard Recovery Procedure" Level 3 "Nuclear Reset" lacks a warning about losing unpushed work

**Problem:** §5.1 Level 3 (Nuclear Reset) shows:

```bash
mv .git .git.broken
git init
git remote add origin <remote-url>
git fetch origin
git reset origin/main
```

This procedure discards ALL local state — including unpushed commits — and replaces it with the remote state. The section does not explicitly warn that any unpushed work will be lost. A user following Level 3 as their first recovery attempt (without trying Level 1 or Level 2 first) could lose data permanently.

**Proposed solution:** Add a warning box at the top of §5.1 Level 3: "WARNING: Nuclear Reset discards ALL local state including unpushed commits. Only use this after Level 1 (Manual Terminal) and Level 2 (Sandbox Restart) have both failed. Before running these commands, attempt to recover unpushed commits via `git fsck --lost-found` (per STD-GIT-001 §4.2) on the `.git.broken` directory."

### GSB-003 `[OPEN]` — §6.6 Git Timeout Configuration uses `--global` scope, but sandbox sessions may not persist global config

**Problem:** §6.6 (Git Timeout Configuration) shows:

```bash
git config --global http.lowSpeedLimit 1000
git config --global http.lowSpeedTime 10
```

The `--global` scope writes to `~/.gitconfig`. In Z.ai sandbox, the home directory may or may not persist across sessions — this is not documented. If the home directory is reset on session restart, the timeout configuration is lost and must be reapplied every session.

**Proposed solution:** Add a note to §6.6: "In Z.ai sandbox, `--global` git config writes to `~/.gitconfig`. If the home directory persists across sessions (verify via `ls -la ~/.gitconfig` after restart), the configuration is durable. If the home directory is reset on each session, use `--local` scope (per-repository) instead, and apply the configuration in a setup script that runs at session start. Add the setup script to the project's `package.json` `postinstall` hook or to a `scripts/setup-git.sh` file invoked from the worklog startup checklist."

---

## 11. Cross-References

| Standard | Relationship |
|----------|-------------|
| STD-GIT-001 | Core git rules (commit format, branching, push policy, versioning, GitHub-specific) |
| STD-ENV-002 | Sandbox environment constraints |
| STD-AGENT-001 | Subagent commit protocol |
| STD-FE-001 | Post-refactor commit rules |
| STD-META-001 | Standard ID System: registry entry for STD-GIT-002 must be kept in sync with the version in this document's header |
