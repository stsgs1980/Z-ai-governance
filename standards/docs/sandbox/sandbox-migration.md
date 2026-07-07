# Sandbox Migration Guide v2.0

> **Universal instruction for sandbox migration**
>
> Complete guide for transferring a project to a new AI-sandbox
>
> Version 2.0 — May 2026
>
> Stack: Next.js / GitHub / Vercel
>
> stsgs1980 v2.0

## 1. Analysis of the Original Instruction

The original migration instruction contained several critical errors that could lead to data loss, broken installation, or authentication errors. Below is a detailed analysis of each identified problem and recommendations for fixing them. All corrections have been incorporated into the universal instruction in Section 2.

### Detected Problems

| No. | Problem | Risk | Description |
|-----|---------|------|-------------|
| 1 | `rm -rf` without check | HIGH | Command `rm -rf /home/z/my-project` executed without checking if directory exists. A typo in the path could delete system files. Fix: conditional check `if [ -d ... ]` before deletion. |
| 2 | No clone verification | HIGH | If `git clone` fails (expired token, network error), subsequent commands execute in an empty directory and produce misleading errors. Fix: check `.git` existence after cloning. |
| 3 | Token exposed in URL | MEDIUM | Token embedded in URL may leak when forwarded or screenshotted. Fix: token via environment variable `export GH_TOKEN=...` |
| 4 | No Node.js check | MEDIUM | Installing dependencies without checking Node.js version may cause confusing errors. Fix: `node --version` before `npm install`. |
| 5 | `npm install` without flags | LOW | Newer npm versions (v7+) strictly check peer dependencies - this causes ERESOLVE. Flag `--legacy-peer-deps` resolves the issue. |
| 6 | No build verification | MEDIUM | Without `npm run build`, broken imports or missing dependencies are detected only later. Fix: `npm run build` after installation. |
| 7 | Incorrect worklog format | LOW | Format "Say AI:" doesn't work as a reliable command. Fix: direct command `cat > worklog.md << 'EOF'`. |

---

## 2. Universal Instruction for AI

Copy the text below and send it to AI as a single message. Do not split into parts — AI must receive the full context at once. Before sending, replace `YOUR_GITHUB_TOKEN` with the actual token.

### Step 1. Safe Cleanup

Before cloning, check if the directory exists and delete it only if it exists. This prevents accidental deletion of other files due to a typo.

```bash
# 1. Safe cleanup: delete only if directory exists
if [ -d "/home/z/my-project" ]; then
  echo "Directory exists. Deleting..."
  rm -rf /home/z/my-project
else
  echo "Directory not found. Skipping deletion."
fi
```

### Step 2. Clone Repository

Clone the repository with a token via environment variable. This is safer than embedding the token directly in the URL. After cloning, verify that `.git` was created.

```bash
# 2. Clone repository (replace YOUR_GITHUB_TOKEN)
export GH_TOKEN="YOUR_GITHUB_TOKEN"
git clone https://x-access-token:${GH_TOKEN}@github.com/stsgs1980/stanislav-graur.git /home/z/my-project

# 3. Verify clone success
if [ -d "/home/z/my-project/.git" ]; then
  echo "Clone successful."
else
  echo "ERROR: Clone failed. Check token and URL."
  exit 1
fi
```

> **CRITICAL:** If cloning fails — DO NOT continue.
> Check that the token has not expired and has `repo` permission.
> Create a new token: https://github.com/settings/tokens

### Step 3. Install Dependencies

Navigate to the project directory, check Node.js version, and install dependencies. The `--legacy-peer-deps` flag prevents peer dependency conflicts that often occur in newer npm versions.

```bash
# 4. Navigate and check Node.js version
cd /home/z/my-project
node --version  # Verify installed version
npm --version

# 5. Install dependencies
npm install --legacy-peer-deps
```

### Step 4. Configure Git

Set Git user data for correct commit attribution. Email must match the GitHub account to link commits to the profile.

```bash
# 6. Configure Git
git config user.email "stsgs1980@gmail.com"
git config user.name "stsgs1980"
```

### Step 5. Verify Build

Run the build to check that the project compiles without errors. This detects broken imports, missing packages, and TypeScript errors before starting work.

```bash
# 7. Verify build
npm run build
```

### Step 6. Restore Worklog

If you have a saved copy of worklog from the previous sandbox — paste its content. If not — create an empty file using the template below. Worklog tracks all work between sessions and is critical for continuity.

```bash
# 8. Restore worklog (paste saved content or use template)
cat > /home/z/my-project/worklog.md << 'EOF'
# Worklog

---

Task ID: 1
Agent: main
Task: Migration to new sandbox
Work Log:
- Cloned repository from GitHub
- Installed npm dependencies
- Configured Git user
- Verified build
Stage Summary:
- Project successfully deployed in new sandbox
EOF
```

