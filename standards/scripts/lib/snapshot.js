/**
 * ============================================================================
 * lib/snapshot.js — graph snapshot compare for verify-id-graph.js
 * ============================================================================
 *
 * Extracted from verify-id-graph.js v1.1.4 as part of O-018 modularization.
 * Has ONE fs call (read baseline file) but is otherwise pure — accepts
 * a currentJSON object, returns { ok, diff }.
 *
 * Consumers:
 *   - verify-id-graph.js main() (primary)
 *   - future test harness for snapshot compare edge cases
 *
 * Source of truth for: compareSnapshot.
 *
 * Snapshot file format (JSON):
 *   {
 *     "snapshot_meta": { "script_version": "1.1.4", "generated": "..." },
 *     "summary": { "ids_extracted": N, "related_edges": N, ... },
 *     "checks": [ { "id": "G01", "status": "PASS", "description": "...", "details": [] } ],
 *     "warnings": [ { "code": "W13", "message": "..." } ]
 *   }
 *
 * Comparison is structural (order-independent for checks + warnings):
 *   - summary block: exact match required (counts must be identical)
 *   - checks block: every check id+status+description must match; details
 *     arrays are compared as sorted sets
 *   - warnings block: compared as sorted arrays of {code, message} pairs
 *
 * script_version mismatch is a WARNING printed to stderr, not a
 * comparison failure — the structure may still match.
 *
 * ============================================================================
 */

"use strict";

const fs = require("fs");

/**
 * Compare the current graph (as emitted by emitJSON) to a baseline file.
 *
 * @param {object} currentJSON - the current graph output, as emitted by
 *   emitJSON() in verify-id-graph.js
 * @param {string} baselinePath - path to the baseline .json file
 * @param {string} currentVersion - the current script VERSION (for
 *   version-mismatch warning); pass verify-id-graph.js VERSION constant
 * @returns {{ ok: boolean, diff: string[] }}
 *   - ok=true: current matches baseline
 *   - ok=false: current differs; diff[] lists every difference found
 */
function compareSnapshot(currentJSON, baselinePath, currentVersion) {
  const diffs = [];
  let baseline;
  try {
    baseline = JSON.parse(fs.readFileSync(baselinePath, "utf8"));
  } catch (e) {
    return {
      ok: false,
      diff: [`[snapshot] Could not read baseline file ${baselinePath}: ${e.message}`],
    };
  }

  // Version mismatch warning (non-fatal)
  if (
    baseline.snapshot_meta &&
    baseline.snapshot_meta.script_version &&
    baseline.snapshot_meta.script_version !== currentVersion
  ) {
    console.error(
      `[snapshot] WARNING: baseline was created with version ${baseline.snapshot_meta.script_version}, current is ${currentVersion}. Structure may still match.`,
    );
  }

  // Compare summary
  const curSum = currentJSON.summary;
  const baseSum = baseline.summary || {};
  for (const key of [
    "ids_extracted",
    "related_edges",
    "aligned_with_edges",
    "hard_pass",
    "hard_fail",
    "warnings",
  ]) {
    if (curSum[key] !== baseSum[key]) {
      diffs.push(`[snapshot] summary.${key}: baseline=${baseSum[key]}, current=${curSum[key]}`);
    }
  }

  // Compare checks (by id)
  const curChecks = new Map((currentJSON.checks || []).map((c) => [c.id, c]));
  const baseChecks = new Map((baseline.checks || []).map((c) => [c.id, c]));
  const allCheckIds = new Set([...curChecks.keys(), ...baseChecks.keys()]);
  for (const id of [...allCheckIds].sort()) {
    const cur = curChecks.get(id);
    const base = baseChecks.get(id);
    if (!base) {
      diffs.push(`[snapshot] check ${id}: present in current, MISSING in baseline`);
      continue;
    }
    if (!cur) {
      diffs.push(`[snapshot] check ${id}: MISSING in current, present in baseline`);
      continue;
    }
    if (cur.status !== base.status) {
      diffs.push(`[snapshot] check ${id}.status: baseline=${base.status}, current=${cur.status}`);
    }
    if (cur.description !== base.description) {
      diffs.push(`[snapshot] check ${id}.description changed`);
    }
    // details: compare as sorted arrays
    const curDetails = (cur.details || []).slice().sort();
    const baseDetails = (base.details || []).slice().sort();
    if (JSON.stringify(curDetails) !== JSON.stringify(baseDetails)) {
      diffs.push(
        `[snapshot] check ${id}.details differ (baseline ${baseDetails.length} entries, current ${curDetails.length})`,
      );
    }
  }

  // Compare warnings (as sorted set of {code/id, message/detail})
  // Normalize file paths inside "(in ...)" to strip OS-specific absolute prefixes
  const normalizePaths = (str) =>
    str.replace(/\(in\s+([^)]+)\)/g, (match, filePath) => {
      const normalized = filePath
        .replace(/\\/g, "/") // Windows backslashes to forward slashes
        .replace(/.*(Z-ai-governance|Z-ai-standards|Z-ai-guard|Z-ai-skills)\//, "");
      return `(in ${normalized})`;
    });
  const normWarn = (w) => {
    const msg = w.message || w.detail || w.msg || JSON.stringify(w);
    return (w.code || w.id) + "::" + normalizePaths(msg);
  };
  const curWarn = (currentJSON.warnings || []).map(normWarn).sort();
  const baseWarn = (baseline.warnings || []).map(normWarn).sort();
  if (JSON.stringify(curWarn) !== JSON.stringify(baseWarn)) {
    const curSet = new Set(curWarn);
    const baseSet = new Set(baseWarn);
    const added = curWarn.filter((w) => !baseSet.has(w));
    const removed = baseWarn.filter((w) => !curSet.has(w));
    if (added.length)
      diffs.push(`[snapshot] warnings ADDED: ${added.length} (first: ${added[0].slice(0, 100)})`);
    if (removed.length)
      diffs.push(
        `[snapshot] warnings REMOVED: ${removed.length} (first: ${removed[0].slice(0, 100)})`,
      );
  }

  return { ok: diffs.length === 0, diff: diffs };
}

module.exports = {
  compareSnapshot,
};
