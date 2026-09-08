/*
 * S77.2 — ослабить запреты формы A на DEV-схеме sudz.
 *
 * Согласовано S77.1 (2026-09-08). Только DEV `sudz`.
 * Не MSSQL2012/, не продуктив, не test_sudz (82/85), не test_sudz_sm.
 *
 * I1: DROP UNIQUE(iddInv, iddDbt) — N слотов одного Dbt на одном СФ.
 * I2: убрать Consistency п.5 (N Value на Dbt×upl; уникальность — слот×upl).
 * I3: п.4 same-ttl — отказ только если sibling принадлежит другому Dbt.
 *
 * Живут: UX_invDbtDbt_Slot, UX_DbtValue_InvDbtUpl, Consistency п.1–3.
 *
 * lastUpdated: 2026-09-08
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;

/* I1: один Dbt может иметь несколько слотов на одном inv */
IF EXISTS (
    SELECT 1
    FROM sys.key_constraints
    WHERE parent_object_id = OBJECT_ID(N'sudz.invDbtDbt')
      AND name = N'UX_invDbtDbt_InvDbt'
)
BEGIN
    ALTER TABLE sudz.invDbtDbt DROP CONSTRAINT UX_invDbtDbt_InvDbt;
    PRINT N'DROP sudz.UX_invDbtDbt_InvDbt';
END
ELSE
    PRINT N'sudz.UX_invDbtDbt_InvDbt already absent';

IF OBJECT_ID(N'sudz.trg_DbtValue_Consistency', N'TR') IS NOT NULL
    DROP TRIGGER sudz.trg_DbtValue_Consistency;

EXEC(N'
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
        RAISERROR(N''DbtValue: cnNum.cnnCn must belong to cnInv for invNum.inInv'', 16, 1);
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
        RAISERROR(N''DbtValue: invDbt.idInv must equal invNum.inInv from dvInvDbtVar'', 16, 1);
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
        RAISERROR(N''DbtValue: missing invDbtDbtVar linking dvInvDbt to dvInvDbtVar'', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- 4) sibling same-ttl: P1-дубль (разные Dbt). Доли одного канона разрешены (S77 I3).
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
          AND NOT EXISTS (
                SELECT 1
                FROM sudz.invDbtDbt AS a
                INNER JOIN sudz.invDbtDbt AS b ON b.iddDbt = a.iddDbt
                WHERE a.iddInvDbt = i.dvInvDbt
                  AND b.iddInvDbt = sib.idKey
            )
    )
    BEGIN
        RAISERROR(N''DbtValue: sibling slot of a different Dbt already has same ttl on this upl (P1)'', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- п.5 (one Value per Dbt@upl) снят: split на одном СФ и merge канонов на разных СФ
    -- дают N строк DbtValue на Dbt×upl. Уникальность — UNIQUE(dvInvDbt, dvUpl).
END
');

PRINT N'S77.2 DRAFT applied on sudz (DEV). UX_invDbtDbt_Slot and UX(dvInvDbt,dvUpl) unchanged.';
