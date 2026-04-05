---
title: "Audit log: VBA → Java mapping (ход ревизии)"
created: "2026-03-26"
lastUpdated: "2026-04-05"
status: "draft"
version: "0.2.0"
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
    - `map -> J-A.1.msg.start [MSG]`
    - `status -> present`
    - `gap -> цветовая семантика пока в HTML-тексте; структурированные `colorHint/messageType/emphasis` как source-of-truth — следующий шаг`
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
        - `map -> J-A.1.2.msg.dir.lookup.missing [MSG]`
        - `status -> present`
        - `gap -> требуется выравнивание структурированных полей визуальной семантики (`colorHint/messageType/emphasis`)`
        - **Поля:** `Me!adt_results`
        - **Шаблон:**
          ```vb
          Me!adt_results = "<P>Не обнаружена <font color=""red"">директория</font> для ревизии</P>" & Me!adt_results
          ```
      - `V-A.1.2.b.a1 [TERMINAL]` `### TERMINAL: DIR_LOOKUP_NOT_FOUND`
      - `V-A.1.2.b.b.msg [MSG]`
        - `map -> J-A.1.2.msg.dir.lookup.found [MSG]`
        - `status -> present`
        - `gap -> требуется выравнивание структурированных полей визуальной семантики (`colorHint/messageType/emphasis`)`
        - **Поля:** `strDir`, `Me!adt_results`
        - **Шаблон:**
          ```vb
          Me!adt_results = "<P>Имя директории *<B><font color=""green"">" & strDir & "</font></B>* для ревизии обнаружено</P>" _
              & Me!adt_results
          ```
      - `V-A.1.2.b.b.check [CHECK]` Директория существует в ФС?
        - `V-A.1.2.b.b.check.a [MSG]`
          - `map -> J-A.1.2.b.msg.dir.fs.missing [MSG]`
          - `status -> present`
          - `gap -> формулировка Java-сообщения менее акцентная, чем в VBA (semantic parity)`
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
          - `map -> J-A.1.2.b.msg.dir.fs.found [MSG]`
          - `status -> present`
          - `gap -> формулировка Java-сообщения менее акцентная, чем в VBA (semantic parity)`
          - **Поля:** `strDir`, `Me!adt_results`
          - **Шаблон:**
            ```vb
            Me!adt_results = "<P>Директория с именем *<B><font color=""green"">" & strDir & "</font></B>* в файловой системе обнаружена</P>" _
                & Me!adt_results
            ```
        - `V-A.1.2.b.b.check.b1 [MSG]`
          - `map -> J-B.1.1`
          - `status -> semantic`
          - `gap -> принято как целевое решение: используем `WORKBOOK_OPEN` из `J-B` без отдельного app-level события`
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
                  - `map -> J-A.1.3.2.msg.file.fs.found [MSG]`
                  - `status -> present`
                  - `gap -> формулировка Java-сообщения менее акцентная, чем в VBA (semantic parity)`
                  - **Поля:** `DateTime.Now`, `strFile`, `Me!adt_results`
                  - **Шаблон:**
                    ```vb
                    Me!adt_results = "<P>" & DateTime.Now & " - Файл с именем *<B>" & strFile _
                        & "</B>* в файловой системе обнаружен</P>" & Me!adt_results
                    ```
                - `V-A.1.2.b.b.check.b2.0.a.0.a1 [MSG]`
                  - `map -> J-B.1.1`
                  - `status -> semantic`
                  - `gap -> принято как целевое решение: открытие файла покрывается `WORKBOOK_OPEN` без отдельного app-level/file-open события`
                  - **Поля:** `DateTime.Now`, `strFile`, `Me!adt_results`
                  - **Шаблон:**
                    ```vb
                    Me!adt_results = _
                        "<P>" & DateTime.Now & " - Файл с именем *<B><font color=""green"">" & strFile _
                        & "</font></B>* в приложении открыт</P>" & Me!adt_results
                    ```
                - `V-A.1.2.b.b.check.b2.0.a.0.b [MSG]`
                  - `map -> J-A.1.3.2.msg.file.fs.missing [MSG]`
                  - `status -> present`
                  - `gap -> формулировка Java-сообщения менее акцентная, чем в VBA (semantic parity)`
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
                      - `map -> J-C.5.B.2 SHEET_MISSING [MSG]`
                      - `status -> present`
                      - `gap -> Java-сообщение `SHEET_MISSING` эмитируется из `DefaultAuditStagingService`; VBA-текст про «в книге» и `DateTime.Now` — semantic расхождение, смысл идентичен`
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
              - `map -> J-A.1.3.msg.files.empty [MSG]`
              - `status -> present`
              - `gap -> Java-сообщение реализовано как оркестровочный WARN без HTML-акцента VBA`
              - **Поля:** `Me!adt_results`
              - **Шаблон:**
                ```vb
                Me!adt_results = "<P>Не обнаружены файлы для рассмотрения</P>" & Me!adt_results
                ```
            - `V-A.1.2.b.b.check.b2.0.b1 [ACTION]` Переход к `V-A.1.msg.end`
  - `V-A.1.msg.excel.close [MSG]`
    - `map -> J-B.1.2`
    - `status -> semantic`
    - `gap -> принято как целевое решение: закрытие покрывается `WORKBOOK_CLOSE` без отдельного app-level события`
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
    - `map -> J-A.1.msg.end [MSG]`
    - `status -> present`
    - `gap -> цветовая семантика пока в HTML-тексте; структурированные `colorHint/messageType/emphasis` как source-of-truth — следующий шаг`
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

### V-C. `ra_aAllAgents.cls :: Audit -> RaReadOfExcel` (актуальная ветка type 5, детализированный inventory)

