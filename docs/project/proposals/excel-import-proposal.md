# Предложение: Функциональность импорта данных из Excel

**Дата:** 2025-12-19  
**Автор:** Александр  
**Статус:** Предложение  
**Версия:** 1.0.0

## Цель

Добавить в проект FEMSQ функциональность для чтения данных из файлов Excel и переноса их в таблицы MS SQL Server.

## Требования

1. **Чтение Excel файлов:**
   - Поддержка форматов `.xlsx` (Excel 2007+)
   - Поддержка формата `.xls` (Excel 97-2003) - опционально
   - Чтение данных с указанного листа
   - Обработка заголовков строк
   - Пропуск пустых строк

2. **Маппинг данных:**
   - Маппинг колонок Excel на колонки таблицы БД
   - Валидация данных перед вставкой
   - Преобразование типов данных (String → Integer, Date, и т.д.)
   - Обработка ошибок валидации

3. **Вставка в БД:**
   - Batch вставка для производительности
   - Транзакционная обработка (rollback при ошибках)
   - Поддержка режимов: INSERT, UPDATE, UPSERT
   - Логирование процесса импорта

4. **API:**
   - REST endpoint для загрузки файла
   - Возможность указать целевую таблицу и схему
   - Возврат отчета об импорте (успешно/ошибки)

## Архитектурное решение

### Вариант 1: Новый модуль `femsq-import` (Рекомендуется)

**Преимущества:**
- Четкое разделение ответственности
- Возможность расширения для других форматов (CSV, JSON)
- Независимое тестирование
- Переиспользование в других проектах

**Структура модуля:**
```
femsq-import/
├── src/main/java/com/femsq/import/
│   ├── excel/
│   │   ├── ExcelReader.java              # Основной класс для чтения Excel
│   │   ├── ExcelRowMapper.java           # Маппинг строк Excel на объекты
│   │   ├── ExcelValidationService.java   # Валидация данных
│   │   └── ExcelImportException.java     # Специфичные исключения
│   ├── database/
│   │   ├── BatchInsertService.java       # Batch вставка в БД
│   │   └── ImportDao.java               # DAO для импорта
│   ├── api/
│   │   ├── ImportController.java         # REST контроллер
│   │   ├── ImportRequest.java            # DTO для запроса
│   │   └── ImportResponse.java           # DTO для ответа
│   └── config/
│       └── ImportConfiguration.java      # Конфигурация модуля
```

### Вариант 2: Расширение модуля `femsq-web`

**Преимущества:**
- Быстрее реализовать
- Меньше модулей

**Недостатки:**
- Смешивание ответственности
- Сложнее тестировать
- Менее масштабируемо

## Выбор библиотеки для работы с Excel

### Apache POI (Рекомендуется)

**Преимущества:**
- Стандарт де-факто для работы с Excel в Java
- Поддержка `.xlsx` и `.xls`
- Активная разработка и поддержка
- Хорошая документация
- Широкое использование в enterprise

**Недостатки:**
- Большой размер (~15-20 MB)
- Высокое потребление памяти для больших файлов

**Зависимость:**
```xml
<dependency>
    <groupId>org.apache.poi</groupId>
    <artifactId>poi-ooxml</artifactId>
    <version>5.2.5</version>
</dependency>
```

### EasyExcel (Альтернатива)

**Преимущества:**
- Низкое потребление памяти (streaming)
- Быстрая обработка больших файлов
- Простой API

**Недостатки:**
- Меньше функций
- Меньше примеров в интернете
- Только `.xlsx`

**Зависимость:**
```xml
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>easyexcel</artifactId>
    <version>3.3.2</version>
</dependency>
```

### Рекомендация

**Использовать Apache POI** по следующим причинам:
1. Проект уже использует тяжелые библиотеки (JasperReports ~15 MB)
2. Стандарт в Java экосистеме
3. Лучшая поддержка различных форматов Excel
4. Больше примеров и документации

Для больших файлов (>100K строк) можно добавить streaming режим с использованием `SXSSFWorkbook` или перейти на EasyExcel.

## Детальная архитектура (Вариант 1)

### 1. Модуль `femsq-import`

#### Зависимости
```xml
<dependencies>
    <!-- Apache POI для работы с Excel -->
    <dependency>
        <groupId>org.apache.poi</groupId>
        <artifactId>poi-ooxml</artifactId>
        <version>5.2.5</version>
    </dependency>
    
    <!-- Зависимость на femsq-database для ConnectionFactory -->
    <dependency>
        <groupId>com.femsq</groupId>
        <artifactId>femsq-database</artifactId>
        <version>${project.version}</version>
    </dependency>
    
    <!-- Spring для REST API -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    
    <!-- Валидация -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
</dependencies>
```

### 2. Основные компоненты

#### ExcelReader.java
```java
package com.femsq.import.excel;

import org.apache.poi.ss.usermodel.*;
import java.io.InputStream;
import java.util.List;
import java.util.function.Function;

/**
 * Сервис для чтения данных из Excel файлов.
 */
public class ExcelReader {
    
    /**
     * Читает данные с указанного листа Excel файла.
     * 
     * @param inputStream поток данных Excel файла
     * @param sheetName имя листа (null для первого листа)
     * @param headerRow номер строки с заголовками (0-based, обычно 0)
     * @param dataStartRow номер строки начала данных (0-based, обычно 1)
     * @param mapper функция маппинга строки Excel на объект
     * @return список объектов
     */
    public <T> List<T> readSheet(
            InputStream inputStream,
            String sheetName,
            int headerRow,
            int dataStartRow,
            Function<Row, T> mapper) throws ExcelImportException;
    
    /**
     * Получает список имен листов в файле.
     */
    public List<String> getSheetNames(InputStream inputStream) throws ExcelImportException;
}
```

#### ExcelRowMapper.java
```java
package com.femsq.import.excel;

import org.apache.poi.ss.usermodel.Row;
import java.util.Map;

/**
 * Маппер для преобразования строк Excel в объекты.
 */
public interface ExcelRowMapper<T> {
    
    /**
     * Маппит строку Excel на объект.
     * 
     * @param row строка Excel
     * @param columnMapping маппинг: имя колонки Excel -> имя поля объекта
     * @return объект или null если строка должна быть пропущена
     */
    T mapRow(Row row, Map<String, Integer> columnMapping) throws ExcelMappingException;
}
```

#### BatchInsertService.java
```java
package com.femsq.import.database;

import java.sql.Connection;
import java.util.List;

/**
 * Сервис для batch вставки данных в БД.
 */
public class BatchInsertService {
    
    /**
     * Выполняет batch вставку данных.
     * 
     * @param connection соединение с БД
     * @param tableName имя таблицы (схема.таблица)
     * @param columns список колонок для вставки
     * @param data список данных для вставки
     * @param batchSize размер batch (обычно 1000-5000)
     * @return количество вставленных строк
     */
    <T> int batchInsert(
            Connection connection,
            String tableName,
            List<String> columns,
            List<T> data,
            int batchSize) throws ImportException;
}
```

#### ImportController.java
```java
package com.femsq.import.api;

import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

/**
 * REST контроллер для импорта данных из Excel.
 */
@RestController
@RequestMapping("/api/v1/import")
public class ImportController {
    
    /**
     * Импортирует данные из Excel файла в указанную таблицу.
     * 
     * POST /api/v1/import/excel
     * 
     * Body (multipart/form-data):
     * - file: Excel файл
     * - tableName: имя таблицы (например, "ags.og")
     * - sheetName: имя листа (опционально, по умолчанию первый)
     * - headerRow: номер строки с заголовками (по умолчанию 0)
     * - dataStartRow: номер строки начала данных (по умолчанию 1)
     * - columnMapping: JSON маппинг колонок Excel -> колонки БД
     * - mode: INSERT | UPDATE | UPSERT (по умолчанию INSERT)
     */
    @PostMapping("/excel")
    public ImportResponse importExcel(@RequestParam("file") MultipartFile file,
                                      @Valid @ModelAttribute ImportRequest request);
}
```

### 3. Пример использования

#### Пример 1: Импорт организаций в таблицу `ags.og`

**Excel файл:**
| ogNm | ogNmOf | ogINN | ogKPP |
|------|--------|-------|-------|
| ООО "Рога" | Общество с ограниченной ответственностью "Рога" | 1234567890 | 123456789 |
| ООО "Копыта" | Общество с ограниченной ответственностью "Копыта" | 0987654321 | 987654321 |

