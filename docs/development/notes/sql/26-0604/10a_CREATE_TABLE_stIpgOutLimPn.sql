USE [FishEye];
GO

-- =============================================================================
-- Файл:    10a_CREATE_TABLE_stIpgOutLimPn.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Таблица правил OUT_GROUP — разрешённые типы внелимитных строек
--   для узла stIpg (Решение 16, этап 19.1).
--   siolpStIpg → stIpg.stiKey; siolpCstType — 5-я литера кода САК ('1','2','3').
--   Пустая таблица для узла = только IN_GROUP.
-- Предусловия: ags.stIpg.
-- Следующий: 10b (fnCstAgPnTypeChar), 10c (seed).
-- Автор:   Александр
-- Дата:    2026-06-29
-- =============================================================================

PRINT N'=== 10a: CREATE TABLE ags.stIpgOutLimPn ===';
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
