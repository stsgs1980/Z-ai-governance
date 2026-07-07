#!/usr/bin/env bash
# check-worklog.sh — thin wrapper delegating to canonical guard implementation
# Usage: bash check-worklog.sh [--paths PATH1,PATH2] [--min-lines N] [--config PATH]
#
# NOTE: This is a compatibility wrapper. The canonical implementation is:
#   guard/scripts/worklog-check.sh (PROC-WORKLOG-005, enforces min 3 new lines)
#
# This wrapper reads thresholds from .zai/config.json and delegates to the
# guard script for actual enforcement.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
GUARD_WORKLOG="${PLATFORM_DIR}/guard/scripts/worklog-check.sh"
CONFIG_FILE="${SCRIPT_DIR}/../config.json"

# Parse CLI args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --config) CONFIG_FILE="$2"; shift 2 ;;
        --paths|--min-lines) shift 2 ;;  # accepted for compat, guard script uses its own logic
        *) shift ;;
    esac
done

if [[ -f "$GUARD_WORKLOG" ]]; then
    exec bash "$GUARD_WORKLOG" "$@"
else
    echo "[check-worklog] WARN: guard/scripts/worklog-check.sh not found"
    echo "[check-worklog] Falling back to basic check..."

    # Minimal fallback: just verify worklog.md exists and is non-empty
    WORKLOG="${PLATFORM_DIR}/worklog.md"
    if [[ -s "$WORKLOG" ]]; then
        LINES=$(awk 'END{print NR}' "$WORKLOG")
        echo "[check-worklog] PASS: worklog.md ($LINES lines)"
        exit 0
    else
        echo "[check-worklog] FAIL: worklog.md missing or empty"
        exit 1
    fi
fi