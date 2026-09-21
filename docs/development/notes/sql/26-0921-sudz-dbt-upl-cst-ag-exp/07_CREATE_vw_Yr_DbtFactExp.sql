-- 07_CREATE_vw_Yr_DbtFactExp.sql — витрина эксперимента строек (§4)
-- Копия зерна vw_Yr_DbtFact, но CstAgPn* / AgOrg из DbtUplCstAgExp.
-- Канон vw_Yr_DbtFact не меняется.
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'sudz.vw_Yr_DbtFactExp', N'V') IS NOT NULL
    DROP VIEW sudz.vw_Yr_DbtFactExp;
GO

CREATE VIEW sudz.vw_Yr_DbtFactExp
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
    duex.duexCstAgPn AS CstAgPnKey,
    duex.duexCode AS CstAgPnCode,
    duex.duexName AS CstAgPnName,
    duex.duexRule AS CstAgPnRule,
    duex.duexDetail AS CstAgPnDetail,
    CASE
        WHEN duex.duexCstAgPn IS NOT NULL THEN agog.ogNm
        ELSE NULL
    END AS AgOrg
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
LEFT JOIN sudz.DbtUplCstAgExp AS duex
    ON duex.duexDbt = idd.iddDbt AND duex.duexUpl = u.upl_key
LEFT JOIN ags.cstAgPn AS pn ON pn.cstapKey = duex.duexCstAgPn
LEFT JOIN ags.cstAg AS ca ON ca.cstaKey = pn.cstapCsta
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
