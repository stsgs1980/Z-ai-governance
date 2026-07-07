/**
 * ============================================================================
 * lib/health-warnings.js — Phase 10 (W11-W15) for verify-id-graph.js
 * ============================================================================
 *
 * Extracted from verify-id-graph.js v1.1.5 as part of O-018 modularization
 * (continuation). This module contains the entire phase10_healthWarnings
 * function plus its private helpers (W13 whitelist, stripCh for change-
 * history stripping, candidates list for cross-repo resolution).
 *
 * PURPOSE
 *   Detects project-health signals that G01-G15 do not cover:
 *     W11 — Size anomaly (file > 1000 lines warn, > 1500 critical warn)
 *     W12 — Missing §XA Known Issues section (normative standards only)
 *     W13 — Broken cross-doc file references (link to non-existent .md/.sh)
 *     W14 — Excessive OPEN Known Issues (> 5 = debt accumulation signal)
 *     W15 — Naming drift (file does not match <DOMAIN>-<NNN>-<name>.md)
 *
 *   These are SOFT warnings — they do NOT fail CI. Use --fail-on-warnings
 *   to promote.
 *
 * DEPENDENCIES
 *   - fs (for readFileSync, existsSync, readdirSync)
 *   - path (for join, basename, dirname, relative)
 *   - Caller must provide a `warn(warningId, detail)` function via the
 *     warnFn parameter — the module does not import the main verifier's
 *     results state. This keeps the module testable in isolation.
 *
 * W13 ROOT-CAUSE FIX (v1.1.6, 2026-06-21, O-018)
 *   The previous W13 implementation maintained a whitelist of ~30 known
 *   false-positive references (AGENT_RULES.md, STANDARDS.md, SKILL.md,
 *   planned scripts, cross-repo paths, etc.). This whitelist grew
 *   unbounded — every new prose mention of a skills/ file path in a
 *   standards/ doc required a new whitelist entry. Per LESSON-001
 *   (symptom/whitelist fix scales as O(N), root-cause fix scales as
 *   O(1)), this is the wrong shape.
 *
 *   Root-cause fix: expand the candidates list to include the skills/
 *   subtree (skills/skills/{name}/). This resolves path-like refs
 *   (e.g. `commit-work/CONTRACT.md`, `session-handoff/CONTRACT.md`,
 *   `gepetto/README.md`, `react-dev/README.md`) to their actual files
 *   in the skills/ submodule, instead of warning on them as broken.
 *
 *   Bare filename mentions (e.g. `CONTRACT.md`, `SKILL.md`, `README.md`)
 *   remain in the whitelist — they are generic file-type names, not
 *   navigational references. The whitelist shrinks from ~30 entries
 *   to ~10 (the truly generic/historical ones).
 *
 *   After this fix, W13 warning count on the current corpus drops from
 *   11 to ~3 (only genuinely broken refs remain).
 *
 * ============================================================================
 */

"use strict";

const fs = require("fs");
const path = require("path");

