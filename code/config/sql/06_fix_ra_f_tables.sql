USE [FishEye];
GO

-- =============================================
-- Скрипт исправления таблиц ra_f, ra_ft_s
-- Дата: 2026-01-15
-- Цель: Привести структуру к оригинальной из MS Access
-- =============================================

PRINT 'Начало исправления таблиц ra_f и ra_ft_s...';
GO

-- =============================================
-- 1. Исправление таблицы ags.ra_f
-- =============================================

PRINT 'Исправление таблицы ags.ra_f...';
GO

-- 1.1 Удаляем лишние поля, которых нет в Access
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
           WHERE TABLE_SCHEMA = 'ags' AND TABLE_NAME = 'ra_f' AND COLUMN_NAME = 'af_is_source')
BEGIN
    PRINT '  Удаление поля af_is_source...';
    ALTER TABLE ags.ra_f DROP COLUMN af_is_source;
END;
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
           WHERE TABLE_SCHEMA = 'ags' AND TABLE_NAME = 'ra_f' AND COLUMN_NAME = 'af_is_done')
BEGIN
    PRINT '  Удаление поля af_is_done...';
    ALTER TABLE ags.ra_f DROP COLUMN af_is_done;
END;
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
           WHERE TABLE_SCHEMA = 'ags' AND TABLE_NAME = 'ra_f' AND COLUMN_NAME = 'af_adt_key')
BEGIN
    PRINT '  Удаление FK на af_adt_key...';
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ra_f_adt')
        ALTER TABLE ags.ra_f DROP CONSTRAINT FK_ra_f_adt;
    
    PRINT '  Удаление индекса на af_adt_key...';
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ra_f_adt_key')
        DROP INDEX IX_ra_f_adt_key ON ags.ra_f;
    
    PRINT '  Удаление поля af_adt_key...';
    ALTER TABLE ags.ra_f DROP COLUMN af_adt_key;
END;
GO

-- 1.2 Изменяем тип поля af_source с INT на BIT
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
           WHERE TABLE_SCHEMA = 'ags' AND TABLE_NAME = 'ra_f' AND COLUMN_NAME = 'af_source' AND DATA_TYPE = 'int')
BEGIN
    PRINT '  Изменение типа af_source с INT на BIT...';
    -- Сначала обновляем данные (0 или NULL остаются 0, всё остальное становится 1)
    UPDATE ags.ra_f SET af_source = CASE WHEN ISNULL(af_source, 0) = 0 THEN 0 ELSE 1 END;
    -- Изменяем тип
    ALTER TABLE ags.ra_f ALTER COLUMN af_source BIT NULL;
END;
GO

-- 1.3 Добавляем недостающие поля
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_SCHEMA = 'ags' AND TABLE_NAME = 'ra_f' AND COLUMN_NAME = 'af_num')
BEGIN
    PRINT '  Добавление поля af_num...';
    ALTER TABLE ags.ra_f ADD af_num INT NULL;
    
    -- Инициализируем значения (номер по порядку для каждой директории)
    WITH CTE AS (
        SELECT af_key, ROW_NUMBER() OVER (PARTITION BY af_dir ORDER BY af_key) AS rn
        FROM ags.ra_f
    )
    UPDATE ags.ra_f 
    SET af_num = CTE.rn
    FROM ags.ra_f f
    INNER JOIN CTE ON f.af_key = CTE.af_key;
    
    PRINT '  Создание индекса на af_num...';
    CREATE NONCLUSTERED INDEX IX_ra_f_num ON ags.ra_f(af_num);
END;
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_SCHEMA = 'ags' AND TABLE_NAME = 'ra_f' AND COLUMN_NAME = 'ra_org_sender')
BEGIN
    PRINT '  Добавление поля ra_org_sender...';
    ALTER TABLE ags.ra_f ADD ra_org_sender INT NULL;
    
    PRINT '  Создание индекса на ra_org_sender...';
    CREATE NONCLUSTERED INDEX IX_ra_f_org_sender ON ags.ra_f(ra_org_sender);
    
    -- Комментарий для поля
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Идентификатор организации-отправителя (FK → таблица организаций)', 
        @level0type = N'SCHEMA', @level0name = 'ags',
        @level1type = N'TABLE',  @level1name = 'ra_f',
        @level2type = N'COLUMN', @level2name = 'ra_org_sender';
END;
GO

-- 1.4 Добавляем комментарий для af_num
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties 
               WHERE major_id = OBJECT_ID('ags.ra_f') 
               AND minor_id = (SELECT column_id FROM sys.columns 
                               WHERE object_id = OBJECT_ID('ags.ra_f') AND name = 'af_num')
               AND name = 'MS_Description')
BEGIN
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Номер файла по порядку (для отображения и сортировки)', 
        @level0type = N'SCHEMA', @level0name = 'ags',
        @level1type = N'TABLE',  @level1name = 'ra_f',
        @level2type = N'COLUMN', @level2name = 'af_num';
END;
GO

-- =============================================
-- 2. Исправление таблицы ags.ra_ft_s
-- =============================================

PRINT 'Исправление таблицы ags.ra_ft_s...';
GO

-- 2.1 Добавляем недостающее поле ft_s_period
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_SCHEMA = 'ags' AND TABLE_NAME = 'ra_ft_s' AND COLUMN_NAME = 'ft_s_period')
BEGIN
    PRINT '  Добавление поля ft_s_period...';
    ALTER TABLE ags.ra_ft_s ADD ft_s_period NVARCHAR(50) NULL;
    
    PRINT '  Создание индекса на ft_s_period...';
    CREATE NONCLUSTERED INDEX IX_ra_ft_s_period ON ags.ra_ft_s(ft_s_period);
    
    -- Комментарий для поля
    EXEC sys.sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'Период для источника данных (используется для определения временного интервала)', 
        @level0type = N'SCHEMA', @level0name = 'ags',
        @level1type = N'TABLE',  @level1name = 'ra_ft_s',
        @level2type = N'COLUMN', @level2name = 'ft_s_period';
END;
GO

-- =============================================
-- 3. Проверка результатов
-- =============================================

PRINT '';
PRINT 'Проверка структуры таблиц после исправления:';
PRINT '';

PRINT 'Таблица ags.ra_f:';
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ags' AND TABLE_NAME = 'ra_f'
ORDER BY ORDINAL_POSITION;
GO

PRINT '';
PRINT 'Таблица ags.ra_ft_s:';
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ags' AND TABLE_NAME = 'ra_ft_s'
ORDER BY ORDINAL_POSITION;
GO

PRINT '';
PRINT 'Исправление таблиц завершено успешно!';
GO
