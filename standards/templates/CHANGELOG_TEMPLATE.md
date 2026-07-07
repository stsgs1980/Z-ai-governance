# Changelog Template v1.0

> ID: STD-DOC-006
> Version: 1.0
> Level: **[W] Warning**
> Related: RULE-VERSION-013, Keep a Changelog

This template defines the structure for project `CHANGELOG.md` files.

---

## 1. Purpose

Changelog documents all notable changes to the project.
Format follows [Keep a Changelog](https://keepachangelog.com/).

---

## 2. Rules

| Rule                 | Description                                              |
| -------------------- | -------------------------------------------------------- |
| User-facing          | Write for users, not developers                          |
| One entry per change | Each notable change gets its own bullet                  |
| Versioned            | Group changes by version                                 |
| Date-stamped         | Each version has a release date                          |
| Categorized          | Use standard categories (Added, Changed, Fixed, Removed) |

---

## 3. File Structure

```markdown
# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/)
and this project adheres to [Semantic Versioning](https://semver.org/).

---

## [version] - YYYY-MM-DD

### Added

- New feature description

### Changed

- Change description

### Fixed

- Bug fix description

### Removed

- Removed feature description

---

## [previous-version] - YYYY-MM-DD

...
```

---

## 4. Categories

| Category   | When to use                       |
| ---------- | --------------------------------- |
| Added      | New features                      |
| Changed    | Changes to existing functionality |
| Deprecated | Features that will be removed     |
| Fixed      | Bug fixes                         |
| Removed    | Removed features                  |
| Security   | Vulnerability fixes               |

---

## 5. Version Format

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** - incompatible API changes
- **MINOR** - backwards-compatible functionality
- **PATCH** - backwards-compatible bug fixes

---

## 6. Example

```markdown
## [1.2.0] - 2026-07-04

### Added

- Template for worklog files (STD-DOC-005)
- Template for changelog files (STD-DOC-006)

### Changed

- Updated snapshot normalization to use greedy regex

### Fixed

- Cross-platform path comparison in verify-id-graph.js

---

## [1.1.0] - 2026-07-02

### Changed

- Renamed ESLint rule `no-unicode-policy` to `unicode-policy`

### Fixed

- CRLF line endings broke blockquote parsing on Windows
```

---

## 7. Anti-patterns

- [FAIL] Using emoji instead of text tags
- [FAIL] Mixing languages within same entry
- [FAIL] Technical jargon without explanation
- [FAIL] Missing version numbers or dates
- [FAIL] Combining multiple changes in one bullet
