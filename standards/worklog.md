# WORKLOG

## Work Notes for Z-ai-standards

**Format:**
Sections separated by ---

**Content:** specific facts (files, commands, results)

---

## Sessions

### 2026-07-02
**Entry:** Starting work in Z-ai-standards

Initialized Z-ai-standards with worklog.md and CHANGELOG.md files.

**Next steps:** Complete creation of all worklog.md and CHANGELOG.md files for the four Z-ai modules.

---

### 2026-07-02 16:00-22:00
**Entry:** META-002 creation + ESLint tooling + Unicode cleanup + CI fixes

**Work completed:**

1. **Created STD-META-002 (Language Policy v1.0)**
   - New file: `standards/META-002-language-policy.md`
   - Level [C] Critical, 259 lines
   - Covers: documentation language, commit messages, branch names, code, user communication, error messages
   - Added to ARCH-002 at installation position #2 (v2.6 -> v2.7)
   - Cross-references updated in GIT-001, AGENT-001, DOC-002

2. **Set up ESLint tooling**
   - Created `eslint.config.js`, `eslint-rules/unicode-policy.js`, `eslint-rules/raw-text-parser.js`
   - Created `.husky/pre-commit` with lint-staged
   - Updated `package.json` with husky, lint-staged, eslint devDependencies
   - Updated `scripts/check-md.sh` comment: `no-unicode-policy` -> `unicode-policy`

3. **Renamed ESLint rule** `no-unicode-policy` -> `unicode-policy` in all docs and code
   - `standards/DOC-002-eslint-integration.md`
   - `standards/DOC-003-unicode-policy.md`

4. **Bulk Unicode/emoji replacement** (225 replacements, 14 files)
   - `->` (101 arrows), `[OK]` (23 check marks), `[FAIL]` (26 ballot X / cross marks)
   - `<=` (11), `<->` (11), `>=` (2), `!=` (1)
   - Restored DOC-003 Forbidden Patterns table examples (eslint-disabled)
   - Restored DOC-002 violation example (eslint-disabled)
   - Removed unused eslint-disable directives

5. **Fixed 3 CRLF bugs in verifiers**
   - `lib/parsers.js` line 57: `parseYAMLFrontmatter` regex `/^---\n/` -> `/^---\r?\n/`
   - `lib/parsers.js` line 123: `parseBlockquoteHeader` added `.replace(/\r$/, '')` on split
   - `lib/file-scanner.js` line 99: `path.relative()` backslashes normalized to forward slashes

6. **Fixed V10 (README_TEMPLATE badges)**
   - `verify-standards.js` line 506: regex template block extraction added `\r?\n`

7. **Fixed G03 cycle (Related graph)**
   - META-002: removed GIT-001, DOC-002, AGENT-001 from `Related:` field
   - These created bidirectional edges, forming SCC of 5 standards
   - References remain in body text (Section 7), only graph edges removed

8. **Added Known Issues section** to META-002 (section 8A)
   - Documents the G03 cycle fix as META-002-001 [OPEN]

9. **Updated snapshot baseline**: `_snapshots/id-graph-baseline.json`
   - 66 IDs, 129 edges, 0 warnings (was 65 IDs, 125 edges, 0 warnings)

10. **Fixed graph-deps.sh ESM compatibility**
    - Line 110: `.graph-transform.js` -> `.graph-transform.cjs`
    - Platform `package.json` has `"type": "module"`, breaking CommonJS `require()`

**Files modified (summary):**
- `standards/META-002-language-policy.md` (new)
- `standards/ARCH-002-implementation-order.md` (META-002 added)
- `standards/GIT-001-github.md`, `AGENT-001-subagent.md`, `DOC-002-markdown-standard.md` (cross-refs)
- `standards/DOC-002-eslint-integration.md`, `DOC-003-unicode-policy.md` (rule rename)
- `standards/META-001-standard-id-system.md` (Unicode cleanup, 67 replacements)
- `standards/SKILL-001-skill-format.md` (Unicode cleanup, 18 replacements)
- `docs/CI-AND-TESTING.md` (Unicode cleanup, 31 replacements)
- `docs/verify-id-graph-spec-v1.0.md` (Unicode cleanup, 38 replacements)
- `MIGRATIONS.md` (Unicode cleanup, 26 replacements)
- `scripts/verify-standards.js` (V10 CRLF fix)
- `scripts/graph-deps.sh` (ESM fix)
- `scripts/lib/parsers.js` (CRLF fixes)
- `scripts/lib/file-scanner.js` (path separator + SUBMODULE_DIRS)
- `scripts/lib/constants.js` (SUBMODULE_DIRS not needed here)
- `_snapshots/id-graph-baseline.json` (updated)
- `.husky/pre-commit` (new)
- `eslint.config.js`, `eslint-rules/` (new)

**Verification:**
```bash
npx eslint . --max-warnings=0                    # 0 errors, 0 warnings
node scripts/verify-standards.js                 # 8/8 PASS
node scripts/verify-id-graph.js                  # 13/13 PASS, 0 warnings
node scripts/verify-id-graph.js --compare=_snapshots/id-graph-baseline.json  # OK
```text

**Commits this session:**
- `f9c8676` feat: add META-002, rename unicode-policy, add pre-commit hooks
- `5a59299` fix: CRLF line endings breaking ID graph verifier + cycle in Related graph
- `5bd3051` fix: replace Unicode graphics and emoji with ASCII equivalents
- `a44e640` fix: V10 CRLF regex + add Known Issues to META-002
- `0522c42` fix: Windows path separator + YAML frontmatter CRLF
- `f5a5bd4` fix: graph-deps.sh .cjs extension for ESM compatibility

---

### 2026-07-03 01:11
**Entry:** Add lint-markdown workflow (close last consistency gap)

**Context:** Audit found standards was the only repo without CI markdown lint, despite having identical eslint.config.js (unicode-policy for `**/*.md`) as guard/skills. Decision: close gap for completeness ("rules apply to the rule-maker").

**Work completed:**

1. **Synced local `main` to `origin/main`** (was 7 commits behind, detached HEAD)
2. **Restored package.json/package-lock.json** (side-effect of local npm install had added spurious dependency)
3. **Created `.github/workflows/lint-markdown.yml`** (same template as guard/skills, `checkout@v5`)
4. **Committed `3f2bfce`**: `ci: add lint-markdown workflow (STD-DOC-002, STD-DOC-003)`
5. **CI run #28631805161 = GREEN** (13s)

**Verification:**
```bash
npx eslint . --max-warnings=0    # 0 errors, 0 warnings (preventive, no active violations)
```

---
