#!/usr/bin/env node
/**
 * validate-registry.js — Full validation of guard/registry.json
 *
 * Checks:
 *   1. Every ID in registry has a corresponding definition
 *   2. Every implements/calls reference resolves
 *   3. Every file reference exists (non-RETIRED)
 *   4. Script "Implements:" header matches registry
 *   5. RULE files have related: connections
 *   6. Every owning_standard points to an existing standard
 */
const fs = require("fs");
const path = require("path");

const reg = JSON.parse(fs.readFileSync("guard/registry.json", "utf-8"));

// Build sets of valid IDs
const validIds = new Map();
for (const e of reg.ids) validIds.set(e.id, e);

// Collect all RULE-*.md filenames
const ruleFiles = fs.readdirSync("guard/rules").filter((f) => /^RULE-/.test(f));
const rulesFromFs = new Set(ruleFiles.map((f) => f.replace(/\.md$/, "")));

let totalIssues = 0;

function fail(msg) {
  console.log("  FAIL: " + msg);
  totalIssues++;
}
function warn(msg) {
  console.log("  WARN: " + msg);
}
function info(msg) {
  console.log("  INFO: " + msg);
}
function pass(msg) {
  console.log("  PASS: " + msg);
}

// Check 1: every ID in registry has a corresponding definition
console.log("=== Check 1: IDs in registry are defined ===");
const idsInReg = new Set(reg.ids.map((e) => e.id));
for (const id of idsInReg) {
  if (id.startsWith("RULE-") && !rulesFromFs.has(id)) {
    fail(id + " in registry but no .md file");
  }
}
for (const f of ruleFiles) {
  const id = f.replace(/\.md$/, "");
  if (!idsInReg.has(id)) fail(id + " .md exists but not in registry");
}
if (totalIssues === 0) pass("all 17 RULEs defined and in registry");

// Check 2: every implements/calls reference resolves
console.log("\n=== Check 2: implements/calls references ===");
for (const e of reg.ids) {
  if (e.implements) {
    const target = validIds.get(e.implements);
    if (!target) fail(e.id + " -> implements " + e.implements + " (NOT IN REGISTRY)");
    else if (
      !rulesFromFs.has(e.implements) &&
      !e.implements.startsWith("PROC-") &&
      !e.implements.startsWith("TOOL-")
    ) {
      fail(e.id + " -> implements " + e.implements + " (NOT A RULE/PROC/TOOL)");
    }
  }
  for (const c of e.calls || []) {
    if (!validIds.has(c)) fail(e.id + " -> calls " + c + " (NOT IN REGISTRY)");
  }
}
if (totalIssues === 0) pass("all implements/calls references resolve");

// Check 3: every file reference exists (non-RETIRED)
console.log("\n=== Check 3: file references exist ===");
for (const e of reg.ids) {
  if (e.file && !e.file.startsWith("(") && e.status !== "RETIRED") {
    if (!fs.existsSync(e.file)) fail(e.id + " -> " + e.file + " (NOT FOUND)");
  }
}
if (totalIssues === 0) pass("all ACTIVE file references exist");

