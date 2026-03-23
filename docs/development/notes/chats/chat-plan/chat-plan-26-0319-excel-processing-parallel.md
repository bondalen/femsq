# План работы: Excel-конвейер в ревизии (параллельная разработка, af_type=2/3/5/6)

**Дата создания:** 2026-03-19  
**Проект:** FEMSQ  
**Версия плана:** 0.9.1  
**Цель:** Реализовать параллельный конвейер переноса Excel → staging (`ags.ra_stg_*`) → доменные таблицы для всех активных типов файлов (`af_type=2,3,5,6`) с минимизацией type-specific кода на ранних этапах.

---

## Ссылки

- **Архитектура процессоров файлов / технические решения:** `docs/development/notes/analysis/ra-audit-file-processor-architecture.md`
- **Анализ VBA / оригинальная логика:** `docs/development/notes/analysis/ra-audit-btnAuditRun-analysis.md`
- **VBA-исходник AllAgents:** `docs/project/proposals/vba-analysis/VBA-Code-Export/Class-Modules/ra_aAllAgents.cls`
- **VBA-исходник формы:** `docs/project/proposals/vba-analysis/VBA-Code-Export/Form-Modules/Form_ra_a.cls`
- **Каталог артефактов Access (таблицы/запросы):** `docs/project/proposals/vba-analysis/access-queries/README.md`
- **Порядок снятия сведений из Access:** `docs/project/proposals/vba-analysis/MS-ACCESS-OBJECTS-CAPTURE.md`

---

## Специальный пункт (горячие следы): метаданные MS Access → `access-queries/`

**Зачем:** чтобы в `docs/project/proposals/vba-analysis/access-queries/` было **по одному файлу на каждую описанную таблицу** (`{Имя}.table.md`) и **по одному на каждый вынесенный запрос** (`{Имя}.access.sql`), без дублей; число таких файлов визуально соответствует охвату объектов Access для контура ревизии `af_type ∈ {2,3,5,6}`.

**Нормативка:** один файл на таблицу (в т.ч. Caption/Description, индексы, ссылки на SQL Server staging); запросы — вы передаёте сырой SQL как **`.txt`**, в репозитории хранится доработанный **`*.access.sql`** (см. `MS-ACCESS-OBJECTS-CAPTURE.md` §3).

**Общий статус пункта:** [x] выполнено — закрыты контуры **типов 2/3/5/6** (S.1/S.2 по `cn_PrDocImp` + `ags_PdSdRRcList`, аренда и агентское вознаграждение); остаётся только чеклист `S.3`.

### S.1. Таблицы Access (подпункты по `af_type`)

Имена промежуточных таблиц — как в Access/VBA; соответствие staging в SQL Server — по `ra-audit-file-processor-architecture.md` §6.1.

#### S.1.1. `af_type = 5` — отчёты всех агентов (лист `Отчеты`)

| Объект Access | Файл в репозитории | Статус |
|----------------|-------------------|--------|
| `ra_ImpNew` | `access-queries/ra_ImpNew.table.md` (+ опционально `ra_ImpNew.dump.utf8.txt`) | ✅ |
| (общий модуль DAO-дампа, не «таблица») | `access-queries/DumpTableDef_RaImpNew.bas` | ✅ |

#### S.1.2. `af_type = 2` — хранение / стройконтроль (лист `ХрСтрКнтрл`)

| Объект Access | Staging SQL Server | Файл в репозитории | Статус |
|----------------|--------------------|--------------------|--------|
| `cn_PrDocImp` | `ags.ra_stg_cn_prdoc` | `access-queries/cn_PrDocImp.table.md` | ✅ (2026-03-21) |

#### S.1.3. `af_type = 3` — аренда земли

**Статус подпункта:** ✅ выполнен целиком (обе таблицы задокументированы).

| Объект Access | Лист Excel | Staging SQL Server | Файл в репозитории | Статус |
|----------------|------------|--------------------|--------------------|--------|
| `ralpRaAuTest` | `Аренда_Земли` | `ags.ra_stg_ralp` | `access-queries/ralpRaAuTest.table.md` | ✅ (2026-03-19) |
| `ralpRaSumTest` | `учет_аренды` | `ags.ra_stg_ralp_sm` | `access-queries/ralpRaSumTest.table.md` | ✅ (2026-03-19) |

