# Архитектура Java-процессоров файлов ревизии

**Дата создания:** 2026-03-19
**Последнее обновление:** 2026-03-19
**Версия:** 0.6.0
**Автор:** Александр

---

## 1. Назначение документа

Документ фиксирует **архитектурные решения Java-реализации** обработки Excel-файлов в рамках ревизии (`AuditExecutionService`). Он не дублирует анализ VBA-кода — это задача `ra-audit-btnAuditRun-analysis.md`. Здесь описывается, **как** мы переносим логику Access/VBA в Spring Boot.

### Связанные документы
- **Анализ VBA/оригинальной логики:** `docs/development/notes/analysis/ra-audit-btnAuditRun-analysis.md`
- **Чат-план реализации:** `docs/development/notes/chats/chat-plan/chat-plan-26-0319-excel-processing.md`
- **VBA-исходник формы:** `docs/project/proposals/vba-analysis/VBA-Code-Export/Form-Modules/Form_ra_a.cls`
- **VBA-исходник AllAgents:** `docs/project/proposals/vba-analysis/VBA-Code-Export/Class-Modules/ra_aAllAgents.cls`

---

## 2. Иерархия классов-процессоров

### 2.1. Обоснование

В VBA обработка каждого типа файла — это отдельная процедура или класс, вызываемая из монолитного `btnAuditRun_Click`. Между ними нет формальной иерархии. В Java мы вводим явную иерархию по **Template Method Pattern**, чтобы:
- вынести общий lifecycle (логирование, открытие/закрытие книги, обработка ошибок) в базовый класс;
- устранить VBA-баги (файл открывается даже когда `af_source = false`);
- дать возможность разрабатывать процессоры для разных типов файлов параллельно, независимо.

### 2.2. Диаграмма иерархии

```
interface AuditFileProcessor
│   process(ctx: AuditExecutionContext, file: AuditFile): void
│
└── abstract AbstractAuditFileProcessor  [implements AuditFileProcessor]
    │   # Финальный template method process():
    │   #   1. ctx.logFileStart(file)
    │   #   2. if af_source → readFromExcel(ctx, file, filePath)
    │   #   3.               (workbook НЕ открывается если af_source = false)
    │   #   4. reconcileWithDb(ctx, file)
    │   #   5. ctx.logFileEnd(file)
    │   #
    │   # abstract readFromExcel(ctx, file, filePath)
    │   # abstract reconcileWithDb(ctx, file)
    │   # protected checkSheetExists(workbook, sheetName): boolean
    │
    ├── abstract AbstractFixedSheetProcessor  [extends AbstractAuditFileProcessor]
    │   │   # Для типов с одним жёстко заданным именем листа
    │   │   # readFromExcel: открывает workbook → ищет лист → processSheet()
    │   │   #
    │   │   # abstract getSheetName(): String
    │   │   # abstract processSheet(ctx, file, sheet)
    │   │
    │   ├── AllAgentsAuditFileProcessor       (af_type = 5, лист "Отчеты")
    │   └── CnPrDocAuditFileProcessor         (af_type = 2, лист "ХрСтрКнтрл")
    │
    ├── RalpAuditFileProcessor                (af_type = 3)
    │       # Два листа с разными обработчиками: "Аренда_Земли" + "учет_аренды"
    │       # Не укладывается в AbstractFixedSheetProcessor → наследует напрямую
    │       # readFromExcel: открывает workbook один раз, обрабатывает оба листа
    │
    └── AgFee2306AuditFileProcessor           (af_type = 6)
            # Динамическое обнаружение листов через ra_ft_s / ra_ft_sn
            # Дополнительный guard: ctx.getAuditType() == 1
            # readFromExcel: запрос ra_ft_s → перебор листов → AgFee_Month + AgFee23_06 handler
```

### 2.3. Пакетная структура

```
com.femsq.web.audit
├── AuditFileProcessor              (интерфейс)
├── AuditExecutionContext           (контекст запуска ревизии)
├── AuditFile                       (DTO: af_key, af_name, af_type, af_source, af_execute, af_temp_path)
│
├── base
│   ├── AbstractAuditFileProcessor  (абстрактный базовый, template method)
│   └── AbstractFixedSheetProcessor (абстрактный промежуточный, для типов 2 и 5)
│
├── excel
│   ├── AuditExcelReader            (withWorkbook helper, Apache POI)
│   ├── AuditExcelColumnLocator     (поиск колонок по заголовкам)
│   ├── AuditExcelCellReader        (типизированное чтение ячеек)
│   └── AuditExcelException         (runtime-исключение)
│
└── processors
    ├── AllAgentsAuditFileProcessor  (af_type = 5)
    ├── CnPrDocAuditFileProcessor    (af_type = 2)
    ├── RalpAuditFileProcessor       (af_type = 3)
    └── AgFee2306AuditFileProcessor  (af_type = 6)
```

---

## 3. Жизненный цикл `process()` — Template Method

