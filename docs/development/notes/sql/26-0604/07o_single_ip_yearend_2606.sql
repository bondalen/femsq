USE [FishEye];
GO

-- =============================================================================
-- Файл:    07o_single_ip_yearend_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Gate К-12b@yearend для одиночных цепей 501 (ИП 6) / 502 (ИП 8).
--   iv_PlAccum @ 2022-12-31 = лимит ipgPn@212; invest-golden cst 2102, stIpg=42.
-- Предусловия: FIXTURE_06, FIXTURE_10, 05c (plan LmMn@212).
-- Автор:   Александр | Дата: 2026-07-06
-- =============================================================================

SET NOCOUNT ON;
GO

RAISERROR(N'=== 07o single-IP yearend: chains 501/502, cst 2102 ===', 0, 1) WITH NOWAIT;

DECLARE @stIpg   int  = 42;
DECLARE @cstAgPn int  = 2102;
DECLARE @dt      date = '2022-12-31';
DECLARE @epsilon money = 1.0;
DECLARE @fail    int  = 0;
DECLARE @msg     nvarchar(500);

IF OBJECT_ID('tempdb..#expect') IS NOT NULL DROP TABLE #expect;

SELECT
    v.ipgcrvChain AS chainNo,
    v.ipgcrvIpg   AS ipgKey,
    pn.ipgpKey,
    COALESCE(l.ipgplLim, pn.ipgpSmTtl) * 1000000 AS lim212_rub
INTO #expect
FROM ags.ipgChRl_2606 v
INNER JOIN ags.ipgPn pn ON pn.ipgpIpg = v.ipgcrvIpg AND pn.ipgpCstAgPn = @cstAgPn
LEFT JOIN ags.ipgPnLim l ON l.ipgplPn = pn.ipgpKey AND l.ipgplStCost = 212
WHERE v.ipgcrvChain IN (501, 502);

SELECT * FROM #expect ORDER BY chainNo;

IF (SELECT COUNT(*) FROM #expect) <> 2
BEGIN
    RAISERROR(N'  FAIL: expected 2 chains (501/502). Run FIXTURE_10_00.', 16, 1);
    RETURN;
END;

IF OBJECT_ID('tempdb..#plan') IS NOT NULL DROP TABLE #plan;

SELECT
    e.chainNo,
    e.ipgKey,
    e.ipgpKey,
    e.lim212_rub,
    p.iv_Pl,
    p.iv_PlAccum,
    p.iv_PlAccum - e.lim212_rub AS diff_accum
INTO #plan
FROM #expect e
OUTER APPLY (
    SELECT TOP 1
        pb.iv_Pl,
        pb.iv_PlAccum
    FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(e.chainNo, @stIpg, NULL) pb
    WHERE pb.cstapKey = @cstAgPn
      AND pb.ipgKey = e.ipgKey
      AND pb.dateRslt = @dt
) p;

SELECT chainNo, ipgKey, lim212_rub, iv_Pl, iv_PlAccum, diff_accum FROM #plan ORDER BY chainNo;

DECLARE @ch int, @ipg int, @lim money, @pl money, @plAcc money, @diff money;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT chainNo, ipgKey, lim212_rub, iv_Pl, iv_PlAccum, diff_accum FROM #plan;
OPEN cur;
FETCH NEXT FROM cur INTO @ch, @ipg, @lim, @pl, @plAcc, @diff;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF ISNULL(@plAcc, 0) = 0 OR ABS(ISNULL(@diff, 0)) > @epsilon
    BEGIN
        SET @fail = @fail + 1;
        SET @msg = N'  FAIL: chain=' + CAST(@ch AS nvarchar(10))
            + N' ipg=' + CAST(@ipg AS nvarchar(10))
            + N' iv_PlAccum=' + CAST(ISNULL(@plAcc, 0) AS nvarchar(30))
            + N' lim=' + CAST(ISNULL(@lim, 0) AS nvarchar(30));
        RAISERROR(@msg, 0, 1) WITH NOWAIT;
    END
    ELSE IF ISNULL(@pl, 0) = 0
    BEGIN
        SET @msg = N'  WARN: chain=' + CAST(@ch AS nvarchar(10))
            + N' ipg=' + CAST(@ipg AS nvarchar(10))
            + N' iv_Pl=0 @yearend (accum=lim OK)';
        RAISERROR(@msg, 0, 1) WITH NOWAIT;
    END
    ELSE
    BEGIN
        SET @msg = N'  OK: chain=' + CAST(@ch AS nvarchar(10))
            + N' ipg=' + CAST(@ipg AS nvarchar(10))
            + N' iv_Pl+iv_PlAccum = lim@yearend';
        RAISERROR(@msg, 0, 1) WITH NOWAIT;
    END
    FETCH NEXT FROM cur INTO @ch, @ipg, @lim, @pl, @plAcc, @diff;
END
CLOSE cur;
DEALLOCATE cur;

IF @fail = 0
    RAISERROR(N'=== 07o single-IP yearend: PASS ===', 0, 1) WITH NOWAIT;
ELSE
    RAISERROR(N'=== 07o single-IP yearend: FAIL ===', 0, 1) WITH NOWAIT;
GO
