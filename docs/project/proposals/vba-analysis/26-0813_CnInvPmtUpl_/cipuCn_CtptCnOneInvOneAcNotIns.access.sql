-- Access QueryDef: cipuCn_CtptCnOneInvOneAcNotIns
-- Type: APPEND (64)
-- dumped: 2026-08-17 23:44

INSERT INTO ags_cnInvAccntSmpl ( ciasCnInv, ciasAccnt, ciasCn_s_org_smpl, ciasTimeOfEntry )
SELECT cipuCn_CtptCnOneInvOneAcNot.ciKey, cipuCn_CtptCnOneInvOneAcNot.account_key, cipuCn_CtptCnOneInvOneAcNot.csosKey, Now() AS toe
FROM cipuCn_CtptCnOneInvOneAcNot
GROUP BY cipuCn_CtptCnOneInvOneAcNot.ciKey, cipuCn_CtptCnOneInvOneAcNot.account_key, cipuCn_CtptCnOneInvOneAcNot.csosKey;
