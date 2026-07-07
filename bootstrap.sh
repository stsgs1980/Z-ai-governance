#!/usr/bin/env bash
#
# bootstrap.sh — restore your custom skills in a fresh Z.ai sandbox session
#
# Usage:
#   bash bootstrap.sh
#   (run from repo root, or: bash <(curl -fsSL https://raw.githubusercontent.com/stsgs1980/Z-ai-governance/main/bootstrap.sh))
#
# What it does:
#   1. Clones (or updates) stsgs1980/Z-ai-governance into the current directory.
#      Flat repo — standards/ and guard/ are regular directories (no submodules).
#   2. Normalizes git mode-bit handling (core.fileMode=false).
#      Sandbox fs mount sets +x on all files, which git's default
#      core.fileMode=true flags as 'modified' (17-file noise). See
#      SESSION_NOTES.md §12 LESSON-002.
#   3. Symlinks every skill from Z-ai-governance/skills/* into
#      /home/z/my-project/skills/ so the sandbox can find them.
#   4. Prints a list of available custom skills at the end.
#
# Run this once at the start of any new sandbox session where you want your
# custom skills back.

set -euo pipefail

PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel 2>/dev/null || pwd)"
SANDBOX_SKILLS_DIR="/home/z/my-project/skills"
GITHUB_URL="https://github.com/stsgs1980/Z-ai-governance.git"

echo "=== Step 1: Ensure Z-ai-governance is cloned ==="

if [ ! -d "$PLATFORM_DIR/.git" ]; then
    echo "Cloning Z-ai-governance into $PLATFORM_DIR ..."
    git clone "$GITHUB_URL" "$PLATFORM_DIR"
else
    echo "Z-ai-governance already exists. Pulling latest ..."
    cd "$PLATFORM_DIR"
    git pull --ff-only
fi

echo ""
echo "=== Step 2: Normalize git mode-bit handling ==="
# Sandbox fs mount sets +x on all files (so .sh scripts run). Git's default
# core.fileMode=true flags the index/working-tree mismatch as 'modified'.
# Setting false makes git ignore mode bit changes. Existing index modes are
# preserved: .sh files stay 100755, docs stay 100644. New .sh files need
# explicit 'git update-index --chmod=+x'.
# See SESSION_NOTES.md §12 LESSON-002 for full rationale.
cd "$PLATFORM_DIR"
git config core.fileMode false
echo "  core.fileMode=false applied"

echo ""
echo "=== Step 3: Symlink custom skills into sandbox skills dir ==="

mkdir -p "$SANDBOX_SKILLS_DIR"

TOOLKIT_SKILLS_DIR="$PLATFORM_DIR/skills"
LINKED_COUNT=0
SKIPPED_COUNT=0

for skill_dir in "$TOOLKIT_SKILLS_DIR"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    target_link="$SANDBOX_SKILLS_DIR/$skill_name"

    if [ -e "$target_link" ] || [ -L "$target_link" ]; then
        if [ -L "$target_link" ]; then
            # Already a symlink we created — refresh it
            rm "$target_link"
            ln -s "$skill_dir" "$target_link"
            LINKED_COUNT=$((LINKED_COUNT + 1))
        else
            # Real directory exists with this name. For our toolkit skills
            # (the ones in Z-ai-governance), we want OUR version to win.
            # Backup the sandbox version and replace with symlink.
            backup_dir="${target_link}.sandbox-backup"
            if [ -d "$backup_dir" ]; then
                # Already backed up previously — just remove the sandbox copy
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
echo "Skipped (already exist as real dirs): $SKIPPED_COUNT"
echo ""
echo "Custom skills now available via Skill(command=\"...\"):"
for skill_dir in "$TOOLKIT_SKILLS_DIR"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    if [ -f "$skill_dir/SKILL.md" ]; then
        # Extract description first line
        desc=$(awk '/^description:/{sub(/^description: /,""); print; exit}' "$skill_dir/SKILL.md" | cut -c1-80)
        printf "  %-40s %s\n" "$skill_name" "$desc"
    fi
done

echo ""
echo "=== Step 5: Print AGENT_RULES.md (single entry point) ==="
if [ -f "$PLATFORM_DIR/AGENT_RULES.md" ]; then
    echo "----------------------------------------  AGENT_RULES.md  ----------------------------------------"
    cat "$PLATFORM_DIR/AGENT_RULES.md"
    echo "----------------------------------------------------------------------------------------------------"
else
    echo "  WARNING: AGENT_RULES.md not found at $PLATFORM_DIR/AGENT_RULES.md"
    echo "           Agent onboarding protocol is missing. Clone integrity may be compromised."
fi

echo ""
echo "=== Step 6: Run sanity verifiers (warning-only, non-blocking) ==="
if [ -f "$PLATFORM_DIR/standards/scripts/verify-standards.js" ]; then
    echo "  Running verify-standards.js..."
    (cd "$PLATFORM_DIR/standards" && node scripts/verify-standards.js 2>&1 | tail -10) || echo "  [WARN] verify-standards.js failed (non-blocking)"
else
    echo "  SKIP: verify-standards.js not found"
fi
if [ -f "$PLATFORM_DIR/standards/scripts/verify-id-graph.js" ]; then
    echo ""
    echo "  Running verify-id-graph.js..."
    (cd "$PLATFORM_DIR/standards" && node scripts/verify-id-graph.js 2>&1 | tail -10) || echo "  [WARN] verify-id-graph.js failed (non-blocking)"
else
    echo "  SKIP: verify-id-graph.js not found"
fi

echo ""
echo "Done. To verify: Skill(command=\"skill-creator\") should now load your refactored version."
echo "Onboarding: see AGENT_RULES.md above (single entry point for agents)."
