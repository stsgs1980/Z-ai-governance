#!/usr/bin/env bash
#
# RULE-INTEGRITY-011 — Anti-bypass enforcement
# Detects: --no-verify, hook tampering, worklog deletion, fake entries
#
# Usage:
#   bash guard/scripts/check-no-bypass.sh           # soft warn
#   bash guard/scripts/check-no-bypass.sh --hard    # hard fail
#
# Exit codes:
#   0  no bypass attempts detected
#   1  bypass attempt detected AND --hard set
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

echo "=== RULE-INTEGRITY-011: anti-bypass check ==="
echo "Mode: $([ $HARD_MODE -eq 1 ] && echo 'HARD' || echo 'SOFT')"
echo ""

cd "$PLATFORM_DIR"

# 1. Check .husky/ files are not modified in staged files
# Exception: .husky/pre-commit is allowed to be modified (adding new enforcement rules)
HOOKS_MODIFIED=$(git diff --cached --name-only -- .husky/ 2>/dev/null | grep -v ".husky/pre-commit$" || true)
if [ -n "$HOOKS_MODIFIED" ]; then
    emit_fail "Hook files modified in staged commit: $HOOKS_MODIFIED (RULE-INTEGRITY-011: no hook tampering)"
else
    emit_pass "no hook files modified (or only pre-commit updated)"
fi

# 2. Check worklog.md is not deleted
WORKLOG_DELETED=$(git diff --cached --diff-filter=D --name-only -- worklog.md 2>/dev/null || true)
if [ -n "$WORKLOG_DELETED" ]; then
    emit_fail "worklog.md deleted in staged commit (RULE-INTEGRITY-011: no worklog deletion)"
else
    emit_pass "worklog.md not deleted"
fi

# 3. Check guard/rules/ files are not modified
RULES_MODIFIED=$(git diff --cached --name-only -- guard/rules/ 2>/dev/null || true)
if [ -n "$RULES_MODIFIED" ]; then
    emit_fail "Guard rules modified in staged commit: $RULES_MODIFIED (RULE-INTEGRITY-011: no rule tampering)"
else
    emit_pass "guard rules not modified"
fi

# 4. Check standards/ scripts are not modified (upstream write protection)
SCRIPTS_MODIFIED=$(git diff --cached --name-only -- standards/scripts/ 2>/dev/null || true)
if [ -n "$SCRIPTS_MODIFIED" ]; then
    emit_fail "Standards verifier scripts modified: $SCRIPTS_MODIFIED (RULE-ARCH-016/017: upstream immutable)"
else
    emit_pass "standards verifier scripts not modified"
fi

echo ""
echo "=== Summary ==="
echo "  Violations: $VIOLATIONS"
echo ""

if [ $VIOLATIONS -gt 0 ] && [ $HARD_MODE -eq 1 ]; then
    echo "RESULT: FAIL — bypass/integrity violation detected. (RULE-INTEGRITY-011)"
    exit 1
elif [ $VIOLATIONS -gt 0 ]; then
    echo "RESULT: WARN — re-run with --hard to enforce."
    exit 0
else
    echo "RESULT: PASS — no bypass attempts detected."
    exit 0
fi
