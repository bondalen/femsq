> Файл исходника: `docs/project/proposals/vba-analysis/VBA-Code-Export/Form-Modules/Form_ra_a.cls`

## 1. Заголовок формы и размещение процедуры

В начале модуля формы `Form_ra_a` указаны стандартные атрибуты формы Access и включён `Option Compare Database`. Сразу после этого объявлена процедура:

```vba
Private Sub btnAuditRun_Click()
    Const cstrTitle As String = "..."
    ' ... объявления переменных ...
End Sub
```

Эта процедура является обработчиком нажатия кнопки **"Выполнить ревизию"** на форме ревизий в Access.

## 2. Высокоуровневая структура btnAuditRun_Click (по первым ~200 строкам)

По первым строкам процедуры (около 1–200 в `Form_ra_a.cls`) можно выделить такие логические блоки:

1. **Объявление констант и переменных**  
   - `cstrTitle` — заголовок для сообщений об ошибках/диалогов.  
   - Объекты DAO: `db As DAO.Database`, `qd As DAO.QueryDef`, несколько `Recordset` (основные данные ревизии, директории, фильтрованные наборы листов).  
   - Объекты Excel: `xlA As Excel.Application`, `xlW As Excel.Workbook`, `xlS As Excel.Worksheet`.  
   - Служебные переменные: `sqlString`, `yyyy`, переменные для подсчёта времени `dStart`, `dFinish`, `dDateDiff`.  
   - Класс `objRa_aCarrent As ra_a` — объект доменной модели ревизии, загружаемый через `ClassFactory.Ra_aReadKey`.

2. **Общий обработчик ошибок**  
   - В начале стоит `On Error GoTo ErrHandler`, а в конце процедуры — стандартный блок `ErrHandler:` с `MsgBox` и `Resume NormalExit`.  
   - Это задаёт общий каркас: любая ошибка в середине приводит к показу сообщения и выходу через `NormalExit`.

3. **Проверка: выбрана ли ревизия**  
   - `If IsNull(Me!adt_key) = False Then` … `End If`  
   - Вся дальнейшая логика находится внутри этого блока. Если `adt_key` пустой, процедура фактически ничего не делает.

4. **Инициализация логов и времени**  
   - Сброс текста результата: `Me!adt_results = ""`.  
   - Установка даты/времени запуска ревизии: `Me!adt_date = DateTime.Now`, `dStart = Me!adt_date`.  
   - Формирование первых записей в `adt_results` в HTML-формате (название ревизии, директория, отметка времени старта).

5. **Инициализация доступа к БД и загрузка объекта ревизии**  
   - `Set db = CurrentDb` — получение текущей базы Access/линка на MS SQL.  
   - Создание доменного объекта ревизии: `Set objRa_aCarrent = ClassFactory.Ra_aReadKey(Me!adt_key, db, Me!adt_results)`.  
   - Здесь начинается переход от чисто UI-логики формы к доменной модели ревизий.

6. **Определение базового года ревизии (yyyy)**  
   - Формирование `sqlString` с довольно сложным `JOIN` по `ra_dir`, `ra_a`, `ags_yyyy`, `ags_ra_period`, `ra_dir_s_p`.  
   - Открытие снимка `rst = db.OpenRecordset(sqlString, dbOpenSnapshot)`.  
   - Если есть записи — из `First(ags_yyyy.yyyy)` берётся год в переменную `yyyy`, иначе `yyyy = 0`.  
   - После этого `rst` закрывается.

7. **Очистка временной таблицы итогов ревизии**  
   - Выполняется `DELETE * FROM ra_aTtl` через временный `QueryDef`.  
   - Это подготовка хранилища для суммарных результатов текущего запуска ревизии.

8. **Подготовка набора файлов для обработки (`ra_f`)**  
   - `Set rst = db.OpenRecordset("ra_f", dbOpenSnapshot)` — чтение всех записей о файлах.  
   - Применение фильтра по директории ревизии: `filterStr = "af_dir = " & Me!adt_dir`, затем `rst.Filter = filterStr` и `Set rstFiltered = rst.OpenRecordset`.  
   - Дальнейшая работа идёт именно с `rstFiltered`.

9. **Проверка наличия файлов и определение директории**  
   - Если `rstFiltered.RecordCount > 0`, то:
     - Открывается `rstDir = db.OpenRecordset("select * from ra_dir order by key", dbOpenSnapshot)`.  
     - По `Me!adt_dir` находится запись директории, извлекается путь `strDir = !Dir`.  
     - В `adt_results` записывается сообщение о найденной директории.  
     - Через `Scripting.FileSystemObject` проверяется наличие папки `strDir` (`fso.FolderExists`).

