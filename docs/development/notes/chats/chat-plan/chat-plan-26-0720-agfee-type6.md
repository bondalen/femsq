# План: Type=6 (AgFee2306) — reconcile «Акты агентского вознаграждения» → «Пункты по стройкам»

**Дата создания:** 2026-07-20
**Последнее обновление:** 2026-07-21
**Проект:** FEMSQ
**Версия плана:** 1.0.0 (завершён)
**Задачи:** [0055](../../../project-development.json) (completed), [0056](../../../project-development.json) (completed)
**Статус плана:** ✅ выполнен (A–G + UAT B/C); вне scope — П1–П4 (см. § «После 0055»)
**Резюме:** [chat-resume-26-0720-agfee-type6.md](../chat-resume/chat-resume-26-0720-agfee-type6.md)

---

## 0. Предыстория и связь с другими планами

- **Почему сейчас, а не после прода:** разбор в `chat-plan-26-0707-ralp-reconcile.md#9511-prod-bootstrap-таблиц-ревизий-access--mssql-новая-задача-0054` показал, что задача **0054** (bootstrap `ags.ra_a` и связанных таблиц на prod) объективно требует доступа к продуктивному серверу и рискует переделкой после получения доступа. Type=6 — принципиально другой случай: **домен уже существует на сервере** (`ags.ogAgFee`, `ags.ogAgFeeP`) и используется текущим live Access-процессом через ODBC linked tables (`DSN=FishEye`) — то есть это часть **текущего прода**, не гипотеза. Риск переделки после доступа к проду — минимальный.
- **Готовый скелет:** `chat-plan-26-0323-reconcile-specific.md#фаза-4-type-6-ra_stg_agfee--домен` — чек-лист был написан 2026-03-23/2026-04-15, но ни один пункт не выполнен (`[ ]` везде). Этот план — раскрытие и уточнение той же «Фазы 4» с учётом фактически найденной T-SQL логики (см. §3–4) и явного требования по иерархии Акт→Пункты (см. §5).
- **Не путать с 0054.** Здесь бизнес-домен (`ags.ogAgFee`/`ogAgFeeP`) не бутстрапится — он есть. Задача — **портировать существующую T-SQL/VBA-логику** сверки в Java reconcile-сервис (по аналогии с `RalpReconcileService`/`AllAgentsReconcileService`), работающий против `ags.ra_stg_agfee` + `exec_key`, а не против legacy `ags.ogAgFeePnTest`.

---

## 1. Цель

Реализовать и верифицировать полный reconcile для `af_type=6` (AgFee2306, «Акты по агентскому вознаграждению»):

1. Stage 2a — FK-резолюция отправителя (агента) и стройки с той же строгостью, что в legacy VBA/T-SQL (включая обработку неоднозначностей).
2. Stage 2b/2c — двухуровневая (Акт → Пункты) сверка/применение изменений к домену (`ags.ogAgFee` + `ags.ogAgFeeP`).
3. Отдельная модель формирования лога `adt_results` для type=6 (иерархия Акт → его Пункты), отличная от type=3/5.
4. Идемпотентность повторного запуска, dry-run/apply, smoke на реальных снимках март/июль.

---

## 2. Обязательное условие: тщательное изучение VBA перед реализацией

Перед написанием Java-кода **обязательно** повторно свериться с исходниками (не только с выводами этого плана):

| Файл | Назначение | Что проверить |
|------|-----------|----------------|
| `docs/project/proposals/vba-analysis/VBA-Code-Export/Class-Modules/ra_aAgFee23_06.cls` | Оркестрация `Audit()` — порядок вызовов, что выводится в лог, что модифицируется в БД | Точный порядок шагов (§3.2), формулировки строк лога (для сравнения с будущим Java-выводом) |
| `docs/project/proposals/vba-analysis/VBA-Code-Export/Class-Modules/ogAgFee.cls` | Доменный класс *Акт* — геттеры/сеттеры полей заголовка | Список полей заголовка (§4.1); подтверждено — только generic property accessors, скрытых вычислений нет |
| `docs/project/proposals/vba-analysis/VBA-Code-Export/Class-Modules/ogAgFeePn.cls` | Доменный класс *Пункт стройки* — `parent As ogAgFee`, `parentKey = oafpOaf` | Подтверждает связь 1:N Акт→Пункт на уровне VBA-модели, не только SQL |
| `docs/project/proposals/vba-analysis/access-queries/ogAgFeePnTest.table.md`, `ags_ogAgFeePnTest.table.md` | Структура legacy staging (локальная и linked) | Сверка полей с `ags.ra_stg_agfee` (Stage 1 уже реализован через `ra_col_map`) |
| `docs/development/notes/analysis/ra-audit-file-processor-architecture.md` §5–7, §10 | Общая архитектура процессоров, двухстадийная модель staging | Убедиться, что Stage 2a/2b/2c для type=6 в новом коде укладываются в существующий контракт `AbstractAuditFileProcessor` |

**Правило:** если при реализации обнаружится расхождение между выводами этого плана и первичным VBA-текстом — приоритет у VBA-текста; план актуализировать.

---

## 3. Что уже подтверждено (инвентаризация 2026-07-20)

### 3.1. Домен на сервере — уже существует, не бутстрапится

| Таблица | Роль | Строк на dev (вероятно = зеркало prod) |
|---------|------|------------------------------------------|
| `ags.ogAgFee` | Акт (заголовок) | **837** |
| `ags.ogAgFeeP` | Пункт Акта по стройке (строка) | **26 628** |
| `ags.ogAgCs` | Организация-отправитель (агент) | — (lookup) |
| `ags.cstAgPn` | Стройка (`cstapIpgPnN`, `cstapKey`) | — (lookup) |
| `ags.yyyy` | Справочник года (`yKey`/`yyyy`) | — (lookup) |
| `ags.ogNmF_allVariantsAg` | Варианты наименований агента + `ogaCode` (для разрешения задвоений, напр. «Газпром телеком» 008/013) | — (lookup) |
| `ags.ogAgFeePnTest` | **Legacy staging** (аналог `ra_stg_agfee`, НЕ домен) | 3635 (текущее содержимое от последнего Access-прогона) |

**Связь 1:N подтверждена на трёх уровнях:** VBA (`ogAgFeePn.parent As ogAgFee`), T-SQL (`ogAgFeeP.oafpOaf → ogAgFee.oafKey`), и структура Excel (см. §5.1).