**Запрос:**
```http
POST /api/v1/import/excel
Content-Type: multipart/form-data

file: organizations.xlsx
tableName: ags.og
sheetName: Организации
headerRow: 0
dataStartRow: 1
columnMapping: {"ogNm": "ogNm", "ogNmOf": "ogNmOf", "ogINN": "ogINN", "ogKPP": "ogKPP"}
mode: INSERT
```

**Ответ:**
```json
{
  "success": true,
  "totalRows": 100,
  "importedRows": 98,
  "failedRows": 2,
  "errors": [
    {
      "row": 5,
      "message": "ogINN должен содержать 10 или 12 цифр"
    },
    {
      "row": 12,
      "message": "ogNm не может быть пустым"
    }
  ],
  "executionTimeMs": 1234
}
```

## Интеграция с существующей архитектурой

### Использование ConnectionFactory

Модуль `femsq-import` будет использовать существующий `ConnectionFactory` из `femsq-database`:

```java
@Service
public class ImportService {
    private final ConnectionFactory connectionFactory;
    
    public ImportService(ConnectionFactory connectionFactory) {
        this.connectionFactory = connectionFactory;
    }
    
    public ImportResult importExcel(ImportRequest request) {
        try (Connection connection = connectionFactory.createConnection()) {
            // Импорт данных
        }
    }
}
```

### Конфигурация Spring

Модуль будет автоматически подключаться через Spring Boot auto-configuration или явную конфигурацию в `femsq-web`.

## Обработка ошибок

### Типы ошибок

1. **Ошибки файла:**
   - Неподдерживаемый формат
   - Поврежденный файл
   - Отсутствует указанный лист

2. **Ошибки валидации:**
   - Неверный тип данных
   - Обязательные поля пусты
   - Нарушение ограничений БД

3. **Ошибки БД:**
   - Ошибки подключения
   - Нарушение уникальности
   - Ошибки транзакции

### Стратегии обработки

1. **Строгий режим:** Остановка при первой ошибке, rollback транзакции
2. **Мягкий режим:** Продолжение обработки, сбор всех ошибок, частичный commit

## Производительность

### Оптимизации

1. **Batch вставка:** Группировка INSERT запросов (batch size 1000-5000)
2. **Streaming чтение:** Для больших файлов использовать `SXSSFWorkbook`
3. **Параллельная обработка:** Для очень больших файлов (>1M строк)
4. **Кэширование:** Кэширование метаданных таблиц БД

### Оценка производительности

- **Малые файлы (<10K строк):** < 5 секунд
- **Средние файлы (10K-100K строк):** 5-30 секунд
- **Большие файлы (100K-1M строк):** 30-300 секунд
- **Очень большие файлы (>1M строк):** Асинхронная обработка

## Безопасность

1. **Валидация файлов:**
   - Проверка расширения файла
   - Проверка MIME типа
   - Ограничение размера файла (configurable)

2. **Валидация данных:**
   - SQL injection защита через PreparedStatement
   - Валидация типов данных
   - Проверка прав доступа к таблице

3. **Ограничения:**
   - Максимальный размер файла: 50 MB (по умолчанию)
   - Максимальное количество строк: 1M (по умолчанию)
   - Timeout обработки: 10 минут

## Тестирование

### Unit тесты

- `ExcelReaderTest` - тестирование чтения Excel
- `ExcelRowMapperTest` - тестирование маппинга
- `BatchInsertServiceTest` - тестирование batch вставки

### Integration тесты

- `ImportControllerIT` - полный цикл импорта
- Тесты с реальными Excel файлами
- Тесты с различными форматами данных

## План реализации

### Этап 1: Базовая функциональность (1-2 недели)
- [ ] Создание модуля `femsq-import`
- [ ] Реализация `ExcelReader`
- [ ] Реализация `BatchInsertService`
- [ ] Базовый REST API

### Этап 2: Расширенная функциональность (1 неделя)
- [ ] Валидация данных
- [ ] Обработка ошибок
- [ ] Поддержка режимов UPDATE/UPSERT
- [ ] Логирование

### Этап 3: Оптимизация и тестирование (1 неделя)
- [ ] Оптимизация производительности
- [ ] Unit и integration тесты
- [ ] Документация
- [ ] Примеры использования

## Альтернативные решения

### CSV импорт

После реализации Excel импорта можно легко добавить CSV импорт, используя ту же архитектуру.

### Прямой импорт через SQL Server

Для очень больших файлов можно использовать `BULK INSERT` или `bcp` утилиту SQL Server, но это требует:
- Доступ к файловой системе сервера БД
- Дополнительные права доступа
- Более сложная настройка

## Вопросы для обсуждения

1. **Приоритет форматов:** Начать с `.xlsx` или сразу поддержать `.xls`?
2. **Режимы импорта:** Нужны ли UPDATE и UPSERT сразу или только INSERT?
3. **Асинхронная обработка:** Нужна ли поддержка асинхронной обработки больших файлов?
4. **UI:** Нужен ли веб-интерфейс для загрузки файлов или только REST API?
5. **Валидация:** Какие правила валидации должны быть обязательными?

## Расширенная архитектура для сложной логики обработки

### Требования к расширенной функциональности

1. **Определение размера листа:**
   - Получение общего количества строк до начала обработки
   - Поддержка пустых строк и пропусков

2. **Построчная обработка с принятием решений:**
   - Кастомная логика для каждой строки
   - Условная обработка (переносить или нет)
   - Преобразование данных перед переносом

3. **Отображение прогресса в UI:**
   - Real-time обновления прогресса
   - Детальная информация о текущей строке
   - Возможность остановки/паузы процесса

4. **Сохранение промежуточных результатов:**
   - Сохранение статуса обработки в таблицы БД
   - Логирование каждой строки
   - История импортов

### Расширенная архитектура

#### 1. Асинхронная обработка с отслеживанием прогресса

```java
package com.femsq.import.core;

import java.util.UUID;
import java.util.concurrent.CompletableFuture;

/**
 * Сервис для асинхронной обработки импорта Excel.
 */
@Service
public class AsyncImportService {
    
    /**
     * Запускает асинхронную обработку импорта.
     * 
     * @param request запрос на импорт
     * @param progressCallback callback для обновления прогресса
     * @return ID задачи импорта
     */
    public UUID startImport(ImportRequest request, 
                           ImportProgressCallback progressCallback);
    
    /**
     * Получает статус задачи импорта.
     */
    public ImportTaskStatus getTaskStatus(UUID taskId);
    
    /**
     * Останавливает задачу импорта.
     */
    public void cancelTask(UUID taskId);
}
```

#### 2. Построчная обработка с кастомной логикой

```java
package com.femsq.import.excel;

import org.apache.poi.ss.usermodel.Row;
import java.util.function.BiFunction;

/**
 * Callback для обработки каждой строки Excel.
 */
@FunctionalInterface
public interface RowProcessor<T> {
    
    /**
     * Обрабатывает строку Excel и принимает решение о дальнейших действиях.
     * 
     * @param row строка Excel
     * @param rowNumber номер строки (0-based)
     * @param totalRows общее количество строк
     * @return результат обработки строки
     */
    RowProcessingResult<T> processRow(Row row, int rowNumber, int totalRows);
}

/**
 * Результат обработки строки.
 */
public record RowProcessingResult<T>(
    boolean shouldImport,      // Переносить ли строку на сервер
    T transformedData,         // Преобразованные данные (или null если не импортировать)
    String reason,             // Причина решения (для логирования)
    List<String> warnings      // Предупреждения
) {}
```

#### 3. Расширенный ExcelReader с построчной обработкой

```java
package com.femsq.import.excel;

/**
 * Расширенный сервис для чтения Excel с поддержкой построчной обработки.
 */
public class StreamingExcelReader {
    
    /**
     * Получает информацию о листе (размер, количество строк).
     */
    public SheetInfo getSheetInfo(InputStream inputStream, String sheetName) 
            throws ExcelImportException;
    
    /**
     * Обрабатывает лист построчно с callback для каждой строки.
     * 
     * @param inputStream поток данных Excel
     * @param sheetName имя листа
     * @param headerRow номер строки с заголовками
     * @param dataStartRow номер строки начала данных
     * @param processor callback для обработки каждой строки
     * @param progressCallback callback для обновления прогресса
     */
    public <T> ImportResult processSheet(
            InputStream inputStream,
            String sheetName,
            int headerRow,
            int dataStartRow,
            RowProcessor<T> processor,
            ImportProgressCallback progressCallback) throws ExcelImportException;
}

/**
 * Информация о листе Excel.
 */
public record SheetInfo(
    String sheetName,
    int totalRows,           // Общее количество строк (включая заголовки)
    int dataRows,           // Количество строк с данными
    List<String> headers,    // Заголовки колонок
    Map<String, Integer> columnIndexMap  // Маппинг имени колонки -> индекс
) {}
```

