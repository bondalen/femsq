USE [FishEye];
GO

-- =============================================================================
-- Файл:    MSSQL2012/03d_CREATE_FUNCTION_fnMasteringStIpgStCost_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Совместимость: SQL Server 2012 SP4. Без CREATE OR ALTER.
-- =============================================================================

PRINT '=== 03d MSSQL2012: CREATE fnMasteringStIpgStCost_2606 ===';
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'ags.fnMasteringStIpgStCost_2606', N'IF') IS NOT NULL
    DROP FUNCTION ags.fnMasteringStIpgStCost_2606;
GO

CREATE FUNCTION ags.fnMasteringStIpgStCost_2606
(
    @ipgStKey  int,
    @ipgCh     int,
    @stCostKey int,
    @stNet     int
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        y.ipgpCstAgPn,
        m.iuplpSubAg,
        m.dAll,
        SUM(m.agSmm) AS agSmm,
        SUM(m.agSmmTtl) AS agSmmTtl,
        SUM(m.agLim) AS agLim,
        CASE WHEN SUM(m.agLim) = 0 THEN NULL ELSE SUM(m.agSmmTtl) / SUM(m.agLim) END AS agPct,
        SUM(m.agMstrngPrsRa) AS agMstrngPrsRa,
        SUM(m.agMstrngAcpRa) AS agMstrngAcpRa,
        SUM(m.agMstrngPrsRaMn) AS agMstrngPrsRaMn,
        SUM(m.agMstrngAcpRaMn) AS agMstrngAcpRaMn,
        SUM(m.agMstrngPrsAgFee) AS agMstrngPrsAgFee,
        SUM(m.agMstrngAcpAgFee) AS agMstrngAcpAgFee,
        SUM(m.agMstrngPrsAgFeeMn) AS agMstrngPrsAgFeeMn,
        SUM(m.agMstrngAcpAgFeeMn) AS agMstrngAcpAgFeeMn,
        SUM(m.agMstrngPrsRalp) AS agMstrngPrsRalp,
        SUM(m.agMstrngAcpRalp) AS agMstrngAcpRalp,
        SUM(m.agMstrngPrsRalpMn) AS agMstrngPrsRalpMn,
        SUM(m.agMstrngAcpRalpMn) AS agMstrngAcpRalpMn,
        SUM(m.agMstrngAcpStor) AS agMstrngAcpStor,
        SUM(m.agMstrngAcpStorMn) AS agMstrngAcpStorMn,
        SUM(m.agMstrngAcpControl) AS agMstrngAcpControl,
        SUM(m.agMstrngAcpControlMn) AS agMstrngAcpControlMn,
        SUM(m.agMstrngAcpMnrl) AS agMstrngAcpMnrl,
        SUM(m.agMstrngAcpMnrlMn) AS agMstrngAcpMnrlMn,
        SUM(m.agMasteringPres) AS agMasteringPres,
        SUM(m.agMasteringAccp) AS agMasteringAccp,
        SUM(m.agMasteringPresMn) AS agMasteringPresMn,
        SUM(m.agMasteringAccpMn) AS agMasteringAccpMn,
        SUM(m.agPlanCompleted) AS agPlanCompleted,
        SUM(m.agPlanCompletedNot) AS agPlanCompletedNot,
        SUM(m.agPlanCompletedOver) AS agPlanCompletedOver,
        SUM(m.aglimNot) AS aglimNot,
        SUM(m.aglimOver) AS aglimOver,
        SUM(m.inSmm) AS inSmm,
        SUM(m.inSmmTtl) AS inSmmTtl,
        SUM(m.inLim) AS inLim,
        CASE WHEN SUM(m.inLim) = 0 THEN NULL ELSE SUM(m.inSmmTtl) / SUM(m.inLim) END AS inPct,
        SUM(m.inMstrngPrsRa) AS inMstrngPrsRa,
        SUM(m.inMstrngAcpRa) AS inMstrngAcpRa,
        SUM(m.inMstrngPrsRaMn) AS inMstrngPrsRaMn,
        SUM(m.inMstrngAcpRaMn) AS inMstrngAcpRaMn,
        SUM(m.inMstrngPrsAgFee) AS inMstrngPrsAgFee,
        SUM(m.inMstrngAcpAgFee) AS inMstrngAcpAgFee,
        SUM(m.inMstrngPrsAgFeeMn) AS inMstrngPrsAgFeeMn,
        SUM(m.inMstrngAcpAgFeeMn) AS inMstrngAcpAgFeeMn,
        SUM(m.inMstrngPrsRalp) AS inMstrngPrsRalp,
        SUM(m.inMstrngAcpRalp) AS inMstrngAcpRalp,
        SUM(m.inMstrngPrsRalpMn) AS inMstrngPrsRalpMn,
        SUM(m.inMstrngAcpRalpMn) AS inMstrngAcpRalpMn,
        SUM(m.inMstrngAcpStor) AS inMstrngAcpStor,
        SUM(m.inMstrngAcpStorMn) AS inMstrngAcpStorMn,
        SUM(m.inMstrngAcpControl) AS inMstrngAcpControl,
        SUM(m.inMstrngAcpControlMn) AS inMstrngAcpControlMn,
        SUM(m.inMstrngAcpMnrl) AS inMstrngAcpMnrl,
        SUM(m.inMstrngAcpMnrlMn) AS inMstrngAcpMnrlMn,
        SUM(m.inMasteringPres) AS inMasteringPres,
        SUM(m.inMasteringAccp) AS inMasteringAccp,
        SUM(m.inMasteringPresMn) AS inMasteringPresMn,
        SUM(m.inMasteringAccpMn) AS inMasteringAccpMn,
        SUM(m.inPlanCompleted) AS inPlanCompleted,
        SUM(m.inPlanCompletedNot) AS inPlanCompletedNot,
        SUM(m.inPlanCompletedOver) AS inPlanCompletedOver,
        SUM(m.inlimNot) AS inlimNot,
        SUM(m.inlimOver) AS inlimOver,
        SUM(m.drSmm) AS drSmm,
        SUM(m.drSmmTtl) AS drSmmTtl,
        SUM(m.drLim) AS drLim,
        CASE WHEN SUM(m.drLim) = 0 THEN NULL ELSE SUM(m.drSmmTtl) / SUM(m.drLim) END AS drPct,
        SUM(m.drMstrngPrsRa) AS drMstrngPrsRa,
        SUM(m.drMstrngAcpRa) AS drMstrngAcpRa,
        SUM(m.drMstrngPrsRaMn) AS drMstrngPrsRaMn,
        SUM(m.drMstrngAcpRaMn) AS drMstrngAcpRaMn,
        SUM(m.drMstrngPrsAgFee) AS drMstrngPrsAgFee,
        SUM(m.drMstrngAcpAgFee) AS drMstrngAcpAgFee,
        SUM(m.drMstrngPrsAgFeeMn) AS drMstrngPrsAgFeeMn,
        SUM(m.drMstrngAcpAgFeeMn) AS drMstrngAcpAgFeeMn,
        SUM(m.drMstrngPrsRalp) AS drMstrngPrsRalp,
        SUM(m.drMstrngAcpRalp) AS drMstrngAcpRalp,
        SUM(m.drMstrngPrsRalpMn) AS drMstrngPrsRalpMn,
        SUM(m.drMstrngAcpRalpMn) AS drMstrngAcpRalpMn,
        SUM(m.drMstrngAcpStor) AS drMstrngAcpStor,
        SUM(m.drMstrngAcpStorMn) AS drMstrngAcpStorMn,
        SUM(m.drMstrngAcpControl) AS drMstrngAcpControl,
        SUM(m.drMstrngAcpControlMn) AS drMstrngAcpControlMn,
        SUM(m.drMstrngAcpMnrl) AS drMstrngAcpMnrl,
        SUM(m.drMstrngAcpMnrlMn) AS drMstrngAcpMnrlMn,
        SUM(m.drMasteringPres) AS drMasteringPres,
        SUM(m.drMasteringAccp) AS drMasteringAccp,
        SUM(m.drMasteringPresMn) AS drMasteringPresMn,
        SUM(m.drMasteringAccpMn) AS drMasteringAccpMn,
        SUM(m.drPlanCompleted) AS drPlanCompleted,
        SUM(m.drPlanCompletedNot) AS drPlanCompletedNot,
        SUM(m.drPlanCompletedOver) AS drPlanCompletedOver,
        SUM(m.drlimNot) AS drlimNot,
        SUM(m.drlimOver) AS drlimOver
    FROM
        (
            SELECT x.ipgpCstAgPn
            FROM
                (
                    SELECT @ipgStKey AS strIpgPn
                    WHERE @ipgStKey IS NOT NULL
                    UNION
                    SELECT f.strChild
                    FROM ags.fnStDownAll(
                        ISNULL(@stNet, (SELECT c.ipgcStNetIpg FROM ags.ipgCh c WHERE c.ipgcKey = @ipgCh)),
                        @ipgStKey
                    ) f
                    WHERE @ipgStKey IS NOT NULL
                ) AS z
                RIGHT JOIN
                (
                    SELECT p.ipgpCstAgPn, s.ipgspSt
                    FROM ags.ipgChRl_2606 v
                    INNER JOIN ags.ipgPn p ON v.ipgcrvIpg = p.ipgpIpg
                    INNER JOIN ags.ipgStPn s ON p.ipgpKey = s.ipgspPn
                    WHERE v.ipgcrvChain = @ipgCh
                    GROUP BY p.ipgpCstAgPn, s.ipgspSt
                ) AS x ON @ipgStKey IS NULL OR z.strIpgPn = x.ipgspSt
            WHERE @ipgStKey IS NULL OR z.strIpgPn IS NOT NULL
            GROUP BY x.ipgpCstAgPn
        ) AS y
        CROSS APPLY ags.fnMasteringCstAgPnSh_2606(
            @ipgCh,
            y.ipgpCstAgPn,
            ISNULL(@stCostKey, 212),
            ISNULL(@stNet, (SELECT c.ipgcStNetIpg FROM ags.ipgCh c WHERE c.ipgcKey = @ipgCh)),
            ISNULL(@ipgStKey, 1)
        ) m
    GROUP BY
        y.ipgpCstAgPn,
        m.iuplpSubAg,
        m.dAll
);
GO

PRINT '=== 03d MSSQL2012: fnMasteringStIpgStCost_2606 создана ===';
GO
