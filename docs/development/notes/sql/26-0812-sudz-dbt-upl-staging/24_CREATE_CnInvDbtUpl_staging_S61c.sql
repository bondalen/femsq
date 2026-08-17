-- =============================================================================
-- S61c / 0069: staging лаунчера загрузки свода (Access CnInvDbtUpl* → sudz)
-- DEV only (SQL Server 2022). ags.* не изменяет.
-- Статус: ЧЕРНОВИК — применять после согласия владельца.
-- См. README.md в этой папке.
-- =============================================================================

SET NOCOUNT ON;
GO

-- ---------------------------------------------------------------------------
-- 1. CnInvDbtUplFile — шапка лаунчера (persist, 1:1 с upl_key логически)
-- ---------------------------------------------------------------------------
IF OBJECT_ID(N'sudz.CnInvDbtUplFile', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.CnInvDbtUplFile
    (
        cidufKey              int            NOT NULL IDENTITY(1, 1),
        cidufUpload           int            NOT NULL,  -- = upl_key (ags или sudz); без FK — см. README
        cidufPath             nvarchar(255)  NOT NULL,
        cidufFlLoad           bit            NOT NULL CONSTRAINT DF_CnInvDbtUplFile_FlLoad DEFAULT (0),
        cidufLoadingProgress  nvarchar(max)  NULL,     -- HTML (в Access — RTF Memo)
        cidufFlTbl            bit            NOT NULL CONSTRAINT DF_CnInvDbtUplFile_FlTbl DEFAULT (0),
        CONSTRAINT PK_CnInvDbtUplFile PRIMARY KEY CLUSTERED (cidufKey),
        CONSTRAINT UX_CnInvDbtUplFile_Upload UNIQUE (cidufUpload)
    );
END
GO

-- ---------------------------------------------------------------------------
-- 2. CnInvDbtUplFileSh — листы файла (persist)
-- ---------------------------------------------------------------------------
IF OBJECT_ID(N'sudz.CnInvDbtUplFileSh', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.CnInvDbtUplFileSh
    (
        cidufsKey      int            NOT NULL IDENTITY(1, 1),
        cidufsFile     int            NOT NULL,
        cidufsSheet    nvarchar(255)  NOT NULL,
        cidufsAccount  int            NOT NULL,  -- ags.accnt.account_key
        cidufsTest     bit            NOT NULL CONSTRAINT DF_CnInvDbtUplFileSh_Test DEFAULT (0),
        CONSTRAINT PK_CnInvDbtUplFileSh PRIMARY KEY CLUSTERED (cidufsKey),
        CONSTRAINT FK_CnInvDbtUplFileSh_File FOREIGN KEY (cidufsFile)
            REFERENCES sudz.CnInvDbtUplFile (cidufKey),
        CONSTRAINT FK_CnInvDbtUplFileSh_Accnt FOREIGN KEY (cidufsAccount)
            REFERENCES ags.accnt (account_key)
    );
    CREATE NONCLUSTERED INDEX IX_CnInvDbtUplFileSh_File
        ON sudz.CnInvDbtUplFileSh (cidufsFile);
END
GO

-- ---------------------------------------------------------------------------
-- 3. CnInvDbtUplTbl — буфер строк Excel (эфемерный; + суррогатный PK)
-- ---------------------------------------------------------------------------
IF OBJECT_ID(N'sudz.CnInvDbtUplTbl', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.CnInvDbtUplTbl
    (
        cidutKey              int             NOT NULL IDENTITY(1, 1),  -- FEMSQ: в Access PK не было
        FindDbtNum            smallint        NULL CONSTRAINT DF_CnInvDbtUplTbl_FindDbtNum DEFAULT (0),
        cidutAccount          int             NULL,
        cidutCntrPrtNum       int             NULL,
        cidutCntrPrtName      nvarchar(255)   NULL,
        cidutCntrPrtITN       nvarchar(255)   NULL,
        cidutCnName           nvarchar(255)   NULL,
        cidutCnDate           datetime        NULL,
        cidutCnInv            nvarchar(255)   NULL,
        cidutCnInvName        nvarchar(255)   NULL,
        cidutFormtnDate       datetime        NULL,
        cidutMatrtyDate       datetime        NULL,
        cidutDebt             decimal(19, 4)  NULL,  -- Access Currency → decimal
        cidutDebtOverdue      decimal(19, 4)  NULL,
        cidutDoc              nvarchar(255)   NULL,
        cidutLink             nvarchar(255)   NULL,
        cidutSheet            int             NULL,  -- ≈ cidufsKey
        cidutSheetNum         int             NULL,
        cidutUnloadKey        int             NULL,  -- = upl_key
        cidutCnDateNull       datetime        NULL,
        cidutCnNameNull       nvarchar(243)   NULL,
        cidutCnInvNull        nvarchar(243)   NULL,
        cidutCnInvNameNull    nvarchar(243)   NULL,
        CONSTRAINT PK_CnInvDbtUplTbl PRIMARY KEY CLUSTERED (cidutKey)
    );
    CREATE NONCLUSTERED INDEX IX_CnInvDbtUplTbl_Unload
        ON sudz.CnInvDbtUplTbl (cidutUnloadKey);
END
GO

-- ---------------------------------------------------------------------------
-- 4. CnInvDbtUplTblCnInv — промежуточные новые СФ (эфемерный)
-- ---------------------------------------------------------------------------
IF OBJECT_ID(N'sudz.CnInvDbtUplTblCnInv', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.CnInvDbtUplTblCnInv
    (
        cidutciRow     int            NOT NULL IDENTITY(1, 1),  -- FEMSQ surrogate
        cidutciCnName  nvarchar(255)  NULL,
        cidutciCn_key  int            NULL,
        cidutciCnInv   nvarchar(255)  NULL,
        cidutciCiKey   int            NULL,
        inNumCount     int            NULL,
        CONSTRAINT PK_CnInvDbtUplTblCnInv PRIMARY KEY CLUSTERED (cidutciRow)
    );
END
GO

-- ---------------------------------------------------------------------------
-- 5. CnInvDbtUplFileInvDouble — очередь неоднозначных СФ (эфемерный)
-- ---------------------------------------------------------------------------
IF OBJECT_ID(N'sudz.CnInvDbtUplFileInvDouble', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.CnInvDbtUplFileInvDouble
    (
        cidufiKey          int            NOT NULL IDENTITY(1, 1),
        cidufiCiduf        int            NULL,
        cidufiCnNnn        int            NULL,
        cidufiCnNum        nvarchar(255)  NULL,
        cidufiCnKey        int            NULL,
        cidufiInvNnn       int            NULL,
        cidufiInvNum       nvarchar(255)  NULL,
        cidufiInvNumCount  nvarchar(255)  NULL,  -- как в Access (Text)
        CONSTRAINT PK_CnInvDbtUplFileInvDouble PRIMARY KEY CLUSTERED (cidufiKey),
        CONSTRAINT FK_CnInvDbtUplFileInvDouble_File FOREIGN KEY (cidufiCiduf)
            REFERENCES sudz.CnInvDbtUplFile (cidufKey)
    );
END
GO

-- VERIFY
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = N'sudz'
  AND t.name IN (
      N'CnInvDbtUplFile', N'CnInvDbtUplFileSh', N'CnInvDbtUplTbl',
      N'CnInvDbtUplTblCnInv', N'CnInvDbtUplFileInvDouble'
  )
ORDER BY t.name;
GO
