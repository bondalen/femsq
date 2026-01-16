-- ============================================================================
-- Создание таблиц для файлов ревизий (Audit Files Tables)
-- ============================================================================
-- Дата создания: 2026-01-15
-- Автор: Александр
-- Описание: DDL скрипты для создания таблицы ra_f (файлы для проверки) и справочных таблиц типов файлов в схеме ags
-- ============================================================================

USE [FishEye];
GO

-- ============================================================================
-- 1. Таблица: ags.ra_f (Файлы для проверки / Audit Files)
-- ============================================================================
-- Описание: Список файлов Excel, которые должны быть проверены в рамках ревизии
-- Связи: 
--   - FK к ags.ra_dir (af_dir → key)
--   - FK к ags.ra_a (af_adt_key → adt_key) - явная связь с ревизией
-- ============================================================================

IF OBJECT_ID('ags.ra_f', 'U') IS NOT NULL
    DROP TABLE ags.ra_f;
GO

CREATE TABLE ags.ra_f (
    af_key BIGINT PRIMARY KEY IDENTITY(1,1),            -- Первичный ключ
    af_name NVARCHAR(255) NOT NULL,                     -- Имя файла (например, "report.xlsx")
    af_dir INT NOT NULL,                                -- FK → ags.ra_dir.key (директория для проверки)
    af_type INT NOT NULL,                               -- Тип файла (1-6: отчёт агента, хранение, аренда земли, инвестиции и т.д.)
    af_execute BIT NOT NULL DEFAULT 1,                  -- Флаг: подлежит ли файл рассмотрению/выполнению
    af_source INT NULL,                                 -- Источник данных (используется при обработке)
    af_adt_key BIGINT NULL,                             -- FK → ags.ra_a.adt_key (явная связь с ревизией)
    af_is_done BIT NOT NULL DEFAULT 0,                  -- Флаг: выполнена ли проверка файла
    af_is_source BIT NOT NULL DEFAULT 0,                 -- Флаг: является ли файл источником данных
    af_created DATETIME2 DEFAULT GETDATE(),             -- Дата создания записи
    af_updated DATETIME2 DEFAULT GETDATE(),             -- Дата последнего обновления
    
    -- Foreign Key constraints
    CONSTRAINT FK_ra_f_dir FOREIGN KEY (af_dir) 
        REFERENCES ags.ra_dir([key]),
    
    CONSTRAINT FK_ra_f_adt FOREIGN KEY (af_adt_key) 
        REFERENCES ags.ra_a(adt_key)
);
GO

-- Индексы для ags.ra_f
-- Индекс по директории (для фильтрации файлов по директории)
CREATE NONCLUSTERED INDEX IX_ra_f_dir 
    ON ags.ra_f(af_dir);

-- Индекс по типу файла (для фильтрации по типу)
CREATE NONCLUSTERED INDEX IX_ra_f_type 
    ON ags.ra_f(af_type);

-- Индекс по ревизии (для быстрого поиска файлов конкретной ревизии)
CREATE NONCLUSTERED INDEX IX_ra_f_adt_key 
    ON ags.ra_f(af_adt_key)
    WHERE af_adt_key IS NOT NULL;

-- Индекс по флагу выполнения (для фильтрации активных файлов)
CREATE NONCLUSTERED INDEX IX_ra_f_execute 
    ON ags.ra_f(af_execute)
    WHERE af_execute = 1;

-- Индекс по имени файла (для поиска по имени)
CREATE NONCLUSTERED INDEX IX_ra_f_name 
    ON ags.ra_f(af_name);

-- Составной индекс для частых запросов: директория + тип + выполнение
CREATE NONCLUSTERED INDEX IX_ra_f_dir_type_execute 
    ON ags.ra_f(af_dir, af_type, af_execute)
    WHERE af_execute = 1;
GO

-- ============================================================================
-- 2. Таблица: ags.ra_ft_st (Типы источников / File Type Source Types)
-- ============================================================================
-- Описание: Справочник типов источников данных для файлов
-- Связи: Родительская для ags.ra_ft_s (ft_s_sheet_type → st_key)
-- ============================================================================

IF OBJECT_ID('ags.ra_ft_st', 'U') IS NOT NULL
    DROP TABLE ags.ra_ft_st;
GO

CREATE TABLE ags.ra_ft_st (
    st_key INT PRIMARY KEY IDENTITY(1,1),                -- Первичный ключ
    st_name NVARCHAR(255) NOT NULL,                     -- Название типа источника
    st_created DATETIME2 DEFAULT GETDATE(),             -- Дата создания записи
    st_updated DATETIME2 DEFAULT GETDATE()              -- Дата последнего обновления
);
GO

