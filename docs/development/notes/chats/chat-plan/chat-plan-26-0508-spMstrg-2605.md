# План работы чата: Рефакторинг отчётной ветки spMstrg → версия _2605

**Дата:** 2026-05-08  
**Автор:** Александр  
**Связанные задачи:** (будут созданы в ходе работы)  
**Связанное резюме:** (будет создано по завершению)

---

## Контекст

В результате параллельного развития двух проектов — **MS Access + MS SQL Server** (действующая система) и **FEMSQ** (новый проект) — сложились дублирующиеся группы артефактов SQL Server, которые выполняют аналогичные задачи формирования наборов данных для отчётов.

### Существующие артефакты (папка `docs/development/notes/sql/26-0416`)

**Функции:**
- `ags.fnIpgChRsltCstUtl2_2408` — базовая функция: результаты по стройкам (разные схемы) для цепи инвестпрограмм
- `ags.fnIpgChRsltCstUtl2_2408_ipgSt` — тонкая обёртка над предыдущей с JOIN к `importIpgSt_26-0320` и фильтром по `@ipgSt`
- `ags.fnIpgChRsltCstUtlPercentBrn_2408` — большая аналитическая функция (полный набор данных для отчётов); источник для процедур
- `ags.fnIpgChRsltCstUtlPercentBrn_2408_ipgSt` — ~261 КБ, почти полная копия предыдущей; единственное отличие — в строке FROM вызывает `fnIpgChRsltCstUtl2_2408_ipgSt` вместо `fnIpgChRsltCstUtl2_2408`

**Процедуры:**
- `ags.spMstrg_2408` — возвращает 7 рекордсетов клиенту MS Access
- `ags.spMstrg_2408_ipgSt` — то же, но с фильтром по группе строек (`@ipgSt` захардкожен внутри как `'12ОПР'`)
- `ags.spMstrg_2408_SaveToTables` — заполняет 7 таблиц SQL Server (для FEMSQ/JasperReports, обходит ограничение таймаута DBHub)
- `ags.spMstrg_2408_SaveToTables_ipgSt` — то же, но с фильтром по группе строек

**Справочник группировки строек:**
- `ags.[importIpgSt_26-0320]` — таблица (`cst`, `cst_type`); 780 строек, 6 групп (`99ОСТ`, `23КПР`, `20ПКП`, `12ОПР`, `11ПРЗ`, `30ППР`)

**Клиенты процедур:**
- **MS Access** (VBA, `Form_ipgChMin.cls`, `btnMasteringPercent_2408_Click`) — вызывает `spMstrg_2408` или `spMstrg_2408_ipgSt` (выбор — копипаст из комментария; `@ipgSt` группа захардкожена внутри SP); получает рекордсеты и пишет в локальные таблицы Access
- **FEMSQ / JasperReports** (Java) — вызывает `spMstrg_2408_SaveToTables`; отчёт читает из таблиц SQL Server напрямую

### Проблемы

1. **Критическое дублирование:** `fnIpgChRsltCstUtlPercentBrn_2408_ipgSt` (~261 КБ) — почти полная копия `fnIpgChRsltCstUtlPercentBrn_2408`. Изменение логики требует синхронного правки двух объектов.
2. **Дублирование процедур:** логика 7 рекордсетов существует в четырёх экземплярах (`spMstrg_2408`, `_ipgSt`, `_SaveToTables`, `_SaveToTables_ipgSt`).
3. **Захардкоженные параметры в VBA:** имя процедуры и группа строек не параметризованы — выбираются вручную через копипаст.
4. **Отсутствие параметра группы в UI:** нет элемента управления для выбора `@ipgSt` на форме Access.

---

## Принятые решения

- **Именование новых объектов:** суффикс `_2605` (май 2026 — дата архитектурной ревизии), аналогично сложившейся конвенции `_2408`
- **Стратегия перехода:** параллельная разработка; старые `_2408`-объекты сохраняются до финального тестирования новых `_2605`-объектов, после чего удаляются
- **Объекты `_ipgSt`** не получают аналогов в `_2605`-серии — параметр `@ipgSt` встраивается в основные объекты

