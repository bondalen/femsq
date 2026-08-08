-- =============================================================================
-- S42c+d: Cst/Ag/погашено в мини-витрине Rslt
-- DEV only. Требует 14_SEED_cst_ag_82_85.sql (DbtUplCstAg).
-- погашено(d) = Overd(база года) − Overd(d); на базовой выгрузке NULL.
-- База года = yr.cn_inv_dbt_upl → upl_date.
-- sqlcmd -I
-- =============================================================================

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

---------------------------------------------------------------------
-- 1) Факт + Cst/Ag периода
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
    y.cn_inv_dbt_upl AS yr_base_upl,
    ub.upl_date AS yr_base_upl_date,
    u.upl_key,
    u.uplStatusOnDate AS as_of,
    u.upl_date,
    dv.dvDbt AS dbtKey,
    n.inNum AS invNumEnum,
    slot.idNum,
    c.cnnNum AS cnNumEnum,
    a.account_num,
    og.ogNm AS CtptOrg,
    inn.org_id_value_t AS ITN,
    bur.org_id_value_l,
    so.csoCnDate,
    dv.dvTtl,
    dv.dvOverd,
    dv.dvDateStart,
    dv.dvDateMaturity,
    dv.dvDocBase,
    dv.dvInvDbtVar,
    duca.ducaCstAgPn AS CstAgPnKey,
    pn.cstapIpgPnN AS CstAgPnCode,
    cst.cstName AS CstAgPnName,
    agog.ogNm AS AgOrg
FROM sudz.yr y
JOIN sudz.yr_upl_p yp ON yp.yr_upl_p_yr = y.yr_key
JOIN sudz.cn_inv_dbt_upl u ON u.upl_key = yp.cn_inv_dbt_upl
LEFT JOIN sudz.cn_inv_dbt_upl ub ON ub.upl_key = y.cn_inv_dbt_upl
JOIN sudz.DbtValue dv ON dv.dvUpl = u.upl_key AND dv.dvDbt IS NOT NULL
JOIN sudz.invDbtVar v ON v.idvvKey = dv.dvInvDbtVar
JOIN sudz.invDbtDbtVar dvv ON dvv.iddvInvDbtVar = v.idvvKey
JOIN sudz.invDbt slot ON slot.idKey = dvv.iddvInvDbt
JOIN ags.invNum n ON n.inKey = v.idvvInvNum
JOIN ags.cnNum c ON c.cnnKey = v.idvvCnNum
JOIN ags.accnt a ON a.account_key = v.idvvAccnt
JOIN ags.cn_s_org so ON so.cn_s_org_key = v.idvvCn_s_org
JOIN ags.cn_s_org_smpl os ON os.csosKey = so.csoCn_s_org_smpl
JOIN ags.org_id oi ON oi.org_id_key = os.csosOrgId
JOIN ags.og og ON og.ogKey = oi.org
LEFT JOIN sudz.DbtUplCstAg duca
    ON duca.ducaDbt = dv.dvDbt AND duca.ducaUpl = u.upl_key
LEFT JOIN ags.cstAgPn pn ON pn.cstapKey = duca.ducaCstAgPn
LEFT JOIN ags.cstAg ca ON ca.cstaKey = pn.cstapCsta
LEFT JOIN ags.cst cst ON cst.cstKey = ca.cstaCst
LEFT JOIN ags.ogAg oa ON oa.ogaKey = ca.cstaAg
LEFT JOIN ags.og agog ON agog.ogKey = oa.ogaOg
OUTER APPLY (
    SELECT MIN(i2.org_id_value_t) AS org_id_value_t
    FROM ags.org_id i2
    WHERE i2.org = og.ogKey AND i2.org_id_type = 2
) inn
OUTER APPLY (
    SELECT MIN(i3.org_id_value_l) AS org_id_value_l
    FROM ags.org_id i3
    WHERE i3.org = og.ogKey AND i3.org_id_type = 1
) bur;
GO