-- Индексы для ags.ra_ft_st
CREATE UNIQUE NONCLUSTERED INDEX IX_ra_ft_st_name 
    ON ags.ra_ft_st(st_name);
GO

-- ============================================================================
-- 3. Таблица: ags.ra_ft_s (Источники / листы / File Type Sources)
-- ============================================================================
-- Описание: Справочник источников данных (листов Excel) для типов файлов
-- Связи: 
--   - FK к ags.ra_ft_st (ft_s_sheet_type → st_key)
--   - Связь по значению с ags.ra_f (ft_s_type соответствует af_type)
--   - Родительская для ags.ra_ft_sn (ftsn_ft_s → ft_s_key)
-- ============================================================================

IF OBJECT_ID('ags.ra_ft_s', 'U') IS NOT NULL
    DROP TABLE ags.ra_ft_s;
GO

CREATE TABLE ags.ra_ft_s (
    ft_s_key INT PRIMARY KEY IDENTITY(1,1),             -- Первичный ключ
    ft_s_type INT NOT NULL,                             -- Тип файла (соответствует ra_f.af_type: 1-6)
    ft_s_num INT NOT NULL,                              -- Номер источника/листа (для сортировки и определения порядка обработки)
    ft_s_sheet_type INT NOT NULL,                       -- FK → ags.ra_ft_st.st_key (тип источника)
    ft_s_created DATETIME2 DEFAULT GETDATE(),           -- Дата создания записи
    ft_s_updated DATETIME2 DEFAULT GETDATE(),           -- Дата последнего обновления
    
    -- Foreign Key constraints
    CONSTRAINT FK_ra_ft_s_sheet_type FOREIGN KEY (ft_s_sheet_type) 
        REFERENCES ags.ra_ft_st(st_key)
);
GO

-- Индексы для ags.ra_ft_s
-- Индекс по типу файла (для связи с ra_f.af_type)
CREATE NONCLUSTERED INDEX IX_ra_ft_s_type 
    ON ags.ra_ft_s(ft_s_type);

-- Индекс по типу источника (FK)
CREATE NONCLUSTERED INDEX IX_ra_ft_s_sheet_type 
    ON ags.ra_ft_s(ft_s_sheet_type);

-- Составной индекс для частых запросов: тип файла + номер (для сортировки)
CREATE NONCLUSTERED INDEX IX_ra_ft_s_type_num 
    ON ags.ra_ft_s(ft_s_type, ft_s_num);
GO

-- ============================================================================
-- 4. Таблица: ags.ra_ft_sn (Имена источников / File Type Source Names)
-- ============================================================================
-- Описание: Справочник вариантов имен листов Excel для каждого источника
-- Связи: FK к ags.ra_ft_s (ftsn_ft_s → ft_s_key)
-- ============================================================================

IF OBJECT_ID('ags.ra_ft_sn', 'U') IS NOT NULL
    DROP TABLE ags.ra_ft_sn;
GO

CREATE TABLE ags.ra_ft_sn (
    ftsn_key INT PRIMARY KEY IDENTITY(1,1),             -- Первичный ключ
    ftsn_ft_s INT NOT NULL,                             -- FK → ags.ra_ft_s.ft_s_key (источник/лист)
    ftsn_name NVARCHAR(255) NOT NULL,                  -- Вариант имени листа Excel
    ftsn_created DATETIME2 DEFAULT GETDATE(),          -- Дата создания записи
    ftsn_updated DATETIME2 DEFAULT GETDATE(),          -- Дата последнего обновления
    
    -- Foreign Key constraints
    CONSTRAINT FK_ra_ft_sn_ft_s FOREIGN KEY (ftsn_ft_s) 
        REFERENCES ags.ra_ft_s(ft_s_key)
);
GO

-- Индексы для ags.ra_ft_sn
-- Индекс по источнику (FK)
CREATE NONCLUSTERED INDEX IX_ra_ft_sn_ft_s 
    ON ags.ra_ft_sn(ftsn_ft_s);

-- Индекс по имени листа (для поиска)
CREATE NONCLUSTERED INDEX IX_ra_ft_sn_name 
    ON ags.ra_ft_sn(ftsn_name);
GO

-- ============================================================================
-- Комментарии к таблицам (Extended Properties)
-- ============================================================================

-- Таблица ra_f
EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Таблица файлов Excel для проверки в рамках ревизий. Содержит список файлов, которые должны быть обработаны для каждой ревизии.', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_f';
GO

