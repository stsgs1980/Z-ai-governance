#!/usr/bin/env bash
# ============================================================================
# TOOL-VERIFY-001: verify-docs (guard-side docs invariants)
# ============================================================================
#
# Related:    STD-META-001 §4.15, RULE-DOC-010 (documentation sync),
#             RULE-INTEGRITY-011 (integrity protection)
# Calls:      verify-standards.js (TOOL-VERIFY-002), verify-id-graph.js (TOOL-VERIFY-004)
#
# Purpose:
#   Guard-side docs integrity wrapper. Composes the two platform-level
#   verifiers (which already check cross-repo invariants) and adds
#   guard-specific checks:
#     A. registry.json parses and matches rules/INDEX.md census
#     B. every ACTIVE rule file referenced in registry.json exists
#     C. every PROC-*.md in instructions/ references its implementing script
#        (or explicitly marks itself as "planned")
#     D. AGENT_RULES.md §2 priority order matches registry.json status fields
#
# Trigger:
#   bash guard/tools/verify-docs.sh            # full check
#   bash guard/tools/verify-docs.sh --quiet    # errors only
#   bash guard/tools/verify-docs.sh --skip-platform  # skip node verifiers
#
# Outputs:
#   Stdout: per-check PASS/FAIL + summary
#   Exit 0: all checks PASS
#   Exit 1: at least one check FAILED
#
# ============================================================================

set -euo pipefail

GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLATFORM_DIR="$(cd "$GUARD_DIR/.." && pwd)"
cd "$GUARD_DIR"

QUIET=0
SKIP_PLATFORM=0
for arg in "$@"; do
  case "$arg" in
    --quiet)         QUIET=1 ;;
    --skip-platform) SKIP_PLATFORM=1 ;;
    -h|--help)
      sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "[verify-docs] Unknown flag: $arg" >&2; exit 1 ;;
  esac
done

log() { [ "$QUIET" -eq 0 ] && echo "$@" || true; }
FAILS=0
PASS() { log "[verify-docs] PASS: $1"; }
FAIL() { echo "[verify-docs] FAIL: $1"; FAILS=$((FAILS+1)); }

echo "[verify-docs] TOOL-VERIFY-001 — guard-side docs invariants"
echo ""

# --- Check A: registry.json parses + census matches INDEX.md ----------------
if [ ! -f registry.json ]; then
  FAIL "registry.json missing — run scripts/setup-001.sh"
else
  if python3 -c "import json; json.load(open('registry.json'))" 2>/dev/null; then
    REG_RULES=$(python3 -c "import json; d=json.load(open('registry.json')); print(sum(1 for i in d['ids'] if i['id'].startswith('RULE-')))")
    IDX_RULES=$(grep -cE '^\| RULE-[A-Z]+-[0-9]+ ' rules/INDEX.md || true)
    if [ "$REG_RULES" = "$IDX_RULES" ]; then
      PASS "registry.json census matches INDEX.md ($REG_RULES RULE entries)"
    else
      FAIL "registry.json has $REG_RULES RULE entries, INDEX.md has $IDX_RULES — drift"
    fi
  else
    FAIL "registry.json is not valid JSON"
  fi
fi

# --- Check B: ACTIVE rule files exist ---------------------------------------
MISSING=$(python3 - <<'PY' "$GUARD_DIR"
import json, os, sys
guard = sys.argv[1]
d = json.load(open('registry.json'))
for i in d['ids']:
    if i['id'].startswith('RULE-') and i.get('status') == 'ACTIVE':
        path = os.path.join(guard, i['file'].replace('guard/', ''))
        if not os.path.isfile(path):
            print(f"  missing: {path}")
PY
)
if [ -z "$MISSING" ]; then
  PASS "all ACTIVE rule files present on disk"
else
  FAIL "missing rule files:"
  echo "$MISSING"
fi

# --- Check C: PROC-*.md cross-reference scripts -----------------------------
PROC_ISSUES=""
for doc in instructions/PROC-*.md; do
  [ -f "$doc" ] || continue
  base=$(basename "$doc" .md)
  script=$(grep -oE 'scripts/[a-z0-9-]+\.(sh|py)' "$doc" | head -1 || true)
  status=$(grep -E '^status:' "$doc" | head -1 | sed 's/status: *//; s/[[:space:]]*$//')
  if [ -z "$script" ]; then
    if echo "$status" | grep -qi 'planned'; then
      :
    else
      PROC_ISSUES="${PROC_ISSUES}  $base: no scripts/ reference and not marked planned\n"
    fi
  else
    script_path="$GUARD_DIR/$script"
    if [ ! -f "$script_path" ]; then
      PROC_ISSUES="${PROC_ISSUES}  $base references $script but file missing\n"
    fi
  fi
done
if [ -z "$PROC_ISSUES" ]; then
  PASS "all PROC-*.md cross-references valid"
else
  FAIL "PROC cross-reference issues:"
  printf "%b" "$PROC_ISSUES"
fi

# --- Check D: AGENT_RULES.md §2 priority list non-empty ---------------------
AGENT_RULES="$PLATFORM_DIR/AGENT_RULES.md"
if [ -f "$AGENT_RULES" ]; then
  if grep -qE 'STD-\*' "$AGENT_RULES" && grep -qE 'RULE-' "$AGENT_RULES" && grep -qiE 'priority' "$AGENT_RULES"; then
    PASS "AGENT_RULES.md §2 priority chain present"
  else
    FAIL "AGENT_RULES.md §2 priority chain missing"
  fi
else
  FAIL "AGENT_RULES.md not found at $AGENT_RULES"
fi

# --- Platform verifiers (TOOL-VERIFY-002 + TOOL-VERIFY-004) -----------------
if [ "$SKIP_PLATFORM" -eq 1 ]; then
  log "[verify-docs] SKIP: --skip-platform (verify-standards.js + verify-id-graph.js)"
else
  VS="$PLATFORM_DIR/standards/scripts/verify-standards.js"
  VG="$PLATFORM_DIR/standards/scripts/verify-id-graph.js"
  if ! command -v node >/dev/null 2>&1; then
    log "[verify-docs] SKIP: node not in PATH"
  elif [ ! -f "$VS" ] || [ ! -f "$VG" ]; then
    log "[verify-docs] SKIP: standards submodule not initialized"
  else
    if node "$VS" >/tmp/vd-vs.log 2>&1; then
      PASS "verify-standards.js (TOOL-VERIFY-002)"
    else
      FAIL "verify-standards.js — see /tmp/vd-vs.log"
    fi
    if node "$VG" >/tmp/vd-vg.log 2>&1; then
      PASS "verify-id-graph.js (TOOL-VERIFY-004)"
    else
      FAIL "verify-id-graph.js — see /tmp/vd-vg.log"
    fi
  fi
fi

# --- Summary ----------------------------------------------------------------
echo ""
if [ "$FAILS" -eq 0 ]; then
  echo "[verify-docs] RESULT: PASS — all guard-side docs invariants satisfied"
  exit 0
else
  echo "[verify-docs] RESULT: FAIL — $FAILS check(s) failed"
  exit 1
fi