### Целевая архитектура

```
importIpgSt_26-0320  (справочник групп, не меняется)
         ↓ JOIN (внутри функции, условно при @ipgSt IS NOT NULL)
fnIpgChRsltCstUtl2_2605 (@ipgChKey, @ipgSt nvarchar(255) = NULL)
         ↓
fnIpgChRsltCstUtlPercentBrn_2605 (@ipgChKey, @ipgSt nvarchar(255) = NULL)
         ↓
spMstrg_2605 (@ipgCh, @MounthEndDate, @ipgSt = NULL, @saveToTables bit = 0)
    ├── @saveToTables = 0  →  SELECT ×7  →  MS Access (рекордсеты → локальные таблицы)
    └── @saveToTables = 1  →  INSERT ×7  →  FEMSQ (JasperReports читает таблицы SQL Server)

Форма Access:
    cbxIpgSt [(все стройки) / 99ОСТ / 23КПР / 20ПКП / 12ОПР / 11ПРЗ / 30ППР]
         ↓
    btnMasteringPercent_2408_Click → spMstrg_2605 с динамическим @ipgSt
```

### Объекты к удалению после перехода

- `fnIpgChRsltCstUtl2_2408_ipgSt`
- `fnIpgChRsltCstUtlPercentBrn_2408_ipgSt`
- `spMstrg_2408_ipgSt`
- `spMstrg_2408_SaveToTables_ipgSt`
- `spMstrg_2408` (заменяется `spMstrg_2605` с `@saveToTables = 0`)
- `spMstrg_2408_SaveToTables` (заменяется `spMstrg_2605` с `@saveToTables = 1`)

---

## Структурный план

### Этап 0 — Подготовка и верификация

- [ ] **0.1 Проверка текущего состояния БД**
  - [ ] 0.1.1 Убедиться, что все 8 целевых объектов `_2408` существуют в БД (`FishEye`, схема `ags`)
  - [ ] 0.1.2 Убедиться, что таблица `importIpgSt_26-0320` заполнена (780 строк, 6 групп)
  - [ ] 0.1.3 Убедиться, что таблицы `spMstrg_2408_ResultSet1..7` существуют и доступны
  - [ ] 0.1.4 Зафиксировать эталонные результаты для последующего сравнения:
    - Количество строк в каждой ResultSet-таблице при текущих параметрах (`@ipgCh=15`, `@MounthEndDate` — актуальная дата)
    - Контрольные суммы по ключевым полям (`ag_accepted`, `ag_lim`) в RS1 и RS2

- [ ] **0.2 Изучение исходного кода `fnIpgChRsltCstUtl2_2408`**
  - [ ] 0.2.1 Получить `OBJECT_DEFINITION` функции из БД
  - [ ] 0.2.2 Определить тип функции (inline TVF vs multi-statement TVF)
  - [ ] 0.2.3 Выявить точку, где добавляется фильтрация по `cstAgPnCode` (для `_ipgSt`-варианта)

---

### Этап 1 — Создание `fnIpgChRsltCstUtl2_2605`

- [ ] **1.1 Проектирование**
  - [ ] 1.1.1 Определить способ условной фильтрации по `@ipgSt`:
    - При `@ipgSt IS NULL` — возвращать все стройки (поведение как у `_2408`)
    - При `@ipgSt IS NOT NULL` — LEFT JOIN/EXISTS к `ags.[importIpgSt_26-0320]` по `cstAgPnCode = cst` и `cst_type = @ipgSt`
  - [ ] 1.1.2 Учесть тип функции: если inline TVF — условный фильтр через `WHERE (@ipgSt IS NULL OR EXISTS(...))`, если multi-statement — возможно `IF/ELSE` ветвление
  - [ ] 1.1.3 Оценить влияние условного JOIN на производительность оптимизатора

- [ ] **1.2 Создание функции в БД**
  - [ ] 1.2.1 Написать скрипт `CREATE FUNCTION ags.fnIpgChRsltCstUtl2_2605`
  - [ ] 1.2.2 Сохранить скрипт в `docs/development/notes/sql/26-0508/CREATE_FUNCTION_ags_fnIpgChRsltCstUtl2_2605.sql`
  - [ ] 1.2.3 Выполнить скрипт в БД

