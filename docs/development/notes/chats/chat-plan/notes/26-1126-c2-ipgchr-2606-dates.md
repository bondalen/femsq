# ipgChRl_2606 для цепей DEV 507–510

**Дата:** 2026-11-26  
**План C2:** §3.5.2  
**Стенд:** `FishEye_prod_noM6`

## Проблема

Членство в `ipgChRl` есть; строк в `ipgChRl_2606` нет → `spMstrg_2606` по цепям A–D не стартует. GraphQL цепей пока без дат `_2606`.

## Решение (DEV SQL)

Скрипт: [docs/development/notes/sql/26-1126-ipgchr-2606-dates/](../../sql/26-1126-ipgchr-2606-dates/)

| chain | ipg | ipgcrvStr | ipgcrvEnd |
|------:|----:|-----------|-----------|
| 507 | 27 | `ipg.ipgStr` | NULL |
| 508 | 28 | `ipg.ipgStr` | NULL |
| 509 | 29 | `ipg.ipgStr` | NULL |
| 510 | 30 | `ipg.ipgStr` | NULL |

**Применено на noM6:** 2026-11-26 — строки `ipgcrvKey` 8–11 (`ipgcrvStr=2026-11-24`, `ipgcrvEnd=NULL`).

## Хвост

UI/GraphQL дат членства (`ipgcrvStr`/`ipgcrvEnd`) — в бэклог C2 (контракт O1 §7 уже требует).
