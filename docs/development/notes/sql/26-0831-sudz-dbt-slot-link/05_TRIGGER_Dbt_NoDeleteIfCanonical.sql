/*
 * I4 — запрет DELETE Dbt, если он canonical active-группы L*.
 * lastUpdated: 2026-08-31
 */
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'sudz.trg_Dbt_NoDeleteIfCanonical', N'TR') IS NOT NULL
    DROP TRIGGER sudz.trg_Dbt_NoDeleteIfCanonical;
GO

CREATE TRIGGER sudz.trg_Dbt_NoDeleteIfCanonical
ON sudz.Dbt
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM deleted AS d
        INNER JOIN sudz.DbtSlotLinkGroup AS g
            ON g.canonicalDbtKey = d.dbtKey AND g.dslgStatus = N'active'
    )
    BEGIN
        RAISERROR(N'Dbt: cannot delete canonical Dbt of active DbtSlotLink group', 16, 1);
        RETURN;
    END;

    DELETE d
    FROM sudz.Dbt AS d
    INNER JOIN deleted AS x ON x.dbtKey = d.dbtKey;
END;
GO
