#!/usr/bin/env bash
# ============================================================================
# check-md.sh — Markdown linter entry point for STD-DOC-002 v2.4.1
# ============================================================================
#
# Purpose:
#   Single-command check that one or more .md files comply with the
#   Markdown Formatting Standard (STD-DOC-002 v2.4.1) and the No-Unicode
#   Policy (STD-DOC-003 v2.3). Runs three layers:
#
#     1. Static checks (pure bash, no dependencies)
#        - Bare fenced code blocks (``` without language) — STD-DOC-002 §5.4
#        - `*` or `+` as unordered-list markers — §5.2
#        - Closing `#` on ATX headings — §5.1
#        - Multiple H1 headings in a single document — §5.1
#        - Table pseudographics outside code blocks — §3
#
#     2. ESLint (auto-detected via npx) — §10
#        - markdown/* rules via eslint-plugin-markdown
#        - Custom unicode-policy rules (error severity, §10.6)
#        - Skipped silently if npx or eslint-plugin-markdown is missing
#
#     3. lint-md.js (custom Node linter) — §10.7
#        - Runs `node lint-md.js --level=C <path>` if the script is present
#          at the repo root or under scripts/, otherwise skipped with notice
#
# Usage:
#   bash scripts/check-md.sh                       # check all .md in repo
#   bash scripts/check-md.sh path/to/file.md       # check one file
#   bash scripts/check-md.sh docs/                 # check a directory
#   bash scripts/check-md.sh file1.md file2.md     # check multiple paths
#   bash scripts/check-md.sh --quiet path/to/dir   # only print failures
#   bash scripts/check-md.sh --help                # show this help
#
# Exit codes:
#   0 — all checks passed (skipped checks do not count as failures)
#   1 — at least one violation found
#   2 — invalid invocation
#
# Wiring:
#   This script is the canonical entry point referenced by STD-DOC-002 §0
#   (TL;DR) and §13 (Pre-merge checklist). It is intentionally bash-only
#   so it works in any checkout without requiring `npm install` first.
#   Once dependencies are installed, layers 2 and 3 add coverage on top.
#
# ============================================================================

set -euo pipefail

# ---- Colors (disabled if not a TTY) ---------------------------------------
if [ -t 1 ]; then
  C_RED=$'\033[31m'
  C_GRN=$'\033[32m'
  C_YLW=$'\033[33m'
  C_BLU=$'\033[34m'
  C_RST=$'\033[0m'
else
  C_RED=""
  C_GRN=""
  C_YLW=""
  C_BLU=""
  C_RST=""
fi

# ---- Globals ---------------------------------------------------------------
SCRIPT_NAME="$(basename "$0")"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QUIET=0
SHOW_HELP=0
TARGETS=()

# Counters
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
TOTAL_FILES=0

# ---- Helpers ---------------------------------------------------------------
log()  { printf '%s[check-md]%s %s\n' "$C_BLU" "$C_RST" "$*"; }
ok()   { if [ "$QUIET" -eq 0 ]; then printf '%s[ok]%s    %s\n'  "$C_GRN" "$C_RST" "$*"; fi; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { printf '%s[FAIL]%s  %s\n' "$C_RED" "$C_RST" "$*"; FAIL_COUNT=$((FAIL_COUNT+1)); }
skip() { if [ "$QUIET" -eq 0 ]; then printf '%s[skip]%s  %s\n' "$C_YLW" "$C_RST" "$*"; fi; SKIP_COUNT=$((SKIP_COUNT+1)); }
note() { if [ "$QUIET" -eq 0 ]; then printf '         %s\n' "$*"; fi; }

die() {
  printf '%s[check-md]%s %s%s%s\n' "$C_RED" "$C_RST" "$C_RED" "$*" "$C_RST" >&2
  exit 2
}

# ---- Argument parsing ------------------------------------------------------
usage() {
  # Print the leading comment block (everything from line 3 up to but not
  # including the `set -euo pipefail` line), with the `# ` prefix stripped.
  # Line 1 is the shebang, line 2 is the top `# ====` rule — both skipped.
  awk '
    /^set -euo pipefail/ { exit }
    NR >= 3 { sub(/^# ?/, ""); print }
  ' "$0"
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)    usage ;;
    --quiet|-q)   QUIET=1; shift ;;
    --)           shift; break ;;
    -*)           die "unknown option: $1 (try --help)" ;;
    *)            TARGETS+=("$1"); shift ;;
  esac