```java
// AbstractAuditFileProcessor
public final void process(AuditExecutionContext ctx, AuditFile file) {
    ctx.logFileStart(file);
    try {
        if (file.isAfSource()) {
            FileAccess access = resolveFileAccess(file);  // в AuditExecutionServiceImpl
            if (access == null) {
                ctx.appendLog(WARN, "Файл недоступен ни напрямую, ни через загрузку — пропуск: " + file.getAfName());
            } else {
                try {
                    readFromExcel(ctx, file, access.path());
                } finally {
                    if (access.isTemp()) {
                        tempFileService.deleteQuietly(access.path());  // только для temp-файла
                    }
                }
            }
        }
        reconcileWithDb(ctx, file);
    } catch (AuditExcelException e) {
        ctx.appendLog(ERROR, "Ошибка при чтении Excel: " + e.getMessage());
    } catch (Exception e) {
        ctx.appendLog(ERROR, "Непредвиденная ошибка при обработке файла: " + e.getMessage());
        // ошибка одного файла НЕ останавливает обработку остальных
    }
    ctx.logFileEnd(file);
}

// AuditExecutionServiceImpl
// record FileAccess(String path, boolean isTemp) {}
private FileAccess resolveFileAccess(AuditFile file) {
    // Режим 1 — прямой доступ бэкенда: af_name доступен на сервере (общий диск, та же машина)
    if (Files.exists(Path.of(file.getAfName()))) {
        return new FileAccess(file.getAfName(), false);
    }
    // Режим 2 — загруженный temp-файл: фронтенд передал файл заранее
    if (file.getAfTempPath() != null) {
        return new FileAccess(file.getAfTempPath(), true);
    }
    return null;  // файл недоступен ни одним из способов
}

// AbstractFixedSheetProcessor
@Override
protected void readFromExcel(AuditExecutionContext ctx, AuditFile file, String filePath) {
    AuditExcelReader.withWorkbook(filePath, workbook -> {
        Sheet sheet = workbook.getSheet(getSheetName());
        if (sheet == null) {
            ctx.appendLog(WARN, "Лист \"" + getSheetName() + "\" не найден в файле " + file.getAfName());
            return;
        }
        processSheet(ctx, file, sheet);
    });
}
```

---

## 4. Работа с Excel-файлами: от пользователя до обработчика

### 4.1. Режимы доступа к файлу

`ra_f.af_name` — путь к файлу, **задаётся пользователем вручную** в перечне файлов директории ревизии. Пользователь отвечает за корректность пути. Специальная кнопка «Загрузить» **отсутствует**.

В зависимости от развёртывания возможны два режима:

| Режим | Условие | Поведение бэкенда | `af_temp_path` |
|-------|---------|-------------------|----------------|
| **Прямой** | Файл по пути `af_name` доступен бэкенду напрямую (общий сетевой диск, та же машина) | Читает `af_name` напрямую | NULL (загрузка не нужна) |
| **Загрузка** | Файл доступен только пользователю (локальная машина, недоступная серверу) | Читает `af_temp_path` (загружен фронтендом) | Временный путь, очищается после обработки |

`resolveFileAccess()` в `AuditExecutionServiceImpl` обрабатывает оба режима прозрачно — см. §3. Процессоры получают готовый путь и не знают, каким способом он получен.

### 4.2. Поток выполнения

**Режим прямого доступа** (бэкенд видит файл напрямую):

```
Пользователь            Фронтенд                       Бэкенд
     │                      │                               │
     ├─ нажимает ────────────>│ GET /api/ra/files/{afKey}    │
     │  "Выполнить           │   /accessible                │
     │   ревизию"            │──────────────────────────────>│ Files.exists(af_name)
     │                       │<── {accessible: true} ────────│
     │                       │                               │
     │                       │ (загрузка НЕ нужна)           │
     │                       │                               │
     │                       │ mutation executeAudit(id)     │
     │                       │──────────────────────────────>│ @Async:
     │<── {started:true} ────│<── {started:true} ────────────│  resolveFileAccess → af_name
     │   polling... ─────────>│                              │  readFromExcel(af_name)
     │<── {adtStatus} ───────│<─────────────────────────────>│  reconcileWithDb()
```

**Режим загрузки** (файл только на машине пользователя):

```
Пользователь            Фронтенд                       Бэкенд
     │                      │                               │
     ├─ нажимает ────────────>│ GET /api/ra/files/{afKey}    │
     │  "Выполнить           │   /accessible                │
     │   ревизию"            │──────────────────────────────>│ Files.exists(af_name) → false
     │                       │<── {accessible: false} ───────│
     │                       │                               │
     │                       │ Фронтенд читает файл          │
     │                       │ по af_name (browser File API) │
     │                       │                               │
     │                       │ Файл не найден?               │
     │<── ошибка ────────────│ → показать сообщение,         │
     │                       │   ревизия НЕ запускается      │
     │                       │                               │
     │                       │ Файл найден:                  │
     │                       │ POST /api/ra/files/{afKey}    │
     │                       │   /content  (multipart)       │
     │                       │──────────────────────────────>│ сохр. temp
     │                       │<── {ok} ──────────────────────│ обновл. af_temp_path
     │                       │                               │
     │                       │ mutation executeAudit(id)     │
     │                       │──────────────────────────────>│ @Async:
     │<── {started:true} ────│<── {started:true} ────────────│  resolveFileAccess → af_temp_path
     │   polling... ─────────>│                              │  readFromExcel(af_temp_path)
     │<── {adtStatus} ───────│<─────────────────────────────>│  delete temp file
     │                       │                               │  reconcileWithDb()
```

