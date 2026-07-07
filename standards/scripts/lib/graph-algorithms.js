/**
 * ============================================================================
 * lib/graph-algorithms.js — pure graph algorithms for verify-id-graph.js
 * ============================================================================
 *
 * Extracted from verify-id-graph.js v1.1.4 as part of O-018 modularization.
 * Pure functions: (nodes, edges) in → SCCs out. No fs, no side effects.
 *
 * Consumers:
 *   - verify-id-graph.js phase6_detectCycles() (primary)
 *   - future test harness for cycle detection edge cases
 *
 * Source of truth for: tarjanSCC.
 *
 * Reference: Tarjan, R. (1972). "Depth-first search and linear graph
 * algorithms". SIAM Journal on Computing. 1 (2): 146–160.
 * Complexity: O(V + E) time, O(V) space.
 *
 * ============================================================================
 */

'use strict';

/**
 * Tarjan's Strongly Connected Components algorithm.
 *
 * @param {string[]} nodes - array of node IDs
 * @param {Array<{source: string, target: string}>} edges - directed edges
 * @returns {string[][]} array of SCCs (each SCC is an array of node IDs).
 *   SCCs with more than one node indicate cycles. Single-node SCCs with
 *   no self-loop are not cycles.
 *
 * Implementation notes:
 *   - Uses recursion (JS stack). For graphs > ~10k nodes, consider
 *     iterative variant (current Z-ai graph has <100 nodes, recursion
 *     is fine).
 *   - Nodes not in `nodes` array are ignored if they appear as edge
 *     targets — caller should ensure nodes[] is complete.
 */
function tarjanSCC(nodes, edges) {
  // Build adjacency list
  const adj = new Map();
  for (const n of nodes) adj.set(n, []);
  for (const e of edges) {
    if (adj.has(e.source)) {
      adj.get(e.source).push(e.target);
    }
  }

  let index = 0;
  const stack = [];
  const indices = new Map();
  const lowlinks = new Map();
  const onStack = new Map();
  const sccs = [];

  function strongconnect(v) {
    indices.set(v, index);
    lowlinks.set(v, index);
    index++;
    stack.push(v);
    onStack.set(v, true);

    for (const w of adj.get(v) || []) {
      if (!indices.has(w)) {
        strongconnect(w);
        lowlinks.set(v, Math.min(lowlinks.get(v), lowlinks.get(w)));
      } else if (onStack.get(w)) {
        lowlinks.set(v, Math.min(lowlinks.get(v), indices.get(w)));
      }
    }

    if (lowlinks.get(v) === indices.get(v)) {
      const scc = [];
      let w;
      do {
        w = stack.pop();
        onStack.set(w, false);
        scc.push(w);
      } while (w !== v);
      sccs.push(scc);
    }
  }

  for (const v of nodes) {
    if (!indices.has(v)) {
      strongconnect(v);
    }
  }

  return sccs;
}

module.exports = {
  tarjanSCC,
};
