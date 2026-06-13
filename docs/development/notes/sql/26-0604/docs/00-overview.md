# spMstrg_2606 — Проектная документация задачи

**Дата начала:** 2026-06-04  
**Статус:** в разработке  
**Автор:** Александр  
**План чата:** `docs/development/notes/chats/chat-plan/chat-plan-26-0604-spMstrg-2606.md`  
**Предшествующая задача:** `docs/development/notes/sql/26-0508/` (`spMstrg_2605`)  
**Порядок работ на продуктиве:** `docs/deployment/db-upgrade-spMstrg-2606.md` *(создать в Этапе 7)*  
**Чеклист дня деплоя:** `docs/deployment/db-upgrade-spMstrg-2606-deploy-day-checklist.md` *(создать в Этапе 7)*

---

## Цель задачи и конечные результаты

Разработать и верифицировать SQL-объекты серии `_2606` на тестовой БД **FishEye** и сформировать **пакет для продуктивного сервера** — набор нумерованных `.sql`-скриптов и документ порядка работ, пригодный для самостоятельного применения на продуктиве (SQL Server 2012 SP4, `FishEye`).

| Артефакт | Путь | Этап |
|----------|------|------|
| SQL-скрипты создания объектов (dev) | `docs/development/notes/sql/26-0604/` | 1–6 |
| SQL-скрипты для продуктива (`MSSQL2012/`) | `docs/development/notes/sql/26-0604/MSSQL2012/` | 1–6 |
| Скрипт «до» + «после» + откат | `00_VERIFY_before.sql`, `07_VERIFY_after.sql`, `08_ROLLBACK.sql` | 1, 6, 1–6 |
| Таблицы FEMSQ `spMstrg_2606_ResultSet1..7` | `05b_CREATE_TABLE_spMstrg_2606_ResultSets.sql` | 6 |
| Порядок работ на продуктиве | `docs/deployment/db-upgrade-spMstrg-2606.md` | 7 |
| Краткий чеклист дня деплоя | `docs/deployment/db-upgrade-spMstrg-2606-deploy-day-checklist.md` | 7 |

---

## Суть задачи

В ходе разработки `spMstrg_2605` выявлены два архитектурных дефекта. Задача — создать `spMstrg_2606`, устраняющую оба дефекта, не затрагивая существующий код `_2605`.

### Дефект А — Фильтр `importIpgSt` не привязан к актуальной ИПГ

`importIpgSt_26-0320` содержит пары `(cst, cst_type)` без привязки к конкретной ИПГ. Фильтр в `fnIpgChRsltCstUtl2_2605` применяется ко всем строкам безотносительно того, какая `ipg` была актуальна на конкретную дату.

**Решение:** заменить `importIpgSt`-фильтр на DAG-обход через `ipgStPn` + `fnStDownAll` с параметром `@ipgStKey int`.

### Дефект Б — `ipgStr/ipgEnd` как атрибут `ipg`, а не `ipgChRl`

`ipg.ipgStr/ipgEnd` — глобальные атрибуты ИПГ, не зависящие от цепи. Из-за этого в месяцах 7–12 цепи 15 одновременно присутствуют `ipg=25` и `ipg=26` (716 + 690 строк вместо 690).

**Решение:** таблица `ags.ipgChRlV` + скалярный UDF `ags.fnIpgChRlVEnd`. `ipgcrvEnd` — вычисляемый столбец (`MIN(next.ipgcrvStr) − 1 день`); не хранится, не обновляется вручную. Прямой доступ к `ipgcrvEnd` через `ags.ipgChRlV` без дополнительного объекта-обёртки.

---

## Состав новых объектов БД

> **Пересмотрено 2026-06-04**: базовый стек — `fnMasteringStIpgStCost`, а не `fnIpgChRsltCstUtl_2408`.  
> Оба параметра `@ipgStKey` и `@stCostKey` включены в `_2606`.  
> **Уточнено 2026-06-04**: ~25 новых скалярных функций факта (Вариант 6А); итого ~37 объектов. Детали: `05-fact-stcost-map.md`.

**Суперкласс документов факта (Решение 9, шаг 1 — все типы):**

