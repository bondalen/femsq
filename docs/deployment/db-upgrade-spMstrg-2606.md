# Порядок работ: пакет `spMstrg_2606`

**Файл:** `docs/deployment/db-upgrade-spMstrg-2606.md`  
**Дата:** 2026-06-12  
**lastUpdated:** 2026-06-26  
**Версия:** 1.4  
**Автор:** Александр

**Краткий чеклист на день деплоя:** [`db-upgrade-spMstrg-2606-deploy-day-checklist.md`](db-upgrade-spMstrg-2606-deploy-day-checklist.md)

**Реестр продуктивного сервера:** `docs/project/project-docs.json` → `development.environments.machines.prod-fisheye`  
**Общие правила SQL для FishEye:** [`sql-server-deployment-rules.md`](sql-server-deployment-rules.md)  
**Dev-приёмка:** [`docs/development/notes/sql/26-0604/docs/12-dev-acceptance-protocol.md`](../development/notes/sql/26-0604/docs/12-dev-acceptance-protocol.md)

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
| `spMstrg_2606` | CREATE (fn-path: `06`; SP-path: `06b` после gate spFn2) |
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
| 2.6 | На dev пройдены **К-9, К-9b** @ `'2022-12-31'` | `run_acceptance_dev_chain5.sh` |
| 2.7 | *(рекомендуется перед финальной сборкой флеша)* На dev PASS **К-12, К-13** (планы UtPl по stCost) | `13-plan-stcost-monthly-acceptance.md`, `--with-plan-stcost` |

---

## 3. Состав пакета

**Корень (dev, SQL Server 2016+):** `docs/development/notes/sql/26-0604/`  
**Продуктив (SQL Server 2012):** `docs/development/notes/sql/26-0604/MSSQL2012/`

| # | Файл | Назначение |
|---|------|------------|
| 0 | `00_VERIFY_before.sql` | Состояние «до» |
| 0a | `00-perf-indexes.sql`, `00-perf-indexes-k7.sql` | Индексы |
| 1–1d1 | `01` … `01d1` | ipgChRlV + factDoc + work→195 |
| 2–3d | `02` … `03d` | fnStCost, mastering |
| 3b1, 3b1b | bundles CostBase (этап 14.2) | |
| 4, 4b | fn2 MSTVF + **spFn2** (ступень 3) | prod: `04b` |
| 5, 5b | PercentBrn fn + **sp** | prod: `05b` (INSERT EXEC spFn2) |
| 5b | `05b_CREATE_TABLE_spMstrg_2606_ResultSets.sql` | ResultSet1..7 |
| 6, 6b | spMstrg fn-path / **SP-path** | dev: `06`; prod TBD после `07_VERIFY_spFn2_schema` |
| 6c | `06c_FIX_spMstrg_ROWCOUNT_logging.sql` | Патч лога saveToTables (опционально для `_2605`) |
| 7 | `07_VERIFY_after.sql` | Объекты «после» |
| — | `07_VERIFY_spFn2_schema.sql` | Gate: fn2 ↔ spFn2 INSERT EXEC |
| 9a–9c | `09a_utpl_audit_zero_negative.sql` | Аудит UtPl `lim<=0` (READ ONLY) |
| | `09b_utpl_cleanup_nonpositive.sql` | Очистка нулей/отрицательных (компенсация SUM) |
| | `09c_utpl_enable_check_constraints.sql` | CHECK `lim > 0` на Mn/Qu/Ye |
| — | `07k`, `07l`, `run_acceptance_dev_chain5.sh` | Dev-приёмка |
| — | `08_ROLLBACK.sql` | Откат |

**Синхронизация MSSQL2012:** `_sync_to_mssql2012.py` (из dev `03c`, `03b1`).

---

## 4. Порядок выполнения (SQL)

```
1.  Резервная копия FishEye
2.  00_VERIFY_before.sql
3.  00-perf-indexes.sql + 00-perf-indexes-k7.sql
4.  01 … 01d1
5.  02 … 03d, 03b1 (+ 03b1b CostBase на prod)
6.  04, 04b (опционально spFn2)
7.  05, 05b
8.  05b (таблицы), 06 или 06b
9.  07_VERIFY_after.sql
10. 07_VERIFY_spFn2_schema.sql      (если 04b/05b/06b)
11. 09a → 09b → 09c                 (UtPl: аудит → очистка → CHECK lim>0)
12. run_acceptance / 07_VERIFY_spMstrg_2606_chain5 @ 2022-12-31
```

