# Relation tree: карта экземпляра (JSON) + каталог рёбер

**Дата:** 2026-08-18 · **обновлено:** 2026-08-19  
**Статус:** **T1** ✅ (полные JSON v1); **T4b** ✅; **T5** ✅ (полный каталог + экран КСДСФ на `ksdsf-inv-num.tree.json`); далее **T6** UAT + проектирование actions/forms  
**План:** [chat-plan-26-0802-sudz.md](../../chats/chat-plan/chat-plan-26-0802-sudz.md) S68t  
**ADR:** [Решение 009](../../../../project/decisions/009-femsq-walk-tree.md)  
**Конспекты:** [ksdsf-inv-num.tree.md](./ksdsf-inv-num.tree.md) · [contracts-inv.tree.md](./contracts-inv.tree.md) · [ksdsf-cid-sum.tree.md](./ksdsf-cid-sum.tree.md) · [ksdsf-dv-sum.tree.md](./ksdsf-dv-sum.tree.md)  
**JSON:** [`ksdsf-inv-num.tree.json`](../../../../code/femsq-frontend-q/src/trees/ksdsf-inv-num.tree.json) · [`contracts-inv.tree.json`](../../../../code/femsq-frontend-q/src/trees/contracts-inv.tree.json) · [`ksdsf-cid-sum.tree.json`](../../../../code/femsq-frontend-q/src/trees/ksdsf-cid-sum.tree.json) · [`ksdsf-dv-sum.tree.json`](../../../../code/femsq-frontend-q/src/trees/ksdsf-dv-sum.tree.json)  
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
6. Действия CRUD и навигации описываются **декларативно в JSON**, но выполняются **на хосте**. Walker/renderer не знают GraphQL, SQL, экранов и модалок проекта.
7. Универсальная форма под деревом — это **форма записи таблицы**, а не только “форма связи двух FK”. Таблица связи — частный случай записи.
8. Вынос в feQuLib (**T9**) — после T7 или когда второй продукт берёт дерево. Не смешивать с **T8** (дыра renderer).

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

### 2.1. Действия узла (проектируется после T5)

Следующий слой поверх дерева — **декларативные actions** на узлах и папках. Правило слоёв:

- JSON описывает, **какое действие доступно** и **какую форму/модалку открыть**.
- `RelationTree` только рисует action и отдаёт наружу `actionId + context`.
- Хост FEMSQ решает, **какой GraphQL query/mutation** вызвать и как обновить дерево после успеха.

Минимальные сущности контракта:

| Сущность | Где живёт | Назначение |
|---|---|---|
| `actions[]` в JSON | экземпляр дерева | какие действия видны на узле / папке |
| `ActionContext` | walker → хост | `root`, `node`, `edge`, `fromId`, `rowKey`, `fields` |
| `formSpec` | JSON / реестр хоста | схема универсальной формы записи |
| `pickerSpec` | JSON / реестр хоста | как выбирать FK/lookup-поля |

Базовые типы действий v1:

- `create-child`
- `link-related`
- `unlink-related`
- `open-form`
- `navigate`
- `delete-record`

### 2.2. Универсальная форма записи

Форма под `RelationTree` проектируется как **универсальная модалка записи таблицы**:

- обычная сущность (`cn`, `inv`, `org`, `cn_s_org`) — одна запись;
- таблица связи (`cnInv`) — тоже одна запись;
- таблица связи с доп. полями (`leftId`, `rightId`, `relationTypeId`, `note`) — та же модель, только полей больше.

Из этого следуют правила:

1. Верхняя часть модалки — **поля записи**.
2. Нижняя часть — **picker-вкладки для FK/lookup-полей**, а не “экраны вообще”.
3. Для тяжёлого выбора FK используется шаблон `таблица кандидатов + нижнее дерево`.
4. Для простого lookup используется `lookup-list` / `enum`.

Примеры kinds полей v1:

- `display`
- `text`
- `number`
- `date`
- `boolean`
- `fk-single`
- `enum-fk`
- `readonly-fixed`

Примеры kinds picker v1:

