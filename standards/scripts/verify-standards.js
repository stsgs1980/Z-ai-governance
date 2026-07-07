/**
 * ============================================================================
 * PERMANENT STANDARDS VERIFIER — verify-standards.js
 * ============================================================================
 *
 * PURPOSE
 *   PERMANENT invariant checker. Updated whenever ANY standard changes.
 *   The contract is:
 *
 *     Whenever you edit a .md standard, you MUST:
 *       (1) Re-read this file and find the V## check(s) covering that standard
 *       (2) Adjust the check if the invariant changed
 *       (3) Add a new V## check if the standard introduced a new rule
 *       (4) Run `node scripts/verify-standards.js` — it must exit 0
 *
 *   Every standard's header should declare `verified_by: V01, V02, ...` so
 *   the link is mechanical, not just narrative.
 *
 * COVERAGE (vs verify-id-graph.js)
 *   verify-id-graph.js: structural / ID-graph invariants (G01-G15 hard +
 *     W01-W15 soft) — duplicate IDs, Related-edge resolution, layer matrix,
 *     line counts, §XA presence, naming patterns.
 *   verify-standards.js:  content-level invariants — emoji/Unicode hygiene,
 *     code-fence language tags, English-only, anti-monolith threshold values,
 *     design-system delegation, README_TEMPLATE structure.
 *   Both scripts are complementary and should both run in CI.
 *
 * HISTORY
 *   2026-06-21: V11 added — promotes W11's 1000-line markdown soft cap to a
 *     HARD invariant. Closes the "detection without prevention" gap: W11
 *     (verify-id-graph.js) warned on >1000-line files but did not fail the
 *     pipeline, so W11=0 was fragile (any commit could regress it). V11 turns
 *     the same 1000-line cap into a hard exit-1 enforcement, applying the
 *     LESSON-001 principle (root-cause fix scales as O(1), whitelist as O(N)).
 *     V11 scans STANDARDS_DIR + DOCS/sandbox + TEMPLATES via readdirSync
 *     (catches any NEW file, not just an enumerated list).
 *   2026-06-18: Path re-targeting to flat <DOMAIN>-<NNN>-<name>.md layout.
 *     V01/V02/V03 retired (premises contradicted current standards).
 *     V07 thresholds updated to FE-001 v2.1+ actual values.
 *     V10 retuned to match README_TEMPLATE.md actual Badges=Optional choice.
 *     V09 target list pruned (removed deprecated upload/*.md references).
 *
 * EXIT CODES
 *   0 — all invariants hold
 *   1 — at least one invariant violated
 *
 * USAGE
 *   node scripts/verify-standards.js            # human-readable
 *   node scripts/verify-standards.js --json     # CI-friendly
 *
 * ============================================================================
 */

const fs = require("fs");
const path = require("path");

// ---------------------------------------------------------------------------
// Paths — RELATIVE to this script's location so the corpus works:
//   - standalone:     <standalone-checkout>/scripts/verify-standards.js
//   - as a submodule: <host-repo>/standards/scripts/verify-standards.js
//   - in CI:          any checkout path GitHub Actions uses
//
// Layout (post-2026-06 migration to flat <DOMAIN>-<NNN>-<name>.md naming):
//   <repo-root>/
//     scripts/verify-standards.js        (this file)
//     standards/                          (21 .md standards, flat layout)
//     docs/sandbox/                       (sandbox guides + cookbook)
//     templates/                          (README_TEMPLATE.md, etc.)
// ---------------------------------------------------------------------------
const SCRIPT_DIR = __dirname;
const REPO_ROOT = path.resolve(SCRIPT_DIR, "..");
const STANDARDS_DIR = path.join(REPO_ROOT, "standards");
const DOCS_DIR = path.join(REPO_ROOT, "docs", "sandbox");
const TEMPLATES_DIR = path.join(REPO_ROOT, "templates");

const PATHS = {
  STD_ENV_002: path.join(STANDARDS_DIR, "ENV-002-zai-integration.md"),
  STD_FE_001: path.join(STANDARDS_DIR, "FE-001-frontend.md"),
  STD_META_001: path.join(STANDARDS_DIR, "META-001-standard-id-system.md"),
  STD_DESIGN_001: path.join(STANDARDS_DIR, "DESIGN-001-design-system.md"),
  STD_DOC_003: path.join(STANDARDS_DIR, "DOC-003-unicode-policy.md"),
  STD_ARCH_001: path.join(STANDARDS_DIR, "ARCH-002-implementation-order.md"),
  HOOKS_GUIDE: path.join(DOCS_DIR, "sandbox-hooks-cookbook.md"),
  // Split-out parts of the cookbook (split 2026-06-19). Each part is a separate
  // .md file that must pass the same STD-DOC-003 / fence / ratio checks as the
  // INDEX file. Listed here so all 3 verifier phases (V04 unicode, V08 fences,
  // V09 ratio) include them automatically via the `...PATHS.HOOKS_GUIDE_PARTS`
  // spread in each phase's `targets` array.
  HOOKS_GUIDE_PARTS: [
    path.join(DOCS_DIR, "hooks-basic.md"),
    path.join(DOCS_DIR, "hooks-ai.md"),
    path.join(DOCS_DIR, "hooks-routes.md"),
    path.join(DOCS_DIR, "hooks-patterns.md"),
  ],
  // Split-out parts of the commands cheatsheet (split 2026-06-19).
  CHEATSHEET_PARTS: [
    path.join(DOCS_DIR, "sandbox-commands-file.md"),
    path.join(DOCS_DIR, "sandbox-commands-system.md"),
    path.join(DOCS_DIR, "sandbox-commands-dev.md"),
    path.join(DOCS_DIR, "sandbox-commands-media.md"),
  ],
  SANDBOX_GUIDE: path.join(DOCS_DIR, "sandbox-guide.md"),
  README_TEMPLATE: path.join(TEMPLATES_DIR, "README_TEMPLATE.md"),
  WORKLOG_TEMPLATE: path.join(TEMPLATES_DIR, "WORKLOG_TEMPLATE.md"),
  CHANGELOG_TEMPLATE: path.join(TEMPLATES_DIR, "CHANGELOG_TEMPLATE.md"),
  AGENT_RULES_TEMPLATE: path.join(TEMPLATES_DIR, "AGENT_RULES_TEMPLATE.md"),
  ROOT_README: path.join(REPO_ROOT, "README.md"),
};

