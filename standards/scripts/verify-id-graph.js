#!/usr/bin/env node
/**
 * ============================================================================
 * verify-id-graph.js — Cross-Repo ID Graph Validator v1.1.6
 * ============================================================================
 *
 * ID: TOOL-VERIFY-004
 * Implements: STD-META-001 v2.0 §10.2 (G01-G15) + STD-SKILL-001 v1.0 §10.2
 * Spec: _design/verify-id-graph-spec.md (APPROVED 2026-06-17)
 *
 * PURPOSE
 *   Validates that the ID graph across the 4 Z-ai repositories is consistent:
 *     - No duplicate IDs (G01)
 *     - All Related: references resolve (G02)
 *     - No cycles in Related: graph (G03, G11)
 *     - Layer-edge matrix respected (G04, G07-G10)
 *     - No deprecated IDs referenced post-window (G05)
 *     - Aligned_with: has corresponding Related: edge (G15)
 *     - Compatibility DAG valid for ZAI skills (G14)
 *     - Soft warnings (W01-W10) for non-critical issues
 *     - Soft warnings (W11-W15) for project health / consistency (v1.1.0)
 *
 * TWO-LEVEL STRICTNESS
 *   HARD (G01-G15)  → exit 1 if any fail
 *                    Always apply to STD/RULE/PROC/TOOL
 *                    Apply to ZAI skills only when `id` field present
 *   SOFT (W01-W10)  → reported, but does not fail
 *                    Unless --fail-on-warnings flag is set
 *   SOFT (W11-W15)  → project-health warnings (v1.1.0): size anomalies,
 *                    missing §XA Known Issues, broken cross-doc refs,
 *                    excessive OPEN issues, naming drift
 *
 * USAGE
 *   node scripts/verify-id-graph.js [options]
 *
 *   Options:
 *     --root=<path>        Override platform root
 *     --json               Output JSON instead of human-readable
 *     --ci                 Skip network-dependent checks
 *     --fail-on-warnings   Exit 1 if any warning is emitted
 *     --verbose            Print full graph
 *     --repo=<name>        Limit to one repo (debug)
 *     --help               Show this help
 *
 * EXIT CODES
 *   0 — all HARD checks pass (warnings may be present)
 *   1 — at least one HARD check failed (or warning with --fail-on-warnings)
 *   2 — configuration error (missing repos, parse error)
 *
 * ============================================================================
 */

"use strict";

const fs = require("fs");
const path = require("path");

// ============================================================================
// LIBRARY MODULES (O-018 modularization, 2026-06-21)
// ============================================================================
// Pure functions + constants extracted into lib/ for reuse and isolation.
// See lib/*.js for source. The main file retains stateful / impure code:
//   - extractDeclaration (calls fs.readFileSync)
//   - parseMigrations (calls fs.readFileSync + fs.existsSync)
//   - phase1-phase10 (mutate global `results`)
//   - emitHumanReadable / emitJSON (read global `results`)
//   - main (orchestrates everything)
// ============================================================================

const {
  LAYER_MATRIX,
  COMPAT_MATRIX,
  FORBIDDEN_EDGES,
  REPO_GLOBS,
  ID_REGEX,
  // VALID_DOMAINS is NOT imported here — lib/constants exports the skills-
  // side domain set (MEM/FS/SESSION/...), but verify-id-graph.js has its
  // own standards-side set (META/ARCH/DOC/...) defined inline at line ~897.
  // These are different sets and must not collide.
} = require("./lib/constants");

const {
  parseYAMLFrontmatter,
  parseBlockquoteHeader,
  parseHTMLComment,
  extractReferences,
} = require("./lib/parsers");

const { tarjanSCC } = require("./lib/graph-algorithms");
const { compareSnapshot: compareSnapshotLib } = require("./lib/snapshot");
const { phase10_healthWarnings } = require("./lib/health-warnings");
const { emitHumanReadable: emitHumanReadableLib, emitJSON: emitJSONLib } = require("./lib/output");
const { listFiles, globFiles, matchesPattern, SUBMODULE_DIRS } = require("./lib/file-scanner");
const { extractDeclaration, parseMigrations } = require("./lib/declarations");

