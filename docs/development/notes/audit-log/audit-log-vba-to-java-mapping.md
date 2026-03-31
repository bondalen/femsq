---
title: "Audit log: VBA → Java mapping (ход ревизии)"
created: "2026-03-26"
lastUpdated: "2026-03-25"
status: "draft"
version: "0.1.2"
---

## Назначение

Двухдеревный mapping между:
- деревом сообщений VBA (эталон привычного лога),
- деревом сообщений Java (текущая реализация).

Цель: явно показать путь выполнения от корня (`Выполнить ревизию`), развилки (`CHECK`/`CASE`), тупики (`### TERMINAL`) и соответствия `V-* -> J-*`.

## Источники

- VBA: `VBA-Code-Export/Form-Modules/Form_ra_a.cls` (`btnAuditRun_Click`) + `RAAudit_*`
- Java:
  - `AuditExecutionServiceImpl` (audit/file orchestration)
  - `DefaultAuditStagingService` (sheet/staging)
  - file processors (`AllAgentsAuditFileProcessor`, `CnPrDocAuditFileProcessor`, ...)

## Правила нотации дерева

- Узлы `V-*` — дерево VBA.
- Узлы `J-*` — дерево Java.
- Тип узла: `[ACTION] | [CHECK] | [CASE] | [MSG] | [TERMINAL]`.
- Для тупиков используется явная метка: `### TERMINAL: <reason>`.
- Для связи между деревьями: `map -> J-x.y` или `map -> missing/partial`.

### Порядок "трансляции" сообщений `V-A -> J-A`

1. Для каждого `V-A.* [MSG]` фиксируется:
   - VBA-эталон (поля + исходный шаблон),
   - фактический Java-аналог (`J-A.* [MSG]`, если уже есть),
   - целевой Java-аналог (`J-A.* [MSG][TARGET]`, если фактического аналога нет или он неполный).
2. У `V-A.* [MSG]` добавляется блок соответствия:
   - `map -> J-A.*` (или `map -> missing`),
   - `status -> exact | semantic | partial | missing`,
   - `gap -> <что не покрыто в Java>`.
3. Правила статусов:
   - `exact` — совпадают смысл и ключевые поля,
   - `semantic` — смысл совпадает, но формат отличается,
   - `partial` — покрыта только часть смысла/полей,
   - `missing` — эквивалента в Java нет.
4. Для `partial/missing` обязательно фиксируется `J-A.* [MSG][TARGET]` с минимальным контрактом полей и критериями готовности.

### Порядок сохранения цветового оформления VBA

1. В Java-логе хранится не HTML, а семантика оформления:
   - `colorHint: RED|GREEN|BLUE`,
   - `emphasis: NORMAL|BOLD`,
   - `messageType: START|INFO|SUCCESS|WARNING|ERROR|END`.
2. Текст сообщения хранится в чистом виде (`messageText`) с параметрами (`params`).
3. Визуализация цвета и акцентов выполняется на уровне UI/рендера по правилам маппинга:
   - `RED -> error/warning accent`,
   - `GREEN -> success accent`,
   - `BLUE -> lifecycle/info accent`.
4. Допускается временный HTML-рендер для отчётов, но source-of-truth — структурированные поля (`colorHint`, `emphasis`, `messageType`, `messageText`, `params`).

## Дерево VBA (по процедурам/файлам, только рабочие типы `2/3/5/6`)

### V-A. `Form_ra_a.cls :: btnAuditRun_Click` (общая оркестровка)

#### Порядок построения дерева `V-A`

1. Сначала фиксируется рамка процесса: `V-A.1/start [ACTION]` и `V-A.1/end [ACTION]`.
2. Сразу после старта фиксируется открывающее сообщение `V-A.1.msg.start [MSG]` (полный HTML).
3. Между start/end размещаются только внутренние шаги оркестровки в порядке выполнения (без избыточной детализации).
4. Перед закрывающим `ACTION` фиксируется закрывающее сообщение `V-A.1.msg.end [MSG]` (полный HTML).
5. Для `MSG`-узлов сохраняется исходная разметка (включая `font color`, `B`) и имена полей.

