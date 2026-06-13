USE [FishEye];
GO
-- =============================================================================
-- 07h_compare_fn2_by_stIpg.sql
-- Сравнение fn2_2606 ↔ fn_2408 с сегментацией по stIpg.
-- Стратегия:
--   1) fn_2408(5) — один вызов для ВСЕЙ цепи (~7 сек), сохраняем в #all08.
--   2) fn2_2606(5, @stIpg, NULL) — вызов для ОДНОГО stIpg (~11 сек).
--   3) Фильтруем #all08 по контрактам данного stIpg и сравниваем.
--
-- Параметры:
--   @stIpg — ключ stIpg для проверки (пример: 61 = маленький, 46 = большой)
--
-- stIpg цепи 5 по убыванию:
--   46→164 контракта  27→129  71→100  31→53  30→47
--   61,66,67,72,74    → 1–5 контрактов (начинай с малых)
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh int = 5;
DECLARE @stIpg int = 61;    -- <<< МЕНЯЙ ЗДЕСЬ

DECLARE @msg nvarchar(200);
SET @msg = N'=== 07h: fn2_2606 vs fn_2408  chain=' + CAST(@ipgCh AS nvarchar) + N'  stIpg=' + CAST(@stIpg AS nvarchar) + N' ===';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#all08') IS NOT NULL DROP TABLE #all08;
IF OBJECT_ID('tempdb..#f06')   IS NOT NULL DROP TABLE #f06;
IF OBJECT_ID('tempdb..#stTc')  IS NOT NULL DROP TABLE #stTc;

-- Контракты данного stIpg в цепи
SELECT DISTINCT pp.ipgpCstAgPn AS cstAgPnKey
INTO #stTc
FROM ags.ipgPn pp
JOIN ags.ipg ip ON ip.ipgKey = pp.ipgpIpg
JOIN ags.ipgChRl cr ON cr.ipgcrIpg = ip.ipgKey AND cr.ipgcrChain = @ipgCh
WHERE EXISTS (SELECT 1 FROM ags.ipgStPn sp
              WHERE sp.ipgspSt = @stIpg AND sp.ipgspPn = pp.ipgpKey);

