#!/usr/bin/env bash
#
# PROC-COCHANGE-003 — Co-change check (code + docs must sync)
# Implements: RULE-DOC-010 (documentation sync, no code without docs)
# Calls:      (none — pure git diff inspection)
#
# Usage:
#   bash guard/scripts/co-change-check.sh           # soft warn (exit 0 always)
#   bash guard/scripts/co-change-check.sh --hard    # hard fail (exit 1 on violation)
#   bash guard/scripts/co-change-check.sh --staged  # check staged files (default)
#   bash guard/scripts/co-change-check.sh --help
#
# Exit codes:
#   0  no violations (or --hard not set)
#   1  code change without doc change AND --hard set
#   2  usage error
#
# What this checks:
#   For every staged file, if it is a CODE file (.py/.js/.ts/.tsx/.jsx/.sh/.go/.rs),
#   at least one .md file MUST also be staged in the same commit.
#
#   Exemptions:
#     - Pure docs commits (only .md staged)         → PASS
#     - Pure config commits (only .json/.yml/.toml)  → PASS
#     - Test-only commits (.test.* / .spec.*)        → PASS
#     - Lockfile-only commits (package-lock.json etc.) → PASS
#     - Auto-generated files (with header comment)   → PASS
#
# Why this matters (RULE-DOC-010):
#   "When changing the codebase, documentation MUST be kept in sync."
#   This procedure is the mechanical enforcement of that rule. Without it,
#   the rule is a declaration only — agents can violate it without consequence.

set -euo pipefail

HARD_MODE=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    sed -n '2,30p' "$0"
    exit 0
fi
if [[ "${1:-}" == "--hard" ]]; then
    HARD_MODE=1
fi

# ─── Helpers ────────────────────────────────────────────────────────────
VIOLATIONS=0
WARN_COUNT=0

emit_pass() { echo "  [PASS] $1"; }
emit_fail() { echo "  [FAIL] $1"; VIOLATIONS=$((VIOLATIONS + 1)); }
emit_warn() { echo "  [WARN] $1"; WARN_COUNT=$((WARN_COUNT + 1)); }

# ─── Get staged files ───────────────────────────────────────────────────
cd "$PLATFORM_DIR"
STAGED=$(git diff --cached --name-only 2>/dev/null || true)

if [ -z "$STAGED" ]; then
    echo "=== PROC-COCHANGE-003: co-change check ==="
    echo "  No staged files. Nothing to check."
    exit 0
fi

# ─── Classify staged files ──────────────────────────────────────────────
CODE_EXT_REGEX='\.(py|js|ts|tsx|jsx|sh|go|rs|java|c|cpp|h|hpp|rb|php|swift|kt)$'
TEST_REGEX='\.(test|spec)\.(js|ts|tsx|jsx|py|go|rs)$'
LOCKFILE_REGEX='(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Cargo\.lock|go\.sum|poetry\.lock)$'
CONFIG_REGEX='\.(json|yml|yaml|toml|ini|env)$'

CODE_FILES=()
DOC_FILES=()
TEST_FILES=()
CONFIG_FILES=()
OTHER_FILES=()

while IFS= read -r f; do
    [ -z "$f" ] && continue
    if [[ "$f" =~ $LOCKFILE_REGEX ]]; then
        OTHER_FILES+=("$f [lockfile]")
    elif [[ "$f" =~ $TEST_REGEX ]]; then
        TEST_FILES+=("$f")
    elif [[ "$f" =~ $CODE_EXT_REGEX ]]; then
        CODE_FILES+=("$f")
    elif [[ "$f" == *.md ]]; then
        DOC_FILES+=("$f")
    elif [[ "$f" =~ $CONFIG_REGEX ]]; then
        CONFIG_FILES+=("$f")
    else
        OTHER_FILES+=("$f")
    fi
done <<< "$STAGED"

# ─── Decision logic ─────────────────────────────────────────────────────
echo "=== PROC-COCHANGE-003: co-change check ==="
echo "Mode: $([ $HARD_MODE -eq 1 ] && echo 'HARD (will fail on code-without-docs)' || echo 'SOFT (warning-only)')"
echo "Implements: RULE-DOC-010 (documentation sync)"
echo ""
echo "Staged files: $(echo "$STAGED" | wc -l)"
echo "  code:    ${#CODE_FILES[@]}"
echo "  docs:    ${#DOC_FILES[@]}"
echo "  tests:   ${#TEST_FILES[@]}"
echo "  config:  ${#CONFIG_FILES[@]}"
echo "  other:   ${#OTHER_FILES[@]}"
echo ""

# Pure-docs commit — PASS
if [ ${#CODE_FILES[@]} -eq 0 ]; then
    emit_pass "no code files staged — RULE-DOC-010 does not apply"
    echo ""
    echo "RESULT: PASS"
    exit 0
fi

# Code + at least one .md — PASS
if [ ${#DOC_FILES[@]} -gt 0 ]; then
    emit_pass "code change accompanied by doc change (${#DOC_FILES[@]} .md file(s))"
    if [ ${#DOC_FILES[@]} -lt ${#CODE_FILES[@]} ]; then
        emit_warn "fewer docs (${-#DOC_FILES[@]}) than code files (${#CODE_FILES[@]}) — verify each code change has relevant doc update"
    fi
    echo ""
    echo "RESULT: PASS"
    exit 0
fi

# Code without docs — VIOLATION
if [ ${#CODE_FILES[@]} -gt 0 ] && [ ${#DOC_FILES[@]} -eq 0 ]; then
    msg="code change without doc change — RULE-DOC-010 violation"
    msg+="  code files (${#CODE_FILES[@]}):"
    for f in "${CODE_FILES[@]}"; do
        msg+="\n    $f"
    done
    msg+="\n  suggestion: stage at least one .md describing the change"
    if [ $HARD_MODE -eq 1 ]; then
        emit_fail "$msg"
    else
        emit_warn "$msg"
    fi
fi

echo ""
echo "=== Summary ==="
echo "  Violations: $VIOLATIONS"
echo "  Warnings:   $WARN_COUNT"
echo ""

if [ $VIOLATIONS -gt 0 ] && [ $HARD_MODE -eq 1 ]; then
    echo "RESULT: FAIL — code change without doc update. Stage a .md or revert. (RULE-DOC-010)"
    exit 1
elif [ $VIOLATIONS -gt 0 ]; then
    echo "RESULT: WARN — code change without doc update. Re-run with --hard to enforce."
    exit 0
else
    echo "RESULT: PASS — docs in sync with code."
    exit 0
fi