- `V-C.1 [ACTION]` Вход в `ra_aAllAgents.Audit` (вызов из `btnAuditRun_Click` при `af_type=5`).
- `V-C.2 [ACTION]` Поиск и валидация структуры листа `Отчёты обычные` (`CellFind` по обязательным колонкам/смещениям).
  - `V-C.2.1 [CHECK]` Ключевые колонки и диапазон найдены?
    - `V-C.2.1.a [MSG]` Диапазон данных найден: колонка, первая/последняя строка, адрес (`colorHint=BLUE`, `messageType=INFO`).
      - `map -> J-C.5.B.2 [MSG][TARGET]`
      - `status -> partial`
      - `gap -> в Java пока нет полного вывода адреса диапазона и всех координат (как в VBA)`
      - **Поля:** `ra_RA.Column`, `ra_RA.Row`, `ra_RA.Rows.Count`, `ra_RA.Address`, `adt_results`
      - **Шаблон (VBA):**
        ```vb
        str = "<P>  <font color=""gray"">...</font> <font color=""blue"">*...*</font>, колонка - " _
            & ra_RA.Column & ", первая строка - " & ra_RA.Row & ", последняя строка - " _
            & ra_RA.Row + ra_RA.Rows.count - 1 & ". Адрес: <font color=""blue"">" & ra_RA.Address & "</font>.</P>"
        ```
    - `V-C.2.1.a.1 [ACTION]` Перебор найденных строк (`Find/FindNext`) и вызов `RaReadOfExcel(...)`.
      - `V-C.2.1.a.1.filter [CHECK]` Критерий отбора строк для загрузки в staging.
        - `map -> J-C.5.B.4`
        - `status -> present`
        - `gap -> механизм отбора отличается: VBA использует `Find("*???????-*")` + `FindNext`; Java — линейный проход с фильтром по полю `Признак` из whitelist (`ОА`/`ОА изм`/`ОА прочие`) в `ags.ra_sheet_conf`. Семантический результат идентичен. Реализовано в `1.8.10.5` ✅.`
      - `V-C.2.1.a.1.1 [MSG]` Для каждой строки формируется row-level `paragraph` (добавляется в начало лога).
        - `map -> J-C.5.B/J-C.5.C`
        - `status -> partial`
        - `gap -> в Java реализован row-level preview (`ROW_PARAGRAPH_PREVIEW*`), но в режиме `top-N + counters`; это не полный эквивалент VBA-лога по каждой строке.`
      - `V-C.2.1.a.1.1.a [ACTION]` `RaReadOfExcel` (row-level слой, источник строк `ra_ImpNew`).
        - `V-C.2.1.a.1.1.a.1 [MSG]` Старт `paragraph`: тип/номер ОА, стройка и контекст строки.
          - `map -> J-C.5.B.4 / ROW_PARAGRAPH_PREVIEW`
          - `status -> partial`
          - `gap -> в Java сообщение есть, но выводится ограниченной выборкой (`ROW_PREVIEW_LIMIT`) и без полного VBA-форматирования/контекста каждой строки.`
          - **Поля:** `ra_type`, `ra`, `Constraction`, `ra_Row`
          - **Шаблон (VBA):**
            ```vb
            paragraph = "<P>  <font color=""Silver"">Найден тип: </font>*" _
                & ra_type & "*; <font color=""Silver"">№</font>: " & ra_ & ". ..."
            ```
        - `V-C.2.1.a.1.1.a.2 [CHECK]` `af_source=true`?
          - `V-C.2.1.a.1.1.a.2.a [ACTION]` Запись строки в `ra_ImpNew`.
          - `V-C.2.1.a.1.1.a.2.a.1 [MSG]` Успешная вставка в импорт с ID (`colorHint=GREEN`, `messageType=SUCCESS`).
            - `map -> J-C.5.C.3 [MSG][TARGET]`
            - `status -> missing`
            - `gap -> в Java фиксируются агрегированные счётчики apply, но нет row-level подтверждения по каждой строке`
            - **Поля:** `ra_`, `ra_date`, `rainRow (ID)`, `paragraph`
            - **Шаблон (VBA):**
              ```vb
              paragraph = paragraph & " <font color=""orange"">по <b>" & ra_ & "</b> ...</font>" _
                  & " ... <font color=""DarkGreen"">добавлен в импорт. ID - " & raRow & "</font> ..."
              ```
          - `V-C.2.1.a.1.1.a.2.b [ACTION]` Только формирование `paragraph` без вставки.
        - `V-C.2.1.a.1.1.a.3 [ACTION]` `str = paragraph & str`.
      - `V-C.2.1.a.1.2 [TERMINAL]` `### TERMINAL: TYPE5_PARAGRAPH_APPENDED`.
    - `V-C.2.1.b [MSG]` Ключевой столбец/маркер не найден либо найден в неверной колонке (`colorHint=RED`, `messageType=ERROR`).
      - `map -> J-C.5.B.2 [MSG][TARGET]`
      - `status -> partial`
      - `gap -> в Java отсутствует детализация причины (не найдено / найдено в неверной колонке)`
      - **Поля:** `cellRaNumColumn`, `c.Column`, `adt_results`
      - **Шаблон (VBA):**
        ```vb
        str = "<P> ... <B><font color=""mediumVioletRed"">данные не найдены</font></B> ...</P>"
        ```
    - `V-C.2.1.b1 [TERMINAL]` `### TERMINAL: TYPE5_REQUIRED_COLUMNS_OR_RANGE_MISSING`.

