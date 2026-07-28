# План: компонент `FemsqTable` — единая фильтрация/сортировка гридов

**Дата создания:** 2026-07-25  
**Последнее обновление:** 2026-07-28  
**Проект:** FEMSQ  
**Версия плана:** 1.4.0 (0063 ✅; §7 ✅; возврат к 0058)  
**Задача:** [0059](../../../project-development.json) (completed) · [0061](../../../project-development.json) (completed) · [0060](../../../project-development.json) (completed) · [0063](../../../project-development.json) (completed)  
**Статус плана:** ✅ закрыт для FemsqTable/projectize; продолжение — `chat-plan-26-0722` (0058)  
**Компонент:** [02-8_femsq-table-component.md](../../UI/02-8_femsq-table-component.md)

---

## 0. Зачем и откуда

Выявлено в чате `chat-2026-07-22-001` (вкладка «отчёты, аренда»): каждая новая форма заново решает фильтрацию/сортировку списков ad-hoc (пример: основной перечень строек не фильтруется по `cstKey`). Разбор Quasar `QTable` и рынка (см. §5) показал: готового решения нет — нужна собственная тонкая обёртка, чтобы доработки компонента автоматически долетали до всех форм, где он применён.

**Приоритет (2026-07-25):** задача 0058 (формы `cst`/`cstAgPn`) приостановлена (`blocked`) до конца цепочки **0059 → 0061 → 0060** (фаза A → MVP реестра документации → вынос в `feQuLib`) — решено не только не наращивать в 0058 новые ad-hoc гриды, но и не продолжать 0058 на локальной (не вынесенной) версии `FemsqTable`, и не заводить `feQuLib` с документацией «на будущее переделать»: везде один и тот же принцип «сделать один раз правильно». Работа по 0058 возобновляется только после того, как `FemsqTable` реально подключён в FEMSQ из `feQuLib` (0060 завершена). Задача 0062 (перенос истории FEMSQ в реестр) — вне этой цепочки, не спешит.

**2026-07-25 итог:** цепочка 0059→0061→0060 выполнена (код и локальные папки).

**2026-07-28 итог:** 0063 закрыта; оба репозитория осязаемы. 0058 → `pending`. Продолжение — `chat-plan-26-0722-forms-ia-cst.md` (шаг 10, новый чат).

**Вне scope этого плана:** дерево агентов как иерархический TreeList-контрол (см. §5, п. G) — только зарезервировано место в roadmap, реализация — отдельный план/чат, когда до неё дойдёт очередь.

---

## 1. Цель

Дать один компонент `FemsqTable` (обёртка над `QTable`) с единым контрактом фильтрации/сортировки/форматирования и постепенно перевести на него существующие гриды, начиная с перечня строек (`cstKey`-фильтр — исходный триггер).

---

## 2. Принципы контракта (зафиксировать в коде, не только в доке)

| Принцип | Суть |
|---|---|
| `cellText(row, col)` по умолчанию | `col.format ? col.format(value, row) : String(value ?? '')` — обычные колонки фильтруются/сортируются автоматически, без доп. кода. |
| `filterValue?: (row) => string` | Обязателен только для колонок, отрисованных через `#body-cell-*` слот (иконки/кнопки), если колонка должна участвовать в поиске; dev-warning, если забыли и `filterable !== false`. |
| `actionsColumn()` хелпер | Сразу выставляет `filterable: false, sortable: false` для колонки действий — не нужно помнить руками. |
| Агрегатные предикаты — колонка, не тумблер | Если фильтр зависит от COUNT/EXISTS по дочерней таблице (пример: «несколько Au»), значение приходит как обычное поле строки; UI-тумблер — опциональный быстрый пресет над тем же полем, не единственный способ. |
| `mode: 'client' \| 'server'` | Контракт `@request` (`{ filter, sortBy, descending, page, rowsPerPage }`) заложен сразу; server-режим включается точечно для конкретных списков по мере роста данных, а не в конце roadmap. |
| Additive-first | Новые пропсы/слоты — только опциональные; удаление старых — через цикл `deprecated`-warning; манифест форм-потребителей в 02-8 — чек-лист миграции. |

