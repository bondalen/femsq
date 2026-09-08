-- =============================================================================
-- Ослабить запреты, мешающие split на одном СФ. Только test_sudz_sm.
-- Снимает: UX (iddInv, iddDbt); п.4 и п.5 триггера DbtValue.
-- Оставляет: UNIQUE слота, UNIQUE(slot,upl), iddInv=idInv, мост var.
-- =============================================================================

SET NOCOUNT ON;

IF EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE parent_object_id = OBJECT_ID(N'test_sudz_sm.invDbtDbt')
      AND name = N'UX_sm_idd_InvDbt'
)
    ALTER TABLE test_sudz_sm.invDbtDbt DROP CONSTRAINT UX_sm_idd_InvDbt;
GO

IF OBJECT_ID(N'test_sudz_sm.trg_DbtValue_Consistency', N'TR') IS NOT NULL
    DROP TRIGGER test_sudz_sm.trg_DbtValue_Consistency;
GO

CREATE TRIGGER test_sudz_sm.trg_DbtValue_Consistency
ON test_sudz_sm.DbtValue
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN test_sudz_sm.invDbt AS slot ON slot.idKey = i.dvInvDbt
        INNER JOIN test_sudz_sm.invDbtVar AS v ON v.idvvKey = i.dvInvDbtVar
        INNER JOIN test_sudz_sm.invNum AS n ON n.inKey = v.idvvInvNum
        WHERE slot.idInv <> n.inInv
    )
    BEGIN
        RAISERROR(N'DbtValue: invDbt.idInv must equal invNum.inInv', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        WHERE NOT EXISTS (
            SELECT 1
            FROM test_sudz_sm.invDbtDbtVar AS bv
            WHERE bv.iddvInvDbt = i.dvInvDbt
              AND bv.iddvInvDbtVar = i.dvInvDbtVar
        )
    )
    BEGIN
        RAISERROR(N'DbtValue: missing invDbtDbtVar', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

UPDATE test_sudz_sm.lab_state
SET labMode = N'relaxed',
    labNote = N'сняты UX(inv,dbt) и Consistency п.4–5'
WHERE labKey = 1;

INSERT INTO test_sudz_sm.lab_event (evScript, evOk, evMsg)
VALUES (N'04_RELAX', 1, N'relaxed split constraints');
GO
