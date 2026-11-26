USE [FishEye_prod_noM6];
GO
-- =============================================================================
-- 01_REPAIR_sm_agg_axes_R_MONEY_AGG.sql
-- One-shot ADR 012 / задача 0095: согласование ipgpSm* + resync ipgPnLim.
--   Q  (|δ|≤1e-8): Oth += δ (авторитет Ttl)
--   A  (ε_q < |δ| ≤ ε_block): Ttl := Wrk+Equ+Oth
--   A-hard (|δ| > ε_block): НЕ трогаем — только отчёт
-- ε_block = max(1, 0.01 * max(|Ttl|, |parts|))
-- =============================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID('tempdb..#fix') IS NOT NULL DROP TABLE #fix;
IF OBJECT_ID('tempdb..#hard') IS NOT NULL DROP TABLE #hard;

SELECT
  p.ipgpKey,
  p.ipgpIpg,
  p.ipgpCstAgPn,
  CAST(ISNULL(p.ipgpSmTtl, 0) AS decimal(23, 8)) AS ttl0,
  CAST(ISNULL(p.ipgpSmWrk, 0) AS decimal(23, 8)) AS wrk0,
  CAST(ISNULL(p.ipgpSmEqu, 0) AS decimal(23, 8)) AS equ0,
  CAST(ISNULL(p.ipgpSmOth, 0) AS decimal(23, 8)) AS oth0,
  CAST(ISNULL(p.ipgpSmTtl, 0) - (ISNULL(p.ipgpSmWrk, 0) + ISNULL(p.ipgpSmEqu, 0) + ISNULL(p.ipgpSmOth, 0))
      AS decimal(23, 8)) AS d0
INTO #fix
FROM ags.ipgPn p
WHERE ISNULL(p.ipgpSmTtl, 0) <> 0
  AND (ISNULL(p.ipgpSmWrk, 0) + ISNULL(p.ipgpSmEqu, 0) + ISNULL(p.ipgpSmOth, 0)) <> 0
  AND ABS(ISNULL(p.ipgpSmTtl, 0) - (ISNULL(p.ipgpSmWrk, 0) + ISNULL(p.ipgpSmEqu, 0) + ISNULL(p.ipgpSmOth, 0))) > 0;

ALTER TABLE #fix ADD
  parts0 decimal(23, 8) NULL,
  eps_block decimal(23, 8) NULL,
  cls varchar(8) NULL,
  ttl1 decimal(23, 8) NULL,
  wrk1 decimal(23, 8) NULL,
  equ1 decimal(23, 8) NULL,
  oth1 decimal(23, 8) NULL;

UPDATE #fix SET
  parts0 = wrk0 + equ0 + oth0,
  eps_block = CASE
    WHEN CASE WHEN ABS(ttl0) >= ABS(wrk0 + equ0 + oth0) THEN ABS(ttl0) ELSE ABS(wrk0 + equ0 + oth0) END * 0.01
         > 1
    THEN CASE WHEN ABS(ttl0) >= ABS(wrk0 + equ0 + oth0) THEN ABS(ttl0) ELSE ABS(wrk0 + equ0 + oth0) END * 0.01
    ELSE 1
  END;

UPDATE #fix SET cls = CASE
  WHEN ABS(d0) <= 0.00000001 THEN 'Q'
  WHEN ABS(d0) > eps_block THEN 'HARD'
  ELSE 'A'
END;

UPDATE #fix SET
  ttl1 = CASE WHEN cls = 'A' THEN parts0 ELSE ttl0 END,
  wrk1 = wrk0,
  equ1 = equ0,
  oth1 = CASE WHEN cls = 'Q' THEN oth0 + d0 ELSE oth0 END
WHERE cls IN ('Q', 'A');

SELECT cls, COUNT(*) AS n FROM #fix GROUP BY cls ORDER BY cls;

SELECT 'HARD_SKIP' AS tag, ipgpKey, ipgpIpg, ipgpCstAgPn, ttl0, parts0, d0, eps_block
INTO #hard
FROM #fix WHERE cls = 'HARD';

SELECT * FROM #hard ORDER BY ABS(d0) DESC;

BEGIN TRAN;

UPDATE p
SET
  p.ipgpSmTtl = f.ttl1,
  p.ipgpSmWrk = f.wrk1,
  p.ipgpSmEqu = f.equ1,
  p.ipgpSmOth = f.oth1
FROM ags.ipgPn p
INNER JOIN #fix f ON f.ipgpKey = p.ipgpKey
WHERE f.cls IN ('Q', 'A');

-- Resync lim 212/195/172/187 for fixed keys (delete+insert nonzero)
DELETE l
FROM ags.ipgPnLim l
INNER JOIN #fix f ON f.ipgpKey = l.ipgplPn
WHERE f.cls IN ('Q', 'A')
  AND l.ipgplStCost IN (212, 195, 172, 187);

INSERT INTO ags.ipgPnLim (ipgplPn, ipgplStCost, ipgplLim)
SELECT ipgpKey, 212, ttl1 FROM #fix WHERE cls IN ('Q', 'A') AND ttl1 <> 0
UNION ALL
SELECT ipgpKey, 195, wrk1 FROM #fix WHERE cls IN ('Q', 'A') AND wrk1 <> 0
UNION ALL
SELECT ipgpKey, 172, equ1 FROM #fix WHERE cls IN ('Q', 'A') AND equ1 <> 0
UNION ALL
SELECT ipgpKey, 187, oth1 FROM #fix WHERE cls IN ('Q', 'A') AND oth1 <> 0;

COMMIT TRAN;

-- Verify no Q/A left (HARD may remain)
SELECT
  SUM(CASE WHEN ABS(d)=0 THEN 1 ELSE 0 END) AS ok_now,
  SUM(CASE WHEN ABS(d)>0 AND ABS(d)<=0.00000001 THEN 1 ELSE 0 END) AS q_left,
  SUM(CASE WHEN ABS(d)>0.00000001 AND ABS(d)<=1 THEN 1 ELSE 0 END) AS a_left_approx,
  SUM(CASE WHEN ABS(d)>1 THEN 1 ELSE 0 END) AS hard_left
FROM (
  SELECT ISNULL(ipgpSmTtl,0)-(ISNULL(ipgpSmWrk,0)+ISNULL(ipgpSmEqu,0)+ISNULL(ipgpSmOth,0)) AS d
  FROM ags.ipgPn
  WHERE ISNULL(ipgpSmTtl,0)<>0
    AND (ISNULL(ipgpSmWrk,0)+ISNULL(ipgpSmEqu,0)+ISNULL(ipgpSmOth,0))<>0
) z;

-- Spot 3555
SELECT ipgpKey, ipgpCstAgPn, ipgpSmTtl, ipgpSmWrk, ipgpSmEqu, ipgpSmOth,
  ipgpSmTtl-(ipgpSmWrk+ipgpSmEqu+ipgpSmOth) AS d
FROM ags.ipgPn WHERE ipgpCstAgPn=3555 AND ipgpIpg=27;
GO
