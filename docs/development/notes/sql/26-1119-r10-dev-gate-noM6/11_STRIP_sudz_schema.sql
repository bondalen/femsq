/*
 * DEV only: удалить все объекты схемы sudz в текущей БД (ожидается FishEye_prod_noM6).
 * Имитация «прод без M6» по SURVEY: cutover-слой в sudz отсутствует.
 * ags.invDbt / ags.invDbtTmpCiaRel не трогаем. lastUpdated: 2026-11-19
 */
SET NOCOUNT ON;

IF DB_NAME() NOT IN (N'FishEye_prod_noM6')
BEGIN
    RAISERROR(N'Ожидается БД FishEye_prod_noM6 (сейчас: %s).', 16, 1, DB_NAME());
    RETURN;
END;

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'sudz')
BEGIN
    PRINT N'sudz schema отсутствует — strip не нужен.';
    RETURN;
END;

DECLARE @sql nvarchar(max);

/* 1. FK в схеме sudz */
WHILE 1 = 1
BEGIN
    SELECT TOP (1) @sql =
        N'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(fk.parent_object_id))
        + N'.' + QUOTENAME(OBJECT_NAME(fk.parent_object_id))
        + N' DROP CONSTRAINT ' + QUOTENAME(fk.name) + N';'
    FROM sys.foreign_keys AS fk
    INNER JOIN sys.schemas AS s ON s.schema_id = fk.schema_id
    WHERE s.name = N'sudz';

    IF @@ROWCOUNT = 0 BREAK;
    EXEC sys.sp_executesql @sql;
END;

/* 2. FK из других схем на таблицы sudz */
WHILE 1 = 1
BEGIN
    SELECT TOP (1) @sql =
        N'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(fk.parent_object_id))
        + N'.' + QUOTENAME(OBJECT_NAME(fk.parent_object_id))
        + N' DROP CONSTRAINT ' + QUOTENAME(fk.name) + N';'
    FROM sys.foreign_keys AS fk
    INNER JOIN sys.tables AS t ON t.object_id = fk.referenced_object_id
    INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE s.name = N'sudz';

    IF @@ROWCOUNT = 0 BREAK;
    EXEC sys.sp_executesql @sql;
END;

/* 3. Views */
WHILE 1 = 1
BEGIN
    SELECT TOP (1) @sql = N'DROP VIEW ' + QUOTENAME(s.name) + N'.' + QUOTENAME(o.name) + N';'
    FROM sys.objects AS o
    INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
    WHERE s.name = N'sudz' AND o.type = N'V';

    IF @@ROWCOUNT = 0 BREAK;
    EXEC sys.sp_executesql @sql;
END;

/* 4. Procedures / functions */
WHILE 1 = 1
BEGIN
    SELECT TOP (1) @sql =
        CASE o.type
            WHEN N'P'  THEN N'DROP PROCEDURE '
            WHEN N'FN' THEN N'DROP FUNCTION '
            WHEN N'IF' THEN N'DROP FUNCTION '
            WHEN N'TF' THEN N'DROP FUNCTION '
            ELSE N'DROP PROCEDURE '
        END + QUOTENAME(s.name) + N'.' + QUOTENAME(o.name) + N';'
    FROM sys.objects AS o
    INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
    WHERE s.name = N'sudz' AND o.type IN (N'P', N'FN', N'IF', N'TF');

    IF @@ROWCOUNT = 0 BREAK;
    EXEC sys.sp_executesql @sql;
END;

/* 5. Tables (triggers drop with table) */
WHILE 1 = 1
BEGIN
    SELECT TOP (1) @sql = N'DROP TABLE ' + QUOTENAME(s.name) + N'.' + QUOTENAME(o.name) + N';'
    FROM sys.objects AS o
    INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
    WHERE s.name = N'sudz' AND o.type = N'U';

    IF @@ROWCOUNT = 0 BREAK;
    EXEC sys.sp_executesql @sql;
END;

/* 6. Пустая схема */
IF NOT EXISTS (
    SELECT 1
    FROM sys.objects AS o
    INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
    WHERE s.name = N'sudz' AND o.is_ms_shipped = 0
)
BEGIN
    DROP SCHEMA sudz;
    PRINT N'sudz schema dropped.';
END
ELSE
BEGIN
    SELECT N'remaining' AS section, o.type_desc, o.name
    FROM sys.objects AS o
    INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
    WHERE s.name = N'sudz' AND o.is_ms_shipped = 0
    ORDER BY o.type_desc, o.name;
    RAISERROR(N'В sudz остались объекты — см. сетку remaining.', 16, 1);
END;
