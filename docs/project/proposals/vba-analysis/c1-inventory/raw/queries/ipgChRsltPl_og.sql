-- Access QueryDef: ipgChRsltPl_og
-- Type: 0

SELECT ipgChRsltPl.ipgCh, ipgChRsltPl.ogNm
FROM ipgChRsltPl
GROUP BY ipgChRsltPl.ipgCh, ipgChRsltPl.ogNm;