- `V-A.1/start [ACTION]` Кнопка `Выполнить ревизию`
  - `V-A.1.1 [ACTION]` Инициализация `adt_results` / `adt_date`
  - `V-A.1.msg.start [MSG]`
    - `map -> J-A.1.msg.start [TARGET]`
    - `status -> missing`
    - `gap -> требуется Java MSG уровня оркестрации с полями старта (`auditId`, `auditName`, `auditDir`, `startedAt`) и семантическим оформлением (`colorHint=RED`, `emphasis=BOLD`, `messageType=START`)`
    - **Поля:** `Me!adt_name`, `Me!adt_dir`, `Me!adt_date`
    - **Шаблон:**
      ```vb
      Me!adt_results = "<P>Начало проведения ревизии *<B><font color=""red"">" & Me!adt_name & "</font></B>*.</P>" _
          & "<P>Проводим по директории - " & Me!adt_dir & "</P>" _
          & "<P><B>" & Me!adt_date & "</B> - Время начала проведения ревизии.</P>"
      ```
  - `V-A.1.2 [CHECK]` `adt_key` задан?
    - `V-A.1.2.a [TERMINAL]` `### TERMINAL: AUDIT_KEY_EMPTY`
    - `V-A.1.2.b [CHECK]` `adt_dir` найден в справочнике?
      - `V-A.1.2.b.a [MSG]`
        - `map -> J-A.1.2.msg.dir.lookup.missing [TARGET]`
        - `status -> missing`
        - `gap -> требуется Java MSG об отсутствии директории ревизии в справочнике (`messageType=ERROR`, `colorHint=RED`)`
        - **Поля:** `Me!adt_results`
        - **Шаблон:**
          ```vb
          Me!adt_results = "<P>Не обнаружена <font color=""red"">директория</font> для ревизии</P>" & Me!adt_results
          ```
      - `V-A.1.2.b.a1 [TERMINAL]` `### TERMINAL: DIR_LOOKUP_NOT_FOUND`
      - `V-A.1.2.b.b.msg [MSG]`
        - `map -> J-A.1.2.msg.dir.lookup.found [TARGET]`
        - `status -> missing`
        - `gap -> требуется Java MSG о найденном имени директории ревизии (`dirName`, `messageType=INFO`, `colorHint=GREEN`)`
        - **Поля:** `strDir`, `Me!adt_results`
        - **Шаблон:**
          ```vb
          Me!adt_results = "<P>Имя директории *<B><font color=""green"">" & strDir & "</font></B>* для ревизии обнаружено</P>" _
              & Me!adt_results
          ```
      - `V-A.1.2.b.b.check [CHECK]` Директория существует в ФС?
        - `V-A.1.2.b.b.check.a [MSG]`
          - `map -> J-A.1.2.b.msg.dir.fs.missing [TARGET]`
          - `status -> missing`
          - `gap -> требуется Java MSG об отсутствии директории в файловой системе (`dirPath`, `messageType=ERROR`, `colorHint=RED`)`
          - **Поля:** `strDir`, `Me!adt_results`
          - **Шаблон:**
            ```vb
            Me!adt_results = _
                "<P>Директория с именем *<B><font color=""red"">" _
                & strDir _
                & "</font></B>* в файловой системе не обнаружена</P>" _
                & Me!adt_results
            ```
        - `V-A.1.2.b.b.check.a1 [TERMINAL]` `### TERMINAL: DIR_FS_MISSING`
        - `V-A.1.2.b.b.check.b [MSG]`
          - `map -> J-A.1.2.b.msg.dir.fs.found [TARGET]`
          - `status -> missing`
          - `gap -> требуется Java MSG об обнаружении директории в файловой системе (`dirPath`, `messageType=SUCCESS`, `colorHint=GREEN`)`
          - **Поля:** `strDir`, `Me!adt_results`
          - **Шаблон:**
            ```vb
            Me!adt_results = "<P>Директория с именем *<B><font color=""green"">" & strDir & "</font></B>* в файловой системе обнаружена</P>" _
                & Me!adt_results
            ```
        - `V-A.1.2.b.b.check.b1 [MSG]`
          - `map -> J-B.1.1`
          - `status -> semantic`
          - `gap -> в Java фиксируется открытие workbook (`WORKBOOK_OPEN`), но нет отдельного сообщения уровня "приложение Excel открыто"`
          - **Поля:** `DateTime.Now`, `Me!adt_results`
          - **Шаблон:**
            ```vb
            Me!adt_results = "<P>" & DateTime.Now _
                & " - *<B><font color=""green"">" & "Приложение Excel открыто" & "</font></B>*</P>" & Me!adt_results
            ```
        - `V-A.1.2.b.b.check.b2 [ACTION]` Перейти к циклу файлов
          - `V-A.1.2.b.b.check.b2.0 [CHECK]` `rstFiltered.RecordCount > 0`?
            - `V-A.1.2.b.b.check.b2.0.a [ACTION]` Цикл файлов `ra_f`
              - `V-A.1.2.b.b.check.b2.0.a.0 [CHECK]` `fsof.FileExists(strFile)`?
                - `V-A.1.2.b.b.check.b2.0.a.0.a [MSG]`
                  - `map -> J-A.1.3.2.msg.file.fs.found [TARGET]`
                  - `status -> missing`
                  - `gap -> требуется Java MSG об обнаружении файла в файловой системе (`filePath`, `checkedAt`, `messageType=INFO`)`
                  - **Поля:** `DateTime.Now`, `strFile`, `Me!adt_results`
                  - **Шаблон:**
                    ```vb
                    Me!adt_results = "<P>" & DateTime.Now & " - Файл с именем *<B>" & strFile _
                        & "</B>* в файловой системе обнаружен</P>" & Me!adt_results
                    ```
                - `V-A.1.2.b.b.check.b2.0.a.0.a1 [MSG]`
                  - `map -> J-B.1.1`
                  - `status -> semantic`
                  - `gap -> в Java открытие файла отражается через `WORKBOOK_OPEN` в staging-сервисе, без отдельного file-level события "в приложении открыт"`
                  - **Поля:** `DateTime.Now`, `strFile`, `Me!adt_results`
                  - **Шаблон:**
                    ```vb
                    Me!adt_results = _
                        "<P>" & DateTime.Now & " - Файл с именем *<B><font color=""green"">" & strFile _
                        & "</font></B>* в приложении открыт</P>" & Me!adt_results
                    ```
                - `V-A.1.2.b.b.check.b2.0.a.0.b [MSG]`
                  - `map -> J-A.1.3.2.msg.file.fs.missing [TARGET]`
                  - `status -> missing`
                  - `gap -> требуется Java MSG об отсутствии файла в файловой системе (`filePath`, `messageType=ERROR`, `colorHint=RED`)`
                  - **Поля:** `strFile`, `Me!adt_results`
                  - **Шаблон:**
                    ```vb
                    Me!adt_results = "<P>Файл с именем *<B><font color=""red"">" & strFile _
                        & "</font></B>* в файловой системе не обнаружен</P>" & Me!adt_results
                    ```
                - `V-A.1.2.b.b.check.b2.0.a.0.b1 [ACTION]` Переход к следующему файлу
              - `V-A.1.2.b.b.check.b2.0.a.1 [CASE]` Ветка по `af_type` (раскрываем только `2/3/5/6`)
                - `V-A.1.2.b.b.check.b2.0.a.1.2 [ACTION]` `af_type=2` -> `RAAudit_cn_PrDoc`
                  - `V-A.1.2.b.b.check.b2.0.a.1.2.1 [CHECK]` Листы по настройкам (`281..366`) найдены?
                    - `V-A.1.2.b.b.check.b2.0.a.1.2.1.a [ACTION]` Вызов `RAAudit_cn_PrDoc`
                    - `V-A.1.2.b.b.check.b2.0.a.1.2.1.b [MSG]`
                      - **Поля:** `DateTime.Now`, `strFile`, `Me!adt_results`
                      - **Шаблон:**
                        ```vb
                        Me!adt_results = "<P>" & DateTime.Now _
                            & " - *<B> в книге *<font color=""red"">" & strFile _
                            & "</font>* отсутствуют обязательные листы по настройкам (281..366)</B>*</P>" _
                            & Me!adt_results
                        ```
                - `V-A.1.2.b.b.check.b2.0.a.1.3 [ACTION]` `af_type=3` -> `RAAudit_ralp` + `RAAudit_ralpSum`
                  - `V-A.1.2.b.b.check.b2.0.a.1.3.1 [CHECK]` `WorksheetIsExist(xlW, "Аренда_Земли")`?
                    - `V-A.1.2.b.b.check.b2.0.a.1.3.1.a [ACTION]` Вызов `RAAudit_ralp`
                    - `V-A.1.2.b.b.check.b2.0.a.1.3.1.b [MSG]`
                      - **Поля:** `DateTime.Now`, `Me!adt_results`
                      - **Шаблон:**
                        ```vb
                        Me!adt_results = _
                            "<P>" & DateTime.Now _
                            & " - *<B> лист <font color=""red"">Аренда_Земли не обнаружен" & "</font> в книге</B>*</P>" _
                            & Me!adt_results
                        ```
                  - `V-A.1.2.b.b.check.b2.0.a.1.3.2 [CHECK]` `WorksheetIsExist(xlW, "учет_аренды")`?
                    - `V-A.1.2.b.b.check.b2.0.a.1.3.2.a [ACTION]` Вызов `RAAudit_ralpSum`
                    - `V-A.1.2.b.b.check.b2.0.a.1.3.2.b [MSG]`
                      - **Поля:** `DateTime.Now`, `Me!adt_results`
                      - **Шаблон:**
                        ```vb
                        Me!adt_results = _
                            "<P>" & DateTime.Now _
                            & " - *<B> лист <font color=""red"">учет_аренды не обнаружен" & "</font> в книге</B>*</P>" _
                            & Me!adt_results
                        ```
                - `V-A.1.2.b.b.check.b2.0.a.1.5 [ACTION]` `af_type=5` -> `ra_aAllAgentsChild.Audit`
                  - `V-A.1.2.b.b.check.b2.0.a.1.5.1 [CHECK]` `WorksheetIsExist(xlW, "Отчёты обычные")`?
                    - `V-A.1.2.b.b.check.b2.0.a.1.5.1.a [ACTION]` Вызов `ra_aAllAgentsChild.Audit`
                    - `V-A.1.2.b.b.check.b2.0.a.1.5.1.b [MSG]`
                      - **Поля:** `DateTime.Now`, `Me!adt_results`
                      - **Шаблон:**
                        ```vb
                        Me!adt_results = _
                            "<P>" & DateTime.Now _
                            & " - *<B> лист <font color=""red"">Отчёты обычные не обнаружен" & "</font> в книге</B>*</P>" _
                            & Me!adt_results
                        ```
                - `V-A.1.2.b.b.check.b2.0.a.1.6 [ACTION]` `af_type=6` -> `RAAudit_AgFee_Month`
                - `V-A.1.2.b.b.check.b2.0.a.1.n [MSG]` Тип файла не содержит листов для анализа
                  - **Поля:** `DateTime.Now`, `Me!adt_results`
                  - **Шаблон:**
                    ```vb
                    Me!adt_results = _
                        "<P>" & DateTime.Now _
                        & " - *<B><font color=""red"">Тип файла не содержит листов для анализа</font></B>*</P>" _
                        & Me!adt_results
                    ```
                - `V-A.1.2.b.b.check.b2.0.a.1.x [TERMINAL]` `### TERMINAL: OBSOLETE_TYPE_SKIPPED`
            - `V-A.1.2.b.b.check.b2.0.b [MSG]`
              - `map -> J-A.1.3.msg.files.empty [TARGET]`
              - `status -> missing`
              - `gap -> требуется Java MSG о пустом списке файлов для рассмотрения (`messageType=WARNING`, `colorHint=RED`)`
              - **Поля:** `Me!adt_results`
              - **Шаблон:**
                ```vb
                Me!adt_results = "<P>Не обнаружены файлы для рассмотрения</P>" & Me!adt_results
                ```
            - `V-A.1.2.b.b.check.b2.0.b1 [ACTION]` Переход к `V-A.1.msg.end`
  - `V-A.1.msg.excel.close [MSG]`
    - `map -> J-B.1.2`
    - `status -> semantic`
    - `gap -> в Java фиксируется закрытие workbook (`WORKBOOK_CLOSE`), но нет отдельного сообщения про жизненный цикл приложения Excel`
    - **Поля:** `DateTime.Now`, `Me!adt_results`
    - **Шаблон:**
      ```vb
      Me!adt_results = "<P>" & DateTime.Now _
          & " - *<B><font color=""blue"">" _
          & "Приложение Excel закрыто" _
          & "</font></B>*</P>" _
          & Me!adt_results
      ```
  - `V-A.1.msg.end [MSG]`
    - `map -> J-A.1.msg.end [TARGET]`
    - `status -> missing`
    - `gap -> требуется Java MSG уровня оркестрации с полями завершения (`finishedAt`, `startedAt`, `durationSec`, `durationHuman`, `status`) и семантическим оформлением (`colorHint=BLUE`, `emphasis=BOLD`, `messageType=END`)`
    - **Поля:** `dFinish`, `dStart`, `dDateDiff`, `Me!adt_results`
    - **Шаблон:**
      ```vb
      Me!adt_results = "<P>В " & dFinish & " - *<B><font color=""blue"">" & "ревизия завершена" _
          & "</font></B>*. C " & dStart & " в течении " & dDateDiff \ 60 & " мин. " & dDateDiff - ((dDateDiff \ 60) * 60) & " сек., (всего " _
          & dDateDiff & " сек.).</P>" & Me!adt_results
      ```
