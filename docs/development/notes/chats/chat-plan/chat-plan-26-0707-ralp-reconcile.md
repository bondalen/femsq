# План работы: Reconcile для `af_type=3` (Аренда земли, RALP)

**Дата создания:** 2026-07-07  
**Последнее обновление:** 2026-07-08  
**Проект:** FEMSQ  
**Версия плана:** 0.5.0  

---

## Цель

Реализовать доменную логику reconcile для `af_type=3` (аренда земли, RALP):
- перенос данных из `ags.ra_stg_ralp` → `ags.ralpRa` + `ags.ralpRaAu`,
- устранение причин VBA-ошибок (чрезмерные соединения к SQL Server) за счёт bulk-load + in-memory matching,
- идемпотентность повторного запуска на том же `exec_key`,
- верификация на реальных данных из `(2026)_Аренда_рабочий.xlsx`.

---

## Предыстория и ссылки

- **Предыдущий чат (reconcile-specific):** `chat-plan-26-0323-reconcile-specific.md` — полная реализация `af_type=5` (AllAgents), служит эталонной архитектурой.
- **Анализ VBA:** `docs/project/proposals/vba-analysis/VBA-Code-Export/Form-Modules/Form_ra_a.cls` (функции `RAAudit_ralp`, `RAAudit_ralpSum`, `FindRalpRaAu`, `FindRalpRa`, строки 2404–3599)
- **Access-таблицы:** `docs/project/proposals/vba-analysis/access-queries/ralpRaAuTest.table.md`, `ralpRaSumTest.table.md`
- **Access-запросы удаления:** `ralpRaAuTestQuRa.access.sql`, `ralpRaAuTestQuAu.access.sql`
- **Стейджинг DDL / ra_col_map seed:** `code/femsq-backend/femsq-web/src/main/resources/db/changelog/changes/2026-03-20-ra-audit-staging.sql`
- **Существующий Java-код:**
  - `RalpAuditFileProcessor.java` — оркестратор Stage 1/2 для `af_type=3`
  - `RalpStage2Service.java` — FK / derived-resolution для `ra_stg_ralp` и `ra_stg_ralp_sm`
  - `RalpReconcileService.java` — reconcile `af_type=3` (bulk-load + in-memory matching + JDBC apply)
- **Excel-файл для тестирования:** `docs/excel/ralp/(2026)_Аренда_рабочий.xlsx`
- **Скриншоты ошибок VBA:** `docs/excel/ralp/26-0707-01.PNG`, `docs/excel/ralp/26-0707-02.PNG`

---

## Вход в чат (что уже сделано)

В предыдущих чатах для `af_type=3` выполнено:
- Stage 1 (Excel → `ags.ra_stg_ralp` и `ags.ra_stg_ralp_sm`) — реализован и работает.
- Stage 2 FK/derived resolution (`RalpStage2Service`): `ralprtCstAgPn`, `ralprtOgSender`, `ralprsSender`, `ralprtStatus` — реализован и работает.
- `RalpReconcileService` — реализован и верифицирован (apply: 1248 записей за 2026 год, exec_key=1133).

---

## Уточнение вопросов перед реализацией

### В1. Маппинг `ralprtArrived` и происхождение `ralpraArrivedDate` — **ЗАКРЫТ** ✅

По данным seed-данных из `2026-03-20-ra-audit-staging.sql`:
- `rcm_key=130`: `ralprtArrived`, ординал=12, заголовок `N'Письмо Агента о направлении отчетов'`, `rcm_rsc_key=4` (лист `Аренда_Земли`).
- Тип в staging: `NVARCHAR(255)` — хранит строковый идентификатор письма.

По анализу VBA `FindRalpRaAu` (строки 3446–3450 `Form_ra_a.cls`):
```vba
!ralpraArrived = strArrived_
DataSourceNull = ParseDate(strArrived_, True)
If IsNull(DataSourceNull) = False Then
    !ralpraArrivedDate = DataSourceNull
End If
```

**Вывод:** `ralpraArrivedDate` **вычисляется из строки** `ralprtArrived` функцией `ParseDate` — та же логика применяется для `ralpraSentDate` ← `ralprtSent` и `ralpraReturnedDate` ← `ralprtReturned`.

