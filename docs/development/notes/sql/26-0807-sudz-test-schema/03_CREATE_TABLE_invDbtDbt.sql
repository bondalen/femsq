-- =============================================================================
-- test_sudz.invDbtDbt — мост Inv ↔ Dbt через слот invDbt (песочница СУДЗ)
-- DEV only. Спецификация: 08-target-schema.md §2.2 (S35: FK на invDbt.idKey)
-- Требует: test_sudz.Dbt, test_sudz.invDbt (с суррогатным PK)
-- =============================================================================

IF OBJECT_ID(N'test_sudz.invDbtDbt', N'U') IS NULL
BEGIN
    CREATE TABLE test_sudz.invDbtDbt
    (
        iddKey          int         NOT NULL IDENTITY(1, 1),
        iddInv          int         NOT NULL,
        iddDbt          int         NOT NULL,
        iddInvDbt       int         NOT NULL,
        iddTimeOfEntry  datetime    NOT NULL
            CONSTRAINT DF_invDbtDbt_iddTimeOfEntry DEFAULT (getdate()),

        CONSTRAINT PK_invDbtDbt PRIMARY KEY CLUSTERED (iddKey),
        CONSTRAINT UX_invDbtDbt_InvDbt UNIQUE (iddInv, iddDbt),
        CONSTRAINT UX_invDbtDbt_Slot UNIQUE (iddInvDbt),

        CONSTRAINT FK_invDbtDbt_inv FOREIGN KEY (iddInv)
            REFERENCES ags.inv (iKey),
        CONSTRAINT FK_invDbtDbt_Dbt FOREIGN KEY (iddDbt)
            REFERENCES test_sudz.Dbt (dbtKey),
        CONSTRAINT FK_invDbtDbt_invDbt FOREIGN KEY (iddInvDbt)
            REFERENCES test_sudz.invDbt (idKey)
    );
END
GO

IF OBJECT_ID(N'test_sudz.trg_invDbtDbt_InvMatchesSlot', N'TR') IS NULL
BEGIN
    EXEC(N'
    CREATE TRIGGER test_sudz.trg_invDbtDbt_InvMatchesSlot
    ON test_sudz.invDbtDbt
    AFTER INSERT, UPDATE
    AS
    BEGIN
        SET NOCOUNT ON;
        IF EXISTS (
            SELECT 1
            FROM inserted i
            INNER JOIN test_sudz.invDbt s ON s.idKey = i.iddInvDbt
            WHERE s.idInv <> i.iddInv
        )
        BEGIN
            RAISERROR(N''invDbtDbt: iddInv must equal invDbt.idInv for iddInvDbt'', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
    END
    ');
END
GO
