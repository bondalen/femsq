-- Access QueryDef: cipuCn_AgTwo
-- Type: 0

SELECT a.cn_key, a.CnName, a.ciputAgentNum, a.ciputAgentName, a.CountCsosKey
FROM cipuCn_Ag AS a
WHERE (((a.CountCsosKey)>1));
