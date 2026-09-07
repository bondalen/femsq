# План: аналог «системы управления дебиторской задолженностью» (СУДЗ) из MS Access

**Дата создания:** 2026-08-02  
**Последнее обновление:** 2026-09-07  
**Проект:** FEMSQ  
**Версия плана:** 0.99.21 (S76-C.10 UI gate-UAT 901(X)→902→Rslt QI)
**Задача:** 0065–0072 (дерево features **02.03**); эскизы [02-9](../../UI/02-9_sudz-mvp-screens.md); **активно: 0069** — **S76-C.10** UI gate-UAT; **S74 M5**; **0071** 🔶; **S69**/**S70** ✅
**Статус плана:** ✅ 0070; **S75** stage1 ✅; **S76** 🔄 (**X найден** → C.10 UI 901→902→Rslt); **S74 M1–M4** ✅; **M5 C1** ✅; next **S76-C.10**; **0071** 🔶
**Cutover prod/DEV:** [db-upgrade-sudz-invdbt-cutover.md](../../../../deployment/db-upgrade-sudz-invdbt-cutover.md) · §5.6 [S74](#s74--трек-cutover-m1m6--2026-08-27) · D1: [04-5](../../domain/sudz/04-5_dbt-invdbt-cardinality-d1.md)
**Паспорт pmt:** [02-11_cn-inv-pmt-upl-access.md](../../UI/02-11_cn-inv-pmt-upl-access.md) · §5.7  
**План UI pmt:** [chat-plan-26-0819-cn-inv-pmt-upl.md](./chat-plan-26-0819-cn-inv-pmt-upl.md) · §5.8  
**План UI Договоры / СФ (T7):** [chat-plan-26-0826-contracts-inv.md](./chat-plan-26-0826-contracts-inv.md) · 0071  
**Резюме UI pmt (S70):** [chat-resume-26-0819-cn-inv-pmt-upl.md](../chat-resume/chat-resume-26-0819-cn-inv-pmt-upl.md)  
**Резюме pmt (S69):** [chat-resume-26-0817-cn-inv-pmt-upl.md](../chat-resume/chat-resume-26-0817-cn-inv-pmt-upl.md)


**Доменные доки:** [01-overview](../../domain/sudz/01-overview.md) · [02-glossary](../../domain/sudz/02-glossary.md) · [03-processes](../../domain/sudz/03-processes.md) · [04-data-model](../../domain/sudz/04-data-model.md) · [04-1 MS_Description](../../domain/sudz/04-1_ms-descriptions.md) · [04-3 проблемы](../../domain/sudz/04-3_problems-solutions.md) · [04-4 зерно/счёт долгов](../../domain/sudz/04-4_legacy-debt-grain.md) · [04-5 D1 кардинальность Dbt↔invDbt](../../domain/sudz/04-5_dbt-invdbt-cardinality-d1.md) · [04-6 multi-Dbt P1 три пути](../../domain/sudz/04-6_multi-dbt-p1-three-paths.md) · [07-readiness (покрытие/готовность)](../../domain/sudz/07-readiness.md) · [08-target-schema (физ. схема + ER)](../../domain/sudz/08-target-schema.md)  
**UI-эскизы:** [02-9_sudz-mvp-screens.md](../../UI/02-9_sudz-mvp-screens.md)  
**Дерево:** [02-12 relation-tree](../../UI/02-12_femsq-tree/relation-tree.md) · [КСДСФ](../../UI/02-12_femsq-tree/ksdsf-inv-num.tree.md) · [Договоры/СФ](../../UI/02-12_femsq-tree/contracts-inv.tree.md) · ADR [009](../../../../project/decisions/009-femsq-walk-tree.md)  
**IA (целевое меню):** [02-4_app-forms-ia.md](../../UI/02-4_app-forms-ia.md)  
**Метод съёма Access:** [MS-ACCESS-OBJECTS-CAPTURE.md](../../../../project/proposals/vba-analysis/MS-ACCESS-OBJECTS-CAPTURE.md)

---

## 0. Зачем и откуда

В MS Access существует рабочая **система управления дебиторской задолженностью** (далее — **СУДЗ**): набор форм, запросов, таблиц (локальных и связанных с `ags` / FishEye) и сценариев работы с долгами по договорам/счетам/агентам.

В FEMSQ уже есть смежные артефакты (импорт долгов, таблицы `cn_inv_dbt*`, `invDbt*`, формы Access `CnInvDbtUpl*`), но **единой доменной картины СУДЗ нет**: нет согласованного описания процессов, границ с «Договорами» / «Инвестициями» / ревизиями, целевой IA и модели данных Java.

**Цель этого чата — прежде всего документация и сбор знаний**, а не полноценная реализация. Код UI и структуры данных — только в объёме, достаточном для проверки понимания (эскизы, черновики схем, точечные прототипы).

**Режим работы:** пользователь передаёт сведения **сегментами** (формы, таблицы, скрины, VBA, сценарии, термины). Ассистент **укладывает** каждый сегмент в общую систему документов и обновляет этот план (инвентарь, открытые вопросы, связи).

---

## 1. Цель (scope текущего чата)

1. **Собрать и систематизировать** информацию о СУДЗ в Access (объекты, процессы, роли, данные, отчёты).
2. **Разработать проектную документацию** домена в FEMSQ: границы, глоссарий, процессы, модель данных, IA/экраны, связь с уже существующими таблицами `ags`.
3. **Набросать** (без обязательства полного MVP):
   - целевое место СУДЗ в TopBar / IA;
   - эскиз ключевых экранов (master–detail, вкладки);
   - черновик структур данных (таблицы FishEye + возможные локальные/staging сущности).
4. **Сформировать backlog** реализации (отдельные задачи/чаты) — после того, как документация стабилизируется.

**Вне scope этого чата (явно):**

- полный порт всех Access-форм СУДЗ в Java;
- reconcile/ревизии `ra_a` (кроме явных точек соприкосновения с долгами);
- массовая миграция исторических `importDbt_*` / локальных Excel-буферов без описания процесса;
- пиксель-в-пиксель копирование UI Access.

---

## 2. Принципы укладки сегментов

| Принцип | Суть |
|--------|------|
| **Один сегмент → одно место в системе** | Новый материал сразу попадает в соответствующий раздел целевой доки + строку инвентаря §5; не остаётся только в чате. |
| **Сначала смысл, потом имена** | Термин бизнес-процесса важнее имени Access-объекта; имена Access/SQL фиксируются рядом как aliases. |
| **Не путать контуры** | СУДЗ ≠ ревизия (`ra_a`); СУДЗ ≠ учёт строек (`cst`); пересечения (договор, счёт, агент) описываются явно как связи. |
| **Access — источник поведения** | VBA/формы/запросы — эталон сценариев; UI Java — по IA FEMSQ (Quasar, master–detail), не 1:1 Access. |
| **FishEye уже есть** | Новые таблицы — только если в `ags` нет подходящей сущности; сначала инвентаризация существующих `*dbt*`, `*Dbt*`, `cia*`. |
| **GraphQL-only** | Любой будущий доменный API — через GraphQL; в этом чате достаточно контрактных набросков в доке. |
| **Открытые вопросы — явно** | Незакрытые пункты в §7; не выдумывать доменные правила без подтверждения. |

---

## 3. Фазы

| Фаза | Название | Содержание | Статус |
|------|----------|------------|--------|
| **A** | Приём сегментов | Сбор от пользователя: формы, таблицы, запросы, скрины, сценарии, термины; фиксация в инвентаре §5 | 🔄 текущая |
| **B** | Каркас документации | Создать целевые документы домена (см. §4); глоссарий; границы с другими доменами | 🔄 начат (01–03) |
| **C** | Модель данных | Карта сущностей Access ↔ `ags`; ER/связи; gaps; черновик DDL только при необходимости | 🔄 начат (04) |
| **D** | IA и UI-эскиз | Место в TopBar; список экранов; wireframe/описание 1–2 ключевых экранов | ☐ |
| **E** | Backlog реализации | Задачи в `project-development.json` / registry; критерии MVP; что отложить | ☐ |

**Порядок:** A идёт непрерывно; B стартует после первых 2–3 содержательных сегментов; C–D — по мере накопления; E — когда документация «достаточно полна» (критерий §6).

---

## 4. Целевые артефакты документации

Пути — ориентир; точные имена можно уточнить после первых сегментов.

| # | Артефакт | Путь | Статус |
|---|----------|------|--------|
| 1 | **Обзор домена СУДЗ** | [01-overview.md](../../domain/sudz/01-overview.md) | 🔄 черновик |
| 2 | **Глоссарий** | [02-glossary.md](../../domain/sudz/02-glossary.md) | 🔄 черновик |
| 3 | **Процессы / сценарии** | [03-processes.md](../../domain/sudz/03-processes.md) | 🔄 P1 + дерево 1–1.2.3 (S3) |
| 4 | **Модель данных** | [04-data-model.md](../../domain/sudz/04-data-model.md) | 🔄 S4–S6 |
| 4a | **MS_Description (ER-сегмент)** | [04-1_ms-descriptions.md](../../domain/sudz/04-1_ms-descriptions.md) | ✅ S6 |
| 4b | **Пример Rslt 82/85** | [04-2_example-rslt-82-85.md](../../domain/sudz/04-2_example-rslt-82-85.md) | ✅ S7 |
| 4c | **Реестр проблем и решений** | [04-3_problems-solutions.md](../../domain/sudz/04-3_problems-solutions.md) | ✅ S10 |
| 5 | **IA и экраны** | `docs/development/notes/domain/sudz/05-ia-screens.md` + правка [02-4](../../UI/02-4_app-forms-ia.md) | 🔄 имя/место в TopBar решены (S27, в [02-4](../../UI/02-4_app-forms-ia.md)); эскиз экранов — не начат |
| 6 | **Инвентарь Access** | `docs/development/notes/domain/sudz/06-access-inventory.md` | ☐ |
| 7 | **Связь с VBA/запросами** | ссылки в `docs/project/proposals/vba-analysis/` по [MS-ACCESS-OBJECTS-CAPTURE](../../../../project/proposals/vba-analysis/MS-ACCESS-OBJECTS-CAPTURE.md) | по мере съёма |
| 8 | **Резюме чата** | `docs/development/notes/chats/chat-resume/chat-resume-26-0802-sudz.md` | в конце / при паузе |
| 9 | **Реестр покрытия / готовности к разработке** | [07-readiness.md](../../domain/sudz/07-readiness.md) | ✅ S24 |

Инвентарь сегментов и Excel — в этом плане (§5); смысл процесса — в `domain/sudz/`.

---

## 5. Инвентарь (наполняется по сегментам)

### 5.1. Уже известные зацепки в FEMSQ / FishEye (до сегментов)

| Источник | Что есть | Заметка |
|----------|----------|---------|
| VBA summary | таблицы долгов `24-*_debt_*`, поля `ciaKey`, `curr`, `cmm`, `cst` | [VBA-ANALYSIS-SUMMARY](../../../../project/proposals/vba-analysis/VBA-ANALYSIS-SUMMARY.md) |
| Access Form-Modules | `Form_CnInvDbtUpl*`, связанные subforms | загрузка долгов по договорам/счетам |
| `ags` (dev, 2026-08-02) | `cn_inv_dbt`, `cn_inv_dbt_double`, `cn_inv_dbt_upl*`, `invDbt`, `invDbtValue`, `invDbtTmpCiaRel`, `dtqInvoiceDbt`, `dtqCounterparty`, серия `importDbt_*` | доменные + импортные/исторические |
| IA TopBar | Организации / Стройки / Инвестиции / Договоры / Ревизии / Отчёты / Сервис | отдельного пункта «Долги / СУДЗ» пока нет |

### 5.2. Сегменты от пользователя

| # | Дата | Тема сегмента | Куда уложено | Статус |
|---|------|---------------|--------------|--------|
| S1 | 2026-08-02 | Папки `debit/` на SMB-шаре (Excel-источники ДЗ) | §5.5; классификация файлов | ✅ |
| S2 | 2026-08-03 | Квартальный процесс: свод → портфель начала года → исходящие сведения | [03-processes P1](../../domain/sudz/03-processes.md); [01-overview](../../domain/sudz/01-overview.md); §5.4 | ✅ |
| S3 | 2026-08-03 | Дерево работ 1–1.2.3 (Access↔FishEye, Rslt, export→cst) | [03-processes дерево](../../domain/sudz/03-processes.md); глоссарий; §5.4–5.5 | ✅ |
| S4 | 2026-08-03 | ER-сегмент СУДЗ + оговорки о качестве модели; старт документации структуры | [04-data-model](../../domain/sudz/04-data-model.md); assets ER | ✅ |
| S5 | 2026-08-03 | Главная проблема: задолженность ≠ inv/cn; нужна отдельная сущность + match | [04 §1.1](../../domain/sudz/04-data-model.md); глоссарий; overview | ✅ |
| S6 | 2026-08-03 | MS_Description таблиц/полей сегмента ER | [04-1_ms-descriptions](../../domain/sudz/04-1_ms-descriptions.md) | ✅ |
| S7 | 2026-08-03 | Роли cnInvAccnt/cn_inv_dbt; пример Rslt 82 vs 85 + 4 строки сводов; match = сумма+договор+дата | [04-2](../../domain/sudz/04-2_example-rslt-82-85.md) | ✅ |
| S8 | 2026-08-03 | Судьба долгов 82/85 в Rslt за 2025 год | [04-2 §2025](../../domain/sudz/04-2_example-rslt-82-85.md) | ✅ |
| S9 | 2026-08-03 | Свод 30.06.2026; осцилляция СФ А19↔90 для долга 85 | [04-2 §30.06](../../domain/sudz/04-2_example-rslt-82-85.md) | ✅ |
| S10 | 2026-08-03 | Реестр P1–P4; проверка 7/5 долгов А19; хронология invDbt; похожие importDbt/invBranch | [04-3](../../domain/sudz/04-3_problems-solutions.md) | ✅ |
| S11 | 2026-08-03 | P1 уточнён (суд↔СФ); `90`=1 долг; P5 переименование; P3 поглощён | [04-3 P1/P5](../../domain/sudz/04-3_problems-solutions.md) | ✅ |
| S12 | 2026-08-03 | Узел cn_s/org/Smpl/Accnt; P6/P7; целевой порядок PartyOrg→Debt (A/B/C) | [04-3 §5](../../domain/sudz/04-3_problems-solutions.md) | ✅ |
| S13 | 2026-08-03 | P8 (объём Smpl, отложено); целевая модель `Dbt`↔`DocBasis` M:N (закрывает P1+P2+P5+P6); карта миграции; шаги match | [04-3 §6](../../domain/sudz/04-3_problems-solutions.md#6-целевая-модель-судз-dbt--docbasis-многие-ко-многим-предложение-s13) | ✅ |
| S14–S19 | 2026-08-03 | Эскиз владельца `Dbt`/`invDbtDbt`/`DbtValue`; триггер; `UNIQUE(inv,dbt)`; миграция без `doc_base` | [04-3 §7](../../domain/sudz/04-3_problems-solutions.md) | ✅ |
| S20 | 2026-08-05 | Образцы итогового и сводного документов; история Access SQL (`*D644*`) | [03 §1.2](../../domain/sudz/03-processes.md); глоссарий; §5.5 | ✅ |
| S21 | 2026-08-05 | Соответствие запросов `23-0421_sql.docx` ↔ Excel Rslt / D644 на шаре | [03 §1.2.5](../../domain/sudz/03-processes.md); §5.3 | ✅ |
| S22 | 2026-08-05 | Маппинг полей SQL → колонки 4 Excel; что добавлено сверх запросов | [03 §1.2.6](../../domain/sudz/03-processes.md) | ✅ |
| S23 | 2026-08-05 | FEMSQ может собрать Rslt/D644 при корректных данных; `cur_new`/`mery_new`/`cstAgPn_new` = сбор 1.1.2–1.1.3 | [03 дерево S3 + §1.3](../../domain/sudz/03-processes.md); глоссарий «Мероприятие» | ✅ |
| S24 | 2026-08-06 | Проверка блокеров S19: роль стороны не помогает (все карточки — «исполнитель»), помогает org карточки → 12 220 переносимы; `cnNum`/`invNum` требуют исторических Excel; **решение — приоритет живому процессу S3 на Q4’25–Q2’26, история отложена**; заведён реестр покрытия/готовности | [04-3 §7.4.2](../../domain/sudz/04-3_problems-solutions.md); [03 «Приоритет реализации»](../../domain/sudz/03-processes.md); [07-readiness](../../domain/sudz/07-readiness.md) | ✅ |
| S25 | 2026-08-06 | Подтверждена по БД структура хранения мероприятий: `cnInvCmm*`+`Gr`+`Tp` (иерархия специалист-подгруппы→общая, численно 192+16=208), `yr`/`yr_upl_p` (выбор актуальной группы года); В11 закрыт; найдены М14 (не найден базовый SQL `ags_Yr_DbtChanges`) и М15 (dev-БД отстаёт от Excel на ~3 квартала) | [04-data-model §2.6](../../domain/sudz/04-data-model.md); [03-processes §1.1.3](../../domain/sudz/03-processes.md); глоссарий «Мероприятие»; [07-readiness](../../domain/sudz/07-readiness.md) | ✅ |
| S26 | 2026-08-06 | Скрин свойств Access-запроса → `ags_Yr_DbtChanges` = хранимая процедура SQL Server (не QueryDef), снята и разобрана через DBHub (`ags.Yr_DbtChanges(@yr)`, функция `ags.fnCiasDbtUplCst`, тип `ags.tempDbtYr`); подтверждено 1:1 совпадение динамических колонок с Rslt (S22); найдено правило неоднозначности стройки (`'строек: N'`); М14/В20 закрыт. Владелец уточнил причину отставания dev-БД — отсутствие бэкапов, без изменения методики в проде; М15/В21 закрыт. Область D реестра закрыта полностью | [04-data-model §2.6](../../domain/sudz/04-data-model.md#механизм-agsyr_dbtchanges-найден-и-разобран-s26); [03-processes §1.1.3](../../domain/sudz/03-processes.md); глоссарий `ags_Yr_DbtChangesRslt`; [07-readiness](../../domain/sudz/07-readiness.md) | ✅ |
| S27 | 2026-08-06 | Владелец решил G1/G2 (домен `sudz`/«СУДЗ» — верхний пункт TopBar, голова возможной группы) и I1 (без ролей/прав на MVP — доступно всем); скрины главной/вложенной формы `CnInvDbtUpl_2`/`CnInvDbtUpl>File_f` + начало VBA `btnCidufLoad_Click` — форма-«ядро» шага 1.1.1.1 (загрузка свода через COM Excel в буфер `CnInvDbtUplTbl`). Осталась одна блокирующая MVP-позиция — C6 | [01-overview §4](../../domain/sudz/01-overview.md#4-идентичность-в-femsq-имя-topbar-роли--решено-s27); [02-4_app-forms-ia.md](../../UI/02-4_app-forms-ia.md); [03-processes §1.1.1.1](../../domain/sudz/03-processes.md); [04-data-model](../../domain/sudz/04-data-model.md); [07-readiness](../../domain/sudz/07-readiness.md) | ✅ |
| S28 | 2026-08-06 | По просьбе «изучить `btnCidufLoad_Click()` в имеющейся в проекте информации» проверено `vba-analysis/`: полного модуля `Form_CnInvDbtUpl>File_f` в репозитории нет; найден родственный экспортированный `Form_CnInvPmtUpl>File_f>InvDouble>invNum>cnInv` — раскрывает паттерн вложенной подформы `InvDouble` для ручного разбора повторов СФ; по аналогии — вероятный UI над `cn_inv_dbt_double` для долговой ветки (M9 обогащён). Новых фактов о самом алгоритме match не найдено; MVP-блокеры не изменились | [03-processes §1.1.1.1](../../domain/sudz/03-processes.md); [04-data-model §2.2/§7](../../domain/sudz/04-data-model.md) | ✅ |
| S29 | 2026-08-06 | Пользователь предоставил полный экспорт `Form_CnInvDbtUpl>File_f` (1996 строк) — весь алгоритм `btnCidufLoad_Click()` разобран: воронка из 10 подпроцедур сопоставления/вставки, точная формула match (`CiaNm.SumMatch`, ключ `inv+ciaName+сумма`), подтверждённая подформа `InvDouble` для долгов (факт, не гипотеза), коды `cn_s_type=2`=исполнитель/`cnnType=1`. Побочно: весь `VBA-Code-Export` (120 файлов) был в CP1251, перекодирован в UTF-8. М1 и М9 закрыты | [04-data-model §2.7](../../domain/sudz/04-data-model.md#27-полный-алгоритм-btncidufload_click--цепочка-сопоставления-подтверждено-s29); [04-3 P2](../../domain/sudz/04-3_problems-solutions.md); [03-processes §1.1.1.1](../../domain/sudz/03-processes.md) | ✅ |
| S30 | 2026-08-06 | **C6 разобран и закрыт полностью, по одному вопросу:** (1) физ. имена — camelCase как на эскизе; (2) `UNIQUE(cn_key, cn_s_type)` на `cn_s` — закреплён как жёсткий constraint (перед решением проверены фактами через DBHub `ags.cn_s`/`cn_s_org_smpl`/`cn_s_org` + `openpyxl` по 3 «Общим сводам»: смена стороны «во времени» есть, но последовательная — 104 роли; «один долг — две стороны в одной выгрузке» не встречается; гипотеза «`Dbt`=прото-долг/`DbtTrue`=канон» уже реализована эскизом зеркально по именам — новая сущность не нужна); (3) `invDbt` — та же таблица, новые строки при каждой загрузке; (4) порог исторической реконструкции — не нужен, закрыт решением S24. **Область C реестра готовности закрыта — блокирующих MVP-позиций больше нет, домен готов к Фазе E** | [04-3 §7.7–7.8](../../domain/sudz/04-3_problems-solutions.md#78-проверка-смена-стороны-договора-во-времени-и-гипотеза-dbt--прото-долг-dbttrue--каноничный-долг-s30); [07-readiness §11](../../domain/sudz/07-readiness.md#11-вывод-о-готовности-к-переходу-к-разработке) | ✅ |
| S31–S32 | 2026-08-06/07 | Уточнение по массовым договорам кратко переоткрыло `UNIQUE(cn_key, cn_s_type)` (S31: показалось, что 80 исполнителей = 80 строк `cn_s`); владелец уточнил (S32) — роль одна, организаций под ней много (`cn_s_org_smpl` 1:N от `cn_s`, уже в схеме), противоречия с constraint нет, **решение S30 подтверждено без изменений**. Прислан и разобран второй эскиз владельца (замена S16) — вводит `invDbtVar`/`invDbtDbtVar` («снимок контекста долга»: `cnNum`/`invNum`/`cn_s_org`/`accnt` переезжают с `DbtValue` на `invDbtVar`; диагностика по нетипичному счёту ГК; помогает разбору массовых договоров). Владелец решил: `DbtValue` сужается до величины; нужен обязательный защитный триггер против «чужих» реквизитов на `invDbtVar`; сущности **включены в объём MVP**. Верхнее ядро идентичности (P1/P2/C6) не изменилось | [04-3 §7.8–7.9](../../domain/sudz/04-3_problems-solutions.md#79-второй-эскиз-владельца--invdbtvar--invdbtdbtvar-вариант-именования-долга-s32); assets `26-0807-sudz-target-sketch-dbtvar.png`; [07-readiness](../../domain/sudz/07-readiness.md) | ✅ |
| S33 | 2026-08-07 | Владелец: `ciaName` — уходящий костыль P2 (причина появления `invDbt`), **не** прообраз `invDbtVar` — из целевой схемы исключён. Выбран формат физ. спецификации: новый `08-target-schema.md` + **редактируемая Mermaid ER** в том же файле (правим параллельно). Черновик v0.1: таблицы `Dbt`/`invDbtDbt`/`invDbtVar`/`invDbtDbtVar`/`DbtValue`, оживление `invDbt`, триггеры; обнаружено что `UNIQUE(cn_key, cn_s_type)` уже есть в БД (`cn_cnSType`) | [08-target-schema](../../domain/sudz/08-target-schema.md); [04-3 §7.9/S33](../../domain/sudz/04-3_problems-solutions.md) | 🔄 |
| S34 | 2026-08-07 | Песочница: схема **`test_sudz`** создана на DEV; все проектируемые таблицы и тестовые данные — там; FK на живые `ags.*` без изменения их DDL; SQL-пакет `26-0807-sudz-test-schema` | [08-target-schema](../../domain/sudz/08-target-schema.md); [sql/26-0807-sudz-test-schema](../../sql/26-0807-sudz-test-schema/) | ✅ |
| S35–S39 | 2026-08-07 | Ядро `Dbt`…`DbtValue` + триггеры; sandbox-upl 901–903; seed долгов 82/85 за IV.25–II.26 | [08-target-schema](../../domain/sudz/08-target-schema.md); sql `01`–`09` | ✅ |
| S40 | 2026-08-07 | Зеркала `cnInvCmm*`/`cnInvGr`/`yr`/`yr_upl_p` с FK на `Dbt`; условные группы IV.25–II.26; `yr` 2026 (база 901, `yr_CmmGr`→903); seed комментариев 82/85 + пример «углубленно в сентябре» | [08 §3.4](../../domain/sudz/08-target-schema.md); sql `10`–`11` | ✅ |
| S41 | 2026-08-07 | Мини-витрина Rslt: `vw_Yr_DbtFact` + `vw_Yr_DbtChanges_mini_2026` + `Yr_DbtChanges_mini(@yr)`; JOIN комментариев по `dbtKey` | [08 §3.5](../../domain/sudz/08-target-schema.md); sql `12` | ✅ |
| S42 | 2026-08-07 | Gaps; S42a–b контракт; склейка СГК; **S42c** `DbtUplCstAg`+Cst/Ag; **S42d** погашено; **S42e** кураторы | [08 §3.6](../../domain/sudz/08-target-schema.md#36-сверка-мини-rslt--excel-долги-8285--s42); sql `13`–`15` | ✅ |
| S43 | 2026-08-07 | Date-major порядок колонок; обёртка `test_sudz.Yr_DbtChanges`; ядро Rslt-контракта на песочнице | [08 §3.6.5](../../domain/sudz/08-target-schema.md); sql `16` | ✅ |
| S45 | 2026-08-07 | Регрессия на `ags_Yr_DbtChangesRslt_26-0212` (5 `upl_date`); seed `yr=900`; паритет 82/85 (стр. 129/134); `NULLIF` для погашено | [08 §3.6.6](../../domain/sudz/08-target-schema.md#366-регрессия-s45--ags_yr_dbtchangesrslt_26-0212-5-срезов); sql `17` | ✅ |
| S44 | 2026-08-07 | D644: агент из `cstAgPn` по «Код стройки»; doc = base `invNumEnum`; полные mery; `Yr_DbtChangesD644`; smoke 82/85 ↔ D644_26-05 | [08 §3.6.4](../../domain/sudz/08-target-schema.md); sql `18`–`19` | ✅ |
| S46 | 2026-08-07 | Регрессия D644 @900 ↔ D644_26-03; `Yr_DbtChangesD644Svod` (форма свода; числа — subset 82/85) | [08 §3.6.7](../../domain/sudz/08-target-schema.md); sql `20`–`21` | ✅ |
| S47 | 2026-08-07 | Приёмка витрины; эскизы экранов A/B; backlog 0065–0070 (дерево 02.03) | [02-9](../../UI/02-9_sudz-mvp-screens.md); tasks 0065–0070 | ✅ |
| S48 | 2026-08-07 | Cutover DEV: схема **`sudz`**; пакет target-schema; smoke 82/85; 0066 ✅ | [08 §3.6.9](../../domain/sudz/08-target-schema.md); sql `26-0807-sudz-target-schema` | ✅ |
| S48a | 2026-08-07 | Прод: объекты СУДЗ в **`ags`** (не отдельная схема); DEV остаётся `sudz` | [08](../../domain/sudz/08-target-schema.md); `MSSQL2012/README` | ✅ |
| S49 | 2026-08-07 | GraphQL read: `sudzYears` / `sudzYrDbtChanges` / `sudzD644` / `sudzD644Svod`; Apollo `sudz-api`; smoke IT 82/85; 0067 ✅ | `sudz-schema.graphqls`; `SudzGraphqlController`; `src/api/sudz-api.ts` | ✅ |
| S50 | 2026-08-07 | UI Портфель (экран A): FemsqTable+detail; mutation `updateSudzDebtCollection`; TopBar «СУДЗ»; UAT mery→D644; 0068 ✅ | `SudzPortfolioView.vue`; store `sudz-portfolio` | ✅ |
| S51 | 2026-08-07 | Пересмотр: «Портфель года» = форма **`yr`** (CRUD, upl/pm); бывший Rslt → «Долги / мероприятия»; схема `femsq.sudz.schema`; зеркала `cn_inv_pm_upl`/`g_p` | [02-9 §1a](../../UI/02-9_sudz-mvp-screens.md); sql `22_…_S51` | ✅ |
| S52 | 2026-08-08 | Progress-лаунчер документов; Rslt сбор/повтор; срез `asOfUpl`/`curr_upl`; scope 0070 | [02-9 §1a Progress](../../UI/02-9_sudz-mvp-screens.md); [03 §1.1.2](../../domain/sudz/03-processes.md) | ✅ |
| S52a | 2026-08-08 | **`yr_CmmGr_New`**; только Rslt повтор использует New+CmmGr; внесение в 1.1.2.2; веха **1.1.3**; S25 убран из 03 → 04 | [03](../../domain/sudz/03-processes.md); [08](../../domain/sudz/08-target-schema.md); 0070 | ✅ |
| S53 | 2026-08-08 | Rslt сбор: `asOfUpl` в GraphQL; Excel REST; лаунчер Progress (прототип+Excel) | [02-9](../../UI/02-9_sudz-mvp-screens.md); JAR 0.1.0.158 | ✅ |
| S54 | 2026-08-08 | Excel Rslt v2 (шапка row1–3 как эталон); `appendSudzYearProgress` + запись при Excel/прототипе; **полный путь папки выгрузки отложен**; прототип UI «как Excel» — после приёмки формата | [08 §S54](../../domain/sudz/08-target-schema.md); JAR 0.1.0.159 | ✅ |
| S55 | 2026-08-08 | Excel Rslt v3: заливки/шрифты/границы/фильтр/freeze/SUBTOTAL по эталону `…26-0212…`; имя файла с датой-временем | [08 §S55](../../domain/sudz/08-target-schema.md); JAR 0.1.0.162 | ✅ |
| S56 | 2026-08-08 | UAT: Excel Rslt **принят**; подпись `idNum` → «№ задолженности в СФ»; точечные правки — по мере замечаний | [08 §S56](../../domain/sudz/08-target-schema.md) | ✅ |
| S57 | 2026-08-08 | Rslt повтор: `yr_CmmGr_New`+гр.904; возвраты Excel 82/85; REST/UI повтор; итоговый `…povtor_S57.xlsx` | [08 §S57](../../domain/sudz/08-target-schema.md); JAR 0.1.0.164 | ✅ |
| S58 | 2026-08-08 | Progress: комбо **Операция** (док+действие), **Выполнить**, New+файл на загрузке | [02-9 Progress](../../UI/02-9_sudz-mvp-screens.md) | ✅ |
| S59 | 2026-08-09 | D644 / Свод · Выгрузить: Excel REST + Progress | [08 §S59](../../domain/sudz/08-target-schema.md); [02-9](../../UI/02-9_sudz-mvp-screens.md) | ✅ |
| S59b | 2026-08-09 | Приёмка владельцем среза D644/Свод (UAT «приемлемо»; высота R по комментарию) | [08 §S59](../../domain/sudz/08-target-schema.md); [02-9 §5](../../UI/02-9_sudz-mvp-screens.md) | ✅ |
| S59c | 2026-08-09 | Свод: переключатели Предпросмотр/Excel + native preview | [02-9](../../UI/02-9_sudz-mvp-screens.md); `sudz-svod-preview.ts` | ✅ |
| S60 | 2026-08-09 | Веха 1.1.3 = прекращение правок (без New→CmmGr); путь папки отложен; **0070 ✅** | [03 §1.1.3](../../domain/sudz/03-processes.md); [02-9 §5](../../UI/02-9_sudz-mvp-screens.md) | ✅ |
| S61 | 2026-08-11 | **0069:** старт — эскиз лаунчера; затем воронка; не смешивать с 1.1.1.2 | [§5.6](#56-0069-загрузка-общего-свода--порядок-s61--s61c) | ✅ |
| S61c | 2026-08-11 | **0069:** UI после staging на SQL | [§5.6](#56-0069-загрузка-общего-свода--порядок-s61--s61c) | ✅ этап1–5: TableDef+DDL `sudz`+seed File/Sh |
| S61d | 2026-08-13 | **0069 / 1.1.1.2 prep:** `CnInvPmtUpl*` → `sudz` (File/Tbl/TblCnInv; без Tbl_1); seed File=30 | [26_/27_](../../sql/26-0812-sudz-dbt-upl-staging/); [съём](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/) | ✅ |
| S61e | 2026-08-13 | **0069 этап 6:** экран C «Загрузка свода» — GraphQL лаунчер + UI; «загрузка» stub | [02-9 §4a](../../UI/02-9_sudz-mvp-screens.md); `SudzDbtUplView` | ✅ |
| S61f | 2026-08-13 | **0069 этап 7 (метод):** панель шагов воронки с чекбоксами (Access: раскомментирование Sub); код не начат | [§5.6 этап 7](#56-0069-загрузка-общего-свода--порядок-s61--s61c); [02-9 §4a](../../UI/02-9_sudz-mvp-screens.md); [04 §2.7](../../domain/sudz/04-data-model.md#27-полный-алгоритм-btncidufload_click--цепочка-сопоставления-подтверждено-s29) | 🔶 док |
| S61g | 2026-08-13 | **0069:** UI панель шагов + stub-оркестратор `runSudzDbtUplFunnel` | `SudzDbtUplView`; GraphQL mutation | ✅ |
| S61h | 2026-08-13 | **0069:** шаг `excelToTbl` — REST staging + POI → `CnInvDbtUplTbl` (UAT: 1764 строк, файл 31.12.2025) | `SudzDbtUplExcelToTblImporter`; `/api/v1/sudz/dbt-upl/excel` | ✅ |
| S61i | 2026-08-14 | **0069:** путь Excel = `cidufPath` как в Проводнике; скрепка/REST staging сняты; Java читает из БД (`D:\`→`/mnt/d/`) | `SudzDbtUplExcelPathResolver`; `SudzDbtUplView` | ✅ |
| S61j | 2026-08-14 | **0069:** UAT excelToTbl 1764 ок; лог прогона заменяет старый; чекбокс excelToTbl снят (остался «обнов. по исх?»); пути Проводника — канон проекта | `SudzDbtUplFunnelRunner`; `development.file_paths` | ✅ |
| S61k | 2026-08-14 | **0069:** шаг `orgNotInBuirg` — лог новых орг. без type=1; без записи в домен; `cidufFlLoad` не влияет | `JdbcSudzDao.findDbtUplOrgNotInBuirg`; `SudzDbtUplOrgNotInBuirgLog` | ✅ |
| S61l | 2026-08-14 | **0069:** шаг `CnNotLoad` — лог новых договоров; SQL-цепочка `ciduCnNotLoad`…; `*Null` как Access calculated; без `flLoad` | `findDbtUplCnNotLoad`; `SudzDbtUplCnNotLoadLog`; `access-queries/cidu*.access.sql` | ✅ |
| S61l+ | 2026-08-14 | **0069:** `CnNotLoad` apply при `flLoad` + откат по `cnMark` (`strMark`); транзакция INSERT | `applyDbtUplCnNotLoad`; `rollbackSudzCnNotLoad` | ✅ |
| S61m | 2026-08-14 | **0069:** целые NUMERIC Excel → plain digits (не `2.11E+11`); откат 8142118 + excelToTbl + apply → **cnMark 8142135** | `AuditExcelCellReader`; UAT upl **910** | ✅ |
| S61n | 2026-08-14 | **0069:** `CnExistCtptNotLoad` только лог; SQL = `ciduCnExistCtptNot` (номер есть, пара №+дата+исполнитель нет); `flLoad` не влияет | `findDbtUplCnExistCtptNotLoad`; `ciduCnExistCtptNot.access.sql` | ✅ |
| S62 | 2026-08-15 | **Блокер воронки:** эталон Access **`cnNum`** (стороны + пакет 2: СФ/`cnInv`/`AccntSmpl`); UI **0071** не начат | [02-10](../../UI/02-10_contracts-cnNum-access.md); [assets/26-0815-cnNum](../../UI/assets/26-0815-cnNum/README.md) | 🔶 док |
| S62c | 2026-08-15 | Пакеты 3–4: Accnt/dbt, lookups (`ciNumCs`, `cnnType`, `accnt`, `cn_s_orgCs`, upl), PM (`cn_inv_pm_dbt_upl`), PrDoc/PrDocP; явная связка **Access≠целевой dbtvar**; runtime PrDoc пуст (ошибка Access) | [02-10](../../UI/02-10_contracts-cnNum-access.md); assets `41`–`74` | 🔶 док |
| S63 | 2026-08-15 | Ошибка эскиза dbtvar: pm→`cn_s_org_smpl` без СГК. **Решение владельца: вариант 1** (pm/PrDoc → `cnInvAccntSmpl`; не трогать живое; без моста Dbt↔Smpl; освоение лимитов — после СУДЗ) | [04-3 §9](../../domain/sudz/04-3_problems-solutions.md); assets `26-0815-sudz-target-sketch-pm-accnt-fix.png` | ✅ |
| S64 | 2026-08-15 | **0071 шаг 1:** master `cnNum` + detail `cn`/nested `cnNum`; FemsqTable **client** (быстрый путь СУДЗ); server-side filter — позже на **`cn_inv_pm`** | [02-10](../../UI/02-10_contracts-cnNum-access.md); GraphQL `cn-schema` | ✅ |
| S65 | 2026-08-15 | **0071 шаг 2:** стороны `cn_s`→smpl→org, полный CRUD (паттерн агентов cst); `cnSides` + mutations; JAR **0.1.0.187** | `ContractPartiesPanel`; [02-10](../../UI/02-10_contracts-cnNum-access.md) | 🔶 UAT |
| S65b | 2026-08-15 | UAT 910 БУРГЕОКОМ: org есть, smpl нет; Excel/Tbl `Б/Н` без даты; UI даты ДД.ММ.ГГГГ | `flexible-date.ts` | ✅ |
| S65c | 2026-08-15 | «+ Договор»: обязателен только `cnnType`; номер/дата/исполнитель опциональны; коллизии — на операторе | `createCnContract`; JAR **0.1.0.191** | 🔶 UAT |
| S65d | 2026-08-15 | Create: дата → только `csoCnDate`, `cn_date`=NULL; UI правка `cn_date` (`updateCn`) | JAR **0.1.0.192** | 🔶 UAT |
| S65e | 2026-08-15 | `clearInvDouble` убран из чекбоксов; prelude внутри `CnCtptExistInvNotLoad` (как Access вызов перед Sub) | реестр FE+BE | ✅ |
| S66 | 2026-08-15 | **0069:** `CnCtptExistInvNotLoad` — clear InvDouble + буфер TblCnInv + лог; apply inv/invNum/cnInv при flLoad | JAR **0.1.0.194**; **UAT apply 910: 693** (2026-08-24 14:34) | ✅ |
| S66a | 2026-08-24 | **0069:** `CnCtptInvExistAccSmplNotLoad` — эталон `cidu-sql` (anti-join БУиРГ; Ins без даты) | UAT 910: **705** (первый apply); хвост Access-Not=0 | ✅ |
| S66b | 2026-08-24 | Дамп `cidu*` (36 QueryDef); сверка org/CnNot/ExistCtpt/InvNot vs Access на 910: Δ=0. Код предшествующих шагов **не менять**. `ciduCnExistCtptNot.access.sql` = живой SQL | [`cidu-sql/`](../../../../project/proposals/vba-analysis/26-0811_CtInvDbtUpl_/cidu-sql/) | ✅ |
| S66c | 2026-08-24 | **Шов воронки:** AccSmpl — последний 1:1 с Access. Владелец: **сразу целевая воронка**. Next: черновик stepId | [§5.6 S66c](#s66c--шов-после-accsmpl-старая-vs-новая-воронка-2026-08-24) | ✅ |
| S66d | 2026-08-24 | Черновик целевых stepId A–E — **отложен**: владелец меняет подход | [§5.6 S66d](#s66d--черновик-целевых-stepid-после-accsmpl-2026-08-24) | ⏸ |
| S66e | 2026-08-24 | **Порядок `invDbt`** сегм. **1–21** (15 уточнён 21); код v1 ensure/load + очередь; stub экрана; Access-хвост disabled | [§5.6 S66e](#s66e--порядок-определения-invdbt-сегментами-2026-08-24); [sql/26-0824](../../sql/26-0824-sudz-inv-dbt-double/) | 🔶 экран/Value |
| S71 | 2026-08-25 | **M2:** `DbtValue` без `dvDbt`; якорь `invDbt` + var + upl; `Dbt` обязателен, связь через `invDbtDbt`; DDL в БД пока старый — backlog | [04-3 §10](../../domain/sudz/04-3_problems-solutions.md#10-dbtvalue-без-прямого-fk-на-dbt-m2--s71); [08 §2.5](../../domain/sudz/08-target-schema.md) | ✅ док |
| S72 | 2026-08-25…26 | Дорожная карта; **B1/B1b/A2** ✅; порядок C пересмотрен **S74** | [§5.6 S72](#s72--дорожная-карта-реализации-слоя-i--m2--канон-2026-08-25) | 🔄 |
| S73-grain | 2026-08-26 | Зерно legacy `(iKey,ciaName)≈idNum`; счёт **11906–11907** | [04-4](../../domain/sudz/04-4_legacy-debt-grain.md) | ✅ |
| S74 | 2026-08-27 | Трек cutover **M1–M6** (Dbt→DEV seed→calm→экран/7→чекбоксы→prod) | [§5.6 S74](#s74--трек-cutover-m1m6--2026-08-27); [cutover](../../../../deployment/db-upgrade-sudz-invdbt-cutover.md) | 🔄 M5 (M1–M4 ✅) |
| S75 | 2026-08-31 | **Rslt stage1** база–QI–QII: PIT `09`, L*, row1+погашено+выборка; E1′ в cutover; gate `verify-rslt-stage1.sh` | [26-0831](../../sql/26-0831-sudz-dbt-slot-link/); [E1′](../../../../deployment/db-upgrade-sudz-invdbt-cutover.md#e1--паритет-исторических-rslt-pit-2026-08-31) | ✅ |
| S76 | 2026-09-01…07 | **Rslt stage2 / QIV (variant B):** реестр Δ; **X найден** (НОВЫЙ 31.12.2025); **S76-C.10** UI gate-UAT 901(X)→902→Rslt QI | [§5.6 S76](#s76--rslt-stage2-qiv-дельта-воронка-901-vs-access-variant-b-2026-09-01); [stage2_qiv_delta_registry.md](../../sql/26-0831-sudz-dbt-slot-link/stage2_qiv_delta_registry.md) | 🔄 C.10 |
| S73 | 2026-08-26 | **0071 T7:** отдельный план вкладки «Счета-фактуры» (слева `cnInv`, справа `contracts-inv`); interim = `cn-picker` | [chat-plan-26-0826-contracts-inv.md](./chat-plan-26-0826-contracts-inv.md) | 🔄 план |
| S67 | 2026-08-16 | UAT 910 dry: **128** дог. / **705** СФ ✅, но rebuild **~3m14s** (CTE). Перепись на `#temp`+индексы; лог СФ усечён (8+…) | JAR **0.1.0.196** | ✅ via S67a |
| S67a | 2026-08-16 | `#temp` без COLLATE → conflict Latin1 vs Cyrillic на JOIN `cnnNumNull`. Колонки `#cidu*` → `Cyrillic_General_CI_AS` | JAR **0.1.0.197** | ✅ UAT: sqlMs=241, 128/705 |
| S68 | 2026-08-16 | **КСДСФ:** `CnInvUplSfDouble` на DEV; наполнение 1:1 Excel; bulk без очереди; экран + create/link | JAR **0.1.0.198**; [DDL](../../../sql/26-0816-sudz-sf-num-collision/); **S68u** UAT 910 | ✅ |
| S68t | 2026-08-18 | **Walker ≠ FemsqTree:** JSON + каталог + обёртка. T1–T5 ✅; T6 принят через разбор очереди 910 (якорь 832930 больше не в open) | [02-12](../../UI/02-12_femsq-tree/relation-tree.md); ADR [009](../../../../project/decisions/009-femsq-walk-tree.md); §5.6 S68t | ✅ T6; T6a/T6b/T7 — далее |
| S69 | 2026-08-17 | **1.1.1.2 / паспорт `CnInvPmtUpl*`:** съём Access закрыт. Шаг 8 (`TwoLoad`) — только показ; запись/перепривязка двоящих СФ — вручную оператором. Runtime InvDouble: **0 строк**. INSERT финала: `ags_cn_inv_pm`. Java pmt — не этот чат | [02-11](../../UI/02-11_cn-inv-pmt-upl-access.md); [03 §1.1.1.2](../../domain/sudz/03-processes.md); §5.7; [съём](../../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/) | ✅ |
| S70 | 2026-08-19 | **Экран D «Загрузка платежей»:** задача **0072** visual v1 ✅, UAT владельца ✅. Вкладка `g_p` на экране свода ≠ этот лаунчер | [chat-plan-26-0819](./chat-plan-26-0819-cn-inv-pmt-upl.md); [resume 26-0819](../chat-resume/chat-resume-26-0819-cn-inv-pmt-upl.md); [02-9 §4b](../../UI/02-9_sudz-mvp-screens.md#4b-экран-d--загрузка-платежей-cn_inv_pm_upl--лаунчер-file_f); §5.8 | ✅ visual |
| S68h | 2026-08-24 | **КСДСФ подсказки:** полоса под колонкой «СФ»; исполнитель Excel (`cn_s_type=2`) по БУиРГ **или** ИНН; клик `inKey`/`cidKey`/`dvKey` | GraphQL `sudzSfDoubleHints`; [02-9](../../UI/02-9_sudz-mvp-screens.md) | ✅ |
| S68v | 2026-08-24 | **fill-layout:** `FemsqTable fill` / `FemsqTree fill` на КСДСФ; снята `.relation-tree-scroll` | feQuLib inbox `2026-08-24_1320_*` | ✅ UAT скролл |
| S68u | 2026-08-24 | **UAT КСДСФ upl 910:** оператор создал часть СФ и часть привязал; двоящих № не осталось. DEV: `CnInvUplSfDouble`=0; `TblCnInv`=693, все `inNumCount` NULL (было InvDouble=12 / СФ=705) | §5.6 S68u | ✅ |

### 5.3. Объекты Access (формы / запросы / таблицы / отчёты)

| Тип | Имя Access | Назначение (кратко) | Связь с `ags` / FEMSQ | Док / файл |
|-----|------------|---------------------|----------------------|------------|
| Query (семейство) | `ags_Yr_DbtChangesRslt_*` | Выгрузка для специалистов (мероприятия) | `ags_Yr_DbtChanges` → Excel Rslt | `debit/23-0421_sql.docx` |
| Query (семейство) | `ags_Yr_DbtChangesRsltD644_*` | Итоговый документ (приложение к письму 644) | сохранённый Rslt + `ags_cstAgPn` + `ags_cn_inv_dbt` | тот же docx; образцы Приложений |
| *(пары)* | см. таблицу S21 | каждый D644 читает конкретный Rslt (`… AS r`) | соответствие имён и файлов на шаре | [03 §1.2.5](../../domain/sudz/03-processes.md) |
| Form | `CnInvDbtUpl_2` | Главная форма загрузки общего свода (список выгрузок) | ↔ `cn_inv_dbt_upl` | [04-data-model §2.7](../../domain/sudz/04-data-model.md#27-полный-алгоритм-btncidufload_click--цепочка-сопоставления-подтверждено-s29) |
| Form | `cnNum` (+ `cn`, `cn>s`, `cn>s>orgSmpl`, `cn>s>org`) | Карточка/навигация договоров: номер → cn → стороны → org | `ags.cnNum` / `cn` / `cn_s` / `cn_s_org_smpl` / `cn_s_org` | [02-10](../../UI/02-10_contracts-cnNum-access.md); [скрины](../../UI/assets/26-0815-cnNum/README.md) |
| Form | `CnInvDbtUpl>File_f>InvDouble` (+ `InvDouble_f`, `cns`) | Ручной разбор неоднозначных СФ/договоров; кнопка `btnInvAdd_Click` создаёт СФ+связь вручную | подтверждено как факт (S29) | там же |
| Form | `CnInvPmtUpl>File_f` / `…>InvDouble` (+ `invNum`→`cnInv`) | Платежи 1.1.1.2: `btnUpload`; вкладки ход / повторы СФ / стройки новые / прочее; RS File = `CnInvPmtUplFile`; InvDouble = `TblCnInv` WHERE count NOT NULL; `btnInvCreate` = inv+cnInv | нет FileSh / FileInvDouble; лист = `cipufSheet` | [02-11](../../UI/02-11_cn-inv-pmt-upl-access.md); S68/S69; VBA `btnUpload_Click` |

### 5.4. Сценарии бизнеса

| ID | Сценарий | Актёры | Вход | Выход | Приоритет MVP |
|----|----------|--------|------|-------|---------------|
| P1 | Квартальная подготовка исходящих документов (итоговый ± сводный за год) | оператор СУДЗ (Access) / специалисты по долгам / согласующие разделов / получатель итога | общий свод + `export_{счётГК}` | итоговый документ (`*D644*`); после Q4 — ещё сводный по счетам | высокий (ядро) |

**Суть P1 (S2+S3+S20+S23):** работа **ежеквартальная**. Объект года Y — только долги, просроченные на **31.12.(Y−1)**. Через Access в FishEye.ags грузятся свод и `export_*`; выгружается `ags_Yr_DbtChangesRslt` (в т.ч. колонки `cur_new` / `mery_new` / `cstAgPn_new` для сбора на 1.1.2–1.1.3); затем Access-запросами `*D644*` готовится **итоговый документ** (счета 606012/762210/767502); по итогам Q4 дополнительно — **итоговый сводный** по счетам ГК. В FEMSQ те же Excel **воспроизводимы** при корректной витрине с бэкенда ([03 §1.3](../../domain/sudz/03-processes.md)). Новая просрочка внутри года Y **не** ведётся. Свод на 31.12.Y задаёт портфель на год Y+1.

Дерево шагов 1 / 1.1 / 1.2 — в [03-processes.md](../../domain/sudz/03-processes.md).

**Решение по порядку работ (S24):** приоритет — реализация P1/дерева S3 на доступных Excel **Q4’2025–Q2’2026** (`2025-12`/`2026_03`/`2026-06`: есть начало годового портфеля + два квартала). Историческая миграция (ретро-`cnNum`/`invNum`, ~473 неоднозначных карточки) **отложена** — не решается текущими данными `ags`, нужны архивные Excel-своды 2023–2025, которых на шаре нет. См. [04-3 §7.4.2](../../domain/sudz/04-3_problems-solutions.md) и [03 «Приоритет реализации»](../../domain/sudz/03-processes.md).

### 5.5. Excel на шаре: `femsq/excel/*/debit/` (сегмент S1)

**Путь (nb-win):** `/mnt/d/wire-guard-share-nb-win/femsq/excel/{период}/debit/`  
**Конвенция БД/Fedora:** `/mnt/nb-win-share/femsq/excel/...` (на 2026-08-02 bind `/mnt/nb-win-share` **не** смонтирован — содержимое читалось через D:).

Три периода с подпапкой `debit`:

| Период | Содержимое (кратко) |
|--------|---------------------|
| `2025-12` | Общий свод ДЗ на 31.12.2025; `ags_Yr_DbtChangesRslt_*`; **Приложение 1** (сводный по счетам); **Приложение 2** (итоговый по 606012/762210/767502) |
| `2026_03` | Общий свод на 31.03.2026; `export_{счётГК}_*`; `ags_Yr_DbtChangesRslt_*`; кейс `26-0526_Головинова`; **Приложение 1** (итоговый по счетам, без годового свода) |
| `2026-06` | Общий свод на 30.06.2026 (`-НОВЫЙ`) |

Также вне `excel/*/debit/`: **`femsq/debit/23-0421_sql.docx`** — история Access SQL для Rslt и `*D644*`.

**Типы файлов (рабочая классификация):**

| Тип | Пример имени | Назначение (по заголовкам) |
|-----|--------------|----------------------------|
| **Общий свод ДЗ** | `Дт Задолженность на ДД.ММ.ГГГГ (Общий свод)[-НОВЫЙ].xlsx` | **Вход из бухучёта** → загрузка в FishEye.ags (Access, 1.1.1.1). Без привязки к стройке |
| **ags_Yr_DbtChangesRslt** | `ags_Yr_DbtChangesRslt_*.xlsx` | **Выгрузка из FishEye.ags** (Access, 1.1.1.3): сопоставленные ДЗ нарастающим итогом; оборот со специалистами по мероприятиям |
| **export_{счётГК}** | `export_606012_26-0422.XLSX` и др. | **Вход для привязки к `cst`/`cstAgPn`** → загрузка в FishEye.ags (Access, 1.1.1.2) |
| **Кейс / претензия** | `26-0526_Головинова/` | Материалы к мероприятиям (к шагу 1.1.2) |
| **Итоговый документ** | `Приложение N. Сведения о ходе работы по балансовым счетам 606012, 762210, 767502.xlsx` | **Выход** (1.2.*): построчные сведения; лист `ags_Yr_DbtChangesRsltD644_*`; счета 606012/762210/767502 |
| **Итоговый сводный документ** | `Приложение 1. Информация о состоянии дебиторской задолженности в разрезе счетов бухгалтерского учета.xlsx` | **Выход раз в год** (после Q4): агрегат по счетам ГК; лист `СВОД по субсчетам Д644`; с итоговым за Q4 |
| **История Access SQL** | `debit/23-0421_sql.docx` | Запросы `ags_Yr_DbtChangesRslt_*` и `*D644*` (финальная обработка в Access) |

**Счета ГК, встречающиеся в сводах (черновик списка):**  
`601300`, `601750`, `601760`, `606012`, `606022`, `682102`, `761010`, `762210`, `767401`, `767402`, `767403`, `767501`, `767502` (часть листов помечена «нет»).

**S2 → роль свода:** В6 закрыт.  
**S3 → Rslt / export:** В7 и В8 закрыты; Access = клиент FishEye.ags на всех шагах загрузки/выгрузки/мероприятий/согласования.  
**S20 → исходящие:** В9 закрыт (есть образцы итогового и сводного); уточнена роль запросов `*D644*`.

---

## 6. Критерии «документация достаточно полна» (выход из фаз A–D)

**Область MVP (S24):** живой квартальный процесс (дерево S3) на данных Q4’2025–Q2’2026. Историческая ретро-миграция (`cnNum`/`invNum` до 2025, P8) — **вне** критериев готовности MVP, отдельный этап позже.

- [x] Есть **обзор** домена: зачем СУДЗ, границы, что не входит *(черновик 01-overview)*.
- [x] **Глоссарий** — базовые термины процесса *(02-glossary; Access/SQL — позже)*.
- [x] Описан **основной процесс** P1 квартального цикла *(03-processes; детали Access UI — позже)*.
- [x] **Карта данных:** перечень сущностей Access ↔ таблицы `ags`; gaps явно помечены *(04-data-model + карта миграции 04-3 §6.6/§7.6; целевая модель `Dbt`/`invDbtDbt`/`DbtValue` закрыта полностью — S30)*.
- [x] **IA:** решение, куда в меню кладётся СУДЗ *(домен `sudz`, отдельный верхний пункт TopBar «СУДЗ» — S27)*.
- [x] **Эскиз** 1–2 ключевых экранов согласован с пользователем *(02-9_sudz-mvp-screens.md; решение S47)*.
- [x] **Backlog** MVP сформулирован и готов к выносу в задачу разработки *(0065–0070, дерево 02.03)*.

Детальная, по-областям разбивка (что именно закрыто каждым сегментом, что нет) — в реестре покрытия [07-readiness.md](../../domain/sudz/07-readiness.md); он — рабочий инструмент для поиска пропущенных сегментов и обоснования финального перехода к разработке.

---

## 7. Открытые вопросы

| ID | Вопрос | Статус |
|----|--------|--------|
| В1 | Официальное имя домена в FEMSQ: «СУДЗ», «Дебиторка», «Долги», иное? | ✅ **закрыт (S27):** домен `sudz`, отображаемое имя «СУДЗ» |
| В2 | СУДЗ — отдельный пункт TopBar или раздел внутри «Договоры» / «Инвестиции»? | ✅ **закрыт (S27):** отдельный верхний пункт TopBar, голова возможной группы — [02-4_app-forms-ia.md](../../UI/02-4_app-forms-ia.md) |
| В3 | Какие формы Access считаются «ядром» СУДЗ, а какие — вспомогательным импортом (`CnInvDbtUpl`)? | 🔶 **1.1.1.1 закрыт (S27/S29):** ядро dbt — `CnInvDbtUpl_2` / `File_f` / `btnCidufLoad` / InvDouble — [04 §2.7](../../domain/sudz/04-data-model.md#27-полный-алгоритм-btncidufload_click--цепочка-сопоставления-подтверждено-s29). **1.1.1.2 паспорт Access закрыт (S69):** ядро pmt — `CnInvPmtUpl>File_f` / `btnUpload` — [02-11](../../UI/02-11_cn-inv-pmt-upl-access.md); шаг 8 только показ. Шаги 1.1.2/1.2.* — формы ещё нет |
| В4 | Живой Access-файл СУДЗ: путь на nb-win / в ВМ, отличие от `ra_audits.accdb`? | ☐ открыт |
| В5 | Какие таблицы `ags` — «истина» домена, а какие — staging / архив импорта? | ☐ частично: факт загрузки = `cn_inv_dbt*`; канон сущности долга — ещё нет (S5, М8) |
| В6 | Общие своды `Дт Задолженность…` — вход / выход / внешний источник? | ✅ **закрыт (S2):** вход из бухгалтерской системы |
| В7 | Что такое `ags_Yr_DbtChangesRslt_*`? | ✅ **закрыт (S3):** выгрузка из FishEye.ags через Access |
| В8 | Файлы `export_{счёт}_*`? | ✅ **закрыт (S3):** привязка к `cst`/`cstAgPn`; загрузка в ags через Access |
| В9 | Пример **исходящего** Excel для подразделения? | ✅ **закрыт (S20):** итоговый документ (`Приложение N. Сведения о ходе…606012, 762210, 767502`) + годовой сводный (`Приложение 1. Информация о состоянии…`); образцы в `2025-12` / `2026_03` |
| В10 | «Перенос срока погашения» — как отражается в следующем своде? | ☐ открыт |
| В11 | Где фиксируются **мероприятия**? | ✅ **закрыт (S25):** `cnInvCmm*`(+`Ag`/`Cst`/`Dt`/`Fn`)+`Gr`+`Tp`, FK на `cnInvAccnt`; иерархия групп специалист→общая; выбор актуальной группы года — `yr.yr_CmmGr`/`yr_upl_p` — [04-data-model §2.6](../../domain/sudz/04-data-model.md) |
| В12 | Какие формы/запросы Access на шагах 1.1.1.* / 1.1.3 / 1.2.*? | 🔶 **частично (S20–S21):** пары Rslt→D644 из docx сведены; на шаре подтверждены 2 Rslt + 2 листа D644 в Приложениях — [03 §1.2.5](../../domain/sudz/03-processes.md); формы UI ещё нет |
| В13 | Таблица `vr` на ER: локальная Access / устаревшая / другое имя? | ☐ открыт (в FishEye.ags `vr%` нет) |
| В14 | Целевая таблица сущности «Задолженность» (`cnInvAccnt` vs `invDbt` vs новая) и правила match (М8–М10) | 🔶 **уточнено (S14):** эскиз владельца `Dbt`+`invDbtDbt`+`DbtValue`, опирается на уже живые `cnInv`/`invNum`/`cnNum`; закрывает реестр целиком кроме P8 — [04-3 §7](../../domain/sudz/04-3_problems-solutions.md#7-ревизия-целевой-модели-по-эскизу-владельца-dbt--invdbtdbt--dbtvalue-s14) |
| В15 | Утвердить целевой порядок сторон/Debt (P6/P7) | ✅ **закрыт по существу (S14):** у `Dbt` вовсе нет FK на сторону (сильнее вариантов A/B/C) — сторона выводится через `Cn` или снимается на `DbtValue` |
| В16 | Утвердить целевую модель к реализации: физические имена, `UNIQUE(inv, dbt)`+`UNIQUE(invDbt)` на `invDbtDbt` (S16, взамен `is_current`), правило `UNIQUE(cn_key, cn_s_type)` на `cn_s`, формат оживления `invDbt` | ✅ **закрыт полностью (S30, подтверждено S32):** имена — camelCase как на эскизе; `UNIQUE(cn_key, cn_s_type)` — жёсткий constraint (проверено фактами, гипотеза `Dbt`/`DbtTrue` разобрана — новая сущность не нужна; кратковременное переоткрытие S31 по массовым договорам снято в S32 — множественность исполнителей живёт на `cn_s_org_smpl`, не на `cn_s`); `invDbt` — та же таблица, новые строки при каждой загрузке — [04-3 §7.7–7.9](../../domain/sudz/04-3_problems-solutions.md#77-что-осталось-уточнить-перед-реализацией) |
| В17 | P8 (объём Smpl под `cstAgPn`) — когда возвращаемся к решению? | ☐ явно отложен владельцем (S13); подтверждено отложенным на уровне порядка работ (S24) |
| В18 | Миграция истории в эскиз без `doc_base` | ✅ **уточнено (S19), правило выбора найдено (S24):** `smpl` — по org карточки (не «единственный на сторону») → **12 220** карточек / **41 124** фактов переносимы без неоднозначности; остаток **~473** (в основном несколько `cnNum`) требует исторических Excel — **миграция отложена**, приоритет живому процессу — [04-3 §7.4.2](../../domain/sudz/04-3_problems-solutions.md#742-уточнение-блокера-несколько-smpl-s24-роль-не-помогает-помогает-org) |
| В19 | Реестр покрытия домена: какие области ещё не закрыты сегментами (нужно для критериев §6) | 🔄 заведён (S24) — [07-readiness.md](../../domain/sudz/07-readiness.md) |
| В20 | Где определён базовый Access-запрос `ags_Yr_DbtChanges` (пивот `cnInvCmm*` → колонки Rslt)? | ✅ **закрыт (S26, = М14):** это хранимая процедура SQL Server `ags.Yr_DbtChanges(@yr)` (не Access QueryDef) — найдена и разобрана через DBHub — [04-data-model §2.6](../../domain/sudz/04-data-model.md#механизм-agsyr_dbtchanges-найден-и-разобран-s26) |
| В21 | Почему dev-снимок `ags` не содержит выгрузок/групп комментариев новее середины 2025 года при том, что Excel-образцы доходят до 30.06.2026? | ✅ **закрыт (S26, = М15):** уточнено владельцем — просто отсутствие новых бэкапов dev-БД; в проде процесс велся без изменения методики |
| В22 | Роли пользователей приложения СУДЗ и права доступа (= I1) | ✅ **закрыт (S27):** на MVP — без ролей/прав, доступно всем; пересмотр — отдельным сегментом при потребности |

---

## 8. Порядок работы в чате (протокол)

1. Пользователь присылает **сегмент** (текст, скрин, имя формы/таблицы, SQL, VBA, сценарий).
2. Ассистент:
   - кратко подтверждает, что понял;
   - классифицирует (процесс / данные / UI / термин / связь с другим доменом);
   - обновляет §5 (и при необходимости §7);
   - при накоплении материала — создаёт/дополняет файлы из §4;
   - задаёт **не больше 1–3 уточняющих вопросов**, если без них нельзя уложить сегмент.
3. Не начинать широкую реализацию Java, пока не закрыты критерии §6 (кроме согласованных микро-эскизов).

**Форматы сегментов (удобно):**

- список форм/запросов Access с однострочным назначением;
- скрин главной формы + пояснение «что здесь делают»;
- DAO-дамп / `.table.md` / `.access.sql` по [MS-ACCESS-OBJECTS-CAPTURE](../../../../project/proposals/vba-analysis/MS-ACCESS-OBJECTS-CAPTURE.md);
- пользовательский сценарий («как бухгалтер закрывает долг»);
- указание «это то же, что X в FishEye» или «в SQL этого нет».

---

## 9. Связанные материалы (стартовый набор)

- IA: [02-4_app-forms-ia.md](../../UI/02-4_app-forms-ia.md)
- VBA summary (долги): [VBA-ANALYSIS-SUMMARY.md](../../../../project/proposals/vba-analysis/VBA-ANALYSIS-SUMMARY.md)
- Съём объектов Access: [MS-ACCESS-OBJECTS-CAPTURE.md](../../../../project/proposals/vba-analysis/MS-ACCESS-OBJECTS-CAPTURE.md)
- Формы загрузки долгов (VBA): `Form_CnInvDbtUpl*.cls` в `VBA-Code-Export/Form-Modules/`
- План форм строек (образец документации+IA): [chat-plan-26-0722-forms-ia-cst.md](./chat-plan-26-0722-forms-ia-cst.md)

---

**Автор плана:** Cursor AI Assistant + Александр  
**Создано:** 2026-08-02  
**S2 / domain/sudz:** 2026-08-03  
**S3 дерево работ:** 2026-08-03  
**S4 модель данных:** 2026-08-03  
**S5 идентичность задолженности:** 2026-08-03  
**S6 MS_Description:** 2026-08-03  
**S7 пример Rslt 82/85:** 2026-08-03  
**S8 судьба в Rslt 2025:** 2026-08-03  
**S9 свод 30.06.2026:** 2026-08-03  
**S10 реестр проблем / invDbt:** 2026-08-03  
**S11 P1 объект документа (суд↔СФ):** 2026-08-03  
**S12 стороны/Smpl/P6–P7:** 2026-08-03  
**S13 целевая модель Dbt/DocBasis:** 2026-08-03  
**S14 ревизия по эскизу владельца:** 2026-08-03  
**S15 уточнение триггера (членство, constraint):** 2026-08-03  
**S16 invDbtDbt на UNIQUE(inv, dbt):** 2026-08-03  
**S17 снято «текущий Inv»:** 2026-08-03  
**S18 оценка неперегружаемой истории:** 2026-08-03  
**S19 перегрузка однозначных карточек:** 2026-08-03  
**S20 итоговые/сводные документы + SQL D644:** 2026-08-05  
**S21 соответствие Rslt/D644 ↔ Excel:** 2026-08-05  
**S22 маппинг полей SQL ↔ Excel:** 2026-08-05  
**S23 FEMSQ Excel / `*_new` = 1.1.2–1.1.3:** 2026-08-05  
**S24 приоритет реализации (история отложена) + реестр покрытия:** 2026-08-06  
**S25 структура хранения мероприятий подтверждена по БД:** 2026-08-06  
**S26 `ags_Yr_DbtChanges` найдена как SQL Server-процедура; область D закрыта:** 2026-08-06  
**S27 G1/G2/I1 решены владельцем; форма-«ядро» 1.1.1.1 найдена:** 2026-08-06  
**S28 изучены материалы по `btnCidufLoad_Click`; найден `InvDouble`-паттерн:** 2026-08-06  
**S29 полный `btnCidufLoad_Click()` найден и разобран; М1/М9 закрыты:** 2026-08-06  
**S41 мини-витрина Rslt:** 2026-08-07  
**S42 gaps мини ↔ Excel → план Rslt/D644:** 2026-08-07  
**S42a контракт шапки Rslt (владелец):** 2026-08-07  
**S52 / S52a Progress + yr_CmmGr_New:** 2026-08-08  
**S53 Rslt сбор:** 2026-08-08  
**S54 Excel v2 + yr_Progress (путь папки отложен):** 2026-08-08  
**S55 Excel стили эталона 26-0212:** 2026-08-08  
**S56 UAT Excel Rslt принят (подпись idNum):** 2026-08-08  
**S57 Rslt повтор (yr_CmmGr_New):** 2026-08-08  
**S58 Progress операции Выгрузить/Загрузить:** 2026-08-08 — UI+REST импорт; JAR `0.1.0.166-SNAPSHOT`
**S59 D644 / Свод · Выгрузить:** 2026-08-09 — Excel REST + Progress; UAT S59a; JAR → `0.1.0.171-SNAPSHOT`  
**S59b приёмка владельцем:** 2026-08-09 — срез D644/Свод принят  
**S59c Свод proto/Excel:** 2026-08-09 — переключатели как у D644; `sudz-svod-preview.ts`  
**S60 закрытие 0070:** 2026-08-09 — 1.1.3 без операции New→CmmGr; полный путь папки — отдельно; Progress MVP ✅  
**S61 старт 0069:** 2026-08-11 — эскиз лаунчера  
**S61c:** 2026-08-11 — UI после переноса Access-local→SQL; см. §5.6 этапы 0–7

---

### 5.6. 0069 — загрузка общего свода → порядок (S61 → S61c)

**Задача:** [0069](../../../project-development.json) · шаг процесса [03 §1.1.1.1](../../domain/sudz/03-processes.md) · алгоритм Access [04 §2.7](../../domain/sudz/04-data-model.md#27-полный-алгоритм-btncidufload_click--цепочка-сопоставления-подтверждено-s29) · IA [02-9](../../UI/02-9_sudz-mvp-screens.md) / [02-4](../../UI/02-4_app-forms-ia.md).

**Решение владельца (2026-08-11, S61):** новый чат Cursor, тот же chat-plan; сначала лаунчер, потом воронка.

**Уточнение владельца (2026-08-11, S61c):** UI **после** переноса Access-local буферов на SQL. Причина: `CnInvDbtUplFile*` / `Tbl*` на сервере **нет** (DBHub); экран без них = тупик для воронки. Эскиз wireframe (02-9 §4a) остаётся ориентиром, код UI — после DDL/решения по staging.

#### Порядок работ (S61c) — согласованное предложение

| # | Этап | Содержание | Результат / критерий |
|---|------|------------|----------------------|
| **0** | Эскиз UI (сделано) | Wireframe + скрины Access; разделение SQL vs Access-local | [02-9 §4a](../../UI/02-9_sudz-mvp-screens.md); [assets](../../UI/assets/26-0811-cn-inv-dbt-upl/README.md) |
| **1** | Съём структуры Access-local | Полный TableDef (поля, типы, PK/индексы, Description) для контура ДЗ | Дампы UTF-8 в `docs/…` (метод [MS-ACCESS-OBJECTS-CAPTURE](../../../../project/proposals/vba-analysis/MS-ACCESS-OBJECTS-CAPTURE.md)) |
| **2** | Связи и формы | Карта: File↔FileSh↔Tbl↔TblCnInv↔InvDouble↔`cidufUpload`→`cn_inv_dbt_upl`; привязка к `CnInvDbtUpl_2` / `File_f` / InvDouble; что эфемерно (очистка на load) vs долговечно | Раздел в 04-data-model + ER-набросок |
| **3** | Границы переноса | В scope 0069: File, FileSh, Tbl, TblCnInv, FileInvDouble. Вне: `CnInvPmtUpl*`, `*Old`, `cipu*`, `ags_Yr_DbtTbl`, `cn_PrDocImp` (пока) | Решение владельца |
| **4** | Целевая схема на сервере | Куда: **`sudz`** (DEV) зеркало имён vs новые имена; FK на `cn_inv_dbt_upl`; тип лога (nvarchar(max)/HTML); путь — имя файла vs полный UNC (S60) | ADR/запись в 08-target-schema + DDL-черновик |
| **5** | DDL + apply на DEV | Скрипты (корень = SQL2022; `MSSQL2012/` если когда-либо на prod); seed пустой / минимальный | ✅ Dbt+Pmt staging |
| **6** | GraphQL + экран C | Список upl + карточка File + подвкладки (каркасы с реальными таблицами); кнопка «загрузка» ещё stub | ✅ 2026-08-13 |
| **7** | Воронка `btnCidufLoad` | Шаги с UI-чекбоксами (S61f); оркестратор + отдельный метод на шаг; см. ниже | Критерии 0069 |

**Минимум дампа этапа 1 (обязательно):**

1. `CnInvDbtUplFile`  
2. `CnInvDbtUplFileSh`  
3. `CnInvDbtUplTbl`  
4. `CnInvDbtUplTblCnInv`  
5. `CnInvDbtUplFileInvDouble`  

Желательно (для полноты связей): Relationships Access (скрин/экспорт) + 1–2 строки-образца из File/FileSh по upl_key=26.  
Вне этапа 1: платёжные `CnInvPmtUpl*` — только если всплывут зависимости в коде File_f.

**Метод съёма:** `DumpTableDef_Extended "ИмяТаблицы", …, "C:\temp\….txt"` → UTF-8 в репозиторий (см. capture-док).

**Не путать с A0 «Выгрузки»:** там уже SQL `yr_upl_p`; здесь — операционный буфер загрузки свода.

**Вне первого среза 0069:** шаг **1.1.1.2** (`export_*`); контент вкладок «счета/долги/pm» (можно read-only с уже существующих SQL позже).

#### Шаг «воронка» (бывш. шаг 2; теперь этап 7)

**Решение владельца (2026-08-13, S61f):** не гнать всю цепочку сразу. В Access практика — комментировать последующие `Sub` и включать по одной после приёмки предыдущей. В FEMSQ — **визуальная панель шагов с чекбоксами**; разработка и UAT **каждого шага отдельно**.

**S61g (2026-08-13):** UI панель + mutation `runSudzDbtUplFunnel` (stub: пишет HTML в `cidufLoadingProgress`, домен не трогает).

**S61h (2026-08-13):** реальный `excelToTbl` — сначала браузерный upload → staging; парсер VBA/`AccountSheetTest`→`ReceivablesTest` → `REPLACE` `sudz.CnInvDbtUplTbl`. DEV UAT: **1764** строк (файл 31.12.2025).

**S61i (2026-08-14):** скрепка и REST staging сняты. Пользователь вставляет путь **как в Проводнике** в редактируемое поле → `updateSudzDbtUplFile.path` → `cidufPath`. `excelToTbl` читает это поле; JVM на WSL переводит `D:\…` → `/mnt/d/…` (и bind `/mnt/nb-win-share` для шары nb-win). В БД путь не переписывается.

**S61j (2026-08-14):** UAT upl=910 — **1764** строк (606012:1125, 606022:327, 761010:9, 762210:58, 767501:7, 767502:238). Новый прогон **очищает** `cidufLoadingProgress`. Чекбокс «Обновлять промежуточную таблицу…» снят: Excel→Tbl включает только переключатель **«обнов. по исх?»** (`cidufFlTbl`), как в Access. Канон путей проекта: `project-docs.json` → `development.file_paths`.

**S61k (2026-08-14):** шаг `orgNotInBuirg` реален: DISTINCT из `CnInvDbtUplTbl` (фильтр `cidutUnloadKey`) LEFT JOIN `ags.org_id` type=1; нет кода БУиРГ → лог «Новая: N. имя. БУиРГ. ИНН»; при совпадении ИНН type=2 — «Уже имеется организация». Несколько type=2 на один ИНН дают несколько строк (как Access). **Домен не пишется**; `cidufFlLoad` не влияет. UAT upl=**910** (превью SQL: 9 строк лога / 4 кода БУиРГ; Россети — 6 совпадений ИНН). **upl 26 не трогать.** Далее — `CnNotLoad`.

**S61l (2026-08-14):** шаг `CnNotLoad` реален (только лог). Цепочка Access QueryDef снята в `access-queries/ciduCnNotLoad*.access.sql`. T-SQL считает `cidutCnNameNull` / `cidutCnDateNull` как **вычисляемые** поля Access (`NullИлиПусто` / `1900-01-01`), физические столбцы `sudz` не используются. Anti-join: номер + БУиРГ + дата vs `ciduCnCtptList`; затем номер отсутствует в `ags.cnNum`. Превью/UAT upl=**910**: ~65 строк.

**S61l+ (2026-08-14):** apply при `cidufFlLoad` / `flLoad=true`: INSERT `cn`→`cnNum`→`cn_s`(type=2)→`cn_s_org_smpl`→`cn_s_org` только если `countCnName=1`; общий `cnMark=strMark(Now())`; лог печатает mark и ключи. Откат: GraphQL `rollbackSudzCnNotLoad(cnMark)` (DELETE org→smpl→s→num→cn). Транзакция на весь apply. **upl 26 не трогать.** Далее — `CnExistCtptNotLoad`.

**S61m (2026-08-14):** `DataFormatter` давал scientific для длинных целых NUMERIC (Ростелеком `211000089635` → `2.11E+11`). `AuditExcelCellReader.readString` пишет plain digits. UAT 910: откат **8142118** → перезаливка Tbl 1764 → apply **cnMark=8142135** (65 шт.); в домене `cnnNum=211000089635`. UI: «Обновлять» = `cidufFlLoad` (persist); чекбоксы шагов — сессия. JAR **0.1.0.184**. Далее — `CnExistCtptNotLoad`.

**S61n (2026-08-14):** шаг `CnExistCtptNotLoad` реален (только лог). Access: QueryDef `ciduCnExistCtptNot` / `SqlCnExistCtptNotLoad`; несмотря на «либо добавляем», VBA **не пишет** в домен (`cidufFlLoad` не используется). Семантика: те же CTE, что `CnNotLoad`, но `HAVING COUNT(cn) > 0` (номер уже в БД, нет пары №+дата+БУиРГ). Артефакт: `access-queries/ciduCnExistCtptNot.access.sql`. UAT upl=**910**: **5** строк (в т.ч. БУРГЕОКОМ «Б/Н», Россети Волга `2540-000097`). JAR **0.1.0.185**. Далее — ручной контур сторон (**S62** / **0071**), затем `clearInvDouble` / `CnCtptExistInvNotLoad`.

**S62 (2026-08-15):** владелец подтвердил: пакетный apply исполнителя к существующему договору в Access не делался — нужен UI. Присланы Design/SQL скрины формы **`cnNum`** и вложенных `cn` → `cn>s` → `orgSmpl` → `org`. Сохранены в [assets/26-0815-cnNum](../../UI/assets/26-0815-cnNum/README.md); сводка — [02-10](../../UI/02-10_contracts-cnNum-access.md). Заведена задача **0071**. **Код экрана не начинать**, пока не согласован подход (следующий пост). TopBar «Договоры» — из заготовки в запланированный экран ([02-4](../../UI/02-4_app-forms-ia.md)).

**S62b (2026-08-15):** второй пакет скринов — **runtime** (`cnNum` список, стороны, `cnMark`) и ветка **счёта-фактуры**: `ciNumCs` → `inv`/`invNum` → `cnInv` → `cnInvAccntSmpl` → runtime-стек `cn_inv_dbt`/комментарии. Файлы `20`–`40` в том же каталоге assets. Для **0071 MVP** достаточно сторон; СФ — эталон следующих шагов воронки (сплющить вкладки в web).

**S62c (2026-08-15):** пакеты 3–4 — Accnt_f/dbt_t, lookups, вкладки **платежи** (`ags_cn_inv_pm_dbt_upl`) и **первичные документы** (`ags_cn_PrDoc`/`PrDocP`). Владелец: UI FEMSQ — по [dbtvar](../../domain/sudz/assets/26-0807-sudz-target-sketch-dbtvar.png), Access — справочник живой формы. Runtime наполненного PrDoc не снят (ошибка Access); Design/SQL достаточно для описания.

**S63 (2026-08-15):** вскрыта ошибка эскиза dbtvar (`cn_inv_pm`→`cn_s_org_smpl` без пути к `accnt`; ломает и PrDoc/освоение лимитов). Живая `ags` уже: `ciaCnInvAccntSmpl` NOT NULL на всех 479 268 pm; PrDoc тоже на Smpl. **Владелец утвердил вариант 1:** pm/PrDoc → `cnInvAccntSmpl`; живое не трогать; явный мост Dbt↔Smpl не нужен (навигация через invDbt*→cn_s_org→…→Smpl→pm для строек); PrDoc в СУДЗ не используется; освоение лимитов — после СУДЗ, ничего не ломать. Smpl искусственен онтологически, но sunset только «когда‑нибудь». Разбор: [04-3 §9](../../domain/sudz/04-3_problems-solutions.md).

**S64 (2026-08-15):** для экрана Договоры выбран **самый быстрый путь СУДЗ** — FemsqTable **client** (~2.4k `cnNum`); серверная фильтрация fequlib отложена, целевой кейс — **`cn_inv_pm`**. Реализация шага 1: TopBar «Договоры», GraphQL `cnNums`/`cn`/`cnNumsByCn`, UI master–detail.

**S65 (2026-08-15):** шаг 2 — стороны как дерево агентов cst (не fequlib): `cn_s`→smpl→org, **полный CRUD**; GraphQL `cnSides` + mutations; lookup `org_id` БУиРГ; роли заказчик/исполнитель всегда видны. JAR **0.1.0.187**. UAT: договор со сторонами (напр. `cn_key=356`) и кейс `CnExistCtptNotLoad` (upl 910).

**S65b (2026-08-15):** разбор UAT 910 «БУРГЕОКОМ / Б/Н / дата отсутствует»: org **уже в** `org_id` (641/642, og 579); в `cn_s_org_smpl` **0** связей — искать «договор БУРГЕОКОМ» бессмысленно; нужно **добавить smpl** под любой существующий `cnnNum=Б/Н` + org с пустым `csoCnDate`. Excel лист `762210` R43: Договор=`Б/Н`, дата договора пустая, долг 7454; Tbl upl910 `findDbtNum=1507` совпадает. Даты в UI org — всеядный парсер ДД.ММ.ГГГГ.

**S65c (2026-08-15):** развилка CnExistCtptNotLoad: (1) новый договор vs (2) перемена сторон на старом. Авторазбор коллизий номера (**Б/Н** и т.п.) **не делаем** — ответственность оператора. UI: **«+ Договор»** = create `cn`+`cnNum`+исполнитель (вар.1); «+ smpl» = вар.2. Предупреждение при duplicate `cnnNum`. JAR **0.1.0.188**.

**S65d (2026-08-15):** как Access CnNotLoad — дата из свода в **`csoCnDate`**, при create **`cn_date` всегда NULL**. Mutation `updateCn` + кнопка на карточке для ручной правки `cn_date`/`cn_note`/`cnMark`. JAR **0.1.0.192**.

**S65e (2026-08-15):** чекбокс «Очищаем таблицу двоящих счётов-фактур» снят с панели. В Access это вызов `TableRecordsClear` сразу перед `CnCtptExistInvNotLoad` — для оператора не этап. В FEMSQ prelude внутри шага `CnCtptExistInvNotLoad`.

**S66 (2026-08-15):** шаг `CnCtptExistInvNotLoad` реален. QueryDef-цепочка: `ciduCnExistInvNot` ← `ciduCnCtptExistList` / `agsCnInvNumsVariants` / `agsInvNumCount`. Буфер `CnInvDbtUplTblCnInv`; лог как Access; InvDouble при `inNumCount`; apply `inv`→`invNum`→`cnInv` при flLoad. JAR **0.1.0.194**.

**S67 (2026-08-16):** UAT upl=**910** dry (`flLoad=false`): **128** договоров, **705** отсутствующих СФ — счётчики верны; время **>3 мин** из‑за одного CTE на `rebuildDbtUplCnCtptExistInvNot`. Перепись на поэтапные `#temp` + индексы; HTML-лог — первые 8 СФ на договор. JAR **0.1.0.196**.

**S67a (2026-08-16):** после `#temp` — `collation conflict` Latin1 (tempdb) vs `Cyrillic_General_CI_AS` (ags/sudz) на `fillMatched`. Колонки nvarchar в `#ciduNorm`/`#ciduMatched`/`#ciduPairs` с явным `COLLATE Cyrillic_General_CI_AS`. JAR **0.1.0.197**. UAT 10:11: **sqlMs=241 / totalMs=265**, rows=705, contracts=128; InvDouble=12 (все `inNumCount=1`, как Access `Not IsNull`); dry `flLoad=false`.

**S68 (2026-08-16): модуль КСДСФ + общая очередь**

Проблема Access (не решена системно): номер СФ уже в `ags`, а в Excel — «новый» для другого договора. СФ иногда **переезжают** между договорами. Решение «создать новый» vs «перепривязать существующий» — только оператор; система даёт максимум фактов.

**Решения владельца:**

1. Несколько строк Excel с одним двоящим № → **отдельная строка очереди на каждую** (разный Excel 1/3 и «суммы»; одинаковый домен/СФ по номеру).
2. Bulk `flLoad` на `CnCtptExistInvNotLoad` **исключает** очередь — разбор вручную.
3. Перепривязка v1 **не** делается (оператор сам в «Договоры»).
4. Статус разбора (`open` / `created` / `deferred`) до следующего полного прогона загрузки выгрузки.
5. Вкладка «Повторяющиеся СФ» **без** встраивания КСДСФ: только грид + кнопка на **отдельный экран**.
6. Модуль переиспользуется для **долгов и платежей** через общую таблицу очереди.

**Access pmt (снято):** `CnInvPmtUpl>File_f>InvDouble` RS =

`TblCnInv AS d LEFT JOIN (cnInv⋈invNum) … WHERE ciputciCnInvNumCount Is Not Null`;  
nested `invNum` (`ciputciCnInv`↔`inNumNull`) → `cnInv` (`inInv`↔`ciInv`);  
`btnInvCreate` → `invCreateNewNumDate` + `cnInvCreateNewInvCn` + Requery.

**DDL (проект → DEV):** [`docs/development/notes/sql/26-0816-sudz-sf-num-collision/`](../../../sql/26-0816-sudz-sf-num-collision/) — `sudz.CnInvUplSfDouble` (`cius*`), XOR FK `ciusCidut` / `ciusCiput`, статусы, индексы. **CREATE применён на femsq-mssql (2026-08-16).** Legacy `CnInvDbtUplFileInvDouble` пока пишется параллельно.

**Реализовано (JAR 0.1.0.198):** наполнение очереди при rebuild (1 Excel-строка ↔ 1 queue); bulk apply только `inNumCount IS NULL`; launcher.`sfDoubles`; экран `sudz-sf-double` (кнопка на вкладке doubles); Excel-карточка + домен/СФ; mutation `createSudzSfFromDouble`; вкладка «суммы» — заглушка.

**Целевая структура правого нижнего блока (tree) для S68 / `sudz-sf-double`:**

Конспекты и правила — [02-12](../../UI/02-12_femsq-tree/relation-tree.md). Исторический H1: [`sudz-sf-double-tree.md`](../../UI/02-12_femsq-tree/sudz-sf-double-tree.md). Актуальная карта КСДСФ: [`ksdsf-inv-num.tree.md`](../../UI/02-12_femsq-tree/ksdsf-inv-num.tree.md). Договоры/СФ: [`contracts-inv.tree.md`](../../UI/02-12_femsq-tree/contracts-inv.tree.md). Поля шапки/детали — в конспектах, здесь не дублировать.

**H1 (2026-08-18):** нижняя карточка заменена на `FemsqTree` из fequlib. Ручной builder `sudz-sf-double-tree.ts`: каркас из `sudzSfDoubleDomainMatches`; стороны — `cnSides`; СГК/`cn_inv_dbt`/`invDbt` — `sudzSfDoubleTreeDebt`. Корень пока `inv`, не `invNum`; `cn_inv_dbt_upl` нет; `lazy`/`@load` не включены. UAT-якорь: СФ `832930` / `inv=85069` / `cn=2265`.

##### S68t (2026-08-18): дерево связей — walker над FemsqTree

**Граница.** `FemsqTree` v1 (fequlib **0016**) закрыт: renderer, слоты, `selectedKey` ≠ `expandedKeys`, lazy `@load`. Обход связей — **другой** компонент (`RelationTree`), который использует `FemsqTree`. Не класть JSON/fetch внутрь renderer. Решение: [009](../../../../project/decisions/009-femsq-walk-tree.md). До **T4b** обёртка ещё импортирует Apollo FEMSQ — это долг среза 1, не целевой контракт.

**Мероприятия**

| ID | Что | Где | Критерий |
|----|-----|-----|----------|
| **T0** | Заморозить конспекты 02-12; колонки рёбер сверить с живой `ags`/`sudz` (DBHub) | [relation-tree.md](../../UI/02-12_femsq-tree/relation-tree.md) §3 | ✅ 2026-08-18; PK/FK сверены; в каталог добавлены `invDbt.idd` / `idd.dbt` / `dbt.dv` |
| **T1** | Два **независимых** JSON по конспектам | [`src/trees/`](../../../../code/femsq-frontend-q/src/trees/) | ✅ 2026-08-19: `ksdsf-inv-num` / `contracts-inv` **version 1**; 15/14 рёбер; `to` у всех детей; без `$ref`; единственное отличие КСДСФ — `invNum.inv` |
| **T2** | Каталог рёбер (whitelist имён) | Java `RelationEdgeCatalog` + FE `relation-edges.ts` | ✅ T5: 15 рёбер v1 (полный КСДСФ); чужое имя → ошибка |
| **T3** | GraphQL `relationExpand(edge, fromId)` | `relation-schema.graphqls`; плюс `relationNode(table, id)` для корня | ✅ playground: три ребра; неизвестный edge → 400 |
| **T4** | Обёртка над `FemsqTree` | `RelationTree.vue`; КСДСФ флаг `useRelationWalker` | ✅ lazy `@load`; rebuild по токену `invNum:{inKey}`; JAR **0.1.0.200** |
| **T4b** | Отвязать walker от хоста | `RelationTree` + `relation-tree.ts` + JSON | ✅ `fetchNode`/`fetchExpand` пропсами; `to` у детей JSON; без `RELATION_EDGES` в walker; 7 unit-тестов |
| **T5** | КСДСФ: корень `invNum` выбранной строки списка; выкинуть ручной builder | `SudzSfDoubleView` | ✅ 2026-08-19: `ksdsf-inv-num.tree.json`; только `RelationTree`; удалены builder + `sudzSfDoubleTreeDebt`; JAR **0.1.0.201** |
| **T6** | UAT дерева КСДСФ | очередь upl **910**, якорь `832930` | ✅ 2026-08-24: экран использован при разборе; после S68u open-очереди нет (якорь больше не в `open`) |
| **T6a** | Actions в `RelationTree` | walker + JSON + хост | action на папке/записи; walker отдаёт `ActionContext`, но не знает GraphQL/экранов; v1 JSON-схема actions зафиксирована в 02-12 |
| **T6b** | Универсальная форма записи / связи | `RecordModal`, `pickerSpec`, JSON | `cnInv` как первый кейс; форма возвращает `cnId + invId`; допускает доп. поля связи (`relationTypeId`, `note`, даты); v1 JSON-схема form/picker зафиксирована в 02-12 |
| **T7** | Договоры: вкладка «Счета-фактуры» | 0071 / `ContractsView` | слева `cnInv`; справа **та же** обёртка (уже после T4b/T6a) + JSON Договоров; корень `inv`/`ciInv` · **рабочий план:** [chat-plan-26-0826-contracts-inv.md](./chat-plan-26-0826-contracts-inv.md) |
| **T8** | feQuLib только при дыре контракта **FemsqTree** v1 | отдельный чат fequlib | иначе **0016** не трогать; не путать с T9 |
| **T9** | Вынести walker в feQuLib как `FemsqWalkTree` | отдельный чат fequlib | после **T7** или когда второй продукт берёт дерево; хост FEMSQ = spec + fetch; Java-каталог не выносить |

**Предложение по исполнению — вертикальные срезы, не «сначала весь каталог».**

1. **Срез 0 (док, до кода).** T0 → T1. JSON пишем по md и останавливаемся на ревью. Пока JSON не подписан — полный каталог/`relationExpand` не расширять. ✅ T1 подписан 2026-08-19.
2. **Срез 1 (механизм).** T2 + T3 на **трёх** рёбрах (`invNum.inv`, `inv.cnInv`, `cnInv.cn`) + T4 + урезанный JSON КСДСФ только с этими детьми. На экране доказать: lazy `@load`, смена строки списка пересобирает дерево, та же строка — нет. Ручной builder пока можно оставить за флагом. ✅ 2026-08-18 (JAR 200).
3. **Срез 1.5 (контракт walker).** **T4b** сразу после среза 1, **до** полного JSON и **до T7**. Иначе второй экран и полный каталог нарастут вокруг импорта Apollo. ✅ 2026-08-18.
4. **Срез 2 (полнота КСДСФ).** ✅ 2026-08-19 (T5): полный каталог 15 рёбер; экран на `ksdsf-inv-num.tree.json`; удалены `sudz-sf-double-tree.ts`, `slice1`, `sudzSfDoubleTreeDebt`.
5. **Срез 3 (приёмка).** T6 ✅ 2026-08-24 через операторский разбор upl 910 (S68u); отдельный чеклист на `832930` не повторять — строки `open` больше нет.
6. **Срез 3.5 (контракт CRUD-слоя).** T6a/T6b: actions в JSON + `ActionContext` в walker + универсальная `RecordModal` на хосте. `RelationTree` не знает GraphQL; JSON не содержит SQL; первая предметная форма — `cnInv` (пара `cnId + invId`), но модель сразу допускает обычные сущности и таблицы связи с доп. полями.
7. **Срез 4 (второй потребитель).** T7 только после зелёного T6 **и T4b/T6a**. Иначе два экрана одновременно ломают обёртку. Вкладка «Общее» (S64/S65) не переписывается. Макет вкладок Договоров — в 0071, не в обходнике.
7. **Стоп-кран T8.** Дыра lib renderer (например `@load` не стреляет, слот detail не на selected) → обмен с fequlib, не патч внутри FEMSQ. Нет дыры — `FemsqTree` не трогаем.
8. **T9 не в срезах S68t.** Вынос `FemsqWalkTree` — после T7 / второго продукта, отдельный чат.

**Почему так, а не иначе**

- Расширять `FemsqTree` нечего: не хватает обхода связей, не renderer. Walker — библиотечный кандидат, не режим таблицы и не экран СУДЗ.
- Писать полный каталог до первого экрана — риск недель без картинки. Три ребра на КСДСФ дают ту же обёртку, что потом съест T7.
- Общий JSON / `$ref` между экранами **запрещён** (02-12 §6): дешевле копировать ветку `cn`/`cn_s`, чем связать КСДСФ с Договорами.
- Eager H1 (`cnSides` + `sudzSfDoubleTreeDebt` одним махом) на полный конспект не масштабируется; lazy — контракт v1, его и включать.
- Частная модалка “добавить договор к СФ” слишком узкая; нужен общий контракт формы записи таблицы, где таблица связи — частный случай.
- Если в таблице связи появятся доп. поля (`relationTypeId`, даты, note), схема `верхние поля записи + нижние picker-вкладки по FK-полям` переживёт рост без переписывания дерева.
- T7 не параллелить с T5: один wrapper, два JSON — сначала один живой потребитель. T7 не начинать до T4b.
- Backend Java-каталог не обобщать, пока нет второго Spring-хоста.

**Вне этого среза (не смешивать с T0–T7):** UAT create/наполнения очереди; адаптер pmt; массовая перепривязка СФ; `FemsqTreeList` для сторон договора; **T9** (`FemsqWalkTree`).

**Фазы S68 далее (не дерево):** ✅ UAT create/link 910 (**S68u**); ✅ apply 693 (**S66**); ✅ AccSmpl 705 (**S66a**); ✅ сверка cidu (**S66b**); **S66c шов** — next не код `invDbtDouble`. T6a/T6b — для следующих коллизий.

##### S68s (2026-08-21): вкладка «Суммы» на КСДСФ

**Решения владельца:**

1. Вкладка делится **по вертикали**: сверху старая структура (`ags.cn_inv_dbt`), снизу новая (`sudz.DbtValue`).
2. В каждой половине: **таблица** сумм сверху + **RelationTree** снизу.
3. Совпадение сумм v1 — **только по сумме** (`ABS(сумма − cidutDebt) ≤ ε`), без фильтра по договору Excel.
4. Корень новой половины — **`DbtValue`**.
5. Подсветка строк по выбранному СФ на вкладке «СФ» — **не нужна**.
6. В JSON деревьев приоритет — хорошо раскрыть **СФ**: все `invNum` и все `cnInv`→договоры/стороны.

**Конспекты / JSON (черновик T1):** [ksdsf-cid-sum.tree.md](../../UI/02-12_femsq-tree/ksdsf-cid-sum.tree.md) · [ksdsf-dv-sum.tree.md](../../UI/02-12_femsq-tree/ksdsf-dv-sum.tree.md) · `src/trees/ksdsf-*-sum.tree.json`.

**Нужны новые рёбра каталога:** `cid.cia`, `cia.cias`, `cias.cnInv`, `inv.invNum`, `dv.dbt`, `dbt.idd`, `idd.invDbt`, `invDbt.inv` — **добавлены** (JAR ≥ 0.1.0.213).

**Срезы:** (1) ✅ макет UI + enable вкладки (JAR 211); (2) ✅ GraphQL `sudzSfDoubleSumMatches(debt, epsilon)`; (3) ✅ рёбра + JSON деревьев; (4) UAT якорь `106647` / `41666666.67` (DEV: ~49 `cn_inv_dbt`, 0 `DbtValue`).

**API (срез 2):** query возвращает `oldMatches` (`ags.cn_inv_dbt` по `dbt_ttl`) и `newMatches` (`sudz.DbtValue` по `dvTtl`), TOP 200, ε=0.01.

##### S68h (2026-08-24): подсказки по контрагенту на КСДСФ

**Зачем:** при многих строках в «СФ» / «Суммы» обход tree неудобен. Нужен краткий вывод: есть ли уже в домене исполнитель Excel, и **какие ключи выбрать** в таблице.

**Решения владельца:**

1. Полоса подсказок **только под колонкой «Счета-фактуры»** (не под всей правой половиной).
2. Проверка и по **старым** (`cn_inv_dbt`), и по **новым** (`DbtValue`) суммам.
3. Совпадение контрагента: **БУиРГ или ИНН** (достаточно одного); роль — `cn_s_type=2` (исполнитель).
4. При совпадениях — ключи выбора строки: `inKey` (СФ), `cidKey`/`cn_inv_dbt_key` (old), `dvKey` (new); клик выставляет selection в таблице.
5. Логика на **backend** (GraphQL), не в feQuLib и не через обход `RelationTree`.
6. Расширяемый реестр проверок v1 = один check `ctpt` в трёх зонах; позже — договор/счёт/срок и т.п.

**API:** `sudzSfDoubleHints(ciusKey, epsilon)` → `sfByNum` / `sumsOld` / `sumsNew` (`status`, `message`, `totalCount`, `items[]`).

**UI:** блок `data-test="sudz-sf-hints"` под сплиттером списка СФ и дерева (`SudzSfDoubleView`).

**Код:** BE `JdbcSudzDao.findSfDoubleHints` + `SudzGraphqlController`; FE `getSudzSfDoubleHints` / `onHintPick`. JAR ≥ **0.1.0.214**.

**Smoke API (2026-08-24, DEV):** очередь `ciusKey=13` (Excel СФ `106647`, долг `41666666.67`, БУиРГ `1000139` / ИНН `0560022871`):
- `sfByNum` = **yes** (`inKey=90880`, `matchBy=BOTH`);
- `sumsOld` = **yes** (`totalCount=18`, ключи `cidKey`);
- `sumsNew` = **no** (0 `DbtValue` на якоре — как S68s).
UAT UI: экран использован при разборе 910 (S68u); отдельный чеклист кликов не требуется.

##### S68v (2026-08-24): fill-layout feQuLib на КСДСФ

Ответ lib: feQuLib inbox `docs/agent-exchange-inbox/2026-08-24_1320_fequlib_to_femsq_fill-layout-response.md`. Prop **`fill`** (default `false`); `class="fit"` не алиас.

**Хост:**

- `SudzSfDoubleView`: `fill` на очередях/СФ/суммах (`FemsqTable`);
- `RelationTree`: `<FemsqTree fill>`; обёртка `.relation-tree-host` только задаёт высоту (`overflow: hidden`), без скролла хоста.

Master-списки без `fill` не трогали. **0012** wide H-scroll / Rslt — не этот срез.

**UAT:** вкладка «Суммы» / cn_inv_dbt — V-scrollbar, шапка видна; дерево без двойного скролла. **Подтверждено владельцем 2026-08-24.**

##### S68u (2026-08-24): UAT разбора КСДСФ, upl 910

Оператор на экране разбора частично **создал** новые СФ, частично **привязал** к существующим. После этого во вкладке «повторяющиеся СФ» лаунчера `[funnel] Дт Задолженность на 31.12.2025 (Общий свод) — UAT воронки` двоящих номеров нет.

Проверка DEV (DBHub, 2026-08-24):

| Объект | Было (S67a) | Стало |
|--------|-------------|--------|
| Excel `CnInvDbtUplTbl` | 1764 | 1764 |
| Буфер `TblCnInv` | 705 «новых» СФ, из них InvDouble=12 (`inNumCount` NOT NULL) | **693**, все `inNumCount` NULL (12 уже в домене → больше не «новые»: 705−12=693) |
| Очередь `CnInvUplSfDouble` | open-строки | **0** |
| Legacy `FileInvDouble` | — | 0 |

Rebuild очереди берёт только `inNumCount IS NOT NULL` — пустая очередь = в этом прогоне нет двоящих №. DELETE по `ciusUnloadKey` при rebuild **стирает** статусы `created` — журнал разбора в очереди не хранится.

**Важно → закрыто UAT apply (2026-08-24 14:34):** коллизии (S68u) + массовая запись однозначных СФ.

| Критерий | Результат |
|----------|-----------|
| Лог UI | «Внесено счетов-фактур (строк) в БД: **693**»; завершение 14:34:52 |
| `ags.inv` в окне 14:34:50 | **693** строк (`iTimeOfEntry`) |
| Буфер `TblCnInv` после rebuild | **0** (хвост пуст) |
| `CnInvUplSfDouble` / `FileInvDouble` | **0** / **0** |
| Выборка 5 № (`100792`→cn 419, `102689`→2501, `103069`→419, `103180`→2481, `103662`→308) | `invNum`+`cnInv` на месте |
| Excel `Tbl` 910 | 1764 (не трогали) |

За сутки `iTimeOfEntry` ≈701 (693 bulk + ранее ручные create с КСДСФ).

### S66a — AccSmpl UAT (2026-08-24)

Шаг `CnCtptInvExistAccSmplNotLoad` реален: diff + apply `ags.cnInvAccntSmpl`.
Эталон Access (дамп 2026-08-24 15:25): [`cidu-sql/`](../../../../project/proposals/vba-analysis/26-0811_CtInvDbtUpl_/cidu-sql/) —
`ciduCnCtptInvAccSmplNot` / `All` / `NotIns` / `ciduCnCtptExistInvAll`.
Anti-join Smpl: **(ciKey, account_key, БУиРГ)**; INSERT `csosKey` по номеру+БУиРГ **без даты**.
`cidutAccount` = **account_key**.

UAT 910 первый apply (2026-08-24 ~14:55) был по реконструкции (тройка с датой) — **705**.
После эталона: AccSmplNot по БУиРГ **пуст** (повторный apply = 0). DAO приведён к дампу.

| Критерий | Результат |
|----------|-----------|
| Diff до apply (upl 910) | **705** missing пар СФ+СГК |
| INSERT `cnInvAccntSmpl` | **705** (`ciasTimeOfEntry` окно apply) |
| Diff после apply | **0** |
| Excel `Tbl` 910 | 1764 (не трогали) |

### S66b — дамп `cidu*` + сверка предшествующих шагов (2026-08-24)

Снимок QueryDef: [`cidu-sql/`](../../../../project/proposals/vba-analysis/26-0811_CtInvDbtUpl_/cidu-sql/) (36 файлов, 15:25; [`DumpCiduQueryDefs.bas`](../../../../project/proposals/vba-analysis/26-0811_CtInvDbtUpl_/DumpCiduQueryDefs.bas)).

**AccSmpl vs реконструкция:** живые `ciduCnCtptInvAccSmplNot` / `All` / `NotIns` ≠ сплющенный CTE. Anti-join Smpl по **(ciKey, account_key, БУиРГ)**; INSERT `csosKey` по номеру+БУиРГ **без даты**. DAO S66a после дампа приведён к эталону. Первый apply 705 был по гипотезе с датой; хвост Access-Not после него **0**.

**Предшествующие шаги (код не меняли).** Прогон upl=910 (после apply Cn/Inv/AccSmpl):

| Метрика | Access | FEMSQ | Δ |
|---------|--------|-------|---|
| Tbl | 1764 | 1764 | 0 |
| orgNotInBuirg | 2 | 2 | 0 |
| CnNotLoad | 0 | 0 | 0 |
| ExistCtpt (живой `LEFT JOIN CnNotLoad WHERE countCnName IS NULL` vs FEMSQ `HAVING COUNT>0`) | 2 | 2 | 0 |
| ExistList | 267 | 267 | 0 |
| пары cn×СФ | 1751 | 1751 | 0 |
| InvNot missing | 0 | 0 | 0 |

Хвосты 910 (ожидаемые, не баг формул): org 1106510 / 1130174; ExistCtpt — договоры «188» и «203» у БУиРГ 1074001.

**Решение владельца (чат):** корректировка DAO org/CnNot/ExistCtpt/InvNot **нецелесообразна**. Док: живой [`ciduCnExistCtptNot.access.sql`](../../../../project/proposals/vba-analysis/access-queries/ciduCnExistCtptNot.access.sql) вместо реконструкции HAVING.

Apply Inv (`inNumCount IS NULL` vs Access «весь TblCnInv») — намеренный S68, не предмет этой сверки.

**Следующий код 0069:** **не писать**, пока нет решения S66c (куда писать идентичность долга). SQL Access `invDoubleCia` снят — см. ниже.

### S66c — шов после AccSmpl: старая vs новая воронка (2026-08-24)

**Вопрос владельца:** не сходим ли с воронки старой структуры (`cnInvAccnt` после Smpl) на воронку новой (`invDbt` / `Dbt`)?

**Ответ: да, шов именно здесь.** До AccSmpl включительно FEMSQ зеркалит Access и это **остаётся валидным** в целевой схеме (S63: pm/PrDoc на `cnInvAccntSmpl`). Следующие Access-шаги пишут **другую идентичность долга**, чем критерий задачи 0069.

| Уровень | Access (живой `btnCidufLoad`) | Целевая модель (08 / критерий 0069) | 1:1 аналог? |
|---------|-------------------------------|-------------------------------------|-------------|
| договор / сторона | `cn` / `cn_s` / smpl / org | те же `ags` | да (уже в FEMSQ) |
| СФ | `inv` / `invNum` / `cnInv` | те же `ags` | да |
| простая карточка | **`cnInvAccntSmpl`** | **та же таблица** (якорь PM) | да — **последний общий шаг** |
| идентичность долга | **`cnInvAccnt`** + костыль `ciaName` | **`Dbt` + слот `invDbt` + `invDbtDbt`** | **нет** |
| факт выгрузки | **`cn_inv_dbt`** | **`DbtValue`** (+ контекст `invDbtVar`) | **нет** |

**Имя `invDbtDouble` обманчиво.** VBA (17.01.2022) открывает QueryDef `invDoubleCia`. Живой SQL (2026-08-24):

- JOIN: `cnInvAccnt` → `cnInvAccntSmpl` → `cnInv` → `inv`
- `WHERE ciaName IS NOT NULL`, `GROUP BY i.iKey`
- **нет** `HAVING COUNT(*)>1`
- таблица **`ags.invDbt` в запросе не участвует**

То есть это диагностика **старых именованных карточек** (`cia`), свёрнутых до ключа СФ, плюс VBA `CiaNm.SumMatch` по `cn_inv_dbt`. Сообщение лога («более чем одна задолженность») **шире**, чем сам SELECT.

**`CnCtptInvExistAccNotLoad`:** `ciduCnCtptInvAccSmplExtAccNotIns` = `INSERT INTO ags_cnInvAccnt`. Комментарий VBA: «не имеющие *Задолженностей*» — в Access «задолженность» = `cnInvAccnt`, не `invDbt`.

Это тот же **разрыв S5**, уже записанный в правиле 5 оркестратора (куда писать apply). До AccSmpl писали в живой `ags` без развилки; дальше развилка обязательна.

**Решение владельца (2026-08-24, чат):** развилка **2 — сразу целевая воронка.** Access-шаги AccNot / NameCount / DbtNot / DbtExist в FEMSQ **не клонировать**. Новые stepId под `Dbt` / `invDbt*` / `DbtValue`. Перед кодом — согласовать **match без `ciaName`** (S33).

**Следующий шаг работы (не код apply):** черновик целевых stepId — **S66d** (ниже). Правило «один долг» без `ciaName` — **TBD** (владелец: пока не решать).

Файлы SQL: [`invDoubleCia.access.sql`](../../../../project/proposals/vba-analysis/access-queries/invDoubleCia.access.sql), копия в [`cidu-sql/invDoubleCia.sql`](../../../../project/proposals/vba-analysis/26-0811_CtInvDbtUpl_/cidu-sql/invDoubleCia.sql).

### S66d — черновик целевых stepId после AccSmpl (2026-08-24)

**Статус:** черновик для утверждения. **Без SQL, без кода.** Имена stepId — рабочие (можно переименовать).

**Контекст:** схема `sudz` (DEV) / цель `ags` на прод; живой `ags.cnInvAccnt` / `cn_inv_dbt` воронкой **не пишем**. Запись — в `Dbt`, `invDbt`, `invDbtDbt`, `invDbtVar`, `invDbtDbtVar`, `DbtValue` (08-target-schema).

**Открыто (TBD, не блокирует утверждение каркаса stepId):** критерий «ровно один долг» / дискриминатор вместо `ciaName` (`idNum`? 1 Smpl = 1 Dbt?). В черновике: *однозначность TBD* — при неоднозначности только лог или очередь, без auto-INSERT.

#### Карта Access → цель (роль, не клон)

| Access (не реализовывать) | Роль | Целевой stepId (черновик) |
|---------------------------|------|---------------------------|
| `invDbtDouble` | диагностика «уже несколько долгов на СФ» | `dbtAmbiguous` |
| `CnCtptInvExistAccNotLoad` | создать идентичность долга | `DbtNotLoad` |
| `ciduTbl…NameCountOneNot` | в источнике несколько имён на тройку | `srcDbtAmbiguous` |
| `CnCtptInvAccExistDbl` | отключён | — (не в UI) |
| `CnCtptInvAccExistDbtNotLoad` | факт выгрузки | `DbtValueNotLoad` |
| `CnCtptInvAccDbtExist` | diff уже загруженного | `DbtValueExist` |

#### Предлагаемый порядок после `CnCtptInvExistAccSmplNotLoad`

| # | stepId | Цель | При `flLoad` | Без `flLoad` / неоднозначность |
|---|--------|------|--------------|--------------------------------|
| A | `dbtAmbiguous` | В БД у СФ (через `inv`←Tbl) уже **>1** слота `invDbt` / связи `invDbtDbt`, и строка свода попадает на такой СФ | только лог | лог; опционально очередь (как КСДСФ) — **TBD UI** |
| B | `srcDbtAmbiguous` | В **Tbl** этой выгрузки на одну пару (СФ+СГК / Smpl) **несколько** строк-кандидатов в долг (бывш. NameCount / P2 «в источнике») | только лог | лог; auto запрещён |
| C | `DbtNotLoad` | Есть Smpl (+ сторона/контекст), **нет** связанного `Dbt`/`invDbt` по правилу match (**TBD**) | auto: `Dbt` + `invDbt` (+ `invDbtDbt`) + при необходимости `invDbtVar` / `invDbtDbtVar` | лог diff; при неоднозначности — **не** писать |
| D | `DbtValueNotLoad` | `Dbt` есть, для **этой** `upl` нет `DbtValue` | auto INSERT `DbtValue` (суммы/даты/doc из Tbl) | лог |
| E | `DbtValueExist` | `DbtValue` на эту upl уже есть | **нет** UPDATE (как Access: только показ) | построчный diff полей vs Tbl |

**Инварианты черновика:**

1. A → B → C → D → E — жёсткий префикс (как S61f).
2. Auto только при *однозначности TBD*; иначе лог (и очередь, если позже решим).
3. `ciaName` / INSERT `cnInvAccnt` / INSERT `cn_inv_dbt` — вне оркестратора 0069.
4. Stub stepId Access (`invDbtDouble`, `CnCtptInvExistAccNotLoad`, …) в UI: **скрыть или disabled** после утверждения S66d (заменить на A–E).

**Не в этом черновике:** cutover seed старых `cnInvAccnt`→`Dbt`; match-формула; экран очереди неоднозначных долгов.

**Статус S66d:** владелец не утвердил каркас (выбран «изменить»). Подход сменён на **S66e** — сначала сегменты порядка определения `invDbt`, затем stepId.

### S66e — порядок определения `invDbt` сегментами (2026-08-24)

**Решение владельца:** не утверждать stepId заранее. Фиксировать **сегменты порядка**, по которому определяется / находится / создаётся `invDbt` (и связанные `Dbt` / мосты). Когда порядок сложится — вывести шаги воронки.

**Правила ведения:**
1. Владелец передаёт сегменты по одному (текст, эскиз, правило, исключение).
2. Ассистент укладывает каждый сегмент сюда (нумерованный список) и в связанные доки при необходимости.
3. ~~Код не начинать, пока порядок недостаточен~~ — **снято 2026-08-24:** владелец подтвердил рекомендации → код v1 `invDbtVarEnsure` / `invDbtLoad`.
4. Черновик S66d A–E — справочный, не канон (заменён S66e).

**Сегменты (накопитель):**

| # | Дата | Суть | Статус |
|---|------|------|--------|
| 1 | 2026-08-24 | Зачем `invDbt`: >1 долг на один СФ в одной `cn_inv_dbt_upl`; Excel-идентификаторов мало для последующих выгрузок; искусственный ID; в старой структуре — `ciaName` | ✅ |
| 2 | 2026-08-24 | Новая структура: СФ↔`invDbt` (обычно 1); два признака «>1 долга» (текущий свод + история); обратное → спокойная загрузка, иначе тщательный разбор | ✅ |
| 3 | 2026-08-24 | «Тщательный разбор»: (а) auto-преемственность по **сумме** к старому `invDbt`; даты — мягкий плюс; (б) иначе — только оператор | ✅ |
| 4 | 2026-08-24 | После прохождения досюда: для строк Excel проверить/создать **`invDbtVar`**; запись только при «Обновлять» | ✅ |
| 5 | 2026-08-24 | Ключ Excel↔`invDbtVar` = эскиз (`accnt`+`cnNum`+`invNum`+`cn_s_org`…); GROUP BY → СФ с 1+ долгами; затем работа сегм. 1–3 → `invDbt`+`invDbtDbtVar` | ✅ |
| 6 | 2026-08-24 | Шаг 2 дробится на **2a** auto (совпадение сумм) и **2b** ручной «Разбор…» (как КСДСФ); порядок 2a↔2b **произвольный** | ✅ |
| 7 | 2026-08-24 | Показание «>1 долга»: не только **текущая** выгрузка, но и **история СФ** в **старой или новой** структуре | ✅ |
| 8 | 2026-08-24 | **Куда писать (DEV):** INSERT воронки → только **`sudz`**; `ags.invDbt` не трогать. История «>1» — читать `ags` **и** `sudz` | ✅ |
| 9 | 2026-08-24 | **Якорь СФ** = **`iKey`**; без `iKey` строка не в шагах `invDbt*` | ✅ |
| 10 | 2026-08-24 | **`idNum`:** первый слот → `1`; следующий → `MAX+1` в `sudz.invDbt` | ✅ |
| 11 | 2026-08-24 | **stepId:** `invDbtVarEnsure` + единый **`invDbtLoad`**; экран разбора по кнопке; Access-хвост disabled | ✅ |
| 12 | 2026-08-24 | **Сумма для auto:** полная ДЗ; просрочка не ключ match | ✅ |
| 13 | 2026-08-24 | **История «>1»:** multi = **OR** старый∪новый | ✅ |
| 14 | 2026-08-24 | **Очередь/экран:** `CnInvUplInvDbtDouble` + «Разбор двоящих задолженностей СФ»; уточнения в ходе работ | ✅ |
| 15 | 2026-08-24 | **`Dbt` отложен** с чекбокса 7; **`DbtValue` — уточнено сегм. 21** (раньше: Value тоже отложен) | ✅→21 |
| 16 | 2026-08-24 | **Резолв четвёрки `invDbtVar`:** INSERT только при **однозначных** 4 FK; иначе лог (→ перечень шага 2) | ✅ |
| 17 | 2026-08-24 | **`cn_s_org` до `invDbtVarEnsure`:** сверка CnNot/ExistCtpt **с датой**; отдельный чекбокс ensure **не** нужен | ✅ |
| 18 | 2026-08-25 | **M2** модель Value (без `dvDbt`) | ✅ |
| 19 | 2026-08-25 | Дорожная карта S72 A→D; **порядок пересмотрен сегм. 21** | ✅→21 |
| 20 | 2026-08-26 | **UI экрана двоящих:** каркас как КСДСФ; create+link; var на экране; плоский список; суммы old↑/new↓ + деревья; `ciaName` в old | ✅ |
| 21 | 2026-08-26 | **SoT выгрузки = `DbtValue`:** Value с экрана **и** в **calm** `invDbtLoad`; B1 до записи; A4 снят; `Dbt`/`invDbtDbt` — C1 | ✅ |
| 22 | 2026-08-26 | Экран двоящих: кейсы; **S73-grain**; счёт **11906–11907** / 10 manual | ✅ M4 |
| 23 | 2026-08-27 | Трек **S74 M1–M6**; старт **M1** (повестка Dbt D1–D7) | ✅ |
| 24 | 2026-08-27 | **M1/D1:** 1:N `Dbt`↔`invDbt` только во внешних Rslt Excel; реестр L001–L010; БД без новых | ✅ |
| 25 | 2026-08-27 | **M1/D2:** P1 после seed — тот же `Dbt` + новый слот / `invDbtDbt` (не новый `Dbt`) | ✅ |
| 26 | 2026-08-27 | **M1/D3:** cmm в том же seed (не этап 2); → **D3′** сегм. 32 | ✅ |
| 27 | 2026-08-27 | **M1/D4:** витрины Rslt — INNER на `invDbtDbt` после seed | ✅ |
| 28 | 2026-08-27 | **M1/D5:** энтропия 11907; перечень 10 `iKey` в cutover §1.2 на ручной разбор | ✅ |
| 29 | 2026-08-27 | **M1/D6:** seed `Dbt` + `dbtNote` (`S73-split` / `S73-quarter` / опц. `Rslt-L*`) | ✅ |
| 30 | 2026-08-27 | **M1/D7:** C1 — auto при однозначности, иначе очередь; seed ≠ C1 | ✅ |
| 31 | 2026-08-27 | **M1 закрыт** (D1–D7); переход к **M2** | ✅ |
| 32 | 2026-08-27 | **D3′:** cmm — ADD nullable `*Dbt`, не затирать `*InvAccnt` | ✅ |
| 33 | 2026-08-27 | **Seed invDbtVar:** `cnNum`/`invNum` по `TimeOfEntry`≤asOf (без ручной очереди) | ✅ |
| 34 | 2026-08-27 | **E1:** вся история `cn_inv_dbt` → Value; var сколько нужно для корректной загрузки | ✅ |
| 35 | 2026-08-27 | **M2 DEV seed:** пакет `26-0827-sudz-m2-seed`; counts 11907/11897/42354; L* OK; bak pre-m2-seed | ✅ |
| 36 | 2026-08-27 | **D4a:** concurrent multi-cia → доп. `invDbt` (классы A/B; 40665=migrate); E1 = cid; cutover §1.5 | ✅ |
| 37 | 2026-08-27 | **M3 Calm F1:** sum→слот (ε=0.01); 06c FK sudz upl; UAT 910: Value 1629 / f1=1 / queue ~131; JAR 225 | ✅ |
| 38 | 2026-08-27 | **M4 экран/7:** ciaName + деревья сумм + `[row.select]`; Link UAT `2446→4405`; dry 7 → queued=124; JAR 226 | ✅ |
| 39 | 2026-08-28 | **КСДД 22b:** rebuild — full DELETE upl, INSERT только `open` | ✅ |
| 40 | 2026-08-29 | **КСДД 22e:** Link/Create → `created` (как КСДСФ S68); экран все статусы, launcher — open | ✅ |
| 41 | 2026-08-30 | **КСДД 22f:** resolveByExcel; `excel_unresolved`; calm INSERT var; UI «Выбрать контекст» | ✅ |
| 42 | 2026-08-30 | **22g/B3:** регресс upl 910; open=0; D644 OK | ✅ |
| 43 | 2026-08-30 | **M5/C1:** stepId `invDbtDbtEnsure`; calm+экран `Dbt`+`invDbtDbt`; UAT 705 мостов | ✅ |
| 44 | 2026-08-31 | **Сегм. 35:** multi-Dbt P1 — три пути; `overdReduced`; исчезновение base yr→curr | ✅ решения |
| 45 | 2026-08-31 | **Сегм. 36/C2:** `dbtValueLoad` + `CnInvUplDbtP1`; DDL DEV | ✅ код |

**Код v1 (2026-08-24, после подтверждения владельца):** реализованы `invDbtVarEnsure` + `invDbtLoad` (DAO/оркестратор/логи), DDL `sudz.CnInvUplInvDbtDouble`, stub экрана `sudz-inv-dbt-double`, Access-хвост disabled. Auto load = calm path (без sum-match multi). **2026-08-25:** на лаунчере отдельная вкладка «двоящие долги СФ» (очередь `invDbtDoubles` рядом с «повторяющиеся СФ»). Следующее: **UAT upl 910** (dry → flLoad), затем наполнение экрана разбора.

**Сегмент 1 (текст владельца, 2026-08-24):**

Потребность в **`invDbt`** возникла из того, что у **одного СФ** в **одной** выгрузке (`cn_inv_dbt_upl`) может быть **более одной** задолженности/долга. Тогда для идентификации **одной из** таких задолженностей в **последующих** выгрузках **недостаточно** идентификаторов, изначально имеющихся в Excel выгрузки/свода. Потребовался **искусственный** идентификатор. В **старой** структуре данных эту роль играло поле **`ciaName`**.

Сегмент задаёт **причину** слоя (P2 + стабильность выбора долга между выгрузками), не алгоритм поиска/создания `invDbt` и не состав целевых stepId.

**Сверка с уже задокументированным — противоречий нет.**

| Документ | Положение | Отношение к сегменту 1 |
|----------|-----------|------------------------|
| [04-3 P2](../../domain/sudz/04-3_problems-solutions.md#p2--несколько-задолженностей-у-одного-документа-основания-в-одной-выгрузке) | Несколько ДЗ на один документ основания в одной выгрузке; `ciaName` — костыль, **причина появления `invDbt`** | **Совпадает** |
| 04-3 P2 / S10 | Живой квартальный контур шёл через `cnInvAccnt`+`ciaName`+`cn_inv_dbt`; таблица `ags.invDbt` залита разово, `invDbtValue` пуст | **Не противоречит:** сегмент про **потребность/роль**, не про то, что Access сейчас пишет в `invDbt` |
| S33 / 08-target-schema | `ciaName` **не** в целевой схеме (не прообраз `invDbtVar`) | **Не противоречит:** сегмент относит `ciaName` к **старой** структуре |
| S66c | VBA `invDbtDouble` / QueryDef `invDoubleCia` читают `cnInvAccnt.ciaName`, не таблицу `invDbt` | **Не противоречит:** имя шага vs фактический дискриминатор — та же старая роль `ciaName` |
| P1 (осцилляция СФ между выгрузками) | Другой класс: меняется сам документ-основание | **Не покрыт** сегментом 1 и **не отрицается**; сегмент про множественность долгов на **том же** СФ в пакете |

**Не смешивать (уже в доках, сегмент 1 не меняет):** целевой стабильный ID долга — сущность **`Dbt`**; слот на СФ — **`invDbt`**; `idNum` в цели — отдельная тема 08 / S16, в этом сегменте не утверждается. Статусная фраза в 04-3 P2 («`idNum` в новой структуре не переносится») расходится с 08 (`UNIQUE(idInv,idNum)` на слоте) — **давний зазор документов**, не введён сегментом 1, здесь не правится.

**Сегмент 2 (текст владельца, 2026-08-24):**

В **новой** структуре данных у **каждого** СФ из Excel есть **соответствующая** запись в **`invDbt`**. Ситуация «у СФ более одного долга» **редка**, поэтому у подавляющего числа СФ в `invDbt` будет **одна** запись.

Самый простой способ увидеть «более одного долга» у СФ — **число строк Excel при группировке по СФ > 1**. Этого **недостаточно** как единственного критерия: СФ мог иметь **более одного** долга в **предшествующих** выгрузках, к моменту новой выгрузки часть погашена, и в свод попал **только один** долг.

**Показания** к тому, что у СФ долгов **более одного** (как минимум два):

1. наличие более одного долга **в загружаемой** выгрузке/своде;
2. наличие более одного долга **в истории** этого СФ.

**Обратное (ценное):** если у СФ **нет** более одного долга в загружаемой выгрузке **и** такого **не было** в истории → долг **один**, его можно **спокойно грузить** в БД. Иначе — **более тщательное рассмотрение**.

Сегмент задаёт **правило ветвления** (спокойная загрузка vs разбор), не физический источник «истории» и не stepId.

**Сверка с уже задокументированным — противоречий нет.**

| Документ | Положение | Отношение к сегменту 2 |
|----------|-----------|------------------------|
| Сегмент 1 / P2 | >1 долг на СФ в одной выгрузке — редкий, но реальный класс | **Совпадает** (редкость + критерий «в текущем своде») |
| 08 / S16 | `invDbt` = слот(ы) на `Inv`, `UNIQUE(idInv, idNum)`; N слотов на один СФ допустимы | **Совпадает** (обычно один слот; редко больше) |
| S61f / 04 §2.7 | Auto только при однозначности; иначе лог / оператор | **Совпадает** с «спокойно грузить» vs «тщательное рассмотрение» |
| S66d A/B (черновик) | Раздельные сигналы: неоднозначность в БД / в источнике | **Согласуется по смыслу** (история ≈ БД; текущий свод ≈ Excel); каркас stepId по-прежнему не канон |
| S30 «новые строки `invDbt` при каждой загрузке» | Оживление записи в таблицу после заморозки 2022 | **Не противоречит**, если читать так: новые **слоты** при появлении долгов / продолжение записи в контур; **факт выгрузки** — `DbtValue` (`UNIQUE(dvInvDbt, dvUpl)` после S71; ранее ошибочно писали `UNIQUE(dvDbt, dvUpl)`), а не новая строка `invDbt` на каждую upl для того же единственного долга. Иная буквальная трактовка S30 (новый `invDbt` на каждую выгрузку при одном долге) **расходилась бы** с «одна запись» и с 08 — сегмент 2 и 08 здесь согласованы |
| P1 | Смена документа-основания между выгрузками | **Не покрыт** (история «того же СФ» предполагает тот же `inv`; при P1 якорь истории — отдельная тема) |

**Не утверждается сегментом 2 (осознанно открыто):** ~~точное определение «СФ» для GROUP BY~~ — **закрыто сегментом 9** (`iKey`). Источник «истории >1 долга» — **сегмент 7**.

**Сегмент 3 (текст владельца, 2026-08-24):**

Ветка сегмента 2 «**тщательный разбор**» (есть >1 долга в текущем своде **и/или** в истории) делится на **две** части.

**Часть 1 — подлежащая автоматизации.** В этой ситуации **единственный** идентификатор, позволяющий установить **преемственность** долга между выгрузками, — **сумма долга**. Если суммы **совпадают**, долг в новой выгрузке **может быть привязан** к `invDbt` старых выгрузок **автоматически**. Даты возникновения и погашения **полезно** сверить: совпадение — хороший дополнительный сигнал, но они **не** могут **однозначно подтвердить** и **не** могут **опровергнуть** преемственность, потому что **меняются со временем** (например, из‑за допсоглашений).

**Часть 2 — всё, что не входит в часть 1.** Решение «это **старый** долг или **новый**» принимает **только оператор**.

Сегмент уточняет **внутренность** ветки «тщательный разбор», не отменяет спокойную загрузку сегмента 2 и не задаёт stepId.

**Сверка с уже задокументированным — противоречий нет.**

| Документ | Положение | Отношение к сегменту 3 |
|----------|-----------|------------------------|
| Сегмент 1 / S33 | `ciaName` — старый костыль; в цели нет | **Совпадает:** в новой ветке разбора дискриминатор преемственности — **сумма**, не `ciaName` |
| S29 `CiaNm.SumMatch` | Access: `(inv, ciaName, dbt_ttl)` точное совпадение суммы | **Не противоречит:** сумма как жёсткий ключ match — тот же принцип; `ciaName` в Access был вторым дискриминатором старого контура, в сегменте 3 для **новой** структуры не используется |
| 04 §2.7 / S61f | Auto только при однозначности; иначе оператор | **Совпадает** (часть 1 = однозначное совпадение суммы; часть 2 = оператор) |
| Наблюдение M9 (S7, Rslt) | «сумма + договор + дата» глазами | **Не противоречит:** сегмент 3 сужает **авто**-правило для ветки P2-разбора до суммы (+даты мягко); договор/СФ здесь уже в контексте сопоставленного СФ/`invDbt` |
| Даты договора / допсоглашения (модель `cn_s_org` periods и др.) | Реквизиты меняются во времени | **Совпадает** с тем, что даты долга не жёсткий verdict |

**Уточнение владельца (2026-08-24, к открытым пунктам сегмента 3):** если **нет однозначной** идентификации — в том числе **несколько кандидатов с одной суммой** — ситуация на **разбор оператора** (часть 2). То же относится к случаям, когда без однозначности нельзя решить, писать ли сразу `DbtValue` / какое поле суммы даёт единственный match: нет однозначности → оператор, не auto.

**Поле суммы для auto (часть 1):** ~~открыто надолго~~ — **рабочая договорённость сегмент 12** (полная сумма; просрочка не ключ). Долгое сосуществование старого/нового контура остаётся, но критерий match зафиксирован.

**Сегмент 12 — сумма для auto (владелец, 2026-08-24):**

Вариант **1:** ключ совпадения — **полная сумма задолженности**: Excel «Всего сумма…» / буфер **`cidutDebt`** ↔ старое **`cn_inv_dbt.dbt_ttl`** ↔ новое поле величины «всего» на **`DbtValue`** (когда пишется). **Просроченная** сумма в auto-match **не** участвует (может логироваться как мягкий плюс рядом с датами, сегмент 3).

**Сверка:** согласуется с Access `SumMatch` (`dbt_ttl`) и сегментом 3.

**Сегмент 4 (текст владельца, 2026-08-24):**

Для **всех** записей Excel, **прошедших по воронке до этого места**, нужно **проверить** наличие **соответствующих** записей в **`invDbtVar`**. Если их **нет** — **создать**. Запись в БД — как обычно, только при включённом переключателе **«Обновлять»** (`cidufFlLoad`).

Сегмент задаёт **обеспечение** контекстного снимка (`invDbtVar`) для строк, дошедших до этого места; ключ соответствия и связь с созданием `invDbt`/`invDbtDbtVar` — **сегмент 5**.

**Сверка с уже задокументированным — противоречий нет.**

| Документ | Положение | Отношение к сегменту 4 |
|----------|-----------|------------------------|
| S32 / 04-3 §7.9 | `invDbtVar` — снимок контекста; для новых выгрузок создаётся «на лету» при новом сочетании атрибутов | **Совпадает** |
| 08 `UX_invDbtVar_Context` | UNIQUE `(cnNum, invNum, accnt, cn_s_org)` — тот же контекст не плодим | **Совпадает** с «проверить → создать если нет» |
| S33 | `ciaName` ≠ `invDbtVar` | **Не затрагивается** |
| S61f / Access «Обновлять» | `cidufFlLoad`: diff всегда, INSERT только при флаге | **Совпадает** |

**Открытое сегмента 4 закрыто сегментом 5** (ключ; `invDbt`+`invDbtDbtVar` после работы 1–3). Строки, ждущие оператора, по-прежнему не в «прошедших».

**Сегмент 5 (текст владельца, 2026-08-24):**

Точный ключ **«соответствия» Excel ↔ `invDbtVar`** **задаётся эскизом**. В `invDbtVar` входят:

- **счёт главной книги** — из `accnt`;
- **№ договора** — из `cnNum`;
- **№ СФ** — из `invNum`;
- **1. Контрагент, 2. ИНН, 3. № контрагента, 4. Дата договора** — из `cn_s_org` и **однозначно** связанных с нею таблиц.

Если **сгруппировать** таблицу Excel по `invDbtVar` (по этому ключу), получаются СФ, имеющие **одну или более** задолженностей/долгов — то, с чего начались рассуждения сеанса (сегменты 1–2). После этого остаётся провести работу, описанную в **предшествующих** сегментах (1–3), и **на её основе** создать **`invDbt`** и **`invDbtDbtVar`**.

**Уточнение порядка относительно формулировки сегмента 4:** контекст/`invDbtVar` (ключ эскиза, ensure при «Обновлять») — ось группировки Excel; ветки однозначности/суммы/оператора (1–3) — поверх групп; слот `invDbt` и мост `invDbtDbtVar` — **результат** этой работы, не предпосылка ключа.

**Сверка с уже задокументированным — противоречий нет.**

| Документ | Положение | Отношение к сегменту 5 |
|----------|-----------|------------------------|
| Эскиз [`26-0824-…dbtvar.png`](../../domain/sudz/assets/26-0824-sudz-target-sketch-dbtvar.png) | `invDbtVar` ← `accnt`/`cnNum`/`invNum`/`cn_s_org`; подпись про контрагента/ИНН/№/дату | **Совпадает** |
| 08 §2.3 | FK только на четвёрку; UNIQUE той же четвёрки | **Совпадает** (реквизиты 1–4 не отдельные колонки `invDbtVar`, а через `cn_s_org`+связанные) |
| S32 / эскиз подписи | один вариант именования у нескольких «долгов СФ»; в разных выгрузках один слот под разными вариантами | **Согласуется** с GROUP BY по варианту → группы долгов на СФ |
| 08 `invDbtDbtVar` | мост `invDbt` ↔ `invDbtVar` | **Совпадает** с «создать … и `invDbtDbtVar`» после работы 1–3 |
| Сегменты 1–3 | зачем слот; 1 vs >1; auto по сумме / оператор | **Совпадает** как работа «поверх» групп Excel по ключу `invDbtVar` |

**Не утверждается сегментом 5:** момент INSERT `Dbt` / `DbtValue` — **закрыто сегментом 15** (отложено).

### Два шага создания слоя `invDbt` (сводка сегментов 1–5) — подтверждено 2026-08-24

Формулировка владельца: создание раскладывается на **два** шага.

| # | Шаг | Суть | Сегменты | «Обновлять» |
|---|-----|------|----------|-------------|
| **1** | **`invDbtVarEnsure`** | актуализация `invDbtVar` по ключу эскиза | **4** + **5** | да (`cidufFlLoad`) |
| **2** | **`invDbtLoad`** (один чекбокс) | лог + перечень на ручной разбор; при `flLoad` — auto однозначных; экран «Разбор двоящих задолженностей СФ». Показания «>1»: текущая + история (**7**). Писать в **`sudz`** (**8**). Якорь **`iKey`** (**9**). `idNum` **10** | **5–11** | да |

**Проверка согласованности — да, противоречий нет.**

1. **Порядок обязателен:** `invDbtDbtVar` ссылается на оба конца; без актуального `invDbtVar` мост невозможен. Сегмент 5 уже фиксирует: контекст — ось, слот/мост — результат.
2. **Разделение ролей:** шаг 1 не различает долги внутри СФ (UNIQUE четвёрки контекста); шаг 2 как раз решает преемственность/множественность (замена роли `ciaName`).
3. **По старым данным:** группы `(inv, accnt, cn_s_org)` с **>1** named-карточкой — **15** (нужен шаг 2); у **всех** 12 536 unnamed-карточек в такой группе ровно **одна** карточка (`gt1=0`) — после шага 1 шаг 2 для массы строк однозначен («спокойно грузить», сегмент 2).
4. **`Dbt`/`DbtValue`:** не в этом этапе (**сегмент 15**); только слот/вариант/мост варианта.

**Сегмент 6 (текст владельца, 2026-08-24):**

Шаг **2** целесообразно разбить **по примеру «СФ с двоящими номерами» (КСДСФ)** на **два вложенных** шага. **Последовательность между ними может быть произвольной.**

| Вложенный | Суть | Аналог КСДСФ |
|-----------|------|----------------|
| **2a** | **Автоматизированное** создание `invDbt` / `invDbtDbtVar` при **совпадении сумм** (сегмент 3, часть 1) | bulk apply однозначных СФ (`inNumCount IS NULL`) |
| **2b** | **Ручная** работа со **списком кандидатов** и экраном типа **«Разбор …»** (сегмент 3, часть 2: нет однозначности) | очередь `CnInvUplSfDouble` + экран КСДСФ |

**Сверка — противоречий нет.**

| Документ | Положение | Отношение |
|----------|-----------|-----------|
| Сегмент 3 | auto по сумме vs только оператор | **Совпадает** с 2a / 2b |
| S68 / UAT 910 | коллизии СФ → отдельный экран; однозначные — apply воронки; порядок разбора и apply совместим | **Совпадает** (паттерн «очередь + экран» + произвольность порядка относительно auto) |
| S61f | неоднозначность — не решать за оператора | **Совпадает** с 2b |
| Проверка `ciaName` | дубли сумм / смена суммы | **Согласуется:** 2a не покрывает всё; остаток — 2b |

**Уточнения (не противоречие):**

- «Спокойная» загрузка при **ровно одном** долге без истории multi (сегмент 2, обратное) — тоже **авто**, по смыслу рядом с **2a** (не экран Разбор); владелец в сегменте 6 явно назвал auto-критерий «совпадение сумм» для ветки тщательного разбора — однодолёвый случай остаётся auto вне 2b.
- Жёсткий порядок **шаг 1 → шаг 2** сохраняется; произвольность — только **2a ↔ 2b**.
- Имя экрана / очередь / stepId — TBD (как `SudzSfDoubleView`, не клон кода).

**Уточнение сегмента 6 → сегмент 11 (владелец, 2026-08-24):** вложенные **2a/2b** — **не** два чекбокса воронки. Шаг **2** в панели — **один** чекбокс (`invDbtLoad`). Логика как у «двоящих номеров СФ»:

| `cidufFlLoad` | Поведение при проходе чекбокса шага 2 |
|---------------|----------------------------------------|
| **выкл** | Только **лог** + формирование **таблицы/очереди** позиций, требующих ручной обработки. **БД не меняется.** |
| **вкл** | В БД вносятся позиции, которые можно закрыть **без** ручного разбора (алгоритм: один долг / совпадение сумм = бывш. 2a). Остальные остаются в перечне на ручную обработку. |

Кнопка у таблицы перечня → экран, напр. **«Разбор двоящих задолженностей СФ»**, где оператор вручную создаёт `invDbt`/`invDbtDbtVar` (бывш. 2b). Порядок auto vs ручной разбор на экране — как у КСДСФ (произвольный относительно момента apply однозначных).

**Сегмент 11 — stepId (владелец, 2026-08-24):**

После `CnCtptInvExistAccSmplNotLoad` в enabled-цепочке:

| stepId | Роль |
|--------|------|
| `invDbtVarEnsure` | шаг **1**: актуализация `invDbtVar` |
| `invDbtLoad` | шаг **2** (**один** чекбокс): лог + перечень кандидатов; при `flLoad` — auto INSERT однозначных `invDbt`/`invDbtDbtVar` |

Access-stub’ы (`invDbtDouble`, `CnCtptInvExistAccNotLoad`, `ciduTbl…NameCount…`, `CnCtptInvAccExistDbl`, `…DbtNotLoad`, `…DbtExist`) — **disabled / убрать** из enabled (или оставить disabled до снятия). Экран ручного разбора — **не** отдельный stepId в панели (как КСДСФ не чекбокс воронки).

**Сверка:** совпадает с паттерном S66+S68 (Inv apply + очередь/экран). Уточняет сегмент 6 без отмены auto/manual по сути.

**Сегмент 14 — очередь и экран разбора (владелец, 2026-08-24):**

Вариант **1 (каркас):** по аналогии с КСДСФ (`CnInvUplSfDouble`):

- таблица очереди **`sudz.CnInvUplInvDbtDouble`** (префикс колонок, напр. `ciud*`);
- rebuild при проходе **`invDbtLoad`**: позиции, не закрытые auto;
- экран **«Разбор двоящих задолженностей СФ»** (маршрут вроде `sudz-inv-dbt-double`); вход — кнопка у перечня на лаунчере;
- create/link `invDbt`/`invDbtDbtVar` вручную на экране.

Дело новое — **уточнения колонок/UI/статусов неизбежны в ходе работ**; каркас не запрещает правки без смены сегментов 1–13.

**Сверка:** зеркало S68; согласуется с сегментом 11 (один чекбокс + экран не stepId).

**Сегмент 15 — Dbt отложен; Value уточнён сегм. 21 (владелец, 2026-08-24; S71 2026-08-25; поправка 2026-08-26):**

Исходный вариант **1:** этап после AccSmpl пишет только **`invDbtVar` / `invDbt` / `invDbtDbtVar`** (+ очередь); **`Dbt`**, **`invDbtDbt`**, **`DbtValue`** — не смешивать с `invDbtLoad`.

**Поправка сегм. 21:** **`Dbt` / `invDbtDbt` по-прежнему не на чекбоксе 7.** **`DbtValue` пишется** в calm `invDbtLoad` и на экране двоящих (после B1 M2 DDL). SoT «Excel учтён в этой upl» = наличие `DbtValue`.

**S71 / M2:** у `DbtValue` **нет** `dvDbt`; якорь = `invDbt`. Физический DDL с `dvDbt` — **B1** (пререквизит записи Value).

**Сегмент 18 — модель Value (владелец, 2026-08-25):**

Утверждено **M2** (отклонены M1 с `dvDbt` и M3 с якорем `invDbtDbt`):

| | |
|--|--|
| Зерно | `UNIQUE(dvInvDbt, dvUpl)` |
| FK | `dvInvDbt`, `dvInvDbtVar`, `dvUpl` — **без** `dvDbt` |
| Отчётный `dbtKey` | join `invDbt` → `invDbtDbt` → `Dbt` |
| Документы | [04-3 §10](../../domain/sudz/04-3_problems-solutions.md#10-dbtvalue-без-прямого-fk-на-dbt-m2--s71), [08 §2.5](../../domain/sudz/08-target-schema.md) |

**Сверка:** эскиз `26-0824`; S32 текст; P2; обязательность `Dbt` в модели сохранена.

**Сегмент 19 — дорожная карта (владелец, 2026-08-25; порядок пересмотрен сегм. 21, 2026-08-26):**

Исходно: A1→A3→A2→A4→B→C. **Актуально:** см. [S72](#s72--дорожная-карта-реализации-слоя-i--m2--канон-2026-08-25) и **сегмент 21**.

**Сегмент 20 — UI экрана «Разбор двоящих задолженностей СФ» (владелец, 2026-08-26):**

| # | Решение |
|---|---------|
| Каркас | Как КСДСФ: слева очередь + Excel; справа слоты/`RelationTree` + суммы |
| Действия | **Create** нового `invDbt` + мост; **Link** к выбранному слоту; при необходимости create **`invDbtVar`** (ambiguous) |
| Цель разбора | Довести строку до слоя I **и** `DbtValue` на текущий `upl` (сегм. 21) — без `Dbt`/`invDbtDbt` |
| Список | Плоский; сортировка по `iKey` |
| Суммы | Панель **нужна**; сверху **старая** (`cn_inv_dbt`, явно **`ciaName`**), снизу **новая** (`invDbt` / позже Value); в каждой половине **таблица + дерево** |
| SoT «не в open» | = наличие `DbtValue` на upl (не суррогат A4) |

**Сегмент 21 — `DbtValue` в calm и на экране (владелец, 2026-08-26):**

Утверждено:

1. **SoT «Excel учтён в текущей выгрузке»** = строка **`DbtValue`** (`dvInvDbt`, `dvInvDbtVar`, `dvUpl`, величины из Tbl) — аналог факта `cn_inv_dbt` на upl.
2. **`DbtValue` пишется симметрично:**
   - **calm auto** при `invDbtLoad` + `flLoad` (после слота + `invDbtDbtVar`);
   - **экран двоящих** при create/link (и create var при необходимости).
3. **`Dbt` / `invDbtDbt` на 7-м чекбоксе и на экране двоящих — не писать** (остаются C1).
4. **Пререквизит:** **B1-prep** → **B1** (DDL M2) — **до** любой записи Value в воронке. **B1 на DEV выполнен 2026-08-26** (`dvInvDbt`, без `dvDbt`).
5. **A4** как отдельный SoT слоя I — **снят**; rebuild open: не класть позиции, у которых уже есть `DbtValue` на эту upl.
6. **C2** (`DbtValueLoad`) сжимается до skip / Exist / diff / догон хвостов; **C3** «учтено» опирается на уже существующий Value + путь к `Dbt` после C1.
7. **2026-08-26:** перед B1 — подпункт **B1-prep** в [S72](#s72--дорожная-карта-реализации-слоя-i--m2--канон-2026-08-25) (инвентарь, baseline, черновики SQL/кода, гейт GO).

**Сверка:** M2 / сегм. 18; поправка сегм. 15; не противоречит обязательности `Dbt` в модели (канон позже).

**Сегмент 22 — процесс работы оператора на экране двоящих (владелец, 2026-08-26):**

**Статус:** ✅ закрыт по UI (M4 2026-08-27): `ciaName`, деревья сумм, `[row.select]`, регламент Link по уникальной сумме; UAT Link `2446→4405`. Defer/bulk — вне scope.

**Принято сейчас:**
1. Тексты `[queue.build]` — **человекочитаемые** (коды в скобках).
2. Create «вслепую» / блок UI / массовый ETL — **не фиксируем**, пока не разобраны судьбы нескольких строк вручную (здесь в чате).
3. Smoke Create по `iKey=329` / slot **10130** — **откатан** (Value+мост+слот удалены; очередь снова `open`).
4. **S73 — зерно старого долга:** `(iKey, ciaNameNull) ≈ (idInv, idNum)`; СГК **не** в ключе (0 concurrent multi-acc); оценка числа долгов **11 906–11 907**, из них **10** ручных (`9` сплит + `4480`). Док: [04-4](../../domain/sudz/04-4_legacy-debt-grain.md).
5. **Cutover (v0.2 → S74):** мероприятия **M1–M6** — см. [S74](#s74--трек-cutover-m1m6--2026-08-27). Док: [db-upgrade-sudz-invdbt-cutover.md](../../../../deployment/db-upgrade-sudz-invdbt-cutover.md).
6. **M4 UI:** old sums показывают **`ciaName`**; панели сумм — таблица+дерево; live `[row.select]`; регламент — [M4_SCREEN.md](../../../sql/26-0827-sudz-m2-seed/M4_SCREEN.md).

**Кейсы для разбора (очередь 910):** `329` (multi, сумма вне истории → ручной выбор); `12032` (7 Excel↔слот по сумме — Link smoke `2446→4405`); ambiguous без var → Create var. *После M2 seed приоритет — new.*

**Сверка:** сегм. 20/21; P2 / `ciaName`; S73-grain; S74 M4.

**Сегмент 22b — КСДД: очередь rebuild (владелец, 2026-08-28):**

**Статус:** ✅ код + UI · Link/Create уточнён в **22e**

| # | Решение |
|---|---------|
| Имя | **КСДД** — компонент сличения двоящих долгов (аналог КСДСФ) |
| Rebuild | `DELETE` **все** строки upl; `INSERT` только `open` (Excel∩домен, без Value на upl) |
| SoT | `DbtValue` на upl |

**Сегмент 22e — КСДД: Link/Create → `created` как КСДСФ (2026-08-29):**

**Статус:** ✅ код

| # | Решение |
|---|---------|
| Link / Create слота | `UPDATE ciudStatus='created'`, `ciudCreatedIdKey`=слот; **не** DELETE |
| Очередь на экране | все статусы; кнопки только `open` |
| Launcher | бейдж «к разбору» = только `open` |
| Сверка | S68 п.4 — статус до следующего прогона загрузки/свода |

Док: [KSDD_QUEUE.md](../../../sql/26-0827-sudz-m2-seed/KSDD_QUEUE.md).

**Сегмент 22c — КСДД: советник + динамика слота (владелец, 2026-08-28):**

**Статус:** ✅ код (JAR после сборки)

| # | Решение |
|---|---------|
| Советник | GraphQL `sudzInvDbtDoubleAdvice` → `[advisor]` в «Сообщения» (F1, accnt, амортизация) |
| Динамика | вкладка по **выбранному** слоту; `sudzInvDbtSlotTimeline` |
| Графики | **FemsqChart** (feQuLib, ECharts 5); ADR [010](../../../../project/decisions/010-chart-platform-echarts.md) |
| PDF | Jasper позже; общий SQL с timeline |

Док: [KSDD_ADVISOR.md](../../../sql/26-0827-sudz-m2-seed/KSDD_ADVISOR.md).

**Сегмент 22d — relationQuery: контекст invDbtVar в дереве (2026-08-28):**

**Статус:** ✅ код

| # | Решение |
|---|---------|
| API | GraphQL `relationQuery(queryId, fromId)`; реестр `RelationQueryCatalog` (Java) |
| JSON | `inv-dbt-slots.tree.json` v3: `contextBySlot` (+ дата стороны); `DbtValue` вложен под var (`bySlotVarBridge`, имя/дата свода) |
| Безопасность | только whitelist SELECT; SQL не с клиента; TOP 50, timeout 5 с |
| ADR | [011-relation-query-registry.md](../../../../project/decisions/011-relation-query-registry.md) |

**Сверка:** ADR 009 (walker); сегм. 22c (bridge_ready в дереве).

**Сегмент 22f — КСДД: resolveByExcel, calm-excel (2026-08-30):**

**Статус:** ✅ код

| # | Решение |
|---|---------|
| ensure CTE | `cnnKey`/`invNumKey` по совпадению `cidutCnNameNull`/`cidutCnInvNull` с `ags.cnNum`/`ags.invNum` (OUTER APPLY), не `cnnUnique`/`inUnique` |
| Очередь | ложный `ambiguous` → **`excel_unresolved`** (0 или >1 match по тексту Excel); настоящий **`multi`** без изменений |
| calm | `applyDbtUplInvDbtLoadUnambiguous`: INSERT missing `invDbtVar` перед слотами; ~118 строк upl 910 → auto без KSDD |
| UI | кнопка **«Выбрать контекст»**; reason `excel` в гриде |
| ags | санитария **не** нужна — Excel остаётся SoT для выбора FK |

Док: [KSDD_QUEUE.md](../../../sql/26-0827-sudz-m2-seed/KSDD_QUEUE.md).

**Сегмент 22g — КСДД: закрытие UAT + B3 (2026-08-30):**

**Статус:** ✅

| # | Результат |
|---|-----------|
| upl 910 open | **0** после 22f calm |
| D644 REST | HTTP 200 |
| Док | [B3_SMOKE_22g.md](../../../sql/26-0827-sudz-m2-seed/B3_SMOKE_22g.md) |

**Сегмент 23/C1 — M5: `invDbtDbtEnsure` (2026-08-30):**

**Статус:** ✅ код

| # | Решение |
|---|---------|
| stepId | **`invDbtDbtEnsure`** после `invDbtLoad` |
| calm | F1 reuse → тот же `Dbt` (**D2**); иначе без sibling-моста → новый `Dbt` (**D7**); sibling без F1 → ambiguous (лог) |
| экран | Create/Link: `ensureInvDbtDbtBridgeForSlot` после `DbtValue` |
| UAT 910 | **705** новых `Dbt`+мостов; missing=**0** |

**Сегмент 35 — multi-Dbt (P1): три пути, UI канона, `overdReduced` (владелец, 2026-08-31):**

**Статус:** ✅ решения зафиксированы · **C2 код** сегм. 36

| # | Решение |
|---|---------|
| Задача | Один **`Dbt`** → несколько **`invDbt`** (разные `iKey`); не путать с КСДД (P2) |
| Суть P1 | **Исчезновение** `Dbt` на curr относительно base (нет Value на слоте), не «уменьшение суммы» |
| Путь **1** | Исторический: cross-iKey sum-match, L* (D1/D2) |
| Путь **2** | Base **`yr.cn_inv_dbt_upl`** → curr; исчезнувшие `Dbt` + sum-match `cidutDebt` из `overdReduced`/base; очередь P1 (C2) |
| Путь **2b** | Q↔Q исчезновение — **фаза 2** (по потребности) |
| Путь **3** | UI rebind (0071 + экран `Dbt`); полный случай |
| Sum-match | Полная сумма; **все** совпадения; без жёсткого фильтра cn/контрагент |
| Auto cross-iKey | **Отложено** — по опыту UI (аналог calm КСДД) |
| Retrofix 910 | **Отложено** |
| Именование | Excel/UI: **«погашено»**; код: **`overdReduced`** ✅ |
| Док | [04-6_multi-dbt-p1-three-paths.md](../../domain/sudz/04-6_multi-dbt-p1-three-paths.md) |

**Сверка:** сегм. 24–25 (D1/D2); 23/C1 (default 1:1); C2 next; 0071; V10.

**Сегмент 23 — трек cutover и возврат к воронке (владелец, 2026-08-27):**

Принят порядок **S74 M1→M6**. Экран двоящих / чекбокс 7 **не** развиваем массово до **M2** (DEV seed с `Dbt`). Сначала **M1** — решения по `Dbt` без UI.

**Сверка:** cutover v0.2; сегм. 21 (Value в потоке ≠ отсутствие `Dbt` в seed).

**Сегмент 24 — M1/D1: кардинальность `Dbt`↔`invDbt` и внешний Excel (владелец, 2026-08-27):**

**Проблема:** в выгрузке **нет** формальных признаков отнести несколько `invDbt` к одному `Dbt`. В старой БД связь **не отражена**; на практике чинили **вручную в Excel** `ags_Yr_DbtChangesRslt_*` (вне Access): «погашенный» без продолжателя → замечание специалистов → находят тот же долг на **другом СФ** (часто по сумме) → перенос колонок квартала (в т.ч. № СФ) в строку старого долга, удаление новой строки → контроль равенством суммы по выгрузке.

**Следствие:** следы 1:N сохранились **только во внешних Rslt**; для cutover нужен **разбор Excel** + реестр связей (находки на DEV сохранять для prod).

**Песочница:** `test_sudz` (S34+) · seed `09_SEED_dbt_82_85_Q4Q1Q2.sql` · разбор [04-2](../../domain/sudz/04-2_example-rslt-82-85.md) · источник `ags_Yr_DbtChangesRslt_26-0505.xlsx` · выходы FEMSQ: `excel/2026-06/debit/test/`. В БД: **`Dbt` 85 → слоты на `iKey` 12032 и 20505** (1:N); **82** — 1:1. Строки Excel 84–95 — в основном **P2** на зонтике; эталон P1 — **стр. 85**.

**Документ:** [04-5_dbt-invdbt-cardinality-d1.md](../../domain/sudz/04-5_dbt-invdbt-cardinality-d1.md) (реестр **L001–L010** по кол. T файла `26-0505`; за вычетом 85/91 при расширении — 9 новых + эталон 85).

**Сверка:** P1; S7/04-2; S16 `invDbtDbt`; S74 M1; **снимает** наивное «всегда 1 `Dbt` = 1 слот без Excel». **D1 закрыт** (реестр L001–L010 достаточен для канона seed; доп. Rslt — не блокер).

**Сегмент 25 — M1/D2: P1 после cutover (владелец, 2026-08-27):**

**Утверждено:** при P1 после seed — **тот же `Dbt` + новый `invDbt` + `invDbtDbt`** (calm F1 / сумма 2a / экран 2b·M4). **Новый `Dbt`** — только действительно новый долг (**D7/C1**), не смена СФ. Три пути и UI rebind — **сегм. 35**.

**Сверка:** D1 / 04-5; сегм. 35; S16 красный путь; сегм. 3/6 (2a/2b); M3–M4 — механизм, D2 — семантика.

**Сегмент 26 — M1/D3: перенос мероприятий cmm (владелец, 2026-08-27):**

**Утверждено (исходная формулировка):** перенос якоря cmm на `dbtKey` **в том же seed (M2)**; не отдельный этап 2.  
**Уточнение D3′ (сегм. 32):** механика — **ADD** колонок, не rewrite `*InvAccnt`.

**Сверка:** cutover v0.2; 08 зеркала cmm; R7 → D3′.

**Сегмент 27 — M1/D4: витрины Rslt / `dbtKey` (владелец, 2026-08-27):**

**Утверждено:** целевые витрины после seed — **INNER** на `invDbtDbt` для `dbtKey`. Слот без моста = дефект VERIFY. Dual-read / старый `ags.Yr_DbtChanges` — отдельно; 1:N → одна строка на `dbtKey`.

**Сверка:** 08 §2.5/3.5; D1–D3; фаза I.

**Сегмент 28 — M1/D5: 10 manual / N≈11907 (владелец, 2026-08-27):**

**Утверждено:** seed с **энтропией вверх → 11 907**; разбор 10 кейсов **не** блокирует M2.  
**Перечень зафиксирован** для последующего ручного разбора: [cutover §1.2](../../../../deployment/db-upgrade-sudz-invdbt-cutover.md#12-очередь-ручного-разбора-после-seed-d5--10-ikey) и [04-4](../../domain/sudz/04-4_legacy-debt-grain.md) §3 — сплит `336,4786,6766,6770,6776,6798,6801,6812,6814`; спорный `4480`. После фазы B на prod — сверить список.

**Сверка:** 04-4; D1 (≠ L* Excel).

**Сегмент 29 — M1/D6: атрибуты `Dbt` при seed (владелец, 2026-08-27):**

**Утверждено:** при seed заполнять `dbtKey`, `dbtTimeOfEntry` и **`dbtNote`** по конвенции cutover §1.2 (`S73-split` / `S73-quarter`; опц. `Rslt-Lnnn` для L*; иначе NULL). Без FK на карточке `Dbt`.

**Сверка:** 08 §2.1; 04-3 §7.2; D5.

**Сегмент 30 — M1/D7: новые `Dbt` после cutover / C1 (владелец, 2026-08-27):**

**Утверждено:** C1 — auto `Dbt`+`invDbtDbt` при однозначно новом долге; неоднозначно — очередь/экран (M4); P1/сумма — тот же `Dbt` (**D2**). Разовый seed M2 **не** через C1. `Dbt` не писать молча в calm `invDbtLoad` без C1/seed.

**Сверка:** D2; сегм. 21; S66e C1; M3–M4.

**Сегмент 31 — M1 закрыт (2026-08-27):**

Сводка решений cutover [§1.1](../../../../deployment/db-upgrade-sudz-invdbt-cutover.md): **D1–D7 ✅**. Следующее мероприятие трека S74 — **M2** (DEV seed).

**Сегмент 32 — D3′: колонки `*Dbt` на cmm (владелец, 2026-08-27):**

**Утверждено:** вместо затирания `*InvAccnt` — **добавить** nullable `*Dbt` → `Dbt.dbtKey`, backfill в M2; cia-колонки сохранить до dual-read off. Откат M2 = обнуление/drop новых колонок. Детали: [cutover §1.3](../../../../deployment/db-upgrade-sudz-invdbt-cutover.md#13-cmm-и-dbtkey--уточнение-d3-2026-08-27).

**Сверка:** откат M2; dual-read; Access на переход; D3 по сроку (тот же seed) сохранён.

**Сегмент 33 — резолв `cnNum`/`invNum` для seed `invDbtVar` (владелец, 2026-08-27):**

**Утверждено:** при неоднозначности номеров у того же `cn`/`inv` — **не** руками; для asOf выгрузки брать номер с max `*TimeOfEntry ≤ asOf`, иначе earliest. `accnt`/`cn_s_org` — из `cia`/`cias`. Проверено на ~10 multi-фактах DEV. Канон: [cutover §1.4](../../../../deployment/db-upgrade-sudz-invdbt-cutover.md#14-резолв-cnnum--invnum-для-invdbtvar-при-историческом-seed-2026-08-27).

**Сверка:** структурный разрыв cia↛cnnKey/inKey; E1; без очереди оператора.

**Сегмент 34 — E1: полный перенос истории Value (владелец, 2026-08-27):**

**Утверждено:** для M2/cutover — **E1**: грузим **всю** историю из `cn_inv_dbt` в `DbtValue` в корректном виде; `invDbtVar` — в количестве, обеспечивающем эту загрузку (новая четвёрка по §1.4 → новый var; совпавшая → reuse UNIQUE). Цель — перетащить историю в новую структуру, не откладывать на первую FEMSQ-выгрузку (E0) и не резать год (E2).

**Сверка:** calm F1 / M3–M4; §1.4; D1–D7.

**Сегмент 16 — резолв Excel → FK `invDbtVar` (владелец, 2026-08-24):**

Вариант **1 (строгая однозначность):** `invDbtVarEnsure` создаёт строку **только** если все **четыре** FK резолвятся **однозначно**. Иначе — только лог; позиция может попасть в перечень `invDbtLoad` на ручную обработку. Источники по умолчанию:

| FK | Откуда |
|----|--------|
| `idvvAccnt` | `cidutAccount` (= `account_key`) |
| `idvvInvNum` | `invNum` у `iKey`, номер совпадает с Excel СФ |
| `idvvCnNum` | `cnNum` `cnnType=1` у договора строки |
| `idvvCn_s_org` | исполнитель `cn_s_type=2` по БУиРГ + №/дата из Tbl; при нескольких кандидатах — **не** выбирать эвристикой; **наличие** датированной стороны — **сегмент 17** |

**Сверка:** согласуется с ключом сегмента 5, UNIQUE четвёрки в 08, принципом «не решать за оператора».

**Сегмент 17 — `cn_s_org` уже обеспечен префиксом CnNot/ExistCtpt (владелец + проверка Access/FEMSQ, 2026-08-24):**

Гипотеза владельца подтверждена: шаги **«Отображаем отсутствующие в БД договоры с исполнителями…»** (`CnNotLoad`) и **«…договора, имеющиеся в БД, в которых отсутствует обнаруженный в БД исполнитель»** (`CnExistCtptNotLoad`) сверяют Excel с договорами **с джойном к `cn_s_org` и датой**, не только по номеру + БУиРГ.

| Факт | Источник |
|------|----------|
| Эталон списка | Access `ciduCnCtptList`: `cn` → `cn_s` (type=2) → smpl → **`cn_s_org`**; `csoCnDateNull` = null → `#1900-01-01#` |
| «Нет пары» | `ciduCnCtptExistNot`: LEFT JOIN по **№ + БУиРГ + дата** (`cidutCnDateNull` = `csoCnDateNull`); `cn_key IS NULL` |
| CnNotLoad apply | создаёт цепочку вплоть до **`cn_s_org`** (дата из Excel, если есть) |
| CnExistCtptNotLoad | номер есть, тройки №+БУиРГ+**дата** нет → **только лог**; дату/`cn_s_org` оператор добирает вручную (**Договоры** / **0071**), затем повторный прогон |
| FEMSQ | тот же join/сравнение дат в `JdbcSudzDao` |

**Следствие для воронки:** строка Excel, **не** попавшая ни в CnNotLoad, ни в ExistCtpt, уже имеет в БД **`cn_s_org` с той же датой** (или оба NULL → sentinel `1900-01-01`). Отдельный чекбокс «ensure `cn_s_org`» **перед** `invDbtVarEnsure` **не** вводится.

**Нюансы (не отменяют следствия):** AccSmpl цепляет smpl **без** даты — это не создание `cn_s_org`; для FK `idvvCn_s_org` брать сторону из тройки ExistList. Пустая дата ↔ sentinel — формальная, но всё же конкретный `cn_s_org_key`. Непустой ExistCtpt → поток не «чистый»; чинят вручную, не новым ensure-шагом.

**Сверка:** согласуется с сегментами 4–5 и 16 (`idvvCn_s_org`); с S61l+/S61n и реестром stepId (`CnNotLoad` / `CnExistCtptNotLoad`).

**Сегмент 7 (текст владельца, 2026-08-24):**

Не упустить: при решении «один долг / тщательный разбор / 2a vs 2b» нужно проверить **не только** наличие **более чем одной** задолженности в **текущей** выгрузке, но и наличие таких случаев в **истории СФ** — в **старой** или **новой** структуре данных.

Это **усиливает** сегмент 2 (два показания) и задаёт источник «истории» на переходный период: смотреть **оба** контура (`cnInvAccnt`+`ciaName`+`cn_inv_dbt` и/или уже накопленные `invDbt` / факты новой модели), а не один из них.

**Сверка — противоречий нет.** Совпадает с сегментом 2 и проверкой `ciaName` (44/51 inv: в одних upl >1, в других =1). Закрывает часть открытого сегмента 2 («из каких таблиц история»): **оба** контура, пока старая структура жива рядом с новой (как сверка суммы Excel).

**Не утверждается сегментом 7 (деталь реализации):** ~~точный SQL UNION/приоритет~~ — **закрыто сегментом 13** (OR).

**Сегмент 13 — история multi OR (владелец, 2026-08-24):**

Вариант **1 (безопасный):** у `iKey` «в истории было >1 долга», если **хотя бы один** контур говорит «да»:

- **старый (`ags`):** >1 `cnInvAccnt` с непустым `ciaName` на этот `iKey`, **или** в какой-то выгрузке >1 строки `cn_inv_dbt` по этому `iKey`;
- **новый (`sudz`):** в `sudz.invDbt` по этому `iKey` уже **>1** слот.

При расхождении контуров — считать multi (чаще попадёт в перечень ручной обработки). Принцип: сомнение → смотреть вручную.

**Сверка:** усиливает сегменты 2 и 7; согласуется с проверкой `ciaName` (история ≠ только текущий свод).

**Сегмент 8 — куда писать / откуда читать (владелец, 2026-08-24):**

Вариант **1** (как S48): на DEV воронка 0069 **пишет** `invDbt` / `invDbtVar` / `invDbtDbtVar` **только в схему `sudz`**. Живой **`ags.invDbt`** (заливка 2022) из воронки **не** INSERT/UPDATE. **Чтение** истории «>1 долга» (сегмент 7): **`ags`** (старый контур) **и** **`sudz`** (уже накопленное новое). Прод — по S48a (`ags` пакетом), не сейчас.

**Сверка:** совпадает с 08 / S48 / S48a. Закрывает пробел «куда INSERT» для разработки шагов 1–2.

**Сегмент 9 — якорь СФ (владелец, 2026-08-24):**

Вариант **1:** для GROUP BY текущей выгрузки и для истории «>1 долга» якорь СФ — **`iKey`** (уже сопоставленный документ в БД после шагов Inv / КСДСФ). Строки Excel **без** резолва в `iKey` в шаги `invDbt*` **не** входят (ещё не «прошедшие до этого места»). Текст номера из Excel сам по себе якорем не служит.

**Сверка:** согласуется с S66/S68u (`TblCnInv` → `inv`) и сегментами 4–5 («прошедшие»). Закрывает открытое сегмента 2 про определение СФ.

**Сегмент 10 — `idNum` (владелец, 2026-08-24):**

Вариант **1:** при INSERT в `sudz.invDbt` — если на данный `idInv` (`iKey`) слотов ещё нет → **`idNum = 1`**; иначе → **`MAX(idNum) + 1`** по этому `iKey` в `sudz.invDbt`. Правило одно для **2a** и **2b** (оператор не вводит `idNum` вручную как замену `ciaName`). `idNote` при необходимости — отдельно, не вместо `idNum`.

**Сверка:** совпадает с 08 `UNIQUE(idInv, idNum)` / DEFAULT 1. Не смешивать с `ciaName`.

### Проверка выводов сегментов 1–5 на старой схеме (`ciaName` NOT NULL) — 2026-08-24, DEV `ags`

Источник: `cnInvAccnt` с непустым `ciaName` + `cnInvAccntSmpl` / `cnInv` / `cn_inv_dbt` / `cn_inv_dbt_upl` (DBHub).

| Факт | Число | К сегментам |
|------|-------|-------------|
| Всего `cnInvAccnt` / с непустым `ciaName` | 12 693 / **157** (**1,24 %**) | **S2 редкость** — да |
| Различных `inv` с ≥1 named-карточкой | **51** (= стиль `invDoubleCia`) | S1/S66c |
| Из них `inv` с **>1** named-карточкой / ровно 1 | **51 / 0** | **S1:** `ciaName` появляется именно при множественности на СФ — да |
| Пар (выгрузка×`inv`) с >1 строкой `cn_inv_dbt` по named | **244** (21 upl, 51 inv) | **S1** в одной выгрузке — да |
| `inv`, у которых в одних upl named>1, в других =1 | **44** из 51 | **S2 история vs текущий свод** — да (типично) |
| `inv`, где во всех upl с фактами named>1 | **7** | S2 (меньшинство) |
| Дубли `dbt_ttl` в одной паре (upl×`inv`) среди named | **55** | **S3** неоднозначность суммы → оператор — да, случаи есть |
| Разные named-`ciaKey` на одном `inv` с одной и той же `dbt_ttl` (по истории) | **13** пар (inv×ttl) | **S3 часть 2** — да |
| Пары фактов одного `ciaKey` в разных upl: сумма равна / изменилась | 3712 / 3352 из 7064 | **S3:** сумма — полезный, но не вечный ключ; при смене — оператор |
| Из пар с равной суммой: совпала дата начала / срок | 3048 / 3368 | **S3:** даты — мягкий плюс, не вердикт |
| Группы named по `(ciInv, accnt, cn_s_org)`: >1 долг / =1 | **15 / 114** (всего 129) | **S5:** ключ контекста дробит; на одной группе бывает >1 долга |
| Среди multi-named `inv`: разные `cn_s_org` / разные `accnt` / один accnt+org при >1 cia | 40 / 8 / **5** | S5: чаще различает сторона/`cn_s_org`, реже счёт; **5** случаев — чистая множественность в одной «ячейке» контекста (нужен слот/`ciaName`) |

**Итог проверки:** выводы сегментов **1–3 и 5** на популяции `ciaName` **справедливы**. Искусственный дискриминатор реально нужен и редок; одного GROUP BY по текущему Excel мало (история); auto по сумме осмысленно, но неоднозначности и смена суммы встречаются; ключ эскиза `invDbtVar` согласуется с тем, как named-карточки разложены по СГК/`cn_s_org`. Сегмент **4** (ensure `invDbtVar` + «Обновлять») данными `ciaName` напрямую не проверяется — сущности ещё нет в старом контуре.

**Эскиз целевой модели (владелец, 2026-08-24):** исправленный вариант (незначительные ошибки предыдущего) — [`assets/26-0824-sudz-target-sketch-dbtvar.png`](../../domain/sudz/assets/26-0824-sudz-target-sketch-dbtvar.png). Предшественники: `26-0807-…dbtvar.png`, fix pm S63 `26-0815-…pm-accnt-fix.png`.

**Практика Access (источник):** [`Form_CnInvDbtUpl_gt_File_f.cls`](../../../../project/proposals/vba-analysis/VBA-Code-Export/Form-Modules/Form_CnInvDbtUpl_gt_File_f.cls) ≈ стр. 140–247: после Excel→Tbl идёт **инлайн**-блок «отсутствующие контрагенты» (не выделен в `Sub`), затем именованные `CnNotLoad` … `CnCtptInvAccDbtExist`; `CnCtptInvAccExistDbl` закомментирован с 03.02.2023.

**Реестр stepId (оркестратор сверху вниз; чекбокс = вызывать ли шаг):**

| stepId | Access / VBA | Примечание |
|--------|--------------|------------|
| `excelToTbl` | `cidufFlTbl` → `AccountSheetTest` / `ReceivablesTest` | **не чекбокс**; переключатель «обнов. по исх?» |
| `orgNotInBuirg` | **инлайн** 140–207 | именованный шаг; **S61k** только лог |
| `CnNotLoad` | `CnNotLoad` | **S61l** лог; **S61l+** apply при `flLoad` + `rollbackSudzCnNotLoad(cnMark)`; **S66e сегм. 17:** apply создаёт `cn_s_org` с датой Excel |
| `CnExistCtptNotLoad` | `CnExistCtptNotLoad` | **S61n** только лог; разбор вручную → экран **Договоры** (**S62** / **0071**); **S66e сегм. 17:** gate датированной `cn_s_org` до `invDbtVarEnsure` |
| `CnCtptExistInvNotLoad` | clear InvDouble + `CnCtptExistInvNotLoad` | **S66** лог+apply ✅ UAT 910: **693**; коллизии → КСДСФ ✅ **S68u** |
| `CnCtptInvExistAccSmplNotLoad` | `CnCtptInvExistAccSmplNotLoad` | **S66a** ✅; **последний 1:1 с Access** |
| `invDbtVarEnsure` | **новый** (S66e) | лог missing/ambiguous; INSERT `sudz.invDbtVar` при `flLoad` (только однозначные 4 FK) |
| `invDbtLoad` | **новый** (S66e; сегм. 21) | rebuild очереди; при `flLoad` — calm: `invDbt`+`invDbtDbtVar`+**`DbtValue`** (после B1); экран двоящих |
| ~~`invDbtDouble`~~ … ~~`CnCtptInvAccDbtExist`~~ | Access-хвост | **disabled** в панели (S66e); эталон только для сравнения |
| ~~`dbtAmbiguous` / `srcDbtAmbiguous` / `Dbt*NotLoad`~~ | S66d черновик | **снят** — заменён `invDbtVarEnsure`+`invDbtLoad`; `Dbt`/`DbtValue` — следующий этап |

**Правила UI/API (S61f):**

1. Порядок **жёсткий** (префикс цепочки): нельзя выполнить поздний шаг, пропустив ранний (без отдельного «force» — в v1 не давать).
2. Два измерения: ☐ выполнить шаг; ☐ писать в БД (`cidufFlLoad` глобально и/или per-step).
3. Пресеты: «только org», «до договоров dry-run», «полная dry-run», «полная + apply».
4. Backend: один оркестратор + **отдельный метод на шаг** (зеркало `Private Sub`); mutation с `runSteps[]` + `flLoad`.
5. После AccSmpl apply в целевой контур `sudz.invDbt*` (**S66c/S66e**); не в `cnInvAccnt` / `cn_inv_dbt`. **`Dbt`/`invDbtDbt` — этап C1**; **`DbtValue` — в `invDbtLoad` (calm) и на экране двоящих** после **B1** (сегм. 21).

Итерации: … → **S72 A1/A2/B1/B1b ✅** → **S74 M1** (Dbt) → **M2** DEV cutover → **M3** calm → **M4** экран/7 → **M5** чекбоксы → **M6** prod.  
**Критерии 0069** (из `project-development`): порт/адаптация match; Dbt/DbtValue + upl; UI + очередь; регрессия Rslt без ручного SQL-seed.  
**Добавлено S61c:** staging на SQL до UI. **S61f:** панель шагов вместо «всё сразу».

##### S74 — трек cutover M1…M6 (2026-08-27)

**Документ порядка:** [db-upgrade-sudz-invdbt-cutover.md](../../../../deployment/db-upgrade-sudz-invdbt-cutover.md) (v0.2).  
**Зачем:** однократный перенос old→new **с `Dbt`**; не тянуть dual-read; экран/7 — на заполненной new.

| # | Мероприятие | Содержание | Выход | Статус |
|---|-------------|------------|-------|--------|
| **M1** | Обсуждение `Dbt` (без UI) | Повестка **D1–D7** ✅; сегм. 24–31 | Письменный канон seed `Dbt` | ✅ |
| **M2** | DEV-перенос old→new | Seed + **D4a** concurrent split + **E1** + **D3′**; `ROLLBACK_M2` | `DbtValue`=cid; cutover §1.5 | ✅ 2026-08-27 |
| **M3** | Calm F1 | Sum уникальна → тот же `invDbt`; код + UAT 910 | Value 1629 / f1=1; [M3_CALM_F1](../../../sql/26-0827-sudz-m2-seed/M3_CALM_F1.md) | ✅ 2026-08-27 |
| **M4** | Экран двоящих + чекбокс 7 | Доработка UI/регламента на seeded; Create/Link + Value | Сегм. 22 закрыт по UI; [M4_SCREEN](../../../sql/26-0827-sudz-m2-seed/M4_SCREEN.md) | ✅ 2026-08-27 |
| **M5** | Остальные чекбоксы воронки | C1 ✅ `invDbtDbtEnsure`; C2/C3 — next | 🔄 C2 next |
| **M6** | Prod | Survey A → `MSSQL2012/` → окно H → dual-read off | Cutover на FishEye | ☐ после M5 |

**Подпункты M1 (D1–D7)** — см. cutover §1.1; стартовые предложения — в чате при открытии M1.

**Связь с S72:** фаза **C1** (канон в воронке) не отменяется, но **разовый seed `Dbt`** = **M2**, до возврата к экрану. Потоковый C1 (новые долги после cutover) — в **M5** / D7.

**Запрет до M2:** массовая доработка экрана «под пустую» new; ETL без решений M1.

##### S72 — дорожная карта реализации (слой I → M2 → канон) (2026-08-25; **правка 2026-08-26 сегм. 21**; **порядок C — S74**)

**Контекст:** обязательность `Dbt` в модели; M2 физ. (S71); **Value — SoT выгрузки**; **seed канона `Dbt` — трек S74**, не «после всего UI».

**Порядок ближайших работ:** **S74 M5 → M6** (M1–M4 ✅); хвосты S72 **B2/B3** — по мере M5; **0071** параллельно.

###### Фаза A — слой I + очередь (+ Value после B1)

| # | Шаг | Содержание | Статус |
|---|-----|------------|--------|
| **A1** | UAT 910 ensure/load | dry → apply ensure/load → dry; 1634 var; apply Auto **1627** → БД **1630** `invDbt`+мост; очередь **133**; dry повтор без роста слотов (~39 с) | ✅ 2026-08-25 |
| **A3** | Hist multi в queue/calm | сегм. 13 OR: +`histCidMulti`; JAR **0.1.0.215**; UAT dry 910: очередь **133** | ✅ |
| **A2** | Экран двоящих долгов СФ | UI сегм. 20; create/link слоя I + **`DbtValue`** на upl; rebuild не open при наличии Value | ✅ v1 2026-08-26; **M4 2026-08-27** |
| ~~**A4**~~ | ~~отдельный SoT слоя I~~ | **Снят (сегм. 21):** SoT = `DbtValue` | ❌ |

###### Фаза B — физика Value M2 (**до** записи Value в воронке)

| # | Шаг | Содержание | Статус |
|---|-----|------------|--------|
| **B1-prep** | Подготовка к DDL M2 | чеклист ниже; без ALTER `DbtValue`; с baseline-проверками | ✅ P0–P9 |
| **B1** | DDL `sudz` (+ `test_sudz`) | убрать `dvDbt`; добавить `dvInvDbt`; `UNIQUE(dvInvDbt,dvUpl)`; триггер §4.1 M2 | ✅ 2026-08-26 (JAR 0.1.0.217) |
| **B1b** | Value в calm `invDbtLoad` | после слота+моста INSERT `DbtValue` (идемпотентно); симметрия с A2 | ✅ 2026-08-26: upl 910 → **1628** Value; queue **133**; idempotent 0; JAR **0.1.0.218** |
| **B2** | Seed-скрипты + доводка витрин | обновить INSERT seed под M2; остаточный хвост витрин | ☐ ↔ S74 M2 |
| **B3** | Smoke Rslt/D644 | регрессия после seed с `Dbt` | ☐ ↔ S74 M2/M5 |

####### B1-prep — подготовка (до ALTER `DbtValue`)

Цель: **ничего не ломать** — сначала инвентаризация и baseline, затем черновики миграции/кода, гейт «можно B1». Выполнять **пошагово**; каждый подпункт — со своей проверкой. DDL B1 **не** начинать, пока гейт не ✅.

| # | Мероприятие | Зачем | Проверка / критерий готовности | Статус |
|---|-------------|-------|--------------------------------|--------|
| **P0** | Зафиксировать scope B1 vs B1-prep / B2 | не смешать DDL с Value-in-calm и с полным seed | в плане: B1 = таблица+триггер+минимально необходимый rewrite зависимых SQL-объектов; код приложения — в prep как «патч готов к выкладке сразу после B1» | ✅ 2026-08-26 (этот чеклист) |
| **P1** | Инвентарь зависимостей `dvDbt` | знать, что упадёт при DROP колонки | реестр: [P1_INVENTORY_dvDbt.md](../../../sql/26-0826-sudz-dbtvalue-m2/P1_INVENTORY_dvDbt.md) — БД (`trg`, `vw_Yr_DbtFact` sudz+test_sudz); косвенно proc Rslt/D644; Java/GQL/UI КСДСФ; рёбра; seed SQL; `DbtUplCstAg` join; вне scope `ags.invDbtValue` | ✅ 2026-08-26 |
| **P2** | Baseline функционала **до** изменений | эталон «как было», чтобы ловить регресс | [P2_BASELINE.md](../../../sql/26-0826-sudz-dbtvalue-m2/P2_BASELINE.md) — P2a–e | ✅ 2026-08-26 |
| **P2a** | Лаунчер свода + очередь двоящих долгов upl **910** | слой I не связан с `dvDbt`, но контроль «не тронули» | open **133**; invDbt/мост **1630**; var **1634**; dry funnel ~41 с ✅ | ✅ |
| **P2b** | КСДСФ: вкладка/панель **Суммы · new** (`DbtValue`) | читает `dvDbt` | debt 70525000.01 → newMatches **8** (`dvDbt=82`) | ✅ |
| **P2c** | КСДСФ: **подсказки** `sumsNew` | hints JOIN по `dvDbt` | SF-очередь пуста; SQL-path join **8** dvKey; API `na` без 500 | ✅ |
| **P2d** | RelationTree рёбра `dv.dbt` / `dbt.dv` | каталог рёбер | expand dvKey=1→82; dbt=82→Values с `dvDbt` | ✅ |
| **P2e** | Progress / отчёты: Rslt или D644 на yr с seed 82/85 | `vw_Yr_DbtFact` использует `dv.dvDbt` | fact **16**; D644 **2** строки; REST xlsx 200 | ✅ |
| **P3** | Dry-check миграции данных (SELECT only) | убедиться, что backfill однозначен | [00_VERIFY_before.sql](../../../sql/26-0826-sudz-dbtvalue-m2/00_VERIFY_before.sql) · [P3_VERIFY_RESULT.md](../../../sql/26-0826-sudz-dbtvalue-m2/P3_VERIFY_RESULT.md): sudz+test_sudz 16/16 one_slot, dup=0 | ✅ 2026-08-26 |
| **P4** | Черновик SQL-пакета B1 (без apply) | воспроизводимый ALTER | [пакет](../../../sql/26-0826-sudz-dbtvalue-m2/): `00`…`04`+`99` + [README](../../../sql/26-0826-sudz-dbtvalue-m2/README.md); **не выполнять** до гейта | ✅ 2026-08-26 |
| **P5** | Черновик rewrite `vw_Yr_DbtFact` | view иначе сломается в ту же секунду, что DROP `dvDbt` | [04](../../../sql/26-0826-sudz-dbtvalue-m2/04_VIEW_vw_Yr_DbtFact_M2.sql) · [P5_VERIFY_RESULT](../../../sql/26-0826-sudz-dbtvalue-m2/P5_VERIFY_RESULT.md): sudz+test_sudz 16/16 `dbtKey` eq via `invDbtDbt`; CREATE — при B1 | ✅ 2026-08-26 |
| **P6** | Черновик патча приложения (код готов, выкладка **после** B1) | КСДСФ/API не останутся на `dvDbt` | [P6_APP_PATCH.md](../../../sql/26-0826-sudz-dbtvalue-m2/P6_APP_PATCH.md): DAO/GQL/UI/рёбра/деревья → `dvInvDbt`+`dbtKey`; рёбра `dv.invDbt`/`invDbt.dv` | ✅ 2026-08-26 |
| **P7** | Стратегия выкладки «без окна поломки» | порядок apply | [P7_DEPLOY.md](../../../sql/26-0826-sudz-dbtvalue-m2/P7_DEPLOY.md): stop UI → 00 → 01…04 → 99 → JAR P6 → smoke P2a–e | ✅ 2026-08-26 |
| **P8** | Снимок / откат DEV | безопасность Docker | [P8_ROLLBACK.md](../../../sql/26-0826-sudz-dbtvalue-m2/P8_ROLLBACK.md): диск OK; `backup-fisheye.sh manual` + fallback 26-0807 | ✅ 2026-08-26 |
| **P9** | Гейт «можно B1» | единая точка GO | [P9_GO_GATE.md](../../../sql/26-0826-sudz-dbtvalue-m2/P9_GO_GATE.md); **GO B1** 2026-08-26 | ✅ |

**Правило регресса:** после каждого выполненного подпункта prep — при необходимости точечный re-check связанного P2*; после **B1** — полный повтор P2a–P2e и сравнение с baseline.

**Вне B1-prep:** B2/B3 ↔ **S74 M2**; прод `MSSQL2012/` ↔ **S74 M6**.

###### Фаза C — канон `Dbt` в **потоке** воронки (после S74 M2)

| # | Шаг | Содержание | Статус |
|---|-----|------------|--------|
| **C0** | Разовый seed `Dbt` | = **S74 M1✅+M2✅** (не чекбокс) | ✅ M2 |
| **C1** | `Dbt` + `invDbtDbt` в воронке | auto для новых слотов без канона; иначе очередь (D7) | ✅ 2026-08-30 |
| **C2** | `dbtValueLoad` / Exist | diff base yr→curr; исчезнувшие `Dbt` + очередь P1 (`overdReduced`, сегм. 35) | ✅ **M5** код |
| **C3** | «Учтено» / отчёты | Value + путь к `Dbt` | ☐ **M5** |

###### Фаза D — параллельно (не блокер M1)

| # | Шаг | Статус |
|---|-----|--------|
| **D1** | 0071 Договоры / ExistCtpt | 🔶 |
| **D2** | Полировка КСДСФ T6a/T7 | ☐ |
| **D3** | Прод `MSSQL2012/` | = **S74 M6** |

**Запреты:** не писать **`Dbt`/`invDbtDbt`** внутри `invDbtLoad` / экрана **до решений M1** и без политики C1; после M2 seed — отдельное решение D7. Очередь ≠ SoT (SoT = `DbtValue`). **B1 DDL** на DEV ✅.

**Сегмент 19/21/23** зеркалят эту карту.

##### S76 — Rslt stage2 QIV: дельта воронка 901 vs Access (variant B) (2026-09-01)

**Контекст:** после apply воронки на upl **901** (Excel «Дт Задолженность на 31.12.2025», Tbl **1764**) сверка с эталоном `ags_Yr_DbtChangesRslt_26-0212_26-0217.xlsx` дала Δ QIV (~+2,1 млрд Ttl). Владелец выбрал **variant B** — сначала паритет QIV с Access (QIII игнор), затем 902/903. Достигнут **PASS** сумм base–QI–QII–QIV после **ручных SQL-правок** — это **не** gate «воронка из одного Excel».

**Реестр (рабочий документ):** [stage2_qiv_delta_registry.md](../../sql/26-0831-sudz-dbt-slot-link/stage2_qiv_delta_registry.md)  
**Артефакты:** `artifacts/stage2_qiv_verify_26-0831.json`, `…asOf901_qiv_parity_26-0831.xlsx` (после подгонки)  
**Эталон Access QIV:** срез **2026-01-30**; FEMSQ upl **901** — **2026-01-15** (разные asOf).

###### Две группы явлений

| Группа | Суть | Критерий «закрыто» |
|--------|------|-------------------|
| **A — код загрузки** | Tbl → `invDbtLoad` → `DbtValue@901` даёт лишнее / не то / не туда | Повторный apply на чистом upl **без ручных SQL** → Rslt QIV ≡ эталон (или ≡ Tbl-производимая часть) |
| **B — вне Excel / вне приложения** | В Access Rslt есть строки, которых **нет** в загруженном своде на шаре | Реестр + объяснение происхождения; либо найден исходный Excel, либо зафиксирован **manual overlay** |

###### Четыре явления (кратко)

| # | Явление | Группа | Суть | Подгонка (2026-08-31) |
|---|---------|--------|------|------------------------|
| **1** | Дубли `DbtValue` на sibling-слотах (6760/28469, L006, 7454…) | **A** | `invDbtLoad` пишет Value на каждый слот iKey без guard «один слот на upl» | DELETE 4 Value (hist=0) |
| **2** | 9240 / 90621: Tbl ≠ Access QIV (53,76M→64,51M; 2,5M→3M) | **A?/B?** | Рост сумм к QIV; разные даты среза 15.01 vs 30.01 | UPDATE Value |
| **3** | 9 строк 762210 (`06/44-*`, `б/н`, `Б/С`), ~592,9 млн | **B** | QIV-only в Access; **0** строк на листе 762210 в Excel свода | `10_SEED_access_q4_missing_9.sql` |
| **4** | `732 от 10.01.24`: Tbl есть, Value на укороченном `732` | **A** | partial match invNum вместо exact + hist-слота | INSERT на 8898, DELETE на `732` |

###### План работ S76 (порядок разбора в чате)

| Шаг | Содержание | Артефакт | Статус |
|-----|------------|----------|--------|
| **S76.0** | Зафиксировать реестр и критерии gate | `stage2_qiv_delta_registry.md`, эта секция | ✅ |
| **S76-A** | Группа **A**: кейсы 1, 4 (+ релевантные подкейсы 2) — код `JdbcSudzDao.applyInvDbtLoad` | A1 sibling guard; A2 exact invNum; A3 post-apply отчёт; A4 UAT без SQL | ☐ next |
| **S76-B** | Группа **B**: кейсы 2 (источник сумм), 3 (происхождение 9 строк) | VBA Rslt, prod `ags`, архив Excel, Приложение 2 | ☐ |
| **S76-G** | Два gate: `excel_only` vs `full_access` + documented overlay | скрипты verify (черновик в реестре) | ☐ |

**Формула целевого паритета:**

```text
Rslt(QIV) ≡ Excel_эталон
  ⇔  (Tbl → funnel → Value) ≡ эталон_excel_producible
     +  manual_overlay ≡ эталон_B   (если overlay документирован)
```

**Связь:** **S75** (PIT 801–803) не менять; **S76** не смешивать gate stage1 и stage2. Скрипт `10_SEED_…` — **временный UAT**, не cutover.

**Следующий шаг в чате:** **S76-C.10** (UI gate-UAT). **S76-A** — только если после закрытых G2–G4 gate Rslt всё ещё FAIL по группе A. Группа B / явление 3 (X) — **закрыта** (C.8 ✅).

###### S76-C — воронка 901→903 без B-seed (2026-09-01)

**Контекст (исторический):** P3 (~592,9M) считался data gap при OLD Excel; B-seed **deprecated**. GraphQL-цикл C.3–C.6 выполнен на OLD. С **2026-09-07** канон upl **901** = Excel **X** (НОВЫЙ); исполнение — **C.10**.

| Шаг | Содержание | Артефакт | Статус |
|-----|------------|----------|--------|
| **S76-C.1** | Reset upl **901** (Tbl/Value/очередь + откат B-seed) | `12_RESET_upl901_clean_apply.sql` | ✅ |
| **S76-C.2** | Seed File + FileSh **902/903** (13 листов «НОВЫЙ» svod) | `30_SEED_funnel_upl_902_903.sql` | ✅ |
| **S76-C.3** | Funnel **901** `flLoad=true`, yrKey=**900** (на **OLD** Excel) | GraphQL `runSudzDbtUplFunnel` | ✅ (~256 с; Tbl=1764, DV=1755) — **superseded** C.10 |
| **S76-C.4** | Gate **T0+T1** @901 (OLD) | `verify-qiv-stage2-gate.sh` | ✅ T0 A1=0; T2 FAIL Δq4≈−790M (P3 без X) |
| **S76-C.5** | Funnel **902**, yrKey=**901** (преждевременный / без gate'ов) | JAR **246** | ✅ — **superseded** C.10 |
| **S76-C.6** | Funnel **903**, yrKey=**901** | JAR **247** compact 606012 | ✅ — вне scope C.10 (после QI) |
| **S76-C.7** | Gate **T2** + manifest T2′ | `p3_data_gap_manifest.json` | ⏸ пересмотреть после C.10 (с X P3-gap на QIV снимается) |
| **S76-C.8** | Excel **X** найден на шаре | `…31.12.2025 (Общий свод) -НОВЫЙ.xlsx` (mtime 2026-09-07) | ✅ **9/9** P3 в Tbl@901; Rslt QIV **9/9**; QI **8/9** (105449 ø) |

**Политика:** без `10_SEED_access_q4_missing_9.sql`; overlay не использовать. После X — T2 по P3 не считать «ожидаемым FAIL».

###### S76-C.9 — казус «full apply без gate'ов» @902 (2026-09-02)

**Суть:** GraphQL-прогон enabled-шагов **1–9** + `flLoad=true` **без** остановок на ручных gate'ах (G2 ExistCtpt, G3 КСДСФ, G4 КСДД) дал **неполную** загрузку: DbtValue=**1725**/1746, КСДД open=**10**. Вероятная причина расхождений Rslt @902 — пропуск ручных контуров, не только код `invDbtLoad`.

