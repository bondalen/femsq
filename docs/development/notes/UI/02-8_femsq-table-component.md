# Компонент `FemsqTable` — единая фильтрация/сортировка гридов

**Дата:** 2026-07-25 · **обновлено:** 2026-07-29  
**Статус:** ✅ фазы A–B + generic Row (fequlib 0003) + вынесен в `fequlib` (0060) + projectize (0063) + unit-тесты (0004); 🔄 визуальный контракт хост↔lib (fequlib **0011**)  
**Задача:** [0059](../../project-development.json) · [0060](../../project-development.json) · [0063](../../project-development.json)  
**План:** [chat-plan-26-0725-femsq-table.md](../chats/chat-plan/chat-plan-26-0725-femsq-table.md) §7–§8  
**Пакет:** `fequlib` — https://github.com/bondalen/fequlib · локально `file:../../../feQuLib`  
**Импорт:** `import { FemsqTable, actionsColumn } from 'fequlib'`  
**Дерево:** отдельный компонент `FemsqTree` (renderer) + обходник JSON — [02-12](./02-12_femsq-tree/relation-tree.md), не режим таблицы

## Зачем

Каждая форма (перечень строек, отчёты, аренда, agents-list) заново решала фильтрацию/сортировку ad-hoc. `FemsqTable` — тонкая обёртка над Quasar `QTable`, дающая единый контракт один раз, чтобы доработки автоматически долетали до всех форм-потребителей.

## Распределение дизайна (FEMSQ ↔ fequlib)

Зафиксировано 2026-07-29 (бриф в fequlib):

| Слой | Где | Примеры |
|------|-----|---------|
| Тема продукта | **FEMSQ** | Kimbie Dark / VS Light, `--femsq-*`, шрифты, TopBar/StatusBar |
| Контракт грида | **fequlib** | filter, sort, columnFilters, slots, API |
| Хроматика грида | **fequlib** (`--fequlib-table-*`, задача **0011**) | высоты строк/шапки/filter-row, padding; DX — эталон плотности |
| Переопределение плотности | **FEMSQ** тема | один блок в `femsq-theme-tokens.css` после появления токенов в lib |
| Исключение экрана | форма | редко |

**Не делать:** копировать палитру Kimbie в fequlib; UAT «цвет шапки» как дефект грида; пиксель-копия DevExpress WinForms.

Полный бриф: fequlib `docs/design/FemsqTable-visual-target.md` · план `chat-plan-26-0729-femsq-table-visual.md` · эталоны DX `docs/assets/devexpress-grid/`.  
В FEMSQ: [frontend-themes.md](../../frontend-themes.md) § fequlib; план [§8](../chats/chat-plan/chat-plan-26-0725-femsq-table.md).

## Контракт

- **`cellText(row, col)`** — единая точка «что такое ячейка для фильтра/сортировки». По умолчанию `col.format ? col.format(value, row) : String(value ?? '')`. Работает для всех обычных колонок без доп. кода.
- **`filterValue?: (row) => string`** — для колонок с `#body-cell-*`, если колонка в поиске; иначе `filterable: false` или dev-warning.
- **`actionsColumn()`** — `filterable: false`, `sortable: false`; без UI колоночного фильтра.
- **Агрегатные предикаты — это колонка.** COUNT/EXISTS приходят полем строки (`auCnt`, `hasReturned`); тумблер — опциональный пресет.
- **`mode: 'client' | 'server'`** — server эмитит `@request` с `{ filter, columnFilters?, sortBy, descending, page, rowsPerPage }`.
- **Глобальный фильтр** — `v-model:filter` / `showFilter` (фаза A).
- **Поколоночные фильтры (фаза B ✅)** — dense-поле под заголовком; `v-model:columnFilters` (`Record<column.name, string>`); `showColumnFilters` (default `true`); AND с глобальным; `filterable: false` — без поля; кастомный `#header-cell-*` перекрывает встроенный UI.
- **Generic Row (fequlib 0003 ✅)** — `FemsqTableRowBase`, `rows: Row[]` / `FemsqTableColumn<Row>[]` без `as unknown as` для DTO-интерфейсов.
- **Additive-first** — новые API опциональны; ниже манифест потребителей.

Подробности контракта B — в репозитории fequlib: `docs/components/FemsqTable.md`.

## Границы компонента

- **Group By (фаза D)** — группировка **плоских** строк по колонке. Не путать с иерархией.
- **Иерархия** — **не `FemsqTable`**. Renderer: `FemsqTree` в fequlib. Обходник JSON/рёбер (`RelationTree`, кандидат `FemsqWalkTree`) — отдельный слой в FEMSQ, не внутри `FemsqTree`: [02-12](./02-12_femsq-tree/relation-tree.md), [Решение 009](../../../project/decisions/009-femsq-walk-tree.md).
- **Filter Editor (F)** — не реализован.
- **Тема продукта** — не в fequlib (см. распределение дизайна выше).

## Roadmap

A ✅ → B ✅ → generic Row ✅ (0003) → **visual 0011** (хроматика) → C (аудит гридов в FEMSQ) → D → E → F → G → H ✅.  
Тесты чистых функций: fequlib 0004. UI SFC — ещё не покрыт.

**Репозиторий:** https://github.com/bondalen/fequlib · локально `/home/alex/projects/feQuLib` — [Решение 008](../../../project/decisions/008-fequlib-and-docs-registry.md).

## Манифест форм-потребителей

| Форма | Файл | Версия контракта | Статус |
|---|---|---|---|
| Стройки · перечень | `ConstructionSitesView.vue` | A–B / client · fequlib | ✅ smoke §7.2 |
| Стройки · отчёты (ra) | `CstReportsTab.vue` | A–B / client · fequlib | ✅ |
| Стройки · аренда (ralpRa + Au) | `CstRentReportsTab.vue` | A–B / client · fequlib | ✅ |
