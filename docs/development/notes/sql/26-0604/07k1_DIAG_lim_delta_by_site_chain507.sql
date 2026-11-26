USE [FishEye_prod_noM6];
GO
-- =============================================================================
-- 07k1_DIAG_lim_delta_by_site_chain507.sql
-- Декомпозиция lim 195+172+187−212 до стройки (RS1 site-grain @max date).
-- Цель: отличить float-артефакт SUM(float) от реальной money-δ по cstapKey.
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh int = 507;
DECLARE @ipg int = 27;
DECLARE @end date = '20261130';

IF OBJECT_ID('tempdb..#siteLim') IS NOT NULL DROP TABLE #siteLim;
CREATE TABLE #siteLim (
  stCostKey int NOT NULL,
  cstapKey  int NOT NULL,
  ag_ipgpKey int NULL,
  lim       decimal(38, 12) NOT NULL
);

DECLARE @stKey int;
DECLARE @stList TABLE (ord int, stKey int);
INSERT INTO @stList VALUES (1,212),(2,195),(3,172),(4,187);

DECLARE @ord int = 1;
DECLARE @maxd date;

WHILE @ord <= 4
BEGIN
  SELECT @stKey = stKey FROM @stList WHERE ord = @ord;

  EXEC ags.spMstrg_2606
    @ipgCh = @ipgCh,
    @MounthEndDate = @end,
    @ipgStKey = NULL,
    @stCostKey = @stKey,
    @saveToTables = 1;

  SELECT @maxd = MAX(dateRslt)
  FROM ags.spMstrg_2606_ResultSet1
  WHERE ipgKey = @ipg;

  INSERT INTO #siteLim (stCostKey, cstapKey, ag_ipgpKey, lim)
  SELECT
    @stKey,
    cstapKey,
    ag_ipgpKey,
    CAST(ISNULL(ag_lim, 0) AS decimal(38, 12))
  FROM ags.spMstrg_2606_ResultSet1
  WHERE ipgKey = @ipg
    AND dateRslt = @maxd
    AND ag_ipgpKey IS NOT NULL
    AND cstapKey IS NOT NULL;

  SET @ord += 1;
END

-- --- A) Totals: float vs decimal ---
;WITH piv AS (
  SELECT
    cstapKey,
    SUM(CASE WHEN stCostKey = 212 THEN lim ELSE 0 END) AS lim212,
    SUM(CASE WHEN stCostKey = 195 THEN lim ELSE 0 END) AS lim195,
    SUM(CASE WHEN stCostKey = 172 THEN lim ELSE 0 END) AS lim172,
    SUM(CASE WHEN stCostKey = 187 THEN lim ELSE 0 END) AS lim187
  FROM #siteLim
  GROUP BY cstapKey
),
agg AS (
  SELECT
    SUM(lim212) AS d212,
    SUM(lim195) AS d195,
    SUM(lim172) AS d172,
    SUM(lim187) AS d187,
    SUM(lim195 + lim172 + lim187) AS d_parts,
    SUM(lim212) - SUM(lim195 + lim172 + lim187) AS d_delta_decimal,
    CAST(SUM(CAST(lim212 AS float)) AS float)
      - (CAST(SUM(CAST(lim195 AS float)) AS float)
       + CAST(SUM(CAST(lim172 AS float)) AS float)
       + CAST(SUM(CAST(lim187 AS float)) AS float)) AS d_delta_float_path
  FROM piv
)
SELECT
  d212, d195, d172, d187, d_parts,
  d_delta_decimal,
  d_delta_float_path,
  CASE WHEN d_delta_decimal = 0 THEN N'DECIMAL_EXACT'
       WHEN ABS(d_delta_decimal) <= 0.00000001 THEN N'DECIMAL_NEAR_0'
       ELSE N'DECIMAL_NONZERO' END AS decimal_verdict
FROM agg;

-- --- B) Sites with nonzero delta (money/decimal) ---
;WITH piv AS (
  SELECT
    cstapKey,
    SUM(CASE WHEN stCostKey = 212 THEN lim ELSE 0 END) AS lim212,
    SUM(CASE WHEN stCostKey = 195 THEN lim ELSE 0 END) AS lim195,
    SUM(CASE WHEN stCostKey = 172 THEN lim ELSE 0 END) AS lim172,
    SUM(CASE WHEN stCostKey = 187 THEN lim ELSE 0 END) AS lim187
  FROM #siteLim
  GROUP BY cstapKey
),
diff AS (
  SELECT
    cstapKey,
    lim212, lim195, lim172, lim187,
    (lim195 + lim172 + lim187) AS parts,
    lim212 - (lim195 + lim172 + lim187) AS delta
  FROM piv
)
SELECT
  COUNT(*) AS n_sites,
  SUM(CASE WHEN delta <> 0 THEN 1 ELSE 0 END) AS n_nonzero_delta,
  SUM(CASE WHEN ABS(delta) > 0.00000001 THEN 1 ELSE 0 END) AS n_abs_gt_1e8,
  MIN(delta) AS min_delta,
  MAX(delta) AS max_delta,
  SUM(delta) AS sum_delta
FROM diff;

-- --- C) Top offenders (if any) ---
;WITH piv AS (
  SELECT
    cstapKey,
    SUM(CASE WHEN stCostKey = 212 THEN lim ELSE 0 END) AS lim212,
    SUM(CASE WHEN stCostKey = 195 THEN lim ELSE 0 END) AS lim195,
    SUM(CASE WHEN stCostKey = 172 THEN lim ELSE 0 END) AS lim172,
    SUM(CASE WHEN stCostKey = 187 THEN lim ELSE 0 END) AS lim187
  FROM #siteLim
  GROUP BY cstapKey
),
diff AS (
  SELECT
    cstapKey,
    lim212, lim195, lim172, lim187,
    (lim195 + lim172 + lim187) AS parts,
    lim212 - (lim195 + lim172 + lim187) AS delta
  FROM piv
)
SELECT TOP 30
  cstapKey, lim212, lim195, lim172, lim187, parts, delta
FROM diff
WHERE delta <> 0
ORDER BY ABS(delta) DESC;

-- --- D) Cross-check source ipgPnLim (same grain: sum by cstAgPn @ ipg 27) ---
;WITH src AS (
  SELECT
    p.ipgpCstAgPn AS cstapKey,
    SUM(CASE WHEN l.ipgplStCost = 212 THEN l.ipgplLim ELSE 0 END) AS lim212,
    SUM(CASE WHEN l.ipgplStCost = 195 THEN l.ipgplLim ELSE 0 END) AS lim195,
    SUM(CASE WHEN l.ipgplStCost = 172 THEN l.ipgplLim ELSE 0 END) AS lim172,
    SUM(CASE WHEN l.ipgplStCost = 187 THEN l.ipgplLim ELSE 0 END) AS lim187
  FROM ags.ipgPn p
  LEFT JOIN ags.ipgPnLim l ON l.ipgplPn = p.ipgpKey AND l.ipgplStCost IN (212,195,172,187)
  WHERE p.ipgpIpg = @ipg
  GROUP BY p.ipgpCstAgPn
)
SELECT
  COUNT(*) AS n_src_sites,
  SUM(lim212) AS src212,
  SUM(lim195+lim172+lim187) AS src_parts,
  SUM(lim212) - SUM(lim195+lim172+lim187) AS src_delta,
  SUM(CASE WHEN lim212 - (lim195+lim172+lim187) <> 0 THEN 1 ELSE 0 END) AS n_src_nonzero
FROM src;
GO
