#!/usr/bin/env bash
#
# RULE-ENV-008 — Sandbox verification (no fake setup)
# Verifies: clone path, dev server, HMR status, editing location
#
# Usage:
#   bash guard/scripts/check-sandbox-env.sh           # soft warn
#   bash guard/scripts/check-sandbox-env.sh --hard    # hard fail
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

echo "=== RULE-ENV-008: sandbox verification ==="
echo "Mode: $([ $HARD_MODE -eq 1 ] && echo 'HARD' || echo 'SOFT')"
echo ""

# 1. Verify clone path is /home/z/my-project/ (sandbox only)
# Skip this check if not in a sandbox environment
if [ -d "/home/z" ]; then
    REAL_PATH=$(realpath "$PLATFORM_DIR" 2>/dev/null || echo "$PLATFORM_DIR")
    if echo "$REAL_PATH" | grep -q "/home/z/my-project"; then
        emit_pass "clone path is correct: $REAL_PATH"
    else
        emit_fail "clone path is NOT /home/z/my-project/: $REAL_PATH (RULE-ENV-008: code outside sandbox root)"
    fi
else
    echo "  [INFO] not in sandbox environment — clone path check skipped"
fi

# 2. Verify dev server is managed by sandbox (not manually started)
# Skip entirely if this repo is not a Next.js project (no next dependency).
IS_NEXT_PROJECT=0
if [ -f "$PLATFORM_DIR/package.json" ] && grep -q '"next"' "$PLATFORM_DIR/package.json" 2>/dev/null; then
    IS_NEXT_PROJECT=1
fi

if [ "$IS_NEXT_PROJECT" -eq 0 ]; then
    echo "  [INFO] not a Next.js project — dev server check skipped"
elif pgrep -f ".zscripts/dev.sh" >/dev/null 2>&1; then
    emit_pass "dev server managed by sandbox (.zscripts/dev.sh running)"
elif pgrep -f "next dev" >/dev/null 2>&1; then
    emit_fail "detected manual 'next dev' — sandbox manages dev server via .zscripts/dev.sh (RULE-ENV-008)"
else
    # No dev server running — not a violation, just info
    echo "  [INFO] no dev server running (not a violation)"
fi

# 3. Verify HMR is working (not 500)
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/ 2>/dev/null | grep -q "200"; then
    emit_pass "HMR returns 200 (working)"
elif curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/ 2>/dev/null | grep -q "500"; then
    emit_fail "HMR returns 500 — broken code, not working (RULE-ENV-008)"
else
    echo "  [INFO] dev server not responding (not running or different port)"
fi

# 4. Verify git config core.fileMode is false (sandbox standard, skip on CI)
if [ -z "${CI:-}" ]; then
    FILE_MODE=$(git -C "$PLATFORM_DIR" config core.fileMode 2>/dev/null || echo "true")
    if [ "$FILE_MODE" = "false" ]; then
        emit_pass "core.fileMode=false (sandbox standard)"
    else
        emit_fail "core.fileMode is not false (RULE-ENV-008: run 'git config core.fileMode false')"
    fi
else
    echo "  [INFO] running in CI — core.fileMode check skipped"
fi

echo ""
echo "=== Summary ==="
echo "  Violations: $VIOLATIONS"
echo ""

if [ $VIOLATIONS -gt 0 ] && [ $HARD_MODE -eq 1 ]; then
    echo "RESULT: FAIL — sandbox verification failed. (RULE-ENV-008)"
    exit 1
elif [ $VIOLATIONS -gt 0 ]; then
    echo "RESULT: WARN — re-run with --hard to enforce."
    exit 0
else
    echo "RESULT: PASS — sandbox environment verified."
    exit 0
fi