- `lookup-list`
- `table-tree-picker`

### 2.3. Симметричная модалка связи

Для `cnInv` якорь зависит от того, из какой ветви открыта модалка:

- из `inv.cnInv` фиксирован `invId = folder.fromId`;
- из симметричного узла со стороны договора фиксирован `cnId = folder.fromId`.

Форма должна уметь вернуть **пару `cnId + invId`** независимо от направления входа. Если таблица связи позже получит доп. поля (тип связи, дата, note), они просто добавляются в верхнюю часть формы и получают свои picker/lookup.

По умолчанию: **контекст входа в модалку влияет только на блокировку FK/lookup-полей (`locked`/`disabled`)**, но не на состав доступных кандидатов и не на работу поиска/фильтрации внутри picker. Любые отступления от этого правила (например, намеренное ограничение кандидатов по контексту) должны приниматься отдельным решением и фиксироваться как “исключение”, чтобы не ломать универсальность компонента.

### 2.4. Конкретная JSON-схема v1

Ниже — **практический v1-контракт**, который можно реализовывать без SQL/GraphQL внутри walker.

#### 2.4.1. `actions[]` у узла / папки

```json
{
  "edge": "inv.cnInv",
  "to": "cnInv",
  "card": "1:N",
  "folder": "СФ, связи с договорами",
  "title": ["ciKey", "ciCn"],
  "detail": "*",
  "actions": [
    {
      "id": "cnInv.link.create",
      "kind": "link-related",
      "label": "Добавить связь",
      "icon": "add_link",
      "scope": "folder",
      "modal": "record",
      "form": "cnInv.link",
      "visibleWhen": {
        "nodeKind": "folder",
        "edge": "inv.cnInv"
      }
    }
  ],
  "children": []
}
```

Поля action v1:

| Поле | Смысл |
|---|---|
| `id` | стабильный id действия |
| `kind` | `create-child`, `link-related`, `unlink-related`, `open-form`, `navigate`, `delete-record` |
| `label` | подпись кнопки |
| `icon` | иконка |
| `scope` | `record`, `folder`, `both` |
| `modal` | пока `record` или `none` |
| `form` | id формы в реестре хоста |
| `visibleWhen` | простой фильтр видимости |

#### 2.4.2. `ActionContext`, который walker отдаёт хосту

Не JSON-файл, а shape события `@action`:

```json
{
  "actionId": "cnInv.link.create",
  "root": {
    "table": "invNum",
    "id": 85078
  },
  "node": {
    "kind": "folder",
    "table": "cnInv",
    "edge": "inv.cnInv",
    "fromId": 85069,
    "rowKey": null,
    "title": "СФ, связи с договорами",
    "fields": {}
  }
}
```

Правило:

- для `inv.cnInv` хост получает `fromId = invId`;
- для симметричного узла со стороны договора хост получит `fromId = cnId`.

#### 2.4.3. `formSpec` в реестре хоста

Пример для таблицы связи `cnInv`:

```json
{
  "id": "cnInv.link",
  "mode": "create",
  "table": "cnInv",
  "title": "Связь договора и СФ",
  "result": {
    "kind": "record",
    "shape": "cnInvPair"
  },
  "fields": [
    {
      "name": "cnId",
      "label": "Договор",
      "kind": "fk-single",
      "required": true,
      "display": {
        "template": "{{ cnDisplayNumber }}",
        "fallback": "—"
      },
      "picker": "cn-picker"
    },
    {
      "name": "invId",
      "label": "СФ",
      "kind": "fk-single",
      "required": true,
      "display": {
        "template": "{{ invDisplayNumber }}",
        "fallback": "—"
      },
      "picker": "inv-picker"
    }
  ]
}
```

#### 2.4.4. `fieldSpec`

Пример фиксированного якоря:

```json
{
  "name": "invId",
  "label": "СФ",
  "kind": "readonly-fixed",
  "required": true,
  "valueFromContext": {
    "source": "node.fromId"
  },
  "display": {
    "template": "{{ invDisplayNumber }}",
    "fallback": "—"
  },
  "picker": "inv-picker",
  "locked": true
}
```

