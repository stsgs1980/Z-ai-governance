/**
 * ============================================================================
 * lib/declarations.js — header + migrations parsers for verify-id-graph.js
 * ============================================================================
 *
 * Extracted from verify-id-graph.js v1.1.5 as part of O-018 modularization
 * (continuation). Contains extractDeclaration() and parseMigrations() —
 * the impure (fs-reading) parsers that take a filePath and return a
 * declaration object or a migrations list.
 *
 * DEPENDENCIES
 *   - fs (for readFileSync, existsSync)
 *   - path (not used directly, but filePath comes from caller)
 *   - lib/parsers.js: parseYAMLFrontmatter, parseBlockquoteHeader,
 *     parseHTMLComment (pure parsers, imported here)
 *   - lib/constants.js: ID_REGEX
 *
 * DESIGN
 *   These functions are NOT pure — they call fs.readFileSync(). They are
 *   kept together in lib/declarations.js (rather than inlined in the main
 *   verifier) so that:
 *     (a) The main file is shorter and easier to scan for the orchestration
 *         logic (phases 1-9, main()).
 *     (b) A future test harness can mock fs and exercise edge cases
 *         (malformed YAML, missing blockquote, mixed-format headers).
 *
 *   The pure parsing primitives (parseYAMLFrontmatter etc.) live in
 *   lib/parsers.js and are reused by both this module and verify-skills.js.
 *
 * ============================================================================
 */

"use strict";

const fs = require("fs");
const { ID_REGEX } = require("./constants");
const { parseYAMLFrontmatter, parseBlockquoteHeader, parseHTMLComment } = require("./parsers");

// Regex to extract ID-shaped tokens (STD/RULE/PROC/TOOL/ZAI-<DOMAIN>-<NNN>)
// from Related: and Aligned_with: prose fields. Used to filter out
// non-ID prose like "see also the FAQ" — only ID tokens are edges.
const ID_TOKEN_RE = /\b(STD|RULE|PROC|TOOL|ZAI)-[A-Z]+-\d{3}\b/g;

/**
 * extractDeclaration(filePath, repoName) → decl | null
 *
 * Reads the file at filePath, tries 3 header formats in order:
 *   1. HTML comment (rules): <!-- ID: RULE-XXX-001 ... -->
 *   2. YAML frontmatter (skills): ---\n id: ZAI-XXX-001 \n---
 *   3. Blockquote (standards): > ID: STD-XXX-001
 *
 * Returns a declaration object with all extracted fields, or null if no
 * header found. The decl object carries:
 *   - id, prefix, domain, number (parsed from ID_REGEX)
 *   - version, level, related[], aligned_with[]
 *   - compatibility, trigger, author (skills-only, null for rules/standards)
 *   - file, repo, header_format ('html-comment' | 'yaml' | 'blockquote')
 *   - malformed (true if ID doesn't match ID_REGEX)
 *   - _fmId/_bqId/_fmVer/_bqVer (for V14a/V14b cross-checks, null if consistent)
 *
 * For YAML frontmatter skills, also parses blockquote for Related:/Aligned_with:
 * and merges them (YAML takes precedence, blockquote fills gaps). This is
 * per STD-SKILL-001 §3.4 — blockquote is the human-readable copy, YAML is
 * canonical.
 */
