-- Access QueryDef: exl_Uprow_Rpt
-- Type: 0

SELECT exl_Uprov.code AS Выражение1, Sum(exl_Uprov.utilWork) AS utilWork, Sum(exl_Uprov.utilEquipTtl) AS utilEquipTtl, Sum(exl_Uprov.utilEquipStorage) AS utilEquipStorage, Sum(exl_Uprov.utilOthersTtl) AS utilOthersTtl, Sum(exl_Uprov.utilOthersAgFee) AS utilOthersAgFee, Sum(exl_Uprov.utilOthersRalp) AS utilOthersRalp
FROM exl_Uprov
GROUP BY exl_Uprov.code
HAVING ((([exl_Uprov].[code]) Is Not Null));
