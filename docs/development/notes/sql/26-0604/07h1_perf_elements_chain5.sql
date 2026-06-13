USE [FishEye];
GO
-- Поэлементные замеры fn2_2606 (цепь 5).
-- Правило: каждый шаг — отдельный запуск; лимит ~60 сек на шаг.
-- Прогресс: RAISERROR ... WITH NOWAIT (не буферизуется).
--
-- Запуск одного шага:
--   sed -n '/^-- STEP A/,/^GO/p' 07h1_perf_elements_chain5.sql | sqlcmd ...
-- Или задать @step в начале батча.
SET NOCOUNT ON;
GO

DECLARE @ipgCh int = 5;
DECLARE @step  char(1) = 'A';   -- <<< A|B|C|D|V

DECLARE @t0 datetime2;
DECLARE @msg nvarchar(400);
DECLARE @n int;

IF @step = 'V'
BEGIN
    RAISERROR(N'=== 07h1-V: versions in DB ===', 0, 1) WITH NOWAIT;
    SELECT
        LEN(OBJECT_DEFINITION(OBJECT_ID('ags.fnMasteringCstAgPnSh_2606'))) AS sh_def_len,
        CASE WHEN OBJECT_DEFINITION(OBJECT_ID('ags.fnMasteringCstAgPnSh_2606')) LIKE '%fnMasteringCstAgPn_2606%' THEN 1 ELSE 0 END AS sh_calls_pn2606,
        LEN(OBJECT_DEFINITION(OBJECT_ID('ags.fnMasteringCstAgPn_2606'))) AS pn_def_len,
        CASE WHEN OBJECT_DEFINITION(OBJECT_ID('ags.fnMasteringCstAgPn_2606')) LIKE '%fnMasteringPresRa_2606%' THEN 1 ELSE 0 END AS pn_pres2606,
        CASE WHEN OBJECT_DEFINITION(OBJECT_ID('ags.fnMasteringCstAgPn_2606')) LIKE '%RetRa_2606%' THEN 1 ELSE 0 END AS pn_ret2606,
        CASE WHEN OBJECT_DEFINITION(OBJECT_ID('ags.fnIpgChRsltCstUtl2_2606')) LIKE '%ipgPnSchemePts%' THEN 1 ELSE 0 END AS fn2_scheme_pts;
    -- Этап 8.3: PresRa в fnMasteringCstAgPn_2606; Sh вызывает CstAgPn_2606 (sh_pres в Sh не ожидается)
    RAISERROR(N'=== 07h1-V: done ===', 0, 1) WITH NOWAIT;
    RETURN;
END

IF @step = 'A'
BEGIN
    RAISERROR(N'=== 07h1-A: fn_2408 full chain START ===', 0, 1) WITH NOWAIT;
    SET @t0 = SYSDATETIME();
    SELECT @n = COUNT(*) FROM ags.fnIpgChRsltCstUtl_2408(@ipgCh) f WHERE f.ipgKey IS NOT NULL;
    SET @msg = N'07h1-A DONE rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(DATEDIFF(ms,@t0,SYSDATETIME()) AS nvarchar);
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
    RETURN;
END

IF @step = 'B'
BEGIN
    RAISERROR(N'=== 07h1-B: fnMasteringStIpgStCost_2606 stIpg=46 START ===', 0, 1) WITH NOWAIT;
    SET @t0 = SYSDATETIME();
    SELECT @n = COUNT(*) FROM ags.fnMasteringStIpgStCost_2606(46, @ipgCh, NULL, NULL);
    SET @msg = N'07h1-B DONE rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(DATEDIFF(ms,@t0,SYSDATETIME()) AS nvarchar);
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
    RETURN;
END

IF @step = 'C'
BEGIN
    RAISERROR(N'=== 07h1-C: fn2_2606 stIpg=61 START ===', 0, 1) WITH NOWAIT;
    SET @t0 = SYSDATETIME();
    SELECT @n = COUNT(*) FROM ags.fnIpgChRsltCstUtl2_2606(@ipgCh, 61, NULL) f WHERE f.ipgKey IS NOT NULL;
    SET @msg = N'07h1-C DONE rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(DATEDIFF(ms,@t0,SYSDATETIME()) AS nvarchar);
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
    RETURN;
END

IF @step = 'D'
BEGIN
    DECLARE @ntc int;
    SELECT @ntc = COUNT(DISTINCT pp.ipgpCstAgPn)
    FROM ags.ipgPn pp
    JOIN ags.ipg ip ON ip.ipgKey = pp.ipgpIpg
    JOIN ags.ipgChRl cr ON cr.ipgcrIpg = ip.ipgKey AND cr.ipgcrChain = @ipgCh
    WHERE EXISTS (SELECT 1 FROM ags.ipgStPn sp WHERE sp.ipgspSt = 46 AND sp.ipgspPn = pp.ipgpKey);
    SET @msg = N'07h1-D contracts stIpg=46: ' + CAST(@ntc AS nvarchar);
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
    RAISERROR(N'=== 07h1-D: fn2_2606 stIpg=46 START (лимит 60 сек снаружи) ===', 0, 1) WITH NOWAIT;
    SET @t0 = SYSDATETIME();
    SELECT @n = COUNT(*) FROM ags.fnIpgChRsltCstUtl2_2606(@ipgCh, 46, NULL) f WHERE f.ipgKey IS NOT NULL;
    SET @msg = N'07h1-D DONE rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(DATEDIFF(ms,@t0,SYSDATETIME()) AS nvarchar);
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
    RETURN;
END

RAISERROR(N'07h1: unknown @step — use V, A, B, C, D', 16, 1) WITH NOWAIT;
GO
