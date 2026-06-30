USE [FishEye];
GO

-- =============================================================================
-- Файл:    03a_CREATE_FUNCTION_fnStCostRsIpgPn_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: График планируемого освоения по пункту ИПГ (_2606).
--   Фикс Деф.Б: actuality через ipgChRl_2606; расширенный fallback к ipgUtPlP.iuplpLim
--   (Решение 7, docs/03-design-decisions.md).
-- Предусловия: 01 (ipgChRl_2606 заполнена), 03a0 (fnStCostIpgPn_2606).
-- Прототип: ags.fnStCostRsIpgPn (legacy, не изменяется).
-- Автор:   Александр
-- Дата:    2026-06-09
-- =============================================================================

PRINT '=== 03a: CREATE FUNCTION ags.fnStCostRsIpgPn_2606 ===';
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- -----------------------------------------------------------------------------
-- fnStCostRsIpgPn_2606 — график освоения по пункту ИПГ с actuality из ipgChRl_2606
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnStCostRsIpgPn_2606
(
    @ipgCh     int, -- цепь ИПГ
    @ipgPn     int, -- пункт инвестпрограммы
    @ipgUtPlGr int, -- группа уточнённых планов
    @stCost    int, -- ключ пункта структуры затрат
    @stNet     int, -- структура пунктов затрат
    @ipgSh     int  -- схема реализации инвестпроектов
)
RETURNS @TblRslt TABLE
(
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
    DECLARE @Tbl TABLE
    (
        iuplgKey    int,
        iuplgpPl    int,
        iuplpKey    int,
        iuplpIpgPn  int,
        iuplpPl     int,
        ipgpCstAgPn int,
        mKey        int,
        smm         money,
        ipgStr      date,
        ipgEnd      date,
        dd          date,
        ipgSh       int,
        iuplpSubAg  int
    );

    DECLARE @lim    money;
    DECLARE @limIpg money;
    DECLARE @stCostIuplpLim int = 212; -- корень DAG для fallback к ipgUtPlP.iuplpLim

    -- 1. заполняем временную табличку
    INSERT INTO @Tbl
    (
        iuplgKey, iuplgpPl, iuplpKey, iuplpIpgPn, iuplpPl, ipgpCstAgPn,
        mKey, smm, ipgStr, ipgEnd, dd, ipgSh, iuplpSubAg
    )
    SELECT
        y.iuplgKey, y.iuplgpPl, y.iuplpKey, y.iuplpIpgPn, y.iuplpPl, y.ipgpCstAgPn,
        y.mKey, y.smm, y.iStart, y.iEnd,
        iif
        (
            (month(y.dd) + 1) < month(y.iStart),
            null,
            iif
            (
                (month(y.iStart) - month(y.dd)) = 1,
                y.iStart,
                iif
                (
                    month(y.dd) > month(y.iEnd),
                    null,
                    iif
                    (
                        month(y.dd) = month(y.iEnd),
                        y.iEnd,
                        y.dd
                    )
                )
            )
        ) AS ddd,
        y.ipgpSh,
        y.iuplpSubAg
    FROM
    (
        SELECT
            z.iuplgKey, z.iuplgpPl, z.iuplpKey, z.iuplpIpgPn, z.iuplpPl, z.ipgpCstAgPn,
            m.mKey,
            ags.fnStCostUtPlPMn(z.iuplpKey, @stCost, @stNet, m.mKey) AS smm,
            iif
            (
                year(z.ipgStr) < z.yyyy,
                datefromparts(z.yyyy, 1, 1),
                z.ipgStr
            ) AS iStart,
            iif
            (
                z.ipgEnd IS NOT NULL,
                z.ipgEnd,
                datefromparts(z.yyyy, 12, 31)
            ) AS iEnd,
            eomonth(datefromparts(z.yyyy, m.mKey, 1)) AS dd,
            z.ipgpSh,
            z.iuplpSubAg
        FROM
        (
            SELECT
                p.iuplgpGr AS iuplgKey,
                p.iuplgpPl,
                n.iuplpKey,
                n.iuplpIpgPn,
                n.iuplpPl,
                i.ipgpCstAgPn,
                v.ipgcrvStr AS ipgStr,
                v.ipgcrvEnd AS ipgEnd,
                y.yyyy,
                i.ipgpSh,
                n.iuplpSubAg
            FROM
                ags.ipgPn i
                INNER JOIN ags.ipg a ON i.ipgpIpg = a.ipgKey
                INNER JOIN ags.yyyy y ON a.ipgYy = y.yKey
                INNER JOIN ags.ipgChRl_2606 v
                    ON v.ipgcrvChain = @ipgCh
                   AND v.ipgcrvIpg = i.ipgpIpg
                LEFT JOIN ags.ipgUtPlP n ON i.ipgpKey = n.iuplpIpgPn
                LEFT JOIN ags.ipgUtPlGrP p ON n.iuplpPl = p.iuplgpPl
            WHERE
                (p.iuplgpGr = @ipgUtPlGr OR p.iuplgpGr IS NULL)
                AND i.ipgpKey = @ipgPn
                AND i.ipgpSh = @ipgSh
        ) AS z
        CROSS JOIN ags.mmmm m
    ) AS y;

    -- 2. получаем лимит
    SET @lim =
    (
        SELECT SUM(y.smmLim)
        FROM
        (
            SELECT ags.fnStCostUtPlP(z.iuplpKey, @stCost, @stNet) AS smmLim
            FROM
            (
                SELECT t.iuplpKey
                FROM @Tbl t
                GROUP BY t.iuplpKey
            ) AS z
        ) AS y
    );

    -- если лимит из *Уточнённого плана* получить не удалось, пробуем из *Пункта инвестпрограммы*
    IF @lim = 0 OR @lim IS NULL
        SET @limIpg = ags.fnStCostIpgPn_2606(@ipgPn, @stCost, @stNet);

    -- Решение 7: расширенный fallback к ipgUtPlP.iuplpLim (DAG fnStUpAll, корень 212)
    IF (@lim = 0 OR @lim IS NULL) AND (@limIpg = 0 OR @limIpg IS NULL)
        SET @limIpg =
        (
            SELECT SUM(y.smmLim)
            FROM
            (
                SELECT
                (
                    SELECT MAX(z.stSum)
                    FROM ags.ipgUtPlP p
                    CROSS APPLY
                    (
                        SELECT f.strParent AS stCost, p.iuplpLim * 1000000.0 AS stSum
                        FROM ags.fnStUpAll(@stNet, @stCostIuplpLim) f
                        UNION ALL
                        SELECT @stCostIuplpLim, p.iuplpLim * 1000000.0
                    ) AS z
                    WHERE p.iuplpKey = k.iuplpKey
                      AND z.stCost = @stCost
                ) AS smmLim
                FROM
                (
                    SELECT t.iuplpKey
                    FROM @Tbl t
                    WHERE t.iuplpKey IS NOT NULL
                    GROUP BY t.iuplpKey
                ) AS k
            ) AS y
        );

    -- 3. заполняем результирующую табличку
    IF @lim = 0 OR @lim IS NULL
        -- 3.A. лимит из *Уточнённого плана* отсутствует — используем @limIpg
        INSERT INTO @TblRslt
        (
            iuplgKey, iuplgpPl, iuplpKey, iuplpIpgPn, iuplpPl, ipgpCstAgPn,
            mKey, smm, ipgStr, ipgEnd, dd, ipgSh, smmTtl, lim, pct, iuplpSubAg
        )
        SELECT
            z.iuplgKey, z.iuplgpPl, z.iuplpKey, z.iuplpIpgPn, z.iuplpPl, z.ipgpCstAgPn,
            z.mKey, z.smm, z.ipgStr, z.ipgEnd, z.dd, z.ipgSh, z.smmTtl, z.lim,
            iif(z.lim IS NULL OR z.lim = 0, NULL, z.smmTtl / z.lim) AS pct,
            z.iuplpSubAg
        FROM
        (
            SELECT
                tb.*,
                (
                    SELECT SUM(t.smm)
                    FROM @Tbl t
                    WHERE t.mKey <= tb.mKey
                      AND t.ipgSh = tb.ipgSh
                      AND t.iuplpKey = tb.iuplpKey
                ) AS smmTtl,
                @limIpg AS lim
            FROM @Tbl tb
        ) AS z
        WHERE z.dd IS NOT NULL;
    ELSE
        -- 3.B. лимит из уточнённого плана имеется (с fallback к iuplpLim по строке)
        INSERT INTO @TblRslt
        (
            iuplgKey, iuplgpPl, iuplpKey, iuplpIpgPn, iuplpPl, ipgpCstAgPn,
            mKey, smm, ipgStr, ipgEnd, dd, ipgSh, smmTtl, lim, pct, iuplpSubAg
        )
        SELECT
            z.iuplgKey, z.iuplgpPl, z.iuplpKey, z.iuplpIpgPn, z.iuplpPl, z.ipgpCstAgPn,
            z.mKey, z.smm, z.ipgStr, z.ipgEnd, z.dd, z.ipgSh, z.smmTtl, z.lim,
            iif(z.lim IS NULL OR z.lim = 0, NULL, z.smmTtl / z.lim) AS pct,
            z.iuplpSubAg
        FROM
        (
            SELECT
                tb.*,
                (
                    SELECT SUM(t.smm)
                    FROM @Tbl t
                    WHERE t.mKey <= tb.mKey
                      AND t.ipgSh = tb.ipgSh
                      AND t.iuplpKey = tb.iuplpKey
                ) AS smmTtl,
                COALESCE
                (
                    NULLIF(ags.fnStCostUtPlP(tb.iuplpKey, @stCost, @stNet), 0),
                    (
                        SELECT MAX(z.stSum)
                        FROM ags.ipgUtPlP p
                        CROSS APPLY
                        (
                            SELECT f.strParent AS stCost, p.iuplpLim * 1000000.0 AS stSum
                            FROM ags.fnStUpAll(@stNet, @stCostIuplpLim) f
                            UNION ALL
                            SELECT @stCostIuplpLim, p.iuplpLim * 1000000.0
                        ) AS z
                        WHERE p.iuplpKey = tb.iuplpKey
                          AND z.stCost = @stCost
                    )
                ) AS lim
            FROM @Tbl tb
        ) AS z
        WHERE z.dd IS NOT NULL;

    RETURN;
END;
GO

-- -----------------------------------------------------------------------------
-- MS_Description
-- -----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'ags.fnStCostRsIpgPn_2606') AND minor_id = 0 AND name = N'MS_Description'
)
    EXEC sys.sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'График планируемого освоения по пункту ИПГ (_2606). Actuality через ipgChRl_2606; fallback к ipgUtPlP.iuplpLim (DAG fnStUpAll, корень 212).',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnStCostRsIpgPn_2606';
