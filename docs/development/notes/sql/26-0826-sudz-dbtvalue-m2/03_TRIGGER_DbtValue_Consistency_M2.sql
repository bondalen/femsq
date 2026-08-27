/*
 * B1 DRAFT — trg_DbtValue_Consistency M2 (08 §4.1 / S71)
 *
 * НЕ ПРИМЕНЯТЬ до гейта B1-prep P9 (GO).
 * Требует: колонка dvInvDbt уже есть (после 01/02).
 *
 * Проверки:
 *   1) cnNum ∈ cnInv для Inv из invNum var
 *   2) invDbt.idInv слота = invNum.inInv из var
 *   3) существует invDbtDbtVar (этот слот ↔ этот var)
 * НЕ требует Dbt / invDbtDbt.
 *
 * lastUpdated: 2026-08-26
 */

SET NOCOUNT ON;
GO

/* ===== sudz ===== */
IF OBJECT_ID(N'sudz.trg_DbtValue_Consistency', N'TR') IS NOT NULL
    DROP TRIGGER sudz.trg_DbtValue_Consistency;
GO

CREATE TRIGGER sudz.trg_DbtValue_Consistency
ON sudz.DbtValue
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) cnNum.cnnCn ∈ cnInv для invNum.inInv
    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN sudz.invDbtVar AS v ON v.idvvKey = i.dvInvDbtVar
        INNER JOIN ags.cnNum AS c ON c.cnnKey = v.idvvCnNum
        INNER JOIN ags.invNum AS n ON n.inKey = v.idvvInvNum
        WHERE NOT EXISTS (
            SELECT 1
            FROM ags.cnInv AS ci
            WHERE ci.ciInv = n.inInv
              AND ci.ciCn = c.cnnCn
        )
    )
    BEGIN
        RAISERROR(N'DbtValue: cnNum.cnnCn must belong to cnInv for invNum.inInv', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- 2) слот и var — одна СФ
    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN sudz.invDbt AS slot ON slot.idKey = i.dvInvDbt
        INNER JOIN sudz.invDbtVar AS v ON v.idvvKey = i.dvInvDbtVar
        INNER JOIN ags.invNum AS n ON n.inKey = v.idvvInvNum
        WHERE slot.idInv <> n.inInv
    )
    BEGIN
        RAISERROR(N'DbtValue: invDbt.idInv must equal invNum.inInv from dvInvDbtVar', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- 3) мост слот↔var
    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        WHERE NOT EXISTS (
            SELECT 1
            FROM sudz.invDbtDbtVar AS bv
            WHERE bv.iddvInvDbt = i.dvInvDbt
              AND bv.iddvInvDbtVar = i.dvInvDbtVar
        )
    )
    BEGIN
        RAISERROR(N'DbtValue: missing invDbtDbtVar linking dvInvDbt to dvInvDbtVar', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

/* ===== test_sudz ===== */
IF OBJECT_ID(N'test_sudz.trg_DbtValue_Consistency', N'TR') IS NOT NULL
    DROP TRIGGER test_sudz.trg_DbtValue_Consistency;
GO

CREATE TRIGGER test_sudz.trg_DbtValue_Consistency
ON test_sudz.DbtValue
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN test_sudz.invDbtVar AS v ON v.idvvKey = i.dvInvDbtVar
        INNER JOIN ags.cnNum AS c ON c.cnnKey = v.idvvCnNum
        INNER JOIN ags.invNum AS n ON n.inKey = v.idvvInvNum
        WHERE NOT EXISTS (
            SELECT 1
            FROM ags.cnInv AS ci
            WHERE ci.ciInv = n.inInv
              AND ci.ciCn = c.cnnCn
        )
    )
    BEGIN
        RAISERROR(N'test_sudz.DbtValue: cnNum.cnnCn must belong to cnInv for invNum.inInv', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN test_sudz.invDbt AS slot ON slot.idKey = i.dvInvDbt
        INNER JOIN test_sudz.invDbtVar AS v ON v.idvvKey = i.dvInvDbtVar
        INNER JOIN ags.invNum AS n ON n.inKey = v.idvvInvNum
        WHERE slot.idInv <> n.inInv
    )
    BEGIN
        RAISERROR(N'test_sudz.DbtValue: invDbt.idInv must equal invNum.inInv from dvInvDbtVar', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        WHERE NOT EXISTS (
            SELECT 1
            FROM test_sudz.invDbtDbtVar AS bv
            WHERE bv.iddvInvDbt = i.dvInvDbt
              AND bv.iddvInvDbtVar = i.dvInvDbtVar
        )
    )
    BEGIN
        RAISERROR(N'test_sudz.DbtValue: missing invDbtDbtVar linking dvInvDbt to dvInvDbtVar', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

SELECT SCHEMA_NAME(o.schema_id) AS sch, t.name AS trigger_name
FROM sys.triggers t
JOIN sys.objects o ON o.object_id = t.parent_id
WHERE t.name = N'trg_DbtValue_Consistency'
ORDER BY sch;
GO