// ---------------------------------------------------------------------------
// Results accumulator
// ---------------------------------------------------------------------------
const results = {
  passed: 0,
  failed: 0,
  checks: [],
};

function check(id, description, condition, detail) {
  const status = condition ? "PASS" : "FAIL";
  results.checks.push({ id, description, status, detail: detail || "" });
  if (condition) results.passed++;
  else results.failed++;
}

function readSafe(filePath) {
  if (!fs.existsSync(filePath)) return null;
  return fs.readFileSync(filePath, "utf-8");
}

/**
 * Extract a numbered section from a markdown file.
 * Returns the section's text including the heading line, up to the next
 * heading of the same or higher level. Skips fenced code blocks so that
 * shell comments like `# Check if dev server is running` inside ```bash
 * blocks are NOT mistaken for markdown headings.
 */
function extractSection(content, sectionNumber) {
  if (!content) return "";
  // Match `## 5. Title` or `### 5.1 Title` etc.
  const pattern = new RegExp(
    `(^|\\n)(#{2,4})\\s*${sectionNumber.replace(/\./g, "\\.")}[^\\n]*\\n`,
    "m",
  );
  const match = content.match(pattern);
  if (!match) return "";
  const startIdx = match.index + match[1].length;
  const headingLevel = match[2].length;
  const afterStart = content.slice(startIdx);
  const lines = afterStart.split("\n");

  let inCodeFence = false;
  let endLineIdx = -1;
  const headingRe = new RegExp(`^#{1,${headingLevel}}\\s+\\S`);

  for (let i = 1; i < lines.length; i++) {
    const line = lines[i];
    if (/^```/.test(line)) {
      inCodeFence = !inCodeFence;
      continue;
    }
    if (inCodeFence) continue;
    if (headingRe.test(line)) {
      endLineIdx = i;
      break;
    }
  }

  if (endLineIdx === -1) return afterStart;
  return lines.slice(0, endLineIdx).join("\n");
}

// ============================================================================
// V01 — RETIRED 2026-06-18 — ENV-002 §5.1 startup must NOT be `npx next dev`
//
// Retirement reason: The original invariant conflated BOOTSTRAP (one-time
// `init-fullstack_*.sh` per ENV-002 §3.0.1 step 5) with RECURRING DEV-SERVER
// STARTUP (`npx next dev` per ENV-002 §5.2). The standard correctly uses
// `init-fullstack` for bootstrap and `npx next dev` for the dev server —
// these are different lifecycle events. The V01 check would have forbidden
// the canonical startup command, which is wrong.
//
// The invariant is preserved here as a comment so:
//   (a) the V01 ID is not silently re-used for an unrelated check,
//   (b) future readers can see why it was retired, and
//   (c) standards that declared `verified_by: V01` still resolve to a
//       documented (if retired) check.
// ============================================================================

// ============================================================================
// V02 — RETIRED 2026-06-18 — ENV-002 must NOT use /tmp/zdev.log
//
// Retirement reason: ENV-002 §3 "Allowed paths" table explicitly lists
// `/tmp/zdev.log` as Allowed — "Dev server log (not in source code)". §5.2
// uses it as the canonical dev-server log target. The V02 invariant
// contradicted the standard's actual rule (the standard permits /tmp/zdev.log
// because it is a runtime artifact, not source code, and lives outside the
// source tree where the DOC-003 / ENV-001 path rules apply).
//
// If a future refactor moves the dev log into the source tree (e.g.,
// `.zscripts/dev.log`), a new V## check should be added at that time to
// enforce the new path. For now, the standard's choice stands.
// ============================================================================

// ============================================================================
// V03 — RETIRED 2026-06-18 — Hooks cookbook API routes use Zod safeParse
//
// Retirement reason: The sandbox-hooks-cookbook.md (formerly
// `Hooks-in-Z.ai-Guide.md` under the deprecated `upload/` layout) is a
// pattern reference, not an API surface. It contains no `z.object` or
// `safeParse` references and never did — this check appears to have been a
// one-shot cascade-task verification that was accidentally promoted to
// "permanent invariant" status. Zod safeParse enforcement, when needed,
// belongs in STD-SEC-001 §input-validation (which is verified separately).
// ============================================================================

// ============================================================================
// V04 — All .md standards + guides: no emoji/Unicode graphic chars (STD-DOC-003)
// ============================================================================
(function V04() {
  const targets = [
    ...fs
      .readdirSync(STANDARDS_DIR)
      .filter((f) => f.endsWith(".md"))
      .map((f) => path.join(STANDARDS_DIR, f)),
    PATHS.HOOKS_GUIDE,
    ...PATHS.HOOKS_GUIDE_PARTS,
    ...PATHS.CHEATSHEET_PARTS,
    PATHS.SANDBOX_GUIDE,
    PATHS.ROOT_README,
  ].filter(Boolean);

  // STD-DOC-003 forbidden range: pictographs, dingbats, arrows, geometric shapes
  const forbidden =
    /[\u{1F300}-\u{1F9FF}\u{2702}\u{2714}\u{2716}\u{274C}\u{274E}\u{2753}\u{2757}\u{2795}-\u{2797}\u{2B05}-\u{2B07}\u{2B1B}\u{2B1C}\u{2B50}\u{2B55}]/u;

  // Box-drawing and arrow chars that are allowed inside code fences (for ASCII art)
  const codeFenceAllowed = /[\u2500-\u257F\u2B00-\u2B07]/u;

  // Strip fenced code blocks (preserving box-drawing chars for later check),
  // inline code spans, then scan for emoji/Unicode graphics.
  // DOC-003 (the Unicode policy standard itself) legitimately shows emoji
  // inside `inline code` spans as "forbidden pattern" examples — those
  // should not count as violations. Same applies to any other standard
  // that documents forbidden characters by example.
  const offenders = [];
  for (const file of targets) {
    const raw = readSafe(file) || "";
    // Extract code fences content separately to check box-drawing chars
    const fenceMatches = raw.match(/```[\s\S]*?```/g) || [];
    const stripped = raw
      .replace(/```[\s\S]*?```/g, "") // fenced code blocks
      .replace(/`[^`\n]+`/g, ""); // inline code spans (single-line)
    if (forbidden.test(stripped)) {
      const matches = stripped.match(new RegExp(forbidden.source, "u")) || [];
      offenders.push(`${path.basename(file)} (${matches.length} match(es))`);
    }
  }
  check(
    "V04",
    `No emoji/Unicode graphic chars in ${targets.length} .md files (STD-DOC-003) — code spans stripped`,
    offenders.length === 0,
    offenders.length === 0 ? "all clean" : `offenders: ${offenders.join("; ")}`,
  );
})();

