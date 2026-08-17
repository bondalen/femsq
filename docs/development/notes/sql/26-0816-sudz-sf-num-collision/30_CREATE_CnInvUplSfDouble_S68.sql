-- =============================================================================
-- S68: sudz.CnInvUplSfDouble — общая очередь СФ с совпадающими номерами
-- DEV (SQL Server 2022 Docker). ags.* не изменяет.
-- Статус: ПРОЕКТ — применять после согласия владельца.
-- См. README.md в этой папке.
-- =============================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'sudz.CnInvUplSfDouble', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.CnInvUplSfDouble
    (
        ciusKey            int            NOT NULL IDENTITY(1, 1),

        -- Ровно один FK на строку Excel-staging (долги XOR платежи)
        ciusCidut          int            NULL,  -- → sudz.CnInvDbtUplTbl.cidutKey
        ciusCiput          int            NULL,  -- → sudz.CnInvPmtUplTbl.ciputKey

        -- Контекст лаунчера / выгрузки (денормализация для грида и фильтра)
        ciusDbtFile        int            NULL,  -- → sudz.CnInvDbtUplFile.cidufKey
        ciusPmtFile        int            NULL,  -- → sudz.CnInvPmtUplFile.cipufKey
        ciusUnloadKey      int            NULL,  -- upl_key / cn_inv_pm_key

        -- Опциональная связь с буфером «новые СФ» воронки
        ciusDbtTblCnInvRow int            NULL,  -- → sudz.CnInvDbtUplTblCnInv.cidutciRow
        ciusPmtTblCnInvRow int            NULL,  -- → sudz.CnInvPmtUplTblCnInv.ciputciRow

        -- Денормализация для списка (как Access InvDouble / TblCnInv)
        ciusCnKey          int            NULL,
        ciusCnNum          nvarchar(255)  COLLATE Cyrillic_General_CI_AS NULL,
        ciusInvNum         nvarchar(255)  COLLATE Cyrillic_General_CI_AS NULL,
        ciusInvNumCount    int            NULL,  -- сколько inv с этим номером в ags (не Text)

        -- Разбор оператором до следующего прогона загрузки
        -- open | created | deferred
        ciusStatus         varchar(16)    NOT NULL
            CONSTRAINT DF_CnInvUplSfDouble_Status DEFAULT ('open'),
        ciusStatusAt       datetime       NULL,
        ciusCreatedInvKey  int            NULL,  -- ags.inv.iKey после «Создать СФ»

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
        -- FK на TblCnInv / inv — намеренно без: буфер эфемерен, inv на ags
    );

    -- Одна строка очереди на одну строку Excel
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

-- VERIFY
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = N'sudz' AND t.name = N'CnInvUplSfDouble';
GO

SELECT c.name AS column_name, ty.name AS type_name, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'sudz.CnInvUplSfDouble')
ORDER BY c.column_id;
GO