**Для Java-реализации:** необходим вспомогательный метод `parseDate(String)` для извлечения даты из строкового поля письма (аналог VBA `ParseDate`). Маппинг:
- `ralprtArrived` → `ralpraArrived` (строка) + `ralpraArrivedDate` (`parseDate(ralprtArrived)`)
- `ralprtSent` → `ralpraSent` + `ralpraSentDate` (аналогично)
- `ralprtReturned` → `ralpraReturned` + `ralpraReturnedDate` (аналогично)

### В2. Доменная таблица для `ralpRaSumTest` (`учет_аренды`) — **НЕ СУЩЕСТВУЕТ**

По результатам запроса к БД — среди таблиц схемы `ags` с маской `*ralp*` присутствуют:
`ra_stg_ralp`, `ra_stg_ralp_sm`, `ralp`, `ralpGr`, `ralpOld`, `ralpRa`, `ralpRaAu`.

Таблицы с именем `ralpSm`, `ralpSum`, `ralpRaSm` и аналогов **не существует**.

**Вывод:** Для сводных данных (`учет_аренды`) нет доменной целевой таблицы. `ralpRaSumTest` в VBA — это только локальный буфер Access для отображения/диагностики, не связанный с `INSERT/UPDATE/DELETE` в SQL Server напрямую.

### В3. Нужен ли DELETE «лишних» записей `ralpRa`/`ralpRaAu` при reconcile — **ЗАКРЫТ** ✅

По анализу `ralpRaAuTestQuRa.access.sql` и `ralpRaAuTestQuAu.access.sql`:
- **`ralpRaAuTestQuRa`**: находит все `ags.ralpRa` за год ревизии (`ralprY = First-yyyy`), у которых нет соответствия в staging (`ralprtKeySQL IS NULL`) → эти записи VBA **удаляет** из `ags.ralpRa`.
- **`ralpRaAuTestQuAu`**: находит все `ags.ralpRaAu`, связанные с `ralpRa` за год ревизии, у которых нет соответствия в staging (`ralprtRaAuKey IS NULL`) → эти записи VBA **удаляет** из `ags.ralpRaAu`.

**Вывод:** DELETE **обязателен** — reconcile выполняет полную синхронизацию (UPSERT + DELETE) за год ревизии. Год берётся из `ags.ra_execution` → `ags.ra_period` → `ags.yyyy`.

**Для Java-реализации:**
1. Определить `year` ревизии через `exec_key`.
2. После UPSERT — DELETE из `ags.ralpRaAu` для `ralpraRa IN (ralpRa за year)` где `ralpraKey NOT IN` применённых `RaAuKey`.
3. DELETE из `ags.ralpRa` за `year` где `ralprKey NOT IN` применённых `RaKey`.

### В4. Нужна ли reconcile для `учет_аренды` (`ra_stg_ralp_sm`) — **НЕ НУЖНА (в текущем объёме)**

Поскольку:
- Нет целевой доменной таблицы в SQL Server (см. В2),
- VBA не выполняла `INSERT/UPDATE/DELETE` для данных `ralpRaSumTest` в SQL Server (лист служил агрегированным представлением для визуального контроля),
- Stage 1/2 для `ra_stg_ralp_sm` уже реализованы и обеспечивают загрузку данных для просмотра/диагностики.

**Вывод:** Reconcile для `ra_stg_ralp_sm` в текущей итерации **не выполняется**. Данные листа `учет_аренды` сохраняются в staging для целей BI/сверки, но не применяются к домену.

**Уточнение у пользователя:** Подтверждено: создание доменной таблицы для `учет_аренды` и полной reconcile для неё в текущей задаче **не входит в объём работ** (отдельная задача). → **(В4 закрыт)**

---

## Архитектурное решение

### Проблема VBA

