-- Access QueryDef: cipuCn_CtptCnOneInvOne
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT a.CntrPrtNum, a.CntrPrtName, a.CnName, a.cn_key, a.csosKey, a.ciputCnInv, a.CountCiKey, i.ciKey
FROM (SELECT z.CntrPrtNum, z.CntrPrtName, z.CnName, z.cn_key, z.csosKey, z.ciputCnInv, Count(i.ciKey) AS CountCiKey FROM cipuCn_CtptCnOneInv AS z LEFT JOIN (SELECT c.ciKey, c.ciCn, c.ciInv, n.inNumNull FROM (ags_cnInv AS c INNER JOIN ags_inv AS i ON c.ciInv = i.iKey) INNER JOIN ags_invNum AS n ON i.iKey = n.inInv)  AS i ON (z.ciputCnInv = i.inNumNull) AND (z.cn_key = i.ciCn) GROUP BY z.CntrPrtNum, z.CntrPrtName, z.CnName, z.cn_key, z.csosKey, z.ciputCnInv HAVING (((Count(i.ciKey))=1)))  AS a LEFT JOIN (SELECT c.ciKey, c.ciCn, c.ciInv, n.inNumNull FROM (ags_cnInv AS c INNER JOIN ags_inv AS i ON c.ciInv = i.iKey) INNER JOIN ags_invNum AS n ON i.iKey = n.inInv)  AS i ON (a.cn_key = i.ciCn) AND (a.ciputCnInv = i.inNumNull);
