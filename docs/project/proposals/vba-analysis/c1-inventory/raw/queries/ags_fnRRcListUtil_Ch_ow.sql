-- Access QueryDef: ags_fnRRcListUtil_Ch_ow
-- Type: 0

SELECT ags_fnRRcListUtil_Ch.dateRslt, ags_fnRRcListUtil_Ch.sortType, ags_fnRRcListUtil_Ch.costsSummAccum, ags_fnRRcListUtil_Ch.cst
FROM ags_fnRRcListUtil_Ch
WHERE (((ags_fnRRcListUtil_Ch.costsType)<>"всего"));
