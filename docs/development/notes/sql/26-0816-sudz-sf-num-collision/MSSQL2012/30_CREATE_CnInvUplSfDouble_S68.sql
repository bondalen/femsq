-- =============================================================================
-- S68: sudz.CnInvUplSfDouble — SQL Server 2012 SP4
-- ags.* не изменяет. Статус: ПРОЕКТ — после согласия владельца.
-- =============================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'sudz.CnInvUplSfDouble', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.CnInvUplSfDouble
    (
        ciusKey            int            NOT NULL IDENTITY(1, 1),
        ciusCidut          int            NULL,
        ciusCiput          int            NULL,
        ciusDbtFile        int            NULL,
        ciusPmtFile        int            NULL,
        ciusUnloadKey      int            NULL,
        ciusDbtTblCnInvRow int            NULL,
        ciusPmtTblCnInvRow int            NULL,
        ciusCnKey          int            NULL,
        ciusCnNum          nvarchar(255)  COLLATE Cyrillic_General_CI_AS NULL,
        ciusInvNum         nvarchar(255)  COLLATE Cyrillic_General_CI_AS NULL,
        ciusInvNumCount    int            NULL,
        ciusStatus         varchar(16)    NOT NULL
            CONSTRAINT DF_CnInvUplSfDouble_Status DEFAULT ('open'),
        ciusStatusAt       datetime       NULL,
        ciusCreatedInvKey  int            NULL,
        CONSTRAINT PK_CnInvUplSfDouble PRIMARY KEY CLUSTERED (ciusKey),
        CONSTRAINT CK_CnInvUplSfDouble_OneTbl CHECK (
            (ciusCidut IS NOT NULL AND ciusCiput IS NULL)
            OR (ciusCidut IS NULL AND ciusCiput IS NOT NULL)
        ),
        CONSTRAINT CK_CnInvUplSfDouble_Status CHECK (
            ciusStatus IN ('open', 'created', 'deferred')
        ),
        CONSTRAINT FK_CnInvUplSfDouble_DbtTbl FOREIGN KEY (ciusCidut)
            REFERENCES sudz.CnInvDbtUplTbl (cidutKey),
        CONSTRAINT FK_CnInvUplSfDouble_PmtTbl FOREIGN KEY (ciusCiput)
            REFERENCES sudz.CnInvPmtUplTbl (ciputKey),
        CONSTRAINT FK_CnInvUplSfDouble_DbtFile FOREIGN KEY (ciusDbtFile)
            REFERENCES sudz.CnInvDbtUplFile (cidufKey),
        CONSTRAINT FK_CnInvUplSfDouble_PmtFile FOREIGN KEY (ciusPmtFile)
            REFERENCES sudz.CnInvPmtUplFile (cipufKey)
    );

    CREATE UNIQUE NONCLUSTERED INDEX UX_CnInvUplSfDouble_Cidut
        ON sudz.CnInvUplSfDouble (ciusCidut)
        WHERE ciusCidut IS NOT NULL;

    CREATE UNIQUE NONCLUSTERED INDEX UX_CnInvUplSfDouble_Ciput
        ON sudz.CnInvUplSfDouble (ciusCiput)
        WHERE ciusCiput IS NOT NULL;

    CREATE NONCLUSTERED INDEX IX_CnInvUplSfDouble_DbtFile_Status
        ON sudz.CnInvUplSfDouble (ciusDbtFile, ciusStatus)
        WHERE ciusDbtFile IS NOT NULL;

    CREATE NONCLUSTERED INDEX IX_CnInvUplSfDouble_PmtFile_Status
        ON sudz.CnInvUplSfDouble (ciusPmtFile, ciusStatus)
        WHERE ciusPmtFile IS NOT NULL;

    CREATE NONCLUSTERED INDEX IX_CnInvUplSfDouble_InvNum
        ON sudz.CnInvUplSfDouble (ciusInvNum);
END
GO

SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = N'sudz' AND t.name = N'CnInvUplSfDouble';
GO
