USE [FishEye];
GO

-- =============================================================================
-- Файл:    MSSQL2012/02_CREATE_FUNCTION_fnIpgChDatsV.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: ags.fnIpgChDatsV — генератор дат расчёта (_2606).
--   Совместимость: SQL Server 2012 SP4 (11.0.7507.2). Без CREATE OR ALTER.
-- Автор:   Александр
-- Дата:    2026-06-09
-- =============================================================================

PRINT '=== 02 MSSQL2012: CREATE fnIpgChDatsV ===';
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'ags.fnIpgChDatsV', N'IF') IS NOT NULL
    DROP FUNCTION ags.fnIpgChDatsV;
GO

CREATE FUNCTION ags.fnIpgChDatsV
(
    @ipgCh int
)
RETURNS TABLE
AS
RETURN
(
    WITH chainYear AS
    (
        SELECT MIN(yy.yyyy) AS intYear
        FROM ags.ipgChRlV v
        INNER JOIN ags.ipg i ON i.ipgKey = v.ipgcrvIpg
        INNER JOIN ags.yyyy yy ON yy.yKey = i.ipgYy
        WHERE v.ipgcrvChain = @ipgCh
    )
    SELECT DISTINCT x.dAll
    FROM
    (
        SELECT DATEFROMPARTS(cy.intYear, 1, 1) AS dAll
        FROM chainYear cy

        UNION ALL

        SELECT v.ipgcrvStr
        FROM ags.ipgChRlV v
        CROSS JOIN chainYear cy
        WHERE v.ipgcrvChain = @ipgCh
          AND v.ipgcrvStr IS NOT NULL
          AND YEAR(v.ipgcrvStr) = cy.intYear

        UNION ALL

        SELECT v.ipgcrvEnd
        FROM ags.ipgChRlV v
        CROSS JOIN chainYear cy
        WHERE v.ipgcrvChain = @ipgCh
          AND v.ipgcrvEnd IS NOT NULL
          AND YEAR(v.ipgcrvEnd) = cy.intYear

        UNION ALL

        SELECT EOMONTH(DATEFROMPARTS(cy.intYear, m.mNum, 1))
        FROM ags.mmmm m
        CROSS JOIN chainYear cy
    ) x
);
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Даты расчёта освоения для цепи ИПГ (_2606). Переходы из ipgChRlV; 01.01 года + концы мес. + ipgcrvStr/ipgcrvEnd.',
    @level0type = N'SCHEMA', @level0name = N'ags',
    @level1type = N'FUNCTION', @level1name = N'fnIpgChDatsV';
GO

PRINT '=== 02 MSSQL2012: fnIpgChDatsV создана ===';
GO
