-- Access QueryDef: ags_Yr_DbtDtT
-- Type: 16

PARAMETERS gr Long;
TRANSFORM Min(a.cnicdDate) AS [Min-cnicdDate]
SELECT a.cnicdInvAccnt
FROM (SELECT ags_cnInvCmmDt.cnicdCmmGr, ags_cnInvCmmDt.cnicdInvAccnt, ags_cnInvCmmDtN.cnicdnName, ags_cnInvCmmDt.cnicdDate FROM ags_cnInvCmmDt INNER JOIN ags_cnInvCmmDtN ON ags_cnInvCmmDt.cnicdName = ags_cnInvCmmDtN.cnicdnKey WHERE (((ags_cnInvCmmDt.cnicdCmmGr)=[gr])))  AS a
GROUP BY a.cnicdInvAccnt
ORDER BY a.cnicdInvAccnt, a.cnicdnName
PIVOT a.cnicdnName;
