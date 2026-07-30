-- =============================================================================
-- 03_CREATE_staging.sql — ra_execution + staging (CREATE-if-missing)
-- База Liquibase 2026-03-20 + финальные колонки 26-0714/26-0720/26-0721
-- =============================================================================

PRINT '=== 03_CREATE_staging ===';

IF OBJECT_ID(N'ags.ra_execution', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_execution (
        exec_key      INT NOT NULL IDENTITY(1,1),
        exec_adt_key  INT NOT NULL,
        exec_status   NVARCHAR(20) NOT NULL,
        exec_add_ra   BIT NOT NULL,
        exec_started  DATETIME2 NULL,
        exec_finished DATETIME2 NULL,
        exec_error    NVARCHAR(MAX) NULL,
        CONSTRAINT PK_ra_execution PRIMARY KEY (exec_key)
    );
    PRINT 'Created ags.ra_execution';
END
ELSE
    PRINT 'Skip: ags.ra_execution exists';
GO

IF OBJECT_ID(N'ags.ra_stg_ra', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_stg_ra (
        rain_key INT NOT NULL IDENTITY(1,1),
        rain_exec_key INT NULL,
        rainRow INT NULL,
        rainRaNum NVARCHAR(100) NOT NULL,
        rainRaDate DATE NULL,
        rainSign NVARCHAR(50) NULL,
        rainCstAgPnStr NVARCHAR(100) NULL,
        rainCstName NVARCHAR(255) NULL,
        rainSender NVARCHAR(255) NULL,
        rainTtl MONEY NULL,
        rainWork MONEY NULL,
        rainEquip MONEY NULL,
        rainOthers MONEY NULL,
        rainArrivedNum NVARCHAR(255) NULL,
        rainArrivedDate DATE NULL,
        rainArrivedDateFact DATE NULL,
        rainReturnedNum NVARCHAR(255) NULL,
        rainReturnedDate DATE NULL,
        rainReturnedReason NVARCHAR(500) NULL,
        rainSendNum NVARCHAR(255) NULL,
        rainSendDate DATE NULL,
        rainUnit NVARCHAR(255) NULL,
        rainRaSheetsNumber INT NULL,
        rainTitleDocSheetsNumber INT NULL,
        rainPlanNumber INT NULL,
        rainPlanDate DATE NULL,
        rainRaSignOfTest NVARCHAR(50) NULL,
        rainRaSendedSum MONEY NULL,
        rainRaReturnedSum MONEY NULL,
        CONSTRAINT PK_ra_stg_ra PRIMARY KEY (rain_key)
    );
    PRINT 'Created ags.ra_stg_ra';
END
ELSE
    PRINT 'Skip: ags.ra_stg_ra exists';
GO

IF OBJECT_ID(N'ags.ra_stg_ralp', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_stg_ralp (
        ralprt_key INT NOT NULL IDENTITY(1,1),
        ralprt_exec_key INT NULL,
        ralprtNum NVARCHAR(100) NOT NULL,
        ralprtDate DATE NULL,
        ralprtCstCodeStr NVARCHAR(50) NULL,
        ralprtOgSenderStr NVARCHAR(255) NULL,
        ralprtOgBranchStr NVARCHAR(255) NULL,
        ralprtCostAndVat MONEY NULL,
        ralprtPresented TINYINT NULL,
        ralprtSentToBook TINYINT NULL,
        ralprtReturnedFlg TINYINT NULL,
        ralprtTestStartDate DATE NULL,
        ralprtNote NVARCHAR(MAX) NULL,
        ralprtArrived NVARCHAR(255) NULL,
        ralprtSent NVARCHAR(255) NULL,
        ralprtReturned NVARCHAR(255) NULL,
        ralprtCstAgPn INT NULL,
        ralprtOgSender INT NULL,
        ralprtStatus TINYINT NULL,
        ralprtRaKey INT NULL,
        ralprtRaAuKey INT NULL,
        ralprtRow INT NULL,
        CONSTRAINT PK_ra_stg_ralp PRIMARY KEY (ralprt_key)
    );
    PRINT 'Created ags.ra_stg_ralp';
END
ELSE
    PRINT 'Skip: ags.ra_stg_ralp exists';
GO

IF OBJECT_ID(N'ags.ra_stg_ralp_sm', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_stg_ralp_sm (
        ralprs_key INT NOT NULL IDENTITY(1,1),
        ralprs_exec_key INT NULL,
        ralprsNum INT NULL,
        ralprsSenderStr NVARCHAR(255) NOT NULL,
        ralprsArrived INT NULL,
        ralprsInProcess INT NULL,
        ralprsSended INT NULL,
        ralprsReturned INT NULL,
        ralprsAccepted MONEY NULL,
        ralprsSender INT NULL,
        ralprsY INT NULL,
        ralprsAdtKey INT NULL,
        ralprsRow INT NULL,
        CONSTRAINT PK_ra_stg_ralp_sm PRIMARY KEY (ralprs_key)
    );
    PRINT 'Created ags.ra_stg_ralp_sm';
END
ELSE
    PRINT 'Skip: ags.ra_stg_ralp_sm exists';
GO

IF OBJECT_ID(N'ags.ra_stg_agfee', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_stg_agfee (
        oafpt_key INT NOT NULL IDENTITY(1,1),
        oafpt_exec_key INT NULL,
        oafptOafName NVARCHAR(100) NOT NULL,
        oafptOafDate DATE NULL,
        oafptPnCstAgPn NVARCHAR(50) NULL,
        oafptTtl MONEY NULL,
        oafptArrivedNum NVARCHAR(255) NULL,
        oafptArrivedDate DATE NULL,
        oafptSendedNum NVARCHAR(255) NULL,
        oafptSendedDate DATE NULL,
        oafptReturnedNum NVARCHAR(255) NULL,
        oafptReturnedDate DATE NULL,
        oafptReturnedReason NVARCHAR(500) NULL,
        oafptUnit NVARCHAR(255) NULL,
        oafptPagesCount INT NULL,
        oafptActCount INT NULL,
        oafptOafSender NVARCHAR(255) NULL,
        oafptCapex NVARCHAR(10) NULL,
        oafptReturnedSum MONEY NULL,
        oafptOgKey INT NULL,
        oafptOafSenderKey INT NULL,
        oafptPnCstAgPnKey INT NULL,
        oafptRow INT NULL,
        CONSTRAINT PK_ra_stg_agfee PRIMARY KEY (oafpt_key)
    );
    PRINT 'Created ags.ra_stg_agfee';
END
ELSE
    PRINT 'Skip: ags.ra_stg_agfee exists';
GO

PRINT '=== 03_CREATE_staging: готово ===';
GO
