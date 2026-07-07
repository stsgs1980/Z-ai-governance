# Standard: Z.ai Integration v1.3 (EN)

> ID: STD-ENV-002
> Version: 1.3
> Level: **[C] Critical**
> Related: ENV-001-reproducibility.md (STD-ENV-001), ARCH-002-implementation-order.md (STD-ARCH-002), docs/sandbox/INDEX.md (reference)

---

## 1. Introduction

This standard defines rules and best practices for AI agent operation within the Z.ai sandbox environment. It ensures consistent, safe, and reproducible behavior across all Z.ai chat sessions.

---

## 2. Sandbox Environment Constraints

The Z.ai sandbox has specific characteristics that affect all operations:

| Constraint                    | Impact                                           | Mitigation                            |
| ----------------------------- | ------------------------------------------------ | ------------------------------------- |
| Shared filesystem             | Files from one chat visible in all chats         | Use project-specific directories      |
| Chat = Shell process          | Processes die when chat ends                     | Use `disown` for background processes |
| Process mortality             | Background processes die after ~5 min inactivity | Watchdog with cron every 5 min        |
| No cross-chat process sharing | Cannot control processes from other chats        | File-based coordination               |
| Git lockup possible           | Previous chat may leave git blocked              | Recovery protocol defined below       |

---

## 3.0. Bootstrap Procedure for a New Project

This subsection defines the canonical bootstrap flow when starting a new project in the Z.ai sandbox. It is **thin** — full reference material lives in `docs/sandbox/` and is loaded on demand.

### 3.0.1. Seven-step bootstrap flow

| Step | Action                                                                                                                                                                 | Verify                                                                                                 | Reference                                                                                                                |
| ---- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| 1    | Confirm the sandbox shell is fresh: no stale `.git/rebase-merge`, no orphan `next dev` processes                                                                       | `git status` reports clean; `pgrep -f 'next dev'` returns nothing                                      | §4.3 below; `docs/sandbox/sandbox-guide.md` §8                                                                           |
| 2    | Place the project under `/home/z/my-project/` (the designated sandbox root)                                                                                            | `pwd` starts with `/home/z/my-project/`                                                                | §3 below                                                                                                                 |
| 3    | Install standards compliance layer: clone `Z-ai-governance` so `standards/`, `guard/`, `skills/` are all present                             | `ls standards/standards/*.md \| wc -l` returns 20; `node standards/scripts/verify-id-graph.js` exits 0 | `ARCH-002-implementation-order.md` §1 install order; `ARCH-001-architecture-and-repo-layout.md` §3 repo layout |
| 4    | Read `worklog.md` (tail 200 lines) to learn what prior sessions did, then append a new section with the bootstrap Task ID                                              | `tail -200 worklog.md` shows recent context; your new section appears at end                           | §6.2 below; `AGENT-002-orchestration.md`                                                                                 |
| 5    | For fullstack web-dev sessions only: run `init-fullstack_*.sh` from `https://z-cdn.chatglm.cn/`, then add `allowedDevOrigins` to `next.config.ts` manually (infra bug) | `next dev` returns HTTP 200 on `http://127.0.0.1:3000/`; `next.config.ts` contains `allowedDevOrigins` | `docs/sandbox/sandbox-guide.md` §1-5; `docs/sandbox/INDEX.md` §3 contradiction #3                                        |
| 6    | For docs/methodology sessions (no Next.js): skip step 5, do NOT start dev server, do NOT create `src/app/`                                                             | `ls src/app/ 2>/dev/null` returns "No such file"                                                       | `docs/sandbox/INDEX.md` §2 scenario table                                                                                |
| 7    | Before declaring "project ready", run `docs/sandbox/verify-sandbox.sh` (fullstack only) or `verify-id-graph.js` (any session)                                          | Both exit 0                                                                                            | `docs/sandbox/verify-sandbox.sh`; §11 below                                                                              |

### 3.0.2. What the bootstrap flow guarantees

After steps 1-7 complete successfully:

- The project lives in the designated sandbox root (no path drift).
- The standards compliance layer is present and self-consistent (ID graph passes HARD checks G01-G15).
- The worklog carries forward prior context — no "black box" between sessions.
- For fullstack sessions: dev server starts cleanly, no CORS/Caddy/port issues.
- For docs sessions: no accidental Next.js scaffolding pollutes the project tree.

### 3.0.3. When the bootstrap flow fails

If any step fails, STOP and consult the reference column before retrying. Do NOT work around failures — they almost always indicate an environment issue (stale rebase, missing directory, infra bug) that must be fixed, not hidden.

---

## 3. Project Directory

All projects MUST reside in `/home/z/my-project/`:

- This is the designated sandbox working directory
- Do NOT create project clones in other directories
- All relative paths in configs must resolve from this directory
- Output files go to `/home/z/my-project/download/`
- Dev server logs go to `/tmp/zdev.log`

### 3.1 Absolute Path Exception

`/home/z/my-project/` and related sandbox paths are allowed as environment-constant exceptions in Z.ai sandbox code. All other absolute paths are prohibited by REPRODUCIBILITY_STANDARD (STD-ENV-001 v2.1, L1 Path Rules). This section (§3.1) is the authoritative source for the sandbox path table; STD-ENV-001 §1.2 mirrors it for self-contained readability.

| Path                            | Status     | Reason                                    |
| ------------------------------- | ---------- | ----------------------------------------- |
| `/home/z/my-project/`           | Allowed    | Designated sandbox working directory      |
| `/home/z/my-project/download/`  | Allowed    | Designated output directory               |
| `/tmp/zdev.log`                 | Allowed    | Dev server log (not in source code)       |
| `/tmp/` (for backups)           | Allowed    | Temporary backups (not committed)         |
| `/home/user/`, `/Users/`, `C:\` | Prohibited | Platform-specific, breaks reproducibility |
| `http://localhost:` in source   | Prohibited | Use relative paths or XTransformPort      |

Relative paths are preferred when `process.cwd()` resolves to `/home/z/my-project/`. Use `path.resolve(process.cwd(), ...)` for database and file paths.

---

## 4. Git Operations in Sandbox

### 4.1 Backup Before Rewrite

Before any git operation that rewrites history (rebase, merge, pull, reset --hard):

```bash
git stash push -m "pre-op-backup"
cp -r src/ /tmp/src-backup/
git log --oneline -20 > /tmp/git-log-backup.txt
```None

### 4.2 Force Push Over Rebase

- `git push --force-with-lease origin main` -- CORRECT
- `git push --force origin main` -- AVOID
- `git pull --rebase` -- FORBIDDEN (blocks sandbox on conflict)

### 4.3 Git Lockup Recovery

If a previous chat left git in a blocked state:

```bash
rm -rf .git/rebase-merge .git/rebase-apply
git reset --hard HEAD
```

This must be done from a NEW chat session.

---

## 5. Dev Server Protocol

### 5.1 Startup

```bash
pkill -f 'next dev' 2>/dev/null
sleep 1
cd /home/z/my-project && npx next dev -p 3000 </dev/null >/tmp/zdev.log 2>&1 & disown
sleep 6
curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3000/
```None

### 5.2 Rules

- Always use `disown` after backgrounding
- Always use `npx next dev`, NOT `bun run dev`
- Always redirect output: `>/tmp/zdev.log 2>&1`
- Always close stdin: `</dev/null`
- Always use `127.0.0.1` for health checks (not `localhost`)

### 5.3 Health Check Response Codes

| Code | Action                   |
| ---- | ------------------------ |
| 200  | Server running, proceed  |
| 000  | Server down, restart     |
| 500  | Server error, check logs |

---

## 6. Session Continuity

### 6.1 Context Preservation

When a session is interrupted or context is lost:

1. Read `worklog.md` for previous session history
2. Check git state: `git log --oneline -10` and `git status`
3. Verify dev server status
4. Report current state to user before continuing

### 6.2 Worklog Protocol

- Every agent MUST append work records to `worklog.md`
- Format: Task ID, agent name, work log, stage summary
- NEVER overwrite existing worklog entries
- Use `/home/z/my-project/worklog.md` as the canonical location

---

## 7. File Safety

### 7.1 Auto-Backup

