---
name: zai-skill-creator
id: ZAI-DEVTOOLS-001
author: StsDev
version: 1.0
description: Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, verify skill claims against reality, or optimize a skill's description for better triggering accuracy.
related:
  - STD-SKILL-001
  - STD-META-001

# Skill: Zai Skill Creator v1.0

Create, test, and iterate on opencode skills until they work reliably.

## Mental Model

You are a skill engineer. The user has something they want opencode to do better — maybe a workflow, a domain, a format. Your job is to turn that into a skill: a SKILL.md with optional bundled scripts and references.

The core loop:

1. Understand what the skill should do
2. Draft the skill
3. **Fact-check the draft** (verify claims against reality)
4. Test it on real prompts using subagents
5. Review results with the user
6. Improve based on feedback
7. Repeat until satisfied

Figure out where the user is in this loop and jump in. If they already have a draft, skip to testing. If they say "just help me brainstorm", skip evals entirely.

## When to Use

Activate this skill when the user wants to:

- **Create a new skill from scratch** — "I want to make a skill for X", "build me a skill that does Y"
- **Edit or improve an existing skill** — "fix the skill I made last week", "make this skill trigger more reliably"
- **Run evals on a skill** — "test this skill", "benchmark it", "compare version A vs version B"
- **Optimize a skill's description** — "the skill isn't triggering when I ask for X", "improve its triggering accuracy"
- **Package a skill for distribution** — "zip this up", "give me a `.skill` file I can reuse"
- **Fact-check a skill** — "check if this skill's claims are accurate", "verify the file paths in this skill"

**Do NOT activate if:**

- The user only wants to look up a skill ID or see the list of reserved domains
- The user wants to invoke an existing skill (e.g., "use the mermaid-diagrams skill") — invoke that skill directly
- The user is asking about skill standards as documentation — point them to project standards

## Creating a Skill

### Capture Intent

Start by understanding what the skill should enable. If the conversation already contains a workflow to capture, extract it — tools used, steps taken, corrections made, formats observed. The user fills gaps and confirms.

Key questions:

1. What should this skill enable opencode to do?
2. When should it trigger? (what user phrases/contexts)
3. What's the expected output format?
4. Should we set up test cases? Skills with objectively verifiable outputs benefit from them. Subjective skills (writing style, art) usually don't.

### Interview and Research

Ask about edge cases, input/output formats, example files, success criteria, dependencies. Check available MCPs for research. Come prepared to reduce burden on the user.

### Write the SKILL.md

Components:

- **name**: kebab-case identifier (<=64 chars). MUST start with `zai-` prefix
- **description**: trigger mechanism — what it does AND when to use it. All "when" info goes here, not in the body. Models tend to under-trigger skills, so make descriptions slightly "pushy" with synonyms and related phrases. Keep under 1024 chars.
- **author**: MUST be `StsDev` (hardcoded, all skills in this library)
- **id**: ZAI-XXX-NNN format, optional — only if skill participates in ID graph
- **version**: semantic version (start at v1.0)
- **body**: instructions, structured for progressive disclosure

#### Required Frontmatter

```yaml
---
name: zai-<skill-name>
description: "<what it does and when to trigger>"
author: StsDev
version: 1.0
id: ZAI-XXX-NNN  # optional
---
```

#### Skill Structure

```python
skill-name/
|-- SKILL.md (required)
|   |-- YAML frontmatter (name, description, author, version)
|   -- Markdown instructions
-- Bundled Resources (optional)
    |-- scripts/    - Executable code for deterministic tasks
    |-- references/ - Docs loaded into context as needed
    |-- agents/     - Subagent instruction files
    -- assets/     - Files used in output (templates, fonts)
```

#### Progressive Disclosure

Three-level loading:
1. **Metadata** (name + description) — always in context (~100 words)
2. **SKILL.md body** — loaded when skill triggers (<500 lines ideal)
3. **Bundled resources** — loaded as needed (unlimited)

#### Writing Style

- Imperative form ("run the test" not "the test should be run")
- Explain *why*, not just *what* — models follow instructions better when they understand the reason
- Examples over rules — show good output rather than listing restrictions
- Keep it lean — remove things that aren't pulling their weight
- If approaching 500 lines, add hierarchy with clear pointers to reference files