#### 4. Сохранение промежуточных результатов в БД

```java
package com.femsq.import.database;

/**
 * DAO для сохранения статуса импорта и промежуточных результатов.
 */
public interface ImportStatusDao {
    
    /**
     * Создает запись о начале импорта.
     */
    UUID createImportTask(ImportTaskMetadata metadata);
    
    /**
     * Обновляет прогресс импорта.
     */
    void updateProgress(UUID taskId, int processedRows, int totalRows, 
                       String currentStatus);
    
    /**
     * Сохраняет результат обработки строки.
     */
    void saveRowResult(UUID taskId, int rowNumber, RowProcessingResult result);
    
    /**
     * Завершает задачу импорта.
     */
    void completeTask(UUID taskId, ImportSummary summary);
    
    /**
     * Получает статус задачи.
     */
    ImportTaskStatus getTaskStatus(UUID taskId);
    
    /**
     * Получает детали обработки строк.
     */
    List<RowProcessingDetail> getRowDetails(UUID taskId, int offset, int limit);
}
```

**Структура таблиц для хранения статуса:**

```sql
-- Таблица задач импорта
CREATE TABLE ags.import_tasks (
    task_id UNIQUEIDENTIFIER PRIMARY KEY,
    file_name NVARCHAR(255) NOT NULL,
    sheet_name NVARCHAR(100),
    table_name NVARCHAR(255) NOT NULL,
    total_rows INT NOT NULL,
    processed_rows INT DEFAULT 0,
    imported_rows INT DEFAULT 0,
    failed_rows INT DEFAULT 0,
    status NVARCHAR(50) NOT NULL, -- PENDING, PROCESSING, COMPLETED, FAILED, CANCELLED
    started_at DATETIME2 NOT NULL,
    completed_at DATETIME2,
    error_message NVARCHAR(MAX),
    created_by NVARCHAR(100)
);

-- Таблица деталей обработки строк
CREATE TABLE ags.import_row_details (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    task_id UNIQUEIDENTIFIER NOT NULL,
    row_number INT NOT NULL,
    should_import BIT NOT NULL,
    imported BIT DEFAULT 0,
    transformed_data NVARCHAR(MAX), -- JSON с преобразованными данными
    reason NVARCHAR(500),
    warnings NVARCHAR(MAX), -- JSON массив предупреждений
    error_message NVARCHAR(MAX),
    processed_at DATETIME2 NOT NULL,
    FOREIGN KEY (task_id) REFERENCES ags.import_tasks(task_id)
);

CREATE INDEX idx_import_row_details_task_id ON ags.import_row_details(task_id);
CREATE INDEX idx_import_row_details_row_number ON ags.import_row_details(task_id, row_number);
```

#### 5. Real-time обновления через WebSocket или SSE

**Вариант A: Server-Sent Events (SSE) - Рекомендуется**

**Преимущества:**
- Проще реализовать
- Работает через HTTP (не требует специальной инфраструктуры)
- Автоматическое переподключение
- Подходит для односторонней передачи данных (server -> client)

**Реализация:**

```java
package com.femsq.import.api;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

/**
 * REST контроллер для импорта с поддержкой SSE.
 */
@RestController
@RequestMapping("/api/v1/import")
public class ImportController {
    
    /**
     * Запускает импорт и возвращает SSE поток для обновлений.
     * 
     * POST /api/v1/import/excel/async
     */
    @PostMapping(value = "/excel/async", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter importExcelAsync(
            @RequestParam("file") MultipartFile file,
            @Valid @ModelAttribute ImportRequest request) {
        
        SseEmitter emitter = new SseEmitter(3600000L); // 1 час timeout
        
        UUID taskId = asyncImportService.startImport(
            request, 
            new SseProgressCallback(emitter)
        );
        
        return emitter;
    }
    
    /**
     * Получает статус задачи импорта.
     * 
     * GET /api/v1/import/tasks/{taskId}/status
     */
    @GetMapping("/tasks/{taskId}/status")
    public ImportTaskStatus getTaskStatus(@PathVariable UUID taskId) {
        return asyncImportService.getTaskStatus(taskId);
    }
    
    /**
     * Получает детали обработки строк.
     * 
     * GET /api/v1/import/tasks/{taskId}/rows?offset=0&limit=100
     */
    @GetMapping("/tasks/{taskId}/rows")
    public PageResponse<RowProcessingDetail> getRowDetails(
            @PathVariable UUID taskId,
            @RequestParam(defaultValue = "0") int offset,
            @RequestParam(defaultValue = "100") int limit) {
        return importStatusDao.getRowDetails(taskId, offset, limit);
    }
    
    /**
     * Отменяет задачу импорта.
     * 
     * POST /api/v1/import/tasks/{taskId}/cancel
     */
    @PostMapping("/tasks/{taskId}/cancel")
    public void cancelTask(@PathVariable UUID taskId) {
        asyncImportService.cancelTask(taskId);
    }
}
```

**Callback для SSE:**

```java
package com.femsq.import.api;

import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

public class SseProgressCallback implements ImportProgressCallback {
    private final SseEmitter emitter;
    
    @Override
    public void onProgress(int processedRows, int totalRows, String status) {
        try {
            ImportProgressEvent event = new ImportProgressEvent(
                processedRows, totalRows, status, 
                (processedRows * 100.0 / totalRows)
            );
            emitter.send(SseEmitter.event()
                .name("progress")
                .data(event));
        } catch (IOException e) {
            // Обработка ошибки
        }
    }
    
    @Override
    public void onRowProcessed(int rowNumber, RowProcessingResult result) {
        try {
            emitter.send(SseEmitter.event()
                .name("row")
                .data(new RowProcessedEvent(rowNumber, result)));
        } catch (IOException e) {
            // Обработка ошибки
        }
    }
    
    @Override
    public void onComplete(ImportSummary summary) {
        try {
            emitter.send(SseEmitter.event()
                .name("complete")
                .data(summary));
            emitter.complete();
        } catch (IOException e) {
            emitter.completeWithError(e);
        }
    }
    
    @Override
    public void onError(Exception error) {
        emitter.completeWithError(error);
    }
}
```

**Вариант B: WebSocket**

Для двусторонней коммуникации (например, возможность отправки команд от клиента).

### 6. Пример использования расширенной архитектуры

```java
package com.femsq.import.excel;

@Service
public class CustomImportService {
    
    public ImportResult importWithCustomLogic(ImportRequest request) {
        // 1. Получаем информацию о листе
        SheetInfo sheetInfo = excelReader.getSheetInfo(
            request.getFileInputStream(), 
            request.getSheetName()
        );
        
        // 2. Создаем задачу импорта
        UUID taskId = importStatusDao.createImportTask(
            new ImportTaskMetadata(
                request.getFileName(),
                request.getSheetName(),
                request.getTableName(),
                sheetInfo.dataRows()
            )
        );
        
        // 3. Определяем кастомную логику обработки строк
        RowProcessor<Og> rowProcessor = (row, rowNumber, totalRows) -> {
            // Читаем данные из строки
            String ogNm = getCellValue(row, "ogNm");
            String ogINN = getCellValue(row, "ogINN");
            
            // Принимаем решение: переносить или нет
            if (ogNm == null || ogNm.trim().isEmpty()) {
                return new RowProcessingResult<>(
                    false, null, 
                    "ogNm пустое, строка пропущена",
                    List.of()
                );
            }
            
            // Проверяем дубликаты по ИНН
            if (ogINN != null && existsInDatabase(ogINN)) {
                return new RowProcessingResult<>(
                    false, null,
                    "Организация с ИНН " + ogINN + " уже существует",
                    List.of("Дубликат по ИНН")
                );
            }
            
            // Преобразуем данные
            Og transformed = new Og(
                null, // ogKey будет сгенерирован
                ogNm,
                getCellValue(row, "ogNmOf"),
                ogINN,
                getCellValue(row, "ogKPP"),
                // ... другие поля
            );
            
            return new RowProcessingResult<>(
                true, transformed,
                "Строка будет импортирована",
                List.of()
            );
        };
        
        // 4. Обрабатываем лист построчно
        ImportProgressCallback progressCallback = new DatabaseProgressCallback(
            taskId, importStatusDao
        );
        
        ImportResult result = excelReader.processSheet(
            request.getFileInputStream(),
            request.getSheetName(),
            request.getHeaderRow(),
            request.getDataStartRow(),
            rowProcessor,
            progressCallback
        );
        
        // 5. Выполняем batch вставку только для строк, которые нужно импортировать
        List<Og> toImport = result.getProcessedRows().stream()
            .filter(RowProcessingResult::shouldImport)
            .map(RowProcessingResult::transformedData)
            .filter(Objects::nonNull)
            .collect(Collectors.toList());
        
        if (!toImport.isEmpty()) {
            batchInsertService.batchInsert(
                connectionFactory.createConnection(),
                request.getTableName(),
                getColumnNames(),
                toImport,
                1000
            );
        }
        
        // 6. Завершаем задачу
        importStatusDao.completeTask(taskId, result.getSummary());
        
        return result;
    }
}
```

