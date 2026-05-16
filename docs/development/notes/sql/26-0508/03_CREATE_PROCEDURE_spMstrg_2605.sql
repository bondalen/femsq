/*
=============================================================================
Файл:    03_CREATE_PROCEDURE_spMstrg_2605.sql
Объект:  ags.spMstrg_2605
Дата:    2026-05-16
Этап:    3 из 4  (chat-plan-26-0508-spMstrg-2605)
=============================================================================
НАЗНАЧЕНИЕ:
  Объединённая версия spMstrg_2408 + spMstrg_2408_SaveToTables.
  @ipgSt nvarchar(255) = NULL  — фильтр по стройке (NULL = все стройки)
  @saveToTables bit = 0        — 0=SELECT (Access), 1=TRUNCATE+INSERT (FEMSQ)
ЗАВИСИМОСТИ:
  ags.fnIpgChRsltCstUtlPercentBrn_2605(@ipgCh, @ipgSt)
ROLLBACK: 05_ROLLBACK.sql → DROP PROCEDURE IF EXISTS [ags].[spMstrg_2605]
=============================================================================*/
SET NOCOUNT ON;
PRINT '=== 03: Создание ags.spMstrg_2605 ===';

DECLARE @sql  nvarchar(max);
DECLARE @i    int, @j int, @k int;
DECLARE @sel  nvarchar(max);

-- Шаг A: получить исходный текст
SET @sql = OBJECT_DEFINITION(OBJECT_ID('ags.spMstrg_2408_SaveToTables'));
IF @sql IS NULL
BEGIN
    RAISERROR('OBJECT_DEFINITION вернул NULL для spMstrg_2408_SaveToTables', 16, 1);
    RETURN;
END;
PRINT 'Длина исходного текста: ' + CAST(LEN(@sql) AS nvarchar(20));

-- Шаг B: основные замены

-- B1: имя процедуры
SET @sql = REPLACE(@sql,
    'CREATE PROCEDURE ags.spMstrg_2408_SaveToTables',
    'CREATE OR ALTER PROCEDURE ags.spMstrg_2605');

-- B2: параметры — пробуем оба варианта окончания строки (CRLF и LF)
IF CHARINDEX('@MounthEndDate date' + CHAR(13)+CHAR(10)+'AS', @sql) > 0
    SET @sql = REPLACE(@sql,
        '@MounthEndDate date' + CHAR(13)+CHAR(10)+'AS',
        '@MounthEndDate date,' + CHAR(13)+CHAR(10)
        + '    @ipgSt         nvarchar(255) = NULL,' + CHAR(13)+CHAR(10)
        + '    @saveToTables  bit           = 0      -- 0=SELECT(Access), 1=INSERT(FEMSQ)' + CHAR(13)+CHAR(10)
        + 'AS');
ELSE
    SET @sql = REPLACE(@sql,
        '@MounthEndDate date' + CHAR(10)+'AS',
        '@MounthEndDate date,' + CHAR(10)
        + '    @ipgSt         nvarchar(255) = NULL,' + CHAR(10)
        + '    @saveToTables  bit           = 0      -- 0=SELECT(Access), 1=INSERT(FEMSQ)' + CHAR(10)
        + 'AS');

-- B3: вызов функции
SET @sql = REPLACE(@sql,
    'fnIpgChRsltCstUtlPercentBrn_2408(@ipgCh)',
    'fnIpgChRsltCstUtlPercentBrn_2605(@ipgCh, @ipgSt)');

PRINT 'Замены B1-B3 выполнены. Длина: ' + CAST(LEN(@sql) AS nvarchar(20));
PRINT 'Проверка @ipgSt: ' + CAST(CHARINDEX('@ipgSt', @sql) AS nvarchar(20));
PRINT 'Проверка fn_2605: ' + CAST(CHARINDEX('fnIpgChRsltCstUtlPercentBrn_2605', @sql) AS nvarchar(20));

-- Шаг C: обернуть TRUNCATE блок в IF @saveToTables = 1
DECLARE @tStart int, @tEnd int;
SET @tStart = CHARINDEX('TRUNCATE TABLE ags.spMstrg_2408_ResultSet1', @sql);
SET @tEnd   = CHARINDEX(';', @sql,
              CHARINDEX('TRUNCATE TABLE ags.spMstrg_2408_ResultSet7', @sql));
-- Сначала вставляем END после последнего TRUNCATE (правый конец)
SET @sql = STUFF(@sql, @tEnd + 1, 0,
    CHAR(10) + '    END  -- IF @saveToTables = 1 (TRUNCATE)');
