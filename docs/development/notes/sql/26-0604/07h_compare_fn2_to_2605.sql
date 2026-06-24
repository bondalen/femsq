USE [FishEye];
GO
-- =============================================================================
-- 07h_compare_fn2_to_2605.sql
-- Сравнение fn2_2606 ↔ fn2_2605 с сегментацией по stIpg (эталон dev-приёмки).
-- Стратегия:
--   1) fn2_2605(5, NULL) — один вызов для ВСЕЙ цепи, сохраняем в #all05.
--   2) fn2_2606(5, @stIpg, NULL) — вызов для ОДНОГО stIpg.
--   3) Фильтруем #all05 по контрактам данного stIpg и сравниваем.
--
-- Критерий PASS приёмки: M.1–M.5 (M.5 — lim/presentedAccum; NULL↔0 на stIpg=46 — whitelist).
-- Для сравнения с fn_2408 (диагностика) — 07h_compare_fn2_by_stIpg.sql.
--
-- Параметры: @stIpg — ключ stIpg (61 = малый, 46 = большой)
-- Автор: Александр | Дата: 2026-06-15
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh int = 5;
DECLARE @stIpg int = 61;    -- <<< МЕНЯЙ ЗДЕСЬ (run_acceptance: sed)

DECLARE @msg nvarchar(200);
SET @msg = N'=== 07h: fn2_2606 vs fn2_2605  chain=' + CAST(@ipgCh AS nvarchar) + N'  stIpg=' + CAST(@stIpg AS nvarchar) + N' ===';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#all05') IS NOT NULL DROP TABLE #all05;
IF OBJECT_ID('tempdb..#f06')   IS NOT NULL DROP TABLE #f06;
IF OBJECT_ID('tempdb..#stTc')  IS NOT NULL DROP TABLE #stTc;

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

-- [1] fn2_2605 — вся цепь
DECLARE @t0 datetime2;
SET @t0 = SYSDATETIME();
RAISERROR(N'--- [1/3] fn2_2605 full chain ---', 0, 1) WITH NOWAIT;

SELECT f.ipgKey, f.cstAgPnKey, f.typeGr, f.mNum, f.iShKey, f.lim,
       f.presentedAll, f.presentedAllAccum, f.presented, f.presentedAccum,
       f.accepted, f.acceptedAccum
INTO #all05
FROM ags.fnIpgChRsltCstUtl2_2605(@ipgCh, NULL) f
WHERE f.ipgKey IS NOT NULL;

DECLARE @n05all int; SELECT @n05all = COUNT(*) FROM #all05;
DECLARE @ms05 int;   SET @ms05 = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  fn2_2605 total rows=' + CAST(@n05all AS nvarchar) + N'  time=' + CAST(@ms05 AS nvarchar) + N' ms';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

