-- Access QueryDef: cipuCn_AgOne
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT b.cn_key, b.CnName, b.ciputAgentNum, b.ciputAgentName, c.csosKey
FROM (SELECT a.cn_key, a.CnName, a.ciputAgentNum, a.ciputAgentName, a.CountCsosKey FROM cipuCn_Ag AS a WHERE (((a.CountCsosKey)=1)))  AS b LEFT JOIN agsCnCtptAgentSmplBuirgOne AS c ON (b.cn_key = c.cn_key) AND (b.ciputAgentNum = c.org_id_value_l);
