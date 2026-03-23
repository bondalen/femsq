# Таблица Access: `cn_PrDocImp`

**Статус описания:** **достаточно для дальнейшей работы** по метаданным Access — в DAO-дампе непрерывно перечислены **55 полей** (OrdinalPosition 0–54), типы, размеры, `Required`, `Description` / `Caption` (где выводились). Индексы и связи в дампе **пустые**. Скриншоты конструктора совпадают с дампом и полезны для визуальной сверки.

**Назначение:** локальный буфер импорта первичных документов с листа **`ХрСтрКнтрл`** (`af_type = 2`); в VBA очищается перед чтением Excel и заполняется при разборе (`RAAudit_cn_PrDoc`, см. `Form_ra_a.cls`). В Java/SQL Server перенос строк — в **`ags.ra_stg_cn_prdoc`** (состав колонок **уже** по DDL; в Access есть дополнительные вычисляемые и FK-поля, которых нет в staging — см. ниже).

**Источник метаданных:** `DumpTableDef_Extended "cn_PrDocImp", ...` + UTF-8-файл (тот же модуль, что и для `ra_ImpNew`: [`DumpTableDef_RaImpNew.bas`](./DumpTableDef_RaImpNew.bas)).

**Метаданные таблицы (TableDef):** локальная таблица; `DateCreated` 11.01.2022; `LastUpdated` 14.10.2022; в свойствах `RecordCount = 405`. Строка `RecordCount (SELECT COUNT): ... Err=3008` в дампе — таблица могла быть занята другим сеансом Access; на полноту списка полей не влияет.

**Ошибки 3008 у части Field.Properties (`Precision` / `Scale`):** известный эффект для части типов/вычисляемых полей при чтении через DAO; тип поля и размер в шапке `FIELD:` остаются достоверными.

**lastUpdated:** 2026-03-19

---

## Поля (DAO)

Типы: `2`=Byte, `4`=Long, `5`=Currency, `7`=Double, `8`=Date, `10`=Text.

| Имя поля | Type | Size | Required | Примечание (Description / Caption из дампа) |
|----------|------|------|----------|---------------------------------------------|
| `NumSequential` | 4 | 4 | no | В staging SQL Server: `cnpdNumSequential` |
| `cnpdKey` | 4 | 4 | no | Суррогатный ключ строки в буфере (аналог идентичности позже в `ags.ra_stg_cn_prdoc.cnpd_key`) |
| `cnpdTpOrd` | 10 | 255 | no | в источнике: ВидЗаказаНаПоставку |
| `cnpdTpOrdKey` | 4 | 4 | no | Резолв типа заказа (Stage 2 в Java; в `ra_col_map` не маппится из Excel) |
| `cnpdNum` | 10 | 255 | no | — |
| `cnpdNumNull` | 10 | 243 | no | Перв. документ, №, с учётом Null |
| `cnpdDate` | 8 | 8 | no | — |
| `cnpdDateNull` | 8 | 8 | no | Перв. документ, дата, с учётом Null |
| `cnpdCnInv` | 4 | 4 | no | — |
| `cnpdCnInvNum` | 10 | 255 | no | в источнике: Номер вх. Счета-фактуры |
| `cnpdCnInvNumNull` | 10 | 243 | no | Счёт-фактура, №, с учётом Null |
| `cnpdCnInvDate` | 8 | 8 | no | в источнике: Дата вх. Счета-фактуры |
| `cnpdCnInvDateNull` | 8 | 8 | no | Счёт-фактура, дата, с учётом Null |
| `cnpdCnNum` | 10 | 255 | no | — |
| `cnpdCnNumNull` | 10 | 243 | no | Договор, №, с учётом Null |
| `pdpKey` | 4 | 4 | no | — |
| `pdpCstAgPnStr` | 10 | 255 | no | в источнике: Определение проекта |
| `pdpCstAgPnKey` | 4 | 4 | no | Резолв проекта (Stage 2; в `ra_col_map` не из Excel) |
| `StatusOfDICtext` | 10 | 255 | no | в источнике: Статус ДИС (текст) |
| `satstusOfOUKVtext` | 10 | 255 | no | в источнике: Статус ОУКВ (текст) *(имя поля с опечаткой `satstus` — как в Access)* |
| `summ` | 5 | 8 | no | в источнике: Сумма; формат `#,##0.00 ₽` |
| `cost` | 5 | 8 | no | в источнике: Стоимость |
| `SumTax` | 5 | 8 | no | в источнике: Сумма налога |
| `costVAT` | 5 | 8 | no | в источнике: Стоимость с НДС |
| `SPPelement` | 10 | 255 | no | в источнике: СПП-элемент |
| `AccountMain` | 4 | 4 | no | Основной счет *(в staging DDL колонка `AccountMain` — `NVARCHAR`; расхождение типа Access↔SQL — учитывать при миграции)* |
| `docOfAccountNum` | 10 | 255 | no | № документа счета |
| `docOfAccountNumNull` | 10 | 243 | no | № документа счета, с учётом Null |
| `AccountDate` | 8 | 8 | no | в источнике: Дата счета |
| `positingDate` | 8 | 8 | no | в источнике: Дата проводки |
| `accountingDoc` | 10 | 255 | no | Бухг. документ |
| `accountingDocNull` | 10 | 243 | no | Бухг. документ, с учётом Null |
| `agent` | 4 | 4 | no | в источнике: Агент |
| `TextOfAgent` | 10 | 255 | no | Текст агента |
| `prjctDefinition` | 10 | 255 | no | Определение проекта |
| `prjctDefinitionSort` | 10 | 255 | no | Краткое описание проекта |
| `prjctHierarchyLevel` | 7 | 8 | no | Уровень в иерархии проекта *(Double в DAO; в staging — строка)* |
| `ParentSppElementNum` | 10 | 255 | no | Номер вышестоящего СПП-Элемента |
| `object` | 10 | 255 | no | Объект *(в SQL Server staging: `Object`)* |
| `objectNull` | 10 | 243 | no | Объект, с учётом Null |
| `cstDSW` | 10 | 255 | no | Стройка/ПИР |
| `raNum` | 10 | 255 | no | Номер отчета Агента |
| `raDate` | 8 | 8 | no | Дата отчета Агента |
| `CorrectionNum` | 10 | 255 | no | Номер исправления |
| `CorrectionDate` | 8 | 8 | no | Дата исправления |
| `accountingDocName` | 10 | 255 | no | Название бух док-та |
| `purchasingGroup` | 10 | 255 | no | Группа закупок |
| `purchasingGroupName` | 10 | 255 | no | Название ГрЗакупок |
| `textOfCreditor` | 10 | 255 | no | Текст кредитора |
| `supplierTIN` | 10 | 255 | no | ИНН поставщика |
| `supplierKPP` | 10 | 255 | no | КПП поставщика |
| `supplierOrgId` | 4 | 4 | no | ключ исполнителя по договору |
| `cn_key` | 4 | 4 | no | ключ договора |
| `cn_s_key` | 4 | 4 | no | ключ стороны договора |
| `csosKey` | 4 | 4 | no | ключ организации - простой стороны договора |

