# Платежи — эталон Access `CnInvPmtUpl*` (процесс 1.1.1.2)

**Дата создания:** 2026-08-17  
**Последнее обновление:** 2026-08-18 (DumpTableDef буфера `…ExtPmTbl`)  
**Статус:** 🔶 паспорт; QueryDef и буфер шага 12 **сняты**. Осталось: `.cls` (родитель / Sum_t / InvDouble / invNum / CstNew), полный RS File_f, Excel Offset. **UI FEMSQ для pmt не проектируем**, пока паспорт не закрыт  
**Скрины Design/SQL/Runtime:** [assets/26-0817-cn-inv-pmt-upl/README.md](./assets/26-0817-cn-inv-pmt-upl/README.md)  
**Съём таблиц:** [26-0813_CnInvPmtUpl_/](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/)  
**Метод съёма:** [MS-ACCESS-OBJECTS-CAPTURE.md](../../../project/proposals/vba-analysis/MS-ACCESS-OBJECTS-CAPTURE.md)  
**Процесс:** [03-processes §1.1.1.2](../domain/sudz/03-processes.md)  
**Алгоритм VBA:** [04-data-model §2.9](../domain/sudz/04-data-model.md#29-алгоритм-btnupload_click--cninvpmtupl-процесс-1112-каркас-s69)  
**План СУДЗ (инвентарь, не 0069):** [chat-plan-26-0802-sudz.md](../chats/chat-plan/chat-plan-26-0802-sudz.md) §5.3 / §5.7  
**Соседние чаты (не смешивать):** воронка долгов `CnInvDbtUpl` / 0069; КСДСФ (S68) — только ссылка на переиспользование очереди

---

## 1. Зачем паспорт сейчас

Шаг **1.1.1.2** грузит `export_{счётГК}_*` в FishEye.ags через семейство форм **`CnInvPmtUpl*`**. Общий свод (1.1.1.1) **не содержит** привязки к стройке / САК; специалисты работают только с объектами — поэтому после свода нужна эта выгрузка.

Этот документ — **карта Access** (UI, VBA, таблицы, запросы). Реализация Java-воронки платежей **вне scope**, пока паспорт закрыт. Эскиз FEMSQ для pmt — отдельное решение после полноты съёма.

**Не додумываем** RecordSource / Link Master/Child / SQL сохранённых запросов: ждём скрин конструктора или UTF-8-дамп QueryDef.

---

## 2. Покрытие репозитория (сверка, не пересъём вслепую)

### 2.1. Таблицы Access → `sudz` (S61d)

| Таблица | Роль | Съём | SQL `sudz` |
|---------|------|------|------------|
| `CnInvPmtUplFile` | шапка лаунчера: path, `flLoad`, `flTbl`, лог, **`cipufSheet`** (листа FileSh **нет**) | `.table.md` + dump + `data.csv` (30 записей) | `26_`/`27_` — File=30 |
| `CnInvPmtUplTbl` | staging Excel (~7736 в снимке, `ciputUnloadKey=32`) | `.table.md` + csv | таблица есть; seed строк **нет** (для воронки позже) |
| `CnInvPmtUplTblCnInv` | буфер «новые СФ»; шире dbt (`ctpt`, date, `csos`, `CiKey`, `CnInvNumCount`) | `.table.md`, 0 строк | пустая |
| `CnInvPmtUplTbl_1` | дубль Tbl, 0 строк | `.table.md` | **не** переносили |
| `cipuCn_CtptCnOneInvOneAcDcExtPmTbl` | эфемерный буфер шага 12 (готовые PM) | [`.table.md`](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_CtptCnOneInvOneAcDcExtPmTbl.table.md) + dump; 40 полей, 7736 строк, без PK | **не** в `sudz` |

Отдельной `FileInvDouble` у платежей **нет** (S68): грид InvDouble — view над `TblCnInv`. Архив `…ExtPmTblOld` не снимать. Раннее чтение `ExtPmtTbl` (лишняя `t`) — ошибка съёма 01b.

### 2.2. VBA (`VBA-Code-Export/Form-Modules/`)

| Модуль | Объект Access | Строк (прибл.) | Статус |
|--------|---------------|----------------|--------|
| `Form_CnInvPmtUpl_gt_File_f.cls` | `CnInvPmtUpl>File_f` | ~1811 | ✅ есть: `btnUpload`, `btnInvCreate`, `btnCstNewCreate`, `btnTestWord`, воронка `cipu*` |
| `Form_CnInvPmtUpl_gt_File_f_gt_InvDouble_gt_invNum_gt_cnInv.cls` | `…>InvDouble>invNum>cnInv` | ~20 | ✅ есть: `cnName_DblClick` → `OpenForm "invNum"` |
| родитель `CnInvPmtUpl` | главная | — | ❌ нет `.cls`; **`_2` нет**; RS = `ags_cn_inv_pm_upl` |
| `CnInvPmtUpl>Sum_t` | вкладка родителя «счета, сумма» | — | ❌ нет `.cls`; **не было в кадре Nav** `CnInvPmtUpl*` |
| `…>File_f>InvDouble` | грид повторов СФ | — | ❌ нет `.cls` |
| `…>InvDouble>invNum` | nested | — | ❌ нет `.cls` |
| `…>File_f>CstNew` | вкладка «стройки новые» | — | ❌ нет `.cls` |

`SqlLong.bas`: функция `SqlCipuCn_CtptCnNot()` — SQL «отсутствующие договоры» клеится в VBA (читает QueryDef **`cipuCn_CtptCnNot`**). Текст функции в репозитории есть; QueryDef снят: [`cipuCn_CtptCnNot.access.sql`](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_CtptCnNot.access.sql).

### 2.3. Запросы (`*.access.sql`)

На префиксе **`CnInvPmtUpl*`** (Nav, 2026-08-17) два QueryDef; на префиксе **`cipu*`** снят первый живой шаг воронки:

| Запрос | Роль | Съём |
|--------|------|------|
| `CnInvPmtUplTbl_CstNew` | вкладка «стройки новые»: из `cipuCacNot` берёт `cacOrNull`; `Right(…,6)` = `sh` ↔ `ags_cstAgPn.cstapIpgPnN`; `Right(…,7)` = `cccD` ↔ `tblPIR.pirIDnew` (+ `pirName`) | [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/CnInvPmtUplTbl_CstNew.access.sql) |
| `CnInvPmtUplTblNull` | нормализация `CnInvPmtUplTbl`: `cacOrNull` (11 символов с `-` в 4-й позиции из CAC или Link), договор/СФ → `NullИлиПусто`, LEFT JOIN `ags_cstAgPn` / `ags_cstAg`. **Не** фильтр «только пустой CAC» — в datasheet есть и заполненные, и пустые `cacOrNull`. Access принимает `b.a.ciputLink`: в конструкторе поле называется **`a.ciputLink`**, таблица **`b`** ([21d](../../UI/assets/26-0817-cn-inv-pmt-upl/21d-design-CnInvPmtUplTblNull-a-ciputLink.png)) — колонка подзапроса унаследовала префикс внутреннего алиаса, это не путь `b.a.поле`. | [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/CnInvPmtUplTblNull.access.sql); [datasheet](../../UI/assets/26-0817-cn-inv-pmt-upl/21-runtime-CnInvPmtUplTblNull.png) |
| `cipuCacNot` | шаг 2 `btnUpload` + источник `CnInvPmtUplTbl_CstNew`: уникальные непустые `cacOrNull` из `CnInvPmtUplTblNull`, для которых LEFT JOIN к `ags_cstAgPn` не дал `cstapCsta` (`HAVING … Is Null`). VBA только лог. Access: `HAVING` по полю из `GROUP BY` законен, даже если поле не в `SELECT`. | [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCacNot.access.sql); [22](./assets/26-0817-cn-inv-pmt-upl/22-sql-cipuCacNot.png) |
| `cipuCtpt_All_OIdNot` | шаг 1 `btnUpload`: контрагенты Excel без `org_id`. SQL: `CntrPrtNum`, `CntrPrtName`, `org_id_key` из **`cipuCtpt_All_OId`** WHERE `org_id_key is null`. Имя = **OId** (org_id), не архивный **Old**. Nav может показать `OidNot` (регистр не важен). VBA читает этот QueryDef, только лог. | [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCtpt_All_OIdNot.access.sql); [23](./assets/26-0817-cn-inv-pmt-upl/23-sql-cipuCtpt_All_OIdNot.png) |
| `cipuCtpt_All_OId` | родитель шага 1: `cipuCtpt_All` **INNER JOIN** `agsOrgIdBUiRG` ON `CntrPrtNum` = `org_id_value_l`. `agsOrgIdBUiRG` — QueryDef Access: `ags_org_id` WHERE `org_id_type=1` (БУиРГ). | [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCtpt_All_OId.access.sql); [24](./assets/26-0817-cn-inv-pmt-upl/24-sql-cipuCtpt_All_OId.png) |
| `cipuCtpt_All` | уникальные (номер, имя) из `CnInvPmtUplTbl`: **UNION** контрагента (`ciputCntrPrt*`) и агента (`ciputAgent*`), затем оба NOT NULL. Шаг 1 смотрит и тех, и других. Nav-фильтр `cipuCtpt_All` показывает `All`, `All_Old` (legacy), `All_OidNot` — **Old ≠ OId**. | [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCtpt_All.access.sql); [25](./assets/26-0817-cn-inv-pmt-upl/25-sql-cipuCtpt_All.png) |
| `agsOrgIdBUiRG` | срез БУиРГ: `org_id_value_l`, `org_id_key` из `ags_org_id` WHERE `org_id_type=1`. Linked `ags_org_id` = `ags.org_id`. | [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/agsOrgIdBUiRG.access.sql) |
| `agsCnCtptExequtorSmplBuirg` | договоры с исполнителем (простая карточка): `ags_cn` ⋈ `cn_s` **type=2** ⋈ `cn_s_org_smpl` ⋈ `org_id` type=1 ⋈ `og` ⋈ `cnNum` (**`cnnNumNull`**). Не VIEW `ags.cn_s_orgExeBuirg` (там полная `cn_s_org`). | [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/agsCnCtptExequtorSmplBuirg.access.sql) |
| `agsCnCtptExequtorSmplBuirgOne` | уникальная пара (договор, БУиРГ исполнителя) с ровно одним `csosKey`. Источник шага 3 `cipuCn_CtptCnOne`. | [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/agsCnCtptExequtorSmplBuirgOne.access.sql) |
| `agsCnCtptAgentSmplBuirg` | то же дерево, но **агент/заказчик**: `cn_s_type=1`; номер договора — **`cnnNum`** (не `cnnNumNull`). Источник шагов 5–6 (`cipuCn_Ag` / `cipuCn_AgntCnOne`). | [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/agsCnCtptAgentSmplBuirg.access.sql) |
| `agsCnCtptAgentSmplBuirgOne` | уникальная пара (договор, БУиРГ агента) с ровно одним `csosKey`. Источник `cipuCn_AgOne`. | [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/agsCnCtptAgentSmplBuirgOne.access.sql) |
| `cipuCn_CtptCnNot` | шаг 3: пары (БУиРГ + № договора) из `cipuCn_Ctpt`, которых нет в `agsCnCtptExequtorSmplBuirg` (LEFT JOIN, `HAVING Count(cn_key)=0`). `CnName` пустой → `NullИлиПусто`. VBA оборачивает QueryDef (`SqlCipuCn_CtptCnNot`) и считает схожие № в `ags_cn`/`cnNum` как `countCn`. | [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_CtptCnNot.access.sql); [26](./assets/26-0817-cn-inv-pmt-upl/26-sql-cipuCn_CtptCnNot.png) |
| `cipuCn_Ctpt` | вход шага 3: уникальные (контрагент, № договора, `org_id_key`) из `CnInvPmtUplTbl`. LEFT JOIN `cipuCtpt_All_OIdNot` WHERE `b.CntrPrtNum` Is Null (задумано: только те, у кого уже есть БУиРГ). Из-за пустого `OIdNot` анти-join никого не отсекает. Затем LEFT JOIN `agsOrgIdBUiRG`. Только `ciputCntrPrt*`, не агенты. | [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_Ctpt.access.sql); [27](./assets/26-0817-cn-inv-pmt-upl/27-sql-cipuCn_Ctpt.png) |

Живой контур **`cipu*`** (40 QueryDef, без Old) и helper’ы **`agsCnCtpt*SmplBuirg*`** сняты дампом 2026-08-17: сырьё [`cipu-sql/`](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipu-sql/), в паспорт — `{Имя}.access.sql`. Кириллица `NullИлиПусто` в дампе целая. `agsInvNumCount` совпал с уже снятым [`access-queries/agsInvNumCount.access.sql`](../../../project/proposals/vba-analysis/access-queries/agsInvNumCount.access.sql) — повтор в паспорт не копировали.

### 2.4. Точечно снято ранее (S68, не полный паспорт)

- `File_f` RecordSource = SELECT полей `CnInvPmtUplFile` (подтверждено Design 2026-08-17; на скрине строка обрезана после `cipufPa…`).
- Вкладки File_f (design): ход загрузки | повторяющиеся счета-фактуры | стройки новые | прочее.
- InvDouble RecordSource = `TblCnInv` LEFT JOIN (`cnInv`⋈`invNum`) WHERE `ciputciCnInvNumCount` Is Not Null; `nnn`=«есть», если `ciCn` не Null — **подтверждено Design 2026-08-17**.
- Link InvDouble↔File: пустые Master/Child — **подтверждено**.
- Nested: InvDouble → invNum (**Основные `ciputciCnInv` / Подчинённые `inNumNull`**) → cnInv (**Основные `inInv` / Подчинённые `ciInv`**) — **подтверждено**.
- `btnInvCreate`: `invCreateNewNumDate` + `cnInvCreateNewInvCn` + Requery.
- Подсказка: «для просмотра существующего СФ — двойной клик на договор».
- CstNew: `cstAgPnByNameAndCodeNew` (имя/код).

---

## 3. Иерархия объектов

Nav, фильтр `CnInvPmtUpl`: [00-nav](./assets/26-0817-cn-inv-pmt-upl/00-nav-CnInvPmtUpl.png). Design родителя: [10](./assets/26-0817-cn-inv-pmt-upl/10-design-main-recordsource.png)–[13](./assets/26-0817-cn-inv-pmt-upl/13-design-main-tab-other.png).

**Таблицы (4):** `CnInvPmtUplFile`, `CnInvPmtUplTbl`, `CnInvPmtUplTbl_1`, `CnInvPmtUplTblCnInv`.

**Запросы (2 на этом префиксе):** `CnInvPmtUplTbl_CstNew`, `CnInvPmtUplTblNull`.

```text
CnInvPmtUpl                            ← RS = ags_cn_inv_pm_upl; Order By cn_inv_pm_date DESC
├── шапка: cn_inv_pm_date | cn_inv_pm_name | cn_inv_pm_key
└── вкладки родителя:
    ├── загрузка
    │   └── File_f                     ← Source = CnInvPmtUpl>File_f
    │       Link Master/Child: cn_inv_pm_key ↔ cipufUpload
    │       RS File_f: SELECT … FROM CnInvPmtUplFile (строка обрезана)
    │       ├── ход загрузки           → cipufLoadingProgress
    │       ├── повторяющиеся СФ
    │       │   └── InvDouble          ← Link к File_f пустой
    │       │       RS: TblCnInv LEFT JOIN (cnInv⋈invNum) WHERE count Is Not Null
    │       │       nnn = «есть» если ciCn не Null
    │       │       └── invNum         ← Master ciputciCnInv / Child inNumNull
    │       │           RS: SELECT * поля FROM ags_invNum
    │       │           └── cnInv      ← Master inInv / Child ciInv
    │       │               RS: ags_cnInv INNER JOIN ags_cn
    │       ├── стройки новые
    │       │   └── CstNew             ← Link к File_f пустой
    │       │       RS: SELECT 5 полей FROM QueryDef CnInvPmtUplTbl_CstNew
    │       └── прочее                 → только cipufKey, cipufUpload
    ├── счета, сумма
    │   └── Sum_t                      ← Source = CnInvPmtUpl>Sum_t
    │       Link: cn_inv_pm_key ↔ cn_inv_pm_upl
    │       RS: SELECT 9 полей FROM ags_q_cn_inv_pm_upl_sum
    └── прочее                         ← в Design видимых controls нет (пустой контейнер)
```

Форма **`CnInvPmtUpl>Sum_t`** в кадре Nav `CnInvPmtUpl*` не попала (должна быть ниже `File_f*`) — при случае прокрутить Nav до конца. `CnInvPmtUpl_2` нет.

**Отличие от долгов:** нет `FileSh`; лист = `cipufSheet`. У dbt внешние вкладки шире (листы / долги правка / чтение / pm-мост); здесь три вкладки родителя.

---

## 4. UI вкладок (по скринам Design)

| Зона | Controls | RecordSource / Source Object | Link Master/Child | События |
|------|----------|------------------------------|-------------------|---------|
| родитель `CnInvPmtUpl` | `cn_inv_pm_date`, `cn_inv_pm_name`, `cn_inv_pm_key` | **`ags_cn_inv_pm_upl`**; Order By `cn_inv_pm_date DESC`; Add/Del/Edit = Да | — | `.cls` нет |
| вкладка «загрузка» | subform `File_f` | объект `CnInvPmtUpl>File_f` | **`cn_inv_pm_key` ↔ `cipufUpload`** | — |
| шапка File_f | `cipufSheet` («лист:»), `cipufPath`, ☑ «обновлять?», ☑ «обнов. по исх?», кнопка **«загрузка»**; служебные `cipufKey`, `cipufUpload` | SELECT полей `CnInvPmtUplFile` (обрезка на скрине) | см. выше | `btnUpload_Click` |
| File_f «ход загрузки» | `cipufLoadingProgress` | то же File | — | лог VBA |
| File_f «повторяющиеся СФ» | кнопка «создать новый счёт-фактуру»; подсказка про двойной клик на договор; subform InvDouble | объект `…>InvDouble`; [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/CnInvPmtUpl_InvDouble.recordsource.access.sql) | **пустые** (подтверждено Design) | `btnInvCreate_Click` на File_f |
| InvDouble (форма) | поля `ciputci*` + `nnn` | `TblCnInv AS d` LEFT JOIN `(cnInv⋈invNum)` ON номер+`cn_key`; WHERE `ciputciCnInvNumCount` Is Not Null; `nnn`=«есть» если не `IsNull(ciCn)` | — | Add/Del/Edit = Да |
| nested `invNum` | `inKey`, `inNum`, `inNote`, `inInv`, `inTimeOfEntry`, `inNumNull` | SELECT из **`ags_invNum`** ([SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/CnInvPmtUpl_invNum.recordsource.access.sql)) | **Основные `ciputciCnInv` / Подчинённые `inNumNull`** | `.cls` нет |
| nested `cnInv` | `cnName`, `ciKey`, `ciCn`, `ciNote`, `ciMark`, `ciInv`, `ciTimeOfEntry` | `ags_cnInv` INNER JOIN `ags_cn` ([SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/CnInvPmtUpl_cnInv.recordsource.access.sql)) | **Основные `inInv` / Подчинённые `ciInv`** | `cnName_DblClick` |
| File_f «стройки новые» | кнопки «проверить по слову», «создать новую стройку»; subform CstNew | объект `…>CstNew`; QueryDef **`CnInvPmtUplTbl_CstNew`** ([SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/CnInvPmtUplTbl_CstNew.access.sql)); форма — SELECT 5 полей с алиасами `Выражение*` | **пустые** | `btnTestWord_Click` / `btnCstNewCreate_Click` |
| CstNew (форма) | `cacOrNull`, `sh`, `ipCode`, `pirIDnew`, `pirName` | см. выше | — | Add/Del/Edit = Да |
| File_f «прочее» | только `cipufKey`, `cipufUpload` | поля шапки File (вкладка **Вкладка14**) | — | — |
| родитель «счета, сумма» | subform `Sum_t`; 9 полей: `cn_inv_pm_upl`, `account_num`, `dbt_blns`, `dbt_blns_overd`, `dbt_blns_not_overd`, `cdt_blns`, `cdt_blns_overd`, `cdt_blns_not_overd`, `blns` | SELECT из **`ags_q_cn_inv_pm_upl_sum`** ([SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/CnInvPmtUpl_Sum_t.recordsource.access.sql)); VIEW `ags.q_cn_inv_pm_upl_sum` | **`cn_inv_pm_key` ↔ `cn_inv_pm_upl`** | `.cls` нет |
| родитель «прочее» | в Design пустой контейнер | нет видимого Source | — | — |

**`Sum_t` / VIEW (FishEye, 2026-08-17):** Access-имя `ags_q_cn_inv_pm_upl_sum` = `ags.q_cn_inv_pm_upl_sum`. Определение VIEW: `SUM` полей `dbt_blns*` / `cdt_blns*` / `blns` из `ags.cn_inv_pm` ⋈ `cnInvAccntSmpl` ⋈ `accnt`, `GROUP BY ROLLUP (cn_inv_pm_upl, account_num)`. Это агрегаты строк **платежной** выгрузки по счёту ГК, не таблица долгов `cn_inv_dbt`.

---

## 5. Карта запросов и доп. таблиц

### 5.1. Nav `cipu` (2026-08-17)

Скрины: [01a верх](./assets/26-0817-cn-inv-pmt-upl/01a-nav-cipu-top.png), [01b низ](./assets/26-0817-cn-inv-pmt-upl/01b-nav-cipu-bottom.png). Форм с префиксом `cipu` нет.

**Таблицы (2)**

| Имя на Nav | VBA `File_f` | Примечание |
|------------|--------------|------------|
| `cipuCn_CtptCnOneInvOneAcDcExtPmTbl` | `DELETE` / буфер: **`…ExtPmTbl`** (совпадает с Nav, 2026-08-17) | живой буфер шага 12; [`.table.md`](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_CtptCnOneInvOneAcDcExtPmTbl.table.md) |
| `cipuCn_CtptCnOneInvOneAcDcExtPmTblOld` | не вызывается | архив; в SQL не переносить, пока не понадобится |

**Запросы — вызываются из `btnUpload` / подпроцедур (живой контур)**

| Имя | Как в VBA | Роль по комментарию (не SQL) |
|-----|-----------|------------------------------|
| `cipuCtpt_All_OIdNot` | OpenRecordset (SQL поверх QueryDef) | контрагенты Excel без `org_id`. FROM `cipuCtpt_All_OId` WHERE `org_id_key is null`. **OId** ≠ **Old**. Родитель — INNER JOIN к `agsOrgIdBUiRG` (`org_id_type=1`); лог структурно пуст (вопрос 8). [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCtpt_All_OIdNot.access.sql) |
| `cipuCacNot` | OpenRecordset | САК/стройки Excel, которых нет в БД. SQL: DISTINCT `cacOrNull` из `CnInvPmtUplTblNull`, WHERE не Null, HAVING `cstapCsta` Is Null (анти-join к `ags_cstAgPn`). Только лог. [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCacNot.access.sql) |
| `cipuCn_AgNot` | OpenRecordset | нет агента (заказчик, `cn_s_type=1`) у договора: из `cipuCn_Ag` где CountCsosKey=0. [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_AgNot.access.sql) |
| `cipuCn_AgTwo` | OpenRecordset | агент >1 раз. [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_AgTwo.access.sql) |
| `cipuCn_CtptCnNot` | FROM в `SqlCipuCn_CtptCnNot()` | отсутствующие договоры (номер + исполнитель БУиРГ). QueryDef: LEFT JOIN `agsCnCtptExequtorSmplBuirg`, HAVING Count=0. [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_CtptCnNot.access.sql) |
| `cipuCn_CtptCnTwo` | OpenRecordset | пары договор+исполнитель >1 (`HAVING Count>1`). [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_CtptCnTwo.access.sql) |
| `cipuCn_CtptCnOneInvNotCn` | OpenRecordset | лог новых СФ из `TblCnInv`. [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_CtptCnOneInvNotCn.access.sql) |
| `cipuCn_CtptCnOneInvNotIns` | `db.Execute` (append) | **INSERT** `CnInvPmtUplTblCnInv`. [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_CtptCnOneInvNotIns.access.sql) |
| `cipuCn_CtptCnOneInvTwoCn` | OpenRecordset | лог СФ, уже >1 в БД. [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_CtptCnOneInvTwoCn.access.sql) |
| `cipuCn_CtptCnOneInvTwoIns` | `db.Execute` (append) | **INSERT** `CnInvPmtUplTblCnInv`. [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_CtptCnOneInvTwoIns.access.sql) |
| `cipuCn_CtptCnOneInvOneAcNot` | OpenRecordset | нет пары СФ+счёт ГК. [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_CtptCnOneInvOneAcNot.access.sql) |
| `cipuCn_CtptCnOneInvOneAcNotIns` | `db.Execute` при flLoad (append) | **INSERT** `ags_cnInvAccntSmpl` (ciKey, account_key, csosKey). [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_CtptCnOneInvOneAcNotIns.access.sql) |
| `cipuCn_CtptCnOneInvOneAcDcNot` | OpenRecordset | счётчик СФ без платёжного документа. [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_CtptCnOneInvOneAcDcNot.access.sql) |
| `cipuCn_CtptCnOneInvOneAcDcExtPmIns` | `db.Execute` (append) | **INSERT** буфер `cipuCn_CtptCnOneInvOneAcDcExtPmTbl` из `…ExtPm`. [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_CtptCnOneInvOneAcDcExtPmIns.access.sql) |
| `cipuDocNot` | OpenRecordset | нет кода документа в `ags_cn_inv_doc`. [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuDocNot.access.sql) |
| `cipuDocNotIns` | `db.Execute` при flLoad (append) | **INSERT** `ags_cn_inv_doc` (`cn_inv_doc_kod`). [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuDocNotIns.access.sql) |
| `cipuInsPmNot` | OpenRecordset | готовые PM из буфера, которых нет в `ags_cn_inv_pm` (LEFT JOIN, key IS NULL). [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuInsPmNot.access.sql) |
| `cipuInsPmNotIns` | `db.Execute` при flLoad (append) | **INSERT** `ags_cn_inv_pm` (суммы, даты, `cacOrNull`→`constract_code`, `cstapKey`, `ciasKey`, `cn_inv_pm_upl`=unload). [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuInsPmNotIns.access.sql) |
| `cipuInsPmExt` | OpenRecordset | уже есть в БД: построчный diff полей Excel ↔ `ags_cn_inv_pm` (`MainTest`). [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuInsPmExt.access.sql) |
| `cipuInsPmExtFalse` | OpenRecordset | те же, у кого `MainTest=False` (расхождения). [SQL](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuInsPmExtFalse.access.sql) |

**Имя OId vs Old:** шаг 1 — объект **`cipuCtpt_All_OIdNot`**. Это **OId** = `org_id`, не архивный **Old**. На Nav при фильтре `cipuCtpt_All` видны **оба**: `cipuCtpt_All_Old` (legacy) и `cipuCtpt_All_OidNot`. Цепочка: `cipuCtpt_All` → INNER JOIN `agsOrgIdBUiRG` (`ags_org_id` type=1) → `cipuCtpt_All_OId` → WHERE null → `cipuCtpt_All_OIdNot`.

**Цепочка / промежуточные** — SQL снят дампом (см. `{Имя}.access.sql`):  
`cipuCn_Ag`, `cipuCn_Agnt`, `cipuCn_AgntCnOne`, `cipuCn_AgOne`, `cipuCn_Ctpt`, `cipuCn_CtptCnOne`, `cipuCn_CtptCnOneInv`, `cipuCn_CtptCnOneInvNot`, `cipuCn_CtptCnOneInvOne`, `cipuCn_CtptCnOneInvOneAc`, `cipuCn_CtptCnOneInvOneAcDc`, `cipuCn_CtptCnOneInvOneAcDcExt`, `cipuCn_CtptCnOneInvOneAcDcExtPm`, `cipuCn_CtptCnOneInvTwo`, `cipuCn_CtptNot`, `cipuCtpt_All`, `cipuCtpt_All_OId`, `cipuInsPm`.

**Суффикс `Old` / `Old2` (legacy, в дамп не входили):**  
`cipuCn_CtptCnNotOld`, `…NotOld2`, `cipuCn_CtptCnOneInvNotOld`, `…InvOld`, `…OneAcNotOld`, `…OneAcOld`, `cipuCn_CtptCnOneOld`, `…Old2`, `cipuCn_CtptCnTwoOld`, `…Old2`, `cipuCtpt_All_Old`, `cipuInsPmExtOld`.

**Apply (подтверждено SQL APPEND):** `cipuInsPmNotIns` → **`ags_cn_inv_pm`**; `cipuDocNotIns` → **`ags_cn_inv_doc`**; `cipuCn_CtptCnOneInvOneAcNotIns` → **`ags_cnInvAccntSmpl`**; `…NotIns`/`…TwoIns` → `CnInvPmtUplTblCnInv`; `…ExtPmIns` → буфер `…ExtPmTbl`. DAO по-прежнему: `ags_cn`, `ags_cnNum`, `ags_cn_s`, `ags_cn_s_org_smpl`, `ags_cn_s_org`, `ags_inv`, `ags_invNum`, `ags_cnInv`.

---

## 6. Алгоритм кнопки «загрузка» (`btnUpload_Click`)

Полный текст в экспорте `File_f`. Ниже — порядок вызовов **как в коде**. SQL шагов — после съёма QueryDef. Подробная таблица шагов: [04-data-model §2.9](../domain/sudz/04-data-model.md#29-алгоритм-btnupload_click--cninvpmtupl-процесс-1112-каркас-s69).

### 6.1. Этап Excel → `CnInvPmtUplTbl`

Условие: `cipufFlTbl` и непустой `cipufSheet`. COM Excel, файл `cipufPath`, лист по **имени поля** (не FileSh).

Якорь колонки: `UsedRange.Find(what:="№ докум.", LookAt:=xlWhole)`. Дальше — **не** поиск заголовков (в отличие от долгов), а **фиксированные Offset** от ячейки «№ докум.»: −20…−1 слева, сама ячейка = `ciputCnInvDocCode`, +1…+5 справа. Непустые ячейки якоря → `PaymentUnloadTest` → `AddNew` в `CnInvPmtUplTbl` (`DELETE *` перед циклом). `ciputUnloadKey` = `cipufUpload`.

**Следствие для съёма:** нужен скрин **строки заголовков** живого `export_*` (и/или runtime листа), чтобы подписать Offset именами колонок. По VBA имена Excel-заголовков кроме «№ докум.» **не** восстанавливаются.

### 6.2. Воронка (всегда, даже если Excel не перечитывали)

Порядок в `btnUpload_Click` (после блока `cipufFlTbl`):

1. `cipuCtpt_All_OIdNot` — лог, без flLoad; QueryDef снят: `org_id_key is null` из `cipuCtpt_All_OId`. Набор номеров — UNION контрагента **и агента** из `cipuCtpt_All`  
2. `cipuCacNot` — лог (стройки); QueryDef снят: анти-join `cacOrNull` ↔ `ags_cstAgPn` через `cstapCsta` Is Null  
3. `cipuCn_CtptCnNotLoad` — договоры; QueryDef снят (анти-join к `agsCnCtptExequtorSmplBuirg`); при flLoad DAO: cn→cnNum→cn_s→smpl→org; VBA дополнительно считает схожий № в `ags_cn`/`cnNum`  
4. `cipuCn_CtptCnTwo` — лог неоднозначных пар (`HAVING Count>1`)  
5. `cipuCn_AgNotLoad` — агент/заказчик (`cn_s_type=1`); при flLoad DAO в `ags_cn_s` / `ags_cn_s_org`  
6. `cipuCn_AgTwo` — лог  
7. `cipuCn_CtptCnOneInvNotLoad` — новые СФ → `TblCnInv` (APPEND); при flLoad DAO: inv→invNum→cnInv  
8. `cipuCn_CtptCnOneInvTwoLoad` — СФ уже >1 в БД; **блок apply в коде закомментирован** (повторный показ)  
9. `cipuCn_CtptCnOneInvOneAcNotLoad` — нет пары СФ+счёт; при flLoad INSERT `ags_cnInvAccntSmpl`  
10. `cipuDocNotLoad` — нет платёжного документа; при flLoad INSERT `ags_cn_inv_doc`  
11. `cipuCn_CtptCnOneInvOneAcDcNot` — лог-счётчик  
12. `cipuInsPmNotLoad` — готовые платежи; при flLoad INSERT **`ags_cn_inv_pm`**  
13. `cipuInsPmExt` — уже есть в БД (построчный diff; `cipuInsPmExtFalse` = расхождения)

Флаги: `cipufFlTbl` = перечитать Excel; `cipufFlLoad` = писать в `ags`. Без `cipufUpload` — MsgBox, выход.

---

## 7. Отличие от `CnInvDbtUpl` (1.1.1.1 / 0069)

| | Долги `CnInvDbtUpl*` | Платежи `CnInvPmtUpl*` |
|--|---------------------|-------------------------|
| Вход Excel | общий свод ДЗ | `export_{счётГК}_*` |
| Листы | таблица `FileSh` + флаги «проверять?» | поле **`cipufSheet`** на File |
| Чтение колонок | `Range.Find` по **тексту заголовка** | якорь «№ докум.» + **Offset** |
| Кнопка загрузки | `btnCidufLoad` | `btnUpload` |
| InvDouble | отдельная `FileInvDouble` + nested `InvDouble_f`/`cns` | view над **`TblCnInv`**; nested `invNum`→`cnInv` |
| Кнопка новой СФ | `btnInvAdd` | `btnInvCreate` (тот же ClassFactory) |
| Воронка | org → cn → СФ → AccntSmpl → Accnt → `cn_inv_dbt` | org → САК → cn → агент → СФ → счёт ГК → doc → **`cn_inv_pm`** (INSERT `ags_cn_inv_pm`) |
| Staging SQL | `sudz.CnInvDbtUpl*` (0069) | `sudz.CnInvPmtUpl*` (S61d); воронка Java **не** начата |
| КСДСФ | очередь `CnInvUplSfDouble` (S68) | тот же модуль **позже** (адаптер pmt); этот чат не реализует |

---

## 8. Чеклист съёма из Access

Порядок — как в [MS-ACCESS-OBJECTS-CAPTURE.md](../../../project/proposals/vba-analysis/MS-ACCESS-OBJECTS-CAPTURE.md). Кириллица — только UTF-8, не Immediate.

### Волна 1 — Navigation Pane (сделать первой)

- [x] Скрин Nav, фильтр `CnInvPmtUpl` — 4 табл. / 2 запроса / 6 форм; родитель `CnInvPmtUpl`, **`_2` нет** ([00-nav](./assets/26-0817-cn-inv-pmt-upl/00-nav-CnInvPmtUpl.png)).
- [x] Скрин Nav, фильтр **`cipu`** — 2 табл. + цепочка QueryDef / `*Ins` / `*Old` ([01a](./assets/26-0817-cn-inv-pmt-upl/01a-nav-cipu-top.png), [01b](./assets/26-0817-cn-inv-pmt-upl/01b-nav-cipu-bottom.png)).
- [x] SQL QueryDef `CnInvPmtUplTbl_CstNew` → [`.access.sql`](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/CnInvPmtUplTbl_CstNew.access.sql).
- [x] SQL QueryDef `CnInvPmtUplTblNull` → [`.access.sql`](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/CnInvPmtUplTblNull.access.sql).

### Волна 2 — конструктор родителя и `File_f`

- [x] Родитель `CnInvPmtUpl`: RS `ags_cn_inv_pm_upl`, Order By date DESC; вкладки загрузка / счета, сумма / прочее ([10](./assets/26-0817-cn-inv-pmt-upl/10-design-main-recordsource.png)).
- [x] Link File_f: `cn_inv_pm_key` ↔ `cipufUpload` ([11](./assets/26-0817-cn-inv-pmt-upl/11-design-main-link-file-f.png)).
- [x] Вкладка «счета, сумма»: `Sum_t`, Link `cn_inv_pm_key` ↔ `cn_inv_pm_upl`; RS = `ags_q_cn_inv_pm_upl_sum` ([12](./assets/26-0817-cn-inv-pmt-upl/12-design-main-tab-sum-t.png), [15](./assets/26-0817-cn-inv-pmt-upl/15-design-sum-t-recordsource.png)).
- [x] Родитель «прочее»: пустой контейнер ([13](./assets/26-0817-cn-inv-pmt-upl/13-design-main-tab-other.png)).
- [x] Шапка File_f + кнопка «загрузка» + RS SELECT `CnInvPmtUplFile…` ([14](./assets/26-0817-cn-inv-pmt-upl/14-design-file-f-recordsource.png)).
- [ ] File_f «ход загрузки»: Text Format `cipufLoadingProgress` (RTF?).
- [x] File_f «повторяющиеся СФ»: InvDouble + кнопка + RS/Link пустой ([16](./assets/26-0817-cn-inv-pmt-upl/16-design-file-f-tab-invdouble.png), [16c](./assets/26-0817-cn-inv-pmt-upl/16c-sql-invdouble-recordsource.png)).
- [x] File_f «стройки новые»: CstNew + кнопки; Link пустой; RS обёртка QueryDef ([19](./assets/26-0817-cn-inv-pmt-upl/19-design-file-f-tab-cstnew.png)).
- [x] File_f «прочее»: только `cipufKey` / `cipufUpload` ([20](./assets/26-0817-cn-inv-pmt-upl/20-design-file-f-tab-other.png)).
- [x] RecordSource формы `CnInvPmtUpl>Sum_t` = SELECT из `ags_q_cn_inv_pm_upl_sum` ([15](./assets/26-0817-cn-inv-pmt-upl/15-design-sum-t-recordsource.png), [15b](./assets/26-0817-cn-inv-pmt-upl/15b-sql-sum-t-recordsource.png)).

### Волна 3 — nested InvDouble и CstNew

- [x] Design + RecordSource `…>InvDouble` — совпало с S68 ([16c](./assets/26-0817-cn-inv-pmt-upl/16c-sql-invdouble-recordsource.png)).
- [x] Design + RecordSource + Link `…>invNum` и `…>cnInv`.
- [x] Design + RecordSource CstNew (обёртка QueryDef; сам QueryDef — отдельно).
- [ ] Runtime: грид InvDouble с данными (если буфер не пуст) **или** явное «0 строк».

### Волна 4 — недостающие `.cls`

Экспорт модулей форм (UTF-8), класть в `VBA-Code-Export/Form-Modules/` с тем же `gt_`-именованием:

- [ ] `Form_CnInvPmtUpl.cls` (родитель);
- [ ] `Form_CnInvPmtUpl_gt_Sum_t.cls` (если модуль есть);
- [ ] `Form_CnInvPmtUpl_gt_File_f_gt_InvDouble.cls`;
- [ ] `…_gt_InvDouble_gt_invNum.cls`;
- [ ] `Form_CnInvPmtUpl_gt_File_f_gt_CstNew.cls`;
- [ ] модули вкладки «прочее».

### Волна 5 — таблицы и запросы

- [x] SQL QueryDef `cipuCacNot` → [`.access.sql`](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCacNot.access.sql) ([22](./assets/26-0817-cn-inv-pmt-upl/22-sql-cipuCacNot.png)).
- [x] SQL QueryDef `cipuCtpt_All_OIdNot` → [`.access.sql`](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCtpt_All_OIdNot.access.sql) ([23](./assets/26-0817-cn-inv-pmt-upl/23-sql-cipuCtpt_All_OIdNot.png)). Имя = **OId**, не Old.
- [x] SQL QueryDef `cipuCtpt_All_OId` → [`.access.sql`](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCtpt_All_OId.access.sql) ([24](./assets/26-0817-cn-inv-pmt-upl/24-sql-cipuCtpt_All_OId.png)).
- [x] SQL QueryDef `cipuCtpt_All` → [`.access.sql`](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCtpt_All.access.sql) ([25](./assets/26-0817-cn-inv-pmt-upl/25-sql-cipuCtpt_All.png)).
- [x] SQL QueryDef `agsOrgIdBUiRG` → [`.access.sql`](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/agsOrgIdBUiRG.access.sql).
- [x] SQL QueryDef `cipuCn_CtptCnNot` → [`.access.sql`](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_CtptCnNot.access.sql) ([26](./assets/26-0817-cn-inv-pmt-upl/26-sql-cipuCn_CtptCnNot.png)).
- [x] SQL QueryDef `cipuCn_Ctpt` → [`.access.sql`](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_Ctpt.access.sql) ([27](./assets/26-0817-cn-inv-pmt-upl/27-sql-cipuCn_Ctpt.png)).
- [x] Дамп живого контура `cipu*` (40 QueryDef, 2026-08-17) → [`cipu-sql/`](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipu-sql/) и `{Имя}.access.sql`. Кириллица в дампе целая. Модуль: [`DumpCipuQueryDefs.bas`](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/DumpCipuQueryDefs.bas).
- [x] Helper QueryDef: `agsCnCtptAgentSmplBuirg`, `agsCnCtptAgentSmplBuirgOne`, `agsCnCtptExequtorSmplBuirgOne` (дамп 23:58). `agsInvNumCount` = уже снятый в `access-queries/`.
- [x] DumpTableDef UTF-8: `cipuCn_CtptCnOneInvOneAcDcExtPmTbl` → [`.table.md`](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_CtptCnOneInvOneAcDcExtPmTbl.table.md) ([dump](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/cipuCn_CtptCnOneInvOneAcDcExtPmTbl_dump.txt)).
- [ ] Скрин заголовков Excel `export_*` (строка с «№ докум.») для карты Offset.

### Не снимать повторно (уже есть)

`CnInvPmtUplFile` / `Tbl` / `TblCnInv` / `Tbl_1` — `.table.md`+dump; VBA `File_f` и самый внутренний `cnInv`.

---

## 9. Открытые вопросы

1. ~~Есть ли родитель / RS / Link File_f?~~ **`CnInvPmtUpl`** ← `ags_cn_inv_pm_upl`; Link File_f `cn_inv_pm_key`↔`cipufUpload`. `_2` нет.
2. ~~Полный список объектов `cipu*` на Nav~~ **снят**. ~~`ExtPmtTbl` vs `ExtPmTbl`~~ — на Nav (фильтр `cipuCn_Ctpt`, 2026-08-17) **`…ExtPmTbl`**, как в VBA. ~~`OldNot` vs `OIdNot`~~ — **`cipuCtpt_All_OIdNot`**.
3. ~~QueryDef живого контура `cipu*` / helper `agsCnCtpt*` / буфер `…ExtPmTbl`~~ **сняты**. Осталось: полный RS File_f; `.cls` без экспорта; Excel Offset.
4. ~~Куда INSERT `cipuInsPmNotIns` / `cipuDocNotIns` / `…AcNotIns`~~ **снято:** `ags_cn_inv_pm` / `ags_cn_inv_doc` / `ags_cnInvAccntSmpl`.
5. Почему `cipuCn_CtptCnOneInvTwoLoad` не пишет в БД (закомментированный apply) — намеренно?
6. Соответствие колонок Excel Offset ↔ заголовки `export_*` (меняются ли между периодами?).
7. ~~Почему на гриде Sum_t поля `dbt_blns*`?~~ Колонки **`ags.cn_inv_pm`**, агрегат VIEW `ags.q_cn_inv_pm_upl_sum` (rollup по выгрузке+счёту ГК); аналог dbt `ags_q_cn_inv_dbt_upl_sum`.
8. ~~`cipuCtpt_All_OId` INNER JOIN + `OIdNot` IS NULL~~ **снято:** `agsOrgIdBUiRG` = `ags_org_id` WHERE `org_id_type=1`; `org_id_key` NOT NULL. После INNER JOIN строк с null-ключом нет — лог шага 1 («новые организации») структурно пуст. У долгов тот же смысл — **LEFT JOIN** (`ciduCtptNot`). **Следствие:** `cipuCn_Ctpt` отсекает тех, кто в `OIdNot`; пустой `OIdNot` → анти-join никого не отсекает, в шаг 3 попадают все контрагенты Excel (в т.ч. без БУиРГ, тогда `org_id_key` Null).
9. ~~`agsCnCtptExequtorSmplBuirg` / Agent / `*One`~~ **снято.** Исполнитель: `cn_s_type=2`, номер = **`cnnNumNull`**. Агент: `cn_s_type=1`, номер = **`cnnNum`**. `*One` = ровно один `csosKey` на пару (договор, БУиРГ). Не VIEW `ags.cn_s_orgExeBuirg` (там полная `cn_s_org`).

---

## 10. Связанные артефакты

| Артефакт | Путь |
|----------|------|
| Съём таблиц | [26-0813_CnInvPmtUpl_/](../../../project/proposals/vba-analysis/26-0813_CnInvPmtUpl_/) |
| DDL staging | [26-0812-sudz-dbt-upl-staging/README-Pmt.md](../sql/26-0812-sudz-dbt-upl-staging/README-Pmt.md) |
| VBA File_f | `docs/project/proposals/vba-analysis/VBA-Code-Export/Form-Modules/Form_CnInvPmtUpl_gt_File_f.cls` |
| Аналог долгов (скрины) | [assets/26-0811-cn-inv-dbt-upl/](./assets/26-0811-cn-inv-dbt-upl/README.md) |
| КСДСФ (ссылка) | [sql/26-0816-sudz-sf-num-collision/](../sql/26-0816-sudz-sf-num-collision/) — адаптер pmt **не** эта тема |
