# План работы: Реализация обработки Excel-файлов в ревизии (AllAgents, инфраструктура POI)

**Дата создания:** 2026-03-19
**Проект:** FEMSQ — реализация `AllAgentsAuditFileProcessor` и общей Excel-инфраструктуры
**Версия плана:** 0.2.0
**Цель:** Реализовать первый реальный процессор файла ревизии (`af_type=5`, лист "Отчеты"), включая общую Excel-инфраструктуру (Apache POI), таблицу `ra_ImpNew` и `ra_execution` на SQL Server, и логику сверки с `ags_ra`/`ags_ra_change`.

---

## Ссылки

- **Анализ VBA/архитектуры:** `docs/development/notes/analysis/ra-audit-btnAuditRun-analysis.md`
- **VBA-исходник AllAgents:** `docs/project/proposals/vba-analysis/VBA-Code-Export/Class-Modules/ra_aAllAgents.cls`
- **VBA-исходник формы:** `docs/project/proposals/vba-analysis/VBA-Code-Export/Form-Modules/Form_ra_a.cls`
- **Предыдущий план (GraphQL-миграция):** `docs/development/notes/chats/chat-plan/chat-plan-26-0317-graphql-migration.md`

---

## Архитектурные решения (зафиксированы)

| Вопрос | Решение |
|--------|---------|
| `ra_ImpNew` — in-memory или SQL Server? | **SQL Server таблица** (данные из Excel ценны сами по себе, 10-20K записей, требуют ручной проверки) |
| Изоляция конкурентных запусков `ra_ImpNew` | **Таблица `ra_execution`** как уникальный сеанс-изолятор (`rain_exec_key FK → ra_execution.exec_key`) |
| Статус выполнения ревизии | **`ra_execution`** заменяет in-memory `AuditExecutionRegistry` (статус переживает рестарт) |
| `@Async` для `executeAudit` | **Да, в Фазе 0** (обязательно: обработка занимает минуты, синхронный режим неприемлем) |

---

## Предусловия (должны быть выполнены до начала реализации)

| Элемент | Статус | Примечание |
|---------|--------|-----------|
| SQL-определение `ra_ImpNewQuRa` получено из Access VM | ⬜ | `Debug.Print CurrentDb.QueryDefs("ra_ImpNewQuRa").SQL` |
| SQL-определение `ra_ImpNewQuRc` получено из Access VM | ⬜ | `Debug.Print CurrentDb.QueryDefs("ra_ImpNewQuRc").SQL` |
| Значения `af_type` в реальной БД проверены | ⬜ | `SELECT DISTINCT af_type, COUNT(*) FROM ags.ra_f GROUP BY af_type` |

---

## Фаза 0: Подготовительные правки

**Цель:** Устранить известные пропуски, добавить зависимость POI, сделать `executeAudit` асинхронным.

### 0.1. Добавить Apache POI в `femsq-web/pom.xml`
- `org.apache.poi:poi-ooxml` (актуальная версия)
- Проверить: `mvn dependency:tree` — нет конфликтов

### 0.2. Добавить `@Async` / `@EnableAsync` для `executeAudit`
- Добавить `@EnableAsync` на конфигурационный класс или `FemsqWebApplication`
- Добавить `@Async` на `AuditExecutionServiceImpl.executeAudit`
- Проверить: GraphQL mutation `executeAudit` возвращает ответ немедленно, не дожидаясь завершения

### 0.3. Исправить `AuditExecutionServiceImpl`: заполнять `directoryPath`
- Загружать `RaDir` по `audit.adtDir`
- Устанавливать `ctx.setDirectoryPath(raDir.dir())`

### 0.4. Исправить логику определения полного пути файла
- Типы 2, 3, 5, 6 → `af_name` содержит абсолютный путь, использовать как есть
- Типы 1, 4 → `directoryPath + File.separator + af_name`
- Добавить метод `resolveFilePath(AuditFile file, String directoryPath)` в `AuditExecutionServiceImpl`