**Блок 09 (deploy-day, этап 17.3.1):** привести prod-данные UtPl к состоянию, эквивалентному dev после **18.8.3** (sparse, без `lim<=0`), затем включить CHECK. `09a` прерывает цепочку при обнаружении нарушений; `09b` удаляет нули и отрицательные значения с **компенсацией SUM** по `(plPn, stCost)`; `09c` включает `CK_*_gt0` (`lim > 0`).

На продуктиве скрипты применяет **администратор БД** (или владелец проекта через **SSMS**).

**Модель доставки (2026-06):** с рабочей станции `nb-win` продуктив **недоступен по сети**. Пакет собирается скриптом `26-0616_deploy/build_flash_package.sh` и копируется на флеш-носитель (структура `open/` + `archive/*.zip`). Порядок: [`sql-flash-drive-packaging.md`](sql-flash-drive-packaging.md). Выполнение на prod — **SSMS**, **Windows Authentication**.

---

## 5. Приёмочные критерии (цепь 5)

**Эталон dev @ `'2022-12-31'`** (RS4–RS7: окт–ноя–дек 2022):

| Проверка | Ожидание (dev) |
|----------|----------------|
| `07f` F.3 dedup | **0** |
| `07k` RS1 keyDiff | **0** |
| `07k` RS2–RS7 COUNT | совпадают с `_2605` |
| `spMstrg_2606` save=1 RS1 | **14447** |
| `spMstrg_2606` save=1 RS4 | **916** |
| `07_VERIFY_spFn2_schema` | PASS (B+C) перед `06b` |
| `_2605` / `_2408` | на месте, ResultSet `_2408` не перезаписаны |

**Примечание:** в логе spMstrg после `06c` — «Записей сохранено» = фактический COUNT (не 0).

---

## 6. Откат

`08_ROLLBACK.sql` — удаляет объекты `_2606` и `spMstrg_2606_ResultSet*`.  
**Не затрагивает** `_2605`, `_2408`, `spMstrg_2408_ResultSet*`.

---

## 7. Переключение клиентов (после SQL-приёмки)

| Клиент | Действие |
|--------|----------|
| **FEMSQ** | `execute_spMstrg_2606.sh` → `spMstrg_2606`, таблицы `*_2606_ResultSet*` |
| **MS Access** | `spMstrg_2606`, `@ipgStKey`, `@saveToTables=0` |
| **JasperReports** | Источник `spMstrg_2606_ResultSet*` |

Детали Access — по аналогии с [`db-upgrade-spMstrg-2605.md`](db-upgrade-spMstrg-2605.md) §6, с заменой `@ipgSt nvarchar` на `@ipgStKey int`.

---

## 8. Ограничения: помесячные планы по stCost

Разбивка уточнённого плана (`ipgUtPlPnLmMn`) по элементам структуры затрат **212 / 195 / 172 / 187** на продуктиве — **отдельная задача наполнения данных** (участие нескольких организаций, длительный срок).

| Среда | Поведение |
|-------|-----------|
| **Dev** | Тестовая разбивка через fixture `fixture/dev-chain5-utpl-stcost/`; приёмка **К-12** (план = лимит по каждому stCost) и **К-13** (212 = 172+187+195) @ `2022-12-31` |
| **Prod (deploy-day)** | **Без** fixture и без `07m`; только `MSSQL2012/` + `07_VERIFY` + smoke. Отсутствие UtPl@172/187/195 до наполнения — **не блокер** SQL-релиза |

Корректность стека по планам подтверждается на dev; см. `docs/development/notes/sql/26-0604/docs/13-plan-stcost-monthly-acceptance.md`.

---

## 9. Ссылки

- План: `docs/development/notes/chats/chat-plan/chat-plan-26-0604-spMstrg-2606-v2.md`
- Флеш-носитель: [`sql-flash-drive-packaging.md`](sql-flash-drive-packaging.md)
- Протокол dev-приёмки: `docs/development/notes/sql/26-0604/docs/12-dev-acceptance-protocol.md`
- Планы UtPl по stCost (К-12/К-13, dev-only): `docs/development/notes/sql/26-0604/docs/13-plan-stcost-monthly-acceptance.md`
- Архитектура RS: `docs/development/notes/sql/26-0604/docs/06-sp-recordsets-and-acceptance.md`
