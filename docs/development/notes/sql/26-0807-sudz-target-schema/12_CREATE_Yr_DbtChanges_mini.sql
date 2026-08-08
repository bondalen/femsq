-- =============================================================================
-- Мини-витрина Rslt на модели sudz (заготовка под Yr_DbtChanges)
-- DEV only. Зерно строки = Dbt (не iKey+account+ciaName).
-- Комментарии клеятся по dbtKey к yr.yr_CmmGr.
-- =============================================================================

SET NOCOUNT ON;

---------------------------------------------------------------------
-- 1) Длинный факт: долг × выгрузка года (удобно отлаживать)
---------------------------------------------------------------------
IF OBJECT_ID(N'sudz.vw_Yr_DbtFact', N'V') IS NOT NULL
    DROP VIEW sudz.vw_Yr_DbtFact;
GO

CREATE VIEW sudz.vw_Yr_DbtFact
AS
SELECT
    y.yr_key,
    y.yr_variant,
    y.yr_CmmGr,
    u.upl_key,
    u.uplStatusOnDate AS as_of,
    u.upl_date,
    dv.dvDbt AS dbtKey,
    inv.iKey AS iKey,
    n.inNum AS invNum,
    c.cnnNum AS cnNum,
    a.account_num,
    og.ogNm AS CtptOrg,
    inn.org_id_value_t AS ITN,
    so.csoCnDate,
    dv.dvTtl,
    dv.dvOverd,
    dv.dvDateStart,
    dv.dvDateMaturity,
    dv.dvDocBase,
    dv.dvInvDbtVar
FROM sudz.yr y
JOIN sudz.yr_upl_p yp ON yp.yr_upl_p_yr = y.yr_key
JOIN sudz.cn_inv_dbt_upl u ON u.upl_key = yp.cn_inv_dbt_upl
JOIN sudz.DbtValue dv ON dv.dvUpl = u.upl_key
JOIN sudz.invDbtVar v ON v.idvvKey = dv.dvInvDbtVar
JOIN ags.invNum n ON n.inKey = v.idvvInvNum
JOIN ags.inv inv ON inv.iKey = n.inInv
JOIN ags.cnNum c ON c.cnnKey = v.idvvCnNum
JOIN ags.accnt a ON a.account_key = v.idvvAccnt
JOIN ags.cn_s_org so ON so.cn_s_org_key = v.idvvCn_s_org
JOIN ags.cn_s_org_smpl os ON os.csosKey = so.csoCn_s_org_smpl
JOIN ags.org_id oi ON oi.org_id_key = os.csosOrgId
JOIN ags.og og ON og.ogKey = oi.org
OUTER APPLY (
    SELECT MIN(i2.org_id_value_t) AS org_id_value_t
    FROM ags.org_id i2
    WHERE i2.org = og.ogKey AND i2.org_id_type = 2
) inn;
GO

---------------------------------------------------------------------
-- 2) Широкая «статическая» витрина под seed 2026 (3 as-of даты)
--    Для быстрой проверки без EXEC. Колонки фиксированы.
---------------------------------------------------------------------
IF OBJECT_ID(N'sudz.vw_Yr_DbtChanges_mini_2026', N'V') IS NOT NULL
    DROP VIEW sudz.vw_Yr_DbtChanges_mini_2026;
GO