### Test Cases

After writing the skill draft, come up with 2-3 realistic test prompts. Share them with the user for confirmation. Save to `evals/evals.json`:

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's task prompt",
      "expected_output": "Description of expected result",
      "files": [],
      "expectations": []
    }
  ]
}
```

See `references/schemas.md` for the full schema.

## Fact-Check Phase

**Before running evals, verify the skill's factual claims against reality.**

This is critical. Evals test behavioral compliance and output correctness. They do NOT test whether the skill's own instructions are factually accurate. A skill can pass 100% of evals while containing fabricated file paths, wrong command names, or incorrect explanations of system behavior.

### When to Fact-Check

After writing or editing a SKILL.md, and before launching eval runs. This is a gate — if fact-check finds contradictions, fix them before spending time on evals.

### How to Fact-Check

Spawn a fact-checker subagent that reads `agents/fact-checker.md` and verifies the skill. Pass it:

```python
Skill path: <path-to-skill>
Output path: <workspace>/fact-check.json
```

### What Gets Checked

| Category | Example | Verification Method |
|----------|---------|-------------------|
| File existence | "logs are written to dev.log" | Glob / Read |
| File content | "package.json contains tee" | Grep in the file |
| Path accuracy | "config is at ~/.config/app/" | Glob / LS |
| Command existence | "run `npm run dev`" | Bash `which` / `type` |
| Command behavior | "tee creates the file" | Bash + docs |
| System behavior | "sandbox kills processes" | Read actual init scripts |
| Dependency existence | "uses pypdf" | Bash `pip show` |
| Structural claims | "script is at scripts/run.py" | Glob within skill |

### Handling Results

- **contradicted claims**: fix before evals. These are bugs.
- **unverifiable claims**: flag to user, consider rewording to be explicit about assumptions
- **confirmed claims**: no action needed

## Running and Evaluating Test Cases

Continuous sequence — don't stop partway.

Put results in `<skill-name>-workspace/` as sibling to skill directory. Organize by iteration (`iteration-1/`, `iteration-2/`), within that by test case (`eval-0/`, `eval-1/`). Create directories as you go.

### Step 1: Spawn All Runs

For each test case, spawn two subagents in the same turn — one with skill, one without. Launch everything at once using the `task` tool.

**With-skill run:**
```python
Execute this task:
- Skill path: <path-to-skill>
- Task: <eval prompt>
- Input files: <eval files if any, or "none">
- Save outputs to: <workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/
- Outputs to save: <what the user cares about>
```

**Baseline run:**
- New skill: no skill at all. Same prompt, save to `without_skill/outputs/`.
- Improving existing: snapshot first (`cp -r <skill> <workspace>/skill-snapshot/`), point baseline at snapshot, save to `old_skill/outputs/`.

Write `eval_metadata.json` for each test case. Give each eval a descriptive name.

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name",
  "prompt": "The user's task prompt",
  "assertions": []
}
```

### Step 2: Draft Assertions While Runs Execute

Don't wait — draft quantitative assertions now. Good assertions are objectively verifiable and have descriptive names. Subjective skills are better evaluated qualitatively.

For assertions that can be checked programmatically, write and run a script — faster, more reliable, reusable.

### Step 3: Capture Timing Data

When each subagent completes, save `total_tokens` and `duration_ms` to `timing.json` in the run directory. This is the only opportunity — it comes through the task notification.

### Step 4: Grade, Aggregate, Launch Viewer

Once all runs complete:

1. **Grade each run** — spawn grader subagent (read `agents/grader.md`) or grade inline. Save to `grading.json`. The expectations array must use fields `text`, `passed`, `evidence`.

2. **Aggregate into benchmark:**
   ```bash
   python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
   ```
   Produces `benchmark.json` and `benchmark.md`. Put with_skill before baseline.

3. **Analyst pass** — read benchmark data, surface patterns. See `agents/analyzer.md` ("Analyzing Benchmark Results" section).