// ============================================================================
// CONSTANTS (script-level — not shared with other verifiers)
// ============================================================================

const VERSION = "1.1.7";
const EFFECTIVE_DATE = "2026-07-06";

// ============================================================================
// RESULTS STATE
// ============================================================================

const results = {
  declarations: [], // all ID declarations across all repos
  edges: {
    related: [], // directed edges from Related:
    aligned_with: [], // undirected edges from Aligned_with:
  },
  migrations: [], // parsed MIGRATIONS.md entries
  checks: {
    G01: { status: "PASS", description: "No duplicate IDs across repos", details: [] },
    G02: {
      status: "PASS",
      description: "All Related: references resolve to existing IDs",
      details: [],
    },
    G03: { status: "PASS", description: "No cycles in Related: graph", details: [] },
    G04: { status: "PASS", description: "All Related: edges conform to layer matrix", details: [] },
    G05: {
      status: "PASS",
      description: "No deprecated ID referenced outside migration window",
      details: [],
    },
    G07: { status: "PASS", description: "No STD → (RULE/PROC/TOOL/ZAI) edges", details: [] },
    G08: { status: "PASS", description: "No PROC → ZAI edges", details: [] },
    G09: { status: "PASS", description: "No TOOL → PROC edges", details: [] },
    G10: { status: "PASS", description: "No TOOL → ZAI edges", details: [] },
    G11: { status: "PASS", description: "No self-references", details: [] },
    G12: { status: "PASS", description: "No typo-IDs (format violations)", details: [] },
    G14: { status: "PASS", description: "Compatibility DAG valid for ZAI skills", details: [] },
    G15: {
      status: "PASS",
      description: "Aligned_with: has corresponding Related: edge",
      details: [],
    },
  },
  warnings: [], // W01-W10 entries
  stats: {
    ids_extracted: 0,
    related_edges: 0,
    aligned_with_edges: 0,
    repos_scanned: 0,
  },
};

function fail(checkId, detail) {
  results.checks[checkId].status = "FAIL";
  results.checks[checkId].details.push(detail);
}

function warn(warningId, detail) {
  results.warnings.push({ id: warningId, detail });
}

// ============================================================================
// CLI PARSING
// ============================================================================

function parseArgs(argv) {
  const opts = {
    root: null,
    json: false,
    ci: false,
    failOnWarnings: false,
    verbose: false,
    repo: null,
    help: false,
    snapshot: null,
    compare: null,
    updateSnapshot: false,
  };
  for (const arg of argv.slice(2)) {
    if (arg === "--help" || arg === "-h") opts.help = true;
    else if (arg === "--json") opts.json = true;
    else if (arg === "--ci") opts.ci = true;
    else if (arg === "--fail-on-warnings") opts.failOnWarnings = true;
    else if (arg === "--verbose") opts.verbose = true;
    else if (arg === "--update-snapshot") opts.updateSnapshot = true;
    else if (arg.startsWith("--root=")) opts.root = arg.slice(7);
    else if (arg.startsWith("--repo=")) opts.repo = arg.slice(7);
    else if (arg.startsWith("--snapshot=")) opts.snapshot = arg.slice(11);
    else if (arg.startsWith("--compare=")) opts.compare = arg.slice(10);
    else {
      console.error(`Unknown argument: ${arg}`);
      process.exit(2);
    }
  }
  // --update-snapshot implies --snapshot=baseline.json if no path given
  if (opts.updateSnapshot && !opts.snapshot && !opts.compare) {
    opts.snapshot = "baseline.json";
  }
  return opts;
}

