USE [FishEye];
GO
-- =============================================================================
-- 07g_mini_fn2_compare_chain5.sql
-- Быстрое сравнение fn2_2606 ↔ fn_2408 по стройкам (ipgPn-уровень).
-- Без PercentBrn и fnMasteringShShow — секунды вместо часов.
--
-- Параметры:
--   @ipgCh       — цепь (5)
--   @stIpgFilter — NULL=все; число=конкретный stIpg-блок (см. ниже)
--   @allContracts— 1=все контракты цепи (при @stIpgFilter IS NULL)
--
-- stIpg цепи 5 (по убыванию контрактов):
--   46→164  27→129  71→100  31→53  30→47  21→47
--   61,66,67,72,74 → 1–5 контрактов (начальный тест)
--
-- Проверки:
--   M.1  Кол-во строк (ipgKey IS NOT NULL)
--   M.2  Распределение по ipgKey
--   M.3  Строки fn_2408, отсутствующие в fn2_2606
--   M.4  Лишние строки fn2_2606 (нет в fn_2408)
--   M.5  Расхождения lim/presentedAccum/acceptedAccum
--   M.6  Кол-во null-IPG строк fn2_2606
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh        int = 5;
DECLARE @stIpgFilter  int = 61;   -- NULL = все; 61 = маленький стартовый блок (1 контракт)
DECLARE @allContracts bit = 0;    -- 1 = все контракты цепи (медленнее)

-- ---- шапка ----
DECLARE @hdr nvarchar(200);
SET @hdr = N'=== 07g: fn2_2606 vs fn_2408  chain=' + CAST(@ipgCh AS nvarchar(3))
         + N'  stIpg=' + ISNULL(CAST(@stIpgFilter AS nvarchar(10)), N'ALL')
         + N'  allContracts=' + CAST(@allContracts AS nvarchar(1)) + N' ===';
RAISERROR(@hdr, 0, 1) WITH NOWAIT;

-- ---- временные таблицы ----
IF OBJECT_ID('tempdb..#tc')  IS NOT NULL DROP TABLE #tc;
IF OBJECT_ID('tempdb..#f08') IS NOT NULL DROP TABLE #f08;
IF OBJECT_ID('tempdb..#f06') IS NOT NULL DROP TABLE #f06;

-- ---- список тестовых контрактов ----
SELECT DISTINCT pp.ipgpCstAgPn AS cstAgPnKey
INTO #tc
FROM ags.ipgPn pp
JOIN ags.ipg ip ON ip.ipgKey = pp.ipgpIpg
JOIN ags.ipgChRl cr ON cr.ipgcrIpg = ip.ipgKey AND cr.ipgcrChain = @ipgCh
WHERE
    (   @stIpgFilter IS NOT NULL
        AND EXISTS (SELECT 1 FROM ags.ipgStPn sp
                    WHERE sp.ipgspSt = @stIpgFilter AND sp.ipgspPn = pp.ipgpKey)
    )
 OR (   @stIpgFilter IS NULL AND @allContracts = 1
    )
 OR (   @stIpgFilter IS NULL AND @allContracts = 0
        AND pp.ipgpCstAgPn IN (4,16,23,849,121,122,428,429)
    );

DECLARE @ntc int;
SELECT @ntc = COUNT(*) FROM #tc;
DECLARE @msg nvarchar(200);
SET @msg = N'  test contracts: ' + CAST(@ntc AS nvarchar(10));
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- ==================================================================
-- [1/3] fn_2408
DECLARE @t0 datetime2;
SET @t0 = SYSDATETIME();
RAISERROR(N'--- [1/3] materialize fn_2408 ---', 0, 1) WITH NOWAIT;

SELECT f.ipgKey, f.cstAgPnKey, f.typeGr, f.mNum, f.iShKey, f.lim,
       f.presentedAll, f.presentedAllAccum, f.presented, f.presentedAccum,
       f.accepted, f.acceptedAccum
