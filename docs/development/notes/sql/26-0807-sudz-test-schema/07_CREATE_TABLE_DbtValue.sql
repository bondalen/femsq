-- =============================================================================
-- test_sudz.DbtValue — величина долга в выгрузке (песочница СУДЗ)
-- DEV only. Спецификация: 08-target-schema.md §2.5 / §4.1
-- =============================================================================

IF OBJECT_ID(N'test_sudz.DbtValue', N'U') IS NULL
BEGIN
    CREATE TABLE test_sudz.DbtValue
    (
        dvKey           int            NOT NULL IDENTITY(1, 1),
        dvDbt           int            NOT NULL,
        dvInvDbtVar     int            NOT NULL,
        dvUpl           int            NOT NULL,
        dvTtl           money          NOT NULL,
        dvOverd         money          NOT NULL,
        dvDateStart     date           NULL,
        dvDateMaturity  date           NULL,
        dvDocBase       nvarchar(255)  NULL,
        dvTimeOfEntry   datetime       NOT NULL
            CONSTRAINT DF_DbtValue_dvTimeOfEntry DEFAULT (getdate()),

        CONSTRAINT PK_DbtValue PRIMARY KEY CLUSTERED (dvKey),
        CONSTRAINT UX_DbtValue_DbtUpl UNIQUE (dvDbt, dvUpl),

        CONSTRAINT FK_DbtValue_Dbt FOREIGN KEY (dvDbt)
            REFERENCES test_sudz.Dbt (dbtKey),
        CONSTRAINT FK_DbtValue_invDbtVar FOREIGN KEY (dvInvDbtVar)
            REFERENCES test_sudz.invDbtVar (idvvKey),
        CONSTRAINT FK_DbtValue_upl FOREIGN KEY (dvUpl)
            REFERENCES ags.cn_inv_dbt_upl (upl_key)
    );

    CREATE NONCLUSTERED INDEX IX_DbtValue_Upl
        ON test_sudz.DbtValue (dvUpl);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.extended_properties ep
    WHERE ep.major_id = OBJECT_ID(N'test_sudz.DbtValue')
      AND ep.minor_id = 0
      AND ep.name = N'MS_Description'
)
BEGIN
    EXEC sys.sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'СУДЗ песочница: величина долга в выгрузке. Контекст только через invDbtVar. UNIQUE(dbt,upl).',
        @level0type = N'SCHEMA', @level0name = N'test_sudz',
        @level1type = N'TABLE',  @level1name = N'DbtValue';
END
GO

IF OBJECT_ID(N'test_sudz.trg_DbtValue_Consistency', N'TR') IS NOT NULL
    DROP TRIGGER test_sudz.trg_DbtValue_Consistency;
GO

CREATE TRIGGER test_sudz.trg_DbtValue_Consistency
ON test_sudz.DbtValue
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) cnNum договора из контекста ∈ cnInv для Inv из invNum контекста
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN test_sudz.invDbtVar v ON v.idvvKey = i.dvInvDbtVar
        INNER JOIN ags.cnNum c ON c.cnnKey = v.idvvCnNum
        INNER JOIN ags.invNum n ON n.inKey = v.idvvInvNum
        WHERE NOT EXISTS (
            SELECT 1
            FROM ags.cnInv ci
            WHERE ci.ciInv = n.inInv
              AND ci.ciCn = c.cnnCn
        )
    )
    BEGIN
        RAISERROR(N'DbtValue: cnNum.cnnCn must belong to cnInv for invNum.inInv', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- 2) существует invDbtDbt (iddInv = invNum.inInv, iddDbt = dvDbt)
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN test_sudz.invDbtVar v ON v.idvvKey = i.dvInvDbtVar
        INNER JOIN ags.invNum n ON n.inKey = v.idvvInvNum
        WHERE NOT EXISTS (
            SELECT 1
            FROM test_sudz.invDbtDbt b
            WHERE b.iddInv = n.inInv
              AND b.iddDbt = i.dvDbt
        )
    )
    BEGIN
        RAISERROR(N'DbtValue: missing invDbtDbt for (inv from invDbtVar, dvDbt)', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- 3) существует invDbtDbtVar: слот из invDbtDbt связан с этим invDbtVar (S5)
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN test_sudz.invDbtVar v ON v.idvvKey = i.dvInvDbtVar
        INNER JOIN ags.invNum n ON n.inKey = v.idvvInvNum
        INNER JOIN test_sudz.invDbtDbt b
            ON b.iddInv = n.inInv
           AND b.iddDbt = i.dvDbt
        WHERE NOT EXISTS (
            SELECT 1
            FROM test_sudz.invDbtDbtVar bv
            WHERE bv.iddvInvDbt = b.iddInvDbt
              AND bv.iddvInvDbtVar = i.dvInvDbtVar
        )
    )
    BEGIN
        RAISERROR(N'DbtValue: missing invDbtDbtVar linking invDbt slot to invDbtVar', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

SELECT c.name AS column_name, ty.name AS type_name, c.is_nullable, c.is_identity
FROM sys.columns c
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'test_sudz.DbtValue')
ORDER BY c.column_id;

SELECT tr.name AS trigger_name
FROM sys.triggers tr
WHERE tr.parent_id = OBJECT_ID(N'test_sudz.DbtValue');
GO
