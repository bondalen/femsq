-- Access QueryDef: ags_Yr_DbtCmm
-- Type: 16

PARAMETERS gr Long;
TRANSFORM Min(a.cnicKey) AS [Min-cnicKey]
SELECT a.cnicInvAccnt
FROM (SELECT ags_cnInvCmm.cnicGroup, ags_cnInvCmm.cnicKey, ags_cnInvCmmTp.cnictName, ags_cnInvCmm.cnicInvAccnt FROM ags_cnInvCmm INNER JOIN ags_cnInvCmmTp ON ags_cnInvCmm.cnicType = ags_cnInvCmmTp.cnictKey WHERE (((ags_cnInvCmm.cnicGroup)=[gr])))  AS a
GROUP BY a.cnicInvAccnt
ORDER BY a.cnicInvAccnt, a.cnictName
PIVOT a.cnictName;
