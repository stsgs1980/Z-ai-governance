#!/usr/bin/env bash
#
# RULE-LOOPS-005 — Loop detection (3 retries with same result = stop)
# Detects: worklog patterns suggesting repeated failed attempts
#
# Heuristic approach:
#   - Scan worklog.md for repeated identical file modifications
#   - If same file appears 3+ times in recent entries = possible loop
#   - If same error message appears 3+ times = definite loop
#
# Limitations:
#   - Worklog-based only (cannot track actual agent behavior)
#   - Relies on agent logging attempts honestly
#   - False positives if legitimate repeated work on same file
#
# Usage:
#   bash guard/scripts/check-no-loops.sh           # soft warn
#   bash guard/scripts/check-no-loops.sh --hard    # hard fail
#
# Exit codes:
#   0  no loop patterns detected
#   1  loop pattern detected AND --hard set
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

echo "=== RULE-LOOPS-005: loop detection (heuristic) ==="
echo "Mode: $([ $HARD_MODE -eq 1 ] && echo 'HARD' || echo 'SOFT')"
echo "Note: worklog-based. Checks for repeated file modifications."
echo ""

cd "$PLATFORM_DIR"

if [ ! -f "worklog.md" ]; then
    emit_pass "worklog.md not found — loop check skipped"
    echo "RESULT: PASS"
    exit 0
fi

WORKLOG=$(cat worklog.md 2>/dev/null || true)

# Split worklog into entries (separated by ---)
# Only check LAST 10 entries to avoid false positives from full history
ENTRIES=$(echo "$WORKLOG" | awk '/^---$/{n++} n>=1{print > "/tmp/zai-loop-entry-"n".txt"} END{print n}')

if [ -z "$ENTRIES" ] || [ "$ENTRIES" -eq 0 ]; then
    emit_pass "no worklog entries found"
    echo "RESULT: PASS"
    exit 0
fi

TOTAL_ENTRIES=$ENTRIES

# Only analyze last 10 entries (not entire history)
LAST_N=10
if [ "$TOTAL_ENTRIES" -gt "$LAST_N" ]; then
    # Extract last N entries into temp file
    RECENT_ENTRIES=$(tail -n "$((LAST_N * 30))" worklog.md 2>/dev/null || true)
    echo "Analyzing last $LAST_N entries (of $TOTAL_ENTRIES total)"
else
    RECENT_ENTRIES="$WORKLOG"
    echo "Analyzing all $TOTAL_ENTRIES entries"
fi

# Check for repeated file modifications across entries.
#
# Per-entry counting: a loop = same file appears in ERROR/FAIL context
# across 3+ SEPARATE worklog entries. A single verbose entry that
# mentions a file many times is ONE work session, not a loop.
#
# Algorithm:
#   1. Write RECENT_ENTRIES to a temp file
#   2. Pass temp file to awk
#   3. For each file, count in how many separate entries it appears
#   4. Flag if count >= 3
TMP_RECENT=$(mktemp 2>/dev/null || echo "/tmp/zai-no-loops-$$.tmp")
echo "$RECENT_ENTRIES" > "$TMP_RECENT"

FILE_LOOP_DETECTION=$(awk '
  BEGIN { entry = 0 }
  /^---$/ { entry++ }
  /[a-zA-Z0-9_/.-]+\.(js|ts|tsx|jsx|py|sh|go|rs|md|json|yml|yaml)/ {
    if (tolower($0) ~ /fail|error|broken|ошибка|не работает/) {
      n = split($0, parts, /[ \t,]+/)
      for (i = 1; i <= n; i++) {
        if (parts[i] ~ /[a-zA-Z0-9_/.-]+\.(js|ts|tsx|jsx|py|sh|go|rs|md|json|yml|yaml)$/) {
          files[parts[i]] = files[parts[i]] " " entry
        }
      }
    }
  }
  END {
    for (f in files) {
      n = split(files[f], entries, " ")
      seen_count = 0
      delete seen
      for (i = 1; i <= n; i++) {
        if (entries[i] != "" && !seen[entries[i]]) {
          seen[entries[i]] = 1
          seen_count++
        }
      }
      if (seen_count >= 3) {
        print seen_count " " f
      }
    }
  }
' "$TMP_RECENT" | sort -rn)

rm -f "$TMP_RECENT"

LOOP_FILES=""
if [ -n "$FILE_LOOP_DETECTION" ]; then
    while IFS= read -r line; do
        ENTRY_COUNT=$(echo "$line" | awk '{print $1}')
        FILE=$(echo "$line" | awk '{print $2}')
        LOOP_FILES="$LOOP_FILES\n  $FILE (in $ENTRY_COUNT separate entries)"
    done <<< "$FILE_LOOP_DETECTION"
fi

# Check for repeated error patterns
ERROR_REPEATS=$(echo "$RECENT_ENTRIES" | grep -iE "(fail|error|ошибка|не работает|broken)" | sort | uniq -c | sort -rn | head -5)
LOOP_ERRORS=""
if [ -n "$ERROR_REPEATS" ]; then
    while IFS= read -r line; do
        COUNT=$(echo "$line" | awk '{print $1}')
        if [ "$COUNT" -ge 3 ]; then
            MSG=$(echo "$line" | cut -d' ' -f2-)
            LOOP_ERRORS="$LOOP_ERRORS\n  \"$MSG\" ($COUNT times)"
        fi
    done <<< "$ERROR_REPEATS"
fi

echo "Worklog entries: $TOTAL_ENTRIES"
echo ""

# Report file loops
if [ -n "$LOOP_FILES" ]; then
    echo "Files mentioned 3+ times (possible loop):"
    echo -e "$LOOP_FILES"
    echo ""
    LOOP_COUNT=$(echo -e "$LOOP_FILES" | grep -c "." || echo "0")
    if [ "$LOOP_COUNT" -gt 0 ]; then
        msg="Same file(s) modified 3+ times — possible loop (RULE-LOOPS-005)"
        msg+=" — if stuck, ask for help instead of retrying"
        if [ $HARD_MODE -eq 1 ]; then
            emit_fail "$msg"
        else
            emit_warn "$msg"
        fi
    fi
else
    emit_pass "no file modified 3+ times"
fi

# Report error loops
if [ -n "$LOOP_ERRORS" ]; then
    echo "Repeated errors (possible loop):"
    echo -e "$LOOP_ERRORS"
    echo ""
    ERR_COUNT=$(echo -e "$LOOP_ERRORS" | grep -c "." || echo "0")
    if [ "$ERR_COUNT" -gt 0 ]; then
        msg="Same error repeated 3+ times — DEFINITE loop (RULE-LOOPS-005)"
        msg+=" — STOP and ask for help"
        if [ $HARD_MODE -eq 1 ]; then
            emit_fail "$msg"
        else
            emit_warn "$msg"
        fi
    fi
else
    emit_pass "no repeated error patterns"
fi

# Cleanup temp files
rm -f /tmp/zai-loop-entry-*.txt 2>/dev/null || true

echo ""
echo "=== Summary ==="
echo "  Violations: $VIOLATIONS"
echo ""

if [ $VIOLATIONS -gt 0 ] && [ $HARD_MODE -eq 1 ]; then
    echo "RESULT: FAIL — loop pattern detected. STOP and ask for help. (RULE-LOOPS-005)"
    exit 1
elif [ $VIOLATIONS -gt 0 ]; then
    echo "RESULT: WARN — re-run with --hard to enforce."
    exit 0
else
    echo "RESULT: PASS — no loop patterns detected."
    exit 0
fi
