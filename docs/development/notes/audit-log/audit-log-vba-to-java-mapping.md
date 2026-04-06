---
title: "Audit log: VBA → Java mapping (ход ревизии)"
created: "2026-03-26"
lastUpdated: "2026-04-06"
status: "draft"
version: "0.3.6"
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
    - `screenshot -> SCR-003-A` (верхние строки блока старта)
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
        - `visual -> derived-from SCR-003-A` (зеркало DIR_FS_EXISTS: «Не обнаружена **директория** для ревизии» `[RED]`)
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
        - `screenshot -> SCR-003-A` («Имя директории *...* для ревизии обнаружено» `[GREEN BOLD]`)
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
          - `visual -> derived-from SCR-003-A` (зеркало DIR_FS_EXISTS: «Директория с именем "..." в ФС **не** обнаружена» `[RED BOLD]`)
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
          - `screenshot -> SCR-003-A` («Директория с именем "..." в ФС обнаружена» `[GREEN BOLD]`)
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
          - `screenshot -> SCR-003-A` («*Приложение Excel открыто*» `[BLUE BOLD]`)
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
                  - `screenshot -> SCR-003-A` («... Файл с именем "..." в файловой системе обнаружен»)
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
                  - `screenshot -> SCR-003-A` («... Файл с именем "..." в приложении открыт» `[GREEN BOLD]`)
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
                  - `visual -> derived-from SCR-003-A` (зеркало FILE_FS_FOUND: «Файл с именем "..." в ФС **не** обнаружен» `[RED BOLD]`)
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
                      - `visual -> derived-from SCR-003-C` (формат «лист *...* **не** обнаружен» `[RED BOLD]` — зеркало SCR-003-C с заменой «найден»→«не найден»)
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
              - `visual -> inferred` (нет на скриншоте; по VBA-сниппету: «Не обнаружены файлы для рассмотрения» `[plain]`)
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
    - `screenshot -> SCR-002-D` («*Приложение Excel закрыто*» `[BLUE BOLD]`)
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
    - `screenshot -> SCR-002-D` («В {finishTime} - *ревизия завершена*. С {startTime} в течении ... сек.» `[BLUE BOLD]`)
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
  - `visual -> SCR-003-B` (серия BLUE «Найдена ячейка {col} колонка - {N}, строка - 1» — по одной строке на каждый столбец из конфигурации)
  - `V-C.2.1 [CHECK]` Ключевые колонки и диапазон найдены?
    - `V-C.2.1.a [MSG]` Диапазон данных найден: колонка, первая/последняя строка, адрес (`colorHint=BLUE`, `messageType=INFO`).
      - `map -> J-C.5.B.2 [MSG][TARGET]`
      - `status -> present`
      - `gap -> —`
      - `screenshot -> SCR-003-C` («Найден диапазон *Отчёты обычные*, колонка - 4, первая строка - 2, нижняя строка - 19144. Адрес: $D$2:$D$19144.»)
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
        - `gap -> staging row-level (`ROW_PARAGRAPH_PREVIEW*`) без лимита top-N, HTML по SCR-003-D (1.8.11.9.7). Полный эквивалент VBA-лога по файлу ещё требует row-level reconcile RA/RC (1.8.11.5–1.8.11.6).`
      - `V-C.2.1.a.1.1.a [ACTION]` `RaReadOfExcel` (row-level слой, источник строк `ra_ImpNew`).
        - `V-C.2.1.a.1.1.a.1 [MSG]` Старт `paragraph`: тип/номер ОА, стройка и контекст строки.
          - `map -> J-C.5.B.4 / ROW_PARAGRAPH_PREVIEW`
          - `status -> partial`
          - `gap -> формат и цвета выровнены по SCR-003-D; `rain_key` после INSERT. Остаётся полный parity по reconcile RA/RC per-row (1.8.11.5–1.8.11.6), не staging.`
          - `screenshot -> SCR-003-D` («Найден тип *ОА*; имя: ...; Стр. - ....» `[TEAL BOLD]`)
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
            - `screenshot -> SCR-003-D` («Отчёт внесён в промеж. тбл. ID - {id}» `[DARK_GREEN]`, ID `[ORANGE BOLD]`)
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
      - `visual -> derived-from SCR-003-C` (зеркало SCR-003-C: «... **данные не найдены** ...» `[RED BOLD]` — цвет blue→red, «найден»→«не найдены»)
      - **Поля:** `cellRaNumColumn`, `c.Column`, `adt_results`
      - **Шаблон (VBA):**
        ```vb
        str = "<P> ... <B><font color=""mediumVioletRed"">данные не найдены</font></B> ...</P>"
        ```
    - `V-C.2.1.b1 [TERMINAL]` `### TERMINAL: TYPE5_REQUIRED_COLUMNS_OR_RANGE_MISSING`.