---------------------------------------------------------------------
-- 2) Широкая витрина 2026
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
acc AS (
    SELECT
        dbtKey,
        CONVERT(nvarchar(200),
            CASE
                WHEN COUNT(*) = 1 THEN MIN(acc_txt)
                ELSE STRING_AGG(acc_txt, N' / ') WITHIN GROUP (ORDER BY acc_txt)
            END
        ) AS account_num
    FROM (
        SELECT DISTINCT dbtKey, CONVERT(nvarchar(20), account_num) AS acc_txt
        FROM base
        WHERE account_num IS NOT NULL
    ) x
    GROUP BY dbtKey
),
base_overd AS (
    SELECT b.dbtKey, b.dvOverd AS base_Overd
    FROM base b
    WHERE b.upl_key = b.yr_base_upl
),
wide AS (
    SELECT
        dbtKey,

        MAX(CASE WHEN upl_date = '2026-01-15' THEN cnNumEnum END) AS [2026-01-15_cnNumEnum],
        MAX(CASE WHEN upl_date = '2026-01-15' THEN csoCnDate END) AS [2026-01-15_csoCnDate],
        MAX(CASE WHEN upl_date = '2026-01-15' THEN invNumEnum END) AS [2026-01-15_invNumEnum],
        MAX(CASE WHEN upl_date = '2026-01-15' THEN idNum END) AS [2026-01-15_idNum],
        MAX(CASE WHEN upl_date = '2026-01-15' THEN org_id_value_l END) AS [2026-01-15_org_id_value_l],
        MAX(CASE WHEN upl_date = '2026-01-15' THEN ITN END) AS [2026-01-15_ITN],
        MAX(CASE WHEN upl_date = '2026-01-15' THEN CtptOrg END) AS [2026-01-15_CtptOrg],
        MAX(CASE WHEN upl_date = '2026-01-15' THEN dvDateMaturity END) AS [2026-01-15_Maturity],
        MAX(CASE WHEN upl_date = '2026-01-15' THEN dvTtl END) AS [2026-01-15_Ttl],
        MAX(CASE WHEN upl_date = '2026-01-15' THEN dvOverd END) AS [2026-01-15_Overd],
        MAX(CASE WHEN upl_date = '2026-01-15' THEN CstAgPnKey END) AS [2026-01-15_CstAgPnKey],
        MAX(CASE WHEN upl_date = '2026-01-15' THEN CstAgPnCode END) AS [2026-01-15_CstAgPnCode],
        MAX(CASE WHEN upl_date = '2026-01-15' THEN CstAgPnName END) AS [2026-01-15_CstAgPnName],
        MAX(CASE WHEN upl_date = '2026-01-15' THEN AgOrg END) AS [2026-01-15_AgOrg],

        MAX(CASE WHEN upl_date = '2026-04-15' THEN cnNumEnum END) AS [2026-04-15_cnNumEnum],
        MAX(CASE WHEN upl_date = '2026-04-15' THEN csoCnDate END) AS [2026-04-15_csoCnDate],
        MAX(CASE WHEN upl_date = '2026-04-15' THEN invNumEnum END) AS [2026-04-15_invNumEnum],
        MAX(CASE WHEN upl_date = '2026-04-15' THEN idNum END) AS [2026-04-15_idNum],
        MAX(CASE WHEN upl_date = '2026-04-15' THEN org_id_value_l END) AS [2026-04-15_org_id_value_l],
        MAX(CASE WHEN upl_date = '2026-04-15' THEN ITN END) AS [2026-04-15_ITN],
        MAX(CASE WHEN upl_date = '2026-04-15' THEN CtptOrg END) AS [2026-04-15_CtptOrg],
        MAX(CASE WHEN upl_date = '2026-04-15' THEN dvDateMaturity END) AS [2026-04-15_Maturity],
        MAX(CASE WHEN upl_date = '2026-04-15' THEN dvTtl END) AS [2026-04-15_Ttl],
        MAX(CASE WHEN upl_date = '2026-04-15' THEN dvOverd END) AS [2026-04-15_Overd],
        MAX(CASE WHEN upl_date = '2026-04-15' THEN CstAgPnKey END) AS [2026-04-15_CstAgPnKey],
        MAX(CASE WHEN upl_date = '2026-04-15' THEN CstAgPnCode END) AS [2026-04-15_CstAgPnCode],
        MAX(CASE WHEN upl_date = '2026-04-15' THEN CstAgPnName END) AS [2026-04-15_CstAgPnName],
        MAX(CASE WHEN upl_date = '2026-04-15' THEN AgOrg END) AS [2026-04-15_AgOrg],

        MAX(CASE WHEN upl_date = '2026-07-15' THEN cnNumEnum END) AS [2026-07-15_cnNumEnum],
        MAX(CASE WHEN upl_date = '2026-07-15' THEN csoCnDate END) AS [2026-07-15_csoCnDate],
        MAX(CASE WHEN upl_date = '2026-07-15' THEN invNumEnum END) AS [2026-07-15_invNumEnum],
        MAX(CASE WHEN upl_date = '2026-07-15' THEN idNum END) AS [2026-07-15_idNum],
        MAX(CASE WHEN upl_date = '2026-07-15' THEN org_id_value_l END) AS [2026-07-15_org_id_value_l],
        MAX(CASE WHEN upl_date = '2026-07-15' THEN ITN END) AS [2026-07-15_ITN],
        MAX(CASE WHEN upl_date = '2026-07-15' THEN CtptOrg END) AS [2026-07-15_CtptOrg],
        MAX(CASE WHEN upl_date = '2026-07-15' THEN dvDateMaturity END) AS [2026-07-15_Maturity],
        MAX(CASE WHEN upl_date = '2026-07-15' THEN dvTtl END) AS [2026-07-15_Ttl],
        MAX(CASE WHEN upl_date = '2026-07-15' THEN dvOverd END) AS [2026-07-15_Overd],
        MAX(CASE WHEN upl_date = '2026-07-15' THEN CstAgPnKey END) AS [2026-07-15_CstAgPnKey],
        MAX(CASE WHEN upl_date = '2026-07-15' THEN CstAgPnCode END) AS [2026-07-15_CstAgPnCode],
        MAX(CASE WHEN upl_date = '2026-07-15' THEN CstAgPnName END) AS [2026-07-15_CstAgPnName],
        MAX(CASE WHEN upl_date = '2026-07-15' THEN AgOrg END) AS [2026-07-15_AgOrg],

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
cst_yr AS (
    SELECT
        cs.ciccInvAccnt AS dbtKey,
        MAX(pn.cstapIpgPnN) AS [Код стройки],
        MAX(c.cstName) AS [Код стройкиN]
    FROM sudz.yr y
    JOIN sudz.cnInvCmmCst cs ON cs.ciccCmmGr = y.yr_CmmGr AND cs.ciccType = 2
    JOIN ags.cstAgPn pn ON pn.cstapKey = cs.ciccCstAgPn
    JOIN ags.cstAg ca ON ca.cstaKey = pn.cstapCsta
    JOIN ags.cst c ON c.cstKey = ca.cstaCst
    WHERE y.yr_key = 901
    GROUP BY cs.ciccInvAccnt
),
dt AS (
    SELECT d.cnicdInvAccnt AS dbtKey, MIN(d.cnicdDate) AS forecast_date
    FROM sudz.yr y
    JOIN sudz.cnInvCmmDt d ON d.cnicdCmmGr = y.yr_CmmGr
    WHERE y.yr_key = 901
    GROUP BY d.cnicdInvAccnt
),
fn AS (
    SELECT f.cnicfInvAccnt AS dbtKey, MIN(f.cnicfValue) AS agent_overd
    FROM sudz.yr y
    JOIN sudz.cnInvCmmFn f ON f.cnicfCmmGr = y.yr_CmmGr
    WHERE y.yr_key = 901
    GROUP BY f.cnicfInvAccnt
),
gr AS (
    SELECT g.cnigInvAccnt AS dbtKey, MIN(n.cnignName) AS debt_group
    FROM sudz.yr y
    JOIN sudz.cnInvGr g ON g.cnigCmmGr = y.yr_CmmGr
    JOIN sudz.cnInvGrNm n ON n.cnignKey = g.cnigGrName
    WHERE y.yr_key = 901
    GROUP BY g.cnigInvAccnt
)
SELECT
    w.dbtKey,
    a.account_num,

    w.[2026-01-15_cnNumEnum], w.[2026-01-15_csoCnDate],
    w.[2026-01-15_invNumEnum], w.[2026-01-15_idNum],
    w.[2026-01-15_org_id_value_l], w.[2026-01-15_ITN], w.[2026-01-15_CtptOrg],
    w.[2026-01-15_Maturity], w.[2026-01-15_Ttl], w.[2026-01-15_Overd],
    w.[2026-01-15_CstAgPnKey], w.[2026-01-15_CstAgPnCode], w.[2026-01-15_CstAgPnName], w.[2026-01-15_AgOrg],

    w.[2026-04-15_cnNumEnum], w.[2026-04-15_csoCnDate],
    w.[2026-04-15_invNumEnum], w.[2026-04-15_idNum],
    w.[2026-04-15_org_id_value_l], w.[2026-04-15_ITN], w.[2026-04-15_CtptOrg],
    w.[2026-04-15_Maturity], w.[2026-04-15_Ttl], w.[2026-04-15_Overd],
    w.[2026-04-15_CstAgPnKey], w.[2026-04-15_CstAgPnCode], w.[2026-04-15_CstAgPnName], w.[2026-04-15_AgOrg],
    NULLIF(CONVERT(money, bo.base_Overd - w.[2026-04-15_Overd]), 0) AS [2026-04-15_погашено],

    w.[2026-07-15_cnNumEnum], w.[2026-07-15_csoCnDate],
    w.[2026-07-15_invNumEnum], w.[2026-07-15_idNum],
    w.[2026-07-15_org_id_value_l], w.[2026-07-15_ITN], w.[2026-07-15_CtptOrg],
    w.[2026-07-15_Maturity], w.[2026-07-15_Ttl], w.[2026-07-15_Overd],
    w.[2026-07-15_CstAgPnKey], w.[2026-07-15_CstAgPnCode], w.[2026-07-15_CstAgPnName], w.[2026-07-15_AgOrg],
    NULLIF(CONVERT(money, bo.base_Overd - w.[2026-07-15_Overd]), 0) AS [2026-07-15_погашено],

    c.curator AS [Куратор от Управления],
    c.mery AS [Мероприятия по погашению дебиторской задолженности],
    cy.[Код стройки],
    cy.[Код стройкиN],
    c.notes,
    d.forecast_date,
    f.agent_overd,
    g.debt_group,
    w.yr_CmmGr
FROM wide w
LEFT JOIN acc a ON a.dbtKey = w.dbtKey
LEFT JOIN base_overd bo ON bo.dbtKey = w.dbtKey
LEFT JOIN cmm c ON c.dbtKey = w.dbtKey
LEFT JOIN cst_yr cy ON cy.dbtKey = w.dbtKey
LEFT JOIN dt d ON d.dbtKey = w.dbtKey
LEFT JOIN fn f ON f.dbtKey = w.dbtKey
LEFT JOIN gr g ON g.dbtKey = w.dbtKey;
GO

---------------------------------------------------------------------
-- 3) Процедура
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

    DECLARE @cols_Ttl nvarchar(max), @cols_Overd nvarchar(max), @cols_Maturity nvarchar(max);
    DECLARE @cols_inv nvarchar(max), @cols_idNum nvarchar(max), @cols_cn nvarchar(max), @cols_cso nvarchar(max);
    DECLARE @cols_org nvarchar(max), @cols_ITN nvarchar(max), @cols_Ctpt nvarchar(max);
    DECLARE @cols_CstKey nvarchar(max), @cols_CstCode nvarchar(max), @cols_CstName nvarchar(max), @cols_Ag nvarchar(max);
    DECLARE @sel_Ttl nvarchar(max), @sel_Overd nvarchar(max), @sel_Maturity nvarchar(max);
    DECLARE @sel_inv nvarchar(max), @sel_idNum nvarchar(max), @sel_cn nvarchar(max), @sel_cso nvarchar(max);
    DECLARE @sel_org nvarchar(max), @sel_ITN nvarchar(max), @sel_Ctpt nvarchar(max);
    DECLARE @sel_CstKey nvarchar(max), @sel_CstCode nvarchar(max), @sel_CstName nvarchar(max), @sel_Ag nvarchar(max);
    DECLARE @sel_Pog nvarchar(max);
    DECLARE @sql nvarchar(max);
    DECLARE @yrStr nvarchar(20) = CONVERT(nvarchar(20), @yr);
    DECLARE @baseDate date;

    SELECT @baseDate = u.upl_date
    FROM sudz.yr y
    JOIN sudz.cn_inv_dbt_upl u ON u.upl_key = y.cn_inv_dbt_upl
    WHERE y.yr_key = @yr;

    ;WITH dates AS (
        SELECT DISTINCT f.upl_date
        FROM sudz.vw_Yr_DbtFact f
        WHERE f.yr_key = @yr
    )
    SELECT
        @cols_Ttl = STUFF((SELECT N',' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_Ttl') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @cols_Overd = STUFF((SELECT N',' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_Overd') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @cols_Maturity = STUFF((SELECT N',' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_Maturity') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @cols_inv = STUFF((SELECT N',' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_invNumEnum') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @cols_idNum = STUFF((SELECT N',' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_idNum') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @cols_cn = STUFF((SELECT N',' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_cnNumEnum') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @cols_cso = STUFF((SELECT N',' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_csoCnDate') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @cols_org = STUFF((SELECT N',' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_org_id_value_l') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @cols_ITN = STUFF((SELECT N',' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_ITN') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @cols_Ctpt = STUFF((SELECT N',' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_CtptOrg') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @cols_CstKey = STUFF((SELECT N',' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_CstAgPnKey') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @cols_CstCode = STUFF((SELECT N',' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_CstAgPnCode') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @cols_CstName = STUFF((SELECT N',' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_CstAgPnName') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @cols_Ag = STUFF((SELECT N',' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_AgOrg') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @sel_Ttl = STUFF((SELECT N',t.' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_Ttl') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @sel_Overd = STUFF((SELECT N',o.' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_Overd') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @sel_Maturity = STUFF((SELECT N',m.' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_Maturity') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @sel_inv = STUFF((SELECT N',iv.' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_invNumEnum') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @sel_idNum = STUFF((SELECT N',idn.' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_idNum') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @sel_cn = STUFF((SELECT N',c.' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_cnNumEnum') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @sel_cso = STUFF((SELECT N',cs.' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_csoCnDate') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @sel_org = STUFF((SELECT N',og.' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_org_id_value_l') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @sel_ITN = STUFF((SELECT N',it.' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_ITN') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @sel_Ctpt = STUFF((SELECT N',ct.' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_CtptOrg') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @sel_CstKey = STUFF((SELECT N',ck.' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_CstAgPnKey') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @sel_CstCode = STUFF((SELECT N',cc.' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_CstAgPnCode') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @sel_CstName = STUFF((SELECT N',cn.' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_CstAgPnName') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N''),
        @sel_Ag = STUFF((SELECT N',ag.' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_AgOrg') FROM dates ORDER BY upl_date FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N'');

    /* погашено — для всех дат кроме базы года */
    ;WITH dates AS (
        SELECT DISTINCT f.upl_date
        FROM sudz.vw_Yr_DbtFact f
        WHERE f.yr_key = @yr AND f.upl_date <> @baseDate
    )
    SELECT @sel_Pog = STUFF((
        SELECT N', CONVERT(money, bo.base_Overd - o.' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_Overd')
             + N') AS ' + QUOTENAME(CONVERT(nvarchar(10), upl_date, 23) + N'_погашено')
        FROM dates ORDER BY upl_date
        FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, N'');

    IF @cols_Ttl IS NULL
    BEGIN
        RAISERROR(N'sudz.Yr_DbtChanges_mini: нет DbtValue для yr_key=%d', 16, 1, @yr);
        RETURN;
    END;

    DECLARE @pogPart nvarchar(max) = N'';
    IF @sel_Pog IS NOT NULL AND LEN(@sel_Pog) > 0
        SET @pogPart = N', ' + @sel_Pog;

    SET @sql = N'
;WITH src AS (
    SELECT dbtKey, upl_date, invNumEnum, idNum, cnNumEnum, csoCnDate,
           org_id_value_l, ITN, CtptOrg, account_num,
           dvTtl, dvOverd, dvDateMaturity,
           CstAgPnKey, CstAgPnCode, CstAgPnName, AgOrg,
           yr_base_upl_date
    FROM sudz.vw_Yr_DbtFact
    WHERE yr_key = ' + @yrStr + N'
),
pivotTtl AS (
    SELECT * FROM (SELECT dbtKey, dvTtl, CONVERT(nvarchar(10), upl_date, 23) + N''_Ttl'' AS col FROM src) s
    PIVOT (MAX(dvTtl) FOR col IN (' + @cols_Ttl + N')) p
),
pivotOverd AS (
    SELECT * FROM (SELECT dbtKey, dvOverd, CONVERT(nvarchar(10), upl_date, 23) + N''_Overd'' AS col FROM src) s
    PIVOT (MAX(dvOverd) FOR col IN (' + @cols_Overd + N')) p
),
pivotMaturity AS (
    SELECT * FROM (SELECT dbtKey, dvDateMaturity, CONVERT(nvarchar(10), upl_date, 23) + N''_Maturity'' AS col FROM src) s
    PIVOT (MAX(dvDateMaturity) FOR col IN (' + @cols_Maturity + N')) p
),
pivotInv AS (
    SELECT * FROM (SELECT dbtKey, invNumEnum, CONVERT(nvarchar(10), upl_date, 23) + N''_invNumEnum'' AS col FROM src) s
    PIVOT (MAX(invNumEnum) FOR col IN (' + @cols_inv + N')) p
),
pivotIdNum AS (
    SELECT * FROM (SELECT dbtKey, idNum, CONVERT(nvarchar(10), upl_date, 23) + N''_idNum'' AS col FROM src) s
    PIVOT (MAX(idNum) FOR col IN (' + @cols_idNum + N')) p
),
pivotCn AS (
    SELECT * FROM (SELECT dbtKey, cnNumEnum, CONVERT(nvarchar(10), upl_date, 23) + N''_cnNumEnum'' AS col FROM src) s
    PIVOT (MAX(cnNumEnum) FOR col IN (' + @cols_cn + N')) p
),
pivotCso AS (
    SELECT * FROM (SELECT dbtKey, csoCnDate, CONVERT(nvarchar(10), upl_date, 23) + N''_csoCnDate'' AS col FROM src) s
    PIVOT (MAX(csoCnDate) FOR col IN (' + @cols_cso + N')) p
),
pivotOrg AS (
    SELECT * FROM (SELECT dbtKey, org_id_value_l, CONVERT(nvarchar(10), upl_date, 23) + N''_org_id_value_l'' AS col FROM src) s
    PIVOT (MAX(org_id_value_l) FOR col IN (' + @cols_org + N')) p
),
pivotITN AS (
    SELECT * FROM (SELECT dbtKey, ITN, CONVERT(nvarchar(10), upl_date, 23) + N''_ITN'' AS col FROM src) s
    PIVOT (MAX(ITN) FOR col IN (' + @cols_ITN + N')) p
),
pivotCtpt AS (
    SELECT * FROM (SELECT dbtKey, CtptOrg, CONVERT(nvarchar(10), upl_date, 23) + N''_CtptOrg'' AS col FROM src) s
    PIVOT (MAX(CtptOrg) FOR col IN (' + @cols_Ctpt + N')) p
),
pivotCstKey AS (
    SELECT * FROM (SELECT dbtKey, CstAgPnKey, CONVERT(nvarchar(10), upl_date, 23) + N''_CstAgPnKey'' AS col FROM src) s
    PIVOT (MAX(CstAgPnKey) FOR col IN (' + @cols_CstKey + N')) p
),
pivotCstCode AS (
    SELECT * FROM (SELECT dbtKey, CstAgPnCode, CONVERT(nvarchar(10), upl_date, 23) + N''_CstAgPnCode'' AS col FROM src) s
    PIVOT (MAX(CstAgPnCode) FOR col IN (' + @cols_CstCode + N')) p
),
pivotCstName AS (
    SELECT * FROM (SELECT dbtKey, CstAgPnName, CONVERT(nvarchar(10), upl_date, 23) + N''_CstAgPnName'' AS col FROM src) s
    PIVOT (MAX(CstAgPnName) FOR col IN (' + @cols_CstName + N')) p
),
pivotAg AS (
    SELECT * FROM (SELECT dbtKey, AgOrg, CONVERT(nvarchar(10), upl_date, 23) + N''_AgOrg'' AS col FROM src) s
    PIVOT (MAX(AgOrg) FOR col IN (' + @cols_Ag + N')) p
),
acc AS (
    SELECT dbtKey,
           CONVERT(nvarchar(200),
               CASE WHEN COUNT(*) = 1 THEN MIN(acc_txt)
                    ELSE STRING_AGG(acc_txt, N'' / '') WITHIN GROUP (ORDER BY acc_txt) END
           ) AS account_num
    FROM (
        SELECT DISTINCT dbtKey, CONVERT(nvarchar(20), account_num) AS acc_txt
        FROM src WHERE account_num IS NOT NULL
    ) x
    GROUP BY dbtKey
),
bo AS (
    SELECT dbtKey, dvOverd AS base_Overd
    FROM src
    WHERE upl_date = ''' + CONVERT(nvarchar(10), @baseDate, 23) + N'''
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
cst_yr AS (
    SELECT cs.ciccInvAccnt AS dbtKey,
           MAX(pn.cstapIpgPnN) AS cst_code,
           MAX(c.cstName) AS cst_name
    FROM sudz.yr y
    JOIN sudz.cnInvCmmCst cs ON cs.ciccCmmGr = y.yr_CmmGr AND cs.ciccType = 2
    JOIN ags.cstAgPn pn ON pn.cstapKey = cs.ciccCstAgPn
    JOIN ags.cstAg ca ON ca.cstaKey = pn.cstapCsta
    JOIN ags.cst c ON c.cstKey = ca.cstaCst
    WHERE y.yr_key = ' + @yrStr + N'
    GROUP BY cs.ciccInvAccnt
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
    a.account_num,
    ' + @sel_cn + N',
    ' + @sel_cso + N',
    ' + @sel_inv + N',
    ' + @sel_idNum + N',
    ' + @sel_org + N',
    ' + @sel_ITN + N',
    ' + @sel_Ctpt + N',
    ' + @sel_Maturity + N',
    ' + @sel_Ttl + N',
    ' + @sel_Overd + N',
    ' + @sel_CstKey + N',
    ' + @sel_CstCode + N',
    ' + @sel_CstName + N',
    ' + @sel_Ag + @pogPart + N',
    cm.curator AS [Куратор от Управления],
    cm.mery AS [Мероприятия по погашению дебиторской задолженности],
    cy.cst_code AS [Код стройки],
    cy.cst_name AS [Код стройкиN],
    cm.notes,
    dt.forecast_date,
    fn.agent_overd,
    gr.debt_group
FROM pivotTtl t
LEFT JOIN pivotOverd o ON o.dbtKey = t.dbtKey
LEFT JOIN pivotMaturity m ON m.dbtKey = t.dbtKey
LEFT JOIN pivotInv iv ON iv.dbtKey = t.dbtKey
LEFT JOIN pivotIdNum idn ON idn.dbtKey = t.dbtKey
LEFT JOIN pivotCn c ON c.dbtKey = t.dbtKey
LEFT JOIN pivotCso cs ON cs.dbtKey = t.dbtKey
LEFT JOIN pivotOrg og ON og.dbtKey = t.dbtKey
LEFT JOIN pivotITN it ON it.dbtKey = t.dbtKey
LEFT JOIN pivotCtpt ct ON ct.dbtKey = t.dbtKey
LEFT JOIN pivotCstKey ck ON ck.dbtKey = t.dbtKey
LEFT JOIN pivotCstCode cc ON cc.dbtKey = t.dbtKey
LEFT JOIN pivotCstName cn ON cn.dbtKey = t.dbtKey
LEFT JOIN pivotAg ag ON ag.dbtKey = t.dbtKey
LEFT JOIN acc a ON a.dbtKey = t.dbtKey
LEFT JOIN bo ON bo.dbtKey = t.dbtKey
LEFT JOIN cmm cm ON cm.dbtKey = t.dbtKey
LEFT JOIN cst_yr cy ON cy.dbtKey = t.dbtKey
LEFT JOIN dt ON dt.dbtKey = t.dbtKey
LEFT JOIN fn ON fn.dbtKey = t.dbtKey
LEFT JOIN gr ON gr.dbtKey = t.dbtKey
ORDER BY t.dbtKey;
';

    EXEC sys.sp_executesql @sql;
END
GO

-- smoke
SELECT dbtKey, account_num,
       [2026-01-15_CstAgPnCode], [2026-04-15_AgOrg],
       [2026-04-15_Overd], [2026-04-15_погашено],
       [Код стройки], [Куратор от Управления]
FROM sudz.vw_Yr_DbtChanges_mini_2026
ORDER BY dbtKey;
EXEC sudz.Yr_DbtChanges_mini @yr = 901;
GO
