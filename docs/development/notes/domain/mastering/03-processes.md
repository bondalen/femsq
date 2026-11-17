# Освоение лимитов — процессы (P2)

**Дата создания:** 2026-11-17  
**Последнее обновление:** 2026-11-17  
**Статус:** черновик; состав этапов уточняется реестром инвентаризации Access (трек **C1** дорожной карты R1)  
**Сводный перечень:** [business-processes.md → P2](../../../../project/business-processes.md#p2-освоение-лимитов-капитального-строительства)  
**Дорожная карта:** [chat-plan-26-1116-roadmap-r1.md](../../chats/chat-plan/chat-plan-26-1116-roadmap-r1.md)  
**SQL-стек `_2606`:** [план 0604 v2](../../chats/chat-plan/chat-plan-26-0604-spMstrg-2606-v2.md) · [решения](../../sql/26-0604/docs/03-design-decisions.md) · [карта факта ↔ stCost](../../sql/26-0604/docs/05-fact-stcost-map.md) · [наборы RS1–RS7](../../sql/26-0604/docs/06-sp-recordsets-and-acceptance.md)

---

## Назначение

Ежедневно поддерживать актуальные **планы, факт и проценты освоения** лимитов капитального строительства по цепям инвестпрограмм и выпускать отчёты по исполнению плана.

Сейчас процесс выполняется в **MS Access** на стеке **`_2605`**; ревизии актов АВ и аренды земли — в **FEMSQ JAR 156**. Цель R1 — **FEMSQ как единственный инструмент** на стеке `_2606`.

Источник сведений об Access — выгрузка VBA [`VBA-Code-Export/`](../../../../project/proposals/vba-analysis/VBA-Code-Export/) (**2026-11-17**, UTF-8, файл `24-1125_ra_R_26-1113`) и каталог C1 [`c1-inventory/raw/`](../../../../project/proposals/vba-analysis/c1-inventory/raw/) (формы 243, отчёты 72, запросы 342, linked 167). Реестр групп: [`registry.md`](../../../../project/proposals/vba-analysis/c1-inventory/registry.md). Порядок съёма: [MS-ACCESS-OBJECTS-CAPTURE §4](../../../../project/proposals/vba-analysis/MS-ACCESS-OBJECTS-CAPTURE.md).

---

## P2 1. Ввод инвестпрограмм и планов

| Этап | Access (по выгрузке VBA) | Таблицы БД | FEMSQ сейчас | Вопросы для C1 |
|------|---------------------------|------------|--------------|----------------|
| **1.1** Ведение ИП и цепей | `Form_ipg`, `Form_ipgMin`, `Form_ipgMinBranch`, `Form_ipgCh`, `Form_ipgChMin`; классы `ipg`, `ipgCh`, `ipgPn` | `ags.ipg`, `ags.ipgPn`, `ags.ipgCh`, `ipgChRl*` | `InvestmentChainsView` — только чтение (`investmentChains`, `investmentChainRelations`) | Какие формы правят данные (привязанные формы без кода) |
| **1.2** Загрузка уточнённых планов из Excel | `Form_ipg_gt_LdM_t` (`btnLoad`: просмотр/загрузка файлов, `UPDATE ags.ipgPn`, таблицы `ipgLdM*`); `Form_ipgCh_gt_impNewSumCompare` | `ags.ipgPn`, `ipgLdM*` (Access), `ags.ipgCostItsNmAll` | нет | Формат файлов, частота, сравнение сумм |
| **1.3** Помесячные планы и лимиты | `Form_ipg_gt_Pn_t_gt_UtPlP_t`; класс `ipgPnLim` | `ipgUtPlP` (широкие `iuplpM01…M12`), `ipgUtPlPnLmMn`, `ipgPnLim` | нет | Ввод вручную или из файла; разбивка по stCost 212/195/172/187 на проде отсутствует ([db-upgrade §8](../../../../deployment/db-upgrade-spMstrg-2606.md)) |
| **1.4** Справочники освоения | `Form_stNetIpg`, `Form_stNetCost`, `Form_stNet_gt_fnSt_t`, `Form_ipgStRlSh` | `stNet*`, `stIpg`, `ipgUtPlGr` | Только чтение (`stNetworks`, `investmentPrograms`, `investmentPlanGroups`) | Нужен ли ввод в FEMSQ или справочники статичны |

## P2 2. Обновление факта

Факт поступает **ревизиями** (Excel → staging → домен, форма Access `ra_a` / экран FEMSQ «Ревизии») и загрузкой ОПИ. Расчёт `_2606` читает факт через `factDocCost` и функции `fnMastering*_2606`.

| Этап | `af_type` | stCost | Таблицы домена | Access | FEMSQ (`com.femsq.web.audit`) | Прод |
|------|-----------|--------|----------------|--------|-------------------------------|------|
| **2.1** Отчёты агентов (RA) | 5 | 212, 195, 172, 187 | `ra`, `ra_summ`, `ra_summCt`, `ra_change*` | `ra_a` (`ra_aAllAgents`) | `AllAgentsAuditFileProcessor`, `AllAgentsReconcileService` | Access; редко JAR 156 |
| **2.1.0** Периоды отчётов и отправители | — | — | периоды и отправители (имена таблиц — уточнить в C1) | `Form_yyyy_gt_ra_period*`, `…_sender` | нет | Access |
| **2.2** Акты АВ 23-06 | 6 | 148 | `ogAgFee`, `ogAgFeeP` | `ra_a` (`ra_aAgFee23_06`) | `AgFee2306AuditFileProcessor`, `AgFee2306ReconcileService` | **JAR 156** |
| **2.3** Аренда земли (РАЛП) | 3 | 150 | `ralp`, `ralpRa`, `ralpRaAu` | `ra_a` | `RalpAuditFileProcessor`, `RalpReconcileService` | **JAR 156** |
| **2.4** Хранение | 2 | 205 | `cn_PrDoc`, `cn_PrDocP` | `ra_a`, запросы `cn_PrDocImp_*` | `CnPrDocAuditFileProcessor` (загрузка листа «ХрСтрКнтрл»); `CnPrDocReconcileService` — **заглушка** («type=2 reconcile is not implemented yet») | Access |
| **2.5** Строительный контроль (ССК) | 2 | 197 | то же | то же | то же | Access |
| **2.6** ОПИ | — | 169 | `cstAgPnMnrl` | импорт `mnrl_imp` (таблицы `YY-MMDD_mnrl_imp`) | нет | Access |

**Вопрос для C1 по ОПИ:** функция `fnIpgChRsltCstUtl2_2606` берёт ОПИ и из RA-источника (`raFactMnrl`), и из `cstAgPnMnrl` — нужно подтвердить, какой канал основной.

Подробно по ревизиям: [ra-audit-btnAuditRun-analysis.md](../../analysis/ra-audit-btnAuditRun-analysis.md) (§10.6 — таблица `af_type`), планы [0707](../../chats/chat-plan/chat-plan-26-0707-ralp-reconcile.md) (тип 3), [0720](../../chats/chat-plan/chat-plan-26-0720-agfee-type6.md) (тип 6), [0323](../../chats/chat-plan/chat-plan-26-0323-reconcile-specific.md) (типы 2/5).

## P2 3. Расчёт освоения

| Этап | Access | SQL | FEMSQ |
|------|--------|-----|-------|
| **3.1** Расчёт по цепи ИП | `Form_ipgChMin`: `btnMasteringPercent_2408_Click` (сейчас `spMstrg_2605`, `cbxIpgSt`), `btnMasteringPercent`, `btnMasteringCst` | `spMstrg_2605` (RS1–RS7, `@saveToTables`); целевой `spMstrg_2606` (17 дат, LmMn@212 — Решение 22) | `execute_spMstrg_2605.sh` для Jasper; `_2606` — DEV |
| **3.2** Помесячное освоение со стройками и прежние расчёты | `Form_yyyyM` (`btn_obtainUtl` → `spIpgChRsltCstUtl3_GP_cst` → `ipgChRsltPlCst`); `Form_ipgCh*` читают `ipgChRslt`, `ipgChRsltPl`, `ipgChRsltFull`, `fnIpgChRsltCstUtlPercentBrn` | `spIpgChRsltCstUtl3_GP_cst` и др. | нет |

**Вопрос для C1:** используются ли 3.2 и потребители `ipgChRslt*`; если да — чем `_2606` их заменяет.

## P2 4. Отчёты

| Этап | Access | FEMSQ |
|------|--------|-------|
| **4.1** Исполнение плана | ≈27 отчётов `Report_mstrgAg*` (`_23_Branch_q2m_2408_25`, `_dg_z_*`, `_Risk*`, `_Src*`, `_oneCst*`, …) на наборах `spMstrg_*` | Jasper `mstrgAg_23_Branch_q2m_2408_25` (на `spMstrg_2408_ResultSet*`); UI отчётов — каталог карточек |
| **4.2** Стройки вне инвестпрограммы | `Report_ipgOutSide`, `_Diag`, `_gt_RRcListView`, `Report_s_ipgOutSide` | нет |
| **4.3** Выгрузка в Excel | — (уточнить в C1) | частично |

**Вопрос для C1:** какие варианты `mstrgAg_*` реально используются — карточки Jasper (C5) делаются только для них.

---

## Связь с треками R1

| Этап | Трек |
|------|------|
| P2 1.1–1.4, 2.1.0 | C2 |
| P2 2.1–2.6 | C3 |
| P2 3.1–3.2 | A (SQL-тест), C4 |
| P2 4.1–4.3 | C5 |
| Переключение клиентов, отключение форм Access | C7 |

---

## Журнал правок

| Дата | Версия | Что изменили |
|------|--------|----------------|
| 2026-11-17 | 0.1.0 | Создан: этапы P2 1–4 с объектами Access, таблицами, компонентами FEMSQ и вопросами для C1 |
