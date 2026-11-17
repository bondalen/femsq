-- Access QueryDef: ags_Yr_DbtCst
-- Type: 16

PARAMETERS gr Long;
TRANSFORM Min(a.ciccKey) AS [Min-ciccKey]
SELECT a.ciccInvAccnt
FROM (SELECT ags_cnInvCmmCst.ciccCmmGr, ags_cnInvCmmCst.ciccInvAccnt, ags_cnInvCmmCstN.ciccnName, ags_cnInvCmmCst.ciccKey FROM ags_cnInvCmmCst INNER JOIN ags_cnInvCmmCstN ON ags_cnInvCmmCst.ciccType = ags_cnInvCmmCstN.ciccnKey WHERE (((ags_cnInvCmmCst.ciccCmmGr)=[gr])))  AS a
GROUP BY a.ciccInvAccnt
PIVOT a.ciccnName;
