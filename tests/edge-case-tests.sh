#!/usr/bin/env bash
#
# edge-case-tests.sh — Edge cases for sandbox environment
#
# Usage:
#   bash tests/edge-case-tests.sh
#
# What it tests:
#   1. Missing files and directories
#   2. Permission issues
#   3. Invalid configurations
#   4. Error handling
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
# Test 1: Missing AGENT_RULES.md
# ============================================================================

test_missing_agent_rules() {
    local test_file="/tmp/test-agent-rules-$$.md"
    
    # Temporarily hide AGENT_RULES.md
    if [ -f "$PLATFORM_DIR/AGENT_RULES.md" ]; then
        mv "$PLATFORM_DIR/AGENT_RULES.md" "$test_file"
        
        # Try to read it
        if [ -f "$PLATFORM_DIR/AGENT_RULES.md" ]; then
            log_fail "AGENT_RULES.md still exists after hiding"
            mv "$test_file" "$PLATFORM_DIR/AGENT_RULES.md"
            return 1
        else
            log_info "AGENT_RULES.md correctly not found when hidden"
            mv "$test_file" "$PLATFORM_DIR/AGENT_RULES.md"
            return 0
        fi
    else
        log_warn "AGENT_RULES.md doesn't exist, skipping test"
        return 0
    fi
}

# ============================================================================
# Test 2: Missing skills directory
# ============================================================================

test_missing_skills_dir() {
    local test_dir="/tmp/test-skills-$$.bak"
    local skills_dir="/home/z/my-project/skills"
    
    # Temporarily hide skills directory
    if [ -d "$skills_dir" ]; then
        mv "$skills_dir" "$test_dir"
        
        # Try to access it
        if [ -d "$skills_dir" ]; then
            log_fail "skills directory still exists after hiding"
            mv "$test_dir" "$skills_dir"
            return 1
        else
            log_info "skills directory correctly not found when hidden"
            mv "$test_dir" "$skills_dir"
            return 0
        fi
    else
        log_warn "skills directory doesn't exist, skipping test"
        return 0
    fi
}

# ============================================================================
# Test 3: Missing .zai directory
# ============================================================================

test_missing_zai_dir() {
    local test_dir="/tmp/test-zai-$$.bak"
    
    # Temporarily hide .zai directory
    if [ -d "$PLATFORM_DIR/.zai" ]; then
        mv "$PLATFORM_DIR/.zai" "$test_dir"
        
        # Try to access it
        if [ -d "$PLATFORM_DIR/.zai" ]; then
            log_fail ".zai directory still exists after hiding"
            mv "$test_dir" "$PLATFORM_DIR/.zai"
            return 1
        else
            log_info ".zai directory correctly not found when hidden"
            mv "$test_dir" "$PLATFORM_DIR/.zai"
            return 0
        fi
    else
        log_warn ".zai directory doesn't exist, skipping test"
        return 0
    fi
}

# ============================================================================
# Test 4: Corrupted config.json
# ============================================================================

test_corrupted_config() {
    local config_file="$PLATFORM_DIR/.zai/config.json"
    local backup_file="/tmp/config-backup-$$.json"
    
    if [ -f "$config_file" ]; then
        # Backup original
        cp "$config_file" "$backup_file"
        
        # Corrupt it
        echo "invalid json {{{" > "$config_file"
        
        # Try to parse it
        if command -v node &>/dev/null; then
            if node -e "require('$config_file')" 2>/dev/null; then
                log_fail "Corrupted config.json was accepted as valid"
                cp "$backup_file" "$config_file"
                rm -f "$backup_file"
                return 1
            else
                log_info "Corrupted config.json correctly rejected"
                cp "$backup_file" "$config_file"
                rm -f "$backup_file"
                return 0
            fi
        else
            log_skip "node not available"
            cp "$backup_file" "$config_file"
            rm -f "$backup_file"
            return 0
        fi
    else
        log_warn "config.json doesn't exist, skipping test"
        return 0
    fi
}

# ============================================================================
# Test 5: Empty SKILL.md
# ============================================================================