### 7. Frontend интеграция (Vue.js + Quasar)

```typescript
// stores/import.ts
import { apiRequest } from '@/api/http';

export interface ImportProgress {
  processedRows: number;
  totalRows: number;
  percentage: number;
  status: string;
  currentRow?: number;
}

export interface ImportTask {
  taskId: string;
  fileName: string;
  status: 'PENDING' | 'PROCESSING' | 'COMPLETED' | 'FAILED' | 'CANCELLED';
  progress: ImportProgress;
}

export async function startImport(
  file: File,
  config: ImportConfig
): Promise<EventSource> {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('tableName', config.tableName);
  formData.append('sheetName', config.sheetName || '');
  formData.append('headerRow', config.headerRow.toString());
  formData.append('dataStartRow', config.dataStartRow.toString());
  
  // Создаем EventSource для получения SSE событий
  const eventSource = new EventSource(
    `/api/v1/import/excel/async?${new URLSearchParams({
      tableName: config.tableName,
      sheetName: config.sheetName || '',
      headerRow: config.headerRow.toString(),
      dataStartRow: config.dataStartRow.toString(),
    })}`
  );
  
  return eventSource;
}

export async function getTaskStatus(taskId: string): Promise<ImportTask> {
  return apiRequest(`/api/v1/import/tasks/${taskId}/status`);
}

export async function cancelTask(taskId: string): Promise<void> {
  return apiRequest(`/api/v1/import/tasks/${taskId}/cancel`, {
    method: 'POST',
  });
}
```

**Vue компонент:**

```vue
<template>
  <q-page>
    <q-card>
      <q-card-section>
        <q-file v-model="file" label="Выберите Excel файл" />
        <q-input v-model="tableName" label="Таблица" />
        <q-input v-model="sheetName" label="Лист (опционально)" />
        <q-btn @click="startImport" label="Начать импорт" />
        <q-btn v-if="taskId" @click="cancelImport" label="Отменить" />
      </q-card-section>
      
      <q-card-section v-if="progress">
        <q-linear-progress 
          :value="progress.percentage / 100" 
          :label="`${progress.processedRows} / ${progress.totalRows}`"
        />
        <div>Статус: {{ progress.status }}</div>
        <div v-if="progress.currentRow">
          Обрабатывается строка: {{ progress.currentRow }}
        </div>
      </q-card-section>
      
      <q-card-section v-if="rowDetails.length > 0">
        <q-table
          :rows="rowDetails"
          :columns="columns"
          row-key="rowNumber"
        />
      </q-card-section>
    </q-card>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onUnmounted } from 'vue';
import { startImport, cancelTask, getTaskStatus } from '@/stores/import';

const file = ref<File | null>(null);
const tableName = ref('ags.og');
const sheetName = ref('');
const taskId = ref<string | null>(null);
const progress = ref<ImportProgress | null>(null);
const rowDetails = ref([]);
let eventSource: EventSource | null = null;

async function startImport() {
  if (!file.value) return;
  
  // Запускаем импорт и получаем SSE поток
  eventSource = await startImport(file.value, {
    tableName: tableName.value,
    sheetName: sheetName.value,
    headerRow: 0,
    dataStartRow: 1,
  });
  
  // Обрабатываем события
  eventSource.addEventListener('progress', (event) => {
    progress.value = JSON.parse(event.data);
  });
  
  eventSource.addEventListener('row', (event) => {
    const rowDetail = JSON.parse(event.data);
    rowDetails.value.push(rowDetail);
  });
  
  eventSource.addEventListener('complete', (event) => {
    const summary = JSON.parse(event.data);
    console.log('Импорт завершен:', summary);
    eventSource?.close();
  });
  
  eventSource.addEventListener('error', (error) => {
    console.error('Ошибка импорта:', error);
    eventSource?.close();
  });
}

async function cancelImport() {
  if (taskId.value) {
    await cancelTask(taskId.value);
    eventSource?.close();
  }
}

onUnmounted(() => {
  eventSource?.close();
});
</script>
```

### 8. Зависимости для расширенной функциональности

```xml
<dependencies>
    <!-- Apache POI -->
    <dependency>
        <groupId>org.apache.poi</groupId>
        <artifactId>poi-ooxml</artifactId>
        <version>5.2.5</version>
    </dependency>
    
    <!-- Spring Web для SSE -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    
    <!-- Для работы с JSON (если еще не добавлено) -->
    <dependency>
        <groupId>com.fasterxml.jackson.core</groupId>
        <artifactId>jackson-databind</artifactId>
    </dependency>
</dependencies>
```

## Сравнение гибкости: Apache POI vs VBA в MS Access

### Контекст сравнения

При работе с импортом данных из Excel в базу данных, важно понимать возможности каждого подхода для принятия обоснованного решения.

### VBA в MS Access: Возможности обработки строк

#### Преимущества VBA

1. **Прямая интеграция с Office:**
```vba
' Открытие Excel файла
Dim xlApp As Object
Set xlApp = CreateObject("Excel.Application")
Dim xlWorkbook As Object
Set xlWorkbook = xlApp.Workbooks.Open("C:\data\import.xlsx")
Dim xlSheet As Object
Set xlSheet = xlWorkbook.Worksheets("Sheet1")

' Построчная обработка
Dim lastRow As Long
lastRow = xlSheet.Cells(xlSheet.Rows.Count, 1).End(-4162).Row ' xlUp

Dim i As Long
For i = 2 To lastRow ' Пропускаем заголовок
    Dim ogNm As String
    ogNm = xlSheet.Cells(i, 1).Value
    
    ' Кастомная логика для каждой строки
    If ogNm <> "" Then
        ' Проверка дубликатов
        Dim rs As DAO.Recordset
        Set rs = CurrentDb.OpenRecordset("SELECT * FROM og WHERE ogNm = '" & ogNm & "'")
        
        If rs.EOF Then
            ' Преобразование данных
            Dim ogINN As String
            ogINN = xlSheet.Cells(i, 2).Value
            
            ' Вставка в БД
            CurrentDb.Execute "INSERT INTO og (ogNm, ogINN) VALUES ('" & ogNm & "', '" & ogINN & "')"
        End If
        rs.Close
    End If
Next i
```

2. **Простота разработки:**
   - Встроенная IDE в Access
   - Немедленное выполнение и отладка
   - Прямой доступ к объектной модели Access

3. **Интерактивность:**
   - Формы Access для отображения прогресса
   - Возможность остановки через UI
   - Встроенные диалоги и сообщения

4. **Работа с данными Access:**
   - Прямой доступ к таблицам через DAO/ADO
   - Использование запросов SQL
   - Транзакции через `BeginTrans`/`CommitTrans`

#### Ограничения VBA

1. **Производительность:**
   - Медленная обработка больших файлов (>100K строк)
   - Нет эффективного batch insert
   - Ограничения по памяти

2. **Платформенная зависимость:**
   - Только Windows
   - Требует установленный MS Office
   - Не работает в серверных средах

3. **Масштабируемость:**
   - Сложно распараллелить обработку
   - Ограничения по количеству одновременных пользователей
   - Нет веб-интерфейса

4. **Поддержка и развертывание:**
   - Сложное развертывание (требует Access Runtime)
   - Версионность кода (хранится в .accdb)
   - Ограниченные возможности тестирования

### Apache POI (Java): Возможности обработки строк

#### Преимущества Apache POI

