# План: инфраструктура форм FEMSQ + экраны Стройки (`cst` / `cstAgPn`)

**Дата создания:** 2026-07-22  
**Последнее обновление:** 2026-07-28  
**Проект:** FEMSQ  
**Версия плана:** 0.5.0 (выполнен, MVP)  
**Задачи:** [0057](../../../project-development.json) (completed), [0058](../../../project-development.json) (completed)  
**Статус плана:** ✅ выполнен (MVP)  
**IA (целевое меню):** [02-4_app-forms-ia.md](../../UI/02-4_app-forms-ia.md)  
**Резюме:** [chat-resume-26-0722-forms-ia-cst.md](../chat-resume/chat-resume-26-0722-forms-ia-cst.md)

**✅ Разблокировано 2026-07-28:** задача **0063** (projectize) завершена — [docs-registry](https://github.com/bondalen/docs-registry) и [fequlib](https://github.com/bondalen/fequlib) на GitHub, с `docs/` и отдельными окнами Cursor. Задача 0058 снова `pending`. Продолжение форм cst/cstAgPn — с библиотечной версии `FemsqTable`. Задача 0062 вне этой цепочки.

*(Ранее: 2026-07-25 — цепочка 0059→0061→0060; 2026-07-28 утро — снова blocked до 0063.)*

---

## 0. Предыстория и связь с другими планами

- **Зачем сейчас:** до портирования Access-форм `cst` / `cstAgPn` в Java нужен согласованный **целевой каркас IA** (верхняя строка меню) и **общие подходы к дизайну доменных экранов**, иначе каждый новый экран будет ad-hoc (как уже намечено для Organizations / InvestmentChains / Audits / Reports).
- **Источник Access:** экспорт VBA `docs/project/proposals/vba-analysis/VBA-Code-Export/` (Form-Modules + Class-Modules + `Module1.RefreshCstChart`). Отдельных скриншотов layout нет — визуал Java **не копирует** Access пиксель-в-пиксель; ориентир — доменные данные, иерархия подформ и поведение `Form_Current` / requery.
- **Не путать:**
  - с reconcile/ревизией (`ra_a`, type=3/5/6) — другой контур;
  - с отчётами `mstrgAg_*` / `spMstrg_2606` — пункт меню **Отчёты**, не экраны строек;
  - с `ipgChMin` (расчёт освоения) — раздел **Инвестиции**, не **Стройки**.
- **Связанные артефакты:** `Form_cst.cls`, `Form_cstAgPn.cls`, `Form_cst_gt_ra_t.cls`, `cst.cls` / `cstAg.cls` / `cstAgPn.cls` / `cstCol.cls`, `Module1.bas` (`RefreshCstChart` → `ags.fnRRcList` / `fnRRcListUtil`).

---

## 1. Цель (scope текущего чата)

1. **Зафиксировать и внедрить IA верхней строки** (базовая редакция; допускается последующая корректировка): домены меню, Java-only пункты, увод `Test Grid` в **Сервис**.
2. **Сформировать общую инфраструктуру управления формами/экранами** во frontend (и при необходимости минимальный backend-контракт): навигация, реестр экранов, единые UX-паттерны списка/карточки/вложенного контекста.
3. **Реализовать экраны Стройки:** аналоги Access-форм `cst` и `cstAgPn` (данные + навигация + базовое поведение смены текущей записи; без обязательного 1:1 копирования всех вложенных RA-чартов, если они выходят за MVP — см. фазы).

**Вне scope этого чата (явно):** полный порт `cn*`/`inv*`/`CnInv*`, глубокая доработка `ipg*`/`stNet*`, миграция всех Access Report_*, скриншоты Access (желательны позже, не блокируют MVP).

---

## 2. Принятая основа IA (подлежит уточнению)

Дерево зафиксировано в [02-4_app-forms-ia.md](../../UI/02-4_app-forms-ia.md). Краткая схема:

```text
TopBar:  FEMSQ │ Организации │ Стройки │ Инвестиции │ Договоры │ Ревизии │ Отчёты │ Сервис
StatusBar: ● соединение │ сообщение │ тема │ logout
```

**Правила:** верхняя строка = домены; подключение/тема — StatusBar; Access-подформы `_gt_*` не в меню; отчёты — один пункт + каталог.  
**Темы (вариант B, 2026-07-22):** Kimbie Dark (default) + VS Light; одинаковая геометрия, разные только цвета.

---

## 3. Общие подходы к дизайну доменных экранов (инфраструктура)

Зафиксировать в коде и коротко в UI-доке (этот план + `02-4` / при необходимости `02-4-1_form-design.md`):

| Подход | Суть |
|--------|------|
| **Master–detail** | Слева список сущностей (фильтр + пагинация), справа карточка/детали выбранной записи — как Organizations / Audits. |
| **Вложенный контекст** | Дочерние сущности (агент, САК, перечень RA) — вкладки или панели внутри карточки, а не отдельные топ-пункты. |
| **Смена текущей записи** | Аналог Access `Form_Current`: при выборе строки — перезагрузка дочерних наборов (requery). |
| **GraphQL-only** | Доменные CRUD/query — только GraphQL + Apollo; REST не добавлять (правило проекта). |
| **Навигация** | Единый `ActiveView` (или эволюция в router) + TopBar; пункты с подменю — `QBtnDropdown` / `QMenu`. |
| **Enablement** | Доменные экраны доступны при `connected`; Подключение и Тема — всегда в StatusBar. |
| **Сервис/DEV** | `Test Grid` и будущие служебные экраны — только под **Сервис**. |
| **Визуал** | Quasar + Kimbie/VS Light (**вариант B**: общая геометрия); ориентир оболочки — Cursor. |
| **Неполнота Access-layout** | При отсутствии скриншотов — MVP по полям БД + поведению VBA; уточнение UI — отдельным UAT/скринами. |

**Инфраструктурный минимум:**

- Фаза **A0** — Design chrome (TopBar/StatusBar, токены геометрии).
- Фаза **A** — реестр экранов + полное дерево IA (Стройки, Инвестиции, …).
- (Опционально) `navigation.ts` / `app-screens.ts` — единый источник подписей, иконок, `requiresConnection`.

---

## 4. Домен строек — инвентаризация

### 4.1. Таблицы (dev, DBHub 2026-07-22)

| Таблица | PK | Ключевые поля |
|--------|-----|----------------|
| `ags.cst` | `cstKey` | `cstName` (NO), `cstBusSgm`, `cstMark`, … |
| `ags.cstAg` | `cstaKey` | `cstaAg` → агент, `cstaCst` → `cst`, `cstaInvestor` |
| `ags.cstAgPn` | `cstapKey` | `cstapCsta`, `cstapIpgPnN` (код САК), `cstapCstName`, `cstapCstName255`, `cstapOgName` |

Иерархия: **cst ← cstAg ← cstAgPn**.

### 4.2. Поведение Access (из VBA)

| Форма | Record / вложения | `Form_Current` |
|-------|-------------------|----------------|
| `cst` | `cstKey`; sub: `cst>ra_t`, `cst>raUtil_t`, `cst>ra_f` | `RefreshCstChart(cstKey)`; requery списков; filter `ra_f` по `ra_key` |
| `cstAgPn` | host + subform `cstAgPn>cst_f` (= форма `cst`) | chart + requery через вложенный `cst` |
| `cst>ra_t` | перечень отчётов | filter parent `cst>ra_f` по `ra_key` |
| `cstCol` | — | открыть `cst`, filter `cstName like '*…*'` |

`RefreshCstChart` переписывает pass-through QueryDef на `ags.fnRRcList(@cstKey)` / `ags.fnRRcListUtil(@cstKey)`.

### 4.3. MVP Java vs полный порт

| Возможность | MVP (0058) | Позже |
|-------------|------------|--------|
| Список/карточка `cst` | ✅ | |
| Вкладка **агенты**: дерево `cstAg`→`cstAgPn`→`cstAgPnBranch` | ✅ **CRUD** | |
| Остальные вкладки формы `cst` | stub | по скринам |
| Отдельный режим `cstAgPn` (вход по САК) | ✅ | |
| Перечень RA / util / chart (`fnRRcList*`) | ✅ список + CRUD ra/summ | chart / util / ra_change |
| Создание `cst`/`cstAg`/`cstAgPn`/Branch | ✅ в MVP | — |

**Скрины Access (2026-07-23):** [02-5_cst-form-agents-tab.md](../../UI/02-5_cst-form-agents-tab.md) — **достаточно** для MVP `cst` + «агенты».

---

## 5. Фазы работ

### Фаза A0 — Design chrome (Cursor-inspired, вариант B) ⬜

**Задача:** [0057](../../../project-development.json)  
**Решение оператора (2026-07-22):** две темы (Kimbie Dark по умолчанию + VS Light для глянцевых экранов); **одинаковая геометрия** контролов; меняются только цветовые токены. Подключение и тема — в **StatusBar**; TopBar — только навигация.

- [x] **A0.1** Документировать Design chrome в `02-4_app-forms-ia.md` (§ роли полос, геометрия, темы B).
- [x] **A0.2** Токены `--femsq-control-radius`, nav/status font-size; единый стиль `.femsq-nav-item` / status controls.
- [x] **A0.3** TopBar: убрать chip статуса, «Подключение», тему; плоские пункты доменов; Test Grid → **Сервис**.
- [x] **A0.4** StatusBar: клик по статусу → модалка подключения; индикатор без дубля TopBar; переключатель темы; logout.
- [x] **A0.5** Обновить home-подсказки в `App.vue`; smoke: `npm run type-check` OK.

**Критерий A0:** нет дубля статуса подключения в TopBar; геометрия chrome одинакова в dark/light; StatusBar — единая точка connection/theme. ✅ 2026-07-22

---

### Фаза A — IA + инфраструктура навигации/дизайна ✅/⬜

**Задача:** [0057](../../../project-development.json)

- [x] **A.1** Зафиксировать документ IA `02-4_app-forms-ia.md` (базовая редакция) + ссылка в `components.md`.
- [x] **A.2** Описать общие подходы к дизайну (§3 плана / `02-4`).
- [x] **A.3** Расширить `ActiveView` / реестр экранов: `construction-sites`; TopBar **Стройки** (заглушка view). Группа **Инвестиции** / **Договоры** — следующим шагом.
- [x] **A.4** TopBar: пункт **Стройки** поверх chrome A0 (полный набор вкладок IA — по мере реализации).
- [x] **A.5** Smoke: сборка frontend, переключение существующих экранов без регрессий. _(2026-07-28: type-check + build + Playwright nav)_

**Критерий A:** меню соответствует дереву IA; навигация к существующим экранам работает; документ IA в git. ✅ 2026-07-28

---

### Фаза B — Backend GraphQL для `cst` / дерево агентов ✅

**Задача:** [0058](../../../project-development.json) (часть B)  
**Решение оператора (2026-07-23):** CRUD сразу (не read-only).

- [x] **B.1** Модели/DAO/сервисы: `cst`, `cstAg`, `cstAgPn`, `cstAgPnBranch`, lookup `ogAgCs`.
- [x] **B.2** GraphQL `cst-schema.graphqls` + `CstGraphqlController`: списки, byKey, nested by parent, mutations CRUD; lookup `ogAgCsLookups`.
- [x] **B.3** Связь уровней: `cstAgents(cstKey)` → `cstAgPoints(cstaKey)` → `cstAgPnBranches(cstapKey)`.
- [x] **B.4** Unit/integration smoke на dev БД (после перезапуска JAR).

**Критерий B:** Apollo загружает иерархию и выполняет CRUD. _(фильтр/пагинация master — client-side в MVP)_ ✅ smoke 2026-07-23: 5064 cst; cstKey=3321 → агент «049 Газпромтранс»

---

### Фаза C — Frontend экраны Стройки ✅/⬜

**Задача:** [0058](../../../project-development.json) (часть C)

- [x] **C.1** `construction-sites-api.ts` (Apollo) + Pinia `construction-sites.ts`.
- [x] **C.2** View **Стройки**: master–detail `cst` + вкладка «агенты» L1–L3 CRUD; прочие вкладки disabled.
- [x] **C.3** Смена текущей записи перезагружает дочерние уровни.
- [x] **C.4** Заглушки прочих вкладок формы `cst`.
- [x] **C.5** Компонентные тесты (минимум: рендер списка, выбор записи). _(2026-07-28: `ConstructionSitesView.spec.ts`, 4 теста)_
- [x] **C.6** Отдельный режим входа по САК (`cstAgPn`) — список кодов + обёртка формы cst.

**Критерий C:** при подключении открывается **Стройки**, CRUD по `cst` и дереву агентов.

---

### Фаза D — Углубление (отчёты) ✅/⬜

- [x] **D.1** Порт `fnRRcList` в GraphQL + UI вкладки «отчёты» (список + CRUD `ags.ra` / `ags.ra_summ`).
- [x] **D.2** Фильтр/выбор детального RA по `ra_key` (аналог `cst>ra_f`).
- [ ] **D.3** CRUD изменений (`ags.ra_change`) — follow-up.
- [ ] **D.4** Chart / `fnRRcListUtil` — follow-up.
- [x] **D.5** Вкладка «отчёты, аренда»: список `ralpRaCst` + CRUD `ags.ralpRa` / `ags.ralpRaAu` (2026-07-24).

Скрины и заметка: [02-6_cst-form-reports-tab.md](../../UI/02-6_cst-form-reports-tab.md); аренда: [02-7_cst-form-rent-reports-tab.md](../../UI/02-7_cst-form-rent-reports-tab.md).

Если chart/util не войдёт — оформить в chat-resume как follow-up.

---

### Фаза E — Документация и закрытие ✅

- [x] **E.1** Обновить план (версии, чекбоксы), chat-resume.
- [x] **E.2** Journal + статусы задач 0057/0058.
- [x] **E.3** При появлении Vue-артефактов — записи в `modules.json`.
- [x] **E.4** UAT оператора: меню + экраны строек на dev. _(2026-07-28: GraphQL + Playwright UI smoke nb-win)_

---

## 6. Риски и открытые вопросы

| ID | Риск / вопрос | Митигация |
|----|---------------|-----------|
| R1 | Нет скриншотов Access | MVP по полям БД + VBA-поведению; UAT уточнит layout |
| R2 | `fnRRcList*` тяжёлые / вне MVP | ✅ список+CRUD ra/summ; chart/util/ra_change — later |
| R3 | Корректировка IA после внедрения | Версионировать `02-4`; не хардкодить подписи вне реестра экранов |
| R4 | Именование `ActiveView` (`sites` vs `construction-sites`) | Зафиксировать в A.3 одним решением |
| R5 | Нужен ли CRUD создания строек в MVP | ✅ **CRUD сразу** (решение 2026-07-23) |

---

## 7. Порядок выполнения (рекомендуемый)

1. Документы IA (A.1–A.2) — уже стартуют вместе с этим планом.  
2. TopBar / ActiveView (A.3–A.5).  
3. GraphQL (B).  
4. Frontend экраны (C).  
5. UAT + закрытие (E); D — по остатку времени.

---

## 8. Чеклист готовности чата

- [x] План создан (`chat-plan-26-0722-forms-ia-cst.md`)
- [x] Задачи 0057, 0058 в `project-development.json`
- [x] IA-документ `02-4_app-forms-ia.md`
- [x] Фаза A0 (Design chrome, вариант B) выполнена
- [x] Фаза A выполнена _(A.1–A.5 ✅ 2026-07-28)_
- [x] Фаза B выполнена _(B.4 smoke — после деплоя JAR)_
- [x] Фаза C выполнена _(C.5 ✅ 2026-07-28; C.6 ✅)_
- [x] Фаза E / resume _(chat-resume-26-0722-forms-ia-cst.md)_

---

**Автор плана:** Cursor AI Assistant + Александр  
**Создано:** 2026-07-22
**Закрыто:** 2026-07-28