#### S.1.4. `af_type = 6` — агентское вознаграждение (23-0628)

| Объект Access | Staging SQL Server | Файл в репозитории | Статус |
|----------------|--------------------|--------------------|--------|
| `ags_ogAgFeePnTest` *(linked table, ODBC -> `ags.ogAgFeePnTest`)* | `ags.ra_stg_agfee` | `access-queries/ags_ogAgFeePnTest.table.md` | ✅ (2026-03-19) |
| `ogAgFeePnTest` *(local table, используется в `Form_ra_a.cls`)* | локальный буфер af_type=6 | `access-queries/ogAgFeePnTest.table.md` | ✅ (2026-03-19) |

### S.2. Сохранённые запросы QueryDef (подпункты по `af_type`)

Каждый запрос → один `access-queries/{ИмяЗапроса}.access.sql` после доработки из исходного `.txt`.

#### S.2.1. `af_type = 5`

| Запрос Access | Файл в репозитории | Статус |
|---------------|-------------------|--------|
| `ra_ImpNewQuRa` | `access-queries/ra_ImpNewQuRa.access.sql` | ✅ |
| `ra_ImpNewQuRc` | `access-queries/ra_ImpNewQuRc.access.sql` | ✅ |

#### S.2.2. `af_type = 2` (`ХрСтрКнтрл` / `RAAudit_cn_PrDoc`)

**Таблица** `cn_PrDocImp` — см. `access-queries/cn_PrDocImp.table.md` (✅). Ниже — объекты для выгрузки SQL (по одному `*.access.sql` на **запрос** / linked view).

| Объект Access | Примечание | Файл в репозитории | Статус |
|---------------|------------|-------------------|--------|
| `cn_PrDocImp` | **таблица**, не QueryDef | — (только `.table.md`) | ✅ |
| `cn_PrDocImp_Compare` | явный `db.QueryDefs("cn_PrDocImp_Compare")` | `cn_PrDocImp_Compare.access.sql` | ✅ |
| `cn_PrDocImp_Cn` | Recordset (запрос или view) | `cn_PrDocImp_Cn.access.sql` | ✅ |
| `cn_PrDocImp_CnInv` | цепочка `CnInv*` (базовое звено) | `cn_PrDocImp_CnInv.access.sql` | ✅ |
| `cn_PrDocImp_CnInvEx` | цепочка `CnInv*` | `cn_PrDocImp_CnInvEx.access.sql` | ✅ |
| `cn_PrDocImp_CnInvExCsosEx` | цепочка; от `cn_PrDocImp_CnInvEx` | `cn_PrDocImp_CnInvExCsosEx.access.sql` | ✅ |
| `cn_PrDocImp_CnInvExCsosExPdEx` | цепочка; от `CnInvExCsosEx` + ags_cn_PrDoc | `cn_PrDocImp_CnInvExCsosExPdEx.access.sql` | ✅ |
| `cn_PrDocImp_CnInvExCsosExPdExPnEx` | цепочка; + ags_cn_PrDocP | `cn_PrDocImp_CnInvExCsosExPdExPnEx.access.sql` | ✅ |
| `cn_PrDocImp_CnInvExCsosExPdExPnNt` | агрегат «нет строки в ags_cn_PrDocP» (`pdpKey Is Null`) | `cn_PrDocImp_CnInvExCsosExPdExPnNt.access.sql` | ✅ |
| `cn_PrDocImp_CnInvExCsosExPdExPnNtOneAccDoc` | позиция найдена, но `accountingDocNull` буфер ≠ БД (см. SQL) | `cn_PrDocImp_CnInvExCsosExPdExPnNtOneAccDoc.access.sql` | ✅ |
| `cn_PrDocImp_CnInvNt` | нет `ciKey` на сервере; `HAVING x.ciKey Is Null`; `inKeyCount` | `cn_PrDocImp_CnInvNt.access.sql` | ✅ |
| `cn_PrDocImp_CnInvExCsosNt` | вариант CsosEx; `account_key`; `y.ciasKey Is Null` | `cn_PrDocImp_CnInvExCsosNt.access.sql` | ✅ |
| `cn_PrDocImp_CnInvExCsosExPdNt` | вариант PdEx; `HAVING` без шапки ПД; `NumDateCount` | `cn_PrDocImp_CnInvExCsosExPdNt.access.sql` | ✅ |
| `cn_PrDocImp_CnInvExCsosExPdExPnNtIn` | от PnNt + буфер + `ags_cn_PrDocP`; флаги `*Equal` | `cn_PrDocImp_CnInvExCsosExPdExPnNtIn.access.sql` | ✅ |
| `cn_PrDocImp_CnInvExCsosExPdExPnExRs` | цепочка; сравнение i/b + агрегат `rslt` (см. комментарии в SQL) | `cn_PrDocImp_CnInvExCsosExPdExPnExRs.access.sql` | ✅ |
| `ags_PdSdRRcList` | динамический `.SQL` в VBA; снимок + шаблоны | `ags_PdSdRRcList.access.sql` | ✅ |

