-- Access QueryDef: 24-08_Diagramm
-- Type: 0

SELECT b.rowNum, b.ogaKey, b.ogNm, b.branch, b.branchName, b.cstAgPnCode, b.dateRslt, a.ag_PlFulfillment AS [АД, выполнен], a.ag_PlNonFulfillment AS [АД, не выполнено], a.ag_PlOverFulfillment AS [АД, перевыполнено], a.ag_PlRestLimit AS [АД, остаток], a.iv_PlFulfillment AS [ИД, выполнено], a.iv_PlNonFulfillment AS [ИД, не выполнено], a.iv_PlOverFulfillment AS [ИД, перевыполнено], a.iv_PlRestLimit AS [ИД, остаток], b.uk_PlFulfillment AS [? выполнено], b.uk_PlNonFulfillment AS [? не выполнено], b.uk_PlOverFulfillment AS [? перевыполнено], b.uk_PlRestLimit AS [? остаток], a.ag_PlOverLimit AS [АД, сверх лимита], a.iv_PlOverLimit AS [ИД, сверх лимита], b.uk_PlOverLimit AS [? сверх лимита], b.np_acceptedTtlAccum AS [вне плана], b.oh_acceptedTtlAccum AS прочие
FROM ags_fnIpgChRsltCstUtlPercentBrn_2408_tbl_part_1 AS a INNER JOIN ags_fnIpgChRsltCstUtlPercentBrn_2408_tbl_part_2 AS b ON a.rowNum = b.rowNum
ORDER BY b.rowNum;
