# КСДСФ pmt: decision-TreeList кандидата СФ

**Экземпляр:** центр колонки «Счета-фактуры» на `sudz-sf-double` при `source=pmt`  
**JSON:** [`src/trees/ksdsf-inv-decision.tree.json`](../../../../code/femsq-frontend-q/src/trees/ksdsf-inv-decision.tree.json) (черновик спеки **1.14.1**, wiring — **1.14.3**)  
**Корень данных:** `inv.iKey` = `selectedDomain[0].invKey` выбранной строки **верхнего списка** совпадений  
**Правила:** [relation-tree.md](./relation-tree.md) · [Решение 009](../../../../project/decisions/009-femsq-walk-tree.md) · план [0922 §1.14 / §2.8](../../chats/chat-plan/chat-plan-26-0922-pmt-upl-ui-complete.md)  
**Контракт:** [KSDSF_CONTEXTS](../../sql/26-0816-sudz-sf-num-collision/KSDSF_CONTEXTS.md)  
**Дата спеки:** 2026-10-05 · лист **1.14.1** · enrichment **1.14.7.1** (контрагент) / **1.14.7.5** (стройка) 2026-10-06 · **1.14.7.2–.3** (алиасы / переезды) 2026-10-09

## 0. Зачем

Цель КСДСФ — решить судьбу двоящего СФ (**link** | **create**).  
Outline [`ksdsf-inv-num`](./ksdsf-inv-num.tree.md) показывает каталог связей / СГК / долгов и **не показывает платежи** — для решения недостаточен.

Правый [`pm-doc-forest`](../../../../code/femsq-frontend-q/src/trees/pm-doc-forest.tree.json) отвечает на другой вопрос: «куда ездил **код документа** Excel-строки» (переезды КС-51 ↔ …). Его роль **не менять**.

Центр должен отвечать: «что уже висит на **этом** кандидате СФ».

## 1. Границы

| Есть | Нет (в этой спеке) |
|------|-------------------|
| Контекст **pmt** на КСДСФ | Замена outline на **dbt** (отдельное решение) |
| Профиль выбранного доменного СФ | Дублирование правого леса по белой строке |
| Платежи через `cias → cn_inv_pm` | Автосмена action советника |
| Шапка сверки с Excel (хост) | — |

**Порядок:** A (этот TreeList) → B (решение) → C (apply). Повисшие pm текущего пакета — вход для B, не «ремонт после UX».

**B @cius=1310 (1.14.5–1.14.6 ✅):** create inv **106724**; pm=59 на cias **113261**; 40729 — история. JAR **332**.

## 2. Корень и ключи

| Поле | Значение |
|------|----------|
| Таблица корня | `ags.inv` |
| PK | `iKey` |
| `root-id` хоста | `selectedDomain[0].invKey` (**не** `invNumKey`) |
| Почему не `invNum` | Платежи идут `pm → cias → cnInv.ciInv = inv.iKey`. Корень `invNum` (как сейчас) прячет путь к деньгам и путает `inKey` с legacy `inv`. |

Пилот @cius=1310: список показывает inv **40729**; деньги на cnInv **43566** (`ciInv=40729`, `ciCn=877`), cias **50319**. Корень = **40729**; в колонках pm видны `ciKey=43566`, `ciasKey=50319`.

## 3. Шапка сверки (хост, над TreeList)

Не узлы WalkTree — полоса `text-caption` / чипы над деревом. Сверка Excel-кейса (сводка + выбранная белая строка) с выбранным доменным СФ:

| Критерий | Excel | Кандидат | Исход |
|----------|-------|----------|-------|
| Номер СФ | текст Tbl / «б/н» | `inv.iNum` | да \| нет \| подозрительный |
| Договор | текст Tbl | `cn` через `cnInv` строки списка / pm | да \| нет |
| Исполнитель | БУиРГ Excel | сторона договора кандидата (`cn_s_type=2`) | да \| нет \| н/д (**1.14.7.1**) |
| Сумма | Σ сальдо кейса / строка | Σ `blns` pm кандидата (или pm текущего пакета) | да \| нет \| н/д |
| Стройка | CAC Excel (`pmtCac`) | коды `cnipCstAgPn` → `cstapIpgPnN` на pm | да \| **хвост** \| нет \| н/д (**1.14.7.5**) |
| Номер (алиасы) | текст Tbl / «б/н» | `inv.iNum` **и** все `ags.invNum.inNum` | да \| нет \| подозрительный (**1.14.7.2**) |
| Документы | — | коды на pm кандидата; переезд = тот же код на **другом** inv/cn | н/д \| **переезд** (**1.14.7.3**) |