#### S.2.3. `af_type = 3`

**Статус подпункта:** ✅ выполнен целиком (идентифицированы и оформлены QueryDef `ralpRaAuTestQuRa` и `ralpRaAuTestQuAu`).

| Задача | Статус |
|--------|--------|
| Имена и SQL запросов для сценариев `RAAudit_ralp` / `RAAudit_ralpSum` (навигатор Access или обход `AllQueries`) | ✅ *(минимум идентифицирован: `ralpRaAuTestQuRa`, `ralpRaAuTestQuAu`)* |
| Оформление по одному `*.access.sql` на запрос + ссылки из `ralpRaAuTest.table.md` / `ralpRaSumTest.table.md` | ✅ *(сделаны `ralpRaAuTestQuRa.access.sql` и `ralpRaAuTestQuAu.access.sql`)* |

#### S.2.4. `af_type = 6`

| Задача | Статус |
|--------|--------|
| Идентификация **Access QueryDef** сценария `RAAudit_AgFee_Month` / `ra_aAgFee23_06` | ✅ *(именованные QueryDef не используются: в VBA применяется `CreateQueryDef(\"\", ...)` ad-hoc)* |
| Идентификация используемых **SQL Server objects (`ags.*`)** из `ra_aAgFee23_06.cls` | ✅ *(получается из кода и при необходимости подтверждается через DBHub; отдельно в `access-queries/` не фиксируем)* |
| Оформление Access QueryDef в `*.access.sql` + ссылки из `ags_ogAgFeePnTest.table.md` | ✅ *(не требуется: нет сохранённых QueryDef для этого контура)* |

### S.3. Закрытие спринта по этому пункту

- [x] В `access-queries/README.md` обновлена таблица «Текущий состав» (фактический список `*.table.md` и `*.access.sql`).
- [x] Нет нарушения правила «одна таблица — один `{имя}.table.md`» (исключение: общие `.bas` для дампа).
- [x] При появлении нового типа/листа — сначала дополнение этого пункта плана, затем файлы в `access-queries/`.

---

## Зафиксированный scope по `af_type`

| `af_type` | ft_name | Статус |
|-----------|--------|--------|
| 1 | отчёты агента | УСТАРЕВШИЙ — не реализовывать (пропуск с логом) |
| 2 | хранение оборудования и стройконтроль | В работе: `CnPrDocAuditFileProcessor` |
| 3 | аренда земли | В работе: `RalpAuditFileProcessor` (2 листа) |
| 4 | агентское вознаграждение | УСТАРЕВШИЙ — не реализовывать (пропуск с логом) |
| 5 | отчёты всех агентов | В работе: `AllAgentsAuditFileProcessor` |
| 6 | 23-0627_агентское вознаграждение | В работе: `AgFee2306AuditFileProcessor` |

---

## Что считается техническим “каркасом” (вынесено в архитектуру)