1. **Гибкость обработки:**
```java
// Построчная обработка с кастомной логикой
RowProcessor<Og> processor = (row, rowNumber, totalRows) -> {
    // Чтение данных
    String ogNm = getCellValue(row, "ogNm");
    String ogINN = getCellValue(row, "ogINN");
    
    // Сложная логика принятия решений
    if (ogNm == null || ogNm.trim().isEmpty()) {
        return new RowProcessingResult<>(false, null, "ogNm пустое", List.of());
    }
    
    // Проверка дубликатов через DAO
    if (ogDao.existsByINN(ogINN)) {
        return new RowProcessingResult<>(false, null, "Дубликат", List.of());
    }
    
    // Преобразование данных
    Og transformed = transformRow(row);
    
    return new RowProcessingResult<>(true, transformed, "OK", List.of());
};

// Обработка с прогрессом
excelReader.processSheet(inputStream, sheetName, 0, 1, processor, progressCallback);
```

2. **Производительность:**
   - Эффективная обработка больших файлов (миллионы строк)
   - Batch insert для оптимизации БД
   - Streaming режим для экономии памяти
   - Многопоточная обработка

3. **Интеграция с современными технологиями:**
   - REST API для веб-доступа
   - Real-time обновления через SSE/WebSocket
   - Интеграция с Spring Boot
   - Микросервисная архитектура

4. **Масштабируемость:**
   - Работа в серверных средах
   - Поддержка множественных пользователей
   - Кроссплатформенность (Windows, Linux, macOS)
   - Контейнеризация (Docker)

5. **Качество кода:**
   - Unit и integration тесты
   - Версионирование через Git
   - CI/CD интеграция
   - Code review процессы

#### Ограничения Apache POI

1. **Сложность разработки:**
   - Требует знания Java
   - Более длительный цикл разработки
   - Необходимость компиляции

2. **Инфраструктура:**
   - Требует JVM и сервер приложений
   - Более сложное развертывание
   - Необходимость настройки окружения

### Детальное сравнение по критериям

| Критерий | VBA в MS Access | Apache POI (Java) | Победитель |
|----------|----------------|-------------------|------------|
| **Гибкость логики обработки строк** | ⭐⭐⭐⭐ Высокая | ⭐⭐⭐⭐⭐ Очень высокая | Apache POI |
| **Простота разработки** | ⭐⭐⭐⭐⭐ Очень простая | ⭐⭐⭐ Средняя | VBA |
| **Производительность** | ⭐⭐ Низкая | ⭐⭐⭐⭐⭐ Очень высокая | Apache POI |
| **Обработка больших файлов** | ⭐⭐ Проблемы | ⭐⭐⭐⭐⭐ Отлично | Apache POI |
| **Интерактивность UI** | ⭐⭐⭐⭐ Хорошая | ⭐⭐⭐⭐⭐ Отличная (веб) | Apache POI |
| **Интеграция с БД** | ⭐⭐⭐⭐ Хорошая | ⭐⭐⭐⭐⭐ Отличная | Apache POI |
| **Масштабируемость** | ⭐⭐ Низкая | ⭐⭐⭐⭐⭐ Очень высокая | Apache POI |
| **Кроссплатформенность** | ⭐ Только Windows | ⭐⭐⭐⭐⭐ Все платформы | Apache POI |
| **Развертывание** | ⭐⭐⭐ Среднее | ⭐⭐⭐⭐ Хорошее | Apache POI |
| **Поддержка и сопровождение** | ⭐⭐⭐ Средняя | ⭐⭐⭐⭐⭐ Отличная | Apache POI |

### Сравнение гибкости обработки строк

#### Пример 1: Простая проверка и вставка

**VBA:**
```vba
For i = 2 To lastRow
    Dim ogNm As String
    ogNm = xlSheet.Cells(i, 1).Value
    If ogNm <> "" Then
        CurrentDb.Execute "INSERT INTO og (ogNm) VALUES ('" & ogNm & "')"
    End If
Next i
```

**Apache POI:**
```java
RowProcessor<Og> processor = (row, rowNumber, totalRows) -> {
    String ogNm = getCellValue(row, "ogNm");
    if (ogNm == null || ogNm.trim().isEmpty()) {
        return new RowProcessingResult<>(false, null, "Пустое", List.of());
    }
    return new RowProcessingResult<>(true, new Og(null, ogNm), "OK", List.of());
};
```

**Вывод:** Оба подхода справляются одинаково хорошо для простых случаев.

#### Пример 2: Сложная логика с проверками и преобразованиями

**VBA:**
```vba
For i = 2 To lastRow
    Dim ogNm As String, ogINN As String, ogKPP As String
    ogNm = Trim(xlSheet.Cells(i, 1).Value)
    ogINN = Trim(xlSheet.Cells(i, 2).Value)
    ogKPP = Trim(xlSheet.Cells(i, 3).Value)
    
    ' Валидация
    If ogNm = "" Then
        Debug.Print "Строка " & i & ": ogNm пустое"
        GoTo NextRow
    End If
    
    If Len(ogINN) <> 10 And Len(ogINN) <> 12 Then
        Debug.Print "Строка " & i & ": Неверный ИНН"
        GoTo NextRow
    End If
    
    ' Проверка дубликатов
    Dim rs As DAO.Recordset
    Set rs = CurrentDb.OpenRecordset("SELECT ogKey FROM og WHERE ogINN = '" & ogINN & "'")
    If Not rs.EOF Then
        Debug.Print "Строка " & i & ": Дубликат по ИНН"
        rs.Close
        GoTo NextRow
    End If
    rs.Close
    
    ' Преобразование данных
    Dim ogNmOf As String
    ogNmOf = "ООО """ & ogNm & """"
    
    ' Вставка
    CurrentDb.Execute "INSERT INTO og (ogNm, ogNmOf, ogINN, ogKPP) " & _
                      "VALUES ('" & ogNm & "', '" & ogNmOf & "', '" & ogINN & "', '" & ogKPP & "')"
    
NextRow:
Next i
```

**Apache POI:**
```java
RowProcessor<Og> processor = (row, rowNumber, totalRows) -> {
    // Чтение данных
    String ogNm = normalize(getCellValue(row, "ogNm"));
    String ogINN = normalize(getCellValue(row, "ogINN"));
    String ogKPP = normalize(getCellValue(row, "ogKPP"));
    
    List<String> warnings = new ArrayList<>();
    
    // Валидация
    if (ogNm == null || ogNm.isEmpty()) {
        return new RowProcessingResult<>(
            false, null, 
            "ogNm пустое", 
            List.of()
        );
    }
    
    if (ogINN == null || (ogINN.length() != 10 && ogINN.length() != 12)) {
        return new RowProcessingResult<>(
            false, null,
            "Неверный ИНН: должен быть 10 или 12 цифр",
            List.of()
        );
    }
    
    // Проверка дубликатов (через DAO)
    if (ogDao.existsByINN(ogINN)) {
        return new RowProcessingResult<>(
            false, null,
            "Дубликат по ИНН: " + ogINN,
            List.of("Организация уже существует в БД")
        );
    }
    
    // Преобразование данных
    String ogNmOf = "ООО \"" + ogNm + "\"";
    
    Og transformed = new Og(
        null, ogNm, ogNmOf, ogINN, ogKPP, null, null, null, null, null, null
    );
    
    return new RowProcessingResult<>(
        true, transformed,
        "Строка будет импортирована",
        warnings
    );
};
```

**Вывод:** Apache POI предоставляет более структурированный и типобезопасный подход, но VBA также справляется с задачей.

#### Пример 3: Обработка с прогрессом и сохранением промежуточных результатов

**VBA:**
```vba
' Создание таблицы для логов
CurrentDb.Execute "CREATE TABLE IF NOT EXISTS import_log (" & _
                  "row_number INT, status TEXT, message TEXT, processed_at DATETIME)"

For i = 2 To lastRow
    ' Обновление прогресса в форме
    Me.lblProgress.Caption = "Обработка строки " & i & " из " & lastRow
    Me.lblProgressPercent.Caption = Int((i / lastRow) * 100) & "%"
    DoEvents ' Обновление UI
    
    ' Обработка строки
    On Error Resume Next
    ' ... логика обработки ...
    On Error GoTo 0
    
    ' Сохранение в лог
    CurrentDb.Execute "INSERT INTO import_log (row_number, status, message, processed_at) " & _
                      "VALUES (" & i & ", 'PROCESSED', 'OK', NOW())"
    
    ' Проверка отмены
    If Me.cmdCancel.Value Then
        Exit For
    End If
Next i
```