---

## 3. Фазы

- **A — Core ✅.** Обёртка в FEMSQ, миграция трёх гридов cst; затем перенос в feQuLib (H).
- **B–G** — по плану, отдельно.
- **H — feQuLib ✅** (0060): пакет `/home/alex/projects/feQuLib`, зависимость `fequlib` в `femsq-frontend-q`, локальная копия удалена; проект зарегистрирован в docs-registry.
- **0061 ✅** — `/home/alex/projects/docs-registry` (Postgres :5433, CLI).

**Порядок:** 0059 ✅ → 0061 ✅ → 0060 ✅ → 0063 ✅ → 0058. 0062 — когда угодно после 0061, вне цепочки.

---

## 4. Критерии готовности фазы A (MVP)

- [x] `FemsqTable.vue` создан, покрывает контракт §2 (без B–G).
- [x] Перечень строек (`ConstructionSitesView.vue`) фильтруется по `cstKey`/имени без регрессии.
- [x] `CstReportsTab.vue` переведён на компонент, старая ad-hoc фильтрация удалена.
- [x] `CstRentReportsTab.vue` переведён на компонент (включая вложенный `ralpRaAu`), старая ad-hoc фильтрация удалена.
- [x] Манифест форм-потребителей начат в `02-8_femsq-table-component.md`.
- [x] Type-check/lint frontend чисто.

---

## 5. Справка (перенесено из обсуждения, не расширять)

- Рынок Quasar-обёрток проверен: `quasar-grouped-table` (только группировка, неактивен), `quasar-app-extension-table-builder` (тянет свой Form Builder/стор), `quasar-zod-editable-table` (заточен под Zod-редактирование) — ни один не закрывает задачу целиком, решение писать тонкую обёртку обоснованно.
- DevExpress разделяет `GridControl`/`DataGrid` (плоские данные + Group By по колонкам) и `TreeList` (родитель-потомок структура данных) как **два разных класса/пакета**, не режимы одного виджета — граница `FemsqTable` vs будущий TreeList выбрана по этому образцу.

---

## 6. Projectize: `docs-registry` и `feQuLib` как отдельные проекты (задача 0063)

**Зачем:** MVP 0061/0060 сделан в соседних папках без коммитов, без GitHub и без собственной документации — это не «проекты», а черновики. Принцип «не переделывать» требует оформить их до возврата к формам 0058.

**Критерий «осязаемый проект» (оба репозитория):**

