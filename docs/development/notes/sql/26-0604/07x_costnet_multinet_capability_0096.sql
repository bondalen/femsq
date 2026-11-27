USE [FishEye_prod_noM6];
GO
-- =============================================================================
-- 07x_costnet_multinet_capability_0096.sql
-- §3 плана C4b / 0096: multi-net capability T1–T6 + cleanup
-- Носитель: iuplp=7226, mn=4 (нет прямой 212; части 148+187 = 0.225+0.225)
-- Боевая «Стандартная»(3): 148 под 187 → overlap → 225000
-- Temp: 212→148 и 212→187 siblings → 450000
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @iuplp     int = 7226;
DECLARE @mn        int = 4;
DECLARE @ipgCh     int = 507;
DECLARE @stIpgProbe int = 1;   -- корень разделов для T5
DECLARE @fail      bit = 0;
DECLARE @msg       nvarchar(400);

DECLARE @cntBefore int = (SELECT COUNT(*) FROM ags.stNet WHERE stnType = 2);
DECLARE @stNetIpg  int = (SELECT ipgcStNetIpg FROM ags.ipgCh WHERE ipgcKey = @ipgCh);
DECLARE @combat    int = (
    SELECT TOP (1) n.stnKey FROM ags.stNet n
    WHERE n.stnType = 2
    ORDER BY CASE WHEN n.stnName = N'Стандартная' THEN 0 ELSE 1 END, n.stnKey
);

DECLARE @leafCombat money;
DECLARE @leafTemp   money;
DECLARE @defaultNet int;
DECLARE @tempNet    int = NULL;
DECLARE @rel148     int = NULL;
DECLARE @rel187     int = NULL;  -- reuse existing 212→187 if present
DECLARE @downIpgBefore int;
DECLARE @downIpgAfter  int;
DECLARE @contractsBefore int;
DECLARE @contractsAfter  int;

SET @msg = N'=== 07x multi-net 0096  type2_before=' + CAST(@cntBefore AS nvarchar)
         + N'  combat=' + ISNULL(CAST(@combat AS nvarchar), N'?')
         + N'  ipgNet=' + ISNULL(CAST(@stNetIpg AS nvarchar), N'?')
         + N' ===';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @combat IS NULL OR @stNetIpg IS NULL OR @cntBefore < 1
BEGIN
    RAISERROR(N'FAIL: preconditions (combat cost-net / IPG-net)', 16, 1);
    RETURN;
END

