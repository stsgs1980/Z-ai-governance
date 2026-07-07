#!/usr/bin/env bash
#
# save-work.sh — quick save your work to GitHub (safety net against session death)
#
# Usage:
#   bash scripts/save-work.sh "what you did"
#
# What it does:
#   1. Stages ALL changes in Z-ai-governance (flat repo, no submodules)
#   2. Commits with your message (+ timestamp)
#   3. Pushes everything to GitHub
#
# Run this every time you finish a meaningful chunk of work. If your session
# dies 5 minutes later, your work is already on GitHub.

set -euo pipefail

PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$PLATFORM_DIR"

MSG="${1:-manual save at $(date -u +%Y-%m-%dT%H:%M:%SZ)}"

echo "=== 1. Stage + commit all changes ==="
if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    git add -A
    git commit -m "$MSG" 2>&1 | tail -5
    echo ""
    echo "=== 2. Push to GitHub ==="
    git push origin main 2>&1 | tail -3
else
    echo "(no changes to save)"
fi

echo ""
echo "=== Done. Work saved to GitHub at $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="