-- Комментарии к полям ra_f
EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Первичный ключ файла', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_f',
    @level2type=N'COLUMN', @level2name=N'af_key';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Имя файла Excel (например, "report.xlsx"). Для типов 2, 3, 5, 6 может содержать полный путь к файлу.', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_f',
    @level2type=N'COLUMN', @level2name=N'af_name';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Идентификатор директории (FK к ags.ra_dir.key). Определяет директорию, в которой находится файл.', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_f',
    @level2type=N'COLUMN', @level2name=N'af_dir';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Тип файла: 1=Отчёт агента, 2=Хранение и стройконтроль, 3=Аренда земли, 4=Инвестиционные программы, 5=Отчёты всех агентов, 6=Инвестиционные программы (23-0628)', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_f',
    @level2type=N'COLUMN', @level2name=N'af_type';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Флаг выполнения: 1=файл подлежит рассмотрению, 0=файл пропускается при обработке', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_f',
    @level2type=N'COLUMN', @level2name=N'af_execute';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Источник данных (используется при обработке файлов типа 2 - хранение и стройконтроль)', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_f',
    @level2type=N'COLUMN', @level2name=N'af_source';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Идентификатор ревизии (FK к ags.ra_a.adt_key). Явная связь файла с конкретной ревизией. Может быть NULL для файлов, не привязанных к конкретной ревизии.', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_f',
    @level2type=N'COLUMN', @level2name=N'af_adt_key';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Флаг завершения проверки: 1=проверка файла выполнена, 0=проверка не выполнена', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_f',
    @level2type=N'COLUMN', @level2name=N'af_is_done';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Флаг источника данных: 1=файл является источником данных, 0=файл не является источником', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_f',
    @level2type=N'COLUMN', @level2name=N'af_is_source';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Дата и время создания записи', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_f',
    @level2type=N'COLUMN', @level2name=N'af_created';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Дата и время последнего обновления записи', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_f',
    @level2type=N'COLUMN', @level2name=N'af_updated';
GO

-- Таблица ra_ft_st
EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Справочник типов источников данных для файлов. Используется для классификации листов Excel в файлах ревизий.', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_ft_st';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Первичный ключ типа источника', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_ft_st',
    @level2type=N'COLUMN', @level2name=N'st_key';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Название типа источника данных (например, "Основной лист", "Сводный лист")', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_ft_st',
    @level2type=N'COLUMN', @level2name=N'st_name';
GO

-- Таблица ra_ft_s
EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Справочник источников данных (листов Excel) для типов файлов. Определяет, какие листы должны быть обработаны для каждого типа файла (af_type).', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_ft_s';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Первичный ключ источника/листа', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_ft_s',
    @level2type=N'COLUMN', @level2name=N'ft_s_key';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Тип файла (соответствует ra_f.af_type: 1=Отчёт агента, 2=Хранение и стройконтроль, 3=Аренда земли, 4=Инвестиционные программы, 5=Отчёты всех агентов, 6=Инвестиционные программы 23-0628)', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_ft_s',
    @level2type=N'COLUMN', @level2name=N'ft_s_type';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Номер источника/листа. Определяет порядок обработки листов (сортировка по этому полю).', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_ft_s',
    @level2type=N'COLUMN', @level2name=N'ft_s_num';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Тип источника (FK к ags.ra_ft_st.st_key). Определяет категорию листа.', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_ft_s',
    @level2type=N'COLUMN', @level2name=N'ft_s_sheet_type';
GO

-- Таблица ra_ft_sn
EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Справочник вариантов имен листов Excel для каждого источника. Позволяет задать несколько возможных имен для одного листа (например, "Лист1", "Sheet1", "Основной").', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_ft_sn';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Первичный ключ имени источника', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_ft_sn',
    @level2type=N'COLUMN', @level2name=N'ftsn_key';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Идентификатор источника/листа (FK к ags.ra_ft_s.ft_s_key). Определяет, к какому источнику относится это имя.', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_ft_sn',
    @level2type=N'COLUMN', @level2name=N'ftsn_ft_s';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'Вариант имени листа Excel. При обработке файла проверяется наличие листа с каждым вариантом имени, используется первый найденный.', 
    @level0type=N'SCHEMA', @level0name=N'ags',
    @level1type=N'TABLE', @level1name=N'ra_ft_sn',
    @level2type=N'COLUMN', @level2name=N'ftsn_name';
GO

PRINT 'Таблицы для файлов ревизий и справочники типов файлов успешно созданы!';
GO