### 4.3. Поля `ra_f`, задействованные в потоке

| Поле | Назначение |
|------|-----------|
| `af_name` | Путь к файлу — задаётся пользователем, используется бэкендом напрямую в прямом режиме |
| `af_execute` | Флаг «рассматривать файл» |
| `af_source` | Флаг «читать из Excel-источника» (false = использовать данные прошлого запуска) |
| `af_temp_path` | Серверный путь к temp-файлу (только в режиме загрузки); NULL в прямом режиме |

### 4.4. REST-эндпоинты

Работа с бинарными файлами — **осознанное исключение** из правила GraphQL-first (аналогично `reports-api.ts`):

```
GET    /api/ra/files/{afKey}/accessible  — проверить, доступен ли файл бэкенду напрямую
POST   /api/ra/files/{afKey}/content     — загрузить файл (multipart/form-data); только в режиме загрузки
DELETE /api/ra/files/{afKey}/content     — удалить temp-файл вручную (опционально)
```

Это единственные REST-эндпоинты в домене ревизий. Все прочие операции — через GraphQL.

### 4.5. Поведение при различных условиях

| Условие | Результат |
|---------|-----------|
| `af_source = false` | Файл не нужен; `readFromExcel` не вызывается |
| Прямой режим: `af_name` доступен бэкенду | Читается напрямую; загрузка не производится |
| Режим загрузки: файл найден фронтендом | Загружается автоматически при запуске ревизии |
| Режим загрузки: файл **не найден** фронтендом | Ревизия **не запускается**; пользователь получает сообщение об ошибке |
| `af_source = true`, файл недоступен ни одним способом (при старте бэкенда) | Лог `WARN`, файл пропускается, обработка остальных файлов продолжается |

---

## 5. Маппинг VBA-процедур → Java-классы

| `af_type` | VBA-процедура / класс | Java-класс | Лист(ы) |
|-----------|----------------------|------------|---------|
| 2 | `RAAudit_cn_PrDoc` | `CnPrDocAuditFileProcessor` | `ХрСтрКнтрл` |
| 3 | `RAAudit_ralp` + `RAAudit_ralpSum` | `RalpAuditFileProcessor` | `Аренда_Земли`, `учет_аренды` |
| 5 | `ra_aAllAgents.Audit()` | `AllAgentsAuditFileProcessor` | `Отчеты` |
| 6 | `RAAudit_AgFee_Month` + `ra_aAgFee23_06.Audit()` | `AgFee2306AuditFileProcessor` | динамически через `ra_ft_s`/`ra_ft_sn` |
| 1, 4 | `RAAudit_RA_RepPeriod`, `RAAudit_AgFee_Month` | **не реализуются** (устаревшие) | — |

**Примечание по типу 6:** в VBA обработка типов 4 и 6 частично совпадает (`RAAudit_AgFee_Month` вызывается для обоих в строке 341). Тип 6 — это **не продолжение** типа 4, а самостоятельный сценарий. В Java они полностью разделены: тип 4 пропускается, тип 6 — отдельный процессор с собственной логикой.

**Примечание по типу 6 и `adt_type`:** в VBA обработка листов для типов 1, 4, 6 обёрнута в `If Me!adt_type = 1 Then` (проверяется тип **ревизии**, не файла). `AgFee2306AuditFileProcessor` должен воспроизвести это: `if (ctx.getAuditType() != 1) { log WARN; return; }`.

---

## 6. Промежуточные таблицы и сопоставление колонок

### 6.1. Промежуточные таблицы (staging) в VBA

Все staging-таблицы именуются по единому правилу: префикс `ra_stg_` + короткий доменный идентификатор. Все таблицы **созданы на сервере** 2026-03-19, конфигурация `ags.ra_sheet_conf` заполнена.

| `af_type` | Лист Excel | Старое имя (Access) | Новое имя (SQL Server) | Статус |
|-----------|-----------|--------------------|-----------------------|--------|
| 2 | `ХрСтрКнтрл` | `cn_PrDocImp` | `ags.ra_stg_cn_prdoc` | ✅ создана |
| 3 | `Аренда_Земли` | `ralpRaAuTest` | `ags.ra_stg_ralp` | ✅ создана |
| 3 | `учет_аренды` | `ralpRaSumTest` | `ags.ra_stg_ralp_sm` | ✅ создана |
| 5 | `Отчеты` | `ra_ImpNew` | `ags.ra_stg_ra` | ✅ создана |
| 6 | динамические | `ags_ogAgFeePnTest` | `ags.ra_stg_agfee` | ✅ создана |

