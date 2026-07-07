#!/usr/bin/env bash
#
# save-work.sh — quick save your work to GitHub (safety net against session death)
#
# Usage:
#   bash scripts/save-work.sh "what you did"
#
# What it does:
#   1. Stages ALL changes in Z-ai-platform + 2 submodules (standards, guard)
#      Note: skills/ is an inline monorepo since a3d358b, not a submodule.
#   2. Commits with your message (+ timestamp)
#   3. Pushes everything to GitHub
#
# Run this every time you finish a meaningful chunk of work. If your session
# dies 5 minutes later, your work is already on GitHub.

set -euo pipefail

PLATFORM_DIR="/home/z/my-project/Z-ai-platform"
cd "$PLATFORM_DIR"

MSG="${1:-manual save at $(date -u +%Y-%m-%dT%H:%M:%SZ)}"

echo "=== 1. Save submodule changes (standards, guard) ==="
for sub in standards guard; do
    if [ -d "$sub/.git" ]; then
        echo "--- $sub ---"
        cd "$sub"
        # Make sure we're on main, not detached HEAD
        current_branch=$(git rev-parse --abbrev-ref HEAD)
        if [ "$current_branch" = "HEAD" ]; then
            git checkout main 2>&1 | tail -3 || git checkout -B main origin/main 2>&1 | tail -3
        fi
        # Stage + commit if there's anything
        if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
            git add -A
            git commit -m "$MSG" 2>&1 | tail -3 || echo "(nothing to commit in $sub)"
            git push origin main 2>&1 | tail -3
        else
            echo "(no changes in $sub)"
        fi
        cd "$PLATFORM_DIR"
    fi
done

echo ""
echo "=== 2. Update submodule pointers in parent repo ==="
git add standards guard 2>/dev/null || true

echo ""
echo "=== 3. Stage + commit parent repo changes ==="
if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    git add -A
    # Run pre-commit hooks (verify-standards.js + verify-id-graph.js)
    git commit -m "$MSG" 2>&1 | tail -5
    echo ""
    echo "=== 4. Push parent repo ==="
    git push origin main 2>&1 | tail -3
else
    echo "(no changes in parent repo)"
fi

echo ""
echo "=== Done. Work saved to GitHub at $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
