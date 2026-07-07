# Z.ai Sandbox - Complete Guide

> This guide is based on real hands-on experience. All errors and solutions are real.

---

## Table of Contents

1. [Quick Start](#1-quick-start)
2. [Project Structure](#2-project-structure)
3. [Development Rules](#3-development-rules)
4. [Working with Dependencies](#4-working-with-dependencies)
5. [Preview Panel](#5-preview-panel)
6. [Cloning a Third-Party Project](#6-cloning-a-third-party-project)
7. [Dev Server Won't Start](#7-dev-server-wont-start)
8. [Port 3000 Busy (EADDRINUSE)](#8-port-3000-busy-eaddrinuse)
9. [HMR Crashed - Page Returns 500](#9-hmr-crashed---page-returns-500)
10. [Modules Not Found (Module not found)](#10-modules-not-found-module-not-found)
11. [Git Submodule](#11-git-submodule)
12. [Common Errors and Solutions](#12-common-errors-and-solutions)
13. [Useful Commands](#13-useful-commands)
14. [Pre-Completion Checklist](#14-pre-completion-checklist)
15. [Full Workflow Example](#15-full-workflow-example)
16. [Golden Rules](#16-golden-rules)
17. [Known Infrastructure Issues](#17-known-infrastructure-issues)

---

## 1. Quick Start

### Clean Start - Correct Sequence

```bash
# Step 1: Initialize the sandbox (ALWAYS the first command)
curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash
```

This command:

- Creates a Next.js 16 project structure
- Installs base dependencies
- Configures TypeScript, Tailwind CSS, shadcn/ui
- **Automatically starts the dev server** in the background via `.zscripts/dev.sh`
- Writes logs to `/home/z/my-project/.zscripts/dev.log`

```bash
# Step 2: Install additional dependencies
cd /home/z/my-project && bun add <package-name>

# Example:
bun add framer-motion
bun add three @react-three/fiber @react-three/drei
```

```bash
# Step 3: Verify everything works
cat /home/z/my-project/.zscripts/dev.log | tail -20
# Expected: "GET / 200 in ..."
```

### What NOT to do

```bash
# [FAIL] Do NOT start dev server manually
npm run dev
bun run dev
next dev
npx next dev

# [FAIL] Do NOT create projects from scratch
npx create-next-app

# [FAIL] Do NOT clone into subfolders (see section 6)
git clone ... && cd subdir && npm install
```

> **Why:** The sandbox manages the dev server itself through `.zscripts/dev.sh`. Manual startup breaks the Preview Panel - preview does not update and stops working.

### Sandbox Agent Limitations

The sandbox agent (GLM-5.2, M-5-Turbo) has security restrictions that affect command execution:

| Command Type        | Agent Behavior | Reason                                    |
| ------------------- | -------------- | ----------------------------------------- |
| `curl ... \| bash`  | **BLOCKED**    | Executes remote code — high security risk |
| `bash <(curl ...)`  | **BLOCKED**    | Executes remote code — high security risk |
| `git clone`         | **ALLOWED**    | Downloads files only — low risk           |
| `git pull`          | **ALLOWED**    | Downloads files only — low risk           |
| `bun add`           | **ALLOWED**    | Package installation — expected behavior  |
| `node scripts/*.js` | **ALLOWED**    | Local script execution — low risk         |

**Workaround for bootstrap.sh:**

If the agent refuses to run bootstrap.sh, use this alternative sequence:

```bash
# Agent will execute these commands:
git clone https://github.com/stsgs1980/Z-ai-governance.git /home/z/my-project/Z-ai-governance
cd /home/z/my-project/Z-ai-governance
git config core.fileMode false
# Skills are already integrated — no symlink needed
```

**Why this works:**

- `git clone` is safe (downloads files only)
- `git config` is safe (modifies local config)
- Skills are already present in the repo as inline directories

**For fresh sandbox sessions:**
The agent will typically find and execute the necessary commands on its own when given a clear goal. Provide context:

> "I need to set up Z-ai-governance in this sandbox. Clone https://github.com/stsgs1980/Z-ai-governance.git into /home/z/my-project/Z-ai-governance and verify the skills are accessible."

---

## 2. Project Structure

```text
/home/z/my-project/
  src/
    app/
      page.tsx          # MAIN FILE - all UI goes here
      layout.tsx        # Layout (rarely needed)
      globals.css       # Global styles
    components/
      ui/               # shadcn/ui components
      sections/         # Page sections
      features/         # Stateful components
    lib/
      perf-data.ts
      db.ts
      utils.ts
  prisma/
    schema.prisma       # Database schema
  public/               # Static files
  .zscripts/
    dev.sh              # Dev server startup script (DO NOT EDIT)
    dev.pid             # Process PID
    dev.log             # LOGS (read from here on errors)
  package.json
  tsconfig.json
  tailwind.config.ts
  next.config.ts
```

### Important Files

| File                   | Purpose                                               |
| ---------------------- | ----------------------------------------------------- |
| `src/app/page.tsx`     | **Single page** - all UI here                         |
| `src/components/ui/`   | Ready shadcn/ui components                            |
| `prisma/schema.prisma` | Database definition                                   |
| `.zscripts/dev.log`    | Dev server logs                                       |
| `next.config.ts`       | Next.js configuration (including `allowedDevOrigins`) |

---

## 3. Development Rules

### [OK] DO

1. **Write code only in `src/app/page.tsx`**

   ```tsx
   "use client";

   export default function Home() {
     return <div className="min-h-screen">{/* Your UI */}</div>;
   }
   ```

2. **Use shadcn/ui components**

   ```tsx
   import { Button } from "@/components/ui/button";
   import { Card } from "@/components/ui/card";
   ```

3. **Create additional components in `src/`**

   ```text
   src/
     app/
       page.tsx
     my-components/
       Chart.tsx
       Data.tsx
   ```

4. **Use `'use client'` for interactive components**

   ```tsx
   "use client";

   import { useState } from "react";
   ```

5. **Check logs on errors**
   ```bash
   cat /home/z/my-project/.zscripts/dev.log | tail -30
   ```

### [FAIL] DO NOT

1. **Do NOT start dev server manually**

   ```bash
   # [FAIL] DO NOT DO THIS
   npm run dev
   bun run dev
   next dev
   ```

2. **Do NOT create other routes**

   ```bash
   # [FAIL] DO NOT DO THIS
   src/app/about/page.tsx
   src/app/api/route.ts
   ```

3. **Do NOT use external URLs for preview**

   ```bash
   # [FAIL] DO NOT DO THIS
   http://localhost:3000
   http://127.0.0.1:3000
   preview-xxx.space.chatglm.site
   ```

4. **Do NOT create a project from scratch**

   ```bash
   # [FAIL] DO NOT DO THIS
   npx create-next-app
   ```

5. **Do NOT clone repositories into separate folders**
   ```bash
   # [FAIL] DO NOT DO THIS
   git clone https://github.com/xxx/yyy.git
   cd yyy && npm install
   ```

---

## 4. Working with Dependencies

### Installing Packages

```bash
cd /home/z/my-project && bun add <package>
```

### Common Dependencies

| Category    | Packages                                     |
| ----------- | -------------------------------------------- |
| 3D Graphics | `three @react-three/fiber @react-three/drei` |
| Animations  | `framer-motion`                              |
| Charts      | `recharts`                                   |
| Forms       | `react-hook-form @hookform/resolvers zod`    |
| Dates       | `date-fns`                                   |
| Tables      | `@tanstack/react-table`                      |

### Prisma (Database)

1. Define the schema in `prisma/schema.prisma`:

   ```prisma
   model User {
     id    Int    @id @default(autoincrement())
     name  String
     email String @unique
   }
   ```

2. Apply the schema:

   ```bash
   bun run db:push
   ```

3. Use in code:
   ```tsx
   import { db } from "@/lib/db";

   const users = await db.user.findMany();
   ```

### If Prisma is Needed After Cloning a Project

```bash
cd /home/z/my-project

# Apply schema
bunx prisma db push

# Generate client
bunx prisma generate
```

---

## 5. Preview Panel

### How Preview Works

1. Dev server starts **automatically** on initialization
2. Preview Panel is located on the **right** side of the interface
3. Updates **automatically** when code changes

### Preview Panel Network Diagram

```text
Browser (chatglm.site / IM)
    |
    +----> Port 81 (sandbox proxy)
              |
              +----> Port 3000 (Next.js dev server)
                        |
                        +----> .zscripts/dev.sh (automatic startup)
```

> **Important:** Preview Panel in Z.ai works through a sandbox proxy on port 81, which forwards requests to the Next.js dev server on port 3000. If the dev server dies, the proxy returns a "sandbox is inactive" error (see section 17).

### If Preview is Not Working

1. **Check logs:**

   ```bash
   cat /home/z/my-project/.zscripts/dev.log | tail -30
   ```

2. **Check linter:**

   ```bash
   bun run lint
   ```

3. **Restart via reinitialization:**
   ```bash
   curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash
   ```

### Other Reasons Preview is Not Working

| Symptom                   | Cause                     | Solution                                             |
| ------------------------- | ------------------------- | ---------------------------------------------------- |
| Page 500                  | Compilation error in code | `cat .zscripts/dev.log \| tail -30` - find the error |
| White screen              | Dev server crashed        | Reinitialize the sandbox                             |
| Preview shows old content | HMR broken                | Reinitialize the sandbox                             |
| Connection refused        | No process on port 3000   | Reinitialize the sandbox                             |
| Module not found          | Forgot `bun add`          | `bun add <package>`                                  |
| "sandbox is inactive"     | Dev server killed on idle | See section 17.1                                     |

### For IM Users

If you use Z.ai through IM (Telegram, etc.), the preview link is:

```text
https://preview-<container-id>.space-z.ai/
```

Where `<container-id>` can be found with:

```bash
echo $FC_CONTAINER_ID
# or
hostname
```

---

## 6. Cloning a Third-Party Project

### Correct Way (Code in Project Root)

```bash
# Step 1: Initialize sandbox (creates Next.js scaffold)
curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash

# Step 2: Clone TEMPORARILY into a separate folder
cd /tmp && git clone https://github.com/user/project.git

# Step 3: Copy project files to the sandbox ROOT
rsync -av --exclude='node_modules' --exclude='.next' \
  /tmp/project/ /home/z/my-project/

# Step 4: Install dependencies in the sandbox ROOT
cd /home/z/my-project && bun install

# Step 5: Reinitialize (restarts dev server)
curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash

# Step 6: Verify
cat /home/z/my-project/.zscripts/dev.log | tail -20
```

### Incorrect Way

```bash
# [FAIL] Do NOT clone directly into a project subfolder
cd /home/z/my-project
git clone https://github.com/user/project.git my-project
cd my-project && npm install && npm run dev  # Will break the sandbox!
```

> **Why it doesn't work:** The sandbox dev server starts in `/home/z/my-project/` and expects the code there. If the code is in a subfolder - the preview shows the default placeholder, not your project.

---

## 7. Dev Server Won't Start

### Symptoms

```bash
cat .zscripts/dev.log | tail -30
# Shows: EADDRINUSE, Connection refused, or just empty
```

### Solution: Full Reinitialization

```bash
# Step 1: Kill everything
pkill -f "next"
pkill -f "node"
pkill -f "bun"

# Step 2: Remove cache
rm -rf /home/z/my-project/.next

# Step 3: Reinitialize
curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash

# Step 4: Wait 10-15 seconds
sleep 15

# Step 5: Verify
cat /home/z/my-project/.zscripts/dev.log | tail -20
```

### If Reinitialization Doesn't Help

```bash
# Check if log file is being written at all
ls -la /home/z/my-project/.zscripts/dev.log
ls -la /home/z/my-project/.zscripts/dev.pid

# If dev.pid exists but server is dead:
kill $(cat /home/z/my-project/.zscripts/dev.pid)
curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash
```

---

## 8. Port 3000 Busy (EADDRINUSE)

### Real Case

```text
Error: listen EADDRINUSE: address already in use :::3000
```

This means: the dev server is already running (possibly manually started in a previous session).

### Solution

```bash
# Step 1: Do NOT start manually! The sandbox will start the server itself.

# Step 2: If a restart is needed:
pkill -f "next dev"
pkill -f "bun run dev"

# Step 3: Reinitialize
curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash
```

> **Important:** In the sandbox NEVER run `npm run dev`, `bun run dev`, `next dev`. The server starts automatically via `.zscripts/dev.sh`.

---

## 9. HMR Crashed - Page Returns 500

### Symptoms

```text
GET / 500 in 942ms (compile: 852ms, render: 90ms)
```

### Cause

You changed/deleted files that Turbopack (HMR) tried to reload. For example:

- Deleted a component that is imported in `page.tsx`
- Renamed a folder
- Added a submodule (deleted and recreated a folder)

### Solution

```bash
# HMR does not recover on its own after file deletion.
# A full restart is needed:

pkill -f "next dev"
rm -rf /home/z/my-project/.next
curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash
sleep 15
cat /home/z/my-project/.zscripts/dev.log | tail -10
# Expected: GET / 200
```

---

## 10. Modules Not Found (Module not found)

### Symptoms

```text
Module not found: Can't resolve '@/lib/guided-tour/src'
```

### Causes and Solutions

| Cause                               | Solution                                                 |
| ----------------------------------- | -------------------------------------------------------- |
| Package not installed               | `cd /home/z/my-project && bun add <package>`             |
| Wrong import path                   | Check path: file must exist at the specified path        |
| Path ends with a file, not a folder | `@/lib/guided-tour` instead of `@/lib/guided-tour/index` |
| Deleted file but import remains     | Update import in `page.tsx`                              |
| Submodule not downloaded            | `git submodule update --init --recursive`                |

### How to Verify

```bash
# Check that the file exists
ls /home/z/my-project/src/lib/guided-tour/index.ts

# Check alias path (should be @/ -> src/)
cat /home/z/my-project/tsconfig.json | grep -A3 "paths"

# Check linter
cd /home/z/my-project && bun run lint
```

---

## 11. Git Submodule

> **Note:** This section covers generic Git submodule usage for user projects. The Z-ai-governance repository itself is a flat repo with no submodules.

### Adding a Submodule

```bash
# Step 1: Prepare the submodule folder
mkdir -p /home/z/my-project/src/lib/guided-tour

# Step 2: Add submodule
cd /home/z/my-project
git submodule add https://github.com/user/GuidedTour.git src/lib/guided-tour

# Step 3: Verify
cat .gitmodules
# Should show:
# [submodule "src/lib/guided-tour"]
#     path = src/lib/guided-tour
#     url = https://github.com/user/GuidedTour.git

ls src/lib/guided-tour/
# Should show component files

# Step 4: Update imports in code
# Was: import { X } from "@/components/ui/guided-tour"
# Now: import { X } from "@/lib/guided-tour"

# Step 5: Reinitialize sandbox (HMR may crash)
curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash
```

### If Submodule Won't Push (Protected Branch)

```bash
# Push to a separate branch, then PR through GitHub UI:
git checkout -b feature/my-changes
git push origin feature/my-changes

# Create PR: https://github.com/user/repo/pull/new/feature/my-changes
```

### Updating a Submodule

```bash
# Quick update
git submodule update --remote src/lib/guided-tour
```

**Full cycle (update + commit):**

```bash
# 1. Pull changes from upstream
git submodule update --remote src/lib/guided-tour

# 2. See what changed
git diff src/lib/guided-tour

# 3. Commit the new version
git add src/lib/guided-tour
git commit -m "chore: update GuidedTour submodule"

# 4. Reinitialize sandbox (if dependencies are needed)
curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash
```

**Check current submodule version:**

```bash
git submodule status src/lib/guided-tour
```

**What's new since last update:**

```bash
cd src/lib/guided-tour && git log --oneline HEAD..origin/main && cd -
```

**Rollback if broken:**

```bash
cd src/lib/guided-tour
git checkout <commit-hash>
cd ..
git add src/lib/guided-tour
git commit -m "chore: pin GuidedTour to <commit-hash>"
```

---

## 12. Common Errors and Solutions

| N   | Error                        | Cause                              | Solution                                     |
| --- | ---------------------------- | ---------------------------------- | -------------------------------------------- |
| 1   | `Module not found`           | Package not installed              | `bun add <package>`                          |
| 2   | `EADDRINUSE`                 | Server already running             | `pkill -f next` + reinitialize               |
| 3   | `GET / 500`                  | Code error                         | Check `.zscripts/dev.log`                    |
| 4   | `GET / 200` but white screen | HMR broken                         | Reinitialize sandbox                         |
| 5   | `Connection refused`         | Server not running                 | Reinitialize sandbox                         |
| 6   | Preview doesn't update       | Dev server crashed                 | `cat .zscripts/dev.log` + reinitialize       |
| 7   | Submodule folder empty       | Forgot `--recurse-submodules`      | `git submodule update --init --recursive`    |
| 8   | TypeScript errors            | Wrong types                        | `bunx tsc --noEmit`                          |
| 9   | Imports not working          | Wrong path                         | Use `@/` alias                               |
| 10  | Turbopack panic              | File deletion while server running | Reinitialize sandbox                         |
| 11  | Cannot find module           | Package not installed              | `cd /home/z/my-project && bun add <package>` |
| 12  | Port 3000 already in use     | Dev server already running         | Do NOT start server manually                 |
| 13  | "sandbox is inactive"        | Dev server killed on idle          | See section 17.1                             |

---

## 13. Useful Commands

### Check Sandbox Status

```bash
# Dev server logs
cat /home/z/my-project/.zscripts/dev.log | tail -30

# Dev server PID
cat /home/z/my-project/.zscripts/dev.pid

# Process PID
cat /home/z/my-project/.zscripts/dev.pid | xargs ps -p
```

### Check Code

```bash
# Linter
cd /home/z/my-project && bun run lint

# TypeScript errors
bunx tsc --noEmit
```

### Database (Prisma)

```bash
cd /home/z/my-project

# Apply schema
bunx prisma db push

# Generate client
bunx prisma generate

# Reset database
bunx prisma migrate reset
```

### Restart Sandbox

```bash
# Standard reinitialization
curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash

# Hard restart (if standard doesn't help)
pkill -f "next dev"
rm -rf /home/z/my-project/.next
curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash
```

### Preview URL

```bash
# Get container ID
echo $FC_CONTAINER_ID
# or
hostname

# Preview URL:
# https://preview-<container-id>.space-z.ai/
```

### Quick Command Reference

```bash
# Initialization
curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash

# Install package
cd /home/z/my-project && bun add <package>

# Check code
bun run lint

# Server logs
cat /home/z/my-project/.zscripts/dev.log | tail -20

# Database (if used)
bun run db:push
```

---

## 14. Pre-Completion Checklist

- [ ] Code in `/home/z/my-project/src/app/page.tsx`
- [ ] Dependencies installed via `bun add`
- [ ] `bun run lint` without errors
- [ ] Server logs without errors: `cat .zscripts/dev.log | tail -20`
- [ ] Preview Panel shows UI

---

## 15. Full Workflow Example

```bash
# 1. Initialize
curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash

# 2. Install needed packages
cd /home/z/my-project && bun add three @react-three/fiber @react-three/drei

# 3. Create components (if needed)
mkdir -p src/components
# ... write components in src/components/

# 4. Write UI in page.tsx
# ... edit src/app/page.tsx

# 5. Verify
bun run lint

# 6. View preview in the right panel
```

---

## 16. Golden Rules

1. **ALWAYS** start with `curl ... init-fullstack ... | bash`
2. **NEVER** start the dev server manually (`npm run dev`, `bun run dev`, `next dev`)
3. **ALL CODE** goes in `/home/z/my-project/` (project root, not subfolders)
4. **LOGS** are always here: `cat /home/z/my-project/.zscripts/dev.log | tail -30`
5. **DEPENDENCIES** are installed via: `cd /home/z/my-project && bun add <package>`
6. **RESTART** = reinitialize: `curl ... init-fullstack ... | bash`
7. **BROKEN** - don't fix manually, reinitialize

**Main rule:**

> Write code in `/home/z/my-project/src/app/page.tsx`, install dependencies via `bun add`, and the preview will appear on the right by itself.

**Don't overcomplicate:**

- Don't create new projects
- Don't start the server manually
- Don't look for external URLs

**Trust the system:**

- Preview Panel works automatically
- Dev server starts itself
- Hot reload works out of the box

---

## 17. Known Infrastructure Issues

This section documents problems that are not code-related, but caused by architectural limitations of the Z.ai sandbox. Knowing these problems will save hours of debugging.

---

### 17.1. Dev Server Dies on Idle (Idle Timeout)

#### Symptoms

- After 2-5 minutes of inactivity in the sandbox, Preview Panel shows an error
- Instead of a preview, you see: **"sandbox is inactive"**
- Or error 502 / Connection refused
- The `.zscripts/dev.log` logs have **NO** crash entries -- the process simply disappears

#### Network Diagram

```text
User's browser (chatglm.site / IM)
    |
    +----> Port 81 (sandbox proxy / gateway)
              |
              +----> Port 3000 (Next.js dev server)
                        |
                        +----> .zscripts/dev.sh (automatic startup)
```

When Next.js on port 3000 dies, the proxy on port 81 cannot forward the request and returns a **"sandbox is inactive"** error.

#### Cause

**Infrastructure limitation of the sandbox, NOT a code problem.**

The sandbox infrastructure kills idle dev servers to save resources. The process disappears:

- Without a crash log
- Without OOM (Out of Memory) error
- Without warning in system logs
- `nohup` doesn't help -- the process is killed at the container/orchestrator level

**The code is absolutely correct.** If the project works on Vercel (as with Filter Log, 258126 accepted), the code is 100% working. The problem is purely infrastructure-related.

#### Solution

**Option 1: Reinitialize (guaranteed method)**

```bash
curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash
```

**Option 2: Wait for automatic restart**

In some configurations, the sandbox automatically restarts the dev server on the next request. Wait 10-30 seconds and refresh the Preview Panel.

**Option 3: Preventive measures**

To avoid idle time during long work sessions:

- Periodically refresh the Preview Panel (every 2-3 minutes)
- Use `watch` or a script that pings the dev server

```bash
# Simple ping script (run in background)
while true; do curl -s http://localhost:3000 > /dev/null; sleep 60; done &
```

#### How to Distinguish Infrastructure from Code Problems

| Indicator                | Infrastructure            | Code Error                  |
| ------------------------ | ------------------------- | --------------------------- |
| Preview Panel error      | "sandbox is inactive"     | 500, 404, compilation error |
| `.zscripts/dev.log` logs | Empty or cut off          | Error with stack trace      |
| Reproducibility          | After 2-5 minutes of idle | After code change           |
| Solution                 | Reinitialize              | Fix the code                |

---

### 17.2. CORS / Cross-Origin Requests Blocked (502)

#### Symptoms

- Preview Panel shows 502 Bad Gateway
- CORS errors in the browser console
- Requests to `localhost:3000` are blocked

#### Cause

Next.js 16 requires explicit permission for cross-domain requests to the dev server via `allowedDevOrigins` in `next.config.ts`. Without this setting, the browser in the sandbox (domain `chatglm.site` or `space-z.ai`) blocks requests to `localhost:3000`.

Network diagram:

```text
Browser (https://preview-xxx.space-z.ai)
    |
    +----> API request (https://preview-xxx.space-z.ai/api/...)
              |
              +----> sandbox proxy (port 81)
                        |
                        +----> Next.js dev server (localhost:3000)
                                  |
                                  +----> blocked without allowedDevOrigins
```

#### Solution

Add `allowedDevOrigins` to `next.config.ts`:

```typescript
// next.config.ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // ... other settings

  // Allows cross-domain requests to the dev server from the sandbox
  // Without this, the browser on chatglm.site blocks requests to localhost:3000
  allowedDevOrigins: ["*"], // Allow all for development

  // Alternative: explicitly specify sandbox domains
  // allowedDevOrigins: [
  //   'https://preview-*.space-z.ai',
  //   'https://*.chatglm.site',
  //   'https://*.z.ai'
  // ],
};

export default nextConfig;
```

> **Important:**
>
> - `["*"]` allows everyone -- **safe only for development** in the sandbox
> - In production, replace with specific domains
> - After changing `next.config.ts`, reinitialization is needed:
>   ```bash
>   curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash
>   ```

#### Verification

After applying the setting:

```bash
# Check that the config was applied
cat /home/z/my-project/next.config.ts | grep -A3 "allowedDevOrigins"

# Reinitialize
curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash

# Check logs
cat /home/z/my-project/.zscripts/dev.log | tail -20
```

---

### 17.3. Comparison: Infrastructure vs Code

| Problem                            | Infrastructure              | Code                |
| ---------------------------------- | --------------------------- | ------------------- |
| Dev server dies on idle            | [OK] Idle timeout           | [FAIL]              |
| "sandbox is inactive" error        | [OK]                        | [FAIL]              |
| CORS 502 without allowedDevOrigins | [OK] Next.js 16 requirement | [FAIL]              |
| HMR crashes after file deletion    | [FAIL]                      | [OK] Turbopack      |
| Module not found                   | [FAIL]                      | [OK]                |
| EADDRINUSE                         | [FAIL]                      | [OK] (manual start) |

---

### 17.4. Quick Checklist for Preview Issues

If Preview Panel is not working, check in this order:

- [ ] Is there a process on port 3000? `lsof -i :3000`
- [ ] Are there errors in the logs? `cat .zscripts/dev.log | tail -30`
- [ ] Was there idle time > 2-5 minutes? -> section 17.1
- [ ] Is `allowedDevOrigins` added to `next.config.ts`? -> section 17.2
- [ ] Does reinitialization help? `curl ... init-fullstack ... | bash`

**Golden rule for infrastructure problems:**

> If the code works on Vercel but doesn't work in the sandbox -- **the problem is in the infrastructure**. Don't waste time debugging code, immediately apply solutions from section 17.

---

Built with: Next.js 16 + TypeScript + Tailwind CSS