| Факт | Значение |
|------|----------|
| G2 @902 | **5** договоров ExistCtpt (7 строк Tbl) — см. runbook |
| Ошибка INSERT КСДД | duplicate `ciudCidut` — fix JAR **252** (`ROW_NUMBER` dedupe) |
| Статус B2 @902 | apply **преждевременный**; хвост G2@902 **устарел** относительно C.10 (рестарт с 901(X)) |

**Артефакты:**

| Файл | Назначение |
|------|------------|
| [sudz-dbt-upl-funnel-uat-runbook.md](../../sudz-dbt-upl-funnel-uat-runbook.md) | пошаговый UAT **с UI и без UI**; анти-паттерн; фазы A–E |
| [verify_funnel_manual_gates.sql](../../sql/26-0831-sudz-dbt-slot-link/verify_funnel_manual_gates.sql) | SQL G2–G4 + сводка |
| `code/scripts/verify-funnel-manual-gates.sh` | gate-check из GraphQL-лога (+ SQL при `FEMSQ_DB_*`) |

**Правило:** **не** передавать в `steps[]` / UI «все шаги сразу» префикс длиннее текущей фазы; после каждой фазы — verify → ручная работа → следующая фаза. C.9 = урок процесса для **C.10**.

###### S76-C.10 — UI gate-UAT: 901(X) → 902 → Rslt QI (2026-09-07)

