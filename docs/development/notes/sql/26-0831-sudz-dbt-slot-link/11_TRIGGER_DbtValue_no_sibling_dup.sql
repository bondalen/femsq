/*
 * A1 — защита от sibling duplicate DbtValue (P1 / S76-A.1).
 *
 * Дополняет trg_DbtValue_Consistency (M2):
 *   4) same-ttl sibling: на dvUpl не более одного Value на sibling-слотах
 *      одного idInv с |ttl1−ttl2| ≤ 0.01
 *   5) one-per-Dbt@upl: через invDbtDbt — не более одного Value на iddDbt@upl
 *
 * Порядок: после 03_TRIGGER (M2) / trg_DbtValue_Consistency.
 * lastUpdated: 2026-09-01
 */

SET NOCOUNT ON;
GO

/* ===== sudz: расширение Consistency ===== */
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

    -- 4) A1: sibling same-ttl на одной выгрузке
    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN sudz.invDbt AS slot ON slot.idKey = i.dvInvDbt
        INNER JOIN sudz.invDbt AS sib ON sib.idInv = slot.idInv AND sib.idKey <> slot.idKey
        INNER JOIN sudz.DbtValue AS dv2
            ON dv2.dvInvDbt = sib.idKey
           AND dv2.dvUpl = i.dvUpl
           AND dv2.dvKey <> i.dvKey
        WHERE ABS(CAST(i.dvTtl AS decimal(19, 4)) - CAST(dv2.dvTtl AS decimal(19, 4)))
              <= CAST(0.01 AS decimal(19, 4))
    )
    BEGIN
        RAISERROR(N'DbtValue: sibling slot already has same ttl on this upl (P1)', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- 5) one Value per Dbt@upl (через invDbtDbt; L* canonical)
    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN sudz.invDbtDbt AS idd ON idd.iddInvDbt = i.dvInvDbt
        INNER JOIN sudz.DbtValue AS dv2
            ON dv2.dvUpl = i.dvUpl
           AND dv2.dvKey <> i.dvKey
        INNER JOIN sudz.invDbtDbt AS idd2 ON idd2.iddInvDbt = dv2.dvInvDbt
        WHERE idd2.iddDbt = idd.iddDbt
    )
    BEGIN
        RAISERROR(N'DbtValue: another slot already has Value for this Dbt on upl', 16, 1);
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

    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN test_sudz.invDbt AS slot ON slot.idKey = i.dvInvDbt
        INNER JOIN test_sudz.invDbt AS sib ON sib.idInv = slot.idInv AND sib.idKey <> slot.idKey
        INNER JOIN test_sudz.DbtValue AS dv2
            ON dv2.dvInvDbt = sib.idKey
           AND dv2.dvUpl = i.dvUpl
           AND dv2.dvKey <> i.dvKey
        WHERE ABS(CAST(i.dvTtl AS decimal(19, 4)) - CAST(dv2.dvTtl AS decimal(19, 4)))
              <= CAST(0.01 AS decimal(19, 4))
    )
    BEGIN
        RAISERROR(N'test_sudz.DbtValue: sibling slot already has same ttl on this upl (P1)', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN test_sudz.invDbtDbt AS idd ON idd.iddInvDbt = i.dvInvDbt
        INNER JOIN test_sudz.DbtValue AS dv2
            ON dv2.dvUpl = i.dvUpl
           AND dv2.dvKey <> i.dvKey
        INNER JOIN test_sudz.invDbtDbt AS idd2 ON idd2.iddInvDbt = dv2.dvInvDbt
        WHERE idd2.iddDbt = idd.iddDbt
    )
    BEGIN
        RAISERROR(N'test_sudz.DbtValue: another slot already has Value for this Dbt on upl', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

SELECT SCHEMA_NAME(o.schema_id) AS sch, t.name AS trigger_name, t.is_disabled
FROM sys.triggers t
JOIN sys.objects o ON o.object_id = t.parent_id
WHERE t.name = N'trg_DbtValue_Consistency'
ORDER BY sch;
GO