Все решения по:
- иерархии процессоров и template method lifecyle,
- модели доступа к файлу (`af_name` / `af_temp_path`),
- декларативному маппингу колонок (`ra_sheet_conf`, `ra_col_map`),
- staging-таблицам (`ags.ra_stg_*`) и их naming,
- двум стадиям заполнения staging и месту computed/derived полей,

описаны в `ra-audit-file-processor-architecture.md` и **не дублируются** здесь.

---

## Фаза 0: Подготовительные правки (общие для всех типов) ✅

**Цель:** подготовить сервис к корректному асинхронному выполнению и правильному доступу к Excel-файлам в обоих режимах (direct / upload).

### 0.0. Статус готовности Фазы 0 (короткий чек-лист)
- ✅ `@EnableAsync` в `FemsqWebApplication` и `@Async` на `AuditExecutionServiceImpl.executeAudit` (асинхронный старт)
- ✅ `poi-ooxml` в `code/femsq-backend/femsq-web/pom.xml`
- ✅ выставление `context.setDirectoryPath(...)` в `AuditExecutionServiceImpl.executeAudit`
- ✅ реализация/включение резолва полного пути файла и режима доступа (`resolveFileAccess` по архитектуре)
- ✅ явный guard устаревших `af_type=1` и `af_type=4` (log WARN + пропуск до открытия Excel)
- ✅ bump версии до `0.1.0.91-SNAPSHOT`

### 0.1. Базовые зависимости для Excel (Apache POI) ✅
- Добавить `org.apache.poi:poi-ooxml` в `femsq-web/pom.xml`
- Проверить отсутствие конфликтов (`mvn dependency:tree`)

**Исполнено (2026-03-20):**
- В `code/femsq-backend/femsq-web/pom.xml` добавлена зависимость `org.apache.poi:poi-ooxml:5.2.5`.
- Проверка `mvn -pl femsq-web -am -DskipTests dependency:tree` упёрлась в существующую проблему резолва локального артефакта `com.femsq:femsq-database` в модуле `femsq-reports` (к POI-правке не относится).

### 0.2. Асинхронное выполнение `executeAudit` ✅
- Убедиться, что старт выполняется в фоне и GraphQL mutation возвращает результат немедленно

**Исполнено (2026-03-20):**
- В `code/femsq-backend/femsq-web/src/main/java/com/femsq/web/FemsqWebApplication.java` включён `@EnableAsync`.
- В `code/femsq-backend/femsq-web/src/main/java/com/femsq/web/audit/AuditExecutionServiceImpl.java` на методе `executeAudit(...)` установлен `@Async`.
- В GraphQL-контроллере вызов `auditExecutionService.executeAudit(id)` используется как асинхронный старт ревизии.

### 0.3. Контекст ревизии: `directoryPath` ✅
- В `AuditExecutionServiceImpl.executeAudit` заполнить `AuditExecutionContext.setDirectoryPath(...)`
- `directoryPath` должен соответствовать источнику из БД (на основании `audit.adtDir`)

**Исполнено (2026-03-20):**
- В `code/femsq-backend/femsq-web/src/main/java/com/femsq/web/audit/AuditExecutionServiceImpl.java` добавлен `RaDirService` в оркестратор.
- При старте `executeAudit(...)` путь директории ревизии читается по `adtDir` и сохраняется в `context.setDirectoryPath(dir.dir())`.
- При отсутствии директории добавлен `WARN`-лог, выполнение продолжается.

### 0.4. Резолв полного пути файла и режим доступа ✅
- `resolveFileAccess()` (или `resolveFilePath()`) должен выбрать путь:
  - direct: читаем `ra_f.af_name` напрямую
  - upload: читаем `ra_f.af_temp_path`
- Важно: процессоры получают готовый `filePath` и не открывают Excel вне `af_source=true`

**Исполнено (2026-03-20):**
- В `AuditExecutionServiceImpl` добавлен `resolveFilePath(...)`.
- Для абсолютных/UNC путей используется `af_name` как есть.
- Для относительных имён путь собирается как `context.directoryPath + af_name`.
- В `AuditFile` теперь передаётся уже резолвнутый `filePath`.

