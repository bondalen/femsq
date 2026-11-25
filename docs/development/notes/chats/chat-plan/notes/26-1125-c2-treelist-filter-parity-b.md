# FemsqTreeList: паритет фильтра с FemsqTable (вариант B)

**Дата:** 2026-11-25  
**План C2:** §3.2.9 · решение **В13**  
**Статус:** ✅ реализовано 2026-11-25 (feQuLib **0.1.21** + FEMSQ Leaves consume)  
**Далее:** §3.4 🔶 — [acceptance-34](./26-1125-c2-o1-acceptance-34.md)

## 1. Решение

| | |
|--|--|
| Выбрано | **B** — additive API фильтрации в **feQuLib `FemsqTreeList`**, затем потребление на Leaves |
| Отклонено | **A** (только хост-chrome) и **C** (гибрид `rowMatches*` на хосте) как целевые |
| До B на Leaves | допустим временный `QInput` + `buildLeavesTree` (уже ищет по коду/стройке/агенту) |
| Не путать | сортировка / paging / виртуализация — **вне** этого пакета (как в non-goal TreeList) |

Цель: оператор на Пунктах фильтрует **так же**, как на экранах с `FemsqTable` (кнопка chrome, глобальный + поколоночный, счётчик), без отдельного «режима дерева».

## 2. Контракт feQuLib (предложение фазы L6 → план TreeList / задача registry)

Снять из «вне scope» **только** фильтр (не sort/paging). Additive-first, как у таблицы (**0011** / chrome **0.1.13**).

### 2.1 Props / v-model (зеркало FemsqTable)

| API | Смысл |
|-----|--------|
| `v-model:filter` | глобальная подстрока |
| `v-model:columnFilters` | `Record<columnName, string>`, AND с global |
| `v-model:filtersVisible` | default `false`; одна кнопка chrome |
| `showFilter` / `showColumnFilters` / `showFilterCount` | capabilities |
| `filterLabel` / `filterIcon` / `filterTestId` | как у таблицы |
| опционально `title` / `#title` / `#actions` | chrome bar над scroll (паритет) |

На колонке `FemsqTreeListColumn`:

| Поле | Смысл |
|------|--------|
| `filterable?: boolean` | default `true`; `false` — вне global/column |
| `filterValue?: (node) => string` | если `format`/слот ≠ текст поиска |

### 2.2 Семантика match (деревья)

1. **Единица фильтра по умолчанию — корень** (для Leaves: узел `level: 'pn'`).  
2. Корень проходит, если **сам** матчит global+columnFilters **или** (опция) потомок матчит — default **только корень** (проще, предсказуемо для оператора ИП).  
3. Prop `filterMode?: 'roots' | 'roots-or-descendants'` — default `'roots'`.  
4. Match: case-insensitive `includes` по тексту колонок комплекта **корневого** `columnSet` / flat `columns` (те же правила, что `rowMatchesAllFilters`).  
5. Отфильтрованные корни **не** показываются; expanded/selected для скрытых — сбрасывать или игнорировать (предпочтение: selected вне видимых → `null`).  
6. Счётчик: «N из M» = видимые корни / всего корней до фильтра (не число всех узлов дерева).

### 2.3 UI

- Кнопка `data-test="femsq-tree-list-filters-toggle"` (аналог table).  
- При `filtersVisible`: строка global filter; при `showColumnFilters` — вторая строка шапки или поля над data-колонками (как 2-row header table **0011**), **только для sticky header level**.  
- Data-ячейки с ellipsis: `title={полный текст}` (tooltip) — обязательно в том же пакете.  
- Resize колонок — без изменений (уже есть).

### 2.4 Вне scope L6

- sort, pagination, virtualization, multi-select  
- server-mode `@request` (Leaves client-only; server — отдельное решение позже)  
- доменные правила FEMSQ (САК / правые 6 цифр) — только хост

### 2.5 DoD feQuLib

- [ ] Документация `FemsqTreeList.md` + правка non-goal в плане TreeList  
- [ ] Unit: match roots / columnFilters AND / filterable=false / filterMode  
- [ ] Story/smoke в lib (минимум unit + ручной чеклист)  
- [ ] Публикация пакета (ожидаемый минор после текущей линии 0.1.x)  
- [ ] Задача registry (продолжение **0018** или новая — на усмотрение владельца feQuLib)

## 3. Потребление FEMSQ (после публикации lib)

Экран: `InvestmentProgramsView` вкладка Пункты.

| Шаг | Содержание |
|-----|------------|
| 3.1 | `check-fequlib.sh` + bump зависимости на пакет с L6 |
| 3.2 | Убрать отдельный `QInput` фильтра; связать `v-model:filter` / `columnFilters` / `filtersVisible` с TreeList |
| 3.3 | Колонки `label`/`cstName`/`ogName`/`shName`/`note` — `filterable: true`; суммы — `filterable: false` (или true по желанию оператора — default false для money) |
| 3.4 | Удалить дублирующую фильтрацию из `buildLeavesTree(filter)` **или** оставить filter=`''` и фильтровать только в lib (предпочтение: **один** путь — lib) |
| 3.5 | UI smoke: фильтр по фрагменту стройки/агента; счётчик; resize узких колонок; tooltip полного имени |

**DoD FEMSQ:** оператор на Пунктах включает фильтры той же кнопкой-привычкой, что на FemsqTable; Стройка/Агент видны в гриде (узко) и участвуют в поиске.

## 4. Колонки «Стройка» / «Агент» (уже в C2, не ждать L6)

| | |
|--|--|
| Где | `columnSets` level `pn`: после САК, `width: ~110px` |
| Показ | data-зона → ellipsis (начало строки); session resize |
| Фильтр до L6 | host `pointFilter` уже включает `cstAgPnCstName` / `cstAgPnOgName` |
| План | §3.2.8.5 |

## 5. Порядок относительно O1 (владелец 2026-11-25)

```text
§3.2.9    B: feQuLib L6 → FEMSQ consume     — сначала
§3.2.8.5  колонки Стройка/Агент (smoke/✅) — затем
§3.4      приёмка O1 (данные)               — после UX фильтра+колонок
```

Код колонок (§3.2.8.5) может уже лежать в FE до закрытия L6; официальный ✅ и JAR-smoke — после §3.2.9.

## 6. Текст для вставки в план feQuLib (TreeList)

Краткий блок для `chat-plan-26-0926-femsq-tree-list.md`:

> **L6 — Filter parity with FemsqTable (запрос FEMSQ C2 / Leaves, 2026-11-25)**  
> Снять «фильтр» из non-goal. Additive API: `filter`, `columnFilters`, `filtersVisible`, chrome, `filterable`/`filterValue` на колонке; match по корням (`filterMode`); ellipsis `title`. Без sort/paging/server. Контракт: FEMSQ `notes/26-1125-c2-treelist-filter-parity-b.md` §2.  
> После публикации — хост C2 §3.2.9.

Обмен с feQuLib: при старте L6 — короткий `agent-exchange` со ссылкой на этот note.