Дополнительно создана **`ags.ra_execution`** (управление сессиями запуска ревизии, 2026-03-19) — на неё ссылаются все staging-таблицы через `*_exec_key`.

> Внутренние имена полей (`rain_*`, `cnpd_*`, `ralprt_*`, `ralprs_*`, `oafpt_*`) соответствуют именам Access. Тип 6 ранее использовал `ags.ogAgFeePnTest` через linked server из Access; теперь — полноценная SQL Server-таблица.
### 6.2. Механизмы сопоставления колонок в VBA

| `af_type` | Механизм | Оценка |
|-----------|---------|--------|
| 2 | `FindOffset(xlS, "Имя колонки", startColumn)` — поиск по имени, возвращает смещение от якоря `"Номер первичного документа"` | Имена колонок явные, но offset-арифметика сохраняется |
| 3 (`Аренда_Земли`) | Якорь `"№ отчета"`, затем жёсткие числовые смещения: `r.Offset(0, -15)`, `r.Offset(0, -13)` и т. д. | ⚠️ Имена колонок Excel в коде **отсутствуют** |
| 3 (`учет_аренды`) | Якорь `"Наименование Агента"`, затем `r.Offset(0, +1)` … `r.Offset(0, +5)` | ⚠️ Имена колонок Excel в коде **отсутствуют** |
| 5 | `CellFind(findStr="Имя колонки")` для каждой колонки независимо — возвращает номер колонки | Лучший подход: колонки ищутся по именам, порядок не важен |
| 6 | `myArray(N, 1) = "Имя в Excel"; myArray(N, 2) = "поле_БД"` → передаётся в `ExcelToTable()` | Хороший подход: явный маппинг в массиве; **прямой аналог таблицы в БД** |

**Вывод:**
- Тип 6 реализует ровно то, что мы хотим перенести в SQL Server: явный двусторонний маппинг имён.
- Тип 5 использует поиск по имени, но маппинг «рассыпан» по коду (один `CellFind` — один блок).
- Тип 2 ищет по именам, но остаток логики — числовые смещения.
- Тип 3: имена колонок Excel неизвестны из кода; их необходимо определить из реальных исходных файлов перед реализацией.

### 6.3. Колонки типа 6 из VBA-массива (`myArray` в `ra_aAgFee23_06.cls`, метод `AuditFillFromSource`)

| Имя в Excel | Поле `ogAgFeePnTest` |
|------------|---------------------|
| `№ Акта` | `oafptOafName` |
| `Дата Акта` | `oafptOafDate` |
| `Код стройки` | `oafptPnCstAgPn` |
| `Сумма` | `oafptTtl` |
| `Поступило (№ письма)` | `oafptArrivedNum` |
| `Поступило (Дата письма)` | `oafptArrivedDate` |
| `Направлен в Бухгалтерию (№ СЗ)` | `oafptSendedNum` |
| `Направлен в Бухгалтерию (дата СЗ)` | `oafptSendedDate` |
| `Возвращен на доработку (№ письма)` | `oafptReturnedNum` |
| `Возвращен на доработку (дата письма)` | `oafptReturnedDate` |
| `Причина возврата` | `oafptReturnedReason` |
| `Отдел Управления` | `oafptUnit` |
| `Кол-во листов Акта и С/Ф` | `oafptPagesCount` |
| `Кол-во Актов` | `oafptActCount` |
| `Агент` | `oafptOafSender` |
| `CAPEX` | `oafptCapex` |
| `Cумма возвращенных АВ` | `oafptReturnedSum` |

> **Тип 5:** маппинг полностью **загружен в `ags.ra_col_map`** (26 колонок / 28 строк с учётом alias, 2026-03-19).
> **Тип 6:** маппинг полностью **загружен в `ags.ra_col_map`** (17 колонок / 20 строк с учётом alias, 2026-03-19).
> **Тип 2:** маппинг `cnpd*`-полей **загружен в `ags.ra_col_map`** (36 колонок / 38 строк с учётом alias, 2026-03-19). Stage 2a-колонки (`cnpdTpOrdKey`, `pdpCstAgPnKey`) — не в `ra_col_map`, только в DDL таблицы.
> **Тип 3 (`Аренда_Земли`):** маппинг **загружен в `ags.ra_col_map`** (14 колонок `ralprt*` / 14 строк, 2026-03-19). Три флага (`ralprtPresented`, `ralprtSentToBook`, `ralprtReturnedFlg`) — для вычисления `ralprtStatus` (см. §6.4). `rsc_stg_tbl = 'ags.ra_stg_ralp'`.
> **Тип 3 (`учет_аренды`):** маппинг **загружен в `ags.ra_col_map`** (6 колонок `ralprs*` / 6 строк, 2026-03-19). Stage 2a-колонка (`ralprsSender`) и Stage 2c-колонки (`ralprsY`, `ralprsAdtKey`) — не в `ra_col_map`, только в DDL таблицы.

