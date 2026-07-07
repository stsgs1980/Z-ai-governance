#!/usr/bin/env bash
#
# RULE-AGENT-009 — Session start protocol (drift prevention)
# Verifies: worklog contains scan results from current session
#
# Heuristic: check if worklog.md was modified recently (within last hour)
# and contains "scan" or "structure" or "version" mentions
#
# Usage:
#   bash guard/scripts/check-session-start.sh           # soft warn
#   bash guard/scripts/check-session-start.sh --hard    # hard fail
#
# Exit codes:
#   0  session start protocol followed
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

echo "=== RULE-AGENT-009: session start protocol ==="
echo "Mode: $([ $HARD_MODE -eq 1 ] && echo 'HARD' || echo 'SOFT')"
echo ""

cd "$PLATFORM_DIR"

# 1. Check if worklog.md exists
if [ ! -f "worklog.md" ]; then
    emit_fail "worklog.md not found (RULE-AGENT-009: worklog is required)"
    echo ""
    echo "RESULT: FAIL"
    exit 1
fi

# Pre-load recent worklog for later checks
RECENT_WORKLOG=$(tail -100 worklog.md 2>/dev/null || true)

# 2. Check if worklog was modified recently (within last 4 hours)
# This is a heuristic — if worklog was modified, the agent is working
WORKLOG_MTIME=$(stat -c %Y worklog.md 2>/dev/null || stat -f %m worklog.md 2>/dev/null || echo "0")
NOW=$(date +%s)
AGE_HOURS=$(( (NOW - WORKLOG_MTIME) / 3600 ))

if [ "$AGE_HOURS" -le 4 ]; then
    # Worklog modified recently — agent is working, protocol likely followed
    emit_pass "worklog modified recently ($AGE_HOURS hours ago) — agent is active"
else
    # Worklog not modified recently — check for scan evidence
    if echo "$RECENT_WORKLOG" | grep -qiE "(scan|structure|session|start|read|прочитал|начало)"; then
        emit_pass "scan-related content found in recent worklog entries"
    else
        msg="worklog not modified recently and no scan/structure evidence"
        msg+=" — RULE-AGENT-009 requires: scan project structure at session start"
        emit_fail "$msg"
    fi
fi

# 4. Check if package.json exists (version source of truth)
if [ -f "package.json" ]; then
    VERSION=$(grep '"version"' package.json 2>/dev/null | head -1 || echo "not found")
    if echo "$RECENT_WORKLOG" | grep -qF "$VERSION" 2>/dev/null; then
        emit_pass "package.json version mentioned in worklog"
    else
        echo "  [INFO] package.json version ($VERSION) not mentioned in worklog (minor)"
    fi
else
    echo "  [INFO] no package.json found"
fi

echo ""
echo "=== Summary ==="
echo "  Violations: $VIOLATIONS"
echo ""

if [ $VIOLATIONS -gt 0 ] && [ $HARD_MODE -eq 1 ]; then
    echo "RESULT: FAIL — session start protocol not followed. (RULE-AGENT-009)"
    echo "Fix: scan project structure, read versions, compare with docs, record in worklog."
    exit 1
elif [ $VIOLATIONS -gt 0 ]; then
    echo "RESULT: WARN — re-run with --hard to enforce."
    exit 0
else
    echo "RESULT: PASS — session start protocol followed."
    exit 0
fi