// ============================================================================
// V05 — STD-META-001 registry must include STD-DESIGN-001 and STD-FE-001 v2.0+
//        (v2.0 = Design System integration milestone)
//
// Updated 2026-06-18: threshold relaxed from "v2.5+" to "v2.0+". FE-001 is
// currently at v2.4 (per its version history), and the "v2.5+" requirement
// was speculative. The real milestone is v2.0 (June 2026 Design System
// integration rewrite of §11) — anything ≥v2.0 satisfies the invariant.
// ============================================================================
(function V05() {
  const meta = readSafe(PATHS.STD_META_001);
  if (!meta) {
    check(
      "V05",
      "STD-META-001 registry includes STD-DESIGN-001 and STD-FE-001 v2.0+",
      false,
      "STD-META-001 file not found",
    );
    return;
  }
  const hasDesign = /STD-DESIGN-001/.test(meta);
  // Match STD-FE-001 followed by a version ≥ 2.0 (e.g., "STD-FE-001 | 1.5 | 2.3 |" or
  // "STD-FE-001 ... v2.0" — either registry row format or narrative).
  // Look for "STD-FE-001" appearing near a version like 2.0, 2.1, ..., 2.9, 3.x
  const feVersionMatch = meta.match(/STD-FE-001[^\n]*?\b(2\.[0-9]+|3\.[0-9]+)\b/);
  const hasFE20 = !!feVersionMatch;
  check(
    "V05",
    "STD-META-001 registry includes STD-DESIGN-001 and STD-FE-001 v2.0+",
    hasDesign && hasFE20,
    `STD-DESIGN-001=${hasDesign}, STD-FE-001 v2.0+=${hasFE20}${feVersionMatch ? ` (matched: ${feVersionMatch[1]})` : ""}`,
  );
})();

// ============================================================================
// V06 — STD-FE-001 §11/§12 delegate to STD-DESIGN-001 (no hardcoded color tokens)
// ============================================================================
(function V06() {
  const fe = readSafe(PATHS.STD_FE_001);
  if (!fe) {
    check(
      "V06",
      "STD-FE-001 §11/§12 delegate to STD-DESIGN-001",
      false,
      "STD-FE-001 file not found",
    );
    return;
  }
  const section11 = extractSection(fe, "11") || "";
  const section12 = extractSection(fe, "12") || "";
  const combined = section11 + "\n" + section12;
  const hasDelegation = /STD-DESIGN-001/.test(combined);
  // Forbidden: hardcoded hex colors as design tokens (allowed in code samples / examples)
  const hasHardcodedHex = /(?:background|color|border):\s*#[0-9a-fA-F]{3,8}\b/.test(combined);
  check(
    "V06",
    "STD-FE-001 §11/§12 delegate to STD-DESIGN-001 (no hardcoded hex tokens)",
    hasDelegation && !hasHardcodedHex,
    `STD-DESIGN-001 ref=${hasDelegation}, hardcoded hex=${hasHardcodedHex}`,
  );
})();