---

### 6.4. Вычисляемые поля (computed staging columns)

Некоторые поля целевой таблицы не читаются напрямую из одной Excel-колонки, а **вычисляются по нескольким флаговым колонкам**. Такие поля отсутствуют в `ra_col_map` под доменным именем; вместо этого каждый флаг-индикатор получает собственное имя в `rcm_tbl_col` (и читается `AuditExcelColumnLocator` как обычная колонка), а Java-метод вычисляет итоговое значение.

**Пример: `ralpraStatus` (`af_type=3`, лист `Аренда_Земли`)**

VBA-логика (строки 2793–2813 `Form_ra_a.cls`):

```
если Поступило в Ф644 = 1:
    если Направ-лено в СБУ = 1 → Status = 2  (направлен в бухгалтерию)
    иначе если Возврат на доработку = 1 → Status = 3  (возвращён агенту)
    иначе → Status = 1  (в работе)
иначе → Status = 0  (не представлен)
```

| Excel-заголовок | `rcm_tbl_col` в `ra_col_map` | Смысл |
|----------------|------------------------------|-------|
| `Поступило в Ф644` | `ralprtPresented` | флаг: отчёт поступил |
| `Направ-лено в СБУ` | `ralprtSentToBook` | флаг: направлен в бухгалтерию |
| `Возврат на доработку` | `ralprtReturnedFlg` | флаг: возвращён агенту |

Java-вычисление в `RalpAuditFileProcessor.readFromExcel()`:

```java
private int computeStatus(int presented, int sentToBook, int returnedFlg) {
    if (presented != 1) return 0;   // не представлен
    if (sentToBook == 1) return 2;  // направлен в бухгалтерию
    if (returnedFlg == 1) return 3; // возвращён агенту
    return 1;                       // в работе
}
```

Флаговые поля (`ralprt*`) читаются `AuditExcelColumnLocator` стандартно, но в INSERT к `ags.ralpRaAu` не записываются — только вычисленный `ralpraStatus`.

---

## 7. Декларативное сопоставление колонок через SQL Server

### 7.1. Обоснование

В VBA сопоставление «заголовок Excel → поле staging» закодировано тремя разными способами (константы в массиве, отдельные `CellFind`-вызовы, жёсткие числовые смещения). При изменении заголовков в исходных файлах требуется правка кода. Предлагается вынести всё сопоставление в SQL Server: любое изменение заголовков — только UPDATE в таблице без перекомпиляции.

### 7.2. Схема таблиц

```sql
-- Конфигурация листа: какой файловый тип, какой лист, какая staging-таблица, какой якорь
-- Таблица создана на сервере 2026-03-19
CREATE TABLE ags.ra_sheet_conf (
    rsc_key          INT IDENTITY(1,1) NOT NULL,
    rsc_ft_key       INT           NOT NULL,            -- FK → ags.ra_ft.ft_key (INT, не TINYINT)
    rsc_sheet        NVARCHAR(100) NULL,                -- имя листа Excel; NULL = все листы типа (тип 6)
    rsc_stg_tbl      NVARCHAR(100) NOT NULL,            -- целевая staging-таблица SQL Server (формат: ags.ra_stg_xxx)
    rsc_anchor       NVARCHAR(200) NOT NULL,            -- текст ячейки-якоря (для поиска строки заголовков)
    rsc_anchor_match CHAR(1)       NOT NULL DEFAULT 'W',-- 'W' = xlWhole, 'P' = xlPart
    rsc_row_pattern  NVARCHAR(200) NULL,                -- LIKE-паттерн для строк данных в колонке якоря (NULL = любое непустое)
    CONSTRAINT PK_ra_sheet_conf PRIMARY KEY (rsc_key),
    CONSTRAINT FK_rsc_ft FOREIGN KEY (rsc_ft_key) REFERENCES ags.ra_ft(ft_key)
);

-- Сопоставление колонок: каждая строка = один alias Excel-заголовка для одного поля staging
CREATE TABLE ags.ra_col_map (
    rcm_key        INT IDENTITY(1,1) PRIMARY KEY,
    rcm_rsc_key    INT           NOT NULL,              -- FK → ra_sheet_conf.rsc_key
    rcm_tbl_col    NVARCHAR(100) NOT NULL,              -- поле staging-таблицы (назначение)
    rcm_tbl_col_ord SMALLINT     NOT NULL,              -- порядок колонки (для insert/display)
    rcm_xl_hdr     NVARCHAR(200) NOT NULL,              -- заголовок в Excel (один alias на строку)
    rcm_xl_hdr_pri TINYINT       NOT NULL DEFAULT 1,    -- приоритет alias: 1=основной, 2,3...=запасные
    rcm_xl_match   CHAR(1)       NOT NULL DEFAULT 'W',  -- 'W' = xlWhole, 'P' = xlPart
    rcm_required   BIT           NOT NULL DEFAULT 1,    -- обязательна ли колонка?
    CONSTRAINT FK_rcm_rsc FOREIGN KEY (rcm_rsc_key) REFERENCES ags.ra_sheet_conf(rsc_key),
    CONSTRAINT UQ_rcm UNIQUE (rcm_rsc_key, rcm_tbl_col, rcm_xl_hdr)
);
```

