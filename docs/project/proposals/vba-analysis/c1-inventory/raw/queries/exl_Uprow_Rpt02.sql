-- Access QueryDef: exl_Uprow_Rpt02
-- Type: 0

SELECT exl_Uprow_Rpt01.code AS Выражение1, Round([utilTtlRpt]*1000000,2) AS utilTtl
FROM exl_Uprow_Rpt01
WHERE (((Round([utilTtlRpt]*1000000,2))>0))
ORDER BY exl_Uprow_Rpt01.code;
