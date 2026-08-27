/*
 * B1 DRAFT — vw_Yr_DbtFact M2 (dbtKey через invDbtDbt, якорь dvInvDbt)
 *
 * НЕ ПРИМЕНЯТЬ до гейта B1-prep P9 (GO).
 * Требует: 01/02 (нет dvDbt, есть dvInvDbt).
 *
 * dbtKey = idd.iddDbt (LEFT JOIN — Value без канона Dbt допустим).
 * DbtUplCstAg — по выводимому dbtKey, не по dv.dvDbt.
 *
 * После recreate fact: mini_2026 (SELECT * FROM fact) снова валиден без правок текста.
 * Детальная сверка SELECT — B1-prep P5.
 * lastUpdated: 2026-08-26
 */

SET NOCOUNT ON;
GO

/* ===== sudz ===== */
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
    idd.iddDbt AS dbtKey,
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
    dv.dvInvDbt,
    duca.ducaCstAgPn AS CstAgPnKey,
    pn.cstapIpgPnN AS CstAgPnCode,
    cst.cstName AS CstAgPnName,
    agog.ogNm AS AgOrg
FROM sudz.yr AS y
JOIN sudz.yr_upl_p AS yp ON yp.yr_upl_p_yr = y.yr_key
JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl
LEFT JOIN sudz.cn_inv_dbt_upl AS ub ON ub.upl_key = y.cn_inv_dbt_upl
JOIN sudz.DbtValue AS dv ON dv.dvUpl = u.upl_key
JOIN sudz.invDbt AS slot ON slot.idKey = dv.dvInvDbt
JOIN sudz.invDbtVar AS v ON v.idvvKey = dv.dvInvDbtVar
LEFT JOIN sudz.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
JOIN ags.invNum AS n ON n.inKey = v.idvvInvNum
JOIN ags.cnNum AS c ON c.cnnKey = v.idvvCnNum
JOIN ags.accnt AS a ON a.account_key = v.idvvAccnt
JOIN ags.cn_s_org AS so ON so.cn_s_org_key = v.idvvCn_s_org
JOIN ags.cn_s_org_smpl AS os ON os.csosKey = so.csoCn_s_org_smpl
JOIN ags.org_id AS oi ON oi.org_id_key = os.csosOrgId
JOIN ags.og AS og ON og.ogKey = oi.org
LEFT JOIN sudz.DbtUplCstAg AS duca
    ON duca.ducaDbt = idd.iddDbt AND duca.ducaUpl = u.upl_key
LEFT JOIN ags.cstAgPn AS pn ON pn.cstapKey = duca.ducaCstAgPn
LEFT JOIN ags.cstAg AS ca ON ca.cstaKey = pn.cstapCsta
LEFT JOIN ags.cst AS cst ON cst.cstKey = ca.cstaCst
LEFT JOIN ags.ogAg AS oa ON oa.ogaKey = ca.cstaAg
LEFT JOIN ags.og AS agog ON agog.ogKey = oa.ogaOg
OUTER APPLY (
    SELECT MIN(i2.org_id_value_t) AS org_id_value_t
    FROM ags.org_id AS i2
    WHERE i2.org = og.ogKey AND i2.org_id_type = 2
) AS inn
OUTER APPLY (
    SELECT MIN(i3.org_id_value_l) AS org_id_value_l
    FROM ags.org_id AS i3
    WHERE i3.org = og.ogKey AND i3.org_id_type = 1
) AS bur;
GO

/* ===== test_sudz ===== */
IF OBJECT_ID(N'test_sudz.vw_Yr_DbtFact', N'V') IS NOT NULL
    DROP VIEW test_sudz.vw_Yr_DbtFact;
GO

CREATE VIEW test_sudz.vw_Yr_DbtFact
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
    idd.iddDbt AS dbtKey,
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
    dv.dvInvDbt,
    duca.ducaCstAgPn AS CstAgPnKey,
    pn.cstapIpgPnN AS CstAgPnCode,
    cst.cstName AS CstAgPnName,
    agog.ogNm AS AgOrg
FROM test_sudz.yr AS y
JOIN test_sudz.yr_upl_p AS yp ON yp.yr_upl_p_yr = y.yr_key
JOIN test_sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl
LEFT JOIN test_sudz.cn_inv_dbt_upl AS ub ON ub.upl_key = y.cn_inv_dbt_upl
JOIN test_sudz.DbtValue AS dv ON dv.dvUpl = u.upl_key
JOIN test_sudz.invDbt AS slot ON slot.idKey = dv.dvInvDbt
JOIN test_sudz.invDbtVar AS v ON v.idvvKey = dv.dvInvDbtVar
LEFT JOIN test_sudz.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
JOIN ags.invNum AS n ON n.inKey = v.idvvInvNum
JOIN ags.cnNum AS c ON c.cnnKey = v.idvvCnNum
JOIN ags.accnt AS a ON a.account_key = v.idvvAccnt
JOIN ags.cn_s_org AS so ON so.cn_s_org_key = v.idvvCn_s_org
JOIN ags.cn_s_org_smpl AS os ON os.csosKey = so.csoCn_s_org_smpl
JOIN ags.org_id AS oi ON oi.org_id_key = os.csosOrgId
JOIN ags.og AS og ON og.ogKey = oi.org
LEFT JOIN test_sudz.DbtUplCstAg AS duca
    ON duca.ducaDbt = idd.iddDbt AND duca.ducaUpl = u.upl_key
LEFT JOIN ags.cstAgPn AS pn ON pn.cstapKey = duca.ducaCstAgPn
LEFT JOIN ags.cstAg AS ca ON ca.cstaKey = pn.cstapCsta
LEFT JOIN ags.cst AS cst ON cst.cstKey = ca.cstaCst
LEFT JOIN ags.ogAg AS oa ON oa.ogaKey = ca.cstaAg
LEFT JOIN ags.og AS agog ON agog.ogKey = oa.ogaOg
OUTER APPLY (
    SELECT MIN(i2.org_id_value_t) AS org_id_value_t
    FROM ags.org_id AS i2
    WHERE i2.org = og.ogKey AND i2.org_id_type = 2
) AS inn
OUTER APPLY (
    SELECT MIN(i3.org_id_value_l) AS org_id_value_l
    FROM ags.org_id AS i3
    WHERE i3.org = og.ogKey AND i3.org_id_type = 1
) AS bur;
GO

PRINT N'vw_Yr_DbtFact M2 created (sudz + test_sudz). Smoke: SELECT TOP 20 — P5.';
GO