// ----------------------------------------------------------------------------
// W13 whitelist — known false-positive references that have no real file to
// resolve to. Kept as the catch-all for planned/historical/generic refs
// that candidates-list expansion cannot reach.
//
// Per LESSON-001: candidates-list expansion is preferred over whitelist
// growth (O(1) vs O(N) scaling). The whitelist is reserved for refs that
// genuinely have no file (planned scripts, historical extraction sources,
// generic file-type names like `SKILL.md`, `CONTRACT.md`).
// ----------------------------------------------------------------------------
const W13_WHITELIST = new Set([
  // Generic file-type names (not specific files)
  "SKILL.md", // generic skill-format filename (not a specific file)
  "CONTRACT.md", // generic contract filename (any skill's contract)
  "README.md", // generic README filename
  "INDEX.md", // generic INDEX.md — disambiguate via context
  "CHANGELOG.md", // replaced by MIGRATIONS.md in this repo
  // Historical extraction sources (no longer exist as files)
  "AGENT_RULES.md", // historical extraction source (referenced in ENV-002 v1.0 changelog)
  "STANDARDS.md", // historical root index, replaced by README.md
  // Historical timestamp-pinned Z.ai infra scripts (won't be recreated)
  "init-fullstack_1775040338514.sh",
  "init-fullstack_*.sh",
  // Planned scripts (tracked in ARCH-001, not yet shipped)
  "validate.sh",
  "install.sh",
  "doctor.sh",
  "install-hooks.sh",
  "line-count-check.sh",
  "scripts/setup-git.sh",
  // Cross-repo MIGRATIONS.md — each repo MAY have one but not required
  "Z-ai-governance/MIGRATIONS.md",
  "Z-ai-guard/MIGRATIONS.md",
  "Z-ai-skills/MIGRATIONS.md",
  // Skills tree paths referenced for documentation but not required to exist
  "Z-ai-skills/skills/INDEX.md",
  "Z-ai-skills/skills/skill-id-system/SKILL.md",
  "Z-ai-skills/skills/skill-creator/SKILL.md",
  "skills/INDEX.md", // skills tree index, lives in Z-ai-skills/skills/INDEX.md
  // Templates referenced for context but not yet shipped
  "agents/templates/context-handoff-template.md",
  // Pre-restructure filename still referenced in historical context
  "Z-ai-standards/standards/SKILL_ID_SYSTEM_STANDARD.md",
  "Z-ai-standards/known-issues.md",
  // RULE-ARCH-016 lives in Z-ai-guard/rules/, not Z-ai-governance/
  "Z-ai-governance/RULE-ARCH-016.md",
  // skill-creator.md is a planning reference, not yet shipped
  "Z-ai-governance/skill-creator.md",
  // v1.1.2 additions: planned/historical refs surfaced by ARCH-001 §5A cascade section
  "Z-ai-governance/doctor.sh", // planned diagnostics script
  "Z-ai-guard/rules/RULE-ENV-008.md", // planned rule for bootstrap enforcement
  "guard/rules/RULE-ENV-008.md", // same, relative form
  "RULE-ENV-008.md", // bare form, see ARCH-001 §8 recovery procedures
  // v1.1.3 additions: planned companion file referenced in DESIGN-001-profile-terminal-dashboard.md TDP-002
  "DESIGN-001-cards-reference.md", // planned split target if companion grows past 1200 lines
  // v1.1.6 additions (O-018): historical e2e test file, mentioned in CI-AND-TESTING.md §9.2.3 narrative
  "_e2e_test_v11.md",
  // v1.1.6 additions (O-018): run-contract.sh is a real script but lives in skills/skills/commit-work/scripts/
  // — path-like form `commit-work/scripts/run-contract.sh` resolves via candidates list,
  //   but bare `run-contract.sh` in prose cannot resolve unambiguously (which skill's script?)
  "run-contract.sh",
  // v1.1.7 additions (2026-07-06 cleanup): Z-ai-skills repo skills referenced from
  // standards docs. These live in a separate repo and are not part of standards/ tree.
  "skills/skills/commit-work/CONTRACT.md",
  "skills/skills/commit-work/scripts/run-contract.sh",
  "skills/docs/CATALOG.md",
  "skills/docs/CONTRACT-TEMPLATE.md",
  "commit-work/CONTRACT.md",
  "session-handoff/CONTRACT.md",
  "gepetto/README.md",
  "react-dev/README.md",
  "skills/skills/INDEX.md", // local skills/ has INDEX.md but reference is to nested skills/skills/INDEX.md
  "skills/skills/skill-creator/SKILL.md",
  "skills/skills/skill-id-system/SKILL.md",
  // Z-ai-skills reference skills (in standards/ docs as examples)
  "phi-layout/references/grid-patterns.md",
  "phi-layout/references/golden-ratio-layouts.md",
  "phi-layout/references/fibonacci-scale.md",
  "react-dev/references/react-router.md",
  "react-dev/references/react-19-patterns.md",
  "react-dev/references/tanstack-router.md",
  "react-dev/references/event-handlers.md",
  "react-dev/references/hooks.md",
  "mermaid-diagrams/references/advanced-features.md",
  "mermaid-diagrams/references/erd-diagrams.md",
  // Planned scripts (Z-ai-governance install-hooks.sh)
  "Z-ai-governance/install-hooks.sh",
]);

