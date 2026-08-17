-- =============================================================================
-- S61d / 0069: staging лаунчера выгрузки платежей (CnInvPmtUpl* → sudz)
-- DEV only. ags.* не изменяет. Tbl_1 не создаём (дубль Tbl, 0 строк).
-- =============================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'sudz.CnInvPmtUplFile', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.CnInvPmtUplFile
    (
        cipufKey              int            NOT NULL IDENTITY(1, 1),
        cipufUpload           int            NOT NULL,
        cipufPath             nvarchar(255)  NOT NULL,
        cipufFlLoad           bit            NOT NULL CONSTRAINT DF_CnInvPmtUplFile_FlLoad DEFAULT (0),
        cipufLoadingProgress  nvarchar(max)  NULL,
        cipufFlTbl            bit            NOT NULL CONSTRAINT DF_CnInvPmtUplFile_FlTbl DEFAULT (0),
        cipufSheet            nvarchar(255)  NULL,
        CONSTRAINT PK_CnInvPmtUplFile PRIMARY KEY CLUSTERED (cipufKey),
        CONSTRAINT UX_CnInvPmtUplFile_Upload UNIQUE (cipufUpload)
    );
END
GO

IF OBJECT_ID(N'sudz.CnInvPmtUplTbl', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.CnInvPmtUplTbl
    (
        ciputKey               int             NOT NULL IDENTITY(1, 1),
        ciputBE                nvarchar(50)    NULL,
        ciputAccount           int             NULL,
        ciputCntrPrtNum        int             NULL,
        ciputCntrPrtName       nvarchar(255)   NULL,
        ciputCAC               nvarchar(50)    NULL,
        ciputAgentNum          int             NULL,
        ciputAgentName         nvarchar(255)   NULL,
        ciputCnName            nvarchar(255)   NULL,
        ciputLink              nvarchar(255)   NULL,
        ciputCnInv             nvarchar(255)   NULL,
        ciputEntryDate         datetime        NULL,
        ciputDocDate           datetime        NULL,
        ciputDueDate           datetime        NULL,
        ciputDbtBlns           decimal(19, 4)  NULL,
        ciputDbtBlnsOverd      decimal(19, 4)  NULL,
        ciputDbtBlnsOverdNot   decimal(19, 4)  NULL,
        ciputCdtBlns           decimal(19, 4)  NULL,
        ciputCdtBlnsOverd      decimal(19, 4)  NULL,
        ciputCdtBlnsOverdNot   decimal(19, 4)  NULL,
        ciputBlns              decimal(19, 4)  NULL,
        ciputCnInvDocCode      nvarchar(50)    NULL,
        ciputAlligmentDate     datetime        NULL,
        ciputBaseDate          datetime        NULL,
        ciputCnInvDocSum       decimal(19, 4)  NULL,
        ciputStornoReason      nvarchar(255)   NULL,
        ciputStornoDocCode     nvarchar(50)    NULL,
        ciputSheetNum          int             NULL,
        ciputUnloadKey         int             NULL,
        CONSTRAINT PK_CnInvPmtUplTbl PRIMARY KEY CLUSTERED (ciputKey)
    );
    CREATE NONCLUSTERED INDEX IX_CnInvPmtUplTbl_Unload
        ON sudz.CnInvPmtUplTbl (ciputUnloadKey);
END
GO

IF OBJECT_ID(N'sudz.CnInvPmtUplTblCnInv', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.CnInvPmtUplTblCnInv
    (
        ciputciRow            int            NOT NULL IDENTITY(1, 1),
        ciputciCntrPrtNum     int            NOT NULL,
        ciputciCntrPrtName    nvarchar(255)  NULL,
        ciputciCnName         nvarchar(255)  NULL,
        ciputciCnDate         datetime       NULL,
        ciputciCn_key         int            NULL,
        ciputciCsosKey        int            NULL,
        ciputciCnInv          nvarchar(255)  NULL,
        ciputciCiKey          int            NULL,
        ciputciCnInvNumCount  int            NULL CONSTRAINT DF_CnInvPmtUplTblCnInv_Cnt DEFAULT (0),
        CONSTRAINT PK_CnInvPmtUplTblCnInv PRIMARY KEY CLUSTERED (ciputciRow)
    );
END
GO

SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = N'sudz' AND t.name LIKE N'CnInvPmtUpl%'
ORDER BY t.name;
GO
