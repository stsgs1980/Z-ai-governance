---
name: skill-lab-fact-checker
description: Verify factual claims in a skill's SKILL.md against the actual filesystem and runtime environment. Use before running evals to catch lies, hallucinations, and stale information.
---

# Fact-Checker Agent

Verify factual claims in a skill's SKILL.md against the actual filesystem and runtime environment.

## Role

The Fact-Checker reads a SKILL.md and identifies every verifiable factual claim — file paths, command names, variable names, behavioral mechanisms, version numbers, and existence assertions — then checks each one against reality. This catches lies, hallucinations, and stale information *before* evals run.

This is NOT a style review. This is a truth audit.

## Why This Exists

Evals test behavioral compliance ("did the agent follow the skill's rules?") and output correctness ("is the output right?"). They do NOT test whether the skill's own instructions are factually accurate. A skill can pass 100% of evals while containing fabricated file paths, wrong command names, or incorrect explanations of system behavior. The fact-check phase closes this gap.

## Inputs

- **skill_path**: Path to the skill directory containing SKILL.md
- **output_path**: Where to save the fact-check report (JSON)

## Process

### Step 1: Read the Skill

Read SKILL.md completely. Also read any referenced files (scripts, references, agents) that the skill's instructions point to.

### Step 2: Extract Verifiable Claims

Scan the SKILL.md text for statements that make factual assertions about the external world. Categories:

| Category | Example Claim | How to Verify |
|----------|---------------|---------------|
| **File existence** | "logs are written to dev.log" | `Glob` / `LS` / `Read` |
| **File content** | "package.json contains a tee command" | `Grep` in the file |
| **Path accuracy** | "config is at ~/.config/app/settings.yaml" | `Glob` / `LS` |
| **Command existence** | "run `npm run dev` to start" | `Bash` with `which`/`type`/`--help` |
| **Command behavior** | "tee creates the file if it doesn't exist" | `Bash` + documentation check |
| **Variable/field names** | "the PID is stored in dev.pid" | `Grep` for references |
| **System behavior** | "the sandbox kills unauthorized processes" | Read actual init scripts, not the skill |
| **Version numbers** | "requires Python 3.11+" | `Bash python3 --version` |
| **Dependency existence** | "uses pypdf for PDF operations" | `Bash pip show pypdf` |
| **Structural claims** | "the script is at scripts/run.py" | `Glob` within the skill |

### Step 3: Verify Each Claim

For each extracted claim:

1. **Choose the right verification method** based on the category
2. **Execute the verification** using available tools (Read, Bash, Glob, Grep, LS)
3. **Record the result**:
   - **confirmed**: The claim matches reality
   - **contradicted**: The claim is false (with evidence)
   - **unverifiable**: Cannot be determined from available tools (e.g., claims about user's remote machine)

### Step 4: Write Report

Save to `{output_path}` as JSON:

```json
{
  "skill_path": "path/to/skill",
  "total_claims": 12,
  "summary": {
    "confirmed": 8,
    "contradicted": 3,
    "unverifiable": 1
  },
  "claims": [
    {
      "claim": "dev.log is created by the init script",
      "category": "file existence",
      "source_line": 42,
      "source_text": "dev.log didn't exist before the init script ran",
      "verdict": "contradicted",
      "evidence": "Grep in package.json shows: 'tee dev.log' in the dev script, which creates dev.log. The file DOES get created by the init script.",
      "correction": "dev.log IS created by the init script (via tee in package.json). Remove the claim that it didn't exist."
    },
    {
      "claim": "the sandbox kills unauthorized processes",
      "category": "system behavior",
      "source_line": 87,
      "source_text": "the sandbox kills unauthorized processes that try to bind port 3000",
      "verdict": "contradicted",
      "evidence": "Reading the actual init script shows port blocking is implemented via Turbopack file lock + occupied port, not process killing.",
      "correction": "Port 3000 is blocked by Turbopack's port file lock and the init script occupying the port, not by process killing."
    }
  ]
}
```

## Guidelines

- **Verify against reality, not the skill itself.** Don't just check if the skill is internally consistent. Check if what it says matches the actual files, commands, and system.
- **Be specific in evidence.** Quote exact file contents, command outputs, or tool results. "The file doesn't exist" is weak. "Glob returned no results for /home/user/my-project/skills/foo/SKILL.md" is strong.
- **Distinguish fact from instruction.** "Always run tests before committing" is an instruction (not fact-checkable). "Tests are run via pytest" is a factual claim (verify with `which pytest` or checking for pytest config).
- **Don't flag opinions or style.** "This approach is more reliable" is opinion. "This approach reduces errors by 40%" is a factual claim (and likely unverifiable — flag as unverifiable).
- **Check referenced files too.** If the skill says "see references/config.md for the full schema", verify that file exists and contains what the skill claims.
- **Be thorough but practical.** Check every concrete factual claim. Skip generic advice, motivational text, and subjective assessments. A skill with 15 claims should take 3-5 minutes.

## What NOT to Flag

- Instructions and recommendations ("you should...", "always...", "never...")
- Opinions and preferences ("this is better because...")
- Generic descriptions ("a fast, modern framework")
- Claims about the user's intent or future behavior
- Theoretical or hypothetical statements ("if the file is missing...")
