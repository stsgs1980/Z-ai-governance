#!/usr/bin/env bash
#
# RULE-COMMIT-014 — Pre-commit checklist enforcement
# Checks before every commit:
#   1. No large binary files staged (>1MB) (RULE-COMMIT-014)
#   2. HONEST-006 — "done" without verification evidence
#
# NOTE: Emoji/Unicode check (RULE-DOC-015) was removed — now enforced
#       by root eslint-rules/unicode-policy.js via lint-staged (single source).
# NOTE: Worklog check (RULE-WORKLOG-002) was removed — now enforced
#       by guard/scripts/worklog-check.sh (PROC-WORKLOG-005, single source).
#
# Usage:
#   bash guard/scripts/check-commit-checklist.sh           # soft warn
#   bash guard/scripts/check-commit-checklist.sh --hard    # hard fail
#
# Exit codes:
#   0  all checks pass
#   1  check failed AND --hard set
#   2  usage error

set -euo pipefail

HARD_MODE=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

for arg in "$@"; do
    case "$arg" in
        --help|-h) sed -n '2,20p' "$0"; exit 0 ;;
        --hard) HARD_MODE=1 ;;
        *) echo "Unknown flag: $arg"; exit 2 ;;
    esac
done

VIOLATIONS=0
emit_pass() { echo "  [PASS] $1"; }
emit_fail() { echo "  [FAIL] $1"; VIOLATIONS=$((VIOLATIONS + 1)); }
emit_warn() { echo "  [WARN] $1"; }

echo "=== RULE-COMMIT-014: pre-commit checklist ==="
echo "Mode: $([ $HARD_MODE -eq 1 ] && echo 'HARD' || echo 'SOFT')"
echo ""

cd "$PLATFORM_DIR"
STAGED=$(git diff --cached --name-only 2>/dev/null || true)

if [ -z "$STAGED" ]; then
    echo "  No staged files. Nothing to check."
    echo "RESULT: PASS"
    exit 0
fi

# --- Check 1: Large binary files (>1MB) ---
echo "--- RULE-COMMIT-014: no large binaries ---"
LARGE_FILES=""
while IFS= read -r f; do
    [ -z "$f" ] && continue
    # Skip known binary directories
    [[ "$f" == node_modules/* ]] && continue
    [[ "$f" == .git/* ]] && continue
    [[ "$f" == docs/_graph/* ]] && continue
    if [ -f "$f" ]; then
        SIZE=$(wc -c < "$f" 2>/dev/null || echo "0")
        if [ "$SIZE" -gt 1048576 ]; then
            LARGE_FILES="$LARGE_FILES $f ($(( SIZE / 1048576 ))MB)"
        fi
    fi
done <<< "$STAGED"

if [ -z "$LARGE_FILES" ]; then
    emit_pass "no large binary files (>1MB)"
else
    emit_fail "large files staged:$LARGE_FILES (RULE-COMMIT-014: consider git-lfs)"
fi

# --- Check 2: HONEST-006 — "done" without verification evidence ---
echo "--- RULE-HONEST-006: no unverified completion claims ---"
HONEST_ISSUES=""
while IFS= read -r f; do
    [ -z "$f" ] && continue
    [[ "$f" != *.md ]] && continue
    # Check worklog for completion claims without verification
    if [ -f "$f" ]; then
        # Look for "done", "fixed", "resolved", "готово", "исправлено" followed by no test/verify/run
        CLAIMS=$(grep -inE "(done|fixed|resolved|готово|исправлено|complete|completed)" "$f" 2>/dev/null | grep -viE "(test|verify|run|check|pass|проверк|тест)" | head -5 || true)
        if [ -n "$CLAIMS" ]; then
            HONEST_ISSUES="$HONEST_ISSUES $f"
        fi
    fi
done <<< "$STAGED"

if [ -z "$HONEST_ISSUES" ]; then
    emit_pass "no unverified completion claims"
else
    emit_warn "completion claims without verification evidence:$HONEST_ISSUES (RULE-HONEST-006 — verify before claiming done)"
fi

echo ""
echo "=== Summary ==="
echo "  Violations: $VIOLATIONS"
echo ""

if [ $VIOLATIONS -gt 0 ] && [ $HARD_MODE -eq 1 ]; then
    echo "RESULT: FAIL — commit checklist violations detected. (RULE-COMMIT-014)"
    exit 1
elif [ $VIOLATIONS -gt 0 ]; then
    echo "RESULT: WARN — re-run with --hard to enforce."
    exit 0
else
    echo "RESULT: PASS — all checklist items satisfied."
    exit 0
fi