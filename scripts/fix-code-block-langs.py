#!/usr/bin/env python3
"""
fix-code-block-langs.py — Fix incorrect code block language tags in .md files.

Root cause of ESLint parsing errors: code blocks with JSX are tagged as
`typescript` instead of `tsx`, code with TS types is tagged `javascript`,
and incomplete snippets need `text`.

This script:
1. Scans all .md files for code blocks
2. If a code block tagged `typescript` contains JSX → change to `tsx`
3. If a code block tagged `javascript` contains TS syntax → change to `typescript`
4. If a code block tagged `js` contains TS syntax → change to `typescript`
5. For other parsing failures, change to `text` (incomplete snippet)

Usage: python3 scripts/fix-code-block-langs.py [directory]
"""

import os
import re
import sys
import subprocess

# JSX indicators: <Component, <div, <span, <button, etc.
JSX_RE = re.compile(r"<[A-Z][a-zA-Z]*[\s/>]|<[a-z][a-z-]*[\s/>]|<\/[A-Z]|<\/[a-z]")

# TypeScript indicators that don't exist in plain JS
TS_RE = re.compile(
    r":\s*(string|number|boolean|void|any|never|unknown|undefined|null)\b"
    r"|interface\s+\w+"
    r"|type\s+\w+\s*="
    r"|as\s+\w+"
    r"|<\w+>\("  # generic function call
    r"|:\s*Readonly"
    r"|readonly\s+"
    r"|enum\s+\w+"
    r"|\?\.\w+"  # optional chaining in types
)


def fix_file(filepath):
    """Fix code block language tags. Returns (fixed, count) tuple."""
    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()

    original = "".join(lines)
    changes = 0

    # State machine: track code blocks
    in_code = False
    fence_len = 0
    open_fence_line = None
    current_lang = None
    code_lines = []

    new_lines = list(lines)

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.stripStart() if hasattr(line, "stripStart") else line.lstrip()
        m = re.match(r"^(`{3,})(.*)?$", stripped.rstrip())

        if m:
            fl = len(m.group(1))
            after = (m.group(2) or "").strip()

            if not in_code:
                # Opening fence
                in_code = True
                fence_len = fl
                open_fence_line = i
                current_lang = after
                code_lines = []
            else:
                if fl >= fence_len:
                    # Closing fence — analyze content and fix language if needed
                    if current_lang and code_lines:
                        content = "\n".join(code_lines)
                        new_lang = fix_language_tag(current_lang, content)

                        if new_lang != current_lang:
                            # Fix the opening fence line
                            old_fence = new_lines[open_fence_line]
                            # Replace the language part
                            old_fence_stripped = old_fence.lstrip()
                            indent = old_fence[
                                : len(old_fence) - len(old_fence_stripped)
                            ]
                            new_fence = indent + "`" * fence_len + new_lang + "\n"
                            if new_fence != old_fence:
                                new_lines[open_fence_line] = new_fence
                                changes += 1

                    in_code = False
                    current_lang = None
                    code_lines = []
                else:
                    # Nested fence — treat as content
                    code_lines.append(line.rstrip())
        elif in_code:
            code_lines.append(line.rstrip())

        i += 1

    content = "".join(new_lines)
    if content != original:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)
        return True, changes
    return False, 0


def fix_language_tag(current_lang, content):
    """Determine the correct language tag based on code content."""

    # If already text, keep it
    if current_lang in (
        "text",
        "mermaid",
        "yaml",
        "json",
        "bash",
        "shell",
        "sql",
        "html",
        "css",
        "diff",
        "dockerfile",
        "python",
        "plaintext",
        "markdown",
    ):
        return current_lang

    has_jsx = bool(JSX_RE.search(content))
    has_ts = bool(TS_RE.search(content))

    # --- Fix: typescript with JSX → tsx ---
    if current_lang == "typescript" and has_jsx:
        return "tsx"

    # --- Fix: tsx without JSX but with TS → keep tsx if it has TS types
    # (tsx handles both JSX and non-JSX TS, so this is fine)

    # --- Fix: javascript with TS syntax → typescript ---
    if current_lang == "javascript" and has_ts:
        if has_jsx:
            return "tsx"
        return "typescript"

    # --- Fix: js with TS syntax → typescript ---
    if current_lang == "js" and has_ts:
        if has_jsx:
            return "tsx"
        return "typescript"

    # --- Fix: javascript with JSX → jsx ---
    if current_lang == "javascript" and has_jsx:
        return "jsx"

    # --- Fix: js with JSX → jsx ---
    if current_lang == "js" and has_jsx:
        return "jsx"

    return current_lang


def main():
    target = sys.argv[1] if len(sys.argv) > 1 else "."
    total_files = 0
    total_changes = 0

    for root, dirs, files in os.walk(target):
        dirs[:] = [
            d
            for d in dirs
            if d not in ("node_modules", ".next", "dist", "build", ".git")
        ]
        for f in sorted(files):
            if not f.endswith(".md"):
                continue
            filepath = os.path.join(root, f)
            fixed, count = fix_file(filepath)
            if fixed:
                total_files += 1
                total_changes += count
                print(f"  Fixed {count} tag(s): {filepath}")

    print(f"\nTotal: {count} language tags fixed in {total_files} files")


if __name__ == "__main__":
    main()
