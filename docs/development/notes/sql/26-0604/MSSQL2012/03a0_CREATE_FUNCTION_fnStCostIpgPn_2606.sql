USE [FishEye];
GO

-- =============================================================================
-- Файл:    MSSQL2012/03a0_CREATE_FUNCTION_fnStCostIpgPn_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Лимит по пункту ИПГ (_2606), синтаксис SQL Server 2012.
-- =============================================================================

PRINT '=== 03a0 (MSSQL2012): CREATE FUNCTION ags.fnStCostIpgPn_2606 ===';
GO

IF OBJECT_ID(N'ags.fnStCostIpgPn_2606', N'FN') IS NOT NULL
    DROP FUNCTION ags.fnStCostIpgPn_2606;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE FUNCTION ags.fnStCostIpgPn_2606
(
    @StCostCarrierKey int,
    @StCostKey        int,
    @stNet            int
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

    SELECT @ResultLim =
    (
        SELECT MAX(i.ipgplLim)
        FROM ags.ipgPnLim i
        WHERE i.ipgplPn = @StCostCarrierKey
          AND i.ipgplStCost = @StCostKey
    );

    IF @ResultLim IS NOT NULL
        SET @Result = CAST(@ResultLim * 1000000 AS money);

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

PRINT '=== 03a0 (MSSQL2012): fnStCostIpgPn_2606 создана ===';
GO