4. **Launch the viewer:**
   ```bash
   python <skill-lab-path>/eval-viewer/generate_review.py \
     <workspace>/iteration-N \
     --skill-name "my-skill" \
     --benchmark <workspace>/iteration-N/benchmark.json
   ```
   For iteration 2+, add `--previous-workspace <workspace>/iteration-<N-1>`.

   For headless environments: use `--static <output_path>` for a standalone HTML file.

5. **Tell the user** what they'll see in the viewer and wait for feedback.

### Step 5: Read Feedback

When done, read `feedback.json`. Empty feedback = user thought it was fine. Focus improvements on specific complaints.

## Improving the Skill

### How to Think About Improvements

1. **Generalize from feedback.** The skill needs to work across many prompts, not just the test cases. Avoid fiddly overfitting or rigid MUSTs. Try different metaphors and patterns.
2. **Keep it lean.** Read transcripts — if the model wastes time on unproductive steps from the skill, remove those parts.
3. **Explain the why.** If you're writing ALWAYS/NEVER in caps, that's a yellow flag — reframe with reasoning.
4. **Extract repeated work.** If all test cases independently wrote similar helper scripts, bundle one in `scripts/`.

### The Iteration Loop

1. Apply improvements
2. **Re-run fact-check** on the updated skill (new claims may have been introduced)
3. Re-run all test cases into `iteration-<N+1>/`
4. Launch reviewer with `--previous-workspace`
5. Wait for user review
6. Read feedback, improve, repeat

Stop when: user says they're happy, feedback is all empty, or no meaningful progress.

## Description Optimization

After the skill content is finalized, optimize the description field for triggering accuracy.

### Step 1: Generate Trigger Evals

Use the helper script to generate a starter eval set:

```bash
python scripts/generate_trigger_evals.py <path/to/skill> --output trigger_evals.json
```

This produces a template with 10 placeholder queries. To generate 20 realistic queries automatically, use:

```bash
python scripts/generate_trigger_evals.py <path/to/skill> --prompt-only > prompt.txt
```

Copy the prompt into opencode — it will generate 20 realistic eval queries based on the skill's content.

Requirements for queries:
- Mix of should-trigger (8-10) and should-not-trigger (8-10)
- Realistic — concrete, specific, with file paths, context, casual speech, typos
- Focus on edge cases, not clear-cut matches
- Negative cases should be near-misses (share keywords but need something different), not obviously irrelevant

### Step 2: Review the Eval Set

Open `assets/eval_review.html` in a browser to review and edit the eval set:

1. Replace the `__EVAL_DATA_PLACEHOLDER__` in the HTML with your JSON array
2. Open the file in a browser
3. Edit queries, toggle should-trigger, add or remove entries
4. Click "Export Eval Set" to download the final JSON

Bad evals lead to bad descriptions — this review step is essential.

### Step 3: Automated Trigger Testing

Use `scripts/run_eval.py` for automated trigger testing via `z-ai chat`:

```bash
python scripts/run_eval.py <path/to/skill> --evals trigger_evals.json
```

Outputs JSON results with trigger/no-trigger for each query.

### Step 4: Iterative Description Improvement

Use the eval-improve loop for automated description optimization:

```bash
python scripts/run_loop.py <path/to/skill> --evals trigger_evals.json --max-iterations 10
```

This runs eval + improve cycles automatically, with train/test split to prevent overfitting. Generates an HTML report after each iteration.

Or improve a single round manually:

```bash
python scripts/improve_description.py <path/to/skill> --evals results.json
```

### Step 5: Analyze and Improve

For detailed analysis of trigger results:

```bash
python scripts/analyze_trigger_results.py results.json --skill-path <path/to/skill> --output report.html
```

This produces an HTML report with:
- Precision, recall, accuracy, F1 metrics
- Categorized failures (failed to trigger vs false triggers)
- Common words in failure queries
- Actionable recommendations for improving the description

Apply the recommendations, update the SKILL.md frontmatter, and repeat until metrics are satisfactory.

### Step 6: Apply Result

Update SKILL.md frontmatter with the best-performing description. Show before/after and report the final metrics.

## Advanced: Blind Comparison

For rigorous version comparison. Read `agents/comparator.md` and `agents/analyzer.md`. Optional, requires subagents.

## Environment-Specific Notes

