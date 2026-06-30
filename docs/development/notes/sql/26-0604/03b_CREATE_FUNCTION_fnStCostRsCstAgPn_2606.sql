USE [FishEye];
GO

-- =============================================================================
-- Файл:    03b_CREATE_FUNCTION_fnStCostRsCstAgPn_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: График освоения по строй-агент-коду для цепи ИПГ (_2606).
--   ipgChRl_2606 + fnStCostRsIpgPn_2606.
-- Предусловия: 01 (ipgChRl_2606), 03a (fnStCostRsIpgPn_2606).
-- Прототип: ags.fnStCostRsCstAgPn (legacy, не изменяется).
-- Автор:   Александр
-- Дата:    2026-06-09
-- =============================================================================

PRINT '=== 03b: CREATE FUNCTION ags.fnStCostRsCstAgPn_2606 ===';
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION ags.fnStCostRsCstAgPn_2606
(
    @ipgCh      int,
    @cstAgPn    int,
    @ipgSh      int,
    @stCostPn   int,
    @stCostNet  int,
    @ipgRoot    int
)
RETURNS @RsltTbl TABLE
(
    ipgcrKey     int,
    ipgcrChain   int,
    ipgcrIpg     int,
    ipgcrUtPlGr  int,
    ipgpKey      int,
    ipgpSh       int,
    iuplgKey     int,
    iuplgpPl     int,
    iuplpKey     int,
    iuplpIpgPn   int,
    iuplpPl      int,
    ipgpCstAgPn  int,
    mKey         int,
    smm          money,
    ipgStr       date,
    ipgEnd       date,
    dd           date,
    ipgSh        int,
    smmTtl       money,
    lim          money,
    pct          decimal(8, 6),
    iuplpSubAg   int
)
AS
BEGIN
    DECLARE @ipgRootTrue bit;

    IF
    (
        SELECT COUNT(*)
        FROM
        (
            SELECT z.ipgcrChain, z.ipgpCstAgPn, z.ipgpSh, f.strParent
            FROM
            (
                SELECT
                    v.ipgcrvChain AS ipgcrChain,
                    p.ipgpKey,
                    p.ipgpCstAgPn,
                    p.ipgpSh,
                    s.ipgspSt,
                    c.ipgcStNetIpg
                FROM ags.ipgChRl_2606 v
                INNER JOIN ags.ipgPn p ON v.ipgcrvIpg = p.ipgpIpg
                INNER JOIN ags.ipgStPn s ON p.ipgpKey = s.ipgspPn
                INNER JOIN ags.ipgCh c ON v.ipgcrvChain = c.ipgcKey
                WHERE v.ipgcrvChain = @ipgCh
                  AND p.ipgpCstAgPn = @cstAgPn
                  AND p.ipgpSh = @ipgSh
            ) AS z
            CROSS APPLY
            (
                SELECT * FROM ags.fnStUpAll(z.ipgcStNetIpg, z.ipgspSt) f
                UNION
                SELECT z.ipgspSt
            ) AS f
            GROUP BY z.ipgcrChain, z.ipgpCstAgPn, z.ipgpSh, f.strParent
            HAVING f.strParent = @ipgRoot
        ) AS y
    ) > 0
        SET @ipgRootTrue = 1;
    ELSE
        SET @ipgRootTrue = 0;

    IF @ipgRootTrue = 1
        INSERT INTO @RsltTbl
        (
            ipgcrKey, ipgcrChain, ipgcrIpg, ipgcrUtPlGr,
            ipgpKey, ipgpSh,
            iuplgKey, iuplgpPl, iuplpKey, iuplpIpgPn, iuplpPl, ipgpCstAgPn,
            mKey, smm, ipgStr, ipgEnd, dd, ipgSh, smmTtl, lim, pct,
            iuplpSubAg
        )
        SELECT
            v.ipgcrvKey,
            v.ipgcrvChain,
            v.ipgcrvIpg,
            v.ipgcrvUtPlGr,
            p.ipgpKey,
            p.ipgpSh,
            f.*
        FROM ags.ipgChRl_2606 v
        INNER JOIN ags.ipgPn p ON v.ipgcrvIpg = p.ipgpIpg
        CROSS APPLY ags.fnStCostRsIpgPn_2606(
            @ipgCh, p.ipgpKey, v.ipgcrvUtPlGr, @stCostPn, @stCostNet, @ipgSh
        ) f
        WHERE v.ipgcrvChain = @ipgCh
          AND p.ipgpCstAgPn = @cstAgPn
          AND p.ipgpSh = @ipgSh;
    ELSE
        INSERT INTO @RsltTbl
        (
            ipgcrKey, ipgcrChain, ipgcrIpg, ipgcrUtPlGr,
            ipgpKey, ipgpSh,
            iuplgKey, iuplgpPl, iuplpKey, iuplpIpgPn, iuplpPl, ipgpCstAgPn,
            mKey, smm, ipgStr, ipgEnd, dd, ipgSh, smmTtl, lim, pct,
            iuplpSubAg
        )
        SELECT
            v.ipgcrvKey,
            v.ipgcrvChain,
            v.ipgcrvIpg,
            v.ipgcrvUtPlGr,
            p.ipgpKey,
            p.ipgpSh,
            f.*
        FROM ags.ipgChRl_2606 v
        INNER JOIN ags.ipgPn p ON v.ipgcrvIpg = p.ipgpIpg
        CROSS APPLY ags.fnStCostRsIpgPn_2606(
            @ipgCh, p.ipgpKey, v.ipgcrvUtPlGr, @stCostPn, @stCostNet, @ipgSh
        ) f
        WHERE v.ipgcrvChain = 0
          AND p.ipgpCstAgPn = 0
          AND p.ipgpSh = 0;

    RETURN;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'ags.fnStCostRsCstAgPn_2606') AND minor_id = 0 AND name = N'MS_Description'
)
    EXEC sys.sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'График освоения по строй-агент-коду для цепи ИПГ (_2606). ipgChRl_2606 + fnStCostRsIpgPn_2606.',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnStCostRsCstAgPn_2606';