- `V-C.3 [ACTION]` Блок RA из `Audit`: агрегаты и детализация `ra_ImpNewQuRa`.
  - `V-C.3.1 [MSG]` Всего строк RA в staging (summary count).
    - `map -> J-C.5.C [MSG][TARGET]`
    - `status -> missing`
    - `gap -> в Java нет отдельного MSG «Всего строк отчётов: N» перед блоком RA; целевой `eventKey: RA_ROWS_SUMMARY` (1.8.11.3.1)`
    - **Поля:** `rsRaAll.RecordCount`
    - **Шаблон (VBA):**
      ```vb
      "<P>Всего строк отчётов: <b>" & rsRaAll.RecordCount & "</b></P>"
      ```
  - `V-C.3.2 [MSG]` Новые RA (`ra_key is null`) — count + построчная детализация через `AuditRaCreateNew`.
    - `map -> J-C.5.C.2/J-C.5.C.3 [MSG][TARGET]`
    - `status -> partial`
    - `gap -> Java отражает категории счётчиками в `RECONCILE_TYPE5_MATCH_STATS`, но без VBA-детализации текста по строкам. Целевые события: `RA_NEW_CREATED`, `RA_NEW_SUMS`, `RA_VALIDATION_FAIL` (1.8.11.5.1–5.3)`
    - **Поля:** `rsRaNew.RecordCount`, `rainRow`, `rainRaNum`, `periodKey`, `cstapKey`, `ogKey`, `rainSign`, `exTtl/exWork/exEquip/exOthers`
    - **Шаблон (VBA):**
      ```vb
      "<P><font color=""Crimson"">... отчёты</font> ...: <b>" & rsRaNew.RecordCount & "</b></P>"
      ```
    - `V-C.3.2.a [ACTION]` `AuditRaCreateNew` (создание RA).
      - `V-C.3.2.a.1 [MSG]` Создан новый RA + ключ.
        - `map -> J-C.5.C.3 [MSG][TARGET]`
        - `status -> missing`
        - `gap -> в Java нет row-level сообщения о создании RA; целевой `eventKey: RA_NEW_CREATED` (1.8.11.5.1)`
        - **Поля:** `rainRow`, `rainRaNum`, `ra_key`
        - **Шаблон (VBA):**
          ```vb
          str = "<P>" & iii & ". " & rsRaNew!rainRow & ". ... " & rsRaNew!rainRaNum & " ... создан ... ключ: " & raRa.lngRaKey
          ```
      - `V-C.3.2.a.2 [MSG]` Добавлены суммы (`ttl/work/equip/others`) либо "суммы отсутствуют".
        - `map -> J-C.5.C.3 [MSG][TARGET]`
        - `status -> missing`
        - `gap -> в Java суммы видны агрегатно в apply stats, но нет строкового сообщения по конкретной записи; целевой `eventKey: RA_NEW_SUMS` (1.8.11.5.2)`
        - **Поля:** `exTtl`, `exWork`, `exEquip`, `exOthers`, `rasmRaSm.*`
        - **Шаблон (VBA):**
          ```vb
          str = str & ". суммы: total=" & FormatCurrency(rasmRaSm.curRaSmTtl) & ", work=..."
          ```
      - `V-C.3.2.a.3 [MSG]` Отказы валидации: отсутствуют `ra_num/period/cstap/sender`, неподдерживаемый `sign`, ошибка создания суммы (`colorHint=ORANGE_RED`, `messageType=WARN/ERROR`).
        - `map -> J-C.5.C.4 [MSG][TARGET]`
        - `status -> partial`
        - `gap -> Java даёт diagnostics, но не человекочитаемую причину отказа по каждой строке; целевой `eventKey: RA_VALIDATION_FAIL` (1.8.11.5.3)`
        - **Поля:** `rainRaNum`, `periodKey`, `cstapKey`, `ogKey`, `rainSign`
  - `V-C.3.3 [MSG]` Изменённые RA (`ra_key is not null and rs=false`) — count + построчная детализация через `AuditRaEdit`.
    - `map -> J-C.5.C.2/J-C.5.C.3 [MSG][TARGET]`
    - `status -> partial`
    - `gap -> в Java есть counters CHANGED/UPDATED в `RECONCILE_TYPE5_MATCH_STATS`, но нет полного old/expected/updated текста по каждому полю. Целевые события: `RA_FIELD_MISMATCH`, `RA_FIELD_UPDATED`, `RA_SUM_MISMATCH` (1.8.11.5.4–5.6)`
    - **Поля:** `rsRaErr.RecordCount`, `rainRow`, `ra_key`, `rs*` флаги, `ex*` поля, `domain old values`
    - **Шаблон (VBA):**
      ```vb
      "<P><font color=""Crimson"">... отчёты</font> ...: <b>" & rsRaErr.RecordCount & "</b></P>"
      ```
    - `V-C.3.3.a [ACTION]` `AuditRaEdit` (корректировка существующего RA).
      - `V-C.3.3.a.1 [MSG]` Поле не совпадает: old (Crimson) vs expected (Peru).
        - `map -> J-C.5.C.2 [MSG][TARGET]`
        - `status -> missing`
        - `gap -> Java не выводит row-level diff по полям; целевой `eventKey: RA_FIELD_MISMATCH` (1.8.11.5.4)`
        - **Поля:** `rsArrv/rsDate/...`, `raRa.<field old>`, `rsRaErr!ex<field>`
      - `V-C.3.3.a.2 [MSG]` После apply: updated value (SeaGreen).
        - `map -> J-C.5.C.3 [MSG][TARGET]`
        - `status -> missing`
        - `gap -> Java не публикует row-level "updated" значения в лог; целевой `eventKey: RA_FIELD_UPDATED` (1.8.11.5.5)`
        - **Поля:** `addRa`, `raRa.<field new>`
      - `V-C.3.3.a.3 [MSG]` Суммовой блок: mismatch по компонентам + пересоздание/добавление суммы.
        - `map -> J-C.5.C.3 [MSG][TARGET]`
        - `status -> partial`
        - `gap -> есть итоговые sum counters в apply stats, но нет детализации по компонентам суммы; целевой `eventKey: RA_SUM_MISMATCH` (1.8.11.5.6)`
        - **Поля:** `rsTtl/rsWork/rsEquip/rsOthers`, `rasmRaSm`, `exTtl/exWork/exEquip/exOthers`
  - `V-C.3.4 [MSG]` Лишние RA в домене (нет в текущем source) — count + построчный список кандидатов на удаление.
    - `map -> J-C.5.C.4 [MSG][TARGET]`
    - `status -> partial`
    - `gap -> Java delete-план отражается в diagnostics агрегатно, но без построчного списка имён как в VBA; целевой `eventKey: RA_EXCESS_ITEM` (1.8.11.5.7)`
    - **Поля:** `rsRaExr.RecordCount`, `ra_key`, `ra_name`, `addRa`
    - **Шаблон (VBA):**
      ```vb
      "<P><font color=""Crimson"">... в БД, но отсутствуют в источнике</font>: <b>" & rsRaExr.RecordCount & "</b></P>"
      str = "<p>" & iii & ". <font color=""Crimson"">" & raRaExr.strRaName & "</font> ...</p>"
      ```
  - `V-C.3.5 [CHECK]` `addRa=true`? При true применяются create/update/delete; при false — диагностический режим без apply.
    - `map -> J-C.5.C [MSG][TARGET]`
    - `status -> partial`
    - `gap -> в Java режим отражается неявно (поле `addRa` в meta `RECONCILE_TYPE5_START`), без явного MSG в лог; целевой `eventKey: RECONCILE_TYPE5_MODE` (1.8.11.4.5)`
    - `V-C.3.5.a [ACTION]` apply enabled: create/update/delete + обновление сумм
    - `V-C.3.5.b [ACTION]` dry-run: только диагностика/подсчёты, без изменений в домене

