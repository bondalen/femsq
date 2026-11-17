-- Access QueryDef: ags_cstAgPnMnrl_q
-- Type: 0

SELECT ags_cstAgPnMnrl.amCstAgPn, ags_cstAgPnMnrl.amPositing, ags_cstAgPnMnrl.amSum, ags_cstAgPnMnrl.amType, Year([amPositing]) AS yyyy
FROM ags_cstAgPnMnrl;