### opencode with GLM models
- Ensure `opencode.json` declares the GLM provider correctly:
  ```json
  {
    "model": "glm/glm-4-plus",
    "provider": {
      "glm": { "options": { "apiKey": "..." } }
    }
  }
  ```
- Subagents work via the `task` tool. Spawn eval runs in parallel when possible.
- The viewer (`eval-viewer/generate_review.py`) works in any environment with Python.

### No subagents (single-agent mode)
- Run test cases yourself, one at a time. Skip baselines.
- Present results inline instead of viewer. Skip quantitative benchmarking.
- Skip description optimization loop. Skip blind comparison.

### Headless / remote environments
- Full workflow works. Use `--static` for viewer.
- **Always generate the eval viewer before evaluating inputs yourself.** Get them in front of the human ASAP.

### Updating Existing Skills
- Preserve the original name and directory name.
- Copy to writeable location before editing (`/tmp/skill-name/` or local workspace).

## Standards Compliance

All created skills MUST comply with Z.ai documentation standards:

### DOC-002: Markdown Standard (STD-DOC-002 v2.4)

Skills that produce or process Markdown files must follow the Markdown Standard. Key requirements:
- Proper heading hierarchy (H1 > H2 > H3, no level skipping)
- Consistent list formatting (ordered for sequences, unordered for collections)
- Table formatting with aligned columns
- No raw HTML in Markdown unless explicitly required
- Line length and paragraph spacing rules

Full standard: see `references/DOC-002-markdown-standard.md`

### DOC-003: No-Unicode Policy (STD-DOC-003 v2.3)

Skills that generate text content must follow the No-Unicode Policy. Key requirements:
- No decorative Unicode characters (box-drawing, block elements, emoji)
- No Unicode math operators (superscripts, subscripts) in plain text
- Use ASCII alternatives: `->` not `->`, `!=` not `=`, `---` not `---`
- Latin/CJK/base symbols only
- Exception: Unicode is allowed in code blocks, file paths, and verbatim content

Full policy: see `references/DOC-003-unicode-policy.md`

### Compliance Checklist (applied to every new skill)

When writing a new skill, verify:
- [ ] SKILL.md uses proper Markdown heading hierarchy
- [ ] No decorative Unicode in instructions
- [ ] Description field contains only ASCII-safe characters
- [ ] All example code and file paths are real/verifiable (fact-checked)
- [ ] Skill name is kebab-case, <=64 chars
- [ ] Description is <=1024 chars with trigger phrases

## Packaging

```bash
python -m scripts.package_skill <path/to/skill-folder>
```

## Reference Files

### Agents
- `agents/grader.md` — evaluate assertions against outputs (includes fact-check cross-check)
- `agents/fact-checker.md` — verify skill claims against reality
- `agents/comparator.md` — blind A/B comparison
- `agents/analyzer.md` — post-hoc analysis and benchmark analysis

### Scripts
- `scripts/generate_trigger_evals.py` — generate starter trigger eval set
- `scripts/analyze_trigger_results.py` — analyze trigger results and recommend description improvements
- `scripts/run_eval.py` — automated trigger testing via `z-ai chat`
- `scripts/improve_description.py` — single-round description improvement via LLM
- `scripts/run_loop.py` — iterative eval+improve loop with train/test split
- `scripts/generate_report.py` — HTML report generation from loop output
- `scripts/quick_validate.py` — quick validation of skill structure
- `scripts/aggregate_benchmark.py` — aggregate eval results into benchmark
- `scripts/package_skill.py` — package skill for distribution
- `scripts/utils.py` — shared utilities

### References
- `references/schemas.md` — JSON structures for evals, grading, benchmarks, fact-check, trigger results
- `references/id-assignment-guide.md` — ZAI-ID assignment rules and reserved domains
- `references/DOC-002-markdown-standard.md` — Z.ai Markdown Standard (STD-DOC-002 v2.4)
- `references/DOC-003-unicode-policy.md` — Z.ai No-Unicode Policy (STD-DOC-003 v2.3)

### Assets
- `assets/eval_review.html` — interactive editor for trigger eval sets
- `eval-viewer/generate_review.py` — generate eval review HTML viewer
- `eval-viewer/viewer.html` — eval review viewer template
