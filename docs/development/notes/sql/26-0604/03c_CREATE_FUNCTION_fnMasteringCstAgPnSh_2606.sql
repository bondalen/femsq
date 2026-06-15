USE [FishEye];
GO

-- =============================================================================
-- Файл:    03c_CREATE_FUNCTION_fnMasteringCstAgPnSh_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Освоение по стройке с учётом схем реализации (_2606).
--   fnMasteringCstAgPn_2606: fnIpgChDatsV + fnStCostRsCstAgPn_2606 + ipgChRlV.
--   fnMasteringCstAgPnSh_2606: агрегация схем (прототип fnMasteringCstAgPnSh).
-- ИЗМЕНЕНИЯ (Этап 14.2, 2026-06-15):
--   - @ralpCostBase + @prDocMnrlCostBase вместо 17× OUTER APPLY bundle (P6-lite).
-- ИЗМЕНЕНИЯ (Этап 8.3, 2026-06-11):
--   - Все LEGACY-вызовы fnMasteringPresRa/AccpRa/... → fnMasteringPresRa_2606/...
--   - Добавлены 27 новых колонок Ret/InProc/NotArr/PresAll/PrevYears (Вариант 6А).
-- Предусловия: 02 (fnIpgChDatsV), 03a, 03b, 03b1 (fnMasteringFact*_2606).
-- Автор:   Александр
-- Дата:    2026-06-15 (обновлён)
-- =============================================================================

PRINT '=== 03c: CREATE FUNCTION ags.fnMasteringCstAgPn_2606 ===';
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION ags.fnMasteringCstAgPn_2606
(
    @ipgCh      int,
    @cstAgPn    int,
    @ipgSh      int,
    @StCostKey  int,
    @stNet      int,
    @ipgRoot    int
)
RETURNS
    @TablRslt TABLE
    (
        dAll date, ipgcrKey int, ipgcrChain int, ipgcrIpg int, ipgcrUtPlGr int,
        ipgpKey int, ipgpSh int, iuplgKey int, iuplgpPl int, iuplpKey int,
        ipgpCstAgPn int, cstaAg int, mKey int,
        smm money, smmTtl money, lim money, pct money,
        iuplpSubAg int,
        -- 8.1 Pres/Accp (18 колонок — _2606 вместо LEGACY)
        MstrngPrsRa money, MstrngAcpRa money, MstrngPrsRaMn money, MstrngAcpRaMn money,
        MstrngPrsAgFee money, MstrngAcpAgFee money, MstrngPrsAgFeeMn money, MstrngAcpAgFeeMn money,
        MstrngPrsRalp money, MstrngAcpRalp money, MstrngPrsRalpMn money, MstrngAcpRalpMn money,
        MstrngAcpStor money, MstrngAcpStorMn money, MstrngAcpControl money, MstrngAcpControlMn money,
        MstrngAcpMnrl money, MstrngAcpMnrlMn money,
        -- 8.2 RA Ret/InProc/NotArr/PresAll (8 колонок)
        MstrngRetRa money, MstrngRetRaMn money,
        MstrngInPrcRa money, MstrngInPrcRaMn money,
        MstrngNtArrRa money, MstrngNtArrRaMn money,
        MstrngPresAllRa money, MstrngPresAllRaMn money,
        -- 8.2 RA PrevYears (5 колонок)
        MstrngPresPrvYRa money, MstrngAcpPrvYRa money, MstrngRetPrvYRa money,
        MstrngInPrcPrvYRa money, MstrngNtArrPrvYRa money,
        -- 8.2 AgFee Ret/InProc/NotArr (6 колонок)
        MstrngRetAgFee money, MstrngRetAgFeeMn money,
        MstrngInPrcAgFee money, MstrngInPrcAgFeeMn money,
        MstrngNtArrAgFee money, MstrngNtArrAgFeeMn money,
        -- 8.2 Ralp Ret/InProc/NotArr (6 колонок)
        MstrngRetRalp money, MstrngRetRalpMn money,
        MstrngInPrcRalp money, MstrngInPrcRalpMn money,
        MstrngNtArrRalp money, MstrngNtArrRalpMn money,
        -- Сводные
        MasteringPres money, MasteringAccp money, MasteringPresMn money, MasteringAccpMn money,
        planCompleted money, planCompletedNot money, planCompletedOver money,
        limNot money, limOver money
    )
