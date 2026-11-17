-- Access QueryDef: ipgOutSide
-- Type: 0

PARAMETERS дата_окончания_месяца DateTime;
SELECT a.dateRslt, a.mn, IIf(IsNull([cstapCstName]),IIf(IsNull([branchName2]),[ogNm],[branchName2]),[cstapCstName]) AS nameAll, a.ogNm, a.branch, IIf([branch]=0,"не определен",[branchName]) AS branchName2, a.cstAgPnCode, a.cstapCstName, a.ag_PlOverLimit_, a.np_acceptedTtlAccum, a.ogNmSort, IIf([branch]=0,"не определен",[branchName]) AS branchNameSort, a.cstAgPnCodeSort, a.cstapKey, Year([dateRslt]) AS yearOfDate, a.ag_lim
FROM [24-0710_Справка_22_11_Осв_Филиалы_Слайды] AS a
WHERE (((a.dateRslt)=[дата_окончания_месяца]) AND ((a.ag_PlOverLimit_)>0)) OR (((a.dateRslt)=[дата_окончания_месяца]) AND ((a.np_acceptedTtlAccum)>0))
ORDER BY a.ogNmSort, IIf([branch]=0,"не определен",[branchName]), a.cstAgPnCodeSort;