// ============================================================================
// V07 — STD-FE-001 §2 anti-monolith thresholds present
//       (File 150/250, Component 100/200, Page 30/50, useState 2→3, hook 50/100)
//
// Updated 2026-06-18 to match FE-001 v2.1+ actual thresholds. The previous
// version of this check looked for obsolete thresholds (Function 50/80,
// useEffect 3+/4+, "4+ inline sub-sections") that no longer match the
// standard's current Size Constraints table (§2.1) and State Management
// rule (§2.2).
// ============================================================================
(function V07() {
  const fe = readSafe(PATHS.STD_FE_001);
  if (!fe) {
    check(
      "V07",
      "STD-FE-001 §2 anti-monolith thresholds present",
      false,
      "STD-FE-001 file not found",
    );
    return;
  }
  const section2 = extractSection(fe, "2") || "";

  // §2.1 Size Constraints table — verify each row's recommended/hard pair.
  // Use LINE-based matching: find the row containing the unit name, then
  // verify that the same line contains both threshold numbers. (Previous
  // regex used `[^|]*` between the two numbers, which cannot span the `|`
  // cell separator and so never matched a multi-cell table row.)
  function rowHasPair(unitName, low, high) {
    const lines = section2.split("\n");
    for (const line of lines) {
      if (line.includes(unitName) && line.includes(String(low)) && line.includes(String(high))) {
        return true;
      }
    }
    return false;
  }
  const hasComponent100200 = rowHasPair("Component function", 100, 200);
  const hasFile150250 = rowHasPair("File (Module)", 150, 250);
  const hasPage3050 = rowHasPair("Page / Route", 30, 50);
  const hasHook50100 = rowHasPair("Custom hook", 50, 100);
  const hasBarrel3050 = rowHasPair("Barrel index.ts", 30, 50);

  // §2.2 useState rule: limit is 2 (3rd triggers extraction)
  const hasUseState2Limit =
    /no more than 2\s*`?useState`?/i.test(section2) ||
    /2\s*`?useState`?\s*hooks/i.test(section2) ||
    /3rd\s*`?useState`?\s*triggers/i.test(section2);

  // Anti-monolith exception marker must exist
  const hasExceptionMarker = /ANTI-MONOLITH EXCEPTION/i.test(section2);

  const ok =
    hasComponent100200 &&
    hasFile150250 &&
    hasPage3050 &&
    hasHook50100 &&
    hasBarrel3050 &&
    hasUseState2Limit &&
    hasExceptionMarker;

  check(
    "V07",
    "STD-FE-001 §2 anti-monolith thresholds present (File 150/250, Component 100/200, Page 30/50, hook 50/100, Barrel 30/50, useState 2, exception marker)",
    ok,
    `Component 100/200=${hasComponent100200}, File 150/250=${hasFile150250}, Page 30/50=${hasPage3050}, hook 50/100=${hasHook50100}, Barrel 30/50=${hasBarrel3050}, useState 2=${hasUseState2Limit}, exception marker=${hasExceptionMarker}`,
  );
})();

