# SQL-пакет 26-0714: номер строки Excel в staging RALP (задача 0051)

**Дата:** 2026-07-14  
**Задача:** `0051` / chat-plan §9.3.6.1  
**Цель:** колонки `ralprtRow` / `ralprsRow` — номер строки листа Excel (1-based) для построчных аномалий в логе ревизии.

| Колонка | Таблица | Назначение |
|---------|--------|------------|
| `ralprtRow` | `ags.ra_stg_ralp` | Excel-строка type=3 (аналог `rainRow` в `ra_stg_ra`) |
| `ralprsRow` | `ags.ra_stg_ralp_sm` | Excel-строка сводного листа «учет_аренды» |

`rainRow` в `ags.ra_stg_ra` уже существует (DDL 2026-03-20); этот пакет его **не** меняет — заполнение Stage 1 — §9.3.6.2.

## Применение

| Контур | Папка |
|--------|--------|
| Dev (SQL Server 2022 / abs) | корень `26-0714/` **или** `MSSQL2012/` (идентичный DDL) |
| Prod (SQL Server 2012 SP4) | **только** `MSSQL2012/` |

Порядок: `00_VERIFY_before` → `01_ALTER_…` → `04_VERIFY_after`. Откат: `05_ROLLBACK`.

Liquibase (авто при старте backend): `code/.../db/changelog/changes/2026-07-14-ra-stg-excel-row.sql`.

## Совместимость

Скрипты используют `COL_LENGTH` + `ALTER TABLE … ADD` — совместимы с SQL Server **2012+**. Без `CREATE OR ALTER` / `DROP IF EXISTS`.
