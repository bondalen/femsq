# Порядок работ: обновление `spMstrg_2408` → `spMstrg_2605`

**Файл:** `docs/deployment/db-upgrade-spMstrg-2605.md`  
**Дата:** 2026-05-16  
**Версия:** 1.0  
**Автор:** ANB

---

## 1. Назначение и область применения

Документ описывает порядок применения изменений на **продуктивном сервере** БД `FishEye` в рамках задачи добавления фильтрации по стройке (`@ipgSt`) в процедуру формирования отчёта об освоении.

**Что меняется:**
- Создаются три новых объекта `_2605` с поддержкой фильтра `@ipgSt`
- Клиент Access переключается на `spMstrg_2605` (вместо `spMstrg_2408`)
- Клиент FEMSQ/JasperReports переключается на `spMstrg_2605` (вместо `spMstrg_2408_SaveToTables`)
- Старые `_2408`-объекты **не удаляются** — только после отдельного подтверждения

**Область применения:**
- Сервер: продуктивный SQL Server (вся БД `FishEye`)
- Клиенты: MS Access (`Form_ipgChMin`), FEMSQ Java-приложение

---

## 2. Предварительные условия

| # | Условие | Проверка |
|---|---------|---------|
| 2.1 | SQL Server 2016+ (требуется `CREATE OR ALTER`) | `SELECT @@VERSION` |
| 2.2 | Объект `ags.[importIpgSt_26-0320]` существует в БД | `SELECT OBJECT_ID('ags.[importIpgSt_26-0320]')` |
| 2.3 | Процедура `ags.spMstrg_2408_SaveToTables` существует | `SELECT OBJECT_ID('ags.spMstrg_2408_SaveToTables')` |
| 2.4 | Таблицы `ags.spMstrg_2408_ResultSet1..7` существуют | `SELECT COUNT(*) FROM sys.tables WHERE name LIKE 'spMstrg_2408_ResultSet%'` |
| 2.5 | Резервная копия БД `FishEye` выполнена | см. регламент резервного копирования |
| 2.6 | Доступ к SQL Server с правами `db_ddladmin` | — |
| 2.7 | `sqlcmd` доступен или SSMS подключён к серверу | — |

---

## 3. Состав пакета

Пакет находится в `docs/development/notes/sql/26-0508/`.

| Файл | Назначение | Порядок |
|------|-----------|---------|
| `00_VERIFY_before.sql` | Проверка состояния «до» (эталонные COUNT и объекты) | 0 — до всех изменений |
| `01_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2605.sql` | Создание inline TVF с фильтром `@ipgSt` | 1 |
| `02_CREATE_FUNCTION_fnIpgChRsltCstUtlPercentBrn_2605.sql` | Создание multi-statement TVF через `sp_executesql` | 2 |
| `03_CREATE_PROCEDURE_spMstrg_2605.sql` | Создание процедуры (`saveToTables=0/1`, `@ipgSt`) | 3 |
| `04_VERIFY_after.sql` | Проверка состояния «после» (сравнительные COUNT) | 4 — после применения 01–03 |
| `05_ROLLBACK.sql` | Откат: DROP объектов `_2605` в обратном порядке | только при необходимости отката |

---

## 4. Порядок выполнения (SQL-часть)

Выполнять скрипты **последовательно** в указанном порядке.  
На продуктиве скрипты применяет **администратор БД** — разработчик предоставляет пакет.

```
1. Резервная копия БД FishEye
2. Запустить 00_VERIFY_before.sql  → зафиксировать результаты в таблице приёмки (раздел 8)
3. Запустить 01_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2605.sql
4. Запустить 02_CREATE_FUNCTION_fnIpgChRsltCstUtlPercentBrn_2605.sql
5. Запустить 03_CREATE_PROCEDURE_spMstrg_2605.sql
6. Запустить 04_VERIFY_after.sql   → проверить, что COUNT совпадают с ожидаемыми
7. Внести изменения в MS Access (раздел 6)
8. Развернуть обновлённое FEMSQ-приложение (раздел 7)
```