Функции `RAAudit_ralp` и `FindRalpRaAu` выполняют `db.OpenRecordset` / `db.CreateQueryDef().Execute` для **каждой строки** Excel:
- `FindCstAP` → отдельный `OpenRecordset` к `ags_cstAgPn` на строку,
- `FindRalpRa` → отдельный `OpenRecordset` к `ags_ralpRa` на строку,
- `FindRalpRaAu` → отдельный `OpenRecordset` к `ags_ralpRaAu` на строку.

Это приводит к исчерпанию Named Pipes пула и ошибкам Error 3151 (`ODBC connection failed`).

### Решение Java: Bulk-load + In-memory matching

По образцу реализованного `af_type=5` (`AllAgentsReconcileService`):

1. **Однократная загрузка всех нужных доменных данных** в `Map`-структуры:
   - `ralpRa`: все записи, совпадающие по `exec_key`/году — в `Map<MatchKey, RalpRaRecord>`.
   - `ralpRaAu`: все записи, связанные с загруженными `ralpRa` — в `Map<Integer, RalpRaAuRecord>`.
2. **In-memory матчинг** staging → доменные записи.
3. **Batch JDBC** для применения `INSERT`/`UPDATE`/`DELETE`.

### Ключ матчинга

Анализ VBA `FindRalpRa` и `FindRalpRaAu` (строки 3534–3599, 3025–3600 `Form_ra_a.cls`):
- `ralpRa` идентифицируется по: `(ralprCstAgPn, ralprOgSender, ralprNum, ralprDate)` или подмножеству.
- `ralpRaAu` связан с `ralpRa` через `ralpraRa = ralprKey`.

Точные правила матчинга уточняются при реализации (Фаза 2).

### Scope reconcile (финальный)

| Sheet | Staging | Домен | Reconcile |
|---|---|---|---|
| `Аренда_Земли` | `ags.ra_stg_ralp` | `ags.ralpRa` + `ags.ralpRaAu` | **ДА** |
| `учет_аренды` | `ags.ra_stg_ralp_sm` | — | НЕТ (нет доменной таблицы) |

---

## Фаза 0: Preflight и smoke-тест ✅

### 0.1. Уточнение вопросов и подтверждение объёма ✅

- ✅ 0.1.1. Подтверждено: reconcile для `учет_аренды` в текущем объёме **не выполняется** (В2, В4 закрыты).
- ✅ 0.1.2. `ralpraArrivedDate` вычисляется из строки `ralprtArrived` через `ParseDate(strArrived_, True)` — строки 3446–3450 `Form_ra_a.cls`. Аналогично для `ralpraSentDate` ← `ralprtSent`, `ralpraReturnedDate` ← `ralprtReturned`. (В1 закрыт.)
- ✅ 0.1.3. Финальный маппинг полей зафиксирован в Фазе 1 (§ «Маппинг полей»).

**Инфраструктурные fix (исполнено 2026-07-07):**

В ходе подготовки к smoke-тесту выявлены и устранены три технических блокера:

1. **Пакет `com.femsq.web.audit.excel` отсутствовал в репозитории** (`AuditExcelReader`, `AuditExcelCellReader`, `AuditExcelColumnLocator`, `AuditExcelException`) — создан (4 файла).
2. **Apache POI: `ZipSecureFile` false-positive** — Excel-файл блокировался как «Zip bomb» из-за `xl/styles.xml` (ratio 0.01 < limit 0.01). Исправлено: `ZipSecureFile.setMinInflateRatio(0.0)` в `AuditExcelReader.withWorkbook`.
3. **Парсинг чисел в русском формате** — строка `"130,092,19"` не разбиралась как `BigDecimal`. Реализован метод `normalizeDecimalString` в `AuditExcelCellReader` (запятые как разделители тысяч, последняя запятая — десятичный разделитель).

Сборка: `femsq-web-0.1.0.110-SNAPSHOT.jar`. Конфигурация БД: `database.properties` → `10.7.0.3:1433/FishEye` (prod-fisheye).

### 0.2. Smoke-тест Stage 1 для `af_type=3` ✅

