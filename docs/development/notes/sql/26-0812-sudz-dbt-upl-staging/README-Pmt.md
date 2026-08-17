# 0069 / S61d — DDL: Access `CnInvPmtUpl*` → `sudz`

**Дата:** 2026-08-13  
**Статус:** ✅ применено на DEV (File=30; Tbl/TblCnInv=0; Tbl_1 нет)  
**Опора:** [съём](../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/README.md)

## Решения

| Тема | Решение |
|------|---------|
| Имена | Access-like (`CnInvPmtUpl*`, `cipuf*` / `ciput*`) |
| FK `cipufUpload`→pm_upl | **нет** (`sudz.cn_inv_pm_upl` пуст; ключи 7…36 из `ags`) |
| `Tbl_1` | **не** создавать (дубль Tbl) |
| Seed | **30** File; Tbl/TblCnInv пустые (CSV Tbl 7736 — для воронки позже) |
| DocCode GUID | `nvarchar(50)` по факту CSV |

## Скрипты

| Файл | |
|------|--|
| `26_CREATE_CnInvPmtUpl_staging_S61d.sql` | CREATE 3 tables |
| `27_SEED_CnInvPmtUplFile_Access.sql` | MERGE File 30 + RESEED |
