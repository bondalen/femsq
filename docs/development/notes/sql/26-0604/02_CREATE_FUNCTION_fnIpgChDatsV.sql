USE [FishEye];
GO

-- =============================================================================
-- Файл:    02_CREATE_FUNCTION_fnIpgChDatsV.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Генератор дат расчёта освоения для цепи ИПГ (_2606).
--   Источник переходов: ags.ipgChRlV (ipgcrvStr / ipgcrvEnd), не ipg.ipgStr/ipgEnd.
--   Прототип: ags.fnIpgChDats (legacy, не изменяется).
-- Предусловия: 01 (ipgChRlV заполнена).
-- Автор:   Александр
-- Дата:    2026-06-09
-- =============================================================================

PRINT '=== 02: CREATE FUNCTION ags.fnIpgChDatsV ===';
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION ags.fnIpgChDatsV
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

IF NOT EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'ags.fnIpgChDatsV') AND minor_id = 0 AND name = N'MS_Description'
)
    EXEC sys.sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'Даты расчёта освоения для цепи ИПГ (_2606). Переходы из ipgChRlV; 01.01 года + концы мес. + ipgcrvStr/ipgcrvEnd.',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnIpgChDatsV';
ELSE
    EXEC sys.sp_updateextendedproperty
        @name = N'MS_Description',
        @value = N'Даты расчёта освоения для цепи ИПГ (_2606). Переходы из ipgChRlV; 01.01 года + концы мес. + ipgcrvStr/ipgcrvEnd.',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnIpgChDatsV';
GO

-- -----------------------------------------------------------------------------
-- Проверка 2.1: цепь 5 — 17 дат
-- -----------------------------------------------------------------------------
PRINT '--- fnIpgChDatsV(5) ---';
SELECT d.dAll FROM ags.fnIpgChDatsV(5) d ORDER BY d.dAll;

DECLARE @cnt5 int = (SELECT COUNT(*) FROM ags.fnIpgChDatsV(5));
PRINT N'COUNT(5) = ' + CAST(@cnt5 AS nvarchar(10))
    + CASE WHEN @cnt5 = 17 THEN N' — OK' ELSE N' — ОШИБКА (ожидалось 17)' END;
GO

-- -----------------------------------------------------------------------------
-- Проверка 2.2: цепь 15 — точка разрыва 2025-07-15 / 2025-07-16
-- -----------------------------------------------------------------------------
PRINT '--- fnIpgChDatsV(15) vs fnIpgChDats(15) ---';

SELECT N'V' AS src, d.dAll FROM ags.fnIpgChDatsV(15) d
UNION ALL
SELECT N'legacy', d.dAll FROM ags.fnIpgChDats(15) d
ORDER BY dAll, src;

DECLARE @cnt15v int = (SELECT COUNT(*) FROM ags.fnIpgChDatsV(15));
DECLARE @cnt15l int = (SELECT COUNT(*) FROM ags.fnIpgChDats(15));
DECLARE @has715 bit = CASE WHEN EXISTS (
    SELECT 1 FROM ags.fnIpgChDatsV(15) d WHERE d.dAll = '2025-07-15'
) THEN 1 ELSE 0 END;
DECLARE @has716 bit = CASE WHEN EXISTS (
    SELECT 1 FROM ags.fnIpgChDatsV(15) d WHERE d.dAll = '2025-07-16'
) THEN 1 ELSE 0 END;

PRINT N'COUNT V(15)=' + CAST(@cnt15v AS nvarchar(10))
    + N', legacy(15)=' + CAST(@cnt15l AS nvarchar(10));
PRINT N'2025-07-15 в V: ' + CASE @has715 WHEN 1 THEN N'да' ELSE N'нет' END
    + N'; 2025-07-16 в V: ' + CASE @has716 WHEN 1 THEN N'да' ELSE N'нет' END;

-- Расхождения: только даты, отсутствующие в legacy (исправление разрыва)
SELECT N'только в V' AS diff, v.dAll
FROM ags.fnIpgChDatsV(15) v
WHERE NOT EXISTS (SELECT 1 FROM ags.fnIpgChDats(15) l WHERE l.dAll = v.dAll)
UNION ALL
SELECT N'только legacy', l.dAll
FROM ags.fnIpgChDats(15) l
WHERE NOT EXISTS (SELECT 1 FROM ags.fnIpgChDatsV(15) v WHERE v.dAll = l.dAll)
ORDER BY dAll, diff;
GO

PRINT '=== 02: завершено ===';
GO
