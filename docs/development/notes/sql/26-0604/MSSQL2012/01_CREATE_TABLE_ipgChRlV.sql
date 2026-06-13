USE [FishEye];
GO

-- =============================================================================
-- Файл:    MSSQL2012/01_CREATE_TABLE_ipgChRlV.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: ags.ipgChRlV — таблица сроков актуальности ИПГ в цепи (Дефект Б).
--   ipgcrvEnd — вычисляемый столбец через ags.fnIpgChRlVEnd.
--   Совместимость: SQL Server 2012 SP4 (11.0.7507.2). Без CREATE OR ALTER,
--   без DROP IF EXISTS, без WITHIN GROUP.
-- Автор:   Александр
-- Дата:    2026-06-04
-- =============================================================================

PRINT '=== 01 MSSQL2012: ipgChRlV + fnIpgChRlVEnd ===';

IF OBJECT_ID(N'ags.vIpgChRlV', N'V') IS NOT NULL
BEGIN
    PRINT 'DROP устаревшего ags.vIpgChRlV...';
    DROP VIEW ags.vIpgChRlV;
END
GO

IF OBJECT_ID(N'ags.ipgChRlV', N'U') IS NOT NULL
    DROP TABLE ags.ipgChRlV;
GO

IF OBJECT_ID(N'ags.fnIpgChRlVEnd', N'FN') IS NOT NULL
    DROP FUNCTION ags.fnIpgChRlVEnd;
GO

-- -----------------------------------------------------------------------------
-- Шаг 1: таблица
-- -----------------------------------------------------------------------------
CREATE TABLE ags.ipgChRlV
(
    ipgcrvKey     int           NOT NULL IDENTITY(1, 1),
    ipgcrvChain   int           NOT NULL,
    ipgcrvIpg     int           NOT NULL,
    ipgcrvStr     date          NOT NULL,
    ipgcrvUtPlGr  int           NULL,
    CONSTRAINT PK_ipgChRlV      PRIMARY KEY CLUSTERED (ipgcrvKey),
    CONSTRAINT UQ_ipgChRlV_chain_ipg UNIQUE (ipgcrvChain, ipgcrvIpg),
    CONSTRAINT UQ_ipgChRlV_chain_str UNIQUE (ipgcrvChain, ipgcrvStr),
    CONSTRAINT FK_ipgChRlV_ipgCh FOREIGN KEY (ipgcrvChain)
        REFERENCES ags.ipgCh (ipgcKey),
    CONSTRAINT FK_ipgChRlV_ipg  FOREIGN KEY (ipgcrvIpg)
        REFERENCES ags.ipg (ipgKey),
    CONSTRAINT FK_ipgChRlV_ipgUtPlGr FOREIGN KEY (ipgcrvUtPlGr)
        REFERENCES ags.ipgUtPlGr (iuplgKey)
);
GO

-- -----------------------------------------------------------------------------
-- Шаг 2: скалярная функция для вычисляемого столбца ipgcrvEnd
-- -----------------------------------------------------------------------------
CREATE FUNCTION ags.fnIpgChRlVEnd(@chain int, @str date)
RETURNS date
AS
BEGIN
    RETURN DATEADD(day, -1, (
        SELECT MIN(t.ipgcrvStr)
        FROM ags.ipgChRlV t
        WHERE t.ipgcrvChain = @chain
          AND t.ipgcrvStr > @str
    ))
END
GO

-- -----------------------------------------------------------------------------
-- Шаг 3: вычисляемый столбец ipgcrvEnd
-- -----------------------------------------------------------------------------
ALTER TABLE ags.ipgChRlV
    ADD ipgcrvEnd AS (ags.fnIpgChRlVEnd(ipgcrvChain, ipgcrvStr));
GO

-- -----------------------------------------------------------------------------
-- Заполнение: все цепи, для которых уже есть записи в ipgChRl
-- (на продуктиве нужно раскомментировать / уточнить фильтр WHERE)
-- -----------------------------------------------------------------------------
INSERT INTO ags.ipgChRlV (ipgcrvChain, ipgcrvIpg, ipgcrvStr, ipgcrvUtPlGr)
SELECT
    r.ipgcrChain,
    r.ipgcrIpg,
    CAST(i.ipgStr AS date),
    r.ipgcrUtPlGr
FROM ags.ipgChRl r
INNER JOIN ags.ipg i ON i.ipgKey = r.ipgcrIpg
WHERE r.ipgcrChain IN (5, 15)       -- расширить для продуктива
  AND i.ipgStr IS NOT NULL;
GO

-- Верификация
SELECT
    v.ipgcrvChain,
    v.ipgcrvIpg,
    i.ipgNm,
    v.ipgcrvStr,
    v.ipgcrvEnd,
    v.ipgcrvUtPlGr
FROM ags.ipgChRlV v
JOIN ags.ipg i ON i.ipgKey = v.ipgcrvIpg
WHERE v.ipgcrvChain IN (5, 15)
ORDER BY v.ipgcrvChain, v.ipgcrvStr;
GO

PRINT '=== 01 MSSQL2012: завершено ===';
GO
