-- Access QueryDef: cipuCn_AgNot
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT b.cn_key, b.CnName, b.ciputAgentNum, b.ciputAgentName, b.CountCsosKey, s.cn_s_key, i.org_id_key
FROM ((SELECT a.cn_key, a.CnName, a.ciputAgentNum, a.ciputAgentName, a.CountCsosKey FROM cipuCn_Ag AS a WHERE (((a.CountCsosKey)=0)))  AS b LEFT JOIN (SELECT * FROM ags_cn_s AS a WHERE a.cn_s_type = 1)  AS s ON b.cn_key = s.cn_key) LEFT JOIN (SELECT * FROM ags_org_id AS oi WHERE oi.org_id_type = 1)  AS i ON b.ciputAgentNum = i.org_id_value_l;