| Объект | Тип | Статус |
|--------|-----|--------|
| `ags.factDoc` | Таблица | ✅ `fdKey`, `fdDocType`, `fdNKey`; UQ `(fdDocType, fdNKey)` |
| `ags.factDocCost` | Таблица | ✅ `fdcoFd`, `fdcoStCost`, `fdcoSumm`; UQ `(fdcoFd, fdcoStCost)` |
| `*_fdKey` в 6 подклассах | Колонки FK | ✅ `ras_fdKey`, `racs_fdKey`, `oafp_fdKey`, `ralpra_fdKey`, `pdp_fdKey`, `am_fdKey` |
| `trg*SyncFactDoc` (×6) | Триггеры | ✅ `AFTER INSERT, UPDATE` + `UPDATE(column)` |
| `fnStCostRa/RaCh/AgFee/Ralp/PrDoc/Mnrl_2606` | Scalar UDF | ✅ читают `factDocCost` (политика **B+F**, §10); legacy не трогаем |

**Инфраструктура и основные функции:**

| Объект | Тип | Статус |
|--------|-----|--------|
| `ags.fnIpgChRlVEnd` | Scalar UDF | ✅ вычисляет `ipgcrvEnd` для computed column |
| `ags.ipgChRlV` | Таблица | ✅ цепи 5, 15 + `ipgcrvEnd` computed |
| `ags.fnIpgChDatsV` | Inline TVF | ✅ переходы из ipgChRlV |
| `ags.fnStCostRsIpgPn_2606` | Multi-stmt TVF | ✅ actuality ipgChRlV + fallback iuplpLim |
| `ags.fnStCostRsCstAgPn_2606` | Multi-stmt TVF | ✅ ipgChRlV + fnStCostRsIpgPn_2606 |
| `ags.fnMasteringCstAgPnSh_2606` | Multi-stmt TVF | ✅ fnMasteringCstAgPn_2606 + ipgChRlV |
| `ags.fnMasteringStIpgStCost_2606` | Inline TVF | ✅ ipgChRlV, nullable params |
| `ags.fnIpgChRsltCstUtl2_2606` | Inline TVF | ✅ FishEye dev; 07d PASS |
| `ags.fnIpgChRsltCstUtlPercentBrn_2606` | Multi-stmt TVF | ✅ создан; 07f FAIL (9668≠14447) |
| `ags.spMstrg_2606` | Stored Procedure | ⬜ не создан |
| `ags.spMstrg_2606_ResultSet1..7` | Таблицы | ⬜ не созданы (отдельно от `*_2408_ResultSet*`) |

**Новые скалярные функции факта (Вариант 6А, ~25 шт.)** — см. `05-fact-stcost-map.md`:

| Группа | Функции | Статус |
|--------|---------|--------|
| RA: returned/inProcess/notArrived (+Mn) | `fnMasteringRetRa`, `fnMasteringInProcRa`, `fnMasteringNotArrRa` (×2 с Mn) | ⬜ |
| RA: PrevYears (5 вариантов) | `fnMasteringPres/Accp/Ret/InProc/NotArrPrevYRa` | ⬜ |
| RA: PresentedAll (2 вар.) | `fnMasteringPresAllRa`, `fnMasteringPresAllModulRa` | ⬜ |
| АВ: returned/inProcess/notArrived (+Mn) | `fnMasteringRetAgFee`, `fnMasteringInProcAgFee`, `fnMasteringNotArrAgFee` (×2) | ⬜ |
| РАЛП: returned/inProcess/notArrived (+Mn) | `fnMasteringRetRalp`, `fnMasteringInProcRalp`, `fnMasteringNotArrRalp` (×2) | ⬜ |

---

## SQL-пакет (файлы в `docs/development/notes/sql/26-0604/`)

