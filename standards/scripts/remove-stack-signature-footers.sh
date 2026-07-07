#!/usr/bin/env bash
# Remove cargo-cult `Built with:` footer from governance standards.
# Per DOC-002 §8 (clarified v2.3.2), Stack Signature applies only to
# application repository README/CHANGELOG — NOT to standards.
#
# Footer pattern to remove (at end of file):
#   ---
#
#   Built with: Next.js 16 + TypeScript + Tailwind CSS
#
# Optionally preceded by trailing blank lines.

set -euo pipefail

cd "$(dirname "$0")/.."
STANDARDS_DIR="standards"

# Files that HAVE the footer (17 total per audit, DOC-002 already done)
TARGETS=(
  A11Y-001-wcag-2-1-aa.md
  AGENT-001-subagent.md
  AGENT-002-orchestration.md
  ARCH-002-implementation-order.md
  DESIGN-001-design-system.md
  DOC-003-unicode-policy.md
  ENV-001-reproducibility.md
  ENV-002-zai-integration.md
  ERR-001-error-handling.md
  ERR-002-error-recovery.md
  FE-001-frontend.md
  GIT-001-github.md
  GIT-002-github-sandbox.md
  SEC-001-security-core.md
  SEC-002-security-extended.md
  TEST-001-testing.md
)

for f in "${TARGETS[@]}"; do
  file="$STANDARDS_DIR/$f"
  if [ ! -f "$file" ]; then
    echo "[skip] $f (not found)"
    continue
  fi
  if ! grep -q "^Built with: " "$file"; then
    echo "[skip] $f (no footer)"
    continue
  fi

  # Use perl for multiline regex: remove trailing `---\n\nBuilt with: ...\n`
  # at end of file, plus any trailing whitespace before EOF.
  perl -i -0pe 's/\n*---\n\nBuilt with: [^\n]+\n*\z/\n/' "$file"
  echo "[ok]   $f — footer removed"
done

echo ""
echo "=== Verification ==="
echo "Files still containing 'Built with:' in standards/standards/:"
grep -l "^Built with: " "$STANDARDS_DIR"/*.md 2>/dev/null || echo "  (none)"
