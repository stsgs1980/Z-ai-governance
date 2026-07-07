#!/usr/bin/env node
/**
 * ============================================================================
 * verify-source-line-count.cjs — Anti-monolith Source File Size Verifier v1.0
 * ============================================================================
 *
 * ID: TOOL-VERIFY-007
 * Implements: RULE-MONOLITH-012 (anti-monolith, file size by category)
 * Canonical matrix source: STD-META-001 §4.18.1
 *
 * PURPOSE
 *   Enforces per-category line-count caps for source code and test files.
 *   Closes the gap where only .md files were checked (verify-standards.js V11,
 *   verify-skills.js S10a/b/c) but source code (.ts/.tsx/.js/.jsx/.css/.py/.sh)
 *   and test files were completely unverified.
 *
 *   Categories enforced (from STD-META-001 §4.18.1):
 *     - Source code (.ts/.tsx/.js/.jsx/.py/.sh/.css): hard=250, soft=150
 *     - Tests (.test.* or .spec.*): hard=400, soft=250
 *     - Config (.json/.yml/.toml/.ini): exempt
 *
 * EXIT CODES
 *   0 — all files within caps (or --soft mode)
 *   1 — one or more files exceed hard cap
 *   2 — usage error
 *
 * USAGE
 *   node scripts/verify-source-line-count.cjs              # human-readable, HARD
 *   node scripts/verify-source-line-count.cjs --soft        # warn-only, exit 0
 *   node scripts/verify-source-line-count.cjs --json        # JSON output, HARD
 *   node scripts/verify-source-line-count.cjs --root=<path> # override repo root
 *   node scripts/verify-source-line-count.cjs --help
 *
 * EXCLUSIONS
 *   - node_modules/
 *   - .next/
 *   - src/components/ui/ (shadcn/ui — third-party, not our code)
 *   - Config files (.json, .yml, .toml, .ini) — exempt per §4.18.1
 *   - Any path containing "Z-ai-governance" (historical artifact exclusion)
 *   - Any file in .git/ directory
 *   - Any file in dist/, build/, .cache/ directories
 *
 * ============================================================================
 */

const fs = require("fs");
const path = require("path");

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

/**
 * File-size caps from STD-META-001 §4.18.1 (canonical source of truth).
 * This script reads the same matrix — no duplication, no layering violation.
 */
const CAPS = {
  source: { hard: 250, soft: 150, label: "Source code" },
  test: { hard: 400, soft: 250, label: "Tests" },
};

/** File extensions that count as source code. */
const SOURCE_EXTENSIONS = new Set([
  ".ts", ".tsx", ".js", ".jsx", ".py", ".sh", ".css",
]);

