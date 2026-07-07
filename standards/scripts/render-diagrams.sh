#!/usr/bin/env bash
# ============================================================================
# render-diagrams.sh — Render Mermaid .mmd sources to SVG + PNG
# ============================================================================
#
# USAGE
#   bash scripts/render-diagrams.sh                       # default: docs/_diagrams/
#   bash scripts/render-diagrams.sh --out=/tmp/x          # custom output dir
#   bash scripts/render-diagrams.sh --src=docs/_diagrams  # custom source dir
#
# OUTPUT (in OUT_DIR, default $PLATFORM_DIR/docs/_diagrams/)
#   <name>.svg  — vector rendering (browsable in browser)
#   <name>.png  — raster preview (for embedding in README/docs)
#   <name>.mmd  — Mermaid source (kept for diffing in CI)
#
# AUTOMATION
#   CI runs this script on every push to main, every PR, and nightly at
#   03:00 UTC, immediately after graph-deps.sh. Output is uploaded as part
#   of the same "id-graph" artifact (SVG + PNG + DOT + Mermaid). See
#   .github/workflows/verify-id-graph.yml.
#
# REQUIRES
#   - mmdc (Mermaid CLI). In CI: `npm install -g @mermaid-js/mermaid-cli`.
#     In sandbox: already at /home/z/.npm-global/bin/mmdc.
#   - If mmdc is missing, the script exits 0 with a warning (graceful
#     degradation — does not block CI).
#
# EXIT CODES
#   0 — all diagrams rendered, or mmdc missing (graceful skip)
#   1 — at least one diagram failed to render
#   2 — invalid invocation
# ============================================================================

set -euo pipefail

# PLATFORM_DIR = the Z-ai-governance checkout (grandparent of this script's
# standards/scripts/ location). Works for:
#   - sandbox:        /home/z/my-project/Z-ai-governance/standards/scripts/render-diagrams.sh
#   - CI checkout:    $GITHUB_WORKSPACE/standards/scripts/render-diagrams.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default: read .mmd from docs/_diagrams/, write SVG+PNG back into the same dir
SRC_DIR="${PLATFORM_DIR}/docs/_diagrams"
OUT_DIR="${PLATFORM_DIR}/docs/_diagrams"

while [ $# -gt 0 ]; do
  case "$1" in
    --src=*) SRC_DIR="${1#--src=}" ;;
    --out=*) OUT_DIR="${1#--out=}" ;;
    *) echo "[render-diagrams] unknown flag: $1"; exit 2 ;;
  esac
  shift
done

if [ ! -d "$SRC_DIR" ]; then
  echo "[render-diagrams] source dir not found: $SRC_DIR"
  exit 2
fi

# Locate mmdc. In CI it may be in node_modules/.bin or npm-global.
MMDC=""
for candidate in mmdc /home/z/.npm-global/bin/mmdc node_modules/.bin/mmdc; do
  if command -v "$candidate" >/dev/null 2>&1; then
    MMDC="$candidate"
    break
  fi
done

if [ -z "$MMDC" ]; then
  echo "[render-diagrams] WARNING: mmdc (Mermaid CLI) not found — skipping diagram rendering."
  echo "[render-diagrams] In CI: ensure 'npm install -g @mermaid-js/mermaid-cli' ran."
  echo "[render-diagrams] In sandbox: /home/z/.npm-global/bin/mmdc should exist."
  exit 0
fi

echo "[render-diagrams] using mmdc: $($MMDC --version 2>&1 | head -1)"

mkdir -p "$OUT_DIR"

# Mermaid CLI uses puppeteer for rendering. In sandbox and CI (root user,
# no sandbox namespace), puppeteer needs --no-sandbox. We pass this via a
# temp puppeteer config JSON file.
PUPPETEER_CFG="$(mktemp /tmp/mmdc-puppet-XXXXXX.json)"
trap 'rm -f "$PUPPETEER_CFG"' EXIT
cat > "$PUPPETEER_CFG" <<'JSON'
{
  "args": ["--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage"]
}
JSON
PUPPETEER_FLAG="-p ${PUPPETEER_CFG}"

# Find all .mmd sources
shopt -s nullglob
MMD_FILES=("$SRC_DIR"/*.mmd)
shopt -u nullglob

if [ ${#MMD_FILES[@]} -eq 0 ]; then
  echo "[render-diagrams] no .mmd files in $SRC_DIR — nothing to render."
  exit 0
fi

fail_count=0
ok_count=0

for src in "${MMD_FILES[@]}"; do
  name="$(basename "$src" .mmd)"
  svg_out="${OUT_DIR}/${name}.svg"
  png_out="${OUT_DIR}/${name}.png"

  echo "[render-diagrams] ${name}.mmd -> SVG ..."
  if ! $MMDC -i "$src" -o "$svg_out" -t neutral $PUPPETEER_FLAG 2>/tmp/mmdc-err.log; then
    echo "[render-diagrams] FAILED on ${name}.mmd (SVG):"
    tail -20 /tmp/mmdc-err.log | sed 's/^/    /'
    fail_count=$((fail_count + 1))
    continue
  fi
  echo "[render-diagrams]   SVG: $svg_out ($(wc -c < "$svg_out") bytes)"

  echo "[render-diagrams] ${name}.mmd -> PNG ..."
  if ! $MMDC -i "$src" -o "$png_out" -t neutral -s 2 $PUPPETEER_FLAG 2>>/tmp/mmdc-err.log; then
    echo "[render-diagrams] WARNING: PNG render failed for ${name} (SVG is still available)"
    rm -f "$png_out"
  else
    echo "[render-diagrams]   PNG: $png_out ($(wc -c < "$png_out") bytes)"
  fi

  ok_count=$((ok_count + 1))
done

echo ""
echo "[render-diagrams] DONE. rendered=${ok_count} failed=${fail_count}"

if [ $fail_count -gt 0 ]; then
  exit 1
fi
exit 0
