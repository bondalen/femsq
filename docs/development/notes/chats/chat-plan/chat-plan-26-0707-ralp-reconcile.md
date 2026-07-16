# План работы: Reconcile для `af_type=3` (Аренда земли, RALP)

**Дата создания:** 2026-07-07  
**Последнее обновление:** 2026-07-15  
**Проект:** FEMSQ  
**Версия плана:** 0.12.16

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
- **Excel-файл для тестирования:** `/mnt/nb-win-share/femsq/excel/2026_03/(2026)_Аренда_рабочий.xlsx` (SMB-шара nb-win)
- **Скриншоты ошибок VBA:** `docs/development/notes/assets/ralp-revision/26-0707-01.PNG`, `26-0707-02.PNG`

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

- ✅ 0.2.1. Использован существующий аудит `adt_key=14` (`test_26`). Обновлены: `af_name` → путь на SMB-шаре, `af_source=true`, `af_execute=true`, `ra_dir.dir` → `/mnt/nb-win-share/femsq/excel/2026_03`.
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

## Фаза 5: Слияние функционала nb-win backup в audit/excel ✅

**Контекст (2026-07-08):** после commit+push (`461b201`) и `git pull` на nb-win выявлены расхождения локальной backup-копии (`/tmp/audit-excel-nb-win-backup`) и версии в git (Fedora). Стратегия — **точечный merge**, не wholesale-replace.

### 5.1. Принципы слияния ✅

| Файл | Сохранить из Fedora | Вернуть из nb-win backup |
|------|---------------------|--------------------------|
| `AuditExcelReader` | Fix Zip bomb (`ZipSecureFile`) | Пароль `303` для encrypted xlsx, `Path` API |
| `AuditExcelCellReader` | `normalizeDecimalString`, formula cells | Парсинг дат `dd.MM.yy`, `stripUnicodeSpaceSeparators`, `-`/`—` |
| `AuditExcelColumnLocator` | Группировка алиасов по приоритету | Ранняя ошибка для `rcmRequired` заголовков |

### 5.2. Верификация после merge ✅

- ✅ 5.2.1. `mvn -pl femsq-backend/femsq-web -am package -DskipTests` → `0.1.0.115-SNAPSHOT`
- ✅ 5.2.2. Smoke `executeAudit(id:14)` — exec_key=**1135**: `unchanged=1248`, `raInserted=0` (идемпотентность)
- ✅ 5.2.3. Commit + push с Fedora
- ✅ 5.2.4. nb-win: `git pull` → `650fe01`, backup удалён (`/tmp/audit-excel-nb-win-backup`)

### 5.3. Закрытие инцидента audit/excel ✅

- ✅ 5.3.1. Единая версия `audit/excel` в git на обеих машинах (Fedora + nb-win)
- ✅ 5.3.2. Backup nb-win удалён
- ✅ 5.3.3. План обновлён до **0.6.0**

---

## Фаза 6: Пост-валидация и закрытие задачи 0042 🔄

### 6.1. Анализ 14 invalid строк RALP ✅

**exec_key=1135**, критерий invalid в `RalpReconcileService`: `ralprtCstAgPn IS NULL OR ralprtOgSender IS NULL OR ralprtDate IS NULL`.

| Причина | Кол-во | Интерпретация |
|---------|--------|---------------|
| `ralprtCstAgPn` NULL | 7 | Stage 2 не разрешил FK по коду стройки (`026-3005711`, `001-3000010`, `051-2007383`) |
| `ralprtOgSender` NULL | 7 | Stage 2 не разрешил FK по отправителю («Газпром инвест») |
| **Итого invalid** | **14** | Ожидаемо: строки без FK не участвуют в reconcile (аналог VBA-пропуска) |

Вывод: **не баг reconcile**, а следствие неполного FK-resolution на Stage 2. Даты (`ralprtDate`) — 0 NULL.

### 6.2. Smoke `af_type=5` (отчёты агента) ✅

**Общее хранилище (2026-07-08):** Excel на SMB-шаре nb-win, mount `/mnt/nb-win-share` на Fedora (CIFS) и nb-win WSL (bind). Пути в БД обновлены (`ra_dir`, `af_key=312/314`). Локальный `docs/excel/` удалён.

- ✅ 6.2.1. Fedora: `./code/scripts/mount-nb-win-share.sh` (creds из `~/.smbcredentials` пользователя)
- ✅ 6.2.2. `ls /mnt/nb-win-share/femsq/excel/2026_03/` — файлы type=3 и type=5 на месте
- ✅ 6.2.3. Smoke SUMMARY с SMB-шары (2026-07-09): март **exec_key=1140**, июль **exec_key=1141** — см. сравнение ниже

#### 6.2.4. Сравнение SUMMARY: март vs июль (SMB `/mnt/nb-win-share`, `adt_key=14`, dry-run)

| | **Март `2026_03`** | **Июль `2026-07`** (до 7.3.3) | **Июль после 7.3.3** |
|---|---|---|---|
| `exec_key` | 1140 ✅ | 1141/1142 ❌ | **1143 ✅** |
| Строк staging type=5 | 1720 | 0 (rollback) | **5959** |
| **Stage 1 type=5** | **~64 с** | ~170 с → FAILED | **~330 с** (лист «Отчеты») |
| **Полный dry-run** | **~183 с** | FAILED | **~363 с** (~6 мин) |
| Ошибки формата | — | падение на «в электронном виде» | **2 поля → NULL, warning** (`parseErrorFields=2`) |

См. `docs/development/remote-development-nb-win.md` → «Общее хранилище Excel».

### 6.3. Закрытие задачи 0042 ✅

| Критерий | Статус |
|----------|--------|
| RalpReconcileService реализован | ✅ |
| apply 1248 + идемпотентность (1134, 1135) | ✅ |
| audit/excel в git, инцидент закрыт (фаза 5) | ✅ |
| Документация (0042, journal, plan v0.6.0) | ✅ |
| Smoke type=5 SUMMARY SMB (exec 1140/1141) | ✅ март ~3 мин; июль FAILED (данные) |

**Коммиты:** `461b201`, `650fe01`, `c1b6831`, `e2bcef7`

**Следующий спринт (вне 0042):** задача 0043 — оптимизация Stage 1 (StagingLogLevel) и batch apply (задача 0044).

---

## Фаза 7: Оптимизация производительности Stage 1 (задача 0043)

### 7.1. Анализ и решения ✅

#### 7.1.1. Контекст: анализ узких мест (2026-07-09)

Прогон `exec_key=1136` (март, dry-run): **~117 мин** при 1720 строках type=5.

| Источник | Доля | Причина |
|----------|------|---------|
| Одиночный INSERT / `RETURN_GENERATED_KEYS` на каждую строку | ~75% | `logEachStagingRow=true` для type=5 — batch невозможен |
| `saveProgress` каждую секунду c растущим HTML-блобом >400 КБ | ~15% | `buildHtmlLog()` перестраивает весь лог, пишет по WireGuard |
| Reconcile type=5 (dry-run) | ~8% | отдельная задача 0044 |
| Чтение xlsm по SMB | <1% | POI читает файл в RAM один раз |

#### 7.1.2. Решение: `StagingLogLevel` — уровень детализации лога

Ввести enum `StagingLogLevel` в `DefaultAuditStagingService` и `AuditExecutionContext`:

| Уровень | Что пишется в `adt_results` | INSERT-режим | Назначение |
|---------|-----------------------------|--------------|-----------|
| `VERBOSE` | Каждая строка Excel (текущее поведение) | одиночный + `RETURN_GENERATED_KEYS` | Приёмка нового типа файла / сравнение с VBA |
| `SUMMARY` ← **по умолчанию** | Прогресс раз в 100 строк + строки с проблемами (обязательное поле пустое, ошибка формата ячейки, NULL FK на Stage 2) | batch (200 строк) | Обычная эксплуатация |
| `MINIMAL` | Только итоги (`logSheetStats`) | batch | CI / интеграционные тесты |

Ожидаемое время Stage 1 при `SUMMARY`: **~3–5 мин** вместо ~106 мин (экономия >95%).

#### 7.1.3. Переключатель

Поле `adt_staging_log_level` (NVARCHAR) в таблице `ags.ra_a` + GraphQL input `AuditUpdateInput`.
По умолчанию `NULL` = `SUMMARY`. Управляется из UI (выпадающий список в форме ревизии).
Можно переопределить через `application.yml` свойство `audit.staging.default-log-level`.

#### 7.1.4. Примерный вывод SUMMARY-режима в `adt_results`

```
Книга открыта: 2026 Свод инф-ции по ОА.xlsm (3.1 МБ)
Лист «Отчеты»: якорь найден, строка 5. Диапазон данных: строки 6–2500.
Прогресс: Excel-строка 100 — внесено в staging: 87
Прогресс: Excel-строка 200 — внесено в staging: 171
  ⚠ Excel-строка 218: отчёт ГП26-2001234-1, стройка «002-2001234» не найдена (ralprtCstAgPn=NULL)
Прогресс: Excel-строка 300 — внесено в staging: 258
...
Итог, лист «Отчеты»: исходных=2494, принято=1720, пропущено (нет данных)=774, batch-вызовов=9
Книга закрыта. Длительность Stage 1: 3m 42s
```

### 7.2. Реализация ✅

