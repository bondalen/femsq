-- Access QueryDef: ciduCnCtptInvAccSmplExtAccNotIns
-- Type: APPEND (64)
-- dumped: 2026-08-24 15:25

INSERT INTO ags_cnInvAccnt ( ciaCnInvAccntSmpl, ciaCn_s_org, ciaName, ciaTimeOfEntry )
SELECT ciduCnCtptInvAccSmplExtAccNot.ciasKey, ciduCnCtptInvAccSmplExtAccNot.cn_s_org_key, IIf([cidutCnInvNameNull]="NullИлиПусто",Null,[cidutCnInvNameNull]) AS nnn, Now() AS ddd
FROM ciduCnCtptInvAccSmplExtAccNot;
