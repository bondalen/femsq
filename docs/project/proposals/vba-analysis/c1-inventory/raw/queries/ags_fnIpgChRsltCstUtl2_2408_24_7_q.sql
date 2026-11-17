-- Access QueryDef: ags_fnIpgChRsltCstUtl2_2408_24_7_q
-- Type: 0

SELECT ags_fnIpgChRsltCstUtl2_2408_24_7.*, ags_cstAgPn.cstapCstName
FROM ags_fnIpgChRsltCstUtl2_2408_24_7 INNER JOIN ags_cstAgPn ON ags_fnIpgChRsltCstUtl2_2408_24_7.cstAgPnKey = ags_cstAgPn.cstapKey
WHERE (((ags_fnIpgChRsltCstUtl2_2408_24_7.inProcessTtlAccum)<>0));