**Важно:** Скрипты 01–03 используют `CREATE OR ALTER` и идемпотентны — безопасно выполнять повторно.

---

## 5. Откат

Если что-то пошло не так, выполнить `05_ROLLBACK.sql`:

```sql
-- Удаляет в правильном порядке:
DROP PROCEDURE  IF EXISTS [ags].[spMstrg_2605];
DROP FUNCTION   IF EXISTS [ags].[fnIpgChRsltCstUtlPercentBrn_2605];
DROP FUNCTION   IF EXISTS [ags].[fnIpgChRsltCstUtl2_2605];
```

После отката клиенты Access и FEMSQ продолжают работать с `_2408`-объектами (они не затрагиваются).

---

## 6. Изменения MS Access (`Form_ipgChMin`)

> **Выполняется вручную** разработчиком/администратором Access.  
> Исходник формы: `docs/project/proposals/vba-analysis/VBA-Code-Export/Form-Modules/Form_ipgChMin.cls`

### 6.1 Добавить ComboBox `cbxIpgSt` на форму `Form_ipgChMin`

**В режиме конструктора формы `Form_ipgChMin`:**

1. Добавить ComboBox с именем `cbxIpgSt`
2. Задать свойство **Источник строк (RowSource):**

```sql
SELECT '' AS cst_type, '(все стройки)' AS nm
UNION
SELECT DISTINCT cst_type, cst_type
FROM ags.[importIpgSt_26-0320]
ORDER BY 1
```

3. Задать остальные свойства:

| Свойство | Значение |
|----------|----------|
| `RowSourceType` | `Table/Query` |
| `BoundColumn` | `1` |
| `ColumnCount` | `2` |
| `ColumnWidths` | `0cm;4cm` |
| `DefaultValue` | `""` (пустая строка = все стройки) |
| `LimitToList` | `Yes` |

4. Разместить элемент рядом с кнопкой `btnMasteringPercent_2408_Click` (рекомендуется добавить метку «Стройка:»).

### 6.2 Изменить обработчик `btnMasteringPercent_2408_Click()`

Найти в коде процедуры следующий блок (примерно строки 200–208):

**БЫЛО:**
```vba
With SQLCmd1
   .CommandTimeout = 0
   .ActiveConnection = objConn
   .CommandType = adCmdStoredProc
   .CommandText = "ags.spMstrg_2408"
   ' параметры
   .Parameters.Append .CreateParameter("@ipgCh", adBigInt, adParamInput, , Me!ipgcKey)
   .Parameters.Append .CreateParameter("@MounthEndDate", adDate, adParamInput, , dateEndMount)
End With
```

**СТАЛО:**
```vba
With SQLCmd1
   .CommandTimeout = 0
   .ActiveConnection = objConn
   .CommandType = adCmdStoredProc
   .CommandText = "ags.spMstrg_2605"
   ' параметры — порядок должен совпадать с сигнатурой процедуры
   .Parameters.Append .CreateParameter("@ipgCh", adBigInt, adParamInput, , Me!ipgcKey)
   .Parameters.Append .CreateParameter("@MounthEndDate", adDate, adParamInput, , dateEndMount)
   ' @ipgSt: NULL = все стройки (пустое значение cbxIpgSt тоже означает "все")
   If IsNull(Me!cbxIpgSt) Or CStr(Nz(Me!cbxIpgSt, "")) = "" Then
       .Parameters.Append .CreateParameter("@ipgSt", adVarWChar, adParamInput, 255, Null)
   Else
       .Parameters.Append .CreateParameter("@ipgSt", adVarWChar, adParamInput, 255, Me!cbxIpgSt)
   End If
   ' @saveToTables = 0: Access получает 7 рекордсетов через SELECT
   .Parameters.Append .CreateParameter("@saveToTables", adBoolean, adParamInput, , False)
End With
```

