# Решение проблемы таймаута выполнения процедуры spMstrg_2408

**Дата создания:** 2025-12-04  
**Автор:** AI Assistant  
**Статус:** Реализовано и протестировано

## Проблема

Хранимая процедура `ags.spMstrg_2408` возвращает 6 рекордсетов с результатами анализа инвестиционных программ. Время выполнения процедуры превышает 15 секунд, что является ограничением DBHub (@bytebase/dbhub) для выполнения SQL-запросов через MCP-сервер.

## Анализ возможностей DBHub

### Ограничения DBHub
- **Фиксированный таймаут:** 15 секунд на выполнение запроса
- **Невозможно изменить:** Таймаут захардкожен в коде DBHub и не настраивается
- **Ограничение MCP:** Все MCP-серверы имеют схожие ограничения по времени выполнения

## Предложенное решение: Модифицированная процедура + sqlcmd

**Преимущества:**
- ✅ Настраиваемый таймаут (установлен на 10 минут / 600 секунд)
- ✅ Сохранение всех результатов в таблицы для последующего анализа
- ✅ Возможность выполнения на любой машине с MS SQL Server Tools
- ✅ Логирование процесса выполнения и времени каждого шага

## Использование

### Запуск процедуры

```bash
cd /home/alex/projects/java/spring/vue/femsq/code/scripts
./execute_spMstrg_2408.sh
```

Скрипт автоматически:
- Создаст процедуру `ags.spMstrg_2408_SaveToTables`
- Выполнит её с параметрами `@ipgCh=15, @MounthEndDate='2025-07-31'`
- Проверит результаты

### Проверка результатов через DBHub

```sql
SELECT 
    'ResultSet1' AS TableName,
    COUNT(*) AS RecordCount,
    MIN(dateRslt) AS MinDate,
    MAX(dateRslt) AS MaxDate
FROM ags.spMstrg_2408_ResultSet1;
```

## Реализация

### Созданные таблицы

Процедура `ags.spMstrg_2408_SaveToTables` заполняет 6 таблиц:

1. **`ags.spMstrg_2408_ResultSet1`** (179 столбцов)
   - Полный набор данных из функции `fnIpgChRsltCstUtlPercentBrn_2408`
   - Все схемы реализации: агентская, инвестиционная, неизвестная, неплан, прочие
   - **Количество записей:** 12693

2. **`ags.spMstrg_2408_ResultSet2`** (179 столбцов)
   - Переупорядоченные столбцы: сначала ag_, затем iv_, ia_
   - Те же данные, что в ResultSet1, но с другим порядком столбцов
   - **Количество записей:** 12693

3. **`ags.spMstrg_2408_ResultSet3`** (220 столбцов)
   - Столбцы без префиксов ag_, iv_, ia_: np_, uk_, oh_ и общие
   - Данные для неплановых, неизвестных и прочих затрат
   - **Количество записей:** 12693

4. **`ags.spMstrg_2408_ResultSet4`** (44 столбца)
   - Данные с JOIN для трёх месяцев: текущий, предыдущий, предпредыдущий
   - Фильтрация по `dateRslt = @MounthEndDate`
   - Используется табличная переменная `@TableFnIpgChRsltCstUtlPercentBrnRep01_2408`
   - **Количество записей:** 744 (зависит от даты)

5. **`ags.spMstrg_2408_ResultSet5`** (44 столбца)
   - Данные из ResultSet4 с фильтрацией `WHERE cstAgPnCode = 'всего'`
   - UNION с разделительной строкой ('агентская_', 'Заказчики')
   - Сортировка: `ORDER BY ipgSh, limSort DESC, lim DESC`
   - **Количество записей:** 32 (31 + 1 разделительная строка)

6. **`ags.spMstrg_2408_ResultSet6`** (51 столбец)
   - Данные с источниками освоения (ag_accepted, ag_agFeeAccepted, np_accepted и т.д.)
   - Фильтрация по `dateRslt = @MounthEndDate` и `cstAgPnCode = 'всего'`
   - Используется табличная переменная `@TableFnIpgChRsltCstUtlPercentBrnRepSrc01_2408`
   - UNION с разделительной строкой
   - Сортировка: `ORDER BY ipgSh, limSort DESC, lim DESC`
   - **Количество записей:** 32 (31 + 1 разделительная строка)

## Результаты тестирования

**Время выполнения:** 126 секунд (2 минуты 6 секунд)