- ✅ 7.2.1. Создать `StagingLogLevel.java` (enum: `VERBOSE`, `SUMMARY`, `MINIMAL`)
- ✅ 7.2.2. DDL: добавить `adt_staging_log_level NVARCHAR(16) NULL` в `ags.ra_a`; добавить в `AuditUpdateInput`, GraphQL-схему, маппер, `RaA` record
- ✅ 7.2.3. `DefaultAuditStagingService`: ветвить по `StagingLogLevel` — batch / одиночный INSERT, частота heartbeat, фильтр ошибок
- ✅ 7.2.4. Удалить `fileTypeSupportsRowParagraph`; уровень лога — из `adt_staging_log_level` / `audit.staging.default-log-level`
- ✅ 7.2.5. Frontend: select в форме ревизии (`VERBOSE` / `SUMMARY` / `MINIMAL`)
- ✅ 7.2.6. Верификация: `exec_key=1139`, `adt_staging_log_level=SUMMARY` — Stage 1 type=5 **~70 с** (1720 строк), полный dry-run **~3 мин** (vs ~117 мин при VERBOSE, exec_key=1136)
- ✅ 7.2.7. Обновить `Type5AcceptanceAdtResultsIntegrationIT` и документацию

### 7.3. Устойчивый парсинг Excel: ошибки формата без падения ревизии (задача 0045)

**Контекст:** smoke июль `exec_key=1141` — `AuditExcelCellReader.readInt()` бросает `AuditExcelException` на тексте «в электронном виде» в колонке `rainRaSheetsNumber` («Кол-во листов ОА», `rcm_required=0`). Транзакция staging откатывается, ревизия `FAILED`. Данные в Excel **не правим в коде** — пользователь исправляет файл по сообщению в `adt_results`.

#### 7.3.1. Правила обработки (зафиксировано)

| Ситуация | Действие со строкой | Значение в staging | Запись в лог (`STAGING_ROW_ISSUE`) |
|----------|---------------------|--------------------|-------------------------------------|
| **Необязательное** поле (`rcm_required=0`), ошибка формата (int/decimal/date) | **Строка принимается** | `NULL` в проблемном поле | WARNING: поле, заголовок Excel, сырое значение, ожидаемый тип; **«строка принята, поле записано как NULL»** |
| **Обязательное** поле (`rcm_required=1`), ошибка формата | **Строка пропускается** | строка не вставляется | WARNING: те же детали; **«строка пропущена»** |
| **Обязательное** поле пустое (текущее поведение) | Строка пропускается | — | «пропущено — недостаточно обязательных данных» |

**Важно:** для необязательных полей ошибка формата **не** является основанием пропустить строку — только обнулить поле и предупредить. Пропуск строки — только при ошибке в **обязательном** поле или при отсутствии обязательных данных.

Счётчики в `STAGING_LOAD_STATS`: `parseErrorFields` (поля с warning, строка принята), `skippedParseError` (строки целиком пропущены из‑за обязательного поля).

#### 7.3.2. Пример сообщения в `adt_results` (SUMMARY)

Необязательное поле (июльский кейс — строка **принимается**):

```
⚠ Excel-строка 4601, лист «Отчеты»:
  колонка rainRaSheetsNumber («Кол-во листов ОА»): ожидается целое число,
  получено «в электронном виде» — строка принята, поле записано как NULL.
```

Обязательное поле (для сравнения):

```
⚠ Excel-строка 512, лист «Отчеты»:
  колонка rainReportNumber («№ отчёта»): ожидается текст, получено «#REF!» — строка пропущена.
```

#### 7.3.3. Реализация

- ✅ 7.3.3.1. `CellReadResult<T>` в `AuditExcelCellReader` — `readIntResult` / `readDecimalResult` / `readDateResult`
- ✅ 7.3.3.2. `DefaultAuditStagingService.bindRow`: `CellParseIssue`; необязательное → `NULL` + warning; обязательное → пропуск строки
- ✅ 7.3.3.3. `STAGING_ROW_ISSUE`: метаданные `rowAction` (`ПРИНЯТА_NULL` / `ПРОПУЩЕНА`), текст по правилам 7.3.1
- ✅ 7.3.3.4. `parseErrorFields`, `skippedParseError` в `logSheetStats` и `STAGING_LOAD_STATS`
- ✅ 7.3.3.5. `AuditExcelCellReaderTest` (unit)
- ✅ 7.3.3.6. Smoke июль SMB **exec_key=1143** (0.1.0.117): **COMPLETED** за **363 с**, `ra_stg_ra=5959`, `parseErrorFields=2`, `skippedParseError=0` (vs FAILED exec 1141/1142 на 0.1.0.116)
- ✅ 7.3.3.7. `try-catch` per-file в `AuditExecutionServiceImpl` + `AUDIT_FILE_ERRORS`

**Критерий приёмки:** `executeAudit(14)` на июльском файле с шары завершается `COMPLETED`; в логе есть предупреждение по строке ~4601; `ra_stg_ra` > 0; данные Excel не изменялись.

---

## Фаза 8: Оптимизация reconcile type=5 apply (задача 0044)

### 8.1. Контекст

После **0043** (SUMMARY) полный dry-run type=5: март **~183 с**, июль **~363 с**. Reconcile type=5 — **~8%** времени (оценка на exec 1136); узкие места apply:

| Операция | Было | Проблема |
|----------|------|----------|
| `UPDATE ags.ra` (changed rows) | по одному `executeUpdate` | N round-trips |
| `INSERT ags.ra_summ` | по одному INSERT + per-row SELECT latest | N+M запросов |
| dry-run `estimateDryRunStats` | `hasSameLatestSum` на каждую changed-строку | N SELECT |
| `UPDATE ags.ra_change` + RC sums | per-row UPDATE + per-row latest из VIEW | N round-trips |
| Построчный аудит apply в `adt_results` | всегда (как при VERBOSE staging) | лишние `appendResult` при SUMMARY |

### 8.2. Решение

| Механизм | Описание |
|----------|----------|
| `StagingLogLevel.emitReconcileRowAudit()` | Построчный аудит apply (created/updated/sums) — **только VERBOSE**; при SUMMARY/MINIMAL — агрегаты reconcile без per-row |
| `APPLY_BATCH_SIZE = 200` | JDBC `addBatch` / `executeBatch` для UPDATE `ags.ra`, batch INSERT `ra_summ`, UPDATE `ra_change` |
| `BULK_IN_CHUNK = 500` | `loadLatestRaSumsBulk` / `loadLatestRcSumsBulk` — один запрос на чанк ключей (ROW_NUMBER / VIEW `ra_chSmLt`) |
| `upsertRaSummWithSnapshot` | Сравнение с preloaded snapshot; batch INSERT только для изменившихся сумм |
| `estimateDryRunStats` | bulk latest sums вместо per-row `hasSameLatestSum` |

### 8.3. Реализация ✅

- ✅ 8.3.1. `StagingLogLevel.emitReconcileRowAudit()` + `emitReconcileRowAudit(ReconcileContext)` в `AllAgentsReconcileService`
- ✅ 8.3.2. `updateChangedRaRows` — JDBC batch UPDATE
- ✅ 8.3.3. `evolveRaSums` — bulk load + batch INSERT `ra_summ`
- ✅ 8.3.4. `estimateDryRunStats` — bulk `loadLatestRaSumsBulk`
- ✅ 8.3.5. `updateChangedRcChanges` — batch UPDATE + bulk RC sums + batch INSERT `ra_change_summ`
- ✅ 8.3.6. `insertNewRaRows` / `insertNewRcChanges` — аудит apply gated по VERBOSE
- ✅ 8.3.7. Helpers: `RaSumSnapshot`, `loadLatestRaSumsBulk`, `loadLatestRcSumsBulk`, `sumBatchUpdateCounts`
- ✅ 8.3.8. Smoke dry-run март SMB **exec_key=1144** (0.1.0.118): **COMPLETED** за **180 с**, `ra_stg_ra=1720` (vs exec 1140 **~183 с** на 0.1.0.117)

| exec_key | JAR | Статус | Время | ra_stg_ra |
|----------|-----|--------|-------|-----------|
| 1140 | 0.1.0.117 | COMPLETED | ~183 с | 1720 |
| **1144** | **0.1.0.118** | **COMPLETED** | **180 с** | **1720** |

**Вывод:** при доле reconcile ~8% в dry-run SUMMARY ускорение полного прогона незначительно (~2%); основной выигрыш — меньше round-trips к БД при apply (`adt_AddRA=1`) и отсутствие построчного аудита reconcile при SUMMARY.

**Критерий приёмки:** dry-run `executeAudit(14)` COMPLETED; время не хуже baseline 0043+0045; идемпотентность type=5 не нарушена (тесты компилируются; IT — при доступной FishEye).

---

## Фаза 9: Доработка производительности, приёмка и вывод в продуктив

**Контекст (2026-07-09):** фазы 7–8 закрыли Stage 1 (SUMMARY), парсинг Excel и batch reconcile apply. Остаточные узкие места (~15% dry-run — `saveProgress`/HTML, per-row INSERT новых RA/RC при apply) и цикл **dev → UAT в UI → prod** ещё не пройдены. На продуктиве (`prod-fisheye`, SQL Server 2012) каталог `lib/` уже развёрнут — обновления передаём **thin JAR** (~700 КБ), не fat JAR (~50 МБ).

