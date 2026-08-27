# SQL-пакет: `DbtValue` M2 (S72 B1)

**Создан:** 2026-08-26  
**План:** [chat-plan S72 B1-prep](../../chats/chat-plan/chat-plan-26-0802-sudz.md#s72--дорожная-карта-реализации-слоя-i--m2--канон-2026-08-25)

| Файл | Назначение | Статус |
|------|------------|--------|
| [P1_INVENTORY_dvDbt.md](./P1_INVENTORY_dvDbt.md) | Инвентарь зависимостей | ✅ |
| [P2_BASELINE.md](./P2_BASELINE.md) | Baseline P2a–e до ALTER | ✅ |
| [00_VERIFY_before.sql](./00_VERIFY_before.sql) | Dry-check backfill (P3) | ✅ |
| [P3_VERIFY_RESULT.md](./P3_VERIFY_RESULT.md) | Результат прогона P3 | ✅ |
| [01_ALTER_sudz_DbtValue_M2.sql](./01_ALTER_sudz_DbtValue_M2.sql) | ALTER `sudz.DbtValue` | ✅ applied B1 |
| [02_ALTER_test_sudz_DbtValue_M2.sql](./02_ALTER_test_sudz_DbtValue_M2.sql) | зеркало `test_sudz` | ✅ applied B1 |
| [03_TRIGGER_DbtValue_Consistency_M2.sql](./03_TRIGGER_DbtValue_Consistency_M2.sql) | триггер §4.1 | ✅ applied B1 |
| [04_VIEW_vw_Yr_DbtFact_M2.sql](./04_VIEW_vw_Yr_DbtFact_M2.sql) | rewrite fact view | ✅ applied B1 |
| [P5_VERIFY_RESULT.md](./P5_VERIFY_RESULT.md) | сверка dbtKey M2 vs live | ✅ |
| [P6_APP_PATCH.md](./P6_APP_PATCH.md) | патч app (после B1) | ✅ в дереве; deploy с B1 |
| [P7_DEPLOY.md](./P7_DEPLOY.md) | порядок выкладки | ✅ |
| [P8_ROLLBACK.md](./P8_ROLLBACK.md) | backup / откат | ✅ диск OK |
| [P9_GO_GATE.md](./P9_GO_GATE.md) | гейт GO | ✅ GO B1 |
| [B1_APPLY_RESULT.md](./B1_APPLY_RESULT.md) | результат apply B1 | ✅ |
| [B1b_VALUE_CALM.md](./B1b_VALUE_CALM.md) | Value в calm invDbtLoad | ✅ |
| [A2_INV_DBT_DOUBLE.md](./A2_INV_DBT_DOUBLE.md) | экран двоящих v1 | ✅ |
| [99_VERIFY_after.sql](./99_VERIFY_after.sql) | пост-проверка | ✅ |

## Порядок apply

Выполнен **2026-08-26** после P9 GO — см. [B1_APPLY_RESULT.md](./B1_APPLY_RESULT.md).

1. `00_VERIFY_before.sql` (повтор, SELECT)
2. `01_ALTER_sudz_DbtValue_M2.sql`
3. `02_ALTER_test_sudz_DbtValue_M2.sql`
4. `03_TRIGGER_DbtValue_Consistency_M2.sql`
5. `04_VIEW_vw_Yr_DbtFact_M2.sql`
6. `99_VERIFY_after.sql`
7. JAR с патчем P6 (`0.1.0.217`)

