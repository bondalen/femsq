USE [FishEye];
GO
-- =============================================================================
-- 07h3_diag_contract_profile.sql
-- Профиль одной стройки: объёмы данных + замер компонентов fnMasteringCstAgPnSh.
-- Сравнение медленной (371) и быстрой (338) из stIpg=46.
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh  int = 5;
DECLARE @stIpg  int = 46;
DECLARE @stCost int = 212;
DECLARE @cacSlow int = 371;   -- 051-2002246, ~6897 ms
DECLARE @cacFast int = 338;   -- 051-2002380, ~626 ms
DECLARE @stNet int = (SELECT c.ipgcStNetIpg FROM ags.ipgCh c WHERE c.ipgcKey = @ipgCh);
DECLARE @d0 date = '2022-09-30';

DECLARE @cac int;
DECLARE @label nvarchar(20);
DECLARE @t0 datetime2;
DECLARE @ms int;
DECLARE @msg nvarchar(400);

DECLARE @cacList TABLE (ord int, cac int, lbl nvarchar(10));
INSERT INTO @cacList VALUES (1, @cacSlow, N'slow'), (2, @cacFast, N'fast');

RAISERROR(N'=== 07h3: contract profile stIpg=46 ===', 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- A. Объёмы данных (не зависят от времени)
-- -------------------------------------------------------------------------
RAISERROR(N'--- A. Data volumes ---', 0, 1) WITH NOWAIT;

SELECT v.lbl, v.cac, cap.cstapIpgPnN AS code,
    (SELECT COUNT(*) FROM ags.ra_summ s JOIN ags.ra r ON s.ras_ra = r.ra_key
     JOIN ags.factDocCost fc ON fc.fdcoFd = s.ras_fdKey WHERE r.ra_cac = v.cac) AS factDocCost_ras_cnt,
    (SELECT COUNT(*) FROM ags.RRcTimeList r WHERE r.ra_cac = v.cac) AS RRcTimeList_cnt,
    (SELECT COUNT(*) FROM ags.ogAgFeeP p
     INNER JOIN ags.ogAgFee a ON a.oafKey = p.oafpOaf
     WHERE p.oafpCstAgPn = v.cac) AS ogAgFeeP_cnt,
    (SELECT COUNT(*) FROM ags.ralp rl WHERE rl.ralpCstAgPn = v.cac) AS ralp_cnt,
    (SELECT COUNT(*) FROM ags.cstAgPnMnrl m WHERE m.amCstAgPn = v.cac) AS mnrl_cnt,
    (SELECT COUNT(*) FROM ags.cn_PrDocP p WHERE p.pdpCstAgPn = v.cac) AS prDocP_cnt,
    (SELECT COUNT(DISTINCT p.ipgpSh) FROM ags.ipgPn p
     INNER JOIN ags.ipgChRlV v2 ON v2.ipgcrvIpg = p.ipgpIpg AND v2.ipgcrvChain = @ipgCh
     WHERE p.ipgpCstAgPn = v.cac) AS ipgPn_schemes,
    (SELECT COUNT(*) FROM ags.ipgPn p
     INNER JOIN ags.ipgChRlV v2 ON v2.ipgcrvIpg = p.ipgpIpg AND v2.ipgcrvChain = @ipgCh
     WHERE p.ipgpCstAgPn = v.cac) AS ipgPn_rows
FROM (
    SELECT 1 AS ord, @cacSlow AS cac, N'slow' AS lbl
    UNION ALL SELECT 2, @cacFast, N'fast'
) v
INNER JOIN ags.cstAgPn cap ON cap.cstapKey = v.cac
ORDER BY v.ord;

-- -------------------------------------------------------------------------
-- B. fnStCostRsCstAgPn_2606 (лимиты) — на одну дату
-- -------------------------------------------------------------------------
RAISERROR(N'--- B. fnStCostRsCstAgPn_2606 per scheme ---', 0, 1) WITH NOWAIT;

DECLARE @sh int;
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT cac, lbl FROM @cacList ORDER BY ord;
OPEN cur;
FETCH NEXT FROM cur INTO @cac, @label;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sh = 2;
    DECLARE @rows int;
    SET @t0 = SYSDATETIME();
    SELECT @rows = COUNT(*) FROM ags.fnStCostRsCstAgPn_2606(@ipgCh, @cac, @sh, @stCost, @stNet, @stIpg);
    SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
    SET @msg = N'  ' + @label + N' cac=' + CAST(@cac AS nvarchar) + N' sh=2 lim rows=' + CAST(@rows AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
    FETCH NEXT FROM cur INTO @cac, @label;
END
CLOSE cur; DEALLOCATE cur;

-- -------------------------------------------------------------------------
-- C. Один scalar: fnMasteringPresRa_2606 на @d0
-- -------------------------------------------------------------------------
RAISERROR(N'--- C. Single fnMasteringPresRa_2606 ---', 0, 1) WITH NOWAIT;

DECLARE cur2 CURSOR LOCAL FAST_FORWARD FOR SELECT cac, lbl FROM @cacList ORDER BY ord;
OPEN cur2;
FETCH NEXT FROM cur2 INTO @cac, @label;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @t0 = SYSDATETIME();
    DECLARE @x money = ags.fnMasteringPresRa_2606(@d0, @cac, @stCost, @stNet, 0);
    SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
    SET @msg = N'  ' + @label + N' PresRa_2606=' + ISNULL(CAST(@x AS nvarchar), N'NULL') + N' ms=' + CAST(@ms AS nvarchar);
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
    FETCH NEXT FROM cur2 INTO @cac, @label;
END
CLOSE cur2; DEALLOCATE cur2;

-- -------------------------------------------------------------------------
-- D. fnMasteringCstAgPn_2606 (одна схема sh=2)
-- -------------------------------------------------------------------------
RAISERROR(N'--- D. fnMasteringCstAgPn_2606 sh=2 ---', 0, 1) WITH NOWAIT;

DECLARE cur3 CURSOR LOCAL FAST_FORWARD FOR SELECT cac, lbl FROM @cacList ORDER BY ord;
OPEN cur3;
FETCH NEXT FROM cur3 INTO @cac, @label;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @t0 = SYSDATETIME();
    SELECT @rows = COUNT(*) FROM ags.fnMasteringCstAgPn_2606(@ipgCh, @cac, 2, @stCost, @stNet, @stIpg);
    SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
    SET @msg = N'  ' + @label + N' CstAgPn sh=2 rows=' + CAST(@rows AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
    FETCH NEXT FROM cur3 INTO @cac, @label;
END
CLOSE cur3; DEALLOCATE cur3;

-- -------------------------------------------------------------------------
-- E. fnMasteringCstAgPnSh_2606 (итог 07h2)
-- -------------------------------------------------------------------------
RAISERROR(N'--- E. fnMasteringCstAgPnSh_2606 (full) ---', 0, 1) WITH NOWAIT;

DECLARE cur4 CURSOR LOCAL FAST_FORWARD FOR SELECT cac, lbl FROM @cacList ORDER BY ord;
OPEN cur4;
FETCH NEXT FROM cur4 INTO @cac, @label;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @t0 = SYSDATETIME();
    DECLARE @n int;
    SELECT @n = COUNT(*) FROM ags.fnMasteringCstAgPnSh_2606(@ipgCh, @cac, @stCost, @stNet, @stIpg);
    SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
    SET @msg = N'  ' + @label + N' CstAgPnSh rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
    FETCH NEXT FROM cur4 INTO @cac, @label;
END
CLOSE cur4; DEALLOCATE cur4;

-- -------------------------------------------------------------------------
-- F. Резервы: что ещё не применено (проверка в БД)
-- -------------------------------------------------------------------------
RAISERROR(N'--- F. Reserves status ---', 0, 1) WITH NOWAIT;
SELECT
    CASE WHEN OBJECT_DEFINITION(OBJECT_ID('ags.fnMasteringCstAgPn_2606')) LIKE '%fnMasteringPresRa_2606%' THEN 1 ELSE 0 END AS P1_in_CstAgPn,
    CASE WHEN OBJECT_DEFINITION(OBJECT_ID('ags.fnIpgChRsltCstUtl2_2606')) LIKE '%@schemeRows%' THEN 1 ELSE 0 END AS P2_MSTVF,
    CASE WHEN OBJECT_DEFINITION(OBJECT_ID('ags.fnIpgChRsltCstUtl2_2606')) LIKE '%@branchCache%' THEN 1 ELSE 0 END AS P3_branchCache,
    CASE WHEN EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ipgStPn_St_Pn') THEN 1 ELSE 0 END AS P4_idx_ipgStPn,
    CASE WHEN OBJECT_ID('ags.RRcTimeListBase', 'U') IS NOT NULL THEN 1 ELSE 0 END AS P5_RRcMat;

RAISERROR(N'=== 07h3 DONE ===', 0, 1) WITH NOWAIT;
GO
