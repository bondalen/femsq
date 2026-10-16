# Прод-пакет: Acc → `*Dv` walk-back (узел 4.3)

**Дата:** 2026-10-16  
**Платформа скриптов:** SQL Server 2012 SP4 (`11.0.7507.2`) и новее  
**Контур данных:** схема `sudz` (колонки `cnicDv` / `ciccDv` уже есть)  
**На продуктив не применялся.**

Канон привязки — [08 §7](../26-0908-sudz-split-merge-sandbox/08_CMM_AND_RSLT.md): Value крайней upl года, который смотрит на группу (`yr_CmmGr` или `yr_CmmGr_New`); если на крайней нет долей — предшествующие upl того же года. Нет Value в году — строка остаётся на `*InvAccnt`.

Группа без указателя года не угадывается и не переписывается. Поэтому пакет не «тихо» сажает 905/906, пока на них не смотрит `sudz.yr`.

DDL колонок `*Dv` сюда не входит (`02_DRAFT` / `05_UX` в `26-0908-sudz-split-merge-dev` — только DEV `sudz`). На `ags.cnInvCmm` колонки `cnicDv` нет: `00` такой контур останавливает.

Порядок и день деплоя: [db-upgrade-cmm-dv-walkback.md](../../../../deployment/db-upgrade-cmm-dv-walkback.md).

| Файл | Действие |
|------|----------|
| [MSSQL2012/00_VERIFY_before.sql](MSSQL2012/00_VERIFY_before.sql) | версия, колонки, индексы |
| [MSSQL2012/01_DRYCHECK_cmm_Dv_walkback.sql](MSSQL2012/01_DRYCHECK_cmm_Dv_walkback.sql) | сколько строк сядет / останется |
| [MSSQL2012/02_MIGRATE_cmm_Dv_walkback.sql](MSSQL2012/02_MIGRATE_cmm_Dv_walkback.sql) | UPDATE + копии на доли |
| [MSSQL2012/03_VERIFY_after.sql](MSSQL2012/03_VERIFY_after.sql) | остаток `*Dv IS NULL` |
| [MSSQL2012/04_ROLLBACK.sql](MSSQL2012/04_ROLLBACK.sql) | не откатывает данные; напоминает про бэкап |