// Check 4: script 'Implements:' header consistent with registry
// Rule: if registry.implements is set, header MUST match.
//       if registry.implements is null, header MUST be absent.
console.log("\n=== Check 4: script header matches registry ===");
for (const e of reg.ids) {
  if (e.file && e.file.endsWith(".sh") && e.status !== "RETIRED" && fs.existsSync(e.file)) {
    const content = fs.readFileSync(e.file, "utf-8");
    const m = content.match(/^#\s*Implements:\s*(.+)$/m);
    const hasHeader = !!m;
    const declared = m ? m[1].trim().split(/[\s,]+/)[0] : null;
    const regImplements = e.implements;

    if (regImplements && !hasHeader) {
      fail(
        e.id +
          ": registry says implements " +
          regImplements +
          " but script has no Implements: header",
      );
    } else if (!regImplements && hasHeader) {
      fail(e.id + ": registry says null but script has Implements: " + declared);
    } else if (regImplements && declared !== regImplements) {
      fail(e.id + ": script says " + declared + ", registry says " + regImplements);
    } else if (regImplements) {
      pass(e.id + ": header matches (" + declared + ")");
    } else {
      pass(e.id + ": no Implements: (infrastructure, correct)");
    }
  }
}

// Check 5: RULE files have related: connections (look at frontmatter)
console.log("\n=== Check 5: RULE files related: connections ===");
for (const f of ruleFiles) {
  const content = fs.readFileSync(path.join("guard/rules", f), "utf-8");
  const fmMatch = content.match(/^---\n([\s\S]+?)\n---/);
  if (!fmMatch) {
    fail(f + " has no frontmatter");
    continue;
  }
  const fm = fmMatch[1];
  const relMatch = fm.match(/^related:\n((?:\s+-\s+.+\n?)+)/m);
  if (!relMatch) {
    warn(f + " has no related: field");
  } else {
    const related = relMatch[1]
      .split("\n")
      .filter((l) => l.trim().startsWith("-"))
      .map((l) => l.trim().replace(/^-\s*/, "").trim());
    if (related.length === 1) {
      info(f + " related: [" + related[0] + "] (only 1 connection)");
    }
    // Verify each reference resolves
    for (const ref of related) {
      const idOnly = ref.split(/\s/)[0]; // "STD-META-001 (foo)" -> "STD-META-001"
      if (idOnly.startsWith("RULE-") && !rulesFromFs.has(idOnly)) {
        fail(f + " related: " + idOnly + " (no such RULE file)");
      }
    }
  }
}

// Check 5b: PROC/TOOL script Related: references resolve
console.log("\n=== Check 5b: script Related: references ===");
const stdFiles = fs.readdirSync("standards/standards").filter((f) => /^[A-Z]+-/.test(f));
for (const e of reg.ids) {
  if (
    (e.id.startsWith("PROC-") || e.id.startsWith("TOOL-")) &&
    e.file &&
    e.file.endsWith(".sh") &&
    e.status !== "RETIRED" &&
    fs.existsSync(e.file)
  ) {
    const content = fs.readFileSync(e.file, "utf-8");
    // Find all # Comment lines and extract IDs
    const lines = content.split("\n");
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      // Start of a comment block (Related:, Calls:, Implements:)
      if (/^\s*#\s*(Related|Calls|Implements):/i.test(line)) {
        // Read continuation lines (indented under #)
        let j = i;
        while (j + 1 < lines.length && /^\s+#/.test(lines[j + 1])) {
          j++;
          const ids = lines[j].match(/(?:RULE|STD|PROC|TOOL)-[A-Z]+-\d+/g) || [];
          for (const ref of ids) {
            if (ref.startsWith("RULE-") && !rulesFromFs.has(ref)) {
              fail(e.id + " Related: " + ref + " (no such RULE file)");
            }
            if (
              ref.startsWith("STD-") &&
              !stdFiles.some((sf) => sf.includes(ref.replace(/^STD-/, "")))
            ) {
              fail(e.id + " Related: " + ref + " (no matching .md)");
            }
            if (ref.startsWith("PROC-") && !reg.ids.some((r) => r.id === ref)) {
              fail(e.id + " Related: " + ref + " (not in registry)");
            }
            if (ref.startsWith("TOOL-") && !reg.ids.some((r) => r.id === ref)) {
              fail(e.id + " Related: " + ref + " (not in registry)");
            }
          }
        }
        i = j;
      }
    }
  }
}
for (const e of reg.ids) {
  if (e.owning_standard) {
    const stdId = e.owning_standard.split(" ")[0]; // e.g. "STD-META-001"
    const stdShort = stdId.replace(/^STD-/, ""); // e.g. "META-001"
    const found = stdFiles.some((f) => f.includes(stdShort));
    if (!found) fail(e.id + " owning_standard " + stdId + " (no matching .md)");
  }
}
if (totalIssues === 0) pass("all owning_standard references resolve");

console.log("\n=== Summary ===");
console.log("Total IDs: " + reg.ids.length);
console.log("  RULE: " + reg.ids.filter((e) => e.id.startsWith("RULE-")).length);
console.log("  PROC: " + reg.ids.filter((e) => e.id.startsWith("PROC-")).length);
console.log("  TOOL: " + reg.ids.filter((e) => e.id.startsWith("TOOL-")).length);
console.log("RETIRED: " + reg.ids.filter((e) => e.status === "RETIRED").length);
console.log("ACTIVE: " + reg.ids.filter((e) => e.status === "ACTIVE").length);
console.log("TOTAL ISSUES: " + totalIssues);
process.exit(totalIssues > 0 ? 1 : 0);
