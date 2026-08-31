/*
 * ApplyDbtSlotLinks — canonicalDbtKey + sync invDbtDbt (идемпотентно).
 * lastUpdated: 2026-08-31
 */
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'sudz.ApplyDbtSlotLinks', N'P') IS NOT NULL
    DROP PROCEDURE sudz.ApplyDbtSlotLinks;
GO

CREATE PROCEDURE sudz.ApplyDbtSlotLinks
    @lid nvarchar(16) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF EXISTS (
        SELECT 1
        FROM sudz.DbtSlotLinkGroup AS g
        INNER JOIN sudz.DbtSlotLinkMember AS m ON m.lid = g.lid
        LEFT JOIN sudz.invDbt AS s ON s.idInv = m.iKey AND s.idNum = m.idNum
        LEFT JOIN sudz.invDbtDbt AS b ON b.iddInvDbt = s.idKey
        WHERE g.dslgStatus IN (N'pending', N'active')
          AND (@lid IS NULL OR g.lid = @lid)
          AND (s.idKey IS NULL OR b.iddKey IS NULL)
    )
    BEGIN
        RAISERROR(N'ApplyDbtSlotLinks: member without invDbt slot or invDbtDbt bridge', 16, 1);
        RETURN;
    END;

    DECLARE @work TABLE (
        lid nvarchar(16) NOT NULL PRIMARY KEY,
        canonicalDbtKey int NOT NULL,
        canonicalRule nvarchar(32) NOT NULL
    );

    ;WITH groups AS (
        SELECT g.lid
        FROM sudz.DbtSlotLinkGroup AS g
        WHERE g.dslgStatus IN (N'pending', N'active')
          AND (@lid IS NULL OR g.lid = @lid)
    ),
    members AS (
        SELECT g.lid, s.idKey AS slotKey, m.iKey, m.idNum, b.iddDbt AS dbtKey
        FROM groups AS g
        INNER JOIN sudz.DbtSlotLinkMember AS m ON m.lid = g.lid
        INNER JOIN sudz.invDbt AS s ON s.idInv = m.iKey AND s.idNum = m.idNum
        INNER JOIN sudz.invDbtDbt AS b ON b.iddInvDbt = s.idKey
    ),
    scored AS (
        SELECT
            m.lid,
            m.slotKey,
            m.dbtKey,
            m.iKey,
            m.idNum,
            MIN(COALESCE(u.uplStatusOnDate, u.upl_date)) AS firstAsOf
        FROM members AS m
        LEFT JOIN sudz.DbtValue AS dv ON dv.dvInvDbt = m.slotKey
        LEFT JOIN ags.cn_inv_dbt_upl AS u ON u.upl_key = dv.dvUpl
        GROUP BY m.lid, m.slotKey, m.dbtKey, m.iKey, m.idNum
    ),
    ranked AS (
        SELECT
            s.lid,
            s.dbtKey,
            s.firstAsOf,
            ROW_NUMBER() OVER (
                PARTITION BY s.lid
                ORDER BY
                    CASE WHEN s.firstAsOf IS NULL THEN 1 ELSE 0 END,
                    s.firstAsOf,
                    s.dbtKey,
                    s.iKey,
                    s.idNum
            ) AS rn,
            MIN(s.firstAsOf) OVER (PARTITION BY s.lid) AS minAsOf
        FROM scored AS s
    )
    INSERT INTO @work (lid, canonicalDbtKey, canonicalRule)
    SELECT
        r.lid,
        r.dbtKey,
        CASE WHEN r.minAsOf IS NOT NULL THEN N'earliest-value' ELSE N'min-dbtKey' END
    FROM ranked AS r
    WHERE r.rn = 1;

    IF NOT EXISTS (SELECT 1 FROM @work)
    BEGIN
        RAISERROR(N'ApplyDbtSlotLinks: no groups to apply', 16, 1);
        RETURN;
    END;

    DECLARE @orphans TABLE (dbtKey int NOT NULL PRIMARY KEY);

    BEGIN TRANSACTION;

    UPDATE g
    SET
        g.canonicalDbtKey = w.canonicalDbtKey,
        g.canonicalRule = w.canonicalRule,
        g.canonicalSetAt = GETDATE(),
        g.dslgStatus = N'active'
    FROM sudz.DbtSlotLinkGroup AS g
    INNER JOIN @work AS w ON w.lid = g.lid;

    UPDATE b
    SET b.iddDbt = g.canonicalDbtKey
    OUTPUT deleted.iddDbt INTO @orphans(dbtKey)
    FROM sudz.invDbtDbt AS b
    INNER JOIN sudz.invDbt AS s ON s.idKey = b.iddInvDbt
    INNER JOIN sudz.DbtSlotLinkMember AS m ON m.iKey = s.idInv AND m.idNum = s.idNum
    INNER JOIN sudz.DbtSlotLinkGroup AS g ON g.lid = m.lid AND g.dslgStatus = N'active'
    INNER JOIN @work AS w ON w.lid = g.lid
    WHERE b.iddDbt <> g.canonicalDbtKey;

    DELETE d
    FROM sudz.Dbt AS d
    INNER JOIN @orphans AS o ON o.dbtKey = d.dbtKey
    WHERE NOT EXISTS (SELECT 1 FROM sudz.invDbtDbt AS x WHERE x.iddDbt = d.dbtKey);

    UPDATE d
    SET d.dbtNote = N'Rslt-' + g.lid
    FROM sudz.Dbt AS d
    INNER JOIN sudz.DbtSlotLinkGroup AS g ON g.canonicalDbtKey = d.dbtKey AND g.dslgStatus = N'active'
    INNER JOIN @work AS w ON w.lid = g.lid;

    COMMIT TRANSACTION;

    SELECT w.lid, w.canonicalDbtKey, w.canonicalRule, g.dslgStatus
    FROM @work AS w
    INNER JOIN sudz.DbtSlotLinkGroup AS g ON g.lid = w.lid
    ORDER BY w.lid;
END
GO