**Стройка / хвост:** полный код Excel среди кодов кандидата → **да**; иначе `RIGHT(TRIM(code), 6)` совпал (код переходит между агентами, как **1.6.2**) → **хвост**; иначе **нет**. Нормализация та же, что `SudzPmtUplCstMatch.CODE_SUFFIX_LENGTH`.

Шапка **не** меняет action советника; только факт для оператора.

## 4. Структура TreeList (`view: list`)

```text
inv · номер · дата · note
├─ Номера           ← ags.invNum (**1.14.7.2**); hitExcel при совпадении с Excel
├─ Договоры         ← cnInv 1:N (**1.14.7.4**)
│   └─ cn · номер
│       ├─ Исполнители   cn_s_type=2 (· Excel при hit)
│       └─ Агенты        cn_s_type=1
├─ Платежи          ← главный блок (раскрыт по умолчанию)
├─ Документы        сводка + переезды других inv/cn (**1.14.7.3**)
├─ Счета ГК (cias)
└─ Задолженности    вторично (можно пустая папка / позже)
```

Правило оформления — как у остальных экземпляров: заголовок = узнаваемые ключи; деталь = расширенная карточка; `1:N` — папка, под ней строки.

### 4.1. Корень `inv` (level `inv`)

- Заголовок: `iKey`, `iNum`, `iTimeOfEntry` (или `invEntered`), краткий `ciCn`/`cn_number` из preferred cnInv если однозначен, **контрагент** (`cntrPrtNum · cntrPrtName`, **1.14.7.1**), склейка алиасов при N>1 (**1.14.7.2**).
- Деталь: `ciNote` preferred cnInv (если один), число pm / Σ сальдо, число cias.
- Preferred cnInv: при одном `cnInv` с `ciInv=iKey` — он; при нескольких — тот, что в строке списка совпадений (`domain.ciKey`), иначе не подставлять договор в заголовок.

### 4.1a. Папка «Номера» (level `invNum`, **1.14.7.2**)

Все строки `ags.invNum` с `inInv = root`. Primary = `inNum` совпадает с `inv.iNum` (или единственная).

| Колонка | Поле |
|---------|------|
| Номер | `inNum` (+ «· Excel» при hit) |
| inKey | `inKey` |
| Primary | да / пусто |
| Excel | hitExcel |

Сверка шапки: `invNumVerdict` = yes, если Excel совпал с **любым** алиасом (нормализация как раньше).

### 4.2. Папка «Платежи» (level `pm`) — главный блок

Плоский список **всех** `cn_inv_pm`, у которых `ciaCnInvAccntSmpl → ciasCnInv → ciInv = root iKey`.  
Не группировать сначала по cnInv: оператор сразу видит деньги; `ciKey` / договор — колонки строки.

| Колонка | Поле | Примечание |
|---------|------|------------|
| Платёж | `pmKey` / title | |
| Пакет | `uplName` | + `uplKey` |
| Дата пакета | `uplDate` | |
| № докум. | `docKod` | `cn_inv_doc_kod` |
| Дата док. | `docDate` | |
| Дебет | `dbt` | money |
| Кредит | `cdt` | money |
| Сальдо | `blns` | money |
| Счёт ГК | `accountNum` | |
| Стройка | `cstCode` (+ имя) | **1.14.7.5**; метки `≠стройка` / `хвост` |
| cnInv | `ciKey` | карта домена (43566) |
| Договор | `contract` | `cn_number` / имя |
| cn_inv_key | `legacyPmInv` | пуст → «через cias» |

**Подсветка (поля хоста / CSS-классы строки):**

| Флаг | Условие |
|------|---------|
| `hlCurrentUpl` | `uplKey =` текущий пакет экрана (pm=59) |
| `hlOrphanLink` | `cn_inv_key` и `cnInvKey` оба NULL (типичный InsPm) |
| `hlContractDiff` | договор строки pm ≠ договор Excel-кейса (текст) |
| `hlCstDiff` | код стройки pm ≠ Excel CAC (ни полный, ни хвост 6) |
| `hlCstSuffix` | полный код ≠ Excel, совпал хвост из 6 символов |

Сортировка: `uplDate` DESC, затем `pmKey`.

### 4.3. Папка «Документы» (level `docSum`)

Сводка **по платежам этого СФ** (не замена правого `pm-doc-forest`):

