#!/usr/bin/env bash
#
# sandbox-behavior-test.sh — Test agent behavior in sandbox
#
# Usage:
#   bash tests/sandbox-behavior-test.sh
#
# What it tests:
#   1. Agent can read and understand key files
#   2. Agent can access skills
#   3. Agent can run verifiers
#   4. Agent can follow onboarding protocol
#
# Environment:
#   - Expects to run AFTER bootstrap.sh has been executed
#   - Working directory: /home/z/my-project/Z-ai-governance

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

# Platform directory
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
# Test 1: Agent can read AGENT_RULES.md
# ============================================================================

test_agent_can_read_agent_rules() {
    local agent_rules="$PLATFORM_DIR/AGENT_RULES.md"
    
    if [ -f "$agent_rules" ]; then
        log_info "AGENT_RULES.md exists"
        
        # Check if agent can read it
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
        
        if grep -q "Onboarding Protocol" "$agent_rules"; then
            log_info "Contains 'Onboarding Protocol'"
        else
            log_fail "Missing 'Onboarding Protocol'"
            return 1
        fi
        
        if grep -q "Priority Order" "$agent_rules"; then
            log_info "Contains 'Priority Order'"
        else
            log_fail "Missing 'Priority Order'"
            return 1
        fi
        
        if grep -q "Forbidden Actions" "$agent_rules"; then
            log_info "Contains 'Forbidden Actions'"
        else
            log_fail "Missing 'Forbidden Actions'"
            return 1
        fi
        
        return 0
    else
        log_fail "AGENT_RULES.md not found"
        return 1
    fi
}

# ============================================================================
# Test 2: Agent can load skills
# ============================================================================

