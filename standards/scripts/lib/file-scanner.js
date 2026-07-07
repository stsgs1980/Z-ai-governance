/**
 * ============================================================================
 * lib/file-scanner.js — glob-based file scanner for verify-id-graph.js
 * ============================================================================
 *
 * Extracted from verify-id-graph.js v1.1.5 as part of O-018 modularization
 * (continuation). Contains listFiles(), globFiles(), matchesPattern() —
 * the file-walking + glob-matching logic used to enumerate .md files
 * across the 4 Z-ai repositories.
 *
 * DEPENDENCIES
 *   - fs (for readdirSync, existsSync)
 *   - path (for join, relative)
 *
 * DESIGN
 *   Simple glob implementation: supports `**` (any number of dirs) and
 *   `*` (any chars except `/`). No external dependencies (fast-glob,
 *   globby) — by design, for zero-dep verifier scripts.
 *
 *   Skip-dirs list (node_modules, .git, _research, upload, tool-results,
 *   download) is hardcoded — these are common sandbox/IDE artifacts that
 *   should never be scanned for standards/skills definitions.
 *
 *   Safety limit: depth > 15 aborts the walk (prevents infinite loops on
 *   symlink cycles).
 *
 * ============================================================================
 */

'use strict';

const fs = require('fs');
const path = require('path');

// Dirs that should never be walked — sandbox/IDE/build artifacts.
const SKIP_DIRS = new Set([
  'node_modules', '.git', '_research', 'upload',
  'tool-results', 'download',
]);

// Submodule directories that should be skipped when scanning from the
// platform root (they are scanned separately as their own repos).
// Only used when rootDir == platformRoot to prevent duplicate IDs.
const SUBMODULE_DIRS = new Set([
  'standards', 'guard', 'skills',
]);

/**
 * listFiles(rootDir, patterns, extraSkipDirs) → string[]
 *
 * Walks rootDir, returns deduped list of file paths matching any of the
 * glob patterns. Patterns are evaluated independently; results are merged
 * and deduped via Set.
 *
 * extraSkipDirs: optional Set of directory names to skip in addition to
 * SKIP_DIRS. Used to exclude submodule dirs when scanning from platform root.
 */
function listFiles(rootDir, patterns, extraSkipDirs) {
  const files = [];
  for (const pattern of patterns) {
    files.push(...globFiles(rootDir, pattern, extraSkipDirs));
  }
  return [...new Set(files)];  // dedup
}

/**
 * globFiles(rootDir, pattern, extraSkipDirs) → string[]
 *
 * Walks rootDir, returns list of file paths whose path (relative to
 * rootDir) matches the glob pattern.
 *
 * Special case: if pattern has no `/` (e.g. `STANDARDS.md` or `*.md`),
 * also checks for a direct file at rootDir/pattern (for `STANDARDS.md`),
 * and walks the tree for `*.md` patterns.
 */
function globFiles(rootDir, pattern, extraSkipDirs) {
  const results = [];
  const skipSet = extraSkipDirs
    ? new Set([...SKIP_DIRS, ...extraSkipDirs])
    : SKIP_DIRS;

  function walk(dir, depth = 0) {
    if (depth > 15) return;  // safety limit
    let entries;
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch (e) {
      return;
    }

    for (const entry of entries) {
      if (skipSet.has(entry.name)) continue;

      const full = path.join(dir, entry.name);

      if (entry.isDirectory()) {
        walk(full, depth + 1);
      } else if (entry.isFile()) {
        const rel = path.relative(rootDir, full).split(path.sep).join('/');
        if (matchesPattern(rel, pattern)) {
          results.push(full);
        }
      }
    }
  }

  // Special case: pattern starts at root like 'STANDARDS.md' or '*.md'
  if (!pattern.includes('/')) {
    const direct = path.join(rootDir, pattern);
    if (fs.existsSync(direct)) {
      results.push(direct);
    }
    // Also walk for *.md patterns
    if (pattern === '*.md') {
      walk(rootDir);
    }
  } else {
    walk(rootDir);
  }

  return results;
}

/**
 * matchesPattern(relPath, pattern) → boolean
 *
 * Converts glob pattern to regex and tests relPath. Glob conversions:
 *   double-star         matches any chars including slash
 *   double-star slash   matches zero or more dirs
 *   star                matches any chars except slash
 *   dot                 matches literal dot
 */
function matchesPattern(relPath, pattern) {
  let regex = pattern
    .replace(/\./g, '\\.')
    .replace(/\\\*\*\\\//g, '{{DOUBLESTAR_SLASH}}')  // **/  (after . escaping, * is still *)
    .replace(/\*\*\//g, '{{DOUBLESTAR_SLASH}}')        // **/  (raw, just in case)
    .replace(/\*\*/g, '{{DOUBLESTAR}}')
    .replace(/\*/g, '[^/]*')
    .replace(/{{DOUBLESTAR_SLASH}}/g, '(?:.*/)?')      // **/  →  zero or more dirs
    .replace(/{{DOUBLESTAR}}/g, '.*');
  regex = '^' + regex + '$';
  return new RegExp(regex).test(relPath);
}

module.exports = {
  listFiles,
  globFiles,
  matchesPattern,
  SKIP_DIRS,
  SUBMODULE_DIRS,
};
