# Порядок работ: пакет `spMstrg_2606`

**Файл:** `docs/deployment/db-upgrade-spMstrg-2606.md`  
**Дата:** 2026-06-12  
**Версия:** 1.0  
**Автор:** Александр

**Краткий чеклист на день деплоя:** [`db-upgrade-spMstrg-2606-deploy-day-checklist.md`](db-upgrade-spMstrg-2606-deploy-day-checklist.md)

**Реестр продуктивного сервера:** `docs/project/project-docs.json` → `development.environments.machines.prod-fisheye`  
**Общие правила SQL для FishEye:** [`sql-server-deployment-rules.md`](sql-server-deployment-rules.md)

---

## 1. Назначение и область применения

Пакет внедряет стек **`_2606`** для отчёта об освоении с:

- корректной цепью ИПГ (`ipgChRlV`, `fnIpgChDatsV`);
- DAG-фильтрацией `@ipgStKey` / `@stCostKey` (int, NULL = без фильтра);
- ускоренным освоением через `factDocCost` и bundles;
- **отдельными** таблицами `spMstrg_2606_ResultSet1..7` (решение 8 — не трогаем `*_2408_ResultSet*`).

**Что меняется на продуктиве:**

| Компонент | Действие |
|-----------|----------|
| `ipgChRlV`, `factDoc`, `factDocCost`, триггеры | CREATE + бэкфилл |
| `fnStCost*_2606`, `fnMastering*_2606`, `fn2_2606`, `PercentBrn_2606` | CREATE |
| `spMstrg_2606_ResultSet1..7` | CREATE (схема как `_2408`) |
| `spMstrg_2606` | CREATE |
| `_2605`, `_2408`, `spMstrg_2408_ResultSet*` | **не изменяются** |

**Переключение клиентов** (Access / FEMSQ) на `_2606` — **отдельный этап** после SQL-приёмки (см. раздел 7).

---

## 2. Предварительные условия

| # | Условие | Проверка |
|---|---------|----------|
| 2.1 | SQL Server **2012 SP4+** на продуктиве | `SELECT @@VERSION` |
| 2.2 | Пакет **`MSSQL2012/`** (не корень `26-0604/`) | см. раздел 3 |
| 2.3 | `ags.spMstrg_2605` и `spMstrg_2408_ResultSet1..7` существуют | `00_VERIFY_before.sql` |
| 2.4 | Резервная копия БД `FishEye` | регламент DBA |
| 2.5 | Окно работ согласовано (~15–20 мин SQL + тест spMstrg) | |
| 2.6 | На dev пройдены К-8 (07f), К-9 (spMstrg_2606) | `chat-plan-26-0604-spMstrg-2606-v2.md` |

**Производительность (ориентир dev, цепь 5):**

| Операция | Время |
|----------|-------|
| `fn2_2606` stIpg=46 | ~50 с |
| `fn2_2606` полная цепь | ~4,5 мин |
| `spMstrg_2606` saveToTables=1 | ~5 мин |
| Полный отчёт (fn2 + PercentBrn + sp) | ~10–12 мин |

---

## 3. Состав пакета

**Корень (dev, SQL Server 2016+):** `docs/development/notes/sql/26-0604/`  
**Продуктив (SQL Server 2012):** `docs/development/notes/sql/26-0604/MSSQL2012/`

