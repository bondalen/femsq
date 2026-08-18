# Договоры — эталон Access `cnNum` и план экрана FEMSQ

**Дата создания:** 2026-08-15  
**Последнее обновление:** 2026-08-15 (пакеты 3–4: Accnt/dbt, lookups, PM, PrDoc; Access vs dbtvar)  
**Статус:** 🔶 эталон Access почти полный (структура); **реализация UI/API не начата**  
**Скрины Design/SQL/Runtime:** [assets/26-0815-cnNum/README.md](./assets/26-0815-cnNum/README.md) (файлы `00`–`13`, `20`–`74`)  
**Целевая модель UI:** [26-0807-sudz-target-sketch-dbtvar.png](../domain/sudz/assets/26-0807-sudz-target-sketch-dbtvar.png) — экран FEMSQ **не** клонирует Access-вложенность  
**IA:** [02-4_app-forms-ia.md](./02-4_app-forms-ia.md) — пункт TopBar «Договоры»  
**Связь с СУДЗ:** воронка 0069, шаг `CnExistCtptNotLoad` (только лог) → ручная правка стороны договора  
**План чата:** [chat-plan-26-0802-sudz.md](../chats/chat-plan/chat-plan-26-0802-sudz.md) **S62**  
**Дерево СФ (вкладка, ещё не в UI):** [contracts-inv.tree.md](./02-12_femsq-tree/contracts-inv.tree.md)  
**Задача:** [0071](../../project-development.json)

---

## 1. Зачем экран сейчас

После UAT upl **910** шаг `CnExistCtptNotLoad` находит договоры, у которых номер уже есть в БД, но исполнитель из свода не совпадает с парой в `cn_s` / smpl / `cn_s_org`. В Access VBA **не делает** пакетный INSERT стороны (`cidufFlLoad` в Sub не используется). Оператор открывает форму **`cnNum`** и правит вручную.

Без экрана «Договоры» в FEMSQ пользователь не может закрыть эти расхождения и уверенно идти дальше по воронке (СФ / карточки долга).

**Важно:** форма Access сверстана под **старый** операционный контур (`cnInvAccntSmpl` / `cnInvAccnt` / `cn_inv_dbt` / PM / PrDoc). FEMSQ-экран проектируем под **целевой** слой (`Dbt`, `invDbtVar`, `DbtValue` на эскизе). Описание Access нужно как карта «что оператор делает сегодня» и как справочник живых таблиц — не как макет web-UI.

---

## 2. Модель данных (живая `ags`)

### 2.1. Номер → договор → стороны (MVP 0071)

| Уровень | Таблица | Ключевые поля (со скринов) | Связь parent→child |
|---------|---------|----------------------------|--------------------|
| Номер | `ags.cnNum` | `cnnKey`, `cnnNum`, `cnnCn`, `cnnType`, … | корень формы |
| Тип номера | `ags.cnNumType` | `cnntKey`, `cnntName` | lookup `cnnType` |
| Договор | `ags.cn` | `cn_key`, `cn_number`, `cn_date`, `cn_note`, `cnMark` | `cnnCn` → `cn_key` |
| Сторона | `ags.cn_s` | `cn_s_key`, `cn_key`, `cn_s_type` | `cn_key` → `cn_key` |
| Org без дат | `ags.cn_s_org_smpl` | `csosKey`, `csosCn_s`, `csosOrgId`, `csosTimeOfEntry` | `cn_s_key` → `csosCn_s` |
| Org с датами | `ags.cn_s_org` | `cn_s_org_key`, `csoCn_s_org_smpl`, `date_beg`/`date_end`, `csoCnDate`, `csoAsbulID`, `csoTimeOfEntry` | `csosKey` → `csoCn_s_org_smpl` |

Для СУДЗ критичен **`cn_s_type = 2`** (исполнитель) и **`csoCnDate`**. Lookup — `csosOrgId` → `org_id` / `og`.

### 2.2. Счета-фактуры и задолженности (эталон Access; не MVP-1)