function showHelp() {
  console.log(`
verify-id-graph.js v${VERSION} — Cross-Repo ID Graph Validator

Usage:
  node scripts/verify-id-graph.js [options]

Options:
  --root=<path>        Override platform root
  --json               Output JSON instead of human-readable
  --ci                 Skip network-dependent checks
  --fail-on-warnings   Exit 1 if any warning is emitted
  --verbose            Print full graph
  --repo=<name>        Limit to one repo (debug): standards|guard|skills|platform
  --snapshot=<file>    Write current graph JSON to <file> (creates/overwrites)
  --compare=<file>     Compare current graph to snapshot in <file>; exit 1 on diff
  --update-snapshot    Equivalent to --snapshot=<file> for the path given by
                       --compare, or --snapshot=baseline.json if neither given.
                       Use this to refresh the baseline after an intentional
                       graph change (e.g. adding a new standard ID).
  --help, -h           Show this help

Snapshot testing (v1.1.4+):
  The graph produced by this verifier is deterministic: the same input
  (same set of .md files with the same IDs and Related: edges) MUST
  produce the same JSON output. The --snapshot and --compare flags
  exploit this to detect silent regressions during refactoring.

  Workflow:
    1. Baseline (one-time, or after intentional graph change):
         node verify-id-graph.js --snapshot=baseline.json
    2. CI check (every push):
         node verify-id-graph.js --compare=baseline.json
       Exits 1 if current graph differs from baseline.
    3. Update baseline (after intentional change, reviewed in PR):
         node verify-id-graph.js --update-snapshot --compare=baseline.json

  The snapshot file includes a 'snapshot_meta' block with script_version
  and created_at ISO timestamp. A version mismatch between script and
  baseline is a WARNING, not a FAIL — the structure may still match.

Exit codes:
  0 — all HARD checks pass (warnings may be present); snapshot compare OK
  1 — at least one HARD check failed, OR snapshot compare mismatched
  2 — configuration error (missing repos, parse error, bad CLI args)
`);
}

// ============================================================================
// REPO DISCOVERY
// ============================================================================

function discoverPlatformRoot(opts) {
  // Priority 1: explicit --root
  if (opts.root) {
    if (!fs.existsSync(opts.root)) {
      console.error(`[verify-id-graph] --root path does not exist: ${opts.root}`);
      process.exit(2);
    }
    return opts.root;
  }

  // Priority 2: env var
  if (process.env.ZAI_PLATFORM_ROOT) {
    if (fs.existsSync(process.env.ZAI_PLATFORM_ROOT)) {
      return process.env.ZAI_PLATFORM_ROOT;
    }
  }

  // Priority 3: walk up from script __dirname looking for .gitmodules
  let dir = __dirname;
  for (let i = 0; i < 10; i++) {
    const gitmodules = path.join(dir, ".gitmodules");
    if (fs.existsSync(gitmodules)) {
      const content = fs.readFileSync(gitmodules, "utf8");
      if (
        content.includes("Z-ai-standards") ||
        content.includes("Z-ai-guard") ||
        content.includes("Z-ai-skills")
      ) {
        return dir;
      }
    }
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }

  // Priority 4: assume <platform>/standards/scripts/verify-id-graph.js layout
  // Script is at __dirname, platform root is 3 levels up
  dir = __dirname;
  for (let i = 0; i < 5; i++) {
    // Check if this looks like a platform root (has _design/ or standards/ or skills/)
    if (
      fs.existsSync(path.join(dir, "_design")) ||
      fs.existsSync(path.join(dir, "standards")) ||
      fs.existsSync(path.join(dir, "skills"))
    ) {
      return dir;
    }
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }

  console.error(`[verify-id-graph] Could not discover platform root.`);
  console.error(`  Tried: __dirname walk-up, ZAI_PLATFORM_ROOT env, --root flag`);
  console.error(`  Set --root=<path> or ZAI_PLATFORM_ROOT env var explicitly.`);
  process.exit(2);
}

