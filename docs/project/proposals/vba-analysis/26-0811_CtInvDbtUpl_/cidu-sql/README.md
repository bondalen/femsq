# Дамп QueryDef `cidu*` (загрузка общего свода)

Сырой вывод [`DumpCiduQueryDefs.bas`](../DumpCiduQueryDefs.bas) (UTF-8). Immediate:

`DumpCiduQueryDefs "C:\temp\cidu-sql"`

**Прогон:** 2026-08-24 15:25 — **36** файлов (`cidu*` + extra `agsCnInvNumsVariants`, `agsInvNumCount`).

Кириллица `NullИлиПусто` в дампе есть. Не переснимать, пока SQL в Access не изменится.

Аналог платежей: [`../../26-0813_CnInvPmtUpl_/cipu-sql/`](../../26-0813_CnInvPmtUpl_/cipu-sql/).

## Сверка FEMSQ vs дамп (S66b, 2026-08-24, upl=910)

Код предшествующих шагов **не меняли**. Row-count / симметричная разница:

| Шаг | Access | FEMSQ | Δ |
|-----|--------|-------|---|
| orgNotInBuirg | 2 | 2 | 0 |
| CnNotLoad | 0 | 0 | 0 |
| ExistCtpt (живой anti-join vs HAVING>0) | 2 | 2 | 0 |
| ExistList | 267 | 267 | 0 |
| пары cn×СФ | 1751 | 1751 | 0 |
| InvNot missing (после apply 693) | 0 | 0 | 0 |

Решение: править DAO org/Cn/ExistCtpt/InvNot **нецелесообразно**. AccSmpl — эталон здесь; DAO приведён к All/Not/NotIns.

**Следующий съём (не `cidu*`):** QueryDef `invDoubleCia` — **снят 2026-08-24** ([`invDoubleCia.sql`](./invDoubleCia.sql), канон [`access-queries/invDoubleCia.access.sql`](../../access-queries/invDoubleCia.access.sql)). Это **не** таблица `invDbt`. Дальше код Acc/Dbt Access-шагов не писать до решения S66c (шов воронки).

## Воронка → файлы

| Шаг VBA | QueryDef (дамп) |
|---------|-----------------|
| org / CnNotLoad | `ciduCtptNot`, `ciduTblCtptExist`, `ciduCnCtptList`, `ciduCnNotLoad`, `ciduCnNumNotLoad` |
| CnExistCtptNotLoad | `ciduCnExistCtptNot`, `ciduCnCtptExistNot`, `ciduCnCtptExistList` |
| CnCtptExistInvNotLoad | `ciduCnExistInvNot`, `ciduCnCtptExistInvNot`, `ciduCnCtptExistInvAll`, `ciduCnInvCnCtptExist` |
| AccSmpl | `ciduCnCtptInvAccSmplAll`, `ciduCnCtptInvAccSmplNot`, `ciduCnCtptInvAccSmplNotIns`, `ciduCnCtptInvAccSmplExt` |
| Acc | `ciduCnCtptInvExistAccNot`, `ciduCnCtptInvAccSmplExtAcc*`, `…ExtAccNotIns` |
| Dbt | `…ExtAccExtDbt*`, `…ExtDbtNotIns`, `…ExtD` |
| NameCount | `ciduTblCnCtptInvAccNameCount`, `ciduCnCtptInvAccExistCount*` |
| helper | `agsCnInvNumsVariants`, `agsInvNumCount` |

Часть ранних `cidu*` уже оформлена в [`access-queries/`](../../access-queries/) (S61l/S61n/S66). Этот каталог — полный живой снимок.

**S66a:** эталон AccSmpl — `ciduCnCtptInvAccSmplNot` / `…All` / `…NotIns` здесь, не реконструкция.