| # | Файл | Назначение |
|---|------|------------|
| 0 | `00_VERIFY_before.sql` | Состояние «до» |
| 0a | `00-perf-indexes.sql` | Индексы (опционально, низкий риск) |
| 1 | `01_CREATE_TABLE_ipgChRlV.sql` | Таблица цепи ИПГ |
| 1b | `01b_CREATE_TABLE_factDoc.sql` | factDoc / factDocCost |
| 1c | `01c_CREATE_TRIGGER_factDoc_sync.sql` | 6 триггеров синхронизации |
| 1d | `01d_BACKFILL_factDoc.sql` | Бэкфилл (~112K строк) |
| 1d1 | `01d1_FIX_factDocCost_ra_work_stCost.sql` | **Коррекция:** `ras_work`→stCost **195** (не 182); ~9,8k строк |
| 2 | `02_CREATE_FUNCTION_fnIpgChDatsV.sql` | Даты цепи |
| 3a0–3b | `03a0`, `03a`, `03b0`, `03b` | fnStCost*_2606 |
| 3b1 | `03b1_CREATE_FUNCTION_fnMasteringFact_2606.sql` | 43 fnMastering* + bundles |
| 3c–3d | `03c`, `03d` | CstAgPnSh, StIpgStCost |
| 4 | `04_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2606.sql` | fn2 v9.0 (MSTVF) |
| 5 | `05_CREATE_FUNCTION_fnIpgChRsltCstUtlPercentBrn_2606.sql` | PercentBrn |
| 5b | `05b_CREATE_TABLE_spMstrg_2606_ResultSets.sql` | ResultSet1..7 |
| 6 | `06_CREATE_PROCEDURE_spMstrg_2606.sql` | Процедура |
| 7 | `07_VERIFY_after.sql` | Проверка «после» |
| — | `08_ROLLBACK.sql` | Откат (только при сбое) |

**Примечание:** `03b1` в `MSSQL2012/` — автоконвертация `CREATE OR ALTER` → `DROP` + `CREATE`.

---

## 4. Порядок выполнения (SQL)

```
1.  Резервная копия FishEye
2.  00_VERIFY_before.sql
3.  00-perf-indexes.sql          (рекомендуется)
4.  01 … 01d                     (ipgChRlV + factDoc)
4a. 01d1                         (если 01d уже применялся с work→182 — коррекция factDocCost)
5.  02 … 03d                     (функции освоения)
6.  03b1                         (bundles — долго, ~2–5 мин)
7.  04, 05                       (fn2, PercentBrn)
8.  05b, 06                      (ResultSet + spMstrg_2606)
9.  07_VERIFY_after.sql
10. 07_VERIFY_spMstrg_2606_chain5.sql  (полный прогон spMstrg, ~5 мин)
```

На продуктиве скрипты применяет **администратор БД**.

---

## 5. Приёмочные критерии (цепь 5, `'2022-09-30'`)

| Проверка | Ожидание (dev) |
|----------|----------------|
| `fnIpgChRsltCstUtlPercentBrn_2606(5,NULL,NULL)` COUNT | **14447** |
| `07f` F.3 dedup field_diff | **0** |
| `spMstrg_2606` save=1 RS1 | **14447** |
| `spMstrg_2606` save=1 RS4 | **904** |
| `_2605` / `_2408` объекты | на месте |
| `spMstrg_2408_ResultSet*` | не перезаписаны `_2606` |
| `01d1` / `07j`: `regression_182` | **0** (после этапа 13) |

---

## 6. Откат

`08_ROLLBACK.sql` — удаляет объекты `_2606` и `spMstrg_2606_ResultSet*`.  
**Не затрагивает** `_2605`, `_2408`, `spMstrg_2408_ResultSet*`.

---

## 7. Переключение клиентов (после SQL-приёмки)

| Клиент | Действие |
|--------|----------|
| **FEMSQ** | Новый `execute_spMstrg_2606.sh` → `spMstrg_2606`, таблицы `*_2606_ResultSet*` |
| **MS Access** | `Form_ipgChMin`: `spMstrg_2606`, `@ipgStKey`, `@saveToTables=0` |
| **JasperReports** | Смена источника на `spMstrg_2606_ResultSet*` |

Детали Access — по аналогии с [`db-upgrade-spMstrg-2605.md`](db-upgrade-spMstrg-2605.md) §6, с заменой `@ipgSt nvarchar` на `@ipgStKey int`.

---

## 8. Ссылки

- План разработки: `docs/development/notes/chats/chat-plan/chat-plan-26-0604-spMstrg-2606-v2.md`
- Архитектура: `docs/development/notes/sql/26-0604/docs/03-design-decisions.md`
- Стратегия тестов: `docs/development/notes/sql/26-0604/docs/08-testing-strategy.md`