**Время выполнения шагов:**
- Очистка таблиц: 710 мс
- Заполнение временной таблицы: 106140 мс (106 секунд)
- ResultSet1: 2845 мс (2.8 секунды)
- ResultSet2: 2043 мс (2.0 секунды)
- ResultSet3: 2220 мс (2.2 секунды)
- ResultSet4: 11827 мс (11.8 секунд)
- ResultSet5: 41 мс (0.04 секунды)
- ResultSet6: 163 мс (0.16 секунды)

**Результаты:**
- ✅ Все 6 таблиц заполнены данными
- ✅ Целостность данных подтверждена (суммы совпадают между рекордсетами)
- ✅ Фильтрация работает корректно
- ✅ Сортировка работает правильно
- ✅ Процедура работает в пределах таймаута sqlcmd (10 минут)

### Проверка результатов

```sql
-- Проверка количества записей во всех таблицах
SELECT 
    'ResultSet1' AS TableName, COUNT(*) AS RecordCount FROM ags.spMstrg_2408_ResultSet1
UNION ALL SELECT 'ResultSet2', COUNT(*) FROM ags.spMstrg_2408_ResultSet2
UNION ALL SELECT 'ResultSet3', COUNT(*) FROM ags.spMstrg_2408_ResultSet3
UNION ALL SELECT 'ResultSet4', COUNT(*) FROM ags.spMstrg_2408_ResultSet4
UNION ALL SELECT 'ResultSet5', COUNT(*) FROM ags.spMstrg_2408_ResultSet5
UNION ALL SELECT 'ResultSet6', COUNT(*) FROM ags.spMstrg_2408_ResultSet6;
```

---

## Обновление 2026-05 — Новая процедура `spMstrg_2605`

### Что изменилось

В мае 2026 года создана процедура `ags.spMstrg_2605`, которая объединяет функциональность `spMstrg_2408` и `spMstrg_2408_SaveToTables`, добавляет фильтрацию по стройке (`@ipgSt`) и управляет режимом работы через параметр `@saveToTables`.

### Новые объекты БД

| Объект | Тип | Назначение |
|--------|-----|-----------|
| `ags.fnIpgChRsltCstUtl2_2605` | Inline TVF | Базовая функция расчёта с фильтром `@ipgSt` |
| `ags.fnIpgChRsltCstUtlPercentBrn_2605` | Multi-statement TVF | Сводный расчёт по бренду с фильтром `@ipgSt` |
| `ags.spMstrg_2605` | Хранимая процедура | Объединяет режимы Access (SELECT) и FEMSQ (INSERT) |

### Сигнатура `spMstrg_2605`

```sql
EXEC ags.spMstrg_2605
    @ipgCh        int,              -- код цепи ИПГ (обязательный)
    @MounthEndDate date,            -- последний день периода (обязательный)
    @ipgSt        nvarchar(255),    -- фильтр по стройке (NULL = все стройки)
    @saveToTables  bit;             -- 0 = SELECT-режим (Access), 1 = INSERT-режим (FEMSQ)
```

### Режимы работы

**Режим `@saveToTables = 0` (Access/ADODB):**
- Возвращает 7 рекордсетов через `SELECT` — обратно совместим с `spMstrg_2408`
- Используется при вызове из VBA (`Form_ipgChMin`, обработчик `btnMasteringPercent_2408_Click`)
- При `@ipgSt = NULL` данные идентичны `spMstrg_2408`

**Режим `@saveToTables = 1` (FEMSQ/JasperReports):**
- Выполняет `TRUNCATE` → `INSERT INTO` для таблиц `ags.spMstrg_2408_ResultSet1..7`
- Данные те же таблицы, что использует `spMstrg_2408_SaveToTables`
- JRXML-шаблон и Java-код `ReportGenerationService` **не требуют изменений**

### Запуск через `execute_spMstrg_2605.sh`

Новый скрипт заменяет `execute_spMstrg_2408.sh`:

```bash
cd /home/alex/projects/femsq/code/scripts
./execute_spMstrg_2605.sh
# Параметры задаются переменными внутри скрипта:
# IPGCH=15, MONTH_END_DATE="2025-07-31", IPGST="" (пустая = NULL = все стройки)
```

Скрипт выполняется через `docker exec femsq-mssql` (sqlcmd доступен только внутри контейнера).

### Ожидаемые результаты (тест: ipgCh=15, MounthEndDate='2024-08-31')