test_agent_can_load_skills() {
    if [ -d "$SANDBOX_SKILLS_DIR" ]; then
        log_info "Skills directory exists"
        
        # Check each skill
        local errors=0
        for skill_dir in "$SANDBOX_SKILLS_DIR"/*/; do
            [ -d "$skill_dir" ] || continue
            local skill_name=$(basename "$skill_dir")
            
            # Check if SKILL.md is readable
            if [ -f "$skill_dir/SKILL.md" ]; then
                if cat "$skill_dir/SKILL.md" > /dev/null 2>&1; then
                    log_info "$skill_name: SKILL.md readable"
                else
                    log_fail "$skill_name: SKILL.md not readable"
                    errors=$((errors + 1))
                fi
            else
                log_fail "$skill_name: SKILL.md missing"
                errors=$((errors + 1))
            fi
        done
        
        if [ "$errors" -eq 0 ]; then
            return 0
        else
            return 1
        fi
    else
        log_fail "Skills directory not found"
        return 1
    fi
}

# ============================================================================
# Test 3: Agent can find zai-sandbox-rules
# ============================================================================

test_agent_can_find_sandbox_rules() {
    local skill_file="$SANDBOX_SKILLS_DIR/zai-sandbox-rules/SKILL.md"
    
    if [ -f "$skill_file" ]; then
        log_info "zai-sandbox-rules/SKILL.md exists"
        
        # Check if it contains the rules
        if grep -q "Rule 1:" "$skill_file"; then
            log_info "Contains Rule 1"
        else
            log_fail "Missing Rule 1"
            return 1
        fi
        
        if grep -q "NEVER Run Dev Servers" "$skill_file"; then
            log_info "Contains 'NEVER Run Dev Servers'"
        else
            log_fail "Missing 'NEVER Run Dev Servers'"
            return 1
        fi
        
        if grep -q "Rule 13:" "$skill_file"; then
            log_info "Contains Rule 13"
        else
            log_warn "Missing Rule 13 (may be expected)"
        fi
        
        return 0
    else
        log_fail "zai-sandbox-rules/SKILL.md not found"
        return 1
    fi
}

# ============================================================================
# Test 4: Agent can run verifiers
# ============================================================================

test_agent_can_run_verifiers() {
    if ! command -v node &>/dev/null; then
        log_skip "node not available"
        return 0
    fi
    
    # Check verify-standards.js
    if [ -f "$PLATFORM_DIR/standards/scripts/verify-standards.js" ]; then
        log_info "verify-standards.js exists"
        
        # Try to run it
        log_info "Running verify-standards.js..."
        local output
        output=$(cd "$PLATFORM_DIR/standards" && node scripts/verify-standards.js 2>&1)
        local exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            log_info "verify-standards.js executed successfully"
        else
            log_fail "verify-standards.js failed"
            return 1
        fi
    else
        log_fail "verify-standards.js not found"
        return 1
    fi
    
    return 0
}

# ============================================================================
# Test 5: Agent can check git status
# ============================================================================

test_agent_can_check_git_status() {
    if git -C "$PLATFORM_DIR" status > /dev/null 2>&1; then
        log_info "git status works"
        
        # Check if Z-ai-platform is tracked
        local status_output
        status_output=$(git -C "$PLATFORM_DIR" status --short 2>&1)
        
        if [ -z "$status_output" ]; then
            log_info "Working tree is clean"
        else
            log_info "Working tree has changes"
        fi
        
        return 0
    else
        log_fail "git status failed"
        return 1
    fi
}

# ============================================================================
# Test 6: Agent can read config
# ============================================================================

test_agent_can_read_config() {
    if [ -f "$PLATFORM_DIR/.zai/config.json" ]; then
        log_info "config.json exists"
        
        # Check if agent can read it
        if cat "$PLATFORM_DIR/.zai/config.json" > /dev/null 2>&1; then
            log_info "config.json is readable"
        else
            log_fail "config.json is not readable"
            return 1
        fi
        
        # Check if it's valid JSON
        if command -v node &>/dev/null; then
            if node -e "require('$PLATFORM_DIR/.zai/config.json')" 2>/dev/null; then
                log_info "config.json is valid JSON"
            else
                log_fail "config.json is invalid JSON"
                return 1
            fi
        fi
        
        return 0
    else
        log_fail "config.json not found"
        return 1
    fi
}

# ============================================================================
# Test 7: Agent can understand skill structure
# ============================================================================

test_agent_can_understand_skill_structure() {
    if [ -f "$PLATFORM_DIR/skills/INDEX.md" ]; then
        log_info "INDEX.md exists"
        
        # Check if it lists skills
        if grep -q "zai-sandbox-rules" "$PLATFORM_DIR/skills/INDEX.md"; then
            log_info "INDEX.md lists zai-sandbox-rules"
        else
            log_fail "INDEX.md missing zai-sandbox-rules"
            return 1
        fi
        
        if grep -q "zai-skill-creator" "$PLATFORM_DIR/skills/INDEX.md"; then
            log_info "INDEX.md lists zai-skill-creator"
        else
            log_fail "INDEX.md missing zai-skill-creator"
            return 1
        fi
        
        return 0
    else
        log_fail "INDEX.md not found"
        return 1
    fi
}

# ============================================================================
# Test 8: Agent can follow onboarding protocol
# ============================================================================

test_agent_can_follow_onboarding() {
    # Step 1: Read AGENT_RULES.md
    if [ -f "$PLATFORM_DIR/AGENT_RULES.md" ]; then
        log_info "Step 1: AGENT_RULES.md exists"
    else
        log_fail "Step 1: AGENT_RULES.md not found"
        return 1
    fi
    
    # Step 2: Check standards
    if [ -d "$PLATFORM_DIR/standards" ]; then
        log_info "Step 2: standards directory exists"
    else
        log_fail "Step 2: standards directory not found"
        return 1
    fi
    
    # Step 3: Check skills
    if [ -f "$PLATFORM_DIR/skills/INDEX.md" ]; then
        log_info "Step 3: skills INDEX.md exists"
    else
        log_fail "Step 3: skills INDEX.md not found"
        return 1
    fi
    
    # Step 4: Check guard
    if [ -d "$PLATFORM_DIR/guard" ]; then
        log_info "Step 4: guard directory exists"
    else
        log_fail "Step 4: guard directory not found"
        return 1
    fi
    
    return 0
}

# ============================================================================
# Test 9: Agent can detect sandbox rules
# ============================================================================

test_agent_can_detect_sandbox_rules() {
    local skill_file="$SANDBOX_SKILLS_DIR/zai-sandbox-rules/SKILL.md"
    
    if [ -f "$skill_file" ]; then
        log_info "zai-sandbox-rules detected"
        
        # Check if it has trigger keywords
        if grep -q "bun run dev" "$skill_file"; then
            log_info "Trigger keyword 'bun run dev' found"
        else
            log_fail "Trigger keyword 'bun run dev' not found"
            return 1
        fi
        
        if grep -q "EADDRINUSE" "$skill_file"; then
            log_info "Trigger keyword 'EADDRINUSE' found"
        else
            log_fail "Trigger keyword 'EADDRINUSE' not found"
            return 1
        fi
        
        if grep -q "HMR" "$skill_file"; then
            log_info "Trigger keyword 'HMR' found"
        else
            log_fail "Trigger keyword 'HMR' not found"
            return 1
        fi
        
        return 0
    else
        log_fail "zai-sandbox-rules not detected"
        return 1
    fi
}

# ============================================================================
# Test 10: Agent can understand priority order
# ============================================================================

test_agent_can_understand_priority() {
    if [ -f "$PLATFORM_DIR/AGENT_RULES.md" ]; then
        log_info "AGENT_RULES.md exists"
        
        # Check if it mentions priority
        if grep -q "Priority" "$PLATFORM_DIR/AGENT_RULES.md"; then
            log_info "Priority order mentioned"
        else
            log_fail "Priority order not mentioned"
            return 1
        fi
        
        if grep -q "STD-" "$PLATFORM_DIR/AGENT_RULES.md"; then
            log_info "STD-* standards referenced"
        else
            log_fail "STD-* standards not referenced"
            return 1
        fi
        
        if grep -q "RULE-" "$PLATFORM_DIR/AGENT_RULES.md"; then
            log_info "RULE-* rules referenced"
        else
            log_fail "RULE-* rules not referenced"
            return 1
        fi
        
        return 0
    else
        log_fail "AGENT_RULES.md not found"
        return 1
    fi
}

# ============================================================================
# Main test runner
# ============================================================================

main() {
    echo "=========================================="
    echo "Z-ai-governance Sandbox Behavior Tests"
    echo "=========================================="
    echo ""
    echo "These tests simulate what an agent would experience in the sandbox."
    echo ""
    echo "Platform directory: $PLATFORM_DIR"
    echo "Skills directory: $SANDBOX_SKILLS_DIR"
    echo ""
    
    # Run tests
    run_test "Agent can read AGENT_RULES.md" test_agent_can_read_agent_rules
    run_test "Agent can load skills" test_agent_can_load_skills
    run_test "Agent can find zai-sandbox-rules" test_agent_can_find_sandbox_rules
    run_test "Agent can run verifiers" test_agent_can_run_verifiers
    run_test "Agent can check git status" test_agent_can_check_git_status
    run_test "Agent can read config" test_agent_can_read_config
    run_test "Agent can understand skill structure" test_agent_can_understand_skill_structure
    run_test "Agent can follow onboarding protocol" test_agent_can_follow_onboarding
    run_test "Agent can detect sandbox rules" test_agent_can_detect_sandbox_rules
    run_test "Agent can understand priority order" test_agent_can_understand_priority
    
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
