# impIpgLoad.iilResults — HTML-лог загрузки ИП

**Дата:** 2026-11-26 · **C2 §3.5.4** · контракт: [note](../../chats/chat-plan/notes/26-1126-c2-ipg-load-log-contract.md)

| Что | Где |
|-----|-----|
| Продуктив (2012 SP4) | `MSSQL2012/01_ALTER_impIpgLoad_iilResults.sql` |
| Копия для открытия/просмотра | `open/` (идентична `MSSQL2012/`) |

Добавляет `ags.impIpgLoad.iilResults nvarchar(max) NULL` (если колонки нет). Аналог `adt_results` для ревизий.

Применено на DEV `FishEye_prod_noM6`: 2026-11-26. На прод — по плану выкладки (правила: `docs/deployment/sql-server-deployment-rules.md`).

Без колонки приложение продолжает работать: DAO читает `iilResults` с откатом на `NULL`, запись лога логируется предупреждением и пропускается.