### 0.5. Guard устаревших типов ✅
- В `switch(file.getAfType())` добавить явные `case 1, 4`:
  - `log.warn(...)`
  - `continue` до любой работы с Excel/путями

**Исполнено (2026-03-20):**
- В оркестраторе добавлен ранний guard по `af_type=1` и `af_type=4`.
- Для устаревших типов пишется `WARN` в server log и `AuditLogEntry` в журнал ревизии.
- Файлы этих типов пропускаются до создания `AuditFile` и до вызова процессоров.

### 0.6. Поднять версию проекта ✅
- `0.1.0.90-SNAPSHOT` → `0.1.0.91-SNAPSHOT` (в `code/pom.xml` и `code/femsq-backend/pom.xml`)

**Исполнено (2026-03-20):**
- В `code/pom.xml` обновлена версия до `0.1.0.91-SNAPSHOT`.
- В `code/femsq-backend/pom.xml` обновлена версия parent до `0.1.0.91-SNAPSHOT`.

---

## Фаза 1: Liquibase/DDL для staging и маппинга колонок (один раз) ✅

**Цель:** обеспечить полностью воспроизводимую схему на любых окружениях.

**Статус фазы (2026-03-20):**
- ✅ Подпункты `1.0`, `1.1`, `1.2`, `1.3` исполнены.
- ✅ Liquibase changeSet'ы для DDL и seed добавлены в `db/changelog`.
- ✅ Схема и данные сверены через DBHub с фактическим состоянием SQL Server.
- ✅ Базовый Maven compile проходит успешно после синхронизации parent-версий модулей.

### 1.0. JPA/DAO слой для конфигурации маппинга и сессий ✅
- Создать JPA-сущности `RaSheetConf`, `RaColMap` и репозиторий `AuditColumnMappingRepository`
- Обновить хранение статуса исполнения: `AuditExecutionRegistry` → `ra_execution` (через `RaExecutionDao`)

**Исполнено (2026-03-20):**
- В модуле `femsq-database` добавлены модели и JDBC DAO:
  - `RaSheetConf`, `RaColMap`, `RaExecution`
  - `RaSheetConfDao/JdbcRaSheetConfDao`
  - `RaColMapDao/JdbcRaColMapDao`
  - `RaExecutionDao/JdbcRaExecutionDao`
- Добавлены сервисы:
  - `RaSheetConfService`, `RaColMapService`, `RaExecutionService` (и default-реализации).
- В `DatabaseModuleConfiguration` зарегистрированы новые DAO/Service бины.
- В `femsq-web` добавлен репозиторий `AuditColumnMappingRepository` (`DbAuditColumnMappingRepository`).
- `AuditExecutionRegistry` переведён на хранение статуса в `ags.ra_execution` через `RaExecutionService` (вместо in-memory `ConcurrentHashMap`).

### 1.1. `ra_execution` ✅
- Хранение статуса/изоляция запуска ревизии

**Исполнено (2026-03-20):**
- Добавлен Liquibase changeSet `femsq:2026-03-20-ra-execution` в `code/femsq-backend/femsq-web/src/main/resources/db/changelog/changes/2026-03-20-ra-audit-staging.sql`.
- Таблица `ags.ra_execution` описана в DDL с PK `PK_ra_execution` и полями статуса запуска ревизии.

### 1.2. staging-таблицы ✅
- `ags.ra_stg_ra`
- `ags.ra_stg_cn_prdoc`
- `ags.ra_stg_ralp`
- `ags.ra_stg_ralp_sm`
- `ags.ra_stg_agfee`

**Исполнено (2026-03-20):**
- Добавлен Liquibase changeSet `femsq:2026-03-20-ra-staging-tables` для всех пяти staging-таблиц.
- DDL синхронизирован по фактической серверной схеме (типы, nullable, identity, PK).

### 1.3. `ra_sheet_conf` и `ra_col_map` ✅
- Таблицы **должны быть доступны через DBHub/SQL Server**
- Данные для типов `2/3/5/6` должны быть загружены в `ra_col_map` и `ra_sheet_conf`