**Цель:** полный объём загрузки свода **31.12.2025 (X)** и **31.03.2026 (QI НОВЫЙ)** через **UI** (параллельный UAT экранов), затем сверка FEMSQ Rslt с эталоном **`ags_Yr_DbtChangesRslt_26-0505.xlsx`** (колонки QIV + QI).

**Роли:** оператор — UI (лаунчер, Договоры/0071, КСДСФ, КСДД); агент — SQL/скрипты verify, сверка сумм, лог. Агент **не** гоняет full `runSudzDbtUplFunnel` вместо UI.

**Канон файлов:**

| upl | Excel |
|-----|--------|
| **901** | `excel/2025-12/debit/Дт Задолженность на 31.12.2025 (Общий свод) -НОВЫЙ.xlsx` (**X**) |
| **902** | `excel/2026_03/debit/Дт Задолженность на 31.03.2026 (Общий свод) -НОВЫЙ.xlsx` |
| Эталон Rslt QI | `excel/2026_03/debit/ags_Yr_DbtChangesRslt_26-0505.xlsx` |

**Порядок (строго по [runbook](../../sudz-dbt-upl-funnel-uat-runbook.md)):**

| # | Шаг | Критерий | Статус |
|---|-----|----------|--------|
| **C.10.0** | Reset **901** (Tbl/DV/очереди); `cidufPath` = X | `12_RESET…` + path UI/GraphQL | 🔶 Tbl уже reload агентом 2026-09-07 (1774); DV=0 — перед UI-прогоном повторный reset по желанию оператора |
| **C.10.1** | UI **901**: excelToTbl → фазы A–E (G0…G5) | G2–G4 open=0; DV≈Tbl (±док. искл.) | ☐ |
| **C.10.2** | Smoke P3 @901 | **9/9** сумм в `DbtValue@901` (~592,9M) | ☐ |
| **C.10.3** | Gate QIV `excel_only` / T1 (и T2 без P3-gap) | vs `26-0212` или база `26-0505` | ☐ |
| **C.10.4** | Reset/подготовка **902**; UI **902** теми же gate'ами | G2–G4 PASS | ☐ |
| **C.10.5** | Export Rslt (yr 2026, asOf ≥902) ↔ **`26-0505`** | P3: **8/9** в QI; **105449** — documented exception | ☐ |
| **C.10.6** | (опц.) **903** / QII — вне обязательного C.10 | — | ☐ later |

