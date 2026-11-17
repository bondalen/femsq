-- Access QueryDef: Запрос28
-- Type: 0

SELECT ipgChRsltPlCstPercent.ogNm, ipgChRsltPlCstPercent.dateRslt, ipgChRsltPlCstPercent.ag_lim, ipgChRsltPlCstPercent.ag_PlAccum
FROM ipgChRsltPlCstPercent
WHERE (((ipgChRsltPlCstPercent.ogNm)="Газпром инвест, ООО") AND ((ipgChRsltPlCstPercent.branch) Is Null) AND ((ipgChRsltPlCstPercent.cstAgPnCode) Is Null));
