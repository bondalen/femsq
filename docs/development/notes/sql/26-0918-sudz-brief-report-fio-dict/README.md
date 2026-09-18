# SQL: словарь FIO для краткого отчёта (БП 1.1.1.0)

**Дата:** 2026-09-18  
**WBS:** `1.1.1.0.3.1` — [chat-plan-26-0918](../../chats/chat-plan/chat-plan-26-0918-sudz-rslt-prod-mailing.md)  
**Домен:** [03-1_brief-report-pre-load.md](../../domain/sudz/03-1_brief-report-pre-load.md)  
**Источник seed:** `/mnt/nb-win-share/femsq/excel/2026_03/debit/1_отчёт_краткий/1_process.xlsm` → лист `Справочник` (named range `Словарь`)

## Объекты

| Объект | Назначение |
|--------|------------|
| `ags.fioDict` | Карточки имён (колонки A–F Excel): `fdName`…`fdPatrF`. Бизнес-имя «Словарь». |
| `ags.v_fioDictWord` | DISTINCT слова для порта `FioByDictionary` |

## Порядок применения

**Dev / prod:** `MSSQL2012/00` → `01` → `02` → `04`.  
Откат: `05_ROLLBACK.sql`.

Ожидаемо после seed: **211** строк `fioDict`, **~460** слов в `v_fioDictWord`.

## Статус применения

| Среда | DDL | Seed | Verify |
|-------|-----|------|--------|
| DEV (DBHub) | ✅ `ags.fioDict` + `ags.v_fioDictWord` | ✅ 211 / 460 | ✅ smoke Александр |
| Prod FishEye | ☐ пакет `MSSQL2012/` | ☐ | ☐ |

## Примечание

Физическое имя таблицы — `fioDict` (латиница, удобно для JDBC/GraphQL). В UI/доке — «Словарь».