**Два gate'а:**

1. **`funnel_from_X` (901):** воронка из X без overlay → Rslt QIV ≡ эталон на пересечении + P3 присутствуют.  
2. **`full_access_QI` (901+902):** Rslt vs `26-0505` (QIV+QI); 105449 отсутствует в QI — ожидаемо.

**Запреты:** full apply без gate'ов (C.9); B-seed; сравнивать Rslt до G2–G4 PASS. **S76-A** не смешивать с C.10 до FAIL после закрытых gate'ов.

### 5.7. 1.1.1.2 — паспорт Access `CnInvPmtUpl*` (S69; не 0069)

**Чат:** отдельный от воронки долгов и от реализации КСДСФ. **Паспорт Access закрыт (2026-08-18).** Java-воронка pmt — отдельный чат. КСДСФ — только ссылка (адаптер pmt позже).

**Документ формы:** [02-11_cn-inv-pmt-upl-access.md](../../UI/02-11_cn-inv-pmt-upl-access.md)  
**Резюме чата:** [chat-resume-26-0817-cn-inv-pmt-upl.md](../chat-resume/chat-resume-26-0817-cn-inv-pmt-upl.md)  
**Алгоритм кнопки:** [04-data-model §2.9](../../domain/sudz/04-data-model.md#29-алгоритм-btnupload_click--cninvpmtupl-процесс-1112-каркас-s69)  
**Процесс:** [03 §1.1.1.2](../../domain/sudz/03-processes.md)  
**Съём таблиц:** [26-0813_CnInvPmtUpl_/](../../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/)

**Nav `CnInvPmtUpl` (2026-08-17):** 4 таблицы (как 26-0813); запросы `CnInvPmtUplTbl_CstNew`, `CnInvPmtUplTblNull`; формы: **`CnInvPmtUpl`** (родитель, `_2` нет) → `File_f` → `CstNew` | `InvDouble` → `invNum` → `cnInv`. Скрин: [00-nav](../../UI/assets/26-0817-cn-inv-pmt-upl/00-nav-CnInvPmtUpl.png).

**QueryDef `cipuCacNot` (2026-08-17):** DISTINCT `cacOrNull` из `CnInvPmtUplTblNull`, WHERE не Null, HAVING `cstapCsta` Is Null (анти-join к `ags_cstAgPn`). VBA — только лог. SQL: [cipuCacNot.access.sql](../../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCacNot.access.sql).

**QueryDef `cipuCtpt_All_OIdNot` (2026-08-17):** `FROM cipuCtpt_All_OId WHERE org_id_key is null`. Имя = **OId** (org_id), не архивный **Old**. SQL: [cipuCtpt_All_OIdNot.access.sql](../../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCtpt_All_OIdNot.access.sql).

**QueryDef `cipuCtpt_All_OId` (2026-08-17):** `cipuCtpt_All INNER JOIN agsOrgIdBUiRG ON CntrPrtNum = org_id_value_l`. `agsOrgIdBUiRG` — объект Access, в FishEye нет. SQL: [cipuCtpt_All_OId.access.sql](../../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCtpt_All_OId.access.sql).

**QueryDef `cipuCtpt_All` (2026-08-17):** UNION уникальных пар из `CnInvPmtUplTbl`: контрагент `ciputCntrPrt*` ∪ агент `ciputAgent*`, оба NOT NULL. Nav: `All` / `All_Old` (legacy) / `All_OidNot` — Old ≠ OId. SQL: [cipuCtpt_All.access.sql](../../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCtpt_All.access.sql).

**QueryDef `agsOrgIdBUiRG` (2026-08-17):** `SELECT org_id_value_l, org_id_key FROM ags_org_id WHERE org_id_type=1`. Лог шага 1 структурно пуст (INNER JOIN + key NOT NULL). SQL: [agsOrgIdBUiRG.access.sql](../../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/agsOrgIdBUiRG.access.sql).

**QueryDef `cipuCn_CtptCnNot` (2026-08-17):** LEFT JOIN `agsCnCtptExequtorSmplBuirg` ON БУиРГ + № договора, HAVING Count(cn_key)=0. VBA оборачивает QueryDef (`countCn` по `ags_cn`/`cnNum`). SQL: [cipuCn_CtptCnNot.access.sql](../../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_CtptCnNot.access.sql).

**QueryDef `cipuCn_Ctpt` (2026-08-17):** `CnInvPmtUplTbl` LEFT JOIN `cipuCtpt_All_OIdNot` (IS NULL) LEFT JOIN `agsOrgIdBUiRG`. Пустой `OIdNot` → анти-join никого не отсекает. SQL: [cipuCn_Ctpt.access.sql](../../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_Ctpt.access.sql). Nav: буфер **`…ExtPmTbl`** = VBA.

**Дамп QueryDef (2026-08-17 23:44):** 40 файлов [`cipu-sql/`](../../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipu-sql/) → `{Имя}.access.sql`. Кириллица целая. INSERT-цели: `ags_cn_inv_pm` / `ags_cn_inv_doc` / `ags_cnInvAccntSmpl`. `agsCnCtptExequtorSmplBuirg` снят (локальный QueryDef, не VIEW `ags.cn_s_orgExeBuirg`). `agsInvNumCount` уже есть в `access-queries/`.

**Helper `agsCnCtpt*` (2026-08-17 23:58):** агент `cn_s_type=1` + **`cnnNum`**; исполнитель `cn_s_type=2` + **`cnnNumNull`**. `*One` = ровно один `csosKey` на пару (договор, БУиРГ). SQL: [agsCnCtptAgentSmplBuirg.access.sql](../../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/agsCnCtptAgentSmplBuirg.access.sql), […One](../../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/agsCnCtptAgentSmplBuirgOne.access.sql), [Exequtor…One](../../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/agsCnCtptExequtorSmplBuirgOne.access.sql). `agsInvNumCount` совпал с [access-queries](../../../../project/proposals/vba-analysis/access-queries/agsInvNumCount.access.sql).

**Буфер `…ExtPmTbl` (2026-08-18):** локальная, 40 полей, без PK/индексов, 7736 строк. Type 20 у DocCode = **dbDecimal** (Prec. 18), не GUID. [`.table.md`](../../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_CtptCnOneInvOneAcDcExtPmTbl.table.md).

**Карта Offset `export_*` (2026-08-18):** пять файлов `2026_03/debit` (`export_{счётГК}_26-0422.XLSX`), лист `Sheet1`, якорь **U1** «№ докум.», колонки A–Z, заголовки идентичны. [export_offset-map.md](../../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/export_offset-map.md).

**Runtime InvDouble (2026-08-18):** вкладка «повторяющиеся счета-фактуры», выбран `export_606012_25-0721` (30.06.2025) — грид **0 строк**. Скрин: [29](../../UI/assets/26-0817-cn-inv-pmt-upl/29-runtime-invdouble-empty.png). Link к File пустой: это текущий буфер `TblCnInv`, не строки выбранной выгрузки.

**Шаг 8 (владелец, 2026-08-18):** `cipuCn_CtptCnOneInvTwoLoad` — **намеренно без apply**. Двоящие СФ (номер уже >1 в БД): создать новую запись или перепривязать существующую может только оператор вручную после решения. Автозапись в загрузке закрыта. Согласуется с S68 п.3 (перепривязка не в bulk). Java-воронка pmt **не** начинается в этом чате.

**Паспорт Access закрыт.** Дальше — план UI [chat-plan-26-0819-cn-inv-pmt-upl.md](./chat-plan-26-0819-cn-inv-pmt-upl.md) (задача **0072**, экран D). Не писать реализацию pmt в §5.6 / 0069.

### 5.8. 1.1.1.2 — экран FEMSQ «Загрузка платежей» (S70; не 0069)

**Рабочий план:** [chat-plan-26-0819-cn-inv-pmt-upl.md](./chat-plan-26-0819-cn-inv-pmt-upl.md) · задача **0072** · эскиз [02-9 §4b](../../UI/02-9_sudz-mvp-screens.md#4b-экран-d--загрузка-платежей-cn_inv_pm_upl--лаунчер-file_f) · резюме [chat-resume-26-0819](../chat-resume/chat-resume-26-0819-cn-inv-pmt-upl.md).

**Решение владельца (2026-08-19):** visual analog экрана C без пресетов; лог на вкладке; нижние вкладки ход / повторы СФ / стройки новые; список = все `cn_inv_pm_upl`; вкладка «выгрузки платежей» на C = мост `g_p` (1 дбт → N pmt), не этот экран. Visual v1 в FEMSQ принят владельцем 2026-08-19. Следующий чат — лаунчер File (не воронка). Детали UI — в плане 26-0819, не здесь.

Этот файл (0802) остаётся картой домена; детали UI pmt сюда не копировать.