CREATE VIEW sudz.vw_Yr_DbtChanges_mini_2026
AS
WITH base AS (
    SELECT *
    FROM sudz.vw_Yr_DbtFact
    WHERE yr_key = 901
),
wide AS (
    SELECT
        dbtKey,
        MAX(CASE WHEN as_of = '2025-12-31' THEN cnNum END) AS [2025-12-31_cnNum],
        MAX(CASE WHEN as_of = '2025-12-31' THEN invNum END) AS [2025-12-31_invNum],
        MAX(CASE WHEN as_of = '2025-12-31' THEN account_num END) AS [2025-12-31_account_num],
        MAX(CASE WHEN as_of = '2025-12-31' THEN CtptOrg END) AS [2025-12-31_CtptOrg],
        MAX(CASE WHEN as_of = '2025-12-31' THEN ITN END) AS [2025-12-31_ITN],
        MAX(CASE WHEN as_of = '2025-12-31' THEN dvDateMaturity END) AS [2025-12-31_Maturity],
        MAX(CASE WHEN as_of = '2025-12-31' THEN dvTtl END) AS [2025-12-31_Ttl],
        MAX(CASE WHEN as_of = '2025-12-31' THEN dvOverd END) AS [2025-12-31_Overd],
        MAX(CASE WHEN as_of = '2025-12-31' THEN dvDocBase END) AS [2025-12-31_DocBase],

        MAX(CASE WHEN as_of = '2026-03-31' THEN cnNum END) AS [2026-03-31_cnNum],
        MAX(CASE WHEN as_of = '2026-03-31' THEN invNum END) AS [2026-03-31_invNum],
        MAX(CASE WHEN as_of = '2026-03-31' THEN account_num END) AS [2026-03-31_account_num],
        MAX(CASE WHEN as_of = '2026-03-31' THEN CtptOrg END) AS [2026-03-31_CtptOrg],
        MAX(CASE WHEN as_of = '2026-03-31' THEN ITN END) AS [2026-03-31_ITN],
        MAX(CASE WHEN as_of = '2026-03-31' THEN dvDateMaturity END) AS [2026-03-31_Maturity],
        MAX(CASE WHEN as_of = '2026-03-31' THEN dvTtl END) AS [2026-03-31_Ttl],
        MAX(CASE WHEN as_of = '2026-03-31' THEN dvOverd END) AS [2026-03-31_Overd],
        MAX(CASE WHEN as_of = '2026-03-31' THEN dvDocBase END) AS [2026-03-31_DocBase],

        MAX(CASE WHEN as_of = '2026-06-30' THEN cnNum END) AS [2026-06-30_cnNum],
        MAX(CASE WHEN as_of = '2026-06-30' THEN invNum END) AS [2026-06-30_invNum],
        MAX(CASE WHEN as_of = '2026-06-30' THEN account_num END) AS [2026-06-30_account_num],
        MAX(CASE WHEN as_of = '2026-06-30' THEN CtptOrg END) AS [2026-06-30_CtptOrg],
        MAX(CASE WHEN as_of = '2026-06-30' THEN ITN END) AS [2026-06-30_ITN],
        MAX(CASE WHEN as_of = '2026-06-30' THEN dvDateMaturity END) AS [2026-06-30_Maturity],
        MAX(CASE WHEN as_of = '2026-06-30' THEN dvTtl END) AS [2026-06-30_Ttl],
        MAX(CASE WHEN as_of = '2026-06-30' THEN dvOverd END) AS [2026-06-30_Overd],
        MAX(CASE WHEN as_of = '2026-06-30' THEN dvDocBase END) AS [2026-06-30_DocBase],

        MAX(yr_CmmGr) AS yr_CmmGr
    FROM base
    GROUP BY dbtKey
),
cmm AS (
    SELECT
        cm.cnicInvAccnt AS dbtKey,
        MAX(CASE WHEN cm.cnicType = 1 THEN cm.cnicText END) AS mery,
        MAX(CASE WHEN cm.cnicType = 8 THEN cm.cnicText END) AS curator,
        MAX(CASE WHEN cm.cnicType = 5 THEN cm.cnicText END) AS notes
    FROM sudz.yr y
    JOIN sudz.cnInvCmm cm ON cm.cnicGroup = y.yr_CmmGr
    WHERE y.yr_key = 901
    GROUP BY cm.cnicInvAccnt
),
dt AS (
    SELECT
        d.cnicdInvAccnt AS dbtKey,
        MIN(d.cnicdDate) AS forecast_date
    FROM sudz.yr y
    JOIN sudz.cnInvCmmDt d ON d.cnicdCmmGr = y.yr_CmmGr
    WHERE y.yr_key = 901
    GROUP BY d.cnicdInvAccnt
),
fn AS (
    SELECT
        f.cnicfInvAccnt AS dbtKey,
        MIN(f.cnicfValue) AS agent_overd
    FROM sudz.yr y
    JOIN sudz.cnInvCmmFn f ON f.cnicfCmmGr = y.yr_CmmGr
    WHERE y.yr_key = 901
    GROUP BY f.cnicfInvAccnt
),
gr AS (
    SELECT
        g.cnigInvAccnt AS dbtKey,
        MIN(n.cnignName) AS debt_group
    FROM sudz.yr y
    JOIN sudz.cnInvGr g ON g.cnigCmmGr = y.yr_CmmGr
    JOIN sudz.cnInvGrNm n ON n.cnignKey = g.cnigGrName
    WHERE y.yr_key = 901
    GROUP BY g.cnigInvAccnt
)
SELECT
    w.dbtKey,
    w.[2025-12-31_cnNum], w.[2025-12-31_invNum], w.[2025-12-31_account_num],
    w.[2025-12-31_CtptOrg], w.[2025-12-31_ITN],
    w.[2025-12-31_Maturity], w.[2025-12-31_Ttl], w.[2025-12-31_Overd], w.[2025-12-31_DocBase],
    w.[2026-03-31_cnNum], w.[2026-03-31_invNum], w.[2026-03-31_account_num],
    w.[2026-03-31_CtptOrg], w.[2026-03-31_ITN],
    w.[2026-03-31_Maturity], w.[2026-03-31_Ttl], w.[2026-03-31_Overd], w.[2026-03-31_DocBase],
    w.[2026-06-30_cnNum], w.[2026-06-30_invNum], w.[2026-06-30_account_num],
    w.[2026-06-30_CtptOrg], w.[2026-06-30_ITN],
    w.[2026-06-30_Maturity], w.[2026-06-30_Ttl], w.[2026-06-30_Overd], w.[2026-06-30_DocBase],
    c.mery,
    c.curator,
    c.notes,
    d.forecast_date,
    f.agent_overd,
    g.debt_group,
    w.yr_CmmGr