---

## 3. Full Command (One Copy-Paste)

All steps combined into one block. Copy it entirely and send to AI. Replace `YOUR_GITHUB_TOKEN` with the actual token before sending.

```bash
if [ -d /home/z/my-project ]; then rm -rf /home/z/my-project; fi

git clone https://x-access-token:YOUR_GITHUB_TOKEN@github.com/stsgs1980/stanislav-graur.git /home/z/my-project \
  && cd /home/z/my-project \
  && npm install --legacy-peer-deps \
  && git config user.email "stsgs1980@gmail.com" \
  && git config user.name "stsgs1980" \
  && echo 'Setup complete. Project ready.'

# Then verify build:
cd /home/z/my-project && npm run build

# Then restore worklog (paste saved content).
```

> Replace `YOUR_GITHUB_TOKEN` with the actual token before sending.
> After pasting worklog, verify: `cat /home/z/my-project/worklog.md`

---

## 4. Migration Checklist

Follow this checklist for every migration between sandboxes. It is divided into two parts: actions before closing the old sandbox and actions after opening the new one.

### Old Sandbox (Before Closing)

- [OK] `git push` — all changes pushed to GitHub (`git add . && git commit -m 'save' && git push`)
- [OK] `worklog.md` — content copied to a safe location (notepad, email, etc.)
- [OK] `download/` — required files downloaded from `/home/z/my-project/download/`
- [OK] Vercel — site works in production
- [OK] `.env` — environment variable values recorded

### New Sandbox (After Opening)

- [TODO] Cloning — full command from Section 3 executed
- [TODO] Clone verification — `/home/z/my-project/.git` exists
- [TODO] `npm install` — dependencies installed without errors
- [TODO] Git config — `user.email` and `user.name` set
- [TODO] Build — `npm run build` completed successfully
- [TODO] Worklog — `/home/z/my-project/worklog.md` created with saved content
- [TODO] Dev-server — `npm run dev` starts without errors

---

## 5. Common Errors and Solutions

Below are the most frequent errors that occur during migration. For each, the cause and step-by-step solution are provided.

| Error | Cause | Solution |
|-------|-------|----------|
| `fatal: Authentication failed` | Token expired or missing `repo` permissions | Create a new token at https://github.com/settings/tokens with `repo` permission (full access to private repositories). Replace token in clone command. |
| `npm ERR! code ERESOLVE` | Peer dependency conflict. Common in npm v7+. | Delete `node_modules` and `package-lock.json`, then `npm install --legacy-peer-deps`. If error persists - verify that a package without compatible peer dependencies was added. |
| `npm ERR! network / timeout` | Network issue or npm registry unavailable. | Retry after a few seconds. If that doesn't help, try mirror: `npm install --registry https://registry.npmmirror.com`. |
| `next build: import error` | Package removed from `package.json` but still imported. | Find the package name in the error and run `npm install <package-name>`. Or remove the import if the package is no longer needed. |
| Vercel fails to deploy | Project not linked to repository, or incorrect email in `git config`. | Verify: (a) project on Vercel under account `stsgs1980`, (b) `git config user.email` matches GitHub, (c) repository connected in Vercel: Settings > Git. |
| `Permission denied (git push)` | Token without `repo` scope or from a different account. | Recreate token with `repo` scope. Ensure token belongs to account `stsgs1980`. |
| `Port 3000 already in use` | Previous dev-server still running. | Kill the process: `lsof -ti:3000 | xargs kill -9`, then `npm run dev`. Or use a different port: `PORT=3001 npm run dev`. |

---

## 6. Critical Rules

These rules must be followed without exception. Violating any of them will result in a broken project, lost work, or deployment errors. Based on the most common AI-agent mistakes.

```text
DO NOT clone into /home/z/stanislav-graur - the project must be in /home/z/my-project

DO NOT copy files manually - everything is already in the repository

DO NOT create cron jobs - the sandbox handles this automatically

DO NOT modify page.tsx, layout.tsx, or other files unless explicitly requested

DO NOT run 'Set up project' - the project is already configured in the repository

DO NOT run npm install without --legacy-peer-deps - this causes ERESOLVE

DO NOT skip build verification - a broken build will be discovered later

DO NOT use rm -rf without directory verification

DO NOT share this instruction with an actual token - use YOUR_GITHUB_TOKEN
```

If an AI-agent attempts to execute any of the above — immediately stop it and direct it to the correct procedure. AI must execute only the commands from Sections 2 and 3, without improvising additional steps.

---

Built with: Next.js 16 + TypeScript + Tailwind CSS
