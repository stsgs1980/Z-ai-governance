/**
 * ============================================================================
 * lib/constants.js — shared constants for verify-id-graph.js
 * ============================================================================
 *
 * Extracted from verify-id-graph.js v1.1.4 as part of O-018 modularization.
 * Pure data module — no functions, no side effects. Safe to require() from
 * any verifier or test harness.
 *
 * Consumers:
 *   - verify-id-graph.js (primary)
 *   - verify-skills.js (could consume VALID_DOMAINS, ID_REGEX — TODO)
 *   - future test harness for graph invariants
 *
 * Source of truth for: LAYER_MATRIX, COMPAT_MATRIX, FORBIDDEN_EDGES,
 * REPO_GLOBS, ID_REGEX, VALID_DOMAINS.
 *
 * Do NOT modify these constants without bumping verify-id-graph.js
 * VERSION (currently 1.1.x) and updating the snapshot baseline at
 * standards/_snapshots/id-graph-baseline.json.
 *
 * ============================================================================
 */

"use strict";

// Allowed Related: edges per STD-META-001 §6.1
// Matrix: source prefix → set of allowed target prefixes
const LAYER_MATRIX = {
  STD: new Set(["STD"]),
  RULE: new Set(["STD", "RULE", "PROC", "TOOL", "ZAI"]),
  PROC: new Set(["STD", "RULE", "PROC", "TOOL"]),
  TOOL: new Set(["STD", "RULE", "TOOL"]),
  ZAI: new Set(["STD", "RULE", "TOOL", "ZAI"]),
};

// Compatibility DAG per STD-SKILL-001 §7.2
// Source compatibility → allowed target compatibility
const COMPAT_MATRIX = {
  both: new Set(["both"]),
  sandbox: new Set(["both", "sandbox"]),
  ade: new Set(["both", "ade"]),
};

// Forbidden layer edges (G07-G10)
const FORBIDDEN_EDGES = {
  G07: { from: "STD", to: ["RULE", "PROC", "TOOL", "ZAI"] },
  G08: { from: "PROC", to: ["ZAI"] },
  G09: { from: "TOOL", to: ["PROC"] },
  G10: { from: "TOOL", to: ["ZAI"] },
};

// Repo discovery globs per spec §3.2
const REPO_GLOBS = {
  standards: {
    patterns: ["standards/**/*.md", "STANDARDS.md", "*.md"],
    prefix: "STD",
  },
  guard: {
    patterns: [
      "AGENT_RULES.md",
      "AGENT-RULES.md",
      "rules/**/*.md",
      "instructions/**/*.md",
      "scripts/**/*.{sh,js,ts}",
      "tools/**/*.{md,ts,js}",
    ],
    prefixes: ["RULE", "PROC", "TOOL"],
  },
  skills: {
    patterns: ["*/SKILL.md", "*.md"],
    prefixes: ["ZAI"],
  },
  platform: {
    patterns: ["*.md", "docs/**/*.md", "templates/**/*.md"],
    prefixes: [], // platform declares no IDs; only scanned for references
  },
};

// ID format regex
const ID_REGEX = /^(STD|RULE|PROC|TOOL|ZAI)-([A-Z]+)-(\d{3})$/;

// Valid ZAI skill domains (per STD-SKILL-001 §4.3)
const VALID_DOMAINS = new Set([
  "MEM",
  "FS",
  "SESSION",
  "DEV",
  "ARCH",
  "QA",
  "REQ",
  "META",
  "STS",
  "SDK",
  "DOC",
  "HEALTH",
  "CHART",
  "DEVTOOLS", // sandbox variant for skill-creator (originally ZAI-META-002)
]);

module.exports = {
  LAYER_MATRIX,
  COMPAT_MATRIX,
  FORBIDDEN_EDGES,
  REPO_GLOBS,
  ID_REGEX,
  VALID_DOMAINS,
};
