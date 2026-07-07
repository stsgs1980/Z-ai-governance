#!/usr/bin/env bash
#
# check-changelog-sync.sh — CHANGELOG freshness check
#
# Detects when CHANGELOG.md hasn't been updated despite significant new work.
#
# Why this exists:
#   - CHANGELOG is a public document (Keep a Changelog format)
#   - Users rely on it to know what changed between versions
#   - Easy to forget to update when focused on code
#   - Stale CHANGELOG = users don't know about new features/fixes
#
# Heuristic:
#   - Find last version entry in CHANGELOG (e.g., "## [1.2.0] - 2026-07-06")
#   - Get date of HEAD commit
#   - If (HEAD_date - last_version_date) > 1 day -> warn
#   - List commits since last CHANGELOG version (for context)
#
# Workflow:
#   1. Run this script at commit time
#   2. If it warns, update CHANGELOG.md before committing
#   3. Or run on a schedule (weekly) to detect drift
#
# Usage:
#   bash guard/scripts/check-changelog-sync.sh           # soft warn
#   bash guard/scripts/check-changelog-sync.sh --hard    # hard fail
#   bash guard/scripts/check-changelog-sync.sh --max-age=7  # custom threshold (days)
#
# Exit codes:
#   0  CHANGELOG is fresh (< threshold days old)
#   1  CHANGELOG is stale AND --hard set
#   2  usage error or missing dependencies

set -euo pipefail

HARD_MODE=0
MAX_AGE_DAYS=1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CHANGELOG="CHANGELOG.md"

for arg in "$@"; do
  case "$arg" in
    --help|-h) sed -n '2,30p' "$0"; exit 0 ;;
    --hard) HARD_MODE=1 ;;
    --max-age=*)
      MAX_AGE_DAYS="${arg#--max-age=}"
      if ! [[ "$MAX_AGE_DAYS" =~ ^[0-9]+$ ]]; then
        echo "ERROR: --max-age must be a positive integer"
        exit 2
      fi
      ;;
    *) echo "Unknown flag: $arg"; exit 2 ;;
  esac
done

VIOLATIONS=0
emit_pass() { echo "  [PASS] $1"; }
emit_fail() { echo "  [FAIL] $1"; VIOLATIONS=$((VIOLATIONS + 1)); }
emit_info() { echo "  [INFO] $1"; }

echo "=== check-changelog-sync.sh: CHANGELOG freshness ==="
echo "Mode: $([ $HARD_MODE -eq 1 ] && echo 'HARD' || echo 'SOFT')"
echo "Max age: $MAX_AGE_DAYS day(s)"
echo ""

cd "$PLATFORM_DIR"

# Pre-flight: CHANGELOG.md must exist
if [ ! -f "$CHANGELOG" ]; then
  emit_fail "CHANGELOG.md not found"
  echo ""
  echo "=== Summary ==="
  echo "  Violations: $VIOLATIONS"
  exit 1
fi

# Find last version entry: "## [X.Y.Z] - YYYY-MM-DD"
LAST_VERSION_LINE=$(grep -E "^## \[[0-9]+\.[0-9]+\.[0-9]+\] - [0-9]{4}-[0-9]{2}-[0-9]{2}" "$CHANGELOG" | head -1 || echo "")

if [ -z "$LAST_VERSION_LINE" ]; then
  emit_fail "no versioned entry found in CHANGELOG.md (looking for: ## [X.Y.Z] - YYYY-MM-DD)"
  echo ""
  echo "=== Summary ==="
  echo "  Violations: $VIOLATIONS"
  exit 1
fi

LAST_VERSION=$(echo "$LAST_VERSION_LINE" | sed -E 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\] - ([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/')
LAST_DATE=$(echo "$LAST_VERSION_LINE" | sed -E 's/^## \[[0-9]+\.[0-9]+\.[0-9]+\] - ([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/')
HEAD_DATE=$(date -u +%Y-%m-%d)
HEAD_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

emit_info "Last version in CHANGELOG: $LAST_VERSION ($LAST_DATE)"
emit_info "HEAD commit: $HEAD_SHA ($HEAD_DATE)"

# Calculate days between dates
if command -v python >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1; then
  PY=$(command -v python3 || command -v python)
  DAYS_SINCE=$("$PY" -c "from datetime import date; d1=date.fromisoformat('$LAST_DATE'); d2=date.fromisoformat('$HEAD_DATE'); print((d2-d1).days)" 2>/dev/null || echo "0")
elif command -v node >/dev/null 2>&1 || [ -x "/mnt/c/Program Files/nodejs/node.exe" ] || [ -x "/c/Program Files/nodejs/node.exe" ]; then
  NODE_BIN="$(command -v node 2>/dev/null || echo "/mnt/c/Program Files/nodejs/node.exe")"
  DAYS_SINCE=$("$NODE_BIN" -e "const d1=new Date('$LAST_DATE'); const d2=new Date('$HEAD_DATE'); console.log(Math.round((d2-d1)/86400000))" 2>/dev/null || echo "0")
else
  emit_info "no python or node — skipping age calculation"
  DAYS_SINCE=0
fi

emit_info "Days since last CHANGELOG update: $DAYS_SINCE"
echo ""

# Count commits since last CHANGELOG update (by date, not by content)
COMMITS_SINCE=$(git log --oneline --since="$LAST_DATE" 2>/dev/null | wc -l | tr -d ' ')

if [ "$DAYS_SINCE" -le "$MAX_AGE_DAYS" ]; then
  emit_pass "CHANGELOG is fresh (< $MAX_AGE_DAYS day(s) old)"
elif [ "$COMMITS_SINCE" -lt 3 ]; then
  # Few commits and slightly stale — not a real violation
  emit_info "CHANGELOG is $DAYS_SINCE day(s) old but only $COMMITS_SINCE commits since — within tolerance"
else
  emit_fail "CHANGELOG is $DAYS_SINCE day(s) old, $COMMITS_SINCE commits since last version"
  echo ""
  echo "  Recent commits since $LAST_DATE ($COMMITS_SINCE total):"
  git log --oneline --since="$LAST_DATE" 2>/dev/null | head -10 | sed 's/^/    /'
  echo ""
  echo "  To fix:"
  echo "    1. Bump version in CHANGELOG.md (e.g., $LAST_VERSION -> $LAST_VERSION + minor/patch)"
  echo "    2. Add '## [NEW_VERSION] - $HEAD_DATE' section with Added/Changed/Fixed entries"
  echo "    3. Use the commits above as a starting point"
  echo "    4. Reference commits in CHANGELOG entries (e.g., 'fixes bug introduced in 1.2.0')"
fi

echo ""
echo "=== Summary ==="
echo "  Last version: $LAST_VERSION ($LAST_DATE)"
echo "  Days since update: $DAYS_SINCE"
echo "  Commits since update: $COMMITS_SINCE"
echo "  Violations: $VIOLATIONS"
echo ""

if [ $VIOLATIONS -gt 0 ] && [ $HARD_MODE -eq 1 ]; then
  echo "RESULT: FAIL — CHANGELOG.md is stale. Update before committing."
  exit 1
elif [ $VIOLATIONS -gt 0 ]; then
  echo "RESULT: WARN — CHANGELOG.md is stale (soft mode; CI will block this)"
  exit 0
fi

echo "RESULT: PASS — CHANGELOG.md is fresh."
exit 0
