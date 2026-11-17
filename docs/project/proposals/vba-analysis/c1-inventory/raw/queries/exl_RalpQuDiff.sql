-- Access QueryDef: exl_RalpQuDiff
-- Type: 0

SELECT exl_RalpQu.ralpNum, exl_RalpQu.ralpDate, exl_RalpQu.ralpCostAndVat, exl_RalpQu.ralpArrived, exl_RalpQu.ralpReturned, exl_RalpQu.ralpSent, exl_RalpQu.ralpRespons, exl_RalpQu.ralpNote, ags_ralp.ralpNum, ags_ralp.ralpDate, ags_ralp.ralpKey
FROM exl_RalpQu LEFT JOIN ags_ralp ON (exl_RalpQu.ralpNum = ags_ralp.ralpNum) AND (exl_RalpQu.ralpDate = ags_ralp.ralpDate)
WHERE (((ags_ralp.ralpKey) Is Null));