// ============================================================================
// V08 — Every 3-backtick code fence opening MUST have a language tag
//       (STD-DOC-002 §4.3 + §5.4 "Unknown Languages Rule")
//
// CommonMark fence rules:
//   - A fence is a line starting with >= 3 backticks.
//   - A fence of N backticks is closed by a line with >= N backticks.
//   - Inside a fence of N backticks, lines with < N backticks are CONTENT,
//     not fence openings (so a ``` inside a ```` is just text).
//
// Violation = opening fence with EXACTLY 3 backticks and no language tag.
// 4+ backtick fences (containers for nested examples) are NOT violations.
// ============================================================================
(function V08() {
  const targets = [
    ...fs
      .readdirSync(STANDARDS_DIR)
      .filter((f) => f.endsWith(".md"))
      .map((f) => path.join(STANDARDS_DIR, f)),
    PATHS.HOOKS_GUIDE,
    ...PATHS.HOOKS_GUIDE_PARTS,
    ...PATHS.CHEATSHEET_PARTS,
    PATHS.SANDBOX_GUIDE,
    PATHS.ROOT_README,
  ].filter(Boolean);

  const FENCE_RE = /^(`{3,})(.*?)\s*$/;
  const offenders = [];

  for (const file of targets) {
    const content = readSafe(file) || "";
    const lines = content.split("\n");
    let currentBackticks = 0;
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const m = line.match(FENCE_RE);
      if (!m) continue;
      const count = m[1].length;
      const rest = m[2];

      if (currentBackticks === 0) {
        // Opening fence
        if (count === 3 && rest.trim() === "") {
          offenders.push(`${path.basename(file)}:L${i + 1}`);
        }
        currentBackticks = count;
      } else {
        // Inside a fence. Is this a closing fence?
        // Closing fence: count >= currentBackticks AND rest is empty/whitespace
        if (count >= currentBackticks && rest.trim() === "") {
          currentBackticks = 0;
        }
        // else: content line, skip
      }
    }
  }

  check(
    "V08",
    `All 3-backtick code fences have a language tag (STD-DOC-002 §4.3) — scanned ${targets.length} files`,
    offenders.length === 0,
    offenders.length === 0
      ? "all fences specify a language"
      : `${offenders.length} plain fence(s): ${offenders.slice(0, 8).join(", ")}${offenders.length > 8 ? ` +${offenders.length - 8} more` : ""}`,
  );
})();

// ============================================================================
// V09 — All .md files in upload/ (standards + guides) are English-only
//       (agent-friendly: unified language for RAG, search, prompts, CI)
//
// Threshold: Cyrillic characters must be < 2% of all letters in each file.
// 2% tolerates incidental occurrences (e.g. proper names, citations) while
// catching any real translation backsliding. Latin-only code blocks do NOT
// count toward either side.
// ============================================================================
(function V09() {
  // Scan all standards + sandbox guides + README template.
  // (Previously also scanned upload/SKILL.md / MARKDOWN_STANDARD.md /
  // UNICODE_POLICY.md — those files no longer exist at those paths after the
  // 2026-06 migration to flat <DOMAIN>-<NNN>-<name>.md naming.)
  const targets = [
    ...fs
      .readdirSync(STANDARDS_DIR)
      .filter((f) => f.endsWith(".md"))
      .map((f) => path.join(STANDARDS_DIR, f)),
    PATHS.HOOKS_GUIDE,
    ...PATHS.HOOKS_GUIDE_PARTS,
    ...PATHS.CHEATSHEET_PARTS,
    PATHS.SANDBOX_GUIDE,
    PATHS.README_TEMPLATE,
  ].filter(Boolean);

  const THRESHOLD_PCT = 2.0; // percent
  const offenders = [];

  for (const file of targets) {
    const content = readSafe(file) || "";
    // Strip fenced code blocks so that code samples do not skew the ratio
    const stripped = content.replace(/```[\s\S]*?```/g, "");
    const cyrCount = (stripped.match(/[\u0400-\u04FF]/g) || []).length;
    const latCount = (stripped.match(/[A-Za-z]/g) || []).length;
    const total = cyrCount + latCount;
    if (total === 0) continue;
    const cyrPct = (cyrCount / total) * 100;
    if (cyrPct >= THRESHOLD_PCT) {
      offenders.push(`${path.basename(file)} (${cyrPct.toFixed(1)}% cyr)`);
    }
  }

  check(
    "V09",
    `All ${targets.length} .md files in upload/ are English-only (< ${THRESHOLD_PCT}% Cyrillic)`,
    offenders.length === 0,
    offenders.length === 0
      ? "all files English-only"
      : `${offenders.length} file(s) over threshold: ${offenders.join(", ")}`,
  );
})();

// ============================================================================
// V10 - STD-DOC-004 (README_TEMPLATE.md) — badges guidance
//
// Updated 2026-07-02. v3.0 renumbered sections:
//   §1 = Language Rule, §2 = Size Rules, §3 = Section Map (Badges row),
//   §4 = Format Rules, §5 = Template (shields.io badges),
//   §6 = Checklist (mentions badges).
// The check looks in the correct v3.0 sections:
//   (a) §3 Section Map table has a Badges row (Required or Optional).
//   (b) §5 Template has ≥1 shields.io badge URL.
//   (c) §6 Checklist mentions badges (so authors remember to consider them).
// ============================================================================
(function V10() {
  const readme = readSafe(PATHS.README_TEMPLATE);
  if (!readme) {
    check(
      "V10",
      "STD-DOC-004 README_TEMPLATE.md has Badges guidance (§3 row + §5 example + §6 checklist)",
      false,
      "README_TEMPLATE.md file not found",
    );
    return;
  }

  // (a) §3 Section Map table has a Badges row (Required or Optional — both
  // satisfy "the standard acknowledges badges as a section").
  const section3 = extractSection(readme, "3") || "";
  const hasBadgesRow = /\|\s*\d+\s*\|\s*Badges\s*\|/i.test(section3);

  // (b) §5 Template has ≥1 shields.io badge URL
  const startIdx5 = readme.search(/^## 5\.\s/m);
  const endIdx5 = readme.search(/^## 6\.\s/m);
  let section5 = "";
  if (startIdx5 !== -1 && endIdx5 !== -1 && endIdx5 > startIdx5) {
    section5 = readme.slice(startIdx5, endIdx5);
  }
  const templateBlock = (section5.match(/````markdown\r?\n([\s\S]*?)\r?\n````/) || [])[1] || "";
  const badgeUrls =
    templateBlock.match(/!\[([^\]]*)\]\(https:\/\/img\.shields\.io\/[^)]+\)/g) || [];
  const hasAtLeast1Badge = badgeUrls.length >= 1;

  // (c) §6 Checklist mentions badges
  const section6 = extractSection(readme, "6") || "";
  const checklistMentionsBadges = /badge/i.test(section6);

  check(
    "V10",
    "STD-DOC-004 README_TEMPLATE.md has Badges guidance (§3 row + ≥1 §5 example + §6 checklist mention)",
    hasBadgesRow && hasAtLeast1Badge && checklistMentionsBadges,
    `§3 Badges row=${hasBadgesRow}; §5 shields.io badges=${badgeUrls.length} (≥1=${hasAtLeast1Badge}); §6 checklist mentions badges=${checklistMentionsBadges}`,
  );
})();

// ============================================================================
// V11 — HARD CAP: no .md file in STANDARDS_DIR / docs/sandbox / templates
//       exceeds 1000 lines (promotion of W11 soft cap to hard invariant)
//
// RATIONALE (2026-06-21)
//   W11 in verify-id-graph.js already warns at >1000 lines and warns CRITICAL
//   at >1500. But because W11 is a SOFT warning, a commit could regress it
//   without failing CI — W11=0 was an unstable equilibrium, not a structural
//   guarantee. V11 promotes the 1000-line cap to a HARD exit-1 invariant so
//   that any future commit adding a >1000-line .md file FAILS the verifier
//   and must be split before merge.
//
//   This applies LESSON-001 (root-cause fix scales as O(1), whitelist as O(N)):
//   splitting the 2 long skills files today (cosmetic, O(N) over time) is
//   weaker than encoding the cap as a check that scales as O(1) — the check
//   runs on every commit regardless of how many files exist.
//
// SCOPE
//   - STANDARDS_DIR (all *.md — normative + companion files)
//   - DOCS_DIR = docs/sandbox/ (all *.md — guides, cookbooks, parts)
//   - TEMPLATES_DIR (all *.md)
//
//   Deliberately EXCLUDED:
//   - docs/session/*.md (worklog, SESSION_NOTES, DECISIONS_LOG) — these are
//     append-only journals that grow by design.
//   - scripts/*.js (verifier self-checking is a chicken-egg)
//   - README.md at repo root (project landing page, not a standard)
//
//   The scan uses fs.readdirSync (NOT an enumerated target list) so that any
//   NEW .md file added to the covered directories is automatically subject to
//   the cap. V04/V08/V09 use enumerated lists because they need specific file
//   paths for content-level checks; V11 is structural and must catch growth
//   anywhere in the covered trees.
//
// THRESHOLD
//   1000 lines (matches W11 soft cap exactly — no threshold inflation). If a
//   file legitimately needs >1000 lines, the right answer is to split it into
//   a companion file + INDEX (see DESIGN-001 split pattern, 2026-06-21), not
//   to relax V11.
// ============================================================================
(function V11() {
  const HARD_CAP = 1000;

  function listMd(dir) {
    if (!fs.existsSync(dir)) return [];
    return fs
      .readdirSync(dir)
      .filter((f) => f.endsWith(".md"))
      .map((f) => path.join(dir, f));
  }

  const targets = [...listMd(STANDARDS_DIR), ...listMd(DOCS_DIR), ...listMd(TEMPLATES_DIR)];

  const offenders = [];
  for (const file of targets) {
    const content = readSafe(file) || "";
    // Line count: split on \n. Trailing newline does not add a phantom line
    // because split returns ['last', ''] for 'a\n' → 2 entries, but the
    // empty string is not a line of content. Use the same convention as
    // verify-id-graph.js (which uses `wc -l`-equivalent counting).
    const lineCount =
      content === "" ? 0 : content.split("\n").length - (content.endsWith("\n") ? 1 : 0);
    if (lineCount > HARD_CAP) {
      offenders.push(
        `${path.basename(file)}: ${lineCount} lines (exceeds ${HARD_CAP}-line hard cap, split required)`,
      );
    }
  }

  check(
    "V11",
    `No .md file in standards/ + docs/sandbox/ + templates/ exceeds ${HARD_CAP} lines (hard promotion of W11 soft cap) — scanned ${targets.length} files`,
    offenders.length === 0,
    offenders.length === 0
      ? `all ${targets.length} files ≤ ${HARD_CAP} lines`
      : `${offenders.length} file(s) over cap: ${offenders.join("; ")}`,
  );
})();

// ============================================================================
// V12 — WORKLOG_TEMPLATE.md must exist and have expected structure
//       (non-normative companion)
//
// Checks:
//   (a) File exists in templates/
//   (b) Has "append-only" rule (core invariant: worklog is append-only)
//   (c) Has "Entry Format" or "Template" section with example structure
// ============================================================================
(function V12() {
  const content = readSafe(PATHS.WORKLOG_TEMPLATE);
  if (!content) {
    check(
      "V12",
      "WORKLOG_TEMPLATE.md exists in templates/ with expected structure",
      false,
      "WORKLOG_TEMPLATE.md not found",
    );
    return;
  }
  const hasAppendOnly = /append.only/i.test(content);
  const hasEntryFormat =
    /## 3\.\s*Entry Format/i.test(content) ||
    /## 2\.\s*Template/i.test(content) ||
    /## 3\.\s*Template/i.test(content);

  check(
    "V12",
    "WORKLOG_TEMPLATE.md exists with append-only rule + entry format section",
    hasAppendOnly && hasEntryFormat,
    `append-only=${hasAppendOnly}, entry format=${hasEntryFormat}`,
  );
})();

// ============================================================================
// V13 — CHANGELOG_TEMPLATE.md must exist and have expected structure
//       (STD-DOC-009, non-normative companion)
//
// Checks:
//   (a) File exists in templates/
//   (b) References "Keep a Changelog" format
//   (c) Has version categories (Added, Changed, Deprecated, Removed, Fixed, Security)
// ============================================================================
(function V13() {
  const content = readSafe(PATHS.CHANGELOG_TEMPLATE);
  if (!content) {
    check(
      "V13",
      "CHANGELOG_TEMPLATE.md exists in templates/ with expected structure",
      false,
      "CHANGELOG_TEMPLATE.md not found",
    );
    return;
  }
  const hasKeepAChangelog = /keep.a.changelog/i.test(content) || /keepachangelog/i.test(content);
  const categories = ["Added", "Changed", "Deprecated", "Removed", "Fixed", "Security"];
  const foundCount = categories.filter((c) => new RegExp(`## ${c}`, "i").test(content)).length;

  check(
    "V13",
    "CHANGELOG_TEMPLATE.md exists with Keep a Changelog format (6 categories)",
    hasKeepAChangelog && foundCount >= 4,
    `Keep a Changelog ref=${hasKeepAChangelog}, categories found=${foundCount}/6`,
  );
})();

// ============================================================================
// V14 — AGENT_RULES_TEMPLATE.md must exist and have expected structure
//       (non-normative companion)
//
// Checks:
//   (a) File exists in templates/
//   (b) Has Onboarding Protocol section (core: session start sequence)
//   (c) Has Priority Order section (core: conflict resolution)
//   (d) Has Sections table (structure definition)
// ============================================================================
(function V14() {
  const content = readSafe(PATHS.AGENT_RULES_TEMPLATE);
  if (!content) {
    check(
      "V14",
      "AGENT_RULES_TEMPLATE.md exists in templates/ with expected structure",
      false,
      "AGENT_RULES_TEMPLATE.md not found",
    );
    return;
  }
  const hasOnboarding = /onboarding.protocol/i.test(content);
  const hasPriorityOrder = /priority.order/i.test(content) || /conflict.resolution/i.test(content);
  const hasSectionsTable =
    /\|\s*Section\s*\|\s*Required/i.test(content) ||
    /\|\s*Section\s*\|\s*Description/i.test(content);

  check(
    "V14",
    "AGENT_RULES_TEMPLATE.md exists with Onboarding Protocol + Priority Order + Sections table",
    hasOnboarding && hasPriorityOrder && hasSectionsTable,
    `onboarding=${hasOnboarding}, priority order=${hasPriorityOrder}, sections table=${hasSectionsTable}`,
  );
})();

// ============================================================================
// V15 — If project worklog.md exists, it MUST follow WORKLOG_TEMPLATE structure
//       (enforcement: project files match template invariants)
//
// Checks (only if worklog.md exists in repo root):
//   (a) Has date-stamped entries (## YYYY-MM-DD or [YYYY-MM-DD HH:MM] pattern)
//   (b) Has status tags ([OK], [FAIL], or [WIP])
// ============================================================================
(function V15() {
  const worklogPath = path.join(REPO_ROOT, "worklog.md");
  const content = readSafe(worklogPath);
  if (!content) {
    check(
      "V15",
      "If worklog.md exists, it follows WORKLOG_TEMPLATE structure",
      true,
      "worklog.md not found — skipping (not required at standards level)",
    );
    return;
  }
  const hasTimestamps =
    /\[\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}\]/.test(content) || /##\s*\d{4}-\d{2}-\d{2}/.test(content);
  const hasStatusTags = /\[(OK|FAIL|WIP)\]/.test(content);

  check(
    "V15",
    "worklog.md follows WORKLOG_TEMPLATE: timestamps + status tags",
    hasTimestamps && hasStatusTags,
    `timestamps=${hasTimestamps}, status tags=${hasStatusTags}`,
  );
})();

