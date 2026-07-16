# DB upgrade: номер Excel-строки в staging RALP (26-0714 / 0051)

**Дата:** 2026-07-14  
**Пакет:** `docs/development/notes/sql/26-0714/` (+ `MSSQL2012/`)  
**Задача:** 0051, chat-plan §9.3.6.1

## Изменения

| Объект | Изменение |
|--------|-----------|
| `ags.ra_stg_ralp` | `+ ralprtRow INT NULL` |
| `ags.ra_stg_ralp_sm` | `+ ralprsRow INT NULL` |

Смысл: хранить 1-based номер строки листа Excel для построчных WARN в `adt_results` (type=3). Type=5 уже имеет `ags.ra_stg_ra.rainRow` (заполнение — §9.3.6.2).

## Порядок на abs / prod

1. Бэкап (prod обязателен).
2. `MSSQL2012/00_VERIFY_before.sql`
3. `MSSQL2012/01_ALTER_ra_stg_excel_row.sql`
4. `MSSQL2012/04_VERIFY_after.sql`
5. На abs также сработает Liquibase при следующем старте backend (`2026-07-14-ra-stg-excel-row.sql`) — идемпотентно.

## Откат

`MSSQL2012/05_ROLLBACK.sql` — только если колонки ещё не используются приложением.

## Статус abs (FishEye / Docker 2022)

Применено вручную через DBHub **2026-07-14** (см. журнал / VERIFY_after).
