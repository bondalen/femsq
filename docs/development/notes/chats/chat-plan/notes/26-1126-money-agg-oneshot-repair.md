# One-shot R-MONEY-AGG: ремонт Sm/lim на FishEye_prod_noM6

**Дата:** 2026-11-26  
**Задача:** 0095 · скрипт `docs/development/notes/sql/26-1126/01_REPAIR_sm_agg_axes_R_MONEY_AGG.sql`

## До

| Класс | N |
|-------|--:|
| Q (≤1e−8) | 25 |
| A (fixable) | 4 |
| A-hard | 13 (все **ipg=21**) |

## Сделано

- **Q 25:** `Oth += δ` (авторитет Ttl)  
- **A 4:** `Ttl := Wrk+Equ+Oth`  
- Resync `ipgPnLim` @212/195/172/187 для исправленных ключей  
- **HARD 13:** не трогали (отчёт в логе скрипта)

## После

| | |
|--|--|
| q_left / a_left | **0** |
| hard_left | **13** |
| Spot 3555 @ipg27 | δ Sm = **0** |
| lim @ipg27 site grain | n_nonzero = **0** |
| 07k1 RS @507 | **DECIMAL_EXACT**, d_delta=0, offenders=0 |

## HARD (бэклог / Excel)

Все на ИП **21**: cstAgPn 1507, 843, 1862, 849, 183, 2108, 2273, 3081, 2106, 1087, 660, 1835, 3079 — δ от ~657 до ~25630 млн. Нужна правка исходных файлов или override.