FROM wide w
LEFT JOIN cmm c ON c.dbtKey = w.dbtKey
LEFT JOIN dt d ON d.dbtKey = w.dbtKey
LEFT JOIN fn f ON f.dbtKey = w.dbtKey
LEFT JOIN gr g ON g.dbtKey = w.dbtKey;
GO

---------------------------------------------------------------------
-- 3) Процедура: динамический пивот по as_of выгрузок года + комментарии по Dbt
--    Вызов: EXEC sudz.Yr_DbtChanges_mini @yr = 901;
---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE sudz.Yr_DbtChanges_mini
    @yr int
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM sudz.yr WHERE yr_key = @yr)
    BEGIN
        RAISERROR(N'sudz.Yr_DbtChanges_mini: yr_key=%d не найден', 16, 1, @yr);
        RETURN;
    END;

    DECLARE @cols_Ttl nvarchar(max);
    DECLARE @cols_Overd nvarchar(max);
    DECLARE @cols_Maturity nvarchar(max);
    DECLARE @cols_invNum nvarchar(max);
    DECLARE @cols_cnNum nvarchar(max);
    DECLARE @sel_Ttl nvarchar(max);
    DECLARE @sel_Overd nvarchar(max);
    DECLARE @sel_Maturity nvarchar(max);
    DECLARE @sel_invNum nvarchar(max);
    DECLARE @sel_cnNum nvarchar(max);
    DECLARE @sql nvarchar(max);
    DECLARE @yrStr nvarchar(20) = CONVERT(nvarchar(20), @yr);

    ;WITH dates AS (
        SELECT DISTINCT f.as_of
        FROM sudz.vw_Yr_DbtFact f
        WHERE f.yr_key = @yr
    )
    SELECT
        @cols_Ttl = STUFF((SELECT N',' + QUOTENAME(CONVERT(nvarchar(10), as_of, 23) + N'_Ttl') FROM dates ORDER BY as_of FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @cols_Overd = STUFF((SELECT N',' + QUOTENAME(CONVERT(nvarchar(10), as_of, 23) + N'_Overd') FROM dates ORDER BY as_of FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @cols_Maturity = STUFF((SELECT N',' + QUOTENAME(CONVERT(nvarchar(10), as_of, 23) + N'_Maturity') FROM dates ORDER BY as_of FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @cols_invNum = STUFF((SELECT N',' + QUOTENAME(CONVERT(nvarchar(10), as_of, 23) + N'_invNum') FROM dates ORDER BY as_of FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @cols_cnNum = STUFF((SELECT N',' + QUOTENAME(CONVERT(nvarchar(10), as_of, 23) + N'_cnNum') FROM dates ORDER BY as_of FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @sel_Ttl = STUFF((SELECT N',t.' + QUOTENAME(CONVERT(nvarchar(10), as_of, 23) + N'_Ttl') FROM dates ORDER BY as_of FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @sel_Overd = STUFF((SELECT N',o.' + QUOTENAME(CONVERT(nvarchar(10), as_of, 23) + N'_Overd') FROM dates ORDER BY as_of FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @sel_Maturity = STUFF((SELECT N',m.' + QUOTENAME(CONVERT(nvarchar(10), as_of, 23) + N'_Maturity') FROM dates ORDER BY as_of FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @sel_invNum = STUFF((SELECT N',i.' + QUOTENAME(CONVERT(nvarchar(10), as_of, 23) + N'_invNum') FROM dates ORDER BY as_of FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @sel_cnNum = STUFF((SELECT N',c.' + QUOTENAME(CONVERT(nvarchar(10), as_of, 23) + N'_cnNum') FROM dates ORDER BY as_of FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N'');

    IF @cols_Ttl IS NULL
    BEGIN
        RAISERROR(N'sudz.Yr_DbtChanges_mini: нет DbtValue для yr_key=%d', 16, 1, @yr);
        RETURN;
    END;

    SET @sql = N'
;WITH src AS (
    SELECT dbtKey, as_of, invNum, cnNum, account_num, CtptOrg, ITN,
           dvTtl, dvOverd, dvDateMaturity, dvDocBase
    FROM sudz.vw_Yr_DbtFact
    WHERE yr_key = ' + @yrStr + N'
),
pivotTtl AS (
    SELECT * FROM (
        SELECT dbtKey, dvTtl, CONVERT(nvarchar(10), as_of, 23) + N''_Ttl'' AS col
        FROM src
    ) s PIVOT (MAX(dvTtl) FOR col IN (' + @cols_Ttl + N')) p
),
pivotOverd AS (
    SELECT * FROM (
        SELECT dbtKey, dvOverd, CONVERT(nvarchar(10), as_of, 23) + N''_Overd'' AS col
        FROM src
    ) s PIVOT (MAX(dvOverd) FOR col IN (' + @cols_Overd + N')) p
),
pivotMaturity AS (
    SELECT * FROM (
        SELECT dbtKey, dvDateMaturity, CONVERT(nvarchar(10), as_of, 23) + N''_Maturity'' AS col
        FROM src
    ) s PIVOT (MAX(dvDateMaturity) FOR col IN (' + @cols_Maturity + N')) p
),
pivotInv AS (
    SELECT * FROM (
        SELECT dbtKey, invNum, CONVERT(nvarchar(10), as_of, 23) + N''_invNum'' AS col
        FROM src
    ) s PIVOT (MAX(invNum) FOR col IN (' + @cols_invNum + N')) p
),
pivotCn AS (
    SELECT * FROM (
        SELECT dbtKey, cnNum, CONVERT(nvarchar(10), as_of, 23) + N''_cnNum'' AS col
        FROM src
    ) s PIVOT (MAX(cnNum) FOR col IN (' + @cols_cnNum + N')) p
),
ctx AS (
    SELECT s.dbtKey,
           MAX(CASE WHEN rn = 1 THEN account_num END) AS account_num,
           MAX(CASE WHEN rn = 1 THEN CtptOrg END) AS CtptOrg,
           MAX(CASE WHEN rn = 1 THEN ITN END) AS ITN
    FROM (
        SELECT dbtKey, account_num, CtptOrg, ITN, as_of,
               ROW_NUMBER() OVER (PARTITION BY dbtKey ORDER BY as_of DESC) AS rn
        FROM src
    ) s
    GROUP BY s.dbtKey
),
cmm AS (
    SELECT cm.cnicInvAccnt AS dbtKey,
           MAX(CASE WHEN cm.cnicType = 1 THEN cm.cnicText END) AS mery,
           MAX(CASE WHEN cm.cnicType = 8 THEN cm.cnicText END) AS curator,
           MAX(CASE WHEN cm.cnicType = 5 THEN cm.cnicText END) AS notes
    FROM sudz.yr y
    JOIN sudz.cnInvCmm cm ON cm.cnicGroup = y.yr_CmmGr
    WHERE y.yr_key = ' + @yrStr + N'
    GROUP BY cm.cnicInvAccnt
),
dt AS (
    SELECT d.cnicdInvAccnt AS dbtKey, MIN(d.cnicdDate) AS forecast_date
    FROM sudz.yr y
    JOIN sudz.cnInvCmmDt d ON d.cnicdCmmGr = y.yr_CmmGr
    WHERE y.yr_key = ' + @yrStr + N'
    GROUP BY d.cnicdInvAccnt
),
fn AS (
    SELECT f.cnicfInvAccnt AS dbtKey, MIN(f.cnicfValue) AS agent_overd
    FROM sudz.yr y
    JOIN sudz.cnInvCmmFn f ON f.cnicfCmmGr = y.yr_CmmGr
    WHERE y.yr_key = ' + @yrStr + N'
    GROUP BY f.cnicfInvAccnt
),
gr AS (
    SELECT g.cnigInvAccnt AS dbtKey, MIN(n.cnignName) AS debt_group
    FROM sudz.yr y
    JOIN sudz.cnInvGr g ON g.cnigCmmGr = y.yr_CmmGr
    JOIN sudz.cnInvGrNm n ON n.cnignKey = g.cnigGrName
    WHERE y.yr_key = ' + @yrStr + N'
    GROUP BY g.cnigInvAccnt
)
SELECT
    t.dbtKey,
    x.account_num,
    x.CtptOrg,
    x.ITN,
    ' + @sel_cnNum + N',
    ' + @sel_invNum + N',
    ' + @sel_Maturity + N',
    ' + @sel_Ttl + N',
    ' + @sel_Overd + N',
    cm.mery,
    cm.curator,
    cm.notes,
    dt.forecast_date,
    fn.agent_overd,
    gr.debt_group
FROM pivotTtl t
LEFT JOIN pivotOverd o ON o.dbtKey = t.dbtKey
LEFT JOIN pivotMaturity m ON m.dbtKey = t.dbtKey
LEFT JOIN pivotInv i ON i.dbtKey = t.dbtKey
LEFT JOIN pivotCn c ON c.dbtKey = t.dbtKey
LEFT JOIN ctx x ON x.dbtKey = t.dbtKey
LEFT JOIN cmm cm ON cm.dbtKey = t.dbtKey
LEFT JOIN dt ON dt.dbtKey = t.dbtKey
LEFT JOIN fn ON fn.dbtKey = t.dbtKey
LEFT JOIN gr ON gr.dbtKey = t.dbtKey
ORDER BY t.dbtKey;
';

    EXEC sys.sp_executesql @sql;
END
GO

-- smoke
SELECT TOP 5 * FROM sudz.vw_Yr_DbtFact ORDER BY dbtKey, as_of;
SELECT dbtKey, [2025-12-31_invNum], [2026-03-31_invNum], [2026-06-30_invNum],
       [2025-12-31_Ttl], [2026-03-31_Overd], [2026-06-30_Overd],
       mery, debt_group, forecast_date
FROM sudz.vw_Yr_DbtChanges_mini_2026
ORDER BY dbtKey;
EXEC sudz.Yr_DbtChanges_mini @yr = 901;
GO