function findRepos(platformRoot, opts) {
  const repos = {};

  // Look for known repo directory names (case-insensitive)
  const candidates = {
    standards: ["Z-ai-standards", "standards"],
    guard: ["Z-ai-guard", "guard"],
    skills: ["Z-ai-skills", "skills"],
    platform: ["Z-ai-governance", "platform"], // often == platformRoot
  };

  for (const [name, candidatesList] of Object.entries(candidates)) {
    if (opts.repo && opts.repo !== name) continue;
    for (const cand of candidatesList) {
      const p = path.join(platformRoot, cand);
      if (fs.existsSync(p) && fs.statSync(p).isDirectory()) {
        // Skip if it's just the sandbox runtime skills (not a Z-ai-skills repo)
        // The sandbox skills/ dir is at /home/z/my-project/skills/ and contains
        // only Z.ai official skills (no ZAI- IDs). We want to skip it for now.
        // Heuristic: a real Z-ai-skills repo has one of:
        //   - SKILLS.md (legacy marker)
        //   - skill-id-system/ at top level (older layout)
        //   - INDEX.md at root (inline monorepo layout, skills since a3d358b)
        //   - zai-* subdirectories (current layout)
        if (
          name === "skills" &&
          cand === "skills" &&
          !fs.existsSync(path.join(p, "SKILLS.md")) &&
          !fs.existsSync(path.join(p, "skill-id-system")) &&
          !fs.existsSync(path.join(p, "INDEX.md")) &&
          !fs.readdirSync(p).some((d) => d.startsWith("zai-"))
        ) {
          // This is the sandbox runtime skills dir, not the Z-ai-skills repo.
          // Skip unless explicitly requested.
          if (!opts.repo) continue;
        }
        repos[name] = p;
        break;
      }
    }
  }

  // Always include _design/ if it exists (for draft standards during release)
  // This allows verify-id-graph.js to validate drafts before 4-repo migration
  const designDir = path.join(platformRoot, "_design");
  if (fs.existsSync(designDir) && (!opts.repo || opts.repo === "_design")) {
    repos._design = designDir;
  }

  // Always include platform root itself for reference scanning
  if (!repos.platform) {
    repos.platform = platformRoot;
  }

  return repos;
}

// ============================================================================
// FILE SCANNING
// ============================================================================
// Delegated to lib/file-scanner.js (O-018 modularization, 2026-06-21).
// listFiles, globFiles, matchesPattern are imported from lib/file-scanner.js.
// See lib/file-scanner.js for source.

// ============================================================================
// HEADER EXTRACTION (3 formats per spec §4.1)
// ============================================================================

// parseYAMLFrontmatter, parseBlockquoteHeader, parseHTMLComment are now
// required from ./lib/parsers (O-018 modularization). They are unchanged
// — see lib/parsers.js for source.

// extractDeclaration and parseMigrations are now required from
// ./lib/declarations (O-018 modularization continuation, 2026-06-21).
// These are the impure (fs-reading) parsers. See lib/declarations.js
// for source.

// ============================================================================
// REFERENCE EXTRACTION (any mention of an ID in any file)
// ============================================================================

// extractReferences is now required from ./lib/parsers (O-018).

// ============================================================================
// TARJAN'S SCC ALGORITHM (for cycle detection)
// ============================================================================

// tarjanSCC is now required from ./lib/graph-algorithms (O-018).

// ============================================================================
// MAIN PHASES
// ============================================================================

function phase1_extractIDs(repos) {
  // Phase 1: scan all files in each repo, extract declarations
  for (const [repoName, repoPath] of Object.entries(repos)) {
    if (repoName === "_design") {
      // Special: scan _design/ for draft standards
      // List all .md files directly in _design/
      const designFiles = fs
        .readdirSync(repoPath)
        .filter((f) => f.endsWith(".md"))
        .map((f) => path.join(repoPath, f));
      for (const f of designFiles) {
        const decl = extractDeclaration(f, repoName);
        if (decl) results.declarations.push(decl);
      }
      continue;
    }

    const config = REPO_GLOBS[repoName];
    if (!config) continue;
    // When scanning the platform root, skip submodule directories to
    // prevent duplicate IDs (submodules are scanned separately).
    const extraSkip = repoName === "platform" ? SUBMODULE_DIRS : undefined;
    const files = listFiles(repoPath, config.patterns, extraSkip);
    for (const f of files) {
      const decl = extractDeclaration(f, repoName);
      if (decl) results.declarations.push(decl);
    }
  }
  results.stats.ids_extracted = results.declarations.length;
}

function phase2_buildCatalog() {
  // Phase 2: detect duplicate IDs (G01)
  const idMap = new Map();
  for (const decl of results.declarations) {
    if (decl.malformed) continue;
    if (!idMap.has(decl.id)) {
      idMap.set(decl.id, []);
    }
    idMap.get(decl.id).push(decl);
  }
  for (const [id, decls] of idMap) {
    if (decls.length > 1) {
      // Check if it's a duplicate (not just multiple references)
      const files = decls.map((d) => `${d.repo}:${path.basename(d.file)}`);
      fail("G01", `Duplicate ID ${id} declared in: ${files.join(", ")}`);
    }
  }
  return idMap;
}

