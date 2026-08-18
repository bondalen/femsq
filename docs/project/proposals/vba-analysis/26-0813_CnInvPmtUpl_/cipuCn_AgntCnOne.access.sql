-- Access QueryDef: cipuCn_AgntCnOne
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT n.AgNum, n.AgName, n.CnName, n.org_id_key, n.CountCnKey, n.cn_key, o.csosKey
FROM (SELECT m.AgNum, m.AgName, m.CnName, m.org_id_key, m.CountCnKey, e.cn_key FROM (SELECT u.AgNum, u.AgName, u.CnName, u.org_id_key, count(u.cn_key) AS CountCnKey FROM (SELECT z.AgNum, z.AgName, z.CnName, z.org_id_key, e.cn_key FROM (SELECT AgNum, AgName, IIf(isnull(a.CnName),"NullИлиПусто",IIf(a.CnName="","NullИлиПусто",a.CnName)) AS CnName, org_id_key FROM cipuCn_Agnt AS a)  AS z LEFT JOIN agsCnCtptAgentSmplBuirg AS e ON (z.AgNum = e.org_id_value_l) AND (z.CnName = e.cn_number) GROUP BY z.AgNum, z.AgName, z.CnName, z.org_id_key, e.cn_key)  AS u GROUP BY u.AgNum, u.AgName, u.CnName, u.org_id_key HAVING (((Count(u.cn_key))=1)))  AS m LEFT JOIN agsCnCtptAgentSmplBuirg AS e ON (m.CnName = e.cn_number) AND (m.AgNum = e.org_id_value_l) GROUP BY m.AgNum, m.AgName, m.CnName, m.org_id_key, m.CountCnKey, e.cn_key)  AS n LEFT JOIN agsCnCtptAgentSmplBuirgOne AS o ON (n.AgNum = o.org_id_value_l) AND (n.cn_key = o.cn_key)
GROUP BY n.AgNum, n.AgName, n.CnName, n.org_id_key, n.CountCnKey, n.cn_key, o.csosKey;
