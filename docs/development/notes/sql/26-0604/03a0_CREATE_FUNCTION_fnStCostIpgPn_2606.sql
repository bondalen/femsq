USE [FishEye];
GO

-- =============================================================================
-- Файл:    03a0_CREATE_FUNCTION_fnStCostIpgPn_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Лимит по пункту ИПГ и пункту структуры затрат (_2606).
--   Фикс точности: ipgplLim имеет тип decimal(23,8), единица — 1 млн руб.
--   Минимальная хранимая единица: 10^-8 млн = 0.01 руб = 1 коп.
--   Legacy fnStCostIpgPn присваивает ipgplLim в money ДО умножения:
--     money имеет 4 знака после запятой в рублях → при хранении 13075.09395
--     получается 13075.0940 (округление до 1/10000 руб = 0.01 коп),
--     затем × 1e6 → 13075094000 вместо 13075093950 (ошибка = 50 руб).
--   Здесь: умножение в decimal, cast в money — только на выходе
--   (аналогично cast(ipgpSmTtl * 1000000 as money) в fnIpgChRsltCstUtl_2408).
-- Прототип: ags.fnStCostIpgPn (legacy, не изменяется).
-- Автор:   Александр | Дата: 2026-06-09
-- =============================================================================

PRINT '=== 03a0: CREATE FUNCTION ags.fnStCostIpgPn_2606 ===';
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION ags.fnStCostIpgPn_2606
(
    @StCostCarrierKey int, -- пункт инвестиционной программы (ipgpKey)
    @StCostKey        int, -- пункт структуры затрат
    @stNet            int  -- структура пунктов затрат
)
RETURNS money
AS
BEGIN
    DECLARE @Result    money;
    DECLARE @ResultLim decimal(23, 8);

    DECLARE @tblPn TABLE
    (
        strChild int,
        ipgplKey int,
        ipgplPn  int,
        ipgplLim decimal(23, 8)
    );
    DECLARE @tblChCost    TABLE (strChild int);
    DECLARE @tblChCostNot TABLE (strChild int);

    SET @Result = 0;

    -- 1. прямое значение лимита из ipgPnLim (decimal, без промежуточного money)
    SELECT @ResultLim =
    (
        SELECT MAX(i.ipgplLim)
        FROM ags.ipgPnLim i
        WHERE i.ipgplPn = @StCostCarrierKey
          AND i.ipgplStCost = @StCostKey
    );

    IF @ResultLim IS NOT NULL
        SET @Result = CAST(@ResultLim * 1000000 AS money);

    -- 2. если прямого лимита нет — сумма по дереву нижестоящих stCost
    IF @Result = 0
    BEGIN
        INSERT INTO @tblPn (strChild, ipgplKey, ipgplPn, ipgplLim)
        SELECT z.strChild, l.ipgplKey, l.ipgplPn, l.ipgplLim
        FROM
        (
            SELECT *
            FROM ags.fnStDownAll(@stNet, @StCostKey)
        ) AS z
        INNER JOIN ags.ipgPnLim l ON z.strChild = l.ipgplStCost
        WHERE l.ipgplPn = @StCostCarrierKey;

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

        SELECT @ResultLim =
        (
            SELECT SUM(p.ipgplLim)
            FROM @tblPn p
            LEFT JOIN @tblChCostNot n ON p.strChild = n.strChild
            WHERE n.strChild IS NULL
        );

        SET @Result = CAST(ISNULL(@ResultLim, 0) * 1000000 AS money);
    END;

    RETURN @Result;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'ags.fnStCostIpgPn_2606') AND minor_id = 0 AND name = N'MS_Description'
)
    EXEC sys.sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'Лимит по пункту ИПГ (_2606). decimal(23,8) в единицах млн хранит лимиты с точностью до копейки. Умножение в decimal до cast в money; без потери точности legacy fnStCostIpgPn.',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnStCostIpgPn_2606';
GO

-- Проверка: ipgpKey=4947, stCost=212 — legacy округляет, _2606 совпадает с ipgpSmTtl
DECLARE @legacy money = ags.fnStCostIpgPn(4947, 212, 2);
DECLARE @fixed  money = ags.fnStCostIpgPn_2606(4947, 212, 2);
DECLARE @ref    money = CAST((SELECT ipgpSmTtl FROM ags.ipgPn WHERE ipgpKey = 4947) * 1000000 AS money);

PRINT N'fnStCostIpgPn legacy=' + CAST(@legacy AS nvarchar(30))
    + N', _2606=' + CAST(@fixed AS nvarchar(30))
    + N', ipgpSmTtl*1e6=' + CAST(@ref AS nvarchar(30))
    + CASE WHEN @fixed = @ref THEN N' — OK' ELSE N' — FAIL' END;
GO

PRINT '=== 03a0: fnStCostIpgPn_2606 создана ===';
GO