**Apache POI:**
```java
// Автоматическое сохранение прогресса через callback
ImportProgressCallback callback = new ImportProgressCallback() {
    @Override
    public void onProgress(int processedRows, int totalRows, String status) {
        // Отправка через SSE
        sseEmitter.send(SseEmitter.event()
            .name("progress")
            .data(new ProgressEvent(processedRows, totalRows, status)));
        
        // Сохранение в БД
        importStatusDao.updateProgress(taskId, processedRows, totalRows, status);
    }
    
    @Override
    public void onRowProcessed(int rowNumber, RowProcessingResult result) {
        // Автоматическое сохранение деталей
        importStatusDao.saveRowResult(taskId, rowNumber, result);
    }
};
```

**Вывод:** Apache POI предоставляет более мощные и стандартизированные механизмы для отслеживания прогресса и сохранения результатов.

### Ключевые различия в гибкости

#### 1. Типобезопасность

**VBA:** Слабая типизация, ошибки обнаруживаются во время выполнения
```vba
Dim ogNm As String
ogNm = xlSheet.Cells(i, 1).Value ' Может быть любым типом
```

**Apache POI:** Строгая типизация, ошибки обнаруживаются на этапе компиляции
```java
String ogNm = getCellValueAsString(row, "ogNm"); // Гарантированный тип
```

#### 2. Обработка ошибок

**VBA:** Базовые механизмы (On Error)
```vba
On Error Resume Next
' код
If Err.Number <> 0 Then
    Debug.Print "Ошибка: " & Err.Description
End If
```

**Apache POI:** Современные механизмы (exceptions, try-catch)
```java
try {
    // код
} catch (ExcelImportException e) {
    log.error("Ошибка импорта", e);
    return new RowProcessingResult<>(false, null, e.getMessage(), List.of());
}
```

#### 3. Тестируемость

**VBA:** Сложно тестировать, требует Access
**Apache POI:** Легко тестировать с JUnit, моки, изоляция

#### 4. Реиспользование кода

**VBA:** Код привязан к конкретной базе Access
**Apache POI:** Модульная архитектура, переиспользование компонентов

### Выводы и рекомендации

#### Когда использовать VBA в MS Access:

✅ **Подходит для:**
- Быстрого прототипирования
- Небольших объемов данных (<10K строк)
- Локальных решений для одного пользователя
- Простых импортов без сложной логики
- Когда уже есть инфраструктура Access

❌ **Не подходит для:**
- Больших объемов данных (>100K строк)
- Серверных решений
- Веб-приложений
- Многопользовательских сценариев
- Требований к производительности

#### Когда использовать Apache POI:

✅ **Подходит для:**
- Производственных систем
- Больших объемов данных (миллионы строк)
- Веб-приложений и API
- Многопользовательских сценариев
- Требований к масштабируемости
- Интеграции с современными технологиями

❌ **Может быть избыточным для:**
- Очень простых импортов
- Разовых задач
- Когда нет Java-инфраструктуры

### Гибридный подход

Можно комбинировать оба подхода:

1. **VBA для быстрого прототипирования** логики обработки
2. **Миграция в Java** после валидации логики
3. **Использование VBA скриптов** как спецификаций для Java-кода

### Заключение по гибкости

**Гибкость обработки строк:**

| Аспект | VBA | Apache POI |
|--------|-----|------------|
| **Логика принятия решений** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Преобразование данных** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Интеграция с БД** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Обработка ошибок** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Тестируемость** | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Производительность** | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Масштабируемость** | ⭐⭐ | ⭐⭐⭐⭐⭐ |

**Итог:** Apache POI предоставляет **равную или большую гибкость** в обработке строк по сравнению с VBA, при этом значительно превосходя его в производительности, масштабируемости и возможностях интеграции с современными технологиями.

## Миграция функционала MS Access VBA в Java/Spring Boot

### Обзор миграции

Воспроизведение функционала MS Access VBA в Java/Spring Boot проекте **полностью возможно** и даже предпочтительно для производственных систем. Ниже представлен детальный план миграции всех компонентов VBA.

### Маппинг компонентов VBA → Java/Spring Boot

#### 1. Модули VBA → Java классы/сервисы

**VBA Модуль (Standard Module):**
```vba
' Module: ImportModule
Option Compare Database
Option Explicit

Public Sub ImportOrganizationsFromExcel(filePath As String)
    Dim xlApp As Object
    Set xlApp = CreateObject("Excel.Application")
    ' ... логика импорта ...
End Sub

Public Function ValidateINN(inn As String) As Boolean
    ValidateINN = (Len(inn) = 10 Or Len(inn) = 12) And IsNumeric(inn)
End Function

Public Function TransformOrganizationName(shortName As String) As String
    TransformOrganizationName = "ООО """ & shortName & """"
End Function
```

**Java эквивалент:**
```java
package com.femsq.import.excel;

import org.springframework.stereotype.Service;
import java.util.logging.Logger;

/**
 * Сервис для импорта организаций из Excel.
 * Эквивалент VBA модуля ImportModule.
 */
@Service
public class OrganizationImportService {
    
    private static final Logger log = Logger.getLogger(OrganizationImportService.class.getName());
    
    private final ExcelReader excelReader;
    private final OgDao ogDao;
    private final BatchInsertService batchInsertService;
    
    /**
     * Импортирует организации из Excel файла.
     * Эквивалент VBA Sub ImportOrganizationsFromExcel.
     */
    public ImportResult importOrganizationsFromExcel(String filePath) {
        // Логика импорта
        try (InputStream inputStream = Files.newInputStream(Paths.get(filePath))) {
            SheetInfo sheetInfo = excelReader.getSheetInfo(inputStream, "Организации");
            
            RowProcessor<Og> processor = this::processOrganizationRow;
            
            return excelReader.processSheet(
                inputStream, "Организации", 0, 1, processor, progressCallback
            );
        }
    }
    
    /**
     * Валидирует ИНН.
     * Эквивалент VBA Function ValidateINN.
     */
    public boolean validateINN(String inn) {
        if (inn == null) return false;
        String cleaned = inn.trim();
        return (cleaned.length() == 10 || cleaned.length() == 12) 
               && cleaned.matches("\\d+");
    }
    
    /**
     * Преобразует краткое наименование в официальное.
     * Эквивалент VBA Function TransformOrganizationName.
     */
    public String transformOrganizationName(String shortName) {
        if (shortName == null || shortName.trim().isEmpty()) {
            return null;
        }
        return "ООО \"" + shortName.trim() + "\"";
    }
    
    private RowProcessingResult<Og> processOrganizationRow(
            Row row, int rowNumber, int totalRows) {
        // Логика обработки строки
        String ogNm = getCellValue(row, "ogNm");
        String ogINN = getCellValue(row, "ogINN");
        
        if (!validateINN(ogINN)) {
            return new RowProcessingResult<>(
                false, null, "Неверный ИНН", List.of()
            );
        }
        
        String ogNmOf = transformOrganizationName(ogNm);
        Og transformed = new Og(null, ogNm, ogNmOf, ogINN, null, null, null, null, null, null, null);
        
        return new RowProcessingResult<>(
            true, transformed, "OK", List.of()
        );
    }
}
```

#### 2. Модули классов VBA → Java классы с инкапсуляцией

**VBA Class Module:**
```vba
' Class Module: ExcelRowProcessor
Option Compare Database
Option Explicit

Private m_rowNumber As Long
Private m_data As Dictionary

Public Property Get RowNumber() As Long
    RowNumber = m_rowNumber
End Property

Public Property Let RowNumber(value As Long)
    m_rowNumber = value
End Property

Public Function ProcessRow(xlSheet As Object, rowIndex As Long) As Boolean
    m_rowNumber = rowIndex
    Set m_data = New Dictionary
    
    ' Чтение данных из строки
    m_data("ogNm") = xlSheet.Cells(rowIndex, 1).Value
    m_data("ogINN") = xlSheet.Cells(rowIndex, 2).Value
    
    ' Валидация
    If Not ValidateData() Then
        ProcessRow = False
        Exit Function
    End If
    
    ProcessRow = True
End Function

Private Function ValidateData() As Boolean
    ValidateData = (m_data("ogNm") <> "" And m_data("ogINN") <> "")
End Function
```

