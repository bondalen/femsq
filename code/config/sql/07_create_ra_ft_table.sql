USE [FishEye];
GO

-- =============================================
-- Скрипт создания справочника типов файлов ra_ft
-- Дата: 2026-01-15
-- Цель: Создать lookup-справочник для ra_f.af_type
-- =============================================

PRINT 'Создание таблицы ags.ra_ft...';
GO

-- Проверка и удаление существующей таблицы
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES 
           WHERE TABLE_SCHEMA = 'ags' AND TABLE_NAME = 'ra_ft')
BEGIN
    PRINT '  Таблица ags.ra_ft уже существует, удаление...';
    DROP TABLE ags.ra_ft;
END;
GO

-- Создание таблицы
CREATE TABLE ags.ra_ft (
    ft_key INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    ft_name NVARCHAR(255) NOT NULL
);
GO

-- Создание индекса для быстрого поиска по имени
CREATE NONCLUSTERED INDEX IX_ra_ft_name ON ags.ra_ft(ft_name);
GO

-- Добавление комментариев
EXEC sys.sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Справочник типов файлов для проверки (lookup для ra_f.af_type)', 
    @level0type = N'SCHEMA', @level0name = 'ags',
    @level1type = N'TABLE',  @level1name = 'ra_ft';
GO

EXEC sys.sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Идентификатор типа файла (PRIMARY KEY)', 
    @level0type = N'SCHEMA', @level0name = 'ags',
    @level1type = N'TABLE',  @level1name = 'ra_ft',
    @level2type = N'COLUMN', @level2name = 'ft_key';
GO

EXEC sys.sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Название типа файла (отображается в UI как lookup)', 
    @level0type = N'SCHEMA', @level0name = 'ags',
    @level1type = N'TABLE',  @level1name = 'ra_ft',
    @level2type = N'COLUMN', @level2name = 'ft_name';
GO

PRINT 'Таблица ags.ra_ft успешно создана.';
GO

-- =============================================
-- Импорт данных из MS Access
-- =============================================

PRINT 'Импорт данных в ags.ra_ft...';
GO

SET IDENTITY_INSERT ags.ra_ft ON;
GO

INSERT INTO ags.ra_ft (ft_key, ft_name) VALUES
    (1, N'отчёты агента'),
    (2, N'хранение оборудования и стройконтроль'),
    (3, N'аренда земли'),
    (4, N'агентское вознаграждение'),
    (5, N'отчёты всех агентов'),
    (6, N'23-0627_агентское вознаграждение');
GO

SET IDENTITY_INSERT ags.ra_ft OFF;
GO

PRINT 'Импортировано записей: 6';
GO

-- Проверка импорта
SELECT COUNT(*) AS total_records FROM ags.ra_ft;
SELECT * FROM ags.ra_ft ORDER BY ft_key;
GO

-- =============================================
-- Добавление Foreign Key constraints
-- =============================================

PRINT 'Добавление FK constraints...';
GO

-- FK: ra_f.af_type → ra_ft.ft_key
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ra_f_type')
BEGIN
    PRINT '  Создание FK_ra_f_type...';
    ALTER TABLE ags.ra_f 
        ADD CONSTRAINT FK_ra_f_type 
        FOREIGN KEY (af_type) REFERENCES ags.ra_ft(ft_key);
    
    PRINT '  Создание индекса IX_ra_f_type...';
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ra_f_type' AND object_id = OBJECT_ID('ags.ra_f'))
        CREATE NONCLUSTERED INDEX IX_ra_f_type ON ags.ra_f(af_type);
END
ELSE
    PRINT '  FK_ra_f_type уже существует';
GO

-- FK: ra_f.ra_org_sender → og.ogKey
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ra_f_org_sender')
BEGIN
    PRINT '  Создание FK_ra_f_org_sender...';
    ALTER TABLE ags.ra_f 
        ADD CONSTRAINT FK_ra_f_org_sender 
        FOREIGN KEY (ra_org_sender) REFERENCES ags.og(ogKey);
    
    -- Индекс уже создан ранее (IX_ra_f_org_sender)
    PRINT '  FK_ra_f_org_sender создан';
END
ELSE
    PRINT '  FK_ra_f_org_sender уже существует';
GO

-- Проверка FK constraints
PRINT '';
PRINT 'Проверка FK constraints:';
SELECT 
    fk.name AS constraint_name,
    OBJECT_NAME(fk.parent_object_id) AS table_name,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS column_name,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS referenced_column
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE fk.parent_object_id = OBJECT_ID('ags.ra_f')
  AND fk.name IN ('FK_ra_f_type', 'FK_ra_f_org_sender')
ORDER BY fk.name;
GO

-- =============================================
-- Проверка целостности данных
-- =============================================

PRINT '';
PRINT 'Проверка целостности данных...';
GO

-- Проверка всех значений af_type в ra_f существуют в ra_ft
DECLARE @invalid_types INT;
SELECT @invalid_types = COUNT(*)
FROM ags.ra_f f
LEFT JOIN ags.ra_ft ft ON f.af_type = ft.ft_key
WHERE ft.ft_key IS NULL;

IF @invalid_types > 0
    PRINT '  ВНИМАНИЕ: Найдено ' + CAST(@invalid_types AS VARCHAR) + ' записей с некорректным af_type!';
ELSE
    PRINT '  ✓ Все значения af_type корректны';
GO

-- Проверка значений ra_org_sender
DECLARE @invalid_orgs INT;
SELECT @invalid_orgs = COUNT(*)
FROM ags.ra_f f
LEFT JOIN ags.og o ON f.ra_org_sender = o.ogKey
WHERE f.ra_org_sender IS NOT NULL AND o.ogKey IS NULL;

IF @invalid_orgs > 0
    PRINT '  ВНИМАНИЕ: Найдено ' + CAST(@invalid_orgs AS VARCHAR) + ' записей с некорректным ra_org_sender!';
ELSE
    PRINT '  ✓ Все значения ra_org_sender корректны';
GO

-- Статистика использования типов файлов
PRINT '';
PRINT 'Статистика использования типов файлов:';
SELECT 
    ft.ft_key,
    ft.ft_name,
    COUNT(f.af_key) AS files_count
FROM ags.ra_ft ft
LEFT JOIN ags.ra_f f ON ft.ft_key = f.af_type
GROUP BY ft.ft_key, ft.ft_name
ORDER BY ft.ft_key;
GO

PRINT '';
PRINT '========================================';
PRINT 'Справочник ra_ft успешно создан!';
PRINT 'Импортировано: 6 типов файлов';
PRINT 'FK constraints добавлены';
PRINT '========================================';
GO