- ✅ 0.2.1. Использован существующий аудит `adt_key=14` (`test_26`). Обновлены: `af_name` → `docs/excel/ralp/(2026)_Аренда_рабочий.xlsx`, `af_source=true`, `af_execute=true`, `ra_dir.dir` → Linux-путь к папке с файлом.
- ✅ 0.2.2. Stage 1 отработал без ошибок. `ra_stg_ralp` = **1262 строки**, `ra_stg_ralp_sm` = **27 строк** (exec_key=1128, статус COMPLETED, длительность 44 сек).
- ✅ 0.2.3. Stage 2 отработал: `ralprtCstAgPn` и `ralprtOgSender` заполнены (7 строк из 1262 не resolved — норма). `ralprtStatus` = 0 NULL (все заполнены).
- ✅ 0.2.4. Качество ключевых полей: `ralprtNum`=0 NULL, `ralprtDate`=0 NULL, `ralprtCstAgPn`=7 NULL (0.55%), `ralprtOgSender`=7 NULL (0.55%), `ralprtArrived`=0 NULL, `ralprtStatus`=0 NULL. **GO.**
- ✅ 0.2.5. `exec_key = 1128`.

**Краткая сводка (2026-07-07):**
- ✅ Stage 1 + Stage 2 стабильно работают для `af_type=3`.
- ✅ Ключевые поля для матчинга пригодны: NULL только для 7 записей из 1262.
- ✅ Зафиксирован `exec_key=1128` для последующих DBHub-проверок.

### 0.3. DBHub-проверки staging ✅

```sql
-- Результаты по exec_key=1128 (2026-07-07):
-- total_rows=1262, num_null=0, date_null=0, cst_null=7, og_null=7, arrived_null=0, status_null=0
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN ralprtNum IS NULL OR ralprtNum = '' THEN 1 ELSE 0 END) AS num_null,
    SUM(CASE WHEN ralprtDate IS NULL THEN 1 ELSE 0 END) AS date_null,
    SUM(CASE WHEN ralprtCstAgPn IS NULL THEN 1 ELSE 0 END) AS cst_null,
    SUM(CASE WHEN ralprtOgSender IS NULL THEN 1 ELSE 0 END) AS og_null,
    SUM(CASE WHEN ralprtArrived IS NULL THEN 1 ELSE 0 END) AS arrived_null,
    SUM(CASE WHEN ralprtStatus IS NULL THEN 1 ELSE 0 END) AS status_null
FROM ags.ra_stg_ralp
WHERE ralprt_exec_key = 1128;
```

- ✅ 0.3.1. Запрос выполнен, показатели зафиксированы выше.
- ✅ 0.3.2. **GO** для старта Фазы 1: критических NULL нет, staging качественный.

### 0.4. Изучение VBA-логики `RaTestAdd` — **ЗАКРЫТО (покрыто Фазой 1)** ✅

- ✅ 0.4.1–0.4.3. Маппинг и происхождение `ralpraArrivedDate` зафиксированы в Фазе 1 (В1, § «Маппинг полей»). Отдельный разбор `RaTestAdd` не требуется — `RaTestAdd` заполняет только локальный буфер Access, не домен SQL Server.

### 0.5. Исправление `.gitignore` для `audit/excel` ✅

**Проблема (выявлено 2026-07-08):** правило `excel/` в `.gitignore` (строка 95) матчит и `code/.../audit/excel/`, из-за чего 4 Java-файла пакета `com.femsq.web.audit.excel` не попадают в git.

- ✅ 0.5.1. Правило уточнено: `excel/` → `/docs/excel/`.
- ✅ 0.5.2. 4 файла `audit/excel/*.java` видны в `git status` как untracked.

---

## Маппинг полей (финальный — Фаза 1) ✅

