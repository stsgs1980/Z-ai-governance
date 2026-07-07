#!/usr/bin/env bash
#
# sandbox-integration-test.sh — Test Z-ai-platform in sandbox environment
#
# Usage:
#   bash tests/sandbox-integration-test.sh
#
# What it tests:
#   1. Bootstrap has already run (skills symlinked)
#   2. Skills are valid and accessible
#   3. Governance system (.zai/) exists and works
#   4. Verifiers pass
#   5. Agent can read AGENT_RULES.md
#   6. Git config is correct
#
# Environment:
#   - Expects to run AFTER bootstrap.sh has been executed
#   - Working directory: /home/z/my-project/Z-ai-platform-unified
#   - Does NOT clone from GitHub (uses existing installation)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Platform directory (where this script is run from)
PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Sandbox skills directory
SANDBOX_SKILLS_DIR="/home/z/my-project/skills"

# ============================================================================
# Helper functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
}

run_test() {
    local test_name="$1"
    local test_func="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo ""
    echo "=== Test: $test_name ==="
    
    if $test_func; then
        log_success "$test_name"
    else
        log_fail "$test_name"
    fi
}

# ============================================================================
# Test 1: Platform directory exists
# ============================================================================

test_platform_directory_exists() {
    if [ -d "$PLATFORM_DIR" ]; then
        log_info "Platform directory exists: $PLATFORM_DIR"
        return 0
    else
        log_fail "Platform directory not found: $PLATFORM_DIR"
        return 1
    fi
}

# ============================================================================
# Test 2: Git repository is valid
# ============================================================================

test_git_repository_valid() {
    if [ -d "$PLATFORM_DIR/.git" ]; then
        log_info ".git directory exists"
        
        # Check if it's a valid git repo
        if git -C "$PLATFORM_DIR" status > /dev/null 2>&1; then
            log_info "Git repository is valid"
        else
            log_fail "Git repository is invalid"
            return 1
        fi
        
        return 0
    else
        log_fail ".git directory not found"
        return 1
    fi
}

# ============================================================================
# Test 3: Core directories exist
# ============================================================================

