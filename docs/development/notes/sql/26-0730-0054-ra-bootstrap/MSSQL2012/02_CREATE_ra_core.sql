-- =============================================================================
-- 02_CREATE_ra_core.sql — ra_a, ra_f, ra_ft_s, ra_ft_sn (CREATE-if-missing)
-- Access-поля + FEMSQ: adt_staging_log_level, *_created/*_updated
-- ft_s_period: NVARCHAR(50) для JdbcRaFtSDao (Access Number → CAST при импорте)
-- FK между ra_* без привязки к ags.og (безопаснее на первом прогоне)
-- =============================================================================

PRINT '=== 02_CREATE_ra_core ===';

IF OBJECT_ID(N'ags.ra_a', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_a (
        adt_key                BIGINT NOT NULL IDENTITY(1,1),
        adt_name               NVARCHAR(255) NOT NULL,
        adt_date               DATETIME NULL,
        adt_results            NVARCHAR(MAX) NULL,
        adt_dir                INT NOT NULL,
        adt_type               INT NOT NULL,
        adt_AddRA              BIT NOT NULL CONSTRAINT DF_ra_a_AddRA DEFAULT (0),
        adt_staging_log_level  NVARCHAR(16) NULL,
        adt_created            DATETIME2 NULL CONSTRAINT DF_ra_a_created DEFAULT (GETDATE()),
        adt_updated            DATETIME2 NULL CONSTRAINT DF_ra_a_updated DEFAULT (GETDATE()),
        CONSTRAINT PK_ra_a PRIMARY KEY (adt_key)
    );
    PRINT 'Created ags.ra_a';
END
ELSE
    PRINT 'Skip: ags.ra_a exists';
GO

IF OBJECT_ID(N'ags.ra_a', N'U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ra_a_dir' AND parent_object_id = OBJECT_ID(N'ags.ra_a'))
   AND OBJECT_ID(N'ags.ra_dir', N'U') IS NOT NULL
BEGIN
    ALTER TABLE ags.ra_a ADD CONSTRAINT FK_ra_a_dir
        FOREIGN KEY (adt_dir) REFERENCES ags.ra_dir([key]);
    PRINT 'Added FK_ra_a_dir';
END
GO

IF OBJECT_ID(N'ags.ra_a', N'U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ra_a_type' AND parent_object_id = OBJECT_ID(N'ags.ra_a'))
   AND OBJECT_ID(N'ags.ra_at', N'U') IS NOT NULL
BEGIN
    ALTER TABLE ags.ra_a ADD CONSTRAINT FK_ra_a_type
        FOREIGN KEY (adt_type) REFERENCES ags.ra_at(at_key);
    PRINT 'Added FK_ra_a_type';
END
GO

IF OBJECT_ID(N'ags.ra_f', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_f (
        af_key        BIGINT NOT NULL IDENTITY(1,1),
        af_num        INT NULL,
        af_name       NVARCHAR(255) NOT NULL,
        af_dir        INT NOT NULL,
        af_type       INT NOT NULL,
        ra_org_sender INT NULL,
        af_execute    BIT NOT NULL CONSTRAINT DF_ra_f_execute DEFAULT (1),
        af_source     BIT NULL,
        af_created    DATETIME2 NULL CONSTRAINT DF_ra_f_created DEFAULT (GETDATE()),
        af_updated    DATETIME2 NULL CONSTRAINT DF_ra_f_updated DEFAULT (GETDATE()),
        CONSTRAINT PK_ra_f PRIMARY KEY (af_key)
    );
    PRINT 'Created ags.ra_f';
END
ELSE
    PRINT 'Skip: ags.ra_f exists';
GO

IF OBJECT_ID(N'ags.ra_f', N'U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ra_f_dir' AND parent_object_id = OBJECT_ID(N'ags.ra_f'))
   AND OBJECT_ID(N'ags.ra_dir', N'U') IS NOT NULL
BEGIN
    ALTER TABLE ags.ra_f ADD CONSTRAINT FK_ra_f_dir
        FOREIGN KEY (af_dir) REFERENCES ags.ra_dir([key]);
    PRINT 'Added FK_ra_f_dir';
END
GO

IF OBJECT_ID(N'ags.ra_f', N'U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ra_f_type' AND parent_object_id = OBJECT_ID(N'ags.ra_f'))
   AND OBJECT_ID(N'ags.ra_ft', N'U') IS NOT NULL
BEGIN
    ALTER TABLE ags.ra_f ADD CONSTRAINT FK_ra_f_type
        FOREIGN KEY (af_type) REFERENCES ags.ra_ft(ft_key);
    PRINT 'Added FK_ra_f_type';
END
GO

IF OBJECT_ID(N'ags.ra_ft_s', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_ft_s (
        ft_s_key        INT NOT NULL IDENTITY(1,1),
        ft_s_type       INT NOT NULL,
        ft_s_num        INT NOT NULL,
        ft_s_sheet_type INT NOT NULL,
        ft_s_period     NVARCHAR(50) NULL,
        ft_s_created    DATETIME2 NULL CONSTRAINT DF_ra_ft_s_created DEFAULT (GETDATE()),
        ft_s_updated    DATETIME2 NULL CONSTRAINT DF_ra_ft_s_updated DEFAULT (GETDATE()),
        CONSTRAINT PK_ra_ft_s PRIMARY KEY (ft_s_key)
    );
    PRINT 'Created ags.ra_ft_s';
END
ELSE
    PRINT 'Skip: ags.ra_ft_s exists';
GO

IF OBJECT_ID(N'ags.ra_ft_sn', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_ft_sn (
        ftsn_key     INT NOT NULL IDENTITY(1,1),
        ftsn_ft_s    INT NOT NULL,
        ftsn_name    NVARCHAR(255) NOT NULL,
        ftsn_created DATETIME2 NULL CONSTRAINT DF_ra_ft_sn_created DEFAULT (GETDATE()),
        ftsn_updated DATETIME2 NULL CONSTRAINT DF_ra_ft_sn_updated DEFAULT (GETDATE()),
        CONSTRAINT PK_ra_ft_sn PRIMARY KEY (ftsn_key)
    );
    PRINT 'Created ags.ra_ft_sn';
END
ELSE
    PRINT 'Skip: ags.ra_ft_sn exists';
GO

IF OBJECT_ID(N'ags.ra_ft_sn', N'U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ra_ft_sn_ft_s' AND parent_object_id = OBJECT_ID(N'ags.ra_ft_sn'))
   AND OBJECT_ID(N'ags.ra_ft_s', N'U') IS NOT NULL
BEGIN
    ALTER TABLE ags.ra_ft_sn ADD CONSTRAINT FK_ra_ft_sn_ft_s
        FOREIGN KEY (ftsn_ft_s) REFERENCES ags.ra_ft_s(ft_s_key);
    PRINT 'Added FK_ra_ft_sn_ft_s';
END
GO

PRINT '=== 02_CREATE_ra_core: готово ===';
GO