| `ra_stg_ralp` | `ralpRa` | `ralpRaAu` | Примечание |
|---|---|---|---|
| `ralprtNum` (+ норм.) | `ralprNum` | — | Ключ матчинга; при `ralprtPresented=1` первый `-` → `/` |
| `ralprtDate` | `ralprDate` | — | Ключ матчинга |
| `ralprtCstAgPn` | `ralprCstAgPn` | — | FK из Stage 2; ключ матчинга (INVALID если NULL) |
| `ralprtOgSender` | `ralprOgSender` | — | FK из Stage 2; ключ матчинга (INVALID если NULL) |
| *(computed)* | `ralprY` | — | Вычисляемая колонка: `YEAR(ralprDate)` — в INSERT не указывается |
| *(computed)* | `ralprM` | — | Вычисляемая колонка: `MONTH(ralprDate)` — в INSERT не указывается |
| `ralprtArrived` | — | `ralpraArrived` | Ключ матчинга ralpRaAu; пусто → ralpRaAu не обрабатывается |
| `ralprtArrived` | — | `ralpraArrivedDate` | `parseDate(ralprtArrived)` |
| `ralprtSent` | — | `ralpraSent` + `ralpraSentDate` | Обновляется при CHANGED |
| `ralprtReturned` | — | `ralpraReturned` + `ralpraReturnedDate` | Обновляется при CHANGED |
| `ralprtCostAndVat` | — | `ralpraCostAndVat` | Обновляется при CHANGED |
| `ralprtNote` | — | `ralpraNote` | Обновляется при CHANGED |
| `ralprtStatus` | — | `ralpraStatus` | Из Stage 2; обновляется при CHANGED |
| `ralprtTestStartDate` | — | `ralpraTestStartDate` | Обновляется при CHANGED |
| `ralprtPresented` | — | *(служебный)* | Нормализация `ralprNum` |
| `ralprtSentToBook` | — | *(служебный)* | Stage 2 → `ralprtStatus` |
| `ralprtReturnedFlg` | — | *(служебный)* | Stage 2 → `ralprtStatus` |

---

## Фаза 1: Анализ VBA-логики и ключи матчинга ✅

### 1.1. Детальный разбор `RAAudit_ralp` и `FindRalpRaAu` ✅

- ✅ 1.1.1. Изучены строки 2643–2975 (`RAAudit_ralp`) и 3025–3511 (`FindRalpRaAu`) `Form_ra_a.cls`.
- ✅ 1.1.2. **Ключ матчинга `ralpRa`:** `(ralprNum, ralprDate, ralprCstAgPn, ralprOgSender)` — все четыре поля. SQL: `ralprNum=? AND ralprDate=? AND ralprCstAgPn=? AND ralprOgSender=?`. **Важно:** при `ralprtPresented=1` в VBA первый `-` в номере заменяется на `/` → нужна та же нормализация при матчинге в Java.
- ✅ 1.1.3. **Ключ матчинга `ralpRaAu`:** `(ralpraRa, ralpraArrived)` — FK к `ralpRa` + строка письма. SQL: `ralpraRa=raKey AND ralpraArrived=strArrived_`. Если `ralprtArrived` пусто — FindRalpRaAu сразу возвращает False (рассмотрение не обрабатывается).
- ✅ 1.1.4. Разобраны `ralpRaAuTestQuRa.access.sql` и `ralpRaAuTestQuAu.access.sql`: orphan-записи определяются через `LEFT JOIN ralpRaAuTest ON ralpRa.ralprKey = ralprtKeySQL WHERE ralprtKeySQL IS NULL`, скоп — `ralprY = First-yyyy` (год ревизии).
- ✅ 1.1.5. DELETE выполняется **при `addRa=true`**: сначала orphan `ralpRaAu` (по `ralpraKey`), затем orphan `ralpRa` (по `ralprKey`).
- ✅ 1.1.6. **Категории результатов:**
  - `INVALID` — `ralprtCstAgPn IS NULL` OR `ralprtOgSender IS NULL` OR `ralprtDate IS NULL`
  - `NEW_RA` — не найден в домене → INSERT `ralpRa` (+ INSERT `ralpRaAu` если `ralprtArrived` не пустой)
  - `NEW_RAAAU` — `ralpRa` найден, `ralpRaAu` не найден → INSERT `ralpRaAu`
  - `CHANGED_RAAU` — `ralpRa` найден, `ralpRaAu` найден, есть отличия → UPDATE `ralpRaAu`
  - `UNCHANGED` — `ralpRa` найден, `ralpRaAu` найден, нет отличий
  - `DELETED_RA` — `ralpRa` за год без соответствия в staging → DELETE
  - `DELETED_RAAU` — `ralpRaAu` без соответствия в staging → DELETE
  
  **Поведение `ralpRa` при FOUND:** VBA не обновляет `ralpRa`-поля у существующих записей — только `ralpRaAu` подлежит UPDATE.