- `V-C.4 [ACTION]` Блок RC из `Audit`: агрегаты и детализация `ra_ImpNewQuRc`.
  - `V-C.4.1 [MSG]` Всего строк RC в staging (summary count).
    - `map -> J-C.5.C [MSG][TARGET]`
    - `status -> missing`
    - `gap -> в Java нет отдельного MSG «Всего строк изменений: N» перед блоком RC; целевой `eventKey: RC_ROWS_SUMMARY` (1.8.11.3.2)`
    - **Поля:** `rsRaAll.RecordCount`
    - **Шаблон (VBA):**
      ```vb
      "<P>Всего строк изменений: <b>" & rsRaAll.RecordCount & "</b></P>"
      ```
  - `V-C.4.2 [MSG]` Новые RC (`rac_key is null`) — count + построчная детализация через `AuditRcCreateNew`.
    - `map -> J-C.5.C.2/J-C.5.C.3 [MSG][TARGET]`
    - `status -> partial`
    - `gap -> Java NEW по RC есть как категория в `RECONCILE_TYPE5_MATCH_STATS`, но без VBA row-level текста. Целевые события: `RC_NEW_CREATED`, `RC_NEW_SUMS`, `RC_VALIDATION_FAIL` (1.8.11.6.1–6.3)`
    - **Поля:** `rsRaNew.RecordCount`, `rainRow`, `rainRaNum`, `ra_key`, `rcPeriod`, `num`, `exSender`, `ex* sums`
    - **Шаблон (VBA):**
      ```vb
      "<P><font color=""Crimson"">... изменения</font> ...: <b>" & rsRaNew.RecordCount & "</b></P>"
      ```
    - `V-C.4.2.a [ACTION]` `AuditRcCreateNew` (создание RC).
      - `V-C.4.2.a.1 [MSG]` Создано изменение RC + ключ.
        - `map -> J-C.5.C.3 [MSG][TARGET]`
        - `status -> missing`
        - `gap -> в Java нет row-level сообщения о создании RC; целевой `eventKey: RC_NEW_CREATED` (1.8.11.6.1)`
        - **Поля:** `rainRow`, `rainRaNum`, `rac_key`
      - `V-C.4.2.a.2 [MSG]` Добавлены суммы RC либо "суммы отсутствуют".
        - `map -> J-C.5.C.3 [MSG][TARGET]`
        - `status -> missing`
        - `gap -> нет row-level сообщения по суммам RC; целевой `eventKey: RC_NEW_SUMS` (1.8.11.6.2)`
        - **Поля:** `exTtl`, `exWork`, `exEquip`, `exOthers`, `rcsmRcSm.*`
      - `V-C.4.2.a.3 [MSG]` Отказы валидации: отсутствуют `ra_key/period/num/sender`, ошибка создания RC/сумм.
        - `map -> J-C.5.C.4 [MSG][TARGET]`
        - `status -> partial`
        - `gap -> Java фиксирует часть причин в diagnostics, но не как отдельные человекочитаемые строки; целевой `eventKey: RC_VALIDATION_FAIL` (1.8.11.6.3)`
        - **Поля:** `ra_key`, `rcPeriod`, `num`, `exSender`
  - `V-C.4.3 [MSG]` Изменённые RC (`rac_key is not null and rs=false`) — count + построчная детализация через `AuditRcEdit`.
    - `map -> J-C.5.C.2/J-C.5.C.3 [MSG][TARGET]`
    - `status -> partial`
    - `gap -> Java CHANGED по RC отражается в counters `RECONCILE_TYPE5_MATCH_STATS`, но без покомпонентного diff-текста. Целевые события: `RC_FIELD_MISMATCH`, `RC_FIELD_UPDATED`, `RC_SUM_MISMATCH` (1.8.11.6.4–6.6)`
    - **Поля:** `rsRaErr.RecordCount`, `rainRow`, `rac_key`, `rs*` флаги, `ex*` поля, `domain old values`
    - **Шаблон (VBA):**
      ```vb
      "<P><font color=""Crimson"">... изменения</font> ...: <b>" & rsRaErr.RecordCount & "</b></P>"
      ```
    - `V-C.4.3.a [ACTION]` `AuditRcEdit` (корректировка существующего RC).
      - `V-C.4.3.a.1 [MSG]` Поле не совпадает: old (Crimson) vs expected (Peru).
        - `map -> J-C.5.C.2 [MSG][TARGET]`
        - `status -> missing`
        - `gap -> нет row-level diff-сообщений old vs expected; целевой `eventKey: RC_FIELD_MISMATCH` (1.8.11.6.4)`
        - **Поля:** `rsArrv/rsDate/...`, `rcRc.<field old>`, `rsRaErr!ex<field>`
      - `V-C.4.3.a.2 [MSG]` После apply: updated value (SeaGreen).
        - `map -> J-C.5.C.3 [MSG][TARGET]`
        - `status -> missing`
        - `gap -> нет row-level "updated" сообщений по RC; целевой `eventKey: RC_FIELD_UPDATED` (1.8.11.6.5)`
        - **Поля:** `addRa`, `rcRc.<field new>`
      - `V-C.4.3.a.3 [MSG]` Суммовой блок: mismatch по компонентам + пересоздание/добавление суммы.
        - `map -> J-C.5.C.3 [MSG][TARGET]`
        - `status -> partial`
        - `gap -> в Java только агрегаты по суммам без детального текста по компонентам; целевой `eventKey: RC_SUM_MISMATCH` (1.8.11.6.6)`
        - **Поля:** `rsTtl/rsWork/rsEquip/rsOthers`, `rcsmRcSm`, `exTtl/exWork/exEquip/exOthers`
  - `V-C.4.4 [MSG]` Лишние RC в домене (нет в текущем source) — count + построчный список кандидатов на удаление.
    - `map -> J-C.5.C.4 [MSG][TARGET]`
    - `status -> partial`
    - `gap -> в Java RC delete отражается как агрегат planned/applied, но без построчного перечня имён как в VBA; целевой `eventKey: RC_EXCESS_ITEM` (1.8.11.6.7)`
    - **Поля:** `rsRaExr.RecordCount`, `rac_key`, `rc_name`, `addRa`
    - **Шаблон (VBA):**
      ```vb
      "<P><font color=""Crimson"">... изменения в БД, но отсутствуют в источнике</font>: <b>" & rsRaExr.RecordCount & "</b></P>"
      str = "<p>" & iii & ". <font color=""Crimson"">" & rcRcExr.strRcName & "</font> ...</p>"
      ```
  - `V-C.4.5 [CHECK]` `addRa=true`? При true применяются create/update/delete; при false — диагностический режим без apply.
    - `map -> J-C.5.C [MSG][TARGET]`
    - `status -> partial`
    - `gap -> аналогично `V-C.3.5`: режим отражается неявно; см. `RECONCILE_TYPE5_MODE` (1.8.11.4.5)`
    - `V-C.4.5.a [ACTION]` apply enabled: create/update/delete + обновление сумм
    - `V-C.4.5.b [ACTION]` dry-run: только диагностика/подсчёты, без изменений в домене

## Дерево Java (по классам/файлам, рабочие типы `2/3/5/6`)

**Решение по workbook lifecycle (фиксировано):**
для сообщений VBA уровня "приложение Excel открыто/закрыто" и "файл в приложении открыт" сохраняем соответствие `semantic` через фактические `J-B.1.1/1.2` (`WORKBOOK_OPEN/CLOSE`) без добавления отдельных app-level событий в `J-A`.

### J-A. `AuditExecutionServiceImpl` (общая оркестровка)