**Исполнено (2026-03-20):**
- Добавлен Liquibase changeSet `femsq:2026-03-20-ra-mapping-tables` (DDL) и seed changeSet’ы:
  - `femsq:2026-03-20-ra-sheet-conf-seed`
  - `femsq:2026-03-20-ra-col-map-seed`
- Добавлен master changelog: `code/femsq-backend/femsq-web/src/main/resources/db/changelog/db.changelog-master.yaml`.
- Проверка через DBHub: таблицы присутствуют в схеме `ags`; записи загружены (`ra_sheet_conf=5`, `ra_col_map=105`).

> Примечание: в текущей ветке схема и данные уже присутствуют на сервере, но в этом плане требуется добавить Liquibase `changeSet` (runOnChange="false") для воспроизводимости.

---

## Фаза 2: Общая Excel-инфраструктура (`audit.excel`)

**Цель:** дать общий набор компонентов чтения Excel без type-specific “ручной магии”.

### 2.1. Компоненты ✅
- `AuditExcelReader` (`withWorkbook`)
- `AuditExcelColumnLocator` (якорь + headers по `ra_col_map`)
- `AuditExcelCellReader` (typed reads: String/Date/Int/Decimal)
- `AuditExcelException`

**Исполнено (2026-03-20):**
- Добавлен пакет `com.femsq.web.audit.excel` в `femsq-web`:
  - `AuditExcelReader` (безопасное открытие/закрытие workbook),
  - `AuditExcelColumnLocator` (поиск anchor-строки и колонок по `ra_col_map`),
  - `AuditExcelCellReader` (typed reads: `String/Integer/BigDecimal/LocalDate`),
  - `AuditExcelException` (единое инфраструктурное исключение Excel-слоя).

---

## Фаза 3: Stage 1 (Excel → staging) — параллельно по типам ✅

**Цель:** заполнить staging-таблицы полностью результатом Excel:
- Stage 1 прямой перенос данных по `ra_col_map`
- context поля (`*_exec_key` и т.п. по соглашению из архитектуры)
- **без** reconcileWithDb и без вычислений derived, которые логически относятся к Stage 2.

**Статус фазы (2026-03-20):**
- ✅ `3.1` реализован: generic `AuditStagingService` с anchor/header mapping и batch-insert в `ags.ra_stg_*`.
- ✅ `3.2` реализован: wire-up процессоров типов `2/3/5/6` к Stage 1 сервису.

### 3.1. Реализовать `AuditStagingService` (generic) ✅
- Схема вызовов:
  - найти лист(ы) и anchor row по `ra_sheet_conf`
  - собрать `Map<stgCol, excelColIdx>` по `ra_col_map` с приоритетами `rcm_xl_hdr_pri`
  - итерировать строки данных
  - batch-INSERT в staging-таблицу

**Исполнено (2026-03-20):**
- Добавлены `AuditStagingService` и `DefaultAuditStagingService` (`com.femsq.web.audit.staging`).
- Реализован generic Stage 1 pipeline:
  - чтение `ra_sheet_conf`/`ra_col_map` через `AuditColumnMappingRepository`,
  - поиск anchor/header через `AuditExcelColumnLocator`,
  - typed-read ячеек через `AuditExcelCellReader`,
  - batch INSERT в `rsc_stg_tbl` с учётом `*_exec_key` из `AuditExecutionContext.executionKey`.
- В `AuditExecutionContext` добавлен `executionKey`; при старте `executeAudit(...)` он заполняется из `ra_execution`.

### 3.2. Wire-up в процессоры ✅
- `AllAgentsAuditFileProcessor` (type 5) → `ags.ra_stg_ra`
- `CnPrDocAuditFileProcessor` (type 2) → `ags.ra_stg_cn_prdoc`
- `RalpAuditFileProcessor` (type 3):
  - `Аренда_Земли` → `ags.ra_stg_ralp`
  - `учет_аренды` → `ags.ra_stg_ralp_sm`
- `AgFee2306AuditFileProcessor` (type 6) → `ags.ra_stg_agfee`

