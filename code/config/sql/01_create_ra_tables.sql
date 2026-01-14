-- ============================================================================
-- Создание таблиц для системы ревизий (Audit Tables)
-- ============================================================================
-- Дата создания: 2026-01-12
-- Автор: Александр
-- Описание: DDL скрипты для создания таблиц ra_at, ra_dir, ra_a в схеме ags
-- ============================================================================

USE [femsq];
GO

-- ============================================================================
-- 1. Таблица: ags.ra_at (Типы ревизий / Audit Types)
-- ============================================================================
-- Описание: Справочник типов ревизий
-- Связи: Родительская для ags.ra_a (adt_type → at_key)
-- ============================================================================

IF OBJECT_ID('ags.ra_at', 'U') IS NOT NULL
    DROP TABLE ags.ra_at;
GO

CREATE TABLE ags.ra_at (
    at_key INT PRIMARY KEY IDENTITY(1,1),                -- Первичный ключ
    at_name NVARCHAR(255) NOT NULL,                      -- Название типа ревизии
    at_created DATETIME2 DEFAULT GETDATE(),              -- Дата создания записи
    at_updated DATETIME2 DEFAULT GETDATE()               -- Дата последнего обновления
);
GO

-- Индексы для ags.ra_at
CREATE UNIQUE NONCLUSTERED INDEX IX_ra_at_name 
    ON ags.ra_at(at_name);
GO

-- ============================================================================
-- 2. Таблица: ags.ra_dir (Директории для ревизий / Audit Directories)
-- ============================================================================
-- Описание: Справочник директорий с Excel-файлами для ревизий
-- Связи: Родительская для ags.ra_a (adt_dir → key)
-- ============================================================================

IF OBJECT_ID('ags.ra_dir', 'U') IS NOT NULL
    DROP TABLE ags.ra_dir;
GO

CREATE TABLE ags.ra_dir (
    [key] INT PRIMARY KEY IDENTITY(1,1),                 -- Первичный ключ
    dir_name NVARCHAR(255) NOT NULL,                     -- Название директории
    dir NVARCHAR(500) NOT NULL,                          -- Путь к директории
    dir_created DATETIME2 DEFAULT GETDATE(),             -- Дата создания записи
    dir_updated DATETIME2 DEFAULT GETDATE()              -- Дата последнего обновления
);
GO

-- Индексы для ags.ra_dir
CREATE NONCLUSTERED INDEX IX_ra_dir_name 
    ON ags.ra_dir(dir_name);
GO

-- ============================================================================
-- 3. Таблица: ags.ra_a (Ревизии / Audits)
-- ============================================================================
-- Описание: Основная таблица ревизий Excel-отчётов
-- Связи: 
--   - FK к ags.ra_at (adt_type → at_key)
--   - FK к ags.ra_dir (adt_dir → key)
-- ============================================================================

IF OBJECT_ID('ags.ra_a', 'U') IS NOT NULL
    DROP TABLE ags.ra_a;
GO

CREATE TABLE ags.ra_a (
    adt_key BIGINT PRIMARY KEY IDENTITY(1,1),            -- Первичный ключ
    adt_name NVARCHAR(255) NOT NULL,                     -- Название ревизии
    adt_date DATETIME,                                   -- Дата и время выполнения ревизии
    adt_results NVARCHAR(MAX),                           -- HTML-результаты ревизии
    adt_dir INT NOT NULL,                                -- FK → ags.ra_dir.key
    adt_type INT NOT NULL,                               -- FK → ags.ra_at.at_key
    adt_AddRA BIT NOT NULL DEFAULT 0,                    -- Флаг автодобавления
    adt_created DATETIME2 DEFAULT GETDATE(),             -- Дата создания записи
    adt_updated DATETIME2 DEFAULT GETDATE(),             -- Дата последнего обновления
    
    -- Foreign Key constraints
    CONSTRAINT FK_ra_a_dir FOREIGN KEY (adt_dir) 
        REFERENCES ags.ra_dir([key]),
    
    CONSTRAINT FK_ra_a_type FOREIGN KEY (adt_type) 
        REFERENCES ags.ra_at(at_key)
);
GO

-- Индексы для ags.ra_a
CREATE NONCLUSTERED INDEX IX_ra_a_name 
    ON ags.ra_a(adt_name);

CREATE NONCLUSTERED INDEX IX_ra_a_date 
    ON ags.ra_a(adt_date DESC);

CREATE NONCLUSTERED INDEX IX_ra_a_dir 
    ON ags.ra_a(adt_dir);

CREATE NONCLUSTERED INDEX IX_ra_a_type 
    ON ags.ra_a(adt_type);
GO

-- ============================================================================
-- Комментарии к таблицам (Extended Properties)
-- ============================================================================

-- Таблица ra_at
EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Справочник типов ревизий Excel-отчётов', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_at';

-- Таблица ra_dir
EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Справочник директорий с Excel-файлами для ревизий', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_dir';

-- Таблица ra_a
EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Основная таблица ревизий Excel-отчётов агентов', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_a';
GO

PRINT 'Таблицы для системы ревизий успешно созданы!';
GO
