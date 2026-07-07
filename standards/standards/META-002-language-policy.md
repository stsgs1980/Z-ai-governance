# Standard: Language Policy v1.0 (EN)

> ID: STD-META-002
> Version: 1.0
> Level: **[C] Critical**
> Last Updated: 2026-07
> Related: STD-META-001 (ID system)

---

## 1. Purpose

This standard defines the language policy for all artifacts in the Z-ai ecosystem. It answers three questions that were previously resolved ad-hoc or not at all:

1. **What language are artifacts written in?** Documentation, commit messages, code comments, variable names, error messages.
2. **What language is used for user communication?** Chat responses, subagent prompts, WORKLOG entries.
3. **What are the exceptions?** Localization, i18n, project-specific overrides.

Without this standard, language choices are inconsistent: some documentation is in Russian, some in English; commit messages mix languages; subagent prompts are undefined. This creates friction for contributors and breaks automated tooling that assumes English (e.g., commit linting, search indexing).

---

## 2. Scope

This standard applies to:

| Artifact | Language Rule | Enforcement |
|----------|--------------|-------------|
| Documentation (`.md` files) | English | STD-DOC-002, ESLint |
| Commit messages | English | GIT-001, commit hooks |
| Branch names | English | GIT-001 |
| Subagent prompts and results | English | AGENT-001 |
| WORKLOG entries | English | AGENT-001, AGENT-002 |
| Code comments | English | ESLint (recommended) |
| Variable/function names | English | ESLint (recommended) |
| User-facing error messages | English (localizable) | ERR-001 |
| API responses | English | ERR-001, FE-001 |

This standard does NOT apply to:

- User communication in chat (see Section 3.4)
- Localized content (see Section 4)

---

## 3. Rules

### 3.1 Documentation Language

All documentation files (`.md`) MUST be written in English.

**Rationale:** Documentation is consumed by all contributors and AI agents. English is the lingua franca of the ecosystem. Mixed-language documentation breaks search, onboarding, and automated processing.

**Examples:**

```text
[OK]   ## Installation
[FAIL] ## Установка
[OK]   Run `npm install` to get started.
[FAIL] Запустите `npm install` для начала.
```

### 3.2 Commit Messages

All commit messages MUST be in English (per GIT-001 section 1.4).

**Format:** Conventional Commits with English description.

```text
[OK]   feat(ui): add hero-section with 3 variants
[FAIL] feat(ui): добавил hero-section с 3 вариантами
[OK]   fix(theme): correct contrast ratio for muted-foreground
[FAIL] fix(theme): исправил контраст для muted-foreground
```

### 3.3 Branch Names

All branch names MUST be in English (per GIT-001 section 2.1).

```text
[OK]   feat/wcag-contrast-audit
[FAIL] feat/проверка-контраста
[OK]   fix/tabs-keyboard-nav
[FAIL] fix/фикс-клавиатура
```

### 3.4 User Communication

Communication with the user (chat responses, clarifying questions) MAY be in any language. The AI agent SHOULD match the user's language.

**Rationale:** User communication is a dialogue, not an artifact. Forcing English on a Russian-speaking user creates friction without technical benefit. The language of the *response* does not affect code quality, documentation consistency, or tooling.

**Rules:**

- AI agent matches the user's language (Russian user -> Russian response)
- Technical terms may remain in English (e.g., "commit", "branch", "PR") when no established translation exists
- If the user switches language mid-conversation, the agent follows

### 3.5 Code Comments

Code comments SHOULD be in English.

**Rationale:** Comments are read by all contributors and AI agents. English comments ensure universal readability. However, this is a recommendation [W], not a hard requirement [C], because:

- Legacy code may have comments in other languages
- Inline comments explaining business logic to a specific team may be more effective in the team's language
- Automated enforcement is impractical (no reliable comment-language linter)

**Examples:**

```typescript
[OK]   // Calculate discount based on user tier
[OK]   // Скидка зависит от уровня пользователя (if team is Russian-speaking)
[FAIL] // skidka zavisit ot urovnya (transliteration is worse than either language)
```

### 3.6 Variable and Function Names

Variable and function names MUST be in English.

**Rationale:** Names are part of the API surface. Non-English names break IDE autocompletion, search, and onboarding for non-native speakers.

```text
[OK]   calculateDiscount, getUserById, isValid
[FAIL] skidka, poluchitPolzovatelya, yavlyaetsyaValidnym
```

### 3.7 Error Messages

Error messages shown to users SHOULD be in English. If the application supports localization, error messages MUST use localization keys (see Section 4).

**Rationale:** Error messages appear in logs, API responses, and monitoring tools. English error messages are universally parseable. Localized user-facing messages are handled via i18n frameworks, not hardcoded strings.

