#!/usr/bin/env bash
# ============================================================================
# TOOL-BUMP-005: version bumper (semver-aware, registry-aware)
# ============================================================================
#
# Related:    STD-META-001 §4.15, RULE-VERSION-013 (use ahg bump for version
#             updates), RULE-ARCH-016 (directory immutability)
#
# Purpose:
#   Single entry point for bumping versions across the Z-ai-governance. Wraps
#   the `ahg bump` flow defined by RULE-VERSION-013, but is callable even
#   when the `ahg` CLI is not installed (falls back to manual edits + git tag).
#
# What gets bumped:
#   1. Platform version: AGENT_RULES.md §9 (Version Lock)
#   2. registry.json `platform_version` field
#   3. Git tag vMAJOR.MINOR.PATCH on the platform repo
#
# Trigger:
#   bash guard/tools/bump.sh patch           # 2.6.0 -> 2.6.1
#   bash guard/tools/bump.sh minor           # 2.6.0 -> 2.7.0
#   bash guard/tools/bump.sh major           # 2.6.0 -> 3.0.0
#   bash guard/tools/bump.sh --dry-run patch # show what would change
#   bash guard/tools/bump.sh --check         # report drift, no writes
#
# Outputs:
#   Stdout: before/after versions + tag name
#   Exit 0: success
#   Exit 1: invalid input, drift detected, or tag already exists
#
# ============================================================================

set -euo pipefail

GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLATFORM_DIR="$(cd "$GUARD_DIR/.." && pwd)"
cd "$PLATFORM_DIR"

DRY_RUN=0
CHECK_ONLY=0
BUMPTYPE=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --check)   CHECK_ONLY=1 ;;
    patch|minor|major) BUMPTYPE="$arg" ;;
    -h|--help)
      sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "[bump] Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

# --- Resolve current version ------------------------------------------------
# Look in AGENT_RULES.md §9 for a line like:  v2.6.0
CURRENT=$(grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' AGENT_RULES.md | head -1 || true)
if [ -z "$CURRENT" ]; then
  echo "[bump] FAIL: could not find current version in AGENT_RULES.md §9" >&2
  exit 1
fi
CURRENT="${CURRENT#v}"  # strip leading v

if [ "$CHECK_ONLY" -eq 1 ]; then
  echo "[bump] --check: current platform version = v$CURRENT"
  REG_VER=$(python3 -c "import json; print(json.load(open('guard/registry.json'))['platform_version'])" 2>/dev/null || echo "MISSING")
  echo "[bump] --check: registry.json platform_version = $REG_VER"
  if [ "v$CURRENT" = "$REG_VER" ]; then
    echo "[bump] --check: OK — in sync"
    exit 0
  else
    echo "[bump] --check: DRIFT — versions differ"
    exit 1
  fi
fi

if [ -z "$BUMPTYPE" ]; then
  echo "[bump] FAIL: must specify bump type (patch|minor|major)" >&2
  exit 1
fi

# --- Compute next version ---------------------------------------------------
IFS='.' read -r MAJ MIN PAT <<< "$CURRENT"
case "$BUMPTYPE" in
  patch) PAT=$((PAT+1)) ;;
  minor) MIN=$((MIN+1)); PAT=0 ;;
  major) MAJ=$((MAJ+1)); MIN=0; PAT=0 ;;
esac
NEXT="${MAJ}.${MIN}.${PAT}"

echo "[bump] current: v$CURRENT"
echo "[bump] next:    v$NEXT  ($BUMPTYPE)"
echo ""

if [ "$DRY_RUN" -eq 1 ]; then
  echo "[bump] --dry-run: would update:"
  echo "[bump]   - AGENT_RULES.md §9: v$CURRENT -> v$NEXT"
  echo "[bump]   - guard/registry.json platform_version: v$CURRENT -> v$NEXT"
  echo "[bump]   - git tag v$NEXT on platform repo"
  echo "[bump] No changes made."
  exit 0
fi

# --- Pre-flight: tag must not already exist ---------------------------------
if git rev-parse -q --verify "refs/tags/v$NEXT" >/dev/null; then
  echo "[bump] FAIL: tag v$NEXT already exists in platform repo" >&2
  exit 1
fi

# --- Apply: AGENT_RULES.md --------------------------------------------------
if ! sed -i "s/v${CURRENT//./\\.}/v$NEXT/g" AGENT_RULES.md; then
  echo "[bump] FAIL: sed on AGENT_RULES.md failed" >&2
  exit 1
fi
echo "[bump] OK: AGENT_RULES.md updated"

# --- Apply: guard/registry.json ---------------------------------------------
python3 - <<PY
import json
p = 'guard/registry.json'
d = json.load(open(p))
d['platform_version'] = 'v$NEXT'
d['guard_sha'] = '$(cd guard && git rev-parse --short HEAD)'
d['generated_at'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
with open(p, 'w') as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
    f.write('\n')
print("[bump] OK: guard/registry.json updated")
PY

# --- Commit + tag (NOT pushing — operator pushes) ---------------------------
git add AGENT_RULES.md guard/registry.json
git commit -m "chore(version): bump v$CURRENT -> v$NEXT ($BUMPTYPE)" >/dev/null
git tag "v$NEXT"
echo "[bump] OK: committed + tagged v$NEXT"
echo ""
echo "[bump] NEXT STEPS (operator):"
echo "[bump]   git push origin main"
echo "[bump]   git push origin v$NEXT"
echo "[bump] DONE."
exit 0
