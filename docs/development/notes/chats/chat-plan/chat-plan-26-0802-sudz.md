# План: аналог «системы управления дебиторской задолженностью» (СУДЗ) из MS Access

**Дата создания:** 2026-08-02  
**Последнее обновление:** 2026-08-19  
**Проект:** FEMSQ  
**Версия плана:** 0.91.1 (S70: visual v1 экрана платежей 0072)  
**Задача:** 0065–0072 (дерево features **02.03**); эскизы [02-9](../../UI/02-9_sudz-mvp-screens.md); **активно: 0069** + **S68 КСДСФ** + **S68t дерево (T6 UAT)** + блокер **0071 Договоры**; **S69** паспорт Access pmt ✅; **S70** экран D / [0072](../../../project-development.json) visual v1 ✅  
**Статус плана:** ✅ 0070; **0069** CnCtptExistInvNotLoad dry ✅; **S68** CREATE+наполнение+экран (JAR **0.1.0.202**) 🔶 UAT; **S68t** T1 ✅, T4b ✅, **T5** ✅ → **T6/T6a**; **0071** 🔶 UAT; **S69** паспорт Access `CnInvPmtUpl*` ✅; **S70** visual v1 ✅  
**Паспорт pmt:** [02-11_cn-inv-pmt-upl-access.md](../../UI/02-11_cn-inv-pmt-upl-access.md) · §5.7  
**План UI pmt:** [chat-plan-26-0819-cn-inv-pmt-upl.md](./chat-plan-26-0819-cn-inv-pmt-upl.md) · §5.8  
**Резюме UI pmt (S70):** [chat-resume-26-0819-cn-inv-pmt-upl.md](../chat-resume/chat-resume-26-0819-cn-inv-pmt-upl.md)  
**Резюме pmt (S69):** [chat-resume-26-0817-cn-inv-pmt-upl.md](../chat-resume/chat-resume-26-0817-cn-inv-pmt-upl.md)