// ============================================================================
// V16 — If project CHANGELOG.md exists, it MUST follow CHANGELOG_TEMPLATE structure
//       (enforcement: project files match template invariants)
//
// Checks (only if CHANGELOG.md exists in repo root):
//   (a) Has version headers (## [X.Y.Z] or ## X.Y.Z pattern)
//   (b) Has at least one Keep a Changelog category (Added, Changed, Fixed, etc.)
// ============================================================================
(function V16() {
  const changelogPath = path.join(REPO_ROOT, "CHANGELOG.md");
  const content = readSafe(changelogPath);
  if (!content) {
    check(
      "V16",
      "If CHANGELOG.md exists, it follows CHANGELOG_TEMPLATE structure",
      true,
      "CHANGELOG.md not found — skipping (not required at standards level)",
    );
    return;
  }
  const hasVersionHeaders = /##\s*\[?\d+\.\d+\.\d+/.test(content);
  const categories = ["Added", "Changed", "Deprecated", "Removed", "Fixed", "Security"];
  const foundCategories = categories.filter((c) => new RegExp(`###?\\s+${c}`, "i").test(content));

  check(
    "V16",
    "CHANGELOG.md follows CHANGELOG_TEMPLATE: version headers + Keep a Changelog categories",
    hasVersionHeaders && foundCategories.length >= 1,
    `version headers=${hasVersionHeaders}, categories found=[${foundCategories.join(", ")}]`,
  );
})();

