# План: экран «Договоры» — вкладка «Счета-фактуры» (T7)

**Дата создания:** 2026-08-26  
**Последнее обновление:** 2026-08-27  
**Проект:** FEMSQ  
**Версия плана:** 0.4.0 (P1 ✅: GraphQL `cnInvsByCn` page + индекс `IX_cnInv_ciCn`)  
**Задача:** [0071](../../../project-development.json) (дерево **02.03.07**) · срез **T7** (S68t)  
**Статус плана:** 🔄 этапы 1–2 ✅; **P1 ✅**; next — **P2** (`mode=server` на вкладке СФ) / P2a; CRUD после P2  
**Журнал:** [chat-2026-08-26-001](../../../../journal/project-journal.json)  
**Карта домена СУДЗ:** [chat-plan-26-0802-sudz.md](./chat-plan-26-0802-sudz.md) · S62 / S64–S65 / S68t / S73  
**UI Access:** [02-10_contracts-cnNum-access.md](../../UI/02-10_contracts-cnNum-access.md)  
**Дерево:** [contracts-inv.tree.md](../../UI/02-12_femsq-tree/contracts-inv.tree.md) · [relation-tree.md](../../UI/02-12_femsq-tree/relation-tree.md) · ADR [009](../../../../project/decisions/009-femsq-walk-tree.md)  
**IA:** [02-4_app-forms-ia.md](../../UI/02-4_app-forms-ia.md)  
**Код экрана:** `ContractsView.vue` · JSON [`contracts-inv.tree.json`](../../../../code/femsq-frontend-q/src/trees/contracts-inv.tree.json)

---

## 0. Зачем

Оператор на экране «Договоры» должен видеть **счета-фактуры, связанные с выбранным договором** (`cnInv` → `inv`), раскрывать связи/стороны/долги через тот же `RelationTree`, что уже живёт на КСДСФ, и при необходимости создавать/править/удалять связь `cnInv` через `RecordModal`.

Это **второй потребитель** walker (срез 4 / **T7** в S68t). Инфраструктура (T0–T6, T4b, T6a/T6b) уже есть; вкладка «Стороны» (S64/S65) **не переписывается**.

Не смешивать с:

- воронкой долгов **0069** / экраном C;
- КСДСФ / `sudz-sf-double` (другой корень: `invNum`);
- массовой перепривязкой СФ;
- выносом walker в feQuLib (**T9**).

---

## 1. Цель этого чата (T7)

На вкладке **«Счета-фактуры»** экрана `ContractsView`:

1. **Слева** — перечень связей `cnInv` выбранного договора (`ciCn` = `cn_key`).
2. **Справа** — `RelationTree` + JSON **`contracts-inv`**, корень **`inv` / `iKey`** = `ciInv` выбранной слева строки.
3. CRUD связи `cnInv` — через уже существующую `RecordModal` / form `cnInv.link` (как на КСДСФ и в текущем interim на `cn-picker`).
4. Смена выбранного `cnInv` → пересборка дерева (тот же контракт, что смена строки списка на КСДСФ).

**Вне scope этого чата:**

- вкладка «Стороны» / «+ Договор» / nested `cnNum` (уже сделаны; не трогать без явной нужды);
- серверный filter FemsqTable для `cnNum` (отложен на `cn_inv_pm`);
- T8 / T9 / правки `FemsqTree` в fequlib без дыры контракта;
- PM / PrDoc / полный Access-стек Accnt как отдельный UI;
- общий JSON / `$ref` между КСДСФ и Договорами (запрещено 02-12 §6).

---

## 2. As-is → to-be

### 2.1. Уже есть (не переделывать с нуля)

| Артефакт | Состояние |
|----------|-----------|
| Master `cnNum` + detail `cn` + вкладка «Стороны» | ✅ S64 / S65 |
| `RelationTree` + inject fetch (T4b) | ✅ |
| JSON `contracts-inv` version 1 (корень `inv`) | ✅ T1 |
| Actions + `RecordModal` для `cnInv.link` | ✅ T6a / T6b |
| Вкладка «Счета-фактуры» в UI | 🔄 **чтение T7** (список + `contracts-inv`); CRUD связи — этап 3 |

### 2.2. Interim (снят с вкладки, 2026-08-26)

Ранее вкладка SF монтировала дерево от **`cn`** по **`cn-picker.tree.json`**. С этапами 1–2 основное дерево — **`contracts-inv`**. `cn-picker` остаётся для picker’ов в `RecordModal` (этап 3).

---

### 2.3. Целевая раскладка (утверждена в S68t / 02-12)