| Файл | Содержимое | Статус |
|------|-----------|--------|
| `00_VERIFY_before.sql` | Состояние БД до применения | ⬜ |
| `01_CREATE_TABLE_ipgChRlV.sql` | DDL + INSERT цепи 5, 15 | ✅ |
| `01b_CREATE_TABLE_factDoc.sql` | `factDoc`, `factDocCost`, `*_fdKey` | ✅ |
| `01c_CREATE_TRIGGER_factDoc_sync.sql` | Триггеры на 6 подклассах | ✅ |
| `01d_BACKFILL_factDoc.sql` | Миграция плоских полей + `ra_summCt` | ✅ |
| `02_CREATE_FUNCTION_fnIpgChDatsV.sql` | Генератор дат | ✅ |
| `03a_CREATE_FUNCTION_fnStCostRsIpgPn_2606.sql` | Фикс Деф.Б + fallback | ✅ |
| `03b0_CREATE_FUNCTION_fnStCost_2606.sql` | `fnStCostRa/RaCh/AgFee/Ralp/PrDoc/Mnrl_2606` (B+F) | ✅ |
| `07b_VERIFY_fnStCost_2606.sql` | Тест F: равенство legacy vs `_2606` | ✅ |
| `03b_CREATE_FUNCTION_fnStCostRsCstAgPn_2606.sql` | _2606-версия | ✅ |
| `03c_CREATE_FUNCTION_fnMasteringCstAgPnSh_2606.sql` | _2606-версия (+ fnMasteringCstAgPn_2606) | ✅ |
| `03d_CREATE_FUNCTION_fnMasteringStIpgStCost_2606.sql` | Фикс Деф.А + оба фильтра | ✅ |
| `07c_VERIFY_fnMasteringStIpgStCost_2606.sql` | Приёмка 3e (ipgStKey=21) | ✅ PASS |
| `07c_FULL_VERIFY_fnMasteringStIpgStCost_2606.sql` | Полный NULL-тест (680 строек) | ⬜ опционально |
| `04_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2606.sql` | Обёртка, метаданные | ✅ |
| `07d_VERIFY_fnIpgChRsltCstUtl2_2606.sql` | Приёмка 4 (ipgStKey=21) | ✅ PASS |
| `07e_COMPARE_baseline_chain5.sql` | Baseline compare A/B/C vs _2605 | ✅ A pres=0; lim 11; FAIL(1) |
| `07e1_DIAG_m9_presented_chain5.sql` | Диагностика m9: RRcTimeList vs PresRaMn | ✅ причина найдена |
| `07e2_COMPARE_fn2_single_cstAgPn.sql` | Точечное сравнение fn2 по `@cstAgPnKey` | ✅ инструмент |
| `05_CREATE_FUNCTION_fnIpgChRsltCstUtlPercentBrn_2606.sql` | PercentBrn / RS1 | ✅ создан |
| `07f_COMPARE_PercentBrn_full_chain5.sql` | Полный PercentBrn vs RS1 | ❌ 9668≠14447 |
| `05b_CREATE_TABLE_spMstrg_2606_ResultSets.sql` | DDL `spMstrg_2606_ResultSet1..7` | ⬜ |
| `06_CREATE_PROCEDURE_spMstrg_2606.sql` | Процедура → только `*_2606_ResultSet*` | ⬜ |
| `07_VERIFY_after.sql` | Проверки после применения | ⬜ |
| `08_ROLLBACK.sql` | Откат всех объектов | ⬜ |
| `MSSQL2012/` | Зеркало для продуктива (SQL Server 2012 SP4) | ⏳ до 04 включительно |

---

## Целевая сигнатура `spMstrg_2606`

```sql
EXEC ags.spMstrg_2606
    @ipgCh         int,           -- цепь ИПГ
    @MounthEndDate date,          -- последний день расчётного месяца
    @ipgStKey      int    = NULL, -- узел stIpg (NULL = без фильтра по разделу ИПГ)
    @stCostKey     int    = NULL, -- узел stCost (NULL = без фильтра по статье затрат)
    @saveToTables  bit    = 0     -- 0: SELECT×7 → Access; 1: INSERT → spMstrg_2606_ResultSet1..7
```

**Инварианты:**
- **Приёмка в этом чате — на цепи 5** (`@ipgCh=5`, `@MounthEndDate='2022-09-30'`)
- Опциональная регрессия дефекта Б на цепи 15: `spMstrg_2606(15, '2025-07-31', NULL, NULL)` ≈ `spMstrg_2605` с поправкой на исправленные дефекты (не блокер приёмки)
- `@stCostKey` проверяется на цепи 5 (`ipgPnLim` = 8 510 строк); на продуктиве для цепи 15 точная фильтрация — после наполнения `ipgPnLim` (шаг 2)
- **Параллельность (Решение 8):** `_2606` не пишет в `spMstrg_2408_ResultSet*`; `_2605`/`_2408` не изменяются. См. `docs/03-design-decisions.md §8`.

---

## Ход выполнения

### Этап 0 — Подготовка и уточнение вводных ✅

| Подэтап | Описание | Статус |
|---------|----------|--------|
| 0.1 | Ответы на вопросы Q1–Q4 | ✅ `docs/02-q1-q4-answers.md` |
| 0.2 | Тест DAG-обхода (`fnStDownAll`, узел 21) | ✅ `docs/02-q1-q4-answers.md` |
| 0.3 | Эталон дефекта Б: `_2605(15, NULL)` = 14 210 *(не тестовая цепь разработки)* | ✅ `docs/02-q1-q4-answers.md` |
| 0.4 | Анализ стека `fnMasteringStIpgStCost` + ipgPnLim + ipgUtPlPn* | ✅ `docs/03-design-decisions.md §7` |
| 0.5 | Выбор тестовой цепи: цепь 5 (8 510 строк ipgPnLim, 9 708 ipgUtPlPnLmMn) | ✅ `docs/02-q1-q4-answers.md §0.5` |