function extractDeclaration(filePath, repoName) {
  const content = fs.readFileSync(filePath, "utf8");
  if (!content.trim()) return null;

  let decl = null;
  let format = null;

  // Try HTML comment first (rules)
  const htmlFields = parseHTMLComment(content);
  if (htmlFields && htmlFields.id) {
    decl = htmlFields;
    format = "html-comment";
  }

  // Try YAML frontmatter (skills)
  if (!decl) {
    const yaml = parseYAMLFrontmatter(content);
    if (yaml && yaml.id) {
      // For ZAI skills with YAML frontmatter, also parse blockquote for Related:/Aligned_with:
      const bq = parseBlockquoteHeader(content);
      // Prefer YAML list (related:); fall back to blockquote Related:
      let yamlRelated = [];
      if (Array.isArray(yaml.related)) {
        yamlRelated = yaml.related.flatMap((v) => v.match(ID_TOKEN_RE) || []);
      } else if (yaml.related) {
        yamlRelated = yaml.related.match(ID_TOKEN_RE) || [];
      }
      let yamlAligned = [];
      if (Array.isArray(yaml.aligned_with)) {
        yamlAligned = yaml.aligned_with.flatMap((v) => v.match(ID_TOKEN_RE) || []);
      } else if (yaml.aligned_with) {
        yamlAligned = yaml.aligned_with.match(ID_TOKEN_RE) || [];
      }
      const bqRelated = bq.Related ? bq.Related.match(ID_TOKEN_RE) || [] : [];
      const bqAligned = bq.Aligned_with ? bq.Aligned_with.match(ID_TOKEN_RE) || [] : [];
      // Merge and dedupe (YAML takes precedence, blockquote fills gaps)
      const relatedIds = [...new Set([...yamlRelated, ...bqRelated])];
      const alignedIds = [...new Set([...yamlAligned, ...bqAligned])];

      decl = {
        id: yaml.id,
        version: yaml.version,
        related: relatedIds,
        aligned_with: alignedIds,
        compatibility: yaml.compatibility || null,
        trigger: yaml.trigger ? yaml.trigger.split(",").map((s) => s.trim()) : null,
        author: yaml.author || null,
        level: yaml.level
          ? String(yaml.level)
              .replace(/[\[\]\*]/g, "")
              .trim()
          : null,
      };
      format = "yaml";
      // Cross-check frontmatter id vs blockquote ID
      if (bq.ID && bq.ID !== decl.id) {
        decl._fmId = decl.id;
        decl._bqId = bq.ID;
      }
      if (bq.Version && bq.Version !== decl.version) {
        decl._fmVer = decl.version;
        decl._bqVer = bq.Version;
      }
    }
  }

  // Try blockquote (standards)
  if (!decl) {
    const bq = parseBlockquoteHeader(content);
    if (bq.ID) {
      // Parse Related: — extract only ID-shaped tokens (ignore prose)
      const relatedIds = bq.Related ? bq.Related.match(ID_TOKEN_RE) || [] : [];
      const alignedIds = bq.Aligned_with ? bq.Aligned_with.match(ID_TOKEN_RE) || [] : [];

      decl = {
        id: bq.ID,
        version: bq.Version || null,
        level: bq.Level ? bq.Level.replace(/[\[\]\*]/g, "").trim() : null,
        related: relatedIds,
        aligned_with: alignedIds,
        compatibility: null,
        trigger: null,
        author: null,
      };
      format = "blockquote";
    }
  }

  if (!decl) return null;

  // Extract title from first H1 heading (after frontmatter/blockquote)
  let title = null;
  const lines = content.split("\n");
  for (const line of lines) {
    const h1 = line.match(/^#\s+(.+)\r?$/);
    if (h1) {
      title = h1[1].trim();
      break;
    }
  }

  // Parse ID components
  const m = decl.id.match(ID_REGEX);
  if (!m) {
    // G12 candidate — typo-IDs handled in Phase 4
    return {
      id: decl.id,
      prefix: null,
      domain: null,
      number: null,
      malformed: true,
      file: filePath,
      repo: repoName,
      header_format: format,
      ...decl,
    };
  }

  return {
    id: decl.id,
    prefix: m[1],
    domain: m[2],
    number: parseInt(m[3], 10),
    version: decl.version,
    level: decl.level,
    title: title,
    related: decl.related || [],
    aligned_with: decl.aligned_with || [],
    compatibility: decl.compatibility || null,
    trigger: decl.trigger || null,
    author: decl.author || null,
    file: filePath,
    repo: repoName,
    header_format: format,
    malformed: false,
    _fmId: decl._fmId || null,
    _bqId: decl._bqId || null,
    _fmVer: decl._fmVer || null,
    _bqVer: decl._bqVer || null,
  };
}

/**
 * parseMigrations(filePath) → array of { old_id, action, ... } entries
 *
 * Reads a MIGRATIONS.md file and extracts migration entries from YAML
 * code blocks (```yaml ... ```). Each entry must have at least old_id
 * and action fields to be included.
 *
 * Returns empty array if file does not exist (MIGRATIONS.md is optional
 * per repo — only standards/ has one today, but other repos MAY have one).
 *
 * Limitation: multiline values (| and >) are skipped for simplicity —
 * current migrations don't use them. If a future migration needs
 * multiline, extend this parser or use js-yaml.
 */
function parseMigrations(filePath) {
  if (!fs.existsSync(filePath)) return [];
  const content = fs.readFileSync(filePath, "utf8");
  const migrations = [];
  // Find YAML blocks inside triple-backtick yaml fences
  const blocks = content.match(/```yaml\n([\s\S]*?)```/g) || [];
  for (const block of blocks) {
    const yaml = block.replace(/^```yaml\n/, "").replace(/\n```$/, "");
    const entry = {};
    for (const line of yaml.split("\n")) {
      const m = line.match(/^(\w+):\s*(.*)$/);
      if (m) {
        let val = m[2].trim();
        if (val === "|" || val === ">") {
          // Multiline value — skip for simplicity
          continue;
        }
        entry[m[1]] = val;
      }
    }
    if (entry.old_id && entry.action) {
      migrations.push(entry);
    }
  }
  return migrations;
}

module.exports = {
  extractDeclaration,
  parseMigrations,
  ID_TOKEN_RE,
};
