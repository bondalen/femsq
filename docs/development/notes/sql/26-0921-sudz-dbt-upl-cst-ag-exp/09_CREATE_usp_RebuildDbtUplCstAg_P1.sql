-- 09_CREATE_usp_RebuildDbtUplCstAg_P1.sql
-- Канон H6 / P1: только g_p @upl → A (1.1 + agent) / B (multi) / C (нет).
-- Без 1.3 (вне g_p). Форматы §5a плана 0921.
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
