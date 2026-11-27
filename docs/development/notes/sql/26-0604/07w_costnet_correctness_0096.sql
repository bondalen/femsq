USE [FishEye_prod_noM6];
GO
-- =============================================================================
-- 07w_costnet_correctness_0096.sql
-- §2 плана C4b / задача 0096 / P-2026-11-27-002
-- Gates:
--   G-leaf:  fnStCostUtPlPMn(7226,212,IPG,mn)=0; cost-net → Σ частей (>0)
--   G-stipg: StIpg body передаёт stnType=2 в CstAgPnSh (не ipgcStNetIpg)
--   G-rs:    smoke spMstrg_2606 @507 × {NULL,212,195,172,187} — lim аддитив
--            (паттерн 07k / 0094; ε=0.02)
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @iuplp      int  = 7226;
DECLARE @mn         int  = 4;
DECLARE @ipgCh      int  = 507;
DECLARE @ipg        int  = 27;
DECLARE @end        date = '20261130';
DECLARE @eps        money = 0.02;
DECLARE @fail       bit  = 0;
DECLARE @stNetIpg   int;
DECLARE @stCostNet  int;
DECLARE @leafIpg    money;
DECLARE @leafCost   money;
DECLARE @partsSum   money;
DECLARE @msg        nvarchar(400);
DECLARE @t0         datetime2 = SYSDATETIME();

SELECT @stNetIpg = c.ipgcStNetIpg FROM ags.ipgCh c WHERE c.ipgcKey = @ipgCh;
SELECT TOP (1) @stCostNet = n.stnKey
FROM ags.stNet n
WHERE n.stnType = 2
ORDER BY CASE WHEN n.stnName = N'Стандартная' THEN 0 ELSE 1 END, n.stnKey;

SET @msg = N'=== 07w cost-net 0096  chain=' + CAST(@ipgCh AS nvarchar)
         + N'  ipgNet=' + ISNULL(CAST(@stNetIpg AS nvarchar), N'?')
         + N'  costNet=' + ISNULL(CAST(@stCostNet AS nvarchar), N'?')
         + N' ===';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @stCostNet IS NULL OR @stNetIpg IS NULL
BEGIN
    RAISERROR(N'FAIL: не определены IPG-net / cost-net', 16, 1);
    RETURN;
END

