# 26-0928 — `yr_upl_p_q`: один свод на квартал в портфеле

**Дата:** 2026-09-28  
**План:** [0922](../../chats/chat-plan/chat-plan-26-0922-pmt-upl-ui-complete.md) лист **1.7.6.9**

| Схема | Колонка / ограничение |
|-------|------------------------|
| `sudz.yr_upl_p` | `yr_upl_p_q tinyint NOT NULL` (0=Base YE(Y−1), 1=Q1, 2=Q2, 3=Q3, 4=YE Y) |
| | `CK_yr_upl_p_q` — `BETWEEN 0 AND 4` |
| | `UX_yr_upl_p_YrQ` — UNIQUE (`yr_upl_p_yr`, `yr_upl_p_q`) |

Календарный год портфеля Y = `YEAR(база.uplStatusOnDate)+1`. Слот только при **точном** совпадении `uplStatusOnDate` с концом квартала.

**Prod:** только `MSSQL2012/`.  
**DEV:** тот же скрипт (применён на nb-win 2026-09-28).
