# SQL-пакет: M2 DEV seed (СУДЗ cutover rehearsal)

**Создан:** 2026-08-27  
**Схема:** `sudz` (ags SoT не трогаем)  
**Cutover:** [db-upgrade-sudz-invdbt-cutover.md](../../../../deployment/db-upgrade-sudz-invdbt-cutover.md) §1.1–1.4, E1, §1.5  
**План:** chat-plan-26-0802-sudz.md → S74 M2  

**Бэкап до apply:** `/mnt/d/Backups/femsq/database/manual/FishEye_20260827_120738_pre-m2-seed.bak`

## Цель

Полный old→new на DEV: `invDbt` + `Dbt` + `invDbtDbt` + мост cia + **E1** + D3′ cmm.  
Итоги выгрузок/СГК должны совпадать с суммой `cn_inv_dbt` (без потерь UNIQUE).

| Ожидание (после 06a) | N |
|----------|--:|
| `invDbt` | 11 907 + N_split |
| `Dbt` | 11 897 + N_split |
| `DbtValue` | = `cn_inv_dbt` (DEV: 42 367) |
| `invDbtCia` | = число `cia` |
| N_split DEV | 9 (`M2-concurrent-cia` / `M2-cn-migrate`) |

## Конвенции seed

| Тема | Правило |
|------|---------|
| `idNum` unnamed | **0** (коллизия unnamed/`ciaName='1'`, iKey 4433) |
| `idNum` numeric | `TRY_CAST(ciaName AS tinyint)` |
| `idNum` «первая»/«вторая» | 1 / 2, если свободно на iKey |
| `idNum` прочие строки | 200 + dense_rank в пределах iKey |
| Энтропия §1.2 | `idNum=254` / `253`; Value СГК `606012` → sibling |
| **Concurrent multi-cia (06a)** | если ≥2 `cn_inv_dbt` на `(slot,upl)` — доп. `invDbt` (`idNum` 241+), `dbtNote` `M2-concurrent-cia` или `M2-cn-migrate` |
| L001–L010 | оба слота → один `Dbt` |
| `dvUpl` | FK → `sudz.cn_inv_dbt_upl` (06c; зеркало ags + funnel 910) |

## Порядок apply

```text
00_DDL_invDbtCia.sql
01_DDL_cmm_D3prime.sql
02_CLEAR_debt_layer.sql
03_SEED_grains_invDbt.sql
04_SEED_entropy_slots.sql
05_SEED_Dbt_bridges_Lmerge.sql
06_SEED_invDbtCia.sql
06a_SPLIT_concurrent_cia_slots.sql   -- обязателен до E1 / на prod
06b_DDL_DbtValue_upl_FK_ags.sql   -- legacy; superseded by 06c
06c_DDL_DbtValue_upl_FK_sudz.sql  -- sync ags→sudz upl + FK → sudz (воронка 910)
07_SEED_E1_var_value.sql
08_BACKFILL_cmm_Dbt.sql
99_VERIFY.sql
```

**M3:** код calm F1 в `JdbcSudzDao` (после M2 seed); UAT upl 910.

Откат: `ROLLBACK_M2.sql` (или restore `.bak`).

## Статус

| Шаг | Статус |
|-----|--------|
| Backup pre-m2-seed | ✅ |
| Seed + 06a + E1 full totals | ✅ 2026-08-27 re-run: invDbt=11916, Dbt=11906, DbtValue=42367=cid, split=9, concurrent=0 |

**Класс B:** iKey 40665 → `dbtNote=M2-cn-migrate` (остальные split → `M2-concurrent-cia`).
