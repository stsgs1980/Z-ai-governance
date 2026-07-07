#!/usr/bin/env python3
"""Reconcile ARCH-002 §1 declared prerequisites vs Related: in each standard's header.

Two views to compare:
  view-A: ARCH-002 §1 install order table — what ARCH-002 *says* must be
          read before each standard.
  view-B: each standard's own `Related:` field — what the standard
          *itself* declares as dependencies.

If view-A and view-B agree, the system is internally consistent.
If they disagree, the reading order is ambiguous — reader doesn't know
which to trust.

Output: table of (standard, declared_prereqs_in_ARCH-002, Related_in_header, diff)
"""
import re
from pathlib import Path

STANDARDS_DIR = Path("/home/z/my-project/Z-ai-platform/standards/standards")

# View A: ARCH-002 §1 install order — manually transcribed from the
# table we read earlier. Each entry: (position, ID, declared prereqs)
ARCH002_PREREQS = {
    "STD-META-001":   [],                                            # 1, foundation
    "STD-ARCH-001":   ["STD-META-001"],                              # 2
    "STD-ARCH-002":   ["STD-META-001", "STD-ARCH-001"],              # 3 (self)
    "STD-DOC-002":    ["STD-META-001", "STD-ARCH-002"],              # 4
    "STD-DOC-003":    ["STD-DOC-002"],                               # 5
    "STD-SKILL-001":  ["STD-META-001", "STD-DOC-002"],               # 6
    "STD-ENV-001":    ["STD-ARCH-001", "STD-DOC-002"],               # 7
    "STD-ENV-002":    ["STD-ENV-001", "STD-ARCH-002"],               # 8 (v2.6: added ARCH-002)
    "STD-GIT-001":    ["STD-ENV-001", "STD-DOC-002"],                # 9
    "STD-GIT-002":    ["STD-GIT-001", "STD-ENV-002"],                # 10
    "STD-DESIGN-001": ["STD-DOC-002", "STD-DOC-003"],                # 11
    "STD-FE-001":     ["STD-ENV-001", "STD-DOC-002", "STD-DESIGN-001"],  # 12
    "STD-A11Y-001":   ["STD-FE-001", "STD-DESIGN-001"],              # 13
    "STD-ERR-001":    ["STD-FE-001", "STD-DOC-002"],                 # 14
    "STD-ERR-002":    ["STD-ERR-001"],                               # 15
    "STD-SEC-001":    ["STD-ENV-001", "STD-GIT-001", "STD-DOC-002"], # 16
    "STD-SEC-002":    ["STD-SEC-001"],                               # 17
    "STD-TEST-001":   ["STD-FE-001", "STD-ERR-001", "STD-DOC-002"],  # 18
    "STD-AGENT-001":  ["STD-ENV-001", "STD-GIT-001", "STD-DOC-002"], # 19
    "STD-AGENT-002":  ["STD-AGENT-001", "STD-ERR-001"],              # 20
}

# View B: parse Related: field from each standard's header
STD_ID_RE = re.compile(r"\bSTD-[A-Z]+-\d{3}\b")

def parse_related(content: str) -> tuple:
    """Return (id, related_set, aligned_with_set)."""
    # ID
    m = re.search(r"^>\s*ID:\s*(\S+)", content, re.MULTILINE)
    sid = m.group(1) if m else "?"
    # Related
    rel_m = re.search(r"^>\s*Related:\s*(.+)$", content, re.MULTILINE)
    related = set()
    if rel_m:
        related = set(STD_ID_RE.findall(rel_m.group(1)))
    # Aligned_with
    aw_m = re.search(r"^>\s*Aligned_with:\s*(.+)$", content, re.MULTILINE)
    aligned = set()
    if aw_m:
        aligned = set(STD_ID_RE.findall(aw_m.group(1)))
    return sid, related, aligned