Поля с суффиксом **`Null`** — вычисляемые в Access варианты «с учётом Null» для соответствующих исходных колонок.

---

## Индексы и связи

По дампу: **индексов нет**, **relations** не выведены.

---

## Ссылка на схему в проекте

Staging в SQL Server: **`ags.ra_stg_cn_prdoc`** — Liquibase `code/femsq-backend/femsq-web/src/main/resources/db/changelog/changes/2026-03-20-ra-audit-staging.sql` (в т.ч. `cnpd_exec_key` для изоляции сеанса — в исходной Access-таблице этого поля нет).

Маппинг Excel → staging: `ags.ra_col_map` для `rsc_key`, соответствующего листу **`ХрСтрКнтрл`** (`af_type = 2`).

---

## Запросы и объекты Recordset (контур S.2.2, `af_type = 2`)

Да: для **полного закрытия** пункта **S.2.2** нужно вынести в репозиторий SQL **каждого сохранённого запроса** (и при необходимости — **представления linked server**), из которого VBA открывает `Recordset`, плюс явные `QueryDefs`.

**Важно:** имя **`cn_PrDocImp`** без суффикса — это **локальная таблица** (описана выше в этом файле). В коде её открывают как `OpenRecordset("cn_PrDocImp", …)` — это **не** отдельный `.access.sql`.

