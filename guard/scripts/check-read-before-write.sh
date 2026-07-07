#!/usr/bin/env bash
#
# RULE-READ-003 — Read before write enforcement (heuristic)
# Detects: files modified without evidence of being read first
#
# Heuristic approach:
#   - For each staged CODE file, check if worklog.md mentions reading it
#   - New files (not in git history) are exempt
#   - Files in worklog.md with "read" or "cat" or file path = read evidence
#
# Limitations:
#   - Cannot track actual file access (no inotifywait in sandbox)
#   - Relies on worklog entries as proxy for "read" operation
#   - False positives possible if agent read but didn't log
#
# Usage:
#   bash guard/scripts/check-read-before-write.sh           # soft warn
#   bash guard/scripts/check-read-before-write.sh --hard    # hard fail
#
# Exit codes:
#   0  no violations (or soft mode)
#   1  file modified without read evidence AND --hard set
#   2  usage error

set -euo pipefail

HARD_MODE=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

for arg in "$@"; do
    case "$arg" in
        --help|-h) sed -n '2,30p' "$0"; exit 0 ;;
        --hard) HARD_MODE=1 ;;
        *) echo "Unknown flag: $arg"; exit 2 ;;
    esac
done

VIOLATIONS=0
emit_pass() { echo "  [PASS] $1"; }
emit_fail() { echo "  [FAIL] $1"; VIOLATIONS=$((VIOLATIONS + 1)); }
emit_warn() { echo "  [WARN] $1"; }

echo "=== RULE-READ-003: read before write (heuristic) ==="
echo "Mode: $([ $HARD_MODE -eq 1 ] && echo 'HARD' || echo 'SOFT')"
echo "Note: worklog-based heuristic. Cannot track actual file access."
echo ""

cd "$PLATFORM_DIR"

# Get staged CODE files
CODE_EXT_REGEX='\.(py|js|ts|tsx|jsx|sh|go|rs|java|c|cpp|h|hpp|rb|php|swift|kt)$'
STAGED=$(git diff --cached --name-only 2>/dev/null || true)

if [ -z "$STAGED" ]; then
    echo "  No staged files. Nothing to check."
    echo "RESULT: PASS"
    exit 0
fi

# Read worklog content for heuristic matching
WORKLOG=""
if [ -f "worklog.md" ]; then
    WORKLOG=$(cat worklog.md 2>/dev/null || true)
fi

# Also check staged worklog changes
STAGED_WORKLOG=$(git diff --cached -- worklog.md 2>/dev/null || true)
WORKLOG="$WORKLOG $STAGED_WORKLOG"

CHECKED=0
PASSED=0
NO_READ=0
NEW_FILES=0

while IFS= read -r f; do
    [ -z "$f" ] && continue
    [[ ! "$f" =~ $CODE_EXT_REGEX ]] && continue
    CHECKED=$((CHECKED + 1))

    # Check if file is new (not in git history)
    if ! git cat-file -e HEAD:"$f" 2>/dev/null; then
        NEW_FILES=$((NEW_FILES + 1))
        emit_pass "$f — new file, read-before-write not applicable"
        continue
    fi

    # Heuristic: check if worklog mentions reading this file
    FILE_BASENAME=$(basename "$f")
    FILE_DIR=$(dirname "$f")

    # Search patterns: explicit read mentions, file path, cat command
    READ_EVIDENCE=0
    if echo "$WORKLOG" | grep -qiE "(read|cat|граница|прочитал|изучил).*${FILE_BASENAME}"; then
        READ_EVIDENCE=1
    elif echo "$WORKLOG" | grep -qiE "${FILE_BASENAME}.*(read|cat)"; then
        READ_EVIDENCE=1
    elif echo "$WORKLOG" | grep -qF "$f"; then
        # File path mentioned in worklog (any context)
        READ_EVIDENCE=1
    fi

    if [ $READ_EVIDENCE -eq 1 ]; then
        PASSED=$((PASSED + 1))
        emit_pass "$f — read evidence found in worklog"
    else
        NO_READ=$((NO_READ + 1))
        msg="$f modified without read evidence in worklog (RULE-READ-003)"
        msg+=" — add 'read $f' or 'cat $f' to worklog.md before modifying"
        if [ $HARD_MODE -eq 1 ]; then
            emit_fail "$msg"
        else
            emit_warn "$msg"
        fi
    fi
done <<< "$STAGED"

echo ""
echo "=== Summary ==="
echo "  Checked:   $CHECKED code files"
echo "  New files: $NEW_FILES (exempt)"
echo "  Read OK:   $PASSED"
echo "  No read:   $NO_READ"
echo "  Violations: $VIOLATIONS"
echo ""

if [ $VIOLATIONS -gt 0 ] && [ $HARD_MODE -eq 1 ]; then
    echo "RESULT: FAIL — files modified without read evidence. (RULE-READ-003)"
    echo "Fix: read the file first (Log tool), add to worklog, then modify."
    exit 1
elif [ $VIOLATIONS -gt 0 ]; then
    echo "RESULT: WARN — re-run with --hard to enforce."
    exit 0
else
    echo "RESULT: PASS — all modified files have read evidence."
    exit 0
fi
