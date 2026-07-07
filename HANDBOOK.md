# Справочник по структуре Z-ai-platform

> Краткий обзор каждого каталога и ключевого файла в корне проекта.
> Для полных спецификаций — читайте соответствующие стандарты в `standards/`.

---

## Каталоги

### `.husky/`

Git-хуки (Husky v9). Запускаются автоматически при `git commit`.

| Хук          | Что делает                                                                                                   | Уровень                 |
| ------------ | ------------------------------------------------------------------------------------------------------------ | ----------------------- |
| `pre-commit` | co-change проверка + worklog + verify-standards + verify-id-graph + verify-skills + line-count + lint-staged | HARD (блокирует коммит) |
| `commit-msg` | Проверка Conventional Commits (G4/G5/G6)                                                                     | HARD                    |

Обход: `git commit --no-verify` (только в экстренных случаях).

---

### `.github/workflows/`

CI-пайплайны GitHub Actions.

| Workflow              | Что делает                                                                                        |
| --------------------- | ------------------------------------------------------------------------------------------------- |
| `verify-id-graph.yml` | verify-standards.js + verify-id-graph.js + verify-skills.js + line-count-check + graph generation |
| `e2e-verifiers.yml`   | E2E проверка верификаторов                                                                        |

Запускается при push/PR в main + nightly (03:00 UTC).

---

### `.zai/`

Внутренняя конфигурация Z.ai sandbox.

| Файл          | Назначение                  |
| ------------- | --------------------------- |
| `config.json` | Конфигурация sandbox        |
| `setup.sh`    | Первичная настройка sandbox |
| `lib/`        | Вспомогательные функции     |
| `verify`      | Проверка конфигурации       |

---

### `eslint-rules/`

Кастомные ESLint-правила для Markdown.

| Файл                     | Правило                                                  |
| ------------------------ | -------------------------------------------------------- |
| `code-block-language.js` | Блоки кода должны указывать язык (STD-DOC-002 4.3)       |
| `unicode-policy.js`      | Запрет emoji/Unicode graphics в .md файлах (STD-DOC-003) |

---

### `eslint-processors/`

ESLint-процессоры для извлечения кода из Markdown.

| Файл                   | Назначение                                       |
| ---------------------- | ------------------------------------------------ |
| `markdown-snippets.js` | Извлекает code blocks из .md для проверки ESLint |

---

### `guard/`

Submodule Z-ai-guard — правила и процедуры enforcement.

| Каталог/файл    | Назначение                                                                 |
| --------------- | -------------------------------------------------------------------------- |
| `rules/`        | 17 правил RULE-001..017 (atomic rules)                                     |
| `scripts/`      | Процедуры: co-change-check, worklog-check, line-count-check, setup, update |
| `instructions/` | Инструкции к процедурам                                                    |
| `tools/`        | Инструменты (verify-docs, bump)                                            |
| `registry.json` | Реестр правил со статусами                                                 |

---

### `standards/`

Submodule Z-ai-standards — нормативные стандарты + верификаторы.

| Каталог/файл    | Назначение                                                              |
| --------------- | ----------------------------------------------------------------------- |
| `standards/`    | 21 .md стандарт (STD-FE-001, STD-DOC-002, ...)                          |
| `templates/`    | Шаблоны: README, WORKLOG, CHANGELOG, AGENT_RULES                        |
| `guides/`       | Необязательные гайды (CODE_EXAMPLES_GUIDE)                              |
| `docs/sandbox/` | Документация sandbox (hooks, команды)                                   |
| `scripts/`      | Верификаторы: verify-standards.js, verify-id-graph.js, verify-skills.js |
| `_snapshots/`   | Baseline для snapshot-сравнения ID-графа                                |

---

### `skills/`

Каталог скиллов (монорепо, не submodule).

| Скилл                            | Назначение                                         |
| -------------------------------- | -------------------------------------------------- |
| `zai-anti-monolith`              | Автоматическая декомпозиция при превышении лимитов |
| `zai-debugging`                  | Систематический дебаггинг                          |
| `zai-frontend-styling-expert`    | CSS/Tailwind стилизация                            |
| `zai-md-std`                     | Markdown стандарт                                  |
| `zai-mermaid-diagrams`           | Mermaid диаграммы                                  |
| `zai-performance-code-generator` | Оптимизация кода                                   |
| `zai-phi-layout`                 | Layout по золотому сечению                         |
| `zai-project-clone`              | Клонирование проектов                              |
| `zai-prompt-engineering`         | Инжиниринг промптов                                |
| `zai-sandbox-rules`              | Правила sandbox                                    |
| `zai-skill-creator`              | Создание скиллов                                   |
| `zai-skill-registry`             | Реестр скиллов                                     |
| `zai-ui-composer`                | UI компоновка                                      |
| `zai-workflow-discipline`        | Дисциплина workflow                                |