**Нормализация номера (VBA-семантика):**
```
if (ralprtPresented == 1 && ralprtNum.contains("-")) {
    ralprNum = ralprtNum.replaceFirst("-", "/");  // только первое вхождение
}
```

### 1.2. Изучение доменных таблиц `ralpRa` / `ralpRaAu` ✅

- ✅ 1.2.1. **Схема `ags.ralpRa`:** `ralprKey` (PK, IDENTITY), `ralprNum`, `ralprDate`, `ralprCstAgPn`, `ralprOgSender`, `ralprY`/`ralprM` (**вычисляемые** — `is_computed=1`, в INSERT не указываются).
  **Схема `ags.ralpRaAu`:** `ralpraKey` (PK), `ralpraRa` (FK→ralpRa), `ralpraCostAndVat` (money), `ralpraArrived`/`ralpraArrivedDate`, `ralpraReturned`/`ralpraReturnedDate`, `ralpraSent`/`ralpraSentDate`, `ralpraNote`, `ralpraStatus` (tinyint, DEFAULT 0), `ralpraTestStartDate`, `ralpra_fdKey` (nullable, не используется в reconcile).
- ✅ 1.2.2. Таблицы `ra_change`-типа для RALP **отсутствуют** — структура проще, чем Type 5.
- ✅ 1.2.3. **`ralpRa` за 2026 год: 1248 записей** (после apply, exec_key=1133). До apply: 0. `ralpRa` всего: ~12 386 строк (2020–2026).

```sql
-- Объём данных для 2026 года (зафиксировано 2026-07-07):
-- ralpRa_2026 = 0, ralpRaAu_2026 = 0
SELECT COUNT(*) AS ralpRa_2026 FROM ags.ralpRa WHERE ralprY = 2026;
```

---

## Фаза 2: Реализация `RalpReconcileService` ✅

### 2.1. Загрузка reference-данных в память ✅

- ✅ 2.1.1. Год ревизии берётся из первой не-NULL даты в `ra_stg_ralp.ralprtDate` (`YEAR(MIN(ralprtDate))`). `ra_dir_s_p` в production DB отсутствует — прямая цепочка через `ra_period` недоступна.
- ✅ 2.1.2. `loadDomainRa(conn, year)`: `SELECT ... FROM ags.ralpRa WHERE ralprY=?` → `Map<RaKey, DomainRa>`. `RaKey = record(num, date, cstAgPn, ogSender)`.
- ✅ 2.1.3. `loadDomainRaAu(conn, raKeySet)`: `SELECT ... WHERE ralpraRa IN (...)` → `Map<RaAuKey, DomainRaAu>`. `RaAuKey = record(ralpraRa, arrived)`.
- ✅ 2.1.4. `RaKey(String num, LocalDate date, int cstAgPn, int ogSender)` — все четыре поля. При построении ключа из staging: нормализация `num` при `ralprtPresented=1`.

### 2.2. Match-логика (staging → домен) ✅

- ✅ 2.2.1–2.2.5. Реализован обход staging-строк: `INVALID` → skip; матчинг в `Map<RaKey,DomainRa>` → `NEW_RA` / found; если found → матчинг в `Map<RaAuKey,DomainRaAu>` → `NEW_RAAAU` / `CHANGED_RAAU` / `UNCHANGED`.

### 2.3. Apply-шаг (запись в домен) ✅

