#!/usr/bin/env node
/**
 * build-skills-registry.js — auto-generate skills-registry.json
 * Scans skills/{name}/SKILL.md frontmatter, builds a registry of ZAI-*
 * skills with their connections. Mirrors build-registry.py but for skills.
 */
const fs = require("fs");
const path = require("path");

const PLATFORM = process.cwd();
const SKILLS_DIR = path.join(PLATFORM, "skills");
const OUTPUT = path.join(PLATFORM, "scripts", "skills-registry.json");

function readFrontmatter(content) {
  const m = content.match(/^---\r?\n([\s\S]+?)\r?\n---\r?\n/);
  return m ? m[1] : null;
}

function parseList(fm, key) {
  const m = fm.match(new RegExp("^" + key + ":\\s*\\n((?:\\s+-\\s+.+\\n?)+)", "m"));
  if (!m) return [];
  return m[1]
    .split("\n")
    .filter((l) => /^\s+-\s+/.test(l))
    .map((l) => l.trim().replace(/^-\s*/, "").split(/\s/)[0])
    .filter(Boolean);
}

function parseScalar(fm, key) {
  const m = fm.match(new RegExp("^" + key + ":\\s*(.+)$", "m"));
  return m ? m[1].trim() : null;
}

const skills = [];
const skillsDirs = fs.readdirSync(SKILLS_DIR).filter((d) => {
  const p = path.join(SKILLS_DIR, d);
  return d.startsWith("zai-") && fs.statSync(p).isDirectory();
});

for (const d of skillsDirs) {
  const skillMd = path.join(SKILLS_DIR, d, "SKILL.md");
  if (!fs.existsSync(skillMd)) {
    skills.push({
      id: null,
      name: d,
      version: null,
      status: "ACTIVE",
      file: "skills/" + d + "/SKILL.md",
      related: [],
      implements: [],
      supports: [],
      _warning: "no SKILL.md",
    });
    continue;
  }
  const content = fs.readFileSync(skillMd, "utf-8");
  const fm = readFrontmatter(content);
  if (!fm) {
    skills.push({
      id: null,
      name: d,
      version: null,
      status: "ACTIVE",
      file: "skills/" + d + "/SKILL.md",
      related: [],
      implements: [],
      supports: [],
      _warning: "no frontmatter",
    });
    continue;
  }
  const id = parseScalar(fm, "id");
  const version = parseScalar(fm, "version");
  const related = parseList(fm, "related");
  const ruleRefs = related.filter((r) => r.indexOf("RULE-") === 0);
  const stdRefs = related.filter((r) => r.indexOf("STD-") === 0);
  const others = related.filter((r) => r.indexOf("RULE-") !== 0 && r.indexOf("STD-") !== 0);
  skills.push({
    id,
    name: parseScalar(fm, "name") || d,
    version: version || "unknown",
    status: "ACTIVE",
    file: "skills/" + d + "/SKILL.md",
    related,
    implements: ruleRefs,
    supports: stdRefs,
    other_relations: others.length ? others : undefined,
  });
}

const registry = {
  generated_at: new Date().toISOString(),
  platform_version: "v2.7.0",
  counts: {
    ZAI: skills.length,
    ZAI_with_id: skills.filter((s) => s.id).length,
    ZAI_with_related: skills.filter((s) => s.related.length > 0).length,
    ZAI_with_implements: skills.filter((s) => s.implements.length > 0).length,
    ZAI_with_supports: skills.filter((s) => s.supports.length > 0).length,
  },
  ids: skills,
};

fs.writeFileSync(OUTPUT, JSON.stringify(registry, null, 2) + "\n");
console.log("Wrote " + OUTPUT);
console.log("  Total ZAI: " + registry.counts.ZAI);
console.log("  With id: " + registry.counts.ZAI_with_id);
console.log("  With related: " + registry.counts.ZAI_with_related);
console.log("  With implements (RULE-): " + registry.counts.ZAI_with_implements);
console.log("  With supports (STD-): " + registry.counts.ZAI_with_supports);
