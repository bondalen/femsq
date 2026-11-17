-- Access QueryDef: ags_fnIpgChRsltCstUtl2_2408_24_7
-- Type: 0

SELECT z.*
FROM ags_fnIpgChRsltCstUtl2_2408 AS z
WHERE (z.restOfLimitInProcess < 0 and z.ipgKey = 24 and z.mNum = 7) or (z.lim is null and z.typeGr = '1. ОА и Изм.' and z.ipgKey = 24 and z.mNum = 7 and not z.acceptedAndInProcessAccum = 0);
