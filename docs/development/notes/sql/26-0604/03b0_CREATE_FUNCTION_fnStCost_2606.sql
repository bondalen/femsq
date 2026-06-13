USE [FishEye];
GO

-- =============================================================================
-- Файл:    03b0_CREATE_FUNCTION_fnStCost_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: fnStCostRa/RaCh/AgFee/Ralp/PrDoc/Mnrl_2606 — DAG как legacy,
--   источник сумм factDocCost (политика B+F, docs/03-design-decisions.md §10).
-- Предусловия: 01b–01d (factDoc, factDocCost, *_fdKey, бэкфилл).
-- Автор:   Александр
-- Дата:    2026-06-09
-- =============================================================================

PRINT '=== 03b0: CREATE fnStCost*_2606 ===';
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- -----------------------------------------------------------------------------
-- fnStCostFromFd_2606 — сумма по stCost для factDoc (прямой MAX + rollup fnStDownAll)
-- Используется fnStCostRa/RaCh и set-based fnMastering*Ra (этап 9б).
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnStCostFromFd_2606
(
    @fdKey     int,
    @StCostKey int,
    @stNet     int
)
RETURNS money
AS
BEGIN
    DECLARE @Result       money;
    DECLARE @tblPn        TABLE (strChild int, fdcoKey int, fdcoFd int, fdcoSumm money);
    DECLARE @tblChCost    TABLE (strChild int);
    DECLARE @tblChCostNot TABLE (strChild int);

    SELECT @Result = 0;

    IF @fdKey IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM ags.factDocCost c WHERE c.fdcoFd = @fdKey)
            RETURN 0;

        SET @Result =
        (
            SELECT MAX(c.fdcoSumm)
            FROM ags.factDocCost c
            WHERE c.fdcoFd = @fdKey
              AND c.fdcoStCost = @StCostKey
        );

        IF @Result IS NULL
        BEGIN
            INSERT INTO @tblPn (strChild, fdcoKey, fdcoFd, fdcoSumm)
            SELECT z.strChild, l.fdcoKey, l.fdcoFd, l.fdcoSumm
            FROM
            (
                SELECT * FROM ags.fnStDownAll(@stNet, @StCostKey)
            ) AS z
            INNER JOIN ags.factDocCost l ON z.strChild = l.fdcoStCost
            WHERE l.fdcoFd = @fdKey;

            INSERT INTO @tblChCost (strChild)
            SELECT strChild FROM @tblPn;

            INSERT INTO @tblChCostNot (strChild)
            SELECT y.strChild
            FROM
            (
                SELECT *
                FROM @tblPn AS x
                OUTER APPLY ags.fnStUpAll(@stNet, x.strChild) f
            ) AS y
            LEFT JOIN @tblChCost t ON y.strParent = t.strChild
            WHERE t.strChild IS NOT NULL
            GROUP BY y.strChild;

            SELECT @Result =
            (
                SELECT SUM(p.fdcoSumm)
                FROM @tblPn p
                LEFT JOIN @tblChCostNot n ON p.strChild = n.strChild
                WHERE n.strChild IS NULL
            );

            SELECT @Result = ISNULL(@Result, 0);
        END
    END

    RETURN @Result;
END;
GO

-- -----------------------------------------------------------------------------
-- fnStCostRa_2606 — сумма по stCost для отчёта агента (через factDocCost)
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnStCostRa_2606
(
    @StCostCarrierKey int,
    @StCostKey        int,
    @stNet            int
)
RETURNS money
AS
BEGIN
    DECLARE @Result     money;
    DECLARE @ras_keyMax int;
    DECLARE @fdKey      int;

    SELECT @Result = 0;

    SET @ras_keyMax =
    (
        SELECT MAX(m.ras_key)
        FROM
        (
            SELECT MAX(s.ras_date) AS dm
            FROM ags.ra_summ s
            WHERE s.ras_ra = @StCostCarrierKey
        ) AS z
        INNER JOIN ags.ra_summ m ON z.dm = m.ras_date AND m.ras_ra = @StCostCarrierKey
    );

    IF @ras_keyMax IS NOT NULL
    BEGIN
        SELECT @fdKey = s.ras_fdKey
        FROM ags.ra_summ s
        WHERE s.ras_key = @ras_keyMax;

        SET @Result = ags.fnStCostFromFd_2606(@fdKey, @StCostKey, @stNet);
    END

    RETURN @Result;
END;
GO

