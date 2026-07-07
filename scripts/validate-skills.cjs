#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const PLATFORM = process.cwd();
const SKILLS_DIR = path.join(PLATFORM, "skills");
const RULES_DIR = path.join(PLATFORM, "guard", "rules");
const STANDARDS_DIR = path.join(PLATFORM, "standards", "standards");
let totalIssues = 0;
function fail(m) {
  console.log("  FAIL: " + m);
  totalIssues++;
}
function pass(m) {
  console.log("  PASS: " + m);
}
function warn(m) {
  console.log("  WARN: " + m);
}
function info(m) {
  console.log("  INFO: " + m);
}
const reg = JSON.parse(
  fs.readFileSync(path.join(PLATFORM, "scripts", "skills-registry.json"), "utf-8"),
);
const skillFolders = new Set(
  fs
    .readdirSync(SKILLS_DIR)
    .filter((d) => d.indexOf("zai-") === 0 && fs.statSync(path.join(SKILLS_DIR, d)).isDirectory()),
);
const ruleFiles = new Set(
  fs
    .readdirSync(RULES_DIR)
    .filter((f) => f.indexOf("RULE-") === 0)
    .map((f) => f.replace(/\.md$/, "")),
);
const stdShort = new Set(
  fs
    .readdirSync(STANDARDS_DIR)
    .filter((f) => /^[A-Z]/.test(f))
    .map((f) => f.match(/^([A-Z]+\d*[A-Z]*-\d+)/)?.[1])
    .filter(Boolean),
);
const regIds = new Set(reg.ids.filter((e) => e.id).map((e) => e.id));
console.log("=== Check 1: every registry ZAI id has a skill folder ===");
for (const e of reg.ids) {
  if (e.id && !skillFolders.has(e.name) && !skillFolders.has(e.id))
    fail(e.id + " missing skill folder");
}
if (totalIssues === 0)
  pass("all " + reg.ids.filter((e) => e.id).length + " ZAI ids have skill folders");
console.log("");
console.log("=== Check 2: every skill folder with ZAI id has registry entry ===");
const folderIds = new Set();
for (const f of skillFolders) {
  const p = path.join(SKILLS_DIR, f, "SKILL.md");
  if (!fs.existsSync(p)) continue;
  const m = fs.readFileSync(p, "utf-8").match(/^---\r?\n([\s\S]+?)\r?\n---\r?\n/);
  if (m) {
    const id = m[1].match(/^id:\s*(ZAI-[A-Z]+-\d+)/m);
    if (id) folderIds.add(id[1]);
  }
}
for (const id of folderIds) {
  if (!regIds.has(id)) fail(id + " not in registry");
}
if (totalIssues === 0) pass("all " + folderIds.size + " skill-folder ids in registry");
console.log("");
console.log("=== Check 3: related[] references resolve ===");
for (const e of reg.ids)
  for (const r of e.related || []) {
    if (r.indexOf("RULE-") === 0 && !ruleFiles.has(r))
      fail(e.id + " related: " + r + " (no such RULE)");
    else if (r.indexOf("STD-") === 0 && !stdShort.has(r.replace(/^STD-/, "")))
      fail(e.id + " related: " + r + " (no such STD)");
  }
if (totalIssues === 0) pass("all related[] references resolve");
console.log("");
console.log("=== Check 4: implements[] is subset of related[] ===");
for (const e of reg.ids) {
  const relR = (e.related || []).filter((r) => r.indexOf("RULE-") === 0);
  for (const i of e.implements || [])
    if (!relR.includes(i)) fail(e.id + " implements: " + i + " not in related[]");
}
if (totalIssues === 0) pass("implements[] correctly categorized");
console.log("");
console.log("=== Check 5: supports[] is subset of related[] ===");
for (const e of reg.ids) {
  const relS = (e.related || []).filter((r) => r.indexOf("STD-") === 0);
  for (const s of e.supports || [])
    if (!relS.includes(s)) fail(e.id + " supports: " + s + " not in related[]");
}
if (totalIssues === 0) pass("supports[] correctly categorized");
console.log("");
console.log("=== Check 6: warn on boilerplate related ===");
for (const e of reg.ids) {
  if (e.related && e.related.length > 0 && e.related.every((r) => r === "STD-SKILL-001")) {
    warn(e.id + " related: only [STD-SKILL-001] (boilerplate)");
  }
}
const bp = reg.ids.filter(
  (e) => e.related && e.related.length > 0 && e.related.every((r) => r === "STD-SKILL-001"),
).length;
info(bp + " of " + reg.ids.length + " skills have boilerplate related");
console.log("");
console.log("=== Summary ===");
console.log("Total: " + reg.ids.length + ", FAIL: " + totalIssues + ", Boilerplate: " + bp);
process.exit(totalIssues > 0 ? 1 : 0);
