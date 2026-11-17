-- Access QueryDef: ciduCnCtptInvAccSmplExtAccNotIns
-- Type: 64

INSERT INTO ags_cnInvAccnt ( ciaCnInvAccntSmpl, ciaCn_s_org, ciaName, ciaTimeOfEntry )
SELECT ciduCnCtptInvAccSmplExtAccNot.ciasKey, ciduCnCtptInvAccSmplExtAccNot.cn_s_org_key, IIf([cidutCnInvNameNull]="NullИлиПусто",Null,[cidutCnInvNameNull]) AS nnn, Now() AS ddd
FROM ciduCnCtptInvAccSmplExtAccNot;