### 6.3 Проверка порядка параметров

Порядок **обязателен** (positional parameters в ADODB StoredProc):

| # | Параметр | Тип ADODB | Тип SQL | Значение |
|---|----------|-----------|---------|----------|
| 1 | `@ipgCh` | `adBigInt` | `int` | `Me!ipgcKey` |
| 2 | `@MounthEndDate` | `adDate` | `date` | последний день месяца |
| 3 | `@ipgSt` | `adVarWChar` | `nvarchar(255)` | `NULL` или значение из `cbxIpgSt` |
| 4 | `@saveToTables` | `adBoolean` | `bit` | `False` (= 0) |

### 6.4 Тестирование после изменений в Access

| # | Действие | Ожидаемый результат |
|---|---------|---------------------|
| Т-1 | Открыть `Form_ipgChMin`, выбрать цепь и месяц | Форма открывается без ошибок |
| Т-2 | `cbxIpgSt` = `(все стройки)`, нажать кнопку | Данные загружены, ~12693 строк в RS1 (для ipgCh=15) |
| Т-3 | `cbxIpgSt` = `12ОПР`, нажать кнопку | Данные загружены, ~604 строки в RS1 |
| Т-4 | Проверить все 6 групп отчёта | Данные корректны |

---

## 7. Изменения FEMSQ (Java / JasperReports)

> Выполняется при деплое обновлённой версии FEMSQ-приложения.  
> Подробнее: Этап 5 плана `chat-plan-26-0508-spMstrg-2605.md`.

**Суть изменения:**
- Найти вызов `spMstrg_2408_SaveToTables` в `code/femsq-backend`
- Заменить на `spMstrg_2605` с параметрами `@ipgSt = NULL` и `@saveToTables = 1`

**Важно:** Время выполнения процедуры ~16 сек (на dev-сервере). Убедиться, что таймаут соединения достаточен (`CommandTimeout = 0` или >= 60).

---

## 8. Таблица приёмочной проверки

Заполняется администратором при применении изменений на продуктиве.

### 8.1 Проверка «до» (`00_VERIFY_before.sql`)

| Проверка | Ожидание | Факт | ✓ |
|---------|---------|------|---|
| `fnIpgChRsltCstUtl2_2408` существует | объект есть | | |
| `fnIpgChRsltCstUtlPercentBrn_2408` существует | объект есть | | |
| `spMstrg_2408` существует | объект есть | | |
| `spMstrg_2408_SaveToTables` существует | объект есть | | |
| `importIpgSt_26-0320` существует | объект есть | | |
| ResultSet1..7 существуют (7 таблиц) | 7 таблиц | | |

### 8.2 Проверка «после» (`04_VERIFY_after.sql`)

| Проверка | Ожидание | Факт | ✓ |
|---------|---------|------|---|
| `fnIpgChRsltCstUtl2_2605` существует | объект есть | | |
| `fnIpgChRsltCstUtlPercentBrn_2605` существует | объект есть | | |
| `spMstrg_2605` существует | объект есть | | |
| `fn_2408` vs `fn_2605` столбцы | одинаково | | |
| `spMstrg_2605(ipgCh=15, NULL, save=1)` RS1 | = RS1 от `_SaveToTables` | | |
| `spMstrg_2605(ipgCh=15, '12ОПР', save=1)` RS1 | < RS1 от `_SaveToTables` | | |

### 8.3 Тестирование Access

| Проверка | Ожидание | Факт | ✓ |
|---------|---------|------|---|
| `cbxIpgSt = NULL` → кнопка | успешно, данные = как раньше | | |
| `cbxIpgSt = '12ОПР'` → кнопка | успешно, данных меньше | | |

---

## История изменений

| Версия | Дата | Описание |
|--------|------|---------|
| 1.0 | 2026-05-16 | Первый черновик (SQL-часть + Access-инструкция заполнены; FEMSQ — краткое описание) |