10. **Создание Excel.Application и подготовка к перебору файлов**  
   - Если директория существует:
     - В `adt_results` добавляется запись о входе в директорию.  
     - Создаётся Excel: `Set xlA = CreateObject("Excel.Application")`.  
     - В лог пишется момент и сообщение "запуск Excel".
   - Затем выполняется цикл по `rstFiltered` (`Do Until rstFiltered.EOF`), внутри которого:
     - Определяется полный путь к файлу `strFile` в зависимости от `af_type` (некоторые типы уже содержат полный путь, другие требуют добавления `strDir & "\"").  
     - Проверяется флаг `af_execute` — брать ли файл в обработку.  
     - Через `FileSystemObject.FileExists` проверяется наличие файла; при успехе — логируется событие и выполняется `xlW = xlA.Workbooks.Open(filename:=strFile, ReadOnly:=True, UpdateLinks:=0)`.

На этом месте (после открытия книги Excel и проверки типа файла/листа) процедура начинает вызывать специализированные подпрограммы (`RAAudit_ralp`, `RAAudit_RA_RepPeriod` и др.), которые отвечают за разбор конкретных структур отчётов. Их детальный разбор будет в следующих подпунктах (1.4+, 2.x) при необходимости.

---

## 3. Классы VBA и их роль в выполнении ревизии

### 3.1. Класс ra_a (основной объект ревизии)

**Исходный файл:** `Class-Modules/ra_a.cls`

- **Назначение:** инкапсулирует состояние и поведение одной ревизии ("главной формы") в VBA-проекте.
- **Ключевые поля:**
  - `mlngRa_aKey As Long` — ключ ревизии (`adt_key`);
  - `mblnAdt_AddRA As Boolean` — флаг "добавлять ли служебные записи";
  - `mobgRa_aResult As TextBox` — ссылка на текстовый контрол для вывода результата (`adt_results`);
  - ссылки на дочерние объекты: `mRa_aAllAgentsChild As ra_aAllAgents`, `mRa_aAgFee23_06Child As ra_aAgFee23_06`.
- **Основные свойства/методы:**
  - `adt_key`, `blnAdt_AddRA` — геттеры для ключа и флага;
  - `obgRa_aResult` (Set/Get) — привязка текстового поля результата;
  - `ra_aAllAgentsChild`, `ra_aAllAgentsChildAdd(...)` — ленивое создание и кеширование объекта `ra_aAllAgents` через `ClassFactory.ra_aAllAgentsReadKey`;
  - `ra_aAgFee23_06Child`, `ra_aAgFee23_06ChildAdd(...)` — аналогично для `ra_aAgFee23_06`;
  - `year(db)` — вычисление года ревизии по связям `ra_dir_s_p` / `ags_ra_period` / `ags_yyyy`;
  - `riRa_aReadKey(...)` — инициализация объекта по ключу ревизии.
- **Использование в `btnAuditRun_Click`:**
  - `Set objRa_aCarrent = ClassFactory.Ra_aReadKey(Me!adt_key, db, Me!adt_results)` — загрузка "богатого" объекта ревизии перед запуском цикла по файлам.

### 3.2. Класс ra_aAllAgents (ревизия по всем агентам)

**Исходный файл:** `Class-Modules/ra_aAllAgents.cls`

- **Назначение:** реализует специализированный сценарий проверки/агрегации данных по всем агентам ("AllAgents"), связанный с файлами определённого типа (в `btnAuditRun_Click` — `af_type = 5`, лист "РАСЧЁТ").
- **Типичное использование:**
  - В `btnAuditRun_Click` при обработке файла типа 5:
    - `objRa_aCarrent.ra_aAllAgentsChildAdd rstFiltered!af_key, db` — загрузка/обновление дочернего объекта `ra_aAllAgents` для текущего файла;
    - `objRa_aCarrent.ra_aAllAgentsChild.Audit xlS, db, xlA` — запуск детальной проверки по листу Excel.
- **Роль:** выносит сложную логику анализа одного из сценариев ревизии ("все агенты") в отдельный класс, облегчая основной модуль формы.

### 3.3. Класс ra_aAgFee23_06 (агентские вознаграждения)

**Исходный файл:** `Class-Modules/ra_aAgFee23_06.cls`

- **Назначение:** инкапсулирует логику, связанную с расчётом/проверкой агентских вознаграждений по специфическому сценарию (23.06).
- **Использование:**
  - В `ra_a.cls` через свойства/методы `ra_aAgFee23_06Child` и `ra_aAgFee23_06ChildAdd(...)` — по аналогии с `ra_aAllAgents`.
  - Конкретные вызовы в `Form_ra_a.cls` относятся к отдельным процедурам (не к `btnAuditRun_Click` напрямую) и могут быть перенесены в более позднюю итерацию.

### 3.4. Выводы для новой архитектуры (Spring Boot) и место открытия Excel

- В нынешнем приложении нет необходимости воспроизводить COM/Access-модель 1:1, но полезно сохранить **структурное разделение**:
  - основной контекст ревизии;
  - отдельные компоненты/сервисы для специфических сценариев (AllAgents, AgFee23_06 и др.).
- В качестве аналогов для дальнейшей реализации предлагается:
  - `AuditExecutionContext` — Java-класс/DTO, содержащий ключ ревизии, директорию, год, флаг `addRa`, лог и служебные поля;
  - `AllAgentsAuditService` — Spring‑сервис для сценария "все агенты" (аналог `ra_aAllAgents.Audit`);
  - `AgFee2306AuditService` — Spring‑сервис для сценария агентских вознаграждений (аналог `ra_aAgFee23_06`).
- **Где открывать Excel/Workbook:**
  - Поскольку каждая вызываемая процедура работает **со своим Excel‑файлом** (а не с общим Workbook), логично открывать и закрывать книгу **внутри обработчика одного файла**, а не в оркестраторе:
    - оркестр (`AuditExecutionService`) отвечает за:
      - выбор ревизии, директории и периода;
      - построение списка файлов (`ra_f` / `af_type` / `af_execute` / `af_source`);
      - последовательный вызов обработчиков по каждому файлу (тип → соответствующий сервис).
    - обработчик файла (`AllAgentsAuditService`, обработчик RAAudit_ralp и т.п.) отвечает за:
      - открытие Excel‑книги по пути файла (в Java — `WorkbookFactory.create(path)`);
      - выбор нужных листов и вызов под‑процедур анализа;
      - **гарантированное закрытие** книги (и при необходимости Excel.Application) внутри себя.
  - Чтобы не дублировать код открытия/закрытия Excel, имеет смысл выделить общую утилиту (helper):
    - в VBA‑терминах — стандартная процедура, которая создаёт `Excel.Application`, открывает книгу, вызывает переданную под‑процедуру и закрывает ресурсы;
    - в Java‑терминах — helper вида `withWorkbook(path, action)` (обёртка вокруг Apache POI), которая создаёт `Workbook`, передаёт его в `action` и гарантированно закрывает в `finally`/try-with-resources.

---

## 4. Асинхронный запуск executeAudit и обновление "Хода загрузки"

### 4.1. Асинхронная оркестровка на backend

- Метод `executeAudit(auditId)` в новой архитектуре целесообразно реализовать как **асинхронный запуск ревизии**:
  - REST‑endpoint `POST /api/ra/audits/{id}/execute`:
    - сразу возвращает клиенту подтверждение старта (например, `{ jobId, status: "started" }`);
    - внутри запускает фоновую задачу (через Executor/`@Async`/очередь и т.п.), которая выполняет всю оркестровку:
      - загружает ревизию и директорию;
      - строит список файлов `ra_f`;
      - последовательно вызывает обработчики по каждому файлу;
      - по ходу работы обновляет `adt_results` и статус ревизии (например, поля `status`, `lastUpdated`).

> **Примечание о текущей реализации (по состоянию на 2026-03-17):** метод `executeAudit` пока выполняется **синхронно** на HTTP-потоке запроса — аннотации `@Async` и `@EnableAsync` ещё не добавлены. Это подтверждается логом: весь `AuditExecution` проходит на потоке `nio-8080-exec-N`, а POST возвращается только по завершении выполнения. Для заглушек (время ~900 мс) это незаметно, но станет критической проблемой при реальной обработке Excel-файлов. Добавление `@Async` запланировано в п. 7.2 `chat-plan-26-0311.md`.

### 4.2. Обновление "Хода загрузки" на backend

- Внутри фоновой задачи оркестратор должен **регулярно обновлять лог**:
  - перед стартом — записать в `adt_results` шапку (ревизия, директория, время старта);
  - после обработки каждого файла — добавлять строки вида:
    - "[время] Начата обработка файла X типа Y";
    - "[время] Файл X обработан (заглушка/успех/ошибка)";
  - по завершении — добавить итоговый блок (количество файлов, длительность, число ошибок).
- Эти изменения должны сохраняться в базе (в `ra_a.adt_results`) **по мере выполнения**, а не только в конце, чтобы фронтенд мог видеть прогресс.

### 4.3. Периодическое обновление UI (polling)

- На фронтенде (страница `AuditsView.vue`) при нажатии кнопки "Выполнить ревизию" рекомендуется:
  - вызвать `executeAudit(auditId)` и, получив подтверждение старта, сразу переключить вкладку на "Ход ревизии";
  - запустить **периодический опрос** backend (polling), например раз в 2–3 секунды:
    - вызывать `GET /api/ra/audits/{id}` или специальный `GET /api/ra/audits/{id}/status`;
    - обновлять отображаемый `adt_results` и статус ревизии в UI;
    - прекращать опрос, когда статус изменится на `completed` или `failed`.
- Такой подход, даже без WebSocket/SSE, позволяет пользователю видеть, что ревизия продвигается: лог в "Ходе загрузки" будет заполняться строками по мере работы фоновой задачи, а не только по её завершении.

В совокупности это даёт:
- **Асинхронный backend**, который выполняет тяжёлую обработку Excel и обновляет лог по мере выполнения;
- **Простой, но эффективный frontend‑polling**, который регулярно подтягивает обновлённый `adt_results` и показывает пользователю прогресс, снижая ощущение "зависания" операции.

---

## 5. Предлагаемая структура сервиса-оркестратора AuditExecutionService

### 5.1. Ответственность и границы сервиса

- **Назначение:**
  - Инкапсулировать полный сценарий выполнения ревизии (аналог `btnAuditRun_Click`) на стороне backend.
  - Работать **только в фоне** (асинхронно), вызываясь из обработчика `POST /api/ra/audits/{auditId}/execute` через Executor/`@Async`.
  - Не заниматься деталями анализа конкретных файлов/листов Excel — это задача специализированных обработчиков.

- **Основные задачи сервиса:**
  1. Загрузить ревизию и связанные данные (директория, флаг `adtAddRA`, статус и т.п.).
  2. Подготовить контекст выполнения (`AuditExecutionContext`).
  3. Получить и отфильтровать список файлов для ревизии (`ra_f` по `af_dir`, `af_execute`).
  4. Последовательно пройти по каждому файлу и делегировать обработку соответствующему сервису-заглушке.
  5. По ходу работы:
     - обновлять статус ревизии (`pending` → `running` → `completed`/`failed`);
     - инкрементально дописывать лог в `adt_results`.

### 5.2. Предлагаемый интерфейс и вспомогательные классы

```java
public class AuditExecutionContext {
    Long auditId;
    Long directoryId;
    String directoryPath;
    Integer year;           // yyyy из ags_yyyy/ags_ra_period
    Boolean addRa;          // аналог mblnAdt_AddRA / Me!adt_AddRA

    // Структурированная модель лога: записи в хронологическом порядке
    List<AuditLogEntry> entries;
    Instant startedAt;
    Instant lastUpdatedAt;

    // Удобные методы
    void appendEntry(AuditLogEntry entry);
    String buildHtmlLog(); // сборка HTML-документа для сохранения в adt_results
}

public class AuditLogEntry {
    Instant timestamp;
    AuditLogLevel level;   // INFO, SUCCESS, WARNING, ERROR, SUMMARY
    AuditLogScope scope;   // AUDIT, DIRECTORY, FILE, SHEET, SUMMARY
    String code;           // опционально: код/ключ сообщения
    String messageHtml;    // готовый HTML-фрагмент (минимальный web-формат)
    Map<String, String> meta; // filePath, sheetName и другие атрибуты
}

public interface AuditExecutionService {
    void executeAudit(Long auditId);
}
```

- Подразумевается, что реализация `AuditExecutionServiceImpl` будет использовать репозитории `RaARepository`, `RaFRepository`, `RaDirRepository` и др.

### 5.3. Последовательность действий внутри executeAudit(auditId)

Условный псевдокод, отражающий оркестровку:

```java
public void executeAudit(Long auditId) {
    // 1. Загрузка ревизии и подготовка контекста
    RaA audit = raARepository.findById(auditId)
        .orElseThrow(() -> new NotFoundException("Ревизия не найдена"));

    AuditExecutionContext ctx = contextFactory.fromAudit(audit); // заполняет auditId, dir, year, addRa и т.п.

    // 2. Инициализация статуса и лога
    statusUpdater.markRunning(auditId);
    logUpdater.initLog(ctx, audit);       // добавляет шапку в ctx.log и сохраняет в adt_results

    try {
        // 3. Получение файлов ревизии
        List<AuditFile> files = filesProvider.getFilesForAudit(auditId);

        for (AuditFile file : files) {
            logUpdater.beforeFile(ctx, file);      // "Начата обработка файла ..."

            // 4. Делегирование обработчику по типу файла
            switch (file.getType()) {
                case RALP:
                    ralpHandler.process(ctx, file);
                    break;
                case RA_REP_PERIOD:
                    repPeriodHandler.process(ctx, file);
                    break;
                case CN_PRDOC:
                    cnPrDocHandler.process(ctx, file);
                    break;
                case ALL_AGENTS:
                    allAgentsHandler.process(ctx, file);
                    break;
                default:
                    logUpdater.unknownType(ctx, file);
            }

            logUpdater.afterFile(ctx, file);       // "Файл обработан (заглушка/успех/ошибка)"
        }

        // 5. Финализация
        logUpdater.finishSuccess(ctx);
        statusUpdater.markCompleted(auditId);
    } catch (Exception e) {
        logUpdater.finishFailure(ctx, e);
        statusUpdater.markFailed(auditId, e);
    }
}
```

Здесь `logUpdater` отвечает за формирование HTML-строк в `ctx.log` и периодическую запись в `ra_a.adt_results`, а `statusUpdater` — за обновление полей статуса и `lastUpdated`.

### 5.4. Взаимодействие с обработчиками файлов

- Каждый обработчик (`RalpAuditHandler`, `AllAgentsAuditService`, и т.п.) получает только:
  - `AuditExecutionContext ctx`;
  - объект `AuditFile` (содержит `afKey`, путь к файлу, тип, источник и т.д.).
- Открытие/закрытие Excel-файла происходит **внутри обработчика** (через helper вокруг Apache POI):

```java
withWorkbook(file.getPath(), workbook -> {
    Sheet sheet = workbook.getSheet("...");
    if (sheet != null) {
        // реальная логика позже; пока заглушка
        ctx.appendLog("<P>Обработан лист ... (заглушка)</P>");
    } else {
        ctx.appendLog("<P>Лист ... не найден</P>");
    }
});
```

- На текущем этапе обработчики могут быть простыми заглушками, которые только пишут сообщения в лог, без изменения данных в БД.

Такой каркас `AuditExecutionService` даёт понятный аналог VBA‑процедуры `btnAuditRun_Click` и готов к поэтапному наполнению реальной логикой.

---

## 6. Типы сообщений лога и соответствие VBA

### 6.1. Основные категории сообщений

На основе анализа `btnAuditRun_Click` и связанных процедур можно выделить несколько устойчивых категорий сообщений, которые должны сохраняться в новом логе:

1. **Запуск и завершение ревизии (scope = AUDIT)**
   - Старт ревизии: название, идентификатор, время начала.
   - Успешное завершение: длительность, количество обработанных файлов, количество ошибок/предупреждений.
   - Аварийное завершение: сообщение об ошибке верхнего уровня.

2. **Работа с директорией (scope = DIRECTORY)**
   - Найдена/не найдена директория для ревизии.
   - Начало обработки файлов в директории.

3. **Обработка файлов (scope = FILE)**
   - Файл найден/не найден в файловой системе.
   - Файл помечен к выполнению/пропущен по настройке (`af_execute`).
   - Файл открыт/закрыт (успех/ошибка).
   - Для специальных сценариев (RALP, AllAgents, AgFee и др.) — начало/завершение обработки файла конкретного типа.

4. **Обработка листов (scope = SHEET)**
   - Поиск листа по списку допустимых имён (из `ra_ft_sn`).
   - Лист найден и выбран (с указанием номера файла, имени листа и типа листа).
   - Лист не найден или отсутствуют настройки периода/месяца для данного листа.

5. **Сводные блоки (scope = SUMMARY)**
   - Перечни «лишних» документов, найденных в `ogAgFeePnTest` и связанных таблицах.
   - Итоговые списки по результатам проверок (например, по агентским вознаграждениям).

6. **Ошибки конфигурации и доступа (scope = AUDIT / FILE / SHEET)**
   - Отсутствие директории, файлов, листов, настроек периода/месяца.
   - Ошибки при работе с БД или Excel (в дальнейшем — mapped из исключений Java).

### 6.2. Связь категорий с AuditLogEntry и HTML-представлением

Для каждой записи `AuditLogEntry` рекомендуется использовать следующую схему:

- `level`:
  - `INFO` — обычные шаги процесса (поиск директории, открытие файла, запуск Excel, найден лист).
  - `SUCCESS` — успешное завершение крупных этапов (файл/лист/ревизия обработаны без критических ошибок).
  - `WARNING` — ситуации, когда часть данных отсутствует или пропущена, но процесс может продолжаться (лист не найден, файл помечен как пропущенный и т.п.).
  - `ERROR` — ошибки, препятствующие корректной обработке конкретного файла/листа или всей ревизии.
  - `SUMMARY` — итоговые сводки (блоки с перечнями документов и агрегированной информацией).

- `scope`:
  - `AUDIT` — сообщения уровня всей ревизии (старт/финиш, общие ошибки).
  - `DIRECTORY` — сообщения, связанные с выбором и проверкой директории.
  - `FILE` — события вокруг одного Excel-файла (`ra_f`).
  - `SHEET` — события вокруг конкретного листа в книге.
  - `SUMMARY` — агрегированные выводы и списки.

- `code`:
  - Строковый идентификатор для статики, например: `AUDIT_START`, `DIR_NOT_FOUND`, `FILE_OPENED`, `FILE_SKIPPED`, `SHEET_NOT_FOUND`, `SUMMARY_OAGFEE_UNUSED`. Это позволит в будущем локализовать тексты и строить фильтры по типу сообщений.

- `meta`:
  - `filePath`, `fileType`, `sheetName`, `year`, `month`, `directoryPath` и другие технические атрибуты, которые могут понадобиться для фильтрации и расширенного UI.

#### HTML-формат и порядок отображения

- Внутренняя модель (`entries` в `AuditExecutionContext`) хранит записи в естественном хронологическом порядке (от старых к новым).
- Метод `buildHtmlLog()` формирует строку для `adt_results`, проходя по записям **в обратном порядке** (от новых к старым), чтобы во вкладке "Ход ревизии" новые события были видны пользователю сразу (без ручной прокрутки).
- Базовый HTML для одной записи предполагается в виде `div` с классами по уровню и области, например:

  ```html
  <div class="audit-log-entry audit-log-entry--info audit-log-entry--file">
    <span class="audit-log-entry__time">2026-03-11 16:45:12</span>
    <span class="audit-log-entry__text">Файл C:\path\file.xlsx обработан (заглушка RALP).</span>
  </div>
  ```

  или, на минимальном этапе, простой `<P>...</P>` с понятным текстом и без устаревших тегов `<font>`.

### 6.3. Группировка по файлам и узнаваемость для пользователя

- Тексты `messageHtml` должны сохранять смысл и структуру сообщений Access:
  - упоминание имён файлов и листов;
  - указание действия (найден, не найден, пропущен, обработан);
  - важные параметры (период, год, организация и т.п.).
- При этом вместо устаревших конструкций (`<font color=...>`) рекомендуется использовать нейтральный HTML и CSS-классы, а порядок сообщений в HTML для `adt_results` задавать так, чтобы новые события были видны сразу (новые сверху).

Такая классификация сообщений и HTML-формат позволяют:
- сохранить привычную информативность лога для пользователя, пришедшего из Access;
- задать основу для фильтров и сворачиваемых блоков на фронтенде (по `scope`, `level`, `code` и `meta`);
- постепенно наполнять обработчики файлов/листов сообщениями, не теряя ориентиры исходной VBA-логики.

Дополнительно для группировки по файлам:
- Рекомендуется использовать `scope = FILE` и метаданные `filePath` / `fileType` для всех сообщений, относящихся к одному файлу (`AuditFile`).
- При желании можно оборачивать сообщения одного файла в общий HTML-контейнер (group), чтобы во фронтенде по этим маркерам легко реализовать сворачивание/разворачивание блоков по файлам.

### 7. Паттерн отображения ошибок на клиенте

С учётом классификации сообщений лога и типов ошибок, на клиенте целесообразно использовать следующий паттерн:

1. **HTTP-ошибки запуска ревизии (`POST /api/ra/audits/{id}/execute`)**
   - Отображать немедленно через `Notify` с типом `negative` и кратким текстом ошибки (сетевой сбой, 5xx, 4xx и т.п.).
   - При необходимости записывать в лог ревизии отдельной записью `AuditLogEntry` с `level = ERROR`, `scope = AUDIT`, `code = EXECUTE_HTTP_ERROR`.

2. **Ошибки polling (`GET /status` / `GET /api/ra/audits/{id}`)**
   - При единичных сбоях (временная недоступность) показывать краткое уведомление `Notify` и повторять попытки с экспоненциальной паузой.
   - При устойчивой ошибке (несколько подряд неудачных запросов) отображать баннер/сообщение в области "Ход ревизии" и фиксировать ошибку в логе (`level = ERROR`, `code = STATUS_HTTP_ERROR`).

3. **Логические ошибки конфигурации/данных**
   - Ошибки уровня ревизии (отсутствует директория, нет файлов и т.п.) — отображать в логе как `ERROR`/`WARNING` с `scope = AUDIT` или `DIRECTORY` и, при необходимости, дублировать в UI баннером.
   - Ошибки уровня файла/листа (нет листа, нет настроек периода/месяца) — в первую очередь фиксировать в логе (`scope = FILE`/`SHEET`), а в UI дополнительно может быть счётчик/иконка состояния файла.

Таким образом, UI остаётся лёгким (основная детализация уходит в лог `adt_results`), а пользователь всё равно своевременно узнаёт о критичных проблемах через `Notify` и/или баннеры.

---

## 8. In-memory реестр статуса: `AuditExecutionRegistry`

### 8.1. Обоснование выбора

Статус выполнения ревизии (`RUNNING`, `COMPLETED`, `FAILED`) является техническим артефактом приложения, а не данными предметной области. Хранение его в `ags.ra_a` нарушило бы принцип чистоты доменных таблиц: если с той же БД будет работать другое приложение (например, Access), такое поле будет для него избыточным и непонятным.

Выбранное решение — **Spring-бин `AuditExecutionRegistry`** с `ConcurrentHashMap` в памяти JVM. Схема БД не меняется.

### 8.2. Структура

```java
@Component
public class AuditExecutionRegistry {
    private final ConcurrentHashMap<Long, AuditExecutionState> states = new ConcurrentHashMap<>();

    public void markRunning(long auditId)               { /* put RUNNING + startedAt */ }
    public void markCompleted(long auditId)              { /* update COMPLETED + finishedAt */ }
    public void markFailed(long auditId, String error)   { /* update FAILED + errorMessage */ }
    public Optional<AuditExecutionState> getState(long auditId) { return Optional.ofNullable(states.get(auditId)); }
    public boolean isRunning(long auditId)               { return getState(auditId).map(s -> s.status() == AuditStatus.RUNNING).orElse(false); }
}

public record AuditExecutionState(
    long auditId,
    AuditStatus status,   // RUNNING | COMPLETED | FAILED
    Instant startedAt,
    Instant finishedAt,
    String errorMessage
) {}
```

### 8.3. Жизненный цикл статуса

| Момент | Действие | Статус |
|---|---|---|
| До первого запуска | Запись в реестре отсутствует | `IDLE` (по умолчанию) |
| Начало `executeAudit` | `registry.markRunning(id)` | `RUNNING` |
| Успешное завершение (finally try) | `registry.markCompleted(id)` | `COMPLETED` |
| Ошибка (catch) | `registry.markFailed(id, msg)` | `FAILED` |

### 8.4. Интеграция с DTO и фронтендом

- `RaAMapper` при сборке `RaADto` запрашивает реестр и добавляет вычисляемое поле `adtStatus` (тип `String`). В БД поле не хранится.
- `RaARestController.executeAudit`: если `registry.isRunning(id)` — возвращает `409 Conflict`.
- Фронтенд получает `adtStatus` в составе обычного `GET /api/ra/audits/{id}` — дополнительный эндпоинт не нужен.
- Polling останавливается, когда `adtStatus === 'COMPLETED' || adtStatus === 'FAILED'`.
- При загрузке страницы: если `adtStatus === 'RUNNING'` — polling запускается автоматически.

### 8.5. Ограничения и эволюция

- **Ограничение:** при перезапуске сервера реестр очищается. Ревизия в статусе `RUNNING` после рестарта будет выглядеть как `IDLE`, а `adt_results` сохранит незавершённый лог. Приемлемо для текущего этапа.
- **Эволюция:** если в будущем понадобится история запусков или устойчивость к рестартам, реестр можно заменить отдельной таблицей-журналом (не `ags.ra_a`) без изменения контракта `RaADto`.

---

---

## 10. Таблица `ra_ImpNew` и запросы сверки (`ra_ImpNewQuRa`, `ra_ImpNewQuRc`)

### 10.1. Роль `ra_ImpNew` в процессе ревизии

`ra_ImpNew` — это **промежуточная таблица-буфер** (в Access — локальная, не связанная с SQL Server), которая используется исключительно в контексте `af_type = 5` (AllAgents, лист "Отчеты"). Её жизненный цикл:

1. **Перед чтением Excel**: таблица очищается (`DELETE * FROM ra_ImpNew`).
2. **Во время чтения Excel**: каждая строка-отчёт заносится в таблицу (`INSERT INTO ra_ImpNew`).
3. **После чтения Excel**: таблица используется как основа для двух запросов сверки с SQL Server.

Если `af_source = false` (поле `ra_f.af_source`) — Excel не читается и `ra_ImpNew` не обновляется. Сверка с БД выполняется всегда (по данным, которые были в таблице ранее, или по пустой таблице).

### 10.2. Полная структура `ra_ImpNew` (26 полей)

Все поля полностью восстановлены из процедуры `RaReadOfExcel` в `ra_aAllAgents.cls`:

| Поле | Тип | Excel-колонка (заголовок) | Примечание |
|------|-----|--------------------------|-----------|
| `rainRow` | Integer | — | Номер строки в Excel (идентификатор для сверки) |
| `rainRaNum` | String | "№ ОА" | **Якорная колонка** — по ней ищутся все остальные |
| `rainRaDate` | Date / Null | "Дата ОА" | |
| `rainSign` | String | "Признак" | "ОА" или "ОА прочие" |
| `rainCstAgPnStr` | String | "Код стройки" | Строковый код; разрешается в `cstapKey` в запросе |
| `rainCstName` | String | "Наименование стройки" | Информационное поле |
| `rainSender` | String | "Агент" | Строковое имя; разрешается в `ogKey` в запросе |
| `rainTtl` | Decimal / Null | "Всего с НДС" | `NumericOrNull` — строки → NULL |
| `rainWork` | Decimal / Null | "СМР" | |
| `rainEquip` | Decimal / Null | "Оборудование" | |
| `rainOthers` | Decimal / Null | "Прочие" | |
| `rainArrivedNum` | String | "Поступило (№ письма)" | Заголовок: `"Поступило " & vbLf & "(№ письма)"` |
| `rainArrivedDate` | Date / Null | "Поступило (Дата письма)" | |
| `rainArrivedDateFact` | Date / Null | "Поступило (Фактическая дата)" | |
| `rainReturnedNum` | String | "Возвращен на доработку (№ письма) " | Trailing space в заголовке! |
| `rainReturnedDate` | Date / Null | "Возвращен на доработку (дата письма)" | |
| `rainReturnedReason` | String | "Причина возврата" | |
| `rainSendNum` | String | "Направлен в Бухгалтерию (№ СЗ)" | |
| `rainSendDate` | Date / Null | "Направлен в Бухгалтерию (дата СЗ)" | |
| `rainUnit` | String | "Отдел Управления" | |
| `rainRaSheetsNumber` | Integer / Null | "Кол-во листов ОА" | |
| `rainTitleDocSheetsNumber` | Integer / Null | "Кол-во листов ПУД" | |
| `rainPlanNumber` | Integer / Null | "План кол-во" | |
| `rainPlanDate` | Date / Null | "План дата" | |
| `rainRaSignOfTest` | String | "Признак проверки ОА" | |
| `rainRaSendedSum` | Decimal / Null | "Сумма переданных ОА" | |
| `rainRaReturnedSum` | Decimal / Null | "Cумма возвращенных ОА" | Опечатка в заголовке Excel: "Cумма" (латинская C) |

**Важное замечание:** из 26 полей только `rainRow`, `rainRaNum`, `rainCstAgPnStr`, `rainSender`, `rainSign` являются обязательными для сверки. Остальные — данные для создания/обновления записей в `ags_ra` и `ags_ra_change`.

### 10.3. Поля, возвращаемые `ra_ImpNewQuRa` (сверка с `ags_ra`)

Все поля инферированы из процедур `AuditRaCreateNew` и `AuditRaEdit` в `ra_aAllAgents.cls`:

**Из `ra_ImpNew` (передаются напрямую):**
- `rainRow` — номер строки Excel
- `rainRaNum` — номер отчёта

**Разрешённые ключи (lookup-результаты):**
- `periodKey` — FK на `ags_ra_period` (разрешён из `rainRaDate` + год ревизии)
- `cstapKey` — FK на `cstAgPn` (разрешён из `rainCstAgPnStr`)
- `ogKey` — FK на `og` (разрешён из `rainSender`)
- `rainSign` — передаётся как есть ("ОА" / "ОА прочие")

**Результат сверки с `ags_ra`:**
- `ra_key` — FK на `ags_ra` (NULL = запись не найдена в БД)
- `ras_key` — FK на `ags_ra_sm` (суммы отчёта; NULL = нет суммы)
- `rs` — Boolean: `TRUE` = все поля совпадают

**Поколонные флаги совпадения (Boolean):**
- `rsArrv`, `rsArrvDate`, `rsArrvDateFact` — письмо и даты поступления
- `rsRetn`, `rsRetnDate`, `rsRetnRsn` — письмо возврата, дата, причина
- `rsSent`, `rsSentDate` — письмо направления и дата
- `rsSender` — отправитель (организация)
- `rsDate` — дата отчёта
- `rsSum` — суммы (агрегатный флаг)
- `rsTtl`, `rsWork`, `rsEquip`, `rsOthers` — поколонные флаги сумм

**Значения из источника (для вывода расхождений и создания/обновления):**
- `exArrv`, `exArrvDate`, `exArrvDateFact`
- `exRetn`, `exRetnDate`, `exRetnRsn`
- `exSent`, `exSentDate`
- `exSender` — числовой ключ организации (уже разрешён запросом)
- `exDate` — дата отчёта из Excel
- `exTtl`, `exWork`, `exEquip`, `exOthers` — суммы из Excel

### 10.4. Поля, возвращаемые `ra_ImpNewQuRc` (сверка с `ags_ra_change`)

Инферированы из процедур `AuditRcCreateNew` и `AuditRcEdit`:

Включает все поля `ra_ImpNewQuRa` плюс:
- `rac_key` — FK на `ags_ra_change` (NULL = изменение не найдено)
- `raсs_key` — FK на `ags_ra_change_sm` (суммы изменения)
- `ra_key` — FK на родительский `ags_ra` (отчёт, к которому изменение)
- `rcPeriod` — FK на `ags_ra_period` (период изменения)
- `num` — номер изменения

**Важно:** SQL `ra_ImpNewQuRc` должен JOIN-ить `ra_ImpNew` с данными изменений (`ags_ra_change`) по совместному ключу `(ra_key, num, rcPeriod)` или аналогичному.

### 10.5. Шесть операций сверки в `Audit()`

Метод `Audit()` выполняет **шесть последовательных операций** в двух блоках:

**Блок A — основные отчёты (`ags_ra`):**

| # | Набор данных | Условие | Действие |
|---|-------------|---------|---------|
| A1 | `ra_ImpNewQuRa` | все записи | Лог: "Всего найдено отчётов: N" |
| A2 | `ra_ImpNewQuRa WHERE ra_key IS NULL` | Excel-записи, не найденные в БД | Лог + `AuditRaCreateNew` (если `addRa=true`) |
| A3 | `ra_ImpNewQuRa WHERE ra_key IS NOT NULL AND rs = false` | найдены, но есть расхождения | Лог + `AuditRaEdit` (если `addRa=true`) |
| A4 | `ags_ra_period JOIN ags_ra LEFT JOIN ra_ImpNewQuRa WHERE rainRow IS NULL AND Year(period)=yyyy` | в БД есть, в Excel нет | Лог + `raRaExr.raDelete` (если `addRa=true`) |

**Блок B — изменения отчётов (`ags_ra_change`):**

| # | Набор данных | Условие | Действие |
|---|-------------|---------|---------|
| B1 | `ra_ImpNewQuRc` | все записи | Лог: "Всего найдено изменений: N" |
| B2 | `ra_ImpNewQuRc WHERE rac_key IS NULL` | Excel-изменения, не найденные в БД | Лог + `AuditRcCreateNew` (если `addRa=true`) |
| B3 | `ra_ImpNewQuRc WHERE rac_key IS NOT NULL AND rs = false` | найдены, но есть расхождения | Лог + `AuditRcEdit` (если `addRa=true`) |
| B4 | `ags_ra_change INNER JOIN ra_ImpNewQuRc WHERE rainRow IS NULL AND Year(period)=yyyy` | в БД есть, в Excel нет | Лог + `rcRcExr.rcDelete` (если `addRa=true`) |

### 10.6. Маппинг `af_type` → обработчик → лист Excel → путь файла

Полностью восстановлен из `btnAuditRun_Click` (`Form_ra_a.cls`):

| `af_type` | Тип файла (описание) | Лист(ы) | Обработчик VBA | Путь |
|-----------|---------------------|---------|---------------|------|
| 1 | РАСЧЁТ (расчётный лист) | через `ra_ft_sn` | `RAAudit_RA_RepPeriod` | `strDir + "\" + af_name` |
| 2 | Хранение и стройконтроль | "ХрСтрКнтрл" | `RAAudit_cn_PrDoc` | `af_name` (уже полный) |
| 3 | Аренда земли | "Аренда_Земли" + "учет_аренды" | `RAAudit_ralp` + `RAAudit_ralpSum` | `af_name` (уже полный) |
| 4 | Агентское вознаграждение | через `ra_ft_s`/`ra_ft_st`/`ra_ft_sn` | `RAAudit_RA_RepPeriod` + `ra_aAgFee23_06` | `strDir + "\" + af_name` |
| 5 | Отчёты всех агентов | "Отчеты" | `ra_aAllAgents.Audit` | `af_name` (уже полный) |
| 6 | Агентское вознаграждение 23-0628 | через `ra_ft_s`/`ra_ft_st`/`ra_ft_sn` | `ra_aAgFee23_06` | `af_name` (уже полный) |

**Правило определения полного пути:**
- Типы 2, 3, 5, 6 → `af_name` содержит **абсолютный путь** (имя файла уже включает директорию).
- Типы 1, 4 → `strDir + "\" + af_name` — к имени добавляется директория ревизии.

### 10.7. Открытые вопросы (требуют получения из Access VM)

| Вопрос | Способ получения |
|--------|-----------------|
| SQL-определение `ra_ImpNewQuRa` | `Debug.Print CurrentDb.QueryDefs("ra_ImpNewQuRa").SQL` в Access |
| SQL-определение `ra_ImpNewQuRc` | `Debug.Print CurrentDb.QueryDefs("ra_ImpNewQuRc").SQL` в Access |
| Значения `af_type` для всех реальных файлов | `SELECT DISTINCT af_type, COUNT(*) FROM ags.ra_f GROUP BY af_type` через DBHub |
| Как именно `rainCstAgPnStr` резолвится в `cstapKey` | Вытекает из SQL `ra_ImpNewQuRa` |
| Как именно `rainSender` резолвится в `ogKey` | Вытекает из SQL `ra_ImpNewQuRa` |

### 10.8. Архитектурное решение: `ra_ImpNew` и изоляция сеансов

**Принято:** `ra_ImpNew` создаётся как таблица в SQL Server.

**Обоснование:** к концу года файл Excel содержит 10–20 тысяч записей с высоким риском ошибок разного рода. Факт переноса данных из Excel в реляционную таблицу — ценный результат сам по себе. После переноса данные в `ra_ImpNew` могут быть проверены, исправлены и сохранены через SQL-клиент (DBHub/SSMS) независимо от дальнейшей обработки.

**Проблема изоляции при конкурентных запусках:**

Использование `adt_key` (FK на ревизию) как изолятора недостаточно: два пользователя могут одновременно запустить одну и ту же ревизию — они получат одинаковый `adt_key`, данные смешаются. Также `DATETIME` как суррогатный ключ сеанса — ненадёжен (теоретические коллизии, неудобен для JOIN).

**Решение: таблица `ra_execution` как изолятор сеанса**

```sql
CREATE TABLE ags.ra_execution (
    exec_key         BIGINT IDENTITY(1,1) PRIMARY KEY,
    adt_key          INT NOT NULL,                      -- FK → ra_a.adt_key
    exec_started_at  DATETIME2 NOT NULL,
    exec_finished_at DATETIME2 NULL,
    exec_status      VARCHAR(20) NOT NULL DEFAULT 'RUNNING',  -- RUNNING / COMPLETED / FAILED
    exec_error       NVARCHAR(MAX) NULL
);
```

- `ra_ImpNew` добавляет колонку `rain_exec_key BIGINT NOT NULL` (FK → `ra_execution.exec_key`)
- Каждый запуск ревизии создаёт новую строку в `ra_execution`, получая уникальный `exec_key`
- Два одновременных запуска одной ревизии → два разных `exec_key` → полная изоляция данных
- `DELETE FROM ra_ImpNew WHERE rain_exec_key = :execKey` — очистка строго своего сеанса

**Дополнительный бонус: замена `AuditExecutionRegistry`**

`ra_execution` является **постоянным хранилищем статуса выполнения** и заменяет (или дополняет) in-memory `AuditExecutionRegistry`. Это устраняет ограничение §8.5: статус `RUNNING/COMPLETED/FAILED` теперь переживает рестарт сервера. При перезапуске зависшие сеансы (`exec_status = 'RUNNING'`, `exec_finished_at IS NULL`) могут быть помечены как `FAILED` автоматически при старте.

`AuditExecutionRegistry` может быть:
- Удалён: статус читается напрямую из `ra_execution` через DAO
- Или сохранён как кеш, синхронизируемый с `ra_execution` при старте приложения

### 10.9. Асинхронное выполнение ревизии (`@Async`)

**Принято:** `executeAudit` выполняется асинхронно.

**Обоснование:** обработка 10–20 тыс. строк Excel с INSERT в `ra_ImpNew` и последующими JOIN-сверками с `ags_ra`/`ags_ra_change` займёт от десятков секунд до нескольких минут. Синхронное выполнение на HTTP-потоке приведёт к таймауту клиента и деградации приложения.

**Реализация:**
- `@EnableAsync` на конфигурационном классе (или на `FemsqWebApplication`)
- `@Async` на методе `AuditExecutionServiceImpl.executeAudit`
- GraphQL mutation `executeAudit` возвращает `{started: true, alreadyRunning: false}` немедленно
- Фронтенд запускает polling (`getAuditById` каждые 3 сек.) для отображения прогресса
- `AuditExecutionRegistry` (или `ra_execution`) обеспечивает защиту от двойного запуска (`isRunning` → `409` / `alreadyRunning: true`)

---

## 9. Граница анализа: что остаётся для следующего чата

Данный документ охватывает:
- высокоуровневую структуру `btnAuditRun_Click` (разделы 1–3);
- архитектурные решения для оркестратора, статуса и polling (разделы 4–8).

**Детальный анализ VBA-логики обработчиков файлов** выносится в документ следующего чата (`chat-plan-26-XXXX-excel-processing.md`). Для него потребуется:

- Полный разбор `RAAudit_ralp`: работа с листом «РАСЧЁТ», таблицы `ra_ft_sn`, `ogAgFeePnTest`, логика поиска строк/столбцов.
- Разбор `RAAudit_RA_RepPeriod`: сопоставление периодов (`ags_ra_period`), обработка листов по месяцам.
- Разбор `TotalValuesFind` и логики записи итогов в `ra_aTtl`.
- Карта соответствия: VBA-процедура → Java-класс (`AuditFileProcessor`) → метод Apache POI.
- Детальный план наполнения `RalpAuditFileProcessor` и `AllAgentsAuditFileProcessor` реальной логикой.
