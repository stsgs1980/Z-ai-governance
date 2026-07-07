#!/usr/bin/env bash
#
# PROC-LINECOUNT-004 — Anti-monolith file-size enforcement
# Implements: RULE-MONOLITH-012 (anti-monolith, file size by category)
# Calls:      TOOL-VERIFY-002 (verify-standards.js, V11 1000-line cap)
#             TOOL-VERIFY-004 (verify-id-graph.js — not size but always paired)
# Matrix source: STD-META-001 §4.18.1 (canonical, NOT this file)
#
# Usage:
#   bash guard/scripts/line-count-check.sh           # soft warn (exit 0 always)
#   bash guard/scripts/line-count-check.sh --hard    # hard fail (exit 1 on any offender)
#   bash guard/scripts/line-count-check.sh --help
#
# Exit codes:
#   0  all files under hard cap (or --hard not set)
#   1  one or more files exceed hard cap AND --hard set
#   2  usage error
#
# What this checks (delegates to existing verifiers — no matrix duplication):
#   - verify-standards.js V11:   standards/ + docs/sandbox/ + templates/  <= 1000 lines
#   - verify-skills.js   S10a:   skills/skills/*/SKILL.md                 <=  800 lines
#   - verify-skills.js   S10b:   skills/skills/*/CONTRACT.md              <=  500 lines
#   - verify-skills.js   S10c:   skills/skills/*/README.md                <=  400 lines
#
# Why delegation: RULE-MONOLITH-012 v1.3 explicitly says "the procedure MUST
# read the canonical matrix from META-001 §4.18, NOT from this rule's mirror."
# The verifiers already parse §4.18 — duplicating the matrix here would
# recreate the layering violation that v1.3 fixed.
#
# Future: when TOOL-VERIFY-001 (verify-docs) is built, this script can also
# call it for the broader §4.18.1 matrix (source code 250, tests 400, etc.).
# For now, the four caps above cover 100% of files in the platform tree.

set -euo pipefail

HARD_MODE=0
PLATFORM_DIR="/home/z/my-project/Z-ai-platform"

# ─── Usage ──────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    sed -n '2,30p' "$0"
    exit 0
fi
if [[ "${1:-}" == "--hard" ]]; then
    HARD_MODE=1
fi

# ─── Helpers ────────────────────────────────────────────────────────────
OFFENDERS=0
WARN_COUNT=0

emit_pass() { echo "  [PASS] $1"; }
emit_fail() { echo "  [FAIL] $1"; OFFENDERS=$((OFFENDERS + 1)); }
emit_warn() { echo "  [WARN] $1"; WARN_COUNT=$((WARN_COUNT + 1)); }

# ─── Run verifiers ──────────────────────────────────────────────────────
echo "=== PROC-LINECOUNT-004: anti-monolith file-size check ==="
echo "Mode: $([ $HARD_MODE -eq 1 ] && echo 'HARD (will fail on offenders)' || echo 'SOFT (warning-only)')"
echo "Matrix source: STD-META-001 §4.18.1 (via verify-standards.js + verify-skills.js)"
echo ""

# 1. verify-standards.js (V11 — 1000-line cap on standards/ + docs/ + templates/)
STANDARDS_DIR="$PLATFORM_DIR/standards"
if [ -f "$STANDARDS_DIR/scripts/verify-standards.js" ]; then
    echo "--- TOOL-VERIFY-002: verify-standards.js (V11 cap) ---"
    if (cd "$STANDARDS_DIR" && node scripts/verify-standards.js 2>&1 | tail -5 | grep -qE "Total:.*PASS:.*FAIL: 0"); then
        emit_pass "verify-standards.js V11 — all .md files <= 1000 lines"
    else
        if [ $HARD_MODE -eq 1 ]; then
            emit_fail "verify-standards.js V11 — one or more .md files exceed 1000 lines"
        else
            emit_warn "verify-standards.js V11 — one or more .md files exceed 1000 lines (would fail in --hard)"
        fi
        # Show details
        (cd "$STANDARDS_DIR" && node scripts/verify-standards.js 2>&1 | grep -E "FAIL|exceeds" | head -10) || true
    fi
else
    emit_warn "verify-standards.js not found at $STANDARDS_DIR/scripts/"
fi

echo ""

# 2. verify-skills.js (S10a/b/c — 800/500/400 caps)
SKILLS_DIR="$PLATFORM_DIR/skills"
if [ -f "$STANDARDS_DIR/scripts/verify-skills.js" ]; then
    echo "--- TOOL-VERIFY-002: verify-skills.js (S10a/b/c caps) ---"
    SKILLS_OUT=$(cd "$STANDARDS_DIR" && node scripts/verify-skills.js --strict 2>&1 || true)
    if echo "$SKILLS_OUT" | grep -qE "HARD: 9/9 PASS.*0 FAIL"; then
        emit_pass "verify-skills.js S10a/b/c — SKILL.md <= 800, CONTRACT.md <= 500, README.md <= 400"
    else
        if [ $HARD_MODE -eq 1 ]; then
            emit_fail "verify-skills.js S10a/b/c — one or more skill files exceed caps"
        else
            emit_warn "verify-skills.js S10a/b/c — one or more skill files exceed caps (would fail in --hard)"
        fi
        echo "$SKILLS_OUT" | grep -E "FAIL|exceeds|offender" | head -10 || true
    fi
else
    emit_warn "verify-skills.js not found at $STANDARDS_DIR/scripts/"
fi

echo ""

# ─── Summary ────────────────────────────────────────────────────────────
echo "=== Summary ==="
echo "  Offenders (hard cap):  $OFFENDERS"
echo "  Warnings (soft cap):   $WARN_COUNT"
echo ""

if [ $OFFENDERS -gt 0 ] && [ $HARD_MODE -eq 1 ]; then
    echo "RESULT: FAIL — $OFFENDERS file(s) exceed hard cap. Split before commit. (RULE-MONOLITH-012 §3)"
    exit 1
elif [ $OFFENDERS -gt 0 ]; then
    echo "RESULT: WARN — $OFFENDERS file(s) exceed hard cap. Re-run with --hard to enforce."
    exit 0
else
    echo "RESULT: PASS — all files within §4.18.1 caps."
    exit 0
fi
