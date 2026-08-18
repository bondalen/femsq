-- Access QueryDef: cipuCn_CtptCnOneInvTwo
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT t.CntrPrtNum, t.CntrPrtName, t.CnName, t.cn_key, t.ciputCnInv, Count(i.ciKey) AS [Count-ciKey]
FROM cipuCn_CtptCnOneInv AS t LEFT JOIN (SELECT c.ciKey, c.ciCn, c.ciInv, n.inNumNull FROM (ags_cnInv AS c INNER JOIN ags_inv AS i ON c.ciInv = i.iKey) INNER JOIN ags_invNum AS n ON i.iKey = n.inInv)  AS i ON (t.ciputCnInv = i.inNumNull) AND (t.cn_key = i.ciCn)
GROUP BY t.CntrPrtNum, t.CntrPrtName, t.CnName, t.cn_key, t.ciputCnInv
HAVING (((Count(i.ciKey))>1))
ORDER BY Count(i.ciKey) DESC;
