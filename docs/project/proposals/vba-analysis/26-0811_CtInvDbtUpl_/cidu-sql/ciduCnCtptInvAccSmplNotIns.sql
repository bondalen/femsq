-- Access QueryDef: ciduCnCtptInvAccSmplNotIns
-- Type: APPEND (64)
-- dumped: 2026-08-24 15:25

INSERT INTO ags_cnInvAccntSmpl ( ciasCnInv, ciasAccnt, ciasCn_s_org_smpl, ciasTimeOfEntry )
SELECT a.ciKey, a.account_key, z.csosKey, Now() AS ddd
FROM ciduCnCtptInvAccSmplNot AS a LEFT JOIN (SELECT css.csosKey, cn.cnnNum, cn.cnnNumNull, i.org_id_value_l, i.org_id_type, cs.cn_s_type FROM (((ags_cn_s_org_smpl AS css INNER JOIN ags_cn_s AS cs ON css.csosCn_s = cs.cn_s_key) INNER JOIN ags_cn AS c ON cs.cn_key = c.cn_key) INNER JOIN ags_cnNum AS cn ON c.cn_key = cn.cnnCn) INNER JOIN ags_org_id AS i ON css.csosOrgId = i.org_id_key WHERE (((i.org_id_value_l) Is Not Null) AND ((i.org_id_type)=1) AND ((cs.cn_s_type)=2)))  AS z ON (a.cidutCntrPrtNum = z.org_id_value_l) AND (a.cidutCnNameNull = z.cnnNumNull)
WHERE (((z.csosKey) Is Not Null))
GROUP BY a.ciKey, a.account_key, z.csosKey;