AS
BEGIN
    DECLARE @masteringTrue bit;

    IF @ipgSh = 2
        SET @masteringTrue = 'true';
    ELSE IF @ipgSh = 1
        BEGIN
            IF (SELECT COUNT(*) FROM ags.ipgChRlV v JOIN ags.ipgPn p ON v.ipgcrvIpg = p.ipgpIpg
                WHERE v.ipgcrvChain = @ipgCh AND p.ipgpCstAgPn = @cstAgPn AND p.ipgpSh = 2) > 0
                SET @masteringTrue = 'false';
            ELSE
                SET @masteringTrue = 'true';
        END
    ELSE
        BEGIN
            IF (SELECT COUNT(*) FROM ags.ipgChRlV v JOIN ags.ipgPn p ON v.ipgcrvIpg = p.ipgpIpg
                WHERE v.ipgcrvChain = @ipgCh AND p.ipgpCstAgPn = @cstAgPn AND p.ipgpSh IN (1, 2)) > 0
                SET @masteringTrue = 'false';
            ELSE
                SET @masteringTrue = 'true';
        END

    IF @masteringTrue = 'true'
    BEGIN
        DECLARE @raCostBase TABLE
        (
            orgSender  int          NULL,
            isChange   bit          NOT NULL,
            tyChange   nvarchar(20) NULL,
            datePeriod date         NOT NULL,
            stAccp     bit          NOT NULL,
            stRet      bit          NOT NULL,
            stInProc   bit          NOT NULL,
            stNotArr   bit          NOT NULL,
            CostSm     money        NOT NULL
        );

        INSERT INTO @raCostBase
        SELECT * FROM ags.fnMasteringRaCostBase_2606(@cstAgPn, @StCostKey, @stNet);

        DECLARE @afCostBase TABLE
        (
            mEnd     date  NOT NULL,
            stAccp   bit   NOT NULL,
            stRet    bit   NOT NULL,
            stInProc bit   NOT NULL,
            stNotArr bit   NOT NULL,
            CostSm   money NOT NULL
        );

        INSERT INTO @afCostBase
        SELECT * FROM ags.fnMasteringAgFeeCostBase_2606(@cstAgPn, @StCostKey, @stNet);

        DECLARE @ralpCostBase TABLE
        (
            dEnd     date  NOT NULL,
            stAccp   bit   NOT NULL,
            stRet    bit   NOT NULL,
            stInProc bit   NOT NULL,
            stNotArr bit   NOT NULL,
            CostSm   money NOT NULL
        );

        INSERT INTO @ralpCostBase
        SELECT * FROM ags.fnMasteringRalpCostBase_2606(@cstAgPn, @StCostKey, @stNet);

        DECLARE @prDocMnrlCostBase TABLE
        (
            kind   char(1) NOT NULL,
            dEnd   date    NOT NULL,
            CostSm money   NOT NULL
        );

        INSERT INTO @prDocMnrlCostBase
        SELECT * FROM ags.fnMasteringPrDocMnrlCostBase_2606(@cstAgPn, @StCostKey, @stNet);

        INSERT INTO @TablRslt
        (
            dAll, ipgcrKey, ipgcrChain, ipgcrIpg, ipgcrUtPlGr, ipgpKey, ipgpSh,
            iuplgKey, iuplgpPl, iuplpKey, ipgpCstAgPn, cstaAg, mKey,
            smm, smmTtl, lim, pct, iuplpSubAg,
            MstrngPrsRa, MstrngAcpRa, MstrngPrsRaMn, MstrngAcpRaMn,
            MstrngPrsAgFee, MstrngAcpAgFee, MstrngPrsAgFeeMn, MstrngAcpAgFeeMn,
            MstrngPrsRalp, MstrngAcpRalp, MstrngPrsRalpMn, MstrngAcpRalpMn,
            MstrngAcpStor, MstrngAcpStorMn, MstrngAcpControl, MstrngAcpControlMn,
            MstrngAcpMnrl, MstrngAcpMnrlMn,
            MstrngRetRa, MstrngRetRaMn, MstrngInPrcRa, MstrngInPrcRaMn,
            MstrngNtArrRa, MstrngNtArrRaMn, MstrngPresAllRa, MstrngPresAllRaMn,
            MstrngPresPrvYRa, MstrngAcpPrvYRa, MstrngRetPrvYRa, MstrngInPrcPrvYRa, MstrngNtArrPrvYRa,
            MstrngRetAgFee, MstrngRetAgFeeMn, MstrngInPrcAgFee, MstrngInPrcAgFeeMn,
            MstrngNtArrAgFee, MstrngNtArrAgFeeMn,
            MstrngRetRalp, MstrngRetRalpMn, MstrngInPrcRalp, MstrngInPrcRalpMn,
            MstrngNtArrRalp, MstrngNtArrRalpMn,
            MasteringPres, MasteringAccp, MasteringPresMn, MasteringAccpMn,
            planCompleted, planCompletedNot, planCompletedOver, limNot, limOver
        )
        SELECT
            x.dAll, x.ipgcrKey, x.ipgcrChain, x.ipgcrIpg, x.ipgcrUtPlGr, x.ipgpKey, x.ipgpSh,
            x.iuplgKey, x.iuplgpPl, x.iuplpKey, x.ipgpCstAgPn, x.cstaAg, x.mKey,
            x.smm, x.smmTtl, x.lim, x.pct, x.iuplpSubAg,
            x.MstrngPrsRa, x.MstrngAcpRa, x.MstrngPrsRaMn, x.MstrngAcpRaMn,
            x.MstrngPrsAgFee, x.MstrngAcpAgFee, x.MstrngPrsAgFeeMn, x.MstrngAcpAgFeeMn,
            x.MstrngPrsRalp, x.MstrngAcpRalp, x.MstrngPrsRalpMn, x.MstrngAcpRalpMn,
            x.MstrngAcpStor, x.MstrngAcpStorMn, x.MstrngAcpControl, x.MstrngAcpControlMn,
            x.MstrngAcpMnrl, x.MstrngAcpMnrlMn,
            x.MstrngRetRa, x.MstrngRetRaMn, x.MstrngInPrcRa, x.MstrngInPrcRaMn,
            x.MstrngNtArrRa, x.MstrngNtArrRaMn, x.MstrngPresAllRa, x.MstrngPresAllRaMn,
            x.MstrngPresPrvYRa, x.MstrngAcpPrvYRa, x.MstrngRetPrvYRa, x.MstrngInPrcPrvYRa, x.MstrngNtArrPrvYRa,
            x.MstrngRetAgFee, x.MstrngRetAgFeeMn, x.MstrngInPrcAgFee, x.MstrngInPrcAgFeeMn,
            x.MstrngNtArrAgFee, x.MstrngNtArrAgFeeMn,
            x.MstrngRetRalp, x.MstrngRetRalpMn, x.MstrngInPrcRalp, x.MstrngInPrcRalpMn,
            x.MstrngNtArrRalp, x.MstrngNtArrRalpMn,
            x.MasteringPres, x.MasteringAccp, x.MasteringPresMn, x.MasteringAccpMn,
            IIF(x.MasteringAccp < ISNULL(x.smmTtl, 0), x.MasteringAccp, ISNULL(x.smmTtl, 0)),
            IIF(x.MasteringAccp < ISNULL(x.smmTtl, 0), ISNULL(x.smmTtl, 0) - x.MasteringAccp, 0),
            IIF(ISNULL(x.lim, 0) < x.MasteringAccp,
                ISNULL(x.lim, 0) - ISNULL(x.smmTtl, 0),
                IIF(x.MasteringAccp < ISNULL(x.smmTtl, 0), 0, x.MasteringAccp - ISNULL(x.smmTtl, 0))),
            IIF(x.MasteringAccp < ISNULL(x.smmTtl, 0),
                IIF(ISNULL(x.lim, 0) < ISNULL(x.smmTtl, 0), 0, ISNULL(x.lim, 0) - ISNULL(x.smmTtl, 0)),
                IIF(x.MasteringAccp < ISNULL(x.lim, 0), ISNULL(x.lim, 0) - x.MasteringAccp, 0)),
            IIF(x.MasteringAccp < ISNULL(x.lim, 0), 0, x.MasteringAccp - ISNULL(x.lim, 0))
        FROM
        (
            SELECT
                y.*,
                ISNULL(MstrngPrsRa, 0) + ISNULL(MstrngPrsAgFee, 0) + ISNULL(MstrngPrsRalp, 0)
                    + ISNULL(MstrngAcpStor, 0) + ISNULL(MstrngAcpControl, 0) + ISNULL(MstrngAcpMnrl, 0) AS MasteringPres,
                ISNULL(MstrngAcpRa, 0) + ISNULL(MstrngAcpAgFee, 0) + ISNULL(MstrngAcpRalp, 0)
                    + ISNULL(MstrngAcpStor, 0) + ISNULL(MstrngAcpControl, 0) + ISNULL(MstrngAcpMnrl, 0) AS MasteringAccp,
                ISNULL(MstrngPrsRaMn, 0) + ISNULL(MstrngPrsAgFeeMn, 0) + ISNULL(MstrngPrsRalpMn, 0)
                    + ISNULL(MstrngAcpStorMn, 0) + ISNULL(MstrngAcpControlMn, 0) + ISNULL(MstrngAcpMnrlMn, 0) AS MasteringPresMn,
                ISNULL(MstrngAcpRaMn, 0) + ISNULL(MstrngAcpAgFeeMn, 0) + ISNULL(MstrngAcpRalpMn, 0)
                    + ISNULL(MstrngAcpStorMn, 0) + ISNULL(MstrngAcpControlMn, 0) + ISNULL(MstrngAcpMnrlMn, 0) AS MasteringAccpMn
            FROM
            (
                SELECT
                    d.dAll,
                    z.ipgcrKey, z.ipgcrChain, z.ipgcrIpg, z.ipgcrUtPlGr,
                    z.ipgpKey, z.ipgpSh, z.iuplgKey, z.iuplgpPl, z.iuplpKey,
                    z.ipgpCstAgPn, a.cstaAg, z.mKey, z.smm, z.smmTtl, z.lim, z.pct,
                    z.iuplpSubAg,
                    -- 9б.2а: все RA-колонки — один fnMasteringRaBundle_2606 на дату
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rb.MstrngPrsRa) AS MstrngPrsRa,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rb.MstrngAcpRa) AS MstrngAcpRa,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rb.MstrngPrsRaMn) AS MstrngPrsRaMn,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rb.MstrngAcpRaMn) AS MstrngAcpRaMn,
                    -- 9б.3: AgFee / Ralp / PrDoc+Mnrl — bundle на дату
                    IIF(z.ipgpCstAgPn IS NULL, NULL, af.MstrngPrsAgFee) AS MstrngPrsAgFee,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, af.MstrngAcpAgFee) AS MstrngAcpAgFee,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, af.MstrngPrsAgFeeMn) AS MstrngPrsAgFeeMn,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, af.MstrngAcpAgFeeMn) AS MstrngAcpAgFeeMn,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rl.MstrngPrsRalp) AS MstrngPrsRalp,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rl.MstrngAcpRalp) AS MstrngAcpRalp,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rl.MstrngPrsRalpMn) AS MstrngPrsRalpMn,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rl.MstrngAcpRalpMn) AS MstrngAcpRalpMn,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, pm.MstrngAcpStor) AS MstrngAcpStor,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, pm.MstrngAcpStorMn) AS MstrngAcpStorMn,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, pm.MstrngAcpControl) AS MstrngAcpControl,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, pm.MstrngAcpControlMn) AS MstrngAcpControlMn,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, pm.MstrngAcpMnrl) AS MstrngAcpMnrl,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, pm.MstrngAcpMnrlMn) AS MstrngAcpMnrlMn,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rb.MstrngRetRa) AS MstrngRetRa,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rb.MstrngRetRaMn) AS MstrngRetRaMn,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rb.MstrngInPrcRa) AS MstrngInPrcRa,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rb.MstrngInPrcRaMn) AS MstrngInPrcRaMn,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rb.MstrngNtArrRa) AS MstrngNtArrRa,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rb.MstrngNtArrRaMn) AS MstrngNtArrRaMn,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rb.MstrngPresAllRa) AS MstrngPresAllRa,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rb.MstrngPresAllRaMn) AS MstrngPresAllRaMn,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rb.MstrngPresPrvYRa) AS MstrngPresPrvYRa,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rb.MstrngAcpPrvYRa) AS MstrngAcpPrvYRa,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rb.MstrngRetPrvYRa) AS MstrngRetPrvYRa,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rb.MstrngInPrcPrvYRa) AS MstrngInPrcPrvYRa,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rb.MstrngNtArrPrvYRa) AS MstrngNtArrPrvYRa,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, af.MstrngRetAgFee) AS MstrngRetAgFee,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, af.MstrngRetAgFeeMn) AS MstrngRetAgFeeMn,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, af.MstrngInPrcAgFee) AS MstrngInPrcAgFee,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, af.MstrngInPrcAgFeeMn) AS MstrngInPrcAgFeeMn,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, af.MstrngNtArrAgFee) AS MstrngNtArrAgFee,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, af.MstrngNtArrAgFeeMn) AS MstrngNtArrAgFeeMn,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rl.MstrngRetRalp) AS MstrngRetRalp,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rl.MstrngRetRalpMn) AS MstrngRetRalpMn,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rl.MstrngInPrcRalp) AS MstrngInPrcRalp,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rl.MstrngInPrcRalpMn) AS MstrngInPrcRalpMn,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rl.MstrngNtArrRalp) AS MstrngNtArrRalp,
                    IIF(z.ipgpCstAgPn IS NULL, NULL, rl.MstrngNtArrRalpMn) AS MstrngNtArrRalpMn
                FROM
                    ags.fnIpgChDatsV(@ipgCh) d
                        LEFT JOIN (SELECT * FROM ags.fnStCostRsCstAgPn_2606(@ipgCh, @cstAgPn, @ipgSh, @StCostKey, @stNet, @ipgRoot)) AS z ON d.dAll = z.dd
                        LEFT JOIN ags.cstAgPn c ON z.ipgpCstAgPn = c.cstapKey
                            LEFT JOIN ags.cstAg a ON c.cstapCsta = a.cstaKey
                        OUTER APPLY
                        (
                            SELECT
                                SUM(CASE WHEN bx.dfYLe = 1 AND bx.exclNorm = 0 THEN bx.CostSm ELSE 0 END) AS MstrngPrsRa,
                                SUM(CASE WHEN bx.dfYLe = 1 AND bx.stAccp = 1 AND bx.exclNorm = 0 THEN bx.CostSm ELSE 0 END) AS MstrngAcpRa,
                                SUM(CASE WHEN bx.dfYM = 1 AND bx.exclNorm = 0 THEN bx.CostSm ELSE 0 END) AS MstrngPrsRaMn,
                                SUM(CASE WHEN bx.dfYM = 1 AND bx.stAccp = 1 AND bx.exclNorm = 0 THEN bx.CostSm ELSE 0 END) AS MstrngAcpRaMn,
                                SUM(CASE WHEN bx.dfYLe = 1 AND bx.stRet = 1 AND bx.exclNorm = 0 THEN bx.CostSm ELSE 0 END) AS MstrngRetRa,
                                SUM(CASE WHEN bx.dfYM = 1 AND bx.stRet = 1 AND bx.exclNorm = 0 THEN bx.CostSm ELSE 0 END) AS MstrngRetRaMn,
                                SUM(CASE WHEN bx.dfYLe = 1 AND bx.stInProc = 1 AND bx.exclNorm = 0 THEN bx.CostSm ELSE 0 END) AS MstrngInPrcRa,
                                SUM(CASE WHEN bx.dfYM = 1 AND bx.stInProc = 1 AND bx.exclNorm = 0 THEN bx.CostSm ELSE 0 END) AS MstrngInPrcRaMn,
                                SUM(CASE WHEN bx.dfYLe = 1 AND bx.stNotArr = 1 AND bx.exclNorm = 0 THEN bx.CostSm ELSE 0 END) AS MstrngNtArrRa,
                                SUM(CASE WHEN bx.dfYM = 1 AND bx.stNotArr = 1 AND bx.exclNorm = 0 THEN bx.CostSm ELSE 0 END) AS MstrngNtArrRaMn,
                                SUM(CASE WHEN bx.dfLe = 1 AND bx.exclNorm = 0 THEN bx.CostSm ELSE 0 END) AS MstrngPresAllRa,
                                SUM(CASE WHEN bx.dfMLe = 1 AND bx.exclNorm = 0 THEN bx.CostSm ELSE 0 END) AS MstrngPresAllRaMn,
                                SUM(CASE WHEN bx.dfPrvY = 1 AND bx.exclPrvY = 0 THEN bx.CostSm ELSE 0 END) AS MstrngPresPrvYRa,
                                SUM(CASE WHEN bx.dfPrvY = 1 AND bx.stAccp = 1 AND bx.exclPrvY = 0 THEN bx.CostSm ELSE 0 END) AS MstrngAcpPrvYRa,
                                SUM(CASE WHEN bx.dfPrvY = 1 AND bx.stRet = 1 AND bx.exclPrvY = 0 THEN bx.CostSm ELSE 0 END) AS MstrngRetPrvYRa,
                                SUM(CASE WHEN bx.dfPrvY = 1 AND bx.stInProc = 1 AND bx.exclPrvY = 0 THEN bx.CostSm ELSE 0 END) AS MstrngInPrcPrvYRa,
                                SUM(CASE WHEN bx.dfPrvY = 1 AND bx.stNotArr = 1 AND bx.exclPrvY = 0 THEN bx.CostSm ELSE 0 END) AS MstrngNtArrPrvYRa
                            FROM
                            (
                                SELECT
                                    b.*,
                                    CASE WHEN YEAR(d.dAll) = YEAR(b.datePeriod) AND d.dAll >= b.datePeriod THEN 1 ELSE 0 END AS dfYLe,
                                    CASE WHEN YEAR(d.dAll) = YEAR(b.datePeriod) AND MONTH(d.dAll) = MONTH(b.datePeriod) THEN 1 ELSE 0 END AS dfYM,
                                    CASE WHEN d.dAll >= b.datePeriod THEN 1 ELSE 0 END AS dfLe,
                                    CASE WHEN MONTH(d.dAll) = MONTH(b.datePeriod) AND d.dAll >= b.datePeriod THEN 1 ELSE 0 END AS dfMLe,
                                    CASE WHEN YEAR(b.datePeriod) < YEAR(d.dAll) THEN 1 ELSE 0 END AS dfPrvY,
                                    CASE WHEN b.isChange = 1 AND b.tyChange = N'ранние' AND b.CostSm < 0 THEN 1 ELSE 0 END AS exclNorm,
                                    CASE WHEN b.isChange = 1 AND b.CostSm < 0 THEN 1 ELSE 0 END AS exclPrvY
                                FROM @raCostBase b
                                WHERE ISNULL(z.iuplpSubAg, 0) = 0 OR b.orgSender = ISNULL(z.iuplpSubAg, 0)
                            ) bx
                        ) rb
                        OUTER APPLY
                        (
                            SELECT
                                SUM(CASE WHEN ax.dfYLe = 1 THEN ax.CostSm ELSE 0 END) AS MstrngPrsAgFee,
                                SUM(CASE WHEN ax.dfYLe = 1 AND ax.stAccp = 1 THEN ax.CostSm ELSE 0 END) AS MstrngAcpAgFee,
                                SUM(CASE WHEN ax.dfYM = 1 THEN ax.CostSm ELSE 0 END) AS MstrngPrsAgFeeMn,
                                SUM(CASE WHEN ax.dfYM = 1 AND ax.stAccp = 1 THEN ax.CostSm ELSE 0 END) AS MstrngAcpAgFeeMn,
                                SUM(CASE WHEN ax.dfYLe = 1 AND ax.stRet = 1 THEN ax.CostSm ELSE 0 END) AS MstrngRetAgFee,
                                SUM(CASE WHEN ax.dfYM = 1 AND ax.stRet = 1 THEN ax.CostSm ELSE 0 END) AS MstrngRetAgFeeMn,
                                SUM(CASE WHEN ax.dfYLe = 1 AND ax.stInProc = 1 THEN ax.CostSm ELSE 0 END) AS MstrngInPrcAgFee,
                                SUM(CASE WHEN ax.dfYM = 1 AND ax.stInProc = 1 THEN ax.CostSm ELSE 0 END) AS MstrngInPrcAgFeeMn,
                                SUM(CASE WHEN ax.dfYLe = 1 AND ax.stNotArr = 1 THEN ax.CostSm ELSE 0 END) AS MstrngNtArrAgFee,
                                SUM(CASE WHEN ax.dfYM = 1 AND ax.stNotArr = 1 THEN ax.CostSm ELSE 0 END) AS MstrngNtArrAgFeeMn
                            FROM
                            (
                                SELECT
                                    b.*,
                                    CASE WHEN YEAR(d.dAll) = YEAR(b.mEnd) AND d.dAll >= b.mEnd THEN 1 ELSE 0 END AS dfYLe,
                                    CASE WHEN YEAR(d.dAll) = YEAR(b.mEnd) AND MONTH(d.dAll) = MONTH(b.mEnd) THEN 1 ELSE 0 END AS dfYM
                                FROM @afCostBase b
                            ) ax
                        ) af
                        OUTER APPLY
                        (
                            SELECT
                                SUM(CASE WHEN rx.dfYLe = 1 THEN rx.CostSm ELSE 0 END) AS MstrngPrsRalp,
                                SUM(CASE WHEN rx.dfYLe = 1 AND rx.stAccp = 1 THEN rx.CostSm ELSE 0 END) AS MstrngAcpRalp,
                                SUM(CASE WHEN rx.dfYM = 1 THEN rx.CostSm ELSE 0 END) AS MstrngPrsRalpMn,
                                SUM(CASE WHEN rx.dfYM = 1 AND rx.stAccp = 1 THEN rx.CostSm ELSE 0 END) AS MstrngAcpRalpMn,
                                SUM(CASE WHEN rx.dfYLe = 1 AND rx.stRet = 1 THEN rx.CostSm ELSE 0 END) AS MstrngRetRalp,
                                SUM(CASE WHEN rx.dfYM = 1 AND rx.stRet = 1 THEN rx.CostSm ELSE 0 END) AS MstrngRetRalpMn,
                                SUM(CASE WHEN rx.dfYLe = 1 AND rx.stInProc = 1 THEN rx.CostSm ELSE 0 END) AS MstrngInPrcRalp,
                                SUM(CASE WHEN rx.dfYM = 1 AND rx.stInProc = 1 THEN rx.CostSm ELSE 0 END) AS MstrngInPrcRalpMn,
                                SUM(CASE WHEN rx.dfYLe = 1 AND rx.stNotArr = 1 THEN rx.CostSm ELSE 0 END) AS MstrngNtArrRalp,
                                SUM(CASE WHEN rx.dfYM = 1 AND rx.stNotArr = 1 THEN rx.CostSm ELSE 0 END) AS MstrngNtArrRalpMn
                            FROM
                            (
                                SELECT
                                    b.*,
                                    CASE WHEN YEAR(d.dAll) = YEAR(b.dEnd) AND d.dAll >= b.dEnd THEN 1 ELSE 0 END AS dfYLe,
                                    CASE WHEN YEAR(d.dAll) = YEAR(b.dEnd) AND MONTH(d.dAll) = MONTH(b.dEnd) THEN 1 ELSE 0 END AS dfYM
                                FROM @ralpCostBase b
                            ) rx
                        ) rl
                        OUTER APPLY
                        (
                            SELECT
                                SUM(CASE WHEN px.dfYLe = 1 AND px.kind = N'S' THEN px.CostSm ELSE 0 END) AS MstrngAcpStor,
                                SUM(CASE WHEN px.dfYM = 1 AND px.kind = N'S' THEN px.CostSm ELSE 0 END) AS MstrngAcpStorMn,
                                SUM(CASE WHEN px.dfYLe = 1 AND px.kind = N'C' THEN px.CostSm ELSE 0 END) AS MstrngAcpControl,
                                SUM(CASE WHEN px.dfYM = 1 AND px.kind = N'C' THEN px.CostSm ELSE 0 END) AS MstrngAcpControlMn,
                                SUM(CASE WHEN px.dfYLe = 1 AND px.kind = N'M' THEN px.CostSm ELSE 0 END) AS MstrngAcpMnrl,
                                SUM(CASE WHEN px.dfYM = 1 AND px.kind = N'M' THEN px.CostSm ELSE 0 END) AS MstrngAcpMnrlMn
                            FROM
                            (
                                SELECT
                                    b.*,
                                    CASE WHEN YEAR(d.dAll) = YEAR(b.dEnd) AND d.dAll >= b.dEnd THEN 1 ELSE 0 END AS dfYLe,
                                    CASE WHEN YEAR(d.dAll) = YEAR(b.dEnd) AND MONTH(d.dAll) = MONTH(b.dEnd) THEN 1 ELSE 0 END AS dfYM
                                FROM @prDocMnrlCostBase b
                            ) px
                        ) pm
            ) AS y
        ) AS x;
    END
    ELSE
        INSERT INTO @TablRslt
        (
            dAll, ipgcrKey, ipgcrChain, ipgcrIpg, ipgcrUtPlGr, ipgpKey, ipgpSh,
            iuplgKey, iuplgpPl, iuplpKey, ipgpCstAgPn, cstaAg, mKey,
            smm, smmTtl, lim, pct, iuplpSubAg,
            MstrngPrsRa, MstrngAcpRa, MstrngPrsRaMn, MstrngAcpRaMn,
            MstrngPrsAgFee, MstrngAcpAgFee, MstrngPrsAgFeeMn, MstrngAcpAgFeeMn,
            MstrngPrsRalp, MstrngAcpRalp, MstrngPrsRalpMn, MstrngAcpRalpMn,
            MstrngAcpStor, MstrngAcpStorMn, MstrngAcpControl, MstrngAcpControlMn,
            MstrngAcpMnrl, MstrngAcpMnrlMn,
            MstrngRetRa, MstrngRetRaMn, MstrngInPrcRa, MstrngInPrcRaMn,
            MstrngNtArrRa, MstrngNtArrRaMn, MstrngPresAllRa, MstrngPresAllRaMn,
            MstrngPresPrvYRa, MstrngAcpPrvYRa, MstrngRetPrvYRa, MstrngInPrcPrvYRa, MstrngNtArrPrvYRa,
            MstrngRetAgFee, MstrngRetAgFeeMn, MstrngInPrcAgFee, MstrngInPrcAgFeeMn,
            MstrngNtArrAgFee, MstrngNtArrAgFeeMn,
            MstrngRetRalp, MstrngRetRalpMn, MstrngInPrcRalp, MstrngInPrcRalpMn,
            MstrngNtArrRalp, MstrngNtArrRalpMn,
            MasteringPres, MasteringAccp, MasteringPresMn, MasteringAccpMn,
            planCompleted, planCompletedNot, planCompletedOver, limNot, limOver
        )
        SELECT
            x.dAll, x.ipgcrKey, x.ipgcrChain, x.ipgcrIpg, x.ipgcrUtPlGr, x.ipgpKey, x.ipgpSh,
            x.iuplgKey, x.iuplgpPl, x.iuplpKey, x.ipgpCstAgPn, x.cstaAg, x.mKey,
            x.smm, x.smmTtl, x.lim, x.pct, x.iuplpSubAg,
            NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
            NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
            NULL, NULL,
            NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
            NULL, NULL, NULL, NULL, NULL,
            NULL, NULL, NULL, NULL, NULL, NULL,
            NULL, NULL, NULL, NULL, NULL, NULL,
            NULL, NULL, NULL, NULL,
            0, 0, 0,
            ISNULL(x.lim, 0), 0
        FROM
        (
            SELECT
                y.*, NULL AS MasteringPres, NULL AS MasteringAccp, NULL AS MasteringPresMn, NULL AS MasteringAccpMn
            FROM
            (
                SELECT
                    d.dAll,
                    z.ipgcrKey, z.ipgcrChain, z.ipgcrIpg, z.ipgcrUtPlGr,
                    z.ipgpKey, z.ipgpSh, z.iuplgKey, z.iuplgpPl, z.iuplpKey,
                    z.ipgpCstAgPn, a.cstaAg, z.mKey, z.smm, z.smmTtl, z.lim, z.pct,
                    z.iuplpSubAg
                FROM
                    ags.fnIpgChDatsV(@ipgCh) d
                        LEFT JOIN (SELECT * FROM ags.fnStCostRsCstAgPn_2606(@ipgCh, @cstAgPn, @ipgSh, @StCostKey, @stNet, @ipgRoot)) AS z ON d.dAll = z.dd
                        LEFT JOIN ags.cstAgPn c ON z.ipgpCstAgPn = c.cstapKey
                            LEFT JOIN ags.cstAg a ON c.cstapCsta = a.cstaKey
            ) AS y
        ) AS x;

    RETURN;
