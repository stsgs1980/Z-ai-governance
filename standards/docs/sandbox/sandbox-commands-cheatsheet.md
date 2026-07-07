# Z.ai Sandbox Command Reference

> **Platform:** Linux x86_64 (Debian-based)  
> **Kernel:** 5.10.134  
> **Shell:** GNU Bash 5.2.37  
> **Total commands:** 1321  
> **Date compiled:** 2026-05-13

---

## How to Use This Cheatsheet

This cheatsheet is split into 4 thematic sub-files. Each sub-file is loaded on demand — **do NOT load all 4 into context at once**. Use the table below to pick the file you need, then open it.

---

## File Index

| File | Theme | Sections | When to load |
|------|-------|----------|--------------|
| [`sandbox-commands-file.md`](sandbox-commands-file.md) | File, Text & Archiving | §1-5 | File ops, viewing, grep/sed/awk, archives |
| [`sandbox-commands-system.md`](sandbox-commands-system.md) | System, Network & Services | §6-10 | Network, processes, users, disks, systemd |
| [`sandbox-commands-dev.md`](sandbox-commands-dev.md) | Development Languages & Git | §11-16 | Python, Node, Java, Perl, C/C++, Git |
| [`sandbox-commands-media.md`](sandbox-commands-media.md) | Documents, Media, Data, Web & Misc | §17-25 | Docs, graphics, geodata, web, DB, editors, Z.ai |

---

## Section Index (quick lookup)

| # | Section | Sub-file |
|---|---------|----------|
| 1 | File Operations | [`sandbox-commands-file.md`](sandbox-commands-file.md) |
| 2 | Viewing and Searching Files | [`sandbox-commands-file.md`](sandbox-commands-file.md) |
| 3 | Text Search and Filtering | [`sandbox-commands-file.md`](sandbox-commands-file.md) |
| 4 | Text Processing | [`sandbox-commands-file.md`](sandbox-commands-file.md) |
| 5 | Archiving and Compression | [`sandbox-commands-file.md`](sandbox-commands-file.md) |
| 6 | Network and Internet | [`sandbox-commands-system.md`](sandbox-commands-system.md) |
| 7 | System and Processes | [`sandbox-commands-system.md`](sandbox-commands-system.md) |
| 8 | Users and Permissions | [`sandbox-commands-system.md`](sandbox-commands-system.md) |
| 9 | Disks and File Systems | [`sandbox-commands-system.md`](sandbox-commands-system.md) |
| 10 | System Services (systemd) | [`sandbox-commands-system.md`](sandbox-commands-system.md) |
| 11 | Python and Ecosystem | [`sandbox-commands-dev.md`](sandbox-commands-dev.md) |
| 12 | Node.js / JavaScript / TypeScript | [`sandbox-commands-dev.md`](sandbox-commands-dev.md) |
| 13 | Java | [`sandbox-commands-dev.md`](sandbox-commands-dev.md) |
| 14 | Perl | [`sandbox-commands-dev.md`](sandbox-commands-dev.md) |
| 15 | C/C++ and Build Tools | [`sandbox-commands-dev.md`](sandbox-commands-dev.md) |
| 16 | Git - Version Control | [`sandbox-commands-dev.md`](sandbox-commands-dev.md) |
| 17 | Documents and Conversion | [`sandbox-commands-media.md`](sandbox-commands-media.md) |
| 18 | Graphics, Video, Images | [`sandbox-commands-media.md`](sandbox-commands-media.md) |
| 19 | Maps and Geodata (GDAL/OGR) | [`sandbox-commands-media.md`](sandbox-commands-media.md) |
| 20 | Data and Formats | [`sandbox-commands-media.md`](sandbox-commands-media.md) |
| 21 | Web Servers and API | [`sandbox-commands-media.md`](sandbox-commands-media.md) |
| 22 | Databases | [`sandbox-commands-media.md`](sandbox-commands-media.md) |
| 23 | Editors | [`sandbox-commands-media.md`](sandbox-commands-media.md) |
| 24 | Special Z.ai Commands | [`sandbox-commands-media.md`](sandbox-commands-media.md) |
| 25 | Other Useful Utilities | [`sandbox-commands-media.md`](sandbox-commands-media.md) |

---

## When to Load Which File

| Symptom / Task | Load |
|----------------|------|
| Forgotten file/`ls`/`cp`/`rm` flag | `sandbox-commands-file.md` |
| Need to grep/sed/awk through logs | `sandbox-commands-file.md` |
| Networking / port / process diagnostics | `sandbox-commands-system.md` |
| User/permission/sudo issue | `sandbox-commands-system.md` |
| Python/pip/pytest question | `sandbox-commands-dev.md` |
| Node/npm/bun/tsc/Next.js CLI | `sandbox-commands-dev.md` |
| Git command lookup | `sandbox-commands-dev.md` |
| Need to convert PDF/Markdown/LaTeX | `sandbox-commands-media.md` |
| ImageMagick / ffmpeg | `sandbox-commands-media.md` |
| SQLite/Postgres/MongoDB CLI | `sandbox-commands-media.md` |
| Z.ai-specific (FC_CONTAINER_ID, init script, .zscripts) | `sandbox-commands-media.md` |

---

## Related Files

- [`sandbox-guide.md`](sandbox-guide.md) — high-level sandbox usage guide
- [`sandbox-hooks-cookbook.md`](sandbox-hooks-cookbook.md) — React hooks + AI integration
- [`sandbox-subagents-architecture.md`](sandbox-subagents-architecture.md) — subagent orchestration
- [`sandbox-migration.md`](sandbox-migration.md) — migration notes

---

*Reference compiled for Z.ai sandbox. Total of 1321 commands available across 25 categories, split into 4 thematic sub-files for on-demand loading.*
