/**
 * ============================================================================
 * lib/parsers.js — pure parsers for verify-id-graph.js
 * ============================================================================
 *
 * Extracted from verify-id-graph.js v1.1.4 as part of O-018 modularization.
 * Pure functions: string in → object out. No fs calls, no side effects.
 *
 * extractDeclaration() and parseMigrations() are NOT here because they
 * take a filePath and call fs.readFileSync() — they remain in the main
 * verifier file (impure). The pure parsing primitives they depend on
 * are exported here.
 *
 * Consumers:
 *   - verify-id-graph.js (extractDeclaration calls these)
 *   - verify-skills.js (could use parseYAMLFrontmatter — TODO; currently
 *     has its own parseFrontmatter that handles folded scalars but
 *     duplicates the basic key:value logic)
 *   - future test harness for parser edge cases
 *
 * Source of truth for: parseYAMLFrontmatter, parseBlockquoteHeader,
 * parseHTMLComment, extractReferences.
 *
 * Note: these parsers are intentionally minimal — they handle the subset
 * of YAML / blockquote / HTML-comment syntax used in standards and skill
 * files. For full YAML, use js-yaml; for full HTML, use a real parser.
 * The minimal subset is by design (zero dependencies, fast load).
 *
 * ============================================================================
 */

'use strict';

// ID-shape regex used to extract ID tokens from prose
const ID_TOKEN_REGEX = /\b(STD|RULE|PROC|TOOL|ZAI)-[A-Z]+-\d{3}\b/g;

/**
 * Parse a YAML frontmatter block (--- ... ---) from the start of a
 * markdown file. Returns the parsed key→value object, or null if no
 * frontmatter block is found.
 *
 * Supports:
 *   - flat key: value
 *   - quoted strings ("..." or '...')
 *   - list values (key:\n  - item1\n  - item2)
 *   - empty values (key:) followed by list collection
 *
 * Does NOT support (intentionally):
 *   - nested objects (no indentation-based nesting)
 *   - folded scalars (description: > ...) — see verify-skills.js
 *     parseFrontmatter() for that subset if needed
 *   - anchors / aliases
 *   - multiline values via | or > (key: | is treated as empty)
 */
function parseYAMLFrontmatter(content) {
  // Match --- at start, then YAML block, then ---
  const m = content.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?/);
  if (!m) return null;
  const yaml = m[1];
  const result = {};
  const lines = yaml.split(/\r?\n/);
  let currentListKey = null;
  for (const line of lines) {
    // List item under a previous key (e.g., "  - VALUE")
    const listItem = line.match(/^\s+-\s+(.*)$/);
    if (listItem && currentListKey) {
      if (!Array.isArray(result[currentListKey])) {
        result[currentListKey] = [];
      }
      let v = listItem[1].trim();
      // Strip quotes
      if ((v.startsWith('"') && v.endsWith('"')) ||
          (v.startsWith("'") && v.endsWith("'"))) {
        v = v.slice(1, -1);
      }
      result[currentListKey].push(v);
      continue;
    }
    const kv = line.match(/^(\w+):\s*(.*)$/);
    if (kv) {
      let val = kv[2].trim();
      // Strip quotes
      if ((val.startsWith('"') && val.endsWith('"')) ||
          (val.startsWith("'") && val.endsWith("'"))) {
        val = val.slice(1, -1);
      }
      // Empty value means: either null or a list follows — start collecting list items
      if (val === '') {
        result[kv[1]] = [];
        currentListKey = kv[1];
      } else {
        result[kv[1]] = val;
        currentListKey = null;
      }
    } else if (!line.trim()) {
      // Blank line ends list collection
      currentListKey = null;
    }
  }
  // Convert empty arrays back to empty string for backward compat with `if (yaml.id)` checks
  // (id is always a scalar, so this only affects list keys)
  return result;
}

/**
 * Parse a blockquote header (lines starting with `>`) from the top of
 * a markdown file. Returns key→value object.
 *
 * Supports:
 *   - "> Key: value"
 *   - "> **Key:** value" (markdown bold)
 *   - Comma-separated list values (caller parses ID tokens)
 *
 * Looks at the first 80 lines max (blockquote headers are always near
 * the top, per STD-META-001 §3.1).
 */
function parseBlockquoteHeader(content) {
  const lines = content.split('\n').map(l => l.replace(/\r$/, ''));
  const header = {};
  let inBlockquote = false;
  for (let i = 0; i < Math.min(lines.length, 80); i++) {
    const line = lines[i];
    const m = line.match(/^>\s*\*?\*?([A-Za-z_][\w_]*)\*?\*?:\s*(.*)$/);
    if (m) {
      inBlockquote = true;
      let val = m[2].trim();
      const key = m[1];
      // Strip leading ** and trailing **
      val = val.replace(/^\*\*/, '').replace(/\*\*$/, '').trim();
      header[key] = val;
    } else if (inBlockquote && line.startsWith('>')) {
      // continuation line in blockquote, skip
    } else if (inBlockquote && !line.startsWith('>')) {
      // End of blockquote — allow re-entry if more > lines appear
    }
  }
  return header;
}

/**
 * Parse an HTML comment that declares a rule ID and metadata.
 * Format: <!-- ID: RULE-ENV-008 | ver:1.0 | Level: C | Related: STD-ENV-001,STD-ENV-002 | Aligned_with: -->
 *
 * Returns { id, version, level, related[], aligned_with[] } or null.
 */
function parseHTMLComment(content) {
  const m = content.match(/<!--\s*ID:\s*([A-Z]+-[A-Z]+-\d{3})\s*\|([\s\S]*?)-->/);
  if (!m) return null;
  const id = m[1];
  const rest = m[2];
  const fields = { id };
  for (const part of rest.split('|')) {
    const kv = part.match(/^\s*(\w+):\s*(.*?)\s*$/);
    if (kv) {
      const key = kv[1].toLowerCase();
      const val = kv[2];
      if (key === 'ver') fields.version = val;
      else if (key === 'level') fields.level = val.replace(/^\[?\*?\*?\[?/, '').replace(/[\]\*]?$/, '').trim();
      else if (key === 'related') fields.related = val ? val.split(',').map(s => s.trim()).filter(Boolean) : [];
      else if (key === 'aligned_with') fields.aligned_with = val ? val.split(',').map(s => s.trim()).filter(Boolean) : [];
    }
  }
  return fields;
}

/**
 * Extract all ID-shaped tokens (STD/RULE/PROC/TOOL/ZAI-XXX-NNN) from
 * arbitrary content. Returns a deduplicated array.
 *
 * Used by Phase 4 to validate that every ID mentioned in prose
 * resolves to a declared ID.
 */
function extractReferences(content) {
  const refs = new Set();
  let m;
  while ((m = ID_TOKEN_REGEX.exec(content)) !== null) {
    refs.add(m[0]);
  }
  return [...refs];
}

module.exports = {
  parseYAMLFrontmatter,
  parseBlockquoteHeader,
  parseHTMLComment,
  extractReferences,
  ID_TOKEN_REGEX,
};
