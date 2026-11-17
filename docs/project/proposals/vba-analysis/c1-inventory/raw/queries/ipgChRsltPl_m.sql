-- Access QueryDef: ipgChRsltPl_m
-- Type: 0

SELECT ipgChRsltPl.dateRslt, ipgChRsltPl.ogNm, ipgChRsltPl.ag_lim, ipgChRsltPl.ag_presentedTtl, ipgChRsltPl.ag_acceptedTtl, ipgChRsltPl.ag_presentedTtlAccum, ipgChRsltPl.ag_acceptedTtlAccum, ipgChRsltPl.ag_restOfLimit, [ipgChRsltPl]![ag_acceptedTtlAccum]/[ipgChRsltPl]![ag_lim] AS AcceptedLim, ipgChRsltPl.ag_PlAccum, [ipgChRsltPl]![ag_acceptedTtlAccum]/[ipgChRsltPl]![ag_PlAccum] AS AcceptedPlan
FROM ipgChRsltPl
ORDER BY ipgChRsltPl.dateRslt, ipgChRsltPl.ogNm;