### 3.2. Порядок вызовов в `ra_aAgFee23_06.Audit()` (VBA, дословно)

1. `AuditFillFromSource` — заполняет `ags_ogAgFeePnTest` (linked) построчно из Excel через `myArray`+`ExcelToTable` (аналог уже реализованного Stage 1 → `ra_stg_agfee`).
2. `ogAgFeePnTestAgentKey` (proc) — резолюция ключа агента с учётом кода стройки (первые 3 символа) и **проверкой неоднозначности** через `ogAgFeePnTestAgentNo` (view).
3. Проверка/удаление **Актов**, отсутствующих в источнике (`fnOgAgFeePnTestActDbOnly` + `ogAgFeePnTestActDbOnlyDel`) — **уровень заголовка**.
4. Добавление **новых Актов** (`ogAgFeePnTestActNew` + `ogAgFeePnTestActAdd`) — **уровень заголовка**, group by (`oafptOafSenderKey`, `oafptOafName`, `oafptOafDate`).
5. Проверка задвоения атрибутов у Актов в источнике (`ogAgFeePnTestActAttr`) — сигнал/WARN, без изменения БД.
6. Сверка и **обновление атрибутов заголовка** (`ogAgFeePnTestActAttrTrue`) — Поступило/Направлено/Возврат/CAPEX/год/месяц/Отдел.
7. `ogAgFeePnTestCstKey` (proc) — резолюция ключа стройки.
8. Проверка/удаление **Пунктов**, отсутствующих в источнике (`fnOgAgFeePnTestExcNo` + `ogAgFeePnTestExcNoDel`) — **уровень строки**.
9. Добавление **новых Пунктов** (`ogAgFeePnTestDbNo` + `ogAgFeePnTestActPnAdd`) — **уровень строки**, требует уже существующего `oafKey` (после шага 4!).
10. Сверка и **обновление суммы Пункта** (`ogAgFeePnTestActPnNoEq`) — только `oafpTotal`.
11. Контрольная сверка общей суммы (Excel `=ПРОМЕЖУТОЧНЫЕ.ИТОГИ(109;[Сумма])` vs `SUM(ogAgFeeP.oafpTotal)` за год) — информационная, без изменения БД.

**Критично для реализации:** шаги 3–6 (заголовок) **должны выполняться до** шагов 8–10 (строки) — иначе `ActPnAdd`/`ActPnNoEq` не найдут `oafKey` для новых Актов. Порядок в Java должен буквально повторить этот двухуровневый проход.

### 3.3. Полные T-SQL определения (референс, захвачены `OBJECT_DEFINITION` 2026-07-20)

> Хранится здесь, а не как отдельные `.access.sql`, — согласно правилу `docs/project/proposals/vba-analysis/access-queries/README.md` («SQL Server objects (`ags.*`)… не оформляем отдельными `*.access.sql`»). Это T-SQL логика, которая **уже работает на живом сервере** — референс для портирования в `AgFeeStage2Service`/`AgFee2306ReconcileService`.

<details>
<summary>Views (раскрыть)</summary>

```sql
-- ogAgFeePnTestActNew: новые Акты (заголовки), отсутствующие в БД
create view ags.fnOgAgFeePnTestActNew as
select y.oafptOafName, y.oafptOafDate, y.oafptOafSenderKey, y.oafKey, a.ogaNm
from
    (
        select z.oafptOafName, z.oafptOafDate, z.oafptOafSenderKey, a.oafKey
        from
            (
                select t.oafptOafSenderKey, t.oafptOafName, t.oafptOafDate
                from  ags.ogAgFeePnTest t
                group by t.oafptOafSenderKey, t.oafptOafName, t.oafptOafDate
            ) as z
            left join ags.ogAgFee a on z.oafptOafName = a.oafNum and z.oafptOafDate = a.oafDate and z.oafptOafSenderKey = a.cstaAg
        where a.oafKey is null
    ) as y
    left join ags.ogAgCs a on y.oafptOafSenderKey = a.ogaKey;

-- ogAgFeePnTestDbNo: Пункты, есть в источнике, нет в БД (после того как Акт уже создан)
create view ags.ogAgFeePnTestDbNo as
select
    t.oafptOafName, t.oafptOafDate, t.oafptOafSender, t.oafptOafSenderKey, t.oafptPnCstAgPn, t.oafptPnCstAgPnKey, t.oafptTtl
    , o.oafKey
from ags.ogAgFeePnTest t
    join ags.ogAgFee o on o.oafNum = t.oafptOafName and o.oafDate = t.oafptOafDate and o.cstaAg = t.oafptOafSenderKey
        left join ags.ogAgFeeP p on o.oafKey = p.oafpOaf and t.oafptPnCstAgPnKey = p.oafpCstAgPn
where not t.oafptPnCstAgPnKey is null and p.oafpKey is null and not t.oafptTtl is null;

-- ogAgFeePnTestActPnNoEq: Пункты с разночтением суммы (Пункт уже есть, Сумма разная)
create view ags.ogAgFeePnTestActPnNoEq as
select
    t.oafptOafName, t.oafptOafDate, t.oafptOafSender, t.oafptOafSenderKey, t.oafptPnCstAgPn, t.oafptPnCstAgPnKey, t.oafptTtl
    , o.oafKey
    , p.oafpKey, p.oafpTotal, iif(t.oafptTtl = p.oafpTotal or (t.oafptTtl is null and p.oafpTotal is null), 1, 0) as ttlTest
from ags.ogAgFeePnTest t
    join ags.ogAgFee o on o.oafNum = t.oafptOafName and o.oafDate = t.oafptOafDate and o.cstaAg = t.oafptOafSenderKey
        left join ags.ogAgFeeP p on o.oafKey = p.oafpOaf and t.oafptPnCstAgPnKey = p.oafpCstAgPn
where not t.oafptPnCstAgPnKey is null and not p.oafpKey is null
    and iif(t.oafptTtl = p.oafpTotal or (t.oafptTtl is null and p.oafpTotal is null), 1, 0) = 0;

-- ogAgFeePnTestAgentNo: неоднозначность/отсутствие ключа агента (по имени + коду стройки)
CREATE view [ags].[ogAgFeePnTestAgentNo] as
select z.oafptOafSender, count(o.ogaKey) as keyCount
from
    (
        select y.oafptOafSender, y.ogAgCode
        from
            (
                select t.oafptOafSender, left(t.oafptPnCstAgPn, 3) as ogAgCode
                from ags.ogAgFeePnTest t
            ) as y
        group by y.oafptOafSender, y.ogAgCode
    ) as z
    left join ags.ogNmF_allVariantsAg o on z.oafptOafSender = o.ogNm and z.ogAgCode = o.ogaCode
group by z.oafptOafSender
having count(o.ogaKey) <> 1;

-- ogAgFeePnTestCstNo: стройка из источника не найдена в ags.cstAgPn
create view ags.ogAgFeePnTestCstNo as
select y.oafptPnCstAgPn, y.cstapKey, i.oafptOafName, i.oafptOafDate, i.oafptKey, c.ogaNm
from
    (
        select z.oafptPnCstAgPn, p.cstapKey
        from (select t.oafptPnCstAgPn from ags.ogAgFeePnTest t group by t.oafptPnCstAgPn) as z
            left join ags.cstAgPn p on z.oafptPnCstAgPn = p.cstapIpgPnN
        where p.cstapKey is null
    ) as y
    join ags.ogAgFeePnTest i on y.oafptPnCstAgPn = i.oafptPnCstAgPn
        join ags.ogAgCs c on i.oafptOafSenderKey = c.ogaKey;

-- ogAgFeePnTestActAttr / ActAttrTrue: задвоение атрибутов заголовка / построчная сверка атрибутов заголовка
-- (полные тексты — см. в БД OBJECT_DEFINITION('ags.ogAgFeePnTestActAttr'/'ags.ogAgFeePnTestActAttrTrue');
--  логика: group by (oafptOafSenderKey, oafptOafName, oafptOafDate) -> сравнение с ags.ogAgFee по 11 атрибутам
--  (Arrived/Sent/Returned num+date, ReturnedReason, Capex, год через ags.yyyy, месяц, Отдел) с iif(...) = 1/0 на каждый.
```