done

# Pick up positional args after `--`
while [ $# -gt 0 ]; do
  TARGETS+=("$1"); shift
done

# Default target: repo root (excluding node_modules / .git / .next / dist)
if [ ${#TARGETS[@]} -eq 0 ]; then
  TARGETS=("$REPO_ROOT")
fi

# ---- Collect .md files -----------------------------------------------------
collect_md_files() {
  local target="$1"
  if [ -f "$target" ]; then
    # Single file — include only if extension is .md
    case "$target" in
      *.md) printf '%s\n' "$target" ;;
    esac
  elif [ -d "$target" ]; then
    # find with prune patterns for performance and noise reduction
    find "$target" \
      \( -name node_modules -o -name .git -o -name .next \
         -o -name dist -o -name build -o -name coverage \) -prune \
      -o -type f -name '*.md' -print 2>/dev/null || true
  fi
}

# Collect unique .md files from all targets
declare -a ALL_FILES=()
declare -A SEEN=()
for t in "${TARGETS[@]}"; do
  if [ ! -e "$t" ]; then
    fail "target does not exist: $t"
    continue
  fi
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if [ -z "${SEEN[$f]:-}" ]; then
      SEEN[$f]=1
      ALL_FILES+=("$f")
    fi
  done < <(collect_md_files "$t")
done

TOTAL_FILES=${#ALL_FILES[@]}
if [ "$TOTAL_FILES" -eq 0 ]; then
  log "no .md files found in: ${TARGETS[*]}"
  exit 0
fi

log "checking $TOTAL_FILES file(s) against STD-DOC-002 v2.4.1"

# ---- Layer 1: Static checks (bash only) ------------------------------------
# These run on every file unconditionally — no Node.js, no ESLint, no deps.
# Catches the most common §5 violations that slip past reviewers.
static_check_file() {
  local file="$1"
  local had_issue=0

  local in_fence=0
  local fence_lang=""
  local fence_len_open=0
  local h1_count=0
  local lineno=0

  while IFS= read -r line || [ -n "$line" ]; do
    lineno=$((lineno+1))

    # Detect opening / closing fence: 3+ backticks optionally followed by language.
    # CommonMark rule: a fence of N backticks can only be closed by a fence
    # of N or more backticks. So a 4-backtick fence can contain 3-backtick
    # lines inside it (this is how the standard documents nested examples).
    if [[ "$line" =~ ^(\`\`\`+)([A-Za-z0-9_+-]*) ]]; then
      local fence_len="${#BASH_REMATCH[1]}"
      local lang="${BASH_REMATCH[2]}"
      if [ "$in_fence" -eq 0 ]; then
        in_fence=1
        fence_lang="$lang"
        fence_len_open="$fence_len"
        if [ -z "$lang" ]; then
          fail "$file:$lineno  bare code fence (missing language) - STD-DOC-002 §5.4"
          had_issue=1
        fi
      else
        # Closing fence: must have >= opening fence length
        if [ "$fence_len" -ge "$fence_len_open" ]; then
          in_fence=0
          fence_lang=""
          fence_len_open=0
        fi
        # Shorter fence inside longer fence is just text (e.g. ``` inside ````)
      fi
      continue
    fi

    # Inside a fence — skip static checks (code blocks have their own rules)
    if [ "$in_fence" -eq 1 ]; then
      continue
    fi

    # ATX heading detection (lines starting with #, not inside code)
    if [[ "$line" =~ ^(#{1,6})[[:space:]]+(.*)$ ]]; then
      local hashes="${BASH_REMATCH[1]}"
      local heading_text="${BASH_REMATCH[2]}"
      # Closing hash? e.g. "## Title ##"
      if [[ "$heading_text" =~ [[:space:]]+#+[[:space:]]*$ ]]; then
        fail "$file:$lineno  closing '#' on heading - STD-DOC-002 §5.1"
        had_issue=1
      fi
      # Multiple H1?
      if [ "${#hashes}" -eq 1 ]; then
        h1_count=$((h1_count+1))
        if [ "$h1_count" -gt 1 ]; then
          fail "$file:$lineno  multiple H1 headings in document - STD-DOC-002 §5.1"
          had_issue=1
        fi
      fi
    fi

    # Unordered list with `*` or `+`?
    # (only outside code blocks — checked above)
    if [[ "$line" =~ ^[[:space:]]*[\*+][[:space:]]+ ]]; then
      fail "$file:$lineno  '*' or '+' as unordered list marker (use '-') - STD-DOC-002 §5.2"
      had_issue=1
    fi

    # Table pseudographics OUTSIDE code blocks?
    # Heuristic: line longer than 5 chars, only +,-,| and whitespace,
    # AND contains at least one `+` junction AND one `-` run.
    # Markdown table separator rows like |---|---| do NOT contain `+` and pass.
    if [ "${#line}" -gt 5 ] \
       && [[ "$line" =~ ^[[:space:]]*[+|\ -]+$ ]] \
       && [[ "$line" == *"+"* ]] \
       && [[ "$line" == *"-"* ]]; then
      fail "$file:$lineno  table pseudographics outside code block - STD-DOC-002 §3 (wrap in a fenced 'text' block)"
      had_issue=1
    fi

  done < "$file"

  if [ "$had_issue" -eq 0 ]; then
    ok "$file  (static checks PASS)"
  fi
}

# ---- Layer 2: ESLint (if available) ----------------------------------------
run_eslint() {
  if ! command -v npx >/dev/null 2>&1; then
    skip "eslint: npx not found in PATH"
    return 0
  fi

  # Detect eslint without spawning an install prompt
  local has_eslint=0
  if [ -x "$REPO_ROOT/node_modules/.bin/eslint" ]; then
    has_eslint=1
  elif npx --no-install eslint --version >/dev/null 2>&1; then
    has_eslint=1
  fi
  if [ "$has_eslint" -eq 0 ]; then
    skip "eslint: not installed (run 'npm install --save-dev eslint eslint-plugin-markdown')"
    return 0
  fi

  log "eslint: linting $TOTAL_FILES file(s)"
  local eslint_bin
  if [ -x "$REPO_ROOT/node_modules/.bin/eslint" ]; then
    eslint_bin="$REPO_ROOT/node_modules/.bin/eslint"
  else
    eslint_bin="npx --no-install eslint"
  fi

  # --max-warnings=0 makes warnings fail too (consistent with §9.1 [C] policy)
  if $eslint_bin --max-warnings=0 --plugin markdown "${ALL_FILES[@]}"; then
    ok "eslint: PASS"
  else
    fail "eslint: violations reported above (see STD-DOC-002 §10 for config)"
  fi
}

# ---- Layer 3: lint-md.js (custom linter, if present) -----------------------
run_lint_md_js() {
  local script=""
  for candidate in \
      "$REPO_ROOT/lint-md.js" \
      "$REPO_ROOT/scripts/lint-md.js"; do
    if [ -f "$candidate" ]; then
      script="$candidate"
      break
    fi
  done

  if [ -z "$script" ]; then
    skip "lint-md.js: not present at repo root (optional - see STD-DOC-002 §10.7)"
    return 0
  fi

  if ! command -v node >/dev/null 2>&1; then
    skip "lint-md.js: node not found in PATH"
    return 0
  fi

  # Default level is C (Critical) per STD-DOC-002 §9.1 - blocks commit.
  # The --level=W override exists for legacy migration only and must not
  # be wired into CI or pre-commit hooks.
  log "lint-md.js: linting $TOTAL_FILES file(s) at --level=C"
  if node "$script" --level=C "${ALL_FILES[@]}"; then
    ok "lint-md.js: PASS"
  else
    fail "lint-md.js: violations reported above"
  fi
}

# ---- Run all layers --------------------------------------------------------
# Layer 1: per-file static checks (always run)
for f in "${ALL_FILES[@]}"; do
  static_check_file "$f"
done

# Layer 2 + 3: project-wide tooling (if available)
run_eslint
run_lint_md_js

# ---- Summary ---------------------------------------------------------------
echo ""
log "summary: $PASS_COUNT passed, $FAIL_COUNT failed, $SKIP_COUNT skipped ($TOTAL_FILES files)"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "${C_RED}[check-md] FAIL: $FAIL_COUNT violation(s) found.${C_RST}"
  echo "         See STD-DOC-002 §0 (TL;DR), §3 (Prohibited), §5 (Formatting),"
  echo "         §10 (ESLint), §13 (Pre-merge checklist) for details."
  exit 1
fi

echo "${C_GRN}[check-md] OK: all checks passed.${C_RST}"
exit 0
