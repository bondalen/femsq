# Корневая причина расхождений ag_percentDev (218 ключей, 07f)

**Дата:** 2026-06-11  
**Пакет:** `docs/development/notes/sql/26-0604/`  
**Связанные объекты:** `fnIpgChRsltCstUtl2_2606` v8.9, `fnIpgChRsltCstUtlPercentBrn_2605/_2606`

## Симптом

После v8.8 полный `07f` давал **F.1/F.2 PASS** (14447=14447 строк, 16 dateRslt), но по дедуплицированным ключам `(dateRslt, ipgKey, cstapKey)` оставалось **218** расхождений **только** в `ag_percentDev` при совпадающих `ag_presented` и `ag_lim`.

Скрипт диагностики: `07f3_analyze_pb_diff_chain5.sql`.

## Ложное завышение F.3 в 07f (до правки)

`PercentBrn` использует `GROUPING SETS` → на агрегатных строках (`cstapKey IS NULL`) до **63–65 дублей** на одну дату. Прямой `FULL OUTER JOIN` без дедупликации давал **~48k** «diff» (декартово произведение дублей). Исправлено в `07f_COMPARE_PercentBrn_full_chain5.sql` (F.3 через `GROUP BY` ключей).

## Истинная причина 218 ключей

`ag_percentDev` в `fn2` вычисляется как:

```sql
(acceptedAccum + agFeeAcceptedAccum + acceptedRalpAccum
 + storageSumAccum + cctSumAccum + MnrlSumAccum) / lim * 100
```

при `lim > 0` и `iShKey = 2` (агентская схема).

### fn_2408 / fn2_2605

В `fnIpgChRsltCstUtl_2408` для строк с `fnMasteringShShow = 'true'` суммы **хранения** и **строительного контроля** подставляются из **`cn_PrDocP`** (проведённые документы):

| Поле | Источник fn_2408 | Фильтр |
|------|------------------|--------|
| `storageSum` | `SUM(costVAT)` ZPTG/ZKTG | `cnpdTpOrd IN (1,2,4)`, статус «проведено» |
| `cctSum` | `SUM(costVAT)` ZUGH | `pdtoCode = 'ZUGH'`, статус «проведено» |

Значения реплицируются на **все ИПГ цепи** × 12 месяцев и входят в `percentDev` даже при `accepted = NULL`.

### fn2_2606 (до v8.9) — ошибка

В CTE `ipgBase` поля брались **только из mastering** (`u.storageSum`, `u.cctSum` из `@schemeRows`):

```sql
u.storageSum, u.cctSum   -- только agMstrngAcpStorMn / agMstrngAcpControlMn
```

`@raFactStorage` / факт ССК использовались в `extraBase`/`masExtraBase`, но **не** в агентских plan-строках `ipgBase`.

### Пример cstapKey=1266 (001-2001317), ipgKey=6

| mNum | _2605 storageSumAccum | _2606 (до fix) | _2605 percentDev | _2606 (до fix) |
|------|----------------------|----------------|------------------|----------------|
| 1 | 240144.34 | 0 | 0.24% | **0%** |
| 3 | 697193.25 | 0 | 0.71% | **0%** |
| 4 | 929590.97 (+ cct) | 0 | 1.79% | **0.82%** |

Факт хранения в `cn_PrDocP` есть; mastering по этим месяцам — NULL.

### Пример cstapKey=2221 (051-3000796), mNum=3

| Поле | _2605 | _2606 (до fix) |
|------|-------|----------------|
| acceptedAccum | совпадает | совпадает |
| cctSumAccum | 2 790 070.80 | **0** |
| percentDev | 73.40% | **73.35%** |

## Исправление v8.9

1. Таблица `@raFactCct` — агрегат ZUGH из `cn_PrDocP` (как fn_2408 `cct`).
2. В `ipgBase` при `shShow = 'true'`:

```sql
IIF(u.shShow = N'true', rfs_ipg.storageSum, u.storageSum) AS storageSum,
IIF(u.shShow = N'true', rfc_ipg.cctSum, u.cctSum) AS cctSum,
```

с `LEFT JOIN @raFactStorage` / `@raFactCct` по `(cstAgPnKey, mNum)`.

Паритет с уже существующими JOIN для Ralp/Mnrl при `shShow`.

## Верификация

```bash
# fn2
docker exec -i femsq-mssql sqlcmd ... < 04_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2606.sql

# дедуп-анализ PercentBrn
docker exec -i femsq-mssql sqlcmd ... < 07f3_analyze_pb_diff_chain5.sql

# полный 07f
docker exec -i femsq-mssql sqlcmd ... < 07f_COMPARE_PercentBrn_full_chain5.sql
```

Ожидание: `field_diff_keys = 0`, `07f: PASS`.
