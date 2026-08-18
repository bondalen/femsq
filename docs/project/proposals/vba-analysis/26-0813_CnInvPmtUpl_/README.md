# Access-local: `CnInvPmtUpl*` → `sudz` (S61d)

**Дата:** 2026-08-13  
**Решение:** владелец — вариант **B** (перенос сейчас, не откладывать 1.1.1.2).  
**Linked SQL (уже есть):** `ags`/`sudz`.`cn_inv_pm_upl`, мост `cn_inv_dbt_upl_g_p`.  
**Локальные Access (перенос):**

| # | Таблица | Роль |
|---|--------|------|
| 1 | `CnInvPmtUplFile` | шапка лаунчера (path, флаги, лог, **cipufSheet**) |
| 2 | `CnInvPmtUplTbl` | staging строк Excel |
| 3 | `CnInvPmtUplTblCnInv` | промежуточные СФ |
| ? | `CnInvPmtUplTbl_1` / InvDouble | уточним по nav после File |

Отличие от Dbt: у pm **нет** отдельной `FileSh` — лист в поле `cipufSheet` на File.

**Прогресс:** ✅ File (30); ✅ Tbl (7736); ✅ TblCnInv (0); ✅ Tbl_1 = дубль, **не в SQL**.  
**DDL:** [26_/27_](../../../../development/notes/sql/26-0812-sudz-dbt-upl-staging/) — ✅ DEV: File=30; Tbl/TblCnInv=0.

**Паспорт формы (S69):** [02-11_cn-inv-pmt-upl-access.md](../../../../development/notes/UI/02-11_cn-inv-pmt-upl-access.md) — UI/VBA/запросы; не переснимать эти 4 таблицы вслепую. QueryDef `cipu*` + helper `agsCnCtpt*` сняты. Буфер шага 12: [`cipuCn_CtptCnOneInvOneAcDcExtPmTbl.table.md`](./cipuCn_CtptCnOneInvOneAcDcExtPmTbl.table.md). Apply: INSERT **`ags_cn_inv_pm`**.

**Дыра съёма:** нет. VBA pmt в VBE = `File_f` + `cnInv` (уже в `VBA-Code-Export`). Архив `…ExtPmTblOld` не снимать.





