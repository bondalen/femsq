# 26-0824 — `sudz.CnInvUplInvDbtDouble` (S66e)

Очередь ручного разбора двоящих / неоднозначных задолженностей СФ после шага воронки `invDbtLoad`.

| | |
|--|--|
| Паттерн | зеркало `CnInvUplSfDouble` (S68), префикс **`ciud*`** |
| DEV | SQL Server 2022 (`femsq-mssql`), скрипт корня пакета |
| Prod-синтаксис | `MSSQL2012/` (без IF OBJECT_ID create-or-skip — применить осознанно) |
| План | [chat-plan S66e](../../chats/chat-plan/chat-plan-26-0802-sudz.md#s66e--порядок-определения-invdbt-сегментами-2026-08-24) |

**Статусы:** `open` | `created` | `deferred`.

**Применено на DEV:** 2026-08-24.