| # | Критерий | docs-registry | feQuLib |
|---|---|---|---|
| A | Initial commit + ветка по умолчанию | ☑ | ☑ |
| B | Remote GitHub + push синхронизирован | ☑ [docs-registry](https://github.com/bondalen/docs-registry) | ☑ [fequlib](https://github.com/bondalen/fequlib) |
| C | Папка `docs/` (README, roadmap, chat-plan) | ☑ | ☑ |
| D | `.cursorrules` или `.cursor/rules` | ☑ | ☑ |
| E | README: быстрый старт + ссылки на FEMSQ/docs-registry | ☑ | ☑ |
| F | Задачи/backlog в docs-registry (CLI), не локальный JSON | ☑ | ☑ |
| G | Открыто отдельным окном Cursor | ☑ | ☑ |

**FEMSQ после 0063:** ADR 008 обновлён URL репозиториев; 0058 → `pending`; journal-запись; ссылка из `02-8_femsq-table-component.md`.

### 6.1. Порядок мероприятий (выполнять по шагам, один шаг — одно подтверждение)

| Шаг | Действие | Где | Исполнитель |
|---|---|---|---|
| **1** | Initial commit (весь MVP-код, без `.env`) | `docs-registry` | агент / вы |
| **2** | Создать пустой репозиторий на GitHub + `git remote add` + push | GitHub + `docs-registry` | вы (или `gh` после установки) |
| **3** | Scaffold `docs/` + `.cursorrules` + backlog-задачи в Postgres | `docs-registry` | агент (окно docs-registry) |
| **4** | Открыть `docs-registry` в **отдельном окне** Cursor | IDE | вы |
| **5** | Initial commit | `feQuLib` | агент / вы |
| **6** | GitHub remote + push | `feQuLib` | вы |
| **7** | Scaffold `docs/` + `.cursorrules` + задачи в registry | `feQuLib` | агент (окно feQuLib) |
| **8** | Открыть `feQuLib` в **отдельном окне** Cursor | IDE | вы |
| **9** | Обновить ADR 008, journal, разблокировать 0058 в FEMSQ | `femsq` | агент |
| **10** | Старт чата 0058 по `chat-plan-26-0722-forms-ia-cst.md` | `femsq` | новый чат |

### 6.2. Backlog (зафиксировать в registry и/или `docs/roadmap.md`, не блокирует 0063)

**docs-registry:** CLI для `journal_sessions`/`journal_entries`/`task_items`; smoke-скрипт migrate+list; опционально CI.

**feQuLib:** generic `rows`/`columns`; unit-тесты filter/sort; фазы B–G по roadmap; Quasar App Extension — при втором потребителе.

**FEMSQ (0062, low):** перенос исторического JSON в registry — вне цепочки 0063.

### 6.3. Текущий прогресс §6

- [x] Шаг 1 — initial commit `docs-registry` (`3038d1d`)
- [x] Шаг 2 — GitHub `docs-registry` → https://github.com/bondalen/docs-registry
- [x] Шаг 3 — docs + `.cursorrules` + backlog Postgres (`833bfae`)
- [x] Шаг 4 — окно Cursor `docs-registry` (WSL: Ubuntu)
- [x] Шаг 5 — initial commit `feQuLib` (`d46cb33`)
- [x] Шаг 6 — GitHub `feQuLib` → https://github.com/bondalen/fequlib
- [x] Шаг 7 — docs + `.cursorrules` + backlog в registry для feQuLib (`b019da6`)
- [x] Шаг 8 — окно Cursor `feQuLib` (WSL: Ubuntu)
- [x] Шаг 9 — FEMSQ ADR/journal/0058 (2026-07-28)
- [x] Шаг 10 — возврат к 0058 (новый чат по `chat-plan-26-0722-forms-ia-cst.md`, 2026-07-28)

---

## 7. Гигиена до возврата к 0058 (2026-07-28)

После projectize и фаз A–B + тестов 0004 в fequlib — не начинать D–G. Перед чатом 0058:

| Шаг | Действие | Где | Кто | Статус |
|---|---|---|---|---|
| **7.1** | Обновить FEMSQ `02-8` (фаза B ✅, API `columnFilters`) | `femsq` | агент | ☑ 2026-07-28 |
| **7.2** | Smoke UI фазы B на перечне строек | браузер / FEMSQ | вы | ☑ 2026-07-28 (cstKey + AND с именем) |
| **7.3** | Опционально: fequlib **0003** (generic `rows`/`columns`) | окно `feQuLib` | вы + агент там | ☑ `51d1021` + касты сняты в 3 гридах FEMSQ (не закоммичено) |
| **7.4** | Старт чата 0058 (= шаг 10 §6) | окно `femsq` | вы | ☑ 2026-07-28; C.5 ✅ |

**Не делать в §7:** 0006–0009, Group By, CI workflow (нет PAT scope), App Extension.

**feQuLib на момент §7:** A+B (`7850bf6`), тесты 0004 (`b0b8ef7`), GitHub https://github.com/bondalen/fequlib.