### Этап 1 — Таблица `ipgChRlV` ✅

| Подэтап | Описание | Статус |
|---------|----------|--------|
| 1.1 | DDL `01_CREATE_TABLE_ipgChRlV.sql` (+ `MSSQL2012/`) | ✅ |
| 1.2 | INSERT цепи 5 и 15 из `ipg.ipgStr` | ✅ |
| 1.3 | `ipgcrvEnd` = LEAD−1; перекрытий нет | ✅ |

### Этап 2 — `fnIpgChDatsV` ✅

| Подэтап | Описание | Статус |
|---------|----------|--------|
| 2.1 | Написать функцию; **цепь 5:** 17 дат | ✅ |
| 2.2 | **Доп. цепь 15:** точка разрыва; сравнить с `fnIpgChDats(15)` | ✅ |

### Этап 3 — Промежуточные функции стека ⬜

| Подэтап | Описание | Статус |
|---------|----------|--------|
| 3a | `fnStCostRsIpgPn_2606`: actuality через `ipgChRlV` + fallback `iuplpLim` | ✅ |
| 3b | `fnStCostRsCstAgPn_2606`: ipgChRlV + fnStCostRsIpgPn_2606 | ✅ |
| 3c | `fnMasteringCstAgPnSh_2606`: fnMasteringCstAgPn_2606 + ipgChRlV | ✅ 624/624 COUNT |
| 3d | `fnMasteringStIpgStCost_2606`: ipgChRlV, nullable @ipgStKey/@stCostKey | ✅ |
| 3e | Тест `(NULL,5,NULL,NULL)` + `@ipgStKey=21`: 799=799, 17 дат, agSmmTtl=0 | ✅ 07c PASS; FULL — опц. |

### Этап 4 — `fnIpgChRsltCstUtl2_2606` ✅

| Подэтап | Описание | Статус |
|---------|----------|--------|
| 4.1 | Обёртка: метаданные месяца/ИПГ, совместимость с `_2605` | ✅ |
| 4.2 | Тесты на **цепи 5**: `@ipgStKey=NULL/21`, `@stCostKey=NULL/212` | ✅ 07d PASS |

### Этап 5 — `fnIpgChRsltCstUtlPercentBrn_2606` ⬜

| Подэтап | Описание | Статус |
|---------|----------|--------|
| 5.1 | Адаптация `_2605` → `_2606`: заменить вызов `fn2` | ⬜ |
| 5.2 | Тесты COUNT на **цепи 5** по режимам параметров | ⬜ |

### Этап 6 — `spMstrg_2606` и таблицы ResultSet ⬜

| Подэтап | Описание | Статус |
|---------|----------|--------|
| 6.0 | DDL `spMstrg_2606_ResultSet1..7` (`05b_*.sql`) | ⬜ |
| 6.1 | `spMstrg_2606` — INSERT только в `*_2606_ResultSet*` | ⬜ |
| 6.2 | Тест `@saveToTables=1` на **цепи 5**: COUNT в `*_2606_*`; `_2605` не трогает `*_2408_*` | ⬜ |
| 6.3 | Тест `@saveToTables=0` на **цепи 5**: 7 рекордсетов | ⬜ |

### Этап 7 — Документация и приёмка ⬜

| Подэтап | Описание | Статус |
|---------|----------|--------|
| 7.1 | Создать `docs/deployment/db-upgrade-spMstrg-2606.md` — порядок работ на продуктиве | ⬜ |
| 7.2 | Создать `docs/deployment/db-upgrade-spMstrg-2606-deploy-day-checklist.md` | ⬜ |
| 7.3 | Проверить `MSSQL2012/`-зеркало скриптов (SQL Server 2012 SP4) | ⬜ |
| 7.4 | Обновить `docs/solutions/spMstrg_2408_execution.md` | ⬜ |
| 7.5 | Запись в `project-journal.json` | ⬜ |
| 7.6 | Резюме чата | ⬜ |

---

## Контрольные точки