function phase3_buildEdges(idMap) {
  // Phase 3: build directed (Related:) and undirected (Aligned_with:) edges
  for (const decl of results.declarations) {
    if (decl.malformed) continue;

    // Related: edges (directed)
    for (const target of decl.related) {
      results.edges.related.push({
        source: decl.id,
        target,
        source_file: decl.file,
        source_repo: decl.repo,
        kind: `${decl.prefix}→${(target.match(/^[A-Z]+/) || ["?"])[0]}`,
      });
    }

    // Aligned_with: edges (undirected, stored as lex-ordered pairs)
    for (const target of decl.aligned_with) {
      const left = decl.id < target ? decl.id : target;
      const right = decl.id < target ? target : decl.id;
      // Check if edge already exists (declared by other side)
      const existing = results.edges.aligned_with.find((e) => e.left === left && e.right === right);
      if (existing) {
        existing.reciprocated = true;
      } else {
        results.edges.aligned_with.push({
          left,
          right,
          declared_by: decl.id,
          reciprocated: false,
          file: decl.file,
        });
      }
    }
  }
  results.stats.related_edges = results.edges.related.length;
  results.stats.aligned_with_edges = results.edges.aligned_with.length;
}

function phase4_validateReferences(idMap, migrations) {
  // Phase 4: G02, G05, G12, W01, W10
  for (const edge of results.edges.related) {
    const target = edge.target;

    // G12: format check
    if (!ID_REGEX.test(target)) {
      fail(
        "G12",
        `${edge.source} → ${target}: target does not match ID format (typo?) in ${edge.source_file}`,
      );
      continue;
    }

    // G02: existence check
    if (!idMap.has(target)) {
      // Check if it's a migrated ID
      const mig = migrations.find((m) => m.old_id === target);
      if (mig) {
        // W01 or G05
        warn(
          "W01",
          `${edge.source} references ${target} (deprecated, action=${mig.action}); migration window: until ${mig.window_close_version}`,
        );
      } else {
        fail(
          "G02",
          `${edge.source} → ${target}: target ID does not exist (in ${edge.source_file})`,
        );
      }
    }
  }

  // W10: ZAI skill referenced by ID but missing its own `id` field
  // (Detected when an external reference points to a ZAI-* ID that has no declaration)
  // Already partially covered by G02 — but W10 is specifically for skills
  // For v1.0, we report W10 only if we can identify the missing-declaring skill
  // This requires skill-folder-name ↔ ID mapping which is out of scope for v1.0
}

function phase5_validateLayerEdges() {
  // Phase 5: G04, G07-G10
  for (const edge of results.edges.related) {
    const sourceM = edge.source.match(ID_REGEX);
    const targetM = edge.target.match(ID_REGEX);
    if (!sourceM || !targetM) continue; // already flagged in Phase 4

    const sourcePrefix = sourceM[1];
    const targetPrefix = targetM[1];

    // Check allowed by matrix
    const allowed = LAYER_MATRIX[sourcePrefix];
    if (!allowed || !allowed.has(targetPrefix)) {
      fail(
        "G04",
        `${edge.source} → ${edge.target}: layer edge ${sourcePrefix}→${targetPrefix} not allowed by matrix`,
      );
    }

    // Check specific forbidden patterns
    for (const [gCode, rule] of Object.entries(FORBIDDEN_EDGES)) {
      if (sourcePrefix === rule.from && rule.to.includes(targetPrefix)) {
        fail(
          gCode,
          `${edge.source} → ${edge.target}: forbidden ${gCode} edge (${rule.from}→${targetPrefix})`,
        );
      }
    }
  }
}

function phase6_detectCycles() {
  // Phase 6: G03, G11
  // Self-references (G11)
  for (const edge of results.edges.related) {
    if (edge.source === edge.target) {
      fail("G11", `Self-reference: ${edge.source} → ${edge.target} in ${edge.source_file}`);
    }
  }

  // Cycles (G03) via Tarjan SCC
  const nodes = [
    ...new Set([
      ...results.edges.related.map((e) => e.source),
      ...results.edges.related.map((e) => e.target),
    ]),
  ];
  const sccs = tarjanSCC(nodes, results.edges.related);
  for (const scc of sccs) {
    if (scc.length > 1) {
      fail("G03", `Cycle detected: ${scc.join(" → ")} → ${scc[0]}`);
    }
  }
}

