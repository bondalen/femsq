# P5 — dry-check rewrite `vw_Yr_DbtFact` (без CREATE VIEW)

**Дата:** 2026-08-26  
**Черновик:** [04_VIEW_vw_Yr_DbtFact_M2.sql](./04_VIEW_vw_Yr_DbtFact_M2.sql)

## Идея проверки

Пока `dvDbt` ещё в таблице: сравнить `dv.dvDbt` (live `dbtKey`) с `idd.iddDbt` через  
`invDbtDbtVar → invDbt → LEFT JOIN invDbtDbt` (тот же путь слота, что после backfill `dvInvDbt`).

## Результат

| Schema | n (Value с dvDbt) | dbtKey_eq | no_canon | mismatch |
|--------|-------------------|-----------|----------|----------|
| sudz | 16 | 16 | 0 | 0 |
| test_sudz | 16 | 16 | 0 | 0 |

Fact live: **16** строк (`sudz.vw_Yr_DbtFact`). Sample TOP: yr 900/901, dbt 82/85 — все `dbtKey_match=1`, слот var = слот idd.

## Вывод

Текст `04` (якорь `dvInvDbt` + `dbtKey = idd.iddDbt`, `DbtUplCstAg` по `idd.iddDbt`) согласован с текущими данными. CREATE VIEW — только при apply B1 после P9.
