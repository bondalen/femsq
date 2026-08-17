# Таблица Access: `CnInvPmtUplTbl`

**Статус:** структура + данные сняты (2026-08-13).  
**Источник:** [`CnInvPmtUplTbl.dump.utf8.txt`](./CnInvPmtUplTbl.dump.utf8.txt), [`CnInvPmtUplTbl.csv`](./CnInvPmtUplTbl.csv) (~2.2 MB)  
**Тип:** локальная Access; эфемерный staging строк `export_*`.  
**Записей:** **7736** — все с `ciputUnloadKey=32` (снимок одной выгрузки). **PK / индексы / Relations:** нет.

## Данные (факты)

- В CSV `ciputAccount` приходит как **номер счёта** (напр. `606012`), не `account_key`.
- `ciputCnInvDocCode` / `ciputStornoDocCode` в TableDef = Type 20 (GUID), в CSV — **числовые строки** (напр. `8800354708`); в SQL лучше `nvarchar(50)`, не `uniqueidentifier`.
- GUID nonempty: DocCode все 7736; StornoDocCode 96.

## Поля (28)

| Поле | DAO | Size | Описание (из дампа) |
|------|-----|------|---------------------|
| `ciputBE` | dbText | 50 | БЕ |
| `ciputAccount` | dbLong | 4 | счёт (lookup accnt) |
| `ciputCntrPrtNum` | dbLong | 4 | № контрагента |
| `ciputCntrPrtName` | dbText | 255 | контрагент |
| `ciputCAC` | dbText | 50 | CAC |
| `ciputAgentNum` | dbLong | 4 | № агента |
| `ciputAgentName` | dbText | 255 | агент |
| `ciputCnName` | dbText | 255 | договор |
| `ciputLink` | dbText | 255 | ссылка |
| `ciputCnInv` | dbText | 255 | СФ / документ |
| `ciputEntryDate` | dbDate | 8 | |
| `ciputDocDate` | dbDate | 8 | |
| `ciputDueDate` | dbDate | 8 | |
| `ciputDbtBlns` | dbCurrency | 8 | |
| `ciputDbtBlnsOverd` | dbCurrency | 8 | |
| `ciputDbtBlnsOverdNot` | dbCurrency | 8 | |
| `ciputCdtBlns` | dbCurrency | 8 | |
| `ciputCdtBlnsOverd` | dbCurrency | 8 | |
| `ciputCdtBlnsOverdNot` | dbCurrency | 8 | |
| `ciputBlns` | dbCurrency | 8 | |
| `ciputCnInvDocCode` | **dbGUID (20)** | 16 | код док. (GUID) |
| `ciputAlligmentDate` | dbDate | 8 | опечатка Alignment |
| `ciputBaseDate` | dbDate | 8 | |
| `ciputCnInvDocSum` | dbCurrency | 8 | |
| `ciputStornoReason` | dbText | 255 | |
| `ciputStornoDocCode` | **dbGUID (20)** | 16 | |
| `ciputSheetNum` | dbLong | 4 | № на листе |
| `ciputUnloadKey` | dbLong | 4 | = `cn_inv_pm_key` |

## Для FEMSQ

- Суррогатный PK `ciputKey IDENTITY` (как у Dbt Tbl).
- DocCode/Storno → `nvarchar(50)` (по факту CSV, не uniqueidentifier).
- Currency → `decimal(19,4)`.
- `ciputAccount`: уточнить при воронке — num vs key.

**lastUpdated:** 2026-08-13