function phase7_alignedWithSymmetry(idMap) {
  // Phase 7: G15, W08
  for (const edge of results.edges.aligned_with) {
    // G15: must have corresponding Related: edge in either direction —
    // BUT only for SAME-LAYER pairs (e.g. STD ↔ STD, RULE ↔ RULE).
    // Cross-layer Aligned_with (e.g. STD ↔ ZAI) is a STANDALONE
    // relationship per STD-META-001 §6.2 — Related is forbidden by
    // G07 in one direction and optional in the other, so requiring it
    // would conflict with G07 and is semantically wrong: Aligned_with
    // IS the cross-layer relationship, not a hint to look for Related.
    const leftPrefix = (edge.left.match(/^[A-Z]+/) || ["?"])[0];
    const rightPrefix = (edge.right.match(/^[A-Z]+/) || ["?"])[0];

    if (leftPrefix === rightPrefix) {
      const hasRelated = results.edges.related.some(
        (e) =>
          (e.source === edge.left && e.target === edge.right) ||
          (e.source === edge.right && e.target === edge.left),
      );
      if (!hasRelated) {
        fail(
          "G15",
          `Aligned_with: ${edge.left} ↔ ${edge.right} has no corresponding Related: edge (declared by ${edge.declared_by})`,
        );
      }
    }

    // W08: reciprocation (applies to ALL Aligned_with edges, regardless of layer)
    if (!edge.reciprocated) {
      warn(
        "W08",
        `${edge.declared_by} declares Aligned_with ${edge.right === edge.declared_by ? edge.left : edge.right}; not reciprocated (in ${edge.file})`,
      );
    }
  }
}

function phase8_compatibilityDAG(idMap) {
  // Phase 8: G14, W07, W09
  // Get ZAI skills with compatibility field
  const zaiSkills = new Map();
  for (const decl of results.declarations) {
    if (decl.prefix === "ZAI" && decl.compatibility) {
      // W09: compatibility declared but no id (this shouldn't happen — if decl exists, id exists)
      // W09 is more for skills without ID that have compatibility — handled at extract time
      zaiSkills.set(decl.id, decl.compatibility);
    }
  }

  // Check ZAI → ZAI edges
  for (const edge of results.edges.related) {
    const sourceM = edge.source.match(ID_REGEX);
    const targetM = edge.target.match(ID_REGEX);
    if (!sourceM || !targetM) continue;
    if (sourceM[1] !== "ZAI" || targetM[1] !== "ZAI") continue;

    const sourceCompat = zaiSkills.get(edge.source);
    const targetCompat = zaiSkills.get(edge.target);

    if (!sourceCompat || !targetCompat) {
      // One of them doesn't have compatibility — skip (warning W09 covered elsewhere)
      continue;
    }

    const allowed = COMPAT_MATRIX[sourceCompat];
    if (!allowed || !allowed.has(targetCompat)) {
      fail(
        "G14",
        `${edge.source} (compat=${sourceCompat}) → ${edge.target} (compat=${targetCompat}): incompatible (allowed targets for ${sourceCompat}: ${[...allowed].join(", ")})`,
      );
    }
  }

  // W07: frontmatter/blockquote disagreement (for ZAI skills with id)
  for (const decl of results.declarations) {
    if (decl.prefix !== "ZAI") continue;
    if (decl._fmId && decl._bqId && decl._fmId !== decl._bqId) {
      warn(
        "W07",
        `${decl.id}: frontmatter id="${decl._fmId}" disagrees with blockquote ID="${decl._bqId}"`,
      );
    }
    if (decl._fmVer && decl._bqVer && decl._fmVer !== decl._bqVer) {
      warn(
        "W07",
        `${decl.id}: frontmatter version="${decl._fmVer}" disagrees with blockquote Version="${decl._bqVer}"`,
      );
    }
  }
}