- [ ] **1.3 Тестирование**
  - [ ] 1.3.1 Проверить режим «все стройки» (`@ipgSt = NULL`): количество строк должно совпадать с `fnIpgChRsltCstUtl2_2408`
  - [ ] 1.3.2 Проверить режим фильтрации (`@ipgSt = '12ОПР'`): количество строк должно совпадать с `fnIpgChRsltCstUtl2_2408_ipgSt` при том же параметре
  - [ ] 1.3.3 Проверить остальные группы: `99ОСТ`, `23КПР`, `20ПКП`, `11ПРЗ`, `30ППР`

---

### Этап 2 — Создание `fnIpgChRsltCstUtlPercentBrn_2605`

- [ ] **2.1 Проектирование**
  - [ ] 2.1.1 Взять за основу `fnIpgChRsltCstUtlPercentBrn_2408`
  - [ ] 2.1.2 Добавить параметр `@ipgSt nvarchar(255) = NULL`
  - [ ] 2.1.3 Изменить строку источника данных (единственное содержательное изменение):
    - Было: `from ags.fnIpgChRsltCstUtl2_2408(@ipgChKey) t`
    - Стало: `from ags.fnIpgChRsltCstUtl2_2605(@ipgChKey, @ipgSt) t`
  - [ ] 2.1.4 Убедиться, что `cst_type` из `_2605`-функции не конфликтует с именами столбцов результирующей выборки

- [ ] **2.2 Создание функции в БД**
  - [ ] 2.2.1 Написать скрипт `CREATE FUNCTION ags.fnIpgChRsltCstUtlPercentBrn_2605`
  - [ ] 2.2.2 Сохранить скрипт в `docs/development/notes/sql/26-0508/CREATE_FUNCTION_ags_fnIpgChRsltCstUtlPercentBrn_2605.sql`
  - [ ] 2.2.3 Выполнить скрипт в БД

- [ ] **2.3 Тестирование**
  - [ ] 2.3.1 Режим «все стройки» (`@ipgSt = NULL`): сравнить количество строк и контрольные суммы с `fnIpgChRsltCstUtlPercentBrn_2408`
  - [ ] 2.3.2 Режим фильтрации (`@ipgSt = '12ОПР'`): сравнить с результатами `fnIpgChRsltCstUtlPercentBrn_2408_ipgSt`
  - [ ] 2.3.3 Зафиксировать время выполнения для обоих режимов

---

### Этап 3 — Создание `spMstrg_2605`

- [ ] **3.1 Проектирование**
  - [ ] 3.1.1 Определить сигнатуру:
    ```sql
    CREATE PROCEDURE ags.spMstrg_2605
        @ipgCh         int,
        @MounthEndDate date,
        @ipgSt         nvarchar(255) = NULL,  -- NULL = все стройки
        @saveToTables  bit           = 0      -- 0 = SELECT (Access), 1 = INSERT (FEMSQ)
    ```
  - [ ] 3.1.2 Определить структуру тела процедуры:
    - Заполнить `@TableFnIpgChRsltCstUtlPercentBrn_2605` из `fnIpgChRsltCstUtlPercentBrn_2605(@ipgCh, @ipgSt)`
    - Для каждого из 7 рекордсетов: `IF @saveToTables = 1 → INSERT INTO ResultSet_N; ELSE → SELECT`
    - При `@saveToTables = 1`: предварительно выполнить `TRUNCATE TABLE` для всех 7 таблиц
  - [ ] 3.1.3 Убедиться, что логирование времени шагов сохранено (PRINT-операторы)

- [ ] **3.2 Создание процедуры в БД**
  - [ ] 3.2.1 Написать скрипт `CREATE PROCEDURE ags.spMstrg_2605`
  - [ ] 3.2.2 Сохранить скрипт в `docs/development/notes/sql/26-0508/CREATE_PROCEDURE_ags_spMstrg_2605.sql`
  - [ ] 3.2.3 Выполнить скрипт в БД

