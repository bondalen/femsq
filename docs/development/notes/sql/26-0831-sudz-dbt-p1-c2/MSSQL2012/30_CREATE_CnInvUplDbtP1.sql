-- =============================================================================
-- C2 / сегм. 35: sudz.CnInvUplDbtP1 — очередь кандидатов P1 (multi-Dbt, путь 2)
-- MSSQL2012 (FishEye prod). Фильтрованные UNIQUE без DROP IF EXISTS.
-- =============================================================================

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'sudz.CnInvUplDbtP1', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.CnInvUplDbtP1
    (
        cip1Key            int            NOT NULL IDENTITY(1, 1),

        cip1UnloadKey      int            NOT NULL,
        cip1BaseUpl        int            NOT NULL,
        cip1DbtFile        int            NULL,

        cip1DbtKey         int            NOT NULL,
        cip1BaseSlotKey    int            NOT NULL,
        cip1BaseIKey       int            NULL,
        cip1BaseCnNum      nvarchar(255)  COLLATE Cyrillic_General_CI_AS NULL,
        cip1BaseInvNum     nvarchar(255)  COLLATE Cyrillic_General_CI_AS NULL,

        cip1MatchSum       decimal(19, 4) NOT NULL,
        cip1SumKind        varchar(8)     NOT NULL,

        cip1CandCidut      int            NULL,
        cip1CandIKey       int            NULL,
        cip1CandCnNum      nvarchar(255)  COLLATE Cyrillic_General_CI_AS NULL,
        cip1CandInvNum     nvarchar(255)  COLLATE Cyrillic_General_CI_AS NULL,
        cip1CandDebt       decimal(19, 4) NULL,

        cip1Reason         varchar(16)    NOT NULL,
        cip1ReasonDetail   nvarchar(max)  NULL,

        cip1Status         varchar(16)    NOT NULL
            CONSTRAINT DF_CnInvUplDbtP1_Status DEFAULT ('open'),
        cip1StatusAt       datetime       NULL,
        cip1LinkedSlotKey  int            NULL,

        CONSTRAINT PK_CnInvUplDbtP1 PRIMARY KEY CLUSTERED (cip1Key),

        CONSTRAINT CK_CnInvUplDbtP1_Status CHECK (
            cip1Status IN ('open', 'linked', 'deferred')
        ),
        CONSTRAINT CK_CnInvUplDbtP1_SumKind CHECK (
            cip1SumKind IN ('ttl', 'overd')
        ),
        CONSTRAINT CK_CnInvUplDbtP1_Reason CHECK (
            cip1Reason IN ('single', 'multi', 'none')
        ),

        CONSTRAINT FK_CnInvUplDbtP1_Dbt FOREIGN KEY (cip1DbtKey)
            REFERENCES sudz.Dbt (dbtKey),
        CONSTRAINT FK_CnInvUplDbtP1_BaseSlot FOREIGN KEY (cip1BaseSlotKey)
            REFERENCES sudz.invDbt (idKey),
        CONSTRAINT FK_CnInvUplDbtP1_CandCidut FOREIGN KEY (cip1CandCidut)
            REFERENCES sudz.CnInvDbtUplTbl (cidutKey),
        CONSTRAINT FK_CnInvUplDbtP1_DbtFile FOREIGN KEY (cip1DbtFile)
            REFERENCES sudz.CnInvDbtUplFile (cidufKey)
    );

    CREATE NONCLUSTERED INDEX IX_CnInvUplDbtP1_Unload_Status
        ON sudz.CnInvUplDbtP1 (cip1UnloadKey, cip1Status);

    CREATE NONCLUSTERED INDEX IX_CnInvUplDbtP1_DbtFile_Status
        ON sudz.CnInvUplDbtP1 (cip1DbtFile, cip1Status)
        WHERE cip1DbtFile IS NOT NULL;

    CREATE UNIQUE NONCLUSTERED INDEX UX_CnInvUplDbtP1_Row
        ON sudz.CnInvUplDbtP1 (cip1UnloadKey, cip1DbtKey, cip1SumKind, cip1CandCidut)
        WHERE cip1CandCidut IS NOT NULL;

    CREATE UNIQUE NONCLUSTERED INDEX UX_CnInvUplDbtP1_None
        ON sudz.CnInvUplDbtP1 (cip1UnloadKey, cip1DbtKey, cip1SumKind)
        WHERE cip1CandCidut IS NULL;
END
GO
