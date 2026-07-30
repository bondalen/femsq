-- =============================================================================
-- 01_CREATE_lookups.sql — ra_at, ra_dir, ra_ft, ra_ft_st (CREATE-if-missing)
-- Access = поля ядра; + *_created/*_updated для FEMSQ где нужно Java
-- =============================================================================

PRINT '=== 01_CREATE_lookups ===';

IF OBJECT_ID(N'ags.ra_at', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_at (
        at_key     INT NOT NULL IDENTITY(1,1),
        at_name    NVARCHAR(255) NOT NULL,
        at_created DATETIME2 NULL CONSTRAINT DF_ra_at_created DEFAULT (GETDATE()),
        at_updated DATETIME2 NULL CONSTRAINT DF_ra_at_updated DEFAULT (GETDATE()),
        CONSTRAINT PK_ra_at PRIMARY KEY (at_key)
    );
    PRINT 'Created ags.ra_at';
END
ELSE
    PRINT 'Skip: ags.ra_at exists';
GO

IF OBJECT_ID(N'ags.ra_dir', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_dir (
        [key]       INT NOT NULL IDENTITY(1,1),
        dir_name    NVARCHAR(255) NOT NULL,
        dir         NVARCHAR(500) NOT NULL,
        dir_created DATETIME2 NULL CONSTRAINT DF_ra_dir_created DEFAULT (GETDATE()),
        dir_updated DATETIME2 NULL CONSTRAINT DF_ra_dir_updated DEFAULT (GETDATE()),
        CONSTRAINT PK_ra_dir PRIMARY KEY ([key])
    );
    PRINT 'Created ags.ra_dir';
END
ELSE
    PRINT 'Skip: ags.ra_dir exists';
GO

IF OBJECT_ID(N'ags.ra_ft', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_ft (
        ft_key  INT NOT NULL IDENTITY(1,1),
        ft_name NVARCHAR(255) NOT NULL,
        CONSTRAINT PK_ra_ft PRIMARY KEY (ft_key)
    );
    PRINT 'Created ags.ra_ft';
END
ELSE
    PRINT 'Skip: ags.ra_ft exists';
GO

IF OBJECT_ID(N'ags.ra_ft_st', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_ft_st (
        st_key     INT NOT NULL IDENTITY(1,1),
        st_name    NVARCHAR(255) NOT NULL,
        st_created DATETIME2 NULL CONSTRAINT DF_ra_ft_st_created DEFAULT (GETDATE()),
        st_updated DATETIME2 NULL CONSTRAINT DF_ra_ft_st_updated DEFAULT (GETDATE()),
        CONSTRAINT PK_ra_ft_st PRIMARY KEY (st_key)
    );
    PRINT 'Created ags.ra_ft_st';
END
ELSE
    PRINT 'Skip: ags.ra_ft_st exists';
GO

PRINT '=== 01_CREATE_lookups: готово ===';
GO
