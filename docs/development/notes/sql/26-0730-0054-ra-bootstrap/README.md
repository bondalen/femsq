# 26-0730 — Prod bootstrap таблиц ревизий (задача 0054)

**Дата:** 2026-07-30  
**Целевой сервер:** `SPB-05-NV-SQL1` / БД `FishEye` / SQL Server **2012 SP4**  
**На prod применять только:** `MSSQL2012/`

## Принцип

| Источник | Роль |
|----------|------|
| Access prod (локальные `ra_*`) | метаданные ревизий: поля, ключи, данные |
| FEMSQ Java (`JdbcRa*Dao`, staging) | обязательные доп. поля (`adt_staging_log_level`, `*_created`/`*_updated`, staging) |
| Docker `10.7.0.3` | **не** эталон для копирования на prod |

Запрещено: `DROP TABLE`, `USE [femsq]`, `CREATE OR ALTER`, `DROP IF EXISTS`.  
Локальную Access `ra_a` **не** перелинковывать.

## Порядок на prod (SSMS, БД FishEye)

1. `MSSQL2012/00_VERIFY_before.sql`
2. `01_CREATE_lookups.sql` → `02_CREATE_ra_core.sql` → `03_CREATE_staging.sql` → `04_CREATE_mapping.sql`
3. `05_SEED_lookups_minimal.sql` → `06_SEED_mapping.sql`
4. `07_VERIFY_after.sql`
5. Импорт данных Access (**0054.4**, см. `IMPORT_PLAN.md`) — отдельно
6. Идемпотентные ALTER из очереди 0054.5 (26-0709 / 26-0714 / 26-0720 / 26-0721) — должны дать Skip, если CREATE уже включил колонки

## Состав CREATE

- Access-ядро: `ra_at`, `ra_dir`, `ra_ft`, `ra_ft_st`, `ra_a`, `ra_f`, `ra_ft_s`, `ra_ft_sn`
- FEMSQ: `adt_staging_log_level`, audit-колонки `*_created`/`*_updated`, `ft_s_period` как `NVARCHAR(50)` (Java `getNString`; при импорте из Access Number → `CAST`)
- Staging: `ra_execution`, `ra_stg_ra`, `ra_stg_ralp`, `ra_stg_ralp_sm`, `ra_stg_agfee` (+ финальные `ralprtRow`/`ralprsRow`/`oafptRow`/`oafpt*Key`)
- Mapping FEMSQ: `ra_sheet_conf`, `ra_col_map` + seed (нужны Stage 1)

Опционально позже: `ra_stg_cn_prdoc` (type=2) — не в минимальном контуре 0054.1.