</details>

<details>
<summary>Stored procedures / functions (раскрыть)</summary>

```sql
-- fnOgAgFeePnTestActDbOnly(@yearAct): Акты в БД за год, отсутствующие в источнике
CREATE FUNCTION ags.fnOgAgFeePnTestActDbOnly (@yearAct int) RETURNS TABLE AS RETURN (
    select f.oafKey, f.oafNum, f.oafDate, f.cstaAg, z.oafptOafName, a.ogaNm
    from ags.ogAgFee f
        left join (select t.oafptOafSenderKey, t.oafptOafName, t.oafptOafDate from ags.ogAgFeePnTest t
                    group by t.oafptOafSenderKey, t.oafptOafName, t.oafptOafDate) as z
            on f.oafNum = z.oafptOafName and f.oafDate = z.oafptOafDate and f.cstaAg = z.oafptOafSenderKey
        left join ags.ogAgCs a on f.cstaAg = a.ogaKey
    where year(f.oafDate) = @yearAct and z.oafptOafName is null
);

-- ogAgFeePnTestActDbOnlyDel(@yearAct): удаляет Акты, отсутствующие в источнике (уровень заголовка)
CREATE PROCEDURE ags.ogAgFeePnTestActDbOnlyDel @yearAct int AS BEGIN
    SET NOCOUNT ON;
    delete from ags.ogAgFee where oafKey in (select f.oafKey from ags.fnOgAgFeePnTestActDbOnly(@yearAct) f);
END;

-- ogAgFeePnTestActAdd: вставляет новые Акты (уровень заголовка); порядок ВАЖЕН — до ActPnAdd
CREATE PROCEDURE ags.ogAgFeePnTestActAdd AS BEGIN
    SET NOCOUNT ON;
    insert into ags.ogAgFee(oafNum, oafDate, cstaAg, oafY, oafM)
    select x.oafptOafName, x.oafptOafDate, x.oafptOafSenderKey, y.yKey, x.mmmm
    from (
        select z.oafptOafName, z.oafptOafDate, z.oafptOafSenderKey, year(z.oafptOafDate) as yyyy, month(z.oafptOafDate) as mmmm
        from (select t.oafptOafSenderKey, t.oafptOafName, t.oafptOafDate from ags.ogAgFeePnTest t
              group by t.oafptOafSenderKey, t.oafptOafName, t.oafptOafDate) as z
            left join ags.ogAgFee a on z.oafptOafName = a.oafNum and z.oafptOafDate = a.oafDate and z.oafptOafSenderKey = a.cstaAg
        where a.oafKey is null
    ) as x
        left join ags.yyyy y on x.yyyy = y.yyyy
END;

-- ogAgFeePnTestAgentKey: резолюция ключа агента с учётом кода стройки + строгая проверка keyCount=1
CREATE PROCEDURE ags.ogAgFeePnTestAgentKey AS BEGIN
    SET NOCOUNT ON;
    update t set t.oafptOafSenderKey = y.ogaKey
    from ags.ogAgFeePnTest t
        join (
            select x.oafptOafSender, x.ogAgCode, x.keyCount, o.ogaKey
            from (
                select z.oafptOafSender, z.ogAgCode, count(o.ogaKey) as keyCount
                from (select y.oafptOafSender, y.ogAgCode
                      from (select t.oafptOafSender, left(t.oafptPnCstAgPn, 3) as ogAgCode from ags.ogAgFeePnTest t) as y
                      group by y.oafptOafSender, y.ogAgCode) as z
                    left join ags.ogNmF_allVariantsAg o on z.oafptOafSender = o.ogNm and z.ogAgCode = o.ogaCode
                group by z.oafptOafSender, z.ogAgCode
                having count(o.ogaKey) = 1
            ) as x
                join ags.ogNmF_allVariantsAg o on x.oafptOafSender = o.ogNm and x.ogAgCode = o.ogaCode
        ) as y on t.oafptOafSender = y.oafptOafSender
END;

-- ogAgFeePnTestCstKey: резолюция ключа стройки
CREATE PROCEDURE ags.ogAgFeePnTestCstKey AS BEGIN
    SET NOCOUNT ON;
    update t set t.oafptPnCstAgPnKey = p.cstapKey
    from ags.ogAgFeePnTest t join ags.cstAgPn p on t.oafptPnCstAgPn = p.cstapIpgPnN
END;

-- fnOgAgFeePnTestExcNo(@yearPn) + ogAgFeePnTestExcNoDel: Пункты в БД, отсутствующие в источнике (уровень строки)
CREATE FUNCTION ags.ogAgFeePnTestExcNo (@yearPn int) RETURNS TABLE AS RETURN (
    select p.oafpKey, p.oafpOaf, p.oafpCstAgPn, o.oafNum, o.oafDate, o.cstaAg, c.cstapIpgPnN, t.oafptKey, t.oafptPnCstAgPn
    from ags.ogAgFeeP p
        join ags.ogAgFee o on p.oafpOaf = o.oafKey
            left join ags.ogAgFeePnTest t
                on o.oafNum = t.oafptOafName and o.oafDate = t.oafptOafDate and o.cstaAg = t.oafptOafSenderKey and p.oafpCstAgPn = t.oafptPnCstAgPnKey
        join ags.cstAgPn c on p.oafpCstAgPn = c.cstapKey
    where year(o.oafDate) = @yearPn and t.oafptKey is null
);
CREATE PROCEDURE ags.ogAgFeePnTestExcNoDel @yearAct int AS BEGIN
    SET NOCOUNT ON;
    delete from ags.ogAgFeeP where oafpKey in (select f.oafpKey from ags.fnOgAgFeePnTestExcNo(@yearAct) f);
END;

-- ogAgFeePnTestActPnAdd: вставляет новые Пункты (уровень строки); требует существующего oafKey
CREATE PROCEDURE ags.ogAgFeePnTestActPnAdd AS BEGIN
    SET NOCOUNT ON;
    insert into ags.ogAgFeeP(oafpOaf, oafpCstAgPn, oafpTotal)
    select d.oafKey, d.oafptPnCstAgPnKey, d.oafptTtl
    from ags.ogAgFeePnTestDbNo d
END;
```

