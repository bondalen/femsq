# M3 — Calm F1 (sum → слот)

**Дата:** 2026-08-27  
**JAR:** `0.1.0.225-SNAPSHOT`  
**Cutover:** §F / S74 M3

## Правило

Если в Excel одна сумма `S` на `iKey` и среди слотов `invDbt` ровно один имеет в истории `DbtValue` с `|dvTtl−S|≤0.01`, и контекст `invDbtVar` однозначен:

- не класть iKey в open-очередь;
- при `flLoad` писать `invDbtDbtVar` + `DbtValue` на **этот** слот (не создавать новый).

Код: `JdbcSudzDao.sqlInvDbtF1MatchCtes` + `rebuildInvDbtDoubleQueue` / `applyDbtUplInvDbtLoadUnambiguous`.

## Сопутствующие фиксы

| Тема | Суть |
|------|------|
| `06c` | `dvUpl` FK → `sudz.cn_inv_dbt_upl` (+ sync ключей из ags); иначе воронка 910 не пишет Value |
| queue UX | INSERT open не дублирует `ciudCidut`, уже занятый статусом `created`/др. |

## UAT upl **910** (полный префикс шагов)

| Метрика | Dry (`flLoad=false`) | Apply 1 | Apply 2 (идемп.) |
|---------|---------------------:|--------:|------------------:|
| open queue | **131** | ~131 | — |
| `DbtValue` на 910 | 0 | **1629** | 1629 |
| apply `values=` / `f1Values=` | — | **1629** / **1** | **0** / **0** |
| новые `invDbt` | — | 664 | 0 |

Очередь после M2 в основном `ambiguous` (нет однозначного var) — F1 их не берёт (нужен `idvvKey`). Среди `multi` с var на 910 уникальный sum-match дал **1** F1 Value.

## Next

**M5** — остальные чекбоксы воронки.
