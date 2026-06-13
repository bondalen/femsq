# План работы чата: spMstrg_2606 — DAG-фильтрация и корректная цепь ИПГ

> ⚠️ **Архивная версия.** Актуальный план с логической нумерацией этапов:  
> **`chat-plan-26-0604-spMstrg-2606-v2.md`**

**Дата:** 2026-06-04  
**Обновлён:** 2026-06-11 (переупорядочен с учётом анализа производительности от 2026-06-11)  
**Автор:** Александр  
**Предшествующий план:** `docs/development/notes/chats/chat-plan/chat-plan-26-0508-spMstrg-2605.md`  
**Связанное резюме:** *(создать при закрытии чата)*  
**Порядок работ на продуктиве:** `docs/deployment/db-upgrade-spMstrg-2606.md` *(создать в Этапе 7)*  
**Чеклист дня деплоя:** `docs/deployment/db-upgrade-spMstrg-2606-deploy-day-checklist.md` *(создать в Этапе 7)*

---

## Цель чата

Разработать и верифицировать SQL-объекты серии `_2606` на тестовой БД **FishEye** и **сформировать пакет для продуктивного сервера** — набор нумерованных `.sql`-скриптов и документ `docs/deployment/db-upgrade-spMstrg-2606.md` с пошаговым порядком проведения работ, пригодный для самостоятельного применения на продуктиве (SQL Server 2012 SP4).

**Конечные результаты чата:**

| Артефакт | Путь | Этап |
|----------|------|------|
| SQL-скрипты создания объектов (dev, `CREATE OR ALTER`) | `docs/development/notes/sql/26-0604/` | 1–6 |
| SQL-скрипты для продуктива (`MSSQL2012/`, без `DROP IF EXISTS`) | `docs/development/notes/sql/26-0604/MSSQL2012/` | 1–6 |
| Скрипт проверки «до» | `00_VERIFY_before.sql` | 1 |
| Скрипт проверки «после» | `07_VERIFY_after.sql` | 6 |
| Скрипт отката | `08_ROLLBACK.sql` | 1–6 |
| Таблицы FEMSQ `spMstrg_2606_ResultSet1..7` | `05b_CREATE_TABLE_spMstrg_2606_ResultSets.sql` | 6 |
| Порядок работ на продуктиве | `docs/deployment/db-upgrade-spMstrg-2606.md` | 7 |
| Краткий чеклист дня деплоя | `docs/deployment/db-upgrade-spMstrg-2606-deploy-day-checklist.md` | 7 |

---

## Контекст и мотивация

В ходе разработки `spMstrg_2605` вскрыты два архитектурных дефекта, не позволяющих корректно выполнить фильтрацию по группе строек с учётом смены инвестпрограмм в цепи:

### Дефект A — Фильтр через `importIpgSt_26-0320` не привязан к актуальной ИПГ

`importIpgSt_26-0320` содержит пары `(cst, cst_type)` без привязки к конкретной инвестпрограмме. В `fnIpgChRsltCstUtl2_2605` фильтр вида `EXISTS (SELECT 1 FROM importIpgSt WHERE cst = cstAgPnCode AND cst_type = @ipgSt)` применяется ко всем строкам безотносительно того, какая `ipg` была актуальна на конкретную дату.

Корректное решение: использовать существующую связь `ipgPn → ipgStPn → stIpg` (DAG структуры ИПГ) с учётом актуальной `ipg` на каждую дату расчёта.

### Дефект Б — `ipgStr/ipgEnd` как атрибут `ipg`, а не `ipgChRl`

Даты начала/конца актуальности принадлежат сущности `ipg` (глобально), а не связи «цепь — ИПГ». Одна и та же `ipg` не может иметь разные периоды в разных цепях. Следствие: на цепи 15 (`ipg=25` и `ipg=26` с `ipgEnd=NULL`) в месяцы 7–12 оба `ipg` попадают в результат одновременно.

Корректное решение: новая таблица `ags.ipgChRlV`, где `ipgcrvStr` — атрибут связи «цепь — ИПГ», `ipgcrvEnd` вычисляется как `DATEADD(day, -1, следующий ipgcrvStr в цепи)`.

---

## Принятые архитектурные решения

*(зафиксированы в сессии 2026-06-04, см. раздел «Вскрытые архитектурные проблемы» в предшествующем плане)*

