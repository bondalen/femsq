-- Access QueryDef: ags_ogAgFeeYyyy
-- Type: 0

SELECT ags_ogAgFeeP.oafpCstAgPn, ags_ogAgFeeP.oafpTotal, ags_ogAgFee.oafNum, ags_ogAgFee.oafDate, ags_ogAgFee.oafReturnedDate, Year([oafDate]) AS yyyy
FROM ags_ogAgFeeP INNER JOIN ags_ogAgFee ON ags_ogAgFeeP.oafpOaf = ags_ogAgFee.oafKey;
