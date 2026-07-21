# SQL-пакет 26-0720: FK-ключи staging type=6 (AgFee)

**Задача:** 0055 / Фаза B  
**Chat-plan:** `docs/development/notes/chats/chat-plan/chat-plan-26-0720-agfee-type6.md`

## Изменения

| Объект | Изменение |
|--------|-----------|
| `ags.ra_stg_agfee` | `+ oafptOafSenderKey INT NULL` (`ogaKey`) |
| `ags.ra_stg_agfee` | `+ oafptPnCstAgPnKey INT NULL` (`cstapKey`) |

Колонка `oafptOgKey` сохраняется для совместимости, но Stage 2a больше **не** заполняет её из `ags.og.ogKey` (ошибочная модель).

## Порядок на abs / prod

1. Бэкап (prod обязателен).
2. `MSSQL2012/01_ALTER_ra_stg_agfee_fk_keys.sql`
3. На abs также Liquibase при старте backend (`2026-07-20-ra-stg-agfee-fk-keys.sql`) — идемпотентно.