| Решение | Описание |
|---------|----------|
| `ags.ipgChRlV` + `ags.fnIpgChRlVEnd` | В таблице только `ipgcrvStr`; `ipgcrvEnd` — вычисляемый столбец через скалярный UDF (MIN следующего `ipgcrvStr` − 1 день), не UPDATE |
| DAG-фильтрация через `ipgStPn` | Параметр `@ipgStKey int` вместо `@ipgSt nvarchar`; используются `fnStDownAll` + `ipgStPn` |
| Новая цепочка функций `_2606` | Не трогаем `_2605` и старый код; 9 новых объектов |
| `ipg.ipgStr/ipgEnd` — не исправляем | `spMstrg_2605` остаётся с известным ограничением по цепи 15 |
| Базовый стек — `fnMasteringStIpgStCost` *(пересмотрено Q3)* | `@stCostKey int` включён с nullable-семантикой; fallback к `ipgUtPlP.iuplpLim` при отсутствии `ipgPnLim` (на продуктиве — цепь 15; в разработке — цепь 5 с полными данными) |
| Тестовая цепь — `@ipgCh = 5` | **Основная** разработка и приёмка — цепь 5. Цепь 15 — только `ipgChRlV` (INSERT в пакете) + **доп.** проверка дефекта Б / точки разрыва |
| Параллельное сосуществование *(Решение 8)* | `_2606` пишет только в `spMstrg_2606_ResultSet1..7`; `_2605`/`_2408` и их клиенты не затрагиваются |
| Двухшаговая модель + `factDoc` *(Решение 9)* | **Шаг 1 (чат):** работоспособная `_2606` + `factDoc`/`factDocCost` для **всех** типов документов факта, триггеры, бэкфилл; клиенты не меняем. **Шаг 2:** переключение Access/FEMSQ, данные продуктива, опционально `stNetDocBind` |
| LEGACY scalar UDF → `_2606` через `factDocCost` *(Решение 10, 2026-06-11)* | **Пересмотр `04-computation-map.md §Шаг 5`**: функции `fnMasteringPresRa` и аналоги **не остаются без изменений** — они заменяются на `fnMasteringFact*_2606`-версии, читающие `factDocCost`. Это устраняет узкое место ×70–140 и одновременно реализует Вариант 6А (Ret/InProc/NotArr). `factDocCost` уже заполнен (112 142 строк, шаг 1b.3 ✅). |

### Вопросы, требующие уточнения перед реализацией

- [x] **Q1:** `ipg.ipgStRlSh` — что это: ключ схемы `stNet`, ключ ребра `stRel`, или «схема реализации»? ✅  
  **Ответ:** FK → `stNet.stnKey` (схема связей структуры ИПГ). Каноничный источник для `_2606` — `ipgCh.ipgcStNetIpg`. Детали: `docs/development/notes/sql/26-0604/docs/02-q1-q4-answers.md §Q1`.
- [x] **Q2:** Интерфейс клиента: `@ipgStKey int` или `@ipgSt nvarchar`? ✅  
  **Ответ:** `@ipgStKey int` (числовой ключ `stIpg.stiKey`). `@ipgSt nvarchar` в `_2605` — коды типов затрат (`importIpgSt_26-0320.cst_type`), несопоставимые измерения.
- [x] **Q3:** Нужен ли `@stCostKey int` в `spMstrg_2606`? ✅ *(пересмотрено)*  
  **Ответ (пересмотрен 2026-06-04):** да, включить в `_2606`. Строить на стеке `fnMasteringStIpgStCost`; оба параметра `@ipgStKey` и `@stCostKey` — nullable. 9 новых объектов. Детали: `docs/development/notes/sql/26-0604/docs/03-design-decisions.md §7`.
- [x] **Q4:** `ipgcrvUtPlGr` для `ipg=26` (цепь 15) — NULL или задано? ✅  
  **Ответ:** NULL — корректное значение. В `ags.ipgUtPlGr` записи для ipg=26 нет (последняя — key=17, ipg=25). «Письмо Д644» не имеет выделенной группы планов.

### Роли тестовых цепей *(зафиксировано 2026-06-05)*

| Цепь | Роль в этом чате | Где используется |
|------|------------------|------------------|
| **5** | **Основная** — разработка, функциональные тесты, приёмка `spMstrg_2606` | Этапы 2–6, контрольные точки К-2…К-6 |
| **15** | **Вспомогательная** — источник примера дефекта Б; данные `ipgChRlV` для продуктива | Этап 0.3 (эталон `_2605`), Этап 1 (INSERT), **доп.** проверка `fnIpgChDatsV` (точка разрыва) |

**Не путать:** упоминания цепи 15 в контексте дефекта Б (этап 0, справка) — это исторический эталон проблемы, а не тестовая цепь для этапов 3–6.