| Имя в Access | Тип (ожидаемо) | Файл в репозитории | Статус |
|--------------|----------------|-------------------|--------|
| `cn_PrDocImp` | **TableDef** (таблица) | — (уже этот `.table.md`) | ✅ |
| `cn_PrDocImp_Compare` | сохранённый запрос; `db.QueryDefs("cn_PrDocImp_Compare")` | [`cn_PrDocImp_Compare.access.sql`](./cn_PrDocImp_Compare.access.sql) | ✅ |
| `cn_PrDocImp_Cn` | запрос / linked view | [`cn_PrDocImp_Cn.access.sql`](./cn_PrDocImp_Cn.access.sql) | ✅ |
| `cn_PrDocImp_CnInv` | запрос (базовое звено цепочки `CnInv*`) | [`cn_PrDocImp_CnInv.access.sql`](./cn_PrDocImp_CnInv.access.sql) | ✅ |
| `cn_PrDocImp_CnInvEx` | запрос (цепочка `CnInv*`, до вариантов ExCsos…) | [`cn_PrDocImp_CnInvEx.access.sql`](./cn_PrDocImp_CnInvEx.access.sql) | ✅ |
| `cn_PrDocImp_CnInvExCsosEx` | запрос; использует **`cn_PrDocImp_CnInvEx`** + `cn_PrDocImp` | [`cn_PrDocImp_CnInvExCsosEx.access.sql`](./cn_PrDocImp_CnInvExCsosEx.access.sql) | ✅ |
| `cn_PrDocImp_CnInvExCsosExPdEx` | запрос; от **`cn_PrDocImp_CnInvExCsosEx`** + `ags_cn_PrDoc` | [`cn_PrDocImp_CnInvExCsosExPdEx.access.sql`](./cn_PrDocImp_CnInvExCsosExPdEx.access.sql) | ✅ |
| `cn_PrDocImp_CnInvExCsosExPdExPnEx` | запрос; от **`cn_PrDocImp_CnInvExCsosExPdEx`** + `ags_cn_PrDocP` | [`cn_PrDocImp_CnInvExCsosExPdExPnEx.access.sql`](./cn_PrDocImp_CnInvExCsosExPdExPnEx.access.sql) | ✅ |
| `cn_PrDocImp_CnInvExCsosExPdExPnNt` | запрос; вариант PnEx с `pdpKey Is Null`; источник для **PnNtIn** | [`cn_PrDocImp_CnInvExCsosExPdExPnNt.access.sql`](./cn_PrDocImp_CnInvExCsosExPdExPnNt.access.sql) | ✅ |
| `cn_PrDocImp_CnInvExCsosExPdExPnNtOneAccDoc` | запрос; JOIN к `ags_cn_PrDocP` без `accountingDocNull` в ON; `WHERE` — расхождение `accountingDocNull` буфер vs БД | [`cn_PrDocImp_CnInvExCsosExPdExPnNtOneAccDoc.access.sql`](./cn_PrDocImp_CnInvExCsosExPdExPnNtOneAccDoc.access.sql) | ✅ |
| `cn_PrDocImp_CnInvNt` | запрос; СФ в буфере без `ciKey` на сервере; `inKeyCount`; `OpenRecordset` в `Form_ra_a.cls` | [`cn_PrDocImp_CnInvNt.access.sql`](./cn_PrDocImp_CnInvNt.access.sql) | ✅ |
| `cn_PrDocImp_CnInvExCsosNt` | запрос; вариант CsosEx + `ags_accnt` в `z`; `HAVING y.ciasKey Is Null`; `OpenRecordset` в `Form_ra_a.cls` | [`cn_PrDocImp_CnInvExCsosNt.access.sql`](./cn_PrDocImp_CnInvExCsosNt.access.sql) | ✅ |
| `cn_PrDocImp_CnInvExCsosExPdNt` | запрос; вариант PdEx «нет шапки ПД» + слабый JOIN; `NumDateCount` для `RAAudit_cn_PrDoc_cnInvExCsosExPdNt` | [`cn_PrDocImp_CnInvExCsosExPdNt.access.sql`](./cn_PrDocImp_CnInvExCsosExPdNt.access.sql) | ✅ |
| `cn_PrDocImp_CnInvExCsosExPdExPnNtIn` | запрос; от **`cn_PrDocImp_CnInvExCsosExPdExPnNt`** + `cn_PrDocImp` + `ags_cn_PrDocP`; `OpenRecordset("cn_PrDocImp_CnInvExCsosExPdExPnNtIn", …)` в `Form_ra_a.cls` | [`cn_PrDocImp_CnInvExCsosExPdExPnNtIn.access.sql`](./cn_PrDocImp_CnInvExCsosExPdExPnNtIn.access.sql) | ✅ |
| `cn_PrDocImp_CnInvExCsosExPdExPnExRs` | запрос; `OpenRecordset("cn_PrDocImp_CnInvExCsosExPdExPnExRs", …)` в `Form_ra_a.cls` | [`cn_PrDocImp_CnInvExCsosExPdExPnExRs.access.sql`](./cn_PrDocImp_CnInvExCsosExPdExPnExRs.access.sql) | ✅ |

Запросы **`cn_PrDocImp_CnInv…`** в Access часто выстроены **цепочкой** (следующий может ссылаться на предыдущий). Пока фиксируем каждый объект отдельным `*.access.sql`; **избыточные** запросы можно будет удалить в `.accdb` и в этом списке после ревью.

**Дополнительно (не из этого списка):** динамический `QueryDef` **`ags_PdSdRRcList`** (подстановка `.SQL` в VBA) зафиксирован в [`ags_PdSdRRcList.access.sql`](./ags_PdSdRRcList.access.sql) — шаблоны и ссылка на `Module1.bas` / `Form_ra_a.cls`.

**Порядок:** исходный текст → `.txt` → доработка → `{Имя}.access.sql` ([MS-ACCESS-OBJECTS-CAPTURE.md](../MS-ACCESS-OBJECTS-CAPTURE.md) §3). Список в плане: **`chat-plan-26-0319-excel-processing-parallel.md`**, **S.2.2**.