### 9.1. Доработка производительности (задачи 0046–0047)

#### 9.1.1. `saveProgress` и HTML-блоб в `adt_results` (задача 0046)

| # | Пункт | Статус |
|---|-------|--------|
| 9.1.1.1 | Замерить долю `saveProgress` / `buildHtmlLog()` на dry-run SUMMARY (exec 1144, март) | ✅ exec **1145** (0.1.0.119): `flushes=12`, `skippedThrottled=3313`, `buildHtmlMs=110`, `dbUpdateMs=5402`, `lastHtmlChars≈463 КБ` |
| 9.1.1.2 | Реже писать прогресс при SUMMARY/MINIMAL (интервал / дельта вместо 1 с) | ✅ `StagingLogLevel.progressFlushIntervalMs()`: VERBOSE 1 с, SUMMARY **10 с**, MINIMAL 30 с |
| 9.1.1.3 | Не перестраивать полный HTML на каждый heartbeat; append-only или лимит размера блоба | ✅ кэш `buildHtmlLog()` по числу записей; skip flush если записей не прибавилось |
| 9.1.1.4 | Smoke dry-run март: цель — сократить полный прогон относительно exec 1144 (~180 с) | ✅ exec **1145**: **155 с** (−25 с, ~14%), `ra_stg_ra=1720` |

**Реализация (0.1.0.119):** `AuditLogPersistStats`, `AUDIT_LOG_PERSIST_STATS` в логе, unit-тесты `AuditExecutionContextHtmlCacheTest`.

**Остаток:** `dbUpdateMs≈5.4 с` на 12 flush — дальнейшее снижение только при уменьшении размера HTML или реже принудительных flush после каждого файла.

#### 9.1.2. Batch INSERT новых строк reconcile type=5 (задача 0047)

| # | Пункт | Статус |
|---|-------|--------|
| 9.1.2.1 | `insertNewRaRows`: bulk-load ключей + JDBC batch INSERT (`RETURN_GENERATED_KEYS`) | ✅ |
| 9.1.2.2 | `insertNewRcChanges`: bulk-load + batch INSERT + bulk RC sums + batch `ra_change_summ` | ✅ |
| 9.1.2.3 | Smoke **apply** type=5 (`adt_AddRA=1`): замер до/после; идемпотентность (`Type5*IntegrationIT` с флагами на FishEye) | ⏳ dry-run exec **1146** **150 с** (0.1.0.120); apply на `adt_key=14` не запускался (`adt_AddRA=false`) |

**Реализация (0.1.0.120):** `RaPeriodNumKey`, `RcNaturalKey`, `bulkLoadRaKeysByPeriodNum`, `bulkLoadRacKeysByNatural`, batch по `APPLY_BATCH_SIZE=200`.

#### 9.1.3. Batch apply RALP `af_type=3` (опционально, в рамках 0047 или отдельный подпункт)

| # | Пункт | Статус |
|---|-------|--------|
| 9.1.3.1 | `RalpReconcileService`: batch INSERT `ralpRa` / `ralpRaAu` вместо row-by-row (~4 мин → цель <2 мин) | ⏳ |
| 9.1.3.2 | Повторный apply: идемпотентность `unchanged=1248` (exec 1134) | ⏳ |

---

### 9.2. Тестовое развёртывание на dev-машине

**Целевые машины:** `alex-fedora` (Cursor, backend) + БД FishEye `10.7.0.3` (контейнер на `nb-win`); Excel — SMB `/mnt/nb-win-share/femsq/excel/`.

| # | Пункт | Статус |
|---|-------|--------|
| 9.2.1 | `git pull` на Fedora и nb-win; mount SMB (`mount-nb-win-share.sh` / WSL bind) | ✅ SMB `/mnt/nb-win-share/femsq/excel/` |
| 9.2.2 | Сборка: `mvn -pl femsq-backend/femsq-web -am package` (или `./code/scripts/build-thin-jar.sh` после 9.1) | ✅ JAR **0.1.0.122** |
| 9.2.3 | DDL на dev FishEye: колонка `ags.ra_a.adt_staging_log_level` (Liquibase при старте или ручной скрипт, если ещё не применён) | ✅ |
| 9.2.4 | Запуск backend: `java -jar femsq-web-0.1.0.X-SNAPSHOT.jar` → `/api/v1/connection/status` = 200 | ✅ `:8080` |
| 9.2.5 | Frontend: `npm run dev` (Fedora) **или** статика из JAR — согласовать сценарий UAT | ✅ `npm run dev` (Fedora) |
| 9.2.6 | Smoke CLI: `executeAudit` для `adt_key=14` (type=5, SUMMARY) и ревизии RALP (type=3) — COMPLETED | ✅ RALP exec **1158–1160**; type=5 apply — ⏳ |
| 9.2.7 | Зафиксировать версию JAR и `exec_key` в плане / журнале | ✅ JAR 0.1.0.122; UAT RALP exec **1162–1166** |
| 9.2.8 | **Parity thin vs fat JAR**: восстановить `/graphql` и `executeAudit` в thin-режиме до уровня fat JAR | ✅ 2026-07-16 JAR **0.1.0.136** |

##### 9.2.8. Восстановление thin JAR до уровня fat JAR (blocker G8)

**Факт (2026-07-16, JAR `0.1.0.135`):**
- fat JAR на `:8081` поднимает GraphQL полностью: в логе есть `Loaded 2 resource(s) in the GraphQL schema` и `GraphQL endpoint HTTP POST /graphql`;
- thin JAR на `:8080` стартует, БД/health работают, но `POST /graphql` даёт **404**, а в логе **нет** строк про загрузку GraphQL schema / HTTP endpoint;
- запрос `POST /graphql` в thin-режиме уходит в `ResourceHttpRequestHandler` как статический ресурс, поэтому `executeAudit`/UI ревизий недоступны;
- в thin JAR сохранён `BOOT-INF/classpath.idx` со ссылками на отсутствующие `BOOT-INF/lib/*.jar`;
- дополнительная проверка 2026-07-16 показала: удаление `classpath.idx`/`layers.idx` и запуск через `PropertiesLauncher` **не восстанавливают** `POST /graphql`, при этом `REST`/`/graphiql`/health продолжают работать;
- рабочая гипотеза после проверки: проблема не только в launcher/index, а в автопоиске GraphQL schema resources в thin-режиме;
- локальный фикс 2026-07-16: явная регистрация `graphql/ra-schema.graphqls` и `graphql/og-schema.graphqls` через `GraphQlSourceBuilderCustomizer` в `GraphQlConfig` восстановила thin parity на smoke `:8083` (`Loaded 2 resource(s) in the GraphQL schema`, `GraphQL endpoint HTTP POST /graphql`, `POST /graphql` = `200`).

| # | Пункт | Статус |
|---|-------|--------|
| 9.2.8.1 | Зафиксировать parity-check: fat `POST /graphql` = OK, thin `POST /graphql` = 404; приложить логи | ✅ 2026-07-16 |
| 9.2.8.2 | Проверить упаковку thin JAR: `classpath.idx`, `layers.idx`, `MANIFEST.MF`, способ запуска `JarLauncher` + внешний `lib/*` | ✅ 2026-07-16: удаление index/смена launcher не устраняет 404 |
| 9.2.8.3 | Исправить thin-сборку так, чтобы GraphQL schema и HTTP endpoint поднимались как в fat JAR | ✅ 2026-07-16: локально восстановлено через явную регистрацию schema-resources |
| 9.2.8.4 | Повторить G8 smoke после фикса: dry-run type=5 и type=3 через `executeAudit`/UI | ✅ 2026-07-16 thin **0.1.0.136**: type=5 **exec 1189** (105 с, stg=1720); type=3 **exec 1191** (20 с, stg=424, `af_source=1`) |
| 9.2.8.5 | Fallback: если thin не чинится быстро, выполнить soft-smoke на fat JAR и оставить thin parity отдельным blocker'ом | — не потребовался |

**Фикс (2026-07-16):** `GraphQlConfig.graphQlSchemaResourcesCustomizer()` — явная регистрация `graphql/*.graphqls` (обход ломающегося автосканирования schema resources в thin-режиме).

**Факт G8 smoke (thin JAR `0.1.0.136`, `adt_key=14`, март SMB, dry-run SUMMARY):**

| Прогон | exec | Статус | Длительность | staging |
|--------|------|--------|--------------|---------|
| type=5 (`af_key=312`) | **1189** | COMPLETED | 105 с | `ra_stg_ra` = 1720 |
| type=3 RALP (`af_key=314`, `af_source=1`) | **1191** | COMPLETED | 20 с | `ra_stg_ralp` = 424 |

*Замечание:* прогон **1190** (RALP без `af_source=1`) дал `COMPLETED` за 1 с с пустым staging — не считается валидным smoke.

---

### 9.3. Приёмочное тестирование через веб-интерфейс (оператор — Александр)

**Страница:** `AuditsView` — ревизии, файлы, запуск, просмотр `adt_results`.

#### 9.3.1. Отчёты агентов (`af_type=5`, AllAgents)

