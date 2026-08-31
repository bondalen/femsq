/*
 * I2/I3/I5 — согласованность DbtSlotLink и invDbtDbt; блок прямого CRUD grouped slots.
 * lastUpdated: 2026-08-31
 */
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'sudz.trg_DbtSlotLinkMember_ActiveUnique', N'TR') IS NOT NULL
    DROP TRIGGER sudz.trg_DbtSlotLinkMember_ActiveUnique;
GO

CREATE TRIGGER sudz.trg_DbtSlotLinkMember_ActiveUnique
ON sudz.DbtSlotLinkMember
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN sudz.DbtSlotLinkGroup AS g ON g.lid = i.lid AND g.dslgStatus = N'active'
        INNER JOIN sudz.DbtSlotLinkMember AS m
            ON m.iKey = i.iKey AND m.idNum = i.idNum AND m.lid <> i.lid
        INNER JOIN sudz.DbtSlotLinkGroup AS g2 ON g2.lid = m.lid AND g2.dslgStatus = N'active'
    )
    BEGIN
        RAISERROR(N'DbtSlotLinkMember: slot already in another active group', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

IF OBJECT_ID(N'sudz.trg_invDbtDbt_GroupConsistency', N'TR') IS NOT NULL
    DROP TRIGGER sudz.trg_invDbtDbt_GroupConsistency;
GO

CREATE TRIGGER sudz.trg_invDbtDbt_GroupConsistency
ON sudz.invDbtDbt
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN sudz.invDbt AS s ON s.idKey = i.iddInvDbt
        INNER JOIN sudz.DbtSlotLinkMember AS m ON m.iKey = s.idInv AND m.idNum = s.idNum
        INNER JOIN sudz.DbtSlotLinkGroup AS g ON g.lid = m.lid AND g.dslgStatus = N'active'
        WHERE g.canonicalDbtKey IS NOT NULL
          AND i.iddDbt <> g.canonicalDbtKey
    )
    BEGIN
        RAISERROR(
            N'invDbtDbt: slot in active DbtSlotLink group must use canonicalDbtKey (use rebind service / ApplyDbtSlotLinks)',
            16,
            1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN sudz.invDbt AS s ON s.idKey = i.iddInvDbt
        INNER JOIN sudz.DbtSlotLinkMember AS m ON m.iKey = s.idInv AND m.idNum = s.idNum
        INNER JOIN sudz.DbtSlotLinkGroup AS g ON g.lid = m.lid AND g.dslgStatus = N'active'
        GROUP BY g.lid, i.iddDbt
        HAVING COUNT(DISTINCT i.iddDbt) > 1
           OR (MAX(g.canonicalDbtKey) IS NOT NULL AND MAX(g.canonicalDbtKey) <> MIN(i.iddDbt))
    )
    BEGIN
        RAISERROR(N'invDbtDbt: active group members must share one Dbt', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO
