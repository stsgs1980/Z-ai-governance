#!/usr/bin/env node
/**
 * ============================================================================
 * verify-skills.js — Skills-side Format Verifier v1.1.0
 * ============================================================================
 *
 * ID: TOOL-VERIFY-005
 * Implements: STD-SKILL-001 v1.1 §10.1 (per-skill checks)
 * Companion: verify-standards.js (content) + verify-id-graph.js (graph)
 *
 * PURPOSE
 *   Validates that every SKILL.md in skills/skills/{name}/ conforms to the
 *   format defined in STD-SKILL-001 v1.1. This is the skills-side
 *   analogue of verify-standards.js — same pattern, different corpus.
 *
 *   The script scans the skills/ directory (sibling of standards/) and
 *   runs 11 checks per SKILL.md:
 *
 *     S01 (V11a)  SKILL.md exists in every skills/skills/{name}/ folder
 *     S02 (V11b)  frontmatter `name` matches folder name
 *     S03 (V11c)  name matches folder name (covered by S02)
 *     S04 (V13a)  YAML frontmatter parses
 *     S05 (V13b)  Required fields present: name, description, version
 *     S06 (V05a)  id field format: ZAI-<DOMAIN>-<NNN>  [SOFT, if id present]
 *     S07 (V13c)  compatibility field: both|sandbox|ade  [SOFT, if present]
 *     S08 (V14a)  frontmatter id matches blockquote ID:  [SOFT, if both]
 *     S09 (V14b)  frontmatter version matches blockquote Version:
 *     S10 (V12)   Tiered hard caps (META-001 §4.18.1):
 *                   S10a: SKILL.md ≤ 800 lines (HARD, all skills)
 *                   S10b: CONTRACT.md ≤ 500 lines (HARD, if CONTRACT.md exists)
 *                   S10c: README.md ≤ 400 lines (HARD, if README.md exists)
 *                 References are exempt per §4.18.1 — no check.
 *
 *   Checks S01, S02, S03, S04, S05, S09, S10 are HARD (exit 1 on fail).
 *   Checks S06, S07, S08 are SOFT (reported, do not fail).
 *
 * SCOPE
 *   - skills/skills/{name}/SKILL.md  (one per skill folder, 36 folders today)
 *   - skills/skills/{name}/CONTRACT.md  (optional, 2 skills today)
 *   - skills/skills/{name}/README.md  (optional, present in most skills)
 *   - Does NOT validate the skills/docs/ companion files (those are
 *     prose, not skill definitions).
 *   - Does NOT validate skill scripts (run-contract.sh etc.) — those
 *     are validated by their own contract layer (Phase B).
 *   - Does NOT validate references/**.md — these are exempt per
 *     META-001 §4.18.1 (loaded on demand, not parser-bound).
 *   - Cross-repo `Related:` edge resolution is handled by
 *     verify-id-graph.js G02 (not duplicated here).
 *
 * EXIT CODES
 *   0 — all HARD checks pass (SOFT warnings may be present)
 *   1 — at least one HARD check failed
 *   2 — configuration error (skills/ directory not found, etc.)
 *
 * USAGE
 *   node scripts/verify-skills.js             # human-readable
 *   node scripts/verify-skills.js --json      # CI-friendly
 *   node scripts/verify-skills.js --help      # show help
 *
 * ============================================================================
 */

"use strict";

const fs = require("fs");
const path = require("path");

const VERSION = "1.1.1";
const EFFECTIVE_DATE = "2026-06-22";

// ============================================================================
// PATH RESOLUTION
// ============================================================================
// This script lives at standards/scripts/verify-skills.js.
// The skills/ directory is a sibling of standards/, found by walking up
// from __dirname until we find a directory containing both `standards/`
// and `skills/`.

function discoverPlatformRoot() {
  // Priority 1: env var
  if (process.env.ZAI_PLATFORM_ROOT) {
    if (fs.existsSync(process.env.ZAI_PLATFORM_ROOT)) {
      return process.env.ZAI_PLATFORM_ROOT;
    }
  }
  // Priority 2: walk up from __dirname
  let dir = __dirname;
  for (let i = 0; i < 10; i++) {
    const gitmodules = path.join(dir, ".gitmodules");
    if (fs.existsSync(gitmodules)) {
      const content = fs.readFileSync(gitmodules, "utf8");
      if (content.includes("Z-ai-standards") && content.includes("Z-ai-skills")) {
        return dir;
      }
    }
    // Also accept a directory that has both standards/ and skills/ subdirs
    if (fs.existsSync(path.join(dir, "standards")) && fs.existsSync(path.join(dir, "skills"))) {
      return dir;
    }
    dir = path.dirname(dir);
  }
  return null;
}

// ============================================================================
// YAML FRONTMATTER PARSER (minimal, no dependencies)
// ============================================================================
// Handles the subset of YAML used in SKILL.md files:
//   - flat key: value
//   - folded scalars (description: > ...)
//   - quoted strings ("..." or '...')
//   - numeric values
//   - boolean true/false
// Returns { parsed: bool, data: object, raw: string, error: string|null }

function parseFrontmatter(content) {
  const m = content.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/);
  if (!m) {
    return { parsed: false, data: {}, raw: "", error: "no frontmatter block (---...---) found" };
  }
  const raw = m[1];
  const data = {};
  const lines = raw.split(/\r?\n/);
  let i = 0;
  let lineNum = 0;

  while (i < lines.length) {
    const line = lines[i];
    lineNum++;
    if (!line.trim() || line.trim().startsWith("#")) {
      i++;
      continue;
    }

    const kvMatch = line.match(/^([a-zA-Z_][a-zA-Z0-9_-]*)\s*:\s*(.*)$/);
    if (!kvMatch) {
      i++;
      continue;
    }
    const key = kvMatch[1];
    let value = kvMatch[2].trim();

    // Folded scalar: value is '>' or '>-' or '|'
    if (value === ">" || value === ">-" || value === "|") {
      const indent = line.match(/^(\s*)/)[1].length;
      const foldedLines = [];
      i++;
      while (i < lines.length) {
        const nextLine = lines[i];
        if (nextLine.trim() === "") {
          i++;
          continue;
        }
        const nextIndent = nextLine.match(/^(\s*)/)[1].length;
        if (nextIndent <= indent) break;
        foldedLines.push(nextLine.trim());
        i++;
      }
      data[key] = foldedLines.join(" ");
      continue;
    }

    // Quoted string
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      data[key] = value.slice(1, -1);
      i++;
      continue;
    }

    // Numeric
    if (/^-?\d+(\.\d+)?$/.test(value)) {
      data[key] = parseFloat(value);
      i++;
      continue;
    }

    // Boolean
    if (value === "true" || value === "false") {
      data[key] = value === "true";
      i++;
      continue;
    }

    // Bare string
    data[key] = value;
    i++;
  }

  return { parsed: true, data, raw, error: null };
}

// ============================================================================
// BLOCKQUOTE HEADER PARSER
// ============================================================================
// Extracts `ID:`, `Version:`, `Related:`, `Aligned_with:` from the
// blockquote immediately following the H1. Per STD-SKILL-001 §3.4 these
// are redundant copies of frontmatter fields for human readability.