**Java эквивалент:**
```java
package com.femsq.import.excel;

import org.apache.poi.ss.usermodel.Row;
import java.util.HashMap;
import java.util.Map;

/**
 * Класс для обработки строк Excel.
 * Эквивалент VBA Class Module ExcelRowProcessor.
 */
public class ExcelRowProcessor {
    
    private int rowNumber;
    private Map<String, Object> data;
    
    public ExcelRowProcessor() {
        this.data = new HashMap<>();
    }
    
    /**
     * Обрабатывает строку Excel.
     * Эквивалент VBA Function ProcessRow.
     */
    public boolean processRow(Row row, int rowIndex) {
        this.rowNumber = rowIndex;
        this.data.clear();
        
        // Чтение данных из строки
        data.put("ogNm", getCellValue(row, "ogNm"));
        data.put("ogINN", getCellValue(row, "ogINN"));
        
        // Валидация
        return validateData();
    }
    
    /**
     * Валидирует данные.
     * Эквивалент VBA Private Function ValidateData.
     */
    private boolean validateData() {
        String ogNm = (String) data.get("ogNm");
        String ogINN = (String) data.get("ogINN");
        return ogNm != null && !ogNm.isEmpty() 
            && ogINN != null && !ogINN.isEmpty();
    }
    
    // Getters и Setters
    public int getRowNumber() {
        return rowNumber;
    }
    
    public void setRowNumber(int rowNumber) {
        this.rowNumber = rowNumber;
    }
    
    public Map<String, Object> getData() {
        return new HashMap<>(data); // Защищенная копия
    }
}
```

#### 3. Модули форм VBA → REST API + Vue.js компоненты

**VBA Form Module:**
```vba
' Form Module: frmImportOrganizations
Option Compare Database
Option Explicit

Private Sub cmdImport_Click()
    Dim filePath As String
    filePath = Me.txtFilePath.Value
    
    If filePath = "" Then
        MsgBox "Выберите файл", vbExclamation
        Exit Sub
    End If
    
    ' Обновление UI
    Me.lblStatus.Caption = "Импорт начат..."
    Me.progBar.Value = 0
    DoEvents
    
    ' Импорт
    Call ImportOrganizationsFromExcel(filePath)
    
    Me.lblStatus.Caption = "Импорт завершен"
    Me.progBar.Value = 100
End Sub

Private Sub cmdCancel_Click()
    ' Отмена импорта
    CancelImport = True
End Sub

Private Sub Form_Load()
    Me.lblStatus.Caption = "Готов к импорту"
    Me.progBar.Value = 0
End Sub
```

**Java REST API (Backend):**
```java
package com.femsq.import.api;

import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

/**
 * REST контроллер для импорта организаций.
 * Эквивалент VBA Form Module frmImportOrganizations.
 */
@RestController
@RequestMapping("/api/v1/import/organizations")
public class OrganizationImportController {
    
    private final OrganizationImportService importService;
    
    /**
     * Запускает импорт организаций.
     * Эквивалент VBA Sub cmdImport_Click.
     */
    @PostMapping(value = "/excel", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter importOrganizations(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "sheetName", defaultValue = "Организации") String sheetName) {
        
        SseEmitter emitter = new SseEmitter(3600000L);
        
        // Асинхронная обработка
        CompletableFuture.runAsync(() -> {
            try {
                ImportResult result = importService.importOrganizationsFromExcel(
                    file.getInputStream(), sheetName, emitter
                );
                
                emitter.send(SseEmitter.event()
                    .name("complete")
                    .data(result));
                emitter.complete();
            } catch (Exception e) {
                emitter.completeWithError(e);
            }
        });
        
        return emitter;
    }
    
    /**
     * Отменяет импорт.
     * Эквивалент VBA Sub cmdCancel_Click.
     */
    @PostMapping("/{taskId}/cancel")
    public void cancelImport(@PathVariable UUID taskId) {
        importService.cancelTask(taskId);
    }
    
    /**
     * Получает статус импорта.
     * Эквивалент обновления UI в VBA.
     */
    @GetMapping("/{taskId}/status")
    public ImportTaskStatus getStatus(@PathVariable UUID taskId) {
        return importService.getTaskStatus(taskId);
    }
}
```

**Vue.js компонент (Frontend):**
```vue
<template>
  <q-page>
    <q-card>
      <q-card-section>
        <h6>Импорт организаций из Excel</h6>
        
        <!-- Эквивалент txtFilePath -->
        <q-file 
          v-model="file" 
          label="Выберите Excel файл"
          accept=".xlsx,.xls"
        />
        
        <!-- Эквивалент txtSheetName -->
        <q-input 
          v-model="sheetName" 
          label="Имя листа"
          hint="По умолчанию: Организации"
        />
        
        <!-- Эквивалент cmdImport -->
        <q-btn 
          @click="startImport" 
          label="Начать импорт"
          color="primary"
          :disable="!file"
        />
        
        <!-- Эквивалент cmdCancel -->
        <q-btn 
          v-if="isImporting"
          @click="cancelImport" 
          label="Отменить"
          color="negative"
        />
      </q-card-section>
      
      <!-- Эквивалент lblStatus и progBar -->
      <q-card-section v-if="status">
        <div class="text-body2">{{ status.message }}</div>
        <q-linear-progress 
          :value="status.progress / 100"
          :label="`${status.processedRows} / ${status.totalRows}`"
        />
      </q-card-section>
    </q-card>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onUnmounted } from 'vue';
import { startImport, cancelTask } from '@/stores/import';

const file = ref<File | null>(null);
const sheetName = ref('Организации');
const isImporting = ref(false);
const status = ref<ImportProgress | null>(null);
let eventSource: EventSource | null = null;

// Эквивалент Form_Load
onMounted(() => {
  status.value = { message: 'Готов к импорту', progress: 0, processedRows: 0, totalRows: 0 };
});

// Эквивалент cmdImport_Click
async function startImport() {
  if (!file.value) return;
  
  isImporting.value = true;
  status.value = { message: 'Импорт начат...', progress: 0, processedRows: 0, totalRows: 0 };
  
  eventSource = await startImport(file.value, {
    tableName: 'ags.og',
    sheetName: sheetName.value,
  });
  
  eventSource.addEventListener('progress', (event) => {
    status.value = JSON.parse(event.data);
  });
  
  eventSource.addEventListener('complete', () => {
    status.value!.message = 'Импорт завершен';
    status.value!.progress = 100;
    isImporting.value = false;
    eventSource?.close();
  });
}

// Эквивалент cmdCancel_Click
async function cancelImport() {
  if (eventSource) {
    await cancelTask(taskId.value);
    eventSource.close();
    isImporting.value = false;
  }
}

onUnmounted(() => {
  eventSource?.close();
});
</script>
```

#### 4. Функции и процедуры VBA → Методы Java

**VBA:**
```vba
' Глобальные функции
Public Function GetCellValue(xlSheet As Object, row As Long, col As Long) As String
    On Error Resume Next
    GetCellValue = Trim(CStr(xlSheet.Cells(row, col).Value))
    On Error GoTo 0
End Function

Public Sub LogImportError(rowNumber As Long, errorMessage As String)
    Debug.Print "Row " & rowNumber & ": " & errorMessage
    ' Запись в таблицу логов
    CurrentDb.Execute "INSERT INTO import_log (row_number, error_message) " & _
                      "VALUES (" & rowNumber & ", '" & errorMessage & "')"
End Sub
```

**Java:**
```java
package com.femsq.import.excel;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import java.util.logging.Logger;

/**
 * Утилиты для работы с Excel.
 * Эквивалент глобальных функций VBA.
 */
public class ExcelUtils {
    
    private static final Logger log = Logger.getLogger(ExcelUtils.class.getName());
    
    /**
     * Получает значение ячейки как строку.
     * Эквивалент VBA Function GetCellValue.
     */
    public static String getCellValue(Row row, int columnIndex) {
        try {
            Cell cell = row.getCell(columnIndex);
            if (cell == null) {
                return null;
            }
            
            return switch (cell.getCellType()) {
                case STRING -> cell.getStringCellValue().trim();
                case NUMERIC -> String.valueOf((long) cell.getNumericCellValue());
                case BOOLEAN -> String.valueOf(cell.getBooleanCellValue());
                case FORMULA -> cell.getCellFormula();
                default -> null;
            };
        } catch (Exception e) {
            log.warning("Ошибка чтения ячейки: " + e.getMessage());
            return null;
        }
    }
    
    /**
     * Логирует ошибку импорта.
     * Эквивалент VBA Sub LogImportError.
     */
    public static void logImportError(int rowNumber, String errorMessage, 
                                     ImportStatusDao statusDao, UUID taskId) {
        log.warning(String.format("Row %d: %s", rowNumber, errorMessage));
        
        // Запись в БД
        statusDao.saveRowResult(taskId, rowNumber, 
            new RowProcessingResult<>(false, null, errorMessage, List.of()));
    }
}
```