```typescript
[OK]   throw new NotFoundError('User not found')
[OK]   throw new NotFoundError(t('error.user_not_found'))  // i18n key
[FAIL] throw new NotFoundError('Пользователь не найден')   // hardcoded Russian
```

---

## 4. Exceptions

### 4.1 Localization (i18n)

Applications that support multiple languages MAY display localized content to users. The following rules apply:

| Artifact | Localization allowed? | Requirement |
|----------|----------------------|-------------|
| UI text (buttons, labels, headings) | Yes | Use i18n framework (next-intl, react-intl, etc.) |
| Error messages shown to user | Yes | Use i18n keys, not hardcoded strings |
| API error codes | No | Always English (e.g., `VALIDATION_ERROR`) |
| Log messages | No | Always English (for log aggregation) |
| Documentation | No | Always English |
| Code comments | No | Always English (recommended) |

### 4.2 Project-Specific Overrides

A project MAY declare a different language policy for internal artifacts (code comments, commit messages) if:

1. The entire team shares the same language
2. The project is not intended for external contribution
3. The override is documented in the project's README

**Example:**

```markdown
## Language Policy

This project uses Russian for code comments and commit messages
(internal team only). Documentation remains in English per STD-META-002.
```

**Scope:** Project-specific overrides apply ONLY to the project that declares them. They do not propagate to other projects in the ecosystem.

### 4.3 Legacy Code

Legacy code with comments or variable names in other languages is exempt from Sections 3.5 and 3.6. However:

- New code in the same file MUST follow the standard
- Refactoring of legacy code SHOULD translate names and comments to English
- Exceptions MUST NOT be introduced (no new Russian comments in English codebases)

---

## 5. Enforcement

### 5.1 Automated Checks

| Rule | Tool | Severity | Enforced by |
|------|------|----------|-------------|
| Documentation language | ESLint (no automated check) | Manual review | Code review |
| Commit message language | commitlint | [C] | Pre-commit hook |
| Branch name language | Manual review | [C] | Code review |
| Variable/function names | ESLint (no automated check) | Manual review | Code review |
| Error message format | ESLint (no automated check) | Manual review | Code review |

### 5.2 Code Review Policy

Language violations are grounds for **Request Changes** in code review:

| Violation | Action |
|-----------|--------|
| Russian commit message | Request change to English |
| Russian documentation | Request change to English |
| Russian variable names | Request change to English |
| Hardcoded localized error message | Request i18n key |
| Russian code comment (new code) | Request change to English (or document exception per §4.2) |

### 5.3 Escalation

If a contributor disagrees with a language review comment:

1. The contributor may invoke Section 4.2 (project-specific override) if applicable
2. If no override exists, the Tech Lead decides
3. The decision is recorded in the project's decisions log

---

## 6. Checklist

### Before Commit

- [ ] Commit message in English
- [ ] Branch name in English
- [ ] No hardcoded localized strings in code (use i18n keys)

### Before Merge

- [ ] Documentation in English
- [ ] Code comments in English (or documented exception per Section 4.2)
- [ ] Variable/function names in English
- [ ] Error messages use i18n keys (if app supports localization)

---

## 7. Cross-References

| Standard | Relationship |
|----------|-------------|
| STD-META-001 | ID System: IDs are always in English (by convention, not by this standard) |
| STD-GIT-001 | GitHub: commit messages and branch names in English (Section 1.4, 2.1) |
| STD-DOC-002 | Markdown: documentation in English |
| STD-AGENT-001 | Subagent: prompts, results, and WORKLOG in English |
| STD-AGENT-002 | Orchestration: task descriptions in English |
| STD-ERR-001 | Error Handling: error codes in English, messages localizable |
| STD-FE-001 | Frontend: UI text may be localized via i18n |

---

## 8A. Known Issues

This section documents discovered inconsistencies, missing content, and proposed corrections. Each issue has an ID, status, and proposed action. Issues resolved in the current version are marked `[RESOLVED]`; outstanding issues are marked `[OPEN]`.

### META-002-001 `[OPEN]` — Related field trimmed to break G03 cycle

**Problem:** STD-META-002 originally listed STD-GIT-001, STD-DOC-002, and STD-AGENT-001 in its `Related:` field. These created bidirectional edges (the targets also referenced META-002), forming a strongly connected component of 5 standards detected by G03 (cycle in Related graph).

**Resolution:** Removed STD-GIT-001, STD-DOC-002, and STD-AGENT-001 from the `Related:` field. The cross-references remain in the body text (Section 7) but are no longer graph edges. Only STD-META-001 remains as a dependency edge.

---

## 9. Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-07 | Initial version: documentation, commits, branches, code, user communication, error messages, exceptions, enforcement |

---

**Document complies with MARKDOWN_STANDARD v2.4.1 (level [C])**
