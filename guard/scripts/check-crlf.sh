#!/usr/bin/env bash
#
# check-crlf.sh — Detect CRLF line endings in shell scripts
#
# Implements: R3 (CRLF detection in pre-commit)
# Why: bash on Linux fails silently on CRLF-only scripts. Windows tools
#      can introduce CRLF when copying/editing files.
#
# Heuristic:
#   - For each shell script, check for \r\n line endings
#   - FAIL if any \r found in any .sh file
#   - Excludes: .cmd, .bat, .ps1 (Windows-native files)
#
# Usage:
#   bash guard/scripts/check-crlf.sh           # soft warn
#   bash guard/scripts/check-crlf.sh --hard    # hard fail
#
# Exit codes:
#   0  no CRLF found
#   1  CRLF found AND --hard set
#   2  usage error

set -euo pipefail

HARD_MODE=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

for arg in "$@"; do
  case "$arg" in
    --help|-h) sed -n '2,18p' "$0"; exit 0 ;;
    --hard) HARD_MODE=1 ;;
    *) echo "Unknown flag: $arg"; exit 2 ;;
  esac
done

VIOLATIONS=0
CRLF_FILES=()
emit_pass() { echo "  [PASS] $1"; }
emit_fail() { echo "  [FAIL] $1"; VIOLATIONS=$((VIOLATIONS + 1)); }
emit_info() { echo "  [INFO] $1"; }

echo "=== check-crlf.sh: CRLF line ending detection ==="
echo "Mode: $([ $HARD_MODE -eq 1 ] && echo 'HARD' || echo 'SOFT')"
echo ""

cd "$PLATFORM_DIR"

# Files to check: shell scripts and husky hooks
# Excludes: .cmd, .bat, .ps1 (Windows-native, CRLF is correct)
PATTERNS=(
  "*.sh"
  ".husky/*"
  "guard/scripts/*.sh"
  "standards/scripts/*.sh"
  "bootstrap.sh"
  "scripts/save-work.sh"
  "scripts/status.sh"
)

FOUND_CRLF=0
for pattern in "${PATTERNS[@]}"; do
  # shellcheck disable=SC2086
  for f in $pattern; do
    [ -f "$f" ] || continue

    # Count CR characters (carriage return = \r)
    CR_COUNT=$(tr -cd '\r' < "$f" | wc -c | tr -d ' ')

    if [ "$CR_COUNT" -gt 0 ]; then
      CRLF_FILES+=("$f: $CR_COUNT CR chars")
      FOUND_CRLF=1
    fi
  done
done

if [ $FOUND_CRLF -eq 0 ]; then
  emit_pass "all shell scripts use LF line endings (no CRLF found)"
else
  emit_fail "CRLF line endings found in ${#CRLF_FILES[@]} file(s):"
  for entry in "${CRLF_FILES[@]}"; do
    echo "    $entry"
  done
  echo ""
  echo "  Fix: convert CRLF to LF"
  echo "    git config core.autocrlf false"
  echo "    for f in \$(git ls-files '*.sh' '*.bash' '.husky/*'); do"
  echo "      sed -i 's/\\r\$//' \"\$f\""
  echo "      git add \"\$f\""
  echo "    done"
fi

echo ""
echo "=== Summary ==="
echo "  Files scanned: $(find . -type f \( -name "*.sh" -o -path "./.husky/*" \) 2>/dev/null | wc -l | tr -d ' ')"
echo "  Files with CRLF: ${#CRLF_FILES[@]}"
echo "  Violations: $VIOLATIONS"
echo ""

if [ $VIOLATIONS -gt 0 ] && [ $HARD_MODE -eq 1 ]; then
  echo "RESULT: FAIL — CRLF detected. Run fix commands above."
  exit 1
elif [ $VIOLATIONS -gt 0 ]; then
  echo "RESULT: WARN — CRLF detected (soft mode)."
  exit 0
fi

echo "RESULT: PASS — all scripts use LF line endings."
exit 0