**Доменные доки:** [01-overview](../../domain/sudz/01-overview.md) · [02-glossary](../../domain/sudz/02-glossary.md) · [03-processes](../../domain/sudz/03-processes.md) · [04-data-model](../../domain/sudz/04-data-model.md) · [04-1 MS_Description](../../domain/sudz/04-1_ms-descriptions.md) · [04-3 проблемы](../../domain/sudz/04-3_problems-solutions.md) · [07-readiness (покрытие/готовность)](../../domain/sudz/07-readiness.md) · [08-target-schema (физ. схема + ER)](../../domain/sudz/08-target-schema.md)  
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
| S66 | 2026-08-15 | **0069:** `CnCtptExistInvNotLoad` — clear InvDouble + буфер TblCnInv + лог; apply inv/invNum/cnInv при flLoad | JAR **0.1.0.194**; access-queries `ciduCnExistInvNot*` | 🔶 UAT |
| S67 | 2026-08-16 | UAT 910 dry: **128** дог. / **705** СФ ✅, но rebuild **~3m14s** (CTE). Перепись на `#temp`+индексы; лог СФ усечён (8+…) | JAR **0.1.0.196** | ✅ via S67a |
| S67a | 2026-08-16 | `#temp` без COLLATE → conflict Latin1 vs Cyrillic на JOIN `cnnNumNull`. Колонки `#cidu*` → `Cyrillic_General_CI_AS` | JAR **0.1.0.197** | ✅ UAT: sqlMs=241, 128/705 |
| S68 | 2026-08-16 | **КСДСФ:** `CnInvUplSfDouble` на DEV; наполнение 1:1 Excel; bulk без очереди; экран + кнопка; create mutation | JAR **0.1.0.198**; [DDL](../../../sql/26-0816-sudz-sf-num-collision/) | 🔶 UAT |
| S68t | 2026-08-18 | **Walker ≠ FemsqTree:** JSON + каталог + обёртка. **T1** ✅ v1; срез 1 + T4b ✅. Далее срез 2 / T5 | [02-12](../../UI/02-12_femsq-tree/relation-tree.md); ADR [009](../../../../project/decisions/009-femsq-walk-tree.md); §5.6 S68t | 🔶 T5 |
| S69 | 2026-08-17 | **1.1.1.2 / паспорт `CnInvPmtUpl*`:** съём Access закрыт. Шаг 8 (`TwoLoad`) — только показ; запись/перепривязка двоящих СФ — вручную оператором. Runtime InvDouble: **0 строк**. INSERT финала: `ags_cn_inv_pm`. Java pmt — не этот чат | [02-11](../../UI/02-11_cn-inv-pmt-upl-access.md); [03 §1.1.1.2](../../domain/sudz/03-processes.md); §5.7; [съём](../../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/) | ✅ |
| S70 | 2026-08-19 | **Экран D «Загрузка платежей»:** задача **0072** visual v1 ✅, UAT владельца ✅. Вкладка `g_p` на экране свода ≠ этот лаунчер | [chat-plan-26-0819](./chat-plan-26-0819-cn-inv-pmt-upl.md); [resume 26-0819](../chat-resume/chat-resume-26-0819-cn-inv-pmt-upl.md); [02-9 §4b](../../UI/02-9_sudz-mvp-screens.md#4b-экран-d--загрузка-платежей-cn_inv_pm_upl--лаунчер-file_f); §5.8 | ✅ visual |

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
| **T6** | UAT дерева КСДСФ | очередь upl **910**, якорь `832930` | сумма/срок/исполнитель vs Excel; доменный `cnnNum` = «1»; узел выгрузки (`upl=28`) виден |
| **T6a** | Actions в `RelationTree` | walker + JSON + хост | action на папке/записи; walker отдаёт `ActionContext`, но не знает GraphQL/экранов; v1 JSON-схема actions зафиксирована в 02-12 |
| **T6b** | Универсальная форма записи / связи | `RecordModal`, `pickerSpec`, JSON | `cnInv` как первый кейс; форма возвращает `cnId + invId`; допускает доп. поля связи (`relationTypeId`, `note`, даты); v1 JSON-схема form/picker зафиксирована в 02-12 |
| **T7** | Договоры: вкладка «Счета-фактуры» | 0071 / `ContractsView` | слева `cnInv`; справа **та же** обёртка (уже после T4b/T6a) + JSON Договоров; корень `inv`/`ciInv` |
| **T8** | feQuLib только при дыре контракта **FemsqTree** v1 | отдельный чат fequlib | иначе **0016** не трогать; не путать с T9 |
| **T9** | Вынести walker в feQuLib как `FemsqWalkTree` | отдельный чат fequlib | после **T7** или когда второй продукт берёт дерево; хост FEMSQ = spec + fetch; Java-каталог не выносить |

**Предложение по исполнению — вертикальные срезы, не «сначала весь каталог».**

1. **Срез 0 (док, до кода).** T0 → T1. JSON пишем по md и останавливаемся на ревью. Пока JSON не подписан — полный каталог/`relationExpand` не расширять. ✅ T1 подписан 2026-08-19.
2. **Срез 1 (механизм).** T2 + T3 на **трёх** рёбрах (`invNum.inv`, `inv.cnInv`, `cnInv.cn`) + T4 + урезанный JSON КСДСФ только с этими детьми. На экране доказать: lazy `@load`, смена строки списка пересобирает дерево, та же строка — нет. Ручной builder пока можно оставить за флагом. ✅ 2026-08-18 (JAR 200).
3. **Срез 1.5 (контракт walker).** **T4b** сразу после среза 1, **до** полного JSON и **до T7**. Иначе второй экран и полный каталог нарастут вокруг импорта Apollo. ✅ 2026-08-18.
4. **Срез 2 (полнота КСДСФ).** ✅ 2026-08-19 (T5): полный каталог 15 рёбер; экран на `ksdsf-inv-num.tree.json`; удалены `sudz-sf-double-tree.ts`, `slice1`, `sudzSfDoubleTreeDebt`.
5. **Срез 3 (приёмка).** T6 на якоре 832930. Расхождения Excel↔домен **не** чинить кодом дерева — дерево показывает БД; разбор очереди (create vs перепривязка) остаётся операторским, как S68 п.3.
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

**Вне этого среза (не смешивать с T0–T7):** UAT create/наполнения очереди; вкладка «суммы»; адаптер pmt; массовая перепривязка СФ; `FemsqTreeList` для сторон договора; **T9** (`FemsqWalkTree`).

**Фазы S68 далее (не дерево):** UAT наполнения/create; вкладка «суммы»; адаптер pmt; перепривязка — позже.

**Практика Access (источник):** [`Form_CnInvDbtUpl_gt_File_f.cls`](../../../../project/proposals/vba-analysis/VBA-Code-Export/Form-Modules/Form_CnInvDbtUpl_gt_File_f.cls) ≈ стр. 140–247: после Excel→Tbl идёт **инлайн**-блок «отсутствующие контрагенты» (не выделен в `Sub`), затем именованные `CnNotLoad` … `CnCtptInvAccDbtExist`; `CnCtptInvAccExistDbl` закомментирован с 03.02.2023.

**Реестр stepId (оркестратор сверху вниз; чекбокс = вызывать ли шаг):**

| stepId | Access / VBA | Примечание |
|--------|--------------|------------|
| `excelToTbl` | `cidufFlTbl` → `AccountSheetTest` / `ReceivablesTest` | **не чекбокс**; переключатель «обнов. по исх?» |
| `orgNotInBuirg` | **инлайн** 140–207 | именованный шаг; **S61k** только лог |
| `CnNotLoad` | `CnNotLoad` | **S61l** лог; **S61l+** apply при `flLoad` + `rollbackSudzCnNotLoad(cnMark)` |
| `CnExistCtptNotLoad` | `CnExistCtptNotLoad` | **S61n** только лог; разбор вручную → экран **Договоры** (**S62** / **0071**) |
| `CnCtptExistInvNotLoad` | clear InvDouble + `CnCtptExistInvNotLoad` | **S66** лог+apply; **S68:** bulk без очереди SfDouble; разбор → КСДСФ |
| `CnCtptInvExistAccSmplNotLoad` | `CnCtptInvExistAccSmplNotLoad` | stub |
| `CnCtptInvExistAccSmplNotLoad` | … | |
| `invDbtDouble` | `invDbtDouble` | диагностика |
| `CnCtptInvExistAccNotLoad` | … | |
| `ciduTblCnCtptInvAccNameCountOneNot` | … | |
| `CnCtptInvAccExistDbl` | отключён 03.02.2023 | UI: disabled / не вызывать |
| `CnCtptInvAccExistDbtNotLoad` | … | |
| `CnCtptInvAccDbtExist` | финал, только показ | |

**Правила UI/API (S61f):**

1. Порядок **жёсткий** (префикс цепочки): нельзя выполнить поздний шаг, пропустив ранний (без отдельного «force» — в v1 не давать).
2. Два измерения: ☐ выполнить шаг; ☐ писать в БД (`cidufFlLoad` глобально и/или per-step).
3. Пресеты: «только org», «до договоров dry-run», «полная dry-run», «полная + apply».
4. Backend: один оркестратор + **отдельный метод на шаг** (зеркало `Private Sub`); mutation с `runSteps[]` + `flLoad`.
5. Перед apply в домен: решение **куда пишем** (`ags` / `sudz` / целевой `Dbt` — разрыв S5).

Итерации разработки: UI панели → stub-оркестратор → **excelToTbl** ✅ → **orgNotInBuirg** ✅ → **CnNotLoad** ✅ → **CnExistCtptNotLoad** ✅ → **Договоры (0071)** 🔶 → **`CnCtptExistInvNotLoad`** ✅ dry → **S68 КСДСФ / `CnInvUplSfDouble`** 🔶 → **S68t дерево** 🔶 → … → регрессия Rslt.  
**Критерии 0069** (из `project-development`): порт/адаптация match; Dbt/DbtValue + upl; UI + очередь; регрессия Rslt без ручного seed.  
**Добавлено S61c:** staging на SQL до UI. **S61f:** панель шагов вместо «всё сразу».

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