```text
┌─ Договоры ── master cnNum ── detail cn ─────────────────────┐
│ [ Стороны ]  [ Счета-фактуры ]                              │
│ ┌─ nested cnNum ──────────────────────────────────────────┐ │
│ ├─ SF:                                                    │ │
│ │  ┌─ cnInv договора ──┐  ┌─ RelationTree (contracts-inv)┐ │ │
│ │  │ ciKey · ciInv · … │  │ корень inv = ciInv выбранной │ │ │
│ │  │ (FemsqTable)      │  │ строки слева                 │ │ │
│ │  └───────────────────┘  └──────────────────────────────┘ │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

| Зона | Решение |
|------|---------|
| Список слева | связи `cnInv` **этого** `cn`, не весь `inv` базы |
| Дерево справа | только `contracts-inv`; корень `inv`/`iKey` |
| Пустой выбор | нет выбранного `cnInv` → дерево не монтировать / заглушка |
| Actions CRUD | на папке/записи связи; хост открывает ту же `RecordModal` |
| Вкладка «Стороны» | без переписывания |

---

## 3. Порядок работ

| # | Этап | Содержание | Статус |
|---|------|------------|--------|
| **0** | Документы | Этот план; указатели из 0802 / 0071 / 02-10 / 02-12 | ✅ 2026-08-26 |
| **1** | Данные списка | `fetchCnInvsByCn` ← `relationExpand('cn.cnInv')` + enrich `iNum` (≤80); store `cnInvs` / `selectedCnInv` | ✅ 2026-08-26 · **client-path**, держать до P2 |
| **2** | UI раскладка | Вкладка SF: слева FemsqTable `cnInv`, справа `RelationTree` + `contracts-inv`, `root-id` = `ciInv`; lazy load по вкладке | ✅ 2026-08-26 |
| **2b** | Server page (§7) | GraphQL page + `mode=server`; снять полную выгрузку; без ломки остальных гридов | 🔄 P1 ✅; P2 ☐ |
| **3** | Actions на JSON | Перенести/добавить `cnInv.link.*` / кнопка «+ связь» + `RecordModal` | ☐ после **2b** |
| **4** | Убрать interim | SF не на `cn-picker`; дочистить мёртвый CRUD-host после этапа 3 | ☐ частично |
| **5** | UAT | `cn=2265` + договор с большим `cnInv` (напр. 419/877); CRUD; смена строки → дерево | ☐ |
| **6** | Резюме | `chat-resume-26-0826-contracts-inv.md` при паузе / закрытии | ☐ |

**Правило исполнения:** после каждого этапа обновлять колонку «Статус» здесь и (при значимом шаге) журнал + `lastUpdated` / версию плана. Не отмечать ✅ без проверки в коде/UAT.

---

## 4. Критерии приёмки T7

- [x] На вкладке «Счета-фактуры» слева виден список `cnInv` выбранного договора.
- [x] Справа дерево строится из **`contracts-inv.tree.json`**, корень = `inv` выбранной связи.
- [x] Смена строки слева пересобирает дерево; та же строка — нет лишней пересборки.
- [ ] Create / edit / delete `cnInv` работают через `RecordModal` (паритет с КСДСФ).
- [ ] Вкладка «Стороны» и master `cnNum` без регрессии.
- [x] Walker по-прежнему без импорта Apollo/SQL; хост передаёт `fetchNode` / `fetchExpand`.
- [ ] UAT владельца: экран пригоден для разбора связей договор↔СФ (в т.ч. в контексте воронки / коллизий).

---

## 5. Сегменты / журнал исполнения

| # | Дата | Тема | Куда уложено | Статус |
|---|------|------|--------------|--------|
| S0 | 2026-08-26 | План чата T7 зафиксирован; as-is = interim `cn-picker` | этот файл; указатели 0802 / 0071 | ✅ |
| S1 | 2026-08-26 | Этапы 1–2: список `cnInv` + `RelationTree(contracts-inv)` чтение; lazy по вкладке; enrich `iNum` ≤80 | `contracts-api` / store / `ContractsView` | ✅ |
| S2 | 2026-08-26 | План §7 server page + обмен; **§7.1:** канон = `feQuLib/docs/agent-exchange-inbox` (шара WSL ненадёжна) | этот файл §7 | ✅ док |
| S3 | 2026-08-26 | **P1:** `cnInvsByCn` GraphQL page + `IX_cnInv_ciCn` на DEV; §7.5 | `DefaultCnInvService`; `cn-schema`; sql `26-0826-cninv-cicn-index` | ✅ |

---

## 6. Связанные артефакты

| Артефакт | Путь |
|----------|------|
| Эталон Access cnNum / СФ | [02-10](../../UI/02-10_contracts-cnNum-access.md); [assets/26-0815-cnNum](../../UI/assets/26-0815-cnNum/README.md) |
| Конспект дерева | [contracts-inv.tree.md](../../UI/02-12_femsq-tree/contracts-inv.tree.md) |
| S68t T0–T9 | [chat-plan-26-0802-sudz.md](./chat-plan-26-0802-sudz.md) § S68t |
| Решение walker | [009-femsq-walk-tree.md](../../../../project/decisions/009-femsq-walk-tree.md) |
| feQuLib / FemsqTable | [Решение 008](../../../../project/decisions/008-fequlib-and-docs-registry.md); feQuLib `docs/components/FemsqTable.md`; roadmap **0008**/G |
| Обмен агентов | **канон на nb-win (WSL):** `/home/alex/projects/feQuLib/docs/agent-exchange-inbox/`; шара `agent-exchange/femsq-fequlib` — опциональное зеркало (агент feQuLib шару из WSL часто не читает) |

---

## 7. Server page списка `cnInv` + взаимодействие с feQuLib

**Зачем:** хвост договоров (до ~73k `cnInv`) ломает client-path этапов 1–2. Каркас `mode='server'` / `@request` в feQuLib **уже есть**; дыра — page API в FEMSQ. Полная задача «разработать server-side в lib с нуля» **не** ставится.

**Принцип сохранения функционала:** additive-first на обеих сторонах; client-path и все остальные гриды FEMSQ работают до явного cutover вкладки СФ; `git pull` feQuLib только после ответа обмена и smoke; не копировать код lib в FEMSQ.

### 7.1. Канал обмена с агентом feQuLib (nb-win / WSL)

**Канон для агента feQuLib на nb-win:** каталог в клоне lib  
`/home/alex/projects/feQuLib/docs/agent-exchange-inbox/`.

Причина: агент в окне feQuLib (WSL) **часто не может надёжно читать** шару WireGuard (`D:\wire-guard-share-nb-win\agent-exchange\femsq-fequlib` / `/mnt/d/…` / `/mnt/nb-win-share/…`). На практике fill-layout и tree-обмен уже шли через **inbox в репозитории** (запрос + ответ лежат там же); шара в шапке файла — лишь «контекст», не обязательный путь чтения.

| Шаг | Кто | Куда | Имя файла |
|-----|-----|------|-----------|
| 1 | FEMSQ | **обязательно** `feQuLib/docs/agent-exchange-inbox/` | `YYYY-MM-DD_HHMM_femsq_to_fequlib_<тема>.md` |
| 2 | FEMSQ | опционально зеркало на шару (если доступна с хоста) | тот же файл; **не** считать доставкой для агента feQuLib |
| 3 | feQuLib | ответ **в тот же inbox** | `YYYY-MM-DD_HHMM_fequlib_to_femsq_<тема>.md` («На запрос: …») |
| 4 | FEMSQ | читает ответ из inbox (путь соседнего клона); после `commit`+`push` lib | `./code/scripts/check-fequlib.sh` → `git pull` в `/home/alex/projects/feQuLib` → smoke |
| 5 | Оба | планы/журнал | ссылка на файл **inbox**, не только на шару; SHA в ответе lib |

Образец запроса: `…/feQuLib/docs/agent-exchange-inbox/2026-08-24_1315_femsq_to_fequlib_fill-layout-…`.  
Образец ответа: `…/2026-08-24_1320_fequlib_to_femsq_fill-layout-response.md`.

В шапке exchange-файла указывать:  
`Канон чтения (nb-win WSL): /home/alex/projects/feQuLib/docs/agent-exchange-inbox/`  
и при желании `Зеркало (опц.): D:\wire-guard-share-nb-win\agent-exchange\femsq-fequlib`.

**В запросе G обязательно:** (a) контракт `@request` уже есть — нужен cookbook/`rowsNumber`/счётчик, не новый режим; (b) additive-first, default client не ломать; (c) критерий «уведомить FEMSQ» + SHA; (d) не смешивать с 0011 visual / wide Rslt; (e) ответ класть в **inbox**, не полагаться на шару.

**Окна Cursor:** код lib — окно **feQuLib** (читает/пишет inbox); GraphQL/store/`ContractsView` — окно **FEMSQ**. Не патчить `FemsqTable` внутри FEMSQ.

### 7.2. Фазы работ (рекомендуемый порядок)

| ID | Где | Содержание | Сохранение текущего | Статус |
|----|-----|-------------|---------------------|--------|
| **P0** | FEMSQ док | Этот §7; при старте кода — S-сегмент; опционально строка в 0802 | только доки | ✅ 2026-08-26 |
| **P1** | FEMSQ backend | Query page `cnInvsByCn` → `{ items, totalCount }`; индекс `ciCn`; решения §7.5 | новый API рядом со старым; этапы 1–2 **не трогать** | ✅ 2026-08-26 |
| **P2** | FEMSQ frontend | Вкладка СФ: флаг/`mode='server'` + `@request` → P1; `pagination.rowsNumber = totalCount`; **cutover** только списка СФ; убрать полную выгрузку `fetchCnInvsByCn` с вкладки | остальные экраны client; master `cnNum` client; дерево `contracts-inv` без изменений; rollback = вернуть client-path | ☐ |
| **P2a** | FEMSQ предохранитель | До/вместе с P2: если остаётся client — `COUNT` и отказ/баннер при `cnt > порог` (напр. 200), не грузить 73k | не ломает малые договоры | ☐ |
| **P3** | Exchange → feQuLib | Запрос G polish **в** `feQuLib/docs/agent-exchange-inbox/`; cookbook server + `rowsNumber` + «N из M»; **не** E/F; **не** блокер P1–P2 | lib без ответа не блокирует page API; шара не обязательна | ☐ после или параллельно P1 |
| **P4** | feQuLib | Реализация G polish; ответ **в inbox** + SHA; registry: вынести G из 0008 или medium | additive; списки без `mode=server` без регрессии | ☐ окно feQuLib |
| **P5** | FEMSQ sync | `check-fequlib.sh` / `git pull`; подключить polish если есть; smoke: СФ + стройки/cst без `fill`/`server` | не принимать lib без smoke | ☐ |
| **P6** | FEMSQ | Этапы **3–4** плана (CRUD `cnInv`) уже на page-списке | CRUD не на 73k client | ☐ |
| **P7** | FEMSQ later | Тот же page-паттерн на `cn_inv_pm` (S64) | отдельный срез | ☐ не в T7 |

### 7.3. Критерии приёмки §7 (до CRUD)

- [ ] Договор с тысячами `cnInv` открывает вкладку СФ без выгрузки всех строк в браузер.
- [ ] Пагинация / фильтр / сортировка списка идут через page API (или явно задокументированный subset).
- [ ] `cn=2265` и типичные договоры (≤100) работают не хуже этапов 1–2.
- [ ] Master `cnNum`, «Стороны», КСДСФ, стройки — без регрессии.
- [ ] feQuLib: либо P4+P5 закрыты, либо зафиксирован «контракта хватило, exchange не требовался».
- [ ] Client-path полной выгрузки с вкладки СФ удалён или за флагом rollback, не как default.

### 7.4. Что не делать

- Не ставить feQuLib задачу «изобрести server-side mode».
- Не ждать 0011 / 0015 / wide Rslt для P1–P2.
- Не копировать `FemsqTable` в FEMSQ при рассинхроне клона.
- Не считать доставкой для агента feQuLib (nb-win WSL) только запись на шару WireGuard — **обязателен** файл в `feQuLib/docs/agent-exchange-inbox/`.
- Не включать `mode=server` на всех гридах сразу.
- Не начинать этап 3 CRUD на client-path для «тяжёлых» договоров без P2a/P2.

### 7.5. Решения P1 (зафиксировано 2026-08-26)

| Тема | Решение |
|------|---------|
| Пагинация | **page с 1** (как Quasar / `@request`); `offset = (page - 1) * rowsPerPage` |
| Default | `rowsPerPage = 25`; clamp `rowsPerPage` в 1…200; `page < 1` → 1 |
| sortBy whitelist | `ciKey`, `ciInv`, `iNum`, `ciTimeOfEntry`; иное → `ciKey` |
| descending | `Boolean`, default `false` → `ASC` |
| filter v1 | подстрока по `inv.iNum` (case-insensitive `LIKE`); если filter — целое число, также OR по `ciInv` / `ciKey` |
| Индекс | `NONCLUSTERED IX_cnInv_ciCn ON ags.cnInv (ciCn) INCLUDE (ciInv, ciTimeOfEntry)` — в P1 на DEV + пакет `docs/development/notes/sql/26-0826-cninv-cicn-index/` |
| API | GraphQL `cnInvsByCn(...)` рядом с существующими; client-path `relationExpand` не удалять в P1 |
| iNum | поле в элементе списка через `LEFT JOIN ags.inv` |

---

**Автор плана:** Cursor AI Assistant + Александр  
**Создано:** 2026-08-26