**Смысл alias-строк:** одному полю staging (`rcm_tbl_col`) может соответствовать несколько строк с разными `rcm_xl_hdr`. Java будет перебирать aliases в порядке `rcm_xl_hdr_pri`: первый найденный в Excel заголовок «побеждает». Это позволяет поддерживать старые и новые названия одновременно.

**Пример для типа 6 (17 строк из `myArray`):**
```sql
INSERT INTO ags.ra_sheet_conf(rsc_ft_key, rsc_sheet, rsc_stg_tbl, rsc_anchor, rsc_anchor_match, rsc_row_pattern)
VALUES (6, '<динамически из ra_ft_s>', 'ags.ogAgFeePnTest', '№ Акта', 'W', NULL);

-- rcm_rsc_key = <ключ вставленной строки>
INSERT INTO ags.ra_col_map(rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
VALUES
  (<key>, 'oafptOafName',       1,  '№ Акта',                                  1, 'W', 1),
  (<key>, 'oafptOafDate',       2,  'Дата Акта',                               1, 'W', 1),
  (<key>, 'oafptPnCstAgPn',     3,  'Код стройки',                             1, 'W', 1),
  (<key>, 'oafptTtl',           4,  'Сумма',                                   1, 'W', 1),
  -- alias: если вдруг "Итого" - запасной
  (<key>, 'oafptTtl',           4,  'Итого',                                   2, 'W', 0),
  (<key>, 'oafptArrivedNum',    5,  'Поступило (№ письма)',                    1, 'W', 0),
  -- ... остальные 12 строк
  (<key>, 'oafptReturnedSum',  17, 'Cумма возвращенных АВ',                   1, 'W', 0);
```

### 7.3. Java-реализация

```java
// Загрузка конфигурации маппинга из БД (кэшируется при старте сервиса)
@Repository
public class AuditColumnMappingRepository {
    public Optional<RaSheetConf> findByFileTypeAndSheet(int ftKey, String sheetName);
    public List<RaColMap> findBySheetConf(int rscKey);
}

// Использование в AuditExcelColumnLocator
public Map<String, Integer> buildColumnMap(Sheet sheet, List<RaColMap> mappings) {
    // Группируем aliases по tbl_col (уже отсортированы по tbl_col_ord, затем xl_hdr_pri)
    Map<String, Integer> result = new LinkedHashMap<>();
    Map<String, List<RaColMap>> byColumn = mappings.stream()
        .sorted(Comparator.comparingInt(RaColMap::getTblColOrd)
                          .thenComparingInt(RaColMap::getXlHdrPri))
        .collect(Collectors.groupingBy(RaColMap::getTblCol, LinkedHashMap::new, toList()));

    for (var entry : byColumn.entrySet()) {
        String tblCol = entry.getKey();
        boolean required = entry.getValue().stream().anyMatch(RaColMap::isRequired);
        for (RaColMap alias : entry.getValue()) {
            int col = findHeaderColumn(sheet, alias.getXlHdr(), alias.getXlMatch());
            if (col >= 0) {
                result.put(tblCol, col);
                break;  // первый найденный alias — используем, остальные не проверяем
            }
        }
        if (!result.containsKey(tblCol) && required) {
            throw new AuditExcelException("Обязательная колонка не найдена: " + tblCol);
        }
    }
    return result;
}
```

### 7.4. Особенности по типам

| `af_type` | Сложность `rsc_sheet` | Примечание |
|-----------|----------------------|-----------|
| 2 | `'ХрСтрКнтрл'` (фиксированный) | Якорь: `'Номер первичного документа'`; имена колонок — из `FindOffset`-вызовов в VBA |
| 3 | `'Аренда_Земли'`, `'учет_аренды'` | `Аренда_Земли`: 14 колонок `ralprt*` (в т.ч. 3 флага для `ralprtStatus`, см. §6.4); `учет_аренды`: 6 колонок `ralprs*`, загружено 2026-03-19 |
| 5 | `'Отчеты'` (фиксированный) | Якорь: `'№ ОА'`; имена — из `CellFind`-вызовов в `ra_aAllAgents.cls` (кодировка нарушена, уточнять по файлам) |
| 6 | Динамически из `ra_ft_s`/`ra_ft_sn` | Якорь: `'№ Акта'`; 17 колонок полностью задокументированы в §6.3 |

### 7.5. Место в порядке разработки

Таблицы `ra_sheet_conf`, `ra_col_map`, `ra_execution` и все 5 staging-таблиц **созданы на сервере** (2026-03-19). Данные `ra_col_map` и `ra_sheet_conf` загружены полностью для всех четырёх типов.