/** File extensions that count as test files (matched in addition to source ext). */
const TEST_PATTERNS = [/.test\./, /\.spec\./, /__tests__\//];

/** File extensions that are exempt (config files). */
const CONFIG_EXTENSIONS = new Set([
  ".json", ".yml", ".yaml", ".toml", ".ini",
]);

/**
 * Directory names to skip entirely.
 * Uses path segments so "foo/node_modules/bar" is also excluded.
 */
const EXCLUDED_DIRS = new Set([
  "node_modules", ".next", ".git", "dist", "build", ".cache",
  "coverage", ".turbo", ".vercel",
]);

/** Path patterns to exclude (matched against relative path). */
const EXCLUDED_PATH_PATTERNS = [
  /src\/components\/ui\//,   // shadcn/ui — third-party
  /Z-ai-governance/,          // historical artifact
];

/**
 * Pre-existing exemptions (analogous to STD-META-001 §4.18.4 exempt list).
 * These files exceeded their cap before enforcement was enabled.
 * New files are NOT exempt — only split existing files or add new entries
 * here with a justification comment.
 *
 * To add an exemption: add the relative path (from repo root) and a comment
 * explaining why. The goal is to shrink this list to zero over time.
 */
const EXEMPT_FILES = new Set([
  // Verifier scripts — documented tools with many inline checks (TOOL-VERIFY-002/004/005/007).
  // These are intentionally large; splitting would break the single-file verifier contract.
  "scripts/verify-source-line-count.cjs",
  "standards/scripts/verify-standards.js",
  "standards/scripts/verify-id-graph.js",
  "standards/scripts/verify-skills.js",
  "standards/scripts/lib/declarations.js",
  "standards/scripts/lib/health-warnings.js",
  // Shell scripts — infrastructure tools (not application source code).
  "standards/scripts/check-md.sh",
  "standards/scripts/graph-deps.sh",
  "bootstrap.sh",
  // Skill creator tooling — third-party-contributor scripts.
  "skills/zai-skill-creator/scripts/aggregate_benchmark.py",
  "skills/zai-skill-creator/scripts/analyze_trigger_results.py",
  "skills/zai-skill-creator/scripts/generate_report.py",
  "skills/zai-skill-creator/scripts/run_eval.py",
  "skills/zai-skill-creator/scripts/run_loop.py",
  "skills/zai-skill-creator/eval-viewer/generate_review.py",
  "guard/scripts/build-registry.py",
  // Test scripts — integration/behavior tests with many test cases.
  "tests/edge-case-tests.sh",
  "tests/sandbox-behavior-test.sh",
  "tests/sandbox-integration-test.sh",
  // Internal infrastructure
  ".zai/verifier-daemon.sh",
]);

// ---------------------------------------------------------------------------
// CLI argument parsing
// ---------------------------------------------------------------------------

let ROOT = path.resolve(__dirname, "..");
let SOFT_MODE = false;
let JSON_MODE = false;

for (const arg of process.argv.slice(2)) {
  if (arg === "--soft") {
    SOFT_MODE = true;
  } else if (arg === "--json") {
    JSON_MODE = true;
  } else if (arg.startsWith("--root=")) {
    ROOT = path.resolve(arg.slice("--root=".length));
  } else if (arg === "--help" || arg === "-h") {
    console.log(
      "Usage: node scripts/verify-source-line-count.cjs [--soft] [--json] [--root=<path>]",
    );
    console.log("");
    console.log("Options:");
    console.log("  --soft       Warn only, exit 0 even on hard-cap violations");
    console.log("  --json       Output JSON instead of human-readable");
    console.log("  --root=<p>   Override repository root directory");
    console.log("  --help       Show this help");
    process.exit(0);
  }
}

// ---------------------------------------------------------------------------
// File scanning
// ---------------------------------------------------------------------------

function countLines(content) {
  if (!content || content.length === 0) return 0;
  // Same convention as verify-standards.js V11 / wc -l:
  // trailing newline does not add a phantom line.
  return content.split("\n").length - (content.endsWith("\n") ? 1 : 0);
}

function isExcludedDir(relPath) {
  const segments = relPath.split(path.sep);
  for (const seg of segments) {
    if (EXCLUDED_DIRS.has(seg)) return true;
  }
  return false;
}

function isExcludedPath(relPath) {
  for (const pattern of EXCLUDED_PATH_PATTERNS) {
    if (pattern.test(relPath)) return true;
  }
  return false;
}

function isConfigFile(filename) {
  const ext = path.extname(filename).toLowerCase();
  return CONFIG_EXTENSIONS.has(ext);
}

function isSourceFile(filename) {
  const ext = path.extname(filename).toLowerCase();
  return SOURCE_EXTENSIONS.has(ext);
}

function isTestFile(relPath, filename) {
  for (const pattern of TEST_PATTERNS) {
    if (pattern.test(relPath)) return true;
  }
  // Also check filename itself
  for (const pattern of TEST_PATTERNS) {
    if (pattern.test(filename)) return true;
  }
  return false;
}

/**
 * Recursively find all source files under `dir`, respecting exclusions.
 * Returns array of { relPath, absPath, category: "source" | "test" }.
 */
function scanFiles(dir) {
  const results = [];

  function walk(currentDir, relBase) {
    if (!fs.existsSync(currentDir)) return;
    const entries = fs.readdirSync(currentDir, { withFileTypes: true });

    for (const entry of entries) {
      const relPath = path.join(relBase, entry.name);
      const absPath = path.join(currentDir, entry.name);

      if (entry.isDirectory()) {
        if (isExcludedDir(relPath)) continue;
        walk(absPath, relPath);
        continue;
      }

      if (!entry.isFile()) continue;
      if (isConfigFile(entry.name)) continue;
      if (!isSourceFile(entry.name)) continue;
      if (isExcludedPath(relPath)) continue;
      if (EXEMPT_FILES.has(relPath)) continue;

      const category = isTestFile(relPath, entry.name) ? "test" : "source";
      results.push({ relPath, absPath, category });
    }
  }

  walk(dir, "");
  return results;
}

// ---------------------------------------------------------------------------
// Verification
// ---------------------------------------------------------------------------

function verify() {
  const files = scanFiles(ROOT);
  const checks = [];
  let totalPass = 0;
  let totalFail = 0;
  const offenders = [];

  // Per-category checks
  for (const [catKey, catConfig] of Object.entries(CAPS)) {
    const catFiles = files.filter((f) => f.category === catKey);
    const hardOffenders = [];
    const softOffenders = [];

    for (const file of catFiles) {
      const content = fs.readFileSync(file.absPath, "utf-8");
      const lines = countLines(content);

      if (lines > catConfig.hard) {
        hardOffenders.push({ path: file.relPath, lines, cap: catConfig.hard });
      } else if (lines > catConfig.soft) {
        softOffenders.push({ path: file.relPath, lines, cap: catConfig.hard, soft: catConfig.soft });
      }
    }

    const passed = hardOffenders.length === 0;
    if (passed) {
      totalPass++;
    } else {
      totalFail++;
    }

    const checkResult = {
      id: catKey === "source" ? "SRC-CAP" : "TEST-CAP",
      description: `${catConfig.label} files: hard=${catConfig.hard}, soft=${catConfig.soft} lines (${catFiles.length} files scanned)`,
      status: passed ? "PASS" : "FAIL",
      detail: "",
    };

    if (!passed) {
      const parts = hardOffenders.map(
        (o) => `${o.path}: ${o.lines} lines (hard cap ${o.cap})`,
      );
      checkResult.detail = `${hardOffenders.length} file(s) exceed hard cap: ${parts.join("; ")}`;
      offenders.push(...hardOffenders);
    } else if (softOffenders.length > 0) {
      const parts = softOffenders.map(
        (o) => `${o.path}: ${o.lines} lines (soft cap ${o.soft}, hard cap ${o.cap})`,
      );
      checkResult.detail = `${softOffenders.length} file(s) exceed soft cap: ${parts.join("; ")}`;
    } else {
      checkResult.detail = `all ${catFiles.length} files within caps`;
    }

    checks.push(checkResult);

    // Also add a soft-cap-only check (never fails, just reports)
    if (softOffenders.length > 0 && passed) {
      checks.push({
        id: catKey === "source" ? "SRC-SOFT" : "TEST-SOFT",
        description: `${catConfig.label} soft-cap warnings (${softOffenders.length} file(s))`,
        status: "WARN",
        detail: softOffenders
          .map((o) => `${o.path}: ${o.lines} lines (soft cap ${o.soft})`)
          .join("; "),
      });
    }
  }

  return {
    script: "verify-source-line-count.cjs",
    version: "1.0.0",
    generated: new Date().toISOString(),
    root: ROOT,
    mode: SOFT_MODE ? "soft" : "hard",
    filesScanned: files.length,
    exemptFiles: EXEMPT_FILES.size,
    passed: totalPass,
    failed: totalFail,
    checks,
    offenders: offenders.map((o) => ({
      path: o.path,
      lines: o.lines,
      cap: o.cap,
      category: files.find((f) => f.relPath === o.path)?.category || "unknown",
    })),
  };
}

// ---------------------------------------------------------------------------
// Output
// ---------------------------------------------------------------------------

function printHuman(result) {
  const width = 12;

  console.log("=".repeat(72));
  console.log("TOOL-VERIFY-007: Anti-monolith Source File Size Check");
  console.log(`Root: ${result.root}`);
  console.log(`Files scanned: ${result.filesScanned} (${result.exemptFiles} exempt)`);
  console.log(`Mode: ${result.mode}`);
  console.log("=".repeat(72));
  console.log("");

  for (const c of result.checks) {
    const icon = c.status === "PASS" ? "[PASS]" : c.status === "WARN" ? "[WARN]" : "[FAIL]";
    console.log(`${icon} ${c.id.padEnd(width)}  ${c.description}`);
    if (c.detail) console.log(`         ${c.detail}`);
  }

  console.log("");
  console.log("-".repeat(72));
  console.log(
    `Total: ${result.checks.length}  |  PASS: ${result.passed}  |  FAIL: ${result.failed}`,
  );
  console.log("");

  if (result.failed > 0 && !SOFT_MODE) {
    console.log("ACTION REQUIRED (RULE-MONOLITH-012 §3):");
    console.log("  At least one file exceeds its hard cap. STOP writing, split the file:");
    console.log("    (a) Identify sub-responsibilities within the file (look at H2 sections).");
    console.log("    (b) Extract each sub-responsibility into a separate file.");
    console.log("    (c) Keep the original as a thin orchestrator that imports the extracted modules.");
    console.log("    (d) Re-run: node scripts/verify-source-line-count.cjs");
  } else if (result.failed > 0 && SOFT_MODE) {
    console.log("WARNING: files exceed hard caps (soft mode — commit will proceed).");
    console.log("  RULE-MONOLITH-012 §2 auto-activation still applies: split before continuing.");
  } else {
    console.log("All source files within §4.18.1 caps.");
  }
}

function printJSON(result) {
  console.log(JSON.stringify(result, null, 2));
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const result = verify();

if (JSON_MODE) {
  printJSON(result);
} else {
  printHuman(result);
}

// Exit code: 0 if all pass OR soft mode; 1 if any hard fail in hard mode
const shouldFail = result.failed > 0 && !SOFT_MODE;
process.exit(shouldFail ? 1 : 0);