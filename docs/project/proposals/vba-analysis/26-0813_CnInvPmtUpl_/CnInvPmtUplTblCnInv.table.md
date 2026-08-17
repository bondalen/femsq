# Таблица Access: `CnInvPmtUplTblCnInv`

**Статус:** структура снята (2026-08-13). **Данных нет** (0) — CSV не нужен.  
**Источник:** [`CnInvPmtUplTblCnInv.dump.utf8.txt`](./CnInvPmtUplTblCnInv.dump.utf8.txt)  
**Тип:** локальная Access; промежуточный буфер новых СФ для pm-воронки.  
**PK / индексы / Relations:** нет.

## Поля (9)

| Поле | DAO | Size | Req |
|------|-----|------|-----|
| `ciputciCntrPrtNum` | dbLong | 4 | **да** |
| `ciputciCntrPrtName` | dbText | 255 | нет |
| `ciputciCnName` | dbText | 255 | нет |
| `ciputciCnDate` | dbDate | 8 | нет |
| `ciputciCn_key` | dbLong | 4 | нет |
| `ciputciCsosKey` | dbLong | 4 | нет |
| `ciputciCnInv` | dbText | 255 | нет |
| `ciputciCiKey` | dbLong | 4 | нет |
| `ciputciCnInvNumCount` | dbLong | 4 | нет (default 0) |

## Для FEMSQ

Суррогатный PK `ciputciRow IDENTITY`. Шире, чем Dbt `TblCnInv` (есть Ctpt/Csos/Date).

**lastUpdated:** 2026-08-13
