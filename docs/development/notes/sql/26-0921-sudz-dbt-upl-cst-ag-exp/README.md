# Пакет: эксперимент `DbtUplCstAgExp` (каскад 1.1–1.4)

**Создан:** 2026-09-21  
**План:** [chat-plan-26-0921-dbt-upl-cst-ag-exp.md](../../chats/chat-plan/chat-plan-26-0921-dbt-upl-cst-ag-exp.md)  
**WBS:** [0918 §1.1.1.2.5](../../chats/chat-plan/chat-plan-26-0918-sudz-rslt-prod-mailing.md) · **S83**  
**Правила SQL:** [sql-server-deployment-rules.md](../../../../deployment/sql-server-deployment-rules.md) · prod = MSSQL 2012 SP4  

## Важно

- Канон **`sudz.DbtUplCstAg`** и Java H6 **не менять**.
- Exp-таблица и proc — только для эксперимента / отдельного export.

## Порядок на DEV

| # | Файл | Назначение |
|---|------|------------|
| 0 | `00_VERIFY_before.sql` | version / объекты |
| 1 | `01_CREATE_DbtUplCstAgExp.sql` | DDL Exp |
| 2 | `02_CREATE_usp_RebuildDbtUplCstAgExp.sql` | proc каскад **1.1–1.4** |
| 3 | `03_SMOKE_rebuild_903.sql` | `EXEC` @903 + counts |
| 4 | `04_VERIFY_after.sql` | объекты на месте |
| 5 | `05_ROLLBACK.sql` | DROP view/proc/table (DEV) |
| 6 | `06_REPORT_rebuild_901_902_903.sql` | прогон трёх upl + сводка |
| 7 | `07_CREATE_vw_Yr_DbtFactExp.sql` | витрина Exp |
| **8** | `08_ALTER_DbtUplCstAg_P1.sql` | nullable FK + `ducaCode`/`ducaName` |
| **9** | `09_CREATE_usp_RebuildDbtUplCstAg_P1.sql` | канон H6 / **P1** (A/B/C, без 1.3) |
| **10** | `10_CREATE_vw_Yr_DbtFact_P1.sql` | Rslt code/name из denorm |
| **11** | `11_SMOKE_P1_903.sql` | smoke @903 |
| — | `export_cst_exp_asOf903.cjs` | rebuild Exp + xlsx/json |

Копии под 2012: `MSSQL2012/`.

## Правила proc

| `duexRule` / имя | Смысл |
|------------------|--------|
| **11** / `1.1 g_p` | ровно 1 код в pm ∩ `g_p`@upl |
| **12** / `1.2 agent` | multi@`g_p`; фильтр БУиРГ → 1 |
| **12** / `1.2 multi` | multi@`g_p`; склейка |
| **13** / `1.3 out-gp` | нет в `g_p`; вне `g_p` ровно 1 |
| **13** / `1.3 agent` | вне `g_p` multi → агент → 1 |
| **13** / `1.3 multi` | вне `g_p` multi → склейка |
| **14** / `1.4 none` | нет нигде → `не обнаружена в платежах` |

**Горизонт 1.3 (Exp / будущий P2):** pm того же `yr` → если 0 → all-time (`horizon=year`/`all`).

**Прод-политика (P1, принято 2026-09-21):** в канон Rslt входят только **g_p** (A=1.1+1.2a, B=1.2 multi); бывший 1.3 + 1.4 → **C** `не обнаружена в платежах`. Детали — план 0921 §5a.

## Канон P1 на DEV (2026-09-21)

Применено: `08`–`10`; `usp_RebuildDbtUplCstAg`; `vw_Yr_DbtFact` читает `ducaCode`/`ducaName`.  
**Guard:** нет `g_p`@upl → no-op (не затирать S80 @901).

| upl | A (FK) | B (`кодов -`) | C | ∑ | примечание |
|-----|--------|---------------|---|---|------------|
| **901** | **1659** | 0 | 0 | 1659 | S80 backfill |
| **902** | **1580** | **2** | **163** | **1745** | P1 |
| **903** | **1670** ≡ Exp 1.1 | **6** | **126** | **1802** | P1 |

Java H6 вызывает `usp_RebuildDbtUplCstAg` (нужна пересборка JAR). Отчёт: [`artifacts/cstAg_P1_rebuild_report_26-0921.json`](./artifacts/cstAg_P1_rebuild_report_26-0921.json).

## §3 отчёт DEV 2026-09-21

| upl | канон | 1.1 | 1.2 a/m | 1.3 o/a/m | 1.4 | ∑ Exp |
|-----|-------|-----|---------|-----------|-----|-------|
| **901** | 1660 (S80 бэкфилл) | **0** | 0/0 | **1567**/9/38 | 159 | 1773 |
| **902** | 1580 | **1580** | 0/2 | 8/0/7 | 148 | 1745 |
| **903** | 1670 | **1670** | 0/6 | 3/2/8 | 113 | 1802 |

- @901: **нет `g_p`** → 1.1=0; канон — Excel-бэкфилл S80; Exp наполняет через **1.3 all** (не сопоставлять 1.1↔канон).
- @902/@903: **1.1 ≡ канон** (0 расхождений ключей).

Артефакты: [`artifacts/cstExp_rebuild_report_26-0921.json`](./artifacts/cstExp_rebuild_report_26-0921.json).

## §4 витрина / Excel

- View: `sudz.vw_Yr_DbtFactExp` (`CstAgPnCode`=`duexCode`, `CstAgPnName`=`duexName` метка правила; `AgOrg` только при `duexCstAgPn IS NOT NULL`).
- Excel: [`artifacts/cstExp_yr901_asOf903_26-0921.xlsx`](./artifacts/cstExp_yr901_asOf903_26-0921.xlsx) — листы `cstExp`, `non_1_1`, `summary` (2146 / 1816 non-1.1).
