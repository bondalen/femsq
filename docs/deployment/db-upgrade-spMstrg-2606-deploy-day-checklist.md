# Чеклист: день деплоя `spMstrg_2606` на продуктив

**Дата деплоя:** _______________ (пока не назначена)  
**lastUpdated:** 2026-06-30 (целевые имена Решение 21; этап **21.5** → пересборка флешки)
**Ответственный (SQL):** Александр  
**Среда:** продуктив FishEye, **Windows Authentication**, **SSMS**  
**Доставка пакета:** флеш-носитель `{YY-MMDD}_deploy/` (см. [`sql-flash-drive-packaging.md`](sql-flash-drive-packaging.md))

> Полный порядок: [`db-upgrade-spMstrg-2606.md`](db-upgrade-spMstrg-2606.md)  
> SQL-пакет (2012): `docs/development/notes/sql/26-0604/MSSQL2012/`  
> Сборка флешки: `docs/development/notes/sql/26-0604/26-0616_deploy/build_flash_package.sh`  
> Dev-приёмка: `run_acceptance_dev_chain5.sh` @ `'2022-12-31'`

### Подготовка флешки (на nb-win, до поездки к серверу)

Собрать пакет скриптом и скопировать каталог `26-0616_deploy/` на носитель:

```bash
cd docs/development/notes/sql/26-0604/26-0616_deploy
./build_flash_package.sh
# С паролем на архив (пароль — отдельно от флешки):
DEPLOY_ARCHIVE_PASSWORD='…' ./build_flash_package.sh --zip-password
```

| На флешке | Содержимое |
|-----------|------------|
| `open/01_MSSQL2012/` | все скрипты 00–08, **09a–09c** (UtPl), 04b, 05b, 06b, 03b1b, 00-perf-indexes* |
| `open/02_acceptance/` | `07_VERIFY_spMstrg_2606_chain5.sql`, `07_VERIFY_spFn2_schema.sql` |
| `open/03_docs/` | **PDF** чеклиста + `db-upgrade-spMstrg-2606.md` |
| `open/04_prod_log/` | шаблоны логов |
| `archive/*.zip` | ZIP-копия `open/` (+ `.sha256`) |
| `README_DEPLOY.txt`, `MANIFEST.sha256` | инструкция и контрольные суммы |

В SSMS: **File → Open** → скрипты по порядку; после каждого — проверить вкладку **Messages** на ошибки.

### Что можно сделать **сейчас** (только SSMS, без флешки)

Открыть в SSMS на prod и выполнить `MSSQL2012/00_VERIFY_before.sql` (скопировать из репозитория на nb-win) или минимум:

```sql
USE FishEye;
SELECT @@VERSION;
SELECT name, type_desc FROM sys.objects
WHERE schema_id = SCHEMA_ID('ags') AND name IN (
  'spMstrg_2605','spMstrg_2408_SaveToTables',
  'fnIpgChRsltCstUtl2_2605','fnIpgChRsltCstUtlPercentBrn_2605',
  'ipgChRl_2606','spMstrg_2606'
) ORDER BY name;
SELECT COUNT(*) AS rs2408_tables FROM sys.tables
WHERE schema_id = SCHEMA_ID('ags') AND name LIKE 'spMstrg_2408_ResultSet%';
```

Зафиксировать вывод в чеклист (раздел «Состояние до», ниже).

### Состояние до (заполнить из SSMS)

| Проверка | Результат | Дата |
|----------|-----------|------|
| `@@VERSION` | **11.0.7507.2** SP4-GDR, Standard 64-bit | 2026-06-16 |
| Сервер | **SPB-05-NV-SQL1**, Win 2012 R2, 32 GB / 16 CPU | 2026-06-16 |
| `spMstrg_2605` | **EXISTS** | 2026-06-16 |
| `fn2_2605`, `PercentBrn_2605` | **EXISTS** | 2026-06-16 |
| `_2606` объекты | **нет** (ожидается) | 2026-06-16 |
| `stIpgOutLimPn_2606` | **нет** до `10a` | 2026-06-30 |
| `ipgChRl` | EXISTS (источник для 01) | 2026-06-16 |
| RS `_2408` таблиц | **7** | 2026-06-16 |

---

## Перед началом

| # | Действие | ✓ | Примечание |
|---|----------|---|------------|
| 0.1 | Окно работ согласовано | ☐ | ~20 мин SQL + ~10 мин spMstrg |
| 0.2 | Резервная копия `FishEye` | ☐ | ID: __________ |
| 0.3 | Пакет **`26-0616_deploy/`** на **флешке** | ☐ | `build_flash_package.sh` |
| 0.4 | Dev: **К-9, К-9b** PASS @ `2022-12-31` | ☐ | RS1=14447, RS4=916; доп. @ `11-30` RS4=905 |
| 0.5 | `spMstrg_2605` / `_2408` работают | ☐ | |

---

## Часть A — SQL Server

| # | Скрипт | ✓ | Результат |
|---|--------|---|-----------|
| A.1 | `00_VERIFY_before.sql` | ☐ | _2605 OK |
| A.2 | `00-perf-indexes.sql`, `00-perf-indexes-k7.sql` | ☐ | |
| A.3 | `01` … `01d1` | ☐ | work→195 |
| A.4 | `02` … `03d`, `03b1`, `03b1b` | ☐ | CostBase |
| A.5 | `04`, `05` | ☐ | fn2 + PercentBrn |
| A.5a | `05a_PATCH_PercentBrn_fnIpgChDats_2606` | ☐ | календарь 17 дат (этап 20) |
| A.5b | `05b_PATCH_PercentBrn_ipgChRl_2606` | ☐ | plan-JOIN → `ipgChRl_2606` (**21.2**, после rename **21.1**) |
| A.6 | `04b`, `05b` (опционально) | ☐ | spFn2 path |
| A.7 | `05b` (таблицы), `06` или `06b` | ☐ | fn-path рекомендуется до gate |
| A.8 | `07_VERIFY_after.sql` | ☐ | |
| A.9 | `07_VERIFY_spFn2_schema.sql` | ☐ | если A.6 |
| A.10 | **09 UtPl:** `09a` → `09b` → `09c` | ☐ | аудит `lim<=0` → очистка (с компенсацией SUM) → CHECK `lim>0` |
| A.11 | `07_VERIFY_spMstrg_2606_chain5.sql` @ `2022-12-31` | ☐ | RS1=____ RS4=____ |
| A.12 | `08_ROLLBACK.sql` | ☐ | только откат |

**Эталон (цепь 5, `2022-12-31`, dev):**

| Метрика | Ожидание |
|---------|----------|
| PercentBrn_2606 COUNT | 14447 |
| `07k` RS1 keyDiff | 0 |
| spMstrg_2606 RS1 / RS4 | 14447 / 916 |
| `_2408_ResultSet1` COUNT | без изменений vs до деплоя |

---

## Часть B — Клиенты (после A.11)

| # | Действие | ✓ |
|---|----------|---|
| B.1 | FEMSQ: `spMstrg_2606` + `*_2606_ResultSet*` | ☐ |
| B.2 | Access: `spMstrg_2606`, `@ipgStKey`, save=0 | ☐ |
| B.3 | Smoke-тест отчёта | ☐ |

---

## После деплоя

| # | Действие | Когда |
|---|----------|-------|
| D.1 | Мониторинг 1–2 недели | |
| D.2 | Переключение prod-клиентов с `_2605` на `_2606` | по решению |
| D.3 | Запись в project-journal | |

**Подпись DBA:** _______________  **Дата:** _______________
