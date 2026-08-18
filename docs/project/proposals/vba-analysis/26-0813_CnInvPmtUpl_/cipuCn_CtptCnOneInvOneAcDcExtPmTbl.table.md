# Таблица Access: `cipuCn_CtptCnOneInvOneAcDcExtPmTbl`

**Статус:** структура снята (2026-08-18).  
**Источник:** [`cipuCn_CtptCnOneInvOneAcDcExtPmTbl_dump.txt`](./cipuCn_CtptCnOneInvOneAcDcExtPmTbl_dump.txt)  
**Тип:** локальная Access; эфемерный буфер шага 12 `btnUpload` (готовые платежи до INSERT в `ags_cn_inv_pm`).  
**Записей на момент дампа:** **7736**. **PK / индексы / Relations:** нет.  
**Caption / Description полей:** в дампе нет.

Не путать с архивом `…ExtPmTblOld` и с ранним чтением `ExtPmtTbl` (лишняя `t`).

## Роль в воронке

VBA перед наполнением: `DELETE * FROM cipuCn_CtptCnOneInvOneAcDcExtPmTbl`.  
Заполнение: APPEND [`cipuCn_CtptCnOneInvOneAcDcExtPmIns`](./cipuCn_CtptCnOneInvOneAcDcExtPmIns.access.sql) ← SELECT `*` из [`cipuCn_CtptCnOneInvOneAcDcExtPm`](./cipuCn_CtptCnOneInvOneAcDcExtPm.access.sql).  
Чтение: [`cipuInsPmNot`](./cipuInsPmNot.access.sql) — LEFT JOIN к `ags_cn_inv_pm` по `(ciasKey, cn_inv_doc_key, ciputUnloadKey, ciputSheetNum)`; `HAVING cn_inv_pm_key Is Null`.  
Apply: [`cipuInsPmNotIns`](./cipuInsPmNotIns.access.sql) → `ags_cn_inv_pm` (`AgCsosKey`→`csoCn_s_org_smpl`, `cacOrNull`→`constract_code`, `cstapKey`, `ciasKey`→`ciaCnInvAccntSmpl`, `ciputUnloadKey`→`cn_inv_pm_upl`).

На SQL Server **не** переносилась (S61d: только File / Tbl / TblCnInv).

## Факты дампа

- Локальная (`Connect` пустой, `Attributes=0`). Создана 2022-01-11.
- 40 полей; Required все False.
- `ciputCnInvDocCode` / `ciputStornoDocCode`: DAO **Type 20**, Size 16, **Precision=18, Scale=0** → это **`dbDecimal`**, не `dbGUID` (15). В [`CnInvPmtUplTbl.table.md`](./CnInvPmtUplTbl.table.md) тот же Type 20 назван GUID; по свойствам буфера — Decimal(18,0). В SQL по-прежнему `nvarchar(50)` (как в CSV Tbl).
- `ciputAccount` — номер счёта Excel (`dbLong`); рядом отдельный `account_key`.
- `csosKey` — исполнитель; `AgCsosKey` — агент (`cipuCn_AgOne`). INSERT в `ags_cn_inv_pm` берёт **агента**.
- `ciputAlligmentDate` — опечатка Alignment, как в Tbl.

## Поля (40)

| # | Поле | DAO | Size | Примечание |
|---|------|-----|------|------------|
| 0 | `ciKey` | dbLong | 4 | СФ (`cnInv`) |
| 1 | `ciputAccount` | dbLong | 4 | № счёта ГК из Excel |
| 2 | `account_key` | dbLong | 4 | `ags.accnt` |
| 3 | `csosKey` | dbLong | 4 | исполнитель `cn_s_org_smpl` |
| 4 | `CntrPrtNum` | dbLong | 4 | БУиРГ контрагента |
| 5 | `CntrPrtName` | dbText | 255 | |
| 6 | `CnName` | dbText | 255 | № договора |
| 7 | `cn_key` | dbLong | 4 | |
| 8 | `ciasKey` | dbLong | 4 | `cnInvAccntSmpl` |
| 9 | `ciputCnInv` | dbText | 255 | номер СФ |
| 10 | `ciputCnInvDocCode` | **dbDecimal (20)** | 16 | Prec. 18, Scale 0 |
| 11 | `cn_inv_doc_key` | dbLong | 4 | `ags_cn_inv_doc` |
| 12 | `CountCiputSheetNum` | dbLong | 4 | сколько строк Excel на этот ключ |
| 13 | `ciputBE` | dbText | 50 | |
| 14 | `ciputCAC` | dbText | 50 | |
| 15 | `cacOrNull` | dbText | 255 | → `constract_code` |
| 16 | `ciputAgentNum` | dbLong | 4 | |
| 17 | `ciputAgentName` | dbText | 255 | |
| 18 | `ciputLink` | dbText | 255 | → `cn_inv_doc_link` |
| 19 | `ciputEntryDate` | dbDate | 8 | |
| 20 | `ciputDocDate` | dbDate | 8 | |
| 21 | `ciputDueDate` | dbDate | 8 | → `cn_inv_pm_due` |
| 22–28 | `ciputDbtBlns*` / `ciputCdtBlns*` / `ciputBlns` | dbCurrency | 8 | |
| 29 | `ciputAlligmentDate` | dbDate | 8 | → `alignment_date` |
| 30 | `ciputBaseDate` | dbDate | 8 | |
| 31 | `ciputCnInvDocSum` | dbCurrency | 8 | |
| 32 | `ciputStornoReason` | dbText | 255 | |
| 33 | `ciputStornoDocCode` | **dbDecimal (20)** | 16 | Prec. 18, Scale 0 |
| 34 | `ciputSheetNum` | dbLong | 4 | → `ags_cn_inv_pm.number` |
| 35 | `ciputUnloadKey` | dbLong | 4 | → `cn_inv_pm_upl` |
| 36 | `cstapKey` | dbLong | 4 | `cstAgPn` |
| 37 | `cstapCsta` | dbLong | 4 | |
| 38 | `cstaAg` | dbLong | 4 | |
| 39 | `AgCsosKey` | dbLong | 4 | агент; INSERT → `csoCn_s_org_smpl` |

**lastUpdated:** 2026-08-18
