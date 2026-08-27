# SQL: индекс `ags.cnInv(ciCn)` для page-списка СФ (T7 P1)

**Дата:** 2026-08-26  
**Задача:** 0071 / chat-plan-26-0826-contracts-inv §7 P1  
**Цель:** ускорить `WHERE ciCn = ?` + `COUNT` + `OFFSET/FETCH` для GraphQL `cnInvsByCn`.

## Скрипты

| Файл | Назначение |
|------|------------|
| `00_VERIFY_before.sql` | версия / есть ли индекс |
| `01_CREATE_IX_cnInv_ciCn.sql` | CREATE INDEX (dev: `IF NOT EXISTS`) |
| `04_VERIFY_after.sql` | индекс на месте |
| `05_ROLLBACK.sql` | DROP INDEX |
| `MSSQL2012/` | тот же набор без `IF NOT EXISTS` для prod |

## Применение на DEV

```bash
# через DBHub / sqlcmd на femsq-mssql
```

На nb-win DEV индекс применён в ходе P1 (2026-08-26).