---

## Целевая архитектура `spMstrg_2606`

> **Пересмотрено 2026-06-04 (Q3 revised):** базовый стек — `fnMasteringStIpgStCost`, не `fnIpgChRsltCstUtl_2408`. Оба параметра `@ipgStKey` и `@stCostKey` включены. Итого 9 новых объектов.

```
ags.ipgChRlV  (ipgcrvStr, ipgcrvUtPlGr, …, ipgcrvEnd computed via fnIpgChRlVEnd)
      ↓  ipgcrvEnd = ags.fnIpgChRlVEnd(chain, str) = MIN(next.str) − 1 день — computed column
fnIpgChDatsV(@ipgCh)  →  даты: 2022-01-01 + концы мес. + точки перехода ИПГ
      ↓
fnStCostRsIpgPn_2606(@ipgChKey, @ipgPnKey, @dateRslt)
      — фикс Деф.Б: actuality через ipgChRlV; fallback к ipgUtPlP.iuplpLim
      ↓
fnStCostRsCstAgPn_2606 / fnMasteringFact*_2606 (через factDocCost)  ← Решение 10
      ↓
fnMasteringCstAgPnSh_2606 [обновлённый: вызывает fnMasteringFact*_2606]
      ↓
fnMasteringStIpgStCost_2606(@ipgStKey int=NULL, @ipgChKey, @stCostKey int=NULL, @dateRslt)
      — фикс Деф.А: stNet per-IPG из ipgChRlV (а не max); @ipgStKey/@stCostKey nullable
      ↓
fnIpgChRsltCstUtl2_2606(@ipgCh, @ipgStKey int=NULL, @stCostKey int=NULL)  ← MSTVF (v8)
      — материализует schemeRows в #temp (Решение 10, П2)
      ↓
fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, @ipgStKey int=NULL, @stCostKey int=NULL)
      ↓
spMstrg_2606(@ipgCh, @MounthEndDate, @ipgStKey int=NULL, @stCostKey int=NULL, @saveToTables bit=0)
    ├── @saveToTables = 0  →  SELECT ×7  →  MS Access
    └── @saveToTables = 1  →  INSERT ×7  →  ags.spMstrg_2606_ResultSet1..7  *(не _2408_!)*
```

---

## Состав новых объектов БД

> **Пересмотрено 2026-06-11 (Решение 10):** добавлены `fnMasteringFact*_2606` (~43 функции: 18 Pres/Accp + 25 Ret/InProc/NotArr/PresAll через factDocCost). Общее число объектов ~50.

| Объект | Тип | Назначение |
|--------|-----|-----------|
| `ags.fnIpgChRlVEnd` | Scalar UDF | Вычисляет `ipgcrvEnd` |
| `ags.ipgChRlV` | Таблица | Сроки начала в цепи; `ipgcrvEnd` — вычисляемый столбец |
| `ags.fnIpgChDatsV` | Inline TVF | Генератор дат с точками перехода из `ipgChRlV` |
| `ags.fnStCostRsIpgPn_2606` | Multi-stmt TVF | Лимиты по пунктам ИПГ; фикс Деф.Б + fallback |
| `ags.fnStCostRsCstAgPn_2606` | Multi-stmt TVF | Лимиты по строй-агент-кодам |
| `ags.fnStCostRa/RaCh/AgFee/Ralp/PrDoc/Mnrl_2606` | 6 Scalar UDF | Сумма по stCost из `factDocCost` (политика B+F) |
| `fnMasteringFact*_2606` (~43 функции) | Scalar UDF | **Новые:** Pres/Accp/Ret/InProc/NotArr/PresAll по factDocCost; замена legacy `fnMastering*` |
| `ags.fnMasteringCstAgPnSh_2606` | Multi-stmt TVF | Освоение по стройке; **обновлён** для вызова `fnMasteringFact*_2606` |
| `ags.fnMasteringStIpgStCost_2606` | Inline TVF | Фикс Деф.А; `@ipgStKey`/`@stCostKey` nullable |
| `ags.fnIpgChRsltCstUtl2_2606` | **Multi-stmt TVF** | Обёртка: **MSTVF** с `#temp schemeRows`; CTE-кэш fnCstAgPnBranch |
| `ags.fnIpgChRsltCstUtlPercentBrn_2606` | Multi-stmt TVF | Сводный расчёт |
| `ags.spMstrg_2606` | Stored Procedure | `@ipgStKey`, `@stCostKey`, `@saveToTables` |
| `ags.spMstrg_2606_ResultSet1..7` | Таблицы | Приёмник; **отдельно** от `*_2408_ResultSet*` |

