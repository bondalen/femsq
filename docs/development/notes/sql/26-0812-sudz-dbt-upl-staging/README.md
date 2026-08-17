# 0069 / S61c — DDL: Access-local → `sudz` (лаунчер свода)

**Дата:** 2026-08-12  
**Статус:** ✅ применено на DEV (FishEye / `femsq-mssql`)  
**Опора:** [съём TableDef](../../project/proposals/vba-analysis/26-0811_CtInvDbtUpl_/README.md) · план [§5.6](../../chats/chat-plan/chat-plan-26-0802-sudz.md)

## Решения владельца (2026-08-12)

| # | Вопрос | Решение |
|---|--------|---------|
| 1 | Имена Access-like | **да** |
| 2 | Без FK `cidufUpload`→upl | **да** |
| 3 | `cidutKey IDENTITY` в Tbl | **да** |
| 4 | Seed | **19 File + 114 FileSh** с Access; уточнения — при воронке |

## Скрипты

| Файл | Назначение |
|------|------------|
| [`24_CREATE_CnInvDbtUpl_staging_S61c.sql`](./24_CREATE_CnInvDbtUpl_staging_S61c.sql) | CREATE 5 таблиц |
| [`25_SEED_CnInvDbtUplFile_FileSh_Access.sql`](./25_SEED_CnInvDbtUplFile_FileSh_Access.sql) | MERGE seed + RESEED |
| [`28_SEED_cn_inv_dbt_upl_for_File_Access.sql`](./28_SEED_cn_inv_dbt_upl_for_File_Access.sql) | upl из `ags` для `cidufUpload` (экран C) |
| [`29_SEED_funnel_upl_910_2025-12.sql`](./29_SEED_funnel_upl_910_2025-12.sql) | **upl 910** — песочница воронки на срез 31.12.2025 (File+6 FileSh, Tbl пустой) |

**VERIFY:** File=19, FileSh=114; Tbl / TblCnInv / InvDouble = 0.  
**S61e:** без `28_` список UI (`sudz.cn_inv_dbt_upl`) не содержит ключи Access (2…26) → File «невидимы».  
**Ход загрузки:** slim seed `25_` **не** кладёт `cidufLoadingProgress` (RTF/HTML до ~1–2 MB/строка; полный CSV gitignored). Для UAT upl=26 лог подгружен из `CnInvDbtUplFile.csv.FULL_WITH_LOGS_DO_NOT_COMMIT` (HTML Access, ~1.1 MB).

## ER

```text
upl_key (ags|sudz)  ←логически—  cidufUpload UNIQUE
sudz.CnInvDbtUplFile
        ↓ 1:N FK
sudz.CnInvDbtUplFileSh  → ags.accnt
sudz.CnInvDbtUplTbl / TblCnInv / FileInvDouble  (эфемерные)
```

**Далее:** этап 7 — воронка `btnCidufLoad`.  
**Этап 6 (2026-08-13):** GraphQL `sudzDbtUplLauncher` / `updateSudzDbtUplFile` + UI `SudzDbtUplView`.