- `J-A.1 [ACTION]` Запуск ревизии (`executeAudit`)
  - `J-A.1.1 [ACTION]` `AUDIT_START`
  - `J-A.1.msg.start [MSG]` Оркестрационный старт (эквивалент `V-A.1.msg.start`)
    - **Контракт полей:** `auditId`, `auditName`, `auditDir`, `startedAt`, `colorHint=RED`, `emphasis=BOLD`, `messageType=START`
    - **Статус:** `present` (реализовано в `AuditExecutionServiceImpl` через `AUDIT_START`)
  - `J-A.1.2 [CHECK]` dir lookup
    - `J-A.1.2.msg.dir.lookup.missing [MSG]` Директория ревизии не найдена в справочнике (эквивалент `V-A.1.2.b.a`)
      - **Контракт полей:** `auditId`, `auditDirRef`, `messageType=ERROR`, `colorHint=RED`, `emphasis=BOLD`
      - **Статус:** `present` (реализовано в `AuditExecutionServiceImpl` через `DIR_LOOKUP_NOT_FOUND`)
    - `J-A.1.2.msg.dir.lookup.found [MSG]` Имя директории ревизии найдено (эквивалент `V-A.1.2.b.b.msg`)
      - **Контракт полей:** `auditId`, `dirName`, `messageType=INFO`, `colorHint=GREEN`, `emphasis=BOLD`
      - **Статус:** `present` (реализовано в `AuditExecutionServiceImpl` через `DIR_LOOKUP_FOUND`)
    - `J-A.1.2.a [TERMINAL]` `### TERMINAL: DIR_LOOKUP_NOT_FOUND`
    - `J-A.1.2.b [CHECK]` dir fs exists/missing
      - `J-A.1.2.b.msg.dir.fs.missing [MSG]` Директория отсутствует в ФС (эквивалент `V-A.1.2.b.b.check.a`)
        - **Контракт полей:** `auditId`, `dirPath`, `messageType=ERROR`, `colorHint=RED`, `emphasis=BOLD`
        - **Статус:** `present` (реализовано в `AuditExecutionServiceImpl` через `DIR_FS_MISSING`)
      - `J-A.1.2.b.msg.dir.fs.found [MSG]` Директория обнаружена в ФС (эквивалент `V-A.1.2.b.b.check.b`)
        - **Контракт полей:** `auditId`, `dirPath`, `messageType=SUCCESS`, `colorHint=GREEN`, `emphasis=BOLD`
        - **Статус:** `present` (реализовано в `AuditExecutionServiceImpl` через `DIR_FS_EXISTS`)
  - `J-A.1.3 [ACTION]` Цикл файлов (`FILE_START/FILE_END`)
    - `J-A.1.3.1 [CHECK]` skip by config
    - `J-A.1.3.2 [CHECK]` file fs exists/missing
      - `J-A.1.3.2.msg.file.fs.found [MSG]` Файл обнаружен в ФС (эквивалент `V-A.1.2.b.b.check.b2.0.a.0.a`)
        - **Контракт полей:** `auditId`, `filePath`, `checkedAt`, `messageType=INFO`, `colorHint=GREEN`
        - **Статус:** `present` (реализовано в `AuditExecutionServiceImpl` через `FILE_FS_FOUND`)
      - `J-A.1.3.2.msg.file.fs.missing [MSG]` Файл отсутствует в ФС (эквивалент `V-A.1.2.b.b.check.b2.0.a.0.b`)
        - **Контракт полей:** `auditId`, `filePath`, `messageType=ERROR`, `colorHint=RED`, `emphasis=BOLD`
        - **Статус:** `present` (реализовано в `AuditExecutionServiceImpl` через `FILE_FS_MISSING`)
    - `J-A.1.3.3 [ACTION]` вызов file-processor по `af_type=2/3/5/6`
    - `J-A.1.3.msg.files.empty [MSG]` Не обнаружены файлы для рассмотрения (эквивалент `V-A.1.2.b.b.check.b2.0.b`)
      - **Контракт полей:** `auditId`, `messageType=WARNING`, `colorHint=RED`, `emphasis=NORMAL`
      - **Статус:** `present` (реализовано в `AuditExecutionServiceImpl` через `FILES_EMPTY`)
  - `J-A.1.msg.end [MSG]` Оркестрационное завершение (эквивалент `V-A.1.msg.end`)
    - **Контракт полей:** `finishedAt`, `startedAt`, `durationSec`, `durationHuman`, `status`, `colorHint=BLUE`, `emphasis=BOLD`, `messageType=END`
    - **Статус:** `present` (реализовано в `AuditExecutionServiceImpl` через `AUDIT_END`)

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
- `J-C.5 [ACTION]` Type 5 (target-tree c разбиением по существующим Java-файлам)
  - `J-C.5.A [ACTION]` `AllAgentsAuditFileProcessor` (file-level orchestration)
    - `J-C.5.A.1 [MSG][TARGET]` `FILE_ALL_AGENTS_STAGE1` — старт/итог Stage 1 для файла
      - **eventKey:** `FILE_ALL_AGENTS_STAGE1`; **scope:** `FILE`
      - **Минимальные meta-поля:** `auditId`, `filePath`, `fileType`, `insertedRows`, `messageType`, `colorHint`, `emphasis`
      - **map/status/gap:** `map -> V-C.3/V-C.4`, `status -> partial`, `gap -> в VBA этапы RA/RC детализированы по категориям и строкам; в Java пока агрегат по файлу`
    - `J-C.5.A.2 [MSG][TARGET]` `FILE_ALL_AGENTS_STAGE2_NOOP` — фиксация второго этапа (архитектурный no-op)
      - **eventKey:** `FILE_ALL_AGENTS_STAGE2_NOOP`; **scope:** `FILE`
      - **Минимальные meta-поля:** `auditId`, `filePath`, `fileType`, `reason`, `messageType`, `colorHint`, `emphasis`
      - **map/status/gap:** `map -> V-C.3.5/V-C.4.5`, `status -> semantic`, `gap -> в VBA нет отдельного сообщения "stage2 no-op"; поведение покрывает фазу принятия решения apply`
    - `J-C.5.A.3 [ACTION][TARGET]` Вызов reconcile coordinator
      - **map/status/gap:** `map -> V-C.3/V-C.4`, `status -> partial`, `gap -> требуется MSG-контракт начала/окончания reconcile на уровне file-processor`

  - `J-C.5.B [ACTION]` `DefaultAuditStagingService` (workbook/sheet/anchor/staging-load)
    - `J-C.5.B.1 [MSG]` `WORKBOOK_OPEN/WORKBOOK_CLOSE` (фактические события)
      - **eventKey:** `WORKBOOK_OPEN`, `WORKBOOK_CLOSE`; **scope:** `FILE`
      - **map/status/gap:** `map -> V-A.1.2.b.b.check.b1 / V-A.1.msg.excel.close`, `status -> semantic`, `gap -> принятое решение: app-level Excel события не добавляются`
    - `J-C.5.B.2 [MSG][TARGET]` `SHEET_FOUND/SHEET_MISSING` (лист/диапазон)
      - **eventKey:** `SHEET_FOUND`, `SHEET_MISSING`; **scope:** `FILE`
      - **Минимальные meta-поля:** `auditId`, `filePath`, `sheetName`, `sheetConfigKey`, `messageType`, `colorHint`, `emphasis`
      - **map/status/gap:** `map -> V-C.2.1.a / V-C.2.1.b`, `status -> partial`, `gap -> в VBA есть более детальная диагностика колонок/смещений/адресов`
    - `J-C.5.B.3 [MSG][TARGET]` `ANCHOR_FOUND/ANCHOR_MISSING`
      - **eventKey:** `ANCHOR_FOUND`, `ANCHOR_MISSING`; **scope:** `FILE`
      - **Минимальные meta-поля:** `auditId`, `filePath`, `sheetName`, `anchorText`, `anchorRow`, `messageType`, `colorHint`, `emphasis`
      - **map/status/gap:** `map -> V-C.2.1`, `status -> missing`, `gap -> в коде сейчас нет явного события anchor; ошибка пробрасывается исключением`
    - `J-C.5.B.4 [MSG]` `STAGING_START/STAGING_LOAD_STATS/STAGING_END` + `ROW_PARAGRAPH_PREVIEW*` (фактические события)
      - **eventKey:** `STAGING_START`, `STAGING_LOAD_STATS`, `STAGING_END`; **scope:** `FILE`
      - **map/status/gap:** `map -> V-C.2.1 / V-C.3.1 / V-C.4.1`, `status -> partial`, `gap -> в Java есть row-level preview и staging-статистика, но нет полного VBA-эквивалента: (а) отбор строк по `Find("*???????-*")`/`FindNext`, (б) отдельный summary по RA/RC как в VBA, (в) полный per-row лог без top-N ограничения.`

  - `J-C.5.C [ACTION]` `AllAgentsReconcileService` (match/apply/delete/diagnostics)
    - `J-C.5.C.1 [MSG][TARGET]` `RECONCILE_TYPE5_START`
      - **eventKey:** `RECONCILE_TYPE5_START`; **scope:** `FILE`
      - **Минимальные meta-поля:** `auditId`, `executionKey`, `fileType=5`, `addRa`, `messageType`, `colorHint`, `emphasis`
      - **map/status/gap:** `map -> V-C.3/V-C.4`, `status -> missing`, `gap -> в коде нет отдельного start-msg reconcile ветки type5`
    - `J-C.5.C.2 [MSG][TARGET]` `RECONCILE_TYPE5_MATCH_STATS`
      - **eventKey:** `RECONCILE_TYPE5_MATCH_STATS`; **scope:** `FILE`
      - **Минимальные meta-поля:** `executionKey`, `rowsEligible`, `rowsRejected`, `categoryNew`, `categoryChanged`, `categoryUnchanged`, `categoryAmbiguous`, `categoryInvalid`, `messageType`, `colorHint`, `emphasis`
      - **map/status/gap:** `map -> V-C.3.2/V-C.3.3/V-C.4.2/V-C.4.3`, `status -> partial`, `gap -> сейчас статистика в основном в технической строке diagnostics`
    - `J-C.5.C.3 [MSG][TARGET]` `RECONCILE_TYPE5_APPLY_STATS`
      - **eventKey:** `RECONCILE_TYPE5_APPLY_STATS`; **scope:** `FILE`
      - **Минимальные meta-поля:** `inserted`, `updated`, `unchanged`, `raDeleted`, `rcDeleted`, `sumInserted`, `sumUnchangedSkipped`, `messageType`, `colorHint`, `emphasis`
      - **map/status/gap:** `map -> V-C.3.5/V-C.4.5`, `status -> partial`, `gap -> в VBA apply сопровождается row-level строками old/expected/updated`
    - `J-C.5.C.4 [MSG][TARGET]` `RECONCILE_TYPE5_DIAGNOSTICS`
      - **eventKey:** `RECONCILE_TYPE5_DIAGNOSTICS`; **scope:** `FILE`
      - **Минимальные meta-поля:** `missingSenderTopN`, `missingCstTopN`, `missingPeriodTopN`, `ambiguous*`, `messageType`, `colorHint`, `emphasis`
      - **map/status/gap:** `map -> V-C.3.4/V-C.4.4`, `status -> partial`, `gap -> соответствие по смыслу есть, но детализация и формулировки отличаются`
    - `J-C.5.C.5 [MSG][TARGET]` `RECONCILE_TYPE5_DONE/RECONCILE_TYPE5_SKIPPED/RECONCILE_TYPE5_FAILED`
      - **eventKey:** `RECONCILE_TYPE5_DONE`, `RECONCILE_TYPE5_SKIPPED`, `RECONCILE_TYPE5_FAILED`; **scope:** `FILE`
      - **Минимальные meta-поля:** `executionKey`, `status`, `reason`, `durationSec`, `messageType`, `colorHint`, `emphasis`
      - **map/status/gap:** `map -> V-C.3/V-C.4`, `status -> missing`, `gap -> требуется явная trio-модель завершения reconcile type5 в adt_results`

  - `J-C.5.3 [TERMINAL]` `### TERMINAL: TYPE5_ROW_LEVEL_PARAGRAPH_EQUIVALENT_PARTIAL`
    - Комментарий: `ROW_PARAGRAPH_PREVIEW`, `ROW_PARAGRAPH_PREVIEW_SKIPPED`, `ROW_PARAGRAPH_PREVIEW_SUMMARY` реализованы, но как `top-N + counters`; полного эквивалента VBA per-row (без ограничения, с полным форматом всех строк) пока нет.
