#!/usr/bin/env python3
"""Analyze trigger evaluation results and suggest description improvements.

Reads a JSON file with trigger test results, computes metrics,
analyzes failures, and outputs a report with recommendations.

Usage:
    python analyze_trigger_results.py results.json [--skill-path path/to/skill] [--output report.html]

Input JSON format:
[
  {"query": "...", "should_trigger": true, "did_trigger": true},
  {"query": "...", "should_trigger": false, "did_trigger": true}
]
"""

import argparse
import json
import sys
from pathlib import Path

# Allow importing from skill-lab root when run directly
sys.path.insert(0, str(Path(__file__).parent.parent))

from scripts.utils import parse_skill_md


def compute_metrics(results: list[dict]) -> dict:
    """Compute precision, recall, accuracy from trigger results."""
    tp = sum(1 for r in results if r["should_trigger"] and r["did_trigger"])
    fp = sum(1 for r in results if not r["should_trigger"] and r["did_trigger"])
    fn = sum(1 for r in results if r["should_trigger"] and not r["did_trigger"])
    tn = sum(1 for r in results if not r["should_trigger"] and not r["did_trigger"])

    total = len(results)
    precision = tp / (tp + fp) if (tp + fp) > 0 else 1.0
    recall = tp / (tp + fn) if (tp + fn) > 0 else 1.0
    accuracy = (tp + tn) / total if total > 0 else 0.0
    f1 = (
        2 * precision * recall / (precision + recall)
        if (precision + recall) > 0
        else 0.0
    )

    return {
        "tp": tp,
        "fp": fp,
        "fn": fn,
        "tn": tn,
        "precision": precision,
        "recall": recall,
        "accuracy": accuracy,
        "f1": f1,
        "total": total,
    }


def analyze_failures(results: list[dict]) -> dict:
    """Categorize failures and extract patterns."""
    failed_to_trigger = [
        r for r in results if r["should_trigger"] and not r["did_trigger"]
    ]
    false_triggers = [
        r for r in results if not r["should_trigger"] and r["did_trigger"]
    ]

    # Extract common words from failure queries
    def extract_words(queries: list[str]) -> list[str]:
        words = []
        for q in queries:
            words.extend(q.lower().split())
        # Filter short words and punctuation
        return [w.strip(".,!?;:'\"") for w in words if len(w) > 3]

    fn_words = extract_words([r["query"] for r in failed_to_trigger])
    fp_words = extract_words([r["query"] for r in false_triggers])

    from collections import Counter

    fn_common = Counter(fn_words).most_common(5)
    fp_common = Counter(fp_words).most_common(5)

    return {
        "failed_to_trigger": failed_to_trigger,
        "false_triggers": false_triggers,
        "fn_common_words": fn_common,
        "fp_common_words": fp_common,
    }


def generate_recommendations(
    metrics: dict, failures: dict, skill_name: str, current_description: str
) -> list[str]:
    """Generate actionable recommendations for improving the description."""
    recs = []

    if metrics["recall"] < 0.7:
        recs.append(
            f"[LOW RECALL] The skill fails to trigger for {len(failures['failed_to_trigger'])} queries that should trigger it. "
            "Add broader intent keywords and synonyms to the description. "
            "Focus on what the user is trying to achieve, not just technical terms."
        )

    if metrics["precision"] < 0.7:
        recs.append(
            f"[LOW PRECISION] The skill falsely triggers for {len(failures['false_triggers'])} queries. "
            "Make the description more specific about when NOT to use the skill. "
            "Add distinguishing keywords that separate it from adjacent tools."
        )

    if failures["fn_common_words"]:
        words = ", ".join([w for w, _ in failures["fn_common_words"]])
        recs.append(
            f"[MISSED KEYWORDS] Queries that should trigger often contain: {words}. "
            "Consider adding these or related concepts to the description if they align with the skill's purpose."
        )

    if failures["fp_common_words"]:
        words = ", ".join([w for w, _ in failures["fp_common_words"]])
        recs.append(
            f"[FALSE TRIGGER WORDS] Queries that falsely trigger often contain: {words}. "
            "If these represent adjacent domains, add clarifying exclusions to the description."
        )

    if len(current_description) < 80:
        recs.append(
            "[TOO SHORT] The description is very short. Expand it to 100-200 words "
            "to give the model enough context for accurate triggering."
        )

    if len(current_description) > 900:
        recs.append(
            "[NEAR LIMIT] The description is close to the 1024-character limit. "
            "Prioritize the most distinctive keywords and remove redundant phrasing."
        )

    if not recs:
        recs.append(
            "Metrics look good. If you want further improvement, test with more edge-case queries "
            "or refine based on real user feedback."
        )

    return recs


def generate_html_report(
    metrics: dict,
    failures: dict,
    recommendations: list[str],
    skill_name: str,
    current_description: str,
) -> str:
    """Generate an HTML report with results and recommendations."""

    def row(query: str, expected: bool, actual: bool) -> str:
        status = "PASS" if expected == actual else "FAIL"
        color = "#2a9d3d" if status == "PASS" else "#c44"
        return f"<tr><td>{query}</td><td>{'Yes' if expected else 'No'}</td><td>{'Yes' if actual else 'No'}</td><td style='color:{color};font-weight:bold;'>{status}</td></tr>"

    rows = "\n".join(
        row(r["query"], r["should_trigger"], r["did_trigger"])
        for r in failures["failed_to_trigger"] + failures["false_triggers"]
    )

    recs_html = "\n".join(f"<li>{r}</li>" for r in recommendations)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Trigger Analysis: {skill_name}</title>