---

### `src/`

Исходный код проекта (инфраструктурные тесты).

| Файл                     | Назначение                                                                      |
| ------------------------ | ------------------------------------------------------------------------------- |
| `infrastructure.test.ts` | Проверка инфраструктуры: package.json, tsconfig, .gitignore, .husky, submodules |

---

### `tests/`

Sandbox-интеграционные тесты (bash).

| Файл                          | Назначение                       |
| ----------------------------- | -------------------------------- |
| `sandbox-integration-test.sh` | 20 интеграционных тестов sandbox |
| `sandbox-behavior-test.sh`    | 10 тестов поведения sandbox      |
| `edge-case-tests.sh`          | 15 edge-case тестов              |

---

### `docs/`

Документация.

| Каталог   | Назначение                                      |
| --------- | ----------------------------------------------- |
| `_graph/` | CI-сгенерированные графы зависимостей (ID-граф) |

---

### `eslint.config.js`

ESLint flat config (v9+). Маппит правила из `eslint-rules/` и `eslint-processors/`.

---

### `vitest.config.ts`

Конфигурация Vitest для TypeScript-тестов.

---

### `tsconfig.json`

TypeScript конфигурация (strict mode, ES2022+, ESNext modules).

---

## Ключевые файлы в корне

| Файл                              | Назначение                                                        |
| --------------------------------- | ----------------------------------------------------------------- |
| `AGENT_RULES.md`                  | Точка входа для агентов: протокол онбординга, приоритеты, запреты |
| `README.md`                       | Описание проекта                                                  |
| `CHANGELOG.md`                    | Журнал изменений (Keep a Changelog)                               |
| `CONTRIBUTING.md`                 | Гайд для контрибьюторов                                           |
| `worklog.md`                      | Аппенди-онли лог действий (STD-DOC-008)                           |
| `bootstrap.sh`                    | Единая точка входа: install + update + restore                    |
| `scripts/status.sh`               | Диагностика состояния проекта                                     |
| `scripts/save-work.sh`            | Сохранение текущей работы                                         |
| `package.json`                    | NPM-конфигурация: скрипты, зависимости                            |
| `.prettierrc`                     | Prettier: LF, 100 chars, double quotes                            |
| `.gitmodules`                     | Объявление submodules (standards, guard)                          |
| `.env.example`                    | Пример переменных окружения                                       |
| `scripts/fix-code-block-langs.py` | Разовый скрипт исправления языков в code blocks                   |

---

## npm-скрипты

| Команда                 | Действие                 |
| ----------------------- | ------------------------ |
| `npm run lint`          | ESLint для .ts/.tsx      |
| `npm run lint:fix`      | ESLint + автоисправление |
| `npm run format`        | Prettier форматирование  |
| `npm run format:check`  | Prettier проверка        |
| `npm run typecheck`     | TypeScript проверка      |
| `npm run test`          | Vitest запуск            |
| `npm run test:watch`    | Vitest в watch-режиме    |
| `npm run test:coverage` | Vitest + покрытие        |
| `npm run check:md`      | Проверка Markdown        |
| `npm run check:graph`   | verify-id-graph.js       |
| `npm run validate`      | lint + typecheck + test  |
| `npm run prepare`       | Husky install            |

---

## Потоки данных

```
git commit
  -> .husky/pre-commit
       -> guard/scripts/co-change-check.sh (HARD)
       -> guard/scripts/worklog-check.sh (HARD)
       -> standards/scripts/verify-standards.js (HARD, V01-V17)
       -> standards/scripts/verify-id-graph.js (HARD, G01-G15)
       -> standards/scripts/verify-skills.js (HARD, S01-S10)
       -> guard/scripts/line-count-check.sh (SOFT)
       -> npx lint-staged (eslint + prettier)
  -> .husky/commit-msg
       -> Conventional Commits check (G4/G5/G6)

git push -> .github/workflows/verify-id-graph.yml
  -> verify-standards.js
  -> verify-id-graph.js
  -> verify-skills.js
  -> line-count-check.sh
  -> graph generation (mermaid)
```