| # | Сценарий | Статус |
|---|----------|--------|
| 9.3.1.1 | Открыть ревизию с файлами type=5 (март / июль с SMB) | ⏳ |
| 9.3.1.2 | Проверить select **StagingLogLevel** (VERBOSE / SUMMARY / MINIMAL) — сохранение в БД | ⏳ |
| 9.3.1.3 | **Dry-run** (`adt_AddRA=false`): статус COMPLETED, лог SUMMARY (прогресс, warnings по parse) | ⏳ |
| 9.3.1.4 | Просмотр `adt_results` в UI: читаемость, нет «зависания» страницы на большом логе | ⏳ |
| 9.3.1.5 | **Apply** (на тестовой ревизии, если допустимо): домен не ломается, повторный прогон идемпотентен | ⏳ |

#### 9.3.2. Аренда земли (`af_type=3`, RALP)

**Уточнение перечней (2026-07-09):** файлы **разные** (MD5, размер). Мартовский — **меньший** набор; в БД ошибочно базой был июльский (1248). Исправлено trim → **420**.

| | **Март** `2026_03` | **Июль** `2026-07` |
|--|-------------------|-------------------|
| Документов в Excel (ключ num+date+cst+og) | **424** | **1262** |
| Staging valid (cst+og resolved) | **420** | **1248** |
| Только в файле | 0 | **+838** |
| В обоих | 424 | 424 |
| Разное состояние (arrived/sent/note/cost) в общих | — | **15** |
| По месяцам даты (Excel) | янв 177, фев 235, мар 12 | янв–июн (полный год) |

**Домен dev (после `trim-ralp-domain-to-march-baseline.sql`):** `ralpRa_2026=420`, `ralpRaAu_2026=420`. Источник перечня: staging exec_key=**1152** (мартовый dry-run).

**Smoke «март vs июль» (JAR 0.1.0.121):** exec 1152–1154 — на домене 1248 июль dry-run показал `unchanged=1248` (ожидаемо: домен уже был июльским). После trim возможен повторный apply июля → ожидается `raInserted≈828`.

**Скрипты:** `compare-ralp-excel-snapshots.py`, `trim-ralp-domain-to-march-baseline.sql`, `restore-ralp-march-baseline-from-staging.sql` (exec **1152**), `rollback-ralp-to-march-baseline.sh`, `smoke-ralp-march-vs-july.sh`.

**Apply июль (exec 1156, после trim 420→1248):** `raInserted=828`, `raAuInserted=828`, `raAuUpdated=**3**`, `unchanged=417`, `invalid=14`. В Excel 15 расхождений состояния в общих документах, но reconcile обновляет только поля `ralpRaAu` (cost/sent/returned/note/status) — **не** `arrived`; из 15 только 3 имели отличия в обновляемых полях.

| # | Сценарий | Статус |
|---|----------|--------|
| 9.3.2.1 | Сравнение перечней Excel март vs июль | ✅ 424 vs 1262 |
| 9.3.2.2 | База домена = мартовский перечень (420) | ✅ trim 2026-07-09 |
| 9.3.2.3 | Apply июля с базы 420 | ✅ exec **1156**: +828, `raAuUpdated=3`, домен **1248** |
| 9.3.2.4 | Откат к марту после apply | ✅ exec **1157**: `ralpRa=420`, `ralpRaAu=408`, `unchanged=408` |
| 9.3.2.5 | Smoke apply reconcile (JAR **0.1.0.122**, demote-siblings) | ✅ `RalpReconcileApplySmokeIT` на exec 1152/1156: apply → 1248/1248, `auDemoted*=0`, откат → 420/408 |
| 9.3.2.6 | **UAT UI** март dry-run | ✅ exec **1162**: 420/408 |
| 9.3.2.7 | **UAT UI** июль dry-run → apply → откат → идемпотентность март | ✅ exec **1163–1166**; apply ~3m29s; домен после UAT **420/408**, снимок **2026_03** |
| 9.3.2.8 | **UAT UI** читаемость лога `adt_results` | ❌ **blocker** — см. реестр **9.3.3**, задача **0049** |

#### 9.3.2.1. Политика цепочки рассмотрений (`ralpRaAu`) — отклонение от VBA orphan-delete

**Контекст (2026-07-10):** Excel — конечная истина текущей строки; пользователи не ведут историю рассмотрений вручную. Для освоения (_2408 / _2605 / _2606) по одному `ralpRa` допустим **не более одного** `sent` (принят), но **сколько угодно** `returned`.

**Семантика строки Excel** (при непустом `arrived`):

| `returned` | `sent` | Статус в `ags.ralp` / fn2 |
|------------|--------|---------------------------|
| пусто | заполнено | принят (`sended`) |
| заполнено | пусто | возвращён (`returned`) |
| пусто | пусто | на рассмотрении (`in process`) |

Классификация в SQL (fn2 / mastering): при обоих заполненных — `sentDate >= returnedDate` → `sended`, иначе `returned`. При демоции старого `sent` поля **`ralpraSent` / `ralpraSentDate` обнуляются**.

**Алгоритм reconcile (дополнение к VBA):**

1. Для каждой строки staging с непустым `arrived` — **demote siblings**: все `ralpRaAu` того же `ralpRa` с другим `arrived`:
   - уже `returned` без `sent` — не трогать;
   - `in process` или с `sent` — очистить `sent`, выставить синтетический `returned`.
2. Upsert текущего Au по ключу `(ralpRa, arrived из Excel)`.
3. **Orphan-delete Au** только если ключ не в `survivingRaAuKeys` (в т.ч. пустой `arrived` в Excel → все Au отчёта снимаются, как VBA).
4. **Orphan-delete `ralpRa`** — если отчёт исчез из Excel (без изменений).

**Синтетический `returned`:**

```text
closeDate = max(arrivedDate_старое, sentDate_старое?, arrivedDate_новое − 1 день)
текст: «автозакрытие от ДД.ММ.ГГГГ»
```

**Счётчики в логе apply:** `auDemotedSent`, `auClosedInProcess`, `auUnchangedReturned`.

**Реализация:** `RalpReconcileService.java` — метод `demoteSiblingAus`, изменение orphan-delete.

#### 9.3.2.2. Наличие сценариев в данных (сведение, 2026-07-10)

Проверка dev FishEye + staging exec **1152** (март) / **1156** (июль). **На логику политики не влияет** — зафиксировано для сведения.

| Сценарий | Март ↔ июль (420 общих) | БД (все годы) |
|----------|-------------------------|---------------|
| Смена непустого `arrived` на другой | **0** | 7 отчётов с 2+ Au (2020–2025), типичная цепочка returned → sent |
| Март in process → июль sent (тот же `arrived`) | **0** | 5 отчётов: returned + sent на разных Au |
| Март sent → июль другой `arrived` | **0** | **0** отчётов с 2+ `sent` |
| Март in process → июль in process, смена `arrived` | **0** | 2 отчёта 2025: in process + sent одновременно (аномалия данных) |
| Март без `arrived` → июль с `arrived` | **12** | первое назначение письма, не переписывание |
| Тот же `arrived`, смена cost/sent/returned | **3** | обычный update |
| 2026: 2+ Au на отчёт | — | **0** |

**Вывод:** переписывание строки с непустым `arrived` в паре март–июль **не встречается**; политика demote-siblings ориентирована на будущие правки Excel и исторические цепочки 2020–2025.

#### 9.3.3. Реестр замечаний UAT

**Контекст (2026-07-10):** функциональный UAT RALP (type=3) закрыт (exec **1162–1166**). Замечания **U1–U5** — **blocker** для эксплуатации лога оператором; устраняются в задаче **0049** (§9.3.4) **до** prod и повторного sign-off UAT.