Пример доп. поля у таблицы связи:

```json
{
  "name": "relationTypeId",
  "label": "Тип связи",
  "kind": "enum-fk",
  "required": true,
  "picker": "relation-type-picker"
}
```

Поля `fieldSpec` v1:

| Поле | Смысл |
|---|---|
| `name` | имя поля записи |
| `label` | подпись |
| `kind` | `display`, `text`, `number`, `date`, `boolean`, `fk-single`, `enum-fk`, `readonly-fixed` |
| `required` | обязательность |
| `valueFromContext` | взять значение из `ActionContext` |
| `display` | как показывать выбранное значение |
| `picker` | id picker-конфига |
| `locked` | редактирование запрещено |

#### 2.4.5. `pickerSpec`

Тяжёлый picker: `таблица + нижнее дерево`.

Для договора:

```json
{
  "id": "cn-picker",
  "kind": "table-tree-picker",
  "tabLabel": "Договоры",
  "valueField": "cnId",
  "displayField": "cnDisplayNumber",
  "table": {
    "source": "cnCandidatesForCnInv",
    "columns": [
      { "name": "cnDisplayNumber", "label": "Договор" },
      { "name": "cnCounterparty", "label": "Контрагент" },
      { "name": "cnId", "label": "cn" }
    ]
  },
  "tree": {
    "rootTable": "cn",
    "rootIdField": "cnId",
    "specId": "cn-picker"
  }
}
```

Для СФ:

```json
{
  "id": "inv-picker",
  "kind": "table-tree-picker",
  "tabLabel": "Счета-фактуры",
  "valueField": "invId",
  "displayField": "invDisplayNumber",
  "table": {
    "source": "invCandidatesForCnInv",
    "columns": [
      { "name": "invDisplayNumber", "label": "СФ" },
      { "name": "invEntered", "label": "Ввод" },
      { "name": "invId", "label": "inv" }
    ]
  },
  "tree": {
    "rootTable": "inv",
    "rootIdField": "invId",
    "specId": "inv-picker"
  }
}
```

Лёгкий picker-lookup:

```json
{
  "id": "relation-type-picker",
  "kind": "lookup-list",
  "tabLabel": "Тип связи",
  "valueField": "relationTypeId",
  "displayField": "relationTypeName",
  "lookup": {
    "source": "relationTypeLookup",
    "valueKey": "id",
    "labelKey": "name"
  }
}
```

#### 2.4.6. Режимы `cnInv.link`

| Вход | Что фиксировано |
|---|---|
| из `inv.cnInv` | `invId = node.fromId`, поле СФ locked |
| из симметричного узла договора | `cnId = node.fromId`, поле Договора locked |
| без якоря | обе стороны редактируемы |

#### 2.4.7. Возвращаемое значение модалки

Минимум:

```json
{
  "cnId": 2265,
  "invId": 85069
}
```

Если хосту нужны display-значения сразу:

```json
{
  "cnId": 2265,
  "cnDisplayNumber": "1",
  "invId": 85069,
  "invDisplayNumber": "832930"
}
```

Если у таблицы связи есть доп. поля:

```json
{
  "cnId": 2265,
  "invId": 85069,
  "relationTypeId": 3,
  "dateBeg": "2026-08-19",
  "note": "ручная привязка"
}
```

Корень файла обязан совпадать с тем, что передаёт хост (`invNum`+`inKey` или `inv`+`iKey`). Иначе экземпляр не монтируем.

## 3. Каталог рёбер (инфраструктура, не экран)