- `J-C.6 [ACTION]` Type 6: `AgFee2306AuditFileProcessor`
- `J-C.x [TERMINAL]` `### TERMINAL: PARAGRAPH_EQUIVALENT_NOT_IMPLEMENTED`

## Таблица связей узлов (актуализировано после row-level preview)

| VBA node | Java node | Status | Комментарий |
|---|---|---|---|
| `V-A.1.msg.start` | `J-A.1.msg.start [MSG]` | present | Реализовано через `AUDIT_START` (с `auditId/auditName/auditDir/startedAt`). |
| `V-A.1.2.b.a` | `J-A.1.2.msg.dir.lookup.missing [MSG]` | present | Реализовано через `DIR_LOOKUP_NOT_FOUND`. |
| `V-A.1.2.b.b.msg` | `J-A.1.2.msg.dir.lookup.found [MSG]` | present | Реализовано через `DIR_LOOKUP_FOUND`. |
| `V-A.1.2.b.b.check.a` | `J-A.1.2.b.msg.dir.fs.missing [MSG]` | present | Реализовано через `DIR_FS_MISSING`. |
| `V-A.1.2.b.b.check.b` | `J-A.1.2.b.msg.dir.fs.found [MSG]` | present | Реализовано через `DIR_FS_EXISTS`. |
| `V-A.1.2.b.b.check.b1` | `J-B.1.1` | semantic | Решение зафиксировано: app-level событие не добавляем, используем `WORKBOOK_OPEN` как ближайший аналог. |
| `V-A.1.2.b.b.check.b2.0.a.0.a` | `J-A.1.3.2.msg.file.fs.found [MSG]` | present | Реализовано через `FILE_FS_FOUND`. |
| `V-A.1.2.b.b.check.b2.0.a.0.a1` | `J-B.1.1` | semantic | Решение зафиксировано: открытие файла покрывается `WORKBOOK_OPEN` без отдельного file-open/app-level события. |
| `V-A.1.2.b.b.check.b2.0.a.0.b` | `J-A.1.3.2.msg.file.fs.missing [MSG]` | present | Реализовано через `FILE_FS_MISSING`. |
| `V-A.1.2.b.b.check.b2.0.b` | `J-A.1.3.msg.files.empty [MSG]` | present | Реализовано через `FILES_EMPTY`. |
| `V-A.1.msg.excel.close` | `J-B.1.2` | semantic | Решение зафиксировано: app-level событие не добавляем, используем `WORKBOOK_CLOSE` как ближайший аналог. |
| `V-A.1.msg.end` | `J-A.1.msg.end [MSG]` | present | Реализовано через `AUDIT_END` (с `finishedAt/startedAt/duration/status`). |
| `V-A.1.1` | `J-A.1.1` | present | Старт ревизии есть в обоих деревьях. |
| `V-A.1.2.b.*` | `J-A.1.2.*` | partial | Проверки директории есть, тексты/детали отличаются. |
| `V-A.1.2.b.b.b.1` | `J-A.1.3.*` | partial | Цикл файлов есть, часть VBA-веток агрегирована. |
| `V-A.1.2.b.b.b.2.2/3/5/6` | `J-C.2/3/5/6` | partial | Рабочие типы поддерживаются, но разная детализация лога. |
| `V-A.1.2.b.b.check.b2.0.a.1.5.1.b` | `J-C.5.B.2 SHEET_MISSING` | present | Лист «Отчёты обычные» не найден: Java эмитирует `SHEET_MISSING` из `DefaultAuditStagingService`. Семантически эквивалентно VBA-сообщению; timestamp/«в книге» — semantic расхождение. |
| `V-C.1/V-C.2` | `J-C.5.A/J-C.5.B` | present | Process-level этапы type5 реализованы (`FILE_ALL_AGENTS_STAGE*`, `WORKBOOK_*`, `SHEET_*`, `ANCHOR_*`, `STAGING_*`). |
| `V-C.2.1.a` | `J-C.5.B.2 SHEET_FOUND` | partial | Лист найден: событие есть, но без координат диапазона (column/firstRow/lastRow/address). Целевое расширение: 1.8.11.2.1. |
| `V-C.2.1.a.1.filter` | `J-C.5.B.4` | present | Фильтр строк по полю `Признак` из whitelist (`ОА`/`ОА изм`/`ОА прочие`) реализован в 1.8.10.5 ✅. Механизм отличается от VBA (`Find/FindNext`), семантический результат идентичен. |
| `V-C.2.1.a.1.1.a.2.a.1` | — | missing | Per-row staging insert ID. Целевой `eventKey: STAGING_ROW_INSERTED` (1.8.11.7.1). |
| `V-C.2.1.a.1` | `J-C.5.B/J-C.5.C` | partial | Перебор строк в VBA логируется детально; в Java покрыт через staging/reconcile + row-level preview и агрегированные counters. |
| `V-C.2.1.a.1.1.a.*` | `ROW_PARAGRAPH_PREVIEW*` | partial | Row-level preview реализован (включая summary), но в режиме `top-N + counters`; это не полный VBA-эквивалент per-row лога без ограничений. Целевая политика: полный per-row (решение А, 1.8.11.5–1.8.11.6). |
| `V-C.3.1` | — | missing | «Всего строк отчётов: N». Целевой `eventKey: RA_ROWS_SUMMARY` (1.8.11.3.1). |
| `V-C.3.2.a.1` | — | missing | RA created per row. Целевой `eventKey: RA_NEW_CREATED` (1.8.11.5.1). |
| `V-C.3.2.a.2` | — | missing | RA sums per row. Целевой `eventKey: RA_NEW_SUMS` (1.8.11.5.2). |
| `V-C.3.2.a.3` | `RECONCILE_TYPE5_DIAGNOSTICS` | partial | RA validation fail: в diagnostics частично, без per-row текста. Целевой `eventKey: RA_VALIDATION_FAIL` (1.8.11.5.3). |
| `V-C.3.3.a.1` | — | missing | RA field mismatch old/expected. Целевой `eventKey: RA_FIELD_MISMATCH` (1.8.11.5.4). |
| `V-C.3.3.a.2` | — | missing | RA updated value. Целевой `eventKey: RA_FIELD_UPDATED` (1.8.11.5.5). |
| `V-C.3.3.a.3` | `RECONCILE_TYPE5_APPLY_STATS` | partial | RA sum mismatch: агрегат есть, per-row нет. Целевой `eventKey: RA_SUM_MISMATCH` (1.8.11.5.6). |
| `V-C.3.4` | `RECONCILE_TYPE5_DIAGNOSTICS` | partial | Excess RA: aggregate, без списка имён. Целевой `eventKey: RA_EXCESS_ITEM` (1.8.11.5.7). |
| `V-C.3.5/V-C.4.5` | — | partial | dry-run vs apply: неявно в meta. Целевой `eventKey: RECONCILE_TYPE5_MODE` (1.8.11.4.5). |
| `V-C.4.1` | — | missing | «Всего строк изменений: N». Целевой `eventKey: RC_ROWS_SUMMARY` (1.8.11.3.2). |
| `V-C.4.2.a.1` | — | missing | RC created per row. Целевой `eventKey: RC_NEW_CREATED` (1.8.11.6.1). |
| `V-C.4.2.a.2` | — | missing | RC sums per row. Целевой `eventKey: RC_NEW_SUMS` (1.8.11.6.2). |
| `V-C.4.2.a.3` | `RECONCILE_TYPE5_DIAGNOSTICS` | partial | RC validation fail. Целевой `eventKey: RC_VALIDATION_FAIL` (1.8.11.6.3). |
| `V-C.4.3.a.1` | — | missing | RC field mismatch. Целевой `eventKey: RC_FIELD_MISMATCH` (1.8.11.6.4). |
| `V-C.4.3.a.2` | — | missing | RC updated value. Целевой `eventKey: RC_FIELD_UPDATED` (1.8.11.6.5). |
| `V-C.4.3.a.3` | `RECONCILE_TYPE5_APPLY_STATS` | partial | RC sum mismatch. Целевой `eventKey: RC_SUM_MISMATCH` (1.8.11.6.6). |
| `V-C.4.4` | `RECONCILE_TYPE5_DIAGNOSTICS` | partial | Excess RC: aggregate, без списка имён. Целевой `eventKey: RC_EXCESS_ITEM` (1.8.11.6.7). |
| `V-B.*` | `J-C.x` | parked/missing | Legacy-ветка `paragraph` не раскрывается в текущем scope. |