В Liquibase (Фаза 1 чат-плана) нужно добавить `changeSet` с `runOnChange="false"` для воспроизводимости DDL во всех окружениях.

`AuditExcelColumnLocator.buildColumnMap()` заменяет: `CellFind()`-цепочку (тип 5), `myArray`+`ExcelToTable()` (тип 6), `FindOffset()`-цепочку (тип 2) и жёсткие числовые смещения (тип 3).

---

## 8. Улучшения над VBA-реализацией

| Проблема в VBA | Решение в Java |
|----------------|----------------|
| Файл Excel **всегда открывается**, даже при `af_source = false` | `readFromExcel` вызывается только при `af_source = true`; книга не открывается без необходимости |
| Ошибка в одном файле роняет **весь процесс** (`GoTo ErrHandler` с `Resume NormalExit`) | `try-catch` на уровне каждого `process(ctx, file)`: ошибка одного файла логируется, цикл по файлам продолжается |
| `ra_ImpNew` — локальная Access-таблица **без изоляции** конкурентных запусков | SQL Server таблица `ra_ImpNew` + колонка `rain_exec_key` (FK на `ra_execution.exec_key`) |
| Статус `RUNNING` **теряется при рестарте** Access | Постоянное хранение в `ra_execution` (SQL Server); статус переживает рестарт сервера |
| Тип 6 **молча не обрабатывается** если `adt_type ≠ 1` (нет явного лога) | Явная проверка в `AgFee2306AuditFileProcessor` с `log.warn` и ранним выходом |
| `ogAgFeePnTest` — in-memory Access-таблица для типа 4 | Тип 4 устарел и пропускается; таблица не нужна |
| Асинхронность не предусмотрена — UI **зависает** при долгой обработке | `@Async` + polling `adtStatus` через GraphQL |
| Маппинг колонок Excel **закодирован в трёх разных стилях** (массив, CellFind, числовые смещения) | Единая таблица `ags.ra_col_map` + `ags.ra_sheet_conf`; изменение заголовков — только UPDATE в БД, без пересборки |
| Тип 3: смена порядка колонок Excel **ломает** обработку (жёсткие числовые смещения) | Поиск по именам заголовков через `ra_col_map`; порядок колонок в файле не важен |
| Тип 3: `ralpraStatus` вычисляется **inline** в теле цикла из трёх числовых смещений — логика перемешана с чтением ячеек | `computeStatus()` — отдельный метод в `RalpAuditFileProcessor`; три флаговых колонки читаются через `ra_col_map`, статус вычисляется явно (§6.4) |

---

## 9. Порядок разработки

### Шаг A: Каркас (без наполнения)
Определить финальные контракты и создать все четыре конкретных класса как **заглушки** (только логируют «начат/завершён»). После этого `switch` в `AuditExecutionServiceImpl` корректно работает для всех типов.

### Шаг B: Инфраструктура POI (Фаза 2 чат-плана)
`AuditExcelReader`, `AuditExcelColumnLocator`, `AuditExcelCellReader` — общие утилиты. Этот шаг **должен предшествовать** наполнению любого процессора реальной логикой.

### Шаг C: Наполнение процессоров (можно параллельно)
Каждый процессор разрабатывается независимо:
1. `readFromExcel` → чтение Excel и сохранение во временное хранилище (staging в БД или DTO)
2. `reconcileWithDb` → сравнение staging с доменными таблицами

Все четыре типа могут разрабатываться одновременно, так как их `readFromExcel` и `reconcileWithDb` не зависят друг от друга. По мере работы над параллельными ветками общие паттерны поднимаются в абстрактный уровень.

### Текущий приоритет: тип 5 (`AllAgentsAuditFileProcessor`)
Реализация Фаз 1–5 чат-плана. Остальные три типа — в следующих итерациях.

---

## 10. Двухстадийное заполнение staging-таблиц

### 10.1. Модель двух стадий

Заполнение staging-таблицы из Excel разделяется на **две стадии** внутри метода `readFromExcel`:

| Стадия | Метод в Java | Источник | Применимость |
|--------|-------------|----------|--------------|
| 1 — прямой перенос | `fillStagingFromExcel()` | Excel-ячейки по `ra_col_map` | Все типы (generic) |
| 2a — FK-разрешение | `resolveForeignKeys()` | SQL-запросы по текстовым полям Stage 1 | Типы 2, 3 (type-specific) |
| 2b — вычисляемые поля | `computeDerivedFields()` | Java-код по полям Stage 1 | Тип 3 (`ralprtStatus`) |
| 2c — контекст | `injectContextFields()` | `AuditExecutionContext` | Все типы (generic) |

После `readFromExcel` (все стадии завершены) вызывается отдельная фаза **`reconcileWithDb()`** — сравнение staging с доменными таблицами и применение изменений.

### 10.2. Классификация колонок по стадиям

#### Тип 5 (`ags.ra_stg_ra`)