DECLARE @n05 int;
SELECT @n05 = COUNT(*) FROM #all05 WHERE cstAgPnKey IN (SELECT cstAgPnKey FROM #stTc);
SET @msg = N'  fn2_2605 rows for stIpg=' + CAST(@stIpg AS nvarchar) + N': ' + CAST(@n05 AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- [2] fn2_2606 — данный stIpg
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

-- [3] Сравнение
RAISERROR(N'--- [3/3] comparison ---', 0, 1) WITH NOWAIT;

SET @msg = N'M.1 rows: fn2_2605=' + CAST(@n05 AS nvarchar) + N'  fn2_2606=' + CAST(@n06 AS nvarchar)
         + CASE WHEN @n05=@n06 THEN N'  OK' ELSE N'  DIFF (delta=' + CAST(@n06-@n05 AS nvarchar) + N')' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;

RAISERROR(N'M.2 per ipgKey:', 0, 1) WITH NOWAIT;
SELECT COALESCE(a.ipgKey,b.ipgKey) AS ipgKey,
       ISNULL(a.n05,0) AS n_2605, ISNULL(b.n06,0) AS n_2606,
       CASE WHEN ISNULL(a.n05,0)=ISNULL(b.n06,0) THEN 'OK' ELSE 'DIFF' END AS status
FROM (SELECT ipgKey,COUNT(*) n05 FROM #all05 WHERE cstAgPnKey IN (SELECT cstAgPnKey FROM #stTc) GROUP BY ipgKey) a
FULL JOIN (SELECT ipgKey,COUNT(*) n06 FROM #f06 GROUP BY ipgKey) b ON a.ipgKey=b.ipgKey
ORDER BY COALESCE(a.ipgKey,b.ipgKey);

DECLARE @miss int;
SELECT @miss = COUNT(*) FROM #all05 f5
WHERE f5.cstAgPnKey IN (SELECT cstAgPnKey FROM #stTc)
  AND NOT EXISTS (SELECT 1 FROM #f06 f6
    WHERE f6.ipgKey=f5.ipgKey AND f6.cstAgPnKey=f5.cstAgPnKey
      AND f6.typeGr=f5.typeGr AND f6.mNum=f5.mNum
      AND ISNULL(f6.iShKey,-1)=ISNULL(f5.iShKey,-1));
SET @msg = N'M.3 missing in fn2_2606: ' + CAST(@miss AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

DECLARE @extra int;
SELECT @extra = COUNT(*) FROM #f06 f6
WHERE NOT EXISTS (SELECT 1 FROM #all05 f5
    WHERE f5.cstAgPnKey IN (SELECT cstAgPnKey FROM #stTc)
      AND f5.ipgKey=f6.ipgKey AND f5.cstAgPnKey=f6.cstAgPnKey
      AND f5.typeGr=f6.typeGr AND f5.mNum=f6.mNum
      AND ISNULL(f5.iShKey,-1)=ISNULL(f6.iShKey,-1));
SET @msg = N'M.4 extra in fn2_2606: ' + CAST(@extra AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

DECLARE @vdiff int;
SELECT @vdiff = COUNT(*) FROM #all05 f5
JOIN #f06 f6 ON f6.ipgKey=f5.ipgKey AND f6.cstAgPnKey=f5.cstAgPnKey
             AND f6.typeGr=f5.typeGr AND f6.mNum=f5.mNum
             AND ISNULL(f6.iShKey,-1)=ISNULL(f5.iShKey,-1)
WHERE f5.cstAgPnKey IN (SELECT cstAgPnKey FROM #stTc)
  AND (ABS(ISNULL(f5.lim,0) - ISNULL(f6.lim,0)) > 0.01
    OR ABS(ISNULL(f5.presentedAccum,0) - ISNULL(f6.presentedAccum,0)) > 0.01
    OR ABS(ISNULL(f5.acceptedAccum,0) - ISNULL(f6.acceptedAccum,0)) > 0.01);
SET @msg = N'M.5 lim/presentedAccum diffs: ' + CAST(@vdiff AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

DECLARE @nulln int;
SELECT @nulln = COUNT(*) FROM ags.fnIpgChRsltCstUtl2_2606(@ipgCh, @stIpg, NULL) f
WHERE f.cstAgPnKey IN (SELECT cstAgPnKey FROM #stTc) AND f.ipgKey IS NULL;
SET @msg = N'M.6 null-IPG rows fn2_2606: ' + CAST(@nulln AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

DECLARE @fails int = 0;
IF @n05 <> @n06 SET @fails = @fails + 1;
IF @miss  > 0   SET @fails = @fails + 1;
IF @extra > 0   SET @fails = @fails + 1;
IF @vdiff > 0   SET @fails = @fails + 1;

SET @msg = CASE WHEN @fails=0 THEN N'=== 07h: PASS ===' ELSE N'=== 07h: FAIL (' + CAST(@fails AS nvarchar) + N' check(s)) ===' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;
GO