ELSE
    EXEC sys.sp_updateextendedproperty
        @name = N'MS_Description',
        @value = N'График освоения по строй-агент-коду для цепи ИПГ (_2606). ipgChRl_2606 + fnStCostRsIpgPn_2606.',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnStCostRsCstAgPn_2606';
GO

-- Проверка: цепь 5 — COUNT vs legacy (ipgChRl ≈ ipgChRl_2606 на dev)
PRINT '--- fnStCostRsCstAgPn vs _2606 (цепь 5, sample cstAgPn) ---';

DECLARE @cst int = (
    SELECT TOP 1 p.ipgpCstAgPn
    FROM ags.ipgChRl_2606 v
    INNER JOIN ags.ipgPn p ON p.ipgpIpg = v.ipgcrvIpg
    WHERE v.ipgcrvChain = 5 AND p.ipgpSh = 2
);

DECLARE @cntL int = (SELECT COUNT(*) FROM ags.fnStCostRsCstAgPn(5, @cst, 2, 212, 2, 21));
DECLARE @cntN int = (SELECT COUNT(*) FROM ags.fnStCostRsCstAgPn_2606(5, @cst, 2, 212, 2, 21));

PRINT N'cstAgPn=' + CAST(@cst AS nvarchar(20))
    + N' legacy COUNT=' + CAST(@cntL AS nvarchar(10))
    + N' _2606 COUNT=' + CAST(@cntN AS nvarchar(10))
    + CASE WHEN @cntL = @cntN THEN N' — OK' ELSE N' — РАСХОЖДЕНИЕ' END;
GO

PRINT '=== 03b: fnStCostRsCstAgPn_2606 создана ===';
GO
