---
name: zai-sandbox-rules
id: ZAI-DEV-005
author: StsDev
version: "1.5.0"
description: "CRITICAL: Load this skill BEFORE responding to ANY request involving dev servers, npm/bun/next commands, or sandbox operations. This skill MUST be checked before executing any command. Triggers on: bun run dev, npm run dev, next dev, start dev, run dev, запусти dev, dev server, preview not working, EADDRINUSE, HMR crash, port 3000, module not found, init sandbox, restart dev, sandbox broken, white screen, 500 error, sandbox inactive, idle timeout."
trigger: "bun run dev, npm run dev, next dev, start dev, run dev, запусти dev, dev server, preview not working, EADDRINUSE, HMR crash, port 3000, module not found, init sandbox, restart dev, sandbox broken, white screen, 500 error, sandbox inactive, idle timeout"
related:
  - STD-ENV-001
  - STD-ENV-002
  - STD-META-001

# Skill: Zai Sandbox Rules v1.5.0

## Purpose

**STOP.** If you were about to run `bun run dev`, `npm run dev`, `next dev`, or any dev server command — DO NOT. Read this skill first.

This skill contains the critical rules for operating within the Z.ai development sandbox. These rules MUST be followed by every agent to avoid breaking the preview environment, creating port conflicts, or interfering with the sandbox's own dev server management.

## Why Dev Servers Are Forbidden

The sandbox manages its own dev server via `.zscripts/dev.sh`. This wrapper runs `bun run dev` which starts `next-server` on port 3000. If you run `bun run dev` (or any equivalent) at the project root, you create a SECOND process competing for port 3000. Result: `EADDRINUSE`, duplicate processes, broken HMR, and a preview that stops updating. The sandbox's own server is already running -- yours is redundant and destructive.

## When NOT to Use

Do not apply this skill when any of the following is true. These are near-misses that share keywords with the triggers but are not sandbox-management problems.

- The 500 error or failed request comes from an external API, a third-party service, or your own API route (e.g. `fetch('/api/users')` returns 500). That is a bug in your code, not a sandbox problem. Debug it as a normal application error.
- The "module not found" error is in a Python project (`ModuleNotFoundError: No module named '...'`), a Rust project, a Go project, or any non-Node runtime. This skill is about the Z.ai Node/Next.js sandbox only. Use the appropriate package manager for that runtime (`pip install`, `cargo add`, `go get`).
- You are working outside the Z.ai sandbox (different host, local machine, CI runner, Docker container you control). The rules below assume the sandbox is managing the dev server. On a plain machine, you DO start dev servers manually.
- The user explicitly asks you to start a specific mini-service or background process on a custom port (e.g. a WebSocket service on port 3003, a Redis on 6379). Mini-services are not the Next.js dev server and are not covered by Rule 1. Just start them as requested.
- The user asks you to run a one-shot build, lint, or test command (e.g. `bun run lint`, `npm test`, `tsc --noEmit`). These are not dev servers and are allowed; only long-running dev servers on port 3000 are forbidden.
- The "port 3000" mention is a user request to expose something on port 3000 (e.g. "make the API available on port 3000"), not an `EADDRINUSE` error. That is a feature request, not a crash.

## Rule 1: NEVER Run Dev Servers Manually

The sandbox manages its own dev server process via `.zscripts/dev.sh`. **DO NOT** run any of the following commands manually:

- `npm run dev`
- `bun dev`
- `next dev`
- `npx next dev`
- `yarn dev`
- `npx create-next-app`
- Any command that starts a development server on port 3000 or any other port

The sandbox will start, stop, and restart dev servers automatically. Manual invocation causes port conflicts (`EADDRINUSE`), duplicate processes, and broken HMR (Hot Module Replacement).

## Rule 2: Before Checking Dev Logs

Before inspecting dev server logs or checking for errors:

1. Check if the dev server is actually running: `cat /home/z/my-project/.zscripts/dev.pid` (PID file exists = server was started). `cat /home/z/my-project/.zscripts/dev.log | tail -10` (recent log lines = server is active).
2. Check the preview panel's console output first (browser DevTools)
3. Only check server-side logs if the browser console does not reveal the issue

There is no UI status indicator in the Z.ai interface. Filesystem checks are the only reliable way to know if the dev server is alive.

## Rule 3: When Preview Is Not Working

The response depends on the cause. Do NOT apply a one-size-fits-all wait.

**If the preview shows "sandbox is inactive" (idle timeout, ~5min of inactivity):**

1. The sandbox killed the dev server due to inactivity
2. Wait 10-30 seconds and refresh the Preview Panel -- the sandbox should auto-restart
3. If it does not restart, run the reinitialization: `curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash`

**If the preview shows a 500 error, white screen, or compilation failure:**

