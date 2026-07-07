# FAQ — Companion to STD-META-001

> Companion to: STD-META-001 v2.0.5 (Standard ID System)
> Type: Reference appendix, NOT a separate standard
> Last Updated: 2026-06-21
> Status: ACTIVE (explanatory material)

This file is a **companion reference** to `META-001-standard-id-system.md`
(STD-META-001 v2.0.5). It contains the FAQ (§12 of the parent standard).

**This file is NOT a separate standard.** It does not have an `STD-` ID of
its own and does not participate in the ID graph.

## Why this file exists

In STD-META-001 v2.0.4, the FAQ (§12, 78 lines) lived inline in the main
standard file. Combined with the ID Registry (§4.13-§4.17) and §4.18
(File Size Limits), the file exceeded the 1000-line soft cap (W11 warning).
In v2.0.5, the FAQ and registry tables were moved to companion files.

## How cross-references resolve

External references to "STD-META-001 §12" or "STD-META-001 FAQ" resolve to
this companion file. The section number is preserved verbatim.

---

## 12. FAQ

### Q: Why `ZAI-` and not `SKILL-`?

A: `ZAI-` was chosen in toolkit v2.0.5 to distinguish user-toolkit skills
from Z.ai sandbox built-in skills (which have no prefix) and ZCode Desktop
built-ins (which have no prefix). Renaming to `SKILL-` would break 24
existing IDs and every reference to them in standards, rules, and consumer
projects. The semantic role of `ZAI-` is identical to what `SKILL-` would
be; only the literal prefix differs.

### Q: Do all skills need a `ZAI-` ID?

A: **No.** IDs are optional for skills. A skill needs an ID only when
referenced by ID from a standard, rule, procedure, tool, or another
skill's `Related:` field. Most personal skills do not need an ID.
The runtime sandbox matches skills by `name:` field in frontmatter, not
by ID. See STD-SKILL-001 §4.2 for the full criteria.

### Q: What about the 24 existing ZAI-* IDs from toolkit v2.0.5?

A: They are preserved unchanged. No migration, no rename. The registry
in §4.16 below is the reference. New skills may be added without IDs.

### Q: Why can't a standard reference a rule?

A: Standards describe what is true in a domain (e.g. "every commit message
has a type prefix"). Rules describe what agents must do about it (e.g.
"before pushing, run the commit-lint procedure"). If a standard could
reference a rule, the rule's lifecycle would constrain the standard's
lifecycle — but standards are meant to be slower-moving and more stable
than rules. The direction must be `RULE -> STD`, never the reverse.

### Q: But STD-FE-001 currently references ZAI-ARCH-002 in its prose. Is that wrong?

A: No — that reference is `Aligned_with:`, not `Related:`. STD-FE-001 and
ZAI-ARCH-002 are kept in sync (the standard declares thresholds; the skill
decomposes when thresholds are exceeded). The bidirectional `Aligned_with:`
edge allows this without violating the `Related:` DAG. v2.0 formalizes
this distinction; previously it was implicit and uncheckable.

### Q: Why can't a tool invoke a procedure?

A: Tools are leaf nodes — they do one thing and exit. Procedures are
orchestrators that may call multiple tools. Allowing `TOOL -> PROC` would
invert the dependency: a tool would need to know about higher-level
workflow, breaking composability.

### Q: Why can't a procedure invoke a skill?

A: Procedures run automatically (in hooks, CI). Skills are user-callable
capabilities that may require human input (parameter selection, approval).
A procedure invoking a skill would silently trigger user-facing behavior,
which is unsafe.

### Q: What if I need a rule that depends on a skill?

A: That's allowed (`RULE -> ZAI` is green in the matrix). The rule says
"when condition X holds, the agent should invoke ZAI-Y". The rule does
not invoke the skill mechanically — it instructs the agent to do so. The
mechanical invocation (if any) would be a PROC, but PROC -> ZAI is
forbidden, so any skill invocation is by agent decision, not by hook.

### Q: Can a standard reference another standard?

A: Yes — `STD -> STD` is allowed. All STD-* IDs share a single
registry.

### Q: What happens to ZAI-META-001 after v2.0?

A: Its content (the skill ID system specification) moves to STD-SKILL-001
in `standards/standards/`. The ZAI-META-001 file remains in `skills/skills/`
as a thin pointer (~20 lines) that says "Content moved to STD-SKILL-001;
this file exists only so existing trigger phrases (`skill id`, `create skill`)
continue to resolve during the migration window." After the migration window
closes, ZAI-META-001 is removed entirely.

---