| Колонка | Стадия | Источник |
|---------|--------|---------|
| `rainRaNum` … `rainRaReturnedSum` (26 колонок) | Stage 1 | `ra_col_map` (rsc_key=1) |
| `rain_exec_key` | Stage 2c | `ctx.getExecKey()` |

#### Тип 6 (`ags.ra_stg_agfee`)

| Колонка | Стадия | Источник |
|---------|--------|---------|
| `oafptOafName` … `oafptReturnedSum` (17 колонок) | Stage 1 | `ra_col_map` (rsc_key=2) |
| `oafptOgKey` | Stage 2a | `UPDATE ... SET oafptOgKey = (SELECT og_key FROM ags.ogNm WHERE og_name LIKE oafptOafSender)` |
| `oafpt_exec_key` | Stage 2c | `ctx.getExecKey()` |

#### Тип 2 (`ags.ra_stg_cn_prdoc`)

| Колонка | Стадия | Источник |
|---------|--------|---------|
| `cnpdNum` … `AccountMain` (36 колонок) | Stage 1 | `ra_col_map` (rsc_key=3) |
| `cnpdTpOrdKey` | Stage 2a | Поиск в `ags.cn_PrDocT` по `cnpdTpOrd` |
| `pdpCstAgPnKey` | Stage 2a | Поиск в `ags.cn_CstAgPn` по `pdpCstAgPnStr` |
| `cnpd_exec_key`, `cnpdNumSequential` | Stage 2c | `ctx.getExecKey()`, счётчик строк |

#### Тип 3, лист `Аренда_Земли` (`ags.ra_stg_ralp`)

| Колонка | Стадия | Источник |
|---------|--------|---------|
| `ralprtNum`, `ralprtDate`, `ralprtCstCodeStr`, `ralprtOgSenderStr`, `ralprtOgBranchStr`, `ralprtCostAndVat`, `ralprtPresented`, `ralprtSentToBook`, `ralprtReturnedFlg`, `ralprtTestStartDate`, `ralprtNote`, `ralprtArrived`, `ralprtSent`, `ralprtReturned` (14 колонок) | Stage 1 | `ra_col_map` (rsc_key=4) |
| `ralprtCstAgPn` | Stage 2a | Поиск в `ags.cn_CstAgPn` по `ralprtCstCodeStr` |
| `ralprtOgSender` | Stage 2a | Поиск в `ags.ogNmF` по `ralprtOgSenderStr` + `ralprtOgBranchStr` |
| `ralprtStatus` | Stage 2b | `computeStatus(ralprtPresented, ralprtSentToBook, ralprtReturnedFlg)` |
| `ralprt_exec_key` | Stage 2c | `ctx.getExecKey()` |
| `ralprtRaKey`, `ralprtRaAuKey` | reconcileWithDb | FK на доменные таблицы |

#### Тип 3, лист `учет_аренды` (`ags.ra_stg_ralp_sm`)

| Колонка | Стадия | Источник |
|---------|--------|---------|
| `ralprsSenderStr`, `ralprsArrived`, `ralprsInProcess`, `ralprsSended`, `ralprsReturned`, `ralprsAccepted` (6 колонок) | Stage 1 | `ra_col_map` (rsc_key=5) |
| `ralprsSender` | Stage 2a | Поиск в `ags.ogNmF` по `ralprsSenderStr` (с учётом вложенности: агент → филиал) |
| `ralprsY`, `ralprsAdtKey` | Stage 2c | `ctx.getAuditYear()`, `ctx.getAdtKey()` |
| `ralprsNum`, `ralprs_exec_key` | Stage 2c | счётчик строк, `ctx.getExecKey()` |

### 10.3. Рекомендуемая структура Java-методов

```java
// В AbstractAuditFileProcessor — generic части
protected void fillStagingFromExcel(Sheet sheet, RaSheetConf conf, List<RaColMap> mapping, long execKey);
protected void injectContextFields(long execKey);  // UPDATE ... SET *_exec_key = ?

// В конкретном процессоре — переопределяемые части
protected void resolveForeignKeys();   // SQL UPDATE для Stage 2a (default: no-op)
protected void computeDerivedFields(); // Java-вычисления для Stage 2b (default: no-op)

// После readFromExcel — отдельная фаза
protected abstract void reconcileWithDb(AuditExecutionContext ctx, AuditFile file);
```

**Вариант реализации FK-разрешения (Stage 2a):** SQL UPDATE через JDBC/JPA в теле `resolveForeignKeys()`. Прямо и понятно; не требует дополнительных конфигурационных таблиц.

### 10.4. Отличие от VBA

В VBA стадии 1, 2a и reconcileWithDb перемешаны в одном цикле: строка Excel → немедленная запись в доменную таблицу через `FindRalpRa`/`FindRalpRaAu`. В Java эти стадии **явно разделены**: staging-таблица заполняется полностью (все строки), затем reconcile работает с уже готовым staging. Это упрощает обработку ошибок и тестирование.

---

**Последнее обновление:** 2026-03-19
**Версия:** 0.6.0