- `V-A.1/end [ACTION]` Кнопка `Выполнить ревизию`

### V-B. `Form_ra_a.cls :: RAAudit_RA_RepPeriod / ReportOfAgent` (legacy, parked)

- `V-B.1 [ACTION]` Ветка legacy‑типа (`af_type=1`) до `paragraph`
- `V-B.2 [TERMINAL]` `### TERMINAL: LEGACY_BRANCH_PARKED`
- Примечание: структура `paragraph` сохранена в каталоге событий, но **подробное дерево этой ветки не раскрывается** в текущем документе, т.к. вне рабочих типов `2/3/5/6`.

### V-C. `ra_aAllAgents.cls :: Audit -> RaReadOfExcel` (актуальная ветка type 5)

- `V-C.1 [ACTION]` Вход в `ra_aAllAgents.Audit` (вызов из `btnAuditRun_Click` при `af_type=5`)
  - `V-C.1.1 [CHECK]` `af_source=true`?
    - `V-C.1.1.a [ACTION]` Очистка `ra_ImpNew`
    - `V-C.1.1.b [TERMINAL]` `### TERMINAL: SOURCE_LOADING_SKIPPED`
- `V-C.2 [ACTION]` Поиск обязательных заголовков через `CellFind` (`№ ОА`, `Дата ОА`, `Код стройки`, `Признак`, суммы и др.)
  - `V-C.2.1 [CHECK]` Все обязательные заголовки найдены?
    - `V-C.2.1.a [MSG]` Диапазон `Отчёты обычные` найден (колонка/адрес)
    - `V-C.2.1.b [MSG]` Критичные столбцы/диапазон не найдены
    - `V-C.2.1.b1 [TERMINAL]` `### TERMINAL: TYPE5_REQUIRED_COLUMNS_MISSING`