ELSE
    EXEC sys.sp_updateextendedproperty
        @name = N'MS_Description',
        @value = N'График планируемого освоения по пункту ИПГ (_2606). Actuality через ipgChRl_2606; fallback к ipgUtPlP.iuplpLim (DAG fnStUpAll, корень 212).',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnStCostRsIpgPn_2606';
GO

-- -----------------------------------------------------------------------------
-- Проверка 3a: цепь 5 — сравнение COUNT с legacy (ipgpKey=5403)
-- -----------------------------------------------------------------------------
PRINT '--- fnStCostRsIpgPn vs fnStCostRsIpgPn_2606 (цепь 5, ipgpKey=5403) ---';

DECLARE @cntLegacy int;
DECLARE @cnt2606   int;

SET @cntLegacy =
(
    SELECT COUNT(*)
    FROM ags.fnStCostRsIpgPn(5403, 6, 212, 2, 2)
);

SET @cnt2606 =
(
    SELECT COUNT(*)
    FROM ags.fnStCostRsIpgPn_2606(5, 5403, 6, 212, 2, 2)
);

PRINT N'legacy COUNT=' + CAST(@cntLegacy AS nvarchar(10))
    + N', _2606 COUNT=' + CAST(@cnt2606 AS nvarchar(10))
    + CASE WHEN @cntLegacy = @cnt2606 THEN N' — OK' ELSE N' — РАСХОЖДЕНИЕ' END;
GO

PRINT '=== 03a: fnStCostRsIpgPn_2606 создана ===';
GO
