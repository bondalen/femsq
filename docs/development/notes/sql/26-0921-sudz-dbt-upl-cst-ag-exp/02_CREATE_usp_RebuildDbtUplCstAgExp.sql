-- 02_CREATE_usp_RebuildDbtUplCstAgExp.sql
-- §3.2a–c: 1.1 g_p → 1.2 agent/склейка → 1.3 вне g_p (год, затем всё) → 1.4.
-- Матч cia ∪ docBase — как JdbcSudzDao.sqlDbtUplCstAgRawCte / H6.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'sudz.usp_RebuildDbtUplCstAgExp', N'P') IS NOT NULL
    DROP PROCEDURE sudz.usp_RebuildDbtUplCstAgExp;
GO

CREATE PROCEDURE sudz.usp_RebuildDbtUplCstAgExp
    @dbtUpl int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @dbtUpl IS NULL OR @dbtUpl <= 0
    BEGIN
        RAISERROR(N'usp_RebuildDbtUplCstAgExp: @dbtUpl must be positive', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM sudz.cn_inv_dbt_upl WHERE upl_key = @dbtUpl)
    BEGIN
        RAISERROR(N'usp_RebuildDbtUplCstAgExp: dbt upl not found', 16, 1);
        RETURN;
    END;

    BEGIN TRAN;

    DELETE FROM sudz.DbtUplCstAgExp WHERE duexUpl = @dbtUpl;

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

    /* ---------- g_p @ this upl ---------- */
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

    /* 1.1 */
    INSERT INTO sudz.DbtUplCstAgExp (
        duexDbt, duexUpl, duexRule, duexCstAgPn, duexCode, duexName, duexDetail
    )
    SELECT
        a.dbtKey,
        @dbtUpl,
        CAST(11 AS tinyint),
        a.cstapKeyMin,
        CAST(pn.cstapIpgPnN AS nvarchar(200)),
        N'1.1 g_p',
        NULL
    FROM #agg_gp AS a
    JOIN ags.cstAgPn AS pn ON pn.cstapKey = a.cstapKeyMin
    WHERE a.nCst = 1;

    /* agent hits on g_p multi */
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
    INSERT INTO sudz.DbtUplCstAgExp (
        duexDbt, duexUpl, duexRule, duexCstAgPn, duexCode, duexName, duexDetail
    )
    SELECT
        a.dbtKey,
        @dbtUpl,
        CAST(12 AS tinyint),
        aa.cstapKey,
        CAST(pn.cstapIpgPnN AS nvarchar(200)),
        N'1.2 agent',
        N'nCst=' + CONVERT(nvarchar(10), a.nCst)
    FROM #agg_gp AS a
    JOIN agent_agg AS aa ON aa.dbtKey = a.dbtKey AND aa.nAg = 1
    JOIN ags.cstAgPn AS pn ON pn.cstapKey = aa.cstapKey
    WHERE a.nCst > 1;

    /* 1.2 multi glue */
    INSERT INTO sudz.DbtUplCstAgExp (
        duexDbt, duexUpl, duexRule, duexCstAgPn, duexCode, duexName, duexDetail
    )
    SELECT
        a.dbtKey,
        @dbtUpl,
        CAST(12 AS tinyint),
        NULL,
        CAST(LEFT(STUFF((
            SELECT N'; ' + pn.cstapIpgPnN
            FROM (SELECT DISTINCT r.cstapKey FROM #raw_gp AS r WHERE r.dbtKey = a.dbtKey) AS x
            JOIN ags.cstAgPn AS pn ON pn.cstapKey = x.cstapKey
            ORDER BY pn.cstapIpgPnN
            FOR XML PATH(N''), TYPE
        ).value(N'.', N'nvarchar(max)'), 1, 2, N''), 200) AS nvarchar(200)),
        N'1.2 multi',
        N'nCst=' + CONVERT(nvarchar(10), a.nCst)
    FROM #agg_gp AS a
    WHERE a.nCst > 1
      AND NOT EXISTS (
          SELECT 1 FROM sudz.DbtUplCstAgExp AS e
          WHERE e.duexUpl = @dbtUpl AND e.duexDbt = a.dbtKey
      );

    /* ---------- 1.3: empty after g_p — year horizon, then all ---------- */
    IF OBJECT_ID(N'tempdb..#empty') IS NOT NULL DROP TABLE #empty;
    SELECT v.dbtKey
    INTO #empty
    FROM #valued AS v
    WHERE NOT EXISTS (
        SELECT 1 FROM sudz.DbtUplCstAgExp AS e
        WHERE e.duexUpl = @dbtUpl AND e.duexDbt = v.dbtKey
    );

    /* year peer pm packages (any dbt_upl of same yr via g_p) */
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

    /* helper: load out-of-g_p candidates for #empty into #raw_out */
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
    SELECT
        dbtKey,
        COUNT(DISTINCT cstapKey),
        MIN(cstapKey)
    FROM #raw_out
    GROUP BY dbtKey;

    /* 1.3a year unique */
    INSERT INTO sudz.DbtUplCstAgExp (
        duexDbt, duexUpl, duexRule, duexCstAgPn, duexCode, duexName, duexDetail
    )
    SELECT
        a.dbtKey, @dbtUpl, CAST(13 AS tinyint), a.cstapKeyMin,
        CAST(pn.cstapIpgPnN AS nvarchar(200)),
        N'1.3 out-gp',
        N'horizon=year'
    FROM #agg_out AS a
    JOIN ags.cstAgPn AS pn ON pn.cstapKey = a.cstapKeyMin
    WHERE a.nCst = 1;

    /* 1.3 year multi + agent */
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
    INSERT INTO sudz.DbtUplCstAgExp (
        duexDbt, duexUpl, duexRule, duexCstAgPn, duexCode, duexName, duexDetail
    )
    SELECT
        a.dbtKey, @dbtUpl, CAST(13 AS tinyint), aa.cstapKey,
        CAST(pn.cstapIpgPnN AS nvarchar(200)),
        N'1.3 agent',
        N'horizon=year; nCst=' + CONVERT(nvarchar(10), a.nCst)
    FROM #agg_out AS a
    JOIN agent_agg AS aa ON aa.dbtKey = a.dbtKey AND aa.nAg = 1
    JOIN ags.cstAgPn AS pn ON pn.cstapKey = aa.cstapKey
    WHERE a.nCst > 1
      AND NOT EXISTS (
          SELECT 1 FROM sudz.DbtUplCstAgExp AS e
          WHERE e.duexUpl = @dbtUpl AND e.duexDbt = a.dbtKey
      );

    INSERT INTO sudz.DbtUplCstAgExp (
        duexDbt, duexUpl, duexRule, duexCstAgPn, duexCode, duexName, duexDetail
    )
    SELECT
        a.dbtKey, @dbtUpl, CAST(13 AS tinyint), NULL,
        CAST(LEFT(STUFF((
            SELECT N'; ' + pn.cstapIpgPnN
            FROM (SELECT DISTINCT r.cstapKey FROM #raw_out AS r WHERE r.dbtKey = a.dbtKey) AS x
            JOIN ags.cstAgPn AS pn ON pn.cstapKey = x.cstapKey
            ORDER BY pn.cstapIpgPnN
            FOR XML PATH(N''), TYPE
        ).value(N'.', N'nvarchar(max)'), 1, 2, N''), 200) AS nvarchar(200)),
        N'1.3 multi',
        N'horizon=year; nCst=' + CONVERT(nvarchar(10), a.nCst)
    FROM #agg_out AS a
    WHERE a.nCst > 1
      AND NOT EXISTS (
          SELECT 1 FROM sudz.DbtUplCstAgExp AS e
          WHERE e.duexUpl = @dbtUpl AND e.duexDbt = a.dbtKey
      );

    /* refresh empty after year */
    DELETE e
    FROM #empty AS e
    WHERE EXISTS (
        SELECT 1 FROM sudz.DbtUplCstAgExp AS x
        WHERE x.duexUpl = @dbtUpl AND x.duexDbt = e.dbtKey
    );

    /* --- all-time scope (no pm_upl filter) for remaining empty --- */
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
    SELECT
        dbtKey,
        COUNT(DISTINCT cstapKey),
        MIN(cstapKey)
    FROM #raw_out
    GROUP BY dbtKey;

    INSERT INTO sudz.DbtUplCstAgExp (
        duexDbt, duexUpl, duexRule, duexCstAgPn, duexCode, duexName, duexDetail
    )
    SELECT
        a.dbtKey, @dbtUpl, CAST(13 AS tinyint), a.cstapKeyMin,
        CAST(pn.cstapIpgPnN AS nvarchar(200)),
        N'1.3 out-gp',
        N'horizon=all'
    FROM #agg_out AS a
    JOIN ags.cstAgPn AS pn ON pn.cstapKey = a.cstapKeyMin
    WHERE a.nCst = 1
      AND NOT EXISTS (
          SELECT 1 FROM sudz.DbtUplCstAgExp AS e
          WHERE e.duexUpl = @dbtUpl AND e.duexDbt = a.dbtKey
      );

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
    INSERT INTO sudz.DbtUplCstAgExp (
        duexDbt, duexUpl, duexRule, duexCstAgPn, duexCode, duexName, duexDetail
    )
    SELECT
        a.dbtKey, @dbtUpl, CAST(13 AS tinyint), aa.cstapKey,
        CAST(pn.cstapIpgPnN AS nvarchar(200)),
        N'1.3 agent',
        N'horizon=all; nCst=' + CONVERT(nvarchar(10), a.nCst)
    FROM #agg_out AS a
    JOIN agent_agg AS aa ON aa.dbtKey = a.dbtKey AND aa.nAg = 1
    JOIN ags.cstAgPn AS pn ON pn.cstapKey = aa.cstapKey
    WHERE a.nCst > 1
      AND NOT EXISTS (
          SELECT 1 FROM sudz.DbtUplCstAgExp AS e
          WHERE e.duexUpl = @dbtUpl AND e.duexDbt = a.dbtKey
      );

    INSERT INTO sudz.DbtUplCstAgExp (
        duexDbt, duexUpl, duexRule, duexCstAgPn, duexCode, duexName, duexDetail
    )
    SELECT
        a.dbtKey, @dbtUpl, CAST(13 AS tinyint), NULL,
        CAST(LEFT(STUFF((
            SELECT N'; ' + pn.cstapIpgPnN
            FROM (SELECT DISTINCT r.cstapKey FROM #raw_out AS r WHERE r.dbtKey = a.dbtKey) AS x
            JOIN ags.cstAgPn AS pn ON pn.cstapKey = x.cstapKey
            ORDER BY pn.cstapIpgPnN
            FOR XML PATH(N''), TYPE
        ).value(N'.', N'nvarchar(max)'), 1, 2, N''), 200) AS nvarchar(200)),
        N'1.3 multi',
        N'horizon=all; nCst=' + CONVERT(nvarchar(10), a.nCst)
    FROM #agg_out AS a
    WHERE a.nCst > 1
      AND NOT EXISTS (
          SELECT 1 FROM sudz.DbtUplCstAgExp AS e
          WHERE e.duexUpl = @dbtUpl AND e.duexDbt = a.dbtKey
      );

    /* 1.4 remaining */
    INSERT INTO sudz.DbtUplCstAgExp (
        duexDbt, duexUpl, duexRule, duexCstAgPn, duexCode, duexName, duexDetail
    )
    SELECT
        v.dbtKey,
        @dbtUpl,
        CAST(14 AS tinyint),
        NULL,
        N'не обнаружена в платежах',
        N'1.4 none',
        N'no pm-cst (g_p + year + all)'
    FROM #valued AS v
    WHERE NOT EXISTS (
        SELECT 1 FROM sudz.DbtUplCstAgExp AS e
        WHERE e.duexUpl = @dbtUpl AND e.duexDbt = v.dbtKey
    );

    COMMIT TRAN;

    SELECT
        @dbtUpl AS dbtUpl,
        SUM(CASE WHEN duexRule = 11 THEN 1 ELSE 0 END) AS cnt_11,
        SUM(CASE WHEN duexName = N'1.2 agent' THEN 1 ELSE 0 END) AS cnt_12_agent,
        SUM(CASE WHEN duexName = N'1.2 multi' THEN 1 ELSE 0 END) AS cnt_12_multi,
        SUM(CASE WHEN duexName = N'1.3 out-gp' THEN 1 ELSE 0 END) AS cnt_13_out,
        SUM(CASE WHEN duexName = N'1.3 agent' THEN 1 ELSE 0 END) AS cnt_13_agent,
        SUM(CASE WHEN duexName = N'1.3 multi' THEN 1 ELSE 0 END) AS cnt_13_multi,
        SUM(CASE WHEN duexRule = 14 THEN 1 ELSE 0 END) AS cnt_14,
        COUNT(*) AS cnt_all
    FROM sudz.DbtUplCstAgExp
    WHERE duexUpl = @dbtUpl;
END;
GO
