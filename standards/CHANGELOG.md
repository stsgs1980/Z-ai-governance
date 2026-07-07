# CHANGELOG

## Changelog for Z-ai-standards

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/) and this project adheres to [Semantic Versioning](https://semver.org/).

---

## [1.1.0] - 2026-07-02

### Added

- `standards/META-002-language-policy.md` (STD-META-002 v1.0, level [C] Critical)
  - Documentation, commits, branches, code, user communication, error messages
  - Added to ARCH-002 at installation position #2 (v2.6 -> v2.7)
- `.husky/pre-commit` with lint-staged for .md linting
- `eslint.config.js`, `eslint-rules/unicode-policy.js`, `eslint-rules/raw-text-parser.js`
- `§8A Known Issues` section to META-002 (documents G03 cycle fix)
- `worklog.md` and `CHANGELOG.md`
- Cross-references to STD-META-002 in GIT-001, AGENT-001, DOC-002

### Changed

- Renamed ESLint rule `no-unicode-policy` -> `unicode-policy` across all documentation
- ARCH-002 v2.6 -> v2.7: META-002 added as position #2 in installation order
- "20 normative standards" -> "21" in ARCH-002
- Bulk Unicode/emoji replacement across 14 files (225 replacements):
  - Arrows: `->` (101), `<->` (11), `<=` (11), `>=` (2), `!=` (1)
  - Text tags: `[OK]` (23), `[FAIL]` (26)
- Updated snapshot baseline: 66 IDs (was 65), 129 edges (was 125), 0 warnings

### Fixed

- `lib/parsers.js` `parseYAMLFrontmatter`: regex `/^---\n/` -> `/^---\r?\n/` (CRLF on Windows)
- `lib/parsers.js` `parseBlockquoteHeader`: added `\r` stripping on split lines
- `lib/file-scanner.js`: `path.relative()` backslashes normalized to forward slashes (Windows)
- `lib/file-scanner.js`: added `SUBMODULE_DIRS` to prevent platform scanning into submodules (G01 duplicate IDs)
- `scripts/verify-standards.js` V10: template block regex added `\r?\n` (CRLF)
- `scripts/graph-deps.sh`: `.graph-transform.js` -> `.graph-transform.cjs` (ESM compatibility)
- G03 cycle: META-002 Related trimmed to META-001 only (removed bidirectional edges)
- Restored DOC-003 Forbidden Patterns table examples after bulk replacement

---

## [1.0.0] - 2026-07-02

### Added

- worklog.md and CHANGELOG.md files for compliance with RULE-DOC-010
- Basic structure for change logging

---

## [0.9.0] - 2026-07-01

### Added

- Initial Z-ai-standards module for Z-ai projects
