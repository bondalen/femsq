USE [FishEye_prod_noM6];
GO
-- =============================================================================
-- 07k_COMPARE_stCost_fact_RS_chain507.sql
-- Приёмка 0094 / Решение 23: аддитив факта в RS spMstrg_2606 на цепи 507.
--   SUM(ag_presentedAccum), SUM(ag_acceptedAccum), SUM(ag_lim) @max(dateRslt)
--   site-grain: ipgKey=27 AND ag_ipgpKey IS NOT NULL
--   195+172+187 ≈ 212 (ε); @stCostKey=NULL — smoke (факт не обнулён)
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh int = 507;
DECLARE @ipg int = 27;
DECLARE @end date = '20261130';
DECLARE @epsilon money = 0.01;
DECLARE @t0 datetime2 = SYSDATETIME();

IF OBJECT_ID('tempdb..#m') IS NOT NULL DROP TABLE #m;
CREATE TABLE #m (
  stCostLabel nvarchar(16) NOT NULL,
  stCostKey   int NULL,
  exitCode    int NULL,
  msec        int NULL,
  nn_ipgp     int NULL,
  sum_lim     float NULL,
  sum_pres    float NULL,
  sum_accp    float NULL,
  max_date    date NULL
);

DECLARE @stList TABLE (ord int, label nvarchar(16), stKey int NULL);
INSERT INTO @stList VALUES
  (1, N'NULL', NULL),
  (2, N'212', 212),
  (3, N'195', 195),
  (4, N'172', 172),
  (5, N'187', 187);

DECLARE @ord int = 1, @label nvarchar(16), @stKey int, @t1 datetime2, @rc int, @maxd date;

WHILE @ord <= 5
BEGIN
  SELECT @label = label, @stKey = stKey FROM @stList WHERE ord = @ord;
  SET @t1 = SYSDATETIME();
  BEGIN TRY
    EXEC ags.spMstrg_2606
      @ipgCh = @ipgCh,
      @MounthEndDate = @end,
      @ipgStKey = NULL,
      @stCostKey = @stKey,
      @saveToTables = 1;
    SET @rc = 0;
  END TRY
  BEGIN CATCH
    SET @rc = ERROR_NUMBER();
  END CATCH

  SELECT @maxd = MAX(dateRslt)
  FROM ags.spMstrg_2606_ResultSet1
  WHERE ipgKey = @ipg;

  INSERT INTO #m (stCostLabel, stCostKey, exitCode, msec, nn_ipgp, sum_lim, sum_pres, sum_accp, max_date)
  SELECT
    @label, @stKey, @rc,
    DATEDIFF(millisecond, @t1, SYSDATETIME()),
    SUM(CASE WHEN ag_ipgpKey IS NOT NULL THEN 1 ELSE 0 END),
    SUM(CAST(ISNULL(ag_lim, 0) AS float)),
    SUM(CAST(ISNULL(ag_presentedAccum, 0) AS float)),
    SUM(CAST(ISNULL(ag_acceptedAccum, 0) AS float)),
    @maxd
  FROM ags.spMstrg_2606_ResultSet1
  WHERE ipgKey = @ipg
    AND dateRslt = @maxd
    AND ag_ipgpKey IS NOT NULL;

  SET @ord += 1;
END

SELECT * FROM #m ORDER BY CASE stCostLabel WHEN N'NULL' THEN 0 WHEN N'212' THEN 1 WHEN N'195' THEN 2 WHEN N'172' THEN 3 WHEN N'187' THEN 4 END;

DECLARE @lim212 float, @lim195 float, @lim172 float, @lim187 float;
DECLARE @p212 float, @p195 float, @p172 float, @p187 float, @pNull float;
DECLARE @a212 float, @a195 float, @a172 float, @a187 float, @aNull float;

SELECT @lim212 = sum_lim, @p212 = sum_pres, @a212 = sum_accp FROM #m WHERE stCostLabel = N'212';
SELECT @lim195 = sum_lim, @p195 = sum_pres, @a195 = sum_accp FROM #m WHERE stCostLabel = N'195';
SELECT @lim172 = sum_lim, @p172 = sum_pres, @a172 = sum_accp FROM #m WHERE stCostLabel = N'172';
SELECT @lim187 = sum_lim, @p187 = sum_pres, @a187 = sum_accp FROM #m WHERE stCostLabel = N'187';
SELECT @pNull = sum_pres, @aNull = sum_accp FROM #m WHERE stCostLabel = N'NULL';

SELECT
  ABS(@lim212 - (@lim195+@lim172+@lim187)) AS d_lim,
  ABS(@p212 - (@p195+@p172+@p187)) AS d_pres,
  ABS(@a212 - (@a195+@a172+@a187)) AS d_accp,
  @p212 AS p212, @p195+@p172+@p187 AS p_parts,
  @a212 AS a212, @a195+@a172+@a187 AS a_parts,
  @pNull AS p_null, @aNull AS a_null,
  CASE WHEN ABS(@lim212 - (@lim195+@lim172+@lim187)) <= CAST(@epsilon AS float) THEN N'PASS' ELSE N'FAIL' END AS lim_gate,
  CASE WHEN ABS(@p212 - (@p195+@p172+@p187)) <= CAST(@epsilon AS float) THEN N'PASS' ELSE N'FAIL' END AS pres_gate,
  CASE WHEN ABS(@a212 - (@a195+@a172+@a187)) <= CAST(@epsilon AS float) THEN N'PASS' ELSE N'FAIL' END AS accp_gate,
  CASE WHEN @pNull > 0 AND @aNull > 0 THEN N'PASS' ELSE N'FAIL' END AS null_smoke,
  DATEDIFF(second, @t0, SYSDATETIME()) AS total_sec;
GO
