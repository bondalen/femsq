# Access: семейство `CnInvPmtUpl*` — скрины (процесс 1.1.1.2)

**Дата:** 2026-08-17  
**Чат:** паспорт формы платежей (отдельно от 0069 / S68)  
**Назначение:** визуальный эталон Access для [02-11_cn-inv-pmt-upl-access.md](../../02-11_cn-inv-pmt-upl-access.md).  
**Эскиз FEMSQ:** нет (отдельное решение после закрытия паспорта).

## Каталог файлов

| Файл | Вид | Содержание |
|------|-----|------------|
| `00-nav-CnInvPmtUpl.png` | Nav | фильтр `CnInvPmtUpl`: 4 табл., 2 запроса, 6 форм |
| `01a-nav-cipu-top.png` | Nav | фильтр `cipu`: 2 табл.; запросы до `cipuCtpt_All` |
| `01b-nav-cipu-bottom.png` | Nav | `cipuCtpt_All*` / `cipuDoc*` / `cipuInsPm*` + 6 `*Ins` |
| `10-design-main-recordsource.png` | Design | `CnInvPmtUpl`: RS `ags_cn_inv_pm_upl`; вкладки загрузка / счета, сумма / прочее |
| `11-design-main-link-file-f.png` | Design | subform File_f: Link `cn_inv_pm_key`↔`cipufUpload` |
| `12-design-main-tab-sum-t.png` | Design | вкладка «счета, сумма»: `Sum_t`; Link `cn_inv_pm_key`↔`cn_inv_pm_upl` |
| `13-design-main-tab-other.png` | Design | вкладка родителя «прочее»: пустой контейнер |
| `14-design-file-f-recordsource.png` | Design | File_f: шапка + кнопка «загрузка»; RS SELECT `CnInvPmtUplFile…` |
| `15-design-sum-t-recordsource.png` | Design | `Sum_t`: RS SELECT из `ags_q_cn_inv_pm_upl_sum` |
| `15b-sql-sum-t-recordsource.png` | SQL | полный SELECT 9 полей FROM `ags_q_cn_inv_pm_upl_sum` |
| `16-design-file-f-tab-invdouble.png` | Design | File_f вкладка «повторяющиеся СФ»; control InvDouble; Link пустой |
| `16b-design-invdouble-form.png` | Design | форма InvDouble + nested; RS обрезан |
| `16c-sql-invdouble-recordsource.png` | SQL | полный RS InvDouble |
| `17-design-invdouble-link-invnum.png` | Design | Link InvDouble→invNum: `ciputciCnInv` / `inNumNull` |
| `17b-design-invnum-form.png` | Design | форма invNum; RS `ags_invNum` (обрезка) |
| `17c-sql-invnum-recordsource.png` | SQL | SELECT 6 полей FROM `ags_invNum` |
| `18-design-invnum-link-cninv.png` | Design | Link invNum→cnInv: `inInv` / `ciInv` |
| `18b-design-cninv-form.png` | Design | форма cnInv; RS `ags_cnInv` (обрезка) |
| `18c-sql-cninv-recordsource.png` | SQL | `ags_cnInv` INNER JOIN `ags_cn` |
| `19-design-file-f-tab-cstnew.png` | Design | File_f «стройки новые»; Link CstNew пустой |
| `19b-design-cstnew-form.png` | Design | форма CstNew; поля `cacOrNull`…`pirName` |
| `19c-sql-cstnew-recordsource.png` | SQL | SELECT из QueryDef `CnInvPmtUplTbl_CstNew` (алиасы Выражение*) |
| `20-design-file-f-tab-other.png` | Design | File_f «прочее»: `cipufKey`, `cipufUpload` |
| `21-runtime-CnInvPmtUplTblNull.png` | Datasheet | `CnInvPmtUplTblNull`: есть и заполненный, и пустой `cacOrNull` |
| `21b-sql-CnInvPmtUplTblNull.png` | SQL | тот же QueryDef; `b.a.ciputLink` в SELECT |
| `21d-design-CnInvPmtUplTblNull-a-ciputLink.png` | Design | сетка: Поле `a.ciputLink`, таблица `b` |
| `22-sql-cipuCacNot.png` | SQL | QueryDef `cipuCacNot`: `cacOrNull` из `CnInvPmtUplTblNull`, HAVING `cstapCsta` Is Null |
| `23-sql-cipuCtpt_All_OIdNot.png` | SQL | QueryDef `cipuCtpt_All_OIdNot`: FROM `cipuCtpt_All_OId` WHERE `org_id_key is null`; Nav-фильтр подтвердил имя **OidNot** (= OId, не Old) |
| `24-sql-cipuCtpt_All_OId.png` | SQL | QueryDef `cipuCtpt_All_OId`: INNER JOIN `cipuCtpt_All` ↔ `agsOrgIdBUiRG`; Nav показывает `OId` и `OidNot` |
| `25-sql-cipuCtpt_All.png` | SQL | QueryDef `cipuCtpt_All`: UNION контрагент+агент из `CnInvPmtUplTbl`; Nav: `All`, `All_Old`, `All_OidNot` |
| `26-sql-cipuCn_CtptCnNot.png` | SQL | QueryDef `cipuCn_CtptCnNot`: LEFT JOIN `agsCnCtptExequtorSmplBuirg`, HAVING Count=0; Nav: Not / NotOld / NotOld2 |
| `27-sql-cipuCn_Ctpt.png` | SQL | QueryDef `cipuCn_Ctpt`: Tbl LEFT JOIN `OIdNot` IS NULL + `agsOrgIdBUiRG`; Nav: таблицы `…ExtPmTbl` |
