-- =============================================================================
-- S66e: sudz.CnInvUplInvDbtDouble — очередь разбора двоящих задолженностей СФ
-- MSSQL2012 / продуктив (без CREATE OR ALTER, без DROP IF EXISTS).
-- Зеркало паттерна CnInvUplSfDouble (S68); префикс ciud*.
-- =============================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'sudz.CnInvUplInvDbtDouble', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.CnInvUplInvDbtDouble
    (
        ciudKey            int            NOT NULL IDENTITY(1, 1),

        ciudCidut          int            NOT NULL,
        ciudDbtFile        int            NULL,
        ciudUnloadKey      int            NOT NULL,

        ciudIKey           int            NULL,
        ciudCnNum          nvarchar(255)  COLLATE Cyrillic_General_CI_AS NULL,
        ciudInvNum         nvarchar(255)  COLLATE Cyrillic_General_CI_AS NULL,
        ciudDebt           decimal(18, 2) NULL,
        ciudIdvvKey        int            NULL,
        ciudReason         nvarchar(64)   NULL,
        ciudReasonDetail   nvarchar(max)  NULL,

        ciudStatus         varchar(16)    NOT NULL
            CONSTRAINT DF_CnInvUplInvDbtDouble_Status DEFAULT ('open'),
        ciudStatusAt       datetime       NULL,
        ciudCreatedIdKey   int            NULL,

        CONSTRAINT PK_CnInvUplInvDbtDouble PRIMARY KEY CLUSTERED (ciudKey),

        CONSTRAINT CK_CnInvUplInvDbtDouble_Status CHECK (
            ciudStatus IN ('open', 'created', 'deferred')
        ),

        CONSTRAINT FK_CnInvUplInvDbtDouble_DbtTbl FOREIGN KEY (ciudCidut)
            REFERENCES sudz.CnInvDbtUplTbl (cidutKey),
        CONSTRAINT FK_CnInvUplInvDbtDouble_DbtFile FOREIGN KEY (ciudDbtFile)
            REFERENCES sudz.CnInvDbtUplFile (cidufKey)
    );

    CREATE UNIQUE NONCLUSTERED INDEX UX_CnInvUplInvDbtDouble_Cidut
        ON sudz.CnInvUplInvDbtDouble (ciudCidut);

    CREATE NONCLUSTERED INDEX IX_CnInvUplInvDbtDouble_Unload_Status
        ON sudz.CnInvUplInvDbtDouble (ciudUnloadKey, ciudStatus);

    CREATE NONCLUSTERED INDEX IX_CnInvUplInvDbtDouble_DbtFile_Status
        ON sudz.CnInvUplInvDbtDouble (ciudDbtFile, ciudStatus)
        WHERE ciudDbtFile IS NOT NULL;
END
GO