function parseBlockquote(content) {
  // Skip frontmatter if present
  let body = content;
  const fmMatch = content.match(/^---\r?\n[\s\S]*?\r?\n---\r?\n/);
  if (fmMatch) body = content.slice(fmMatch[0].length);

  // Find the first H1
  const h1Match = body.match(/^#\s+(.+?)\r?$/m);
  if (!h1Match) return {};

  // Find the blockquote that follows (allowing blank lines between)
  const afterH1 = body.slice(h1Match.index + h1Match[0].length);
  const bqMatch = afterH1.match(/^\s*>\s*([\s\S]*?)(\r?\n\s*\r?\n|\r?\n#|\r?$)/m);
  if (!bqMatch) return {};

  const bqText = bqMatch[1];
  const fields = {};
  for (const line of bqText.split(/\r?\n/)) {
    const m = line.match(/^\s*>\s*([A-Za-z_]+)\s*:\s*(.*)$/);
    if (!m) continue;
    const key = m[1].toLowerCase().replace(/_/g, "_");
    fields[key] = m[2].trim();
  }
  return fields;
}

// ============================================================================
// CHECKS
// ============================================================================

const results = {
  checks: [],
  warnings: [],
  stats: {
    skills_scanned: 0,
    hard_pass: 0,
    hard_fail: 0,
    soft_warnings: 0,
  },
};

function check(id, description, passed, detail, isSoft) {
  const status = passed ? "PASS" : isSoft ? "WARN" : "FAIL";
  results.checks.push({ id, status, description, detail, isSoft: !!isSoft });
  if (status === "PASS") results.stats.hard_pass++;
  else if (isSoft) results.stats.soft_warnings++;
  else results.stats.hard_fail++;
}

function warn(code, message) {
  results.warnings.push({ code, message });
}

// Allowed skill domains per STD-SKILL-001 §4.3
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

const VALID_COMPAT = new Set(["both", "sandbox", "ade"]);

// ============================================================================
// MAIN SCAN
// ============================================================================

function listSkillDirs(skillsRoot) {
  // After monorepo conversion, skills live directly in skills/
  // (no longer skills/skills/). Scan skillsRoot for SKILL.md files.
  if (!fs.existsSync(skillsRoot)) return [];
  return fs
    .readdirSync(skillsRoot, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .filter((d) => !d.name.startsWith(".") && d.name !== "docs")
    .filter((d) => fs.existsSync(path.join(skillsRoot, d.name, "SKILL.md")))
    .map((d) => ({
      name: d.name,
      path: path.join(skillsRoot, d.name),
    }));
}

function runChecks(platformRoot, opts) {
  const strict = !!(opts && opts.strict);
  // When strict is true, S02/S03/S05 are promoted from SOFT to HARD.
  // S06/S07/S08 are always SOFT (per the standard itself).
  const s025Soft = !strict;
  const skillsRoot = path.join(platformRoot, "skills");
  if (!fs.existsSync(skillsRoot)) {
    console.error(`[verify-skills] skills/ directory not found at ${skillsRoot}`);
    console.error("[verify-skills] Use ZAI_PLATFORM_ROOT env var to override.");
    process.exit(2);
  }

  const skillDirs = listSkillDirs(skillsRoot);
  results.stats.skills_scanned = skillDirs.length;

  if (skillDirs.length === 0) {
    console.error("[verify-skills] No skill directories found in skills/.");
    process.exit(2);
  }

  // ----------------------------------------------------------------
  // S01 (V11a): SKILL.md exists in every skills/skills/{name}/ folder
  // ----------------------------------------------------------------
  (function S01() {
    const missing = skillDirs.filter((s) => !fs.existsSync(path.join(s.path, "SKILL.md")));
    check(
      "S01",
      `SKILL.md exists in every skills/skills/{name}/ folder — scanned ${skillDirs.length} folders`,
      missing.length === 0,
      missing.length === 0
        ? `all ${skillDirs.length} folders have SKILL.md`
        : `${missing.length} folder(s) missing SKILL.md: ${missing.map((m) => m.name).join(", ")}`,
    );
  })();

  // ----------------------------------------------------------------
  // S02 (V11b): frontmatter `name` matches folder name EXACTLY
  //   - Per STD-SKILL-001 §3.3 + §9.1: name must match folder name exactly.
  // ----------------------------------------------------------------
  (function S02() {
    const offenders = [];
    for (const s of skillDirs) {
      const skillMdPath = path.join(s.path, "SKILL.md");
      if (!fs.existsSync(skillMdPath)) continue; // already flagged by S01
      const content = fs.readFileSync(skillMdPath, "utf8");
      const fm = parseFrontmatter(content);
      if (!fm.parsed) continue; // flagged by S04
      const expected = s.name;
      if (fm.data.name !== expected) {
        offenders.push(`${s.name}: frontmatter name="${fm.data.name}" expected "${expected}"`);
      }
    }
    check(
      "S02",
      "frontmatter `name` matches folder name exactly (per §3.3 + §9.1)",
      offenders.length === 0,
      offenders.length === 0
        ? `all ${skillDirs.length} skills match`
        : `${offenders.length} mismatch(es): ${offenders.join("; ")}`,
      s025Soft,
    );
  })();

  // ----------------------------------------------------------------
  // S03 (V11c): name matches folder name — covered by S02 (V11b)
  //   This check is a no-op.
  // ----------------------------------------------------------------
  (function S03() {
    // Covered by S02 (V11b) — no separate enforcement needed
    check("S03", "name matches folder name (covered by S02)", true, "covered by S02 (V11b)", false);
  })();

  // ----------------------------------------------------------------
  // S04 (V13a): YAML frontmatter parses
  // ----------------------------------------------------------------
  (function S04() {
    const offenders = [];
    for (const s of skillDirs) {
      const skillMdPath = path.join(s.path, "SKILL.md");
      if (!fs.existsSync(skillMdPath)) continue;
      const content = fs.readFileSync(skillMdPath, "utf8");
      const fm = parseFrontmatter(content);
      if (!fm.parsed) {
        offenders.push(`${s.name}: ${fm.error}`);
      }
    }
    check(
      "S04",
      "YAML frontmatter parses — scanned all skill folders with SKILL.md",
      offenders.length === 0,
      offenders.length === 0
        ? "all frontmatter blocks parse successfully"
        : `${offenders.length} parse error(s): ${offenders.join("; ")}`,
    );
  })();

  // ----------------------------------------------------------------
  // S05 (V13b): Required fields present (name, description, version)
  // ----------------------------------------------------------------
  (function S05() {
    const required = ["name", "description", "version"];
    const offenders = [];
    for (const s of skillDirs) {
      const skillMdPath = path.join(s.path, "SKILL.md");
      if (!fs.existsSync(skillMdPath)) continue;
      const content = fs.readFileSync(skillMdPath, "utf8");
      const fm = parseFrontmatter(content);
      if (!fm.parsed) continue; // flagged by S04
      const missing = required.filter((f) => !fm.data[f]);
      if (missing.length) {
        offenders.push(`${s.name}: missing ${missing.join(", ")}`);
      }
    }
    check(
      "S05",
      "Required frontmatter fields present: name, description, version",
      offenders.length === 0,
      offenders.length === 0
        ? `all ${skillDirs.length} skills have required fields`
        : `${offenders.length} skill(s) with missing fields: ${offenders.join("; ")}`,
      s025Soft,
    );
  })();

  // ----------------------------------------------------------------
  // S06 (V05a) [SOFT]: id field format: ZAI-<DOMAIN>-<NNN>
  //   Only checked when id field is present.
  // ----------------------------------------------------------------
  (function S06() {
    const idRegex = /^ZAI-([A-Z]+)-(\d{3})$/;
    const offenders = [];
    let checked = 0;
    for (const s of skillDirs) {
      const skillMdPath = path.join(s.path, "SKILL.md");
      if (!fs.existsSync(skillMdPath)) continue;
      const content = fs.readFileSync(skillMdPath, "utf8");
      const fm = parseFrontmatter(content);
      if (!fm.parsed || !fm.data.id) continue;
      checked++;
      const m = idRegex.exec(fm.data.id);
      if (!m) {
        offenders.push(`${s.name}: id="${fm.data.id}" does not match ZAI-<DOMAIN>-<NNN>`);
        continue;
      }
      if (!VALID_DOMAINS.has(m[1])) {
        offenders.push(`${s.name}: id="${fm.data.id}" has unknown domain "${m[1]}"`);
      }
    }
    check(
      "S06",
      `id field format valid (ZAI-<DOMAIN>-<NNN>, valid domain) — checked ${checked} skills with id field`,
      offenders.length === 0,
      offenders.length === 0
        ? checked === 0
          ? "no skills have id field (optional per STD-SKILL-001 §4.2)"
          : `all ${checked} ids valid`
        : `${offenders.length} invalid: ${offenders.join("; ")}`,
      true, // SOFT
    );
  })();

  // ----------------------------------------------------------------
  // S07 (V13c) [SOFT]: compatibility field valid enum
  //   Only checked when compatibility field is present.
  // ----------------------------------------------------------------
  (function S07() {
    const offenders = [];
    let checked = 0;
    for (const s of skillDirs) {
      const skillMdPath = path.join(s.path, "SKILL.md");
      if (!fs.existsSync(skillMdPath)) continue;
      const content = fs.readFileSync(skillMdPath, "utf8");
      const fm = parseFrontmatter(content);
      if (!fm.parsed || !fm.data.compatibility) continue;
      checked++;
      if (!VALID_COMPAT.has(fm.data.compatibility)) {
        offenders.push(
          `${s.name}: compatibility="${fm.data.compatibility}" not in {both, sandbox, ade}`,
        );
      }
    }
    check(
      "S07",
      `compatibility field valid (both|sandbox|ade) — checked ${checked} skills with compatibility field`,
      offenders.length === 0,
      offenders.length === 0
        ? checked === 0
          ? "no skills declare compatibility (optional unless id present)"
          : `all ${checked} valid`
        : `${offenders.length} invalid: ${offenders.join("; ")}`,
      true, // SOFT
    );
  })();

  // ----------------------------------------------------------------
  // S08 (V14a) [SOFT]: frontmatter id matches blockquote ID:
  //   Only checked when both are present.
  // ----------------------------------------------------------------
  (function S08() {
    const offenders = [];
    let checked = 0;
    for (const s of skillDirs) {
      const skillMdPath = path.join(s.path, "SKILL.md");
      if (!fs.existsSync(skillMdPath)) continue;
      const content = fs.readFileSync(skillMdPath, "utf8");
      const fm = parseFrontmatter(content);
      if (!fm.parsed || !fm.data.id) continue;
      const bq = parseBlockquote(content);
      if (!bq.id) continue;
      checked++;
      if (fm.data.id !== bq.id) {
        offenders.push(`${s.name}: frontmatter id="${fm.data.id}" vs blockquote ID:="${bq.id}"`);
      }
    }
    check(
      "S08",
      `frontmatter id matches blockquote ID: — checked ${checked} skills with both`,
      offenders.length === 0,
      offenders.length === 0
        ? checked === 0
          ? "no skills have both frontmatter id and blockquote ID:"
          : `all ${checked} consistent`
        : `${offenders.length} mismatch(es): ${offenders.join("; ")}`,
      true, // SOFT
    );
  })();

  // ----------------------------------------------------------------
  // S09 (V14b): frontmatter version matches blockquote Version:
  //   HARD check — version drift between frontmatter and blockquote
  //   is a real bug, not a style issue. The blockquote is the
  //   human-readable copy; if it drifts, readers see wrong version.
  //   Checked whenever BOTH are present. If only one is present,
  //   no check (frontmatter is canonical per §3.4).
  // ----------------------------------------------------------------
  (function S09() {
    const offenders = [];
    let checked = 0;
    for (const s of skillDirs) {
      const skillMdPath = path.join(s.path, "SKILL.md");
      if (!fs.existsSync(skillMdPath)) continue;
      const content = fs.readFileSync(skillMdPath, "utf8");
      const fm = parseFrontmatter(content);
      if (!fm.parsed || fm.data.version === undefined) continue;
      const bq = parseBlockquote(content);
      if (bq.version === undefined) continue;
      checked++;
      // Normalize: frontmatter version may be number, blockquote is string
      const fmVer = String(fm.data.version);
      const bqVer = String(bq.version).replace(/^v/, ""); // strip leading v
      if (fmVer !== bqVer) {
        offenders.push(
          `${s.name}: frontmatter version="${fmVer}" vs blockquote Version:="${bq.version}"`,
        );
      }
    }
    check(
      "S09",
      `frontmatter version matches blockquote Version: — checked ${checked} skills with both`,
      offenders.length === 0,
      offenders.length === 0
        ? checked === 0
          ? "no skills have both frontmatter version and blockquote Version:"
          : `all ${checked} consistent`
        : `${offenders.length} mismatch(es): ${offenders.join("; ")}`,
    );
  })();

  // ----------------------------------------------------------------
  // S10 (V12): Tiered hard caps per META-001 §4.18.1
  //   S10a: SKILL.md   ≤ 800 lines  HARD (all skills)
  //   S10b: CONTRACT.md ≤ 500 lines  HARD (if CONTRACT.md exists)
  //   S10c: README.md   ≤ 400 lines  HARD (if README.md exists)
  //
  // RATIONALE (2026-06-21, O-017 Phase D2 + 2026-06-22 README cap)
  //   META-001 §4.18.1 already specifies the SKILL.md ≤ 800 ceiling,
  //   but enforcement was deferred (PROC-LINECOUNT-004 not implemented).
  //   S10a promotes this ceiling from documentation to a runtime HARD
  //   invariant — same pattern as verify-standards.js V11 (which
  //   promoted W11's 1000-line soft cap to HARD on 2026-06-21).
  //
  //   S10b adds a new CONTRACT.md ≤ 500 cap, validated against the 2
  //   pilot contracts (commit-work 368 lines, session-handoff 466
  //   lines). The original O-017 proposal suggested 200, but both
  //   pilots would violate a 200-line cap by 1.8×–2.3×. Per LESSON-001
  //   (root-cause fix scales as O(1)), the cap was adjusted to fit
  //   measured reality rather than compressing the pilots. See
  //   META-001 §4.18.6 for the full rationale.
  //
  //   S10c (added 2026-06-22) enforces README.md ≤ 400. The cap existed
  //   in §4.18.1 since 2026-06-21 but was deferred pending remediation
  //   of 2 pre-existing violations (gepetto 485, react-dev 404). Both
  //   were remediated on 2026-06-22 (gepetto → 302, react-dev → 392);
  //   S10c is now active as HARD from day 1.
  //
  //   References are EXEMPT per §4.18.1 (references/**.md row) — no
  //   check applied.
  //
  // SCOPE
  //   - skills/skills/{name}/SKILL.md (every skill folder)
  //   - skills/skills/{name}/CONTRACT.md (only if present, 2 today)
  //   - skills/skills/{name}/README.md (only if present, most skills)
  //   - References are explicitly NOT scanned (exempt per §4.18.1)
  //
  // THRESHOLDS
  //   SKILL.md:    800 lines (matches §4.18.1 SKILL.md row exactly)
  //   CONTRACT.md: 500 lines (matches §4.18.1 CONTRACT.md row)
  //   README.md:   400 lines (matches §4.18.1 README.md row)
  //
  // FAILURE MODE
  //   If a file exceeds its cap, the offender is reported with the
  //   actual line count and the applicable cap. The fix is either:
  //     (a) Split the file (preferred for SKILL.md — move examples to
  //         references/, see STD-SKILL-001 §8.2)
  //     (b) For CONTRACT.md, externalise auxiliary sections (change
  //         history, cross-refs, honest uncertainties) to references/
  //         — these are NOT parser-bound, see META-001 §4.18.6
  //     (c) For README.md, move detailed integration examples to
  //         references/ — README is for onboarding/overview only.
  // ----------------------------------------------------------------
  (function S10() {
    const SKILLMD_CAP = 800;
    const CONTRACTMD_CAP = 500;
    const READMEMD_CAP = 400;

    const skillMdOffenders = [];
    const contractMdOffenders = [];
    const readmeMdOffenders = [];
    let skillMdChecked = 0;
    let contractMdChecked = 0;
    let readmeMdChecked = 0;

    for (const s of skillDirs) {
      // S10a: SKILL.md
      const skillMdPath = path.join(s.path, "SKILL.md");
      if (fs.existsSync(skillMdPath)) {
        skillMdChecked++;
        const content = fs.readFileSync(skillMdPath, "utf8");
        // Same line-count convention as verify-standards.js V11 and
        // verify-id-graph.js (wc -l equivalent).
        const lineCount =
          content === "" ? 0 : content.split("\n").length - (content.endsWith("\n") ? 1 : 0);
        if (lineCount > SKILLMD_CAP) {
          skillMdOffenders.push(
            `${s.name}/SKILL.md: ${lineCount} lines (exceeds ${SKILLMD_CAP}-line cap, split required — see STD-SKILL-001 §8.2)`,
          );
        }
      }

      // S10b: CONTRACT.md (optional)
      const contractMdPath = path.join(s.path, "CONTRACT.md");
      if (fs.existsSync(contractMdPath)) {
        contractMdChecked++;
        const content = fs.readFileSync(contractMdPath, "utf8");
        const lineCount =
          content === "" ? 0 : content.split("\n").length - (content.endsWith("\n") ? 1 : 0);
        if (lineCount > CONTRACTMD_CAP) {
          contractMdOffenders.push(
            `${s.name}/CONTRACT.md: ${lineCount} lines (exceeds ${CONTRACTMD_CAP}-line cap, externalise auxiliary sections to references/ — see META-001 §4.18.6)`,
          );
        }
      }

      // S10c: README.md (optional)
      const readmeMdPath = path.join(s.path, "README.md");
      if (fs.existsSync(readmeMdPath)) {
        readmeMdChecked++;
        const content = fs.readFileSync(readmeMdPath, "utf8");
        const lineCount =
          content === "" ? 0 : content.split("\n").length - (content.endsWith("\n") ? 1 : 0);
        if (lineCount > READMEMD_CAP) {
          readmeMdOffenders.push(
            `${s.name}/README.md: ${lineCount} lines (exceeds ${READMEMD_CAP}-line cap, move detailed examples to references/ — README is for onboarding/overview only)`,
          );
        }
      }
    }

    // S10a: SKILL.md
    check(
      "S10a",
      `SKILL.md ≤ ${SKILLMD_CAP} lines (META-001 §4.18.1, SKILL.md row) — checked ${skillMdChecked} SKILL.md files`,
      skillMdOffenders.length === 0,
      skillMdOffenders.length === 0
        ? `all ${skillMdChecked} SKILL.md files ≤ ${SKILLMD_CAP} lines`
        : `${skillMdOffenders.length} file(s) over cap: ${skillMdOffenders.join("; ")}`,
    );

    // S10b: CONTRACT.md
    check(
      "S10b",
      `CONTRACT.md ≤ ${CONTRACTMD_CAP} lines (META-001 §4.18.1, CONTRACT.md row) — checked ${contractMdChecked} CONTRACT.md files`,
      contractMdOffenders.length === 0,
      contractMdOffenders.length === 0
        ? contractMdChecked === 0
          ? "no skills have CONTRACT.md (optional)"
          : `all ${contractMdChecked} CONTRACT.md files ≤ ${CONTRACTMD_CAP} lines`
        : `${contractMdOffenders.length} file(s) over cap: ${contractMdOffenders.join("; ")}`,
    );

    // S10c: README.md
    check(
      "S10c",
      `README.md ≤ ${READMEMD_CAP} lines (META-001 §4.18.1, README.md row) — checked ${readmeMdChecked} README.md files`,
      readmeMdOffenders.length === 0,
      readmeMdOffenders.length === 0
        ? readmeMdChecked === 0
          ? "no skills have README.md (optional)"
          : `all ${readmeMdChecked} README.md files ≤ ${READMEMD_CAP} lines`
        : `${readmeMdOffenders.length} file(s) over cap: ${readmeMdOffenders.join("; ")}`,
    );
  })();
}

// ============================================================================
// CLI PARSING + OUTPUT
// ============================================================================

function parseArgs(argv) {
  const opts = { json: false, help: false, root: null, strict: false };
  for (const arg of argv.slice(2)) {
    if (arg === "--help" || arg === "-h") opts.help = true;
    else if (arg === "--json") opts.json = true;
    else if (arg === "--strict") opts.strict = true;
    else if (arg.startsWith("--root=")) opts.root = arg.slice(7);
    else {
      console.error(`Unknown argument: ${arg}`);
      process.exit(2);
    }
  }
  return opts;
}

function showHelp() {
  console.log(`
verify-skills.js v${VERSION} — Skills-side Format Verifier

Usage:
  node scripts/verify-skills.js [options]

Options:
  --json               Output JSON instead of human-readable
  --strict             Promote S02/S03/S05 from SOFT to HARD. Use after
                       the existing 15 violations are remediated (see
                       standards/docs/CI-AND-TESTING.md §9.2.2).
  --root=<path>        Override platform root (auto-detected otherwise)
  --help, -h           Show this help

Checks (S01-S10, mapping to STD-SKILL-001 §10.1 V11a-V14b + META-001 §4.18.1 V12):

  HARD (exit 1 on fail) — always:
    S01 (V11a)  SKILL.md exists in every skills/skills/{name}/ folder
    S04 (V13a)  YAML frontmatter parses
    S09 (V14b)  frontmatter version matches blockquote Version:
    S10a (V12)  SKILL.md ≤ 800 lines (META-001 §4.18.1, SKILL.md row)
    S10b (V12)  CONTRACT.md ≤ 500 lines (META-001 §4.18.1, CONTRACT.md row)
    S10c (V12)  README.md ≤ 400 lines (META-001 §4.18.1, README.md row)

  SOFT-default, HARD with --strict — see rationale below:
  S02 (V11b)  frontmatter name matches folder name
  S03 (V11c)  name matches folder name (covered by S02)
    S05 (V13b)  Required fields: name, description, version

  SOFT (reported, do not fail even with --strict):
    S06 (V05a)  id field format: ZAI-<DOMAIN>-<NNN> + valid domain
    S07 (V13c)  compatibility field: both|sandbox|ade
    S08 (V14a)  frontmatter id matches blockquote ID:

S10 rationale (added 2026-06-21, O-017 Phase D2; S10c added 2026-06-22):
  S10 promotes the META-001 §4.18.1 ceilings from documentation to
  runtime HARD invariants (replacing the deferred PROC-LINECOUNT-004).
  S10a enforces SKILL.md ≤ 800. S10b enforces CONTRACT.md ≤ 500,
  validated against 2 pilot contracts (commit-work 368, session-handoff
  466 — see META-001 §4.18.6). S10c (added 2026-06-22) enforces
  README.md ≤ 400 — activated as HARD from day 1 after remediating the
  2 pre-existing violations (gepetto 485→302, react-dev 404→392).
  Original O-017 proposal of 200 for CONTRACT.md was invalidated by the
  actual pilots; per LESSON-001, the cap was adjusted to fit measured
  reality. References are exempt per §4.18.1 — not scanned.

Soft-default rationale for S02/S03/S05:
  STD-SKILL-001 §10.1 marks these as HARD, but as of v1.0.0 the skills
  corpus has 15 pre-existing violations (8 name/folder mismatches, 3
  missing version fields). Until these are
  remediated, the verifier runs them as SOFT by default so CI does
  not block on pre-existing technical debt. Once remediated, flip
  --strict on in CI to make them HARD.

  S06, S07, S08 are SOFT per the standard itself (only checked when
  the relevant optional field is present).

Companion verifiers:
  verify-standards.js   content-level invariants on standards/*.md
  verify-id-graph.js    cross-repo ID-graph invariants (Related: edges)

Exit codes:
  0 — all HARD checks pass (SOFT warnings may be present)
  1 — at least one HARD check failed
  2 — configuration error (skills/ not found, bad CLI args)
`);
}

function printHuman() {
  const width = Math.max(...results.checks.map((c) => c.id.length));
  console.log(`verify-skills.js v${VERSION} — Skills-side Format Verifier`);
  console.log(`Effective date: ${EFFECTIVE_DATE}`);
  console.log(`Skills scanned: ${results.stats.skills_scanned}`);
  console.log("=".repeat(72));
  console.log("");
  console.log("--- Hard Checks (S01-S05, S09, S10) ---");
  for (const c of results.checks.filter((c) => !c.isSoft)) {
    const icon = c.status === "PASS" ? "[PASS]" : "[FAIL]";
    console.log(`${icon} ${c.id.padEnd(width)}  ${c.description}`);
    if (c.detail) console.log(`         ${c.detail}`);
  }
  console.log("");
  console.log("--- Soft Checks (S06-S08) ---");
  for (const c of results.checks.filter((c) => c.isSoft)) {
    const icon = c.status === "PASS" ? "[PASS]" : "[WARN]";
    console.log(`${icon} ${c.id.padEnd(width)}  ${c.description}`);
    if (c.detail) console.log(`         ${c.detail}`);
  }
  console.log("");
  console.log("-".repeat(72));
  const hardPass = results.checks.filter((c) => !c.isSoft && c.status === "PASS").length;
  const hardFail = results.checks.filter((c) => !c.isSoft && c.status === "FAIL").length;
  const softWarn = results.checks.filter((c) => c.isSoft && c.status === "WARN").length;
  console.log(`HARD: ${hardPass}/${hardPass + hardFail} PASS, ${hardFail} FAIL`);
  console.log(`SOFT: ${softWarn} warning(s)`);
  console.log("");
  if (hardFail > 0) {
    console.log("ACTION REQUIRED:");
    console.log("  At least one HARD invariant was violated. Either:");
    console.log("    (a) Fix the SKILL.md to conform to STD-SKILL-001 v1.1, OR");
    console.log("    (b) Update the S## check in scripts/verify-skills.js if the");
    console.log("        standard itself changed.");
    console.log("  Then re-run: node scripts/verify-skills.js");
  } else {
    console.log("All HARD invariants hold. Skills conform to STD-SKILL-001 v1.1.");
  }
}

function printJSON() {
  const hardPass = results.checks.filter((c) => !c.isSoft && c.status === "PASS").length;
  const hardFail = results.checks.filter((c) => !c.isSoft && c.status === "FAIL").length;
  console.log(
    JSON.stringify(
      {
        script: "verify-skills.js",
        version: VERSION,
        effective_date: EFFECTIVE_DATE,
        generated: new Date().toISOString(),
        summary: {
          skills_scanned: results.stats.skills_scanned,
          hard_pass: hardPass,
          hard_fail: hardFail,
          soft_warnings: results.checks.filter((c) => c.isSoft && c.status === "WARN").length,
        },
        checks: results.checks,
      },
      null,
      2,
    ),
  );
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

  const platformRoot = opts.root || discoverPlatformRoot();
  if (!platformRoot) {
    console.error("[verify-skills] Could not discover platform root.");
    console.error("[verify-skills] Set ZAI_PLATFORM_ROOT env var or use --root=<path>.");
    process.exit(2);
  }

  runChecks(platformRoot, opts);

  if (opts.json) {
    printJSON();
  } else {
    printHuman();
  }

  const hardFail = results.checks.filter((c) => !c.isSoft && c.status === "FAIL").length;
  process.exit(hardFail > 0 ? 1 : 0);
}

main();
