-- Access QueryDef: ags_Yr_DbtGr
-- Type: 16

PARAMETERS gr Long;
TRANSFORM Min(a.nnn) AS [Min-nnn]
SELECT a.cnigInvAccnt
FROM (SELECT g.cnigCmmGr, g.cnigInvAccnt, n.cnignName, "+" AS nnn FROM ags_cnInvGr AS g INNER JOIN ags_cnInvGrNm AS n ON g.cnigGrName = n.cnignKey WHERE (((g.cnigCmmGr)=[gr])))  AS a
GROUP BY a.cnigInvAccnt
PIVOT a.cnignName;
