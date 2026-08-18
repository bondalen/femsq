-- Access QueryDef: cipuCn_CtptCnOneInvNot
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT t.CntrPrtNum, t.CntrPrtName, t.CnName, t.cn_key, t.org_id_key, t.csosKey, t.ciputCnInv, Count(i.ciKey) AS [Count-ciKey], agsInvNumCount.inNumCount
FROM (cipuCn_CtptCnOneInv AS t LEFT JOIN (SELECT c.ciKey, c.ciCn, c.ciInv, n.inNumNull FROM (ags_cnInv AS c INNER JOIN ags_inv AS i ON c.ciInv = i.iKey) INNER JOIN ags_invNum AS n ON i.iKey = n.inInv)  AS i ON (t.cn_key = i.ciCn) AND (t.ciputCnInv = i.inNumNull)) LEFT JOIN agsInvNumCount ON t.ciputCnInv = agsInvNumCount.inNumNull
GROUP BY t.CntrPrtNum, t.CntrPrtName, t.CnName, t.cn_key, t.org_id_key, t.csosKey, t.ciputCnInv, agsInvNumCount.inNumCount
HAVING (((Count(i.ciKey))=0));
