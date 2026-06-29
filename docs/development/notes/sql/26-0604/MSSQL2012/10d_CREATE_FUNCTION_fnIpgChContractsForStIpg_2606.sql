USE [FishEye];
GO

-- =============================================================================
-- Файл:    MSSQL2012/10d_CREATE_FUNCTION_fnIpgChContractsForStIpg_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: IN_GROUP ∪ OUT_GROUP для фильтра fn2 (Решение 16, этап 19.2).
--   Совместимость: SQL Server 2012 SP4 (11.0.7507.2).
-- Автор:   Александр
-- Дата:    2026-06-29
-- =============================================================================

PRINT N'=== 10d MSSQL2012: CREATE FUNCTION ags.fnIpgChContractsForStIpg_2606 ===';
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'ags.fnIpgChContractsForStIpg_2606', N'IF') IS NOT NULL
    DROP FUNCTION ags.fnIpgChContractsForStIpg_2606;
GO

CREATE FUNCTION ags.fnIpgChContractsForStIpg_2606
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