Before any write mutation on critical files:

- Create a backup copy in `/tmp/`
- Log the backup location in worklog.md

### 7.2 Safe Delete

Before deleting any entity:

- Verify with user via confirmation dialog
- Archive instead of hard-delete when possible

---

## 8. API Communication

### 8.1 z-ai-web-dev-sdk

- Use `z-ai-web-dev-sdk` for AI model interactions
- MUST be used in backend code only (never client-side)
- Import: `import ZAI from 'z-ai-web-dev-sdk'`

### 8.2 Retry Strategy

When calling chat.z.ai:

- Exponential backoff: 2s initial, 2x multiplier
- Max 3 retries
- Retryable: 502, 503, 504
- Non-retryable: 401, 403, 404

---

## 9. SDK Integration

### SDK Usage Rules

1. **Backend-only**: z-ai-web-dev-sdk MUST only be used in API routes (app/api/), never in client components
2. **Singleton Pattern**: Create a single ZAI instance and reuse it across requests
3. **Error Propagation**: All SDK errors must propagate through the api-retry skill
4. **Health Check**: Verify chat.z.ai availability via health-check skill before SDK calls
5. **Fallback Chain**: When SDK fails, use fallback skill to switch providers
6. **Image Generation**: Use z-ai-generate CLI for website assets (favicon, logo, backgrounds)
7. **Web Search**: Use zai.functions.invoke("web_search", {...}) for real-time data
8. **Type Safety**: Always type API responses with TypeScript interfaces
9. **Timeout**: Set explicit timeouts (30s for chat, 60s for image generation)
10. **Logging**: Log all SDK interactions to worklog.md with request/response metadata

---

**Document complies with MARKDOWN_STANDARD v2.3 (level [W])**

---

## 10. Version History

| Version | Date       | Changes                                                                                                                                                                                                                                                                                                                                    |
| ------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1.0     | 2026-05    | Initial standard extracted from AGENT_RULES.md                                                                                                                                                                                                                                                                                             |
| 1.1     | 2026-05-14 | Added SDK Integration section with 10 usage rules                                                                                                                                                                                                                                                                                          |
| 1.2     | 2026-06    | Updated §6 Related to reference `REPRODUCIBILITY_STANDARD` (was `REPRODUCIBILITY-STANDARD` — see ZAI-001). Updated §3.1 to reference STD-ENV-001 v2.1 (was v1.1 — see ZAI-002). Updated compliance footer to MARKDOWN_STANDARD v2.3 (was v2.1 — see ZAI-003). Added §3.1 authoritative-source note (see ZAI-004). Added §10A Known Issues. |
| 1.3     | 2026-06-18 | Added §3.0 Bootstrap Procedure for a New Project (7-step flow, thin, references `docs/sandbox/`). Updated Related: field to include `ARCH-002-implementation-order.md` and `docs/sandbox/INDEX.md`. Added ZAI-008 to Known Issues.                                                                                                         |

---

## 10A. Known Issues and Proposed Solutions

This section documents discovered inconsistencies, missing content, and proposed corrections. Each issue has an ID, status, and proposed action. Issues resolved in the current version are marked `[RESOLVED]`; outstanding issues are marked `[OPEN]`.

### ZAI-001 `[RESOLVED in v1.2]` — §6 Related field referenced old filename `REPRODUCIBILITY-STANDARD`

**Problem:** Prior to v1.2, the §6 Related field said "REPRODUCIBILITY-STANDARD (STD-ENV-001)" — using the hyphenated filename. The file has been renamed to `ENV-001-reproducibility.md` (underscore) to match the convention used by all other standards.

**Resolution:** §6 Related field updated to "REPRODUCIBILITY_STANDARD (STD-ENV-001)". The cross-reference is now symmetric with STD-ENV-001's §7 entry for STD-ENV-002.

### ZAI-002 `[RESOLVED in v1.2]` — §3.1 cited STD-ENV-001 v1.1 (stale)

**Problem:** §3.1 said "REPRODUCIBILITY-STANDARD (STD-ENV-001 v1.1, L1 Path Rules)". STD-ENV-001 is at v2.1 (after the file rename and Known Issues addition in its v2.1 release).