| # | Замечание | Критичность | Статус | Задача / файл |
|---|-----------|-------------|--------|---------------|
| **U1** | Темы лога не согласованы с оболочкой приложения; нужны **глобальные** Kimbie Dark / VS Light | **blocker** | ✅ **0050** | `femsq.theme`, TopBar, §9.3.5; sign-off 2026-07-13 |
| **U2** | Межстрочный интервал в `adt_results` слишком большой (~в 3 раза больше нужного) | **blocker** | ✅ код | 0049 → `AuditExecutionContext.java` + frontend CSS |
| **U3** | Сообщение «пропущено — недостаточно обязательных данных» не информативно; нужны **конкретные поля** (первые + «и ещё N») | **blocker** | ✅ код | 0049 → `StagingRowSkipReasonFormatter`, `DefaultAuditStagingService` |
| **U4** | Строки Type5 match/apply на английском (`NEW`, `CHANGED`, `Type5 match — RA:…`) | **major** | ✅ код | 0049 → `AuditReconcileCoordinator.java`, `localizeMessageHtml()` |
| **U5** | Badge фазы **START** в логе — заменить на **`+`** | **minor** | ✅ код | 0049 → `AuditExecutionContext.java` |
| **U6** | Ошибка сохранения файла ревизии: `Cannot assign to read only property` | **blocker** | ✅ **sign-off 2026-07-14** | `files.ts` (`cloneFileDto`); правка флагов файла в UI ×2 |
| **U7** | В details reconcile RALP литералы `%d` вместо чисел | **major** | ✅ | `RalpReconcileService.java`; UI dry-run **exec 1167** — числа на месте |
| **U8** | Баннер «Директория не загружена» при заполненной таблице файлов | **minor** | ✅ 2026-07-16 | `DirectoryInfo.vue` compact: `v-else-if="!directory"` |
| **U9** | Apply RALP ~3–4 мин (perf, не читаемость) | **minor** | ⏳ отложено | §9.1.3 batch JDBC |
| **U10** | `некорректных = N` без причины и без номера Excel-строки (type=3/5) | **blocker** | ✅ **0051**+**0052**+**0053** sign-off 2026-07-15 | §9.3.6–9.3.8; ворота **G3**/**G4** |

**Решения оператора (2026-07-10):** для пропуска строк — **первые 3 обязательных поля + «и ещё N»**; badge фазы — **`+`**.

**Решения оператора (2026-07-14), задача 0051:** полный вариант — **DDL номера строки Excel** + построчные тексты аномалий **в духе Access** (`Form_ra_a.cls` / `RAAudit_ralp`), в т.ч. для **type=5**; пользователь видит **каждую** нештатную ситуацию с причиной и строкой исходного Excel.

**Решения оператора (2026-07-13), задача 0050:** глобальные темы **Kimbie Dark** (по умолчанию) и **VS Light**; переключатель — **иконка в TopBar**; акцент Kimbie — **тёплый** (`#d19a66`); первый demo — экран **Ревизии**, затем остальные модули.

---

#### 9.3.4. Доработка читаемости лога и UI ревизий (задача **0049**)

**Цель:** оператор может читать и понимать `adt_results` без внешних инструментов. **Блокирует** закрытие UAT (9.3.1.4, 9.3.2.8) и prod (9.5).

**Документация:** `docs/development/notes/audit-log/ra-execution-operations.md` → «Читаемость лога в UI».

##### 9.3.4.1. Темы лога (U1) — **перенесено в 0050**

| # | Пункт | Статус |
|---|-------|--------|
| 9.3.4.1.1 | Вынести CSS `.femsq-auditlog` из backend во frontend (`audit-log.css`) | ✅ |
| 9.3.4.1.2 | Палитры Kimbie / VS (прототип в `audit-log.css`) | ✅ прототип |
| 9.3.4.1.3 | Локальный селект в `AuditsView` + `femsq.auditLogTheme` | ✅ **устаревает** → глобальный `femsq.theme` (0050) |
| 9.3.4.1.4 | Согласование лога с оболочкой приложения | ✅ **0050** |

##### 9.3.4.2. Плотность строк (U2)

| # | Пункт | Статус |
|---|-------|--------|
| 9.3.4.2.1 | Уменьшить вертикальные отступы `.row` / `.summary` примерно в **3 раза** (`padding`, `line-height` ~1.1–1.2) | ✅ |
| 9.3.4.2.2 | Убрать лишние отступы у вложенных `details` без потери иерархии | ✅ |

##### 9.3.4.3. Причины пропуска строк Excel (U3)

| # | Пункт | Статус |
|---|-------|--------|
| 9.3.4.3.1 | В `bindRow()` собирать список пустых **обязательных** колонок (имя БД + заголовок Excel из `columnExcelHeaders`) | ✅ |
| 9.3.4.3.2 | В SUMMARY: первые **3** поля + «и ещё N» при N>3; различать «пустая строка», «нет бизнес-данных», «ошибка формата обязательного поля» | ✅ |
| 9.3.4.3.3 | Пример: `⚠ Excel-строка 2: пропущено — пусто обязательное поле: ralprtNum («№ отчёта»), ralprtDate («Дата») и ещё 1` | ✅ |
| 9.3.4.3.4 | Unit-тест на форматирование списка полей | ✅ |

##### 9.3.4.4. Русификация Type5 (U4)

| # | Пункт | Статус |
|---|-------|--------|
| 9.3.4.4.1 | `appendType5MatchStats` / `appendType5ApplyStats`: русские подписи (отчёты / изменения; новые, изменённые, без изменений, некорректные, неоднозначные) | ✅ |
| 9.3.4.4.2 | Дополнить `localizeMessageHtml()` для остаточных EN-фрагментов Type5 | ✅ |
| 9.3.4.4.3 | Обновить `Type5AcceptanceAdtResultsIntegrationIT` (ожидаемые подстроки) | ✅ |

##### 9.3.4.5. Badge фазы (U5)

| # | Пункт | Статус |
|---|-------|--------|
| 9.3.4.5.1 | `badge-start`: текст **`+`** вместо `START` (все коды `*_START`) | ✅ |

##### 9.3.4.6. Сопутствующие исправления (U6–U8)

| # | Пункт | Статус |
|---|-------|--------|
| 9.3.4.6.1 | Пересборка JAR **0.1.0.123+** с U6, U7, demote-siblings, 0049 backend-частью | ✅ JAR **0.1.0.123** |
| 9.3.4.6.2 | Frontend: деплой с `files.ts` fix (U6) | ✅ sign-off 2026-07-14 |
| 9.3.4.6.3 | Баннер директории (U8) — после 0049 или параллельно | ✅ 2026-07-16 |

**Критерий приёмки 0049:** оператор подтверждает **содержание** лога: плотность строк, пропуски Excel с именами полей, Type5 на русском, badge `+`. **Визуальное согласование тем** — задача **0050** (§9.3.5).

---

#### 9.3.5. Глобальные темы приложения Kimbie Dark / VS Light (задача **0050**)

**Цель:** единая палитра header, footer, карточек, форм, таблиц и лога `adt_results`. **Блокирует** закрытие **U1** и sign-off UAT перед prod (0048).

**Документация:** `docs/development/frontend-themes.md`.

**Решения оператора (2026-07-13):**

| # | Решение |
|---|---------|
| 1 | По умолчанию — **Kimbie Dark** |
| 2 | Переключатель — **иконка** в `TopBar` (`dark_mode` ↔ `light_mode`) |
| 3 | Акцент Kimbie — **тёплый** (`--femsq-primary: #d19a66`), не холодный синий |
| 4 | Порядок demo: **сначала «Ревизии»** (B.2), затем все остальные экраны (B.3) |

##### 9.3.5.1. Инфраструктура (фаза B.1)

| # | Пункт | Статус |
|---|-------|--------|
| 9.3.5.1.1 | `femsq-theme-tokens.css`: CSS-переменные `--femsq-*` для обеих тем | ✅ |
| 9.3.5.1.2 | `useFemsqTheme` / `stores/theme.ts`; ключ `localStorage` **`femsq.theme`** | ✅ |
| 9.3.5.1.3 | `main.ts`: Quasar Dark plugin; apply темы до `mount` (`data-femsq-theme` на `<html>`) | ✅ |
| 9.3.5.1.4 | `TopBar.vue`: иконка переключения темы | ✅ |
| 9.3.5.1.5 | `AppLayout.vue`, `StatusBar.vue`: убрать `bg-white text-dark`; токены вместо hardcode градиентов | ✅ |

##### 9.3.5.2. Ревизии — приоритет demo (фаза B.2)

| # | Пункт | Статус |
|---|-------|--------|
| 9.3.5.2.1 | `AuditsView.vue`: убрать локальный селект «Тема лога»; лог наследует глобальную тему | ✅ |
| 9.3.5.2.2 | `audit-log.css`: стили уровней лога через `--femsq-*` (без отдельных `.theme-*` на контейнере) | ✅ |
| 9.3.5.2.3 | `DirectoryInfo`, `FilesList`, `FileEditDialog` — контраст в обеих темах | ✅ |
| 9.3.5.2.4 | Sign-off оператора: экран ревизий × Kimbie Dark × VS Light | ✅ |

##### 9.3.5.3. Остальные экраны (фаза B.3)

| # | Пункт | Статус |
|---|-------|--------|
| 9.3.5.3.1 | Организации (`OrganizationsView`) | ✅ |
| 9.3.5.3.2 | Отчёты (`ReportsCatalog`, меню отчётов) | ✅ |
| 9.3.5.3.3 | Инвестиционные цепочки | ✅ |
| 9.3.5.3.4 | Test Grid, welcome-экран `App.vue` | ✅ |
| 9.3.5.3.5 | `ConnectionModal` | ✅ |

##### 9.3.5.4. Приёмка и остатки (фаза B.4)

| # | Пункт | Статус |
|---|-------|--------|
| 9.3.5.4.1 | UAT: все модули × 2 темы; таблицы Quasar, баннеры, модалки | ✅ sign-off 2026-07-13 |
| 9.3.5.4.2 | Миграция: при первом запуске читать `femsq.auditLogTheme` → `femsq.theme` (если есть) | ✅ |
| 9.3.5.4.3 | Inline `<font color>` в HTML лога — опционально → CSS-классы (не blocker) | ⏳ опционально |
| 9.3.5.4.4 | Закрытие **U1** в реестре 9.3.3 | ✅ |

**Критерий приёмки 0050:** один переключатель в TopBar; после F5 тема сохраняется; ревизии и лог визуально едины; остальные экраны без «белых островов» в Kimbie Dark.

**Оценка:** ~8–11 рабочих дней (1,5–2,5 недели).

---

#### 9.3.6. Трассировка Excel-строки и построчные аномалии (задача **0051**)

**Цель:** в режимах `SUMMARY`/`VERBOSE` оператор видит **каждую** нештатную ситуацию сверки/FK с **причиной** и **номером строки исходного Excel** (лист + 1-based), стилистика Access. **Блокирует** закрытие **U10** и prod-приёмку лога (§9.5.7).

**Документация:** `docs/development/notes/audit-log/ra-execution-operations.md` → «Трассировка Excel-строки и аномалии сверки»; VBA-ориентир — `Form_ra_a.cls` `RAAudit_ralp` (строки ~2706–2875).

##### Контекст и факты (2026-07-14, exec **1168**)

| Факт | Деталь |
|------|--------|
| Симптом | `подробности: … некорректных = 4` без перечня строк/причин |
| Критерий invalid type=3 | `ralprtCstAgPn IS NULL OR ralprtOgSender IS NULL OR ralprtDate IS NULL` (`RalpReconcileService`) |
| Причины 4 строк | стройка `026-3005711` нет в `cstAgPn` (2); отправитель «Газпром инвест»/«Газпром Ремонт» не сматчен (2); у одной из строк ещё сбой JOIN отправителя из‑за филиала = имени орг-ии |
| type=5 `rainRow` | колонка **уже есть** (`INT NULL`), но Stage 1 **не заполняет** → всегда `NULL` |
| type=3 | колонки номера Excel-строки **нет** → нужен DDL |
| Access | писал причину в **каждой** строке с № отчёта; **номер Excel-строки не писал** — в Java требуем **строже Access** |

##### Целевые форматы сообщений (SUMMARY)

```
⚠ Excel-строка 218, лист «Аренда_Земли»: отчёт «0126/310126» от 31.01.2026
  — стройка «026-3005711» в БД отсутствует
  — отправитель «Газпром добыча Оренбург» / филиал «…» в БД отсутствует, или их несколько
  → строка исключена из сверки (некорректная)
```

Type=5 (расширение топ-диагностики):

```
⚠ Excel-строка 4601, лист «Отчеты»: ОА «…» — стройка «002-…» не найдена → некорректная
```

##### Реестр ситуаций для лога (в т.ч. не сработавшие в марте)

| # | Ситуация | Источник Access / Java | Уровень |
|---|----------|------------------------|---------|
| A1 | Код стройки пуст / не `###-#######` | VBA «Стройка не найдена» | WARN |
| A2 | Стройка не в справочнике | VBA «Стройка в БД отсутствует» | WARN |
| A3 | Дата отчёта отсутствует | VBA «Дата отсутствует» | WARN |
| A4 | Отправитель/филиал 0 или несколько | VBA «Отправитель/Филиал … отсутствует, или их несколько» | WARN |
| A5 | Пустое «Поступило» (`arrived`) — сейчас тихий skip AU | VBA без FindRalpRaAu / Java `continue` | INFO/WARN |
| A6 | Orphan RA/AU при apply | VBA «Лишние отчёты в БД» | WARN (при apply) |
| A7 | Demote / закрытие sibling AU | Java demote-siblings | INFO (apply/dry-run сводка) |
| A8 | type=5: invalid / ambiguous / missing lookup | топ → **построчно** с `rainRow` | WARN |
| A9 | Stage 1 skip / parse | уже есть (0045/0049/P4) | — оставить |

##### План работ

| # | Пункт | Статус |
|---|-------|--------|
| **9.3.6.1** | **DDL:** `ags.ra_stg_ralp.ralprtRow INT NULL` (аналог `rainRow`); опц. `ra_stg_ralp_sm.ralprsRow`; пакет `docs/development/notes/sql/26-0714/` + `MSSQL2012/`; Liquibase changelog; `00_VERIFY`/`04_VERIFY`; применить на abs | ✅ 2026-07-14 abs FishEye |
| 9.3.6.2 | Stage 1: при INSERT заполнять `rainRow` / `ralprtRow` / `ralprsRow` (= Excel 1-based); synthetic-колонка вне `ra_col_map` (как `*_exec_key`) | ✅ 2026-07-14 |
| 9.3.6.3 | После Stage 2 type=3: `SUMMARY`-список неразрешённых FK (A1–A4) с `ralprtRow` + № отчёта + код/имя; итог Stage 2 в лог | ✅ 2026-07-14 |
| 9.3.6.4 | `RalpReconcileService`: не молчать на `invalid++`; сообщения по staging с `ralprtRow`; A5 (пустой arrived); A6/A7 при необходимости | ✅ 2026-07-14 |
| 9.3.6.5 | Type=5: построчные WARN для invalid/ambiguous/missing с `rainRow` (не только `RECONCILE_TYPE5_DIAGNOSTICS` топ-N) | ✅ 2026-07-14 |
| 9.3.6.6 | Unit/IT: formatter сообщений; smoke dry-run type=3 (март) — в логе ≥4 ⚠ с Excel-строкой и причиной; type=5 — выборка invalid с `rainRow` | ✅ 2026-07-14 JAR **0.1.0.126**; exec **1169** (type=3), **1170** (type=5) |
| 9.3.6.7 | Документация ops + mapping; sign-off **U10**; обновление ворот **G3**/G4 | ✅ 2026-07-15 (с §9.3.7–9.3.8) |