</details>

### 3.4. Java-заготовка (текущее состояние, 2026-07-20)

| Компонент | Файл | Статус |
|-----------|------|--------|
| Stage 1 (Excel → `ra_stg_agfee`) | `AuditStagingService` (generic) + `ra_col_map`/`ra_sheet_conf` (rsc_key=2) | ✅ Работает |
| `AgFee2306AuditFileProcessor` | `.../audit/AgFee2306AuditFileProcessor.java` | ✅ Оркестрация Stage1→2a→2b (guard `ctx.auditType==1`) |
| Stage 2a (FK агента) | `AgFeeStage2Service.resolveForExecution` | ✅ `oafptOafSenderKey` ← `ogNmF_allVariantsAg` + код стройки (`keyCount=1`) |
| Stage 2a (FK стройки) | `AgFeeStage2Service` | ✅ `oafptPnCstAgPnKey` ← `cstAgPn.cstapIpgPnN`; diagnostic AgentNo/CstNo |
| Stage 2b (Акты) | `AgFee2306ReconcileService` | ✅ Фаза C |
| Stage 2c (Пункты) | `AgFee2306ReconcileService` | ✅ Фаза D |
| Логирование (tree) | `Type6ReconcileTreeLogger` | ✅ Фаза E: Акт→Пункты + ActAttr + year sum |

---

## 4. Доменная модель (точный DDL — Фаза A.1, 2026-07-20)

### 4.1. `ags.ogAgFee` — Акт (заголовок, 1 запись = 1 акт)

| Поле | SQL-тип | NULL | Смысл / Stage 2 |
|---|---|---|---|
| `oafKey` | `int` IDENTITY | NO | PK |
| `oafNum` | `nvarchar(600)` | NO | № Акта — ключ группировки |
| `oafDate` | `date` | YES | Дата Акта — ключ группировки |
| `cstaAg` | `int` | NO | FK → `ags.ogAg.ogaKey` — ключ группировки |
| `oafArrived` / `oafArrivedDate` | `nvarchar(255)` / `date` | YES | Поступило — **update** |
| `oafSent` / `oafSentDate` | `nvarchar(255)` / `date` | YES | Направлен в Бухгалтерию — **update** |
| `oafReturned` / `oafReturnedDate` | `nvarchar(255)` / `date` | YES | Возврат — **update** |
| `oafReturnedReason` | `nvarchar(600)` | YES | Причина возврата — **update** |
| `oafCapex` | `nvarchar(10)` | YES | CAPEX — **update** |
| `oafY` | `int` | NO | FK → `ags.yyyy.yKey` — **update** (не calendar year!) |
| `oafM` | `int` | NO | FK → `ags.mmmm.mKey` (=1..12) — **update** |
| `oafUnit` | `nvarchar(255)` | YES | Отдел управления — **update** |
| `oafNote` | `nvarchar(max)` | YES | Примечание — **не** в VBA `Audit` attr-сверке |

Индексы/FK: `PK_ogAgFee(oafKey)`; `FK_ogAgFee_ogAg(cstaAg)`; `FK_ogAgFee_yyyy(oafY)`; `FK_ogAgFee_mmmm(oafM)`.

### 4.2. `ags.ogAgFeeP` — Пункт Акта по стройке (1 запись = 1 стройка в акте)

| Поле | SQL-тип | NULL | Смысл / Stage 2 |
|---|---|---|---|
| `oafpKey` | `int` IDENTITY | NO | PK |
| `oafpOaf` | `int` | NO | FK → `ogAgFee.oafKey` |
| `oafpCstAgPn` | `int` | NO | FK → `cstAgPn.cstapKey` |
| `oafpTotal` | `money` | NO | Сумма — **единственное поле, сверяемое в reconcile** (`ActPnNoEq`) |
| `oafpNum` | `int` | YES | Порядковый номер пункта — **вне** VBA Audit fill |
| `oafpAgFee` / `oafpVAT` / `oafpAgFeeArr` / `oafpVATArr` / `oafpTotalArr` | `money` | YES | Детализация сумм — **вне** текущего VBA reconcile |
| `oafpNote` | `nvarchar(255)` | YES | Примечание |
| `oafp_fdKey` | `int` | YES | FK → `factDoc.fdKey` |

Индексы/FK: `PK_ogAgFeeP(oafpKey)`; **unique** `OafCst(oafpOaf, oafpCstAgPn)`; `FK_ogAgFeeP_ogAgFee`; `FK_ogAgFeeP_cstAgPn`; `FK_ogAgFeeP_factDoc`.

