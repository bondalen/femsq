-- =============================================================================
-- 04_CREATE_mapping.sql — ra_sheet_conf, ra_col_map (CREATE-if-missing)
-- Нужны Stage 1 FEMSQ; в Access локально отсутствуют
-- =============================================================================

PRINT '=== 04_CREATE_mapping ===';

IF OBJECT_ID(N'ags.ra_sheet_conf', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_sheet_conf (
        rsc_key INT NOT NULL IDENTITY(1,1),
        rsc_ft_key INT NOT NULL,
        rsc_sheet NVARCHAR(100) NULL,
        rsc_stg_tbl NVARCHAR(100) NOT NULL,
        rsc_anchor NVARCHAR(200) NOT NULL,
        rsc_anchor_match CHAR(1) NOT NULL,
        rsc_row_pattern NVARCHAR(200) NULL,
        rsc_sign_whitelist NVARCHAR(500) NULL,
        CONSTRAINT PK_ra_sheet_conf PRIMARY KEY (rsc_key)
    );
    PRINT 'Created ags.ra_sheet_conf';
END
ELSE
    PRINT 'Skip: ags.ra_sheet_conf exists';
GO

IF OBJECT_ID(N'ags.ra_sheet_conf', N'U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_rsc_ft' AND parent_object_id = OBJECT_ID(N'ags.ra_sheet_conf'))
   AND OBJECT_ID(N'ags.ra_ft', N'U') IS NOT NULL
BEGIN
    ALTER TABLE ags.ra_sheet_conf ADD CONSTRAINT FK_rsc_ft
        FOREIGN KEY (rsc_ft_key) REFERENCES ags.ra_ft(ft_key);
    PRINT 'Added FK_rsc_ft';
END
GO

IF OBJECT_ID(N'ags.ra_col_map', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_col_map (
        rcm_key INT NOT NULL IDENTITY(1,1),
        rcm_rsc_key INT NOT NULL,
        rcm_tbl_col NVARCHAR(100) NOT NULL,
        rcm_tbl_col_ord SMALLINT NOT NULL,
        rcm_xl_hdr NVARCHAR(200) NOT NULL,
        rcm_xl_hdr_pri TINYINT NOT NULL,
        rcm_xl_match CHAR(1) NOT NULL,
        rcm_required BIT NOT NULL,
        CONSTRAINT PK_ra_col_map PRIMARY KEY (rcm_key)
    );
    PRINT 'Created ags.ra_col_map';
END
ELSE
    PRINT 'Skip: ags.ra_col_map exists';
GO

IF OBJECT_ID(N'ags.ra_col_map', N'U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_rcm_rsc' AND parent_object_id = OBJECT_ID(N'ags.ra_col_map'))
   AND OBJECT_ID(N'ags.ra_sheet_conf', N'U') IS NOT NULL
BEGIN
    ALTER TABLE ags.ra_col_map ADD CONSTRAINT FK_rcm_rsc
        FOREIGN KEY (rcm_rsc_key) REFERENCES ags.ra_sheet_conf(rsc_key);
    PRINT 'Added FK_rcm_rsc';
END
GO

PRINT '=== 04_CREATE_mapping: готово ===';
GO