- `V-C.3 [ACTION]` Перебор строк диапазона `ra_RA`
  - `V-C.3.1 [CHECK]` Найдены строки отчётов?
    - `V-C.3.1.a [MSG]` Найдены строки отчётов (в т.ч. несколько через `FindNext`)
    - `V-C.3.1.b [MSG]` Отчёты не найдены / найдены в неверной колонке
    - `V-C.3.1.b1 [TERMINAL]` `### TERMINAL: TYPE5_REPORT_ROWS_NOT_FOUND`
  - `V-C.3.2 [ACTION]` Для каждой найденной строки вызов `RaReadOfExcel(...)`
- `V-C.R [ACTION]` `ra_aAllAgents.RaReadOfExcel` (формирование row-level `paragraph`)
  - `V-C.R.1 [MSG]` Старт `paragraph`: “Найден типа: ...; имя: ...; САК ...”
  - `V-C.R.2 [CHECK]` `af_source=true`?
    - `V-C.R.2.a [ACTION]` Добавление строки в `ra_ImpNew`
    - `V-C.R.2.a.1 [MSG]` “ОА ... добавлен в импорт. ID - ...”
    - `V-C.R.2.b [ACTION]` Только формирование `paragraph` без вставки
  - `V-C.R.3 [ACTION]` `str = paragraph & str` (накопление сообщений в лог)
  - `V-C.R.4 [TERMINAL]` `### TERMINAL: TYPE5_PARAGRAPH_APPENDED`

