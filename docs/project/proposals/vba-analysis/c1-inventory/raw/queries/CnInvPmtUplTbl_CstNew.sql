-- Access QueryDef: CnInvPmtUplTbl_CstNew
-- Type: 0

SELECT src.cacOrNull, src.sh, db.ipCode, gp.pirIDnew, gp.pirName
FROM ((SELECT cipuCacNot.cacOrNull, Right([cacOrNull],6) AS sh, Right([cacOrNull],7) AS cccD FROM cipuCacNot)  AS src LEFT JOIN (SELECT Right([cstapIpgPnN],6) AS ipCode FROM ags_cstAgPn GROUP BY Right([cstapIpgPnN],6))  AS db ON src.sh = db.ipCode) LEFT JOIN tblPIR AS gp ON src.cccD = gp.pirIDnew
ORDER BY src.sh;