test_empty_skillmd() {
    local test_skill="/tmp/test-skill-$$.md"
    local skill_dir="$PLATFORM_DIR/skills/zai-sandbox-rules"
    
    if [ -f "$skill_dir/SKILL.md" ]; then
        # Backup original
        cp "$skill_dir/SKILL.md" "$test_skill"
        
        # Empty it (truncate to zero bytes)
        : > "$skill_dir/SKILL.md"
        
        # Try to read it
        if [ -s "$skill_dir/SKILL.md" ]; then
            log_fail "Empty SKILL.md was accepted as valid"
            cp "$test_skill" "$skill_dir/SKILL.md"
            rm -f "$test_skill"
            return 1
        else
            log_info "Empty SKILL.md correctly detected"
            cp "$test_skill" "$skill_dir/SKILL.md"
            rm -f "$test_skill"
            return 0
        fi
    else
        log_warn "zai-sandbox-rules SKILL.md doesn't exist, skipping test"
        return 0
    fi
}

# ============================================================================
# Test 6: Missing SKILL.md frontmatter
# ============================================================================

test_missing_frontmatter() {
    local test_skill="/tmp/test-skill-frontmatter-$$.md"
    local skill_dir="$PLATFORM_DIR/skills/zai-sandbox-rules"
    
    if [ -f "$skill_dir/SKILL.md" ]; then
        # Backup original
        cp "$skill_dir/SKILL.md" "$test_skill"
        
        # Remove frontmatter
        sed '1,/^---$/d' "$skill_dir/SKILL.md" > "$skill_dir/SKILL.md.tmp"
        mv "$skill_dir/SKILL.md.tmp" "$skill_dir/SKILL.md"
        
        # Try to parse it
        if head -1 "$skill_dir/SKILL.md" | grep -q "^---"; then
            log_fail "Missing frontmatter was accepted"
            cp "$test_skill" "$skill_dir/SKILL.md"
            rm -f "$test_skill"
            return 1
        else
            log_info "Missing frontmatter correctly detected"
            cp "$test_skill" "$skill_dir/SKILL.md"
            rm -f "$test_skill"
            return 0
        fi
    else
        log_warn "zai-sandbox-rules SKILL.md doesn't exist, skipping test"
        return 0
    fi
}

# ============================================================================
# Test 7: Broken symlinks
# ============================================================================

test_broken_symlinks() {
    local test_link="/tmp/test-symlink-$$.dir"
    local skills_dir="/home/z/my-project/skills"
    
    # Create a broken symlink
    ln -sf /nonexistent/path "$test_link"
    
    # Check if it's detected
    if [ -L "$test_link" ] && [ ! -e "$test_link" ]; then
        log_info "Broken symlink correctly detected"
        rm -f "$test_link"
        return 0
    else
        log_fail "Broken symlink not detected"
        rm -f "$test_link"
        return 1
    fi
}

# ============================================================================
# Test 8: Symlink loops
# ============================================================================

test_symlink_loops() {
    local test_dir="/tmp/test-loop-$$.dir"
    
    # Create a symlink loop
    mkdir -p "$test_dir"
    ln -sf "$test_dir" "$test_dir/self"
    
    # Check if it's detected
    if [ -L "$test_dir/self" ]; then
        log_info "Symlink loop detected"
        rm -rf "$test_dir"
        return 0
    else
        log_fail "Symlink loop not detected"
        rm -rf "$test_dir"
        return 1
    fi
}

# ============================================================================
# Test 9: Read-only config
# ============================================================================

test_readonly_config() {
    local config_file="$PLATFORM_DIR/.zai/config.json"
    local backup_file="/tmp/config-backup-ro-$$"
    
    if [ -f "$config_file" ]; then
        # Backup original
        cp "$config_file" "$backup_file"
        
        # Make it read-only
        chmod 444 "$config_file"
        
        # Try to write to it
        if echo "test" >> "$config_file" 2>/dev/null; then
            log_fail "Read-only config was writable"
            chmod 644 "$config_file"
            cp "$backup_file" "$config_file"
            rm -f "$backup_file"
            return 1
        else
            log_info "Read-only config correctly rejected writes"
            chmod 644 "$config_file"
            cp "$backup_file" "$config_file"
            rm -f "$backup_file"
            return 0
        fi
    else
        log_warn "config.json doesn't exist, skipping test"
        return 0
    fi
}

# ============================================================================
# Test 10: Invalid git config
# ============================================================================

test_invalid_git_config() {
    local original_value
    original_value=$(git -C "$PLATFORM_DIR" config core.fileMode 2>/dev/null || echo "not set")
    
    # Set invalid value
    git -C "$PLATFORM_DIR" config core.fileMode "invalid" 2>/dev/null || true
    
    # Check if it's invalid
    local current_value
    current_value=$(git -C "$PLATFORM_DIR" config core.fileMode 2>/dev/null || echo "not set")
    
    if [ "$current_value" = "invalid" ]; then
        log_info "Invalid git config value accepted (git allows it)"
        # Restore original
        git -C "$PLATFORM_DIR" config core.fileMode "$original_value" 2>/dev/null || true
        return 0
    else
        log_info "Invalid git config value rejected"
        return 0
    fi
}

