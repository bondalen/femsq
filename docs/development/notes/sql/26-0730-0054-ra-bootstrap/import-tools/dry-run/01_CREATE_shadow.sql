-- =============================================================================
-- Dry-run shadow tables for 0054.4 INSERT validation (Docker only)
-- Tables: ags.i_ra_*  — do NOT use on prod
-- =============================================================================

PRINT '=== CREATE shadow i_ra_* (Docker dry-run) ===';

IF OBJECT_ID(N'ags.i_ra_ft_sn', N'U') IS NOT NULL DROP TABLE ags.i_ra_ft_sn;
IF OBJECT_ID(N'ags.i_ra_ft_s', N'U') IS NOT NULL DROP TABLE ags.i_ra_ft_s;
IF OBJECT_ID(N'ags.i_ra_f', N'U') IS NOT NULL DROP TABLE ags.i_ra_f;
IF OBJECT_ID(N'ags.i_ra_a', N'U') IS NOT NULL DROP TABLE ags.i_ra_a;
IF OBJECT_ID(N'ags.i_ra_ft_st', N'U') IS NOT NULL DROP TABLE ags.i_ra_ft_st;
IF OBJECT_ID(N'ags.i_ra_ft', N'U') IS NOT NULL DROP TABLE ags.i_ra_ft;
IF OBJECT_ID(N'ags.i_ra_dir', N'U') IS NOT NULL DROP TABLE ags.i_ra_dir;
IF OBJECT_ID(N'ags.i_ra_at', N'U') IS NOT NULL DROP TABLE ags.i_ra_at;
GO

CREATE TABLE ags.i_ra_at (
    at_key INT NOT NULL IDENTITY(1,1),
    at_name NVARCHAR(255) NOT NULL,
    CONSTRAINT PK_i_ra_at PRIMARY KEY (at_key)
);

CREATE TABLE ags.i_ra_dir (
    [key] INT NOT NULL IDENTITY(1,1),
    dir_name NVARCHAR(255) NOT NULL,
    dir NVARCHAR(500) NOT NULL,
    CONSTRAINT PK_i_ra_dir PRIMARY KEY ([key])
);

CREATE TABLE ags.i_ra_ft (
    ft_key INT NOT NULL IDENTITY(1,1),
    ft_name NVARCHAR(255) NOT NULL,
    CONSTRAINT PK_i_ra_ft PRIMARY KEY (ft_key)
);

CREATE TABLE ags.i_ra_ft_st (
    st_key INT NOT NULL IDENTITY(1,1),
    st_name NVARCHAR(255) NOT NULL,
    CONSTRAINT PK_i_ra_ft_st PRIMARY KEY (st_key)
);

CREATE TABLE ags.i_ra_ft_s (
    ft_s_key INT NOT NULL IDENTITY(1,1),
    ft_s_type INT NOT NULL,
    ft_s_num INT NOT NULL,
    ft_s_sheet_type INT NOT NULL,
    ft_s_period NVARCHAR(50) NULL,
    CONSTRAINT PK_i_ra_ft_s PRIMARY KEY (ft_s_key)
);

CREATE TABLE ags.i_ra_ft_sn (
    ftsn_key INT NOT NULL IDENTITY(1,1),
    ftsn_ft_s INT NOT NULL,
    ftsn_name NVARCHAR(255) NOT NULL,
    CONSTRAINT PK_i_ra_ft_sn PRIMARY KEY (ftsn_key)
);

CREATE TABLE ags.i_ra_a (
    adt_key BIGINT NOT NULL IDENTITY(1,1),
    adt_name NVARCHAR(255) NOT NULL,
    adt_date DATETIME NULL,
    adt_results NVARCHAR(MAX) NULL,
    adt_dir INT NOT NULL,
    adt_type INT NOT NULL,
    adt_AddRA BIT NOT NULL CONSTRAINT DF_i_ra_a_AddRA DEFAULT (0),
    CONSTRAINT PK_i_ra_a PRIMARY KEY (adt_key)
);

CREATE TABLE ags.i_ra_f (
    af_key BIGINT NOT NULL IDENTITY(1,1),
    af_num INT NULL,
    af_name NVARCHAR(255) NOT NULL,
    af_dir INT NOT NULL,
    af_type INT NOT NULL,
    ra_org_sender INT NULL,
    af_execute BIT NOT NULL CONSTRAINT DF_i_ra_f_execute DEFAULT (1),
    af_source BIT NULL,
    CONSTRAINT PK_i_ra_f PRIMARY KEY (af_key)
);
GO

PRINT '=== shadow tables ready ===';
GO
