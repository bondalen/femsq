-- Access QueryDef: ipgOutSide_cstAgPn
-- Type: 0

SELECT ipgChRsltPlCstPercent.cstAgPnCode, ipgChRsltPlCstPercent.cstapKey
FROM ipgChRsltPlCstPercent
WHERE not ipgChRsltPlCstPercent.cstapKey is null
GROUP BY ipgChRsltPlCstPercent.cstAgPnCode, ipgChRsltPlCstPercent.cstapKey
ORDER BY ipgChRsltPlCstPercent.cstAgPnCode;