**Важно:** `oafpTotal` — единственный атрибут уровня Пункта, который сверяется/обновляется (`ActPnNoEq`). Все временные/статусные атрибуты относятся **только к заголовку**. Unique `(oafpOaf, oafpCstAgPn)` — естественный ключ матчинга пункта.

---

## 5. Особенность обработки: Акт (1) → Пункты (N) — влияние на Stage 2 и на лог

### 5.1. Почему это не тривиально

Лист Excel (`№ Акта`, `Дата Акта`, `Код стройки`, `Сумма`, …) — **плоский/денормализованный**: одна строка Excel = один Пункт (одна стройка), но столбцы `№ Акта`/`Дата Акта`/атрибуты заголовка **повторяются** во всех строках одного Акта. `ra_stg_agfee` (Stage 1) наследует эту денормализацию 1:1 с Excel — это правильно и достаточно для Stage 1.

Stage 2 обязан:
1. **Сначала** свернуть `ra_stg_agfee` в уникальные группы `(oafptOafSenderKey, oafptOafName, oafptOafDate)` → это кандидаты в Акты (заголовки).
2. Обработать заголовки: удалить отсутствующие в источнике, добавить новые, сверить/обновить атрибуты заголовка (VBA-шаги 3–6, см. §3.2). **Ключевое требование:** пока эта фаза не выполнена, `oafKey` для новых Актов не существует.
3. **Только затем** обработать каждую строку `ra_stg_agfee` как кандидата в Пункт, используя `oafKey`, полученный на шаге 2 (VBA-шаги 8–10).

Нарушение порядка (например, попытка вставить Пункты до вставки новых Актов) даёт **NULL/ошибку по FK** — ровно то, из-за чего в VBA `ActPnAdd` вызывается строго после `ActAdd`.

### 5.2. Влияние на формирование лога (отличие от type=3 и type=5)

- **Type=5** (`AllAgentsReconcileService`): лог — плоский список строк (ОА / ОА прочие), группировка есть, но по типу ra, не по родитель→ребёнок.
- **Type=3** (`RalpReconcileService`): один ствол NEW/CHANGED/ошибки по строкам Excel (A1–A4), без иерархии родитель→ребёнок.
- **Type=6**: структурно **двухуровневое дерево** — обязательный уровень **Акт (заголовок)**, и под каждым Актом — **список его Пунктов (стройки)**. Именно так лог формирует и сам VBA (`ra_aAgFee23_06.Audit`, строки ~570–605 и ~620–673): переменная `nnn` отслеживает смену `oafKey`/`oafNum`, при смене — новый заголовок `<b>N. Акт …</b>`, а построчно внутри — `<font>i. Стройка …</font>` для каждого Пункта.

**Требование к новому `Type6ReconcileTreeLogger` (по аналогии с `RalpReconcileTreeLogger`/`Type5ReconcileTreeLogger`):**
- Узел уровня 1 — Акт (`oafNum` + `oafDate` + агент), с суб-статусами: `NEW` / `ATTR_CHANGED` / `UNCHANGED` / `MISSING_IN_SOURCE` (удалён).
- Узел уровня 2 (дети узла 1) — Пункты этого Акта: `NEW` / `SUM_CHANGED` / `UNCHANGED` / `MISSING_IN_SOURCE`.
- Отдельные плоские секции (без привязки к конкретному Акту, как WARN/ошибки в VBA): неоднозначность агента (`AgentNo`), неоднозначность/отсутствие стройки (`CstNo`), задвоение атрибутов в источнике (`ActAttr`), итоговая сверка суммы за год.
- Счётчики (аналог `Type5ReconcileAuditCounters`): `actsNew/actsUpdated/actsUnchanged/actsDeleted`, `linesNew/linesUpdated/linesUnchanged/linesDeleted`, `errors`.

---

## 6. Фазы работы (адаптация «Фазы 4» из `chat-plan-26-0323-reconcile-specific.md`)

### Фаза A: Инвентаризация и подготовка (без изменения кода домена) ✅

- ✅ A.1. DBHub: точный DDL `ags.ogAgFee`/`ags.ogAgFeeP` (типы, nullability, индексы, FK) — сверить с §4.
  - **Исполнено 2026-07-20:** 16 колонок `ogAgFee` (PK `oafKey` IDENTITY; FK `cstaAg→ogAg.ogaKey`, `oafY→yyyy.yKey`, `oafM→mmmm.mKey`); 12 колонок `ogAgFeeP` (PK `oafpKey`; unique `OafCst(oafpOaf,oafpCstAgPn)`; FK на `ogAgFee`/`cstAgPn`/`factDoc`). Поля сверх VBA-списка §4: `oafNote`; у пункта — `oafpNum`, breakdown-money, `oafpNote`, `oafp_fdKey` (вне текущего reconcile). Домен по годам: 2021–2025 (837 актов); **за 2026 актов 0**. §4 обновлён. **В1 закрыт.**
- ✅ A.2. DBHub: `ags.ogAgCs`, `ags.cstAgPn`, `ags.yyyy`, `ags.ogNmF_allVariantsAg` — точная структура для Stage 2a.
  - **Исполнено 2026-07-20:** `ogAgCs` — **view** (`ogaKey`, `ogaCode+' '+ogNm`); целевая таблица FK — `ags.ogAg(ogaKey, ogaCode, ogaOg)`. `ogNmF_allVariantsAg` — view (`ogaKey, ogaCode, ogNm`) через `ogAg⋈ogNmF_allVariants`. `cstAgPn`: match-ключ `cstapIpgPnN`. `yyyy(yKey,yyyy)`; `mmmm`: `mKey=mNum=1..12` (12 строк). **Gap для Фазы B:** `ra_stg_agfee` имеет `oafptOgKey`, но **нет** `oafptOafSenderKey`/`oafptPnCstAgPnKey`; текущий `AgFeeStage2Service` пишет `ags.og.ogKey` — это **не** `ogaKey` (ошибка модели).
- ✅ A.3. Повторно прочитать VBA-файлы из §2 построчно на этапе реализации каждого шага (не только на этапе планирования).
  - **Исполнено для инвентаризации 2026-07-20:** повторно прочитаны `ra_aAgFee23_06.Audit` / `AuditFillFromSource` (порядок шагов §3.2, `myArray` 17 колонок), `ogAgFee.cls` (поля заголовка), `ogAgFeePn.cls` (`parent`/`oafpOaf`). Правило остаётся в силе для Фаз B–D (повторное чтение при реализации каждого шага).
