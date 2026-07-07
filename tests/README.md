# Z-ai-governance Tests

Comprehensive test suite for Z-ai-governance components.

## Test Files

| File                          | Purpose                     | Tests    |
| ----------------------------- | --------------------------- | -------- |
| `sandbox-integration-test.sh` | Core functionality tests    | 12 tests |
| `edge-case-tests.sh`          | Try to break the system     | 12 tests |
| `sandbox-behavior-test.sh`    | Agent experience simulation | 10 tests |

## Running Tests

### Prerequisites

- Bash shell
- Git
- Node.js (for verifier tests)
- Internet connection (for bootstrap tests)

### Run All Tests

```bash
# From repository root
bash tests/sandbox-integration-test.sh
bash tests/edge-case-tests.sh
bash tests/sandbox-behavior-test.sh
```

### Run Individual Tests

```bash
# Integration tests only
bash tests/sandbox-integration-test.sh

# Edge case tests only
bash tests/edge-case-tests.sh

# Behavior tests only
bash tests/sandbox-behavior-test.sh
```

## Test Coverage

### sandbox-integration-test.sh

Tests core functionality:

1. Bootstrap clean run
2. Bootstrap idempotency (run twice)
3. Skills symlink validation
4. Governance system (.zai/)
5. Verifiers
6. Missing dependencies
7. No git
8. Existing Z-ai-governance
9. Skills directory conflicts
10. Bootstrap output format
11. Git config changes
12. Symlink targets

### edge-case-tests.sh

Tries to break the system:

1. Read-only filesystem
2. No write permission to skills dir
3. Corrupted git repo
4. No network (simulated)
5. Disk full (simulated)
6. Very long paths
7. Special characters in path
8. Concurrent runs
9. Symlink loops
10. Broken symlinks
11. Error messages quality
12. Cleanup on failure

### sandbox-behavior-test.sh

Simulates agent experience:

1. Agent can read AGENT_RULES.md
2. Agent can load skills
3. Agent can find zai-sandbox-rules
4. Agent can run verifiers
5. Agent can check git status
6. Agent can read config
7. Agent can understand skill structure
8. Agent can follow onboarding protocol
9. Agent can detect sandbox rules
10. Agent can understand priority order

## Test Environment

Tests create temporary directories in `/tmp/` and clean up after themselves. Each test is independent and can run in isolation.

## Interpreting Results

- `[PASS]` - Test passed
- `[FAIL]` - Test failed (needs investigation)
- `[WARN]` - Warning (not critical)
- `[SKIP]` - Test skipped (dependency not available)

## Adding New Tests

1. Create a new test function in the appropriate test file
2. Follow the naming convention: `test_<description>()`
3. Use `log_info`, `log_success`, `log_fail`, `log_warn` for output
4. Return 0 for success, 1 for failure
5. Add the test to the `main()` function using `run_test`

## Notes

- Edge case tests intentionally create error conditions
- Run only in test environments
- Tests are designed to be non-destructive
- All temporary files are cleaned up automatically