| Точка | Условие готовности | Статус |
|-------|--------------------|--------|
| К-0 | Q1–Q4 отвечены; анализ стека + данных завершён | ✅ |
| К-1 | `ipgChRlV` создана, цепи 5 и 15 заполнены, нет перекрытий | ✅ |
| К-2 | `fnIpgChDatsV(5)` → 17 дат; доп.: `fnIpgChDatsV(15)` → точка разрыва 2025-07-16 | ✅ |
| К-3 | `fnMasteringStIpgStCost_2606(NULL,5,NULL,NULL)` без задвоения ИПГ по месяцам | ⬜ |
| К-4 | `fnIpgChRsltCstUtl2_2606` на **цепи 5**: `@ipgStKey=NULL/21`, `@stCostKey=NULL/212` | ✅ 07d |
| К-5 | Полный `PercentBrn_2606` = `_2605` (будущий **RS1**, все `dateRslt` 2022) | ⬜ |
| К-6 | `spMstrg_2606`: **RS1** полный; RS4–RS7 при `@MounthEndDate` (`@saveToTables=0/1`) | ⬜ |
| К-7 | Пакет передан: `db-upgrade-spMstrg-2606.md` + чеклист + `MSSQL2012/` | ⬜ |

---

## Детальная документация

| Файл | Содержимое |
|------|-----------|
| [`01-schema-analysis.md`](01-schema-analysis.md) | Анализ схемы БД: `st` vs `ipgSt`, `fnStDownAll` и паттерны |
| [`02-q1-q4-answers.md`](02-q1-q4-answers.md) | Ответы Q1–Q4, тестовые запросы, эталонные COUNT |
| [`03-design-decisions.md`](03-design-decisions.md) | Архитектурные решения, в т.ч. §8 — изоляция ResultSet и клиентов |
| [`04-computation-map.md`](04-computation-map.md) | Карта вычислений: какой стек — для лимита / плана / факта; решение «Разрыв 6А» |
| [`05-fact-stcost-map.md`](05-fact-stcost-map.md) | Поля документов факта → `stcKey`; статусные поля RA/АВ/РАЛП; перечень ~25 новых скалярных функций |
| [`06-sp-recordsets-and-acceptance.md`](06-sp-recordsets-and-acceptance.md) | Иерархия RS1..7, `@MounthEndDate`, контракт приёмки vs `_2605` |

---

## Тестовые параметры

**Основная разработка — цепь 5:**

| Параметр | Значение | Описание |
|----------|----------|----------|
| `@ipgCh` | **5** | «Газпром, 2022-го года, полугодие» (3 ИПГ) |
| `@MounthEndDate` | `2022-09-30` | Для **RS4–RS7** (Access): текущий + 2 пред. месяца; **не** для RS1 (полный год → Java) |
| Полный PercentBrn / RS1 | ~14 447 строк, 16 `dateRslt` | Эталон приёмки `_2606` (цепь 5, 2022) |
| `@ipgStKey` | NULL | Все стройки (без фильтра по разделу ИПГ) |
| `@ipgStKey` | 21 | «Объекты добычи газа» (листовой узел) |
| `@stCostKey` | NULL | Без фильтра по затратам |
| Дат расчёта | 17 | 2022-01-01 + 12 концов мес. + 4 точки перехода |
| `ipgPnLim` | 8 510 строк | Достаточно для проверки `@stCostKey` |
| `ipgUtPlPnLmMn` | 9 708 строк | Месячная декомпозиция лимитов |

**Дополнительно — цепь 15** *(только `ipgChRlV` + доп. проверка `fnIpgChDatsV`; не этапы 3–6):*

| Параметр | Значение | Описание |
|----------|----------|----------|
| `@ipgCh` | 15 | «Газпром, 2025-го + письмо Д644» (2 ИПГ) |
| Точка разрыва | 2025-07-16 | Доп. проверка генератора дат |
| Эталон дефекта Б (`_2605`) | 14 210 строк | Опциональная регрессия, не блокер приёмки |

---

## Этап 13 — исправление `ras_work` → stCost 195 ✅

| Пункт | Статус |
|-------|--------|
| Анализ регрессии `_2606(182)` vs legacy | ✅ 8 674 RA на dev (до фикса) |
| План миграции `01c`/`01d1`/`07j` | ✅ `docs/11-ra-work-stCost195-fix-plan.md` |
| SQL-правки и миграция на dev | ✅ `01c` + `01d1` (2026-06-13) |
| К-11: `07j` PASS, `regression_182=0` | ✅ stIpg=46; `07b` G-stCost195 PASS |

---

*Файл создан: 2026-06-04. Обновлён: 2026-06-13 (этап 13 stCost). Обновлять статусы по мере завершения этапов.*