**Не создаются / не меняются в рамках SQL-пакета этого чата:**
- Изменения в `spMstrg_2605`, `fn*_2408`, `fn*_2605`, таблицах `spMstrg_2408_ResultSet*` — не трогаем
- Обязательное переключение MS Access и FEMSQ на `_2606` — **после** SQL-приёмки
- Удаление `_2408`/`_2605` — отдельным этапом

---

## Состав SQL-пакета

Располагается в `docs/development/notes/sql/26-0604/`.

| Файл | Содержимое |
|------|-----------|
| `00_VERIFY_before.sql` | Состояние БД до |
| `01_CREATE_TABLE_ipgChRlV.sql` | DDL + INSERT для цепей 5, 15 |
| `01b_CREATE_TABLE_factDoc.sql` | `factDoc`, `factDocCost`, колонки `*_fdKey` (6 подклассов) |
| `01c_CREATE_TRIGGER_factDoc_sync.sql` | Триггеры синхронизации `factDocCost` |
| `01d_BACKFILL_factDoc.sql` | Миграция из плоских полей + исторический `ra_summCt` |
| `02_CREATE_FUNCTION_fnIpgChDatsV.sql` | Генератор дат |
| `03a0_CREATE_FUNCTION_fnStCostIpgPn_2606.sql` | Точность лимита decimal(23,8) |
| `03a_CREATE_FUNCTION_fnStCostRsIpgPn_2606.sql` | Фикс Деф.Б + fallback к `ipgUtPlP.iuplpLim` |
| `03b0_CREATE_FUNCTION_fnStCost_2606.sql` | `fnStCostRa/RaCh/AgFee/Ralp/PrDoc/Mnrl_2606` → `factDocCost` |
| `03b_CREATE_FUNCTION_fnStCostRsCstAgPn_2606.sql` | Лимиты по строй-агент-кодам |
| `03b1_CREATE_FUNCTION_fnMasteringFact_2606.sql` | ~43 функции факта: Pres/Accp/Ret/InProc/NotArr/PresAll (через `factDocCost`) |
| `03c_CREATE_FUNCTION_fnMasteringCstAgPnSh_2606.sql` | Освоение по стройке (обновлён для `fnMasteringFact*_2606`) |
| `03d_CREATE_FUNCTION_fnMasteringStIpgStCost_2606.sql` | Фикс Деф.А; оба фильтра nullable |
| `04_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2606.sql` | Обёртка (MSTVF v8: #temp schemeRows + CTE-кэш branch) |
| `05_CREATE_FUNCTION_fnIpgChRsltCstUtlPercentBrn_2606.sql` | Сводная функция |
| `05b_CREATE_TABLE_spMstrg_2606_ResultSets.sql` | DDL `spMstrg_2606_ResultSet1..7` |
| `06_CREATE_PROCEDURE_spMstrg_2606.sql` | Процедура |
| `07_VERIFY_after.sql` | Проверочные запросы после применения |
| `08_ROLLBACK.sql` | DROP `_2606` объектов + DROP TABLE `ipgChRlV` |
| `MSSQL2012/` | Зеркало для продуктива |

---

## Структурный план (оптимальная последовательность)

> **Переупорядочен 2026-06-11** с учётом анализа производительности: `fnMasteringFact*_2606` (03b1) является критическим узким местом и должен предшествовать MSTVF-конверсии fn2_2606.

### Этап 0 — Подготовка и уточнение вводных ✅

- [x] **0.1** Q1–Q4 отвечены ✅  
- [x] **0.2** Проверить `fnStDownAll` на тестовом примере ✅  
- [x] **0.3** Зафиксировать эталонные COUNT ✅  
- [x] **0.4** Анализ стека `fnMasteringStIpgStCost` и данных для `@stCostKey` ✅  
- [x] **0.5** Выбор тестовой цепи для разработки → цепь 5 ✅

### Этап 1b — Суперкласс `factDoc` (все типы документов, шаг 1) ✅

- [x] **1b.1** DDL `01b_CREATE_TABLE_factDoc.sql`: `factDoc`, `factDocCost`, `*_fdKey` в 6 подклассах ✅  
  **Исполнено (2026-06-05):** dev + `MSSQL2012/`; применено на FishEye.
- [x] **1b.2** Триггеры `01c_CREATE_TRIGGER_factDoc_sync.sql` ✅  
  **Исполнено:** 6 триггеров; smoke-test ra_summ OK.
- [x] **1b.3** Бэкфилл `01d_BACKFILL_factDoc.sql` ✅  
  **Исполнено:** 79 755 factDoc; 112 142 factDocCost; 0 строк без `*_fdKey`.
- [x] **1b.3b** Проверка задвоения `ra_summ`/`ra_summCt` → политика **B+F** ✅  
- [x] **1b.4** `fnStCost*_2606` в `03b0_CREATE_FUNCTION_fnStCost_2606.sql` ✅  
  **Исполнено (2026-06-09):** 6 функций; dev + `MSSQL2012/`; применено.
- [x] **1b.5** Приёмка F: `07b_VERIFY_fnStCost_2606.sql` — 0 расхождений ✅  
  **Исполнено (2026-06-09):** RA 19 123 / 0 расх.; RaCh 772 / 0; AgFee/Ralp/PrDoc/Mnrl — 0.

### Этап 1 — Таблица `ipgChRlV` ✅

- [x] **1.1** Создать DDL `01_CREATE_TABLE_ipgChRlV.sql` ✅  
- [x] **1.2** Заполнить цепи 5 (dev) и 15 (пилот продуктива) ✅  
- [x] **1.3** Проверить: концы актуальности не перекрываются ✅

### Этап 2 — `fnIpgChDatsV` ✅

- [x] **2.1** `02_CREATE_FUNCTION_fnIpgChDatsV.sql`; цепь 5: 17 дат ✅  
- [x] **2.2** Доп. цепь 15: точка разрыва 2025-07-16; сравнение с legacy ✅

### Этап 3 — Промежуточные функции стека `fnMasteringStIpgStCost` ✅

- [x] **3a0** `fnStCostIpgPn_2606`: точность лимита decimal(23,8) ✅  
- [x] **3a** `fnStCostRsIpgPn_2606`: фикс Деф.Б + fallback ✅  
- [x] **3b** `fnStCostRsCstAgPn_2606`: использует `_2606`-подфункцию ✅  
- [x] **3c** `fnMasteringCstAgPnSh_2606` + `fnMasteringCstAgPn_2606`: работоспособны, лимиты через `_2606` ✅  
  **Заметка:** на момент создания вызывали LEGACY `fnMasteringPresRa` и др. Производительность неприемлема (42 мин для 164 контрактов). Будет исправлено в Этапе 3b1.
- [x] **3d** `fnMasteringStIpgStCost_2606`: фикс Деф.А; `@ipgStKey`/`@stCostKey` nullable ✅  
- [x] **3e** Тест `fnMasteringStIpgStCost_2606(21, 5, NULL, NULL)`: COUNT 799=799 ✅

### Этап 4 — `fnIpgChRsltCstUtl2_2606` (fn2_2606) — частично ✅

- [x] **4.1** ITVF v1 (2026-06-09): метаданные месяца/ИПГ, совместимость с `_2605` ✅  
- [x] **4.2 (частично)** Тесты на цепи 5:
  - 07h stIpg=61 — **PASS** ✅
  - 07h stIpg=46 (v7: raFactRalp + raFactStorage) — **PASS** (2026-06-11) ✅ `proxy05=fn2_2606=5479, miss=0, extra=0, vdiff=0`
  - 07e (baseline): **PASS** ✅
  - 07f (PercentBrn full): прогон не завершён (производительность). Отложено до Этапа 3b1+perf.

### Этап 0.perf — Индексы производительности ⬜

> **Новый этап (2026-06-11), нулевой риск, выполнить немедленно**

- [ ] **0.perf.1** Добавить `IX_ipgStPn_St_Pn`:
  ```sql
  CREATE INDEX IX_ipgStPn_St_Pn ON ags.ipgStPn (ipgspSt, ipgspPn);
  ```
  Применяется: EXISTS-фильтрация в `fnMasteringStIpgStCost_2606`.
- [ ] **0.perf.2** Добавить `IX_cstAgPnBranch_Cst`:
  ```sql
  CREATE INDEX IX_cstAgPnBranch_Cst ON ags.cstAgPnBranch
      (cstapbCstAgPn) INCLUDE (cstapbBranch, cstapbStart, cstapbEnd);
  ```
  Применяется: `fnCstAgPnBranch` + будущий CTE-кэш в fn2_2606.

### Этап 3b1 — `fnMasteringFact*_2606`: новые функции факта через `factDocCost` ⬜

> **Критический приоритет. Главный рычаг производительности: ×70–140.**  
> Одновременно реализует Вариант 6А из `04-computation-map.md` (Ret/InProc/NotArr).

**Файл:** `03b1_CREATE_FUNCTION_fnMasteringFact_2606.sql`

#### 3b1.1 — Pres/Accp функции (~18 штук): замена LEGACY

| Новая функция | Прототип (legacy) | Отличие от прототипа |
|---------------|-------------------|----------------------|
| `fnMasteringPresRa_2606(@dAll, @cac, @stCost, @stNet, @subAg)` | `fnMasteringPresRa` | Источник: `factDocCost` через `fnStCostRa_2606`; не `fnStCostRa` |
| `fnMasteringAccpRa_2606` | `fnMasteringAccpRa` | то же |
| `fnMasteringPresRaMn_2606` | `fnMasteringPresRaMn` | то же |
| `fnMasteringAccpRaMn_2606` | `fnMasteringAccpRaMn` | то же |
| `fnMasteringPresAgFee_2606` | `fnMasteringPresAgFee` | `factDocCost` через `fnStCostAgFee_2606` |
| `fnMasteringAccpAgFee_2606` | `fnMasteringAccpAgFee` | то же |
| `fnMasteringPresAgFeeMn_2606` | `fnMasteringPresAgFeeMn` | то же |
| `fnMasteringAccpAgFeeMn_2606` | `fnMasteringAccpAgFeeMn` | то же |
| `fnMasteringPresRalp_2606` | `fnMasteringPresRalp` | `factDocCost` через `fnStCostRalp_2606` |
| `fnMasteringAccpRalp_2606` | `fnMasteringAccpRalp` | то же |
| `fnMasteringPresRalpMn_2606` | `fnMasteringPresRalpMn` | то же |
| `fnMasteringAccpRalpMn_2606` | `fnMasteringAccpRalpMn` | то же |
| `fnMasteringAccpStor_2606` | `fnMasteringAccpStor` | `factDocCost` через `fnStCostPrDoc_2606` |
| `fnMasteringAccpStorMn_2606` | `fnMasteringAccpStorMn` | то же |
| `fnMasteringAccpControl_2606` | `fnMasteringAccpControl` | `factDocCost` через `fnStCostPrDoc_2606` |
| `fnMasteringAccpControlMn_2606` | `fnMasteringAccpControlMn` | то же |
| `fnMasteringAccpMnrl_2606` | `fnMasteringAccpMnrl` | `factDocCost` через `fnStCostMnrl_2606` |
| `fnMasteringAccpMnrlMn_2606` | `fnMasteringAccpMnrlMn` | то же |

#### 3b1.2 — Новые функции Ret/InProc/NotArr/PresAll (~25 штук, Вариант 6А)

| Группа | Функции | Источник | rsltOfConsider |
|--------|---------|----------|----------------|
| RA returned | `fnMasteringRetRa_2606`, `RetRaMn_2606` | factDocCost | `'returned'` |
| RA inProcess | `fnMasteringInProcRa_2606`, `InProcRaMn_2606` | factDocCost | `'in process'` |
| RA notArrived | `fnMasteringNotArrRa_2606`, `NotArrRaMn_2606` | factDocCost | `'not arrived'` |
| RA PresAll | `fnMasteringPresAllRa_2606`, `PresAllRaMn_2606` | factDocCost | все |
| RA PrevYears | `fnMasteringPrevYrPresRa_2606`, … (5 шт.) | factDocCost | complianceY |
| АВ returned | `fnMasteringRetAgFee_2606`, `RetAgFeeMn_2606` | factDocCost | `'returned'` |
| АВ inProcess | `fnMasteringInProcAgFee_2606`, `InProcAgFeeMn_2606` | factDocCost | `'in process'` |
| АВ notArrived | `fnMasteringNotArrAgFee_2606`, `NotArrAgFeeMn_2606` | factDocCost | `'not arrived'` |
| РАЛП returned | `fnMasteringRetRalp_2606`, `RetRalpMn_2606` | factDocCost | `'returned'` |
| РАЛП inProcess | `fnMasteringInProcRalp_2606`, `InProcRalpMn_2606` | factDocCost | `'in process'` |
| РАЛП notArrived | `fnMasteringNotArrRalp_2606`, `NotArrRalpMn_2606` | factDocCost | `'not arrived'` |

#### 3b1.3 — Обновить `fnMasteringCstAgPnSh_2606` и `fnMasteringCstAgPn_2606`

- Заменить все вызовы legacy `fnMasteringPresRa(...)` → `fnMasteringPresRa_2606(...)`
- Добавить вызовы новых Ret/InProc/NotArr/PresAll функций в соответствующие колонки SELECT
- Обновить `03c_CREATE_FUNCTION_fnMasteringCstAgPnSh_2606.sql`

#### 3b1.4 — Приёмка производительности

- [ ] Запустить `07h stIpg=46` с замером времени. **Цель: < 60 сек** (было 2 553 сек).
- [ ] Записать результат в этот план.

### Этап 4.perf — MSTVF fn2_2606 + CTE-кэш fnCstAgPnBranch ⬜

> **После 3b1. Устраняет ×4–5 re-evaluation schemeRows и scalar UDF fnCstAgPnBranch.**

**Файл:** `04_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2606.sql` (v8)

- [ ] **4.perf.1** Конвертировать fn2_2606 ITVF → **MSTVF**:
  - Добавить `CREATE TABLE #schemeRows (...)` и `INSERT INTO #schemeRows` из `mastering`-CTE
  - Заменить все обращения к CTE `schemeRows` на `#schemeRows`
- [ ] **4.perf.2** Материализовать `raFact2408` в `#raFact` для устранения повторного пересчёта VIEW
- [ ] **4.perf.3** Добавить CTE-кэш вместо `fnCstAgPnBranch`:
  ```sql
  branchCache AS (
      SELECT cstapbCstAgPn, MAX(cstapbBranch) AS branch
      FROM ags.cstAgPnBranch
      WHERE (cstapbEnd IS NULL OR cstapbEnd >= CAST(GETDATE() AS date))
        AND (cstapbStart IS NULL OR cstapbStart <= CAST(GETDATE() AS date))
      GROUP BY cstapbCstAgPn
  )
  ```
  Заменить все `ags.fnCstAgPnBranch(GETDATE(), x.cstKey)` → `bc.branch` через LEFT JOIN.
- [ ] **4.perf.4** Прогон 07h stIpg=46. **Цель: < 15 сек**.
- [ ] **4.perf.5** Прогон 07h stIpg=NULL (полная цепь 5 без фильтра). **Цель: < 2 мин**.

### Этап 4.verify — Финальная верификация fn2_2606 ⬜

- [ ] **4.2 (полная)** Тесты на цепи 5: `@ipgStKey=NULL`, `@ipgStKey=21`, `@stCostKey=NULL`, `@stCostKey=212`
- [ ] **4.3** Baseline `07e_COMPARE_baseline_chain5.sql`: lim=0, pres=0 ✅ (уже PASS, повторить после MSTVF)
- [ ] **4.4** `07f_COMPARE_PercentBrn_full_chain5.sql` — полный PercentBrn vs RS1. **Цель: PASS, < 10 мин.**

### Этап 5 — `fnIpgChRsltCstUtlPercentBrn_2606` ⬜

- [x] **5.1** Адаптировать `_2605` → `_2606`: `05_CREATE_FUNCTION_fnIpgChRsltCstUtlPercentBrn_2606.sql` ✅  
  **Исполнено (2026-06-10):** применено на FishEye dev.
- [ ] **5.2** Тесты COUNT на цепи 5 после 4.verify: 07f PASS

### Этап 6 — `spMstrg_2606` и таблицы ResultSet ⬜

- [ ] **6.0** Создать `05b_CREATE_TABLE_spMstrg_2606_ResultSets.sql` — `ags.spMstrg_2606_ResultSet1..7`
- [ ] **6.1** Создать `spMstrg_2606` по образцу `_2605`; TRUNCATE/INSERT **только** в `*_2606_ResultSet*`
- [ ] **6.2** Тест `@saveToTables=1` на цепи 5: COUNT в `spMstrg_2606_ResultSet1..7`
- [ ] **6.3** Тест `@saveToTables=0` на цепи 5: 7 рекордсетов (Access-режим)

### Этап 7 — Документация и приёмка ⬜

- [ ] **7.1** `docs/deployment/db-upgrade-spMstrg-2606.md`
- [ ] **7.2** `docs/deployment/db-upgrade-spMstrg-2606-deploy-day-checklist.md`
- [ ] **7.3** Проверить `MSSQL2012/`-зеркало скриптов (SQL Server 2012 SP4)
- [ ] **7.4** Обновить `docs/solutions/spMstrg_2408_execution.md` — раздел о `_2606`
- [ ] **7.5** Запись в `project-journal.json`
- [ ] **7.6** Создать резюме чата

---

## Контрольные точки

| Точка | Условие готовности | Статус |
|-------|--------------------|--------|
| К-0 | Q1–Q4 отвечены; анализ стека + данных завершён; цепь 5 выбрана | ✅ |
| К-1 | `ipgChRlV` создана, цепи 5 и 15 заполнены, перекрытий нет | ✅ |
| К-2 | `fnIpgChDatsV(5)` → 17 дат; доп.: `fnIpgChDatsV(15)` → точка разрыва 2025-07-16 | ✅ |
| К-2b | `factDoc`/`factDocCost` заполнены; `fnStCost*_2606` созданы и протестированы | ✅ |
| К-2c | Анализ производительности завершён; оптимальный порядок этапов зафиксирован | ✅ |
| К-perf | Индексы `IX_ipgStPn_St_Pn`, `IX_cstAgPnBranch_Cst` добавлены | ⬜ |
| К-3b1 | `fnMasteringFact*_2606` (~43 шт.) созданы; 07h stIpg=46 < 60 сек | ⬜ |
| К-3c | `fnMasteringCstAgPnSh_2606` обновлён; вызывает `fnMasteringFact*_2606` | ⬜ |
| К-4perf | fn2_2606 MSTVF v8; 07h stIpg=NULL < 2 мин | ⬜ |
| К-3 | `fnMasteringStIpgStCost_2606(NULL, 5, NULL, NULL)` — без задвоения ИПГ | ⬜ |
| К-4 | `fnIpgChRsltCstUtl2_2606` на цепи 5: все параметры; 07f PASS | ⬜ |
| К-5 | Полный `PercentBrn_2606` = `_2605` (RS1, все `dateRslt` 2022, ~14 447 строк) | ⬜ |
| К-6 | `spMstrg_2606`: RS1 полный; RS4–RS7 при `@MounthEndDate='2022-09-30'` | ⬜ |
| К-7 | Пакет передан: `db-upgrade-spMstrg-2606.md` + чеклист + `MSSQL2012/`-зеркало | ⬜ |

---

## Ссылки на документацию по производительности

| Документ | Содержание |
|----------|-----------|
| `docs/development/notes/sql/26-0604/docs/07-performance-analysis.md` | Полный анализ узких мест + предложения П1–П6 |
| `docs/development/notes/sql/26-0604/docs/04-computation-map.md` | Карта вычислений; §Шаг 5 пересмотрен (Решение 10) |
| `docs/development/notes/sql/26-0604/docs/05-fact-stcost-map.md` | Соответствие полей и stcKey для факт-функций |

---

## Справочная информация

### Ключевые объекты БД (существующие, используемые в `_2606`)

| Объект | Тип | Назначение в `_2606` |
|--------|-----|-----------------------|
| `ags.ipgChRl` | Таблица | Источник для миграции данных в `ipgChRlV` |
| `ags.ipgStPn` | Таблица | Связь `ipgPn.ipgpKey → stIpg.stiKey` (DAG-фильтрация Деф.А) |
| `ags.stIpg` / `ags.stIpgNm` | Таблицы | Узлы DAG структуры ИПГ (82 узла, 83 имени) |
| `ags.fnStDownAll` | Inline TVF | Все потомки узла в DAG-схеме |
| `ags.factDoc` / `ags.factDocCost` | Таблицы | Суперкласс документов факта; 79 755 / 112 142 строк (бэкфилл ✅) |
| `ags.RRcTimeList` | **VIEW** (UNION ALL, нет индексов) | Источник RA данных; 52 526 строк — читается в `raFact2408` CTE fn2_2606 |

### Тестовые параметры (основная разработка — цепь 5)

| Параметр | Значение | Описание |
|----------|----------|----------|
| `@ipgCh` | **5** | «Газпром, 2022-го года, полугодие» (3 ИПГ, богатые данные) |
| `@MounthEndDate` | `'2022-09-30'` | Эталонная дата |
| `@ipgStKey` | NULL / 21 / 46 / 61 | Все строки / «Объекты добычи газа» / тестовые подмножества |
| Контрактов в stIpg=46 | 164 | Быстрый тест-подмножество |
| Дат расчёта | 17 | 2022-01-01 + 12 концов мес. + 4 точки перехода ИПГ |

### Справка: дефект Б — цепь 15 *(исторический эталон, не тестовая цепь разработки)*

| ipg | ipgNm | ipgcrvStr (в ipgChRlV) | ipgcrvEnd (вычисл.) | ipgcrvUtPlGr |
|-----|-------|------------------------|---------------------|--------------|
| 25 | Одобренная | 2024-11-28 | 2025-07-15 | 17 |
| 26 | Письмо Д644 | 2025-07-16 | NULL | NULL ✅ |
