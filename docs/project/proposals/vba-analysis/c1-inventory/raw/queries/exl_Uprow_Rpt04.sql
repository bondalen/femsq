-- Access QueryDef: exl_Uprow_Rpt04
-- Type: 0

SELECT exl_Uprow_Rpt02.code, exl_Uprow_Rpt02.utilTtl, ipgChRsltPlCst.cstAgPnCode, ipgChRsltPlCst.ag_acceptedAccum
FROM exl_Uprow_Rpt02 LEFT JOIN ipgChRsltPlCst ON exl_Uprow_Rpt02.code = ipgChRsltPlCst.cstAgPnCode;
