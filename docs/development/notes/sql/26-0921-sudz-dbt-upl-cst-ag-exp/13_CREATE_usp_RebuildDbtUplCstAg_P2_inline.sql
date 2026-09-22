-- P2 DEV: A/B g_p + inline 1.3 (year→all) + C residual — NO Exp dependency
-- Generated 2026-09-22 from 12_..._P2.sql (promote) → inline
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'sudz.usp_RebuildDbtUplCstAg', N'P') IS NOT NULL
    DROP PROCEDURE sudz.usp_RebuildDbtUplCstAg;
GO

CREATE PROCEDURE sudz.usp_RebuildDbtUplCstAg
    @dbtUpl int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @dbtUpl IS NULL OR @dbtUpl <= 0
    BEGIN
        RAISERROR(N'usp_RebuildDbtUplCstAg: @dbtUpl must be positive', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM sudz.cn_inv_dbt_upl WHERE upl_key = @dbtUpl)
    BEGIN
        RAISERROR(N'usp_RebuildDbtUplCstAg: dbt upl not found', 16, 1);
        RETURN;
    END;

    /* Без g_p канон P1 не питается — не затирать бэкфилл (S80 @901). */
    IF NOT EXISTS (
        SELECT 1 FROM sudz.cn_inv_dbt_upl_g_p WHERE cn_inv_dbt_upl = @dbtUpl
    )
    BEGIN
        SELECT
            0 AS deletedCnt,
            (SELECT COUNT(*) FROM sudz.DbtUplCstAg WHERE ducaUpl = @dbtUpl AND ducaCstAgPn IS NOT NULL) AS cntA,
            (SELECT COUNT(*) FROM sudz.DbtUplCstAg
             WHERE ducaUpl = @dbtUpl AND ducaCstAgPn IS NULL AND ducaCode LIKE N'кодов -%') AS cntB,
            (SELECT COUNT(*) FROM sudz.DbtUplCstAg
             WHERE ducaUpl = @dbtUpl AND ducaCode = N'не обнаружена в платежах') AS cntC,
            (SELECT COUNT(*) FROM sudz.DbtUplCstAg WHERE ducaUpl = @dbtUpl) AS insertedCnt;
        RETURN;
    END;

    DECLARE @deleted int;

    DELETE FROM sudz.DbtUplCstAg WHERE ducaUpl = @dbtUpl;
    SET @deleted = @@ROWCOUNT;

    IF OBJECT_ID(N'tempdb..#valued') IS NOT NULL DROP TABLE #valued;
    IF OBJECT_ID(N'tempdb..#raw_gp') IS NOT NULL DROP TABLE #raw_gp;
    IF OBJECT_ID(N'tempdb..#agg_gp') IS NOT NULL DROP TABLE #agg_gp;

    CREATE TABLE #valued (dbtKey int NOT NULL PRIMARY KEY);

    INSERT INTO #valued (dbtKey)
    SELECT DISTINCT idd.iddDbt
    FROM sudz.DbtValue AS dv
    JOIN sudz.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
    WHERE dv.dvUpl = @dbtUpl
      AND idd.iddDbt IS NOT NULL;

    ;WITH raw_cia AS (
        SELECT
            idd.iddDbt AS dbtKey,
            p.cnipCstAgPn AS cstapKey,
            p.csoCn_s_org_smpl AS csosKey
        FROM sudz.DbtValue AS dv
        JOIN sudz.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
        JOIN sudz.invDbtCia AS c ON c.idcInvDbt = dv.dvInvDbt
        JOIN ags.cnInvAccnt AS cia ON cia.ciaKey = c.idcCia
        JOIN ags.cn_inv_pm AS p
            ON p.ciaCnInvAccntSmpl = cia.ciaCnInvAccntSmpl
           AND p.cnipCstAgPn IS NOT NULL
        JOIN sudz.cn_inv_dbt_upl_g_p AS g
            ON g.cn_inv_pm_upl = p.cn_inv_pm_upl
           AND g.cn_inv_dbt_upl = dv.dvUpl
        WHERE dv.dvUpl = @dbtUpl
          AND idd.iddDbt IS NOT NULL
        GROUP BY idd.iddDbt, p.cnipCstAgPn, p.csoCn_s_org_smpl
    ),
    raw_doc AS (
        SELECT
            idd.iddDbt AS dbtKey,
            p.cnipCstAgPn AS cstapKey,
            p.csoCn_s_org_smpl AS csosKey
        FROM sudz.DbtValue AS dv
        JOIN sudz.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
        JOIN sudz.cn_inv_dbt_upl_g_p AS g ON g.cn_inv_dbt_upl = dv.dvUpl
        JOIN ags.cn_inv_pm AS p
            ON p.cn_inv_pm_upl = g.cn_inv_pm_upl
           AND p.cnipCstAgPn IS NOT NULL
        JOIN ags.cnInvAccntSmpl AS s ON s.ciasKey = p.ciaCnInvAccntSmpl
        JOIN ags.cnInv AS ci ON ci.ciKey = s.ciasCnInv
        JOIN ags.invNum AS n ON n.inInv = ci.ciInv
        WHERE dv.dvUpl = @dbtUpl
          AND idd.iddDbt IS NOT NULL
          AND dv.dvDocBase IS NOT NULL
          AND LTRIM(RTRIM(dv.dvDocBase)) <> N''
          AND (
                n.inNumNull = LTRIM(RTRIM(dv.dvDocBase))
             OR (
                    LEN(LTRIM(RTRIM(dv.dvDocBase))) >= 8
                AND LTRIM(RTRIM(ISNULL(p.cn_inv_doc_link, N'')))
                    = LTRIM(RTRIM(dv.dvDocBase))
                )
          )
        GROUP BY idd.iddDbt, p.cnipCstAgPn, p.csoCn_s_org_smpl
    )
    SELECT dbtKey, cstapKey, csosKey
    INTO #raw_gp
    FROM (
        SELECT dbtKey, cstapKey, csosKey FROM raw_cia
        UNION
        SELECT dbtKey, cstapKey, csosKey FROM raw_doc
    ) AS u;

    SELECT
        dbtKey,
        COUNT(DISTINCT cstapKey) AS nCst,
        MIN(cstapKey) AS cstapKeyMin
    INTO #agg_gp
    FROM #raw_gp
    GROUP BY dbtKey;

    /* A: 1.1 */
    INSERT INTO sudz.DbtUplCstAg (ducaDbt, ducaUpl, ducaCstAgPn, ducaCode, ducaName)
    SELECT
        a.dbtKey,
        @dbtUpl,
        a.cstapKeyMin,
        CAST(pn.cstapIpgPnN AS nvarchar(500)),
        CAST(ISNULL(cst.cstName, N'') AS nvarchar(500))
    FROM #agg_gp AS a
    JOIN ags.cstAgPn AS pn ON pn.cstapKey = a.cstapKeyMin
    LEFT JOIN ags.cstAg AS ca ON ca.cstaKey = pn.cstapCsta
    LEFT JOIN ags.cst AS cst ON cst.cstKey = ca.cstaCst
    WHERE a.nCst = 1;

    /* A: 1.2 agent */
    ;WITH agent_hit AS (
        SELECT DISTINCT r.dbtKey, r.cstapKey
        FROM #raw_gp AS r
        JOIN #agg_gp AS a ON a.dbtKey = r.dbtKey AND a.nCst > 1
        JOIN ags.cstAgPn AS pn ON pn.cstapKey = r.cstapKey
        JOIN ags.cstAg AS ca ON ca.cstaKey = pn.cstapCsta
        JOIN ags.ogAg AS oa ON oa.ogaKey = ca.cstaAg
        JOIN ags.og AS og ON og.ogKey = oa.ogaOg
        JOIN ags.cn_s_org_smpl AS os ON os.csosKey = r.csosKey
        JOIN ags.org_id AS oiPm
            ON oiPm.org_id_key = os.csosOrgId
           AND oiPm.org_id_type = 1
           AND oiPm.org_id_value_l IS NOT NULL
           AND oiPm.org_id_value_l <> 9999999
        WHERE EXISTS (
            SELECT 1
            FROM ags.org_id AS oiCst
            WHERE oiCst.org = og.ogKey
              AND oiCst.org_id_type = 1
              AND oiCst.org_id_value_l = oiPm.org_id_value_l
        )
    ),
    agent_agg AS (
        SELECT dbtKey, COUNT(*) AS nAg, MIN(cstapKey) AS cstapKey
        FROM agent_hit
        GROUP BY dbtKey
    )
    INSERT INTO sudz.DbtUplCstAg (ducaDbt, ducaUpl, ducaCstAgPn, ducaCode, ducaName)
    SELECT
        a.dbtKey,
        @dbtUpl,
        aa.cstapKey,
        CAST(pn.cstapIpgPnN AS nvarchar(500)),
        CAST(ISNULL(cst.cstName, N'') AS nvarchar(500))
    FROM #agg_gp AS a
    JOIN agent_agg AS aa ON aa.dbtKey = a.dbtKey AND aa.nAg = 1
    JOIN ags.cstAgPn AS pn ON pn.cstapKey = aa.cstapKey
    LEFT JOIN ags.cstAg AS ca ON ca.cstaKey = pn.cstapCsta
    LEFT JOIN ags.cst AS cst ON cst.cstKey = ca.cstaCst
    WHERE a.nCst > 1;

    /* B: 1.2 multi — кодов - N + склейка имён */
    INSERT INTO sudz.DbtUplCstAg (ducaDbt, ducaUpl, ducaCstAgPn, ducaCode, ducaName)
    SELECT
        a.dbtKey,
        @dbtUpl,
        NULL,
        CAST(
            CASE
                WHEN LEN(N'кодов - ' + CONVERT(nvarchar(10), a.nCst) + N': ' + codes.codesList) <= 500
                    THEN N'кодов - ' + CONVERT(nvarchar(10), a.nCst) + N': ' + codes.codesList
                ELSE LEFT(N'кодов - ' + CONVERT(nvarchar(10), a.nCst) + N': ' + codes.codesList, 497) + N'…'
            END
            AS nvarchar(500)
        ),
        CAST(
            CASE
                WHEN LEN(ISNULL(names.namesList, N'')) <= 500 THEN ISNULL(names.namesList, N'')
                ELSE LEFT(names.namesList, 497) + N'…'
            END
            AS nvarchar(500)
        )
    FROM #agg_gp AS a
    CROSS APPLY (
        SELECT STUFF((
            SELECT N'; ' + pn.cstapIpgPnN
            FROM (SELECT DISTINCT r.cstapKey FROM #raw_gp AS r WHERE r.dbtKey = a.dbtKey) AS x
            JOIN ags.cstAgPn AS pn ON pn.cstapKey = x.cstapKey
            ORDER BY pn.cstapIpgPnN
            FOR XML PATH(N''), TYPE
        ).value(N'.', N'nvarchar(max)'), 1, 2, N'') AS codesList
    ) AS codes
    CROSS APPLY (
        SELECT STUFF((
            SELECT N'; ' + pn.cstapIpgPnN + N' — ' + ISNULL(cst.cstName, N'')
            FROM (SELECT DISTINCT r.cstapKey FROM #raw_gp AS r WHERE r.dbtKey = a.dbtKey) AS x
            JOIN ags.cstAgPn AS pn ON pn.cstapKey = x.cstapKey
            LEFT JOIN ags.cstAg AS ca ON ca.cstaKey = pn.cstapCsta
            LEFT JOIN ags.cst AS cst ON cst.cstKey = ca.cstaCst
            ORDER BY pn.cstapIpgPnN
            FOR XML PATH(N''), TYPE
        ).value(N'.', N'nvarchar(max)'), 1, 2, N'') AS namesList
    ) AS names
    WHERE a.nCst > 1
      AND NOT EXISTS (
          SELECT 1 FROM sudz.DbtUplCstAg AS d
          WHERE d.ducaUpl = @dbtUpl AND d.ducaDbt = a.dbtKey
      );



    /* ---------- P2 inline: 1.3 year→all (no Exp) → A/B before C ---------- */
    IF OBJECT_ID(N'tempdb..#empty') IS NOT NULL DROP TABLE #empty;
    SELECT v.dbtKey
    INTO #empty
    FROM #valued AS v
    WHERE NOT EXISTS (
        SELECT 1 FROM sudz.DbtUplCstAg AS d
        WHERE d.ducaUpl = @dbtUpl AND d.ducaDbt = v.dbtKey
    );

    IF OBJECT_ID(N'tempdb..#yr_pm') IS NOT NULL DROP TABLE #yr_pm;
    SELECT DISTINCT g.cn_inv_pm_upl AS pmUpl
    INTO #yr_pm
    FROM sudz.cn_inv_dbt_upl_g_p AS g
    WHERE g.cn_inv_dbt_upl IN (
        SELECT yp.cn_inv_dbt_upl
        FROM sudz.yr_upl_p AS yp
        WHERE yp.yr_upl_p_yr = (
            SELECT TOP (1) yp2.yr_upl_p_yr
            FROM sudz.yr_upl_p AS yp2
            WHERE yp2.cn_inv_dbt_upl = @dbtUpl
        )
    );

    IF OBJECT_ID(N'tempdb..#raw_out') IS NOT NULL DROP TABLE #raw_out;
    CREATE TABLE #raw_out (
        dbtKey int NOT NULL,
        cstapKey int NOT NULL,
        csosKey int NOT NULL,
        PRIMARY KEY (dbtKey, cstapKey, csosKey)
    );

    /* --- year scope --- */
    TRUNCATE TABLE #raw_out;

    INSERT INTO #raw_out (dbtKey, cstapKey, csosKey)
    SELECT idd.iddDbt, p.cnipCstAgPn, ISNULL(p.csoCn_s_org_smpl, 0)
    FROM sudz.DbtValue AS dv
    JOIN sudz.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
    JOIN #empty AS e ON e.dbtKey = idd.iddDbt
    JOIN sudz.invDbtCia AS c ON c.idcInvDbt = dv.dvInvDbt
    JOIN ags.cnInvAccnt AS cia ON cia.ciaKey = c.idcCia
    JOIN ags.cn_inv_pm AS p
        ON p.ciaCnInvAccntSmpl = cia.ciaCnInvAccntSmpl
       AND p.cnipCstAgPn IS NOT NULL
    JOIN #yr_pm AS y ON y.pmUpl = p.cn_inv_pm_upl
    WHERE dv.dvUpl = @dbtUpl
    GROUP BY idd.iddDbt, p.cnipCstAgPn, ISNULL(p.csoCn_s_org_smpl, 0);

    INSERT INTO #raw_out (dbtKey, cstapKey, csosKey)
    SELECT idd.iddDbt, p.cnipCstAgPn, ISNULL(p.csoCn_s_org_smpl, 0)
    FROM sudz.DbtValue AS dv
    JOIN sudz.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
    JOIN #empty AS e ON e.dbtKey = idd.iddDbt
    JOIN ags.cn_inv_pm AS p ON p.cnipCstAgPn IS NOT NULL
    JOIN #yr_pm AS y ON y.pmUpl = p.cn_inv_pm_upl
    JOIN ags.cnInvAccntSmpl AS s ON s.ciasKey = p.ciaCnInvAccntSmpl
    JOIN ags.cnInv AS ci ON ci.ciKey = s.ciasCnInv
    JOIN ags.invNum AS n ON n.inInv = ci.ciInv
    WHERE dv.dvUpl = @dbtUpl
      AND dv.dvDocBase IS NOT NULL
      AND LTRIM(RTRIM(dv.dvDocBase)) <> N''
      AND (
            n.inNumNull = LTRIM(RTRIM(dv.dvDocBase))
         OR (
                LEN(LTRIM(RTRIM(dv.dvDocBase))) >= 8
            AND LTRIM(RTRIM(ISNULL(p.cn_inv_doc_link, N'')))
                = LTRIM(RTRIM(dv.dvDocBase))
            )
      )
      AND NOT EXISTS (
          SELECT 1 FROM #raw_out AS r
          WHERE r.dbtKey = idd.iddDbt
            AND r.cstapKey = p.cnipCstAgPn
            AND r.csosKey = ISNULL(p.csoCn_s_org_smpl, 0)
      )
    GROUP BY idd.iddDbt, p.cnipCstAgPn, ISNULL(p.csoCn_s_org_smpl, 0);

    IF OBJECT_ID(N'tempdb..#agg_out') IS NOT NULL DROP TABLE #agg_out;
    CREATE TABLE #agg_out (
        dbtKey int NOT NULL PRIMARY KEY,
        nCst int NOT NULL,
        cstapKeyMin int NOT NULL
    );

    INSERT INTO #agg_out (dbtKey, nCst, cstapKeyMin)
    SELECT dbtKey, COUNT(DISTINCT cstapKey), MIN(cstapKey)
    FROM #raw_out
    GROUP BY dbtKey;

    /* 1.3a year unique → A */
    INSERT INTO sudz.DbtUplCstAg (ducaDbt, ducaUpl, ducaCstAgPn, ducaCode, ducaName)
    SELECT
        a.dbtKey, @dbtUpl, a.cstapKeyMin,
        CAST(pn.cstapIpgPnN AS nvarchar(500)),
        CAST(ISNULL(cst.cstName, N'') AS nvarchar(500))
    FROM #agg_out AS a
    JOIN ags.cstAgPn AS pn ON pn.cstapKey = a.cstapKeyMin
    LEFT JOIN ags.cstAg AS ca ON ca.cstaKey = pn.cstapCsta
    LEFT JOIN ags.cst AS cst ON cst.cstKey = ca.cstaCst
    WHERE a.nCst = 1;

    /* 1.3 year agent → A */
    ;WITH agent_hit AS (
        SELECT DISTINCT r.dbtKey, r.cstapKey
        FROM #raw_out AS r
        JOIN #agg_out AS a ON a.dbtKey = r.dbtKey AND a.nCst > 1
        JOIN ags.cstAgPn AS pn ON pn.cstapKey = r.cstapKey
        JOIN ags.cstAg AS ca ON ca.cstaKey = pn.cstapCsta
        JOIN ags.ogAg AS oa ON oa.ogaKey = ca.cstaAg
        JOIN ags.og AS og ON og.ogKey = oa.ogaOg
        JOIN ags.cn_s_org_smpl AS os ON os.csosKey = NULLIF(r.csosKey, 0)
        JOIN ags.org_id AS oiPm
            ON oiPm.org_id_key = os.csosOrgId
           AND oiPm.org_id_type = 1
           AND oiPm.org_id_value_l IS NOT NULL
           AND oiPm.org_id_value_l <> 9999999
        WHERE EXISTS (
            SELECT 1 FROM ags.org_id AS oiCst
            WHERE oiCst.org = og.ogKey AND oiCst.org_id_type = 1
              AND oiCst.org_id_value_l = oiPm.org_id_value_l
        )
    ),
    agent_agg AS (
        SELECT dbtKey, COUNT(*) AS nAg, MIN(cstapKey) AS cstapKey
        FROM agent_hit GROUP BY dbtKey
    )
    INSERT INTO sudz.DbtUplCstAg (ducaDbt, ducaUpl, ducaCstAgPn, ducaCode, ducaName)
    SELECT
        a.dbtKey, @dbtUpl, aa.cstapKey,
        CAST(pn.cstapIpgPnN AS nvarchar(500)),
        CAST(ISNULL(cst.cstName, N'') AS nvarchar(500))
    FROM #agg_out AS a
    JOIN agent_agg AS aa ON aa.dbtKey = a.dbtKey AND aa.nAg = 1
    JOIN ags.cstAgPn AS pn ON pn.cstapKey = aa.cstapKey
    LEFT JOIN ags.cstAg AS ca ON ca.cstaKey = pn.cstapCsta
    LEFT JOIN ags.cst AS cst ON cst.cstKey = ca.cstaCst
    WHERE a.nCst > 1
      AND NOT EXISTS (
          SELECT 1 FROM sudz.DbtUplCstAg AS d
          WHERE d.ducaUpl = @dbtUpl AND d.ducaDbt = a.dbtKey
      );

    /* 1.3 year multi → B */
    INSERT INTO sudz.DbtUplCstAg (ducaDbt, ducaUpl, ducaCstAgPn, ducaCode, ducaName)
    SELECT
        a.dbtKey, @dbtUpl, NULL,
        CAST(
            CASE
                WHEN LEN(N'кодов - ' + CONVERT(nvarchar(10), a.nCst) + N': ' + codes.codesList) <= 500
                    THEN N'кодов - ' + CONVERT(nvarchar(10), a.nCst) + N': ' + codes.codesList
                ELSE LEFT(N'кодов - ' + CONVERT(nvarchar(10), a.nCst) + N': ' + codes.codesList, 497) + N'…'
            END AS nvarchar(500)
        ),
        CAST(
            CASE
                WHEN LEN(ISNULL(names.namesList, N'')) <= 500 THEN ISNULL(names.namesList, N'')
                ELSE LEFT(names.namesList, 497) + N'…'
            END AS nvarchar(500)
        )
    FROM #agg_out AS a
    CROSS APPLY (
        SELECT STUFF((
            SELECT N'; ' + pn.cstapIpgPnN
            FROM (SELECT DISTINCT r.cstapKey FROM #raw_out AS r WHERE r.dbtKey = a.dbtKey) AS x
            JOIN ags.cstAgPn AS pn ON pn.cstapKey = x.cstapKey
            ORDER BY pn.cstapIpgPnN
            FOR XML PATH(N''), TYPE
        ).value(N'.', N'nvarchar(max)'), 1, 2, N'') AS codesList
    ) AS codes
    CROSS APPLY (
        SELECT STUFF((
            SELECT N'; ' + pn.cstapIpgPnN + N' — ' + ISNULL(cst.cstName, N'')
            FROM (SELECT DISTINCT r.cstapKey FROM #raw_out AS r WHERE r.dbtKey = a.dbtKey) AS x
            JOIN ags.cstAgPn AS pn ON pn.cstapKey = x.cstapKey
            LEFT JOIN ags.cstAg AS ca ON ca.cstaKey = pn.cstapCsta
            LEFT JOIN ags.cst AS cst ON cst.cstKey = ca.cstaCst
            ORDER BY pn.cstapIpgPnN
            FOR XML PATH(N''), TYPE
        ).value(N'.', N'nvarchar(max)'), 1, 2, N'') AS namesList
    ) AS names
    WHERE a.nCst > 1
      AND NOT EXISTS (
          SELECT 1 FROM sudz.DbtUplCstAg AS d
          WHERE d.ducaUpl = @dbtUpl AND d.ducaDbt = a.dbtKey
      );

    /* refresh empty after year */
    DELETE e
    FROM #empty AS e
    WHERE EXISTS (
        SELECT 1 FROM sudz.DbtUplCstAg AS d
        WHERE d.ducaUpl = @dbtUpl AND d.ducaDbt = e.dbtKey
    );

    /* --- all-time scope --- */
    TRUNCATE TABLE #raw_out;
    TRUNCATE TABLE #agg_out;

    INSERT INTO #raw_out (dbtKey, cstapKey, csosKey)
    SELECT idd.iddDbt, p.cnipCstAgPn, ISNULL(p.csoCn_s_org_smpl, 0)
    FROM sudz.DbtValue AS dv
    JOIN sudz.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
    JOIN #empty AS e ON e.dbtKey = idd.iddDbt
    JOIN sudz.invDbtCia AS c ON c.idcInvDbt = dv.dvInvDbt
    JOIN ags.cnInvAccnt AS cia ON cia.ciaKey = c.idcCia
    JOIN ags.cn_inv_pm AS p
        ON p.ciaCnInvAccntSmpl = cia.ciaCnInvAccntSmpl
       AND p.cnipCstAgPn IS NOT NULL
    WHERE dv.dvUpl = @dbtUpl
    GROUP BY idd.iddDbt, p.cnipCstAgPn, ISNULL(p.csoCn_s_org_smpl, 0);

    INSERT INTO #raw_out (dbtKey, cstapKey, csosKey)
    SELECT idd.iddDbt, p.cnipCstAgPn, ISNULL(p.csoCn_s_org_smpl, 0)
    FROM sudz.DbtValue AS dv
    JOIN sudz.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
    JOIN #empty AS e ON e.dbtKey = idd.iddDbt
    JOIN ags.cn_inv_pm AS p ON p.cnipCstAgPn IS NOT NULL
    JOIN ags.cnInvAccntSmpl AS s ON s.ciasKey = p.ciaCnInvAccntSmpl
    JOIN ags.cnInv AS ci ON ci.ciKey = s.ciasCnInv
    JOIN ags.invNum AS n ON n.inInv = ci.ciInv
    WHERE dv.dvUpl = @dbtUpl
      AND dv.dvDocBase IS NOT NULL
      AND LTRIM(RTRIM(dv.dvDocBase)) <> N''
      AND (
            n.inNumNull = LTRIM(RTRIM(dv.dvDocBase))
         OR (
                LEN(LTRIM(RTRIM(dv.dvDocBase))) >= 8
            AND LTRIM(RTRIM(ISNULL(p.cn_inv_doc_link, N'')))
                = LTRIM(RTRIM(dv.dvDocBase))
            )
      )
      AND NOT EXISTS (
          SELECT 1 FROM #raw_out AS r
          WHERE r.dbtKey = idd.iddDbt
            AND r.cstapKey = p.cnipCstAgPn
            AND r.csosKey = ISNULL(p.csoCn_s_org_smpl, 0)
      )
    GROUP BY idd.iddDbt, p.cnipCstAgPn, ISNULL(p.csoCn_s_org_smpl, 0);

    INSERT INTO #agg_out (dbtKey, nCst, cstapKeyMin)
    SELECT dbtKey, COUNT(DISTINCT cstapKey), MIN(cstapKey)
    FROM #raw_out
    GROUP BY dbtKey;

    /* 1.3a all unique → A */
    INSERT INTO sudz.DbtUplCstAg (ducaDbt, ducaUpl, ducaCstAgPn, ducaCode, ducaName)
    SELECT
        a.dbtKey, @dbtUpl, a.cstapKeyMin,
        CAST(pn.cstapIpgPnN AS nvarchar(500)),
        CAST(ISNULL(cst.cstName, N'') AS nvarchar(500))
    FROM #agg_out AS a
    JOIN ags.cstAgPn AS pn ON pn.cstapKey = a.cstapKeyMin
    LEFT JOIN ags.cstAg AS ca ON ca.cstaKey = pn.cstapCsta
    LEFT JOIN ags.cst AS cst ON cst.cstKey = ca.cstaCst
    WHERE a.nCst = 1
      AND NOT EXISTS (
          SELECT 1 FROM sudz.DbtUplCstAg AS d
          WHERE d.ducaUpl = @dbtUpl AND d.ducaDbt = a.dbtKey
      );

    /* 1.3 all agent → A */
    ;WITH agent_hit AS (
        SELECT DISTINCT r.dbtKey, r.cstapKey
        FROM #raw_out AS r
        JOIN #agg_out AS a ON a.dbtKey = r.dbtKey AND a.nCst > 1
        JOIN ags.cstAgPn AS pn ON pn.cstapKey = r.cstapKey
        JOIN ags.cstAg AS ca ON ca.cstaKey = pn.cstapCsta
        JOIN ags.ogAg AS oa ON oa.ogaKey = ca.cstaAg
        JOIN ags.og AS og ON og.ogKey = oa.ogaOg
        JOIN ags.cn_s_org_smpl AS os ON os.csosKey = NULLIF(r.csosKey, 0)
        JOIN ags.org_id AS oiPm
            ON oiPm.org_id_key = os.csosOrgId
           AND oiPm.org_id_type = 1
           AND oiPm.org_id_value_l IS NOT NULL
           AND oiPm.org_id_value_l <> 9999999
        WHERE EXISTS (
            SELECT 1 FROM ags.org_id AS oiCst
            WHERE oiCst.org = og.ogKey AND oiCst.org_id_type = 1
              AND oiCst.org_id_value_l = oiPm.org_id_value_l
        )
    ),
    agent_agg AS (
        SELECT dbtKey, COUNT(*) AS nAg, MIN(cstapKey) AS cstapKey
        FROM agent_hit GROUP BY dbtKey
    )
    INSERT INTO sudz.DbtUplCstAg (ducaDbt, ducaUpl, ducaCstAgPn, ducaCode, ducaName)
    SELECT
        a.dbtKey, @dbtUpl, aa.cstapKey,
        CAST(pn.cstapIpgPnN AS nvarchar(500)),
        CAST(ISNULL(cst.cstName, N'') AS nvarchar(500))
    FROM #agg_out AS a
    JOIN agent_agg AS aa ON aa.dbtKey = a.dbtKey AND aa.nAg = 1
    JOIN ags.cstAgPn AS pn ON pn.cstapKey = aa.cstapKey
    LEFT JOIN ags.cstAg AS ca ON ca.cstaKey = pn.cstapCsta
    LEFT JOIN ags.cst AS cst ON cst.cstKey = ca.cstaCst
    WHERE a.nCst > 1
      AND NOT EXISTS (
          SELECT 1 FROM sudz.DbtUplCstAg AS d
          WHERE d.ducaUpl = @dbtUpl AND d.ducaDbt = a.dbtKey
      );

    /* 1.3 all multi → B */
    INSERT INTO sudz.DbtUplCstAg (ducaDbt, ducaUpl, ducaCstAgPn, ducaCode, ducaName)
    SELECT
        a.dbtKey, @dbtUpl, NULL,
        CAST(
            CASE
                WHEN LEN(N'кодов - ' + CONVERT(nvarchar(10), a.nCst) + N': ' + codes.codesList) <= 500
                    THEN N'кодов - ' + CONVERT(nvarchar(10), a.nCst) + N': ' + codes.codesList
                ELSE LEFT(N'кодов - ' + CONVERT(nvarchar(10), a.nCst) + N': ' + codes.codesList, 497) + N'…'
            END AS nvarchar(500)
        ),
        CAST(
            CASE
                WHEN LEN(ISNULL(names.namesList, N'')) <= 500 THEN ISNULL(names.namesList, N'')
                ELSE LEFT(names.namesList, 497) + N'…'
            END AS nvarchar(500)
        )
    FROM #agg_out AS a
    CROSS APPLY (
        SELECT STUFF((
            SELECT N'; ' + pn.cstapIpgPnN
            FROM (SELECT DISTINCT r.cstapKey FROM #raw_out AS r WHERE r.dbtKey = a.dbtKey) AS x
            JOIN ags.cstAgPn AS pn ON pn.cstapKey = x.cstapKey
            ORDER BY pn.cstapIpgPnN
            FOR XML PATH(N''), TYPE
        ).value(N'.', N'nvarchar(max)'), 1, 2, N'') AS codesList
    ) AS codes
    CROSS APPLY (
        SELECT STUFF((
            SELECT N'; ' + pn.cstapIpgPnN + N' — ' + ISNULL(cst.cstName, N'')
            FROM (SELECT DISTINCT r.cstapKey FROM #raw_out AS r WHERE r.dbtKey = a.dbtKey) AS x
            JOIN ags.cstAgPn AS pn ON pn.cstapKey = x.cstapKey
            LEFT JOIN ags.cstAg AS ca ON ca.cstaKey = pn.cstapCsta
            LEFT JOIN ags.cst AS cst ON cst.cstKey = ca.cstaCst
            ORDER BY pn.cstapIpgPnN
            FOR XML PATH(N''), TYPE
        ).value(N'.', N'nvarchar(max)'), 1, 2, N'') AS namesList
    ) AS names
    WHERE a.nCst > 1
      AND NOT EXISTS (
          SELECT 1 FROM sudz.DbtUplCstAg AS d
          WHERE d.ducaUpl = @dbtUpl AND d.ducaDbt = a.dbtKey
      );

    /* C: valued без строки */
    INSERT INTO sudz.DbtUplCstAg (ducaDbt, ducaUpl, ducaCstAgPn, ducaCode, ducaName)
    SELECT
        v.dbtKey,
        @dbtUpl,
        NULL,
        N'не обнаружена в платежах',
        N''
    FROM #valued AS v
    WHERE NOT EXISTS (
        SELECT 1 FROM sudz.DbtUplCstAg AS d
        WHERE d.ducaUpl = @dbtUpl AND d.ducaDbt = v.dbtKey
    );

    SELECT
        @deleted AS deletedCnt,
        (SELECT COUNT(*) FROM sudz.DbtUplCstAg WHERE ducaUpl = @dbtUpl AND ducaCstAgPn IS NOT NULL) AS cntA,
        (SELECT COUNT(*) FROM sudz.DbtUplCstAg
         WHERE ducaUpl = @dbtUpl AND ducaCstAgPn IS NULL AND ducaCode LIKE N'кодов -%') AS cntB,
        (SELECT COUNT(*) FROM sudz.DbtUplCstAg
         WHERE ducaUpl = @dbtUpl AND ducaCode = N'не обнаружена в платежах') AS cntC,
        (SELECT COUNT(*) FROM sudz.DbtUplCstAg WHERE ducaUpl = @dbtUpl) AS insertedCnt;
END
GO

PRINT N'09 usp_RebuildDbtUplCstAg P1 created';
GO