## Event Catalog (compact, source-of-truth)

Ниже — компактный перечень ключей событий, применяемый для реализации и проверки соответствия `V-* -> J-*`.

| eventKey | scope | phase | Минимальные поля | Примечание |
|---|---|---|---|---|
| `AUDIT_START` | `AUDIT` | `START` | `auditId`, `auditName`, `auditDir`, `startedAt` | Оркестровочный старт ревизии. |
| `AUDIT_END` | `AUDIT` | `END` | `auditId`, `finishedAt`, `durationSec`, `status` | Оркестровочное завершение ревизии. |
| `DIR_LOOKUP_NOT_FOUND` | `AUDIT` | `WARN` | `auditId`, `dirId` | Нет директории в справочнике. |
| `DIR_LOOKUP_FOUND` | `AUDIT` | `INFO` | `auditId`, `dirName` | Имя директории ревизии найдено в справочнике. |
| `DIR_FS_EXISTS` | `AUDIT` | `INFO` | `auditId`, `dirPath` | Директория найдена в ФС. |
| `DIR_FS_MISSING` | `AUDIT` | `WARN` | `auditId`, `dirPath` | Директория отсутствует в ФС. |
| `FILE_START` | `FILE` | `START` | `auditId`, `filePath`, `fileType` | Начало обработки файла. |
| `FILE_END` | `FILE` | `END` | `auditId`, `filePath`, `durationSec` | Завершение обработки файла. |
| `FILE_FS_FOUND` | `FILE` | `INFO` | `auditId`, `filePath`, `checkedAt` | Файл найден в ФС. |
| `FILE_FS_MISSING` | `FILE` | `WARN` | `auditId`, `filePath` | Файл не найден в ФС. |
| `FILES_EMPTY` | `AUDIT` | `WARN` | `auditId` | Для ревизии не обнаружены файлы для рассмотрения. |
| `WORKBOOK_OPEN` | `FILE` | `INFO` | `filePath`, `openedAt` | Фактическое событие `DefaultAuditStagingService`. |
| `WORKBOOK_CLOSE` | `FILE` | `INFO` | `filePath`, `closedAt`, `durationSec` | Фактическое событие `DefaultAuditStagingService`. |
| `SHEET_FOUND` | `FILE` | `INFO` | `filePath`, `sheetName` | Лист найден. |
| `SHEET_MISSING` | `FILE` | `WARN` | `filePath`, `sheetName` | Лист не найден. |
| `STAGING_START` | `FILE` | `START` | `filePath`, `tableName`, `sheetName` | Старт загрузки staging. |
| `STAGING_LOAD_STATS` | `FILE` | `INFO` | `filePath`, `tableName`, `inserted`, `skipped*` | Итоговая статистика загрузки. |
| `STAGING_END` | `FILE` | `END` | `filePath`, `tableName`, `durationSec` | Завершение загрузки staging. |
| `ANCHOR_FOUND` | `FILE` | `INFO` | `filePath`, `sheetName`, `anchorText`, `anchorRow` | Якорь заголовка найден. |
| `ANCHOR_MISSING` | `FILE` | `WARN` | `filePath`, `sheetName`, `anchorText` | Якорь заголовка не найден. |
| `RECONCILE_START` | `FILE` | `START` | `execKey`, `fileType` | Старт reconcile. |
| `RECONCILE_DONE` | `FILE` | `END` | `execKey`, `fileType`, `counters` | Завершение reconcile с counters. |
| `RECONCILE_SKIPPED` | `FILE` | `END` | `execKey`, `fileType`, `reason` | Reconcile пропущен. |
| `RECONCILE_TYPE5_START` | `FILE` | `START` | `execKey`, `fileType=5`, `addRa` | Старт reconcile для type 5 (детализированный код). |
| `RECONCILE_TYPE5_DONE` | `FILE` | `END` | `execKey`, `fileType=5`, `affectedRows` | Успешное завершение reconcile type 5. |
| `RECONCILE_TYPE5_SKIPPED` | `FILE` | `END` | `execKey`, `fileType=5`, `reason` | Пропуск reconcile type 5. |
| `RECONCILE_TYPE5_FAILED` | `FILE` | `ERROR` | `execKey`, `fileType=5`, `message` | Ошибка reconcile type 5. |
| `RECONCILE_TYPE5_MATCH_STATS` | `FILE` | `INFO` | `execKey`, `fileType=5`, `counters` | Агрегированные match/apply counters по type 5. |
| `RECONCILE_TYPE5_DIAGNOSTICS` | `FILE` | `WARN` | `execKey`, `fileType=5`, `missingTop` | Top-представление диагностик (`Нет отправителя/стройки/периода`). |
| `ROW_PARAGRAPH_PREVIEW` | `FILE` | `INFO` | `sheetName`, `rowIndex`, `status=ACCEPTED` | Row-level preview для type 5 (staging). |
| `ROW_PARAGRAPH_PREVIEW_SKIPPED` | `FILE` | `WARN` | `sheetName`, `rowIndex`, `status=SKIPPED` | Row-level preview для пропущенной строки (нет данных). |
| `ROW_PARAGRAPH_PREVIEW_SUMMARY` | `FILE` | `INFO` | `sampled`, `suppressed`, `total`, `limit` | Итог row-level staging preview. |
| `STAGING_ROW_INSERTED` | `FILE` | `INFO` | `sheetName`, `rowIndex`, `insertedId` | Строка добавлена в staging с ID (per-row, `af_source=true`). Целевой (1.8.11.7.1). |
| `RECONCILE_TYPE5_MODE` | `FILE` | `INFO` | `execKey`, `addRa`, `mode` | Режим reconcile: `DIAGNOSTIC`/`APPLY`. Целевой (1.8.11.4.5). |
| `RA_ROWS_SUMMARY` | `FILE` | `INFO` | `execKey`, `raRowsCount` | «Всего строк отчётов: N» перед блоком RA. Целевой (1.8.11.3.1). |
| `RA_NEW_CREATED` | `FILE` | `INFO` | `rowIndex`, `raNum`, `raKey`, `period`, `cstap` | Создан новый RA + ключ (per-row). Целевой (1.8.11.5.1). |
| `RA_NEW_SUMS` | `FILE` | `INFO` | `rowIndex`, `raKey`, `ttl`, `work`, `equip`, `others`, `hasSums` | Добавлены суммы RA или «суммы отсутствуют» (per-row). Целевой (1.8.11.5.2). |
| `RA_VALIDATION_FAIL` | `FILE` | `WARN` | `rowIndex`, `raNum`, `reason` | Отказ валидации RA: читаемая причина (per-row). Целевой (1.8.11.5.3). |
| `RA_FIELD_MISMATCH` | `FILE` | `WARN` | `rowIndex`, `raKey`, `field`, `oldValue`, `expectedValue` | Несовпадение поля RA: old (Crimson) vs expected (Peru). Целевой (1.8.11.5.4). |
| `RA_FIELD_UPDATED` | `FILE` | `INFO` | `rowIndex`, `raKey`, `field`, `newValue` | Обновлено поле RA (SeaGreen). Целевой (1.8.11.5.5). |
| `RA_SUM_MISMATCH` | `FILE` | `WARN` | `rowIndex`, `raKey`, `ttlOld`, `ttlNew`, `workOld`, `workNew`, `equipOld`, `equipNew`, `othersOld`, `othersNew` | Суммовой блок RA: покомпонентный diff + пересоздание. Целевой (1.8.11.5.6). |
| `RA_EXCESS_ITEM` | `FILE` | `WARN` | `rowIndex`, `raKey`, `raName` | Лишняя RA в домене (кандидат на удаление). Целевой (1.8.11.5.7). |
| `RC_ROWS_SUMMARY` | `FILE` | `INFO` | `execKey`, `rcRowsCount` | «Всего строк изменений: N» перед блоком RC. Целевой (1.8.11.3.2). |
| `RC_NEW_CREATED` | `FILE` | `INFO` | `rowIndex`, `raKey`, `rcKey`, `period`, `num` | Создано новое RC + ключ (per-row). Целевой (1.8.11.6.1). |
| `RC_NEW_SUMS` | `FILE` | `INFO` | `rowIndex`, `rcKey`, `ttl`, `work`, `equip`, `others`, `hasSums` | Добавлены суммы RC или «суммы отсутствуют» (per-row). Целевой (1.8.11.6.2). |
| `RC_VALIDATION_FAIL` | `FILE` | `WARN` | `rowIndex`, `raKey`, `reason` | Отказ валидации RC: читаемая причина (per-row). Целевой (1.8.11.6.3). |
| `RC_FIELD_MISMATCH` | `FILE` | `WARN` | `rowIndex`, `rcKey`, `field`, `oldValue`, `expectedValue` | Несовпадение поля RC (per-row). Целевой (1.8.11.6.4). |
| `RC_FIELD_UPDATED` | `FILE` | `INFO` | `rowIndex`, `rcKey`, `field`, `newValue` | Обновлено поле RC (per-row). Целевой (1.8.11.6.5). |
| `RC_SUM_MISMATCH` | `FILE` | `WARN` | `rowIndex`, `rcKey`, `ttlOld`, `ttlNew`, `workOld`, `workNew`, `equipOld`, `equipNew`, `othersOld`, `othersNew` | Суммовой блок RC: покомпонентный diff. Целевой (1.8.11.6.6). |
| `RC_EXCESS_ITEM` | `FILE` | `WARN` | `rowIndex`, `rcKey`, `rcName` | Лишний RC в домене (кандидат на удаление). Целевой (1.8.11.6.7). |
| `AUDIT_ERROR` | `AUDIT` | `ERROR` | `auditId`, `message` | Ошибка выполнения ревизии. |

