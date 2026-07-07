#!/usr/bin/env bash
#
# check-snapshot-sync.sh — ID graph snapshot drift detection
#
# Implements: STRUCT-007 + ARCH consistency
# Catches: uncommitted graph changes (new ID, new Related: edge, removed ID)
#
# Why this exists:
#   - Adding a new ZAI- skill or STD- standard changes the ID graph
#   - The baseline snapshot (standards/_snapshots/id-graph-baseline.json) must
#     be updated to match
#   - Without this check, the drift only surfaces in CI (too late)
#   - With this check, the developer is alerted at commit time
#
# Workflow:
#   1. Pre-commit runs verify-id-graph.js --compare=baseline
#   2. If graph changed: FAIL with clear message + update command
#   3. If graph unchanged: PASS
#
# To intentionally update the baseline (after adding a new ID):
#   cd standards && node scripts/verify-id-graph.js --update-snapshot --compare=_snapshots/id-graph-baseline.json
#   git add _snapshots/id-graph-baseline.json
#   git commit
#
# Usage:
#   bash guard/scripts/check-snapshot-sync.sh           # soft warn
#   bash guard/scripts/check-snapshot-sync.sh --hard    # hard fail
#
# Exit codes:
#   0  snapshot matches current graph
#   1  snapshot mismatch AND --hard set
#   2  usage error or missing dependencies

set -euo pipefail

HARD_MODE=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SNAPSHOT="standards/_snapshots/id-graph-baseline.json"

for arg in "$@"; do
  case "$arg" in
    --help|-h) sed -n '2,25p' "$0"; exit 0 ;;
    --hard) HARD_MODE=1 ;;
    *) echo "Unknown flag: $arg"; exit 2 ;;
  esac
done

VIOLATIONS=0
emit_pass() { echo "  [PASS] $1"; }
emit_fail() { echo "  [FAIL] $1"; VIOLATIONS=$((VIOLATIONS + 1)); }
emit_info() { echo "  [INFO] $1"; }

echo "=== check-snapshot-sync.sh: ID graph snapshot drift ==="
echo "Mode: $([ $HARD_MODE -eq 1 ] && echo 'HARD' || echo 'SOFT')"
echo ""

cd "$PLATFORM_DIR"

# Pre-flight: node must be available
# Try multiple methods since git bash on Windows can be finicky
NODE_BIN=""
if command -v node >/dev/null 2>&1; then
  NODE_BIN="$(command -v node)"
elif which node >/dev/null 2>&1; then
  NODE_BIN="$(which node)"
elif [ -x "/mnt/c/Program Files/nodejs/node.exe" ]; then
  NODE_BIN="/mnt/c/Program Files/nodejs/node.exe"
elif [ -x "/c/Program Files/nodejs/node.exe" ]; then
  NODE_BIN="/c/Program Files/nodejs/node.exe"
fi

if [ -z "$NODE_BIN" ]; then
  emit_info "node not found — skipping snapshot check (CI will catch this)"
  echo ""
  echo "=== Summary ==="
  echo "  Status: skipped (no node)"
  exit 0
fi

# Pre-flight: snapshot file must exist
if [ ! -f "$SNAPSHOT" ]; then
  emit_fail "snapshot file not found: $SNAPSHOT"
  echo ""
  echo "=== Summary ==="
  echo "  Violations: $VIOLATIONS"
  echo ""
  echo "Fix: generate the baseline:"
  echo "  cd standards && node scripts/verify-id-graph.js --snapshot=_snapshots/id-graph-baseline.json"
  exit 1
fi

# Pre-flight: standards submodule must be checked out
if [ ! -f "standards/scripts/verify-id-graph.js" ]; then
  emit_info "standards submodule not checked out — skipping snapshot check"
  echo ""
  echo "=== Summary ==="
  echo "  Status: skipped (no submodule)"
  exit 0
fi

# Run compare
echo "Running: $NODE_BIN standards/scripts/verify-id-graph.js --compare=$SNAPSHOT"
echo ""

COMPARE_OUTPUT=$("$NODE_BIN" standards/scripts/verify-id-graph.js --compare="$SNAPSHOT" 2>&1) || COMPARE_EXIT=$?
COMPARE_EXIT=${COMPARE_EXIT:-0}

if [ "$COMPARE_EXIT" -eq 0 ]; then
  emit_pass "snapshot matches current ID graph"
  echo ""
  echo "$COMPARE_OUTPUT" | grep -E "^(IDs|Related|Aligned|Repos)" | head -5 || true
elif [ "$COMPARE_EXIT" -eq 1 ]; then
  # Mismatch detected
  # Parse the diff to give a useful error message
  CURRENT_IDS=$(echo "$COMPARE_OUTPUT" | grep -oE "IDs extracted: [0-9]+" | head -1 | grep -oE "[0-9]+" || echo "?")
  BASELINE_IDS=$("$NODE_BIN" -e "const j=require('${PWD}/${SNAPSHOT}');console.log(j.summary && j.summary.ids_extracted || '?')" 2>/dev/null || echo "?")
  
  emit_fail "ID graph snapshot is out of sync"
  emit_info "  baseline: $BASELINE_IDS IDs"
  emit_info "  current:  $CURRENT_IDS IDs"
  echo ""
  echo "  This usually means you added/removed an ID or Related: edge without"
  echo "  regenerating the baseline snapshot."
  echo ""
  echo "  To fix (run from platform root):"
  echo "    cd standards"
  echo "    node scripts/verify-id-graph.js --update-snapshot --compare=$SNAPSHOT"
  echo "    git add $SNAPSHOT"
  echo "    git commit"
  echo ""
  echo "  Diff summary:"
  echo "$COMPARE_OUTPUT" | grep -E "^[+-]" | head -20 || true
else
  emit_fail "verify-id-graph.js exited with code $COMPARE_EXIT"
  echo "$COMPARE_OUTPUT" | tail -10
fi

echo ""
echo "=== Summary ==="
echo "  Snapshot: $SNAPSHOT"
echo "  Violations: $VIOLATIONS"
echo ""

if [ $VIOLATIONS -gt 0 ] && [ $HARD_MODE -eq 1 ]; then
  echo "RESULT: FAIL — snapshot out of sync. Update the baseline before committing."
  exit 1
elif [ $VIOLATIONS -gt 0 ]; then
  echo "RESULT: WARN — snapshot drift detected (soft mode; CI will block this)"
  exit 0
fi

echo "RESULT: PASS — snapshot is in sync."
exit 0
