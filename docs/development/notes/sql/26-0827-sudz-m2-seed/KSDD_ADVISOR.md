# КСДД — советник и динамика слота (22c)

**Дата:** 2026-08-28  
**ADR:** [010-chart-platform-echarts](../../../../project/decisions/010-chart-platform-echarts.md)

## API (GraphQL)

| Query | Назначение |
|-------|------------|
| `sudzInvDbtDoubleAdvice(ciudKey, epsilon)` | блок `[advisor]` в «Сообщения» |
| `sudzInvDbtSlotTimeline(iKey, idKey, ciudKey)` | ряд `DbtValue` **выбранного** слота |

## Советник — проверки v1

| check | Рекомендация |
|-------|--------------|
| `no_var` | Выбрать контекст |
| `unique_sum_f1` / `sum_exact_new` | Link slot |
| `account_match` + `bridge_ready` | Link (medium/high) |
| `amortization` + `gap_projection` | Link slot (страховка, кейс 329) |

`confidence`: high | medium | low | none. Не заменяет первичку.

## UI

- «Сообщения»: `[queue.build]` + `[row.select]` + `[advisor]`
- «Слоты invDbt»: вкладки **Слоты и дерево** | **Динамика** (только selected slot)
- `FemsqChart` (feQuLib / ECharts): ряд канонических `DbtValue` (без PIT 801–899, одна точка на asOf) + **отдельный красный ряд Excel** (одна точка; подпись вертикально снизу вверх) + кнопки **+/−/1:1** масштаба по X
- Таблица динамики = тот же канон, что точки ряда слота
- Дерево `DbtValue.bySlotVarBridge` — тот же фильтр + `sudz.cn_inv_dbt_upl`
- `recommendIdKey` → auto-select слота

## UAT

- **329** ciud 2574 → advisor `link slot=42`, chart: история + Excel-точка
- **2031** iKey 5130: нет пар 26/801 на одной дате; Excel — красная точка