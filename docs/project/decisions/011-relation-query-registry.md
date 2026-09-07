# Решение 011: relationQuery — реестр именованных SELECT для дерева

**Дата:** 2026-08-28  
**Последнее обновление:** 2026-09-04  
**Статус:** ✅ Принято (v1)  
**Участники:** Александр, Cursor AI

## Проблема

Relation-дерево (`RelationTree` + JSON экземпляра) умеет обход **FK-рёбер** (`relationExpand`). Для `invDbtVar` человекочитаемый контекст (счёт ГК, № договора, № СФ, организация) требует 5–7 join’ов — «борода» в JSON неприемлема для оператора. При этом передавать **произвольный SQL с клиента** нельзя (безопасность, prod FishEye 2012).

## Решение

Третий канал данных рядом с `relationNode` / `relationExpand`:

| API | Назначение |
|-----|------------|
| `relationNode` | строка whitelist-таблицы |
| `relationExpand` | FK-ребро из `RelationEdgeCatalog` |
| **`relationQuery`** | **именованный SELECT** из **`RelationQueryCatalog`** (Java) |

### Правила

1. **SQL только на backend** — клиент передаёт `queryId` + `fromId` (bind `?`).
2. JSON экрана может содержать **`queryId`** на ребёнке (`RelationTreeChildSpec`); walker вызывает `fetchQuery`.
3. Запрос: только `SELECT`, один statement, `TOP`/maxRows, timeout 5 с.
4. Ответ — тот же **`RelationRow`** (`key` + `fields[]`) для `FemsqTree`.
5. Walker/feQuLib **не** содержат SQL; реестр — в `femsq-database` (хост).

### Первый запрос (пилот)

`sudz.invDbtVar.contextBySlot` — контекст var по `invDbt.idKey`; поле **`summaryLine`** для заголовка узла.

JSON: [`inv-dbt-slots.tree.json`](../../../code/femsq-frontend-q/src/trees/inv-dbt-slots.tree.json) v3
(`contextBySlot` + вложенный `sudz.DbtValue.bySlotVarBridge` с именем/датой свода).

## Альтернативы (отклонены)

- SQL-строка в JSON с wire на backend — ❌ injection / audit.
- SQL View + pseudo-table — допустимо позже; v1 — Java-реестр (быстрее итерации).
- Отдельный sudz-only GraphQL без relation-слоя — дублирование контракта дерева.

## Связанные решения

- [009 Обходник связей](./009-femsq-walk-tree.md)
- [010 ECharts / КСДД 22c](./010-chart-platform-echarts.md)

## Следующие шаги

- Документировать `queryId` в [relation-tree.md](../../development/notes/UI/02-12_femsq-tree/relation-tree.md) §2.
- При втором потребителе — вынести SQL в `docs/development/notes/sql/` + ссылка из реестра.