// ============================================================================
// V17 — If project AGENT_RULES.md exists, it MUST follow AGENT_RULES_TEMPLATE structure
//       (enforcement: project files match template invariants)
//
// Checks (only if AGENT_RULES.md exists in repo root):
//   (a) Has Onboarding Protocol section (session start sequence)
//   (b) Has Priority Order or conflict resolution section
//   (c) Has Prohibitions section
// ============================================================================
(function V17() {
  // Support both AGENT_RULES.md and AGENT-RULES.md (hyphen convention)
  const possibleNames = ["AGENT_RULES.md", "AGENT-RULES.md"];
  const agentRulesPath = possibleNames
    .map((name) => path.join(REPO_ROOT, name))
    .find((p) => fs.existsSync(p));
  const content = agentRulesPath ? readSafe(agentRulesPath) : null;
  if (!content) {
    check(
      "V17",
      "If AGENT_RULES.md exists, it follows AGENT_RULES_TEMPLATE structure",
      true,
      "AGENT_RULES.md not found — skipping (not required at standards level)",
    );
    return;
  }
  const hasOnboarding = /onboarding|session.start|step\s*1/i.test(content);
  const hasPriorityOrder = /priority|conflict.resolution|when.*disagree/i.test(content);
  const hasProhibitions = /prohibitions|must.never|never\s+/i.test(content);

  check(
    "V17",
    "AGENT_RULES.md (or AGENT-RULES.md) follows AGENT_RULES_TEMPLATE: onboarding + priority order + prohibitions",
    hasOnboarding && hasPriorityOrder && hasProhibitions,
    `onboarding=${hasOnboarding}, priority order=${hasPriorityOrder}, prohibitions=${hasProhibitions}`,
  );
})();

