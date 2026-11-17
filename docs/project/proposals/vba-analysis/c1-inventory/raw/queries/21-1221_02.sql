-- Access QueryDef: 21-1221_02
-- Type: 0

SELECT e.cstCode, e.cstapKey, e.cnInvKey, e.CountCiasKey
FROM (SELECT d.cstCode, d.cstapKey, d.cnInvKey, Count(s.ciasKey) AS CountCiasKey FROM (SELECT c.cstCode, c.cstapKey, ags_impCmmts.cnInvKey FROM (SELECT b.cstCode, ags_cstAgPn.cstapKey FROM (SELECT trim(a.cstCode) AS cstCode FROM ags_impCmmts AS a WHERE (((a.cstCode) Is Not Null)) GROUP BY a.cstCode)  AS b LEFT JOIN ags_cstAgPn ON b.cstCode = ags_cstAgPn.cstapIpgPnN WHERE (((ags_cstAgPn.cstapKey) Is Not Null)))  AS c INNER JOIN ags_impCmmts ON c.cstCode = ags_impCmmts.cstCode)  AS d LEFT JOIN ags_cnInvAccntSmpl AS s ON d.cnInvKey = s.ciasCnInv GROUP BY d.cstCode, d.cstapKey, d.cnInvKey ORDER BY Count(s.ciasKey) DESC)  AS e
WHERE (((e.CountCiasKey)=2));