### 0.5. Поднять версию проекта
- `0.1.0.90-SNAPSHOT` → `0.1.0.91-SNAPSHOT`

---

## Фаза 1: Таблицы `ra_execution` и `ra_ImpNew` на SQL Server (Liquibase)

**Цель:** Создать постоянное хранилище для сеансов выполнения и промежуточных данных из Excel.

### 1.1. Liquibase-миграция: таблица `ra_execution`

```sql
CREATE TABLE ags.ra_execution (
    exec_key         BIGINT IDENTITY(1,1) PRIMARY KEY,
    adt_key          INT NOT NULL,
    exec_started_at  DATETIME2 NOT NULL DEFAULT GETDATE(),
    exec_finished_at DATETIME2 NULL,
    exec_status      VARCHAR(20) NOT NULL DEFAULT 'RUNNING',  -- RUNNING / COMPLETED / FAILED
    exec_error       NVARCHAR(MAX) NULL
);
```

### 1.2. Liquibase-миграция: таблица `ra_ImpNew`

26 полей (полная структура в `ra-audit-btnAuditRun-analysis.md` §10.2) плюс изолятор сеанса:

```sql
CREATE TABLE ags.ra_ImpNew (
    rain_key             BIGINT IDENTITY(1,1) PRIMARY KEY,
    rain_exec_key        BIGINT NOT NULL,         -- FK → ra_execution.exec_key (изолятор сеанса)
    rainRow              INT NOT NULL,
    rainRaNum            NVARCHAR(100) NULL,
    rainRaDate           DATE NULL,
    rainSign             NVARCHAR(50) NULL,
    rainCstAgPnStr       NVARCHAR(100) NULL,
    rainCstName          NVARCHAR(500) NULL,
    rainSender           NVARCHAR(500) NULL,
    rainTtl              DECIMAL(18,2) NULL,
    rainWork             DECIMAL(18,2) NULL,
    rainEquip            DECIMAL(18,2) NULL,
    rainOthers           DECIMAL(18,2) NULL,
    rainArrivedNum       NVARCHAR(100) NULL,
    rainArrivedDate      DATE NULL,
    rainArrivedDateFact  DATE NULL,
    rainReturnedNum      NVARCHAR(100) NULL,
    rainReturnedDate     DATE NULL,
    rainReturnedReason   NVARCHAR(500) NULL,
    rainSendNum          NVARCHAR(100) NULL,
    rainSendDate         DATE NULL,
    rainUnit             NVARCHAR(200) NULL,
    rainRaSheetsNumber   INT NULL,
    rainTitleDocSheetsNumber INT NULL,
    rainPlanNumber       INT NULL,
    rainPlanDate         DATE NULL,
    rainRaSignOfTest     NVARCHAR(100) NULL,
    rainRaSendedSum      DECIMAL(18,2) NULL,
    rainRaReturnedSum    DECIMAL(18,2) NULL
);
```

### 1.3. Обновить `AuditExecutionRegistry` → `RaExecutionDao`
- Удалить или переработать in-memory `AuditExecutionRegistry`
- Создать `RaExecutionDao`: `createExecution(adtKey)` → `execKey`, `markCompleted(execKey)`, `markFailed(execKey, error)`, `findLastByAuditId(adtKey)`
- `RaAMapper`: `adtStatus` вычислять через `RaExecutionDao.findLastByAuditId(adtKey)`

---

## Фаза 2: Общая Excel-инфраструктура (пакет `audit.excel`)

**Цель:** Создать переиспользуемые компоненты для работы с Excel через Apache POI.

### 2.1. Создать `AuditExcelException`
- Runtime-исключение для ошибок при чтении Excel
- Поля: `message`, `cause`, `filePath`, `sheetName`

