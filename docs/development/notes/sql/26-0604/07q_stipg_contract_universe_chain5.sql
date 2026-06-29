USE [FishEye];
GO

-- =============================================================================
-- Файл:    07q_stipg_contract_universe_chain5.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Приёмка этапа 19.4 — универсум договоров IN_GROUP ∪ OUT_GROUP
--   (Решение 16): TVF fnIpgChContractsForStIpg_2606 и фильтр ipgChContracts в fn2.
--   Цепь 5, stIpg: NULL, 1, 51, 45, 42, 61.
-- Предусловия: 10a–10d, патч 04 (fnIpgChRsltCstUtl2_2606).
-- Автор:   Александр
-- Дата:    2026-06-29
-- =============================================================================

SET NOCOUNT ON;
GO

RAISERROR(N'=== 07q: contract universe chain 5 (Решение 16) ===', 0, 1) WITH NOWAIT;

DECLARE @ipgCh int = 5;
DECLARE @fail int = 0;
DECLARE @msg nvarchar(500);

DECLARE @cases TABLE (
    ord        int          NOT NULL PRIMARY KEY,
    stIpgKey   int          NULL,
    expectedCnt int         NOT NULL,
    label      nvarchar(10) NOT NULL,
    requireMissingZero bit  NOT NULL
);

INSERT INTO @cases (ord, stIpgKey, expectedCnt, label, requireMissingZero) VALUES
    (1, NULL, 968, N'NULL', 0),
    (2, 1,    968, N'1',    0),
    (3, 51,   967, N'51',   0),
    (4, 45,     0, N'45',   1),
    (5, 42,     1, N'42',   1),
    (6, 61,     1, N'61',   1);

DECLARE @ord int, @stIpgKey int, @expectedCnt int, @label nvarchar(10), @requireMissingZero bit;
DECLARE @tvfCnt int, @fn2Distinct int, @extraCnt int, @missingCnt int, @fn2Rows int;
DECLARE @t0 datetime2, @ms int;

DECLARE case_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT ord, stIpgKey, expectedCnt, label, requireMissingZero
    FROM @cases
    ORDER BY ord;

OPEN case_cur;
FETCH NEXT FROM case_cur INTO @ord, @stIpgKey, @expectedCnt, @label, @requireMissingZero;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @t0 = SYSDATETIME();
    SET @msg = N'--- stIpg=' + @label + N' ---';
    RAISERROR(@msg, 0, 1) WITH NOWAIT;

    IF OBJECT_ID('tempdb..#tvfCst') IS NOT NULL DROP TABLE #tvfCst;
    IF OBJECT_ID('tempdb..#fn2Cst') IS NOT NULL DROP TABLE #fn2Cst;

    SELECT DISTINCT cstAgPnKey
    INTO #tvfCst
    FROM ags.fnIpgChContractsForStIpg_2606(@ipgCh, @stIpgKey);

    SELECT @tvfCnt = COUNT(*) FROM #tvfCst;

    SET @msg = N'  TVF DISTINCT cstAgPn: ' + CAST(@tvfCnt AS nvarchar(10))
        + N' (expected ' + CAST(@expectedCnt AS nvarchar(10)) + N')';
    RAISERROR(@msg, 0, 1) WITH NOWAIT;

    IF @tvfCnt <> @expectedCnt
    BEGIN
        SET @fail = @fail + 1;
        RAISERROR(N'  FAIL: TVF count mismatch', 0, 1) WITH NOWAIT;
    END

    SELECT cstAgPnKey, COUNT(*) AS rowCnt
    INTO #fn2Cst
    FROM ags.fnIpgChRsltCstUtl2_2606(@ipgCh, @stIpgKey, NULL)
    GROUP BY cstAgPnKey;

    SELECT @fn2Distinct = COUNT(*), @fn2Rows = ISNULL(SUM(rowCnt), 0) FROM #fn2Cst;

    SET @msg = N'  fn2 DISTINCT cstAgPn=' + CAST(@fn2Distinct AS nvarchar(10))
        + N' rows=' + CAST(@fn2Rows AS nvarchar(10));
    RAISERROR(@msg, 0, 1) WITH NOWAIT;

    SELECT @extraCnt = COUNT(*)
    FROM (
        SELECT cstAgPnKey FROM #fn2Cst
        EXCEPT
        SELECT cstAgPnKey FROM #tvfCst
    ) extra_q;

    SET @msg = N'  fn2 EXCEPT TVF (extra contracts): ' + CAST(@extraCnt AS nvarchar(10)) + N' (expected 0)';
    RAISERROR(@msg, 0, 1) WITH NOWAIT;

    IF @extraCnt <> 0
    BEGIN
        SET @fail = @fail + 1;
        RAISERROR(N'  FAIL: fn2 contains contracts outside universe', 0, 1) WITH NOWAIT;
    END

    SELECT @missingCnt = COUNT(*)
    FROM (
        SELECT cstAgPnKey FROM #tvfCst
        EXCEPT
        SELECT cstAgPnKey FROM #fn2Cst
    ) missing_q;

    SET @msg = N'  TVF EXCEPT fn2 (missing from fn2): ' + CAST(@missingCnt AS nvarchar(10));
    IF @requireMissingZero = 1
        SET @msg = @msg + N' (expected 0)';
    RAISERROR(@msg, 0, 1) WITH NOWAIT;

    IF @requireMissingZero = 1 AND @missingCnt <> 0
    BEGIN
        SET @fail = @fail + 1;
        RAISERROR(N'  FAIL: TVF contract absent in fn2', 0, 1) WITH NOWAIT;
    END

    IF @label IN (N'42', N'61')
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM #tvfCst WHERE cstAgPnKey = 2102)
        BEGIN
            SET @fail = @fail + 1;
            RAISERROR(N'  FAIL: TVF must contain cstAgPnKey=2102', 0, 1) WITH NOWAIT;
        END
        ELSE IF @fn2Distinct = 1 AND EXISTS (SELECT 1 FROM #fn2Cst WHERE cstAgPnKey = 2102)
            RAISERROR(N'  OK: golden cstAgPnKey=2102', 0, 1) WITH NOWAIT;
        ELSE
        BEGIN
            SET @fail = @fail + 1;
            RAISERROR(N'  FAIL: fn2 must be single contract 2102', 0, 1) WITH NOWAIT;
        END
    END

    IF @label = N'45' AND @fn2Rows > 0
    BEGIN
        SET @fail = @fail + 1;
        RAISERROR(N'  FAIL: fn2 must be empty for stIpg=45', 0, 1) WITH NOWAIT;
    END

    SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
    SET @msg = N'  elapsed ms=' + CAST(@ms AS nvarchar(20));
    RAISERROR(@msg, 0, 1) WITH NOWAIT;

    DROP TABLE #tvfCst;
    DROP TABLE #fn2Cst;

    FETCH NEXT FROM case_cur INTO @ord, @stIpgKey, @expectedCnt, @label, @requireMissingZero;
END

CLOSE case_cur;
DEALLOCATE case_cur;

IF @fail = 0
    RAISERROR(N'=== 07q: PASS ===', 0, 1) WITH NOWAIT;
ELSE
BEGIN
    SET @msg = N'=== 07q: FAIL (' + CAST(@fail AS nvarchar(10)) + N' check(s)) ===';
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END
GO
