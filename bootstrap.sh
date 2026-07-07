#!/usr/bin/env bash
#
# bootstrap.sh — Z-ai-governance bootstrap and project installation
#
# Usage:
#   bash bootstrap.sh                  # Mode 1: sandbox setup (clone + skills + AGENT_RULES)
#   bash bootstrap.sh --install <dir>   # Mode 2: install governance into a target project
#
# Mode 1 (default) — sandbox session setup:
#   1. Clones (or updates) Z-ai-governance.
#   2. Normalizes git mode-bit handling (core.fileMode=false).
#   3. Symlinks skills into /home/z/my-project/skills/.
#   4. Prints AGENT_RULES.md and runs sanity verifiers.
#
# Mode 2 (--install <dir>) — install governance into a target project:
#   1. Copies AGENT_RULES.md into the project.
#   2. Installs pre-commit hooks (eslint, no-emoji, LF check).
#   3. Copies config files (.editorconfig, .prettierrc, .gitattributes).
#   4. Configures lint-staged for eslint-rules/ in the project.
#   5. Prints installation summary.
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

    # Step 3: Copy eslint-rules/
    echo ""
    echo "--- Step 3: ESLint rules ---"
    if [ -d "$TARGET/eslint-rules" ]; then
        echo "  SKIP: eslint-rules/ already exists"
        SKIPPED=$((SKIPPED + 1))
    elif [ -d "$GOV_DIR/eslint-rules" ]; then
        cp -r "$GOV_DIR/eslint-rules" "$TARGET/eslint-rules"
        echo "  OK: eslint-rules/ copied"
        INSTALLED=$((INSTALLED + 1))
    else
        echo "  SKIP: eslint-rules/ not found in governance repo"
        SKIPPED=$((SKIPPED + 1))
    fi

    # Step 4: Install pre-commit hook
    echo ""
    echo "--- Step 4: Pre-commit hook ---"
    mkdir -p "$TARGET/.husky"

    HOOK_FILE="$TARGET/.husky/pre-commit"
    if [ -f "$HOOK_FILE" ] && ! grep -q "Z-ai-governance" "$HOOK_FILE" 2>/dev/null; then
        echo "  SKIP: .husky/pre-commit already exists (not managed by governance)"
        echo "  INFO: Add governance checks manually or remove the existing hook and re-run."
        SKIPPED=$((SKIPPED + 1))
    else
        GOV_REL=$(python3 -c "import os; print(os.path.relpath('$GOV_DIR', '$TARGET'))" 2>/dev/null || echo "../$(basename "$GOV_DIR")")

        cat > "$HOOK_FILE" << HOOK
#!/usr/bin/env bash
# Pre-commit hook -- installed by Z-ai-governance bootstrap.sh --install
# Source: $GOV_REL/.husky/pre-commit (full governance hook)
set -euo pipefail

REPO_ROOT="\$(git rev-parse --show-toplevel)"
cd "\$REPO_ROOT"

# --- Governance: no emoji/Unicode graphics in .md files (STD-DOC-003) ---
if command -v rg >/dev/null 2>&1; then
    EMOJI_VIOLATIONS=\$(git diff --cached --name-only -- '*.md' | xargs rg -l '[\\x{2702}-\\x{27B0}\\x{1F000}-\\x{1FFFF}]' 2>/dev/null || true)
    if [ -n "\$EMOJI_VIOLATIONS" ]; then
        echo "[governance] FAIL: emoji/Unicode graphics in .md files (STD-DOC-003):"
        echo "\$EMOJI_VIOLATIONS" | sed 's/^/  /'
        exit 1
    fi
fi

