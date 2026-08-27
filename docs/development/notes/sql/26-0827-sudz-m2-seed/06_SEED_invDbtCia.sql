/*
 * M2 — мост sudz.invDbtCia: каждая cia → слот зерна (не энтропийный sibling)
 * lastUpdated: 2026-08-27
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF EXISTS (SELECT 1 FROM sudz.invDbtCia)
BEGIN
    RAISERROR(N'invDbtCia not empty — CLEAR first', 16, 1);
    RETURN;
END
GO

;WITH raw AS (
    SELECT
        a.ciaKey,
        ci.ciInv AS iKey,
        LTRIM(RTRIM(a.ciaName)) AS ciaNameRaw,
        CASE
            WHEN a.ciaName IS NULL OR LTRIM(RTRIM(a.ciaName)) = N'' THEN 1
            ELSE 0
        END AS is_unnamed,
        TRY_CAST(LTRIM(RTRIM(a.ciaName)) AS int) AS name_int
    FROM ags.cnInvAccnt AS a
    INNER JOIN ags.cnInvAccntSmpl AS s ON a.ciaCnInvAccntSmpl = s.ciasKey
    INNER JOIN ags.cnInv AS ci ON s.ciasCnInv = ci.ciKey
),
claimed AS (
    SELECT DISTINCT iKey, CAST(0 AS tinyint) AS idNum FROM raw WHERE is_unnamed = 1
    UNION
    SELECT DISTINCT iKey, CAST(name_int AS tinyint)
    FROM raw
    WHERE name_int IS NOT NULL AND name_int BETWEEN 0 AND 255
),
per_cia AS (
    SELECT
        r.ciaKey,
        r.iKey,
        CASE
            WHEN r.is_unnamed = 1 THEN CAST(0 AS tinyint)
            WHEN r.name_int IS NOT NULL AND r.name_int BETWEEN 0 AND 255
                THEN CAST(r.name_int AS tinyint)
            WHEN r.ciaNameRaw = N'первая'
                 AND NOT EXISTS (SELECT 1 FROM claimed c WHERE c.iKey = r.iKey AND c.idNum = 1)
                THEN CAST(1 AS tinyint)
            WHEN r.ciaNameRaw = N'вторая'
                 AND NOT EXISTS (SELECT 1 FROM claimed c WHERE c.iKey = r.iKey AND c.idNum = 2)
                THEN CAST(2 AS tinyint)
            ELSE NULL
        END AS idNum_pref,
        CASE
            WHEN r.is_unnamed = 1 THEN N'NullИлиПусто'
            ELSE r.ciaNameRaw
        END AS ciaNameNull
    FROM raw AS r
),
need_rank AS (
    SELECT
        p.ciaKey,
        p.iKey,
        p.ciaNameNull,
        CAST(
            199 + DENSE_RANK() OVER (
                PARTITION BY p.iKey
                ORDER BY p.ciaNameNull
            ) AS tinyint
        ) AS idNum
    FROM per_cia AS p
    WHERE p.idNum_pref IS NULL
),
final AS (
    SELECT ciaKey, iKey, idNum_pref AS idNum FROM per_cia WHERE idNum_pref IS NOT NULL
    UNION ALL
    SELECT ciaKey, iKey, idNum FROM need_rank
)
INSERT INTO sudz.invDbtCia (idcInvDbt, idcCia, idcTimeOfEntry)
SELECT d.idKey, f.ciaKey, GETDATE()
FROM final AS f
INNER JOIN sudz.invDbt AS d
    ON d.idInv = f.iKey AND d.idNum = f.idNum
   AND ISNULL(d.idNote, N'') NOT IN (N'S73-split', N'S73-quarter');

DECLARE @cia int = (SELECT COUNT(*) FROM ags.cnInvAccnt);
DECLARE @map int = (SELECT COUNT(*) FROM sudz.invDbtCia);
PRINT CONCAT(N'invDbtCia=', @map, N' / cia=', @cia);
IF @map <> @cia
    RAISERROR(N'Bridge incomplete: mapped %d of %d cia', 16, 1, @map, @cia);
GO
