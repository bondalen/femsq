USE [FishEye];
GO

-- =============================================================================
-- Файл:    MSSQL2012/10a_CREATE_TABLE_stIpgOutLimPn.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: ags.stIpgOutLimPn — правила OUT_GROUP (Решение 16, этап 19.1).
--   Совместимость: SQL Server 2012 SP4 (11.0.7507.2).
-- Автор:   Александр
-- Дата:    2026-06-29
-- =============================================================================

PRINT N'=== 10a MSSQL2012: CREATE TABLE ags.stIpgOutLimPn ===';
GO

IF OBJECT_ID(N'ags.stIpgOutLimPn', N'U') IS NOT NULL
BEGIN
    PRINT N'DROP существующей ags.stIpgOutLimPn...';
    DROP TABLE ags.stIpgOutLimPn;
END;
GO

CREATE TABLE ags.stIpgOutLimPn
(
    siolpStIpg    int     NOT NULL,
    siolpCstType  char(1) NOT NULL,
    CONSTRAINT PK_stIpgOutLimPn PRIMARY KEY CLUSTERED (siolpStIpg, siolpCstType),
    CONSTRAINT FK_stIpgOutLimPn_stIpg FOREIGN KEY (siolpStIpg)
        REFERENCES ags.stIpg (stiKey),
    CONSTRAINT CK_stIpgOutLimPn_cstType CHECK (siolpCstType IN (N'1', N'2', N'3'))
);
GO

PRINT N'Таблица ags.stIpgOutLimPn создана.';
GO