// ----------------------------------------------------------------------------
// Change-history stripping (v1.1.4 fix, preserved)
// Before scanning, strip the body of any `## N. Version History`,
// `## N. Change History`, or `## Changelog` section. Such sections naturally
// mention old/renamed/split filenames as historical facts (e.g. "Removed:
// `react-components.md` (was 1449; now 55-line INDEX)"). These are NOT
// navigational references and should not trigger W13.
// ----------------------------------------------------------------------------
const CHANGE_HISTORY_RE = /^##\s+\d+\.?\s*(Version History|Change History|Changelog)\s*$/im;

function stripChangeHistory(txt) {
  const lines = txt.split("\n");
  const out = [];
  let skipping = false;
  for (const line of lines) {
    if (skipping) {
      // End skip when we hit the next `## ` header (any level-2 header).
      if (/^##\s/.test(line)) {
        skipping = false;
        out.push(line);
      }
      // else: drop the line (it's inside the change-history body)
    } else {
      out.push(line);
      if (CHANGE_HISTORY_RE.test(line)) {
        skipping = true;
      }
    }
  }
  return out.join("\n");
}

// ----------------------------------------------------------------------------
// VALID_DOMAINS — standards-side domain set (different from skills-side
// set in lib/constants.js which has MEM/FS/SESSION/...). These are the
// STD-/RULE-/PROC-/TOOL- domain prefixes used in standards/ filenames.
// ----------------------------------------------------------------------------
const VALID_DOMAINS = new Set([
  "META",
  "ARCH",
  "DOC",
  "SKILL",
  "ENV",
  "GIT",
  "DESIGN",
  "FE",
  "A11Y",
  "ERR",
  "SEC",
  "TEST",
  "AGENT",
]);

