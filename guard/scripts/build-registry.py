#!/usr/bin/env python3
"""build-registry.py — auto-generate guard/registry.json from authoritative sources.

Sources:
  - guard/rules/INDEX.md        (17 RULE-* entries)
  - standards/standards/META-001-id-registry.md  §4.14 (PROC-*) + §4.15 (TOOL-*)

Output:  guard/registry.json

Schema (one object per ID):
  {
    "id":       "RULE-ANSWER-001",
    "title":    "Answer before act (no unsolicited action)",
    "version":  "1.0",
    "level":    "critical",           // RULE only
    "status":   "ACTIVE",
    "file":     "guard/rules/RULE-ANSWER-001.md",   // relative to platform root
    "source":   "AHG RULE-001",       // provenance
    "implements": null,               // PROC/TOOL only: which RULE it enforces
    "calls":     [],                  // PROC/TOOL only: TOOL IDs it invokes
    "owning_standard": "STD-META-001 v2.0.4"
  }

Top-level shape:
  {
    "generated_at": "2026-06-22T...",
    "platform_version": "v2.6.0",
    "standards_sha":  "a259a6b...",
    "guard_sha":      "2e2579d...",
    "counts": { "RULE": 17, "PROC": 4, "TOOL": 6, "total": 27 },
    "ids": [ ... ]
  }
"""

import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

PLATFORM = Path("/home/z/my-project/Z-ai-governance")
RULES_INDEX = PLATFORM / "guard/rules/INDEX.md"
ID_REGISTRY = PLATFORM / "standards/standards/META-001-id-registry.md"
OUTPUT = PLATFORM / "guard/registry.json"

LEVEL_MAP = {"[C]": "critical", "[W]": "warning", "[I]": "info"}