**Критерий приёмки 0051:** dry-run type=3 на марте: у каждой некорректной строки есть `⚠ Excel-строка N …` и читаемая причина; type=5: некорректные/неоднозначные тоже с номером строки; агрегат `некорректных = N` согласован с числом детальных WARN.

**Оценка:** ~3–5 рабочих дней (DDL → Stage 1 → Stage 2/reconcile → type=5 → приёмка).

**Выполнено:** **9.3.6.1–9.3.6.7** ✅; подсветка / scrollbar JAR **0.1.0.128**; детализация в дереве сверки (**0053**). Задача **0051** закрыта 2026-07-15 вместе с formal **G3**/**U10**.

**Факт smoke 9.3.6.6 (JAR 0.1.0.126, `adt_key=14`, март SMB, dry-run SUMMARY):**
- Unit: `RalpFkAnomalyFormatterTest` 6, `RalpReconcileAnomalyFormatterTest` 4, `Type5RowAnomalyFormatterTest` 4, `StagingExcelRowColumnsTest` 4 — OK.
- **type=3** exec **1169** (~28 с): `ralprtRow` 424/424; unresolved FK=4 (строки Excel 91/151/243/283) → 4×⚠ с причиной; `некорректных = 4`.
- **type=5** exec **1170** (~126 с): `rainRow` 1720/1720; `некорректные=71`; ≥130 построчных WARN с `Excel-строка N, лист «Отчеты»` (0 без номера).

---

#### 9.3.7. Stage 1 type=5: диапазон и классификация строк (задача **0052**)

**Цель:** корректный диапазон листа «Отчеты», честные счётчики в логе (без `UNKNOWN_SIGN` на пустых), явный агрегат по «ОА Аренда», обрезка пустого резерва под итогом.

**Документация:** `ra-execution-operations.md` → «Stage 1 type=5: диапазон листа и фильтры».

**Решение оператора (2026-07-14), проверка на шаре 2025 / 2026_03 / 2026-07:**

| Тема | Решение |
|------|---------|
| «ОА Аренда» | Отсекать **только по «Признак»**; regex по № **не нужен** |
| Пустые в диапазоне | Счётчик пустых; **не** маскировать как `UNKNOWN_SIGN` |
| Маркер № ОА | App-config regex `\d{7}` (не SQL LIKE `%_______-%`); для границы диапазона и OTHER |
| `rsc_row_pattern` | Пока не использовать в runtime (документировать как unused / later) |

##### План работ

| # | Пункт | Статус |
|---|-------|--------|
| 9.3.7.1 | Счётчики: empty vs filtered-by-sign; агрегат «ОА Аренда»; убрать пустые из UNKNOWN_SIGN | ✅ |
| 9.3.7.2 | Нижняя граница диапазона по последней «значимой» строке (+ `\d{7}` / whitelist / ОА Аренда) | ✅ |
| 9.3.7.3 | `audit.staging.type5.ra-num-regex` (default `\d{7}`); OTHER поштучно в SUMMARY (топ + хвост) | ✅ |
| 9.3.7.4 | Unit + smoke март/июль; время Stage 1 и текст «Найден диапазон» | ✅ |
| 9.3.7.5 | Ops/mapping + sign-off; связь с G4 | ✅ 2026-07-15 |

**Следующий пункт к выполнению:** **G8** soft-deploy (thin JAR).

**Выполнено 9.3.7.5:** sign-off formal по smoke **1175**/**1176** и повторным type=5 **1186**/**1188** (диапазон, ОА Аренда-агрегат, без UNKNOWN_SIGN на пустых). Задача **0052** закрыта; formal **G4**.

**Выполнено 9.3.7.1:** `Type5SignFilterClassifier` — пустые (нет признака и № ОА) → `skippedEmptyBeforeSign`, не `UNKNOWN_SIGN`; «ОА Аренда» → `filteredArendaBySign` + агрегат в SUMMARY; unit `Type5SignFilterClassifierTest`.

**Выполнено 9.3.7.2:** нижняя граница type=5 — `isSignificantForDataRange` (whitelist / «ОА Аренда» / `audit.staging.type5.ra-num-regex`); пустой резерв и хвост вроде `2132.0` — за пределами диапазона (`SHEET_FOUND`).

**Выполнено 9.3.7.3:** OTHER без маркера № — поштучный `STAGING_TYPE5_OTHER` (лимит 40) внутри диапазона + скан хвоста; счётчик `прочих без маркера №`; overflow INFO при превышении лимита.

**Факт smoke 9.3.7.4 (JAR 0.1.0.129, `adt_key=14`, type=5 only `af_key=312`, dry-run SUMMARY):**

| Прогон | exec | Диапазон | принято / аренда / OTHER | Stage 1 | полный |
|--------|------|----------|--------------------------|---------|--------|
| март `2026_03` | **1175** | `$D$2:$D$2133` | 1720 / 412 / 1 (стр. 19135 `SUBTOTAL…`) | **1m 5s** | **119 с** |
| июль `2026-07` | **1176** | `$D$2:$D$7438` | 5959 / 1478 / 1 (стр. 19232 `SUBTOTAL…`) | **4m 54s** | **360 с** |

`UNKNOWN_SIGN` в топе — нет; после smoke пути `ra_dir`/`af_name` возвращены на `2026_03`.

---

#### 9.3.8. Дерево сверки в логе: ОА / ОА прочие / изм. + группировка ошибок (задача **0053**)

**Цель:** после «Начало сверки» — иерархия с «+»/`−` как у Access по смыслу NEW/CHANGED, с обязательным разделением признаков и группировкой Excel-строк по корневым ошибкам (стройка / отправитель).

**Решение оператора (2026-07-15), факты БД и шары:**

| Факт | Деталь |
|------|--------|
| Excel-признаки | `ОА`, `ОА прочие`, `ОА изм` (отдельного «изм. к прочим» нет) |
| Домен | `ags.ra.ra_type`: `ОА` и `ОА, прочие` (`mapToDomainRaType`) |
| Изм. к «ОА прочие» | **Есть** в БД: `ra_change` ⋈ `ra` → **2** из ~3047 изменений (~0,07%); примеры `НСК20п-…`, `ГИП21-…` |
| Классификация изм. | по **`ra_type` базы** после resolve, не по Признак Excel |
| NEW ≠ ошибки | invalid/reject — соседняя ветка, не внутри «отсутствуют в БД» |

##### Целевое дерево type=5

```
▶ Начало сверки …
    Режим; Всего строк staging: T
  ▶ ОА
    ▶ Собственно ОА
        Всего / NEW / CHANGED / ошибки (стройка→rows, отправитель→rows, …) / (опц.) лишние
    ▶ Изменения к ОА          ← ОА изм, база ra_type=«ОА»
        Всего / NEW / CHANGED / ошибки / (опц.) лишние
  ▶ ОА прочие
    ▶ Собственно ОА прочие
        …
    ▶ Изменения к ОА прочие   ← ОА изм, база «ОА, прочие» (часто «Не найдены…»)
        …
  ▶ (редко) Изменения без определённой базы
  показатели match/apply
◀ Сверка
```

##### Type=3

Один ствол «Отчёты аренды» (без ОА/прочие/изм): Всего → NEW → CHANGED → ошибки (A1–A4 группировка) → (опц.) лишние. Дублировать Stage 2 WARN и дерево сверки не нужно — одна точка истины.

##### UI «+» / «−»

Badge `_START` был всегда «+». **Решено:** CSS `details[open] > summary .badge-start::before { content: "−" }` (frontend `audit-log.css` + STYLE_BLOCK HTML) — работает и для старых `adt_results` с литералом «+».

##### План работ

| # | Пункт | Статус |
|---|-------|--------|
| 9.3.8.0 | Документация дерева + UI toggle +/− | ✅ 2026-07-15 |
| 9.3.8.1 | Каркас nested spans type=5: ОА / ОА прочие / изм. (пусто при 0) | ✅ 2026-07-15 |
| 9.3.8.2 | NEW / CHANGED / «готово к внесению\|внесено» (SUMMARY лимит / VERBOSE полный) | ✅ 2026-07-15 |
| 9.3.8.3 | Ветка «ошибки»: группировка значение→Excel-строки; meta с primary reason | ✅ 2026-07-15 |
| 9.3.8.4 | Type=3: то же без RA/RC-развилки; опора на Stage 2 A1–A4 | ✅ 2026-07-15 |
| 9.3.8.5 | Smoke март/июль + sign-off; G4 | ✅ 2026-07-15 |

**Следующий пункт к выполнению:** **G8** soft-deploy (thin JAR).

**Выполнено 9.3.8.1:** `Type5ReconcileTreeLogger` + вызов из `AllAgentsReconcileService` после RC read-model. Ветки ОА / ОА прочие × (собственно | изм. к базе по `ra_type`); при 0 — «Не найдены…»; orphan RC без базы. Nested spans — `AuditLogScope.SHEET` (свёрнуты по умолчанию). Unit: `Type5ReconcileTreeLoggerTest` (2).

**Выполнено 9.3.8.2:** под NEW/CHANGED — span «готово к внесению» (dry-run) / «внесено» (apply) со списком строк Access-стиля; SUMMARY — топ **40** + «и ещё N»; VERBOSE — полный; MINIMAL — без списков. `Type5ReconcileTreeLineFormatter`; unit **6**.

**Выполнено 9.3.8.3:** под каждой конечной веткой — «Не участвуют в сверке / ошибки»: стройки / отправитель / неоднозначность / иные; группировка значение→Excel-строки; `primaryReason` в meta; приоритет стройка→отправитель→иное. `Type5ReconcileErrorGrouper`; unit **8**.

**Выполнено 9.3.8.4:** type=3 — один ствол «Отчёты аренды»: Всего → NEW (отчёты+рассмотрения) → CHANGED → **A5 пустое «Поступило»** (span) → ошибки A1–A4 → лишние. Построчные WARN Stage 2/A5 отключены. Deadlock на 2-м соединении исправлен (JAR **0.1.0.131+**). A5-span — JAR **0.1.0.132–133**.

**Выполнено 9.3.8.5 (smoke / sign-off, JAR **0.1.0.134**):** оператор — «замечаний нет». Июль type=5 **apply** не запускался (по выбору).

| Прогон | exec | Режим | Staging | Время | Примечание |
|--------|------|-------|---------|-------|------------|
| type=3 март dry | **1178–1180** | `AddRA=0` | ralp **424** | ~30 с | дерево A1–A4 |
| type=3 июль dry | **1181–1182** | `AddRA=0` | ralp **1262** | ~45–48 с | + A5-span |
| type=3 июль apply | **1183** | `AddRA=1` | ralp **1262** | **191 с** | «внесено»; откат → март baseline |
| type=5 март dry | **1186** | `AddRA=0` | ra **1720** | **131 с** | без плоских VALIDATION_FAIL в SUMMARY |
| type=5 март apply | **1187** | `AddRA=1` | ra **1720** | **130 с** | «внесено» 1578+16; откат |
| type=5 июль dry | **1188** | `AddRA=0` | ra **5959** | **340 с** | sign-off оператора |

---

### 9.4. Устранение замечаний по UAT

| # | Пункт | Статус |
|---|-------|--------|
| 9.4.1 | Приоритизация: **0049** → **0050** → U6 → **0051 (U10)** → **0052** → **0053** → major/minor | ✅ 2026-07-15 |
| 9.4.2 | Реализация **0049** backend/frontend (§9.3.4.2–9.3.4.5) | ✅ |
| 9.4.3 | Реализация **0050** (§9.3.5); demo ревизий после B.2 | ✅ |
| 9.4.4 | Пересборка и деплой на dev; просмотр лога exec **1162–1166** + UAT type=5 | ✅ dev JAR **0.1.0.124**; лог test_26/test_25 в VS Light — sign-off 2026-07-13 |
| 9.4.5 | Закрытие реестра **9.3.3** (blocker U1–U6; **U10** → 0051) | ✅ blocker U1–U7,U10; minor **U9** отложено |
| 9.4.6 | Реализация **0051** + **0052** + **0053** (§9.3.6–9.3.8); закрытие **U10**/G4 | ✅ 2026-07-15 |