INTO #f08
FROM ags.fnIpgChRsltCstUtl_2408(@ipgCh) f
WHERE f.cstAgPnKey IN (SELECT cstAgPnKey FROM #tc)
  AND f.ipgKey IS NOT NULL;

DECLARE @n08 int;  SELECT @n08 = COUNT(*) FROM #f08;
DECLARE @el08 int; SET @el08 = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  fn_2408 rows=' + CAST(@n08 AS nvarchar(10)) + N'  elapsed=' + CAST(@el08 AS nvarchar(10)) + N' ms';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- ==================================================================
-- [2/3] fn2_2606
SET @t0 = SYSDATETIME();
RAISERROR(N'--- [2/3] materialize fn2_2606 ---', 0, 1) WITH NOWAIT;

SELECT f.ipgKey, f.cstAgPnKey, f.typeGr, f.mNum, f.iShKey, f.lim,
       f.presentedAll, f.presentedAllAccum, f.presented, f.presentedAccum,
       f.accepted, f.acceptedAccum
INTO #f06
FROM ags.fnIpgChRsltCstUtl2_2606(@ipgCh, NULL, NULL) f
WHERE f.cstAgPnKey IN (SELECT cstAgPnKey FROM #tc)
  AND f.ipgKey IS NOT NULL;

DECLARE @n06 int;  SELECT @n06 = COUNT(*) FROM #f06;
DECLARE @el06 int; SET @el06 = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  fn2_2606 rows=' + CAST(@n06 AS nvarchar(10)) + N'  elapsed=' + CAST(@el06 AS nvarchar(10)) + N' ms';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- ==================================================================
-- [3/3] comparison
RAISERROR(N'--- [3/3] comparison ---', 0, 1) WITH NOWAIT;

-- M.1
SET @msg = N'M.1 rows: fn_2408=' + CAST(@n08 AS nvarchar(10)) + N'  fn2_2606=' + CAST(@n06 AS nvarchar(10))
         + CASE WHEN @n08=@n06 THEN N'  OK' ELSE N'  DIFF (delta=' + CAST(@n06-@n08 AS nvarchar(10)) + N')' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- M.2
RAISERROR(N'M.2 per ipgKey:', 0, 1) WITH NOWAIT;
SELECT COALESCE(a.ipgKey,b.ipgKey) AS ipgKey,
       ISNULL(a.n08,0) AS n_2408, ISNULL(b.n06,0) AS n_2606,
       CASE WHEN ISNULL(a.n08,0)=ISNULL(b.n06,0) THEN 'OK' ELSE 'DIFF' END AS status
FROM (SELECT ipgKey, COUNT(*) n08 FROM #f08 GROUP BY ipgKey) a
FULL JOIN (SELECT ipgKey, COUNT(*) n06 FROM #f06 GROUP BY ipgKey) b ON a.ipgKey=b.ipgKey
ORDER BY COALESCE(a.ipgKey,b.ipgKey);

-- M.3 missing
DECLARE @miss int;
SELECT @miss = COUNT(*) FROM #f08 f8
WHERE NOT EXISTS (SELECT 1 FROM #f06 f6
    WHERE f6.ipgKey=f8.ipgKey AND f6.cstAgPnKey=f8.cstAgPnKey
      AND f6.typeGr=f8.typeGr AND f6.mNum=f8.mNum
      AND ISNULL(f6.iShKey,-1)=ISNULL(f8.iShKey,-1));
SET @msg = N'M.3 missing in fn2_2606: ' + CAST(@miss AS nvarchar(10));
RAISERROR(@msg, 0, 1) WITH NOWAIT;
IF @miss > 0
    SELECT TOP 15 f8.cstAgPnKey,f8.ipgKey,f8.iShKey,f8.mNum,f8.typeGr,f8.lim,f8.presentedAccum
    FROM #f08 f8
    WHERE NOT EXISTS (SELECT 1 FROM #f06 f6
        WHERE f6.ipgKey=f8.ipgKey AND f6.cstAgPnKey=f8.cstAgPnKey
          AND f6.typeGr=f8.typeGr AND f6.mNum=f8.mNum
          AND ISNULL(f6.iShKey,-1)=ISNULL(f8.iShKey,-1))
    ORDER BY f8.cstAgPnKey,f8.ipgKey,f8.mNum;

-- M.4 extra
DECLARE @extra int;
SELECT @extra = COUNT(*) FROM #f06 f6
WHERE NOT EXISTS (SELECT 1 FROM #f08 f8
    WHERE f8.ipgKey=f6.ipgKey AND f8.cstAgPnKey=f6.cstAgPnKey
      AND f8.typeGr=f6.typeGr AND f8.mNum=f6.mNum
      AND ISNULL(f8.iShKey,-1)=ISNULL(f6.iShKey,-1));
SET @msg = N'M.4 extra in fn2_2606: ' + CAST(@extra AS nvarchar(10));
RAISERROR(@msg, 0, 1) WITH NOWAIT;
IF @extra > 0
    SELECT TOP 15 f6.cstAgPnKey,f6.ipgKey,f6.iShKey,f6.mNum,f6.typeGr,f6.lim,f6.presentedAccum
    FROM #f06 f6
    WHERE NOT EXISTS (SELECT 1 FROM #f08 f8
        WHERE f8.ipgKey=f6.ipgKey AND f8.cstAgPnKey=f6.cstAgPnKey
          AND f8.typeGr=f6.typeGr AND f8.mNum=f6.mNum
          AND ISNULL(f8.iShKey,-1)=ISNULL(f6.iShKey,-1))
    ORDER BY f6.cstAgPnKey,f6.ipgKey,f6.mNum;

-- M.5 value diffs
DECLARE @vdiff int;
SELECT @vdiff = COUNT(*) FROM #f08 f8
JOIN #f06 f6 ON f6.ipgKey=f8.ipgKey AND f6.cstAgPnKey=f8.cstAgPnKey
             AND f6.typeGr=f8.typeGr AND f6.mNum=f8.mNum
             AND ISNULL(f6.iShKey,-1)=ISNULL(f8.iShKey,-1)
WHERE ISNULL(f8.lim,            -999999.0) <> ISNULL(f6.lim,            -999999.0)
   OR ISNULL(f8.presentedAccum, -999999.0) <> ISNULL(f6.presentedAccum, -999999.0)
   OR ISNULL(f8.acceptedAccum,  -999999.0) <> ISNULL(f6.acceptedAccum,  -999999.0);
SET @msg = N'M.5 lim/pres/acc diffs: ' + CAST(@vdiff AS nvarchar(10));
RAISERROR(@msg, 0, 1) WITH NOWAIT;
IF @vdiff > 0
    SELECT TOP 15 f8.cstAgPnKey,f8.ipgKey,f8.iShKey,f8.mNum,f8.typeGr,
           f8.lim AS lim08, f6.lim AS lim06,
           f8.presentedAccum AS pres08, f6.presentedAccum AS pres06,
           f8.acceptedAccum  AS acc08,  f6.acceptedAccum  AS acc06
    FROM #f08 f8
    JOIN #f06 f6 ON f6.ipgKey=f8.ipgKey AND f6.cstAgPnKey=f8.cstAgPnKey
                 AND f6.typeGr=f8.typeGr AND f6.mNum=f8.mNum
                 AND ISNULL(f6.iShKey,-1)=ISNULL(f6.iShKey,-1)
    WHERE ISNULL(f8.lim,            -999999.0) <> ISNULL(f6.lim,            -999999.0)
       OR ISNULL(f8.presentedAccum, -999999.0) <> ISNULL(f6.presentedAccum, -999999.0)
       OR ISNULL(f8.acceptedAccum,  -999999.0) <> ISNULL(f6.acceptedAccum,  -999999.0)
    ORDER BY f8.cstAgPnKey,f8.ipgKey,f8.mNum;

-- M.6 null-IPG
SET @t0 = SYSDATETIME();
RAISERROR(N'M.6 null-IPG fn2_2606 (counting)...', 0, 1) WITH NOWAIT;
DECLARE @nulln int;
SELECT @nulln = COUNT(*)
FROM ags.fnIpgChRsltCstUtl2_2606(@ipgCh, NULL, NULL) f
WHERE f.cstAgPnKey IN (SELECT cstAgPnKey FROM #tc)
  AND f.ipgKey IS NULL;
DECLARE @elnull int; SET @elnull = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  null-IPG rows=' + CAST(@nulln AS nvarchar(10)) + N'  elapsed=' + CAST(@elnull AS nvarchar(10)) + N' ms';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- ==================================================================
DECLARE @fails int;
SET @fails = 0;
IF @n08 <> @n06 SET @fails = @fails + 1;
IF @miss  > 0   SET @fails = @fails + 1;
IF @extra > 0   SET @fails = @fails + 1;
IF @vdiff > 0   SET @fails = @fails + 1;

SET @msg = CASE WHEN @fails=0 THEN N'=== 07g: PASS ===' ELSE N'=== 07g: FAIL (' + CAST(@fails AS nvarchar(3)) + N' check(s)) ===' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;
GO
