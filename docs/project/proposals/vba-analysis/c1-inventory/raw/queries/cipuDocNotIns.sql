-- Access QueryDef: cipuDocNotIns
-- Type: 64

INSERT INTO ags_cn_inv_doc ( cn_inv_doc_kod )
SELECT cipuDocNot.ciputCnInvDocCode
FROM cipuDocNot;
