# CHANGELOG

## Changelog for Z-ai-guard

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/) and this project adheres to [Semantic Versioning](https://semver.org/).

---

## [1.1.0] - 2026-07-02

### Added
- `eslint.config.js`, `eslint-rules/unicode-policy.js`, `eslint-rules/raw-text-parser.js`
- `.github/workflows/lint-markdown.yml` (CI workflow, not pushed to remote)
- `.gitignore` (node_modules/)
- `package.json` (eslint devDependency)
- `worklog.md` and `CHANGELOG.md`

### Changed
- Bulk Unicode replacement: `->` (15), `<=` (4) across 3 files
  - `rules/INDEX.md`, `instructions/PROC-LINECOUNT-004.md`, `instructions/PROC-COCHANGE-003.md`

### Fixed
- `scripts/co-change-check.sh`: replaced hardcoded Linux path with auto-detection via `BASH_SOURCE`
- `scripts/co-change-check.sh`: CRLF -> LF line endings (bash compatibility)

---

## [1.0.0] - 2026-07-02

### Added
- worklog.md and CHANGELOG.md files for compliance with RULE-MONOLITH-010
- Basic structure for change logging

---

## [0.9.0] - 2026-07-01

### Added
- Initial Z-ai-guard module for Z-ai projects
