-- Access QueryDef: exl_Uprow_Rpt01
-- Type: 0

SELECT exl_Uprow_Rpt.code AS Выражение1, exl_Uprow_Rpt.utilWork AS Выражение2, exl_Uprow_Rpt.utilEquipTtl AS Выражение3, exl_Uprow_Rpt.utilEquipStorage AS Выражение4, [utilEquipTtl]-[utilEquipStorage] AS utilEquipRpt, exl_Uprow_Rpt.utilOthersTtl AS Выражение5, exl_Uprow_Rpt.utilOthersAgFee AS Выражение6, exl_Uprow_Rpt.utilOthersRalp AS Выражение7, [exl_Uprow_Rpt]![utilOthersTtl]-[exl_Uprow_Rpt]![utilOthersAgFee]-[exl_Uprow_Rpt]![utilOthersRalp] AS utilOthersRpt, IIf(IsNull([utilWork]),0,[utilWork])+[utilEquipRpt]+[utilOthersRpt] AS utilTtlRpt
FROM exl_Uprow_Rpt;
