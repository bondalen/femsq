-- Access QueryDef: cipuCn_AgTwo
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT a.cn_key, a.CnName, a.ciputAgentNum, a.ciputAgentName, a.CountCsosKey
FROM cipuCn_Ag AS a
WHERE (((a.CountCsosKey)>1));