---

### 9.4a. Ворота перед тестовым развёртыванием (чек-лист согласования)

**Назначение:** единое место для действий **до** soft-deploy (§9.2 повтор на thin JAR) и **до** prod (§9.5).  
При закрытии пункта здесь **одновременно** обновлять исходные строки (§9.3.1, §9.3.2.8, реестр **9.3.3**, §9.3.4.6, §9.4).

**Среда (2026-07-15):** fat JAR **0.1.0.134** `:8080`, frontend Vite `:5175`, БД FishEye `ags`. Soft-deploy thin — **G8**.

| # | Действие | Ссылки | Статус |
|---|----------|--------|--------|
| **G0** | Backend + frontend запущены на soft; `/api/v1/connection/status` = 200 | §9.2.4–9.2.5 | ✅ 2026-07-14 JAR **0.1.0.125** → актуальный **0.1.0.134** |
| **G1** | Sign-off **U6**: сохранить файл ревизии / файл в директории без `Cannot assign to read only property` | 9.3.3 U6; 9.3.4.6.2 | ✅ 2026-07-14: правка «Рассмотрение» / «Из Excel» ×2 без ошибок |
| **G2** | Sign-off **U7**: в логе **нового** прогона RALP нет литералов `%d` | 9.3.3 U7 | ✅ 2026-07-14: **exec 1167** dry-run type=3, details без `%d` |
| **G3** | **type=3** dry-run SUMMARY в UI → COMPLETED; лог читаем (темы/плотность); после **0051** — детализация invalid | 9.3.2.8; 9.4.4; **§9.3.6** | ✅ **formal** 2026-07-15 (**0051**+дерево **0053**; exec **1178+**) |
| **G4** | **type=5** UI: dry-run SUMMARY → COMPLETED; построчные аномалии с `rainRow`; честные счётчики/диапазон Stage 1 | 9.3.1.1–9.3.1.4; **§9.3.6.5**; **§9.3.7**; **§9.3.8** | ✅ **formal** 2026-07-15 (**0052** **1175/1176**; дерево **1186/1188**) |
| **G5** | **U8**: баннер «Директория не загружена» — исправить или явно отложить | 9.3.3 U8; 9.3.4.6.3 | ✅ 2026-07-16 |
| **G6** | Закрытие реестра blocker **U1–U6** (+ **U10** через 0051) | 9.4.5; 9.4.6 | ✅ 2026-07-15 (blocker закрыты; minor U8/U9 вне G6) |
| **G7** | (опц.) Apply type=5 на тестовой ревизии, если домен допускает | 9.3.1.5; 9.1.2.3 | ✅ 2026-07-15 exec **1187** (март apply + откат) |
| **G8** | Soft-deploy «как prod»: `build-thin-jar.sh`, запуск thin JAR + `lib/`, smoke type=3+5 | §9.2 повтор; **§9.2.8** | ✅ 2026-07-16 JAR **0.1.0.136**; exec **1189**/**1191** |

**Отложено (не блокирует G0–G8):** U9 / §9.1.3 (perf RALP batch); §9.3.5.4.3 (`<font color>`); §9.5 prod.

**UI polish (зафиксировано 2026-07-14, исправить в удобный момент — не блокер ворот):**

| # | Замечание | Где | Статус |
|---|-----------|-----|--------|
| **P1** | Высота **StatusBar** (строка подключения внизу): уменьшить до высоты самого высокого компонента + ~10% | `StatusBar.vue` / footer | ✅ 2026-07-14 |
| **P2** | Нижняя кромка карточки-«детали» ревизии — до уровня нижней кромки списка ревизий (+ «Создать новую») | `AuditsView.vue` layout | ✅ 2026-07-14 |
| **P3** | Выпадающее меню TopBar открывается само и «висит»; появление — только по понятному действию пользователя | `TopBar.vue` (`QMenu` / `menu`) | ✅ 2026-07-14 |
| **P4** | SUMMARY: тысячи ⚠ на пустом хвосте Excel — **диапазон + пакет пустых** | `DefaultAuditStagingService` + formatter | ✅ код в JAR **0.1.0.125**; soft OK оператор 2026-07-14 |
| **P5** | Построчные аномалии сверки / FK с Excel-строкой (type=3+5) | задача **0051**, §9.3.6 | ✅ 2026-07-15 |
| **P6** | AddRA / детализация лога: чекбокс без «Сохранить» не влиял на прогон | `AuditsView.vue` | ✅ 2026-07-16 sync перед `executeAudit` |

**Правило ведения:** оператор сообщает результат шага → ассистент ставит ✅ здесь **и** в исходных таблицах.

---

### 9.5. Развёртывание в продуктиве (минимальный перенос файлов, thin JAR)

**Принцип:** на рабочей станции / сервере приложения FEMSQ каталог `lib/` (**~50 МБ**, Spring, POI, Jasper и т.д.) уже извлечён из первого fat JAR. На prod переносим **только изменившееся приложение** — thin JAR и при смене версии — обновлённые `femsq-database-*.jar` / `femsq-reports-*.jar` в `lib/`.

**Документация:** `docs/deployment/thin-jar-quick-start.md`, `docs/deployment/jar-lifecycle.md`, `docs/deployment/sql-server-deployment-rules.md`.

| # | Пункт | Статус |
|---|-------|--------|
| 9.5.1 | **Pre-flight prod:** бэкап БД FishEye; проверка `lib/` и версий (`LibraryCompatibilityChecker` / `lib-manifest.json`) | ⏳ |
| 9.5.2 | **SQL на prod (2012):** DDL `adt_staging_log_level`; DDL **`ralprtRow`** (и связанные) из `docs/development/notes/sql/26-0714/MSSQL2012/` (без `CREATE OR ALTER`); прогон `00_VERIFY` → `04_VERIFY` | ⏳ |
| 9.5.3 | Сборка: `./code/scripts/build-thin-jar.sh` → `femsq-web-X-SNAPSHOT-thin.jar` (~700 КБ) | ⏳ |
| 9.5.4 | **Перенос на prod:** thin JAR (+ только изменённые `femsq-*.jar` в `lib/`, если версия модулей сменилась); **не** копировать весь `lib/` повторно | ⏳ |
| 9.5.5 | Остановка старого процесса; запуск thin JAR (`java -cp "femsq-web-*-thin.jar;lib/*" org.springframework.boot.loader.launch.JarLauncher` или скрипт prod) | ⏳ |
| 9.5.6 | Проверка логов: нет ошибок `LibraryCompatibilityChecker`; `/api/v1/connection/status` = 200 | ⏳ |
| 9.5.7 | **Приёмка prod:** один dry-run ревизии type=5 (SUMMARY) и type=3 под контролем оператора; откат thin JAR при сбое | ⏳ |
| 9.5.8 | Оформить `docs/deployment/db-upgrade-{дата}.md` и запись в журнале | ⏳ |

**Критерий завершения фазы 9:** perf 0046–0047 выполнены или отложены; **0049–0053** закрыты; UAT blocker в 9.3.3 закрыты (minor U8/U9); soft-deploy **G8**; prod thin JAR **0048**/§9.5.

