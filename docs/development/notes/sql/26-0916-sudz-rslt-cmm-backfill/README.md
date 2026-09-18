# Пакет: DEV-бэкфилл комментариев Rslt (cmm) из Access Excel

**Создан:** 2026-09-16  
**lastUpdated:** 2026-09-16  
**Цель:** после S80 заполнить годовые колонки Rslt (куратор / мероприятия / код стройки) на DEV из эталона `ags_Yr_DbtChangesRslt_26-0505.xlsx`, чтобы файл **Rslt сбор** был пригоден к шагу **1.1.1.3**.

## Контекст

| Поле Excel | Таблица | Группа |
|------------|---------|--------|
| Куратор / Мероприятия («старые») | `sudz.cnInvCmm` (type 8 / 1) | `yr.yr_CmmGr` (=903) |
| Код стройки (год) | `sudz.cnInvCmmCst` (type 2) | `yr.yr_CmmGr` |
| `*_new` | `cnInvCmm` / `cnInvCmmCst` | `yr.yr_CmmGr_New` (=904) |

Экспортёр Rslt **сбор** читает «старые» по `cnicInvAccnt = dbtKey` и оставляет `*_new` пустыми (`ColKind.EMPTY`). **Повтор** читает New.

## Скрипт

[`03_BACKFILL_CMM_FROM_ACCESS_EXCEL.mjs`](./03_BACKFILL_CMM_FROM_ACCESS_EXCEL.mjs)

```bash
node 03_BACKFILL_CMM_FROM_ACCESS_EXCEL.mjs [--dry]
```

Матчинг строк: softBase → softQi (как S80). Коды стройки → `ags.cstAgPn.cstapIpgPnN` (COLLATE).

## Итог DEV (2026-09-16)

| Показатель | Значение |
|------------|----------|
| pairs | 1791 |
| curator / mery @903 | **53 / 53** |
| year cst @903 | **1777** (из 1778; 1× `строек: 2` — multi, не код) |
| mery_new @904 | **13** (видны в `rslt-povtor`, не в sborn) |

Сверка: [`stage2_s81_cmm_vs_access_26-0916.json`](../26-0831-sudz-dbt-slot-link/artifacts/stage2_s81_cmm_vs_access_26-0916.json)  
Excel: [`ags_Yr_DbtChangesRslt_901_asOf903_s81_cmm_26-0916.xlsx`](../26-0831-sudz-dbt-slot-link/artifacts/ags_Yr_DbtChangesRslt_901_asOf903_s81_cmm_26-0916.xlsx)

## Связь

- План: [chat-plan S81](../../chats/chat-plan/chat-plan-26-0802-sudz.md)  
- S80 стройки: [26-0915-sudz-rslt-cst-backfill](../26-0915-sudz-rslt-cst-backfill/)
