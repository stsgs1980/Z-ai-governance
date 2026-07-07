#!/usr/bin/env bash
# .zai/setup.sh — Z-ai-platform governance setup (v2 — unified)
# Entry point: bash .zai/setup.sh
# Purpose: validate .zai/config.json and report governance status
# Integrates with: existing .husky/pre-commit (guard + standards + lint-staged)
# Does NOT modify pre-commit — all enforcement is via guard/ and lint-staged
#
# Governance architecture (single layer):
#   - guard/scripts/*.sh     — integrity, commit, version, env, worklog (pre-commit Group 0-1, 3)
#   - standards/scripts/verify-*.js — content, id-graph, skills (pre-commit Group 2)
#   - eslint-rules/          — emoji, unicode, code-block-lang (pre-commit Group 4 via lint-staged)
#   - .zai/config.json       — single source of truth for thresholds

set -uo pipefail

PROJECT_ROOT="${ZAI_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
ZAI_DIR="${PROJECT_ROOT}/.zai"
GUARD_DIR="${PROJECT_ROOT}/guard"
STANDARDS_DIR="${PROJECT_ROOT}/standards"
SKILLS_DIR="${PROJECT_ROOT}/skills"
CONFIG_FILE="${ZAI_DIR}/config.json"

echo "=== Z.ai Governance Setup (unified) ==="
echo "Project root: ${PROJECT_ROOT}"
echo ""

# --- Phase 1: Check dependencies ---
echo "[1/4] Checking dependencies..."
MISSING=0

if command -v jq &>/dev/null; then
    echo "  jq: $(jq --version)"
else
    echo "  jq: NOT FOUND — config.json defaults will be used"
    MISSING=1
fi

if command -v node &>/dev/null; then
    echo "  node: $(node --version)"
else
    echo "  node: NOT FOUND — verify-*.js checks will be skipped"
    MISSING=1
fi

if [[ "$MISSING" -eq 1 ]]; then
    echo "  WARN: Some dependencies missing. Governance will work with reduced functionality."
fi
echo "  OK"

# --- Phase 2: Check existing infrastructure ---
echo "[2/4] Checking existing infrastructure..."

if [[ -f "${PROJECT_ROOT}/.husky/pre-commit" ]]; then
    echo "  .husky/pre-commit: FOUND"
    if grep -q "check-no-bypass.sh" "${PROJECT_ROOT}/.husky/pre-commit" 2>/dev/null; then
        echo "    -> guard integrity checks: present"
    fi
    if grep -q "worklog-check.sh" "${PROJECT_ROOT}/.husky/pre-commit" 2>/dev/null; then
        echo "    -> worklog-check (PROC-WORKLOG-005): present"
    fi
    if grep -q "co-change-check" "${PROJECT_ROOT}/.husky/pre-commit" 2>/dev/null; then
        echo "    -> co-change-check (PROC-COCHANGE-003): present"
    fi
    if grep -q "lint-staged" "${PROJECT_ROOT}/.husky/pre-commit" 2>/dev/null; then
        echo "    -> lint-staged (emoji/unicode via eslint): present"
    fi
else
    echo "  WARN: .husky/pre-commit not found"
fi

if [[ -d "${GUARD_DIR}/scripts" ]]; then
    GUARD_SCRIPTS=$(ls "${GUARD_DIR}/scripts/"*.sh 2>/dev/null | wc -l)
    echo "  Guard scripts: ${GUARD_SCRIPTS} shell scripts"
else
    echo "  WARN: guard/scripts/ not found"
fi

if [[ -d "${STANDARDS_DIR}/scripts" ]]; then
    echo "  Standards verify scripts: verify-standards.js, verify-id-graph.js, verify-skills.js"
else
    echo "  WARN: standards/scripts/ not found"
fi

if [[ -d "${SKILLS_DIR}" ]]; then
    SKILL_COUNT=$(ls -d "${SKILLS_DIR}"/*/ 2>/dev/null | wc -l)
    echo "  Skills: ${SKILL_COUNT} available"
else
    echo "  WARN: ${SKILLS_DIR}/ not found"
fi

echo "  OK"

# --- Phase 3: Create/validate config.json ---
echo "[3/4] Checking config..."
if [[ ! -f "${CONFIG_FILE}" ]]; then
    cat > "${CONFIG_FILE}" << 'CONF'
{
  "version": "1.1.0",
  "line_count": {
    "limit": 1000,
    "note": "Per-category limits in STD-META-001 S4.18.1: SKILL.md=800, CONTRACT.md=500, README.md=400.",
    "extensions": [".md", ".ts", ".js", ".py", ".sh"]
  },
  "worklog": {
    "paths": ["worklog.md"],
    "min_lines": 3,
    "note": "Enforced by guard/scripts/worklog-check.sh (PROC-WORKLOG-005)"
  },
  "emoji": {
    "enabled": true,
    "extensions": [".md"],
    "note": "Enforced by root eslint-rules/unicode-policy.js via lint-staged (STD-DOC-003)"
  },
  "exclude_dirs": [".git", "node_modules", ".next", "skills", "guard", "standards"]
}
CONF
    echo "  Created: .zai/config.json"
else
    echo "  config.json exists"
fi

# --- Phase 4: Validate config ---
echo "[4/4] Validating config..."
if [[ -f "${ZAI_DIR}/validate-config" ]]; then
    bash "${ZAI_DIR}/validate-config" --config "${CONFIG_FILE}" 2>&1 | sed 's/^/  /'
else
    echo "  SKIP: validate-config not found"
fi

# --- Summary ---
echo ""
echo "Setup complete."
echo ""
echo "Governance enforcement (single layer):"
echo "  pre-commit Group 0: guard/scripts/check-*.sh (integrity, commit, version, env)"
echo "  pre-commit Group 1: guard/scripts/co-change-check.sh + worklog-check.sh"
echo "  pre-commit Group 2: standards/scripts/verify-*.js (content, id-graph, skills)"
echo "  pre-commit Group 3: guard/scripts/line-count-check.sh (advisory)"
echo "  pre-commit Group 4: lint-staged -> eslint (emoji, unicode, code-block-lang)"
echo ""
echo "Config: .zai/config.json (single source of truth for thresholds)"
echo ""
echo "Commands:"
echo "  bash .zai/verify                  (run all checks)"
echo "  bash .zai/verify --staged         (staged files only)"
echo "  bash .zai/verify --check worklog  (specific check)"
echo "  bash .zai/validate-config         (validate config.json)"
echo ""
echo "Config: edit .zai/config.json to change limits"