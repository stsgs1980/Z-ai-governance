#!/usr/bin/env bash
#
# bootstrap.sh -- Z-ai-governance bootstrap and project installation
#
# Usage:
#   bash bootstrap.sh                  # Mode 1: sandbox setup (clone + skills + AGENT_RULES)
#   bash bootstrap.sh --install <dir>   # Mode 2: install governance into a target project
#
# Mode 1 (default) -- sandbox session setup:
#   1. Clones (or updates) Z-ai-governance.
#   2. Normalizes git mode-bit handling (core.fileMode=false).
#   3. Symlinks skills into /home/z/my-project/skills/.
#   4. Prints AGENT_RULES.md and runs sanity verifiers.
#
# Mode 2 (--install <dir>) -- install governance into a target project:
#   1. Copies AGENT_RULES.md into the project.
#   2. Copies config files (.editorconfig, .prettierrc, .gitattributes).
#   3. Copies eslint-rules/ and eslint-processors/ into the project.
#   4. Patches the project's eslint.config.* to include governance rules.
#   5. Installs pre-commit hook (emoji, LF, lint-staged).
#   6. Adds lint-staged config to package.json.
#   7. Prints installation summary.
#
# Run Mode 1 at the start of any sandbox session.
# Run Mode 2 after creating a new project to connect governance.

set -euo pipefail

GOV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel 2>/dev/null || pwd)"
SANDBOX_SKILLS_DIR="/home/z/my-project/skills"
GITHUB_URL="https://github.com/stsgs1980/Z-ai-governance.git"

# ============================================================================
# Mode 2: Install governance into a target project
# ============================================================================

