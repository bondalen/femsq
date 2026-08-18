# Дамп QueryDef `cipu*` и helper `agsCnCtpt*` (2026-08-17)

Сырой вывод `DumpCipuQueryDefs` (UTF-8). В паспорт разобрано как `{Имя}.access.sql` на уровень выше.

**Не переснимать** эти файлы, пока SQL в Access не изменится.

| Прогон | Файлы |
|--------|--------|
| 23:44 | 40 QueryDef (`cipu*` + `agsCnCtptExequtorSmplBuirg` + `agsOrgIdBUiRG`) |
| 23:58 | + `agsCnCtptAgentSmplBuirg`, `agsCnCtptAgentSmplBuirgOne`, `agsCnCtptExequtorSmplBuirgOne`, `agsInvNumCount` |

Кириллица `NullИлиПусто` в дампе сохранилась (6 файлов). Mojibake нет.

`agsInvNumCount` совпал с уже снятым [`access-queries/agsInvNumCount.access.sql`](../../access-queries/agsInvNumCount.access.sql) — в паспорт 26-0813 не дублировали.
