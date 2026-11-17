-- Access QueryDef: cipuCn_CtptCnOneInvOneAcNotIns
-- Type: 64

INSERT INTO ags_cnInvAccntSmpl ( ciasCnInv, ciasAccnt, ciasCn_s_org_smpl, ciasTimeOfEntry )
SELECT cipuCn_CtptCnOneInvOneAcNot.ciKey, cipuCn_CtptCnOneInvOneAcNot.account_key, cipuCn_CtptCnOneInvOneAcNot.csosKey, Now() AS toe
FROM cipuCn_CtptCnOneInvOneAcNot
GROUP BY cipuCn_CtptCnOneInvOneAcNot.ciKey, cipuCn_CtptCnOneInvOneAcNot.account_key, cipuCn_CtptCnOneInvOneAcNot.csosKey;