- [ ] **3.3 Тестирование режима Access (`@saveToTables = 0`)**
  - [ ] 3.3.1 Вызвать через DBHub или sqlcmd с `@ipgSt = NULL`: убедиться, что возвращает 7 рекордсетов
  - [ ] 3.3.2 Вызвать с `@ipgSt = '12ОПР'`: проверить фильтрацию
  - [ ] 3.3.3 Сравнить количество строк и суммы с `spMstrg_2408` (режим без фильтра)

- [ ] **3.4 Тестирование режима FEMSQ (`@saveToTables = 1`)**
  - [ ] 3.4.1 Вызвать через sqlcmd с `@ipgSt = NULL`, зафиксировать время выполнения
  - [ ] 3.4.2 Проверить заполнение таблиц `spMstrg_2408_ResultSet1..7`: количество строк, контрольные суммы
  - [ ] 3.4.3 Сравнить результаты с эталоном из п. 0.1.4
  - [ ] 3.4.4 Вызвать с `@ipgSt = '12ОПР'`: убедиться, что в таблицах только отфильтрованные данные

---

### Этап 4 — Обновление VBA (`Form_ipgChMin.cls`)

- [ ] **4.1 Добавление элемента управления на форму Access**
  - [ ] 4.1.1 Добавить `cbxIpgSt` (ComboBox) на форму `Form_ipgChMin`
  - [ ] 4.1.2 Настроить источник строк:
    ```sql
    SELECT '' AS cst_type, '(все стройки)' AS cst_type_nm
    UNION SELECT DISTINCT cst_type, cst_type FROM ags.[importIpgSt_26-0320]
    ORDER BY 1
    ```
  - [ ] 4.1.3 Настроить свойства: `BoundColumn = 1`, `ColumnWidths`, подпись на форме

- [ ] **4.2 Корректировка `btnMasteringPercent_2408_Click()`**
  - [ ] 4.2.1 Изменить `.CommandText` на `"ags.spMstrg_2605"` (единственное имя)
  - [ ] 4.2.2 Добавить параметр `@ipgSt`:
    ```vba
    .Parameters.Append .CreateParameter("@ipgSt", adVarWChar, adParamInput, 255, _
        IIf(Nz(Me!cbxIpgSt, "") = "", Null, Me!cbxIpgSt))
    ```
  - [ ] 4.2.3 Добавить параметр `@saveToTables = 0` (явно, для документальности):
    ```vba
    .Parameters.Append .CreateParameter("@saveToTables", adSmallInt, adParamInput, , 0)
    ```
  - [ ] 4.2.4 Убедиться, что порядок `.Parameters.Append` соответствует сигнатуре процедуры
  - [ ] 4.2.5 Обновить константу `cstrTitle` — отразить новое имя процедуры и наличие фильтра группы

- [ ] **4.3 Тестирование в MS Access**
  - [ ] 4.3.1 Проверить работу кнопки с `cbxIpgSt = "(все стройки)"` — результат должен совпадать со старым `spMstrg_2408`
  - [ ] 4.3.2 Проверить работу с `cbxIpgSt = '12ОПР'` — результат должен совпадать со старым `spMstrg_2408_ipgSt`
  - [ ] 4.3.3 Проверить все 6 групп

---

### Этап 5 — Обновление FEMSQ (Java / JasperReports)

- [ ] **5.1 Найти место вызова `spMstrg_2408_SaveToTables` в коде Java**
  - [ ] 5.1.1 Поиск по кодовой базе `code/femsq-backend`

- [ ] **5.2 Изменить вызов на `spMstrg_2605` с `@saveToTables = 1`**
  - [ ] 5.2.1 Добавить передачу параметра `@ipgSt` (NULL для текущего отчёта)
  - [ ] 5.2.2 Проверить, что таймаут соединения достаточен (процедура выполняется ~126 сек)

- [ ] **5.3 Проверить работу JasperReports**
  - [ ] 5.3.1 Запустить отчёт `mstrgAg_23_Branch_q2m_2408_25`, убедиться в корректности данных