- ✅ 2.3.1. INSERT `ralpRa`: `{ralprNum, ralprDate, ralprCstAgPn, ralprOgSender}` + `Statement.RETURN_GENERATED_KEYS` (триггеры запрещают `OUTPUT INSERTED`).
- ✅ 2.3.2. INSERT `ralpRaAu` для новых и для orphan-arrived: `{ralpraRa, ralpraArrived, ralpraArrivedDate(=parseDate(arrived)), ralpraCostAndVat, ralpraSent, ralpraSentDate(=parseDate(sent)), ralpraReturned, ralpraReturnedDate, ralpraNote, ralpraStatus, ralpraTestStartDate}`.
- ✅ 2.3.3. UPDATE `ralpRa` — **не выполняется** (VBA не обновляет поля `ralpRa` существующих записей).
- ✅ 2.3.4. UPDATE `ralpRaAu`: поля `{ralpraCostAndVat, ralpraSent, ralpraSentDate, ralpraReturned, ralpraReturnedDate, ralpraNote, ralpraStatus, ralpraTestStartDate}`.
- ✅ 2.3.5–2.3.6. DELETE orphan `ralpRaAu` (IN-список ключей не в `survivingRaAuKeys`) и orphan `ralpRa` (IN-список ключей за год не в `survivingRaKeys`).
- ✅ 2.3.7. При `addRa=false`: все INSERT/UPDATE/DELETE пропускаются, счётчики показывают planned, `ReconcileResult.skipped(msg)`.
- ✅ 2.3.8. Batch JDBC для обновления staging-ссылок; INSERT/UPDATE/DELETE через отдельные `PreparedStatement` на row (для получения `INSERTED.ralprKey`).

### 2.4. Обновление staging-ссылок ✅

- ✅ 2.4.1. Batch UPDATE `ra_stg_ralp SET ralprtRaKey=?, ralprtRaAuKey=? WHERE ralprt_key=?` после apply.
- ✅ 2.4.2. Счётчик `stagingLinked` в log-сообщении.

### 2.5. Счётчики и вывод в `adt_results` ✅

- ✅ 2.5.1–2.5.2. Результат: `type=3 RALP year=... staging=... invalid=... raInserted=... raAuInserted=... raAuUpdated=... unchanged=... raDeleted=... raAuDeleted=... addRa=...` → в `ReconcileResult.message()` → пишется в `adt_results`.

---

## Сессия 2026-07-08: идемпотентность и документирование ✅

**Порядок работ на сегодня:**

1. ✅ **0.5** — исправить `.gitignore` (`excel/` → `/docs/excel/`)
2. ✅ **3.3** — тест идемпотентности (повторный apply при `ralpRa_2026=1248`)
3. ✅ **4.x** — документирование (project-docs, development, journal)
4. ✅ Обновить план чата (финальный статус)

**Предусловия:**
- JAR: `femsq-web-0.1.0.114-SNAPSHOT.jar`
- Аудит: `adt_key=14`, `adt_AddRA=true`
- БД: `10.7.0.3:1433/FishEye`
- Снапшот домена: `ralpRa_2026=1248`, `ralpRaAu_2026=1248` (проверено 2026-07-08)

---

## Фаза 3: Верификация

### 3.1. Dry-run прогон ✅

- ✅ 3.1.1. Запуск с `adt_AddRA=false` (exec_key=1129): `[RALP] done: raInserted=1248 raAuInserted=0 raAuUpdated=0 unchanged=0 invalid=14 addRa=false`.
- ✅ 3.1.2. `ags.ralpRa` и `ags.ralpRaAu` **не изменились** — dry-run не применял данные.
- ✅ 3.1.3. Dry-run счётчики: `raInserted=1248` (planned) — соответствует `1262 - 14 invalid = 1248`.

  **Замечание:** в dry-run `raAuInserted=0` (а не 1248), т.к. без `raDbKey` цикл не может проверить ralpRaAu — аналог VBA поведения.

### 3.2. Apply прогон ✅

- ✅ 3.2.1. Запуск с `adt_AddRA=true` (exec_key=1133, сборка `femsq-web-0.1.0.114-SNAPSHOT`).

  **Выявленные и устранённые ошибки apply:**
  - `ralprY`/`ralprM` — вычисляемые колонки, убраны из INSERT.
  - `OUTPUT INSERTED` запрещён при наличии триггеров → переход на `Statement.RETURN_GENERATED_KEYS`.
  - `SCOPE_IDENTITY()` возвращал NULL при разрыве между PreparedStatement-ами → заменён на `RETURN_GENERATED_KEYS`.