| ResultSet | Без фильтра (`@ipgSt=NULL`) | С фильтром (`@ipgSt='12ОПР'`) |
|-----------|----------------------------|-------------------------------|
| RS1 | 12 693 | 604 |
| RS2 | 12 693 | 604 |
| RS3 | 12 693 | 604 |
| RS4 | 0 | 0 |
| RS5 | 1 | 1 |
| RS6 | 0 | 0 |
| RS7 | 1 | 1 |

> RS4–RS7 показывают 0/1 для даты '2024-08-31'; при рабочей дате месяца RS4=744, RS5=32, RS6=721, RS7=32.

### Время выполнения

| Режим | Время (approx.) |
|-------|----------------|
| `@saveToTables=0, @ipgSt=NULL` | ~26 сек |
| `@saveToTables=1, @ipgSt=NULL` | ~17 сек |
| `@saveToTables=0, @ipgSt='12ОПР'` | ~6 сек |
| `@saveToTables=1, @ipgSt='12ОПР'` | ~8 сек |

### Откат к `_2408`

Если возникает необходимость вернуться к старым объектам:

```bash
# Выполнить 05_ROLLBACK.sql:
docker exec femsq-mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P '...' -d FishEye -C \
  -i docs/development/notes/sql/26-0508/05_ROLLBACK.sql
# Переключить скрипт обратно:
./execute_spMstrg_2408.sh  # старый скрипт сохранён
```

### Артефакты

| Файл | Назначение |
|------|-----------|
| `docs/development/notes/sql/26-0508/00_VERIFY_before.sql` | Проверка состояния до применения |
| `docs/development/notes/sql/26-0508/01_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2605.sql` | Создание inline TVF |
| `docs/development/notes/sql/26-0508/02_CREATE_FUNCTION_fnIpgChRsltCstUtlPercentBrn_2605.sql` | Создание multi-stmt TVF |
| `docs/development/notes/sql/26-0508/03_CREATE_PROCEDURE_spMstrg_2605.sql` | Создание процедуры |
| `docs/development/notes/sql/26-0508/04_VERIFY_after.sql` | Проверка после применения |
| `docs/development/notes/sql/26-0508/05_ROLLBACK.sql` | Откат |
| `docs/development/notes/sql/26-0508/06_DROP_obsolete_2408.sql` | Удаление устаревших `_2408` (отложено) |
| `code/scripts/execute_spMstrg_2605.sh` | Shell-скрипт для FEMSQ |
| `docs/deployment/db-upgrade-spMstrg-2605.md` | Порядок работ для продуктива |

---

---

## Стек `spMstrg_2606` (2026-06)

Параллельный стек с DAG-фильтрацией (`@ipgStKey`, `@stCostKey`) и ускоренным освоением через `factDocCost`.  
**Не заменяет** `_2605` на продуктиве до явного переключения клиентов.

### Запуск (FEMSQ / sqlcmd)

```bash
# После применения SQL-пакета 26-0604 на сервере:
docker exec femsq-mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P '...' -d FishEye -C -Q \
  "EXEC ags.spMstrg_2606 @ipgCh=5, @MounthEndDate='2022-09-30',
       @ipgStKey=NULL, @stCostKey=NULL, @saveToTables=1"
```

### Таблицы результатов

| Таблица | Назначение |
|---------|------------|
| `ags.spMstrg_2606_ResultSet1..7` | Отдельно от `*_2408_ResultSet*` (решение 8) |
| Эталон RS1 (цепь 5, dev) | **14447** строк |

### Производительность (dev, цепь 5)

| Операция | Время |
|----------|-------|
| `spMstrg_2606` saveToTables=1 | ~5 мин |
| `spMstrg_2606` saveToTables=0 | ~4 мин |

### Артефакты

| Файл | Назначение |
|------|-----------|
| `docs/development/notes/sql/26-0604/06_CREATE_PROCEDURE_spMstrg_2606.sql` | Процедура |
| `docs/development/notes/sql/26-0604/05b_CREATE_TABLE_spMstrg_2606_ResultSets.sql` | DDL ResultSet |
| `docs/development/notes/sql/26-0604/07_VERIFY_spMstrg_2606_chain5.sql` | Приёмка |
| `docs/deployment/db-upgrade-spMstrg-2606.md` | Деплой на продуктив |
| `docs/development/notes/sql/26-0604/MSSQL2012/` | Пакет SQL Server 2012 |

---

**Дата последнего обновления:** 2026-06-12
