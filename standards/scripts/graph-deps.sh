#!/usr/bin/env bash
# ============================================================================
# graph-deps.sh — Render the Z-ai ID-graph as SVG + PNG via graphviz
# ============================================================================
#
# USAGE
#   bash standards/scripts/graph-deps.sh                   # default: graph/
#   bash standards/scripts/graph-deps.sh --out=/tmp/x      # custom output dir
#   bash standards/scripts/graph-deps.sh --dot-only        # emit DOT only
#   bash standards/scripts/graph-deps.sh --open            # also xdg-open SVG
#
# OUTPUT (in OUT_DIR, default $PLATFORM_DIR/graph/)
#   id-graph.svg   — vector graph (browsable in browser, zoomable)
#   id-graph.png   — raster preview (for embedding in README/docs)
#   id-graph.dot   — DOT source (for diffing in CI)
#
# AUTOMATION
#   CI runs this script on every push to main, every PR, and nightly at
#   03:00 UTC. Output is uploaded as a 30-day-retention artifact named
#   "id-graph". See .github/workflows/verify-id-graph.yml.
#
# DATA SOURCE
#   Calls `node standards/scripts/verify-id-graph.js --json` to get the
#   authoritative node list, then re-parses the .md source files to extract
#   Related:/Aligned_with: edges (the JSON output does not currently dump
#   edges — only counts). Same ID_REGEX as verify-id-graph.js.
#
# LAYOUT
#   Left-to-right (LR) to fit wide screens. Each layer is a subgraph cluster:
#     L1 Standards  (STD-*)      — blue
#     L2 Guard      (RULE-*)     — amber
#     L3 Skills     (ZAI-*)      — green
#   Nodes with no edges are shown in a grey "orphans" cluster at the bottom.
#
# REQUIRES
#   - node (already used by verify-id-graph.js)
#   - graphviz `dot` binary (already installed at /usr/bin/dot)
#
# EXIT CODES
#   0 — graph rendered (or DOT emitted with --dot-only)
#   1 — rendering failed
#   2 — prerequisites missing
# ============================================================================

set -euo pipefail

# PLATFORM_DIR = the Z-ai-governance checkout (parent of this script's
# standards/ directory). Works for:
#   - sandbox:        /home/z/my-project/Z-ai-governance/standards/scripts/graph-deps.sh
#   - CI checkout:    $GITHUB_WORKSPACE/standards/scripts/graph-deps.sh
#   - standalone dev: anywhere — pass --platform=<path> to override
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# OUT_DIR = where SVG/PNG/DOT land. Default: $PLATFORM_DIR/graph/
# (kept inside the repo so it's browsable on GitHub UI).
# Override with --out=<path> or env GRAPH_OUT_DIR.
OUT_DIR="${GRAPH_OUT_DIR:-${PLATFORM_DIR}/graph}"

VERIFY="${PLATFORM_DIR}/standards/scripts/verify-id-graph.js"

# --- preflight --------------------------------------------------------------
if [ ! -f "$VERIFY" ]; then
  echo "[graph-deps] verify-id-graph.js not found at $VERIFY"
  exit 2
fi
if ! command -v node >/dev/null 2>&1; then
  echo "[graph-deps] node not found in PATH"
  exit 2
fi
if ! command -v dot >/dev/null 2>&1; then
  echo "[graph-deps] graphviz 'dot' not found in PATH"
  echo "[graph-deps] install: apt-get install -y graphviz"
  exit 2
fi


OPEN_FLAG=0
DOT_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --open) OPEN_FLAG=1 ;;
    --dot-only) DOT_ONLY=1 ;;
    --platform=*) PLATFORM_DIR="${arg#--platform=}" ;;
    --out=*) OUT_DIR="${arg#--out=}" ;;
    *) echo "[graph-deps] unknown flag: $arg"; exit 2 ;;
  esac
done

# Create output directory AFTER argument parsing (so --out= override is honored)
mkdir -p "$OUT_DIR"

# --- step 1: extract graph data via verify-id-graph.js --json ---------------
echo "[graph-deps] step 1/3: extracting ID graph from verify-id-graph.js ..."
JSON_TMP="$(mktemp /tmp/zai-graph-XXXXXX.json)"
trap 'rm -f "$JSON_TMP"' EXIT

if ! node "$VERIFY" --json > "$JSON_TMP" 2>/dev/null; then
  echo "[graph-deps] FAILED: verify-id-graph.js did not exit 0"
  node "$VERIFY" --json
  exit 1
fi

