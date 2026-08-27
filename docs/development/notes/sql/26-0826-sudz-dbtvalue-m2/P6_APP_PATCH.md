# P6 — патч приложения под M2 `DbtValue` (выкладка **после** B1)

**Дата:** 2026-08-26  
**План:** B1-prep P6 · [chat-plan S72](../../chats/chat-plan/chat-plan-26-0802-sudz.md)  
**Статус:** ✅ код в дереве готов; **не** деплоить JAR/frontend до apply SQL B1 (см. P7).

## Целевая модель API

| Было | Стало |
|------|--------|
| `SudzSfDoubleNewSumMatch.dvDbt` | `dvInvDbt` + опц. `dbtKey` (LEFT JOIN `invDbtDbt`) |
| hints `sumsNew`: join `iddDbt = dv.dvDbt` | join `invDbt.idKey = dv.dvInvDbt` |
| рёбра `dv.dbt` / `dbt.dv` (FK `dvDbt`) | `dv.invDbt` / `invDbt.dv` (FK `dvInvDbt`) |

## Изменённые файлы

### Backend

| Файл | Суть |
|------|------|
| `SudzSfDoubleNewSumMatch.java` | record: `dvInvDbt`, `dbtKey` |
| `JdbcSudzDao.java` | `findNewSumMatches` / `findNewSumHintItems` |
| `sudz-schema.graphqls` | поля GQL |
| `RelationEdgeCatalog.java` | колонки DV; рёбра `dv.invDbt`, `invDbt.dv`; удалены `dv.dbt`, `dbt.dv` |
| `RelationEdgeCatalogTest.java` | ожидания рёбер |

### Frontend

| Файл | Суть |
|------|------|
| `src/types/sudz.ts` | типы |
| `src/api/sudz-api.ts` | query fields |
| `SudzSfDoubleView.vue` | колонки invDbt / dbt |
| `relation-edges.ts` | whitelist |
| `ksdsf-dv-sum.tree.json` | корень: `dv → invDbt → …` |
| `ksdsf-inv-num.tree.json` | Values: `invDbt.dv` (sibling к idd) |
| `contracts-inv.tree.json` | то же |

## Порядок выкладки (P7)

1. Baseline P2 ✅  
2. Apply SQL `01`→`04` (+ trigger)  
3. **Сразу** этот JAR/frontend  
4. Smoke P2b–P2e  

**Запрет:** работающий backend/Vite на **старой** БД (`dvDbt`) с этим патчем — SQL error на sums/hints/expand.

## Вне scope P6

- Seed SQL репо (`09`/`17`) → **B2**  
- Прод `MSSQL2012/` → **D3**  
- Value в calm / экран двоящих → **B1b / A2**