# --- LF line endings for shell scripts ---
CRLF_FILES=\$(git diff --cached --name-only -- '*.sh' | while read -r f; do
    if [ -f "\$f" ] && file "\$f" | grep -q CRLF; then
        echo "\$f"
    fi
done)
if [ -n "\$CRLF_FILES" ]; then
    echo "[governance] FAIL: CRLF line endings in shell scripts:"
    echo "\$CRLF_FILES" | sed 's/^/  /'
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

    # Step 5: Configure lint-staged in package.json
    echo ""
    echo "--- Step 5: lint-staged configuration ---"
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
  '*.md': ['eslint --no-eslintrc -c eslint-rules/no-emoji-in-md.js --plugin markdown']
};
fs.writeFileSync('$TARGET/package.json', JSON.stringify(pkg, null, 2) + '\\n');
console.log('  OK: lint-staged config added to package.json');
" 2>/dev/null || echo "  WARN: could not update package.json (add lint-staged config manually)"
        INSTALLED=$((INSTALLED + 1))
    fi

    # Summary
    echo ""
    echo "=== Installation Summary ==="
    echo "  Installed: $INSTALLED"
    echo "  Skipped:   $SKIPPED"
    echo ""
    echo "Governance layer is now active in $TARGET"
    echo "  - AGENT_RULES.md: agent behavior rules"
    echo "  - .husky/pre-commit: emoji, LF, lint-staged checks"
    echo "  - eslint-rules/: unicode and markdown lint rules"
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

    # Step 3: Copy eslint-rules/
    echo ""
    echo "--- Step 3: ESLint rules ---"
    if [ -d "$TARGET/eslint-rules" ]; then
        echo "  SKIP: eslint-rules/ already exists"
        SKIPPED=$((SKIPPED + 1))
    elif [ -d "$GOV_DIR/eslint-rules" ]; then
        cp -r "$GOV_DIR/eslint-rules" "$TARGET/eslint-rules"
        echo "  OK: eslint-rules/ copied"
        INSTALLED=$((INSTALLED + 1))
    else
        echo "  SKIP: eslint-rules/ not found in governance repo"
        SKIPPED=$((SKIPPED + 1))
    fi

    # Step 4: Install pre-commit hook
    echo ""
    echo "--- Step 4: Pre-commit hook ---"
    mkdir -p "$TARGET/.husky"

    HOOK_FILE="$TARGET/.husky/pre-commit"
    if [ -f "$HOOK_FILE" ] && ! grep -q "Z-ai-governance" "$HOOK_FILE" 2>/dev/null; then
        echo "  SKIP: .husky/pre-commit already exists (not managed by governance)"
        echo "  INFO: Add governance checks manually or remove the existing hook and re-run."
        SKIPPED=$((SKIPPED + 1))
    else
        # Write a lightweight pre-commit hook for the target project.
        # This is NOT the full governance hook (which requires guard/ and standards/).
        # It provides: eslint (via lint-staged), emoji/unicode check, LF check.
        GOV_REL=$(python3 -c "import os; print(os.path.relpath('$GOV_DIR', '$TARGET'))" 2>/dev/null || echo "../$(basename "$GOV_DIR")")

        cat > "$HOOK_FILE" << HOOK
#!/usr/bin/env bash
# Pre-commit hook — installed by Z-ai-governance bootstrap.sh --install
# Source: $GOV_REL/.husky/pre-commit (full governance hook)
set -euo pipefail

REPO_ROOT="\$(git rev-parse --show-toplevel)"
cd "\$REPO_ROOT"

# --- Governance: no emoji/Unicode graphics in .md files (STD-DOC-003) ---
if command -v rg >/dev/null 2>&1; then
    EMOJI_VIOLATIONS=\$(git diff --cached --name-only -- '*.md' | xargs rg -l '[\x{2702}-\x{27B0}\x{1F000}-\x{1FFFF}]' 2>/dev/null || true)
    if [ -n "\$EMOJI_VIOLATIONS" ]; then
        echo "[governance] FAIL: emoji/Unicode graphics detected in .md files (STD-DOC-003):"
        echo "\$EMOJI_VIOLATIONS" | sed 's/^/  /'
        exit 1
    fi
fi

# --- LF line endings for shell scripts ---
CRLF_FILES=\$(git diff --cached --name-only -- '*.sh' | while read -r f; do
    if [ -f "\$f" ] && file "\$f" | grep -q CRLF; then
        echo "\$f"
    fi
done)
if [ -n "\$CRLF_FILES" ]; then
    echo "[governance] FAIL: CRLF line endings in shell scripts:"
    echo "\$CRLF_FILES" | sed 's/^/  /'
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

    # Step 5: Configure lint-staged in package.json
    echo ""
    echo "--- Step 5: lint-staged configuration ---"
    if [ ! -f "$TARGET/package.json" ]; then
        echo "  SKIP: no package.json (not a Node.js project)"
    elif grep -q '"lint-staged"' "$TARGET/package.json" 2>/dev/null; then
        echo "  SKIP: lint-staged already configured in package.json"
    else
        # Use node to safely add lint-staged config to package.json
        node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('$TARGET/package.json', 'utf8'));
pkg['lint-staged'] = {
  '*.{js,jsx,ts,tsx}': ['eslint --fix', 'prettier --write'],
  '*.{json,md,css}': ['prettier --write'],
  '*.md': ['eslint --no-eslintrc -c eslint-rules/no-emoji-in-md.js --plugin markdown']
};
fs.writeFileSync('$TARGET/package.json', JSON.stringify(pkg, null, 2) + '\n');
console.log('  OK: lint-staged config added to package.json');
" 2>/dev/null || echo "  WARN: could not update package.json (add lint-staged config manually)"
        INSTALLED=$((INSTALLED + 1))
    fi

    # Summary
    echo ""
    echo "=== Installation Summary ==="
    echo "  Installed: $INSTALLED"
    echo "  Skipped:   $SKIPPED"
    echo ""
    echo "Governance layer is now active in $TARGET"
    echo "  - AGENT_RULES.md: agent behavior rules"
    echo "  - .husky/pre-commit: emoji, LF, lint-staged checks"
    echo "  - eslint-rules/: unicode and markdown lint rules"
    echo ""
    echo "Full governance (guard/ pre-commit, standards/ verifiers) lives in:"
    echo "  $GOV_DIR"
}