END
GO

PRINT '=== 03c: CREATE FUNCTION ags.fnMasteringCstAgPnSh_2606 ===';
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION ags.fnMasteringCstAgPnSh_2606
(
    @ipgCh      int,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @ipgRoot    int
)
RETURNS
    @TablRslt TABLE
    (
        dAll date, ipgcrKey int, ipgcrChain int, ipgcrIpg int, ipgcrUtPlGr int,
        ipgpKey int, ipgpSh int, iuplgKey int, iuplgpPl int, iuplpKey int,
        ipgpCstAgPn int, cstaAg int, mKey int,
        iuplpSubAg int,
        -- АГЕНТСКАЯ СХЕМА (ag)
        agSmm money, agSmmTtl money, agLim money, agPct money,
        agMstrngPrsRa money, agMstrngAcpRa money, agMstrngPrsRaMn money, agMstrngAcpRaMn money,
        agMstrngPrsAgFee money, agMstrngAcpAgFee money, agMstrngPrsAgFeeMn money, agMstrngAcpAgFeeMn money,
        agMstrngPrsRalp money, agMstrngAcpRalp money, agMstrngPrsRalpMn money, agMstrngAcpRalpMn money,
        agMstrngAcpStor money, agMstrngAcpStorMn money, agMstrngAcpControl money, agMstrngAcpControlMn money,
        agMstrngAcpMnrl money, agMstrngAcpMnrlMn money,
        agMstrngRetRa money, agMstrngRetRaMn money, agMstrngInPrcRa money, agMstrngInPrcRaMn money,
        agMstrngNtArrRa money, agMstrngNtArrRaMn money, agMstrngPresAllRa money, agMstrngPresAllRaMn money,
        agMstrngPresPrvYRa money, agMstrngAcpPrvYRa money, agMstrngRetPrvYRa money, agMstrngInPrcPrvYRa money, agMstrngNtArrPrvYRa money,
        agMstrngRetAgFee money, agMstrngRetAgFeeMn money, agMstrngInPrcAgFee money, agMstrngInPrcAgFeeMn money,
        agMstrngNtArrAgFee money, agMstrngNtArrAgFeeMn money,
        agMstrngRetRalp money, agMstrngRetRalpMn money, agMstrngInPrcRalp money, agMstrngInPrcRalpMn money,
        agMstrngNtArrRalp money, agMstrngNtArrRalpMn money,
        agMasteringPres money, agMasteringAccp money, agMasteringPresMn money, agMasteringAccpMn money,
        agPlanCompleted money, agPlanCompletedNot money, agPlanCompletedOver money,
        aglimNot money, aglimOver money,
        -- ИНВЕСТИЦИОННАЯ СХЕМА (in)
        inSmm money, inSmmTtl money, inLim money, inPct money,
        inMstrngPrsRa money, inMstrngAcpRa money, inMstrngPrsRaMn money, inMstrngAcpRaMn money,
        inMstrngPrsAgFee money, inMstrngAcpAgFee money, inMstrngPrsAgFeeMn money, inMstrngAcpAgFeeMn money,
        inMstrngPrsRalp money, inMstrngAcpRalp money, inMstrngPrsRalpMn money, inMstrngAcpRalpMn money,
        inMstrngAcpStor money, inMstrngAcpStorMn money, inMstrngAcpControl money, inMstrngAcpControlMn money,
        inMstrngAcpMnrl money, inMstrngAcpMnrlMn money,
        inMstrngRetRa money, inMstrngRetRaMn money, inMstrngInPrcRa money, inMstrngInPrcRaMn money,
        inMstrngNtArrRa money, inMstrngNtArrRaMn money, inMstrngPresAllRa money, inMstrngPresAllRaMn money,
        inMstrngPresPrvYRa money, inMstrngAcpPrvYRa money, inMstrngRetPrvYRa money, inMstrngInPrcPrvYRa money, inMstrngNtArrPrvYRa money,
        inMstrngRetAgFee money, inMstrngRetAgFeeMn money, inMstrngInPrcAgFee money, inMstrngInPrcAgFeeMn money,
        inMstrngNtArrAgFee money, inMstrngNtArrAgFeeMn money,
        inMstrngRetRalp money, inMstrngRetRalpMn money, inMstrngInPrcRalp money, inMstrngInPrcRalpMn money,
        inMstrngNtArrRalp money, inMstrngNtArrRalpMn money,
        inMasteringPres money, inMasteringAccp money, inMasteringPresMn money, inMasteringAccpMn money,
        inPlanCompleted money, inPlanCompletedNot money, inPlanCompletedOver money,
        inlimNot money, inlimOver money,
        -- ДРУГАЯ СХЕМА (dr)
        drSmm money, drSmmTtl money, drLim money, drPct money,
        drMstrngPrsRa money, drMstrngAcpRa money, drMstrngPrsRaMn money, drMstrngAcpRaMn money,
        drMstrngPrsAgFee money, drMstrngAcpAgFee money, drMstrngPrsAgFeeMn money, drMstrngAcpAgFeeMn money,
        drMstrngPrsRalp money, drMstrngAcpRalp money, drMstrngPrsRalpMn money, drMstrngAcpRalpMn money,
        drMstrngAcpStor money, drMstrngAcpStorMn money, drMstrngAcpControl money, drMstrngAcpControlMn money,
        drMstrngAcpMnrl money, drMstrngAcpMnrlMn money,
        drMstrngRetRa money, drMstrngRetRaMn money, drMstrngInPrcRa money, drMstrngInPrcRaMn money,
        drMstrngNtArrRa money, drMstrngNtArrRaMn money, drMstrngPresAllRa money, drMstrngPresAllRaMn money,
        drMstrngPresPrvYRa money, drMstrngAcpPrvYRa money, drMstrngRetPrvYRa money, drMstrngInPrcPrvYRa money, drMstrngNtArrPrvYRa money,
        drMstrngRetAgFee money, drMstrngRetAgFeeMn money, drMstrngInPrcAgFee money, drMstrngInPrcAgFeeMn money,
        drMstrngNtArrAgFee money, drMstrngNtArrAgFeeMn money,
        drMstrngRetRalp money, drMstrngRetRalpMn money, drMstrngInPrcRalp money, drMstrngInPrcRalpMn money,
        drMstrngNtArrRalp money, drMstrngNtArrRalpMn money,
        drMasteringPres money, drMasteringAccp money, drMasteringPresMn money, drMasteringAccpMn money,
        drPlanCompleted money, drPlanCompletedNot money, drPlanCompletedOver money,
        drlimNot money, drlimOver money
    )