#### 5. Работа с БД: DAO/Recordset → DAO/Service слой

**VBA с DAO:**
```vba
' Работа с таблицей og
Dim db As DAO.Database
Set db = CurrentDb

Dim rs As DAO.Recordset
Set rs = db.OpenRecordset("SELECT * FROM og WHERE ogINN = '" & inn & "'")

If Not rs.EOF Then
    ' Запись существует
    rs.Close
    Exit Sub
End If

' Вставка новой записи
db.Execute "INSERT INTO og (ogNm, ogINN) VALUES ('" & name & "', '" & inn & "')"
rs.Close
```

**Java с DAO:**
```java
package com.femsq.import.database;

import com.femsq.database.dao.OgDao;
import com.femsq.database.model.Og;
import java.util.Optional;

/**
 * Сервис для работы с организациями при импорте.
 * Эквивалент работы с DAO.Recordset в VBA.
 */
@Service
public class OrganizationImportDaoService {
    
    private final OgDao ogDao;
    
    /**
     * Проверяет существование организации по ИНН.
     * Эквивалент VBA проверки через Recordset.
     */
    public boolean existsByINN(String inn) {
        // Можно добавить метод в OgDao
        return ogDao.findByINN(inn).isPresent();
    }
    
    /**
     * Создает организацию.
     * Эквивалент VBA INSERT через Execute.
     */
    public Og createOrganization(String name, String inn) {
        Og organization = new Og(
            null, // ogKey будет сгенерирован
            name,
            null, // ogNmOf
            inn,
            null, // ogKPP
            null, null, null, null, null, null
        );
        
        return ogDao.create(organization);
    }
    
    /**
     * Batch вставка организаций.
     * Более эффективно, чем VBA цикл с отдельными INSERT.
     */
    public int batchCreateOrganizations(List<Og> organizations) {
        return batchInsertService.batchInsert(
            connectionFactory.createConnection(),
            "ags.og",
            List.of("ogNm", "ogNmOf", "ogINN", "ogKPP"),
            organizations,
            1000
        );
    }
}
```

#### 6. События и обработчики → REST endpoints + WebSocket/SSE

**VBA события:**
```vba
' Обработка события изменения прогресса
Private Sub UpdateProgress(currentRow As Long, totalRows As Long)
    Me.progBar.Value = (currentRow / totalRows) * 100
    Me.lblStatus.Caption = "Обработано " & currentRow & " из " & totalRows
    DoEvents ' Обновление UI
End Sub
```

**Java с SSE:**
```java
// Автоматическая отправка событий через SSE
progressCallback.onProgress(processedRows, totalRows, "PROCESSING");

// Frontend автоматически получает обновления
eventSource.addEventListener('progress', (event) => {
  const progress = JSON.parse(event.data);
  // Обновление UI
});
```

### Структура миграции проекта

```
VBA Access структура          →  Java/Spring Boot структура
─────────────────────────────    ──────────────────────────────
Modules/
  ImportModule.bas            →  femsq-import/
                                    excel/
                                      OrganizationImportService.java
                                      ExcelUtils.java
  
  ValidationModule.bas        →  femsq-import/
                                    validation/
                                      DataValidationService.java
                                      INNValidator.java
  
Class Modules/
  ExcelRowProcessor.cls        →  femsq-import/
                                    excel/
                                      ExcelRowProcessor.java
  
  ImportLogger.cls            →  femsq-import/
                                    logging/
                                      ImportLogger.java

Forms/
  frmImportOrganizations.frm  →  femsq-web/
                                    api/rest/
                                      OrganizationImportController.java
                                +  femsq-frontend-q/
                                    views/
                                      ImportOrganizationsView.vue

Queries/
  qryImportLog                →  femsq-import/
                                    database/
                                      ImportStatusDao.java
                                      (методы для работы с ags.import_tasks)
```

### Пошаговый план миграции

#### Этап 1: Анализ существующего VBA кода

1. **Документирование модулей:**
   - Список всех модулей и их функций
   - Зависимости между модулями
   - Используемые таблицы и запросы

2. **Анализ логики:**
   - Бизнес-правила валидации
   - Преобразования данных
   - Обработка ошибок

#### Этап 2: Создание Java эквивалентов

1. **Модули → Сервисы:**
   ```java
   // VBA Module → Java Service
   @Service
   public class OrganizationImportService {
       // Все функции из VBA модуля
   }
   ```

2. **Классы → Java классы:**
   ```java
   // VBA Class Module → Java Class
   public class ExcelRowProcessor {
       // Инкапсуляция логики обработки строк
   }
   ```

3. **Формы → REST API + Vue компоненты:**
   ```java
   // VBA Form → REST Controller
   @RestController
   public class OrganizationImportController {
       // Все обработчики событий формы
   }
   ```

#### Этап 3: Миграция данных и логики

1. **Работа с БД:**
   - VBA DAO → Java DAO
   - VBA SQL запросы → Java PreparedStatement
   - VBA транзакции → Java Connection transactions

2. **Валидация:**
   - VBA функции валидации → Java валидаторы
   - Использование Bean Validation

3. **Обработка ошибок:**
   - VBA On Error → Java try-catch
   - VBA Debug.Print → Java Logger

#### Этап 4: Тестирование и валидация

1. **Unit тесты:**
   - Тестирование каждого сервиса
   - Тестирование валидаторов
   - Тестирование преобразований данных

2. **Integration тесты:**
   - Полный цикл импорта
   - Сравнение результатов с VBA версией

3. **Регрессионное тестирование:**
   - Импорт тех же файлов
   - Сравнение результатов

### Преимущества миграции

1. **Производительность:**
   - Batch операции вместо циклов
   - Многопоточность
   - Оптимизация запросов

2. **Масштабируемость:**
   - Веб-доступ для множественных пользователей
   - Серверная обработка
   - Контейнеризация

3. **Поддерживаемость:**
   - Версионирование кода (Git)
   - Unit тесты
   - Code review
   - Документация

4. **Расширяемость:**
   - Легко добавить новые форматы (CSV, JSON)
   - Интеграция с другими системами
   - API для внешних клиентов

### Потенциальные сложности и решения

#### 1. Сложная бизнес-логика в VBA

**Проблема:** Много встроенной логики в формах и модулях

**Решение:**
- Постепенная миграция модуль за модулем
- Сохранение VBA версии для референса
- Детальное тестирование каждого модуля

#### 2. Зависимости от Access объектов

**Проблема:** Использование специфичных объектов Access

**Решение:**
- Замена на стандартные Java библиотеки
- Apache POI для Excel
- JDBC для БД

#### 3. UI логика в формах

**Проблема:** Логика отображения смешана с бизнес-логикой

**Решение:**
- Разделение на Backend (REST API) и Frontend (Vue.js)
- Четкое разделение ответственности

### Заключение по миграции

**✅ Воспроизведение функционала VBA полностью возможно:**

1. **Модули VBA** → Java сервисы с той же логикой
2. **Модули классов** → Java классы с инкапсуляцией
3. **Модули форм** → REST API + Vue.js компоненты
4. **Функции и процедуры** → Методы Java
5. **Работа с БД** → DAO/Service слой
6. **События** → REST endpoints + SSE/WebSocket

**Преимущества миграции:**
- ✅ Равная или большая функциональность
- ✅ Значительно лучшая производительность
- ✅ Современная архитектура
- ✅ Масштабируемость
- ✅ Поддерживаемость

**Рекомендация:** Поэтапная миграция модуль за модулем с сохранением VBA версии для сравнения результатов.

## Заключение

Рекомендуется реализовать **Вариант 1** (новый модуль `femsq-import`) с использованием **Apache POI** для максимальной гибкости и расширяемости решения.

**Расширенная архитектура позволяет:**
- ✅ Определять размер листа до начала обработки
- ✅ Выполнять построчный проход с кастомной логикой
- ✅ Принимать решения для каждой строки (импортировать или нет)
- ✅ Преобразовывать данные перед импортом
- ✅ Отображать прогресс в UI через SSE
- ✅ Сохранять промежуточные результаты в таблицы БД
- ✅ Отслеживать историю импортов
- ✅ Останавливать/отменять процесс импорта

**Сравнение с VBA показывает:**
- ✅ Равная или большая гибкость в обработке строк
- ✅ Значительно лучшая производительность
- ✅ Современные возможности интеграции (веб, API, real-time)
- ✅ Масштабируемость для производственных систем

