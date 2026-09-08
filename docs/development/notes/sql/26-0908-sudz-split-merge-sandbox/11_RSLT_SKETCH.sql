-- =============================================================================
-- Макет полос Rslt для Dbt 111 (таблица, не Excel).
-- =============================================================================

SET NOCOUNT ON;

DECLARE @old201 nvarchar(400);
DECLARE @gr201 nvarchar(40);

SELECT @old201 = c.cmmText,
       @gr201 = CASE WHEN gr.cnigKey IS NULL THEN N'' ELSE N'углубленно' END
FROM test_sudz_sm.cmm AS c
INNER JOIN test_sudz_sm.DbtValue AS dv ON dv.dvKey = c.cmmDv
INNER JOIN test_sudz_sm.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
LEFT JOIN test_sudz_sm.cnInvGr AS gr
    ON gr.cnigDv = c.cmmDv AND gr.cnigCmmGr = c.cmmGr
WHERE idd.iddDbt = 111 AND dv.dvUpl = 201 AND c.cmmKind = N'mery';

/* A: крайний срез 202 = 2 факта; старые комментарии с 201 = 1 ячейка (merge на 2 строки) */
SELECT
    N'A curr=202 / old=201' AS scenario,
    ROW_NUMBER() OVER (ORDER BY dv.dvInvDbt) AS band_row,
    CAST(dv.dvTtl AS decimal(19, 2)) AS fact_202,
    N'2 ячейки факта (без merge)' AS fact_hint,
    CASE WHEN dv.dvInvDbt = 322 THEN @old201 ELSE N'↑ merge' END AS old_cmm_201,
    CASE WHEN dv.dvInvDbt = 322 THEN N'merge old на 2 строки' ELSE N'' END AS old_hint,
    CASE WHEN dv.dvInvDbt = 322 THEN @gr201 ELSE N'↑ merge' END AS old_gr,
    c.cmmText AS new_cmm_202,
    CASE WHEN gr.cnigKey IS NULL THEN N'' ELSE N'углубленно' END AS new_gr
FROM test_sudz_sm.DbtValue AS dv
INNER JOIN test_sudz_sm.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
LEFT JOIN test_sudz_sm.cmm AS c
    ON c.cmmDv = dv.dvKey AND c.cmmGr = 202 AND c.cmmKind = N'mery'
LEFT JOIN test_sudz_sm.cnInvGr AS gr
    ON gr.cnigDv = dv.dvKey AND gr.cnigCmmGr = 202
WHERE idd.iddDbt = 111 AND dv.dvUpl = 202
ORDER BY dv.dvInvDbt;

/* B: крайний срез 201 = 1 факт (слитая ячейка); старые с 202 = 2 ячейки комментариев */
SELECT
    N'B curr=201 / old=202' AS scenario,
    ROW_NUMBER() OVER (ORDER BY dvOld.dvInvDbt) AS band_row,
    CAST((SELECT dvTtl FROM test_sudz_sm.DbtValue dv
          INNER JOIN test_sudz_sm.invDbtDbt idd ON idd.iddInvDbt = dv.dvInvDbt
          WHERE idd.iddDbt = 111 AND dv.dvUpl = 201) AS decimal(19, 2)) AS fact_201,
    CASE WHEN ROW_NUMBER() OVER (ORDER BY dvOld.dvInvDbt) = 1
         THEN N'merge факта/погашено на 2 строки old'
         ELSE N'↑ merge факта' END AS fact_hint,
    c.cmmText AS old_cmm_202,
    N'2 ячейки old (без merge)' AS old_hint,
    CASE WHEN gr.cnigKey IS NULL THEN N'' ELSE N'углубленно' END AS old_gr
FROM test_sudz_sm.DbtValue AS dvOld
INNER JOIN test_sudz_sm.invDbtDbt AS idd ON idd.iddInvDbt = dvOld.dvInvDbt
LEFT JOIN test_sudz_sm.cmm AS c
    ON c.cmmDv = dvOld.dvKey AND c.cmmGr = 202 AND c.cmmKind = N'mery'
LEFT JOIN test_sudz_sm.cnInvGr AS gr
    ON gr.cnigDv = dvOld.dvKey AND gr.cnigCmmGr = 202
WHERE idd.iddDbt = 111 AND dvOld.dvUpl = 202
ORDER BY dvOld.dvInvDbt;

SELECT N'112 @201 после merge' AS note,
       dv.dvInvDbt,
       CAST(dv.dvTtl AS decimal(19, 2)) AS ttl,
       c.cmmText,
       CASE WHEN gr.cnigKey IS NULL THEN N'' ELSE N'углубленно' END AS grFlag
FROM test_sudz_sm.DbtValue AS dv
INNER JOIN test_sudz_sm.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
LEFT JOIN test_sudz_sm.cmm AS c ON c.cmmDv = dv.dvKey AND c.cmmGr = 201
LEFT JOIN test_sudz_sm.cnInvGr AS gr ON gr.cnigDv = dv.dvKey AND gr.cnigCmmGr = 201
WHERE idd.iddDbt = 112 AND dv.dvUpl = 201
ORDER BY dv.dvInvDbt;

/* C: крайний срез 210 = 1 факт (снова целый); старые с 209 = 2 ячейки комментариев */
SELECT
    N'C curr=210 / old=209' AS scenario,
    ROW_NUMBER() OVER (ORDER BY dvOld.dvInvDbt) AS band_row,
    CAST((SELECT dvTtl FROM test_sudz_sm.DbtValue dv
          INNER JOIN test_sudz_sm.invDbtDbt idd ON idd.iddInvDbt = dv.dvInvDbt
          WHERE idd.iddDbt = 111 AND dv.dvUpl = 210) AS decimal(19, 2)) AS fact_210,
    CASE WHEN ROW_NUMBER() OVER (ORDER BY dvOld.dvInvDbt) = 1
         THEN N'merge факта на 2 строки old'
         ELSE N'↑ merge факта' END AS fact_hint,
    c.cmmText AS old_cmm_209,
    N'2 ячейки old (без merge)' AS old_hint,
    CASE WHEN gr.cnigKey IS NULL THEN N'' ELSE N'углубленно' END AS old_gr
FROM test_sudz_sm.DbtValue AS dvOld
INNER JOIN test_sudz_sm.invDbtDbt AS idd ON idd.iddInvDbt = dvOld.dvInvDbt
LEFT JOIN test_sudz_sm.cmm AS c
    ON c.cmmDv = dvOld.dvKey AND c.cmmGr = 209 AND c.cmmKind = N'mery'
LEFT JOIN test_sudz_sm.cnInvGr AS gr
    ON gr.cnigDv = dvOld.dvKey AND gr.cnigCmmGr = 209
WHERE idd.iddDbt = 111 AND dvOld.dvUpl = 209
ORDER BY dvOld.dvInvDbt;
GO
