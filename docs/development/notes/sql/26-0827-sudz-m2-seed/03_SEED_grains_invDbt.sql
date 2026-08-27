/*
 * M2 — seed invDbt по зерну S73 (iKey, ciaNameNull) ≈ 11 897
 * idNum: 0=unnamed; numeric ciaName; первая/вторая→1/2; иначе 200+rank
 * lastUpdated: 2026-08-27
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF EXISTS (SELECT 1 FROM sudz.invDbt)
BEGIN
    RAISERROR(N'sudz.invDbt not empty — run 02_CLEAR first', 16, 1);
    RETURN;
END
GO

;WITH raw AS (
    SELECT
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
grains AS (
    SELECT DISTINCT
        iKey,
        CASE WHEN is_unnamed = 1 THEN N'NullИлиПусто' ELSE ciaNameRaw END AS ciaNameNull,
        is_unnamed,
        name_int,
        CASE
            WHEN is_unnamed = 1 THEN N'__unnamed__'
            WHEN name_int IS NOT NULL THEN N'__num__'
            WHEN ciaNameRaw IN (N'первая', N'первая ') THEN N'первая'
            WHEN ciaNameRaw IN (N'вторая', N'вторая ') THEN N'вторая'
            ELSE ciaNameRaw
        END AS name_class
    FROM raw
),
/* numeric / unnamed claimed idNums per iKey */
claimed AS (
    SELECT iKey, CAST(0 AS tinyint) AS idNum FROM grains WHERE is_unnamed = 1
    UNION
    SELECT iKey, CAST(name_int AS tinyint)
    FROM grains
    WHERE name_int IS NOT NULL AND name_int BETWEEN 0 AND 255
),
mapped AS (
    SELECT
        g.iKey,
        g.ciaNameNull,
        g.is_unnamed,
        g.name_int,
        g.name_class,
        CASE
            WHEN g.is_unnamed = 1 THEN CAST(0 AS tinyint)
            WHEN g.name_int IS NOT NULL AND g.name_int BETWEEN 0 AND 255
                THEN CAST(g.name_int AS tinyint)
            WHEN g.name_class = N'первая'
                 AND NOT EXISTS (SELECT 1 FROM claimed c WHERE c.iKey = g.iKey AND c.idNum = 1)
                THEN CAST(1 AS tinyint)
            WHEN g.name_class = N'вторая'
                 AND NOT EXISTS (SELECT 1 FROM claimed c WHERE c.iKey = g.iKey AND c.idNum = 2)
                THEN CAST(2 AS tinyint)
            ELSE NULL
        END AS idNum_pref
    FROM grains AS g
),
need_rank AS (
    SELECT
        m.*,
        CAST(
            199 + DENSE_RANK() OVER (
                PARTITION BY m.iKey
                ORDER BY m.ciaNameNull
            ) AS tinyint
        ) AS idNum_ranked
    FROM mapped AS m
    WHERE m.idNum_pref IS NULL
),
final AS (
    SELECT iKey, ciaNameNull, idNum_pref AS idNum FROM mapped WHERE idNum_pref IS NOT NULL
    UNION ALL
    SELECT iKey, ciaNameNull, idNum_ranked FROM need_rank
)
INSERT INTO sudz.invDbt (idInv, idNum, idNote, idTimeOfEntry)
SELECT
    f.iKey,
    f.idNum,
    CASE WHEN f.ciaNameNull = N'NullИлиПусто' THEN NULL ELSE LEFT(N'ciaName=' + f.ciaNameNull, 255) END,
    GETDATE()
FROM final AS f
ORDER BY f.iKey, f.idNum;

DECLARE @n int = (SELECT COUNT(*) FROM sudz.invDbt);
PRINT CONCAT(N'invDbt grains inserted: ', @n);
IF @n <> 11897
    RAISERROR(N'Expected 11897 grain slots, got %d', 16, 1, @n);
GO