-- -----------------------------------------------------------------------------
-- fnStCostRaCh_2606 — сумма по stCost для изменения отчёта агента
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnStCostRaCh_2606
(
    @StCostCarrierKey int,
    @StCostKey        int,
    @stNet            int
)
RETURNS money
AS
BEGIN
    DECLARE @Result      money;
    DECLARE @racs_keyMax int;
    DECLARE @fdKey       int;

    SELECT @Result = 0;

    SET @racs_keyMax =
    (
        SELECT MAX(m.raсs_key)
        FROM
        (
            SELECT MAX(s.raсs_date) AS dm
            FROM ags.ra_change_summ s
            WHERE s.raсs_raс = @StCostCarrierKey
        ) AS z
        INNER JOIN ags.ra_change_summ m ON z.dm = m.raсs_date AND m.raсs_raс = @StCostCarrierKey
    );

    IF @racs_keyMax IS NOT NULL
    BEGIN
        SELECT @fdKey = s.racs_fdKey
        FROM ags.ra_change_summ s
        WHERE s.raсs_key = @racs_keyMax;

        SET @Result = ags.fnStCostFromFd_2606(@fdKey, @StCostKey, @stNet);
    END

    RETURN @Result;
END;
GO

-- -----------------------------------------------------------------------------
-- fnStCostAgFee_2606 — агентское вознаграждение (восходящий DAG)
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnStCostAgFee_2606
(
    @StCostCarrierKey int,
    @StCostKey        int,
    @stNet            int
)
RETURNS money
AS
BEGIN
    DECLARE @Result          money;
    DECLARE @SimpleSum       money;
    DECLARE @stCostOgAgFee   int;

    SELECT @Result = 0;
    SET @stCostOgAgFee = 148;

    SET @SimpleSum =
    (
        SELECT MAX(c.fdcoSumm)
        FROM ags.ogAgFeeP p
        INNER JOIN ags.factDocCost c ON c.fdcoFd = p.oafp_fdKey AND c.fdcoStCost = @stCostOgAgFee
        WHERE p.oafpKey = @StCostCarrierKey
    );

    IF @SimpleSum IS NOT NULL AND @SimpleSum <> 0
    BEGIN
        SET @Result =
        (
            SELECT MAX(z.stSum)
            FROM
            (
                SELECT f.strParent AS stCost, @SimpleSum AS stSum
                FROM ags.fnStUpAll(@stNet, @stCostOgAgFee) f
                UNION
                SELECT @stCostOgAgFee, @SimpleSum
            ) AS z
            WHERE z.stCost = @StCostKey
        );
    END

    RETURN ISNULL(@Result, 0);
END;
GO

-- -----------------------------------------------------------------------------
-- fnStCostRalp_2606 — аренда земельных участков (восходящий DAG)
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnStCostRalp_2606
(
    @StCostCarrierKey int,
    @StCostKey        int,
    @stNet            int
)
RETURNS money
AS
BEGIN
    DECLARE @Result       money;
    DECLARE @SimpleSum    money;
    DECLARE @stCostRalp   int;

    SELECT @Result = 0;
    SET @stCostRalp = 150;

    SET @SimpleSum =
    (
        SELECT MAX(c.fdcoSumm)
        FROM ags.ralpRaAu p
        INNER JOIN ags.factDocCost c ON c.fdcoFd = p.ralpra_fdKey AND c.fdcoStCost = @stCostRalp
        WHERE p.ralpraKey = @StCostCarrierKey
    );

    IF @SimpleSum IS NOT NULL AND @SimpleSum <> 0
    BEGIN
        SET @Result =
        (
            SELECT MAX(z.stSum)
            FROM
            (
                SELECT f.strParent AS stCost, @SimpleSum AS stSum
                FROM ags.fnStUpAll(@stNet, @stCostRalp) f
                UNION
                SELECT @stCostRalp, @SimpleSum
            ) AS z
            WHERE z.stCost = @StCostKey
        );
    END

    RETURN ISNULL(@Result, 0);
END;
GO

-- -----------------------------------------------------------------------------
-- fnStCostPrDoc_2606 — хранение / стройконтроль (восходящий DAG)
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnStCostPrDoc_2606
(
    @StCostCarrierKey int,
    @StCostKey        int,
    @stNet            int
)
RETURNS money
AS
BEGIN
    DECLARE @Result      money;
    DECLARE @SimpleSum   money;
    DECLARE @stCostPrD   int;

    SELECT @Result = 0, @stCostPrD = 0;

    SELECT
        @SimpleSum = MAX(c.fdcoSumm),
        @stCostPrD = MAX(c.fdcoStCost)
    FROM ags.cn_PrDocP p
    INNER JOIN ags.factDocCost c ON c.fdcoFd = p.pdp_fdKey
    WHERE p.pdpKey = @StCostCarrierKey
      AND c.fdcoStCost IN (205, 197);

    IF @stCostPrD <> 0 AND @SimpleSum IS NOT NULL AND @SimpleSum <> 0
    BEGIN
        SET @Result =
        (
            SELECT MAX(z.stSum)
            FROM
            (
                SELECT f.strParent AS stCost, @SimpleSum AS stSum
                FROM ags.fnStUpAll(@stNet, @stCostPrD) f
                UNION
                SELECT @stCostPrD, @SimpleSum
            ) AS z
            WHERE z.stCost = @StCostKey
        );
    END

    RETURN ISNULL(@Result, 0);
END;
GO

