-- Access QueryDef: ags_Yr_DbtAg
-- Type: 16

PARAMETERS gr Long;
TRANSFORM Min(a.cicaKey) AS [Min-cicaKey]
SELECT a.cicaInvAccnt
FROM (SELECT ags_cnInvCmmAg.cicaCmmGr, ags_cnInvCmmAg.cicaInvAccnt, ags_cnInvCmmAg.cicaKey, ags_cnInvCmmAgN.cicanName FROM ags_cnInvCmmAg INNER JOIN ags_cnInvCmmAgN ON ags_cnInvCmmAg.cicaType = ags_cnInvCmmAgN.cicanKey WHERE (((ags_cnInvCmmAg.cicaCmmGr)=[gr])))  AS a
GROUP BY a.cicaInvAccnt
PIVOT a.cicanName;