install_governance() {
    local TARGET="$1"
    local INSTALLED=0
    local SKIPPED=0

    echo "=== Installing Z-ai-governance into $TARGET ==="
    echo ""

    # Verify target is a git repo
    if [ ! -d "$TARGET/.git" ]; then
        echo "  ERROR: $TARGET is not a git repository."
        echo "  Run 'git init' first, then re-run this command."
        exit 1
    fi

    # Step 1: Copy AGENT_RULES.md
    echo "--- Step 1: AGENT_RULES.md ---"
    if [ -f "$TARGET/AGENT_RULES.md" ]; then
        echo "  SKIP: AGENT_RULES.md already exists"
        SKIPPED=$((SKIPPED + 1))
    else
        cp "$GOV_DIR/AGENT_RULES.md" "$TARGET/AGENT_RULES.md"
        echo "  OK: AGENT_RULES.md copied"
        INSTALLED=$((INSTALLED + 1))
    fi

    # Step 2: Copy config files
    echo ""
    echo "--- Step 2: Config files ---"
    for cfg in .editorconfig .prettierrc .gitattributes; do
        if [ -f "$GOV_DIR/$cfg" ]; then
            if [ -f "$TARGET/$cfg" ]; then
                echo "  SKIP: $cfg already exists"
                SKIPPED=$((SKIPPED + 1))
            else
                cp "$GOV_DIR/$cfg" "$TARGET/$cfg"
                echo "  OK: $cfg copied"
                INSTALLED=$((INSTALLED + 1))
            fi
        fi
    done

    # Step 3: Copy eslint-rules/ and eslint-processors/
    echo ""
    echo "--- Step 3: ESLint rules and processors ---"
    for dir_name in eslint-rules eslint-processors; do
        if [ -d "$TARGET/$dir_name" ]; then
            echo "  SKIP: $dir_name/ already exists"
            SKIPPED=$((SKIPPED + 1))
        elif [ -d "$GOV_DIR/$dir_name" ]; then
            cp -r "$GOV_DIR/$dir_name" "$TARGET/$dir_name"
            echo "  OK: $dir_name/ copied"
            INSTALLED=$((INSTALLED + 1))
        else
            echo "  SKIP: $dir_name/ not found in governance repo"
            SKIPPED=$((SKIPPED + 1))
        fi
    done

    # Step 4: Patch eslint.config.* to include governance rules
    echo ""
    echo "--- Step 4: ESLint config patch ---"
    if [ ! -f "$TARGET/package.json" ]; then
        echo "  SKIP: no package.json (not a Node.js project)"
    else
        # Check if eslint-plugin-markdown and @typescript-eslint/parser are available
        NEED_DEPS=()
        cd "$TARGET"
        if ! node -e "require('eslint-plugin-markdown')" 2>/dev/null; then
            NEED_DEPS+=("eslint-plugin-markdown")
        fi
        if ! node -e "require('@typescript-eslint/parser')" 2>/dev/null; then
            NEED_DEPS+=("@typescript-eslint/parser")
        fi
        if [ ${#NEED_DEPS[@]} -gt 0 ]; then
            echo "  Installing ESLint dependencies: ${NEED_DEPS[*]}"
            npm install --save-dev "${NEED_DEPS[@]}" 2>/dev/null || \
                bun add --dev "${NEED_DEPS[@]}" 2>/dev/null || \
                echo "  WARN: could not install dependencies (install manually: ${NEED_DEPS[*]})"
        fi

        # Generate a governance ESLint config snippet
        GOV_REL=$(python3 -c "import os; print(os.path.relpath('$GOV_DIR', '$TARGET'))" 2>/dev/null || echo "../$(basename "$GOV_DIR")")

        # Detect existing eslint config file
        ESLINT_CONFIG=""
        for ext in ".mjs" ".js" ".cjs"; do
            if [ -f "$TARGET/eslint.config${ext}" ]; then
                ESLINT_CONFIG="eslint.config${ext}"
                break
            fi
        done

        if [ -n "$ESLINT_CONFIG" ]; then
            # Check if governance import already present
            if grep -q "unicode-policy" "$TARGET/$ESLINT_CONFIG" 2>/dev/null; then
                echo "  SKIP: governance rules already in $ESLINT_CONFIG"
                SKIPPED=$((SKIPPED + 1))
            else
                # Determine if the config uses ESM (import/export) or CJS (require/module.exports)
                if grep -qE '^\s*import\s' "$TARGET/$ESLINT_CONFIG" 2>/dev/null; then
                    # ESM config -- prepend governance imports and merge
                    node -e "
const fs = require('fs');
const cfg = fs.readFileSync('$TARGET/$ESLINT_CONFIG', 'utf8');

// Check for existing imports
const hasMarkdown = cfg.includes('eslint-plugin-markdown');
const hasTsParser = cfg.includes('@typescript-eslint/parser');
const hasUnicode = cfg.includes('unicode-policy');
const hasCodeBlock = cfg.includes('code-block-language');

let imports = [];
let needsMarkdownImport = !hasMarkdown;
let needsTsParserImport = !hasTsParser;
let needsUnicodeImport = !hasUnicode;
let needsCodeBlockImport = !hasCodeBlock;

if (needsMarkdownImport) imports.push(\"import markdown from 'eslint-plugin-markdown';\");
if (needsTsParserImport) imports.push(\"import tsParser from '@typescript-eslint/parser';\");
if (needsUnicodeImport) imports.push(\"import unicodePolicy from './eslint-rules/unicode-policy.js';\");
if (needsCodeBlockImport) imports.push(\"import codeBlockLanguage from './eslint-rules/code-block-language.js';\");

const codeBlockLangPlugin = needsCodeBlockImport ? \"
const codeBlockLanguagePlugin = {
  meta: { name: 'code-block-language', version: '1.0.0' },
  rules: { 'require-language': codeBlockLanguage },
};
\" : '';

// Build the governance block to append
const govBlock = \`

// --- Z-ai-governance rules (STD-DOC-002, STD-DOC-003) ---
\${codeBlockLangPlugin}
{
  files: ['**/*.md/**'],
  languageOptions: {
    parser: tsParser,
    parserOptions: { ecmaVersion: 'latest', sourceType: 'module', ecmaFeatures: { jsx: true } },
  },
  linterOptions: { reportUnusedDisableDirectives: false },
  plugins: { 'unicode-policy': unicodePolicy },
  rules: {
    'unicode-policy/emoji': 'error',
    'unicode-policy/unicode-graphics': 'error',
  },
},
{
  files: ['**/*.md'],
  plugins: { 'unicode-policy': unicodePolicy, 'code-block-language': codeBlockLanguagePlugin },
  rules: {
    'unicode-policy/emoji-in-md': 'error',
    'unicode-policy/unicode-graphics-in-md': 'error',
    'code-block-language/require-language': 'error',
  },
},
{
  files: ['**/*.{ts,tsx,js,jsx}'],
  plugins: { 'unicode-policy': unicodePolicy },
  rules: {
    'unicode-policy/emoji': 'error',
    'unicode-policy/unicode-graphics': 'error',
    'no-irregular-whitespace': 'error',
  },
},
\`;

// Insert imports after the first import block, append governance rules before final ];
let result = cfg;
if (imports.length > 0) {
  // Find the last import line and add after it
  const lines = result.split('\n');
  let lastImportIdx = -1;
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].match(/^\s*import\s/)) lastImportIdx = i;
  }
  if (lastImportIdx >= 0) {
    lines.splice(lastImportIdx + 1, 0, ...imports);
  } else {
    lines.unshift(...imports, '');
  }
  result = lines.join('\n');
}

// Append governance block before the last line (if it's just ]; or ])
result = result.replace(/(\n*)(\]\s*;?\s*)$/, govBlock + '\$1\$2');
fs.writeFileSync('$TARGET/$ESLINT_CONFIG', result);
" 2>/dev/null && echo "  OK: governance rules patched into $ESLINT_CONFIG" || echo "  WARN: could not patch $ESLINT_CONFIG (add governance rules manually)"
                    INSTALLED=$((INSTALLED + 1))
                else
                    # CJS config -- add a comment for manual integration
                    echo "  WARN: $ESLINT_CONFIG uses CommonJS format."
                    echo "  INFO: Add governance rules manually (see $GOV_DIR/eslint.config.js for reference)."
                    SKIPPED=$((SKIPPED + 1))
                fi
            fi
        else
            echo "  SKIP: no eslint.config.* found in $TARGET"
            echo "  INFO: Create an eslint.config.mjs, then re-run to auto-patch."
            SKIPPED=$((SKIPPED + 1))
        fi
        cd "$GOV_DIR"
    fi

    # Step 5: Install pre-commit hook
    echo ""
    echo "--- Step 5: Pre-commit hook ---"
    mkdir -p "$TARGET/.husky"

    HOOK_FILE="$TARGET/.husky/pre-commit"
    if [ -f "$HOOK_FILE" ] && ! grep -q "Z-ai-governance" "$HOOK_FILE" 2>/dev/null; then
        echo "  SKIP: .husky/pre-commit already exists (not managed by governance)"
        echo "  INFO: Remove the existing hook and re-run, or integrate manually."
        SKIPPED=$((SKIPPED + 1))
    else
        cat > "$HOOK_FILE" << 'HOOK'
#!/usr/bin/env bash
# Pre-commit hook -- installed by Z-ai-governance bootstrap.sh --install
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# --- Governance: no emoji/Unicode graphics in .md files (STD-DOC-003) ---
if command -v rg >/dev/null 2>&1; then
    EMOJI_VIOLATIONS=$(git diff --cached --name-only -- '*.md' | xargs rg -l '[\x{2702}-\x{27B0}\x{1F000}-\x{1FFFF}]' 2>/dev/null || true)
    if [ -n "$EMOJI_VIOLATIONS" ]; then
        echo "[governance] FAIL: emoji/Unicode graphics in .md files (STD-DOC-003):"
        echo "$EMOJI_VIOLATIONS" | sed 's/^/  /'
        exit 1
    fi
fi

# --- LF line endings for shell scripts ---
CRLF_FILES=$(git diff --cached --name-only -- '*.sh' | while read -r f; do
    if [ -f "$f" ] && file "$f" | grep -q CRLF; then
        echo "$f"
    fi
done)
if [ -n "$CRLF_FILES" ]; then
    echo "[governance] FAIL: CRLF line endings in shell scripts:"
    echo "$CRLF_FILES" | sed 's/^/  /'
    exit 1
fi

# --- lint-staged (eslint + prettier) ---
if [ -f "package.json" ] && grep -q "lint-staged" package.json 2>/dev/null; then
    npx lint-staged
fi

exit 0
HOOK
        chmod +x "$HOOK_FILE"
        echo "  OK: .husky/pre-commit installed"
        INSTALLED=$((INSTALLED + 1))
    fi

    # Step 6: Configure lint-staged in package.json
    echo ""
    echo "--- Step 6: lint-staged configuration ---"
    if [ ! -f "$TARGET/package.json" ]; then
        echo "  SKIP: no package.json (not a Node.js project)"
    elif grep -q '"lint-staged"' "$TARGET/package.json" 2>/dev/null; then
        echo "  SKIP: lint-staged already configured in package.json"
    else
        node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('$TARGET/package.json', 'utf8'));
pkg['lint-staged'] = {
  '*.{js,jsx,ts,tsx}': ['eslint --fix', 'prettier --write'],
  '*.{json,md,css}': ['prettier --write'],
};
fs.writeFileSync('$TARGET/package.json', JSON.stringify(pkg, null, 2) + '\n');
" 2>/dev/null && echo "  OK: lint-staged config added to package.json" || echo "  WARN: could not update package.json (add lint-staged config manually)"
        INSTALLED=$((INSTALLED + 1))
    fi

    # Step 7: Install husky + lint-staged npm packages if missing
    echo ""
    echo "--- Step 7: npm dependencies ---"
    cd "$TARGET"
    NEED_INSTALL=()
    if ! grep -q '"husky"' package.json 2>/dev/null; then
        NEED_INSTALL+=("husky")
    fi
    if ! grep -q '"lint-staged"' package.json 2>/dev/null; then
        NEED_INSTALL+=("lint-staged")
    fi
    if [ ${#NEED_INSTALL[@]} -gt 0 ]; then
        echo "  Installing: ${NEED_INSTALL[*]}"
        npm install --save-dev "${NEED_INSTALL[@]}" 2>/dev/null || \
            bun add --dev "${NEED_INSTALL[@]}" 2>/dev/null || \
            echo "  WARN: could not install (run manually: npm i -D ${NEED_INSTALL[*]})"
    else
        echo "  OK: husky and lint-staged already in package.json"
        SKIPPED=$((SKIPPED + 1))
    fi
    cd "$GOV_DIR"

    # Summary
    echo ""
    echo "=== Installation Summary ==="
    echo "  Installed: $INSTALLED"
    echo "  Skipped:   $SKIPPED"
    echo ""
    echo "Governance layer is now active in $TARGET"
    echo "  - AGENT_RULES.md: agent behavior rules"
    echo "  - .husky/pre-commit: emoji, LF, lint-staged checks"
    echo "  - eslint-rules/: unicode and code-block-language lint rules"
    echo "  - eslint-processors/: markdown snippet extraction for ESLint"
    echo ""
    echo "Full governance (guard/ pre-commit, standards/ verifiers) lives in:"
    echo "  $GOV_DIR"
}

# ============================================================================
# Mode detection
# ============================================================================

if [ "${1:-}" = "--install" ]; then
    if [ -z "${2:-}" ]; then
        echo "Usage: bash bootstrap.sh --install <project-dir>"
        echo "  <project-dir>  Path to the target project root (must be a git repo)."
        exit 1
    fi
    TARGET="$(cd "$2" && pwd)"
    install_governance "$TARGET"
    exit 0
fi

# ============================================================================
# Mode 1: Sandbox session setup
# ============================================================================

echo "=== Step 1: Ensure Z-ai-governance is cloned ==="

if [ ! -d "$GOV_DIR/.git" ]; then
    echo "Cloning Z-ai-governance into $GOV_DIR ..."
    git clone "$GITHUB_URL" "$GOV_DIR"
else
    echo "Z-ai-governance already exists. Pulling latest ..."
    cd "$GOV_DIR"
    git pull --ff-only
fi

echo ""
echo "=== Step 2: Normalize git mode-bit handling ==="
cd "$GOV_DIR"
git config core.fileMode false
echo "  core.fileMode=false applied"

echo ""
echo "=== Step 3: Symlink custom skills into sandbox skills dir ==="

mkdir -p "$SANDBOX_SKILLS_DIR"

TOOLKIT_SKILLS_DIR="$GOV_DIR/skills"
LINKED_COUNT=0

for skill_dir in "$TOOLKIT_SKILLS_DIR"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    target_link="$SANDBOX_SKILLS_DIR/$skill_name"

    if [ -e "$target_link" ] || [ -L "$target_link" ]; then
        if [ -L "$target_link" ]; then
            rm "$target_link"
            ln -s "$skill_dir" "$target_link"
            LINKED_COUNT=$((LINKED_COUNT + 1))
        else
            backup_dir="${target_link}.sandbox-backup"
            if [ -d "$backup_dir" ]; then
                rm -rf "$target_link"
            else
                mv "$target_link" "$backup_dir"
            fi
            ln -s "$skill_dir" "$target_link"
            echo "  REPLACE  $skill_name  (sandbox version backed up to ${skill_name}.sandbox-backup)"
            LINKED_COUNT=$((LINKED_COUNT + 1))
        fi
    else
        ln -s "$skill_dir" "$target_link"
        echo "  LINK     $skill_name"
        LINKED_COUNT=$((LINKED_COUNT + 1))
    fi
done

echo ""
echo "=== Step 4: Available custom skills ==="
echo "Linked: $LINKED_COUNT"
echo ""
for skill_dir in "$TOOLKIT_SKILLS_DIR"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    if [ -f "$skill_dir/SKILL.md" ]; then
        desc=$(awk '/^description:/{sub(/^description: /,""); print; exit}' "$skill_dir/SKILL.md" | cut -c1-80)
        printf "  %-40s %s\n" "$skill_name" "$desc"
    fi
done

echo ""
echo "=== Step 5: Print AGENT_RULES.md (single entry point) ==="
if [ -f "$GOV_DIR/AGENT_RULES.md" ]; then
    echo "----------------------------------------  AGENT_RULES.md  ----------------------------------------"
    cat "$GOV_DIR/AGENT_RULES.md"
    echo "----------------------------------------------------------------------------------------------------"
else
    echo "  WARNING: AGENT_RULES.md not found at $GOV_DIR/AGENT_RULES.md"
fi

echo ""
echo "=== Step 6: Run sanity verifiers (warning-only, non-blocking) ==="
if [ -f "$GOV_DIR/standards/scripts/verify-standards.js" ]; then
    echo "  Running verify-standards.js..."
    (cd "$GOV_DIR/standards" && node scripts/verify-standards.js 2>&1 | tail -10) || echo "  [WARN] verify-standards.js failed (non-blocking)"
else
    echo "  SKIP: verify-standards.js not found"
fi
if [ -f "$GOV_DIR/standards/scripts/verify-id-graph.js" ]; then
    echo ""
    echo "  Running verify-id-graph.js..."
    (cd "$GOV_DIR/standards" && node scripts/verify-id-graph.js 2>&1 | tail -10) || echo "  [WARN] verify-id-graph.js failed (non-blocking)"
else
    echo "  SKIP: verify-id-graph.js not found"
fi

echo ""
echo "Done. Skills and AGENT_RULES.md are ready."
echo "To install governance into a project: bash bootstrap.sh --install <project-dir>"