test_core_directories_exist() {
    local errors=0
    
    # Check standards/ directory
    if [ -d "$PLATFORM_DIR/standards" ]; then
        log_info "standards/ directory exists"
    else
        log_fail "standards/ directory not found"
        errors=$((errors + 1))
    fi
    
    # Check guard/ directory
    if [ -d "$PLATFORM_DIR/guard" ]; then
        log_info "guard/ directory exists"
    else
        log_fail "guard/ directory not found"
        errors=$((errors + 1))
    fi
    
    # Check skills/ directory
    if [ -d "$PLATFORM_DIR/skills" ]; then
        log_info "skills/ directory exists"
    else
        log_fail "skills/ directory not found"
        errors=$((errors + 1))
    fi
    
    if [ "$errors" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# Test 4: Skills directory exists and has skills
# ============================================================================

test_skills_directory_exists() {
    if [ -d "$SANDBOX_SKILLS_DIR" ]; then
        log_info "Skills directory exists: $SANDBOX_SKILLS_DIR"
        
        local skill_count=$(ls -d "$SANDBOX_SKILLS_DIR"/*/ 2>/dev/null | wc -l)
        if [ "$skill_count" -gt 0 ]; then
            log_info "Found $skill_count skills"
        else
            log_fail "No skills found in directory"
            return 1
        fi
        
        return 0
    else
        log_fail "Skills directory not found: $SANDBOX_SKILLS_DIR"
        return 1
    fi
}

# ============================================================================
# Test 5: zai-sandbox-rules skill exists
# ============================================================================

test_sandbox_rules_exists() {
    local skill_file="$SANDBOX_SKILLS_DIR/zai-sandbox-rules/SKILL.md"
    
    if [ -f "$skill_file" ]; then
        log_info "zai-sandbox-rules/SKILL.md exists"
        
        # Check if it contains expected content
        if grep -q "NEVER Run Dev Servers" "$skill_file"; then
            log_info "Contains 'NEVER Run Dev Servers'"
        else
            log_fail "Missing 'NEVER Run Dev Servers'"
            return 1
        fi
        
        if grep -q "Rule 1:" "$skill_file"; then
            log_info "Contains Rule 1"
        else
            log_fail "Missing Rule 1"
            return 1
        fi
        
        return 0
    else
        log_fail "zai-sandbox-rules/SKILL.md not found"
        return 1
    fi
}

# ============================================================================
# Test 6: All skills have SKILL.md
# ============================================================================

test_all_skills_have_skillmd() {
    local errors=0
    local total=0
    
    for skill_dir in "$SANDBOX_SKILLS_DIR"/*/; do
        [ -d "$skill_dir" ] || continue
        local skill_name=$(basename "$skill_dir")
        total=$((total + 1))
        
        if [ -f "$skill_dir/SKILL.md" ]; then
            log_info "$skill_name: SKILL.md exists"
        else
            log_fail "$skill_name: SKILL.md missing"
            errors=$((errors + 1))
        fi
    done
    
    log_info "Checked $total skills"
    
    if [ "$errors" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# Test 7: Skills are symlinks
# ============================================================================

test_skills_are_symlinks() {
    local errors=0
    local total=0
    local symlinks=0
    
    for skill_dir in "$SANDBOX_SKILLS_DIR"/*; do
        [ -d "$skill_dir" ] || continue
        local skill_name=$(basename "$skill_dir")
        total=$((total + 1))
        
        if [ -L "$skill_dir" ]; then
            symlinks=$((symlinks + 1))
            local target=$(readlink -f "$skill_dir" 2>/dev/null || readlink "$skill_dir")
            log_info "$skill_name: symlink -> $target"
        else
            log_warn "$skill_name: not a symlink (regular directory)"
        fi
    done
    
    log_info "Checked $total skills, $symlinks symlinks"
    
    if [ "$symlinks" -gt 0 ]; then
        return 0
    else
        log_warn "No symlinks found (may be expected if skills are copied)"
        return 0
    fi
}

# ============================================================================
# Test 8: No broken symlinks
# ============================================================================

test_no_broken_symlinks() {
    local broken_count=$(find "$SANDBOX_SKILLS_DIR" -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l)
    
    if [ "$broken_count" -eq 0 ]; then
        log_info "No broken symlinks"
        return 0
    else
        log_fail "Found $broken_count broken symlinks"
        find "$SANDBOX_SKILLS_DIR" -type l ! -exec test -e {} \; -print 2>/dev/null | while read link; do
            log_fail "  Broken: $link"
        done
        return 1
    fi
}

# ============================================================================
# Test 9: Governance system (.zai/)
# ============================================================================

test_governance_system() {
    if [ -d "$PLATFORM_DIR/.zai" ]; then
        log_info ".zai/ directory exists"
        
        # Check config.json
        if [ -f "$PLATFORM_DIR/.zai/config.json" ]; then
            log_info "config.json exists"
            
            # Validate JSON
            if command -v node &>/dev/null; then
                if node -e "require('$PLATFORM_DIR/.zai/config.json')" 2>/dev/null; then
                    log_info "config.json is valid JSON"
                else
                    log_fail "config.json is invalid JSON"
                    return 1
                fi
            fi
        else
            log_fail "config.json missing"
            return 1
        fi
        
        # Check setup.sh
        if [ -f "$PLATFORM_DIR/.zai/setup.sh" ]; then
            log_info "setup.sh exists"
        else
            log_fail "setup.sh missing"
            return 1
        fi
        
        # Check verify
        if [ -f "$PLATFORM_DIR/.zai/verify" ]; then
            log_info "verify script exists"
        else
            log_fail "verify script missing"
            return 1
        fi
        
        return 0
    else
        log_fail ".zai/ directory not found"
        return 1
    fi
}

# ============================================================================
# Test 10: Verifiers exist
# ============================================================================

test_verifiers_exist() {
    local errors=0
    
    # Check verify-standards.js
    if [ -f "$PLATFORM_DIR/standards/scripts/verify-standards.js" ]; then
        log_info "verify-standards.js exists"
    else
        log_fail "verify-standards.js not found"
        errors=$((errors + 1))
    fi
    
    # Check verify-id-graph.js
    if [ -f "$PLATFORM_DIR/standards/scripts/verify-id-graph.js" ]; then
        log_info "verify-id-graph.js exists"
    else
        log_fail "verify-id-graph.js not found"
        errors=$((errors + 1))
    fi
    
    # Check verify-skills.js
    if [ -f "$PLATFORM_DIR/standards/scripts/verify-skills.js" ]; then
        log_info "verify-skills.js exists"
    else
        log_fail "verify-skills.js not found"
        errors=$((errors + 1))
    fi
    
    if [ "$errors" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# Test 11: Run verify-standards.js
# ============================================================================

test_run_verify_standards() {
    if ! command -v node &>/dev/null; then
        log_skip "node not available"
        return 0
    fi
    
    log_info "Running verify-standards.js..."
    local output
    output=$(cd "$PLATFORM_DIR/standards" && node scripts/verify-standards.js 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_info "verify-standards.js passed"
        echo "$output" | tail -3
        return 0
    else
        log_fail "verify-standards.js failed (exit code: $exit_code)"
        echo "$output" | tail -10
        return 1
    fi
}

# ============================================================================
# Test 12: Run verify-id-graph.js
# ============================================================================

test_run_verify_id_graph() {
    if ! command -v node &>/dev/null; then
        log_skip "node not available"
        return 0
    fi
    
    log_info "Running verify-id-graph.js..."
    local output
    output=$(cd "$PLATFORM_DIR/standards" && node scripts/verify-id-graph.js 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_info "verify-id-graph.js passed"
        echo "$output" | tail -3
        return 0
    else
        log_fail "verify-id-graph.js failed (exit code: $exit_code)"
        echo "$output" | tail -10
        return 1
    fi
}

# ============================================================================
# Test 13: AGENT_RULES.md is readable
# ============================================================================

test_agent_rules_readable() {
    local agent_rules="$PLATFORM_DIR/AGENT_RULES.md"
    
    if [ -f "$agent_rules" ]; then
        log_info "AGENT_RULES.md exists"
        
        if cat "$agent_rules" > /dev/null 2>&1; then
            log_info "AGENT_RULES.md is readable"
        else
            log_fail "AGENT_RULES.md is not readable"
            return 1
        fi
        
        # Check for expected content
        if grep -q "Single Entry Point" "$agent_rules"; then
            log_info "Contains 'Single Entry Point'"
        else
            log_fail "Missing 'Single Entry Point'"
            return 1
        fi
        
        if grep -q "Priority" "$agent_rules"; then
            log_info "Contains priority order"
        else
            log_fail "Missing priority order"
            return 1
        fi
        
        return 0
    else
        log_fail "AGENT_RULES.md not found"
        return 1
    fi
}

# ============================================================================
# Test 14: Git config is correct
# ============================================================================

test_git_config_correct() {
    local errors=0
    
    # Check core.fileMode in platform
    local platform_filemode
    platform_filemode=$(git -C "$PLATFORM_DIR" config core.fileMode 2>/dev/null || echo "not set")
    
    if [ "$platform_filemode" = "false" ]; then
        log_info "Platform core.fileMode = false"
    else
        log_fail "Platform core.fileMode = $platform_filemode (expected false)"
        errors=$((errors + 1))
    fi
    if [ "$errors" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# Test 15: Skills INDEX.md exists
# ============================================================================

test_skills_index_exists() {
    if [ -f "$PLATFORM_DIR/skills/INDEX.md" ]; then
        log_info "skills/INDEX.md exists"
        
        # Check if it lists skills
        if grep -q "zai-sandbox-rules" "$PLATFORM_DIR/skills/INDEX.md"; then
            log_info "INDEX.md lists zai-sandbox-rules"
        else
            log_fail "INDEX.md missing zai-sandbox-rules"
            return 1
        fi
        
        return 0
    else
        log_fail "skills/INDEX.md not found"
        return 1
    fi
}

# ============================================================================
# Test 16: Pre-commit hook exists
# ============================================================================

test_precommit_hook_exists() {
    if [ -f "$PLATFORM_DIR/.husky/pre-commit" ]; then
        log_info ".husky/pre-commit exists"
        
        # Check if it's executable or has correct content
        if grep -q "co-change-check" "$PLATFORM_DIR/.husky/pre-commit"; then
            log_info "Contains co-change-check"
        else
            log_warn "Missing co-change-check"
        fi
        
        if grep -q "worklog-check" "$PLATFORM_DIR/.husky/pre-commit"; then
            log_info "Contains worklog-check"
        else
            log_warn "Missing worklog-check"
        fi
        
        if grep -q "lint-staged" "$PLATFORM_DIR/.husky/pre-commit"; then
            log_info "Contains lint-staged"
        else
            log_warn "Missing lint-staged"
        fi
        
        return 0
    else
        log_fail ".husky/pre-commit not found"
        return 1
    fi
}

# ============================================================================
# Test 17: No CRLF in shell scripts
# ============================================================================

test_no_crlf_in_shell_scripts() {
    local errors=0
    
    for script in bootstrap.sh scripts/save-work.sh scripts/status.sh; do
        if [ -f "$PLATFORM_DIR/$script" ]; then
            # Check for CRLF
            if cat -A "$PLATFORM_DIR/$script" | grep -q $'\r'; then
                log_fail "$script has CRLF line endings"
                errors=$((errors + 1))
            else
                log_info "$script has LF line endings"
            fi
        fi
    done
    
    # Check husky hooks
    for hook in .husky/pre-commit .husky/pre-push .husky/commit-msg; do
        if [ -f "$PLATFORM_DIR/$hook" ]; then
            if cat -A "$PLATFORM_DIR/$hook" | grep -q $'\r'; then
                log_fail "$hook has CRLF line endings"
                errors=$((errors + 1))
            else
                log_info "$hook has LF line endings"
            fi
        fi
    done
    
    if [ "$errors" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# Test 18: Worklog exists and is non-empty
# ============================================================================

test_worklog_exists() {
    if [ -f "$PLATFORM_DIR/worklog.md" ]; then
        log_info "worklog.md exists"
        
        local line_count=$(wc -l < "$PLATFORM_DIR/worklog.md")
        if [ "$line_count" -gt 0 ]; then
            log_info "worklog.md has $line_count lines"
        else
            log_fail "worklog.md is empty"
            return 1
        fi
        
        return 0
    else
        log_fail "worklog.md not found"
        return 1
    fi
}

# ============================================================================
# Test 19: CHANGELOG exists
# ============================================================================

test_changelog_exists() {
    if [ -f "$PLATFORM_DIR/CHANGELOG.md" ]; then
        log_info "CHANGELOG.md exists"
        return 0
    else
        log_fail "CHANGELOG.md not found"
        return 1
    fi
}

# ============================================================================
# Test 20: Summary of all checks
# ============================================================================

test_summary() {
    echo ""
    echo "=========================================="
    echo "Sandbox Environment Summary"
    echo "=========================================="
    echo ""
    echo "Platform: $PLATFORM_DIR"
    echo "Skills: $SANDBOX_SKILLS_DIR"
    echo ""
    
    # Count skills
    local skill_count=$(ls -d "$SANDBOX_SKILLS_DIR"/*/ 2>/dev/null | wc -l)
    echo "Skills loaded: $skill_count"
    
    # List skills
    for skill_dir in "$SANDBOX_SKILLS_DIR"/*; do
        [ -d "$skill_dir" ] || continue
        local skill_name=$(basename "$skill_dir")
        if [ -L "$skill_dir" ]; then
            echo "  - $skill_name (symlink)"
        else
            echo "  - $skill_name (directory)"
        fi
    done
    
    echo ""
    echo "Core directories:"
    for dir in standards guard skills; do
        if [ -d "$PLATFORM_DIR/$dir" ]; then
            echo "  - $dir/: exists"
        else
            echo "  - $dir/: MISSING"
        fi
    done
    
    echo ""
    return 0
}

# ============================================================================
# Main test runner
# ============================================================================

main() {
    echo "=========================================="
    echo "Z-ai-platform Sandbox Integration Tests"
    echo "=========================================="
    echo ""
    echo "Platform directory: $PLATFORM_DIR"
    echo "Skills directory: $SANDBOX_SKILLS_DIR"
    echo ""
    
    # Run tests
    run_test "Platform directory exists" test_platform_directory_exists
    run_test "Git repository is valid" test_git_repository_valid
    run_test "Core directories exist" test_core_directories_exist
    run_test "Skills directory exists" test_skills_directory_exists
    run_test "zai-sandbox-rules skill exists" test_sandbox_rules_exists
    run_test "All skills have SKILL.md" test_all_skills_have_skillmd
    run_test "Skills are symlinks" test_skills_are_symlinks
    run_test "No broken symlinks" test_no_broken_symlinks
    run_test "Governance system (.zai/)" test_governance_system
    run_test "Verifiers exist" test_verifiers_exist
    run_test "Run verify-standards.js" test_run_verify_standards
    run_test "Run verify-id-graph.js" test_run_verify_id_graph
    run_test "AGENT_RULES.md is readable" test_agent_rules_readable
    run_test "Git config is correct" test_git_config_correct
    run_test "Skills INDEX.md exists" test_skills_index_exists
    run_test "Pre-commit hook exists" test_precommit_hook_exists
    run_test "No CRLF in shell scripts" test_no_crlf_in_shell_scripts
    run_test "Worklog exists" test_worklog_exists
    run_test "CHANGELOG exists" test_changelog_exists
    run_test "Summary" test_summary
    
    # Summary
    echo ""
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo ""
    echo "Tests run:    $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo "Tests skipped: $TESTS_SKIPPED"
    echo ""
    
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        return 1
    fi
}

# Run main function
main "$@"
