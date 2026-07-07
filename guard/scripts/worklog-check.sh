#!/usr/bin/env bash
#
# PROC-WORKLOG-005 -- Worklog enforcement check
# Implements: RULE-WORKLOG-002 (maintain worklog)
# Calls:      (none -- pure git diff inspection)
#
# Usage:
#   bash guard/scripts/worklog-check.sh           # soft warn (exit 0 always)
#   bash guard/scripts/worklog-check.sh --hard    # hard fail (exit 1 on violation)
#   bash guard/scripts/worklog-check.sh --min=5   # require >=5 lines (default: 3)
#   bash guard/scripts/worklog-check.sh --help
#
# Exit codes:
#   0  no violations (or --hard not set)
#   1  code change without meaningful worklog entry AND --hard set
#   2  usage error
#
# What this checks:
#   If staged files contain CODE (.py/.js/.ts/.tsx/.jsx/.sh/.go/.rs),
#   worklog.md MUST be staged with at least N lines added (default 3).
#
#   "Meaningful" = >=3 added lines. A bare touch (1-2 lines) is not enough.
#   This catches "staged worklog.md to satisfy co-change-check but wrote
#   nothing useful."
#
#   Exemptions (same as PROC-COCHANGE-003):
#     - Pure docs commits (only .md staged)         -> PASS
#     - Pure config commits (only .json/.yml/.toml) -> PASS
#     - Test-only commits (.test.* / .spec.*)       -> PASS
#     - Lockfile-only commits                       -> PASS
#
# Why this matters (RULE-WORKLOG-002):
#   "Every coding session MUST add a worklog entry with specific facts."
#   Co-change-check.sh ensures a .md is touched; this script ensures the
#   .md touched is worklog.md AND has meaningful content (>=3 lines added).

set -euo pipefail

HARD_MODE=0
MIN_LINES=3
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

for arg in "$@"; do
    case "$arg" in
        --help|-h) sed -n '2,35p' "$0"; exit 0 ;;
        --hard) HARD_MODE=1 ;;
        --min=*) MIN_LINES="${arg#--min=}" ;;
        *) echo "Unknown flag: $arg"; exit 2 ;;
    esac
done

# -- Helpers ---------------------------------------------------------------
VIOLATIONS=0
WARN_COUNT=0

emit_pass() { echo "  [PASS] $1"; }
emit_fail() { echo "  [FAIL] $1"; VIOLATIONS=$((VIOLATIONS + 1)); }
emit_warn() { echo "  [WARN] $1"; WARN_COUNT=$((WARN_COUNT + 1)); }

# -- Get staged files ------------------------------------------------------
cd "$PLATFORM_DIR"
STAGED=$(git diff --cached --name-only 2>/dev/null || true)

if [ -z "$STAGED" ]; then
    echo "=== PROC-WORKLOG-005: worklog enforcement ==="
    echo "  No staged files. Nothing to check."
    exit 0
fi

# -- Classify staged files -------------------------------------------------
CODE_EXT_REGEX='\.(py|js|ts|tsx|jsx|sh|go|rs|java|c|cpp|h|hpp|rb|php|swift|kt)$'
TEST_REGEX='\.(test|spec)\.(js|ts|tsx|jsx|py|go|rs)$'
LOCKFILE_REGEX='(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Cargo\.lock|go\.sum|poetry\.lock)$'
CONFIG_REGEX='\.(json|yml|yaml|toml|ini|env)$'

CODE_COUNT=0
WORKLOG_STAGED=false
WORKLOG_LINES_ADDED=0

while IFS= read -r f; do
    [ -z "$f" ] && continue
    if [[ "$f" =~ $LOCKFILE_REGEX ]]; then
        continue
    elif [[ "$f" =~ $TEST_REGEX ]]; then
        continue
    elif [[ "$f" =~ $CODE_EXT_REGEX ]]; then
        CODE_COUNT=$((CODE_COUNT + 1))
    elif [[ "$f" =~ $CONFIG_REGEX ]]; then
        continue
    fi
done <<< "$STAGED"

# Check worklog.md specifically
if git diff --cached --name-only -- worklog.md 2>/dev/null | grep -q .; then
    WORKLOG_STAGED=true
    # Count added lines: numstat format = "added\tdeleted\tfilename"
    WORKLOG_LINES_ADDED=$(git diff --cached --numstat -- worklog.md 2>/dev/null | awk '{print $1}' || echo "0")
    WORKLOG_LINES_ADDED=${WORKLOG_LINES_ADDED:-0}
fi

# -- Decision logic --------------------------------------------------------
echo "=== PROC-WORKLOG-005: worklog enforcement ==="
echo "Mode: $([ $HARD_MODE -eq 1 ] && echo "HARD (will fail on code-without-worklog)" || echo "SOFT (warning-only)")"
echo "Implements: RULE-WORKLOG-002 (maintain worklog)"
echo "Threshold: >=${MIN_LINES} lines added to worklog.md when code is committed"
echo ""
echo "Staged code files: ${CODE_COUNT}"
echo "Worklog staged:    ${WORKLOG_STAGED}"
echo "Worklog lines:     +${WORKLOG_LINES_ADDED} added"
echo ""

# No code -> rule does not apply
if [ "$CODE_COUNT" -eq 0 ]; then
    emit_pass "no code files staged -- RULE-WORKLOG-002 does not apply"
    echo ""
    echo "RESULT: PASS"
    exit 0
fi

# Code + worklog with enough lines -> PASS
if [ "$WORKLOG_STAGED" = true ] && [ "$WORKLOG_LINES_ADDED" -ge "$MIN_LINES" ]; then
    emit_pass "code change accompanied by worklog entry (+${WORKLOG_LINES_ADDED} lines, min=${MIN_LINES})"
    echo ""
    echo "RESULT: PASS"
    exit 0
fi

# Code + worklog but not enough lines -> WARN or FAIL
if [ "$WORKLOG_STAGED" = true ] && [ "$WORKLOG_LINES_ADDED" -lt "$MIN_LINES" ]; then
    msg="worklog entry too short: +${WORKLOG_LINES_ADDED} lines (need >=${MIN_LINES})."
    msg+=" Add: date header, what changed, specific files/commands."
    if [ $HARD_MODE -eq 1 ]; then
        emit_fail "$msg"
    else
        emit_warn "$msg"
    fi
fi

# Code without worklog at all -> WARN or FAIL
if [ "$WORKLOG_STAGED" = false ]; then
    msg="code change without worklog entry -- RULE-WORKLOG-002 violation."
    msg+=" Stage worklog.md with >=${MIN_LINES} lines describing the change."
    if [ $HARD_MODE -eq 1 ]; then
        emit_fail "$msg"
    else
        emit_warn "$msg"
    fi
fi

echo ""
echo "=== Summary ==="
echo "  Violations: $VIOLATIONS"
echo "  Warnings:   $WARN_COUNT"
echo ""

if [ $VIOLATIONS -gt 0 ] && [ $HARD_MODE -eq 1 ]; then
    echo "RESULT: FAIL -- code without meaningful worklog entry. (RULE-WORKLOG-002)"
    echo ""
    echo "Fix: add >=${MIN_LINES} lines to worklog.md, stage it, re-commit."
    echo "Bypass (emergencies only): git commit --no-verify"
    exit 1
elif [ $VIOLATIONS -gt 0 ]; then
    echo "RESULT: WARN -- re-run with --hard to enforce."
    exit 0
else
    echo "RESULT: PASS -- worklog in sync with code."
    exit 0
fi
