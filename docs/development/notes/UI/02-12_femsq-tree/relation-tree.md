# Relation tree: карта экземпляра (JSON) + каталог рёбер

**Дата:** 2026-08-18  
**Статус:** срез 1 + **T4b** (fetch пропсами, `to` в JSON); полный JSON КСДСФ/Договоры ещё не на обходнике  
**План:** [chat-plan-26-0802-sudz.md](../../chats/chat-plan/chat-plan-26-0802-sudz.md) S68t  
**ADR:** [Решение 009](../../../../project/decisions/009-femsq-walk-tree.md)  
**Конспекты:** [ksdsf-inv-num.tree.md](./ksdsf-inv-num.tree.md) · [contracts-inv.tree.md](./contracts-inv.tree.md)  
**JSON:** [`ksdsf-inv-num.tree.json`](../../../../code/femsq-frontend-q/src/trees/ksdsf-inv-num.tree.json) · [`contracts-inv.tree.json`](../../../../code/femsq-frontend-q/src/trees/contracts-inv.tree.json)  
**Renderer:** FemsqTree v1 (feQuLib **0016** done) · не путать с [FemsqTable](../02-8_femsq-table-component.md) · обходник — не `FemsqTree`

## 0. Решение

Три слоя ([Решение 009](../../../../project/decisions/009-femsq-walk-tree.md)):

| Слой | Сейчас | Правило |
|---|---|---|
| Renderer | `FemsqTree` | только `nodes` / слоты / `@load`; не знать JSON, рёбра, GraphQL |
| Walker | `RelationTree.vue` + `relation-tree.ts` | JSON экземпляра → узлы; **без** импорта API хоста (после **T4b**); кандидат в feQuLib как `FemsqWalkTree` (**T9**) |
| Хост | каталог, SQL, `relation-api.ts`, JSON экранов | навсегда в FEMSQ |

1. **`FemsqTree` ничего не знает** о СУДЗ, Excel, вкладках, рёбрах. Только `nodes` / слоты.
2. **Walker** знает: таблица корня, ключ записи, **JSON этого экземпляра**. Fetch — колбэки хоста (`fetchNode` / `fetchExpand`). Каталог рёбер (как читать БД) — **не** внутри walker.
3. **У каждого экземпляра свой JSON** и **свой markdown-конспект** того же дерева (формат как [sudz-sf-double-tree.md](./sudz-sf-double-tree.md): вложенный список, у узла заголовок / деталь / дети). JSON — для обходника (`code/femsq-frontend-q/src/trees/`), md — здесь, чтобы читать глазами. Нет `$ref` между экземплярами.
4. Сменилась пара `(таблица, ключ)` — дерево пересобираем. Не сменилась — нет.
5. **T4b до T5/T7:** поле `to` в JSON ребёнка; walker не читает `RELATION_EDGES`. Иначе второй экран копирует связанный с FEMSQ код.
6. Вынос в feQuLib (**T9**) — после T7 или когда второй продукт берёт дерево. Не смешивать с **T8** (дыра renderer).

Экземпляры v0:

| Экземпляр | Экран | Корень | JSON | Конспект |
|---|---|---|---|---|
| КСДСФ, низ вкладки «Счета-фактуры» | выбранная строка верхнего списка | `invNum` / `inKey` | [`ksdsf-inv-num.tree.json`](../../../../code/femsq-frontend-q/src/trees/ksdsf-inv-num.tree.json) | [ksdsf-inv-num.tree.md](./ksdsf-inv-num.tree.md) |
| Договоры, вкладка «Счета-фактуры» | выбранный `cnInv` → `ciInv` | `inv` / `iKey` | [`contracts-inv.tree.json`](../../../../code/femsq-frontend-q/src/trees/contracts-inv.tree.json) | [contracts-inv.tree.md](./contracts-inv.tree.md) |

## 1. Что общее, что нет