-- Потом вставляем BEGIN перед первым TRUNCATE (левый конец, позиция не сдвинулась)
SET @sql = STUFF(@sql, @tStart, 0,
    'IF @saveToTables = 1' + CHAR(10) + '    BEGIN' + CHAR(10) + '        ');
PRINT 'Шаг C (TRUNCATE): ' + CAST(CHARINDEX('IF @saveToTables = 1', @sql) AS nvarchar(20));

-- Шаг D: обернуть каждый INSERT INTO в IF @saveToTables = 1 BEGIN...END ELSE BEGIN...END
-- Обрабатываем от RS7 до RS1 (справа налево, чтобы позиции не сдвигались)

-- D7: RS7
SET @i = CHARINDEX('INSERT INTO ags.spMstrg_2408_ResultSet7', @sql);
SET @j = CHARINDEX('SELECT', @sql, @i);   -- начало SELECT (минуя возможный column list)
SET @k = CHARINDEX(';', @sql, @j);        -- конец INSERT...SELECT блока
SET @sel = SUBSTRING(@sql, @j, @k - @j + 1);  -- тело SELECT (включая ';')
-- Вставляем ELSE BEGIN SELECT; END сразу после ';'
SET @sql = STUFF(@sql, @k + 1, 0,
    CHAR(10) + '    END' + CHAR(10)
    + '    ELSE BEGIN' + CHAR(10) + '        '
    + @sel
    + CHAR(10) + '    END');
-- Вставляем IF @saveToTables = 1 BEGIN перед INSERT
SET @i = CHARINDEX('INSERT INTO ags.spMstrg_2408_ResultSet7', @sql);
SET @sql = STUFF(@sql, @i, 0,
    'IF @saveToTables = 1 BEGIN' + CHAR(10) + '        ');
PRINT 'RS7 обёрнут';

-- D6: RS6
SET @i = CHARINDEX('INSERT INTO ags.spMstrg_2408_ResultSet6', @sql);
SET @j = CHARINDEX('SELECT', @sql, @i);   -- начало SELECT (минуя возможный column list)
SET @k = CHARINDEX(';', @sql, @j);        -- конец INSERT...SELECT блока
SET @sel = SUBSTRING(@sql, @j, @k - @j + 1);  -- тело SELECT (включая ';')
-- Вставляем ELSE BEGIN SELECT; END сразу после ';'
SET @sql = STUFF(@sql, @k + 1, 0,
    CHAR(10) + '    END' + CHAR(10)
    + '    ELSE BEGIN' + CHAR(10) + '        '
    + @sel
    + CHAR(10) + '    END');
-- Вставляем IF @saveToTables = 1 BEGIN перед INSERT
SET @i = CHARINDEX('INSERT INTO ags.spMstrg_2408_ResultSet6', @sql);
SET @sql = STUFF(@sql, @i, 0,
    'IF @saveToTables = 1 BEGIN' + CHAR(10) + '        ');
PRINT 'RS6 обёрнут';

-- D5: RS5
SET @i = CHARINDEX('INSERT INTO ags.spMstrg_2408_ResultSet5', @sql);
SET @j = CHARINDEX('SELECT', @sql, @i);   -- начало SELECT (минуя возможный column list)
SET @k = CHARINDEX(';', @sql, @j);        -- конец INSERT...SELECT блока
SET @sel = SUBSTRING(@sql, @j, @k - @j + 1);  -- тело SELECT (включая ';')
-- Вставляем ELSE BEGIN SELECT; END сразу после ';'
SET @sql = STUFF(@sql, @k + 1, 0,
    CHAR(10) + '    END' + CHAR(10)
    + '    ELSE BEGIN' + CHAR(10) + '        '
    + @sel
    + CHAR(10) + '    END');
-- Вставляем IF @saveToTables = 1 BEGIN перед INSERT
SET @i = CHARINDEX('INSERT INTO ags.spMstrg_2408_ResultSet5', @sql);
SET @sql = STUFF(@sql, @i, 0,
    'IF @saveToTables = 1 BEGIN' + CHAR(10) + '        ');
PRINT 'RS5 обёрнут';

-- D4: RS4
SET @i = CHARINDEX('INSERT INTO ags.spMstrg_2408_ResultSet4', @sql);
SET @j = CHARINDEX('SELECT', @sql, @i);   -- начало SELECT (минуя возможный column list)
SET @k = CHARINDEX(';', @sql, @j);        -- конец INSERT...SELECT блока
SET @sel = SUBSTRING(@sql, @j, @k - @j + 1);  -- тело SELECT (включая ';')
-- Вставляем ELSE BEGIN SELECT; END сразу после ';'
SET @sql = STUFF(@sql, @k + 1, 0,
    CHAR(10) + '    END' + CHAR(10)
    + '    ELSE BEGIN' + CHAR(10) + '        '
    + @sel
    + CHAR(10) + '    END');