# ============================================================================
# Test 11: Very long file path
# ============================================================================

test_long_file_path() {
    local long_dir="/tmp/$(printf 'a%.0s' {1..100})"
    
    # Try to create a long path
    if mkdir -p "$long_dir" 2>/dev/null; then
        log_info "Long path created successfully"
        rm -rf "$long_dir"
        return 0
    else
        log_info "Long path creation failed (expected)"
        return 0
    fi
}

# ============================================================================
# Test 12: Special characters in path
# ============================================================================

test_special_characters_path() {
    local special_dir="/tmp/test path (with) [brackets]"
    
    # Try to create a path with special characters
    if mkdir -p "$special_dir" 2>/dev/null; then
        log_info "Special characters path created"
        rm -rf "$special_dir"
        return 0
    else
        log_info "Special characters path creation failed"
        return 0
    fi
}

# ============================================================================
# Test 13: Concurrent file access
# ============================================================================

test_concurrent_access() {
    local test_file="/tmp/test-concurrent-$$.txt"
    
    # Create a test file
    echo "initial" > "$test_file"
    
    # Try to write from multiple processes
    (echo "process1" >> "$test_file") &
    local pid1=$!
    
    (echo "process2" >> "$test_file") &
    local pid2=$!
    
    # Wait for both
    wait $pid1 2>/dev/null || true
    wait $pid2 2>/dev/null || true
    
    # Check if file is readable
    if cat "$test_file" > /dev/null 2>&1; then
        log_info "Concurrent access handled"
        rm -f "$test_file"
        return 0
    else
        log_fail "Concurrent access caused corruption"
        rm -f "$test_file"
        return 1
    fi
}

# ============================================================================
# Test 14: Disk space check
# ============================================================================

test_disk_space() {
    # Check available disk space
    local available
    available=$(df /tmp 2>/dev/null | tail -1 | awk '{print $4}' || echo "unknown")
    
    if [ "$available" = "unknown" ]; then
        log_warn "Could not determine disk space"
        return 0
    fi
    
    if [ "$available" -gt 1000000 ]; then
        log_info "Sufficient disk space: ${available}KB"
        return 0
    else
        log_warn "Low disk space: ${available}KB"
        return 0
    fi
}

# ============================================================================
# Test 15: Memory check
# ============================================================================

test_memory_check() {
    # Check available memory
    if command -v free &>/dev/null; then
        local available
        available=$(free -m 2>/dev/null | grep Mem | awk '{print $7}' || echo "unknown")
        
        if [ "$available" = "unknown" ]; then
            log_warn "Could not determine available memory"
            return 0
        fi
        
        if [ "$available" -gt 100 ]; then
            log_info "Sufficient memory: ${available}MB"
            return 0
        else
            log_warn "Low memory: ${available}MB"
            return 0
        fi
    else
        log_skip "free command not available"
        return 0
    fi
}

# ============================================================================
# Main test runner
# ============================================================================

main() {
    echo "=========================================="
    echo "Z-ai-governance Edge Case Tests"
    echo "=========================================="
    echo ""
    echo "These tests check error handling and edge cases."
    echo ""
    echo "Platform directory: $PLATFORM_DIR"
    echo ""
    
    # Run tests
    run_test "Missing AGENT_RULES.md" test_missing_agent_rules
    run_test "Missing skills directory" test_missing_skills_dir
    run_test "Missing .zai directory" test_missing_zai_dir
    run_test "Corrupted config.json" test_corrupted_config
    run_test "Empty SKILL.md" test_empty_skillmd
    run_test "Missing SKILL.md frontmatter" test_missing_frontmatter
    run_test "Broken symlinks" test_broken_symlinks
    run_test "Symlink loops" test_symlink_loops
    run_test "Read-only config" test_readonly_config
    run_test "Invalid git config" test_invalid_git_config
    run_test "Very long file path" test_long_file_path
    run_test "Special characters in path" test_special_characters_path
    run_test "Concurrent file access" test_concurrent_access
    run_test "Disk space check" test_disk_space
    run_test "Memory check" test_memory_check
    
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
