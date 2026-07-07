#!/usr/bin/env python3
"""Generate a trigger eval set for a skill.

Reads a skill's SKILL.md and produces a starter eval set plus a prompt
that the user can send to opencode to generate 20 realistic trigger queries.

Usage:
    python generate_trigger_evals.py <path/to/skill> [--output eval_set.json]
"""

import argparse
import json
import sys
from pathlib import Path

# Allow importing from skill-lab root when run directly
sys.path.insert(0, str(Path(__file__).parent.parent))

from scripts.utils import parse_skill_md


def build_generation_prompt(skill_name: str, description: str, body: str) -> str:
    """Build a prompt for opencode to generate trigger eval queries."""
    return f"""You are generating a trigger evaluation set for an opencode skill.

Skill name: {skill_name}
Skill description: {description}

Skill content summary:
{body[:2000]}

Generate 20 eval queries — a mix of should-trigger (8-10) and should-not-trigger (8-10).

Requirements:
- Queries must be realistic — concrete, specific, with file paths, context, casual speech, typos, abbreviations.
- Focus on edge cases, not clear-cut matches.
- Negative cases should be near-misses (share keywords but need something different), not obviously irrelevant.
- Good examples: "ok so my boss just sent me this xlsx file (its in my downloads, called something like 'Q4 sales final FINAL v2.xlsx')..."
- Bad examples: "Format this data", "Extract text from PDF"

Output ONLY a JSON array in this exact format:
[
  {{"query": "...", "should_trigger": true}},
  {{"query": "...", "should_trigger": false}}
]
"""


def generate_starter_set(skill_name: str, description: str) -> list[dict]:
    """Generate a minimal starter eval set based on skill metadata.

    The user should replace these with realistic queries.
    """
    return [
        # Should trigger (placeholders)
        {
            "query": f"[TODO: realistic query that should trigger {skill_name}]",
            "should_trigger": True,
        },
        {
            "query": "[TODO: casual/abbreviated query with file paths that should trigger]",
            "should_trigger": True,
        },
        {
            "query": "[TODO: edge case query where user needs this skill but doesn't name it explicitly]",
            "should_trigger": True,
        },
        {
            "query": "[TODO: query with typos or informal language that should still trigger]",
            "should_trigger": True,
        },
        {
            "query": "[TODO: uncommon use case that should trigger]",
            "should_trigger": True,
        },
        # Should not trigger (placeholders)
        {
            "query": "[TODO: near-miss query — shares keywords but needs different tool]",
            "should_trigger": False,
        },
        {
            "query": "[TODO: adjacent domain query that should NOT trigger]",
            "should_trigger": False,
        },
        {
            "query": "[TODO: ambiguous phrasing where naive keyword match would trigger but shouldn't]",
            "should_trigger": False,
        },
        {
            "query": "[TODO: query touching skill's domain but in wrong context]",
            "should_trigger": False,
        },
        {
            "query": "[TODO: completely unrelated query — too easy, but include one for calibration]",
            "should_trigger": False,
        },
    ]


def main():
    parser = argparse.ArgumentParser(
        description="Generate trigger eval set for a skill"
    )
    parser.add_argument("skill_path", type=Path, help="Path to skill directory")
    parser.add_argument(
        "--output", "-o", type=Path, default=None, help="Output JSON path"
    )
    parser.add_argument(
        "--prompt-only",
        action="store_true",
        help="Print the generation prompt instead of starter set",
    )
    args = parser.parse_args()

    skill_path = args.skill_path.resolve()
    if not (skill_path / "SKILL.md").exists():
        print(f"Error: No SKILL.md found at {skill_path}", file=sys.stderr)
        sys.exit(1)

    name, description, content = parse_skill_md(skill_path)

    if args.prompt_only:
        prompt = build_generation_prompt(name, description, content)
        print(prompt)
        return

    starter = generate_starter_set(name, description)
    output = {
        "skill_name": name,
        "description": description,
        "evals": starter,
        "_note": "Replace placeholder queries with realistic ones. Use --prompt-only to get a prompt for opencode.",
    }

    json_str = json.dumps(output, indent=2, ensure_ascii=False)

    if args.output:
        args.output.write_text(json_str, encoding="utf-8")
        print(f"Starter eval set written to: {args.output}", file=sys.stderr)
    else:
        print(json_str)

    print(
        "\nTip: Run with --prompt-only to get a prompt you can paste into opencode "
        "to generate 20 realistic queries automatically.",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
