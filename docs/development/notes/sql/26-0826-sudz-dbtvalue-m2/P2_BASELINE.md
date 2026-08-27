# P2 — baseline до B1 (B1-prep)

**Дата:** 2026-08-26  
**Среда:** nb-win, Docker `femsq-mssql`, backend `:8080` (JAR ~215), Vite `:5175`  
**Инвентарь:** [P1_INVENTORY_dvDbt.md](./P1_INVENTORY_dvDbt.md)

После B1 повторить те же проверки и сравнить с числами ниже.

---

## P2a — лаунчер / слой I / очередь upl **910**

| Метрика | Значение | Как снято |
|---------|----------|-----------|
| `CnInvUplInvDbtDouble` all / open | **133 / 133** | SQL |
| `sudz.invDbt` | **1630** | SQL |
| `sudz.invDbtDbtVar` | **1630** | SQL |
| `sudz.invDbtVar` | **1634** | SQL |
| Dry funnel `flLoad=false` | **ok**, ~41 с | GraphQL `runSudzDbtUplFunnel` полный префикс … → `invDbtVarEnsure` → `invDbtLoad`; `stub=false` |
| После dry: open очередь | **133** (без изменений) | SQL |

**Замечание:** вызов только `["invDbtVarEnsure","invDbtLoad"]` без префикса → `INTERNAL_ERROR` (S61f). Baseline dry — только с полным префиксом.

**Статус P2a:** ✅

---

## P2b — КСДСФ «Суммы · new» (`DbtValue`)

Якорь: `debt=70525000.01`, `epsilon=0.01` (seed dbt **82**).

| | |
|--|--|
| GraphQL `sudzSfDoubleSumMatches` | ✅ |
| `oldMatches` | **7** (`cidKey` 49240…60222) |
| `newMatches` | **8** — `dvKey` 1,2,3,7,8,9,10,11; все `dvDbt=82`; upl 901–903, 801–805 |
| Поле `dvDbt` в ответе | присутствует (критично для регресса после M2) |

**Статус P2b:** ✅

---

## P2c — подсказки `sumsNew`

| | |
|--|--|
| Очередь `CnInvUplSfDouble` | **0** строк (S68u upl 910 разобрана) — нет валидного `ciusKey` для полного UI-прогона |
| GraphQL `sudzSfDoubleHints(ciusKey:1)` | отвечает без 500: `sumsNew.status=na`, «Строка очереди / Excel-кандидат не найдены» |
| SQL-путь join hints (`DbtValue` ⋈ `invDbtDbt` по **`dv.dvDbt`**) | ✅ `COUNT(DISTINCT dvKey)=8` на якоре 70525000.01 |

**Статус P2c:** ✅ (с оговоркой: полный ctpt-hints UI — после появления строки SF-очереди или тестовой вставки; критичный join по `dvDbt` проверен SQL)

---

## P2d — RelationTree рёбра `dv.dbt` / `dbt.dv`

| Вызов | Результат |
|-------|-----------|
| `relationExpand(edge:"dv.dbt", fromId:1)` | ✅ → `dbtKey=82` |
| `relationExpand(edge:"dbt.dv", fromId:82)` | ✅ → строки Value с полем **`dvDbt`** (в т.ч. dvKey 1,2,…) |

**Статус P2d:** ✅

---

## P2e — `vw_Yr_DbtFact` / отчёты

| Метрика | Значение |
|---------|----------|
| `SELECT COUNT(*) FROM sudz.vw_Yr_DbtFact` | **16** |
| по `yr_key` | 900 → 10; 901 → 6 |
| `EXEC sudz.Yr_DbtChangesD644 @yr=901, @curr_upl=903` | ✅ **2** строки (dbtKey 82, 85) |
| `EXEC sudz.Yr_DbtChangesD644Svod @yr=901, @curr_upl=903` | ✅ **12** счетов; 606012 overd_base=70525000.01 / pogasheno=100%; 762210=9527.42 |
| REST `GET /api/v1/sudz/d644.xlsx?yr=901&currUpl=903` | ✅ 200, ~7373 байт |
| REST `…/d644-svod.xlsx?yr=901&currUpl=903` | ✅ 200, ~5273 байт |
| REST `…/rslt-sborn.xlsx?yr=901&asOfUpl=903` | ✅ 200, ~8546 байт |

**Статус P2e:** ✅

---

## Сводка P2

| # | Статус |
|---|--------|
| P2a | ✅ |
| P2b | ✅ |
| P2c | ✅ (SQL + API na; UI ctpt — оговорка) |
| P2d | ✅ |
| P2e | ✅ |
| **P2** | ✅ 2026-08-26 |

**Next:** **P3** — dry-check backfill `dvInvDbt` (SELECT only) → `00_VERIFY_before.sql`.