- ✅ A.4. Сверить `ra_col_map`/`ra_sheet_conf` (rsc_key=2, 17 колонок) — актуальны ли алиасы заголовков Excel для снимков `2026_03`/`2026-07`.
  - **Исполнено 2026-07-20:** оба файла — лист **`Акты`**, пароль `303` (CDFV2). Заголовки Stage 1 совпадают с `ra_col_map` (нормализация locator: trim + `\n`→пробел — trailing-space/vbLf в map не ломают match). Июль добавил 2 колонки (`Миграция КС БУиРГ`, `Замечания в КС БУиРГ`) — вне map, игнорируются. Счётчики: **март 666 строк / 32 акта**; **июль 1987 / 117**. `rsc_sheet=NULL` (динамический лист) — ок для текущего файла с фиксированным «Акты». **В4 частично закрыт** (структура/счётчики; smoke Stage1 — Фаза F).

**Краткая сводка Фазы A (2026-07-20):**
- ✅ DDL и lookup-контур зафиксированы; §4 актуализирован.
- ✅ Excel март/июль пригодны для Stage 1; `ra_col_map` актуален.
- ⚠️ Перед Фазой B: исправить модель Stage 2a (`ogaKey` + ключ стройки в staging, не `og.ogKey`).
- ✅ Фаза A закрыта → следующий шаг **Фаза B**.

### Фаза B: Stage 2a — FK-резолюция (порт `ogAgFeePnTestAgentKey`/`CstKey`) ✅

- ✅ B.1. Портировать резолюцию агента: `ags.ogNmF_allVariantsAg` + код стройки (первые 3 символа `oafptPnCstAgPn`) + строгая проверка `keyCount=1`.
  - **Исполнено 2026-07-20:** DDL `oafptOafSenderKey` / `oafptPnCstAgPnKey` (Liquibase `2026-07-20-ra-stg-agfee-fk-keys.sql` + пакет `docs/development/notes/sql/26-0720/` / MSSQL2012). `AgFeeStage2Service` переписан: UPDATE агента через `ogNmF_allVariantsAg` + `LEFT(cst,3)` + `HAVING COUNT=1`; join на staging **по имени и коду** (ужесточение legacy SP, где join был только по имени). `oafptOgKey` больше не заполняется из `ags.og`.
- ✅ B.2. Реализовать эквивалент `ogAgFeePnTestAgentNo` как diagnostic-запрос (WARN в лог при неоднозначности/отсутствии — без прерывания прогона, как в VBA).
  - **Исполнено 2026-07-20:** `loadAgentAnomalies` + `AgFeeFkAnomalyFormatter.formatAgentAnomaliesHtml`; `AgFee2306AuditFileProcessor` пишет WARN `FILE_AGFEE_2306_AGENT_NO` или INFO «Все отправители идентифицированы».
- ✅ B.3. Портировать резолюцию стройки (`cstAgPn.cstapIpgPnN`) + diagnostic `ogAgFeePnTestCstNo`.
  - **Исполнено 2026-07-20:** UPDATE `oafptPnCstAgPnKey`; diagnostic `loadCstAnomalies` + HTML `FILE_AGFEE_2306_CST_NO` / OK.
- ✅ B.4. Unit/IT-тесты на реальных данных снимков март/июль.
  - **Исполнено 2026-07-20:** unit `AgFeeFkAnomalyFormatterTest` (4 теста, BUILD SUCCESS). DBHub-проверка SQL на фикстуре `exec_key=-72001` (строки как в Excel март: «Газпром инвест»+`051-*` → `ogaKey=1`, `cstapKey` заполнены; неизвестный агент/`999-*` → NULL + AgentNo). Полный Stage1 на файлах март/июль — **Фаза F**.

**Краткая сводка Фазы B (2026-07-20):**
- ✅ Staging FK-колонки и порт AgentKey/CstKey готовы; В5 закрыт.
- ✅ Diagnostic AgentNo/CstNo в `adt_results` через процессор.
- ✅ Фаза B закрыта → следующий шаг **Фаза C** (уровень заголовка Акт).

### Фаза C: Stage 2b — уровень заголовка (Акт) ✅

- ✅ C.1. Match: группировка `ra_stg_agfee` по `(senderKey, oafName, oafDate)` для текущего `exec_key` → сравнение с `ags.ogAgFee`.
  - **Исполнено 2026-07-20:** `buildHeaders` + `loadDomainActs` по `YEAR(oafDate)=modalYear`; ключ `ActKey(cstaAg, oafNum, oafDate)`.
- ✅ C.2. NEW: вставка новых Актов (`year`/`month` из даты, `ags.yyyy`) — порт `ogAgFeePnTestActAdd`.
  - **Исполнено 2026-07-20:** `INSERT ogAgFee(oafNum,oafDate,cstaAg,oafY,oafM)` + сразу attrs при однозначности (эквивалент ActAdd→ActAttrTrue).
- ✅ C.3. MISSING_IN_SOURCE: диагностика/удаление Актов за год, отсутствующих в источнике (`adt_AddRA`-guard) — порт `ActDbOnlyDel`.
  - **Исполнено 2026-07-20:** удаление только при `ctx.addRa()`; `DELETE ogAgFee` (CASCADE на `ogAgFeeP`). **В2 закрыт** для уровня Акт.
- ✅ C.4. ATTR_CHANGED: сверка/обновление 11 атрибутов заголовка — порт `ogAgFeePnTestActAttrTrue`; diagnostic задвоения — порт `ActAttr`.
  - **Исполнено 2026-07-20:** 9 бизнес-полей + `oafY`/`oafM`; при >1 варианте attrs в источнике — WARN `RECONCILE_AGFEE_ACT_ATTR`, update пропускается.
- ✅ C.5. Dry-run счётчики уровня заголовка.
  - **Исполнено 2026-07-20:** при `addRa=false` — `ReconcileResult.skipped` с счётчиками NEW/ATTR_CHANGED/UNCHANGED/AMBIGUOUS/MISSING; unit `AgFee2306ReconcileServiceTest` 5/5 OK.

