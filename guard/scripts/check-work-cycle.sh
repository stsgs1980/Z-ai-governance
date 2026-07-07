#!/usr/bin/env bash
#
# RULE-STRUCT-007 — Work structure cycle check
# Detects: commits without corresponding worklog updates (violates Read -> Plan -> Execute -> Record -> Commit cycle)
#
# The full STRUCT-007 cycle is LLM-judgment only (cannot detect "did agent read
# AGENT_RULES.md?" or "did agent plan the step?"). This script catches the
# post-hoc artifact: was the worklog updated for this commit?
#
# Heuristic:
#   - For each recent commit (last 10), check if worklog.md was touched
#     - in the same commit, OR
#     - in the commit immediately before
#   - If 2+ consecutive commits have no worklog touch = cycle violation
#
# Why this matters:
#   - STRUCT-007 step 4: "Record in worklog" — every commit should be logged
#   - Catches agents that commit code without documenting
#   - Catches worklog drift (commits accumulating without trace)
#
# Limitations:
#   - Cannot verify "Read" or "Plan" steps (those need LLM judgment)
#   - May false-positive on chore-only commits (e.g., typo fixes, dep bumps)
#   - May false-negative on worklog entries that don't mention the commit
#
# Usage:
#   bash guard/scripts/check-work-cycle.sh           # soft warn
#   bash guard/scripts/check-work-cycle.sh --hard    # hard fail
#
# Exit codes:
#   0  no cycle violations detected
#   1  cycle violation detected AND --hard set
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
emit_info() { echo "  [INFO] $1"; }

echo "=== RULE-STRUCT-007: work structure cycle ==="
echo "Mode: $([ $HARD_MODE -eq 1 ] && echo 'HARD' || echo 'SOFT')"
echo ""

cd "$PLATFORM_DIR"

# Check we are in a git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  emit_fail "not in a git repository (RULE-STRUCT-007 needs git log)"
  echo ""
  echo "=== Summary ==="
  echo "  Violations: $VIOLATIONS"
  exit 1
fi

# How many commits to check
# Lookback of 5 balances: catching real drift (recent) vs. historical noise.
# Historical drift from before this rule was added will be ignored once
# 5+ new commits land. For initial bootstrap, use --no-verify.
LOOKBACK=5

# Get commits with author info (so we can skip bot commits)
# Format: <sha> | <author>
COMMITS=$(git log --format="%H | %ae" -n "$LOOKBACK" 2>/dev/null || echo "")

if [ -z "$COMMITS" ]; then
  emit_info "no commits to check (empty repo)"
  echo ""
  echo "=== Summary ==="
  echo "  Violations: $VIOLATIONS"
  exit 0
fi

COMMIT_COUNT=$(echo "$COMMITS" | wc -l | tr -d ' ')

# Bot author patterns to skip (auto-generated commits, not human work)
# These don't need worklog entries - they're CI artifacts.
BOT_PATTERNS="github-actions\[bot\]|noreply\.github\.com$|.*\[bot\]@.*"

# Count commits where worklog.md is NOT in the commit's files
# We check both: (a) worklog in this commit, (b) worklog in previous commit
UNLOGGED_RUN=0
MAX_UNLOGGED=0
TOTAL_UNLOGGED=0
SKIPPED_BOT=0

# Walk commits from oldest to newest (reverse the list)
REVERSED=$(echo "$COMMITS" | tac)
PREV_TOUCHED_WORKLOG=0

while IFS= read -r line; do
  [ -z "$line" ] && continue
  SHA=$(echo "$line" | awk -F' \\| ' '{print $1}')
  AUTHOR=$(echo "$line" | awk -F' \\| ' '{print $2}')

  # Skip bot commits (CI auto-exports, automated commits)
  if echo "$AUTHOR" | grep -qE "$BOT_PATTERNS"; then
    SKIPPED_BOT=$((SKIPPED_BOT + 1))
    # Bot commits don't reset the unlogged run (they don't have worklog anyway,
    # but they're not "human drift" — they reset the run counter as if they
    # were a "touched" commit because they represent expected automation).
    PREV_TOUCHED_WORKLOG=1
    continue
  fi

  # Check if worklog.md is in this commit
  if git show --name-only --format= "$SHA" 2>/dev/null | grep -q "^worklog.md$"; then
    CURRENT_TOUCHED=1
  else
    CURRENT_TOUCHED=0
  fi

  # Unlogged if neither this commit nor the previous touched worklog
  if [ "$CURRENT_TOUCHED" -eq 0 ] && [ "$PREV_TOUCHED_WORKLOG" -eq 0 ]; then
    UNLOGGED_RUN=$((UNLOGGED_RUN + 1))
    TOTAL_UNLOGGED=$((TOTAL_UNLOGGED + 1))
    if [ "$UNLOGGED_RUN" -gt "$MAX_UNLOGGED" ]; then
      MAX_UNLOGGED=$UNLOGGED_RUN
    fi
  else
    UNLOGGED_RUN=0
  fi

  PREV_TOUCHED_WORKLOG=$CURRENT_TOUCHED
done <<< "$REVERSED"

# Report
if [ "$TOTAL_UNLOGGED" -eq 0 ]; then
  emit_pass "all $COMMIT_COUNT recent commits accompanied by worklog touch"
elif [ "$MAX_UNLOGGED" -ge 2 ]; then
  emit_fail "$TOTAL_UNLOGGED/$COMMIT_COUNT commits without worklog (max run: $MAX_UNLOGGED consecutive) — STRUCT-007 step 4 violated"
else
  emit_info "$TOTAL_UNLOGGED/$COMMIT_COUNT commits without worklog (max run: $MAX_UNLOGGED) — within tolerance"
fi

echo ""
echo "=== Summary ==="
echo "  Commits checked: $COMMIT_COUNT"
echo "  Bot commits skipped: $SKIPPED_BOT"
echo "  Unlogged commits: $TOTAL_UNLOGGED"
echo "  Max consecutive unlogged: $MAX_UNLOGGED"
echo "  Violations: $VIOLATIONS"
echo ""

if [ $VIOLATIONS -gt 0 ] && [ $HARD_MODE -eq 1 ]; then
  echo "RESULT: FAIL — work cycle violation detected. (RULE-STRUCT-007)"
  echo "Fix: ensure every commit is preceded by a worklog.md update (STRUCT-007 step 4)."
  exit 1
elif [ $VIOLATIONS -gt 0 ]; then
  echo "RESULT: WARN — work cycle drift detected. (RULE-STRUCT-007)"
  exit 0
fi

echo "RESULT: PASS — work cycle is healthy. (RULE-STRUCT-007)"
exit 0
