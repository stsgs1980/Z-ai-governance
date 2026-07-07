# ESLint Integration for Markdown Linting — Companion to STD-DOC-002

> Companion to: STD-DOC-002 v2.4.3 (Markdown Formatting Standard)
> Type: Reference appendix, NOT a separate standard
> Last Updated: 2026-07-07
> Status: ACTIVE (reference implementation)
>
> NOTE: In the current repository (Z-ai-governance), ESLint rules live
> ONLY in the root `eslint-rules/` directory. The `guard/eslint-rules/`
> and `standards/eslint-rules/` directories (referenced in some sections
> below) were removed as dead code -- they were never called by lint-staged
> or any other mechanism.

This file is a **companion reference** to `DOC-002-markdown-standard.md`
(STD-DOC-002 v2.4.3). It contains the full ESLint integration guide
(§10 of the parent standard) — concrete configuration, dependency setup,
rule mappings, and example workflows.

**This file is NOT a separate standard.** It does not have an `STD-` ID of
its own and does not participate in the ID graph. It is referenced from
STD-DOC-002 §10 as the canonical ESLint setup guide.

## Why this file exists

In STD-DOC-002 v2.4.2, the ESLint Integration section (§10, 354 lines)
lived inline in the main standard file. Combined with the normative
content (§0-§9, §11-§15), the file exceeded the 1000-line soft cap (W11
warning from `verify-id-graph.js`). In v2.4.3, §10 was moved to this
companion file to bring STD-DOC-002 under the soft cap while preserving
all section numbers and content verbatim.

## How cross-references resolve

External references to "STD-DOC-002 §10" or any of its sub-sections
(§10.1 through §10.7) resolve to this companion file. The section
numbers are preserved verbatim (no renumbering) to keep all existing
references stable.

---

## 10. ESLint Integration for Markdown Linting

This section describes how to configure ESLint to automatically enforce the rules defined in this standard and the nested **Unicode Policy (STD-DOC-003)**. ESLint acts as the automated enforcement layer for the rules that are otherwise checked manually in code review.

### 10.1. Why ESLint for Markdown?

Manual code review is insufficient for consistent enforcement of formatting and character policies across large projects. ESLint provides:

- **Immediate feedback** in the editor (red squiggles, error popups)
- **Pre-commit hooks** that catch violations before they enter the repository
- **CI/CD pipeline enforcement** that generates reports on every push
- **Uniform severity** — rules from STD-DOC-003 ([C] Critical) apply equally to source code and documentation. Same rule = same severity. No downgrade for .md files.

The key principle: **ESLint is the automated executor of the standards, not a replacement for them.** The standards documents remain the single source of truth; ESLint configuration is derived from them.

### 10.2. Required Dependencies

```bash
# Core ESLint (if not already installed)
npm install --save-dev eslint

# Markdown processor — lets ESLint parse .md files
npm install --save-dev eslint-plugin-markdown

# Custom rule for Unicode Policy enforcement (see STD-DOC-003 section 10.1)
# This file lives in your project at: eslint-rules/unicode-policy.js
```text

**Dependency chain:**

```text
eslint
  └── eslint-plugin-markdown       (parses .md into virtual JS AST)
       └── unicode-policy.js    (custom rule from STD-DOC-003)
```

### 10.3. ESLint Configuration (Flat Config — eslint.config.js)

ESLint 9+ uses the flat config format. The configuration below maps this standard's rules to ESLint warnings and STD-DOC-003 rules to ESLint errors.

```javascript
// eslint.config.js
import markdown from "eslint-plugin-markdown";
import unicodePolicy from "./eslint-rules/unicode-policy.js";

export default [
  // --- Global ignores ---
  {
    ignores: [
      "node_modules/**",
      ".next/**",
      "dist/**",
      "build/**",
      "coverage/**",
    ],
  },

  // --- Markdown files (.md) ---
  // eslint-plugin-markdown extracts code blocks from .md files
  // and presents them as virtual JS/TS files for linting.
  ...markdown.configs.recommended,

  {
    files: ["**/*.md/**"],          // virtual files inside .md code blocks
    rules: {
      // STD-DOC-002: Code blocks must specify a language
      // (enforced via custom rule — see section 10.5)
      "markdown/code-block-language": "warn",

      // STD-DOC-003: No emoji/Unicode graphics in code blocks
      "unicode-policy/emoji": "error",
      "unicode-policy/no-unicode-graphics": "error",

      // General quality rules for code inside .md blocks
      "no-undef": "off",            // code snippets in docs may be incomplete
      "no-unused-vars": "off",      // examples don't need every variable used
      "no-console": "off",          // examples often show console usage
    },
  },

  {
    files: ["**/*.md"],             // the .md files themselves (not code blocks)
    plugins: {
      "unicode-policy": unicodePolicy,
    },
    rules: {
      // STD-DOC-003 section 4: No emoji in Markdown documentation
      // Severity: error ([C] Critical) — same rule, same severity as source code.
      // To soften enforcement for a legacy project migration, override in the
      // project's local eslint.config.js to "warn" with a documented cutover date.
      "unicode-policy/emoji-in-md": "error",

      // STD-DOC-003 section 4: No Unicode icons in Markdown documentation
      "unicode-policy/no-unicode-graphics-in-md": "error",
    },
  },

  // --- Source code files (.ts, .tsx, .js, .jsx) ---
  {
    files: ["**/*.{ts,tsx,js,jsx}"],
    plugins: {
      "unicode-policy": unicodePolicy,
    },
    rules: {
      // STD-DOC-003 [C] Critical: No emoji in production code / UI strings
      "unicode-policy/emoji": "error",

      // STD-DOC-003 [C] Critical: No Unicode graphics in production code
      "unicode-policy/no-unicode-graphics": "error",

      // STD-DOC-002 indirectly: no irregular whitespace (NBSP, ZWSP, etc.)
      "no-irregular-whitespace": "error",
    },
  },
];
```None