**Исполнено (2026-03-20):**
- Процессоры типов `2/3/5/6` подключены к `AuditStagingService`:
  - `CnPrDocAuditFileProcessor` (новый, type 2),
  - `RalpAuditFileProcessor` (обновлён, type 3),
  - `AllAgentsAuditFileProcessor` (обновлён, type 5),
  - `AgFee2306AuditFileProcessor` (новый, type 6).
- Для `af_source=true` выполняется Stage 1 загрузка в staging через generic сервис; для `af_source=false` выполняется no-op с логированием.

---

## Фаза 4: Stage 2a/2b (FK и derived/computed) — параллельно по типам ✅

**Цель:** довести staging-данные до формы, пригодной для `reconcileWithDb()`.

**Статус фазы (2026-03-20):**
- ✅ `4.1` (Type 5): явный Stage 2 no-op.
- ✅ `4.2` (Type 2): реализован Stage 2a FK-resolution (`cnpdTpOrdKey`, `pdpCstAgPnKey`).
- ✅ `4.3` (Type 3): реализованы Stage 2a (FK) и Stage 2b (`ralprtStatus`).
- ✅ `4.4` (Type 6): реализован Stage 2a (`oafptOgKey`) и guard `ctx.auditType == 1`.

### 4.1. Type 5 ✅
- no-op (данные уже готовы для reconcile)

**Исполнено (2026-03-20):**
- В `AllAgentsAuditFileProcessor` зафиксирован явный Stage 2 no-op для `af_type=5`.
- После Stage 1 добавляется отдельная запись в журнал ревизии: `FILE_ALL_AGENTS_STAGE2_NOOP`.

### 4.2. Type 2 ✅
- FK resolution по текстовым полям staging

**Исполнено (2026-03-20):**
- Добавлен `CnPrDocStage2Service` (`com.femsq.web.audit.stage2`) для Stage 2a по `ags.ra_stg_cn_prdoc`.
- Реализованы SQL-обновления FK по `exec_key`:
  - `cnpdTpOrdKey` через `ags.cn_PrDocT` (`pdtoText`),
  - `pdpCstAgPnKey` через `ags.cstAgPn` (`cstapIpgPnN`).
- `CnPrDocAuditFileProcessor` обновлён: после Stage 1 вызывается Stage 2a и пишется отдельная запись в журнал ревизии.

### 4.3. Type 3 ✅
- FK resolution по текстовым полям staging
- Java computation derived-поля (пример: `ralprtStatus` через три флага)

**Исполнено (2026-03-20):**
- Добавлен `RalpStage2Service` (`com.femsq.web.audit.stage2`) для Stage 2a/2b по таблицам:
  - `ags.ra_stg_ralp` (лист `Аренда_Земли`),
  - `ags.ra_stg_ralp_sm` (лист `учет_аренды`).
- Реализован Stage 2a (FK resolution по `exec_key`):
  - `ralprtCstAgPn` через `ags.cstAgPn` (`cstapIpgPnN`),
  - `ralprtOgSender` через `ags.ogNmF` (`onfName` + `onfNameExt`),
  - `ralprsSender` через `ags.ogNmF` (`onfName`).
- Реализован Stage 2b (derived):
  - `ralprtStatus` вычисляется SQL-правилом из флагов `ralprtPresented`, `ralprtSentToBook`, `ralprtReturnedFlg`.
- `RalpAuditFileProcessor` обновлён: после Stage 1 вызывается Stage 2, результат фиксируется отдельной записью в журнал ревизии.

### 4.4. Type 6 ✅
- FK resolution по текстовым полям staging
- соблюсти guard: `ctx.auditType == 1` (как в архитектуре)

**Исполнено (2026-03-20):**
- Добавлен `AgFeeStage2Service` (`com.femsq.web.audit.stage2`) для Stage 2a по `ags.ra_stg_agfee`.
- Реализован FK-resolution по `exec_key`:
  - `oafptOgKey` через `ags.og` (`ogNm` ↔ `oafptOafSender`).