- ✅ 3.2.2. `ralpRa` за 2026 год: **1248 записей** (верифицировано DBHub).
- ✅ 3.2.3. `ralpRaAu` за 2026 год: **1248 записей** (1:1 к `ralpRa`).
- ✅ 3.2.4. Выборочная сверка (5 строк): `ralprDate`, `ralpraArrived`, `ralpraArrivedDate`, `ralpraStatus` — все значения корректны (дата из строки парсится правильно).
- [ ] 3.2.5. Идемпотентность — перенесено в § 3.3.

  **Статистика apply прогона (exec_key=1133):**
  ```
  raInserted=1248  raAuInserted=1248  raAuUpdated=0
  unchanged=0  invalid=14  raDeleted=0  raAuDeleted=0
  stagingLinked=1248
  ```
  Длительность: ~4 минуты (1248×2 SQL через сеть). Задача оптимизации производительности — в следующем спринте.

### 3.3. Smoke-тест rollback / idempotency ✅

- ✅ 3.3.1. Снапшот до повторного apply: `ralpRa_2026=1248`, `ralpRaAu_2026=1248` (зафиксировано 2026-07-08, DBHub).
- ✅ 3.3.2. Повторный apply (exec_key=1134): `raInserted=0`, `raAuInserted=0`, `raAuUpdated=0`, `unchanged=1248`, `invalid=14`, `raDeleted=0`, `raAuDeleted=0`, `stagingLinked=1248`. **Идемпотентность подтверждена.**
- ✅ 3.3.3. Rollback не требуется — домен не изменился (`ralpRa_2026=1248` после прогона).

  **Длительность повторного apply:** ~72 сек (Stage 1 + reconcile без INSERT).

---

## Фаза 4: Документирование ✅

- ✅ 4.1. Обновлён `docs/project/project-docs.json` (metadata v1.4.0, lastUpdated 2026-07-08).
- ✅ 4.2. Обновлён `docs/development/project-development.json` (задача № 0042).
- ✅ 4.3. Добавлена запись в `docs/journal/project-journal.json` (chat-2026-07-08-001).
- ✅ 4.4. Версия плана: **0.5.0** (финальный статус).

---

## Блокирующие вопросы (требуют ответа перед Фазой 2)

| # | Вопрос | Статус | Источник уточнения |
|---|--------|--------|---------------------|
| В1 | Откуда берётся `ralpraArrivedDate`? | ✅ ЗАКРЫТ | `ParseDate(strArrived_)` — строки 3446–3450 `Form_ra_a.cls` |
| В2 | Домен для `учет_аренды` не нужен в текущей итерации? | ✅ ЗАКРЫТ | Подтверждено: только Stage 1/2, без reconcile |
| В3 | Нужен ли DELETE «лишних» `ralpRa`/`ralpRaAu` при reconcile? | ✅ ЗАКРЫТ | DELETE обязателен — `ralpRaAuTestQuRa`, `ralpRaAuTestQuAu` |

---

## Доп. факты (актуализировано 2026-07-08)

- Объём `ags.ralpRa`: **~12 386 строк** (2020–2026), `ags.ralpRaAu`: **~12 379 строк**.
- **`ralpRa` за 2026 год: 1248 записей** (после apply, exec_key=1133).
- Staging `ags.ra_stg_ralp`: заполняется при каждом прогоне (~1262 строки на exec_key).
- Таблицы с маской `*ralp*` в схеме `ags`: `ra_stg_ralp`, `ra_stg_ralp_sm`, `ralp`, `ralpGr`, `ralpOld`, `ralpRa`, `ralpRaAu`.
- Доменной таблицы для сводного листа `учет_аренды` нет — только `ags.ra_stg_ralp_sm`.
- `ralprtArrived` в `ra_col_map` подтверждён (rcm_key=130, ординал=12).
- Пакет `com.femsq.web.audit.excel` (4 файла) — **в git** после исправления `.gitignore` (п. 0.5).

---

**Файл создан:** 2026-07-07  
**Последнее обновление:** 2026-07-08  
**Версия:** 0.5.0
