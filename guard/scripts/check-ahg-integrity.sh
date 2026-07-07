#!/usr/bin/env bash
#
# RULE-ARCH-016 — AHG submodule immutable architecture
# RULE-ARCH-017 — Upstream write protection (no consumer agent may push to AHG)
#
# Verifies: no staged files inside guard/ or standards/ (except worklog.md)
# Verifies: no git push commands targeting AHG upstream
#
# Usage:
#   bash guard/scripts/check-ahg-integrity.sh           # soft warn
#   bash guard/scripts/check-ahg-integrity.sh --hard    # hard fail
#
# Exit codes:
#   0  all checks pass
#   1  violation detected AND --hard set
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

echo "=== RULE-ARCH-016/017: AHG integrity check ==="
echo "Mode: $([ $HARD_MODE -eq 1 ] && echo 'HARD' || echo 'SOFT')"
echo ""

cd "$PLATFORM_DIR"

# 1. Check if guard/ has staged changes (ARCH-016: immutable)
if git diff --cached --name-only 2>/dev/null | grep -q "^guard/"; then
    # Allow worklog.md changes (it's a consumer file)
    NON_WORKLOG=$(git diff --cached --name-only 2>/dev/null | grep "^guard/" | grep -v "worklog.md" || true)
    if [ -n "$NON_WORKLOG" ]; then
        emit_fail "staged changes in guard/: $NON_WORKLOG (RULE-ARCH-016: guard/ is immutable architecture)"
    else
        emit_pass "guard/ staged changes are worklog.md only (allowed)"
    fi
else
    emit_pass "no staged changes in guard/"
fi

# 2. Check if standards/ has staged changes (ARCH-016: immutable)
if git diff --cached --name-only 2>/dev/null | grep -q "^standards/"; then
    # Allow worklog.md and _changeset/ changes
    IMMUTABLE=$(git diff --cached --name-only 2>/dev/null | grep "^standards/" | grep -v -E "(worklog\.md|_changeset/)" || true)
    if [ -n "$IMMUTABLE" ]; then
        emit_fail "staged changes in standards/: $IMMUTABLE (RULE-ARCH-016: standards/ is immutable architecture)"
    else
        emit_pass "standards/ staged changes are worklog.md or _changeset/ only (allowed)"
    fi
else
    emit_pass "no staged changes in standards/"
fi

# 3. Check staged commands for AHG push (ARCH-017)
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || true)
if [ -n "$STAGED_FILES" ]; then
    if echo "$STAGED_FILES" | xargs grep -lE "git push.*(anti-hallucination|AHG)|AHG_MODULE_PUSH=1" 2>/dev/null | head -1 | grep -q .; then
        emit_fail "staged files contain AHG push commands (RULE-ARCH-017: consumer agents cannot push to AHG upstream)"
    else
        emit_pass "no AHG push commands in staged files"
    fi
else
    emit_pass "no staged files to check"
fi

# 4. Check if .gitmodules is modified (ARCH-016)
if git diff --cached --name-only 2>/dev/null | grep -q ".gitmodules"; then
    emit_fail ".gitmodules is staged — removing AHG submodule is forbidden (RULE-ARCH-016)"
else
    emit_pass ".gitmodules not modified"
fi

# 5. Verify submodule still exists and AGENT_RULES.md is at platform root
if [ -d "guard" ] && [ -f "AGENT_RULES.md" ]; then
    emit_pass "guard submodule present, AGENT_RULES.md found at platform root"
elif [ -d "guard" ]; then
    echo "  [INFO] guard directory exists but AGENT_RULES.md not found (submodule may need init)"
else
    emit_fail "guard submodule missing (RULE-ARCH-016: AHG submodule is structural)"
fi

echo ""
echo "=== Summary ==="
echo "  Violations: $VIOLATIONS"
echo ""

if [ $VIOLATIONS -gt 0 ] && [ $HARD_MODE -eq 1 ]; then
    echo "RESULT: FAIL — AHG integrity violation detected."
    exit 1
elif [ $VIOLATIONS -gt 0 ]; then
    echo "RESULT: WARN — re-run with --hard to enforce."
    exit 0
else
    echo "RESULT: PASS — AHG integrity verified."
    exit 0
fi
