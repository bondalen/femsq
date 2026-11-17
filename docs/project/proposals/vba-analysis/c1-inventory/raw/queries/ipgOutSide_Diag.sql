-- Access QueryDef: ipgOutSide_Diag
-- Type: 0

SELECT ipgOutSide_cstAgPn_Date.cstapKey, ipgOutSide_cstAgPn_Date.cstAgPnCode, ipgOutSide_cstAgPn_Date.dateRslt, ipgChRsltPlCstPercent.ag_PlOverLimit AS [превышение лимита], ipgChRsltPlCstPercent.np_acceptedTtlAccum AS [вне ИПг], ipgChRsltPlCstPercent.ag_lim AS лимит
FROM ipgOutSide_cstAgPn_Date LEFT JOIN ipgChRsltPlCstPercent ON (ipgOutSide_cstAgPn_Date.dateRslt = ipgChRsltPlCstPercent.dateRslt) AND (ipgOutSide_cstAgPn_Date.cstapKey = ipgChRsltPlCstPercent.cstapKey)
WHERE (((ipgOutSide_cstAgPn_Date.cstapKey) Is Not Null))
ORDER BY ipgOutSide_cstAgPn_Date.cstAgPnCode, ipgOutSide_cstAgPn_Date.dateRslt;
