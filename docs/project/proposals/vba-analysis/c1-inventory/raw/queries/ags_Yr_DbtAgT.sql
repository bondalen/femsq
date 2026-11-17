-- Access QueryDef: ags_Yr_DbtAgT
-- Type: 0

SELECT ags_Yr_DbtAg.cicaInvAccnt, ags_ogAgCs.ogaNm AS Агент, ags_ogAgCs_1.ogaNm AS [Агент новый]
FROM (((ags_Yr_DbtAg LEFT JOIN ags_cnInvCmmAg ON ags_Yr_DbtAg.Агент = ags_cnInvCmmAg.cicaKey) LEFT JOIN ags_ogAgCs ON ags_cnInvCmmAg.cicaOgAg = ags_ogAgCs.ogaKey) LEFT JOIN ags_cnInvCmmAg AS ags_cnInvCmmAg_1 ON ags_Yr_DbtAg.[Агент новый] = ags_cnInvCmmAg_1.cicaKey) LEFT JOIN ags_ogAgCs AS ags_ogAgCs_1 ON ags_cnInvCmmAg_1.cicaOgAg = ags_ogAgCs_1.ogaKey;