-- Вставляем IF @saveToTables = 1 BEGIN перед INSERT
SET @i = CHARINDEX('INSERT INTO ags.spMstrg_2408_ResultSet4', @sql);
SET @sql = STUFF(@sql, @i, 0,
    'IF @saveToTables = 1 BEGIN' + CHAR(10) + '        ');
PRINT 'RS4 обёрнут';

-- D3: RS3
SET @i = CHARINDEX('INSERT INTO ags.spMstrg_2408_ResultSet3', @sql);
SET @j = CHARINDEX('SELECT', @sql, @i);   -- начало SELECT (минуя возможный column list)
SET @k = CHARINDEX(';', @sql, @j);        -- конец INSERT...SELECT блока
SET @sel = SUBSTRING(@sql, @j, @k - @j + 1);  -- тело SELECT (включая ';')
-- Вставляем ELSE BEGIN SELECT; END сразу после ';'
SET @sql = STUFF(@sql, @k + 1, 0,
    CHAR(10) + '    END' + CHAR(10)
    + '    ELSE BEGIN' + CHAR(10) + '        '
    + @sel
    + CHAR(10) + '    END');
-- Вставляем IF @saveToTables = 1 BEGIN перед INSERT
SET @i = CHARINDEX('INSERT INTO ags.spMstrg_2408_ResultSet3', @sql);
SET @sql = STUFF(@sql, @i, 0,
    'IF @saveToTables = 1 BEGIN' + CHAR(10) + '        ');
PRINT 'RS3 обёрнут';

-- D2: RS2
SET @i = CHARINDEX('INSERT INTO ags.spMstrg_2408_ResultSet2', @sql);
SET @j = CHARINDEX('SELECT', @sql, @i);   -- начало SELECT (минуя возможный column list)
SET @k = CHARINDEX(';', @sql, @j);        -- конец INSERT...SELECT блока
SET @sel = SUBSTRING(@sql, @j, @k - @j + 1);  -- тело SELECT (включая ';')
-- Вставляем ELSE BEGIN SELECT; END сразу после ';'
SET @sql = STUFF(@sql, @k + 1, 0,
    CHAR(10) + '    END' + CHAR(10)
    + '    ELSE BEGIN' + CHAR(10) + '        '
    + @sel
    + CHAR(10) + '    END');
-- Вставляем IF @saveToTables = 1 BEGIN перед INSERT
SET @i = CHARINDEX('INSERT INTO ags.spMstrg_2408_ResultSet2', @sql);
SET @sql = STUFF(@sql, @i, 0,
    'IF @saveToTables = 1 BEGIN' + CHAR(10) + '        ');
PRINT 'RS2 обёрнут';

-- D1: RS1
SET @i = CHARINDEX('INSERT INTO ags.spMstrg_2408_ResultSet1', @sql);
SET @j = CHARINDEX('SELECT', @sql, @i);   -- начало SELECT (минуя возможный column list)
SET @k = CHARINDEX(';', @sql, @j);        -- конец INSERT...SELECT блока
SET @sel = SUBSTRING(@sql, @j, @k - @j + 1);  -- тело SELECT (включая ';')
-- Вставляем ELSE BEGIN SELECT; END сразу после ';'
SET @sql = STUFF(@sql, @k + 1, 0,
    CHAR(10) + '    END' + CHAR(10)
    + '    ELSE BEGIN' + CHAR(10) + '        '
    + @sel
    + CHAR(10) + '    END');
-- Вставляем IF @saveToTables = 1 BEGIN перед INSERT
SET @i = CHARINDEX('INSERT INTO ags.spMstrg_2408_ResultSet1', @sql);
SET @sql = STUFF(@sql, @i, 0,
    'IF @saveToTables = 1 BEGIN' + CHAR(10) + '        ');
PRINT 'RS1 обёрнут';

-- Шаг E: выполнить
PRINT 'Итоговая длина SQL: ' + CAST(LEN(@sql) AS nvarchar(20));
PRINT 'Применяем CREATE OR ALTER PROCEDURE ags.spMstrg_2605...';
EXEC sp_executesql @sql;
PRINT 'ags.spMstrg_2605 создана успешно!';