1. Do NOT wait. Check `cat /home/z/my-project/.zscripts/dev.log | tail -30` immediately for the error
2. Check the browser console (F12) for client-side errors
3. Check for syntax errors in recently modified files
4. If the issue is an HMR crash (deleted/corrupted file), see Rule 5
5. If the issue persists, report the specific error message with full stack trace

## Rule 4: Port Conflicts (EADDRINUSE)

If you see `EADDRINUSE` or port 3000 is already in use, follow the prescribed recovery. Do NOT just report and wait.

1. Do NOT start another dev server (that caused the conflict)
2. Kill the stale dev server: `pkill -f "next dev"; pkill -f "bun run dev"`
3. Reinitialize the sandbox: `curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash`
4. Verify recovery: `cat /home/z/my-project/.zscripts/dev.log | tail -10` -- should show `ready in` or `started server on`
5. Check that the preview panel updates again

## Rule 5: HMR Crash

If Hot Module Replacement crashes (e.g. you deleted or corrupted a file that Turbopack was watching):

HMR does NOT auto-recover after file deletion. A full restart is required.

1. Save the current file state
2. Kill the dev server: `pkill -f "next dev"`
3. Remove the build cache: `rm -rf /home/z/my-project/.next`
4. Reinitialize the sandbox: `curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash`
5. Wait 15 seconds for the dev server to come up (this is a POST-reinit wait, not an auto-recovery timer)
6. Verify: `cat /home/z/my-project/.zscripts/dev.log | tail -10`

Do NOT restart via `npm run dev` / `bun run dev` / `next dev` manually. Use the prescribed recovery above.

## Rule 6: Module Not Found

If you see `module not found` or `Cannot resolve` errors:

1. Check if the dependency is listed in `package.json`
2. Run `npm install <package>` or `bun add <package>` to add the missing dependency
3. Do NOT run `npm install` without arguments (may downgrade packages)
4. After installing, reinitialize the sandbox: `curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash`. HMR detects file edits automatically, but dependency changes need explicit reinit.

## Rule 7: Cloning Repos and Submodules

When cloning third-party repositories in the sandbox, follow the guide's prescribed pattern. Do NOT clone directly into the project directory.

1. Clone temporarily to /tmp: `cd /tmp && git clone --depth 1 <repo-url>`
2. Copy project files to the sandbox root, excluding node_modules and .next: `rsync -av --exclude=node_modules --exclude=.next /tmp/<repo>/ /home/z/my-project/`
3. Clean up: `rm -rf /tmp/<repo>`
4. Install dependencies: `cd /home/z/my-project && bun install` (or `npm install --legacy-peer-deps` for npm)
5. Reinitialize the sandbox: `curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash`
6. Check if the project has its own `package.json` and dependencies
7. Verify build: `cd /home/z/my-project && bun run build` (or `npm run build`)
8. Configure git: `git config user.email "stsgs1980@gmail.com" && git config user.name "stsgs1980"`

**npm vs bun:** If the project has `package-lock.json`, use `npm install --legacy-peer-deps` (avoids ERESOLVE errors). If it has `bun.lock`, use `bun install`.

Note: /tmp is writable and is the correct place for transient work (cloning, staging). The prohibition is on relying on /tmp for PERSISTENCE -- it does not survive sandbox restart.

## Rule 8: Build Verification

After cloning or installing dependencies, ALWAYS verify the build compiles:

```bash
cd /home/z/my-project && bun run build  # or npm run build
```

This catches broken imports, missing packages, and TypeScript errors before they cause 500 errors in the preview. Do NOT skip this step.

## Rule 9: Init Sandbox

When initializing a new sandbox project or reinitializing after a crash:

1. Use the canonical reinitialization command: `curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash`
2. This command sets up the dev server, installs dependencies, and starts the preview
3. Do NOT create project scaffolding manually if the sandbox provides templates
4. Follow the sandbox's directory conventions (everything under `/home/z/my-project/`)
5. Ensure all files are created under the sandbox's project root

## Rule 10: White Screen / 500 Error Debugging

For white screens or 500 errors:

1. Open browser DevTools (F12) and check the Console tab
2. Check the Network tab for failed requests (red status codes)
3. Look for runtime errors in the Console (TypeError, ReferenceError, etc.)
4. Check if the page HTML is loading but JavaScript is failing (white screen with HTML in Network)
5. Check for environment variable issues (missing `.env` values)
6. Check `cat /home/z/my-project/.zscripts/dev.log | tail -30` for server-side errors
7. Report all findings with specific error messages and stack traces

## Rule 11: File System Constraints