| Колонка | Поле |
|---------|------|
| № докум. | `docKod` |
| N pm | `pmCount` |
| Σ сальдо | `blnsSum` |
| Пакеты | `uplNames` (кратко) |
| Чужие inv | `otherInvCount` (**1.14.7.3**) |
| Чужие cn | `otherCnCount` |
| Переезд | `transferHint` / `hlDocTransfer` |

**Переезд:** тот же `cn_inv_doc_kod` встречается на платежах **другого** `ciInv` (и/или другого `ciCn`). Подсказка — краткий текст чужого договора/номера СФ (не полный лес). Чип шапки: `docTransferVerdict` = `transfer` \| `na`.

### 4.4. Папка «Счета ГК» (level `cias`)

`cnInvAccntSmpl` всех `cnInv` с `ciInv = root`.

| Колонка | Поле |
|---------|------|
| cias | `ciasKey` |
| cnInv | `ciKey` |
| Счёт | `accountNum` / `ciasAccnt` |
| N pm | `pmCount` |
| Σ сальдо | `blnsSum` |

### 4.5. Папка «Задолженности» (level `debt`)

Вторично. В первой поставке: папка с подписью «не для решения link/create» и 0 детей **или** тонкий reuse существующих рёбер cid (без блокировки 1.14). Не тащить весь outline `ksdsf-inv-num`.

## 5. Отличие от соседних деревьев

| Экземпляр | Вопрос | Корень |
|-----------|--------|--------|
| **ksdsf-inv-decision** (этот) | Что на кандидате СФ? | `inv.iKey` |
| **pm-doc-forest** (справа) | Куда ездил код документа Excel? | `cn_inv_doc` / фильтр kod |
| **ksdsf-inv-num** (outline) | Каталог связей/СГК/долгов | `invNum.inKey` |
| **contracts-inv** | Карточка СФ на договоре | `inv.iKey` |

SQL-путь платежей родственен `findPmDocForestByInv` (`ci.ciInv = ?`), но **форма** — list от inv, не лес от документа. Правый лес не заменять и не вкладывать в центр.

## 6. API (**1.14.2** ✅)

GraphQL `sudzSfDecisionProfile(invKey, currentUplKey?, excelCnText?, excelInvNum?, excelCntrPrtNum?, excelBlnsSum?, excelCac?)` → один профиль:

- корень inv + preferred cnInv (если однозначен) + агрегаты;
- `payments` / `docSums` / `cias` / `debts` (debts stub пустой);
- `compare` (yes|no|suspicious|na|**suffix**|**transfer**) и флаги строк `hlCurrentUpl` / `hlOrphanLink` / `hlContractDiff` / `hlCstDiff` / `hlCstSuffix` / `hlDocTransfer`.
- `invNums` — алиасы (**1.14.7.2**); на платеже: `cstKey` / `cstCode` / `cstName` из `cnipCstAgPn`.
- на `docSums`: `otherInvCount` / `otherCnCount` / `transferHint` / `hlDocTransfer` (**1.14.7.3**).

Путь данных: `cn_inv_pm → cias → cnInv.ciInv = invKey`.  
Клиент: `getSudzSfDecisionProfile` в `sudz-api.ts`.  
queryId JSON (`sudz.ksdsf.decision.*`) мапятся на хосте в **1.14.3** из этого профиля (без отдельных round-trip, если хост кэширует профиль).

Не использовать outline-каталог cid/dv как источник «есть ли платежи».

## 7. UI wiring (**1.14.3** ✅)

- При `source=pmt`: центр = `SfDecisionTree` (`ksdsf-inv-decision`, `root-id = invKey`) + шапка сверки из профиля.
- Outline `ksdsf-inv-num` — кнопка «Техн. каталог» (не основной центр).
- При `source=dbt`: `ksdsf-inv-num` без изменений.
- Правый `PmDocForest` + сплиттер белых строк — без смены роли.
- JAR **0.1.0.330-SNAPSHOT**.

## 8. Приёмка спеки / smoke (**1.14.4**) ✅ 2026-10-05

На @cius=1310, выбран inv **40729** (JAR **330**, Vite `:5175`):

1. ✅ Центр «Платежи»: pm=59 «этот пакет» Σ −10 427 623,46 (+ нули) на `cias=50319` / `ciKey=43566`.
2. ✅ Исторические pm 2023–24 на том же cias.
3. ✅ Шапка сверки: номер подбор / договор да / сумма да; inv 40729 · cnInv 43566 · пакет 59.
4. ✅ Правый лес по `5400224218`: под pm 319308 → СФ `12-05/07-31` · **КС-51** (не регресс).

## 9. Вне scope листа 1.14.1

Реализация GraphQL/UI, решение create|link, apply, смена советника, dbt-центр.
