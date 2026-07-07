#!/usr/bin/env bash
#
# RULE-VERSION-013 — Version bump enforcement
# Detects: manual version changes in package.json / version files
#          that did not go through scripts/ahg.sh bump
#
# Usage:
#   bash guard/scripts/check-version-bump.sh           # soft warn
#   bash guard/scripts/check-version-bump.sh --hard    # hard fail
#
# Exit codes:
#   0  no unauthorized version changes
#   1  version changed without ahg.sh AND --hard set
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

echo "=== RULE-VERSION-013: version bump enforcement ==="
echo "Mode: $([ $HARD_MODE -eq 1 ] && echo 'HARD' || echo 'SOFT')"
echo ""

cd "$PLATFORM_DIR"

# Files that contain version numbers
VERSION_FILES="package.json standards/package.json guard/package.json"

for vf in $VERSION_FILES; do
    if [ ! -f "$vf" ]; then continue; fi

    # Check if this file is staged
    if ! git diff --cached --name-only -- "$vf" 2>/dev/null | grep -q .; then
        continue
    fi

    # Get the diff for version-related lines
    VERSION_DIFF=$(git diff --cached -- "$vf" 2>/dev/null | grep -E '^\+.*"version"' || true)
    OLD_VERSION=$(git diff --cached -- "$vf" 2>/dev/null | grep -E '^\-.*"version"' | head -1 || true)

    if [ -n "$VERSION_DIFF" ] && [ -n "$OLD_VERSION" ]; then
        # Check if bump.sh was also staged (meaning bump was done properly)
        BUMP_STAGED=$(git diff --cached --name-only -- guard/tools/bump.sh 2>/dev/null || true)
        if [ -z "$BUMP_STAGED" ]; then
            emit_fail "$vf: version changed ($OLD_VERSION -> $VERSION_DIFF) but guard/tools/bump.sh not in commit (RULE-VERSION-013: use 'bash guard/tools/bump.sh X.Y.Z')"
        else
            emit_pass "$vf: version changed via bump.sh"
        fi
    fi
done

# Also check standards directory version
STANDARDS_VERSION_FILE="standards/package.json"
if [ -f "$STANDARDS_VERSION_FILE" ]; then
    if git diff --cached --name-only -- "$STANDARDS_VERSION_FILE" 2>/dev/null | grep -q .; then
        VERSION_DIFF=$(git diff --cached -- "$STANDARDS_VERSION_FILE" 2>/dev/null | grep -E '^\+.*"version"' || true)
        if [ -n "$VERSION_DIFF" ]; then
            emit_fail "$STANDARDS_VERSION_FILE: version changed directly (RULE-VERSION-013: version updates must go through upstream)"
        fi
    fi
fi

# If no version files were changed, that's fine
if [ $VIOLATIONS -eq 0 ]; then
    emit_pass "no unauthorized version changes detected"
fi

echo ""
echo "=== Summary ==="
echo "  Violations: $VIOLATIONS"
echo ""

if [ $VIOLATIONS -gt 0 ] && [ $HARD_MODE -eq 1 ]; then
    echo "RESULT: FAIL — unauthorized version change. Use: bash guard/tools/bump.sh X.Y.Z (RULE-VERSION-013)"
    exit 1
elif [ $VIOLATIONS -gt 0 ]; then
    echo "RESULT: WARN — re-run with --hard to enforce."
    exit 0
else
    echo "RESULT: PASS — no version violations."
    exit 0
fi
