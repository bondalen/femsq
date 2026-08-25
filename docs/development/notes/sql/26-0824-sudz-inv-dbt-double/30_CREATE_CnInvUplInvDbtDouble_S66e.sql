-- =============================================================================
-- S66e: sudz.CnInvUplInvDbtDouble — очередь разбора двоящих задолженностей СФ
-- DEV (SQL Server 2022 Docker). ags.* не изменяет.
-- Зеркало паттерна CnInvUplSfDouble (S68); префикс ciud*.
-- =============================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'sudz.CnInvUplInvDbtDouble', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.CnInvUplInvDbtDouble
    (
        ciudKey            int            NOT NULL IDENTITY(1, 1),

        ciudCidut          int            NOT NULL,  -- → sudz.CnInvDbtUplTbl.cidutKey
        ciudDbtFile        int            NULL,      -- → sudz.CnInvDbtUplFile.cidufKey
        ciudUnloadKey      int            NOT NULL,  -- upl_key

        ciudIKey           int            NULL,      -- ags.inv.iKey
        ciudCnNum          nvarchar(255)  COLLATE Cyrillic_General_CI_AS NULL,
        ciudInvNum         nvarchar(255)  COLLATE Cyrillic_General_CI_AS NULL,
        ciudDebt           decimal(18, 2) NULL,
        ciudIdvvKey        int            NULL,      -- sudz.invDbtVar.idvvKey (если известен)
        ciudReason         nvarchar(64)   NULL,      -- multi | ambiguous | sum

        -- open | created | deferred
        ciudStatus         varchar(16)    NOT NULL
            CONSTRAINT DF_CnInvUplInvDbtDouble_Status DEFAULT ('open'),
        ciudStatusAt       datetime       NULL,
        ciudCreatedIdKey   int            NULL,      -- sudz.invDbt.idKey после create

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

-- VERIFY
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = N'sudz' AND t.name = N'CnInvUplInvDbtDouble';
GO

SELECT c.name AS column_name, ty.name AS type_name, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'sudz.CnInvUplInvDbtDouble')
ORDER BY c.column_id;
GO