DECLARE @ntc int;
SELECT @ntc = COUNT(*) FROM #stTc;
SET @msg = N'  stIpg=' + CAST(@stIpg AS nvarchar) + N' contracts=' + CAST(@ntc AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- =====================================================================
-- [1] fn_2408 — ВСЯ цепь (один вызов, фильтруем потом)
DECLARE @t0 datetime2;
SET @t0 = SYSDATETIME();
RAISERROR(N'--- [1/3] fn_2408 full chain (будет использован для всех stIpg) ---', 0, 1) WITH NOWAIT;

SELECT f.ipgKey, f.cstAgPnKey, f.typeGr, f.mNum, f.iShKey, f.lim,
       f.presentedAll, f.presentedAllAccum, f.presented, f.presentedAccum,
       f.accepted, f.acceptedAccum
INTO #all08
FROM ags.fnIpgChRsltCstUtl_2408(@ipgCh) f
WHERE f.ipgKey IS NOT NULL;   -- всегда НЕ NULL в fn_2408

DECLARE @n08all int; SELECT @n08all = COUNT(*) FROM #all08;
DECLARE @ms08 int;   SET @ms08 = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  fn_2408 total rows=' + CAST(@n08all AS nvarchar) + N'  time=' + CAST(@ms08 AS nvarchar) + N' ms';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- Фильтруем fn_2408 по stIpg
DECLARE @n08 int;
SELECT @n08 = COUNT(*) FROM #all08 WHERE cstAgPnKey IN (SELECT cstAgPnKey FROM #stTc);
SET @msg = N'  fn_2408 rows for stIpg=' + CAST(@stIpg AS nvarchar) + N': ' + CAST(@n08 AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- =====================================================================
-- [2] fn2_2606 — ТОЛЬКО данный stIpg
SET @t0 = SYSDATETIME();
RAISERROR(N'--- [2/3] fn2_2606 filtered by stIpg ---', 0, 1) WITH NOWAIT;

SELECT f.ipgKey, f.cstAgPnKey, f.typeGr, f.mNum, f.iShKey, f.lim,
       f.presentedAll, f.presentedAllAccum, f.presented, f.presentedAccum,
       f.accepted, f.acceptedAccum
INTO #f06
FROM ags.fnIpgChRsltCstUtl2_2606(@ipgCh, @stIpg, NULL) f
WHERE f.cstAgPnKey IN (SELECT cstAgPnKey FROM #stTc)
  AND f.ipgKey IS NOT NULL;

DECLARE @n06 int; SELECT @n06 = COUNT(*) FROM #f06;
DECLARE @ms06 int; SET @ms06 = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  fn2_2606 rows=' + CAST(@n06 AS nvarchar) + N'  time=' + CAST(@ms06 AS nvarchar) + N' ms';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- =====================================================================
-- [3] Сравнение
RAISERROR(N'--- [3/3] comparison ---', 0, 1) WITH NOWAIT;

-- M.1
SET @msg = N'M.1 rows: fn_2408=' + CAST(@n08 AS nvarchar) + N'  fn2_2606=' + CAST(@n06 AS nvarchar)
         + CASE WHEN @n08=@n06 THEN N'  OK' ELSE N'  DIFF (delta=' + CAST(@n06-@n08 AS nvarchar) + N')' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- M.2 per ipgKey
RAISERROR(N'M.2 per ipgKey:', 0, 1) WITH NOWAIT;
SELECT COALESCE(a.ipgKey,b.ipgKey) AS ipgKey,
       ISNULL(a.n08,0) AS n_2408, ISNULL(b.n06,0) AS n_2606,
       CASE WHEN ISNULL(a.n08,0)=ISNULL(b.n06,0) THEN 'OK' ELSE 'DIFF' END AS status
FROM (SELECT ipgKey,COUNT(*) n08 FROM #all08 WHERE cstAgPnKey IN (SELECT cstAgPnKey FROM #stTc) GROUP BY ipgKey) a
FULL JOIN (SELECT ipgKey,COUNT(*) n06 FROM #f06 GROUP BY ipgKey) b ON a.ipgKey=b.ipgKey
ORDER BY COALESCE(a.ipgKey,b.ipgKey);

-- M.3 missing
DECLARE @miss int;
SELECT @miss = COUNT(*) FROM #all08 f8
WHERE f8.cstAgPnKey IN (SELECT cstAgPnKey FROM #stTc)
  AND NOT EXISTS (SELECT 1 FROM #f06 f6
    WHERE f6.ipgKey=f8.ipgKey AND f6.cstAgPnKey=f8.cstAgPnKey
      AND f6.typeGr=f8.typeGr AND f6.mNum=f8.mNum
      AND ISNULL(f6.iShKey,-1)=ISNULL(f8.iShKey,-1));
SET @msg = N'M.3 missing in fn2_2606: ' + CAST(@miss AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;
IF @miss > 0
    SELECT TOP 20 f8.cstAgPnKey,f8.ipgKey,f8.iShKey,f8.mNum,f8.typeGr,f8.lim,f8.presentedAccum
    FROM #all08 f8
    WHERE f8.cstAgPnKey IN (SELECT cstAgPnKey FROM #stTc)
      AND NOT EXISTS (SELECT 1 FROM #f06 f6
        WHERE f6.ipgKey=f8.ipgKey AND f6.cstAgPnKey=f8.cstAgPnKey
          AND f6.typeGr=f8.typeGr AND f6.mNum=f8.mNum
          AND ISNULL(f6.iShKey,-1)=ISNULL(f8.iShKey,-1))
    ORDER BY f8.cstAgPnKey,f8.ipgKey,f8.mNum;

-- M.4 extra
DECLARE @extra int;
SELECT @extra = COUNT(*) FROM #f06 f6
WHERE NOT EXISTS (SELECT 1 FROM #all08 f8
    WHERE f8.cstAgPnKey IN (SELECT cstAgPnKey FROM #stTc)
      AND f8.ipgKey=f6.ipgKey AND f8.cstAgPnKey=f6.cstAgPnKey
      AND f8.typeGr=f6.typeGr AND f8.mNum=f6.mNum
      AND ISNULL(f8.iShKey,-1)=ISNULL(f6.iShKey,-1));
SET @msg = N'M.4 extra in fn2_2606: ' + CAST(@extra AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;
IF @extra > 0
    SELECT TOP 20 f6.cstAgPnKey,f6.ipgKey,f6.iShKey,f6.mNum,f6.typeGr,f6.lim,f6.presentedAccum
    FROM #f06 f6
    WHERE NOT EXISTS (SELECT 1 FROM #all08 f8
        WHERE f8.cstAgPnKey IN (SELECT cstAgPnKey FROM #stTc)
          AND f8.ipgKey=f6.ipgKey AND f8.cstAgPnKey=f6.cstAgPnKey
          AND f8.typeGr=f6.typeGr AND f8.mNum=f6.mNum
          AND ISNULL(f8.iShKey,-1)=ISNULL(f6.iShKey,-1))
    ORDER BY f6.cstAgPnKey,f6.ipgKey,f6.mNum;

-- M.5 value diffs
DECLARE @vdiff int;
SELECT @vdiff = COUNT(*) FROM #all08 f8
JOIN #f06 f6 ON f6.ipgKey=f8.ipgKey AND f6.cstAgPnKey=f8.cstAgPnKey
             AND f6.typeGr=f8.typeGr AND f6.mNum=f8.mNum
             AND ISNULL(f6.iShKey,-1)=ISNULL(f8.iShKey,-1)
WHERE f8.cstAgPnKey IN (SELECT cstAgPnKey FROM #stTc)
  AND (ISNULL(f8.lim,           -999999.0) <> ISNULL(f6.lim,           -999999.0)
    OR ISNULL(f8.presentedAccum,-999999.0) <> ISNULL(f6.presentedAccum,-999999.0)
    OR ISNULL(f8.acceptedAccum, -999999.0) <> ISNULL(f6.acceptedAccum, -999999.0));
SET @msg = N'M.5 lim/presentedAccum diffs: ' + CAST(@vdiff AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;
IF @vdiff > 0
    SELECT TOP 20 f8.cstAgPnKey,f8.ipgKey,f8.iShKey,f8.mNum,f8.typeGr,
           f8.lim AS lim08, f6.lim AS lim06,
           f8.presentedAccum AS pres08, f6.presentedAccum AS pres06,
           f8.acceptedAccum  AS acc08,  f6.acceptedAccum  AS acc06
    FROM #all08 f8
    JOIN #f06 f6 ON f6.ipgKey=f8.ipgKey AND f6.cstAgPnKey=f8.cstAgPnKey
                 AND f6.typeGr=f8.typeGr AND f6.mNum=f8.mNum
                 AND ISNULL(f6.iShKey,-1)=ISNULL(f8.iShKey,-1)
    WHERE f8.cstAgPnKey IN (SELECT cstAgPnKey FROM #stTc)
      AND (ISNULL(f8.lim,           -999999.0) <> ISNULL(f6.lim,           -999999.0)
        OR ISNULL(f8.presentedAccum,-999999.0) <> ISNULL(f6.presentedAccum,-999999.0)
        OR ISNULL(f8.acceptedAccum, -999999.0) <> ISNULL(f6.acceptedAccum, -999999.0))
    ORDER BY f8.cstAgPnKey,f8.ipgKey,f8.mNum;

-- M.6 null-IPG
DECLARE @nulln int;
SELECT @nulln = COUNT(*) FROM ags.fnIpgChRsltCstUtl2_2606(@ipgCh, @stIpg, NULL) f
WHERE f.cstAgPnKey IN (SELECT cstAgPnKey FROM #stTc) AND f.ipgKey IS NULL;
SET @msg = N'M.6 null-IPG rows fn2_2606: ' + CAST(@nulln AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- =====================================================================
DECLARE @fails int;
SET @fails = 0;
IF @n08 <> @n06 SET @fails = @fails + 1;
IF @miss  > 0   SET @fails = @fails + 1;
IF @extra > 0   SET @fails = @fails + 1;
IF @vdiff > 0   SET @fails = @fails + 1;

SET @msg = CASE WHEN @fails=0 THEN N'=== 07h: PASS ===' ELSE N'=== 07h: FAIL (' + CAST(@fails AS nvarchar) + N' check(s)) ===' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;
GO
