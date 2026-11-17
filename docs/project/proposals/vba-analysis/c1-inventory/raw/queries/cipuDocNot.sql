-- Access QueryDef: cipuDocNot
-- Type: 0

SELECT a.ciputCnInvDocCode
FROM (SELECT ciputCnInvDocCode FROM CnInvPmtUplTblNull GROUP BY ciputCnInvDocCode)  AS a LEFT JOIN ags_cn_inv_doc ON a.ciputCnInvDocCode = ags_cn_inv_doc.cn_inv_doc_kod
WHERE (((ags_cn_inv_doc.cn_inv_doc_key) Is Null));