IF @stCostNet = @stNetIpg
    RAISERROR(N'WARN: ipgcStNetIpg совпал с cost-net — leaf-контраст слабее', 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- G-leaf: класс 7226
-- -------------------------------------------------------------------------
RAISERROR(N'--- G-leaf iuplp=7226 ---', 0, 1) WITH NOWAIT;

SELECT @leafIpg  = ags.fnStCostUtPlPMn(@iuplp, 212, @stNetIpg,  @mn);
SELECT @leafCost = ags.fnStCostUtPlPMn(@iuplp, 212, @stCostNet, @mn);

;WITH kids AS (
    SELECT z.strChild, l.iuplpmLim
    FROM ags.fnStDownAll(@stCostNet, 212) z
    INNER JOIN ags.ipgUtPlPnLmMn l
        ON l.iuplpmStCost = z.strChild
       AND l.iuplpmPlPn = @iuplp
       AND l.iuplpmMn = @mn
),
covered AS (
    SELECT DISTINCT k.strChild
    FROM kids k
    CROSS APPLY ags.fnStUpAll(@stCostNet, k.strChild) u
    INNER JOIN kids k2 ON k2.strChild = u.strParent AND k2.strChild <> k.strChild
)
SELECT @partsSum = ISNULL(SUM(k.iuplpmLim), 0) * 1000000
FROM kids k
LEFT JOIN covered c ON c.strChild = k.strChild
WHERE c.strChild IS NULL;

SET @msg = N'leaf ipg=' + CAST(ISNULL(@leafIpg, 0) AS nvarchar)
         + N'  cost=' + CAST(ISNULL(@leafCost, 0) AS nvarchar)
         + N'  parts=' + CAST(ISNULL(@partsSum, 0) AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF EXISTS (
    SELECT 1 FROM ags.ipgUtPlPnLmMn
    WHERE iuplpmPlPn = @iuplp AND iuplpmStCost = 212 AND iuplpmMn = @mn
)
BEGIN
    RAISERROR(N'FAIL G-leaf: у 7226 mn есть прямая 212 — тест маскируется', 16, 1);
    SET @fail = 1;
END
ELSE IF @stNetIpg <> @stCostNet AND ISNULL(@leafIpg, 0) <> 0
BEGIN
    RAISERROR(N'FAIL G-leaf: rollup на IPG-net должен быть 0 без прямой 212', 16, 1);
    SET @fail = 1;
END
ELSE IF ISNULL(@leafCost, 0) <= 0
BEGIN
    RAISERROR(N'FAIL G-leaf: rollup на cost-net должен быть > 0', 16, 1);
    SET @fail = 1;
END
ELSE IF ABS(ISNULL(@leafCost, 0) - ISNULL(@partsSum, 0)) > 0.01
BEGIN
    RAISERROR(N'FAIL G-leaf: leaf cost ≠ Σ неперекрытых частей', 16, 1);
    SET @fail = 1;
END
ELSE
    RAISERROR(N'PASS G-leaf', 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- G-stipg: тело StIpg
-- -------------------------------------------------------------------------
RAISERROR(N'--- G-stipg definition ---', 0, 1) WITH NOWAIT;
DECLARE @def nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'ags.fnMasteringStIpgStCost_2606'));
DECLARE @pos int = CHARINDEX(N'fnMasteringCstAgPnSh_2606', @def);
DECLARE @site nvarchar(700) = CASE WHEN @pos > 0 THEN SUBSTRING(@def, @pos, 700) ELSE N'' END;

-- Call-site должен содержать lookup stnType=2; 4-й arg НЕ ISNULL(@stNet, ipgc…)
IF @def NOT LIKE N'%stnType = 2%'
   OR @site NOT LIKE N'%stnType = 2%'
   OR @site LIKE N'ISNULL(@stNet%'
BEGIN
    RAISERROR(N'FAIL G-stipg: CstAgPnSh должен брать stnType=2, не @stNet/ipgcStNetIpg', 16, 1);
    SET @fail = 1;
END
ELSE
    RAISERROR(N'PASS G-stipg', 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- G-rs: smoke spMstrg @507 (паттерн 07k)
-- -------------------------------------------------------------------------
RAISERROR(N'--- G-rs spMstrg @507 stCost keys ---', 0, 1) WITH NOWAIT;

IF OBJECT_ID(N'tempdb..#m', N'U') IS NOT NULL DROP TABLE #m;
CREATE TABLE #m (
    stCostLabel nvarchar(16) NOT NULL,
    stCostKey   int NULL,
    exitCode    int NULL,
    msec        int NULL,
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
    SET @msg = N'  EXEC spMstrg_2606 stCost=' + @label;
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
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
        SET @msg = N'  ERROR ' + CAST(@rc AS nvarchar) + N': ' + ERROR_MESSAGE();
        RAISERROR(@msg, 0, 1) WITH NOWAIT;
    END CATCH

    SELECT @maxd = MAX(dateRslt)
    FROM ags.spMstrg_2606_ResultSet1
    WHERE ipgKey = @ipg;

    INSERT INTO #m (stCostLabel, stCostKey, exitCode, msec, sum_lim, sum_pres, sum_accp, max_date)
    SELECT
        @label, @stKey, @rc,
        DATEDIFF(millisecond, @t1, SYSDATETIME()),
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

SELECT * FROM #m ORDER BY CASE stCostLabel
    WHEN N'NULL' THEN 0 WHEN N'212' THEN 1 WHEN N'195' THEN 2
    WHEN N'172' THEN 3 WHEN N'187' THEN 4 END;

DECLARE @lim212 float, @lim195 float, @lim172 float, @lim187 float, @limNull float;
DECLARE @p212 float, @p195 float, @p172 float, @p187 float;

SELECT @lim212 = sum_lim, @p212 = sum_pres FROM #m WHERE stCostLabel = N'212';
SELECT @lim195 = sum_lim, @p195 = sum_pres FROM #m WHERE stCostLabel = N'195';
SELECT @lim172 = sum_lim, @p172 = sum_pres FROM #m WHERE stCostLabel = N'172';
SELECT @lim187 = sum_lim, @p187 = sum_pres FROM #m WHERE stCostLabel = N'187';
SELECT @limNull = sum_lim FROM #m WHERE stCostLabel = N'NULL';

DECLARE @dLim float = ABS(ISNULL(@lim212, 0) - (ISNULL(@lim195, 0) + ISNULL(@lim172, 0) + ISNULL(@lim187, 0)));
DECLARE @dPres float = ABS(ISNULL(@p212, 0) - (ISNULL(@p195, 0) + ISNULL(@p172, 0) + ISNULL(@p187, 0)));

SET @msg = N'lim NULL=' + CAST(ISNULL(@limNull, 0) AS nvarchar)
         + N'  212=' + CAST(ISNULL(@lim212, 0) AS nvarchar)
         + N'  parts=' + CAST(ISNULL(@lim195, 0) + ISNULL(@lim172, 0) + ISNULL(@lim187, 0) AS nvarchar)
         + N'  δlim=' + CAST(@dLim AS nvarchar)
         + N'  δpres=' + CAST(@dPres AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF EXISTS (SELECT 1 FROM #m WHERE exitCode <> 0)
BEGIN
    RAISERROR(N'FAIL G-rs: spMstrg exitCode ≠ 0', 16, 1);
    SET @fail = 1;
END
ELSE IF @dLim > CAST(@eps AS float)
BEGIN
    RAISERROR(N'FAIL G-rs: lim 195+172+187 ≉ 212', 16, 1);
    SET @fail = 1;
END
ELSE IF ABS(ISNULL(@limNull, 0) - ISNULL(@lim212, 0)) > CAST(@eps AS float)
BEGIN
    RAISERROR(N'FAIL G-rs: lim @NULL ≉ lim @212', 16, 1);
    SET @fail = 1;
END
ELSE
    RAISERROR(N'PASS G-rs lim additive', 0, 1) WITH NOWAIT;

IF @dPres > CAST(@eps AS float)
    RAISERROR(N'WARN G-rs: fact additive δ > ε (0094-класс; не блокер cost-net)', 0, 1) WITH NOWAIT;
ELSE
    RAISERROR(N'PASS G-rs fact additive', 0, 1) WITH NOWAIT;

SET @msg = N'total_sec=' + CAST(DATEDIFF(second, @t0, SYSDATETIME()) AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @fail = 1
BEGIN
    RAISERROR(N'=== 07w FAIL ===', 16, 1);
    RETURN;
END

RAISERROR(N'=== 07w PASS ===', 0, 1) WITH NOWAIT;
GO