### Правило визуального оформления

- В Java-данных хранится семантика: `messageType`, `colorHint`, `emphasis`, `messageText`, `params`.
- HTML — только слой рендера в `adt_results`, не source-of-truth.
- Для оркестровочных событий `J-A` meta-поля `messageType/colorHint/emphasis` заполняются в коде (`AuditExecutionServiceImpl.withPresentationMeta(...)`).

## Implementation Backlog (compact)

- `P1 (done)`: закрыт `missing` в `V-A`/`J-A` для оркестровки (`msg.start`, `dir.*`, `file fs.*`, `msg.end`) — статусы переведены в `present`/`semantic` по факту реализации.
- `P1 (done)`: синхронизированы `eventKey/messageType/colorHint/emphasis` для оркестровочных `J-A` (через `AuditExecutionServiceImpl.withPresentationMeta(...)`), HTML оставлен render-слоем.
- `P1 (done)`: решение по `semantic`-узлам (`V-A ... Excel open/close`) зафиксировано: app-level event не добавляется, используются `WORKBOOK_*` (`J-B.1.1/1.2`).
- `P2`: расширить mapping на type-specific оркестровочные сообщения (`af_type=2/3/5/6`) в том же формате `map/status/gap`. Для type=5 частично закрыто в `1.8.10`; полное закрытие — после выполнения `1.8.11`.
- `P3 (partially done)`: row-level эквиваленты `paragraph` (staging, `V-C.2.1.a.1.1.a.*`) — row-level preview реализован. Полный per-row (без top-N) — целевое решение A, см. `1.8.11.5–1.8.11.7`.
- `P3.1 (done)`: реализован целевой критерий отбора строк type=5 по полю `Признак` (`ОА`/`ОА изм`/`ОА прочие`) из `ags.ra_sheet_conf`; `V-C.2.1.a.1.filter` переведён в `present`. Выполнено в `1.8.10.5` ✅.
- `P4`: реализовать row-level события reconcile type=5 (RA/RC new/changed/excess/validation) по решению A (full parity). Карта задач: `1.8.11.3–1.8.11.7`. Новые `eventKey`: `RA_ROWS_SUMMARY`, `RA_NEW_CREATED`, `RA_NEW_SUMS`, `RA_VALIDATION_FAIL`, `RA_FIELD_MISMATCH`, `RA_FIELD_UPDATED`, `RA_SUM_MISMATCH`, `RA_EXCESS_ITEM`, и симметричные `RC_*`. Плюс framework events: `RECONCILE_TYPE5_MODE`, `STAGING_ROW_INSERTED`.
