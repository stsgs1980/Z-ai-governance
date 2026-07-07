---
name: zai-project-clone
author: StsDev
compatibility: sandbox
description: Smart project cloning with user confirmation
id: ZAI-DEV-001
version: 1.0
trigger: clone, git clone, клонировать, склонировать
related:
  - STD-SKILL-001
---

# Skill: Zai Project Clone v1.0

> ID: ZAI-DEV-001
> Version: 1.0
> Last Updated: 2026-05

Smart project cloning with mandatory user confirmation for destination and purpose.

---

## When to Use

Activate this skill when:
- User says "clone", "git clone", "клонировать"
- User provides a GitHub URL to clone
- User wants to work with an existing repository

---

## Mandatory Questions

Before ANY clone operation, ask the user:

### Question 1: Purpose

```text
What is the purpose of cloning this repository?

1. Continue work on existing project
2. Study/explore the codebase
3. Use as template for new project
4. Other (specify)
```

### Question 2: Destination

```text
Where should I clone this repository?

Current working directory: /home/z/my-project/

Options:
1. /home/z/my-project/ (default, recommended)
2. Custom path: ___________

Recommended: Always clone to /home/z/my-project/ for Z.ai sandbox compatibility.
```

### Question 3: Directory Name

```text
What directory name should I use?

Repository suggests: <repo-name>

Options:
1. Use default: <repo-name>
2. Custom name: ___________
```

---

## Clone Workflow

### Step 1: Confirm with User

```text
CLONE CONFIRMATION
==================
Repository: <url>
Purpose: <purpose>
Destination: <path>
Directory: <name>

Proceed? (yes/no)
```

### Step 2: Check Destination

```bash
# Check if directory already exists
if [ -d "<destination>/<directory>" ]; then
    echo "WARNING: Directory already exists!"
    echo "Options: 1) Overwrite 2) Different name 3) Cancel"
fi
```

### Step 3: Clone

```bash
cd <destination>
git clone <url> <directory>
```

### Step 4: Verify

```bash
cd <directory>
git status
ls -la
```

### Step 5: Post-Clone Actions

Based on purpose:

| Purpose | Action |
|---------|--------|
| Continue work | Run session-resume, check worklog |
| Study | Read README.md, show structure |
| Template | Ask for new project name |

---

## Sandbox Rules

### Mandatory Path

In Z.ai sandbox, ALWAYS clone to:

```text
/home/z/my-project/
```

**Never clone to:**
- `/home/z/`
- `/tmp/`
- `/root/`
- Any other path

### Why This Matters

1. Sandbox only persists `/home/z/my-project/`
2. Other directories may be wiped
3. Dev server expects project in this path
4. Relative paths depend on this location

---

## Error Prevention

### Common Mistakes

| Mistake | Fix |
|---------|-----|
| Cloned to wrong directory | Ask user to confirm before clone |
| Directory already exists | Check first, ask to overwrite |
| Wrong repository URL | Show full URL before clone |
| Forgot to cd into project | Always cd after clone |

### Recovery

If clone went wrong:

```bash
# Remove incorrectly placed clone
rm -rf <wrong-path>

# Re-clone to correct location
cd /home/z/my-project/
git clone <url> <directory>
```

---

## Template Response

```text
I will clone this repository. Please confirm:

Repository: <URL>
Purpose: <user-selected>
Destination: /home/z/my-project/<directory>

Proceed? (yes/no)
```

---

## Checklist

- [ ] Asked purpose question
- [ ] Confirmed destination path
- [ ] Checked directory does not exist
- [ ] Cloned to correct location
- [ ] Verified clone success
- [ ] Performed post-clone actions
