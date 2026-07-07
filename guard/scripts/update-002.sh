#!/usr/bin/env bash
# ============================================================================
# PROC-UPDATE-002: Z-ai-guard workspace updater
# ============================================================================
#
# Related:    STD-META-001 (ID system), RULE-AGENT-009 (session start protocol)
# Calls:      build-registry.py, verify-id-graph.js (TOOL-VERIFY-004)
#
# Purpose:
#   Bring an existing Z-ai-guard workspace up to date after `git pull`
#   of the guard submodule. Detects new/retired rules, regenerates
#   registry.json, and verifies the ID-graph remains intact.
#
# Trigger:
#   bash guard/scripts/update-002.sh            # normal
#   bash guard/scripts/update-002.sh --check    # diff only, do not write
#
# Outputs:
#   Stdout: change summary + verification result
#   Exit 0: success (workspace updated)
#   Exit 1: update failed (missing file, ID-graph broken, etc.)
#
# Open questions resolved by this implementation:
#   - Q: auto-commit registry.json?
#     A: NO. Operator commits. Script prints git hint.
#   - Q: call co-change-check.sh after update?
#     A: NO. co-change is a pre-commit concern, not an update concern.
#       Update is read-only w.r.t. the working tree except for registry.json.
#
# ============================================================================

set -euo pipefail

GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLATFORM_DIR="$(cd "$GUARD_DIR/.." && pwd)"
cd "$GUARD_DIR"

CHECK_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --check) CHECK_ONLY=1 ;;
    -h|--help)
      sed -n '2,30p' "$0"
      exit 0
      ;;
    *)
      echo "[update-002] Unknown flag: $arg" >&2
      exit 1
      ;;
  esac
done

echo "[update-002] PROC-UPDATE-002 v2.1 — Z-ai-guard workspace updater"
echo "[update-002] Guard dir: $GUARD_DIR"
echo ""

# --- Step 1: Detect new/retired rules via INDEX.md --------------------------
echo "[update-002] Step 1/6: re-parse rules/INDEX.md"
INDEX="rules/INDEX.md"
if [ ! -f "$INDEX" ]; then
  echo "[update-002] FAIL: $INDEX missing. git pull failed?"
  exit 1
fi

RULE_COUNT=$(grep -cE '^\| RULE-[A-Z]+-[0-9]+ ' "$INDEX" || true)
echo "[update-002] OK: $INDEX references $RULE_COUNT RULE entries"
echo ""

# --- Step 2: Regenerate registry.json if stale ------------------------------
echo "[update-002] Step 2/6: sync registry.json"
REGISTRY="registry.json"
BUILDER="scripts/build-registry.py"

if [ ! -f "$BUILDER" ]; then
  echo "[update-002] FAIL: $BUILDER not found."
  exit 1
fi

# Snapshot current registry for diff
OLD_REG="$(mktemp)"
[ -f "$REGISTRY" ] && cp "$REGISTRY" "$OLD_REG" || echo "" > "$OLD_REG"

NEW_REG="$(mktemp)"
if ! python3 "$BUILDER" --output "$NEW_REG" >/dev/null 2>&1; then
  echo "[update-002] FAIL: build-registry.py crashed."
  rm -f "$OLD_REG" "$NEW_REG"
  exit 1
fi

# Diff old vs new at the ID level
echo "[update-002] ID-level changes:"
python3 - <<'PY' "$OLD_REG" "$NEW_REG"
import json, sys
def load(p):
    try:
        return {i['id']: i for i in json.load(open(p))['ids']}
    except Exception:
        return {}
old = load(sys.argv[1])
new = load(sys.argv[2])
added = sorted(set(new) - set(old))
removed = sorted(set(old) - set(new))
status_changed = []
for k in sorted(set(old) & set(new)):
    if old[k].get('status') != new[k].get('status'):
        status_changed.append((k, old[k].get('status'), new[k].get('status')))
if added:
    for k in added: print(f"[update-002]   + {k}  ({new[k].get('title','')})")
else:
    print("[update-002]   (no new IDs)")
if removed:
    for k in removed: print(f"[update-002]   - {k}  ({old[k].get('title','')})")
if status_changed:
    for k, o, n in status_changed:
        print(f"[update-002]   ~ {k}: {o} -> {n}")