- All work that must persist MUST be under `/home/z/my-project/` and must be git-committed
- Do NOT rely on `/tmp`, `/usr`, `/etc` for persistence (these do not survive sandbox restart)
- `/tmp` is acceptable for transient work (e.g., cloning before rsync -- see Rule 7)
- Do NOT modify files outside the project scope
- Use absolute paths when referencing files in scripts
- Do NOT modify `page.tsx`, `layout.tsx`, or other core files unless explicitly requested by the user

## Rule 12: Git Submodules

When adding or updating git submodules in the sandbox:

**Adding a submodule:**
```bash
cd /home/z/my-project
git submodule add <repo-url> src/lib/<name>
# Reinitialize after adding (HMR may crash):
curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash
```

**Updating a submodule:**
```bash
git submodule update --remote src/lib/<name>
git add src/lib/<name>
git commit -m "chore: update <name> submodule"
# Reinitialize if dependencies changed:
curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash
```

**If submodule folder is empty after clone:**
```bash
git submodule update --init --recursive
```

## Rule 13: Database (Prisma)

If the project uses Prisma, after any schema change or after cloning:

```bash
cd /home/z/my-project
bunx prisma db push      # Apply schema to database
bunx prisma generate     # Generate Prisma client
bunx prisma migrate reset  # Reset database (destructive)
```

## Useful Commands

```bash
# Dev server status
cat /home/z/my-project/.zscripts/dev.pid
cat /home/z/my-project/.zscripts/dev.log | tail -30

# Code quality
cd /home/z/my-project && bun run lint
bunx tsc --noEmit

# Preview URL
echo $FC_CONTAINER_ID
# https://preview-<container-id>.space-z.ai/
```

## Rationalization Table

This skill enforces prohibitions (NEVER run dev servers, do NOT kill processes, do NOT change ports, etc.). Under task pressure, the model will generate plausible-sounding excuses to bypass these rules. The table below pre-emptively debunks the rationalizations observed in practice. When you catch yourself thinking the left column, apply the right column.

| Excuse | Reality |
|---|---|
| "HMR is broken, I have to restart the dev server" | No. Restart via the prescribed recovery: pkill + rm .next + reinit. See Rule 5. Running `bun run dev` manually causes EADDRINUSE and duplicate processes. |
| "I'll only run `next dev` once, it won't hurt" | One manual run is enough to cause EADDRINUSE plus a duplicate process plus broken HMR. The sandbox already runs the dev server. See Rule 1. |
| "`bun run dev` is not `npm run dev`, so Rule 1 doesn't apply" | Rule 1 forbids ANY command that starts a dev server on port 3000, regardless of package manager. `bun dev`, `next dev`, `npx next dev`, `yarn dev` are all prohibited. See Rule 1. |
| "The session instructions said `bun run dev`, so I'm allowed to run it" | The instructions describe what the sandbox does automatically. They are not permission for you to run it manually. See Rule 1. |
| "The preview has been down for 5 seconds, I have to act now" | For idle timeout: wait 10-30 seconds, then refresh. For 500 errors: check logs immediately (Rule 3). Acting too early on idle timeout restarts a sandbox that was about to recover on its own. |
| "I need to start my mini-service on port 3003, but Rule 1 forbids it" | Rule 1 forbids dev servers on port 3000, not mini-services on other ports. Mini-services are expected and allowed. This is a false generalization. |
| "EADDRINUSE means the sandbox is broken, I should kill the process" | No. The sandbox manages ports. Follow the prescribed recovery: pkill + reinitialize. See Rule 4. Do not just report and wait. |
| "The sandbox hung, I have to intervene" | If the preview is unresponsive, determine the cause first (idle timeout vs. crash). For idle: wait and refresh. For crash: pkill + reinit (Rule 5). Manual intervention without diagnosis makes recovery harder. |
| "I'll wait for HMR to auto-recover" | HMR does NOT auto-recover after file deletion (Rule 5). Waiting wastes time. Follow the prescribed restart procedure. |

## Red Flags: STOP

If you catch yourself thinking or about to type any of the following, STOP. Re-read Rules 1 through 13 before acting.

- "Just this once"
- "Only one time"
- "It's an emergency, the rules don't apply"
- "bun run dev is not the same as npm run dev"
- "HMR is broken, I have to restart"
- "The preview is down, I have to act now"
- "The sandbox hung, I have to intervene"
- "I'll kill the process to free the port"
- "I'll change the port to avoid the conflict"
- "The instructions said `bun run dev`, so I can run it"

Any of these is a signal that you are about to violate this skill. Stop, re-read the relevant rule, and follow the rule instead of the rationalization.

---

## Stack Signature Override

This skill carries a project-mandated Stack Signature as a project-specific override of DOC-002 section 8 (which by default excludes skills from Stack Signature scope). The override is set by the project owner and applies to all skills in this library.
