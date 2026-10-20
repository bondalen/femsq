# MSSQL2012 — копии для продуктивного синтаксиса (2012 SP4)

Те же имена файлов, что в корне пакета (где применимо). Синтаксис без `CREATE OR ALTER` / `DROP IF EXISTS`
(используется `IF OBJECT_ID … DROP` + `CREATE`).

На DEV допустимо применять скрипты из корня или отсюда.

## Канон строек после 1019 (2026-10-20)

| Файл | Назначение |
|------|------------|
| `09_…_P1.sql` | предыдущий канон H6/P1 |
| **`12_…_P2_H1_H2soft_H3soft2.sql`** | **текущий** usp (= корень `14g_…`) |
| **`13_BACKFILL_DbtValue_dvDocBase_CnInv_first.sql`** | backfill Value (= корень `15_…`); нужен JAR с CnInv≻Doc |
| `14_VERIFY_after_14g.sql` | проверка после rebuild |

Деплой: [`docs/deployment/db-upgrade-sudz-dbt-upl-cst-ag-p2-14g.md`](../../../../deployment/db-upgrade-sudz-dbt-upl-cst-ag-p2-14g.md).
