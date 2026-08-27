# 26-0826 — A2-messages: `ciudReasonDetail`

Универсальный текстовый канал по строке очереди двоящих долгов.

| Поле | Роль |
|------|------|
| `ciudReason` | короткий код (`multi` / `ambiguous`) |
| `ciudReasonDetail` | текст сообщений; v1 — блок `[queue.build]` при rebuild |

UI: панель «Сообщения» под Excel на экране разбора.

**Применение DEV:** `01_ALTER_ciudReasonDetail.sql`  
**Прод:** `MSSQL2012/01_ALTER_ciudReasonDetail.sql`
