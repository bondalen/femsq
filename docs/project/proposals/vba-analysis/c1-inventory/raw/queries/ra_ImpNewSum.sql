-- Access QueryDef: ra_ImpNewSum
-- Type: 0

SELECT z.rainCstAgPnStr, z.presTtl, y.accpTtl
FROM (SELECT im.rainCstAgPnStr, Sum(im.rainTtl) AS presTtl FROM ra_ImpNew AS im WHERE (((im.rainSign)<>"ОА прочие")) GROUP BY im.rainCstAgPnStr)  AS z LEFT JOIN (SELECT i.rainCstAgPnStr, Sum(i.rainTtl) AS accpTtl FROM ra_ImpNew AS i WHERE (((i.rainSign)<>"ОА прочие") AND ((i.rainSendNum)<>"" And (i.rainSendNum) Is Not Null)) GROUP BY i.rainCstAgPnStr)  AS y ON z.rainCstAgPnStr = y.rainCstAgPnStr
WHERE (((z.presTtl)<>0));