def git_sha(rel_path: str) -> str:
    """Get short SHA of a submodule/file. Returns 'unknown' on failure."""
    try:
        result = subprocess.run(
            ["git", "-C", str(PLATFORM / rel_path), "rev-parse", "--short", "HEAD"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        return result.stdout.strip() if result.returncode == 0 else "unknown"
    except Exception:
        return "unknown"


def platform_tag() -> str:
    try:
        result = subprocess.run(
            ["git", "-C", str(PLATFORM), "describe", "--tags", "--abbrev=0"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        return result.stdout.strip() if result.returncode == 0 else "unknown"
    except Exception:
        return "unknown"


def parse_rules_index() -> list:
    """Parse guard/rules/INDEX.md table for 17 RULE-* entries.

    Table row format:
      | RULE-ANSWER-001 | Title here | v1.0 | critical | AHG RULE-001 |
    """
    text = RULES_INDEX.read_text()
    entries = []
    # Match table rows: | RULE-NAME-NNN | title | vN.N | level | source |
    pattern = re.compile(
        r"^\|\s*(RULE-[A-Z]+-\d+)\s*\|\s*([^|]+?)\s*\|\s*v([\d.]+)\s*\|\s*(critical|warning|info)\s*\|\s*([^|]+?)\s*\|",
        re.MULTILINE,
    )
    for m in pattern.finditer(text):
        rid, title, ver, level, source = m.groups()
        entries.append(
            {
                "id": rid,
                "title": title.strip(),
                "version": ver.strip(),
                "level": level.strip(),
                "status": "ACTIVE",
                "file": f"guard/rules/{rid}.md",
                "source": source.strip(),
                "implements": None,
                "calls": [],
                "owning_standard": "STD-META-001 v2.0.4",
            }
        )
    return entries


def parse_id_registry() -> tuple:
    """Parse standards/standards/META-001-id-registry.md §4.14 (PROC) + §4.15 (TOOL).

    Table row format:
      | PROC-SETUP-001 | Z-ai-guard/setup.sh | 2.0 | [C] | ACTIVE (planned) — file not yet created |
    """
    text = ID_REGISTRY.read_text()
    procs, tools = [], []

    # PROC table — section §4.14
    proc_pattern = re.compile(
        r"^\|\s*(PROC-[A-Z]+-\d+)\s*\|\s*([^|]+?)\s*\|\s*v?([\d.]+)\s*\|\s*\[([CWI])\]\s*\|\s*([^|]+?)\s*\|",
        re.MULTILINE,
    )
    tool_pattern = re.compile(
        r"^\|\s*(TOOL-[A-Z]+-\d+)\s*\|\s*([^|]+?)\s*\|\s*v?([\d.]+)\s*\|\s*\[([CWI])\]\s*\|\s*([^|]+?)\s*\|",
        re.MULTILINE,
    )

    # Split text at section headers to know which table we're in
    proc_section = (
        text.split("### 4.14. Procedures")[1].split("### 4.15.")[0]
        if "### 4.14. Procedures" in text
        else ""
    )
    tool_section = (
        text.split("### 4.15. Tools")[1].split("### 4.16.")[0]
        if "### 4.15. Tools" in text
        else ""
    )

    def _parse_status(raw: str) -> str:
        raw = raw.strip()
        if raw.startswith("ACTIVE"):
            return "ACTIVE"
        if raw.startswith("RETIRED"):
            return "RETIRED"
        if raw.startswith("DEPRECATED"):
            return "DEPRECATED"
        return raw.upper()

    for m in proc_pattern.finditer(proc_section):
        pid, path, ver, lvl, status_raw = m.groups()
        # Translate Z-ai-guard/path → guard/path (relative to platform root)
        rel_path = (
            path.strip().replace("Z-ai-guard/", "guard/").replace("Z-ai-governance/", "")
        )
        procs.append(
            {
                "id": pid,
                "title": _proc_title(pid),
                "version": ver.strip(),
                "level": LEVEL_MAP.get(f"[{lvl}]", "info"),
                "status": _parse_status(status_raw),
                "file": rel_path,
                "source": "STD-META-001 §4.14",
                "implements": _proc_implements(pid),
                "calls": _proc_calls(pid),
                "owning_standard": "STD-META-001 v2.0.4",
            }
        )

    for m in tool_pattern.finditer(tool_section):
        tid, path, ver, lvl, status_raw = m.groups()
        rel_path = (
            path.strip()
            .replace("Z-ai-standards/", "standards/")
            .replace("Z-ai-guard/", "guard/")
        )
        tools.append(
            {
                "id": tid,
                "title": _tool_title(tid),
                "version": ver.strip(),
                "level": LEVEL_MAP.get(f"[{lvl}]", "info"),
                "status": _parse_status(status_raw),
                "file": rel_path,
                "source": "STD-META-001 §4.15",
                "implements": None,
                "calls": [],
                "owning_standard": "STD-META-001 v2.0.4",
            }
        )

    return procs, tools


def _proc_title(pid: str) -> str:
    titles = {
        "PROC-SETUP-001": "Project installer procedure",
        "PROC-UPDATE-002": "Project update procedure",
        "PROC-COCHANGE-003": "Co-change check (code + docs sync)",
        "PROC-LINECOUNT-004": "Line count check (anti-monolith enforcement)",
        "PROC-PLATFORM-INSTALL-005": "[RETIRED] Platform install",
        "PROC-PLATFORM-UPDATE-006": "[RETIRED] Platform update",
        "PROC-PLATFORM-DOCTOR-007": "[RETIRED] Platform doctor",
    }
    return titles.get(pid, pid)


def _proc_implements(pid: str) -> str | None:
    """Which RULE this PROC enforces."""
    mapping = {
        "PROC-SETUP-001": None,  # not rule-enforcing, runs at install time
        "PROC-UPDATE-002": None,
        "PROC-COCHANGE-003": "RULE-DOC-010",  # docs sync
        "PROC-LINECOUNT-004": "RULE-MONOLITH-012",  # anti-monolith
    }
    return mapping.get(pid)


def _proc_calls(pid: str) -> list:
    """Which TOOLs this PROC invokes."""
    mapping = {
        "PROC-SETUP-001": [],
        "PROC-UPDATE-002": [],
        "PROC-COCHANGE-003": [],
        "PROC-LINECOUNT-004": ["TOOL-VERIFY-002", "TOOL-VERIFY-004"],
    }
    return mapping.get(pid, [])


def _tool_title(tid: str) -> str:
    titles = {
        "TOOL-VERIFY-001": "verify-docs.sh (guard-side docs invariants)",
        "TOOL-VERIFY-002": "verify-standards.js",
        "TOOL-VERIFY-003": "[RETIRED] verify-cascade.js",
        "TOOL-VERIFY-004": "verify-id-graph.js",
        "TOOL-BUMP-005": "bump.sh (version bumper, semver-aware)",
        "TOOL-CHECKUPDATES-006": "check-updates.sh",
    }
    return titles.get(tid, tid)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Auto-generate guard/registry.json")
    parser.add_argument(
        "--output", "-o", default=str(OUTPUT), help=f"Output path (default: {OUTPUT})"
    )
    args = parser.parse_args()
    output_path = Path(args.output)

    if not RULES_INDEX.exists():
        sys.exit(f"ERROR: {RULES_INDEX} not found")
    if not ID_REGISTRY.exists():
        sys.exit(f"ERROR: {ID_REGISTRY} not found")

    rules = parse_rules_index()
    procs, tools = parse_id_registry()

    all_ids = rules + procs + tools
    registry = {
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "platform_version": platform_tag(),
        "standards_sha": git_sha("standards"),
        "guard_sha": git_sha("guard"),
        "counts": {
            "RULE": len(rules),
            "PROC": len(procs),
            "TOOL": len(tools),
            "total": len(all_ids),
        },
        "ids": all_ids,
    }

    output_path.write_text(json.dumps(registry, indent=2, ensure_ascii=False) + "\n")
    print(f"OK: wrote {output_path}")
    print(
        f"   {registry['counts']['RULE']} RULE + {registry['counts']['PROC']} PROC + {registry['counts']['TOOL']} TOOL = {registry['counts']['total']} IDs"
    )
    print(
        f"   platform={registry['platform_version']}  standards@{registry['standards_sha']}  guard@{registry['guard_sha']}"
    )


if __name__ == "__main__":
    main()