| Уровень | Таблица / объект | Ключ / link | Назначение |
|---------|-----------------|-------------|------------|
| Список связей | `ciNumCs` | `ciCn` ← `cn_key`; SQL: `cnInv ⋈ invCs` | СФ договора |
| СФ | `ags.inv` | `iKey` | карточка СФ |
| № СФ | `ags.invNum` | `inInv` ← `iKey` | номера документа |
| Мост cn↔inv | `ags.cnInv` | `ciInv` ← `iKey`; также `ciCn` | M:N договор–СФ |
| Простая карточка | `ags.cnInvAccntSmpl` | `ciasCnInv` ← `ciKey`; `ciasAccnt` ← `accnt` | счёт ГК + сторона |
| Карточка долга (Access) | `ags.cnInvAccnt` | `ciaCnInvAccntSmpl`; `ciaCn_s_org` ← `cn_s_orgCs` | операционный «долг» |
| Факт ДЗ | `ags.cn_inv_dbt` | `cidCnInvAccntCtpt` ← `ciaKey`; `cn_inv_dbt_upl` | суммы / выгрузка |
| Платежи/остатки | `ags.cn_inv_pm_dbt_upl` (форма) / `cn_inv_pm` | `ciaCnInvAccntSmpl` ← `ciasKey` | PM-сетка |
| Первичные док. | `ags.cn_PrDoc` → `ags.cn_PrDocP` | `cnpdCnInvAccntSmpl`; `pdpPrDoc` | шапка + позиции |

**Целевой слой** ([dbtvar](../domain/sudz/assets/26-0807-sudz-target-sketch-dbtvar.png)): `cn`/`inv`/`cnInv`/`cnNum` остаются; вместо пары smpl+`cnInvAccnt` — **`Dbt`**; варианты имени в своде — **`invDbtVar`**; величины — **`DbtValue`**. PrDoc вне ядра эскиза.

**Пробел эталона Access:** наполненный runtime вкладки «первичные документы» (ошибка Access у владельца); Design/SQL `PrDoc`/`PrDocP` сняты.
---

## 3. UI Access (кратко)

```text
Слева: список cnNum (cnnNum, cnnTyp≈«БУиРГ»)
Справа:
  [ договор | общее(корня=cnn*) ]
    → карточка cn: [ номер | общее(cn_number,cnMark) | счёта-фактуры ]
         номер → стороны cn_s → orgSmpl → org
         счёта-фактуры → связанные СФ → inv → invNum / cnInv → AccntSmpl → …
```

CRUD на уровнях разрешён. Вложенность 4–5 уровней вкладок; в FEMSQ сплющить UX, сохранив модель записи.

---

## 4. MVP FEMSQ — подход (утверждено 2026-08-15)

**Шаг 1:** master `CnNum` (FemsqTable, **client** filter) + detail nested `CnNum`.

**Шаг 2 (стороны, 2026-08-15):** дерево как у агентов строек (не fequlib-tree) — `cn_s` → `cn_s_org_smpl` → `cn_s_org`, **полный CRUD** на всех уровнях. UI: `ContractPartiesPanel` под номерами; GraphQL `cnSides` + мутации; lookup `csosOrgId` через `org_id` type=1 (БУиРГ). Роли заказчик/исполнитель всегда на экране (виртуальные, если нет записи). Удаление стороны/smpl — каскад вниз.

**«+ Договор» (вариант 1 для CnExistCtptNotLoad):** создаёт новый `cn` + `cnNum`; исполнитель — если указан. В БД обязателен только **`cnnType`** (`cnNum.cnnType` NOT NULL); `cnnNum`/`cn_date` nullable (пустой номер и без даты допустимы). Отдельно от «+ smpl» к существующей стороне (вариант 2). Коллизии номера **не автоматизируем** — предупреждение оператору; решение и ответственность его.

**Фильтрация:** для СУДЗ — **вариант A** (client FemsqTable) — ~2.4k `cnNum`. Серверный filter в fequlib — позже на **`cn_inv_pm`**.

Критерии шага 1–2:

1. TopBar **«Договоры»** → экран.
2. Список `cnNum` + nested номера `cn`.
3. Дерево сторон с CRUD + **«+ Договор»** (новый cn+исполнитель).
4. GraphQL read + mutations для сторон и создания договора.

---

## 5. Связанные артефакты

| Артефакт | Путь |
|----------|------|
| Скрины | [assets/26-0815-cnNum/](./assets/26-0815-cnNum/) |
| VBA `cnNum` | `docs/project/proposals/vba-analysis/VBA-Code-Export/Form-Modules/Form_cnNum.cls` |
| Воронка / CnExistCtptNotLoad | [04-data-model §2.7](../domain/sudz/04-data-model.md#27-полный-алгоритм-btncidufload_click--цепочка-сопоставления-подтверждено-s29) |
| Организации (паттерн UI) | [02-1-3_organizations-screen.md](./02-1-3_organizations-screen.md) |