function phase9_orphanWarnings(idMap) {
  // Phase 9: W02-W06
  const referenced = new Set();
  for (const edge of results.edges.related) {
    referenced.add(edge.target);
  }
  const alignedTargets = new Set();
  for (const edge of results.edges.aligned_with) {
    alignedTargets.add(edge.left);
    alignedTargets.add(edge.right);
  }

  for (const decl of results.declarations) {
    if (decl.malformed) continue;

    if (decl.prefix === "RULE" && decl.related.length === 0) {
      warn("W02", `${decl.id} (${path.basename(decl.file)}): RULE with empty Related: (orphan)`);
    }
    if (decl.prefix === "STD" && !referenced.has(decl.id) && !alignedTargets.has(decl.id)) {
      warn("W03", `${decl.id}: STD not referenced by any RULE/ZAI (dead standard)`);
    }
    if (decl.prefix === "ZAI" && decl.related.length === 0 && decl.aligned_with.length === 0) {
      // W04 only for ZAI WITH IDs (which is the case here since we have a decl)
      warn(
        "W04",
        `${decl.id} (${path.basename(decl.file)}): ZAI skill with empty Related: and Aligned_with: (rogue skill with ID)`,
      );
    }
    if (decl.prefix === "PROC" && decl.related.length === 0) {
      warn("W05", `${decl.id}: PROC with empty Related: (orphan procedure)`);
    }
    if (decl.prefix === "TOOL" && decl.related.length === 0) {
      warn("W06", `${decl.id}: TOOL with empty Related: (orphan tool)`);
    }
  }
}

// ============================================================================
// PHASE 10 — PROJECT HEALTH WARNINGS (W11-W15, v1.1.0)
// ============================================================================
// Delegated to lib/health-warnings.js (O-018 modularization, 2026-06-21).
// The wrapper passes the main verifier's warn() function so warnings land
// in the global results state. See lib/health-warnings.js for source.
//
// v1.1.6 (2026-06-21, O-018): W13 root-cause fix. Expanded candidates list
// to include skills/skills/ tree (resolves path-like refs like
// `commit-work/CONTRACT.md`, `session-handoff/CONTRACT.md`,
// `gepetto/README.md` to actual files). Whitelist shrunk from ~30 entries
// to ~15 (only truly generic/historical refs remain). Per LESSON-001
// (root-cause fix scales as O(1), whitelist symptom-fix scales as O(N)).
// ============================================================================

// ============================================================================
// OUTPUT FORMATTING
// ============================================================================
// Delegated to lib/output.js (O-018 modularization, 2026-06-21).
// Thin wrappers pass the main verifier's results state + version constants.
// See lib/output.js for source.

function emitHumanReadable(opts) {
  return emitHumanReadableLib(results, VERSION, EFFECTIVE_DATE, opts);
}

function emitJSON(opts) {
  return emitJSONLib(results, VERSION, EFFECTIVE_DATE, opts);
}

// ============================================================================
// SNAPSHOT COMPARE
// ============================================================================

/**
 * Compare the current graph (as emitted by emitJSON) to a baseline file.
 *
 * Comparison is structural:
 *   - summary block: exact match required (counts must be identical)
 *   - checks block: every check id+status+description must match; details
 *     arrays are compared as sorted sets (order-independent)
 *   - warnings block: compared as sorted arrays of {code, message} pairs;
 *     order does not matter, but the set must be identical
 *
 * script_version mismatch (in snapshot_meta) is a WARNING printed to stderr,
 * not a comparison failure — the structure may still match.
 *
 * Returns { ok: true } or { ok: false, diff: [string, ...] }.
 */
// compareSnapshot is now required from ./lib/snapshot (O-018).
// Wrapper preserves the original 2-arg signature for backward compat
// (lib/snapshot.js exports a 3-arg version that takes currentVersion
// explicitly, so we pass VERSION here).
function compareSnapshot(currentJSON, baselinePath) {
  return compareSnapshotLib(currentJSON, baselinePath, VERSION);
}

// ============================================================================
// MAIN
// ============================================================================