BEGIN TRY
    -- baseline IPG DAG + contract universe (без тяжёлого StIpg rollup)
    SELECT @downIpgBefore = COUNT(*) FROM ags.fnStDownAll(@stNetIpg, @stIpgProbe);
    SELECT @contractsBefore = COUNT(*)
    FROM ags.fnIpgChContractsForStIpg_2606(@ipgCh, @stIpgProbe);

    SELECT @leafCombat = ags.fnStCostUtPlPMn(@iuplp, 212, @combat, @mn);
    SET @msg = N'baseline leaf combat=' + CAST(ISNULL(@leafCombat, 0) AS nvarchar)
             + N'  downIpg=' + CAST(@downIpgBefore AS nvarchar)
             + N'  contracts=' + CAST(@contractsBefore AS nvarchar);
    RAISERROR(@msg, 0, 1) WITH NOWAIT;

    -- -----------------------------------------------------------------
    -- T1: создать temp cost-net (stnType=2), топология ≠ Стандартной
    -- -----------------------------------------------------------------
    RAISERROR(N'--- T1 create temp net ---', 0, 1) WITH NOWAIT;

    INSERT INTO ags.stNet (stnType, stnName, stnRoot)
    VALUES (2, N'0096-temp-costnet', 212);
    SET @tempNet = SCOPE_IDENTITY();

    -- reuse 212→187 if exists; else create
    SELECT @rel187 = r.strKey
    FROM ags.stRel r
    WHERE r.strParent = 212 AND r.strChild = 187;

    IF @rel187 IS NULL
    BEGIN
        INSERT INTO ags.stRel (strParent, strChild) VALUES (212, 187);
        SET @rel187 = SCOPE_IDENTITY();
    END

    -- always new 212→148 for sibling topology (may not exist in combat)
    IF EXISTS (SELECT 1 FROM ags.stRel WHERE strParent = 212 AND strChild = 148)
        SELECT @rel148 = strKey FROM ags.stRel WHERE strParent = 212 AND strChild = 148;
    ELSE
    BEGIN
        INSERT INTO ags.stRel (strParent, strChild) VALUES (212, 148);
        SET @rel148 = SCOPE_IDENTITY();
    END

    -- корень 212 висит на 214→212 (strKey=127 в боевой); без этого fnSt не стартует
    DECLARE @relRoot int = (
        SELECT TOP (1) r.strKey
        FROM ags.stRel r
        WHERE r.strParent = 214 AND r.strChild = 212
    );
    IF @relRoot IS NULL
    BEGIN
        INSERT INTO ags.stRel (strParent, strChild) VALUES (214, 212);
        SET @relRoot = SCOPE_IDENTITY();
    END

    INSERT INTO ags.stNetPn (stnpStRel, stpnStNet, stpnNum) VALUES (@relRoot, @tempNet, 0);
    INSERT INTO ags.stNetPn (stnpStRel, stpnStNet, stpnNum) VALUES (@rel187, @tempNet, 1);
    INSERT INTO ags.stNetPn (stnpStRel, stpnStNet, stpnNum) VALUES (@rel148, @tempNet, 2);

    -- sanity: temp children of 212
    DECLARE @tempKids int = (SELECT COUNT(*) FROM ags.fnStDownAll(@tempNet, 212));
    SET @msg = N'T1 tempNet=' + CAST(@tempNet AS nvarchar)
             + N'  kids212=' + CAST(@tempKids AS nvarchar)
             + N'  rel187=' + CAST(@rel187 AS nvarchar)
             + N'  rel148=' + CAST(@rel148 AS nvarchar);
    RAISERROR(@msg, 0, 1) WITH NOWAIT;

    IF @tempKids < 2
    BEGIN
        RAISERROR(N'FAIL T1: temp net must expose both 148 and 187 under 212', 16, 1);
        SET @fail = 1;
    END
    ELSE
        RAISERROR(N'PASS T1', 0, 1) WITH NOWAIT;

    -- -----------------------------------------------------------------
    -- T2: носитель без прямой 212 (класс 7226)
    -- -----------------------------------------------------------------
    RAISERROR(N'--- T2 carrier ---', 0, 1) WITH NOWAIT;
    IF EXISTS (
        SELECT 1 FROM ags.ipgUtPlPnLmMn
        WHERE iuplpmPlPn = @iuplp AND iuplpmStCost = 212 AND iuplpmMn = @mn
    )
    BEGIN
        RAISERROR(N'FAIL T2: прямая 212 маскирует тест', 16, 1);
        SET @fail = 1;
    END
    ELSE IF NOT EXISTS (
        SELECT 1 FROM ags.ipgUtPlPnLmMn
        WHERE iuplpmPlPn = @iuplp AND iuplpmMn = @mn AND iuplpmStCost IN (148, 187)
        HAVING COUNT(DISTINCT iuplpmStCost) = 2
    )
    BEGIN
        RAISERROR(N'FAIL T2: нужны части 148 и 187', 16, 1);
        SET @fail = 1;
    END
    ELSE
        RAISERROR(N'PASS T2', 0, 1) WITH NOWAIT;

    -- -----------------------------------------------------------------
    -- T3: @stCostNet=combat → боевая сумма
    -- -----------------------------------------------------------------
    RAISERROR(N'--- T3 combat rollup ---', 0, 1) WITH NOWAIT;
    SELECT @leafCombat = ags.fnStCostUtPlPMn(@iuplp, 212, @combat, @mn);
    IF ISNULL(@leafCombat, 0) <> 225000.00
    BEGIN
        SET @msg = N'FAIL T3: expected 225000, got ' + CAST(ISNULL(@leafCombat, 0) AS nvarchar);
        RAISERROR(@msg, 16, 1);
        SET @fail = 1;
    END
    ELSE
        RAISERROR(N'PASS T3', 0, 1) WITH NOWAIT;

    -- -----------------------------------------------------------------
    -- T4: @stCostNet=temp → иная сумма (siblings без overlap)
    -- -----------------------------------------------------------------
    RAISERROR(N'--- T4 temp rollup ---', 0, 1) WITH NOWAIT;
    SELECT @leafTemp = ags.fnStCostUtPlPMn(@iuplp, 212, @tempNet, @mn);
    SET @msg = N'T4 leafTemp=' + CAST(ISNULL(@leafTemp, 0) AS nvarchar);
    RAISERROR(@msg, 0, 1) WITH NOWAIT;

    IF ISNULL(@leafTemp, 0) <> 450000.00
    BEGIN
        SET @msg = N'FAIL T4: expected 450000 (148+187), got ' + CAST(ISNULL(@leafTemp, 0) AS nvarchar);
        RAISERROR(@msg, 16, 1);
        SET @fail = 1;
    END
    ELSE IF ISNULL(@leafTemp, 0) = ISNULL(@leafCombat, 0)
    BEGIN
        RAISERROR(N'FAIL T4: temp сумма не отличается от боевой', 16, 1);
        SET @fail = 1;
    END
    ELSE
        RAISERROR(N'PASS T4', 0, 1) WITH NOWAIT;

    -- default lookup всё ещё «Стандартная», пока есть 2 сети type=2
    SELECT TOP (1) @defaultNet = n.stnKey
    FROM ags.stNet n
    WHERE n.stnType = 2
    ORDER BY CASE WHEN n.stnName = N'Стандартная' THEN 0 ELSE 1 END, n.stnKey;

    IF @defaultNet <> @combat
    BEGIN
        RAISERROR(N'FAIL T4b: default cost-net должен оставаться «Стандартная»', 16, 1);
        SET @fail = 1;
    END
    ELSE
        RAISERROR(N'PASS T4b default=Стандартная', 0, 1) WITH NOWAIT;

    -- -----------------------------------------------------------------
    -- T5: смена cost-net не ломает отбор строек (IPG-net)
    -- -----------------------------------------------------------------
    RAISERROR(N'--- T5 IPG selection stable ---', 0, 1) WITH NOWAIT;
    SELECT @downIpgAfter = COUNT(*) FROM ags.fnStDownAll(@stNetIpg, @stIpgProbe);
    SELECT @contractsAfter = COUNT(*)
    FROM ags.fnIpgChContractsForStIpg_2606(@ipgCh, @stIpgProbe);

    SET @msg = N'T5 downIpg ' + CAST(@downIpgBefore AS nvarchar) + N'→' + CAST(@downIpgAfter AS nvarchar)
             + N'  contracts ' + CAST(@contractsBefore AS nvarchar) + N'→' + CAST(@contractsAfter AS nvarchar);
    RAISERROR(@msg, 0, 1) WITH NOWAIT;

    IF @downIpgBefore <> @downIpgAfter OR @contractsBefore <> @contractsAfter
    BEGIN
        RAISERROR(N'FAIL T5: IPG DAG / отбор строек изменился при появлении temp cost-net', 16, 1);
        SET @fail = 1;
    END
    ELSE
        RAISERROR(N'PASS T5', 0, 1) WITH NOWAIT;

