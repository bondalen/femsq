# SQL-пакет 26-0721: Excel-строка staging type=6 (AgFee)

**Задача:** 0056  
**Chat-plan:** `docs/development/notes/chats/chat-plan/chat-plan-26-0720-agfee-type6.md`

## Изменения

| Объект | Изменение |
|--------|-----------|
| `ags.ra_stg_agfee` | `+ oafptRow INT NULL` — номер строки листа Excel (1-based), заполняется Stage 1 |

Нужен для diagnostic CstNo: одна стройка → список Excel-строк (как type=3/5).

## Порядок на abs / prod

1. Бэкап (prod обязателен).
2. `MSSQL2012/01_ALTER_ra_stg_agfee_excel_row.sql`
3. На abs также Liquibase при старте backend (`2026-07-21-ra-stg-agfee-excel-row.sql`) — идемпотентно.
