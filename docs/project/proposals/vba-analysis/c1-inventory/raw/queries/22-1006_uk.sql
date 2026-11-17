-- Access QueryDef: 22-1006_uk
-- Type: 0

SELECT ipgChRsltPlCstPercent.ogNm, ipgChRsltPlCstPercent.cstAgPnCode, ipgChRsltPlCstPercent.dateRslt, ipgChRsltPlCstPercent.ag_lim, ipgChRsltPlCstPercent.ag_acceptedTtlAccum, ipgChRsltPlCstPercent.iv_lim, ipgChRsltPlCstPercent.ia_acceptedTtlAccum, ipgChRsltPlCstPercent.uk_lim, ipgChRsltPlCstPercent.ag_PlOverLimit
FROM ipgChRsltPlCstPercent
WHERE (((ipgChRsltPlCstPercent.dateRslt)=#9/30/2022#) AND ((ipgChRsltPlCstPercent.ag_PlOverLimit)<>0));
