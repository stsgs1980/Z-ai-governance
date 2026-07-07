#!/usr/bin/env bash
# ============================================================================
# PROC-SETUP-001: guard workspace installer
# ============================================================================
#
# Related:    STD-META-001 (ID system), RULE-ENV-008 (sandbox verification)
# Calls:      build-registry.py (to (re)generate registry.json)
#
# Purpose:
#   Verify that a guard workspace has the expected directory structure
#   and that the registry is in sync with rules/INDEX.md. Safe to re-run.
#
# Trigger:
#   bash guard/scripts/setup-001.sh            # normal
#   bash guard/scripts/setup-001.sh --force    # overwrite registry.json
#   bash guard/scripts/setup-001.sh --check    # non-mutating, exit 1 if drift
#
# Outputs:
#   Stdout: human-readable progress + summary
#   Exit 0: success (workspace ready)
#   Exit 1: setup failed (missing prerequisites)
#
# Open questions resolved by this implementation:
#   - Q: create symlinks into .git/hooks/?
#     A: NO. Platform-level bootstrap.sh owns .husky/. Guard stays out.
#   - Q: auto-regenerate registry.json?
#     A: YES, always. build-registry.py is idempotent. --check skips the write.
#
# ============================================================================

set -euo pipefail

GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$GUARD_DIR"

FORCE=0
CHECK_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --force)  FORCE=1 ;;
    --check)  CHECK_ONLY=1 ;;
    -h|--help)
      sed -n '2,30p' "$0"
      exit 0
      ;;
    *)
      echo "[setup-001] Unknown flag: $arg" >&2
      exit 1
      ;;
  esac
done

echo "[setup-001] PROC-SETUP-001 v2.0 — guard workspace installer"
echo "[setup-001] Guard dir: $GUARD_DIR"
echo ""

# --- Step 1: Verify rules/INDEX.md parses (17 RULE entries) -----------------
echo "[setup-001] Step 1/6: verify rules/INDEX.md"
INDEX="rules/INDEX.md"
if [ ! -f "$INDEX" ]; then
  echo "[setup-001] FAIL: $INDEX not found."
  echo "[setup-001]   This file is the rule catalog. Without it, registry.json"
  echo "[setup-001]   cannot be built. Run from a fresh git checkout."
  exit 1
fi

RULE_COUNT=$(grep -cE '^\| RULE-[A-Z]+-[0-9]+ ' "$INDEX" || true)
if [ "$RULE_COUNT" -lt 17 ]; then
  echo "[setup-001] FAIL: $INDEX has $RULE_COUNT RULE entries, expected >= 17."
  exit 1
fi
echo "[setup-001] OK: $INDEX has $RULE_COUNT RULE entries"
echo ""

# --- Step 2: Verify expected directories exist ------------------------------
echo "[setup-001] Step 2/6: verify directory structure"
for d in rules instructions scripts tools; do
  if [ ! -d "$d" ]; then
    echo "[setup-001] mkdir $d (was missing)"
    mkdir -p "$d"
  else
    echo "[setup-001] OK: $d/ exists"
  fi
done
echo ""

# --- Step 3: Regenerate registry.json if stale (or --force) -----------------
echo "[setup-001] Step 3/6: sync registry.json"
REGISTRY="registry.json"
BUILDER="scripts/build-registry.py"

if [ ! -f "$BUILDER" ]; then
  echo "[setup-001] FAIL: $BUILDER not found."
  exit 1
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
  # Non-mutating: regenerate to a temp file, diff against committed.
  # Strip volatile fields (generated_at, *_sha) for stable comparison.
  TMP="$(mktemp)"
  python3 "$BUILDER" --output "$TMP" >/dev/null 2>&1 || {
    echo "[setup-001] FAIL: build-registry.py crashed."
    rm -f "$TMP"
    exit 1
  }
  VOLATILE='s/"generated_at": *"[^"]*"/"generated_at": "..."/; s/"(standards_sha|guard_sha)": *"[^"]*"/"\1": "..."/'
  if [ -f "$REGISTRY" ] && \
     diff -q <(sed -E "$VOLATILE" "$REGISTRY") <(sed -E "$VOLATILE" "$TMP") >/dev/null 2>&1; then
    echo "[setup-001] OK: registry.json in sync (excluding volatile fields)"
  else
    echo "[setup-001] DRIFT: registry.json is stale. Run without --check to fix."
    rm -f "$TMP"
    exit 1
  fi
  rm -f "$TMP"
else
  echo "[setup-001] Running build-registry.py..."
  python3 "$BUILDER" --output "$REGISTRY"
  echo "[setup-001] OK: registry.json regenerated"
fi

# Validate JSON parses
if ! python3 -c "import json; json.load(open('$REGISTRY'))" 2>/dev/null; then
  echo "[setup-001] FAIL: $REGISTRY is not valid JSON."
  exit 1
fi
echo ""

# --- Step 4: Count ACTIVE IDs by category -----------------------------------
echo "[setup-001] Step 4/6: ID census"
python3 - <<'PY' "$REGISTRY"
import json, sys
d = json.load(open(sys.argv[1]))
from collections import Counter
c = Counter(i['id'].split('-')[0] for i in d['ids'])
print(f"[setup-001]   RULE:  {c.get('RULE',0):>3} / 17 expected")
print(f"[setup-001]   PROC:  {c.get('PROC',0):>3} / 4 expected")
print(f"[setup-001]   TOOL:  {c.get('TOOL',0):>3} / 6 expected")
print(f"[setup-001]   total: {d['counts']['total']}")
PY
echo ""

# --- Step 5: Verify every ACTIVE rule file exists ---------------------------
echo "[setup-001] Step 5/6: verify rule files on disk"
MISSING=0
python3 - <<'PY' "$GUARD_DIR" "$REGISTRY"
import json, os, sys
guard = sys.argv[1]
d = json.load(open(sys.argv[2]))
for i in d['ids']:
    if i['id'].startswith('RULE-') and i.get('status') == 'ACTIVE':
        path = os.path.join(guard, i['file'].replace('guard/', ''))
        if not os.path.isfile(path):
            print(f"[setup-001] MISSING: {path}")
            sys.exit(2)
print("[setup-001] OK: all ACTIVE rule files present")
PY
if [ $? -ne 0 ]; then
  echo "[setup-001] FAIL: missing rule files (see above). Run git pull."
  exit 1
fi
echo ""

# --- Step 6: Print onboarding summary ---------------------------------------
echo "[setup-001] Step 6/6: onboarding summary"
echo "[setup-001] Workspace ready. Next steps:"
echo "[setup-001]   1. Read ../../AGENT_RULES.md §1 (onboarding protocol)"
echo "[setup-001]   2. Run ../../scripts/status.sh to verify platform-level hooks"
echo "[setup-001]   3. To check for registry drift later: bash $0 --check"
echo ""
echo "[setup-001] DONE."
exit 0