**Resolution:** §3.1 now references "REPRODUCIBILITY_STANDARD (STD-ENV-001 v2.1, L1 Path Rules)".

### ZAI-003 `[RESOLVED in v1.2]` — Compliance footer cited MARKDOWN_STANDARD v2.1 (stale)

**Problem:** The compliance footer said "Document complies with MARKDOWN_STANDARD v2.1 (level [W])". STD-DOC-002 is at v2.3.1.

**Resolution:** Footer updated to "Document complies with MARKDOWN_STANDARD v2.3 (level [W])".

### ZAI-004 `[RESOLVED in v1.2]` — §3.1 sandbox path table duplicated STD-ENV-001 §1.2 without authoritative-source designation

**Problem:** §3.1 contains the sandbox path table. The same table appears verbatim in STD-ENV-001 §1.2. Neither document stated which was authoritative, creating a silent-drift risk.

**Resolution:** §3.1 now declares itself the authoritative source: "This section (§3.1) is the authoritative source for the sandbox path table; STD-ENV-001 §1.2 mirrors it for self-contained readability." See REP-002 in STD-ENV-001 §6A for the cross-reference.

### ZAI-005 `[OPEN]` — §9 "SDK Integration" section has no number prefix on its subsection

**Problem:** §9 is titled "SDK Integration" but its single subsection is "### SDK Usage Rules" — without the `9.1.` prefix that all other sections use for their subsections. This is a minor formatting inconsistency.

**Proposed solution:** Renumber the subsection to "### 9.1. SDK Usage Rules". No content change required.

### ZAI-006 `[OPEN]` — §5.2 mandates `npx next dev` over `bun run dev`, but does not explain why

**Problem:** §5.2 says "Always use `npx next dev`, NOT `bun run dev`". STD-ENV-001 §1 (Note on package manager vs. runtime) explains the reason: "the Bun wrapper for Next.js is unstable in sandbox environments". However, §5.2 of this standard does not include the rationale — a reader landing on §5.2 directly sees the rule without the "why".

**Proposed solution:** Add a one-line note to §5.2: "The Bun wrapper for Next.js is unstable in sandbox environments (see STD-ENV-001 §1 Note). Use `npx next dev` for the dev server; use `bun run` for other scripts (lint, build, test)."

### ZAI-007 `[OPEN]` — `AGENT_RULES.md` referenced in Version History v1.0 but file is not shipped

**Problem:** §10 Version History v1.0 entry says "Initial standard extracted from AGENT_RULES.md". The file `AGENT_RULES.md` is not present in the standards directory or the project root. The reference is historical (the standard was originally extracted from that file), but a reader may look for the file and not find it.

**Proposed solution:** This is the same issue as RMT-002 in README_TEMPLATE — `AGENT_RULES.md` is referenced by multiple standards but never defined. Resolve via the option chosen in RMT-002. If option 2 (define AGENT_RULES.md in this standard) is chosen, add a new §12 "AGENT_RULES.md Definition" subsection that defines the file's structure and mandatory content.

### ZAI-008 `[OPEN]` — §3.0 Bootstrap Procedure references `init-fullstack_*.sh` without pinning a version

**Problem:** §3.0.1 step 5 references `init-fullstack_*.sh` from `https://z-cdn.chatglm.cn/` using a glob, but does not pin which version. The script URL contains a timestamp (e.g. `init-fullstack_1775040338514.sh`) which changes over time. Different versions may produce different scaffolding, breaking reproducibility.

**Proposed solution:** Add a §3.0.4 "Pinned init-fullstack version" subsection that records the exact script URL and SHA256 of the script used at the time of writing. Update on each verified upgrade. Cross-reference with STD-ENV-001 reproducibility rules.

---

## 11. Cross-References

| Standard     | Relationship                                                                                                       |
| ------------ | ------------------------------------------------------------------------------------------------------------------ |
| STD-ENV-001  | Reproducibility Standard: path rules (Section 1.2 mirrors §3.1 of this document; §3.1 is authoritative)            |
| STD-META-001 | Standard ID System: registry entry for STD-ENV-002 must be kept in sync with the version in this document's header |