END TRY
BEGIN CATCH
    SET @fail = 1;
    SET @msg = N'ERROR: ' + ERROR_MESSAGE();
    RAISERROR(@msg, 16, 1);
END CATCH

-- -----------------------------------------------------------------
-- T6: cleanup (всегда)
-- -----------------------------------------------------------------
RAISERROR(N'--- T6 cleanup ---', 0, 1) WITH NOWAIT;

BEGIN TRY
    IF @tempNet IS NOT NULL
    BEGIN
        DELETE FROM ags.stNetPn WHERE stpnStNet = @tempNet;

        -- удаляем только наше ребро 212→148, если оно не входит в другие сети
        IF @rel148 IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM ags.stNetPn WHERE stnpStRel = @rel148)
            DELETE FROM ags.stRel WHERE strKey = @rel148;

        -- 212→187 могло быть чужим (боевым) — не трогаем, если ещё есть ссылки
        -- (если создали мы и ссылок нет — удалим)
        IF @rel187 IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM ags.stNetPn WHERE stnpStRel = @rel187)
            DELETE FROM ags.stRel WHERE strKey = @rel187;

        DELETE FROM ags.stNet WHERE stnKey = @tempNet;
    END
END TRY
BEGIN CATCH
    SET @fail = 1;
    SET @msg = N'FAIL T6 cleanup ERROR: ' + ERROR_MESSAGE();
    RAISERROR(@msg, 16, 1);
END CATCH

DECLARE @cntAfter int = (SELECT COUNT(*) FROM ags.stNet WHERE stnType = 2);
DECLARE @orphanTemp int = (
    SELECT COUNT(*) FROM ags.stNet WHERE stnName = N'0096-temp-costnet'
);

SET @msg = N'T6 type2 ' + CAST(@cntBefore AS nvarchar) + N'→' + CAST(@cntAfter AS nvarchar)
         + N'  orphanName=' + CAST(@orphanTemp AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @cntAfter <> @cntBefore OR @orphanTemp <> 0
BEGIN
    RAISERROR(N'FAIL T6: COUNT stnType=2 / orphan temp name', 16, 1);
    SET @fail = 1;
END
ELSE
    RAISERROR(N'PASS T6', 0, 1) WITH NOWAIT;

-- post: leaf combat still works
SELECT @leafCombat = ags.fnStCostUtPlPMn(@iuplp, 212, @combat, @mn);
IF ISNULL(@leafCombat, 0) <> 225000.00
BEGIN
    RAISERROR(N'FAIL post: combat leaf after cleanup', 16, 1);
    SET @fail = 1;
END

IF @fail = 1
BEGIN
    RAISERROR(N'=== 07x FAIL ===', 16, 1);
    RETURN;
END

RAISERROR(N'=== 07x PASS ===', 0, 1) WITH NOWAIT;
GO