- `V-C.3 [ACTION]` Блок RA из `Audit`: агрегаты и детализация `ra_ImpNewQuRa`.
  - `V-C.3.1 [MSG]` Всего строк RA в staging (summary count).
    - `map -> J-C.5.C [MSG][TARGET]`
    - `status -> present`
    - `gap -> —`
    - `screenshot -> SCR-002-A` («Всего найдено отчётов: 1952» `[CRIMSON BOLD]`)
    - **Поля:** `rsRaAll.RecordCount`
    - **Шаблон (VBA):**
      ```vb
      "<P>Всего строк отчётов: <b>" & rsRaAll.RecordCount & "</b></P>"
      ```
  - `V-C.3.2 [MSG]` Новые RA (`ra_key is null`) — count + построчная детализация через `AuditRaCreateNew`.
    - `map -> J-C.5.C.2/J-C.5.C.3 [MSG][TARGET]`
    - `status -> partial`
    - `gap -> Java отражает категории счётчиками в `RECONCILE_TYPE5_MATCH_STATS`, но без VBA-детализации текста по строкам. Целевые события: `RA_NEW_CREATED`, `RA_NEW_SUMS`, `RA_VALIDATION_FAIL` (1.8.11.5.1–5.3)`
    - `screenshot -> SCR-002-A` («Найдено отчётов отсутствующих в БД: 8» `[CRIMSON BOLD]`)
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
        - `screenshot -> SCR-002-A` («{idx}. {stgRow}. {raName}. Создан отчёт, ключ: {raKey}. Сумма: ...» — «Создан отчёт, ключ:» `[SEA_GREEN]`, ключ `[ORANGE]`)
        - **Поля:** `rainRow`, `rainRaNum`, `ra_key`
        - **Шаблон (VBA):**
          ```vb
          str = "<P>" & iii & ". " & rsRaNew!rainRow & ". ... " & rsRaNew!rainRaNum & " ... создан ... ключ: " & raRa.lngRaKey
          ```
      - `V-C.3.2.a.2 [MSG]` Добавлены суммы (`ttl/work/equip/others`) либо "суммы отсутствуют".
        - `map -> J-C.5.C.3 [MSG][TARGET]`
        - `status -> missing`
        - `gap -> в Java суммы видны агрегатно в apply stats, но нет строкового сообщения по конкретной записи; целевой `eventKey: RA_NEW_SUMS` (1.8.11.5.2)`
        - `screenshot -> SCR-002-A` (хвост строки: «Сумма: всего: {ttl} Р, СМР: {work} Р, ...» или «Сумма не требуется.»)
        - **Поля:** `exTtl`, `exWork`, `exEquip`, `exOthers`, `rasmRaSm.*`
        - **Шаблон (VBA):**
          ```vb
          str = str & ". суммы: total=" & FormatCurrency(rasmRaSm.curRaSmTtl) & ", work=..."
          ```
      - `V-C.3.2.a.3 [MSG]` Отказы валидации: отсутствуют `ra_num/period/cstap/sender`, неподдерживаемый `sign`, ошибка создания суммы (`colorHint=ORANGE_RED`, `messageType=WARN/ERROR`).
        - `map -> J-C.5.C.4 [MSG][TARGET]`
        - `status -> partial`
        - `gap -> Java даёт diagnostics, но не человекочитаемую причину отказа по каждой строке; целевой `eventKey: RA_VALIDATION_FAIL` (1.8.11.5.3)`
        - `visual -> inferred` (нет на скриншоте — строка 1 в SCR-002-A «Но это изменение!» является косвенным намёком на validation-warn; точный формат — по реализации)
        - **Поля:** `rainRaNum`, `periodKey`, `cstapKey`, `ogKey`, `rainSign`
  - `V-C.3.3 [MSG]` Изменённые RA (`ra_key is not null and rs=false`) — count + построчная детализация через `AuditRaEdit`.
    - `map -> J-C.5.C.2/J-C.5.C.3 [MSG][TARGET]`
    - `status -> partial`
    - `gap -> в Java есть counters CHANGED/UPDATED в `RECONCILE_TYPE5_MATCH_STATS`, но нет полного old/expected/updated текста по каждому полю. Целевые события: `RA_FIELD_MISMATCH`, `RA_FIELD_UPDATED`, `RA_SUM_MISMATCH` (1.8.11.5.4–5.6)`
    - `screenshot -> SCR-002-B` («Найдено отчётов имеющих несоответствия в данных: 36» `[CRIMSON BOLD]`)
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
        - `screenshot -> SCR-002-B` («{fieldName}, БД: {oldVal}» `[CRIMSON]`; «источник: {newVal}» `[PERU]`)
        - **Поля:** `rsArrv/rsDate/...`, `raRa.<field old>`, `rsRaErr!ex<field>`
      - `V-C.3.3.a.2 [MSG]` После apply: updated value (SeaGreen).
        - `map -> J-C.5.C.3 [MSG][TARGET]`
        - `status -> missing`
        - `gap -> Java не публикует row-level "updated" значения в лог; целевой `eventKey: RA_FIELD_UPDATED` (1.8.11.5.5)`
        - `screenshot -> SCR-002-B` («Обновлено, БД: {updatedVal}» `[SEA_GREEN]` — inline после mismatch в той же `<P>`)
        - **Поля:** `addRa`, `raRa.<field new>`
      - `V-C.3.3.a.3 [MSG]` Суммовой блок: mismatch по компонентам + пересоздание/добавление суммы.
        - `map -> J-C.5.C.3 [MSG][TARGET]`
        - `status -> partial`
        - `gap -> есть итоговые sum counters в apply stats, но нет детализации по компонентам суммы; целевой `eventKey: RA_SUM_MISMATCH` (1.8.11.5.6)`
        - `visual -> derived-from SCR-002-B` (формат аналогичен полевому diff: «{component}, БД: {old}; источник: {new}. Обновлено: {upd}» inline; точный текст — по реализации)
        - **Поля:** `rsTtl/rsWork/rsEquip/rsOthers`, `rasmRaSm`, `exTtl/exWork/exEquip/exOthers`
  - `V-C.3.4 [MSG]` Лишние RA в домене (нет в текущем source) — count + построчный список кандидатов на удаление.
    - `map -> J-C.5.C.4 [MSG][TARGET]`
    - `status -> partial`
    - `gap -> Java delete-план отражается в diagnostics агрегатно, но без построчного списка имён как в VBA; целевой `eventKey: RA_EXCESS_ITEM` (1.8.11.5.7)`
    - `visual -> derived-from SCR-002-A` (шаблон счётчика: «... в БД, но отсутствуют в источнике: **N**» `[CRIMSON BOLD]`; список: «{idx}. {raName}» `[CRIMSON]`)
    - **Поля:** `rsRaExr.RecordCount`, `ra_key`, `ra_name`, `addRa`
    - **Шаблон (VBA):**
      ```vb
      "<P><font color=""Crimson"">... в БД, но отсутствуют в источнике</font>: <b>" & rsRaExr.RecordCount & "</b></P>"
      str = "<p>" & iii & ". <font color=""Crimson"">" & raRaExr.strRaName & "</font> ...</p>"
      ```
  - `V-C.3.5 [CHECK]` `addRa=true`? При true применяются create/update/delete; при false — диагностический режим без apply.
    - `map -> J-C.5.C [MSG][TARGET]`
    - `status -> present`
    - `gap -> —` (`RECONCILE_TYPE5_MODE` в `AllAgentsReconcileService`, 1.8.11.4.5 ✅; плюс `addRa` в meta `RECONCILE_TYPE5_START`)
    - `visual -> inferred` (нет отдельной строки на скриншоте; информация передаётся только через meta-поля событий reconcile)
    - `V-C.3.5.a [ACTION]` apply enabled: create/update/delete + обновление сумм
    - `V-C.3.5.b [ACTION]` dry-run: только диагностика/подсчёты, без изменений в домене

