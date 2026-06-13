USE [FishEye];
GO
-- =============================================================================
-- 07h2_perf_contracts_stIpg46.sql  (универсально: любой @stIpg)
-- По одной стройке (cstAgPn) в группе stIpg: замер fnMasteringCstAgPnSh_2606.
-- Эталон: stIpg=61 (~1 контракт, fn2 ~9 сек); проблемная: stIpg=46 (164 контракта).
--
-- Параметры (в DECLARE ниже или через run_07h2_contract.sh):
--   @stIpg        — группа stIpg (61, 46, …)
--   @fromRn,@toRn — диапазон порядковых номеров (1..N), NULL = все
--   @slowMs       — порог «медленной» стройки для отдельного сообщения
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh   int = 5;
DECLARE @stIpg   int = 61;
DECLARE @stCost  int = 212;   -- корень stCost (как в fnMasteringStIpgStCost)
DECLARE @fromRn  int = NULL;  -- <<< с какой стройки (1-based), NULL = 1
DECLARE @toRn    int = NULL;  -- <<< по какую, NULL = все
DECLARE @slowMs  int = 1000;  -- порог медленной стройки

DECLARE @stNet int = (SELECT c.ipgcStNetIpg FROM ags.ipgCh c WHERE c.ipgcKey = @ipgCh);

IF OBJECT_ID('tempdb..#contracts') IS NOT NULL DROP TABLE #contracts;
CREATE TABLE #contracts (
    rn int NOT NULL PRIMARY KEY,
    cstAgPnKey int NOT NULL,
    cstAgPnCode nvarchar(255) NULL
);

INSERT INTO #contracts (rn, cstAgPnKey, cstAgPnCode)
SELECT ROW_NUMBER() OVER (ORDER BY t.cstAgPnKey) AS rn,
       t.cstAgPnKey,
       cap.cstapIpgPnN
FROM (
    SELECT DISTINCT pp.ipgpCstAgPn AS cstAgPnKey
    FROM ags.ipgPn pp
    INNER JOIN ags.ipg ip ON ip.ipgKey = pp.ipgpIpg
    INNER JOIN ags.ipgChRl cr ON cr.ipgcrIpg = ip.ipgKey AND cr.ipgcrChain = @ipgCh
    WHERE EXISTS (
        SELECT 1 FROM ags.ipgStPn sp
        WHERE sp.ipgspSt = @stIpg AND sp.ipgspPn = pp.ipgpKey
    )
) t
INNER JOIN ags.cstAgPn cap ON cap.cstapKey = t.cstAgPnKey;

DECLARE @total int = (SELECT COUNT(*) FROM #contracts);
DECLARE @i int = ISNULL(@fromRn, 1);
DECLARE @iEnd int = ISNULL(@toRn, @total);
DECLARE @cac int;
DECLARE @code nvarchar(255);
DECLARE @t0 datetime2;
DECLARE @ms int;
DECLARE @rows int;
DECLARE @msg nvarchar(500);
DECLARE @sumMs bigint = 0;
DECLARE @maxMs int = 0;
DECLARE @maxCac int = NULL;
DECLARE @slowCnt int = 0;

SET @msg = N'=== 07h2: stIpg=' + CAST(@stIpg AS nvarchar)
    + N' contracts=' + CAST(@total AS nvarchar)
    + N' range=' + CAST(@i AS nvarchar) + N'..' + CAST(@iEnd AS nvarchar) + N' ===';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#perf') IS NOT NULL DROP TABLE #perf;
CREATE TABLE #perf (
    rn int,
    cstAgPnKey int,
    cstAgPnCode nvarchar(255),
    rowCnt int,
    ms int
);

WHILE @i <= @iEnd
BEGIN
    SELECT @cac = cstAgPnKey, @code = cstAgPnCode FROM #contracts WHERE rn = @i;

    SET @t0 = SYSDATETIME();
    SELECT @rows = COUNT(*)
    FROM ags.fnMasteringCstAgPnSh_2606(@ipgCh, @cac, @stCost, @stNet, @stIpg);
    SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());

    INSERT INTO #perf (rn, cstAgPnKey, cstAgPnCode, rowCnt, ms)
    VALUES (@i, @cac, @code, @rows, @ms);

    SET @sumMs += @ms;
    IF @ms > @maxMs BEGIN SET @maxMs = @ms; SET @maxCac = @cac; END
    IF @ms >= @slowMs SET @slowCnt += 1;

    IF @ms >= @slowMs OR @i = @iEnd OR @i % 20 = 0
    BEGIN
        SET @msg = N'  [' + CAST(@i AS nvarchar) + N'/' + CAST(@iEnd AS nvarchar)
            + N'] cac=' + CAST(@cac AS nvarchar)
            + N' ' + ISNULL(@code, N'')
            + N' rows=' + CAST(@rows AS nvarchar)
            + N' ms=' + CAST(@ms AS nvarchar);
        RAISERROR(@msg, 0, 1) WITH NOWAIT;
    END

    SET @i += 1;
END

SET @msg = N'--- SUMMARY range ms=' + CAST(@sumMs AS nvarchar)
    + N' avg=' + CAST(CASE WHEN @iEnd >= ISNULL(@fromRn,1) THEN @sumMs / (@iEnd - ISNULL(@fromRn,1) + 1) ELSE 0 END AS nvarchar)
    + N' maxMs=' + CAST(@maxMs AS nvarchar)
    + N' maxCac=' + ISNULL(CAST(@maxCac AS nvarchar), N'-')
    + N' slow(>=' + CAST(@slowMs AS nvarchar) + N'ms)=' + CAST(@slowCnt AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

RAISERROR(N'--- TOP 15 slowest ---', 0, 1) WITH NOWAIT;
SELECT TOP 15 rn, cstAgPnKey, cstAgPnCode, rowCnt, ms
FROM #perf
ORDER BY ms DESC, cstAgPnKey;

RAISERROR(N'=== 07h2 DONE ===', 0, 1) WITH NOWAIT;
GO