# --- step 2: transform JSON -> DOT ------------------------------------------
echo "[graph-deps] step 2/3: transforming to DOT ..."
DOT_FILE="${OUT_DIR}/id-graph.dot"

# Use node to do the JSON->DOT transformation (jq can't easily emit multi-line
# subgraph clusters with attribute quoting).
TRANSFORM_JS="${OUT_DIR}/.graph-transform.cjs"
cat > "$TRANSFORM_JS" <<'JS'
const fs = require('fs');
const path = require('path');

const jsonPath = process.argv[2];
const dotPath = process.argv[3];
const platformDir = process.argv[4];

const data = JSON.parse(fs.readFileSync(jsonPath, 'utf-8'));

// verify-id-graph.js --json does NOT dump edges. We need to re-extract them
// from the source markdown files. Use the same ID_REGEX and edge patterns.
const ID_REGEX = /^(STD|RULE|PROC|TOOL|ZAI)-([A-Z]+)-(\d{3})$/;

function findFiles(dir, ext) {
  const out = [];
  function walk(d) {
    for (const entry of fs.readdirSync(d, { withFileTypes: true })) {
      if (entry.name === 'node_modules' || entry.name === '.git') continue;
      const p = path.join(d, entry.name);
      if (entry.isDirectory()) walk(p);
      else if (entry.name.endsWith(ext)) out.push(p);
    }
  }
  try { walk(dir); } catch (_) {}
  return out;
}

const files = [
  ...findFiles(path.join(platformDir, 'standards', 'standards'), '.md'),
  ...findFiles(path.join(platformDir, 'guard', 'rules'), '.md'),
  ...findFiles(path.join(platformDir, 'guard', 'instructions'), '.md'),
  ...findFiles(path.join(platformDir, 'guard', 'scripts'), '.sh'),
  ...findFiles(path.join(platformDir, 'guard', 'tools'), '.sh'),
  ...findFiles(path.join(platformDir, 'skills'), '.md'),
];

// Extract: (id, prefix, layer, title) and edge list
const nodes = new Map();   // id -> { prefix, layer, title, file }
const edges = [];          // { from, to, kind }

function layerOf(prefix) {
  if (prefix === 'STD')  return 'L1';
  if (prefix === 'RULE' || prefix === 'PROC' || prefix === 'TOOL') return 'L2';
  if (prefix === 'ZAI')  return 'L3';
  return 'L?';
}