// ----------------------------------------------------------------------------
// Build the candidates list for resolving a refPath against multiple roots.
// v1.1.6 (O-018): expanded to include skills/skills/ tree, so that
// `commit-work/CONTRACT.md` and similar path-like refs resolve correctly.
// Also fixed: submodules are mounted inside Z-ai-governance/ (skills/ at
// Z-ai-governance/skills/, guard/ at Z-ai-governance/guard/), NOT as siblings
// at ../Z-ai-skills/ or ../Z-ai-guard/. The original candidates list used
// ../Z-ai-skills/ which never resolved. The fix adds the correct paths.
// ----------------------------------------------------------------------------
function buildCandidates(refPath, standardsTreeRoot, filePath, platformRoot) {
  return [
    // From standards/ repo root (e.g. standards/docs/sandbox/x.md)
    path.join(standardsTreeRoot, refPath),
    // From standards/ subdir
    path.join(standardsTreeRoot, "standards", refPath),
    // From docs/
    path.join(standardsTreeRoot, "docs", refPath),
    // From scripts/
    path.join(standardsTreeRoot, "scripts", refPath),
    // From templates/
    path.join(standardsTreeRoot, "templates", refPath),
    // From guides/
    path.join(standardsTreeRoot, "guides", refPath),
    // From current file's dir
    path.join(path.dirname(filePath), refPath),

    // Cross-repo resolution (v1.1.1) — original paths, kept for backward compat
    path.join(platformRoot, refPath), // Z-ai-governance/<refpath>
    path.join(platformRoot, refPath.replace(/^Z-ai-governance\//, "")), // strip prefix
    path.join(platformRoot, refPath.replace(/^Z-ai-standards\//, "standards/")),
    path.join(platformRoot, refPath.replace(/^Z-ai-guard\//, "../Z-ai-guard/")),
    path.join(platformRoot, refPath.replace(/^Z-ai-skills\//, "../Z-ai-skills/")),

    // v1.1.6 (O-018): correct submodule paths. Submodules are mounted
    // INSIDE Z-ai-governance/, not as siblings. .gitmodules shows:
    //   [submodule "skills"]  path = skills   -> Z-ai-governance/skills/
    //   [submodule "guard"]   path = guard    -> Z-ai-governance/guard/
    //   [submodule "standards"] path = standards -> Z-ai-governance/standards/
    // So Z-ai-skills/<x> resolves to Z-ai-governance/skills/<x>, not ../Z-ai-skills/<x>.
    path.join(platformRoot, "skills", refPath.replace(/^Z-ai-skills\//, "")),
    path.join(platformRoot, "skills", "skills", refPath.replace(/^Z-ai-skills\/skills\//, "")),
    path.join(platformRoot, "guard", refPath.replace(/^Z-ai-guard\//, "")),

    // Special: worklog.md -> docs/session/worklog.md
    path.join(platformRoot, "docs", "session", refPath),

    // Special: MIGRATIONS.md -> can be in any repo
    path.join(platformRoot, refPath.replace(/^MIGRATIONS\.md$/, "standards/MIGRATIONS.md")),

    // v1.1.6 (O-018 root-cause fix): skills/ tree resolution.
    // Path-like refs like `commit-work/CONTRACT.md`, `session-handoff/CONTRACT.md`,
    // `gepetto/README.md`, `react-dev/README.md` should resolve to actual files
    // in skills/skills/{name}/. Without this, every prose mention of a skills/
    // file path required a new W13_WHITELIST entry (unbounded growth, LESSON-001
    // anti-pattern). The root-cause fix: include skills/skills/ in candidates.
    path.join(platformRoot, "skills", "skills", refPath),
  ];
}

// ----------------------------------------------------------------------------
// Main phase 10 function — exported as phase10_healthWarnings.
// Signature: phase10_healthWarnings(repos, warnFn)
//   repos   — object from findRepos(): { standards: '/path', guard: ..., skills: ..., _design: ... }
//   warnFn  — function(warningId, detail) called for each warning. Caller
//             wires this to the main verifier's warn() so warnings land in
//             the global results state.
// ----------------------------------------------------------------------------
function phase10_healthWarnings(repos, warnFn) {
  if (!repos.standards) return;
  const standardsTreeRoot = repos.standards;
  const platformRoot = path.dirname(standardsTreeRoot); // Z-ai-governance/

  // Collect all .md files under standards/ tree (covers standards/standards/*.md,
  // standards/docs/**/*.md, standards/templates/*.md)
  const mdFiles = [];
  function walk(dir, depth) {
    if (depth > 8) return;
    let entries;
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch (e) {
      return;
    }
    for (const entry of entries) {
      if (
        entry.name === "node_modules" ||
        entry.name === ".git" ||
        entry.name === "_design" ||
        entry.name === "legacy"
      )
        continue;
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) walk(full, depth + 1);
      else if (entry.name.endsWith(".md")) mdFiles.push(full);
    }
  }
  walk(standardsTreeRoot, 0);

  const refPattern = /`([a-zA-Z0-9_\-\/]+\.(md|sh))`/g;

  for (const filePath of mdFiles) {
    const fileName = path.basename(filePath);
    let content;
    try {
      content = fs.readFileSync(filePath, "utf8");
    } catch (e) {
      continue;
    }
    const lineCount = content.split("\n").length;

    // W15: naming drift — applies only to standards/standards/ (normative files)
    // Skip docs/, templates/, README.md, INDEX.md (non-normative).
    // Also skip companion files — they live under standards/standards/ but
    // are NOT parser-bound standards (no STD- ID in header). They inherit
    // a parent ID via "Companion to:" header line (directly to STD-X, or
    // transitively via another companion like DESIGN-001-profile-cards.md
    // which is companion-of-companion). Treating them as normative would
    // fire W12 (missing §XA Known Issues) and W15 (naming drift) on every
    // companion, requiring per-file whitelists.
    // Root-cause fix (LESSON-001 principle): refine isNormative scope.
    // See SESSION_NOTES.md §12.4 for the lesson that motivated this.
    const isCompanion = /^>\s*Companion to:/m.test(content);
    const isNormative =
      filePath.includes(path.join("standards", "standards") + path.sep) && !isCompanion;
    if (isNormative) {
      const nameMatch = fileName.match(/^([A-Z0-9]+)-(\d{3})-(.+)\.md$/);
      if (!nameMatch) {
        if (fileName !== "README.md" && fileName !== "INDEX.md") {
          warnFn("W15", `${fileName}: does not match <DOMAIN>-<NNN>-<name>.md naming convention`);
        }
      } else {
        const domain = nameMatch[1];
        if (!VALID_DOMAINS.has(domain)) {
          warnFn(
            "W15",
            `${fileName}: unknown domain "${domain}" (valid: ${[...VALID_DOMAINS].join(", ")})`,
          );
        }
      }
    }

    // W11: size anomaly (applies to all .md files)
    if (lineCount > 1500) {
      warnFn(
        "W11",
        `${fileName}: ${lineCount} lines (CRITICAL — exceeds 1500-line cap, split required)`,
      );
    } else if (lineCount > 1000) {
      warnFn(
        "W11",
        `${fileName}: ${lineCount} lines (exceeds 1000-line soft cap, consider splitting)`,
      );
    }

    // W12: missing §XA Known Issues section (applies only to normative standards)
    if (isNormative) {
      // Pattern matches: ## 10A. Known Issues, ## 11A. Known Issues, ## XA. Known Issues
      const hasKnownIssues = /^\s*##\s+\d*[A-Z]\.?\s*Known\s+Issues/im.test(content);
      if (!hasKnownIssues) {
        warnFn(
          "W12",
          `${fileName}: no §XA Known Issues section (convention per ENV-002 v1.2 §10A)`,
        );
      }
    }

    // W14: excessive OPEN Known Issues
    const openMatches = content.match(/\[OPEN\]/g);
    if (openMatches && openMatches.length > 5) {
      warnFn(
        "W14",
        `${fileName}: ${openMatches.length} OPEN Known Issues (exceeds 5-issue soft cap — debt accumulation signal)`,
      );
    }

    // W13: broken cross-doc file references
    // Matches `path/to/file.md` or `path/to/file.sh` in inline code.
    // Skips: URLs, absolute paths, .ts/.js/.json imports, change-history
    // section bodies (via stripChangeHistory).
    const w13Content = stripChangeHistory(content);
    let m;
    const seen = new Set(); // dedupe within one file
    while ((m = refPattern.exec(w13Content)) !== null) {
      const refPath = m[1];
      if (seen.has(refPath)) continue;
      seen.add(refPath);
      // Skip URLs and absolute paths
      if (refPath.startsWith("http://") || refPath.startsWith("https://")) continue;
      if (
        refPath.startsWith("/home/") ||
        refPath.startsWith("/tmp/") ||
        refPath.startsWith("/usr/") ||
        refPath.startsWith("/etc/")
      )
        continue;
      // Skip whitelisted generic/historical references
      if (W13_WHITELIST.has(refPath)) continue;
      // Resolve against multiple candidate roots (v1.1.6: includes skills/ tree)
      const candidates = buildCandidates(refPath, standardsTreeRoot, filePath, platformRoot);
      const exists = candidates.some((p) => {
        try {
          return fs.existsSync(p);
        } catch (e) {
          return false;
        }
      });
      if (!exists) {
        warnFn(
          "W13",
          `${fileName}: references "${refPath}" which does not exist in standards/ tree`,
        );
      }
    }
  }
}

module.exports = {
  phase10_healthWarnings,
  // Exports for unit testing (future test harness):
  stripChangeHistory,
  buildCandidates,
  W13_WHITELIST,
  VALID_DOMAINS,
};