AS
BEGIN
    DECLARE @ShType int;

    SET @ShType =
    (
        SELECT MIN(x.toShNum)
        FROM
        (
            SELECT
                y.*,
                CASE
                    WHEN y.rslt IN (N'агентская, инвестиционная и другая', N'агентская и инвестиционная', N'агентская и другая', N'агентская') THEN 1
                    WHEN y.rslt IN (N'инвестиционная и другая', N'инвестиционная') THEN 2
                    WHEN y.rslt = N'другая' THEN 3
                END AS toShNum
            FROM
            (
                SELECT pvt.*,
                    IIF(pvt.[1] = 1,
                        IIF(pvt.[2] = 1,
                            IIF(pvt.[3] = 1, N'агентская, инвестиционная и другая', N'агентская и инвестиционная'),
                            IIF(pvt.[3] = 1, N'инвестиционная и другая', N'инвестиционная')),
                        IIF(pvt.[2] = 1,
                            IIF(pvt.[3] = 1, N'агентская и другая', N'агентская'),
                            IIF(pvt.[3] = 1, N'другая', N'не может быть, чтобы схем не было'))) AS rslt
                FROM
                (
                    SELECT v.ipgcrvChain, p.ipgpIpg, p.ipgpCstAgPn, p.ipgpSh, 1 AS ccc
                    FROM ags.ipgPn p INNER JOIN ags.ipgChRlV v ON p.ipgpIpg = v.ipgcrvIpg
                    WHERE p.ipgpCstAgPn = @cstAgPn AND v.ipgcrvChain = @ipgCh
                    GROUP BY v.ipgcrvChain, p.ipgpIpg, p.ipgpCstAgPn, p.ipgpSh
                ) AS z
                PIVOT (SUM(z.ccc) FOR z.ipgpSh IN ([1],[2],[3])) AS PVT
            ) AS y
        ) AS x
        GROUP BY x.ipgcrvChain, x.ipgpCstAgPn
    );

    -- =========================================================================
    -- @ShType = 1: агентская схема (освоение через ag; in/dr — только лимиты)
    -- =========================================================================
    IF @ShType = 1
        INSERT INTO @TablRslt
        (
            dAll, ipgcrKey, ipgcrChain, ipgcrIpg, ipgcrUtPlGr, ipgpKey, ipgpSh,
            iuplgKey, iuplgpPl, iuplpKey, ipgpCstAgPn, cstaAg, mKey, iuplpSubAg,
            agSmm, agSmmTtl, agLim, agPct,
            agMstrngPrsRa, agMstrngAcpRa, agMstrngPrsRaMn, agMstrngAcpRaMn,
            agMstrngPrsAgFee, agMstrngAcpAgFee, agMstrngPrsAgFeeMn, agMstrngAcpAgFeeMn,
            agMstrngPrsRalp, agMstrngAcpRalp, agMstrngPrsRalpMn, agMstrngAcpRalpMn,
            agMstrngAcpStor, agMstrngAcpStorMn, agMstrngAcpControl, agMstrngAcpControlMn,
            agMstrngAcpMnrl, agMstrngAcpMnrlMn,
            agMstrngRetRa, agMstrngRetRaMn, agMstrngInPrcRa, agMstrngInPrcRaMn,
            agMstrngNtArrRa, agMstrngNtArrRaMn, agMstrngPresAllRa, agMstrngPresAllRaMn,
            agMstrngPresPrvYRa, agMstrngAcpPrvYRa, agMstrngRetPrvYRa, agMstrngInPrcPrvYRa, agMstrngNtArrPrvYRa,
            agMstrngRetAgFee, agMstrngRetAgFeeMn, agMstrngInPrcAgFee, agMstrngInPrcAgFeeMn,
            agMstrngNtArrAgFee, agMstrngNtArrAgFeeMn,
            agMstrngRetRalp, agMstrngRetRalpMn, agMstrngInPrcRalp, agMstrngInPrcRalpMn,
            agMstrngNtArrRalp, agMstrngNtArrRalpMn,
            agMasteringPres, agMasteringAccp, agMasteringPresMn, agMasteringAccpMn,
            agPlanCompleted, agPlanCompletedNot, agPlanCompletedOver, aglimNot, aglimOver,
            inSmm, inSmmTtl, inLim, inPct,
            inMstrngPrsRa, inMstrngAcpRa, inMstrngPrsRaMn, inMstrngAcpRaMn,
            inMstrngPrsAgFee, inMstrngAcpAgFee, inMstrngPrsAgFeeMn, inMstrngAcpAgFeeMn,
            inMstrngPrsRalp, inMstrngAcpRalp, inMstrngPrsRalpMn, inMstrngAcpRalpMn,
            inMstrngAcpStor, inMstrngAcpStorMn, inMstrngAcpControl, inMstrngAcpControlMn,
            inMstrngAcpMnrl, inMstrngAcpMnrlMn,
            inMstrngRetRa, inMstrngRetRaMn, inMstrngInPrcRa, inMstrngInPrcRaMn,
            inMstrngNtArrRa, inMstrngNtArrRaMn, inMstrngPresAllRa, inMstrngPresAllRaMn,
            inMstrngPresPrvYRa, inMstrngAcpPrvYRa, inMstrngRetPrvYRa, inMstrngInPrcPrvYRa, inMstrngNtArrPrvYRa,
            inMstrngRetAgFee, inMstrngRetAgFeeMn, inMstrngInPrcAgFee, inMstrngInPrcAgFeeMn,
            inMstrngNtArrAgFee, inMstrngNtArrAgFeeMn,
            inMstrngRetRalp, inMstrngRetRalpMn, inMstrngInPrcRalp, inMstrngInPrcRalpMn,
            inMstrngNtArrRalp, inMstrngNtArrRalpMn,
            inMasteringPres, inMasteringAccp, inMasteringPresMn, inMasteringAccpMn,
            inPlanCompleted, inPlanCompletedNot, inPlanCompletedOver, inlimNot, inlimOver,
            drSmm, drSmmTtl, drLim, drPct,
            drMstrngPrsRa, drMstrngAcpRa, drMstrngPrsRaMn, drMstrngAcpRaMn,
            drMstrngPrsAgFee, drMstrngAcpAgFee, drMstrngPrsAgFeeMn, drMstrngAcpAgFeeMn,
            drMstrngPrsRalp, drMstrngAcpRalp, drMstrngPrsRalpMn, drMstrngAcpRalpMn,
            drMstrngAcpStor, drMstrngAcpStorMn, drMstrngAcpControl, drMstrngAcpControlMn,
            drMstrngAcpMnrl, drMstrngAcpMnrlMn,
            drMstrngRetRa, drMstrngRetRaMn, drMstrngInPrcRa, drMstrngInPrcRaMn,
            drMstrngNtArrRa, drMstrngNtArrRaMn, drMstrngPresAllRa, drMstrngPresAllRaMn,
            drMstrngPresPrvYRa, drMstrngAcpPrvYRa, drMstrngRetPrvYRa, drMstrngInPrcPrvYRa, drMstrngNtArrPrvYRa,
            drMstrngRetAgFee, drMstrngRetAgFeeMn, drMstrngInPrcAgFee, drMstrngInPrcAgFeeMn,
            drMstrngNtArrAgFee, drMstrngNtArrAgFeeMn,
            drMstrngRetRalp, drMstrngRetRalpMn, drMstrngInPrcRalp, drMstrngInPrcRalpMn,
            drMstrngNtArrRalp, drMstrngNtArrRalpMn,
            drMasteringPres, drMasteringAccp, drMasteringPresMn, drMasteringAccpMn,
            drPlanCompleted, drPlanCompletedNot, drPlanCompletedOver, drlimNot, drlimOver
        )
        SELECT
            a.dAll, a.ipgcrKey, a.ipgcrChain, a.ipgcrIpg, a.ipgcrUtPlGr, a.ipgpKey, a.ipgpSh,
            a.iuplgKey, a.iuplgpPl, a.iuplpKey, a.ipgpCstAgPn, a.cstaAg, a.mKey, a.iuplpSubAg,
            -- ag
            a.smm, a.smmTtl, a.lim, a.pct,
            a.MstrngPrsRa, a.MstrngAcpRa, a.MstrngPrsRaMn, a.MstrngAcpRaMn,
            a.MstrngPrsAgFee, a.MstrngAcpAgFee, a.MstrngPrsAgFeeMn, a.MstrngAcpAgFeeMn,
            a.MstrngPrsRalp, a.MstrngAcpRalp, a.MstrngPrsRalpMn, a.MstrngAcpRalpMn,
            a.MstrngAcpStor, a.MstrngAcpStorMn, a.MstrngAcpControl, a.MstrngAcpControlMn,
            a.MstrngAcpMnrl, a.MstrngAcpMnrlMn,
            a.MstrngRetRa, a.MstrngRetRaMn, a.MstrngInPrcRa, a.MstrngInPrcRaMn,
            a.MstrngNtArrRa, a.MstrngNtArrRaMn, a.MstrngPresAllRa, a.MstrngPresAllRaMn,
            a.MstrngPresPrvYRa, a.MstrngAcpPrvYRa, a.MstrngRetPrvYRa, a.MstrngInPrcPrvYRa, a.MstrngNtArrPrvYRa,
            a.MstrngRetAgFee, a.MstrngRetAgFeeMn, a.MstrngInPrcAgFee, a.MstrngInPrcAgFeeMn,
            a.MstrngNtArrAgFee, a.MstrngNtArrAgFeeMn,
            a.MstrngRetRalp, a.MstrngRetRalpMn, a.MstrngInPrcRalp, a.MstrngInPrcRalpMn,
            a.MstrngNtArrRalp, a.MstrngNtArrRalpMn,
            a.MasteringPres, a.MasteringAccp, a.MasteringPresMn, a.MasteringAccpMn,
            a.planCompleted, a.planCompletedNot, a.planCompletedOver, a.limNot, a.limOver,
            -- in (только лимиты)
            i.smm, i.smmTtl, i.lim, i.pct,
            NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
            NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
            NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
            NULL, NULL, NULL, NULL, NULL,
            NULL, NULL, NULL, NULL, NULL, NULL,
            NULL, NULL, NULL, NULL, NULL, NULL,
            NULL, NULL, NULL, NULL,
            0, 0, 0, ISNULL(i.lim, 0), 0,
            -- dr (только лимиты)
            d.smm, d.smmTtl, d.lim, d.pct,
            NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
            NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
            NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
            NULL, NULL, NULL, NULL, NULL,
            NULL, NULL, NULL, NULL, NULL, NULL,
            NULL, NULL, NULL, NULL, NULL, NULL,
            NULL, NULL, NULL, NULL,
            0, 0, 0, ISNULL(d.lim, 0), 0
        FROM ags.fnMasteringCstAgPn_2606(@ipgCh, @cstAgPn, 2, @StCostKey, @stNet, @ipgRoot) a
            LEFT JOIN ags.fnMasteringCstAgPn_2606(@ipgCh, @cstAgPn, 1, @StCostKey, @stNet, @ipgRoot) i
                ON a.dAll = i.dAll AND (a.iuplpSubAg = i.iuplpSubAg OR (a.iuplpSubAg IS NULL AND i.iuplpSubAg IS NULL))
            LEFT JOIN ags.fnMasteringCstAgPn_2606(@ipgCh, @cstAgPn, 3, @StCostKey, @stNet, @ipgRoot) d
                ON a.dAll = d.dAll AND (a.iuplpSubAg = d.iuplpSubAg OR (a.iuplpSubAg IS NULL AND d.iuplpSubAg IS NULL));
    ELSE
        BEGIN
            -- =========================================================================
            -- @ShType = 2: инвестиционная схема
            -- =========================================================================
            IF @ShType = 2
                INSERT INTO @TablRslt
                (
                    dAll, ipgcrKey, ipgcrChain, ipgcrIpg, ipgcrUtPlGr, ipgpKey, ipgpSh,
                    iuplgKey, iuplgpPl, iuplpKey, ipgpCstAgPn, cstaAg, mKey, iuplpSubAg,
                    agSmm, agSmmTtl, agLim, agPct,
                    agMstrngPrsRa, agMstrngAcpRa, agMstrngPrsRaMn, agMstrngAcpRaMn,
                    agMstrngPrsAgFee, agMstrngAcpAgFee, agMstrngPrsAgFeeMn, agMstrngAcpAgFeeMn,
                    agMstrngPrsRalp, agMstrngAcpRalp, agMstrngPrsRalpMn, agMstrngAcpRalpMn,
                    agMstrngAcpStor, agMstrngAcpStorMn, agMstrngAcpControl, agMstrngAcpControlMn,
                    agMstrngAcpMnrl, agMstrngAcpMnrlMn,
                    agMstrngRetRa, agMstrngRetRaMn, agMstrngInPrcRa, agMstrngInPrcRaMn,
                    agMstrngNtArrRa, agMstrngNtArrRaMn, agMstrngPresAllRa, agMstrngPresAllRaMn,
                    agMstrngPresPrvYRa, agMstrngAcpPrvYRa, agMstrngRetPrvYRa, agMstrngInPrcPrvYRa, agMstrngNtArrPrvYRa,
                    agMstrngRetAgFee, agMstrngRetAgFeeMn, agMstrngInPrcAgFee, agMstrngInPrcAgFeeMn,
                    agMstrngNtArrAgFee, agMstrngNtArrAgFeeMn,
                    agMstrngRetRalp, agMstrngRetRalpMn, agMstrngInPrcRalp, agMstrngInPrcRalpMn,
                    agMstrngNtArrRalp, agMstrngNtArrRalpMn,
                    agMasteringPres, agMasteringAccp, agMasteringPresMn, agMasteringAccpMn,
                    agPlanCompleted, agPlanCompletedNot, agPlanCompletedOver, aglimNot, aglimOver,
                    inSmm, inSmmTtl, inLim, inPct,
                    inMstrngPrsRa, inMstrngAcpRa, inMstrngPrsRaMn, inMstrngAcpRaMn,
                    inMstrngPrsAgFee, inMstrngAcpAgFee, inMstrngPrsAgFeeMn, inMstrngAcpAgFeeMn,
                    inMstrngPrsRalp, inMstrngAcpRalp, inMstrngPrsRalpMn, inMstrngAcpRalpMn,
                    inMstrngAcpStor, inMstrngAcpStorMn, inMstrngAcpControl, inMstrngAcpControlMn,
                    inMstrngAcpMnrl, inMstrngAcpMnrlMn,
                    inMstrngRetRa, inMstrngRetRaMn, inMstrngInPrcRa, inMstrngInPrcRaMn,
                    inMstrngNtArrRa, inMstrngNtArrRaMn, inMstrngPresAllRa, inMstrngPresAllRaMn,
                    inMstrngPresPrvYRa, inMstrngAcpPrvYRa, inMstrngRetPrvYRa, inMstrngInPrcPrvYRa, inMstrngNtArrPrvYRa,
                    inMstrngRetAgFee, inMstrngRetAgFeeMn, inMstrngInPrcAgFee, inMstrngInPrcAgFeeMn,
                    inMstrngNtArrAgFee, inMstrngNtArrAgFeeMn,
                    inMstrngRetRalp, inMstrngRetRalpMn, inMstrngInPrcRalp, inMstrngInPrcRalpMn,
                    inMstrngNtArrRalp, inMstrngNtArrRalpMn,
                    inMasteringPres, inMasteringAccp, inMasteringPresMn, inMasteringAccpMn,
                    inPlanCompleted, inPlanCompletedNot, inPlanCompletedOver, inlimNot, inlimOver,
                    drSmm, drSmmTtl, drLim, drPct,
                    drMstrngPrsRa, drMstrngAcpRa, drMstrngPrsRaMn, drMstrngAcpRaMn,
                    drMstrngPrsAgFee, drMstrngAcpAgFee, drMstrngPrsAgFeeMn, drMstrngAcpAgFeeMn,
                    drMstrngPrsRalp, drMstrngAcpRalp, drMstrngPrsRalpMn, drMstrngAcpRalpMn,
                    drMstrngAcpStor, drMstrngAcpStorMn, drMstrngAcpControl, drMstrngAcpControlMn,
                    drMstrngAcpMnrl, drMstrngAcpMnrlMn,
                    drMstrngRetRa, drMstrngRetRaMn, drMstrngInPrcRa, drMstrngInPrcRaMn,
                    drMstrngNtArrRa, drMstrngNtArrRaMn, drMstrngPresAllRa, drMstrngPresAllRaMn,
                    drMstrngPresPrvYRa, drMstrngAcpPrvYRa, drMstrngRetPrvYRa, drMstrngInPrcPrvYRa, drMstrngNtArrPrvYRa,
                    drMstrngRetAgFee, drMstrngRetAgFeeMn, drMstrngInPrcAgFee, drMstrngInPrcAgFeeMn,
                    drMstrngNtArrAgFee, drMstrngNtArrAgFeeMn,
                    drMstrngRetRalp, drMstrngRetRalpMn, drMstrngInPrcRalp, drMstrngInPrcRalpMn,
                    drMstrngNtArrRalp, drMstrngNtArrRalpMn,
                    drMasteringPres, drMasteringAccp, drMasteringPresMn, drMasteringAccpMn,
                    drPlanCompleted, drPlanCompletedNot, drPlanCompletedOver, drlimNot, drlimOver
                )
                SELECT
                    i.dAll, i.ipgcrKey, i.ipgcrChain, i.ipgcrIpg, i.ipgcrUtPlGr, i.ipgpKey, i.ipgpSh,
                    i.iuplgKey, i.iuplgpPl, i.iuplpKey, i.ipgpCstAgPn, i.cstaAg, i.mKey, i.iuplpSubAg,
                    -- ag (только нули)
                    NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL,
                    0, 0, 0, 0, 0,
                    -- in (освоение)
                    i.smm, i.smmTtl, i.lim, i.pct,
                    i.MstrngPrsRa, i.MstrngAcpRa, i.MstrngPrsRaMn, i.MstrngAcpRaMn,
                    i.MstrngPrsAgFee, i.MstrngAcpAgFee, i.MstrngPrsAgFeeMn, i.MstrngAcpAgFeeMn,
                    i.MstrngPrsRalp, i.MstrngAcpRalp, i.MstrngPrsRalpMn, i.MstrngAcpRalpMn,
                    i.MstrngAcpStor, i.MstrngAcpStorMn, i.MstrngAcpControl, i.MstrngAcpControlMn,
                    i.MstrngAcpMnrl, i.MstrngAcpMnrlMn,
                    i.MstrngRetRa, i.MstrngRetRaMn, i.MstrngInPrcRa, i.MstrngInPrcRaMn,
                    i.MstrngNtArrRa, i.MstrngNtArrRaMn, i.MstrngPresAllRa, i.MstrngPresAllRaMn,
                    i.MstrngPresPrvYRa, i.MstrngAcpPrvYRa, i.MstrngRetPrvYRa, i.MstrngInPrcPrvYRa, i.MstrngNtArrPrvYRa,
                    i.MstrngRetAgFee, i.MstrngRetAgFeeMn, i.MstrngInPrcAgFee, i.MstrngInPrcAgFeeMn,
                    i.MstrngNtArrAgFee, i.MstrngNtArrAgFeeMn,
                    i.MstrngRetRalp, i.MstrngRetRalpMn, i.MstrngInPrcRalp, i.MstrngInPrcRalpMn,
                    i.MstrngNtArrRalp, i.MstrngNtArrRalpMn,
                    i.MasteringPres, i.MasteringAccp, i.MasteringPresMn, i.MasteringAccpMn,
                    i.planCompleted, i.planCompletedNot, i.planCompletedOver, i.limNot, i.limOver,
                    -- dr (только лимиты)
                    d.smm, d.smmTtl, d.lim, d.pct,
                    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL,
                    0, 0, 0, ISNULL(d.lim, 0), 0
                FROM ags.fnMasteringCstAgPn_2606(@ipgCh, @cstAgPn, 1, @StCostKey, @stNet, @ipgRoot) i
                    LEFT JOIN ags.fnMasteringCstAgPn_2606(@ipgCh, @cstAgPn, 3, @StCostKey, @stNet, @ipgRoot) d
                        ON i.dAll = d.dAll AND (i.iuplpSubAg = d.iuplpSubAg OR (i.iuplpSubAg IS NULL AND d.iuplpSubAg IS NULL));
            ELSE
            -- =========================================================================
            -- @ShType = 3: другая схема
            -- =========================================================================
                INSERT INTO @TablRslt
                (
                    dAll, ipgcrKey, ipgcrChain, ipgcrIpg, ipgcrUtPlGr, ipgpKey, ipgpSh,
                    iuplgKey, iuplgpPl, iuplpKey, ipgpCstAgPn, cstaAg, mKey, iuplpSubAg,
                    agSmm, agSmmTtl, agLim, agPct,
                    agMstrngPrsRa, agMstrngAcpRa, agMstrngPrsRaMn, agMstrngAcpRaMn,
                    agMstrngPrsAgFee, agMstrngAcpAgFee, agMstrngPrsAgFeeMn, agMstrngAcpAgFeeMn,
                    agMstrngPrsRalp, agMstrngAcpRalp, agMstrngPrsRalpMn, agMstrngAcpRalpMn,
                    agMstrngAcpStor, agMstrngAcpStorMn, agMstrngAcpControl, agMstrngAcpControlMn,
                    agMstrngAcpMnrl, agMstrngAcpMnrlMn,
                    agMstrngRetRa, agMstrngRetRaMn, agMstrngInPrcRa, agMstrngInPrcRaMn,
                    agMstrngNtArrRa, agMstrngNtArrRaMn, agMstrngPresAllRa, agMstrngPresAllRaMn,
                    agMstrngPresPrvYRa, agMstrngAcpPrvYRa, agMstrngRetPrvYRa, agMstrngInPrcPrvYRa, agMstrngNtArrPrvYRa,
                    agMstrngRetAgFee, agMstrngRetAgFeeMn, agMstrngInPrcAgFee, agMstrngInPrcAgFeeMn,
                    agMstrngNtArrAgFee, agMstrngNtArrAgFeeMn,
                    agMstrngRetRalp, agMstrngRetRalpMn, agMstrngInPrcRalp, agMstrngInPrcRalpMn,
                    agMstrngNtArrRalp, agMstrngNtArrRalpMn,
                    agMasteringPres, agMasteringAccp, agMasteringPresMn, agMasteringAccpMn,
                    agPlanCompleted, agPlanCompletedNot, agPlanCompletedOver, aglimNot, aglimOver,
                    inSmm, inSmmTtl, inLim, inPct,
                    inMstrngPrsRa, inMstrngAcpRa, inMstrngPrsRaMn, inMstrngAcpRaMn,
                    inMstrngPrsAgFee, inMstrngAcpAgFee, inMstrngPrsAgFeeMn, inMstrngAcpAgFeeMn,
                    inMstrngPrsRalp, inMstrngAcpRalp, inMstrngPrsRalpMn, inMstrngAcpRalpMn,
                    inMstrngAcpStor, inMstrngAcpStorMn, inMstrngAcpControl, inMstrngAcpControlMn,
                    inMstrngAcpMnrl, inMstrngAcpMnrlMn,
                    inMstrngRetRa, inMstrngRetRaMn, inMstrngInPrcRa, inMstrngInPrcRaMn,
                    inMstrngNtArrRa, inMstrngNtArrRaMn, inMstrngPresAllRa, inMstrngPresAllRaMn,
                    inMstrngPresPrvYRa, inMstrngAcpPrvYRa, inMstrngRetPrvYRa, inMstrngInPrcPrvYRa, inMstrngNtArrPrvYRa,
                    inMstrngRetAgFee, inMstrngRetAgFeeMn, inMstrngInPrcAgFee, inMstrngInPrcAgFeeMn,
                    inMstrngNtArrAgFee, inMstrngNtArrAgFeeMn,
                    inMstrngRetRalp, inMstrngRetRalpMn, inMstrngInPrcRalp, inMstrngInPrcRalpMn,
                    inMstrngNtArrRalp, inMstrngNtArrRalpMn,
                    inMasteringPres, inMasteringAccp, inMasteringPresMn, inMasteringAccpMn,
                    inPlanCompleted, inPlanCompletedNot, inPlanCompletedOver, inlimNot, inlimOver,
                    drSmm, drSmmTtl, drLim, drPct,
                    drMstrngPrsRa, drMstrngAcpRa, drMstrngPrsRaMn, drMstrngAcpRaMn,
                    drMstrngPrsAgFee, drMstrngAcpAgFee, drMstrngPrsAgFeeMn, drMstrngAcpAgFeeMn,
                    drMstrngPrsRalp, drMstrngAcpRalp, drMstrngPrsRalpMn, drMstrngAcpRalpMn,
                    drMstrngAcpStor, drMstrngAcpStorMn, drMstrngAcpControl, drMstrngAcpControlMn,
                    drMstrngAcpMnrl, drMstrngAcpMnrlMn,
                    drMstrngRetRa, drMstrngRetRaMn, drMstrngInPrcRa, drMstrngInPrcRaMn,
                    drMstrngNtArrRa, drMstrngNtArrRaMn, drMstrngPresAllRa, drMstrngPresAllRaMn,
                    drMstrngPresPrvYRa, drMstrngAcpPrvYRa, drMstrngRetPrvYRa, drMstrngInPrcPrvYRa, drMstrngNtArrPrvYRa,
                    drMstrngRetAgFee, drMstrngRetAgFeeMn, drMstrngInPrcAgFee, drMstrngInPrcAgFeeMn,
                    drMstrngNtArrAgFee, drMstrngNtArrAgFeeMn,
                    drMstrngRetRalp, drMstrngRetRalpMn, drMstrngInPrcRalp, drMstrngInPrcRalpMn,
                    drMstrngNtArrRalp, drMstrngNtArrRalpMn,
                    drMasteringPres, drMasteringAccp, drMasteringPresMn, drMasteringAccpMn,
                    drPlanCompleted, drPlanCompletedNot, drPlanCompletedOver, drlimNot, drlimOver
                )
                SELECT
                    d.dAll, d.ipgcrKey, d.ipgcrChain, d.ipgcrIpg, d.ipgcrUtPlGr, d.ipgpKey, d.ipgpSh,
                    d.iuplgKey, d.iuplgpPl, d.iuplpKey, d.ipgpCstAgPn, d.cstaAg, d.mKey, d.iuplpSubAg,
                    -- ag (нули)
                    NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL,
                    0, 0, 0, 0, 0,
                    -- in (нули)
                    NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, NULL,
                    0, 0, 0, 0, 0,
                    -- dr (освоение)
                    d.smm, d.smmTtl, d.lim, d.pct,
                    d.MstrngPrsRa, d.MstrngAcpRa, d.MstrngPrsRaMn, d.MstrngAcpRaMn,
                    d.MstrngPrsAgFee, d.MstrngAcpAgFee, d.MstrngPrsAgFeeMn, d.MstrngAcpAgFeeMn,
                    d.MstrngPrsRalp, d.MstrngAcpRalp, d.MstrngPrsRalpMn, d.MstrngAcpRalpMn,
                    d.MstrngAcpStor, d.MstrngAcpStorMn, d.MstrngAcpControl, d.MstrngAcpControlMn,
                    d.MstrngAcpMnrl, d.MstrngAcpMnrlMn,
                    d.MstrngRetRa, d.MstrngRetRaMn, d.MstrngInPrcRa, d.MstrngInPrcRaMn,
                    d.MstrngNtArrRa, d.MstrngNtArrRaMn, d.MstrngPresAllRa, d.MstrngPresAllRaMn,
                    d.MstrngPresPrvYRa, d.MstrngAcpPrvYRa, d.MstrngRetPrvYRa, d.MstrngInPrcPrvYRa, d.MstrngNtArrPrvYRa,
                    d.MstrngRetAgFee, d.MstrngRetAgFeeMn, d.MstrngInPrcAgFee, d.MstrngInPrcAgFeeMn,
                    d.MstrngNtArrAgFee, d.MstrngNtArrAgFeeMn,
                    d.MstrngRetRalp, d.MstrngRetRalpMn, d.MstrngInPrcRalp, d.MstrngInPrcRalpMn,
                    d.MstrngNtArrRalp, d.MstrngNtArrRalpMn,
                    d.MasteringPres, d.MasteringAccp, d.MasteringPresMn, d.MasteringAccpMn,
                    d.planCompleted, d.planCompletedNot, d.planCompletedOver, d.limNot, d.limOver
                FROM ags.fnMasteringCstAgPn_2606(@ipgCh, @cstAgPn, 3, @StCostKey, @stNet, @ipgRoot) d;
        END

    RETURN;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'ags.fnMasteringCstAgPnSh_2606') AND minor_id = 0 AND name = N'MS_Description'
)
    EXEC sys.sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'Освоение по стройке с учётом схем реализации (_2606). ipgChRlV + fnMasteringCstAgPn_2606. Обновлено 2026-06-11: LEGACY→_2606, Вариант 6А.',
        @level0type = N'SCHEMA', @level0name = N'ags',
        @level1type = N'FUNCTION', @level1name = N'fnMasteringCstAgPnSh_2606';
GO

PRINT '=== 03c: fnMasteringCstAgPn_2606 / fnMasteringCstAgPnSh_2606 обновлены (Этап 8.3) ===';
GO
