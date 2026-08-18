-- Access QueryDef: cipuDocNot
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT a.ciputCnInvDocCode
FROM (SELECT ciputCnInvDocCode FROM CnInvPmtUplTblNull GROUP BY ciputCnInvDocCode)  AS a LEFT JOIN ags_cn_inv_doc ON a.ciputCnInvDocCode = ags_cn_inv_doc.cn_inv_doc_kod
WHERE (((ags_cn_inv_doc.cn_inv_doc_key) Is Null));