### 2.2. Создать `AuditExcelReader` (helper: `withWorkbook`)
```java
public class AuditExcelReader {
    public static <T> T withWorkbook(String path, ExcelWorkbookAction<T> action) {
        try (Workbook wb = WorkbookFactory.create(new File(path), null, true)) {
            return action.execute(wb);
        } catch (IOException e) {
            throw new AuditExcelException("Не удалось открыть файл: " + path, e, path, null);
        }
    }
}
```

### 2.3. Создать `AuditExcelColumnLocator` (поиск колонок по заголовкам)
- `findHeaderRow(Sheet sheet, String anchorHeaderText)` → `Row` (строка заголовков)
- `findAnchorColumn(Row headerRow, String headerText)` → номер колонки
- `buildColumnMap(Row headerRow, List<String> headers)` → `Map<String, Integer>`
- Аналог VBA `CellFind()`: точное совпадение, поддержка `vbLf` → `\n`

### 2.4. Создать `AuditExcelCellReader` (типизированное чтение ячеек)
- `getString(Row row, int colIdx)` → `String`
- `getStringOrNull(Row row, int colIdx)` → `String`
- `getLocalDate(Row row, int colIdx)` → `LocalDate`
- `getBigDecimalOrNull(Row row, int colIdx)` → `BigDecimal` (аналог `NumericOrNull`)
- `getIntOrNull(Row row, int colIdx)` → `Integer`
- Поддержка типов ячеек: STRING, NUMERIC, FORMULA, BLANK

---

## Фаза 3: `AllAgentsExcelReader` и запись в `ra_ImpNew`

**Цель:** Прочитать данные из Excel и записать в `ra_ImpNew` с привязкой к `exec_key`.

### 3.1. Создать `RaImpNewDao`
- `deleteByExecKey(long execKey)` — очистка перед загрузкой
- `insertBatch(long execKey, List<RaImpNewRow> rows)` — пакетная вставка

### 3.2. Создать `AllAgentsExcelReader`
- Принимает `Workbook`, возвращает `List<RaImpNewRow>`
- Находит лист "Отчеты"
- Локализует якорную колонку "№ ОА" через `AuditExcelColumnLocator`
- Строит `Map<String, Integer>` для всех 26 колонок
- Итерирует строки, находя строки с отчётами (паттерн `*???????-*` в колонке `rainRaNum`)
- Создаёт `RaImpNewRow` для каждой строки через `AuditExcelCellReader`

### 3.3. Интегрировать в `AllAgentsAuditFileProcessor.process()`
- Если `afSource = true`:
  1. `raImpNewDao.deleteByExecKey(ctx.execKey)`
  2. `rows = allAgentsExcelReader.read(workbook)`
  3. `raImpNewDao.insertBatch(ctx.execKey, rows)`
  4. Лог: "Загружено N записей из Excel в ra_ImpNew"

---

## Фаза 4: DAO сверки с `ags_ra` и `ags_ra_change`

> ⚠️ **Предусловие:** SQL-определения `ra_ImpNewQuRa` и `ra_ImpNewQuRc` должны быть получены из Access VM и зафиксированы в `ra-audit-btnAuditRun-analysis.md` §10.9.

### 4.1. Изучить SQL `ra_ImpNewQuRa` и `ra_ImpNewQuRc`
- Получить из Access VM
- Зафиксировать в `ra-audit-btnAuditRun-analysis.md` §10.9
- Определить логику lookup: `rainCstAgPnStr` → `cstapKey`, `rainSender` → `ogKey`, `rainRaDate` → `periodKey`

### 4.2. Перенести запросы как SQL Server VIEW (или нативный SQL в DAO)
- `CREATE VIEW ags.v_ra_ImpNewQuRa AS ...` — аналог Access-запроса `ra_ImpNewQuRa`
- `CREATE VIEW ags.v_ra_ImpNewQuRc AS ...` — аналог `ra_ImpNewQuRc`
- Liquibase-миграция

