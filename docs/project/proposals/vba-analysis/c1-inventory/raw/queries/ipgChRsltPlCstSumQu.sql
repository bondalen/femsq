-- Access QueryDef: ipgChRsltPlCstSumQu
-- Type: 0

SELECT z.maxDateRslt, y.ipgChKey, y.cstAgPnCode, y.ag_presentedAccum, y.ag_acceptedAccum
FROM (SELECT Max(s.dateRslt) AS maxDateRslt FROM ipgChRsltPlCstSum AS s)  AS z INNER JOIN ipgChRsltPlCstSum AS y ON z.maxDateRslt = y.dateRslt
WHERE (((y.cstAgPnCode) Is Not Null) AND ((y.ag_presentedAccum)<>0));
