# 26-0919 — `cidufOpsProgress` (лог операций File свода)

**Дата:** 2026-09-19  
**Зачем:** отдельный HTML-журнал операций шапки `CnInvDbtUplFile` (H6 «Пересчитать стройки» и далее), без затирания `cidufLoadingProgress` (воронка).

| Схема | Колонка |
|-------|---------|
| `sudz.CnInvDbtUplFile` | `cidufOpsProgress nvarchar(max) NULL` |

**Prod:** только `MSSQL2012/01_ALTER_cidufOpsProgress.sql`.  
**DEV:** тот же скрипт (или уже применён на nb-win 2026-09-19).