<style>
body {{ font-family: system-ui, -apple-system, sans-serif; max-width: 900px; margin: 2rem auto; padding: 0 1rem; background: #faf9f5; color: #141413; }}
h1 {{ font-size: 1.5rem; margin-bottom: 0.5rem; }}
.metrics {{ display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; margin: 1.5rem 0; }}
.metric {{ background: white; padding: 1rem; border-radius: 6px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); text-align: center; }}
.metric .value {{ font-size: 1.75rem; font-weight: bold; color: #d97757; }}
.metric .label {{ font-size: 0.875rem; color: #b0aea5; margin-top: 0.25rem; }}
table {{ width: 100%; border-collapse: collapse; background: white; border-radius: 6px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.08); margin: 1rem 0; }}
th {{ background: #141413; color: #faf9f5; padding: 0.75rem 1rem; text-align: left; font-size: 0.875rem; }}
td {{ padding: 0.75rem 1rem; border-bottom: 1px solid #e8e6dc; }}
tr:nth-child(even) td {{ background: #faf9f5; }}
.recommendations {{ background: white; padding: 1.5rem; border-radius: 6px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }}
.recommendations li {{ margin-bottom: 0.75rem; line-height: 1.5; }}
.description {{ background: #f3f1ea; padding: 1rem; border-radius: 6px; font-style: italic; margin: 1rem 0; }}
</style>
</head>
<body>
<h1>Trigger Analysis: {skill_name}</h1>
<div class="description">Current description: {current_description}</div>

<div class="metrics">
  <div class="metric"><div class="value">{metrics["accuracy"]:.0%}</div><div class="label">Accuracy</div></div>
  <div class="metric"><div class="value">{metrics["precision"]:.0%}</div><div class="label">Precision</div></div>
  <div class="metric"><div class="value">{metrics["recall"]:.0%}</div><div class="label">Recall</div></div>
  <div class="metric"><div class="value">{metrics["f1"]:.0%}</div><div class="label">F1</div></div>
</div>

<h2>Failures ({len(failures["failed_to_trigger"]) + len(failures["false_triggers"])})</h2>
<table>
<thead><tr><th>Query</th><th>Should Trigger</th><th>Did Trigger</th><th>Status</th></tr></thead>
<tbody>{rows}</tbody>
</table>

<h2>Recommendations</h2>
<div class="recommendations">
<ol>{recs_html}</ol>
</div>

<p style="color:#b0aea5;font-size:0.875rem;margin-top:2rem;">
  Tip: Update your skill's description in SKILL.md based on these recommendations,
  then re-run the trigger evals to verify improvement.
</p>
</body>
</html>"""


def main():
    parser = argparse.ArgumentParser(description="Analyze trigger eval results")
    parser.add_argument("results", type=Path, help="Path to results JSON file")
    parser.add_argument(
        "--skill-path",
        type=Path,
        default=None,
        help="Path to skill directory (to read current description)",
    )
    parser.add_argument(
        "--output", "-o", type=Path, default=None, help="Output HTML report path"
    )
    parser.add_argument(
        "--json", action="store_true", help="Output JSON instead of HTML"
    )
    args = parser.parse_args()

    raw = json.loads(args.results.read_text(encoding="utf-8"))

    # Normalize input: accept both array and object with "results" key
    if isinstance(raw, dict) and "results" in raw:
        results: list[dict] = raw["results"]
    elif isinstance(raw, list):
        results: list[dict] = raw
    else:
        print(
            "Error: results must be a list or an object with 'results' key",
            file=sys.stderr,
        )
        sys.exit(1)

    skill_name = "unknown"
    current_description = "(not provided)"

    if args.skill_path:
        if not (args.skill_path / "SKILL.md").exists():
            print(f"Error: No SKILL.md found at {args.skill_path}", file=sys.stderr)
            sys.exit(1)
        skill_name, current_description, _ = parse_skill_md(args.skill_path)

    metrics = compute_metrics(results)
    failures = analyze_failures(results)
    recommendations = generate_recommendations(
        metrics, failures, skill_name, current_description
    )

    if args.json:
        output = {
            "skill_name": skill_name,
            "current_description": current_description,
            "metrics": metrics,
            "failures": {
                "failed_to_trigger_count": len(failures["failed_to_trigger"]),
                "false_triggers_count": len(failures["false_triggers"]),
                "failed_to_trigger": failures["failed_to_trigger"],
                "false_triggers": failures["false_triggers"],
            },
            "recommendations": recommendations,
        }
        json_str = json.dumps(output, indent=2, ensure_ascii=False)
        if args.output:
            args.output.write_text(json_str, encoding="utf-8")
            print(f"JSON report written to: {args.output}", file=sys.stderr)
        else:
            print(json_str)
    else:
        html = generate_html_report(
            metrics, failures, recommendations, skill_name, current_description
        )
        if args.output:
            args.output.write_text(html, encoding="utf-8")
            print(f"HTML report written to: {args.output}", file=sys.stderr)
        else:
            print(html)


if __name__ == "__main__":
    main()