- В `AgFee2306AuditFileProcessor` добавлен guard:
  - Stage 2 выполняется только при `context.auditType == 1`;
  - в остальных случаях фиксируется явный skip в журнале ревизии.

---

## Фаза 5: Общий reconcile-каркас (staging → домен)

**Цель:** зафиксировать общий каркас reconcile (контракты, транзакции, единые логи и счётчики), без детализации доменной логики по `af_type`.

### 5.0. Подготовить общий reconcile-каркас ✅
- Ввести общий контракт запуска reconcile (вход: `exec_key`, `audit_id`, `addRa`)
- Зафиксировать единый формат логирования шагов reconcile и счётчиков изменений
- Определить транзакционные границы на уровень типа файла
Исполнено:
- Добавлены общий контракт и результат: `ReconcileContext`, `ReconcileResult`, `AuditReconcileService`.
- Добавлен координатор `AuditReconcileCoordinator` с единым логированием (`RECONCILE_START`, `RECONCILE_DONE`, `RECONCILE_SKIPPED`).
- Добавлена транзакционная база `AbstractTransactionalReconcileService` (границы транзакции на один тип файла).
- Подключены type-specific каркасы (`2/3/5/6`) и вызов reconcile из всех файловых процессоров после Stage 2.
### 5.1. Специфика reconcile по `af_type` (вынесено в отдельные чаты)
- `af_type=5` (`ra_stg_ra` → `ags_ra` / `ags_ra_change`): match-логика, upsert/update, запись `*_change`
- `af_type=5` (`ra_stg_ra` → `ags_ra` / `ags_ra_change`): специфические операции из VBA
- `af_type=5` (`ra_stg_ra` → `ags_ra` / `ags_ra_change`): идемпотентность повторного запуска
- `af_type=5` (`ra_stg_ra` → `ags_ra` / `ags_ra_change`): чек-лист верификации
- `af_type=2` (`ra_stg_cn_prdoc` → домен): reconcile по VBA `RAAudit_cn_PrDoc`
- `af_type=2` (`ra_stg_cn_prdoc` → домен): адаптация SQL-логики Access под источники staging
- `af_type=3` (`ra_stg_ralp` + `ra_stg_ralp_sm` → домен): reconcile по VBA `RAAudit_ralp` (2 листа)
- `af_type=3` (`ra_stg_ralp` + `ra_stg_ralp_sm` → домен): фиксация порядка применения изменений между staging-таблицами
- `af_type=6` (`ra_stg_agfee` → домен): reconcile по VBA `RAAudit_AgFee_Month` + `ra_aAgFee23_06.Audit`
- `af_type=6` (`ra_stg_agfee` → домен): guard по `auditType`, согласованный на стадии Stage 2.

Параллелизм (общий принцип):
- можно делать reconcile для каждого типа после готовности Stage 1–4 для этого типа.

---

## Фаза 6: Сборка и ручная проверка

### 6.1. Сборка
- `npm run type-check`
- `mvn ... package` (fat JAR)

### 6.2. Ручная проверка (минимальный чек-лист)
- Запустить JAR для ревизии с `af_type=2,3,5,6`
- Убедиться, что UI не зависает (`@Async` работает)
- Проверить через DBHub:
  - staging-таблицы заполнены
  - записи привязаны к правильному `*_exec_key`
- Проверить: при `af_source=false` staging не загружается (лог отражает счётчики)
- Проверить: при `af_source=true` и `addRa=true` доменные таблицы получают новые/обновлённые данные

---

## Что остаётся за рамками этого плана

- `ra_aTtl` (итоговые суммы ревизии) — отдельный шаг: очистка и заполнение таблиц итогов
- `ra_aTtl` / итоговые агрегаты не включены в reconcile типов 2/3/5/6
- Типы `1` и `4` (устаревшие) — пропуск с логом

---

## Последнее обновление

**Дата:** 2026-03-23  
**Версия:** 0.9.0  
**Изменение:** добавлено отдельное описание локальной таблицы `ogAgFeePnTest.table.md` (дополнительно к linked `ags_ogAgFeePnTest`), чтобы имена объектов `af_type=6` полностью соответствовали фактическим вызовам VBA.