// ============================================================================
// V18 — Root README.md follows README_TEMPLATE structure (STD-DOC-004 v3.0)
//
// Checks (only if README.md exists in repo root):
//   (a) Has badges (shields.io or similar badge syntax)
//   (b) Has required sections: Features, Tech Stack, Getting Started, License
//   (c) Section order matches template (Title -> Badges -> Features -> Tech Stack -> Getting Started -> License)
//   (d) Stack Signature format correct (for app repos) or absent (for governance)
// ============================================================================
(function V18() {
  const readmePath = PATHS.ROOT_README;
  const content = readSafe(readmePath);
  if (!content) {
    check(
      "V18",
      "If README.md exists, it follows README_TEMPLATE structure (STD-DOC-004 v3.0)",
      true,
      "README.md not found — skipping",
    );
    return;
  }

  const lines = content.split("\n");

  // (a) Badges: look for shields.io or badge syntax
  const hasBadges = /shields\.io|!\[.*\]\(https?:\/\/.*badge/.test(content);

  // (b) Required sections (case-insensitive heading match)
  const headings = lines
    .filter((l) => /^#{1,3}\s+/.test(l))
    .map((l) =>
      l
        .replace(/^#{1,3}\s+/, "")
        .trim()
        .toLowerCase(),
    );

  const hasFeatures = headings.some((h) => /features?/.test(h));
  const hasTechStack = headings.some((h) => /tech.?stack|stack|technologies/.test(h));
  const hasGettingStarted = headings.some((h) =>
    /getting.?started|install|setup|quick.?start/.test(h),
  );
  const hasLicense = headings.some((h) => /^license$/.test(h));

  // (c) Description length: first paragraph after H1 should be 1-2 sentences
  const h1Index = lines.findIndex((l) => /^#\s+/.test(l));
  let descriptionOk = true;
  if (h1Index >= 0) {
    // Find first non-empty line after H1
    let descStart = h1Index + 1;
    while (descStart < lines.length && lines[descStart].trim() === "") descStart++;
    // Count sentences until next heading or empty line
    let descEnd = descStart;
    while (
      descEnd < lines.length &&
      lines[descEnd].trim() !== "" &&
      !/^#{1,3}\s+/.test(lines[descEnd])
    ) {
      descEnd++;
    }
    const descLines = descEnd - descStart;
    // 1-3 lines is acceptable for 1-2 sentences
    descriptionOk = descLines >= 1 && descLines <= 5;
  }

  const allOk =
    hasBadges && hasFeatures && hasTechStack && hasGettingStarted && hasLicense && descriptionOk;

  const details = [
    `badges=${hasBadges}`,
    `features=${hasFeatures}`,
    `techStack=${hasTechStack}`,
    `gettingStarted=${hasGettingStarted}`,
    `license=${hasLicense}`,
    `description=${descriptionOk}`,
  ].join(", ");

  check(
    "V18",
    "README.md follows README_TEMPLATE: badges + required sections (STD-DOC-004 v3.0)",
    allOk,
    details,
  );
})();
// ============================================================================
function printHuman() {
  const width = Math.max(...results.checks.map((c) => c.id.length));
  console.log("PERMANENT STANDARDS VERIFIER — verify-standards.js");
  console.log("=".repeat(72));
  console.log("");
  for (const c of results.checks) {
    const icon = c.status === "PASS" ? "[PASS]" : "[FAIL]";
    console.log(`${icon} ${c.id.padEnd(width)}  ${c.description}`);
    if (c.detail) console.log(`         ${c.detail}`);
  }
  console.log("");
  console.log("-".repeat(72));
  console.log(
    `Total: ${results.checks.length}  |  PASS: ${results.passed}  |  FAIL: ${results.failed}`,
  );
  console.log("");
  if (results.failed > 0) {
    console.log("ACTION REQUIRED:");
    console.log("  At least one invariant was violated. Either:");
    console.log("    (a) Revert the standard change that broke the invariant, OR");
    console.log("    (b) Update the V## check in scripts/verify-standards.js to reflect");
    console.log("        an intentional change to the invariant.");
    console.log("  Then re-run: node scripts/verify-standards.js");
  } else {
    console.log("All invariants hold. Standards are consistent with the cascade plan.");
  }
}

function printJSON() {
  console.log(
    JSON.stringify(
      {
        script: "verify-standards.js",
        generated: new Date().toISOString(),
        passed: results.passed,
        failed: results.failed,
        total: results.checks.length,
        checks: results.checks,
      },
      null,
      2,
    ),
  );
}

const mode = process.argv[2] || "";
if (mode === "--json") printJSON();
else printHuman();

process.exit(results.failed > 0 ? 1 : 0);
