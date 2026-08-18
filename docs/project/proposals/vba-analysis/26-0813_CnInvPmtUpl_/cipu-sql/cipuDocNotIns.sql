-- Access QueryDef: cipuDocNotIns
-- Type: APPEND (64)
-- dumped: 2026-08-17 23:44

INSERT INTO ags_cn_inv_doc ( cn_inv_doc_kod )
SELECT cipuDocNot.ciputCnInvDocCode
FROM cipuDocNot;