### 10.4. ESLint Configuration (Legacy — .eslintrc.js)

For projects still using the legacy config format:

```javascript
// .eslintrc.js
module.exports = {
  plugins: ["markdown"],

  overrides: [
    {
      // Code blocks inside .md files
      files: ["**/*.md/**"],
      rules: {
        "unicode-policy/emoji": "error",
        "unicode-policy/no-unicode-graphics": "error",
        "no-undef": "off",
        "no-unused-vars": "off",
        "no-console": "off",
      },
    },
    {
      // .md files themselves
      files: ["**/*.md"],
      rules: {
        // [C] Critical — same rule, same severity as source code (see §10.6)
        "unicode-policy/emoji-in-md": "error",
        "unicode-policy/no-unicode-graphics-in-md": "error",
      },
    },
    {
      // Source code files
      files: ["**/*.{ts,tsx,js,jsx}"],
      rules: {
        "unicode-policy/emoji": "error",
        "unicode-policy/no-unicode-graphics": "error",
        "no-irregular-whitespace": "error",
      },
    },
  ],
};
```

### 10.5. Custom ESLint Rules for This Standard

#### 10.5.1. Rule: `code-block-language`

Enforces section 5.4 of this standard: every fenced code block must specify a language. If the exact language is unknown, `text` or `bash` must be used as a fallback.

```javascript
// eslint-rules/code-block-language.js
module.exports = {
  meta: {
    type: "suggestion",
    docs: {
      description:
        "Require language specification in fenced code blocks (STD-DOC-002 section 5.4)",
    },
    messages: {
      missingLanguage:
        "Code block must specify a language. Use 'text' or 'bash' if unknown (STD-DOC-002 section 5.4).",
    },
  },
  create(context) {
    const sourceCode = context.sourceCode || context.getSourceCode();
    const text = sourceCode.getText();
    const lines = text.split("\n");

    // Match opening fences without a language: ``` without anything after
    const fenceRegex = /^```(\s*)$/;

    return {
      Program() {
        lines.forEach((line, index) => {
          if (fenceRegex.test(line)) {
            context.report({
              loc: { line: index + 1, column: 0 },
              messageId: "missingLanguage",
            });
          }
        });
      },
    };
  },
};
```None

#### 10.5.2. Rule: `no-emoji-in-md`

Scans the raw text of `.md` files (outside code blocks) for emoji characters. This is the Markdown-specific version of the Unicode Policy rule — it operates at level [C] Critical per STD-DOC-002 section 9.1.

```javascript
// eslint-rules/unicode-policy.js (emoji check section)
module.exports = {
  meta: {
    type: "suggestion",
    docs: {
      description:
        "Disallow emoji in Markdown documentation (STD-DOC-002 + STD-DOC-003 section 4)",
    },
    messages: {
      emojiFound:
        "Emoji are prohibited in documentation. Use text tags like [OK], [FAIL] instead (STD-DOC-002 section 4.4, STD-DOC-003 section 4).",
    },
  },
  create(context) {
    const emojiPattern =
      /[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{27BF}\u{FE00}-\u{FEFF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2702}-\u{27B0}]/u;

    return {
      Program(node) {
        const sourceCode = context.sourceCode || context.getSourceCode();
        const text = sourceCode.getText();

        // Remove code blocks (they are handled by the code-block-level rules)
        const textWithoutCodeBlocks = text.replace(/```[\s\S]*?```/g, "");

        const lines = textWithoutCodeBlocks.split("\n");
        lines.forEach((line, index) => {
          if (emojiPattern.test(line)) {
            context.report({
              loc: { line: index + 1, column: 0 },
              messageId: "emojiFound",
            });
          }
        });
      },
    };
  },
};
```

### 10.6. Nested Standards: How ESLint Rules Map to This Document

The relationship between this standard (STD-DOC-002) and the Unicode Policy (STD-DOC-003) is reflected in the ESLint severity levels:

| Standard Section | Rule | ESLint Severity | Rationale |
|------------------|------|-----------------|-----------|
| STD-DOC-002 Section 3 (Prohibited: Emoji) | `unicode-policy/emoji-in-md` | `error` | [C] level — same as source code |
| STD-DOC-002 Section 3 (Prohibited: Unicode icons) | `unicode-policy/no-unicode-graphics-in-md` | `error` | [C] level — same as source code |
| STD-DOC-002 Section 5.4 (Code block language) | `code-block-language` | `warn` | [W] level for documentation |
| STD-DOC-003 Section 4 (Prohibited: Emoji in code) | `unicode-policy/emoji` | `error` | [C] level for production code |
| STD-DOC-003 Section 4 (Prohibited: Unicode graphics in code) | `unicode-policy/no-unicode-graphics` | `error` | [C] level for production code |
| STD-DOC-002/003 (Irregular whitespace) | `no-irregular-whitespace` | `error` | Always critical |

**Key principle of uniform severity:** A rule originating from STD-DOC-003 ([C] Critical) applies with the same severity regardless of context — source code or documentation. The rationale: if emoji are prohibited, they are prohibited everywhere. Downgrading severity for .md files created an enforcement gap where violations in documentation were not caught before merge. The `lint-md.js` script defaults to `--level=C` and can be overridden with `--level=W` for projects that intentionally want softer enforcement.

### 10.7. Application Stages

| Stage | When | Tool | Action |
|-------|------|------|--------|
| Editor | Real-time | ESLint + VS Code extension | Inline errors |
| Pre-commit | Before commit | husky + lint-staged | Block commit on any violation |
| Manual check | On demand | `bash scripts/check-md.sh [path]` | Wraps ESLint + `lint-md.js` + static checks — see §0 TL;DR |
| CI | Push to branch | eslint-plugin-markdown + custom rules | Report in logs |
| Pre-merge | Before merge to main | GitHub Action | Report in PR |

**`scripts/check-md.sh` (recommended entry point):** Runs three layers in sequence — (1) bash-only static checks for the most common §5 violations, (2) ESLint if `eslint-plugin-markdown` is installed, (3) `lint-md.js` if present at the repo root. Layers 2 and 3 degrade gracefully to `[skip]` when their tools are missing, so the script is useful in any checkout (including fresh clones without `npm install`). Layer 1 always runs and catches: bare code fences (§5.4), `*`/`+` list markers (§5.2), closing `#` on headings (§5.1), multiple H1 in one document (§5.1), table pseudographics outside code blocks (§3).

**lint-staged configuration:**

```json
{
  "*.{ts,tsx,js,jsx}": [
    "eslint --max-warnings=0"
  ],
  "*.md": [
    "node lint-md.js"
  ]
}
```text

**Note:** `lint-md.js` defaults to `--level=C`, so .md violations also block the commit. To soften enforcement for a specific project, use `node lint-md.js --level=W` instead — violations will be reported as warnings but will not block the commit.

**CI workflow:**

```yaml
# .github/workflows/md-lint.yml
name: Markdown + Code Lint
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - name: Lint source code (blocks on error)
        run: npx eslint '**/*.{ts,tsx,js,jsx}' --max-warnings=0
      - name: Lint Markdown (blocks on error)
        run: node lint-md.js .
```

### 10.8. Inline Disabling of ESLint Rules

ESLint supports inline disable comments, but they must be used sparingly and with justification, consistent with the escalation policy in section 9.1.

```markdown
<!-- eslint-disable-next-line unicode-policy/emoji-in-md -->
This line intentionally contains an emoji for demonstration purposes.
```text

**Rules for inline disables:**

1. Each `eslint-disable` must include a comment explaining why
2. Disables of [C]-level rules in production code require Tech Lead approval
3. Disables of [C]-level rules in documentation require Tech Lead approval (same as production code — see §9.1)
4. `eslint-disable` without a specific rule name is prohibited — always specify which rule is being disabled

### 10.9. Running ESLint Manually

```bash
# Lint all source code files (errors block)
npx eslint 'src/**/*.{ts,tsx}'

# Lint all Markdown files (errors block — same severity as source code)
npx eslint '**/*.md' --plugin markdown --max-warnings=0

# Lint a specific file
npx eslint docs/README.md --plugin markdown

# Fix auto-fixable issues (formatting, not policy violations)
npx eslint '**/*.md' --plugin markdown --fix
```

**Important:** ESLint `--fix` can only fix formatting issues (indentation, quote style, missing semicolons). It **cannot** fix policy violations (emoji removal, Unicode graphics replacement) — these require manual intervention because the correct replacement depends on context.

### 10.10. Troubleshooting Common Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| ESLint does not scan .md files | Missing `eslint-plugin-markdown` | Install and configure the plugin (section 10.3) |
| False positives on emoji in code blocks | `.md` rule scanning code blocks | Ensure `no-emoji-in-md` strips code blocks (section 10.5.2) |
| `no-undef` errors in .md code snippets | ESLint treats code blocks as real JS | Add `"no-undef": "off"` in `.md/**` override (section 10.3) |
| Custom rule not found | Incorrect plugin path | Verify `eslint-rules/unicode-policy.js` exists and is imported correctly |
| Flat config vs legacy config conflict | Mixed config formats | Use only one format — flat config (`eslint.config.js`) for ESLint 9+ |

---