def main():
    view_b = {}
    for f in sorted(STANDARDS_DIR.glob("*.md")):
        content = f.read_text(encoding="utf-8")
        sid, related, aligned = parse_related(content)
        if sid == "?":
            continue
        view_b[sid] = {"related": related, "aligned": aligned, "file": f.name}

    # Compare
    print("# Reconciliation: ARCH-002 §1 vs Related: in each standard\n")
    print(f"Standards in ARCH-002 §1: {len(ARCH002_PREREQS)}")
    print(f"Standards with parsed headers: {len(view_b)}")
    missing_in_b = set(ARCH002_PREREQS) - set(view_b)
    missing_in_a = set(view_b) - set(ARCH002_PREREQS)
    if missing_in_b:
        print(f"  In ARCH-002 but no header parsed: {missing_in_b}")
    if missing_in_a:
        print(f"  Header parsed but not in ARCH-002: {missing_in_a}")
    print()

    # Per-standard diff
    # Per ARCH-002 §1 implicit-META convention (v2.6, 2026-06-19):
    #   STD-META-001 is an implicit prereq for every standard. It is
    #   listed in each standard's Related: header for graph completeness
    #   but is NOT repeated in ARCH-002 §1 Prerequisites column unless
    #   META is the *primary* conceptual dep (ARCH-001/002, DOC-002,
    #   SKILL-001). Therefore META-001 in a header is NOT an undeclared
    #   dep unless the standard is one of those four.
    IMPLICIT_META_EXEMPT = {"STD-ARCH-001", "STD-ARCH-002", "STD-DOC-002", "STD-SKILL-001"}

    # Per ARCH-002 §1 A11Y-001 row note (v2.6):
    #   A11Y-001 → STD-TEST-001 is a forward reference (A11Y at #13,
    #   TEST at #18). Header Related: marks it with "forward reference"
    #   text. Such refs are not undeclared deps; they are explicitly
    #   documented as non-prereq cross-links.
    FORWARD_REFS = {("STD-A11Y-001", "STD-TEST-001")}

    print("## Per-standard diff\n")
    print("| # | ID | ARCH-002 prereqs | Header Related: | Undeclared in ARCH-002 | Missing from header |")
    print("|---|---|---|---|---|---|")
    rows = []
    for i, (sid, arch_prereqs) in enumerate(ARCH002_PREREQS.items(), 1):
        header_related = view_b.get(sid, {}).get("related", set())
        # Things in header but not declared as prereq in ARCH-002
        undeclared = header_related - set(arch_prereqs) - {sid}
        # Apply implicit-META convention: META-001 in header is OK
        # unless the standard is in the exempt list (where META IS
        # expected as explicit prereq).
        if sid not in IMPLICIT_META_EXEMPT:
            undeclared = undeclared - {"STD-META-001"}
        # Apply forward-ref convention: A11Y → TEST is documented.
        undeclared = undeclared - {tgt for (src, tgt) in FORWARD_REFS if src == sid}
        # Things declared in ARCH-002 but missing from header
        missing = set(arch_prereqs) - header_related - {sid}
        rows.append((i, sid, arch_prereqs, sorted(header_related),
                     sorted(undeclared), sorted(missing)))
        arch_str = ", ".join(arch_prereqs) if arch_prereqs else "—"
        head_str = ", ".join(sorted(header_related)) if header_related else "—"
        und_str = ", ".join(sorted(undeclared)) if undeclared else "—"
        miss_str = ", ".join(sorted(missing)) if missing else "—"
        print(f"| {i} | {sid} | {arch_str} | {head_str} | {und_str} | {miss_str} |")

    # Summary stats
    print("\n## Summary\n")
    n_perfect = sum(1 for r in rows if not r[4] and not r[5])
    n_undeclared = sum(1 for r in rows if r[4])
    n_missing = sum(1 for r in rows if r[5])
    print(f"- Perfect match (ARCH-002 == header): {n_perfect}/20")
    print(f"- Header has deps not declared in ARCH-002: {n_undeclared}/20")
    print(f"- ARCH-002 declares deps not in header: {n_missing}/20")
    print()

    # Detailed diffs
    if n_undeclared:
        print("## Undeclared deps (header says X, ARCH-002 §1 doesn't)\n")
        for i, sid, arch, head, und, miss in rows:
            if und:
                print(f"- **{sid}**: header Related: includes {und}, but ARCH-002 §1 declares prereqs as {arch or '(none)'}")
        print()
    if n_missing:
        print("## Missing-from-header deps (ARCH-002 says X, header doesn't)\n")
        for i, sid, arch, head, und, miss in rows:
            if miss:
                print(f"- **{sid}**: ARCH-002 §1 declares prereqs {miss}, but header Related: is {head or '(none)'}")
        print()

    # META-001 is special: it's foundational and explicitly has no Related.
    # Check it's not flagged.
    print("## Notes\n")
    print("- STD-META-001 declares `Related: (none — META is foundational)` — by design, no prereqs.")
    print("- STD-ARCH-002 has itself as a prereq (self-reference for the 'this file' row) — filtered out.")
    print()

if __name__ == "__main__":
    main()