**Задачи в `project-development.json`:** 0046, 0047, **0049**, **0050**, **0051**, **0052**, **0053**, 0048.

---

## Блокирующие вопросы (требуют ответа перед Фазой 2)

| # | Вопрос | Статус | Источник уточнения |
|---|--------|--------|---------------------|
| В1 | Откуда берётся `ralpraArrivedDate`? | ✅ ЗАКРЫТ | `ParseDate(strArrived_)` — строки 3446–3450 `Form_ra_a.cls` |
| В2 | Домен для `учет_аренды` не нужен в текущей итерации? | ✅ ЗАКРЫТ | Подтверждено: только Stage 1/2, без reconcile |
| В3 | Нужен ли DELETE «лишних» `ralpRa`/`ralpRaAu` при reconcile? | ✅ ЗАКРЫТ | DELETE обязателен — `ralpRaAuTestQuRa`, `ralpRaAuTestQuAu` |

---

## Доп. факты (актуализировано 2026-07-14)

- **Фаза 9 (v0.12.15):** 0049–**0053** + **U8/G5** закрыты; ворота **G0–G7** ✅; далее **G8** thin JAR → prod **0048**/§9.5.

- **0051 (2026-07-15):** §9.3.6 **закрыта**; U10/P5/G3 formal.

- **0052 (2026-07-15):** §9.3.7 **закрыта**; диапазон/фильтр Stage 1; G4 formal (smoke **1175/1176**, повтор **1186/1188**).

- **0053 (2026-07-15):** §9.3.8 **закрыта**; smoke март/июль (type=3+5) + sign-off; JAR **0.1.0.134**; exec **1186**/**1188** (type=5), **1183** (type=3 apply + откат).

- **0050 (2026-07-13):** **закрыта** — глобальные темы Kimbie Dark / VS Light; иконка TopBar; `femsq.theme`; фазы B.1–B.4; U1 ✅; unit-тест `femsq-theme.spec.ts`. Док: `frontend-themes.md`.

- **0049 (2026-07-13):** **закрыта** — содержание и плотность лога; JAR **0.1.0.124**; U2–U5 ✅; U1 → 0050.

- **UAT RALP UI (2026-07-10):** exec **1162–1166**; домен **420/408**, снимок **2026_03**.

- **База RALP dev (2026-07-09):** март **420** / июль **1248** valid; staging март exec **1152**.

- **Smoke SUMMARY SMB (2026-07-09):** март: 1140 ~183 с → 1144 **180 с** (118) → 1145 **155 с** (119, 0046) → 1146 **150 с** (120, 0047 dry-run); июль 1143 **363 с**.

- Объём `ags.ralpRa`: **~12 386 строк** (2020–2026), `ags.ralpRaAu`: **~12 379 строк**.
- **`ralpRa` за 2026 год: 1248 записей** (после apply, exec_key=1133).
- Staging `ags.ra_stg_ralp`: заполняется при каждом прогоне (~1262 строки на exec_key).
- Таблицы с маской `*ralp*` в схеме `ags`: `ra_stg_ralp`, `ra_stg_ralp_sm`, `ralp`, `ralpGr`, `ralpOld`, `ralpRa`, `ralpRaAu`.
- Доменной таблицы для сводного листа `учет_аренды` нет — только `ags.ra_stg_ralp_sm`.
- `ralprtArrived` в `ra_col_map` подтверждён (rcm_key=130, ординал=12).
- Пакет `com.femsq.web.audit.excel` (4 файла) — **в git** после исправления `.gitignore` (п. 0.5).
- **Invalid exec 1168:** 4 строки (номера `0126/310126`, `137/310126`, `396/280226`, `0226/280226`) — FK стройка/отправитель; без Excel-row в staging.

---

- **Ворота 9.4a (2026-07-16):** **G0–G8** ✅; thin parity восстановлен (§9.2.8, JAR **0.1.0.136**).

**Последнее обновление:** 2026-07-16  
**Версия:** 0.12.17