## Дерево Java (по классам/файлам, рабочие типы `2/3/5/6`)

### J-A. `AuditExecutionServiceImpl` (общая оркестровка)

- `J-A.1 [ACTION]` Запуск ревизии (`executeAudit`)
  - `J-A.1.1 [ACTION]` `AUDIT_START`
  - `J-A.1.msg.start [MSG][TARGET]` Оркестрационный старт (эквивалент `V-A.1.msg.start`)
    - **Контракт полей:** `auditId`, `auditName`, `auditDir`, `startedAt`, `colorHint=RED`, `emphasis=BOLD`, `messageType=START`
    - **Статус:** `missing` (требуется реализация в Java)
  - `J-A.1.2 [CHECK]` dir lookup
    - `J-A.1.2.msg.dir.lookup.missing [MSG][TARGET]` Директория ревизии не найдена в справочнике (эквивалент `V-A.1.2.b.a`)
      - **Контракт полей:** `auditId`, `auditDirRef`, `messageType=ERROR`, `colorHint=RED`, `emphasis=BOLD`
      - **Статус:** `missing` (требуется реализация в Java)
    - `J-A.1.2.msg.dir.lookup.found [MSG][TARGET]` Имя директории ревизии найдено (эквивалент `V-A.1.2.b.b.msg`)
      - **Контракт полей:** `auditId`, `dirName`, `messageType=INFO`, `colorHint=GREEN`, `emphasis=BOLD`
      - **Статус:** `missing` (требуется реализация в Java)
    - `J-A.1.2.a [TERMINAL]` `### TERMINAL: DIR_LOOKUP_NOT_FOUND`
    - `J-A.1.2.b [CHECK]` dir fs exists/missing
      - `J-A.1.2.b.msg.dir.fs.missing [MSG][TARGET]` Директория отсутствует в ФС (эквивалент `V-A.1.2.b.b.check.a`)
        - **Контракт полей:** `auditId`, `dirPath`, `messageType=ERROR`, `colorHint=RED`, `emphasis=BOLD`
        - **Статус:** `missing` (требуется реализация в Java)
      - `J-A.1.2.b.msg.dir.fs.found [MSG][TARGET]` Директория обнаружена в ФС (эквивалент `V-A.1.2.b.b.check.b`)
        - **Контракт полей:** `auditId`, `dirPath`, `messageType=SUCCESS`, `colorHint=GREEN`, `emphasis=BOLD`
        - **Статус:** `missing` (требуется реализация в Java)
  - `J-A.1.3 [ACTION]` Цикл файлов (`FILE_START/FILE_END`)
    - `J-A.1.3.1 [CHECK]` skip by config
    - `J-A.1.3.2 [CHECK]` file fs exists/missing
      - `J-A.1.3.2.msg.file.fs.found [MSG][TARGET]` Файл обнаружен в ФС (эквивалент `V-A.1.2.b.b.check.b2.0.a.0.a`)
        - **Контракт полей:** `auditId`, `filePath`, `checkedAt`, `messageType=INFO`, `colorHint=GREEN`
        - **Статус:** `missing` (требуется реализация в Java)
      - `J-A.1.3.2.msg.file.fs.missing [MSG][TARGET]` Файл отсутствует в ФС (эквивалент `V-A.1.2.b.b.check.b2.0.a.0.b`)
        - **Контракт полей:** `auditId`, `filePath`, `messageType=ERROR`, `colorHint=RED`, `emphasis=BOLD`
        - **Статус:** `missing` (требуется реализация в Java)
    - `J-A.1.3.3 [ACTION]` вызов file-processor по `af_type=2/3/5/6`
    - `J-A.1.3.msg.files.empty [MSG][TARGET]` Не обнаружены файлы для рассмотрения (эквивалент `V-A.1.2.b.b.check.b2.0.b`)
      - **Контракт полей:** `auditId`, `messageType=WARNING`, `colorHint=RED`, `emphasis=NORMAL`
      - **Статус:** `missing` (требуется реализация в Java)
  - `J-A.1.msg.end [MSG][TARGET]` Оркестрационное завершение (эквивалент `V-A.1.msg.end`)
    - **Контракт полей:** `finishedAt`, `startedAt`, `durationSec`, `durationHuman`, `status`, `colorHint=BLUE`, `emphasis=BOLD`, `messageType=END`
    - **Статус:** `missing` (требуется реализация в Java)

