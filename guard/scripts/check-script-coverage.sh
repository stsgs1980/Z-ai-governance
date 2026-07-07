#!/usr/bin/env bash
#
# check-script-coverage.sh — Verify pre-commit and CI run the same scripts
#
# Catches: drift between pre-commit hook and CI workflow
# Example: someone adds check-X.sh to pre-commit but forgets CI
#
# Heuristic:
#   1. Extract script names from .husky/pre-commit (echo lines)
#   2. Extract script names from .github/workflows/*.yml (for loop)
#   3. Compare lists — warn if mismatch
#
# Usage:
#   bash guard/scripts/check-script-coverage.sh           # soft warn
#   bash guard/scripts/check-script-coverage.sh --hard    # hard fail
#
# Exit codes:
#   0  coverage matches
#   1  coverage mismatch AND --hard set
#   2  usage error

set -euo pipefail

HARD_MODE=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PRE_COMMIT=".husky/pre-commit"
CI_DIR=".github/workflows"

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
emit_info() { echo "  [INFO] $1"; }

echo "=== check-script-coverage.sh: pre-commit vs CI sync ==="
echo "Mode: $([ $HARD_MODE -eq 1 ] && echo 'HARD' || echo 'SOFT')"
echo ""

cd "$PLATFORM_DIR"

# Extract check-*.sh names from pre-commit (echo lines like "check-foo.sh (RULE-X)")
if [ ! -f "$PRE_COMMIT" ]; then
  emit_fail "pre-commit hook not found: $PRE_COMMIT"
  exit 1
fi
PRE_COMMIT_SCRIPTS=$(grep -oE "check-[a-z-]+\.sh" "$PRE_COMMIT" 2>/dev/null | sort -u)
PRE_COMMIT_COUNT=$(echo "$PRE_COMMIT_SCRIPTS" | wc -l | tr -d ' ')

emit_info "Pre-commit scripts: $PRE_COMMIT_COUNT"
echo "$PRE_COMMIT_SCRIPTS" | sed 's/^/    /'
echo ""

# Extract check-*.sh names from CI workflows (for loop with guard/scripts/check-X)
if [ ! -d "$CI_DIR" ]; then
  emit_info "no .github/workflows/ — skipping CI check"
  exit 0
fi

CI_SCRIPTS=$(grep -hoE "check-[a-z-]+\.sh" "$CI_DIR"/*.yml 2>/dev/null | sort -u)
CI_COUNT=$(echo "$CI_SCRIPTS" | wc -l | tr -d ' ')

emit_info "CI scripts: $CI_COUNT"
echo "$CI_SCRIPTS" | sed 's/^/    /'
echo ""

# Compare
IN_PRE_NOT_CI=$(comm -23 <(echo "$PRE_COMMIT_SCRIPTS") <(echo "$CI_SCRIPTS"))
IN_CI_NOT_PRE=$(comm -13 <(echo "$PRE_COMMIT_SCRIPTS") <(echo "$CI_SCRIPTS"))

if [ -z "$IN_PRE_NOT_CI" ] && [ -z "$IN_CI_NOT_PRE" ]; then
  emit_pass "pre-commit and CI run identical script sets"
elif [ -z "$IN_CI_NOT_PRE" ]; then
  # Pre-commit has extras that CI doesn't run
  emit_fail "Pre-commit has scripts that CI does NOT run:"
  echo "$IN_PRE_NOT_CI" | sed 's/^/    /'
  echo ""
  echo "  Fix: add missing scripts to .github/workflows/verify-id-graph.yml for loop"
else
  emit_fail "Drift detected between pre-commit and CI:"
  if [ -n "$IN_PRE_NOT_CI" ]; then
    echo "  In pre-commit but NOT in CI:"
    echo "$IN_PRE_NOT_CI" | sed 's/^/    /'
  fi
  if [ -n "$IN_CI_NOT_PRE" ]; then
    echo "  In CI but NOT in pre-commit:"
    echo "$IN_CI_NOT_PRE" | sed 's/^/    /'
  fi
fi

echo ""
echo "=== Summary ==="
echo "  Pre-commit scripts: $PRE_COMMIT_COUNT"
echo "  CI scripts: $CI_COUNT"
echo "  Violations: $VIOLATIONS"
echo ""

if [ $VIOLATIONS -gt 0 ] && [ $HARD_MODE -eq 1 ]; then
  echo "RESULT: FAIL — pre-commit and CI coverage drift detected."
  exit 1
elif [ $VIOLATIONS -gt 0 ]; then
  echo "RESULT: WARN — coverage drift (soft mode; review and align)."
  exit 0
fi

echo "RESULT: PASS — pre-commit and CI coverage aligned."
exit 0
