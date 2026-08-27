/*
 * M2 — VERIFY counts / invariants
 * lastUpdated: 2026-08-27 (после 06a concurrent split)
 */
SET NOCOUNT ON;
GO

DECLARE @cia int = (SELECT COUNT(*) FROM ags.cnInvAccnt);
DECLARE @cid int = (SELECT COUNT(*) FROM ags.cn_inv_dbt);

SELECT N'invDbt' AS metric, COUNT(*) AS n,
       11907 + (SELECT COUNT(*) FROM sudz.Dbt WHERE dbtNote IN (N'M2-concurrent-cia', N'M2-cn-migrate')) AS expect
FROM sudz.invDbt
UNION ALL SELECT N'Dbt', COUNT(*),
       11897 + (SELECT COUNT(*) FROM sudz.Dbt WHERE dbtNote IN (N'M2-concurrent-cia', N'M2-cn-migrate'))
FROM sudz.Dbt
UNION ALL SELECT N'invDbtDbt', COUNT(*),
       11907 + (SELECT COUNT(*) FROM sudz.Dbt WHERE dbtNote IN (N'M2-concurrent-cia', N'M2-cn-migrate'))
FROM sudz.invDbtDbt
UNION ALL SELECT N'invDbtCia', COUNT(*), @cia FROM sudz.invDbtCia
UNION ALL SELECT N'DbtValue', COUNT(*), @cid FROM sudz.DbtValue
UNION ALL SELECT N'cn_inv_dbt', @cid, @cid
UNION ALL SELECT N'invDbtVar', COUNT(*), NULL FROM sudz.invDbtVar
UNION ALL SELECT N'S73_notes', COUNT(*), 10 FROM sudz.Dbt WHERE dbtNote IN (N'S73-split', N'S73-quarter')
UNION ALL SELECT N'Rslt_notes', COUNT(*), 10 FROM sudz.Dbt WHERE dbtNote LIKE N'Rslt-L%'
UNION ALL SELECT N'split_notes', COUNT(*), NULL FROM sudz.Dbt WHERE dbtNote IN (N'M2-concurrent-cia', N'M2-cn-migrate');
GO

SELECT N'slots_without_bridge' AS chk, COUNT(*) AS n
FROM sudz.invDbt d
WHERE NOT EXISTS (SELECT 1 FROM sudz.invDbtDbt b WHERE b.iddInvDbt = d.idKey);

SELECT N'cia_unmapped' AS chk, COUNT(*) AS n
FROM ags.cnInvAccnt a
WHERE NOT EXISTS (SELECT 1 FROM sudz.invDbtCia c WHERE c.idcCia = a.ciaKey);

/* concurrent (slot,upl) must be 0 after 06a */
;WITH cid_slot AS (
    SELECT cid.cn_inv_dbt_upl AS upl, br.idcInvDbt AS slot
    FROM ags.cn_inv_dbt AS cid
    INNER JOIN sudz.invDbtCia AS br ON br.idcCia = cid.cidCnInvAccntCtpt
)
SELECT N'concurrent_slot_upl' AS chk, COUNT(*) AS n
FROM (SELECT slot, upl FROM cid_slot GROUP BY slot, upl HAVING COUNT(*) > 1) x;

/* L*: правый и левый слот — один dbtKey */
SELECT L.lid, bl.iddDbt AS leftDbt, br.iddDbt AS rightDbt,
       CASE WHEN bl.iddDbt = br.iddDbt THEN N'OK' ELSE N'FAIL' END AS st
FROM (VALUES
 (N'L001',12032,3,20505,0),(N'L002',12032,4,20504,0),(N'L003',12032,5,20503,0),
 (N'L004',12032,6,20502,0),(N'L005',12032,7,20501,0),(N'L006',12032,8,20500,0),
 (N'L007',12033,2,19691,0),(N'L008',12033,3,19690,0),(N'L009',12033,4,19689,0),
 (N'L010',12033,5,19688,0)
) AS L(lid,li,ln,ri,rn)
INNER JOIN sudz.invDbt sl ON sl.idInv=L.li AND sl.idNum=L.ln
INNER JOIN sudz.invDbt sr ON sr.idInv=L.ri AND sr.idNum=L.rn
INNER JOIN sudz.invDbtDbt bl ON bl.iddInvDbt=sl.idKey
INNER JOIN sudz.invDbtDbt br ON br.iddInvDbt=sr.idKey;
GO