| Слой | Общее (менять осторожно) | Своё у хоста / экземпляра |
|---|---|---|
| Renderer | `FemsqTree` | слоты header/detail, CRU-формы позже (реестр на хосте) |
| Walker | схема JSON, папки 1:N, токен `(table, id)`, lazy `@load` | — |
| Хост | форма GraphQL `{ key, fields }` как образец | каталог **рёбер** (SQL, from/to, PK), схема `ags`/`sudz` |
| Экземпляр | — | какие рёбра **показывать**, порядок, папки, title/detail, корень |

Добавить ребро в каталог ≠ оно появится на другом экране. Появится только если его впишут в **тот** JSON.

## 2. Схема JSON экземпляра

Один файл = одно дерево от корня. Вложенность `children` = что раскрывать. Нет `children` / `[]` — дальше не идём (цикл отсекается самим деревом спецификации).

```json
{
  "id": "ksdsf-inv-num",
  "root": { "table": "invNum", "pk": "inKey" },
  "title": ["inNum", "inKey"],
  "detail": ["inKey", "inNum", "inNumNull", "inInv"],
  "children": [
    {
      "edge": "invNum.inv",
      "to": "inv",
      "card": "N:1",
      "title": ["iKey"],
      "detail": ["iKey", "iTimeOfEntry"],
      "children": []
    }
  ]
}
```

Поля узла:

| Поле | Смысл |
|---|---|
| `edge` | имя из каталога хоста; у корня нет `edge`, есть `root` |
| `to` | таблица назначения (обязательно с **T4b**); walker не резолвит `to` из каталога |
| `card` | как **рисовать**: `N:1` / `1:1` — сразу запись; `1:N` — пустышка-папка + строки. Должно согласовываться с каталогом, но папку можно включить и для N:1, если нужно |
| `folder` | подпись пустышки при `1:N` (иначе имя `edge`) |
| `title` | колонки заголовка |
| `detail` | колонки карточки; `"*"` = все колонки строки expand |
| `children` | что грузить при expand этой записи |

Корень файла обязан совпадать с тем, что передаёт хост (`invNum`+`inKey` или `inv`+`iKey`). Иначе экземпляр не монтируем.

## 3. Каталог рёбер (инфраструктура, не экран)

Whitelist на хосте: Java `RelationEdgeCatalog` + FE `relation-edges.ts` (срез 1: три ребра). Walker без имени ребра из каталога **не** ходит в БД. После **T4b** FE-каталог нужен хосту для проверки имён, не чистым функциям walker.

Сверка колонок: DBHub, `ags`/`sudz`, 2026-08-18. Якорь КСДСФ: `inv.iKey=85069`, `invNum.inKey=85078`, `iNum`=`inNum`=`832930`.

| edge | from → to | ключи | card в БД | в JSON v0 |
|---|---|---|---|---|
| `invNum.inv` | `ags.invNum` → `ags.inv` | `inInv` = `iKey` | N:1 | КСДСФ |
| `inv.invNum` | `ags.inv` → `ags.invNum` | `iKey` = `inInv` | 1:N | нет (список КСДСФ / `iNum` на корне Договоров) |
| `inv.cnInv` | `ags.inv` → `ags.cnInv` | `iKey` = `ciInv` | 1:N | оба |
| `cnInv.cn` | `ags.cnInv` → `ags.cn` | `ciCn` = `cn_key` | N:1 | оба |
| `cn.cnNum` | `ags.cn` → `ags.cnNum` | `cn_key` = `cnnCn` | 1:N | оба |
| `cn.cn_s` | `ags.cn` → `ags.cn_s` | `cn_key` = `cn_key` | 1:N | оба |
| `cn_s.smpl` | `ags.cn_s` → `ags.cn_s_org_smpl` | `cn_s_key` = `csosCn_s` | 1:N | оба |
| `smpl.org` | `ags.cn_s_org_smpl` → `ags.cn_s_org` | `csosKey` = `csoCn_s_org_smpl` | 1:N | оба |
| `cnInv.cias` | `ags.cnInv` → `ags.cnInvAccntSmpl` | `ciKey` = `ciasCnInv` | 1:N | оба |
| `cias.accnt` | `ags.cnInvAccntSmpl` → `ags.accnt` | `ciasAccnt` = `account_key` | N:1 | нет (в title smpl — `ciasAccnt`; `account_num` join позже) |
| `cias.cia` | `ags.cnInvAccntSmpl` → `ags.cnInvAccnt` | `ciasKey` = `ciaCnInvAccntSmpl` | 1:N | оба |
| `cia.cid` | `ags.cnInvAccnt` → `ags.cn_inv_dbt` | `ciaKey` = `cidCnInvAccntCtpt` | 1:N | оба |
| `cid.upl` | `ags.cn_inv_dbt` → `ags.cn_inv_dbt_upl` | `cn_inv_dbt_upl` = `upl_key` | N:1 | оба |
| `inv.invDbt` | `ags.inv` → `sudz.invDbt` | `iKey` = `idInv` | 1:N | оба |
| `invDbt.idd` | `sudz.invDbt` → `sudz.invDbtDbt` | `idKey` = `iddInvDbt` | 1:N | оба |
| `idd.dbt` | `sudz.invDbtDbt` → `sudz.Dbt` | `iddDbt` = `dbtKey` | N:1 | оба |
| `dbt.dv` | `sudz.Dbt` → `sudz.DbtValue` | `dbtKey` = `dvDbt` | 1:N | оба |