---

### Этап 6 — Финализация и очистка

- [ ] **6.1 Финальная верификация**
  - [ ] 6.1.1 Запустить все тесты: Access (все группы + без фильтра), FEMSQ (режим таблиц)
  - [ ] 6.1.2 Сравнить результаты `_2605` с эталоном `_2408` — расхождений не должно быть

- [ ] **6.2 Удаление устаревших объектов из БД**
  - [ ] 6.2.1 `DROP FUNCTION ags.fnIpgChRsltCstUtl2_2408_ipgSt`
  - [ ] 6.2.2 `DROP FUNCTION ags.fnIpgChRsltCstUtlPercentBrn_2408_ipgSt`
  - [ ] 6.2.3 `DROP PROCEDURE ags.spMstrg_2408_ipgSt`
  - [ ] 6.2.4 `DROP PROCEDURE ags.spMstrg_2408_SaveToTables_ipgSt`
  - [ ] 6.2.5 `DROP PROCEDURE ags.spMstrg_2408` (после подтверждения замены)
  - [ ] 6.2.6 `DROP PROCEDURE ags.spMstrg_2408_SaveToTables` (после подтверждения замены)
  - [ ] 6.2.7 Сохранить DROP-скрипты в `docs/development/notes/sql/26-0508/DROP_obsolete_2408_objects.sql`

- [ ] **6.3 Документирование**
  - [ ] 6.3.1 Обновить `docs/solutions/spMstrg_2408_execution.md` — добавить раздел о `spMstrg_2605`
  - [ ] 6.3.2 Обновить `docs/project/project-docs.json` — секция `reports.implemented`, источник данных
  - [ ] 6.3.3 Создать резюме чата `docs/development/notes/chats/chat-resume/chat-resume-26-0508-spMstrg-2605.md`
  - [ ] 6.3.4 Сделать запись в `docs/journal/project-journal.json`

---

## Контрольные точки

| Точка | Условие готовности |
|---|---|
| К-0 | Эталонные данные зафиксированы; все `_2408`-объекты подтверждены в БД |
| К-1 | `fnIpgChRsltCstUtl2_2605` создана и протестирована в обоих режимах |
| К-2 | `fnIpgChRsltCstUtlPercentBrn_2605` создана; результаты совпадают с `_2408` эталоном |
| К-3 | `spMstrg_2605` создана; оба режима (`@saveToTables = 0/1`) протестированы |
| К-4 | VBA обновлён; форма Access работает с новой процедурой во всех вариантах |
| К-5 | FEMSQ переключён на `spMstrg_2605`; отчёт JasperReports выдаёт корректные данные |
| К-6 | Старые `_2408`/`_ipgSt` объекты удалены; документация обновлена |

---

## Справочная информация

### Машина разработки
- **Среда:** `nb-win` (WSL2, Ubuntu 24.04 на Windows 11)
- **БД:** Docker-контейнер `femsq-mssql`, `localhost:1433`, БД `FishEye`
- **SQL Server:** 2022 (RTM-CU23), `DB_ID('FishEye') = 5`
- **DBHub:** `.cursor/dbhub/node_modules/@bytebase/dbhub/dist/index.js` (таймаут 15 сек)
- **sqlcmd:** внутри контейнера `/opt/mssql-tools18/bin/sqlcmd -C`

### Ключевые параметры для тестирования
- `@ipgCh = 15` (цепь инвестпрограмм)
- `@MounthEndDate` — последний день актуального месяца
- `@ipgSt = NULL` — все стройки (эталон: ~12693 строки в RS1–3, ~744 в RS4, ~32 в RS5–7)
- `@ipgSt = '12ОПР'` — группа для сравнения с `_ipgSt`-вариантами

### Расположение скриптов
- Новые SQL-скрипты: `docs/development/notes/sql/26-0508/`
- Существующие `_2408` скрипты (эталон): `docs/development/notes/sql/26-0416/`
- VBA-исходник: `docs/project/proposals/vba-analysis/VBA-Code-Export/Form-Modules/Form_ipgChMin.cls`