for (const file of files) {
  let raw;
  try { raw = fs.readFileSync(file, 'utf-8'); } catch (_) { continue; }

  // Resolve file path relative to platformDir for display
  const relPath = path.relative(platformDir, file);

  // Find the ID declaration: try YAML frontmatter first, then blockquote
  let id = null;
  let title = null;

  // YAML frontmatter
  const fmMatch = raw.match(/^---\s*\n([\s\S]*?)\n---/);
  if (fmMatch) {
    const fm = fmMatch[1];
    const idLine = fm.match(/^id:\s*(\S+)/m);
    if (idLine) id = idLine[1];
    const titleLine = fm.match(/^title:\s*(.+)$/m);
    if (titleLine) title = titleLine[1].trim();
  }

  // Blockquote header `> ID: ...`
  if (!id) {
    const bqIdMatch = raw.match(/^>\s*ID:\s*(\S+)/m);
    if (bqIdMatch) id = bqIdMatch[1];
  }

  // Heading-based ID (e.g. `# RULE-ANSWER-001: ...`)
  if (!id) {
    const hMatch = raw.match(/^#\s+(STD|RULE|PROC|TOOL|ZAI)-([A-Z]+)-(\d{3})\b/);
    if (hMatch) id = hMatch[0].match(/(STD|RULE|PROC|TOOL|ZAI)-[A-Z]+-\d{3}/)[0];
  }

  if (!id || !ID_REGEX.test(id)) continue;

  const prefix = id.split('-')[0];
  const layer = layerOf(prefix);

  // Title fallback: first H1
  if (!title) {
    const h1 = raw.match(/^#\s+(.+)$/m);
    if (h1) title = h1[1].replace(/^Standard:\s*/, '').replace(/\s+v\d.*$/, '').trim();
  }
  if (!title) title = id;

  nodes.set(id, { prefix, layer, title: title.slice(0, 60), file: relPath });

  // Extract Related: edges
  // Pattern 1: YAML frontmatter `related: \n  - RULE-XXX-001`
  if (fmMatch) {
    const fm = fmMatch[1];
    const relatedMatch = fm.match(/related:\s*\n((?:\s+-\s+\S+\n?)+)/);
    if (relatedMatch) {
      const targets = relatedMatch[1].matchAll(/-\s+(STD|RULE|PROC|TOOL|ZAI)-[A-Z]+-\d{3}/g);
      for (const t of targets) {
        edges.push({ from: id, to: t[0].replace(/^-\s+/, ''), kind: 'related' });
      }
    }
  }

  // Pattern 2: blockquote `> Related: A, B, C`
  const bqRelMatch = raw.match(/^>\s*Related:\s*(.+)$/m);
  if (bqRelMatch) {
    const list = bqRelMatch[1].trim();
    if (!/^\(none|^—/.test(list)) {
      const targets = list.matchAll(/(STD|RULE|PROC|TOOL|ZAI)-[A-Z]+-\d{3}/g);
      for (const t of targets) {
        if (t[0] !== id) edges.push({ from: id, to: t[0], kind: 'related' });
      }
    }
  }

  // Extract Aligned_with: edges
  const bqAlignMatch = raw.match(/^>\s*Aligned_with:\s*(.+)$/m);
  if (bqAlignMatch) {
    const list = bqAlignMatch[1].trim();
    const targets = list.matchAll(/(STD|RULE|PROC|TOOL|ZAI)-[A-Z]+-\d{3}/g);
    for (const t of targets) {
      if (t[0] !== id) edges.push({ from: id, to: t[0], kind: 'aligned' });
    }
  }
}

// --- emit DOT ---------------------------------------------------------------
let dot = '';
dot += 'digraph zai_id_graph {\n';
dot += '  graph [\n';
dot += '    rankdir=LR,\n';
dot += '    splines=true,\n';
dot += '    overlap=false,\n';
dot += '    fontname="Helvetica",\n';
dot += '    label="Z-ai Platform ID Graph\\n' + nodes.size + ' nodes / ' + edges.length + ' edges\\nGenerated ' + new Date().toISOString().slice(0,10) + '",\n';
dot += '    labelloc=t,\n';
dot += '    fontsize=14,\n';
dot += '    bgcolor="#fafafa"\n';
dot += '  ];\n';
dot += '  node [fontname="Helvetica", fontsize=10, style="filled,rounded", shape=box, penwidth=1.2];\n';
dot += '  edge [fontname="Helvetica", fontsize=8, color="#666666"];\n';

// Layer color map
const COLORS = {
  STD:  { fill: '#dbeafe', stroke: '#1e40af', text: '#1e3a8a' },  // blue
  RULE: { fill: '#fef3c7', stroke: '#92400e', text: '#78350f' },  // amber
  PROC: { fill: '#fef3c7', stroke: '#92400e', text: '#78350f' },  // amber
  TOOL: { fill: '#fef3c7', stroke: '#92400e', text: '#78350f' },  // amber
  ZAI:  { fill: '#dcfce7', stroke: '#166534', text: '#14532d' },  // green
};

// Group nodes by layer for subgraph clusters
const byLayer = { L1: [], L2: [], L3: [] };
for (const [id, meta] of nodes) {
  if (byLayer[meta.layer]) byLayer[meta.layer].push(id);
}

dot += '  subgraph cluster_L1 {\n';
dot += '    label="L1 — Standards (STD-*)";\n';
dot += '    style="filled,rounded"; fillcolor="#eff6ff"; color="#bfdbfe"; fontsize=12;\n';
for (const id of byLayer.L1) {
  const m = nodes.get(id);
  const c = COLORS[m.prefix] || COLORS.STD;
  const safeTitle = m.title.replace(/"/g, "'").replace(/\\/, '/');
  dot += `    "${id}" [label="${id}\\n${safeTitle}", fillcolor="${c.fill}", color="${c.stroke}", fontcolor="${c.text}"];\n`;
}
dot += '  }\n';

dot += '  subgraph cluster_L2 {\n';
dot += '    label="L2 — Guard (RULE-*/PROC-*/TOOL-*)";\n';
dot += '    style="filled,rounded"; fillcolor="#fffbeb"; color="#fde68a"; fontsize=12;\n';
for (const id of byLayer.L2) {
  const m = nodes.get(id);
  const c = COLORS[m.prefix] || COLORS.RULE;
  const safeTitle = m.title.replace(/"/g, "'").replace(/\\/, '/');
  dot += `    "${id}" [label="${id}\\n${safeTitle}", fillcolor="${c.fill}", color="${c.stroke}", fontcolor="${c.text}"];\n`;
}
dot += '  }\n';

dot += '  subgraph cluster_L3 {\n';
dot += '    label="L3 — Skills (ZAI-*)";\n';
dot += '    style="filled,rounded"; fillcolor="#f0fdf4"; color="#bbf7d0"; fontsize=12;\n';
for (const id of byLayer.L3) {
  const m = nodes.get(id);
  const c = COLORS.ZAI;
  const safeTitle = m.title.replace(/"/g, "'").replace(/\\/, '/');
  dot += `    "${id}" [label="${id}\\n${safeTitle}", fillcolor="${c.fill}", color="${c.stroke}", fontcolor="${c.text}"];\n`;
}
dot += '  }\n';

// Edges
const seen = new Set();
for (const e of edges) {
  // Skip edges to unknown nodes (verify-id-graph would have caught them,
  // but our parser may have missed the target's declaration).
  if (!nodes.has(e.from) || !nodes.has(e.to)) continue;
  const key = `${e.from}->${e.to}:${e.kind}`;
  if (seen.has(key)) continue;
  seen.add(key);
  if (e.kind === 'aligned') {
    dot += `  "${e.from}" -> "${e.to}" [style=dashed, color="#9333ea", penwidth=1.5, label="align"];\n`;
  } else {
    dot += `  "${e.from}" -> "${e.to}" [color="#666666", penwidth=1.0];\n`;
  }
}

// Identify orphan nodes (no edges)
const connected = new Set();
for (const e of edges) {
  if (nodes.has(e.from) && nodes.has(e.to)) {
    connected.add(e.from);
    connected.add(e.to);
  }
}

dot += '  subgraph cluster_orphans {\n';
dot += '    label="Orphan nodes (no edges)";\n';
dot += '    style="dashed,rounded"; color="#d4d4d4"; fontsize=10;\n';
dot += '    rank=sink;\n';
let orphanCount = 0;
for (const [id, meta] of nodes) {
  if (!connected.has(id)) {
    const c = COLORS[meta.prefix] || COLORS.STD;
    const safeTitle = meta.title.replace(/"/g, "'").replace(/\\/, '/');
    dot += `    "${id}_orphan" [label="${id}\\n${safeTitle}", fillcolor="${c.fill}", color="${c.stroke}", fontcolor="${c.text}"];\n`;
    orphanCount++;
  }
}
if (orphanCount === 0) {
  dot += '    "none" [label="(none)", shape=plaintext, fillcolor=none, color=none];\n';
}
dot += '  }\n';

dot += '}\n';

fs.writeFileSync(dotPath, dot);
console.log('[transform] nodes=' + nodes.size + ' edges=' + edges.length + ' orphans=' + orphanCount);
console.log('[transform] DOT written to ' + dotPath);
JS

node "$TRANSFORM_JS" "$JSON_TMP" "$DOT_FILE" "$PLATFORM_DIR"
rm -f "$TRANSFORM_JS"

if [ "$DOT_ONLY" -eq 1 ]; then
  echo "[graph-deps] --dot-only: DOT written to $DOT_FILE"
  exit 0
fi

# --- step 3: render DOT -> SVG + PNG ----------------------------------------
echo "[graph-deps] step 3/3: rendering SVG + PNG ..."

SVG_FILE="${OUT_DIR}/id-graph.svg"
PNG_FILE="${OUT_DIR}/id-graph.png"

if ! dot -Tsvg "$DOT_FILE" -o "$SVG_FILE" 2>/tmp/zai-graph-doterr.log; then
  echo "[graph-deps] dot -Tsvg failed:"
  cat /tmp/zai-graph-doterr.log
  exit 1
fi
echo "[graph-deps] SVG: $SVG_FILE ($(wc -c < "$SVG_FILE") bytes)"

# PNG render with overlap=false can be slow. Use a simpler layout for PNG.
# Skip if it takes > 30s (SVG is the primary deliverable).
echo "[graph-deps] rendering PNG (may take 10-30s) ..."
if ! timeout 30 dot -Tpng -Gdpi=110 "$DOT_FILE" -o "$PNG_FILE" 2>>/tmp/zai-graph-doterr.log; then
  echo "[graph-deps] WARNING: PNG render skipped (timeout or fail). SVG is still available."
  rm -f "$PNG_FILE"
else
  echo "[graph-deps] PNG: $PNG_FILE ($(wc -c < "$PNG_FILE") bytes)"
fi

echo ""
echo "[graph-deps] DONE."
echo "  SVG: $SVG_FILE"
echo "  PNG: $PNG_FILE"
echo "  DOT: $DOT_FILE"

if [ "$OPEN_FLAG" -eq 1 ] && command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$SVG_FILE" >/dev/null 2>&1 || true
fi