PY

if [ "$CHECK_ONLY" -eq 1 ]; then
  # Strip volatile fields for stable comparison.
  VOLATILE='s/"generated_at": *"[^"]*"/"generated_at": "..."/; s/"(standards_sha|guard_sha)": *"[^"]*"/"\1": "..."/'
  if diff -q <(sed -E "$VOLATILE" "$OLD_REG") <(sed -E "$VOLATILE" "$NEW_REG") >/dev/null 2>&1; then
    echo "[update-002] OK: registry.json in sync (--check, excluding volatile fields)"
  else
    echo "[update-002] DRIFT: registry.json is stale. Re-run without --check."
    rm -f "$OLD_REG" "$NEW_REG"
    exit 1
  fi
else
  cp "$NEW_REG" "$REGISTRY"
  echo "[update-002] OK: registry.json regenerated"
fi
rm -f "$OLD_REG" "$NEW_REG"
echo ""

# --- Step 3: Validate ACTIVE rules have files -------------------------------
echo "[update-002] Step 3/6: verify ACTIVE rule files exist"
MISSING=$(python3 - <<'PY' "$GUARD_DIR" "$REGISTRY"
import json, os, sys
guard = sys.argv[1]
d = json.load(open(sys.argv[2]))
missing = 0
for i in d['ids']:
    if i['id'].startswith('RULE-') and i.get('status') == 'ACTIVE':
        path = os.path.join(guard, i['file'].replace('guard/', ''))
        if not os.path.isfile(path):
            print(f"[update-002] MISSING: {path}")
            missing += 1
sys.exit(1 if missing else 0)
PY
) || MISSING_RC=$?

if [ "${MISSING_RC:-0}" -ne 0 ]; then
  echo "$MISSING"
  echo "[update-002] FAIL: missing rule files. Run git pull on guard submodule."
  exit 1
fi
echo "[update-002] OK: all ACTIVE rule files present"
echo ""

# --- Step 4: Run verify-id-graph.js if available ----------------------------
echo "[update-002] Step 4/6: verify ID-graph integrity (TOOL-VERIFY-004)"
VG="$PLATFORM_DIR/standards/scripts/verify-id-graph.js"
if [ ! -f "$VG" ]; then
  echo "[update-002] SKIP: $VG not found (standards submodule not initialized)."
  echo "[update-002]        Run: git submodule update --init --recursive"
elif ! command -v node >/dev/null 2>&1; then
  echo "[update-002] SKIP: node not in PATH. CI will catch regressions."
else
  if node "$VG" >/tmp/zai-update-vg.log 2>&1; then
    echo "[update-002] OK: verify-id-graph.js PASS"
    rm -f /tmp/zai-update-vg.log
  else
    echo "[update-002] FAIL: verify-id-graph.js reported HARD violations:"
    sed 's/^/  /' /tmp/zai-update-vg.log
    rm -f /tmp/zai-update-vg.log
    exit 1
  fi
fi
echo ""

# --- Step 5: Run verify-standards.js if available ---------------------------
echo "[update-002] Step 5/6: verify standards invariants (TOOL-VERIFY-002)"
VS="$PLATFORM_DIR/standards/scripts/verify-standards.js"
if [ -f "$VS" ] && command -v node >/dev/null 2>&1; then
  if node "$VS" >/tmp/zai-update-vs.log 2>&1; then
    echo "[update-002] OK: verify-standards.js PASS"
    rm -f /tmp/zai-update-vs.log
  else
    echo "[update-002] FAIL: verify-standards.js reported violations:"
    sed 's/^/  /' /tmp/zai-update-vs.log
    rm -f /tmp/zai-update-vs.log
    exit 1
  fi
else
  echo "[update-002] SKIP: $VS not available or node missing."
fi
echo ""

# --- Step 6: Print summary --------------------------------------------------
echo "[update-002] Step 6/6: summary"
echo "[update-002] Workspace is up to date."
if git diff --quiet -- registry.json 2>/dev/null; then
  :
else
  echo "[update-002] NOTE: registry.json was modified. To persist:"
  echo "[update-002]   git add registry.json && git commit -m 'chore(registry): auto-regen after pull'"
fi
echo "[update-002] DONE."
exit 0