**Краткая сводка Фазы C (2026-07-20):**
- ✅ `AgFee2306ReconcileService` больше не стаб на уровне Актов.
- ⚠️ Пункты (`ogAgFeeP`) и tree-лог — Фазы D/E.
- ✅ Фаза C закрыта → следующий шаг **Фаза D**.

### Фаза D: Stage 2b — уровень Пункта (только после Фазы C для текущего `exec_key`) ✅

- ✅ D.1. Match: построчно `ra_stg_agfee` (с уже резолвленным `oafKey` через JOIN на Акт из C) → сравнение с `ags.ogAgFeeP`.
  - **Исполнено 2026-07-20:** ключ `(ActKey, oafptPnCstAgPnKey)` ↔ `(oafpOaf, oafpCstAgPn)`; группировка `buildStagingPns`.
- ✅ D.2. NEW: вставка новых Пунктов — порт `ogAgFeePnTestActPnAdd`/`DbNo`.
  - **Исполнено 2026-07-20:** `INSERT ogAgFeeP(oafpOaf, oafpCstAgPn, oafpTotal)`; skip при NULL ttl; dry-run: пункты актов NEW → `pendingParent`.
- ✅ D.3. MISSING_IN_SOURCE: диагностика/удаление Пунктов за год — порт `ExcNoDel`/`fnOgAgFeePnTestExcNo`.
  - **Исполнено 2026-07-20:** scope `YEAR(oafDate)=@yearAct`; удаление только при `addRa`. **В2 закрыт.**
- ✅ D.4. SUM_CHANGED: сверка/обновление `oafpTotal` — порт `ActPnNoEq`.
  - **Исполнено 2026-07-20:** `compareTo` money; разночтения ttl в источнике → WARN, без update.
- ✅ D.5. Итоговая сверка годовой суммы (информационно) — порт финального блока VBA.
  - **Исполнено 2026-07-20:** sum staging vs `SUM(oafpTotal)` за год; событие `RECONCILE_AGFEE_YEAR_SUM` (без Excel-формулы SUBTOTAL — эквивалент по staging).

**Краткая сводка Фазы D (2026-07-20):**
- ✅ Полный двухуровневый reconcile Акт→Пункты в `AgFee2306ReconcileService`.
- ✅ `@yearAct`: приоритет `AuditExecutionContext.year`, иначе модальный год дат (В6 частично).
- ✅ Unit `AgFee2306ReconcileServiceTest` 9/9.
- ✅ Фаза D закрыта → следующий шаг **Фаза E** (tree-лог) или опциональный dry-run F.0.

### Фаза E: Логирование (см. §5.2) ✅

- ✅ E.1. `Type6ReconcileTreeLogger` — дерево Акт→Пункты + счётчики.
  - **Исполнено 2026-07-20:** span «Акты агентского вознаграждения» → nested акт → пункты (NEW/SUM/UNCH/MISSING/PENDING_PARENT); счётчики в SUMMARY.
- ✅ E.2. Плоские diagnostic-секции (AgentNo/CstNo/ActAttr/итоговая сумма).
  - **Исполнено 2026-07-20:** AgentNo/CstNo — Stage 2a в процессоре; ActAttr + `RECONCILE_TYPE6_YEAR_SUM` — в tree logger.
- ✅ E.3. Сверка формулировок с VBA HTML (цвета Crimson/DarkGreen/Chocolate/CadetBlue) — стилистически согласовано с type=3/5.

**Краткая сводка Фазы E (2026-07-20):** unit `Type6ReconcileTreeLoggerTest` 2/2; smoke dry-run `exec_key=1199` — `adt_results` содержит дерево (~967 КБ).

### Фаза F: Идемпотентность и smoke (год **2026** инкапсулирован)

**Контекст (уточнено 2026-07-20 / baseline после F.5–F.6):** снимки март/июль — акты с датами **2026**. `ActDbOnlyDel`/`ExcNoDel` — только `@yearAct` (`YEAR(oafDate)=…`) — **2021–2025 не затрагиваются**. После F: домен **2026 = мартовский baseline (31 акт / 521 пункт)**; `adt_AddRA=0`. Ориентиры Excel: март ≈ **31** уник. актов / 666 строк; июль ≈ **86** заголовков reconcile / 1987 строк (ранее оценка по Excel ~91).

- ✅ F.0. Dry-run марта при `af_key=313` **без** apply.
  - **Исполнено 2026-07-20:** JAR `0.1.0.138`/`139`; `exec_key=1198` (до E) / `1199` (с tree); `adt_AddRA=0`; staging **666**, заголовков **31** NEW, пунктов NEW **521** (`pendingParent=521`), MISSING актов/пунктов **0**, `skipCst=144`, сумма ист≈**5 558 976 847.24**, БД=0. Домен 2026 не изменён.
- ✅ F.1. Включить `af_execute=true`/`af_source=true` для `af_key=313` (`adt_dir=15`, ревизия `test_26` / 2026).
- ✅ F.2. Dry-run `2026_03` на seeded домене → NEW=0, UNCHANGED актов=31 / пунктов=521, Δ суммы=0 (`exec_key=1203`, после rollback).
- ✅ F.3. Переключение на `2026-07` → apply → diff vs март.
  - **Исполнено:** `audit-switch-agfee-snapshot.sh`; july `exec_key=1202`: staging **1987**, headers **86**, актов NEW=**56** UNCH=**30** MISSING=**1** (del), пунктов NEW=**1037** UNCH=**513**; домен после july **86/1550**, сумма≈**1.613e10**, Δ=0.
- ✅ F.4. Идемпотентность на мартовском baseline после rollback: dry-run NEW=0 / UNCH=31+521 (`exec_key=1203`).
- ✅ F.5. **Seed baseline:** apply марта `exec_key=1201` → домен **31/521**, oafKey **2452–2482**, сумма=ист, Δ=0.
- ✅ F.6. Apply июля → rollback к марту.
  - Rollback: `DELETE YEAR=2026` + re-seed марта `exec_key` после wipe; скрипт `rollback-agfee-to-march-baseline.sh` + `femsq-sql.js` (без sqlcmd). Итог: снова **31/521**, `adt_AddRA=0`.

**Момент seed (F.5):** выполнен 2026-07-20; домен 2026 = мартовский baseline.

### Фаза G: Документация, UAT в браузере, закрытие задачи 0055