### J-B. `DefaultAuditStagingService` (sheet/staging)

- `J-B.1 [ACTION]` `WORKBOOK_OPEN/WORKBOOK_CLOSE`
  - `J-B.1.1 [MSG]` `WORKBOOK_OPEN` (фактическое событие Java из `DefaultAuditStagingService`)
    - **Контракт полей (факт):** `filePath`, `openedAt`, `scope=FILE`
    - **Статус:** `present` (используется как ближайший аналог для `V-A.1.2.b.b.check.b1` и `V-A.1.2.b.b.check.b2.0.a.0.a1`)
  - `J-B.1.2 [MSG]` `WORKBOOK_CLOSE` (фактическое событие Java из `DefaultAuditStagingService`)
    - **Контракт полей (факт):** `filePath`, `closedAt`, `duration`, `scope=FILE`
    - **Статус:** `present` (используется как ближайший аналог для `V-A.1.msg.excel.close`)
- `J-B.2 [CHECK]` `SHEET_FOUND/SHEET_MISSING`
- `J-B.3 [ACTION]` `STAGING_START/STAGING_STATS/STAGING_END`

### J-C. Type-specific processors (до row-level `paragraph`-эквивалента)

- `J-C.2 [ACTION]` Type 2: `CnPrDocAuditFileProcessor`
- `J-C.3 [ACTION]` Type 3: `RalpAuditFileProcessor`
- `J-C.5 [ACTION]` Type 5: `AllAgentsAuditFileProcessor`
  - `J-C.5.1 [ACTION]` Вызов `DefaultAuditStagingService.loadToStaging`
  - `J-C.5.2 [MSG]` `SHEET_FOUND/SHEET_MISSING` + `STAGING_START/STAGING_STATS/STAGING_END`
  - `J-C.5.3 [TERMINAL]` `### TERMINAL: TYPE5_ROW_LEVEL_PARAGRAPH_EQUIVALENT_MISSING`
