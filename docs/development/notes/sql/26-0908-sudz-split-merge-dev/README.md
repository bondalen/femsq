# Черновик DDL split/merge — схема `sudz` (DEV)

**Дата:** 2026-09-08  
**lastUpdated:** 2026-10-15  
**Статус:** S77.2 `01` на DEV `sudz` ✅. S77 I4 `02` (*Dv) ✅. Backfill `03`/`04` ✅ 2026-09-09. UX `05` (*Dv) ✅ 2026-10-14. Миграция группы 907 `06` ✅ 2026-10-14 (узел 3.5). Walk-back группы 1909 `07` ✅ 2026-10-15.  
**Не копировать** в `MSSQL2012/` и не применять на продуктив.

**План:** [chat-plan-26-0802-sudz.md §S77](../../chats/chat-plan/chat-plan-26-0802-sudz.md#s77--splitmerge-ядро--воронка--rslt-ac-dev-2026-09-08)  
**Канон полос A/C:** [08_CMM_AND_RSLT.md](../26-0908-sudz-split-merge-sandbox/08_CMM_AND_RSLT.md)  
**Песочница (уже relaxed):** `test_sudz_sm` — [04_RELAX.sql](../26-0908-sudz-split-merge-sandbox/04_RELAX.sql)  
**Живая фикстура UAT:** `iKey=85166`, слот 11897, ciud 2807/2808 @901 (2×18000). Этот пакет **сам по себе** 85166 не split'ит.

## Состав

| Файл | Что | Когда |
|------|-----|-------|
| `01_DRAFT_relax_split_constraints.sql` | DROP `UX_invDbtDbt_InvDbt`; Consistency: п.4 с исключением «тот же Dbt»; п.5 снят | S77.2 DEV (согласовано) |
| `02_DRAFT_cmm_D3double_Dv.sql` | nullable `*Dv` → `DbtValue` рядом с D3′ `*Dbt` | S77 I4 DEV 2026-09-09 ✅ |
| `03_DRYCHECK_cmm_Dv.sql` | SELECT: группа → upl года по дате → единственная Value | S77 I4 backfill |
| `04_BACKFILL_cmm_Dv.sql` | UPDATE `*Dv` (+ `*Dbt` из `*InvAccnt`) при nval=1 | DEV 2026-09-09 ✅ |
| `05_UX_cmm_Dv.sql` | Filtered UNIQUE `(группа[, тип/имя], *Dv)` | узел 3.2 DEV 2026-10-14 ✅ |
| `06_DRYCHECK_cmm_Dv_group_907.sql` | SELECT: nval по крайним upl годов группы 907 | узел 3.5 |
| `06_MIGRATE_cmm_Dv_group_907.sql` | Acc→*Dv на Value крайних upl (expand полосы) | узел 3.5 DEV 2026-10-14 ✅ |
| `07_MIGRATE_cmm_Dv_group_1909_walkback.sql` | Acc→*Dv walk-back (крайняя → предшествующие) | 4.2 / DEV 2026-10-15 ✅ |

`test_sudz` (эталон 82/85) в черновик **не** входит. Прод-миграция исторических групп — отдельный пакет (не этот `06`).

## Что не меняем этими скриптами

- `UNIQUE(dvInvDbt, dvUpl)`
- `UNIQUE(iddInvDbt)` / `UNIQUE(idInv, idNum)`
- Consistency п.1–3
- `*InvAccnt`, D3′ `*Dbt`
- данные 85166 / очередь КСДД