function main() {
  const opts = parseArgs(process.argv);
  if (opts.help) {
    showHelp();
    process.exit(0);
  }

  const platformRoot = discoverPlatformRoot(opts);
  const repos = findRepos(platformRoot, opts);
  results.stats.repos_scanned = Object.keys(repos).length;

  if (process.env.DEBUG_ID_GRAPH) {
    console.error("[debug] platformRoot:", platformRoot);
    console.error("[debug] repos:", JSON.stringify(repos, null, 2));
  }

  if (results.stats.repos_scanned === 0) {
    console.error("[verify-id-graph] No repos discovered. Use --root=<path>");
    process.exit(2);
  }

  // Parse migrations from each repo
  for (const [repoName, repoPath] of Object.entries(repos)) {
    const migPath = path.join(repoPath, "MIGRATIONS.md");
    if (fs.existsSync(migPath)) {
      results.migrations.push(...parseMigrations(migPath));
    }
  }
  // Also check _design/MIGRATIONS.md
  const designMig = path.join(platformRoot, "_design", "MIGRATIONS.md");
  if (fs.existsSync(designMig)) {
    results.migrations.push(...parseMigrations(designMig));
  }

  // Run all phases
  phase1_extractIDs(repos);

  if (process.env.DEBUG_ID_GRAPH) {
    console.error("[debug] declarations extracted:", results.declarations.length);
    for (const d of results.declarations) {
      console.error(`  ${d.id} (${d.prefix}) from ${path.basename(d.file)}`);
    }
  }

  const idMap = phase2_buildCatalog();
  phase3_buildEdges(idMap);
  phase4_validateReferences(idMap, results.migrations);
  phase5_validateLayerEdges();
  phase6_detectCycles();
  phase7_alignedWithSymmetry(idMap);
  phase8_compatibilityDAG(idMap);
  phase9_orphanWarnings(idMap);
  phase10_healthWarnings(repos, warn);

  // Emit output
  // For snapshot/compare modes we need the JSON payload regardless of
  // --json flag, so we always compute it.
  const jsonPayload = JSON.parse(emitJSON({ ...opts, json: true }));

  if (opts.json) {
    console.log(JSON.stringify(jsonPayload, null, 2));
  } else if (!opts.snapshot && !opts.compare && !opts.updateSnapshot) {
    console.log(emitHumanReadable(opts));
  }

  // Snapshot write (always before compare, so --update-snapshot --compare
  // both writes the new baseline AND verifies it round-trips).
  if (opts.snapshot || (opts.updateSnapshot && opts.compare)) {
    const target = opts.snapshot || opts.compare;
    try {
      // Force snapshot_meta to be included in the written file
      const withMeta = JSON.parse(emitJSON({ snapshot: true }));
      fs.writeFileSync(target, JSON.stringify(withMeta, null, 2) + "\n", "utf8");
      if (!opts.json) {
        console.error(
          `[snapshot] Wrote baseline to ${target} (${withMeta.summary.ids_extracted} IDs, ${withMeta.summary.related_edges} edges, ${withMeta.summary.warnings} warnings)`,
        );
      }
    } catch (e) {
      console.error(`[snapshot] Could not write to ${target}: ${e.message}`);
      process.exit(2);
    }
  }

  // Compare (only when not updating)
  if (opts.compare && !opts.updateSnapshot) {
    const result = compareSnapshot(jsonPayload, opts.compare);
    if (!result.ok) {
      console.error(
        `[snapshot] MISMATCH vs ${opts.compare} (${result.diff.length} difference(s)):`,
      );
      for (const d of result.diff) {
        console.error("  " + d);
      }
      console.error("");
      console.error("[snapshot] If this change is intentional, run:");
      console.error(`  node verify-id-graph.js --update-snapshot --compare=${opts.compare}`);
      console.error("[snapshot] Then commit the updated baseline.");
      process.exit(1);
    } else if (!opts.json) {
      console.error(`[snapshot] OK — current graph matches ${opts.compare}`);
    }
  }

  // Exit code
  const hardFail = Object.values(results.checks).filter((c) => c.status === "FAIL").length;
  if (hardFail > 0) {
    process.exit(1);
  }
  if (opts.failOnWarnings && results.warnings.length > 0) {
    process.exit(1);
  }
  process.exit(0);
}

main();
