-- Access QueryDef: ipgOutSide_cstAgPn_Date
-- Type: 0

SELECT ipgOutSide_cstAgPn.cstAgPnCode, ipgOutSide_cstAgPn.cstapKey, ipgOutSide_Date.dateRslt
FROM ipgOutSide_cstAgPn, ipgOutSide_Date
ORDER BY ipgOutSide_cstAgPn.cstAgPnCode, ipgOutSide_Date.dateRslt;
