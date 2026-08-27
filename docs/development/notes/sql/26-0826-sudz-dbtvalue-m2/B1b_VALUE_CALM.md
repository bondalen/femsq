# B1b — Value в calm `invDbtLoad` (2026-08-26)

**JAR:** `0.1.0.218-SNAPSHOT`  
**План:** S72 B1b / сегм. 21

## Код

| Место | Изменение |
|-------|-----------|
| `JdbcSudzDao.applyDbtUplInvDbtLoadUnambiguous` | после слота+моста INSERT `DbtValue` (`dvInvDbt`,`dvInvDbtVar`,`dvUpl`, суммы/даты из Tbl); без `Dbt`/`invDbtDbt` |
| `rebuildInvDbtDoubleQueue` | не класть в open iKey с уже существующим `DbtValue` на эту upl |
| apply | DELETE из очереди строк, у которых появился Value |
| лог | счётчик `insertedValues` |

## UAT upl **910** (`flLoad=true`, полный префикс шагов)

| Метрика | До | После 1-го apply | Повтор |
|---------|-----|------------------|--------|
| `DbtValue` на 910 | 0 | **1628** | 1628 |
| open queue | 133 | **133** | 133 |
| `invDbt` / мост | 1630 / 1630 | без роста | — |
| `Dbt` / `invDbtDbt` | 2 / 3 (seed) | без роста | — |
| apply values= | — | **1628** | **0** (идемпотентно) |

## Next

**A2** — экран двоящих: create/link + INSERT `DbtValue` для позиций из очереди 133.
