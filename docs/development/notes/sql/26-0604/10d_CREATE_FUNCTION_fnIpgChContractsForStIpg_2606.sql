USE [FishEye];
GO

-- =============================================================================
-- Файл:    10d_CREATE_FUNCTION_fnIpgChContractsForStIpg_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Универсум строек отчёта при @ipgStKey — IN_GROUP ∪ OUT_GROUP (Решение 16).
--   IN_GROUP: ipgStPn в поддереве @ipgStKey (как fnMasteringStIpgStCost_2606).
--   OUT_GROUP: chainActive \ IN_GROUP, тип ∈ stIpgOutLimPn (fnCstAgPnTypeChar).
--   chainActive: те же 7 источников, что CTE ipgChContracts в fn2_2606 (активность цепи).
--   @ipgStKey = NULL → все chainActive (вся цепь).
-- Предусловия: 10a–10c.
-- Следующий: 19.3 — фильтр ipgChContracts в fn2_2606.
-- Автор:   Александр
-- Дата:    2026-06-29
-- =============================================================================

PRINT N'=== 10d: CREATE FUNCTION ags.fnIpgChContractsForStIpg_2606 ===';
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION ags.fnIpgChContractsForStIpg_2606
(
    @ipgCh    int,
    @ipgStKey int
)
RETURNS TABLE
AS
RETURN
(
    WITH chainYear AS (
        SELECT MIN(y.yKey) AS yKey
        FROM (
            SELECT MAX(y2.yyyy) AS mxY
            FROM ags.ipgChRlV v
            INNER JOIN ags.ipg i ON i.ipgKey = v.ipgcrvIpg
            INNER JOIN ags.yyyy y2 ON y2.yKey = i.ipgYy
            WHERE v.ipgcrvChain = @ipgCh
        ) x
        INNER JOIN ags.yyyy y ON y.yyyy = x.mxY
    ),
    -- Источники = UNION в CTE ipgChContracts fn2_2606 (без CROSS JOIN mmmm × ra_typeGr).
    chainActive AS (
        SELECT DISTINCT src.cstAgPnKey
        FROM (
            SELECT p.oafpCstAgPn AS cstAgPnKey
            FROM ags.ogAgFee a
            CROSS JOIN chainYear cy
            INNER JOIN ags.ogAgFeeP p ON a.oafKey = p.oafpOaf
            WHERE a.oafY = cy.yKey
              AND p.oafpCstAgPn IS NOT NULL

            UNION

            SELECT DISTINCT r.ra_cac AS cstAgPnKey
            FROM ags.RRcTimeList r
            INNER JOIN ags.ra_period rp ON r.ra_period = rp.[key]
            CROSS JOIN chainYear cy
            WHERE rp.y = cy.yKey
              AND r.ra_cac IS NOT NULL

            UNION

            SELECT DISTINCT p.ralpCstAgPn AS cstAgPnKey
            FROM ags.ralp p
            INNER JOIN ags.yyyy y ON p.ralpY = y.yyyy
            CROSS JOIN chainYear cy
            WHERE y.yKey = cy.yKey
              AND p.ralpCstAgPn IS NOT NULL

            UNION

            SELECT DISTINCT p.pdpCstAgPn AS cstAgPnKey
            FROM ags.cn_PrDocP p
            INNER JOIN ags.cn_PrDoc d ON p.pdpPrDoc = d.cnpdKey
            INNER JOIN ags.cn_PrDocT t ON d.cnpdTpOrd = t.pdtoKey
            INNER JOIN ags.yyyy yh ON YEAR(p.positingDate) = yh.yyyy
            CROSS JOIN chainYear cy
            WHERE yh.yKey = cy.yKey
              AND p.pdpCstAgPn IS NOT NULL
              AND (
                  (d.cnpdTpOrd = 1 OR d.cnpdTpOrd = 2 OR d.cnpdTpOrd = 4)
                  OR t.pdtoCode IN (N'ZKTG', N'ZPTG', N'ZUGH', N'ZKTA')
              )

            UNION

            SELECT ip.ipgpCstAgPn AS cstAgPnKey
            FROM ags.ipgPn ip
            INNER JOIN ags.ipgChRlV v ON v.ipgcrvChain = @ipgCh AND v.ipgcrvIpg = ip.ipgpIpg
            WHERE ip.ipgpCstAgPn IS NOT NULL

            UNION

            SELECT DISTINCT mr.amCstAgPn AS cstAgPnKey
            FROM ags.cstAgPnMnrl mr
            INNER JOIN ags.yyyy ym ON YEAR(mr.amPositing) = ym.yyyy
            CROSS JOIN chainYear cy
            WHERE ym.yKey = cy.yKey
              AND mr.amCstAgPn IS NOT NULL
        ) src
        WHERE src.cstAgPnKey IS NOT NULL
    ),
    inGroup AS (
        SELECT x.ipgpCstAgPn AS cstAgPnKey
        FROM (
            SELECT p.ipgpCstAgPn, s.ipgspSt
            FROM ags.ipgChRlV v
            INNER JOIN ags.ipgPn p ON v.ipgcrvIpg = p.ipgpIpg
            INNER JOIN ags.ipgStPn s ON p.ipgpKey = s.ipgspPn
            WHERE v.ipgcrvChain = @ipgCh
            GROUP BY p.ipgpCstAgPn, s.ipgspSt
        ) x
        INNER JOIN (
            SELECT @ipgStKey AS strIpgPn
            UNION
            SELECT f.strChild
            FROM ags.ipgCh ch
            CROSS APPLY ags.fnStDownAll(ch.ipgcStNetIpg, @ipgStKey) f
            WHERE ch.ipgcKey = @ipgCh
        ) z ON z.strIpgPn = x.ipgspSt
        WHERE @ipgStKey IS NOT NULL
        GROUP BY x.ipgpCstAgPn
    ),
    outGroup AS (
        SELECT ca.cstAgPnKey
        FROM chainActive ca
        INNER JOIN ags.cstAgPn cap ON cap.cstapKey = ca.cstAgPnKey
        WHERE @ipgStKey IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM inGroup ig WHERE ig.cstAgPnKey = ca.cstAgPnKey)
          AND EXISTS (
              SELECT 1
              FROM ags.stIpgOutLimPn ol
              WHERE ol.siolpStIpg = @ipgStKey
                AND ol.siolpCstType = ags.fnCstAgPnTypeChar(cap.cstapIpgPnN)
          )
    )
    SELECT cstAgPnKey FROM chainActive WHERE @ipgStKey IS NULL
    UNION
    SELECT cstAgPnKey FROM inGroup
    UNION
    SELECT cstAgPnKey FROM outGroup
);
GO