- `J-C.6 [ACTION]` Type 6: `AgFee2306AuditFileProcessor`
- `J-C.x [TERMINAL]` `### TERMINAL: PARAGRAPH_EQUIVALENT_NOT_IMPLEMENTED`

## Таблица связей узлов (до `paragraph`)

| VBA node | Java node | Status | Комментарий |
|---|---|---|---|
| `V-A.1.msg.start` | `J-A.1.msg.start [TARGET]` | missing | Нужен Java MSG с полями старта и семантическим оформлением (`colorHint/emphasis`). |
| `V-A.1.2.b.a` | `J-A.1.2.msg.dir.lookup.missing [TARGET]` | missing | Сообщение об отсутствии директории ревизии в справочнике. |
| `V-A.1.2.b.b.msg` | `J-A.1.2.msg.dir.lookup.found [TARGET]` | missing | Сообщение о найденном имени директории ревизии. |
| `V-A.1.2.b.b.check.a` | `J-A.1.2.b.msg.dir.fs.missing [TARGET]` | missing | Сообщение об отсутствии директории в файловой системе. |
| `V-A.1.2.b.b.check.b` | `J-A.1.2.b.msg.dir.fs.found [TARGET]` | missing | Сообщение об обнаружении директории в файловой системе. |
| `V-A.1.2.b.b.check.b1` | `J-B.1.1` | semantic | В Java есть `WORKBOOK_OPEN` (staging), но нет отдельного app-level сообщения "Excel открыто". |
| `V-A.1.2.b.b.check.b2.0.a.0.a` | `J-A.1.3.2.msg.file.fs.found [TARGET]` | missing | Сообщение об обнаружении файла в файловой системе. |
| `V-A.1.2.b.b.check.b2.0.a.0.a1` | `J-B.1.1` | semantic | Открытие файла книги в Java отражается через `WORKBOOK_OPEN` без выделенного file-open события. |
| `V-A.1.2.b.b.check.b2.0.a.0.b` | `J-A.1.3.2.msg.file.fs.missing [TARGET]` | missing | Сообщение об отсутствии файла в файловой системе. |
| `V-A.1.2.b.b.check.b2.0.b` | `J-A.1.3.msg.files.empty [TARGET]` | missing | Сообщение об отсутствии файлов для рассмотрения. |
| `V-A.1.msg.excel.close` | `J-B.1.2` | semantic | В Java есть `WORKBOOK_CLOSE`, но нет отдельного app-level сообщения о закрытии Excel. |
| `V-A.1.msg.end` | `J-A.1.msg.end [TARGET]` | missing | Нужен Java MSG завершения с длительностью и итоговым статусом. |
| `V-A.1.1` | `J-A.1.1` | present | Старт ревизии есть в обоих деревьях. |
| `V-A.1.2.b.*` | `J-A.1.2.*` | partial | Проверки директории есть, тексты/детали отличаются. |
| `V-A.1.2.b.b.b.1` | `J-A.1.3.*` | partial | Цикл файлов есть, часть VBA-веток агрегирована. |
| `V-A.1.2.b.b.b.2.2/3/5/6` | `J-C.2/3/5/6` | partial | Рабочие типы поддерживаются, но разная детализация лога. |
| `V-C.1/V-C.2` | `J-C.5.1/5.2` | partial | Для type 5 в VBA есть детальная диагностика поиска заголовков/диапазонов; в Java сейчас в основном агрегат staging. |
| `V-C.3` | `J-C.5.2` | partial | Перебор строк в VBA логируется детально; в Java отражается в суммарной статистике. |
| `V-C.R.*` | `J-C.5.3` | missing | Прямого row-level эквивалента `paragraph` (на каждую строку) в Java пока нет. |
| `V-B.*` | `J-C.x` | parked/missing | Legacy-ветка `paragraph` не раскрывается в текущем scope. |