**Порядок (2026-07-21):** G.1–G.4 — артефакты разработки; **G.5 — приёмка оператором в UI** (обязательна для полного sign-off плана); G.3 закрывает инженерный scope 0055 после G.1–G.2/G.4 (UAT G.5 остаётся чек-листом оператора).

- ✅ G.1. Обновить `ra-audit-file-processor-architecture.md` — type=6 Stage2a/reconcile/tree **реализованы** (0055).
- ✅ G.2. Обновить `audit-log-vba-to-java-mapping.md` — `J-C.6` present; gap F.5–F.6 снят; опциональный gap — `AuditExecutionContext.year` (В6).
- ✅ G.3. `project-development.json`: задача **0055 → completed**; журнал + chat-plan.
- ✅ G.4. Скрипты: `audit-switch-agfee-snapshot.sh`, `rollback-agfee-to-march-baseline.sh`, `femsq-sql.js`.
- ✅ **G.5. UAT в браузере (оператор — Александр)** — PASS 2026-07-21 на `test_26` / `af_key=313`:
  1. ✅ Backend JAR ≥ `0.1.0.139` → `0.1.0.143`; `adt_key=14`; type=6 март; `adt_AddRA=false`.
  2. ✅ UI → **COMPLETED**; дерево «Акты агентского вознаграждения», годовая сумма.
  3. ✅ Dry-run baseline: NEW≈0, без изменений ≈31/521, Δ=0 (exec 1207/1208).
  4. ✅ **B** UI-apply март (exec 1209); ✅ **C** UI июль dry-run (1210) → apply (1211, домен 86/1550, Δ=0) → `rollback-agfee-to-march-baseline.sh` → снова **31/521**, снимок март, `adt_AddRA=false`.
  5. ✅ Sign-off; подписи актов: `+`/`−`, имя из `ogAgCs` (JAR 0.1.0.144).

### Задача 0056: читаемость лога type=6 (после UAT G.5.2) ✅

**Контекст:** при dry-run марта в SUMMARY — ~тысячи WARN «пусто № Акта» с 667-й строки; блок CstNo выглядит как 72 «акта», хотя это 72 кода строек; дерево/подробности с `NEW/UNCH/skipCst`.

| # | Изменение | Статус |
|---|-----------|--------|
| 0056.1 | Stage 1: `findLastSignificantAgFeeRowIndex0` — № Акта **+** код стройки / дата Excel (не хвост UsedRange с «665») | ✅ |
| 0056.2 | DDL `oafptRow` + Stage 1 пишет Excel-строку (`StagingExcelRowColumns`) | ✅ |
| 0056.3 | CstNo: одна стройка → список Excel-строк; блок Agent/Cst — **свёртываемые** spans | ✅ (exec 1208) |
| 0056.4 | Русские подписи; SUMMARY без спама UNCHANGED; суммы `5 558 976 847,24`; «Stage»→«Этап» | ✅ |
| 0056.5 | Unit + UAT dry-run JAR ≥ 0.1.0.142/143 | ✅ (exec 1207–1208; WARN пустых=0; spans; суммы) |

SQL: `docs/development/notes/sql/26-0721/`.

### После 0055 (вне scope закрытия; при необходимости)

| # | Действие | Приоритет |
|---|----------|-----------|
| П1 | **В6:** при старте ревизии заполнять `AuditExecutionContext.year` из ревизии | низкий (март/июль и так 2026) |
| П2 | Вернуть `af_execute` для type=3/5 на `dir=15`, если нужен смешанный `test_26` | по необходимости |
| П3 | Задача **0054** (prod bootstrap `ra_a`) — после доступа к FishEye | блокер prod |
| П4 | Прод-пакет DDL Stage2a `docs/development/notes/sql/26-0720/MSSQL2012/` при выкате | с окном на prod |
| П5 | Git-коммит кода/docs/скриптов AgFee | ✅ 2026-07-21 |

---

## 7. Открытые вопросы

| # | Вопрос | Статус |
|---|--------|--------|
| В1 | Точный DDL `ags.ogAgFee`/`ags.ogAgFeeP` (типы полей, NOT NULL, индексы) | ✅ ЗАКРЫТ (A.1, §4) |
| В2 | `adt_AddRA`-guard для удаления Актов/Пунктов (`ActDbOnlyDel`/`ExcNoDel`) — подтвердить, что в Java-модели это тот же флаг `adtAddRA`, что и для type=3/5 | ✅ ЗАКРЫТ (C.3/D.3: `ReconcileContext.addRa`) |
| В3 | Нужен ли отдельный скрипт переключения снимков для type=6, или расширить `audit-switch-excel-snapshot.sh` | ✅ ЗАКРЫТ — отдельный `audit-switch-agfee-snapshot.sh` (+ rollback) |
| В4 | Реальное содержимое файлов `202* Свод инф-ции по Актам.xlsx` на шаре | ✅ (март/июль 2026; smoke F) |
| В5 | Staging: колонки ключей агента/стройки vs `oafptOgKey` | ✅ ЗАКРЫТ (B.1) |
| В6 | Источник `@yearAct`: ctx.year vs модальный год дат | ⏳ опционально после 0055 (П1); для март/июль совпадает |
| В7 | UAT браузер (G.5) | ✅ PASS 2026-07-21 (dry-run + B + C) |
| В8 | Читаемость лога type=6 (диапазон/CstNo/дерево) | ✅ **0056** |

---

## 8. Ссылки

- Задачи: `docs/development/project-development.json` → `0055`, `0056`
- Журнал: `chat-2026-07-20-001`
- Предыдущий (несделанный) скелет: `chat-plan-26-0323-reconcile-specific.md#фаза-4-type-6-ra_stg_agfee--домен`
- Параллельный prod-блокер (не путать): `chat-plan-26-0707-ralp-reconcile.md#9511-prod-bootstrap-таблиц-ревизий-access--mssql-новая-задача-0054` (задача 0054)
- Общая архитектура процессоров: `docs/development/notes/analysis/ra-audit-file-processor-architecture.md`
- Доступ к шаре на nb-win: `docs/development/remote-development-nb-win.md#порядок-доступа-к-шаре-на-nb-win-приоритет`
- SQL 0056: `docs/development/notes/sql/26-0721/`

**Последнее обновление:** 2026-07-21  
**Версия:** 1.0.0
