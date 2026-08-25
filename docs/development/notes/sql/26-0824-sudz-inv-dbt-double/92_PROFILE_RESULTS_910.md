# Profile funnel steps (upl 910) — 2026-08-25

## Три UAT-прогона UI (шаги 1–6, без invDbtLoad)

| # | Время (лог) | flLoad | AccSmpl (backend) | ensure | Итог |
|---|-------------|--------|-------------------|--------|------|
| 1 | 15:06→15:09 (~3 мин) | false | ~163 с | missing=1631, ambiguous=118, apply=0 | dry OK |
| 2 | 15:11→15:14 (~3 мин) | true | ~157 с | missing=1631→apply **1631**; fill `#sudzEia`×3 | apply OK |
| 3 | 15:16→15:19 (~3 мин) | false | ~160 с | missing=**0**, ambiguous=118 | dry после apply OK |

БД после прогонов: `sudz.invDbtVar` = **1634** (1631 в окне 15:11–15:15); `CnInvUplInvDbtDouble` upl 910 = **0** (ожидаемо без `invDbtLoad`).

## Узкое место (до фикса)

~85% времени — **`CnCtptInvExistAccSmplNotLoad`** через монолитный CTE + `PreparedStatement` (~160 с при 0 строк).

## Исправление + timed dry-run (GraphQL, flLoad=false, 15:34)

AccSmpl → `#sudzEia` + Statement; в логе «шаг: N мс».

| Шаг | мс |
|-----|-----|
| orgNotInBuirg | 19 |
| CnNotLoad | 706 |
| CnExistCtptNotLoad | 632 |
| CnCtptExistInvNotLoad | 308 |
| **CnCtptInvExistAccSmplNotLoad** | **6100** (fillMs≈7096, queryMs≈65, rows=0) |
| **invDbtVarEnsure** | **17976** (missing=0, ambiguous=118) |
| **всего** | **25742** (~26 с вместо ~180 с) |

SQL-профиль: `92_PROFILE_funnel_steps_910.sql` (fill / AccSmpl / ensure). Следующий выигрыш — не дублировать `fillSudzEiaTemp` между AccSmpl и ensure (~7 с×2).

## Как снять профиль

1. Выполнить `92_PROFILE_funnel_steps_910.sql` в DEV.
2. В UI — dry-run тех же 6 шагов; сверить «шаг: N мс» с SQL / INFO `funnel step … ms=`.
