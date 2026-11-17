-- Access QueryDef: exl_Uprow_Rpt03
-- Type: 0

SELECT ipgChRsltPlCst.cstAgPnCode, ipgChRsltPlCst.ag_acceptedAccum, exl_Uprow_Rpt02.code, exl_Uprow_Rpt02.utilTtl, Abs([ag_acceptedAccum]-[utilTtl]) AS d
FROM ipgChRsltPlCst LEFT JOIN exl_Uprow_Rpt02 ON ipgChRsltPlCst.cstAgPnCode = exl_Uprow_Rpt02.code
WHERE (((ipgChRsltPlCst.cstAgPnCode) Is Not Null) AND ((ipgChRsltPlCst.ag_acceptedAccum)>0));