## Event Catalog (compact, source-of-truth)

Ниже — компактный перечень ключей событий, применяемый для реализации и проверки соответствия `V-* -> J-*`.

| eventKey | scope | phase | Минимальные поля | Примечание |
|---|---|---|---|---|
| `AUDIT_START` | `AUDIT` | `START` | `auditId`, `auditName`, `auditDir`, `startedAt` | Оркестровочный старт ревизии. |
| `AUDIT_END` | `AUDIT` | `END` | `auditId`, `finishedAt`, `durationSec`, `status` | Оркестровочное завершение ревизии. |
| `DIR_LOOKUP_NOT_FOUND` | `AUDIT` | `WARN` | `auditId`, `dirId` | Нет директории в справочнике. |
| `DIR_FS_EXISTS` | `AUDIT` | `INFO` | `auditId`, `dirPath` | Директория найдена в ФС. |
| `DIR_FS_MISSING` | `AUDIT` | `WARN` | `auditId`, `dirPath` | Директория отсутствует в ФС. |
| `FILE_START` | `FILE` | `START` | `auditId`, `filePath`, `fileType` | Начало обработки файла. |
| `FILE_END` | `FILE` | `END` | `auditId`, `filePath`, `durationSec` | Завершение обработки файла. |
| `FILE_FS_FOUND` | `FILE` | `INFO` | `auditId`, `filePath`, `checkedAt` | Файл найден в ФС. |
| `FILE_FS_MISSING` | `FILE` | `WARN` | `auditId`, `filePath` | Файл не найден в ФС. |
| `WORKBOOK_OPEN` | `FILE` | `INFO` | `filePath`, `openedAt` | Фактическое событие `DefaultAuditStagingService`. |
| `WORKBOOK_CLOSE` | `FILE` | `INFO` | `filePath`, `closedAt`, `durationSec` | Фактическое событие `DefaultAuditStagingService`. |
| `SHEET_FOUND` | `FILE` | `INFO` | `filePath`, `sheetName` | Лист найден. |
| `SHEET_MISSING` | `FILE` | `WARN` | `filePath`, `sheetName` | Лист не найден. |
| `STAGING_START` | `FILE` | `START` | `filePath`, `tableName`, `sheetName` | Старт загрузки staging. |
| `STAGING_LOAD_STATS` | `FILE` | `INFO` | `filePath`, `tableName`, `inserted`, `skipped*` | Итоговая статистика загрузки. |
| `STAGING_END` | `FILE` | `END` | `filePath`, `tableName`, `durationSec` | Завершение загрузки staging. |
| `RECONCILE_START` | `FILE` | `START` | `execKey`, `fileType` | Старт reconcile. |
| `RECONCILE_DONE` | `FILE` | `END` | `execKey`, `fileType`, `counters` | Завершение reconcile с counters. |
| `RECONCILE_SKIPPED` | `FILE` | `END` | `execKey`, `fileType`, `reason` | Reconcile пропущен. |
| `AUDIT_ERROR` | `AUDIT` | `ERROR` | `auditId`, `message` | Ошибка выполнения ревизии. |

### Правило визуального оформления

- В Java-данных хранится семантика: `messageType`, `colorHint`, `emphasis`, `messageText`, `params`.
- HTML — только слой рендера в `adt_results`, не source-of-truth.

## Implementation Backlog (compact)

- `P1`: закрыть `missing` в `V-A`/`J-A` для оркестровки (`msg.start`, `dir.*`, `file fs.*`, `msg.end`).
- `P1`: синхронизировать `messageType/colorHint` для всех `J-A [TARGET]` и фактических `J-B.1.1/1.2`.
- `P2`: для `semantic`-узлов (`V-A ... Excel open/close`) решить, нужен ли отдельный app-level event или достаточно `WORKBOOK_*`.
- `P2`: расширить mapping на type-specific оркестровочные сообщения (`af_type=2/3/5/6`) в том же формате `map/status/gap`.
- `P3`: перейти к row-level эквивалентам `paragraph` (ветка `V-C.R.*`), сохраняя ту же систему статусов.