PRINT N'Функция ags.fnIpgChContractsForStIpg_2606 создана.';
GO

-- -----------------------------------------------------------------------------
-- Smoke: цепь 5, ключевые stIpg (полная приёмка — 07q, этап 19.4)
-- -----------------------------------------------------------------------------
SET NOCOUNT ON;

DECLARE @ch int = 5;
DECLARE @nNull int, @n1 int, @n51 int, @n45 int, @n42 int, @n61 int;
DECLARE @has2102 int;

SELECT @nNull = COUNT(*) FROM ags.fnIpgChContractsForStIpg_2606(@ch, NULL);
SELECT @n1   = COUNT(*) FROM ags.fnIpgChContractsForStIpg_2606(@ch, 1);
SELECT @n51  = COUNT(*) FROM ags.fnIpgChContractsForStIpg_2606(@ch, 51);
SELECT @n45  = COUNT(*) FROM ags.fnIpgChContractsForStIpg_2606(@ch, 45);
SELECT @n42  = COUNT(*) FROM ags.fnIpgChContractsForStIpg_2606(@ch, 42);
SELECT @n61  = COUNT(*) FROM ags.fnIpgChContractsForStIpg_2606(@ch, 61);
SELECT @has2102 = COUNT(*) FROM ags.fnIpgChContractsForStIpg_2606(@ch, 42) WHERE cstAgPnKey = 2102;

PRINT N'  chainActive (NULL): ' + CAST(@nNull AS nvarchar(10));
PRINT N'  stIpg=1:   ' + CAST(@n1 AS nvarchar(10));
PRINT N'  stIpg=51:  ' + CAST(@n51 AS nvarchar(10));
PRINT N'  stIpg=45:  ' + CAST(@n45 AS nvarchar(10));
PRINT N'  stIpg=42:  ' + CAST(@n42 AS nvarchar(10)) + N' (expect 2102: ' + CAST(@has2102 AS nvarchar(2)) + N')';
PRINT N'  stIpg=61:  ' + CAST(@n61 AS nvarchar(10));

IF @has2102 <> 1
BEGIN
    RAISERROR(N'10d FAIL: stIpg=42 must include cstAgPn 2102.', 16, 1);
    RETURN;
END;

IF @n42 >= @nNull OR @n61 >= @nNull
BEGIN
    RAISERROR(N'10d FAIL: leaf stIpg (42/61) count must be < NULL chain (%d).', 16, 1, @nNull);
    RETURN;
END;

IF @n1 <= @n42 OR @n51 <= @n42
BEGIN
    RAISERROR(N'10d FAIL: nodes with OUT_GROUP (1,51) must be wider than leaf 42.', 16, 1);
    RETURN;
END;

PRINT N'10d smoke | PASS';
GO