**Не колонки (lookup, не класть в `title` как имя поля):** подпись орг./БУиРГ по `csosOrgId`; `account_num` по `ciasAccnt`. У `Dbt` нет поля `DbtValue` — величины в `sudz.DbtValue`.

Таблицы вне каталога через API недоступны.

## 4. API

Walker (после **T4b**):

```text
spec + rootId + fetchNode(table, id) + fetchExpand(edge, fromId)
```

Хост FEMSQ передаёт Apollo через пропсы (`SudzSfDoubleView` → `fetchRelationNode` / `fetchRelationExpand`). Walker API не импортирует.

Backend (не знает экранов и walker):

```text
relationNode(table: String!, id: Int!): RelationRow
relationExpand(edge: String!, fromId: Int!): [RelationRow!]!
```

`RelationRow`: ключ, `fields { name, value }`. Lazy: при `@load` walker берёт `children[].edge` из JSON и зовёт `fetchExpand`.

## 5. Порядок работ

Чеклист и срезы исполнения — **S68t** в [chat-plan-26-0802-sudz.md](../../chats/chat-plan/chat-plan-26-0802-sudz.md) (T0–T9). Здесь только смысл шагов:

1. Зафиксировать §2–§3 (схема JSON + список рёбер v0) — **T0** ✅ сверка 2026-08-18.  
2. Два независимых JSON по конспектам — **T1** 🔶 ревью (`src/trees/*.tree.json`).  
3. Каталог рёбер + `relationExpand` — **T2–T3** ✅ срез 1 (`invNum.inv`, `inv.cnInv`, `cnInv.cn`; плюс `relationNode` для корня).  
4. Обёртка над `FemsqTree` — **T4** ✅ `RelationTree.vue`, КСДСФ флаг `useRelationWalker`, spec `ksdsf-inv-num.slice1.tree.json`.  
5. **Отвязать walker от хоста** — **T4b** ✅: `fetchNode`/`fetchExpand` пропсами; `to` в JSON; без `RELATION_EDGES` в чистых функциях.  
6. КСДСФ: верхний список; низ = обёртка(`invNum`, `inKey`, json КСДСФ); выкинуть `buildSudzSfDoubleTree` — **T5–T6**.  
7. Договоры: вкладки «Общее» / «Счета-фактуры»; слева `cnInv`, справа обёртка(`inv`, `ciInv`, json Договоров) — **T7**.  
8. CRU не в v0. Формы — позже (`"form"` в JSON, реестр на хосте). Дыра `FemsqTree` — **T8**. Вынос walker в feQuLib (`FemsqWalkTree`) — **T9**, после T7 / второго продукта.

## 6. Вне v0

- Общий JSON на два экрана, `$ref`, стоп-таблицы как список.
- SQL / DSN / имена экранов внутри JSON.
- Walker внутри `FemsqTree`.
- CRUD в feQuLib.
- Обход всех FK базы.
- Корень-группа по `inNumNull` (список КСДСФ это закрывает).
- Вынос Java `RelationEdgeCatalog` в библиотеку.