- `V-C.4 [ACTION]` Блок RC из `Audit`: агрегаты и детализация `ra_ImpNewQuRc`.
  - `V-C.4.1 [MSG]` Всего строк RC в staging (summary count).
    - `map -> J-C.5.C [MSG][TARGET]`
    - `status -> present`
    - `gap -> —`
    - `screenshot -> SCR-002-C` («Всего новых изменений: 77» `[CRIMSON BOLD]`)
    - **Поля:** `rsRaAll.RecordCount`
    - **Шаблон (VBA):**
      ```vb
      "<P>Всего строк изменений: <b>" & rsRaAll.RecordCount & "</b></P>"
      ```
  - `V-C.4.2 [MSG]` Новые RC (`rac_key is null`) — count + построчная детализация через `AuditRcCreateNew`.
    - `map -> J-C.5.C.2/J-C.5.C.3 [MSG][TARGET]`
    - `status -> partial`
    - `gap -> Java NEW по RC есть как категория в `RECONCILE_TYPE5_MATCH_STATS`, но без VBA row-level текста. Целевые события: `RC_NEW_CREATED`, `RC_NEW_SUMS`, `RC_VALIDATION_FAIL` (1.8.11.6.1–6.3)`
    - `screenshot -> SCR-002-C` («Найдено изменений отсутствующих в БД: 3» `[CRIMSON BOLD]`)
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
        - `screenshot -> SCR-002-C` («Создано изменение отчёта, ключ: {rcKey}» — формат аналогичен SCR-002-A, «ключ:» `[SEA_GREEN]`, значение `[ORANGE]`)
        - **Поля:** `rainRow`, `rainRaNum`, `rac_key`
      - `V-C.4.2.a.2 [MSG]` Добавлены суммы RC либо "суммы отсутствуют".
        - `map -> J-C.5.C.3 [MSG][TARGET]`
        - `status -> missing`
        - `gap -> нет row-level сообщения по суммам RC; целевой `eventKey: RC_NEW_SUMS` (1.8.11.6.2)`
        - `screenshot -> SCR-002-C` (хвост строки: «Сумма: {ttl} Р, ...» или «Сумма не требуется.»)
        - **Поля:** `exTtl`, `exWork`, `exEquip`, `exOthers`, `rcsmRcSm.*`
      - `V-C.4.2.a.3 [MSG]` Отказы валидации: отсутствуют `ra_key/period/num/sender`, ошибка создания RC/сумм.
        - `map -> J-C.5.C.4 [MSG][TARGET]`
        - `status -> partial`
        - `gap -> Java фиксирует часть причин в diagnostics, но не как отдельные человекочитаемые строки; целевой `eventKey: RC_VALIDATION_FAIL` (1.8.11.6.3)`
        - `visual -> inferred` (нет на скриншоте; формат — по аналогии с RA_VALIDATION_FAIL)
        - **Поля:** `ra_key`, `rcPeriod`, `num`, `exSender`
  - `V-C.4.3 [MSG]` Изменённые RC (`rac_key is not null and rs=false`) — count + построчная детализация через `AuditRcEdit`.
    - `map -> J-C.5.C.2/J-C.5.C.3 [MSG][TARGET]`
    - `status -> partial`
    - `gap -> Java CHANGED по RC отражается в counters `RECONCILE_TYPE5_MATCH_STATS`, но без покомпонентного diff-текста. Целевые события: `RC_FIELD_MISMATCH`, `RC_FIELD_UPDATED`, `RC_SUM_MISMATCH` (1.8.11.6.4–6.6)`
    - `screenshot -> SCR-002-C` («Не найдены изменения имеющие несоответствия в данных.» `[plain]` — в данном прогоне CHANGED=0)
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
        - `visual -> derived-from SCR-002-B` (формат идентичен RA: «{field}, БД: {old}» `[CRIMSON]`; «источник: {new}» `[PERU]`)
        - **Поля:** `rsArrv/rsDate/...`, `rcRc.<field old>`, `rsRaErr!ex<field>`
      - `V-C.4.3.a.2 [MSG]` После apply: updated value (SeaGreen).
        - `map -> J-C.5.C.3 [MSG][TARGET]`
        - `status -> missing`
        - `gap -> нет row-level "updated" сообщений по RC; целевой `eventKey: RC_FIELD_UPDATED` (1.8.11.6.5)`
        - `visual -> derived-from SCR-002-B` (формат идентичен RA: «Обновлено, БД: {upd}» `[SEA_GREEN]` inline)
        - **Поля:** `addRa`, `rcRc.<field new>`
      - `V-C.4.3.a.3 [MSG]` Суммовой блок: mismatch по компонентам + пересоздание/добавление суммы.
        - `map -> J-C.5.C.3 [MSG][TARGET]`
        - `status -> partial`
        - `gap -> в Java только агрегаты по суммам без детального текста по компонентам; целевой `eventKey: RC_SUM_MISMATCH` (1.8.11.6.6)`
        - `visual -> derived-from SCR-002-B` (формат аналогичен RA_SUM_MISMATCH; точный текст — по реализации)
        - **Поля:** `rsTtl/rsWork/rsEquip/rsOthers`, `rcsmRcSm`, `exTtl/exWork/exEquip/exOthers`
  - `V-C.4.4 [MSG]` Лишние RC в домене (нет в текущем source) — count + построчный список кандидатов на удаление.
    - `map -> J-C.5.C.4 [MSG][TARGET]`
    - `status -> partial`
    - `gap -> в Java RC delete отражается как агрегат planned/applied, но без построчного перечня имён как в VBA; целевой `eventKey: RC_EXCESS_ITEM` (1.8.11.6.7)`
    - `visual -> derived-from SCR-002-A` (шаблон счётчика и списка аналогичен RA_EXCESS_ITEM; «изменение»→«изменение отчёта»)
    - **Поля:** `rsRaExr.RecordCount`, `rac_key`, `rc_name`, `addRa`
    - **Шаблон (VBA):**
      ```vb
      "<P><font color=""Crimson"">... изменения в БД, но отсутствуют в источнике</font>: <b>" & rsRaExr.RecordCount & "</b></P>"
      str = "<p>" & iii & ". <font color=""Crimson"">" & rcRcExr.strRcName & "</font> ...</p>"
      ```
  - `V-C.4.5 [CHECK]` `addRa=true`? При true применяются create/update/delete; при false — диагностический режим без apply.
    - `map -> J-C.5.C [MSG][TARGET]`
    - `status -> present`
    - `gap -> —` (см. `V-C.3.5` / `RECONCILE_TYPE5_MODE`)
    - `visual -> inferred` (аналогично V-C.3.5; нет отдельной строки на скриншоте)
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
      - **Минимальные meta-поля:** `auditId`, `sheetName`, `anchorText`, `anchorRow`, `anchorRowOneBased`, `anchorColumn`, `anchorCellContent`, `messageType`, `colorHint`, `emphasis`
      - **map/status/gap:** `map -> V-C.2.1`, `status -> present`, `gap -> формат `ANCHOR_FOUND` выровнен к SCR-003-B (текст «Найдена ячейка ...», `BLUE`); для `ANCHOR_MISSING` сохранён WARN/RED + исключение`
    - `J-C.5.B.4 [MSG]` `STAGING_START/STAGING_LOAD_STATS/STAGING_END` + `ROW_PARAGRAPH_PREVIEW*` (фактические события)
      - **eventKey:** `STAGING_START`, `STAGING_LOAD_STATS`, `STAGING_END`; **scope:** `FILE`
      - **map/status/gap:** `map -> V-C.2.1 / V-C.3.1 / V-C.4.1`, `status -> partial`, `gap -> в Java есть row-level staging preview (без top-N, 1.8.11.9.7) и staging-статистика; нет полного VBA-эквивалента: (а) механизм отбора строк отличается от VBA `Find/FindNext` (семантика совпадает через whitelist), (б) summary RA/RC вынесен в reconcile (`RA_ROWS_SUMMARY`/`RC_ROWS_SUMMARY`, 1.8.11.3.1–3.2), (в) row-level reconcile RA/RC per-row.`

  - `J-C.5.C [ACTION]` `AllAgentsReconcileService` (match/apply/delete/diagnostics)
    - `J-C.5.C.0 [MSG]` `RECONCILE_TYPE5_MODE`, `RA_ROWS_SUMMARY`, `RC_ROWS_SUMMARY` (фактические события)
      - **eventKey:** `RECONCILE_TYPE5_MODE`, `RA_ROWS_SUMMARY`, `RC_ROWS_SUMMARY`; **scope:** `FILE`
      - **map/status/gap:** `map -> V-C.3.1 / V-C.4.1 / V-C.3.5 / V-C.4.5`, `status -> present`, `gap -> —` (`AllAgentsReconcileService.reconcileInTransaction`, 1.8.11.3.1–3.2, 4.5; требуется не-null `AuditExecutionContext` в `ReconcileContext`).
    - `J-C.5.C.1 [MSG][TARGET]` `RECONCILE_TYPE5_START`
      - **eventKey:** `RECONCILE_TYPE5_START`; **scope:** `FILE`
      - **Минимальные meta-поля:** `auditId`, `executionKey`, `fileType=5`, `addRa`, `messageType`, `colorHint`, `emphasis`
      - **map/status/gap:** `map -> V-C.3/V-C.4`, `status -> present`, `gap -> реализовано в `AuditReconcileCoordinator.run()`: `beginSpan` с `codeForType(file, \"RECONCILE_START\", \"RECONCILE_TYPE5_START\")` при `fileType=5`; meta: `auditId`, `executionKey`, `fileType`, `addRa`; `messageType=START`, `colorHint=BLUE`, `emphasis=BOLD`. HTML — технический (`Reconcile start: type=...`); VBA-формулировки нет (см. 1.8.11.4.1 при необходимости выравнивания текста).`
    - `J-C.5.C.2 [MSG][TARGET]` `RECONCILE_TYPE5_MATCH_STATS`
      - **eventKey:** `RECONCILE_TYPE5_MATCH_STATS`; **scope:** `FILE`
      - **Минимальные meta-поля:** `auditId`, `executionKey`, `fileType=5`, `raNew`, `raChanged`, `raUnchanged`, `raInvalid`, `raAmbiguous`, `rcNew`, `rcChanged`, `rcUnchanged`, `rcInvalid`, `rcAmbiguous`, `messageType`, `colorHint`, `emphasis`
      - **map/status/gap:** `map -> V-C.3.2/V-C.3.3/V-C.4.2/V-C.4.3`, `status -> present`, `gap -> —` (`Type5ReconcileAuditCounters.MatchStats` из `AllAgentsReconcileService`, эмиссия в `AuditReconcileCoordinator.appendType5MatchStats`, 1.8.11.4.3; `rcInvalid`/`rcAmbiguous` — агрегаты счётчиков read-model RC)
    - `J-C.5.C.3 [MSG][TARGET]` `RECONCILE_TYPE5_APPLY_STATS`
      - **eventKey:** `RECONCILE_TYPE5_APPLY_STATS`; **scope:** `FILE`
      - **Минимальные meta-поля:** `auditId`, `executionKey`, `fileType=5`, `raInserted`, `raUpdated`, `raUnchanged`, `raDeleted`, `rcInserted`, `rcUpdated`, `rcUnchanged`, `rcDeleted`, `sumInserted` (RA+RC суммовые вставки), `messageType`, `colorHint`, `emphasis`
      - **map/status/gap:** `map -> V-C.3.5/V-C.4.5`, `status -> present`, `gap -> row-level old/expected/updated в VBA по-прежнему не покрыты; агрегат apply — в meta `Type5ReconcileAuditCounters.ApplyStats` (1.8.11.4.4).
    - `J-C.5.C.4 [MSG][TARGET]` `RECONCILE_TYPE5_DIAGNOSTICS`
      - **eventKey:** `RECONCILE_TYPE5_DIAGNOSTICS`; **scope:** `FILE`
      - **Минимальные meta-поля:** `missingSenderTopN`, `missingCstTopN`, `missingPeriodTopN`, `ambiguous*`, `messageType`, `colorHint`, `emphasis`
      - **map/status/gap:** `map -> V-C.3.4/V-C.4.4`, `status -> partial`, `gap -> соответствие по смыслу есть, но детализация и формулировки отличаются`
    - `J-C.5.C.5 [MSG][TARGET]` `RECONCILE_TYPE5_DONE/RECONCILE_TYPE5_SKIPPED/RECONCILE_TYPE5_FAILED`
      - **eventKey:** `RECONCILE_TYPE5_DONE`, `RECONCILE_TYPE5_SKIPPED`, `RECONCILE_TYPE5_FAILED`; **scope:** `FILE`
      - **Минимальные meta-поля:** `executionKey`, `status`, `reason`, `durationSec`, `messageType`, `colorHint`, `emphasis`
      - **map/status/gap:** `map -> V-C.3/V-C.4`, `status -> present`, `gap -> trio реализована в `AuditReconcileCoordinator`: `appendResult` вызывает `endSpan` с `RECONCILE_TYPE5_DONE` или `RECONCILE_TYPE5_SKIPPED` (`status` в meta: `DONE`/`SKIPPED`, `affectedRows`, `durationHuman`); при `RuntimeException` из `service.reconcile` — `endSpan` с `RECONCILE_TYPE5_FAILED` (`status=FAILED`). HTML — технический (`Reconcile: type=..., applied=...`); VBA-формулировки нет.`

  - `J-C.5.3 [TERMINAL]` `### TERMINAL: TYPE5_ROW_LEVEL_PARAGRAPH_EQUIVALENT_PARTIAL`
    - Комментарий: `ROW_PARAGRAPH_PREVIEW*` для type=5: лимит `top-N` снят (1.8.11.9.7); HTML и цвета выровнены по SCR-003-D; `rain_key` подставляется после `INSERT` (`RETURN_GENERATED_KEYS`). Оставшийся gap к VBA: формулировки `WORKBOOK_*` («Книга…» vs «Приложение Excel…») и мелкие отличия в шаблоне `AUDIT_START`.
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
| `V-C.3/V-C.4` (рамка reconcile) | `J-C.5.C.1` `RECONCILE_TYPE5_START` | present | Старт reconcile type=5: `AuditReconcileCoordinator.run` → `beginSpan` с `RECONCILE_TYPE5_START` (см. 1.8.11.1.3). |
| `V-C.3/V-C.4` (завершение reconcile) | `J-C.5.C.5` `DONE/SKIPPED/FAILED` | present | Завершение: `appendResult` → `RECONCILE_TYPE5_DONE`/`SKIPPED`; catch → `RECONCILE_TYPE5_FAILED` (см. 1.8.11.1.3). |
| `V-C.2.1.a` | `J-C.5.B.2 SHEET_FOUND` | present | Координаты диапазона в meta (`column`, `firstRow`, `lastRow`, `address`), HTML по SCR-003-C; выполнено в `1.8.11.2.1` ✅. |
| `V-C.2.1` (anchor) | `J-C.5.B.3 ANCHOR_FOUND/ANCHOR_MISSING` | present | Реализовано событие якоря; `ANCHOR_FOUND` в формате SCR-003-B («Найдена ячейка ...», `BLUE`) с meta `anchorColumn/anchorCellContent/anchorRowOneBased`. |
| `V-C.2.1.a.1.filter` | `J-C.5.B.4` | present | Фильтр строк по полю `Признак` из whitelist (`ОА`/`ОА изм`/`ОА прочие`) реализован в 1.8.10.5 ✅. Механизм отличается от VBA (`Find/FindNext`), семантический результат идентичен. |
| `V-C.2.1.a.1.1.a.2.a.1` | — | missing | Per-row staging insert ID. Целевой `eventKey: STAGING_ROW_INSERTED` (1.8.11.7.1). |
| `V-C.2.1.a.1` | `J-C.5.B/J-C.5.C` | partial | Перебор строк в VBA логируется детально; в Java покрыт через staging/reconcile + row-level preview и агрегированные counters. |
| `V-C.2.1.a.1.1.a.*` | `ROW_PARAGRAPH_PREVIEW*` | partial | Staging: полный вывод строк без top-N, SCR-003-D HTML + `rain_key` (1.8.11.9.7). Полный VBA-parity по файлу — ещё reconcile RA/RC per-row (1.8.11.5–1.8.11.6). |
| `V-C.3.1` | `RA_ROWS_SUMMARY` | present | `AllAgentsReconcileService`: `matchRowsConsidered` в `raRowsCount` (1.8.11.3.1) ✅. |
| `V-C.3.2.a.1` | — | missing | RA created per row. Целевой `eventKey: RA_NEW_CREATED` (1.8.11.5.1). |
| `V-C.3.2.a.2` | — | missing | RA sums per row. Целевой `eventKey: RA_NEW_SUMS` (1.8.11.5.2). |
| `V-C.3.2.a.3` | `RECONCILE_TYPE5_DIAGNOSTICS` | partial | RA validation fail: в diagnostics частично, без per-row текста. Целевой `eventKey: RA_VALIDATION_FAIL` (1.8.11.5.3). |
| `V-C.3.3.a.1` | — | missing | RA field mismatch old/expected. Целевой `eventKey: RA_FIELD_MISMATCH` (1.8.11.5.4). |
| `V-C.3.3.a.2` | — | missing | RA updated value. Целевой `eventKey: RA_FIELD_UPDATED` (1.8.11.5.5). |
| `V-C.3.3.a.3` | `RECONCILE_TYPE5_APPLY_STATS` | partial | RA sum mismatch: агрегат есть, per-row нет. Целевой `eventKey: RA_SUM_MISMATCH` (1.8.11.5.6). |
| `V-C.3.4` | `RECONCILE_TYPE5_DIAGNOSTICS` | partial | Excess RA: aggregate, без списка имён. Целевой `eventKey: RA_EXCESS_ITEM` (1.8.11.5.7). |
| `V-C.3.5/V-C.4.5` | `RECONCILE_TYPE5_MODE` | present | Явный MSG режима + `addRa` в `RECONCILE_TYPE5_START` (1.8.11.4.5) ✅. |
| `V-C.4.1` | `RC_ROWS_SUMMARY` | present | `rcRowsConsidered` перед блоком RC (1.8.11.3.2) ✅. |
| `V-C.4.2.a.1` | — | missing | RC created per row. Целевой `eventKey: RC_NEW_CREATED` (1.8.11.6.1). |
| `V-C.4.2.a.2` | — | missing | RC sums per row. Целевой `eventKey: RC_NEW_SUMS` (1.8.11.6.2). |
| `V-C.4.2.a.3` | `RECONCILE_TYPE5_DIAGNOSTICS` | partial | RC validation fail. Целевой `eventKey: RC_VALIDATION_FAIL` (1.8.11.6.3). |
| `V-C.4.3.a.1` | — | missing | RC field mismatch. Целевой `eventKey: RC_FIELD_MISMATCH` (1.8.11.6.4). |
| `V-C.4.3.a.2` | — | missing | RC updated value. Целевой `eventKey: RC_FIELD_UPDATED` (1.8.11.6.5). |
| `V-C.4.3.a.3` | `RECONCILE_TYPE5_APPLY_STATS` | partial | RC sum mismatch. Целевой `eventKey: RC_SUM_MISMATCH` (1.8.11.6.6). |
| `V-C.4.4` | `RECONCILE_TYPE5_DIAGNOSTICS` | partial | Excess RC: aggregate, без списка имён. Целевой `eventKey: RC_EXCESS_ITEM` (1.8.11.6.7). |
| `V-B.*` | `J-C.x` | parked/missing | Legacy-ветка `paragraph` не раскрывается в текущем scope. |

## Visual Reference (скриншоты реального прогона type=5)

> **Источники:** `docs/development/notes/audit-log/images/26-0406-002.PNG`,
> `docs/development/notes/audit-log/images/26-0406-003.PNG`.
> **Прогон:** 06.04.2026, type=5, один файл (`2026 Свод инф-ции по OA.xlsm`), `addRa=true`.
>
> **Правило приоритета:** реальный текст из `SCR-*` имеет приоритет над абстрактным
> VBA-сниппетом в дереве. При расхождении — сниппет уточняется по `SCR`.
>
> **Порядок в VBA-логе:** VBA prepends (новейшее вверху); Java appends (старейшее вверху).
> Содержимое идентично, порядок отображения обратный.

---

### SCR-003-A: Оркестровка — старт (26-0406-003.PNG, нижняя часть)

> Узлы: `V-A.1.msg.start`, `V-A.1.2.b.b.msg`, `V-A.1.2.b.b.check.b`,
> `V-A.1.2.b.b.check.b1`, `V-A.1.2.b.b.check.b2.0.a.0.a`, `V-A.1.2.b.b.check.b2.0.a.0.a1`

```text
Начало проведения ревизии *2026-й год*.                                                   [RED BOLD]
Проводим по директории - X:\grp\F644\All\УКПиУБПроСО                                     [plain]
06.04.2026 9:18:16 - Время начала проведения ревизии.                                     [plain]

Имя директории *X:\grp\F644\All\УКПиУБПроСО* для ревизии обнаружено                      [GREEN BOLD]
Директория с именем *X:\grp\F644\All\УКПиУБПроСО* в файловой системе обнаружена          [GREEN BOLD]
*Приложение Excel открыто*                                                                [BLUE BOLD]
06.04.2026 9:18:07 - Файл с именем "...2026 Свод инф-ции по OA.xlsm" в файловой системе обнаружен
06.04.2026 9:18:07 - Файл с именем "...2026 Свод инф-ции по OA.xlsm" в приложении открыт [GREEN BOLD]
```

**Производные узлы (не на скриншоте, формат выведен по аналогии):**
- `V-A.1.2.b.a` `DIR_LOOKUP_NOT_FOUND`: «Не обнаружена **директория** для ревизии» `[RED]` — зеркало `DIR_LOOKUP_FOUND`
- `V-A.1.2.b.b.check.a` `DIR_FS_MISSING`: «Директория с именем "..." в ФС **не** обнаружена» `[RED BOLD]` — зеркало `DIR_FS_EXISTS`
- `V-A.1.2.b.b.check.b2.0.a.0.b` `FILE_FS_MISSING`: «Файл с именем "..." в ФС **не** обнаружен» `[RED BOLD]` — зеркало `FILE_FS_FOUND`
- `V-A.1.2.b.b.check.b2.0.b` `FILES_EMPTY`: «Не обнаружены файлы для рассмотрения» `[plain]` — по VBA-сниппету, без скриншота

---

### SCR-003-B: Якоря колонок (26-0406-003.PNG, средняя часть)

> Узлы: `V-C.2` (`CellFind` серия → `ANCHOR_FOUND`)

```text
Найдена ячейка № ОА колонка - 4, строка - 1. Содержание: № ОА.                           [BLUE]
Найдена ячейка Дата ОА колонка - 5, строка - 1. Содержание: Дата ОА.                     [BLUE]
Найдена ячейка Поступило (№ письма) колонка - 11, строка - 1. Содержание: ...            [BLUE]
Найдена ячейка Поступило (Фактическая дата) колонка - 13, строка - 1. Содержание: ...   [BLUE]
Найдена ячейка Направлен в Бухгалтерию (Дата С3) колонка - 14, строка - 1. Содержание: ... [BLUE]
Найдена ячейка Направлен в Бухгалтерию (№ С3) колонка - 15, строка - 1. Содержание: ... [BLUE]
... (одно сообщение на каждый столбец из конфигурации)
```

**Шаблон строки:**
```
Найдена ячейка {columnName} колонка - {colNum}, строка - 1. Содержание: {cellContent}.  [BLUE]
```

---

### SCR-003-C: Диапазон найден (26-0406-003.PNG, средняя часть)

> Узел: `V-C.2.1.a`

```text
Найден диапазон *Отчёты обычные*, колонка - 4, первая строка - 2, нижняя строка - 19144.
Адрес: $D$2:$D$19144.                                                                     [BLUE, *name* BOLD]
```

**Шаблон:**
```
Найден диапазон *{sheetName}*, колонка - {colNum}, первая строка - {firstRow}, нижняя строка - {lastRow}. Адрес: {address}.
```

**Производный узел:** `V-C.2.1.b` (range not found):
«... **данные не найдены** ...» `[RED BOLD]` — цвет `blue→red`, «найден»→«не найдены», по аналогии.

---

### SCR-003-D: Per-row staging (26-0406-003.PNG, верхняя часть)

> Узлы: `V-C.2.1.a.1.1.a.1`, `V-C.2.1.a.1.1.a.2.a.1`

```text
Найден тип *ОА*; имя: С326-2002437-1; Стр. - 051-2002437. ОА С326-2002437-1/1 от 15.01.2026;
Отчёт внесён в промеж. тбл. ID - 39 (номер строки листа Excel).

Найден тип *ОА прочие*; имя: НПП26-2001040-1; Стр. - 051-2001040. ОА НПП26-2001040-1 от 01.10.2026;
Отчёт внесён в промеж. тбл. ID - 26 (номер строки листа Excel).

Найден тип *ОА изм*; имя: Изм 1 в ИР25-2004430-16 от 31.07.2025; Стр. - 051-2004430.
ОА Изм 1 в ИР25-2004430-16 от 31.07.2025 от 15.01.2026;
Отчёт внесён в промеж. тбл. ID - 15 (номер строки листа Excel).
```

**Цветовая разметка:**
- `*{sign}*` → `TEAL BOLD`
- `Отчёт внесён в промеж. тбл. ID -` → `DARK_GREEN`
- `{insertedId}` → `ORANGE BOLD`

**Шаблон:**
```
Найден тип *{sign}*; имя: {raName}; Стр. - {stgRowNum}. {raNum} от {raDate}; Отчёт внесён в промеж. тбл. ID - {insertedId} (номер строки листа Excel).
```

**Вариант `af_source=false`** (dry-run): строка заканчивается после даты, без «Отчёт внесён...».

---

### SCR-002-A: RA суммарные счётчики + NEW RA строки (26-0406-002.PNG, нижняя часть)

> Узлы: `V-C.3.1`, `V-C.3.2`, `V-C.3.2.a.1`, `V-C.3.2.a.2`

```text
Всего найдено отчётов: 1952                                                               [CRIMSON BOLD]
Найдено отчётов отсутствующих в БД: 8                                                     [CRIMSON BOLD]
1. 2541. Изменение № 1 к ОА № НСК25-3000860-3 от 28.02.2026. Но это изменение!
2. 2552. ИР26-2006735-9. Создан отчёт, ключ: 60733. Сумма: всего: 132 621 134,15 Р, СМР: 0,00 Р, ...
3. 2549. ИР26-2004430-9. Создан отчёт, ключ: 60732. Сумма: всего: 427 040 266,84 Р, ...
...
```

**Цветовая разметка строки NEW RA:**
- `Создан отчёт, ключ:` → `SEA_GREEN`
- `{raKey}` → `ORANGE`

**Шаблоны:**
```
Всего найдено отчётов: {total}                                           [CRIMSON BOLD]
Найдено отчётов отсутствующих в БД: {countNew}                          [CRIMSON BOLD]
{idx}. {stgRow}. {raName}. Создан отчёт, ключ: {raKey}. Сумма: всего: {ttl} Р, СМР: {work} Р, Оборудование: {equip} Р, Прочие: {others} Р.
(или: ... Сумма не требуется.)
```

**Производный узел `V-C.3.4`** (excess RA): «... в БД, но отсутствуют в источнике: **N**» `[CRIMSON BOLD]` + по строке «`{idx}. {raName}`» `[CRIMSON]`.

---

### SCR-002-B: CHANGED RA строки / inline diff (26-0406-002.PNG, средняя часть)

> Узлы: `V-C.3.3`, `V-C.3.3.a.1`, `V-C.3.3.a.2`

```text
Найдено отчётов имеющих несоответствия в данных: 36                                       [CRIMSON BOLD]
36. 2538. ГПИ26-2006743-3. Письмо направления, БД: ; источник: 472. Обновлено, БД: 472.
    Дата направления, БД: ; источник: 03.04.2026. Обновлено, БД: 03.04.2026
35. 2537. ГПИ26-2005599-1. Письмо направления, БД: ; источник: 472. Обновлено, БД: 472.
    Дата направления, БД: ; источник: 03.04.2026. Обновлено, БД: 03.04.2026
... (аналогично для остальных строк)
```

**Цветовая разметка одной строки CHANGED RA:**
- `{fieldName}, БД: {oldVal}` → `CRIMSON`
- `источник: {newVal}` → `PERU`
- `Обновлено, БД: {updatedVal}` → `SEA_GREEN`

**Шаблон:**
```
{idx}. {stgRow}. {raName}. {fieldName}, БД: {oldVal}; источник: {newVal}. Обновлено, БД: {updatedVal}. [повтор для каждого поля в той же <P>]
```

> **Ключевое наблюдение:** несколько изменённых полей одной записи выводятся **в одной строке `<P>`**. `RA_FIELD_MISMATCH` + `RA_FIELD_UPDATED` — inline-пары без `<P>` между полями; новая `<P>` только при переходе к следующей RA-записи.

**Производные узлы `V-C.4.3.*` CHANGED RC:** формат идентичен, «отчёт»→«изменение».

---

### SCR-002-C: RC суммарные счётчики + NEW RC строки (26-0406-002.PNG, верхняя часть)

> Узлы: `V-C.4.1`, `V-C.4.2`, `V-C.4.2.a.1`, `V-C.4.2.a.2`, `V-C.4.3`

```text
Всего новых изменений: 77                                                                  [CRIMSON BOLD]
Найдено изменений отсутствующих в БД: 3                                                    [CRIMSON BOLD]
1. 838. Изм 1 к ОА № НП25-2001040-18 от 30.11.2025. Создано изменение отчёта, ключ: 3863.
   Сумма: -963 271,25 Р, СМР: , Оборудование: -963 271,25 Р
2. 2556. Изменение № 1 от 31.03.2026 в ИР26-2000714-3 от 31.01.2026. Создано изменение отчёта, ключ: 3864. Сумма не требуется.
3. 2557. Изменение № 1 от 31.03.2026 в ИР26-2000714-7 от 28.02.2026. Создано изменение отчёта, ключ: 3865. Сумма не требуется.
Не найдены изменения имеющие несоответствия в данных.                                     [plain]
```

**Шаблоны:**
```
Всего новых изменений: {total}                                           [CRIMSON BOLD]
Найдено изменений отсутствующих в БД: {countNew}                        [CRIMSON BOLD]
{idx}. {stgRow}. {rcDescription}. Создано изменение отчёта, ключ: {rcKey}. Сумма не требуется.
(или: ... Сумма: {ttl} Р, СМР: {work} Р, Оборудование: {equip} Р, Прочие: {others} Р.)
Не найдены изменения имеющие несоответствия в данных.                   [при countChanged=0]
```

---

### SCR-002-D: Завершение (26-0406-002.PNG, верхняя часть)

> Узлы: `V-A.1.msg.end`, `V-A.1.msg.excel.close`, `FILE_CLOSE` per-file, `FILE_SKIPPED_BY_USER`

```text
В 06.04.2026 9:24:01 - *ревизия завершена*. С 06.04.2026 9:18:16 в течении 5 мин. 45 сек., (всего 345 сек.).  [BLUE BOLD]
06.04.2026 9:24:01 - *Приложение Excel закрыто*                                           [BLUE BOLD]
Файл с именем "...2026_Аренда_рабочий_1.xlsx" рассмотрению, в соответствии с Вашим выбором, не подлежит.  [GRAY]
Файл с именем "...2026 Свод инф-ции по Актам.xlsm" рассмотрению, в соответствии с Вашим выбором, не подлежит.  [GRAY]
06.04.2026 9:24:00 - Файл с именем "...2026 Свод инф-ции по OA.xlsm" в приложении закрыт
```

**Шаблоны:**
```
В {finishTime} - *ревизия завершена*. С {startTime} в течении {durationMin} мин. {durationSec} сек., (всего {durationTotalSec} сек.).
{closedAt} - *Приложение Excel закрыто*                                                   [BLUE BOLD]
Файл с именем "{filePath}" рассмотрению, в соответствии с Вашим выбором, не подлежит.   [GRAY]
{closedAt} - Файл с именем "{filePath}" в приложении закрыт
```

---

### Сводная таблица цветовых токенов (из скриншотов)

| Роль | VBA color | Java `colorHint` | Light HEX | Dark HEX |
|---|---|---|---|---|
| Системные события start/end, «ревизия завершена» | `blue` bold | `BLUE_BOLD` | `#0055AA` | `#5AB4FF` |
| Диапазон, якоря, инфо | `blue` | `BLUE` | `#0066CC` | `#60A5FA` |
| Найдено (dir/file OK), dir/file found | `green` | `GREEN` | `#1A7A1A` | `#4ADE80` |
| «Отчёт внесён в промеж. тбл.» | `DarkGreen` | `DARK_GREEN` | `#006400` | `#16A34A` |
| Тип строки (*ОА*, *ОА изм*…) | teal/cyan | `TEAL` | `#007070` | `#5EEAD4` |
| ID вставки, ключ записи, ключ RA/RC | `orange` | `ORANGE` | `#D06000` | `#FFB74D` |
| Счётчики summary, старое значение БД | `Crimson` | `CRIMSON` | `#B81C2E` | `#FC8181` |
| Ожидаемое/источник в diff | `Peru` | `PERU` | `#A0724B` | `#D4A55A` |
| Применено/обновлено, «Создан отчёт» | `SeaGreen` | `SEA_GREEN` | `#1F7A50` | `#34D399` |
| Критические ошибки, отсутствует | `MediumVioletRed` | `VIOLET_RED` | `#AA1060` | `#E879F9` |
| Пропущенные файлы | `gray` | `GRAY` | `#666666` | `#9CA3AF` |

---

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
| `SHEET_FOUND` | `FILE` | `INFO` | `sheetName`, `tableName`, `column`, `firstRow`, `lastRow`, `address` | Диапазон данных на листе (SCR-003-C), после маппинга заголовков. |
| `SHEET_MISSING` | `FILE` | `WARN` | `filePath`, `sheetName` | Лист не найден. |
| `STAGING_START` | `FILE` | `START` | `filePath`, `tableName`, `sheetName` | Старт загрузки staging. |
| `STAGING_LOAD_STATS` | `FILE` | `INFO` | `filePath`, `tableName`, `inserted`, `skipped*` | Итоговая статистика загрузки. |
| `STAGING_END` | `FILE` | `END` | `filePath`, `tableName`, `durationSec` | Завершение загрузки staging. |
| `ANCHOR_FOUND` | `FILE` | `INFO` | `sheetName`, `anchorText`, `anchorRow`, `anchorRowOneBased`, `anchorColumn`, `anchorCellContent` | Якорь заголовка найден (формат SCR-003-B). |
| `ANCHOR_MISSING` | `FILE` | `WARN` | `filePath`, `sheetName`, `anchorText` | Якорь заголовка не найден. |
| `RECONCILE_START` | `FILE` | `START` | `execKey`, `fileType` | Старт reconcile. |
| `RECONCILE_DONE` | `FILE` | `END` | `execKey`, `fileType`, `counters` | Завершение reconcile с counters. |
| `RECONCILE_SKIPPED` | `FILE` | `END` | `execKey`, `fileType`, `reason` | Reconcile пропущен. |
| `RECONCILE_TYPE5_START` | `FILE` | `START` | `execKey`, `fileType=5`, `addRa` | Старт reconcile для type 5 (детализированный код). |
| `RECONCILE_TYPE5_DONE` | `FILE` | `END` | `execKey`, `fileType=5`, `affectedRows` | Успешное завершение reconcile type 5. |
| `RECONCILE_TYPE5_SKIPPED` | `FILE` | `END` | `execKey`, `fileType=5`, `reason` | Пропуск reconcile type 5. |
| `RECONCILE_TYPE5_FAILED` | `FILE` | `ERROR` | `execKey`, `fileType=5`, `message` | Ошибка reconcile type 5. |
| `RECONCILE_TYPE5_MATCH_STATS` | `FILE` | `INFO` | `executionKey`, `fileType=5`, `raNew`, `raChanged`, `raUnchanged`, `raInvalid`, `raAmbiguous`, `rcNew`, `rcChanged`, `rcUnchanged`, `rcInvalid`, `rcAmbiguous` | Категории read-model RA/RC (`AuditReconcileCoordinator`, 1.8.11.4.3). |
| `RECONCILE_TYPE5_APPLY_STATS` | `FILE` | `INFO` | `executionKey`, `fileType=5`, `raInserted`, `raUpdated`, `raUnchanged`, `raDeleted`, `rcInserted`, `rcUpdated`, `rcUnchanged`, `rcDeleted`, `sumInserted` | Агрегат apply/dry-run (`AuditReconcileCoordinator`, 1.8.11.4.4). |
| `RECONCILE_TYPE5_DIAGNOSTICS` | `FILE` | `WARN` | `execKey`, `fileType=5`, `missingTop` | Top-представление диагностик (`Нет отправителя/стройки/периода`). |
| `ROW_PARAGRAPH_PREVIEW` | `FILE` | `INFO` | `sheetName`, `rowIndex`, `status=ACCEPTED` | Row-level preview для type 5 (staging). |
| `ROW_PARAGRAPH_PREVIEW_SKIPPED` | `FILE` | `WARN` | `sheetName`, `rowIndex`, `status=SKIPPED` | Row-level preview для пропущенной строки (нет данных). |
| `ROW_PARAGRAPH_PREVIEW_SUMMARY` | `FILE` | `INFO` | `sampled`, `suppressed`, `total`, `previewMode=FULL` | Итог row-level staging preview (без лимита). |
| `STAGING_ROW_INSERTED` | `FILE` | `INFO` | `sheetName`, `rowIndex`, `insertedId` | Строка добавлена в staging с ID (per-row, `af_source=true`). Целевой (1.8.11.7.1). |
| `RECONCILE_TYPE5_MODE` | `FILE` | `INFO` | `execKey`, `addRa`, `mode` | Режим reconcile: `DIAGNOSTIC`/`APPLY` (`AllAgentsReconcileService`, 1.8.11.4.5). |
| `RA_ROWS_SUMMARY` | `FILE` | `INFO` | `execKey`, `raRowsCount` | «Всего строк отчётов: N» перед блоком RA (`AllAgentsReconcileService`, 1.8.11.3.1). |
| `RA_NEW_CREATED` | `FILE` | `INFO` | `rowIndex`, `raNum`, `raKey`, `period`, `cstap` | Создан новый RA + ключ (per-row). Целевой (1.8.11.5.1). |
| `RA_NEW_SUMS` | `FILE` | `INFO` | `rowIndex`, `raKey`, `ttl`, `work`, `equip`, `others`, `hasSums` | Добавлены суммы RA или «суммы отсутствуют» (per-row). Целевой (1.8.11.5.2). |
| `RA_VALIDATION_FAIL` | `FILE` | `WARN` | `rowIndex`, `raNum`, `reason` | Отказ валидации RA: читаемая причина (per-row). Целевой (1.8.11.5.3). |
| `RA_FIELD_MISMATCH` | `FILE` | `WARN` | `rowIndex`, `raKey`, `field`, `oldValue`, `expectedValue` | Несовпадение поля RA: old (Crimson) vs expected (Peru). Целевой (1.8.11.5.4). |
| `RA_FIELD_UPDATED` | `FILE` | `INFO` | `rowIndex`, `raKey`, `field`, `newValue` | Обновлено поле RA (SeaGreen). Целевой (1.8.11.5.5). |
| `RA_SUM_MISMATCH` | `FILE` | `WARN` | `rowIndex`, `raKey`, `ttlOld`, `ttlNew`, `workOld`, `workNew`, `equipOld`, `equipNew`, `othersOld`, `othersNew` | Суммовой блок RA: покомпонентный diff + пересоздание. Целевой (1.8.11.5.6). |
| `RA_EXCESS_ITEM` | `FILE` | `WARN` | `rowIndex`, `raKey`, `raName` | Лишняя RA в домене (кандидат на удаление). Целевой (1.8.11.5.7). |
| `RC_ROWS_SUMMARY` | `FILE` | `INFO` | `execKey`, `rcRowsCount` | «Всего строк изменений: N» перед блоком RC (`AllAgentsReconcileService`, 1.8.11.3.2). |
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
- `P3 (partially done)`: staging row-level (`V-C.2.1.a.1.1.a.*`) — полный вывод без top-N, SCR-003-D (1.8.11.9.7). Полный per-row по reconcile RA/RC — целевое решение A, см. `1.8.11.5–1.8.11.7`.
- `P3.1 (done)`: реализован целевой критерий отбора строк type=5 по полю `Признак` (`ОА`/`ОА изм`/`ОА прочие`) из `ags.ra_sheet_conf`; `V-C.2.1.a.1.filter` переведён в `present`. Выполнено в `1.8.10.5` ✅.
- `P4`: реализовать row-level события reconcile type=5 (RA/RC new/changed/excess/validation) по решению A (full parity). Карта задач: `1.8.11.3–1.8.11.7`. Новые `eventKey`: `RA_ROWS_SUMMARY`, `RA_NEW_CREATED`, `RA_NEW_SUMS`, `RA_VALIDATION_FAIL`, `RA_FIELD_MISMATCH`, `RA_FIELD_UPDATED`, `RA_SUM_MISMATCH`, `RA_EXCESS_ITEM`, и симметричные `RC_*`. Плюс framework events: `RECONCILE_TYPE5_MODE`, `STAGING_ROW_INSERTED`.