-- -----------------------------------------------------------------------------
-- fnStCostMnrl_2606 — ОПИ / материалы (восходящий DAG)
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnStCostMnrl_2606
(
    @StCostCarrierKey int,
    @StCostKey        int,
    @stNet            int
)
RETURNS money
AS
BEGIN
    DECLARE @Result       money;
    DECLARE @SimpleSum    money;
    DECLARE @stCostMnr    int;

    SELECT @Result = 0;
    SET @stCostMnr = 169;

    SET @SimpleSum =
    (
        SELECT MAX(c.fdcoSumm)
        FROM ags.cstAgPnMnrl m
        INNER JOIN ags.factDocCost c ON c.fdcoFd = m.am_fdKey AND c.fdcoStCost = @stCostMnr
        WHERE m.amKey = @StCostCarrierKey
    );

    IF @SimpleSum IS NOT NULL AND @SimpleSum <> 0
    BEGIN
        SET @Result =
        (
            SELECT MAX(z.stSum)
            FROM
            (
                SELECT f.strParent AS stCost, @SimpleSum AS stSum
                FROM ags.fnStUpAll(@stNet, @stCostMnr) f
                UNION
                SELECT @stCostMnr, @SimpleSum
            ) AS z
            WHERE z.stCost = @StCostKey
        );
    END

    RETURN ISNULL(@Result, 0);
END;
GO

-- -----------------------------------------------------------------------------
-- MS_Description
-- -----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'ags.fnStCostRa_2606') AND minor_id = 0 AND name = N'MS_Description'
)
    EXEC sys.sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'Сумма по stCost для отчёта агента (_2606). DAG как fnStCostRa; источник — factDocCost по ras_fdKey.',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnStCostRa_2606';
ELSE
    EXEC sys.sp_updateextendedproperty
        @name = N'MS_Description',
        @value = N'Сумма по stCost для отчёта агента (_2606). DAG как fnStCostRa; источник — factDocCost по ras_fdKey.',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnStCostRa_2606';
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'ags.fnStCostRaCh_2606') AND minor_id = 0 AND name = N'MS_Description'
)
    EXEC sys.sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'Сумма по stCost для изменения отчёта агента (_2606). DAG как fnStCostRaCh; источник — factDocCost по racs_fdKey.',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnStCostRaCh_2606';
ELSE
    EXEC sys.sp_updateextendedproperty
        @name = N'MS_Description',
        @value = N'Сумма по stCost для изменения отчёта агента (_2606). DAG как fnStCostRaCh; источник — factDocCost по racs_fdKey.',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnStCostRaCh_2606';
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'ags.fnStCostAgFee_2606') AND minor_id = 0 AND name = N'MS_Description'
)
    EXEC sys.sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'Сумма агентского вознаграждения по stCost (_2606). DAG как fnStCostAgFee; источник — factDocCost по oafp_fdKey, stcKey=148.',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnStCostAgFee_2606';
ELSE
    EXEC sys.sp_updateextendedproperty
        @name = N'MS_Description',
        @value = N'Сумма агентского вознаграждения по stCost (_2606). DAG как fnStCostAgFee; источник — factDocCost по oafp_fdKey, stcKey=148.',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnStCostAgFee_2606';
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'ags.fnStCostRalp_2606') AND minor_id = 0 AND name = N'MS_Description'
)
    EXEC sys.sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'Сумма аренды земельных участков по stCost (_2606). DAG как fnStCostRalp; источник — factDocCost по ralpra_fdKey, stcKey=150.',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnStCostRalp_2606';
ELSE
    EXEC sys.sp_updateextendedproperty
        @name = N'MS_Description',
        @value = N'Сумма аренды земельных участков по stCost (_2606). DAG как fnStCostRalp; источник — factDocCost по ralpra_fdKey, stcKey=150.',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnStCostRalp_2606';
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'ags.fnStCostPrDoc_2606') AND minor_id = 0 AND name = N'MS_Description'
)
    EXEC sys.sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'Сумма хранения/стройконтроля по stCost (_2606). DAG как fnStCostPrDoc; источник — factDocCost по pdp_fdKey (stcKey 205/197).',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnStCostPrDoc_2606';
ELSE
    EXEC sys.sp_updateextendedproperty
        @name = N'MS_Description',
        @value = N'Сумма хранения/стройконтроля по stCost (_2606). DAG как fnStCostPrDoc; источник — factDocCost по pdp_fdKey (stcKey 205/197).',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnStCostPrDoc_2606';
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'ags.fnStCostMnrl_2606') AND minor_id = 0 AND name = N'MS_Description'
)
    EXEC sys.sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'Сумма ОПИ по stCost (_2606). DAG как fnStCostMnrl; источник — factDocCost по am_fdKey, stcKey=169.',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnStCostMnrl_2606';
ELSE
    EXEC sys.sp_updateextendedproperty
        @name = N'MS_Description',
        @value = N'Сумма ОПИ по stCost (_2606). DAG как fnStCostMnrl; источник — factDocCost по am_fdKey, stcKey=169.',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnStCostMnrl_2606';
GO

PRINT '=== 03b0: fnStCost*_2606 созданы ===';
GO
