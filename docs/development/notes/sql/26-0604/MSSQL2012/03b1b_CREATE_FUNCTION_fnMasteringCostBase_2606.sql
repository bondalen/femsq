USE [FishEye];
GO

-- =============================================================================
-- Файл:    MSSQL2012/03b1b_CREATE_FUNCTION_fnMasteringCostBase_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Этап 14.2 — fnMasteringRalpCostBase_2606, fnMasteringPrDocMnrlCostBase_2606.
-- Применять после 03b1 на продуктиве (SQL Server 2012 SP4).
-- Автор:   Александр | Дата: 2026-06-15
-- =============================================================================

PRINT '=== 03b1b: CostBase Ralp/PrDocMnrl (_2606) ===';
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'ags.fnMasteringRalpCostBase_2606', N'TF') IS NOT NULL
    DROP FUNCTION ags.fnMasteringRalpCostBase_2606;
GO

CREATE FUNCTION ags.fnMasteringRalpCostBase_2606
(
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS @t TABLE
(
    dEnd     date  NOT NULL,
    stAccp   bit   NOT NULL,
    stRet    bit   NOT NULL,
    stInProc bit   NOT NULL,
    stNotArr bit   NOT NULL,
    CostSm   money NOT NULL
)
AS
BEGIN
    IF @cstAgPn IS NULL
        RETURN;

    DECLARE @stCostRalp int = 150;
    DECLARE @dagHit     bit = 0;

    IF @StCostKey = @stCostRalp
        SET @dagHit = 1;
    ELSE IF EXISTS (
        SELECT 1 FROM ags.fnStUpAll(@stNet, @stCostRalp) u WHERE u.strParent = @StCostKey
    )
        SET @dagHit = 1;

    DECLARE @docs TABLE
    (
        ralpraKey  int   NOT NULL,
        dEnd       date  NOT NULL,
        stAccp     bit   NOT NULL,
        stRet      bit   NOT NULL,
        stInProc   bit   NOT NULL,
        stNotArr   bit   NOT NULL,
        CostSm     money NOT NULL
    );

    INSERT INTO @docs
    (
        ralpraKey, dEnd, stAccp, stRet, stInProc, stNotArr, CostSm
    )
    SELECT
        r.ralpraKey,
        EOMONTH(DATEFROMPARTS(r.ralpY, r.ralpM, 1)),
        CASE WHEN r.ralpSent IS NOT NULL AND r.ralpSent <> N'' THEN 1 ELSE 0 END,
        CASE WHEN r.ralpReturned IS NOT NULL
                  AND (r.ralpSent IS NULL OR r.ralpSentDate < r.ralpReturnedDate) THEN 1 ELSE 0 END,
        CASE WHEN r.ralpReturned IS NULL AND r.ralpSent IS NULL AND r.ralpArrived IS NOT NULL THEN 1 ELSE 0 END,
        CASE WHEN r.ralpReturned IS NULL AND r.ralpSent IS NULL AND r.ralpArrived IS NULL THEN 1 ELSE 0 END,
        0
    FROM ags.ralp r
    WHERE r.ralpCstAgPn = @cstAgPn;

    IF @dagHit = 1
    BEGIN
        UPDATE d
        SET CostSm = ISNULL(s.simpleSum, 0)
        FROM @docs d
        INNER JOIN
        (
            SELECT r.ralpraKey, MAX(c.fdcoSumm) AS simpleSum
            FROM ags.ralp r
            INNER JOIN ags.ralpRaAu p ON p.ralpraKey = r.ralpraKey
            INNER JOIN ags.factDocCost c ON c.fdcoFd = p.ralpra_fdKey AND c.fdcoStCost = @stCostRalp
            WHERE r.ralpCstAgPn = @cstAgPn
            GROUP BY r.ralpraKey
        ) s ON s.ralpraKey = d.ralpraKey
        WHERE ISNULL(s.simpleSum, 0) <> 0;
    END

    INSERT INTO @t (dEnd, stAccp, stRet, stInProc, stNotArr, CostSm)
    SELECT dEnd, stAccp, stRet, stInProc, stNotArr, CostSm
    FROM @docs;

    RETURN;
END
GO

IF OBJECT_ID(N'ags.fnMasteringPrDocMnrlCostBase_2606', N'TF') IS NOT NULL
    DROP FUNCTION ags.fnMasteringPrDocMnrlCostBase_2606;
GO

CREATE FUNCTION ags.fnMasteringPrDocMnrlCostBase_2606
(
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS @t TABLE
(
    kind   char(1) NOT NULL,
    dEnd   date    NOT NULL,
    CostSm money   NOT NULL
)
AS
BEGIN
    IF @cstAgPn IS NULL
        RETURN;

    DECLARE @stCostMnr int = 169;
    DECLARE @hit205    bit = 0;
    DECLARE @hit197    bit = 0;
    DECLARE @hitMnr    bit = 0;

    IF @StCostKey = 205 SET @hit205 = 1;
    ELSE IF EXISTS (SELECT 1 FROM ags.fnStUpAll(@stNet, 205) u WHERE u.strParent = @StCostKey) SET @hit205 = 1;

    IF @StCostKey = 197 SET @hit197 = 1;
    ELSE IF EXISTS (SELECT 1 FROM ags.fnStUpAll(@stNet, 197) u WHERE u.strParent = @StCostKey) SET @hit197 = 1;

    IF @StCostKey = @stCostMnr SET @hitMnr = 1;
    ELSE IF EXISTS (SELECT 1 FROM ags.fnStUpAll(@stNet, @stCostMnr) u WHERE u.strParent = @StCostKey) SET @hitMnr = 1;

    DECLARE @prDoc TABLE
    (
        pdpKey     int   NOT NULL,
        dEnd       date  NOT NULL,
        isStor     bit   NOT NULL,
        isControl  bit   NOT NULL,
        CostSm     money NOT NULL
    );

    INSERT INTO @prDoc (pdpKey, dEnd, isStor, isControl, CostSm)
    SELECT
        p.pdpKey,
        EOMONTH(DATEFROMPARTS(YEAR(p.positingDate), MONTH(p.positingDate), 1)),
        CASE WHEN d.cnpdTpOrd IN (1, 2, 4) THEN 1 ELSE 0 END,
        CASE WHEN d.cnpdTpOrd = 3 AND i.ciasAccnt = 30 THEN 1 ELSE 0 END,
        0
    FROM ags.cn_PrDocP p
    INNER JOIN ags.cn_PrDoc d ON p.pdpPrDoc = d.cnpdKey
    LEFT JOIN ags.cnInvAccntSmpl i ON d.cnpdCnInvAccntSmpl = i.ciasKey
    WHERE p.pdpCstAgPn = @cstAgPn
      AND p.satstusOfOUKVtext = N'проведено';

    UPDATE pd
    SET CostSm =
        CASE
            WHEN fc.baseStCost = 205 AND @hit205 = 1 AND ISNULL(fc.simpleSum, 0) <> 0 THEN fc.simpleSum
            WHEN fc.baseStCost = 197 AND @hit197 = 1 AND ISNULL(fc.simpleSum, 0) <> 0 THEN fc.simpleSum
            ELSE 0
        END
    FROM @prDoc pd
    INNER JOIN
    (
        SELECT p.pdpKey, c.fdcoStCost AS baseStCost, MAX(c.fdcoSumm) AS simpleSum
        FROM ags.cn_PrDocP p
        INNER JOIN ags.factDocCost c ON c.fdcoFd = p.pdp_fdKey AND c.fdcoStCost IN (205, 197)
        WHERE p.pdpCstAgPn = @cstAgPn
        GROUP BY p.pdpKey, c.fdcoStCost
    ) fc ON fc.pdpKey = pd.pdpKey;

    INSERT INTO @t (kind, dEnd, CostSm)
    SELECT N'S', pd.dEnd, pd.CostSm
    FROM @prDoc pd
    WHERE pd.isStor = 1 AND pd.CostSm <> 0
    UNION ALL
    SELECT N'C', pd.dEnd, pd.CostSm
    FROM @prDoc pd
    WHERE pd.isControl = 1 AND pd.CostSm <> 0;

    IF @hitMnr = 1
    BEGIN
        INSERT INTO @t (kind, dEnd, CostSm)
        SELECT N'M', EOMONTH(DATEFROMPARTS(YEAR(m.amPositing), MONTH(m.amPositing), 1)), ISNULL(s.simpleSum, 0)
        FROM ags.cstAgPnMnrl m
        INNER JOIN
        (
            SELECT m2.amKey, MAX(c.fdcoSumm) AS simpleSum
            FROM ags.cstAgPnMnrl m2
            INNER JOIN ags.factDocCost c ON c.fdcoFd = m2.am_fdKey AND c.fdcoStCost = @stCostMnr
            WHERE m2.amCstAgPn = @cstAgPn
            GROUP BY m2.amKey
        ) s ON s.amKey = m.amKey
        WHERE m.amCstAgPn = @cstAgPn
          AND ISNULL(s.simpleSum, 0) <> 0;
    END

    RETURN;
END
GO

PRINT '=== 03b1b: завершено ===';
GO