### 4.3. Создать `RaComparisonDao`
- `findAllByExecKey(long execKey)` — весь результат `v_ra_ImpNewQuRa`
- `findMissingRa(long execKey)` — `WHERE ra_key IS NULL`
- `findMismatchedRa(long execKey)` — `WHERE ra_key IS NOT NULL AND rs = 0`
- `findExtraRa(long execKey, int auditYear)` — записи в БД, которых нет в Excel

### 4.4. Создать `RcComparisonDao`
- Аналогично для `v_ra_ImpNewQuRc` и `ags_ra_change`

---

## Фаза 5: `AllAgentsAuditFileProcessor` — логика сверки

**Цель:** Реализовать 8 операций сверки (A1-A4, B1-B4) из `ra_aAllAgents.Audit()`.

### 5.1. Реализовать блок A (основные отчёты `ags_ra`)

| Операция | Метод | Действие при `addRa=true` |
|----------|-------|--------------------------|
| A1: подсчёт | `logTotalRaCount` | только лог |
| A2: новые в Excel | `createMissingRa` | `INSERT INTO ags_ra` + `INSERT INTO ags_ra_sm` |
| A3: расхождения | `updateMismatchedRa` | `UPDATE ags_ra` по флагам `rsXxx` |
| A4: удалены из Excel | `deleteExtraRa` | `DELETE FROM ags_ra` |

### 5.2. Реализовать блок B (изменения `ags_ra_change`)

| Операция | Метод | Действие при `addRa=true` |
|----------|-------|--------------------------|
| B1: подсчёт | `logTotalRcCount` | только лог |
| B2: новые в Excel | `createMissingRc` | `INSERT INTO ags_ra_change` + `ags_ra_change_sm` |
| B3: расхождения | `updateMismatchedRc` | `UPDATE ags_ra_change` по флагам |
| B4: удалены из Excel | `deleteExtraRc` | `DELETE FROM ags_ra_change` |

### 5.3. Интеграция в `AuditExecutionServiceImpl`
- Инжектировать `AllAgentsAuditFileProcessor`
- В `switch` по `af_type=5`: вызвать `allAgentsProcessor.process(ctx, file)`

---

## Фаза 6: Сборка и ручная проверка

### 6.1. Сборка
- `npm run type-check`
- `mvn ... package` (fat JAR `0.1.0.91-SNAPSHOT`)

### 6.2. Ручная проверка
- Запустить JAR
- Выбрать ревизию с `af_type=5`
- Запустить ревизию — убедиться, что страница не зависает (`@Async` работает)
- Проверить `ra_ImpNew` через DBHub: данные загружены с правильным `rain_exec_key`
- При `af_source=false`: лог показывает счётчики A1, B1
- При `af_source=true`, `addRa=false`: лог показывает расхождения без изменений в БД
- При `af_source=true`, `addRa=true`: новые записи появляются в `ags_ra`

### 6.3. Обновление документации
- Обновить `ra-audit-btnAuditRun-analysis.md` (раздел 11: итоги реализации)
- Обновить `project-docs.json`, `project-development.json`, `project-journal.json`
- Создать `chat-resume-26-0319-excel-processing.md`

---

## Что остаётся за рамками этого плана

| Компонент | Примечание |
|-----------|-----------|
| `RalpAuditFileProcessor` (`af_type=3`) | Аренда земли: `RAAudit_ralp` + `RAAudit_ralpSum` |
| `CnPrDocAuditFileProcessor` (`af_type=2`) | ХрСтрКнтрл: `RAAudit_cn_PrDoc` |
| `RepPeriodAuditFileProcessor` (`af_type=1,4`) | РАСЧЁТ + AgFee: сложный, через `ra_ft_s`/`ra_ft_sn` |
| `AgFee2306AuditFileProcessor` (`af_type=6`) | Агентское вознаграждение 23-0628 |
| `ra_aTtl` (итоговые суммы ревизии) | Очистка и заполнение таблицы итогов |

---

**Последнее обновление:** 2026-03-19
**Версия:** 0.2.0
