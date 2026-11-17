-- Access QueryDef: ags_Yr_DbtFn
-- Type: 16

PARAMETERS gr Long;
TRANSFORM Min(a.cnicfValue) AS [Min-cnicfValue]
SELECT a.cnicfInvAccnt
FROM (SELECT f.cnicfCmmGr, n.cnicfnName, f.cnicfValue, f.cnicfInvAccnt FROM ags_cnInvCmmFn AS f INNER JOIN ags_cnInvCmmFnN AS n ON f.cnicfName = n.cnicfnKey WHERE (((f.cnicfCmmGr)=[gr])))  AS a
GROUP BY a.cnicfInvAccnt
PIVOT a.cnicfnName;