Whitelist на хосте: Java `RelationEdgeCatalog` + FE `relation-edges.ts` (**T5/T5.1:** каталог v1). Walker без имени ребра из каталога **не** ходит в БД. После **T4b** FE-каталог нужен хосту для проверки имён, не чистым функциям walker.

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
| `smpl.orgId` | `ags.cn_s_org_smpl` → `ags.org_id` | `csosOrgId` = `org_id_key` | N:1 | оба |
| `orgId.og` | `ags.org_id` → `ags.og` | `org` = `ogKey` | N:1 | оба |
| `og.orgId` | `ags.og` → `ags.org_id` | `ogKey` = `org` | 1:N | оба |
| `cnInv.cias` | `ags.cnInv` → `ags.cnInvAccntSmpl` | `ciKey` = `ciasCnInv` | 1:N | оба |
| `cias.accnt` | `ags.cnInvAccntSmpl` → `ags.accnt` | `ciasAccnt` = `account_key` | N:1 | нет (в title smpl — `ciasAccnt`; `account_num` join позже) |
| `cias.cia` | `ags.cnInvAccntSmpl` → `ags.cnInvAccnt` | `ciasKey` = `ciaCnInvAccntSmpl` | 1:N | оба |
| `cia.cid` | `ags.cnInvAccnt` → `ags.cn_inv_dbt` | `ciaKey` = `cidCnInvAccntCtpt` | 1:N | оба |
| `cid.upl` | `ags.cn_inv_dbt` → `ags.cn_inv_dbt_upl` | `cn_inv_dbt_upl` = `upl_key` | N:1 | оба |
| `inv.invDbt` | `ags.inv` → `sudz.invDbt` | `iKey` = `idInv` | 1:N | оба |
| `invDbt.idd` | `sudz.invDbt` → `sudz.invDbtDbt` | `idKey` = `iddInvDbt` | 1:N | оба |
| `idd.dbt` | `sudz.invDbtDbt` → `sudz.Dbt` | `iddDbt` = `dbtKey` | N:1 | оба |
| `dbt.dv` | `sudz.Dbt` → `sudz.DbtValue` | `dbtKey` = `dvDbt` | 1:N | оба |

**Не колонки (lookup, отложено):** `account_num` по `ciasAccnt`. У `Dbt` нет поля `DbtValue` — величины в `sudz.DbtValue`. Подпись орг./БУиРГ через цепочку `smpl.orgId` → `orgId.og` → `og.orgId` (v1.1), не join в `title` smpl.

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
2. Два независимых JSON по конспектам — **T1** ✅ 2026-08-19 (`ksdsf-inv-num` / `contracts-inv` **version 1**).  
3. Каталог рёбер + `relationExpand` — **T2–T3** ✅ срез 1 (`invNum.inv`, `inv.cnInv`, `cnInv.cn`; плюс `relationNode` для корня).  
4. Обёртка над `FemsqTree` — **T4** ✅ `RelationTree.vue`; **T5** ✅ КСДСФ на полном `ksdsf-inv-num.tree.json`.  
5. **Отвязать walker от хоста** — **T4b** ✅: `fetchNode`/`fetchExpand` пропсами; `to` в JSON; без `RELATION_EDGES` в чистых функциях.  
6. КСДСФ: верхний список; низ = обёртка(`invNum`, `inKey`, json КСДСФ); builder удалён — **T5** ✅, UAT — **T6**.  
7. **T6a (новое):** actions в `RelationTree` + хостовый `ActionContext` без GraphQL в walker.  
8. **T6b (новое):** универсальная `RecordModal`/`pickerSpec` для `cnInv` (пара `cnId + invId`), затем обобщение на обычные сущности и таблицы связи с доп. полями.  
9. Договоры: вкладки «Общее» / «Счета-фактуры»; слева `cnInv`, справа обёртка(`inv`, `ciInv`, json Договоров) — **T7**.  
10. Дыра `FemsqTree` — **T8**. Вынос walker в feQuLib (`FemsqWalkTree`) — **T9**, после T7 / второго продукта.

## 6. Вне v0

- Общий JSON на два экрана, `$ref`, стоп-таблицы как список.
- SQL / DSN / имена экранов внутри JSON.
- Walker внутри `FemsqTree`.
- CRUD-исполнение внутри feQuLib.
- Обход всех FK базы.
- Корень-группа по `inNumNull` (список КСДСФ это закрывает).
- Вынос Java `RelationEdgeCatalog` в библиотеку.
