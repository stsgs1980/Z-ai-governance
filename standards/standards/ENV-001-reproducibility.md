# Standard: Reproducibility v2.1

> ID: STD-ENV-001
> Version: 2.1
> Level: **[C] Critical**
> Related: STD-ARCH-001 (architecture), STD-DOC-002 (markdown), STD-META-001 (ID system)

**`git clone` + `bun install` + `npx next dev -p 3000` = working application.**
Always. Everywhere. On any machine. Without exceptions.

**Note on package manager vs. runtime:** Use `bun install` for dependency installation (fast, reliable). Use `npx next dev` for dev server (not `bun run dev` -- the Bun wrapper for Next.js is unstable in sandbox environments). Use `bun run` for other scripts (lint, build, test).

---

## 1. Environment (L1)

Rules that ensure the project starts identically on any machine.

### 1.1 Environment Variables

**`.env.example` -- required.** Contains all variables with safe defaults. Secrets as placeholders. `.env` -- in gitignore.

**Runtime environment validation.** Critical variables checked at startup. Missing vars -- warning, not crash.

### 1.2 Path Rules

**No hardcoded personal paths.** Prohibited: developer-specific absolute paths and localhost URLs in source code. Environment-constant paths are allowed.

| Category                   | Examples                                           | Status         | Reason                                     |
| -------------------------- | -------------------------------------------------- | -------------- | ------------------------------------------ |
| Personal/developer paths   | `/home/<username>/`, `/Users/<name>/`, `C:\Users\` | **PROHIBITED** | Machine-specific, breaks on other machines |
| Localhost URLs in source   | `http://localhost:3000/api/...`                    | **PROHIBITED** | Use relative paths or XTransformPort       |
| Environment-constant paths | `/home/z/my-project/`, `/tmp/`                     | **ALLOWED**    | Identical on all Z.ai sandbox instances    |
| Runtime-resolved paths     | `path.resolve(process.cwd(), ...)`                 | **REQUIRED**   | Produces correct path on any machine       |

**Principle:** if the path is identical on ALL machines running this code, it is allowed. If the path is specific to ONE developer's machine, it is prohibited.

**Exception for Z.ai Sandbox** (see STD-ENV-002 section 3.1):

| Path                           | Allowed in                      | Reason                               |
| ------------------------------ | ------------------------------- | ------------------------------------ |
| `/home/z/my-project/`          | Shell commands, sandbox configs | Designated sandbox working directory |
| `/home/z/my-project/download/` | Output file writes              | Designated output directory          |
| `/tmp/zdev.log`                | Dev server log redirect         | System temp, not in source code      |
| `/tmp/`                        | Backup operations               | System temp, not committed to git    |

All other absolute paths remain prohibited. Outside Z.ai sandbox, this exception does not apply -- use relative paths exclusively.

```typescript
// PROHIBITED -- developer-specific path
fetch("http://localhost:3000/api/documents");

// REQUIRED -- relative path
fetch("/api/documents");
```

For cross-port services -- only `XTransformPort`:

```typescript
// PROHIBITED
fetch("http://localhost:3003/api/chat");

// REQUIRED
fetch("/api/chat?XTransformPort=3003");
```

### 1.3 Binary Files

**Binary files -- outside git.** Only source code and configuration in git. No `.db`, `.sqlite`, images in upload/, backups, logs, build artifacts.

---

## 2. Code (L2)

Rules that ensure the project runs without machine-specific dependencies.

### 2.1 Database Paths

**Relative path via `path.resolve()`:**

```typescript
const dbPath = resolve(process.cwd(), rawUrl.replace(/^file:/, ""));
if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
```

### 2.2 Database Permissions

**Safe permissions:** `0o755` for directories, `0o644` for files.

### 2.3 SQLite Constraints

**SQLite: no `mode: 'insensitive'`** -- SQLite does not support case-insensitive in Prisma. Use `contains`.

**SQLite: connection_limit=1** -- single connection to prevent concurrent write errors.

### 2.4 Database Migration Rules for Z.ai Sandbox

Schema changes must be reversible. Always test `prisma migrate reset` on a clean clone.

### 2.5 Dependency Hygiene

**No dead packages.** Each package in `dependencies` MUST be used in `src/`. Dead dependencies increase install time and attack surface.

**UI components:** `src/components/ui/` -- shadcn/ui library, excluded from dead file check. Each custom file in `src/components/codex/` MUST be imported in `src/`.

---

## 3. Delivery (L3)

Rules that ensure the project builds and deploys identically.

### 3.1 Version Control

**Default branch:** `main`. **Lockfile committed** (`bun.lock`). **Semantic Versioning** in `package.json`.

### 3.2 CI Pipeline (recommended)

`.github/workflows/ci.yml` -- lint, type-check, tests on every push/PR.

### 3.3 Dockerfile (recommended)

Production image based on `node:20-alpine`, multi-stage build, Bun runtime. No `.env`, `.db`, backups.

---

## 4. Process (L4)

Checklists that verify reproducibility before and after changes.

### 4.1 Checklist Before Each Commit

- [ ] `bun run lint` -- 0 errors
- [ ] No hardcoded personal paths in code (environment-constant paths allowed per STD-ENV-002 section 3.1)
- [ ] No unused packages / files
- [ ] Binary files not in git

### 4.2 Checklist Before Release

- [ ] All from commit checklist
- [ ] `.env.example` exists with all variables
- [ ] `bun install && npx next dev -p 3000` on clean clone -- works
- [ ] Tests (if present) -- pass without errors

### 4.3 Worklog

File `worklog.md` in root, append (don't overwrite).

---

## 5. Clean Repository Formula

```text
clone + install + dev = works
```

Everything violating this formula is a bug.

---

## 6. Version History

| Version | Date       | Changes                                                                                                                                                                                                                                                                                                                      |
| ------- | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2.0     | 2026-05-18 | Major restructuring: removed rules not directly ensuring reproducibility (dark theme, color palette, error handling, anti-fragility, dedup, push policy, deletion UI). These rules relocated to their domain-specific standards (STD-FE-001, STD-ERR-001, STD-GIT-001). Added Cross-References section. Renumbered sections. |
| 1.1     | 2026-05-18 | K-01 fix: replaced categorical absolute path ban with nuanced rule. Added Z.ai sandbox exception.                                                                                                                                                                                                                            |
| 1.0     | 2025-01    | Initial standard                                                                                                                                                                                                                                                                                                             |
| 2.1     | 2026-06    | File renamed from `ENV-001-reproducibility.md` to `ENV-001-reproducibility.md` (hyphen -> underscore) to match the naming convention used by all other standards. Added §6A Known Issues documenting REP-001 through REP-003.                                                                                                |
| 2.2     | 2026-07-06 | Removed Cross-References to deleted STD-ERR-002 and STD-TEST-001. Error recovery and testing concerns are now tracked under ERR-001 (recovery) and project-level test conventions respectively.                                                                                                                              |

---

## 6A. Known Issues and Proposed Solutions

This section documents discovered inconsistencies, missing content, and proposed corrections. Each issue has an ID, status, and proposed action. Issues resolved in the current version are marked `[RESOLVED]`; outstanding issues are marked `[OPEN]`.

### REP-001 `[RESOLVED in v2.1]` — Filename used hyphen instead of underscore

**Problem:** Prior to v2.1, the file was named `ENV-001-reproducibility.md` (with a hyphen). Every other standard file in the directory uses underscore separators (`GIT-001-github.md`, `DOC-002-markdown-standard.md`, `ERR-001-error-handling.md`, etc.). The single hyphenated filename was an outlier that broke grep/glob patterns assuming the underscore convention.

**Resolution:** File renamed to `ENV-001-reproducibility.md`. References in other standards updated:

- `ARCH-002-implementation-order.md` Group B table: `ENV-001-reproducibility.md` -> `ENV-001-reproducibility.md` (see ARCH-004).
- `ENV-002-zai-integration.md` §6 Related field: `REPRODUCIBILITY-STANDARD (STD-ENV-001)` -> `REPRODUCIBILITY_STANDARD (STD-ENV-001)` (see ZAI-001 in that file's Known Issues).

### REP-002 `[OPEN]` — §1.2 "Exception for Z.ai Sandbox" table duplicates STD-ENV-002 §3.1

**Problem:** §1.2 contains a table listing allowed sandbox paths (`/home/z/my-project/`, `/home/z/my-project/download/`, `/tmp/zdev.log`, `/tmp/`). The same table appears verbatim in `ENV-002-zai-integration.md` (STD-ENV-002) §3.1 "Absolute Path Exception". Neither document explicitly states which is the authoritative source. If one is updated and the other is not, they will silently drift.

**Proposed solution:** Designate one as authoritative and have the other cross-reference it. Recommendation: STD-ENV-002 §3.1 is the authoritative source (because the sandbox is STD-ENV-002's domain). STD-ENV-001 §1.2 should keep the table for self-contained readability but add a note: "Authoritative source: STD-ENV-002 §3.1. If the two tables diverge, STD-ENV-002 is correct." Alternatively, replace the STD-ENV-001 §1.2 table with a one-line cross-reference and remove the duplication entirely.

### REP-003 `[OPEN]` — Version reference to STD-ENV-002 in §1.2 is stale

**Problem:** §1.2 says "(see STD-ENV-002 section 3.1)". `ENV-002-zai-integration.md` is at v1.1, but this standard's §1.2 was written when STD-ENV-002 was at v1.1 already — so the reference is technically current. However, the table itself in STD-ENV-002 §3.1 says "REPRODUCIBILITY-STANDARD (STD-ENV-001 v1.1, L1 Path Rules)" — citing v1.1 for this standard, which is now v2.1. The cross-references between the two standards are therefore asymmetric.

**Proposed solution:** Update STD-ENV-002 §3.1 to reference STD-ENV-001 v2.1 (see ZAI-002 in that file's Known Issues). After both files are updated, the cross-references will be symmetric.

---

## 7. Cross-References

| Standard    | Relationship                                                                                                                                  |
| ----------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| STD-ERR-001 | Error handling: no internal error leaks (Section 5.2)                                                                                         |
| STD-SEC-001 | Security: env validation (Section 2.1), .env management (Section 2.2)                                                                         |
| STD-GIT-001 | Git: push policy (Section 5), .gitignore (Section 8), versioning (Section 6)                                                                  |
| STD-FE-001  | Frontend: auto-backup (Section 10.5), deduplication (Section 10.6)                                                                            |
| STD-ENV-002 | Z.ai sandbox: project directory (Section 3), absolute path exception (Section 3.1) — authoritative source for sandbox path table; see REP-002 |
