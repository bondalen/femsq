USE [FishEye];
GO

-- =============================================================================
-- Файл:    04b_CREATE_PROCEDURE_spIpgChRsltCstUtl2_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: fn2_2606 как SP с #temp + индексы (Ступень 3, этап 14.3).
--   Логика идентична 04 (MSTVF v9.0); UDF не поддерживает #temp на SQL 2012.
-- Зависимости: 03, 03b, 03c, fnMasteringStIpgStCost_2606, fnIpgChDatsV.
-- Автор:   Александр | Дата: 2026-06-15
-- =============================================================================

PRINT N'=== 04b: CREATE PROCEDURE ags.spIpgChRsltCstUtl2_2606 ===';
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE ags.spIpgChRsltCstUtl2_2606
(
    @ipgChKey   int,
    @ipgStKey   int = NULL,
    @stCostKey  int = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @yKey int, @yyyy int;
    CREATE TABLE #raFact2408 (
        yKey int, mNum int, cstAgPnKey int, typeGr nvarchar(50) COLLATE DATABASE_DEFAULT NOT NULL,
        presentedAll money, presentedAllModul money,
        presented money, accepted money, returned money, inProcess money, notArrived money,
        presentedPrevYears money, acceptedPrevYears money, returnedPrevYears money,
        inProcessPrevYears money, notArrivedPrevYears money
    );
    CREATE TABLE #raFactRalp (
        yKey int, mNum int, cstAgPnKey int, typeGr nvarchar(50) COLLATE DATABASE_DEFAULT NOT NULL,
        presentedRalp money, acceptedRalp money, returnedRalp money,
        inProcessRalp money, notArrivedRalp money
    );
    CREATE TABLE #raFactMnrl (
        yKey int, mNum int, cstAgPnKey int, MnrlSum money
    );
    CREATE TABLE #raFactPrDoc (
        mNum int NOT NULL,
        cstAgPnKey int NOT NULL,
        storageSum money NULL,
        cctSum money NULL,
        PRIMARY KEY (mNum, cstAgPnKey)
    );
    CREATE TABLE #agFeeFact (
        mNum int, cstAgPnKey int,
        agFeePresented money, agFeeAccepted money
    );
    CREATE TABLE #schemeRows (
        ipgpCstAgPn int, dAll date, mNum int, ipgKey int,
        ipgActStr date, ipgActEnd date,
        iShKey int, iShNm nvarchar(100) COLLATE DATABASE_DEFAULT, typeGr nvarchar(50) COLLATE DATABASE_DEFAULT,
        lim money, presented money, accepted money,
        agFeePresented money, agFeeAccepted money,
        presentedRalp money, acceptedRalp money,
        storageSum money, cctSum money, MnrlSum money
    );
    CREATE TABLE #mastMonthEnd (ipgKey int NOT NULL, dAll date NOT NULL);
    CREATE TABLE #branchCache (
        cstapbCstAgPn int NOT NULL PRIMARY KEY,
        branch int NULL
    );

    SELECT @yKey = MIN(y.yKey), @yyyy = MIN(y.yyyy)
    FROM (
        SELECT MAX(y2.yyyy) AS mxY
        FROM ags.ipgChRlV v
        INNER JOIN ags.ipg i ON i.ipgKey = v.ipgcrvIpg
        INNER JOIN ags.yyyy y2 ON y2.yKey = i.ipgYy
        WHERE v.ipgcrvChain = @ipgChKey
    ) x
    INNER JOIN ags.yyyy y ON y.yyyy = x.mxY;

    INSERT INTO #raFact2408
    SELECT
            p.y AS yKey,
            p.m AS mNum,
            r.ra_cac AS cstAgPnKey,
            r.typeGr,
            SUM(r.ras_total) AS presentedAll,
            SUM(ABS(r.ras_total)) AS presentedAllModul,
            SUM(CASE
                WHEN r.complianceY = N'соответствует'
                    OR (r.complianceY = N'не соответствует' AND r.ras_total > 0)
                THEN r.ras_total
            END) AS presented,
            SUM(CASE
                WHEN r.rsltOfConsider = N'sended'
                    AND (r.complianceY = N'соответствует'
                        OR (r.complianceY = N'не соответствует' AND r.ras_total > 0))
                THEN r.ras_total
            END) AS accepted,
            SUM(CASE
                WHEN r.rsltOfConsider = N'returned'
                    AND (r.complianceY = N'соответствует'
                        OR (r.complianceY = N'не соответствует' AND r.ras_total > 0))
                THEN r.ras_total
            END) AS returned,
            SUM(CASE
                WHEN r.rsltOfConsider = N'in process'
                    AND (r.complianceY = N'соответствует'
                        OR (r.complianceY = N'не соответствует' AND r.ras_total > 0))
                THEN r.ras_total
            END) AS inProcess,
            SUM(CASE
                WHEN r.rsltOfConsider = N'not arrived'
                    AND (r.complianceY = N'соответствует'
                        OR (r.complianceY = N'не соответствует' AND r.ras_total > 0))
                THEN r.ras_total
            END) AS notArrived,
            SUM(CASE
                WHEN NOT (r.complianceY = N'соответствует'
                        OR (r.complianceY = N'не соответствует' AND r.ras_total > 0))
                THEN r.ras_total
            END) AS presentedPrevYears,
            SUM(CASE
                WHEN r.rsltOfConsider = N'sended'
                    AND NOT (r.complianceY = N'соответствует'
                        OR (r.complianceY = N'не соответствует' AND r.ras_total > 0))
                THEN r.ras_total
            END) AS acceptedPrevYears,
            SUM(CASE
                WHEN r.rsltOfConsider = N'returned'
                    AND NOT (r.complianceY = N'соответствует'
                        OR (r.complianceY = N'не соответствует' AND r.ras_total > 0))
                THEN r.ras_total
            END) AS returnedPrevYears,
            SUM(CASE
                WHEN r.rsltOfConsider = N'in process'
                    AND NOT (r.complianceY = N'соответствует'
                        OR (r.complianceY = N'не соответствует' AND r.ras_total > 0))
                THEN r.ras_total
            END) AS inProcessPrevYears,
            SUM(CASE
                WHEN r.rsltOfConsider = N'not arrived'
                    AND NOT (r.complianceY = N'соответствует'
                        OR (r.complianceY = N'не соответствует' AND r.ras_total > 0))
                THEN r.ras_total
            END) AS notArrivedPrevYears
        FROM ags.RRcTimeList r
        INNER JOIN ags.ra_period p ON r.ra_period = p.[key]
        WHERE p.y = @yKey
        GROUP BY p.y, r.ra_cac, p.m, r.typeGr;

    INSERT INTO #raFactRalp
    SELECT y.yKey, mm.mNum, p.ralpCstAgPn AS cstAgPnKey, N'1. ОА и Изм.' AS typeGr,
            SUM(p.ralpCostAndVat) AS presentedRalp,
            SUM(CASE WHEN IIF(p.ralpReturned IS NULL,
                    IIF(p.ralpSent IS NULL, IIF(p.ralpArrived IS NULL, N'not arrived', N'in process'), N'sended'),
                    IIF(p.ralpSentDate >= p.ralpReturnedDate, N'sended', N'returned')
                ) = N'sended' THEN p.ralpCostAndVat END) AS acceptedRalp,
            SUM(CASE WHEN IIF(p.ralpReturned IS NULL,
                    IIF(p.ralpSent IS NULL, IIF(p.ralpArrived IS NULL, N'not arrived', N'in process'), N'sended'),
                    IIF(p.ralpSentDate >= p.ralpReturnedDate, N'sended', N'returned')
                ) = N'returned' THEN p.ralpCostAndVat END) AS returnedRalp,
            SUM(CASE WHEN IIF(p.ralpReturned IS NULL,
                    IIF(p.ralpSent IS NULL, IIF(p.ralpArrived IS NULL, N'not arrived', N'in process'), N'sended'),
                    IIF(p.ralpSentDate >= p.ralpReturnedDate, N'sended', N'returned')
                ) = N'in process' THEN p.ralpCostAndVat END) AS inProcessRalp,
            SUM(CASE WHEN IIF(p.ralpReturned IS NULL,
                    IIF(p.ralpSent IS NULL, IIF(p.ralpArrived IS NULL, N'not arrived', N'in process'), N'sended'),
                    IIF(p.ralpSentDate >= p.ralpReturnedDate, N'sended', N'returned')
                ) = N'not arrived' THEN p.ralpCostAndVat END) AS notArrivedRalp
        FROM ags.ralp p
        INNER JOIN ags.yyyy y ON p.ralpY = y.yyyy
        INNER JOIN ags.mmmm mm ON p.ralpM = mm.mNum
        WHERE y.yKey = @yKey
        GROUP BY y.yKey, mm.mNum, p.ralpCstAgPn;

    INSERT INTO #raFactMnrl
    SELECT ym.yKey, mmr.mNum, mr.amCstAgPn AS cstAgPnKey,
            SUM(mr.amSum) AS MnrlSum
        FROM ags.cstAgPnMnrl mr
        INNER JOIN ags.yyyy ym ON YEAR(mr.amPositing) = ym.yyyy
        INNER JOIN ags.mmmm mmr ON MONTH(mr.amPositing) = mmr.mNum
        WHERE ym.yKey = @yKey
        GROUP BY ym.yKey, mmr.mNum, mr.amCstAgPn;

    -- v9.0: один scan cn_PrDocP → storage + cct (вместо двух INSERT)
    INSERT INTO #raFactPrDoc (mNum, cstAgPnKey, storageSum, cctSum)
    SELECT mh.mNum, p.pdpCstAgPn,
            SUM(CASE
                WHEN (d.cnpdTpOrd = 1 OR d.cnpdTpOrd = 2 OR d.cnpdTpOrd = 4)
                     AND p.satstusOfOUKVtext = N'проведено'
                THEN p.costVAT
            END),
            SUM(CASE
                WHEN t.pdtoCode = N'ZUGH' AND p.satstusOfOUKVtext = N'проведено'
                THEN p.costVAT
            END)
        FROM ags.cn_PrDocP p
        INNER JOIN ags.cn_PrDoc d ON p.pdpPrDoc = d.cnpdKey
        INNER JOIN ags.cn_PrDocT t ON d.cnpdTpOrd = t.pdtoKey
        INNER JOIN ags.yyyy yh ON YEAR(p.positingDate) = yh.yyyy
        INNER JOIN ags.mmmm mh ON MONTH(p.positingDate) = mh.mNum
        WHERE yh.yKey = @yKey
          AND (
              (d.cnpdTpOrd = 1 OR d.cnpdTpOrd = 2 OR d.cnpdTpOrd = 4)
              OR t.pdtoCode IN (N'ZKTG', N'ZPTG', N'ZUGH', N'ZKTA')
          )
        GROUP BY mh.mNum, p.pdpCstAgPn;

    INSERT INTO #agFeeFact
    SELECT mm.mNum, p.oafpCstAgPn,
            SUM(p.oafpTotal) AS agFeePresented,
            SUM(CASE WHEN f.oafSent IS NOT NULL AND f.oafSent <> N'' THEN p.oafpTotal END) AS agFeeAccepted
        FROM ags.ogAgFeeP p
        INNER JOIN ags.ogAgFee f ON p.oafpOaf = f.oafKey
        INNER JOIN ags.yyyy y ON f.oafY = y.yKey
        INNER JOIN ags.mmmm mm ON f.oafM = mm.mKey
        WHERE y.yKey = @yKey
          AND p.oafpCstAgPn IS NOT NULL
          AND p.oafpTotal IS NOT NULL AND p.oafpTotal <> 0
        GROUP BY mm.mNum, p.oafpCstAgPn;

    INSERT INTO #mastMonthEnd (ipgKey, dAll)
    SELECT v.ipgcrvIpg AS ipgKey, MAX(d.dAll) AS dAll
    FROM ags.fnIpgChDatsV(@ipgChKey) d
    INNER JOIN ags.ipgChRlV v ON v.ipgcrvChain = @ipgChKey
        AND d.dAll >= v.ipgcrvStr AND (v.ipgcrvEnd IS NULL OR d.dAll <= v.ipgcrvEnd)
    GROUP BY v.ipgcrvIpg, YEAR(d.dAll), MONTH(d.dAll);

    -- v8.1: CTE mastering — ровно 1× вызов StIpgStCost (3× UNION ALL давал 3× re-eval ≈110 с на stIpg=46).
    ;WITH mastering AS (
        SELECT m.*, me.ipgKey, MONTH(me.dAll) AS mNum, v.ipgcrvStr AS ipgActStr, v.ipgcrvEnd AS ipgActEnd
        FROM ags.fnMasteringStIpgStCost_2606(@ipgStKey, @ipgChKey, @stCostKey, NULL) m
        INNER JOIN #mastMonthEnd me ON me.dAll = m.dAll
        INNER JOIN ags.ipgChRlV v ON v.ipgcrvChain = @ipgChKey AND v.ipgcrvIpg = me.ipgKey
    )
    INSERT INTO #schemeRows
    SELECT
        mst.ipgpCstAgPn, mst.dAll, mst.mNum, mst.ipgKey, mst.ipgActStr, mst.ipgActEnd,
        sch.iShKey, sch.iShNm, N'1. ОА и Изм.' AS typeGr,
        sch.lim, sch.presented, sch.accepted,
        sch.agFeePresented, sch.agFeeAccepted,
        sch.presentedRalp, sch.acceptedRalp,
        sch.storageSum, sch.cctSum, sch.MnrlSum
    FROM mastering mst
    CROSS APPLY (VALUES
        (2, N'Агентская',      mst.agLim, mst.agMstrngPrsRaMn, mst.agMstrngAcpRaMn, mst.agMstrngPrsAgFeeMn, mst.agMstrngAcpAgFeeMn, mst.agMstrngPrsRalpMn, mst.agMstrngAcpRalpMn, mst.agMstrngAcpStorMn, mst.agMstrngAcpControlMn, mst.agMstrngAcpMnrlMn),
        (1, N'Инвестиционная',  mst.inLim, mst.inMstrngPrsRaMn, mst.inMstrngAcpRaMn, mst.inMstrngPrsAgFeeMn, mst.inMstrngAcpAgFeeMn, mst.inMstrngPrsRalpMn, mst.inMstrngAcpRalpMn, mst.inMstrngAcpStorMn, mst.inMstrngAcpControlMn, mst.inMstrngAcpMnrlMn),
        (3, N'Иная схема',      mst.drLim, mst.drMstrngPrsRaMn, mst.drMstrngAcpRaMn, mst.drMstrngPrsAgFeeMn, mst.drMstrngAcpAgFeeMn, mst.drMstrngPrsRalpMn, mst.drMstrngAcpRalpMn, mst.drMstrngAcpStorMn, mst.drMstrngAcpControlMn, mst.drMstrngAcpMnrlMn)
    ) AS sch(iShKey, iShNm, lim, presented, accepted, agFeePresented, agFeeAccepted, presentedRalp, acceptedRalp, storageSum, cctSum, MnrlSum)
    WHERE NOT (
        sch.lim IS NULL AND sch.presented IS NULL AND sch.accepted IS NULL
        AND sch.agFeePresented IS NULL AND sch.agFeeAccepted IS NULL
        AND sch.presentedRalp IS NULL AND sch.acceptedRalp IS NULL
        AND sch.storageSum IS NULL AND sch.cctSum IS NULL AND sch.MnrlSum IS NULL
    );


    -- Опционально: индекс #schemeRows (на SQL 2012 prod — seek в allMonthsForIpg)
    CREATE CLUSTERED INDEX IX_schemeRows ON #schemeRows (ipgKey, ipgpCstAgPn, iShKey, mNum);
    CREATE NONCLUSTERED INDEX IX_schemeRows_cpn ON #schemeRows (ipgpCstAgPn);

    INSERT INTO #branchCache (cstapbCstAgPn, branch)
    SELECT b.cstapbCstAgPn, MAX(b.cstapbBranch)
    FROM ags.cstAgPnBranch b
    WHERE (b.cstapbEnd IS NULL OR b.cstapbEnd >= CAST(GETDATE() AS date))
      AND (b.cstapbStart IS NULL OR b.cstapbStart <= CAST(GETDATE() AS date))
    GROUP BY b.cstapbCstAgPn;

    ;WITH ipgPnSchemePts AS (
        SELECT p.ipgpIpg AS ipgKey, p.ipgpCstAgPn, p.ipgpSh AS iShKey
        FROM ags.ipgPn p
        INNER JOIN ags.ipgChRlV v ON v.ipgcrvChain = @ipgChKey AND v.ipgcrvIpg = p.ipgpIpg
        UNION
        SELECT p.ipgpIpg, p.ipgpCstAgPn, 2
        FROM ags.ipgPn p
        INNER JOIN ags.ipgChRlV v ON v.ipgcrvChain = @ipgChKey AND v.ipgcrvIpg = p.ipgpIpg
        WHERE p.ipgpSh = 1
    ),
    -- (ИПГ цепи, стройка) из ipgPn × ipgChRlV — как fn_2408: каждая стройка mastering
    -- реплицируется на все ИПГ цепи (не только ИПГ из mastering-факта).
    ipgMasteringCombos AS (
        SELECT DISTINCT
            v.ipgcrvIpg AS ipgKey,
            v.ipgcrvStr AS ipgActStr,
            v.ipgcrvEnd AS ipgActEnd,
            p.ipgpCstAgPn,
            N'1. ОА и Изм.' AS typeGr
        FROM ags.ipgPn p
        INNER JOIN ags.ipgChRlV v ON v.ipgcrvChain = @ipgChKey AND v.ipgcrvIpg = p.ipgpIpg
        WHERE EXISTS (SELECT 1 FROM #schemeRows sr WHERE sr.ipgpCstAgPn = p.ipgpCstAgPn)
    ),
    -- Уникальные комбинации (ИПГ, стройка, схема) — опорный список для разворота по 12 месяцам.
    -- Схемы берутся из ipgPnSchemePts (паритет fn_2408), а не только из непустых #schemeRows.
    ipgSchemeCombo AS (
        SELECT DISTINCT
            mc.ipgKey, mc.ipgActStr, mc.ipgActEnd, mc.ipgpCstAgPn,
            pt.iShKey,
            CASE pt.iShKey
                WHEN 2 THEN N'Агентская'
                WHEN 1 THEN N'Инвестиционная'
                WHEN 3 THEN N'Иная схема'
            END AS iShNm,
            mc.typeGr,
            CAST(1 AS bit) AS shShow
        FROM ipgMasteringCombos mc
        INNER JOIN ipgPnSchemePts pt
            ON  pt.ipgKey      = mc.ipgKey
            AND pt.ipgpCstAgPn = mc.ipgpCstAgPn
    ),
    -- Годовой лимит на (ИПГ, стройка, схема) — одинаков для всех 12 месяцев (из ipgPn).
    -- Нужен для заполнения pre-period месяцев, где mastering-данных нет.
    ipgSchemeLim AS (
        SELECT ipgKey, ipgpCstAgPn, iShKey, MAX(lim) AS lim
        FROM #schemeRows
        GROUP BY ipgKey, ipgpCstAgPn, iShKey
    ),
    -- Все 12 месяцев × (ИПГ, стройка, схема) — как в fn_2408.
    -- lim — из ipgSchemeLim (постоянен для года); mastering-данные — из #schemeRows (только активные месяцы).
    allMonthsForIpg AS (
        SELECT
            mm.mKey, mm.mNum, mm.mCs, mm.mNm, mm.mQ, mm.mHy,
            c.ipgKey, c.ipgActStr, c.ipgActEnd,
            c.ipgpCstAgPn, c.iShKey, c.iShNm, c.typeGr, c.shShow,
            il.lim,
            sr.presented AS mstrPresented, sr.accepted AS mstrAccepted,
            sr.agFeePresented, sr.agFeeAccepted,
            sr.presentedRalp, sr.acceptedRalp,
            sr.storageSum, sr.cctSum, sr.MnrlSum
        FROM ipgSchemeCombo c
        CROSS JOIN ags.mmmm mm
        LEFT JOIN ipgSchemeLim il
            ON  il.ipgKey       = c.ipgKey
            AND il.ipgpCstAgPn  = c.ipgpCstAgPn
            AND il.iShKey       = c.iShKey
        LEFT JOIN #schemeRows sr
            ON  sr.ipgKey       = c.ipgKey
            AND sr.ipgpCstAgPn  = c.ipgpCstAgPn
            AND sr.iShKey       = c.iShKey
            AND sr.mNum         = mm.mNum
    ),
    -- Полный контрактный универсум для nullIpgBase — inline-версия fnIpgChRsltCst (без вложенного TVF).
    -- Источники: ogAgFee, raFact2408, raFactRalp, cn_PrDocP, ipgPn, raFactMnrl (все 7 как fn_2408).
    -- CROSS JOIN mmmm × ra_typeGr → (cstAgPnKey, mKey, typeGr); DISTINCT убирает дубли.
    ipgChContracts AS (
        SELECT DISTINCT src.cstAgPnKey, mm.mKey, tg.typeGr
        FROM (
            -- агентское вознаграждение
            SELECT p.oafpCstAgPn AS cstAgPnKey
            FROM ags.ogAgFee a
            INNER JOIN (SELECT @yKey AS yKey, @yyyy AS yyyy) ly ON a.oafY = ly.yKey
            INNER JOIN ags.ogAgFeeP p ON a.oafKey = p.oafpOaf
            WHERE p.oafpCstAgPn IS NOT NULL
            UNION
            -- RA-факт (raFact2408 уже фильтрован по году и имеет уникальные cstAgPnKey)
            SELECT DISTINCT cstAgPnKey FROM #raFact2408
            UNION
            -- РАЛП (raFactRalp уже фильтрован по году)
            SELECT DISTINCT cstAgPnKey FROM #raFactRalp
            UNION
            -- хранение / ССК / прочие PrDoc (из #raFactPrDoc — без повторного scan)
            SELECT DISTINCT pd.cstAgPnKey
            FROM #raFactPrDoc pd
            WHERE pd.cstAgPnKey IS NOT NULL
            UNION
            -- стройки из ИПГ цепи
            SELECT ip.ipgpCstAgPn AS cstAgPnKey
            FROM ags.ipgPn ip
            INNER JOIN ags.ipgChRlV v ON v.ipgcrvChain = @ipgChKey AND v.ipgcrvIpg = ip.ipgpIpg
            WHERE ip.ipgpCstAgPn IS NOT NULL
            UNION
            -- ОПИ (raFactMnrl уже фильтрован по году)
            SELECT DISTINCT cstAgPnKey FROM #raFactMnrl
        ) src
        CROSS JOIN ags.mmmm mm
        CROSS JOIN ags.ra_typeGr tg
    ),
    -- Строки с ipgKey=NULL: контрактный универсум как в fn_2408 (fnIpgChRsltCst):
    --   ogAgFee, ra, ralp, cn_PrDocP, ipgPn, cstAgPnMnrl — все 12 мес, ТОЛЬКО typeGr='2...'
    --   Ровно как fn_2408: 968 контрактов × 12 мес × 1 typeGr = 11616 строк.
    --   RA-факт добавляется LEFT JOIN #raFact2408 (NULL для месяцев без данных).
    nullIpgBase AS (
        SELECT
            ly.yKey, ly.yyyy, mm.mKey, mm.mNum, mm.mCs, mm.mNm, mm.mQ, mm.mHy,
            CAST(NULL AS int)           AS ipgKey,
            CAST(NULL AS nvarchar(255)) AS ipgNm,
            CAST(NULL AS date)          AS ipgStr,
            CAST(NULL AS date)          AS ipgEnd,
            ca.cstaInvestor, oa.ogaKey, o.ogNm,
            bc.branch,
            cs.typeGr,
            CAST(NULL AS money)         AS lim,
            CAST(NULL AS int)           AS iShKey,
            CAST(NULL AS nvarchar(100)) AS iShNm,
            CAST(NULL AS nvarchar(255)) AS limPlan,
            cap.cstapIpgPnN AS cstAgPnCode,
            cs.cstAgPnKey,
            rf.presentedAll, rf.presentedAllModul,
            rf.presented, rf.accepted, rf.returned, rf.inProcess, rf.notArrived,
            rf.presentedPrevYears, rf.acceptedPrevYears, rf.returnedPrevYears,
            rf.inProcessPrevYears, rf.notArrivedPrevYears,
            af.agFeePresented,
            af.agFeeAccepted,
            CAST(NULL AS money) AS agFeeReturned,
            CAST(NULL AS money) AS agFeeInProcess,
            CAST(NULL AS money) AS agFeeNotArrived,
            CAST(NULL AS money) AS presentedRalp,
            CAST(NULL AS money) AS acceptedRalp,
            CAST(NULL AS money) AS returnedRalp,
            CAST(NULL AS money) AS inProcessRalp,
            CAST(NULL AS money) AS notArrivedRalp,
            CAST(NULL AS money) AS storageSum,
            CAST(NULL AS money) AS cctSum,
            CAST(NULL AS money) AS MnrlSum
        FROM ipgChContracts cs
        CROSS JOIN (SELECT @yKey AS yKey, @yyyy AS yyyy) ly
        INNER JOIN ags.mmmm mm ON mm.mKey = cs.mKey
        INNER JOIN ags.cstAgPn cap ON cap.cstapKey = cs.cstAgPnKey
        LEFT JOIN #branchCache bc ON bc.cstapbCstAgPn = cap.cstapKey
        INNER JOIN ags.cstAg ca ON ca.cstaKey = cap.cstapCsta
        INNER JOIN ags.ogAg oa ON oa.ogaKey = ca.cstaAg
        INNER JOIN ags.og o ON o.ogKey = oa.ogaOg
        LEFT JOIN #raFact2408 rf
            ON rf.cstAgPnKey = cs.cstAgPnKey
           AND rf.mNum       = mm.mNum
           AND rf.typeGr     = cs.typeGr
        LEFT JOIN #agFeeFact af
            ON af.cstAgPnKey = cs.cstAgPnKey
           AND af.mNum       = mm.mNum
        WHERE cs.typeGr = N'2. ОА, прочие и Изм'

    ),
    ipgBase AS (
        -- Источник: allMonthsForIpg — все 12 мес × (ИПГ, стройка, схема), как в fn_2408
        SELECT ly.yKey, ly.yyyy, u.mKey, u.mNum, u.mCs, u.mNm, u.mQ, u.mHy,
            u.ipgKey, ipg.ipgNm, u.ipgActStr AS ipgStr, u.ipgActEnd AS ipgEnd,
            ca.cstaInvestor, oa.ogaKey, o.ogNm, bc.branch,
            u.typeGr, u.lim, u.iShKey, u.iShNm, CAST(NULL AS nvarchar(255)) AS limPlan,
            cap.cstapIpgPnN AS cstAgPnCode, u.ipgpCstAgPn AS cstAgPnKey,
            IIF(u.iShKey = 2 AND u.shShow = N'true', rf.presentedAll, NULL) AS presentedAll,
            IIF(u.iShKey = 2 AND u.shShow = N'true', rf.presentedAllModul, NULL) AS presentedAllModul,
            IIF(u.iShKey = 2 AND u.shShow = N'true', rf.presented, u.mstrPresented) AS presented,
            IIF(u.iShKey = 2 AND u.shShow = N'true', rf.accepted, u.mstrAccepted) AS accepted,
            IIF(u.iShKey = 2 AND u.shShow = N'true', rf.returned, NULL) AS returned,
            IIF(u.iShKey = 2 AND u.shShow = N'true', rf.inProcess, NULL) AS inProcess,
            IIF(u.iShKey = 2 AND u.shShow = N'true', rf.notArrived, NULL) AS notArrived,
            IIF(u.iShKey = 2 AND u.shShow = N'true', rf.presentedPrevYears, NULL) AS presentedPrevYears,
            IIF(u.iShKey = 2 AND u.shShow = N'true', rf.acceptedPrevYears, NULL) AS acceptedPrevYears,
            IIF(u.iShKey = 2 AND u.shShow = N'true', rf.returnedPrevYears, NULL) AS returnedPrevYears,
            IIF(u.iShKey = 2 AND u.shShow = N'true', rf.inProcessPrevYears, NULL) AS inProcessPrevYears,
            IIF(u.iShKey = 2 AND u.shShow = N'true', rf.notArrivedPrevYears, NULL) AS notArrivedPrevYears,
            u.agFeePresented, u.agFeeAccepted, CAST(NULL AS money) AS agFeeReturned, CAST(NULL AS money) AS agFeeInProcess, CAST(NULL AS money) AS agFeeNotArrived,
            -- РАЛП: из RA-источника (raFactRalp) при shShow='true', как в fn_2408
            IIF(u.shShow = N'true', rr.presentedRalp, NULL) AS presentedRalp,
            IIF(u.shShow = N'true', rr.acceptedRalp,  NULL) AS acceptedRalp,
            IIF(u.shShow = N'true', rr.returnedRalp,  NULL) AS returnedRalp,
            IIF(u.shShow = N'true', rr.inProcessRalp, NULL) AS inProcessRalp,
            IIF(u.shShow = N'true', rr.notArrivedRalp,NULL) AS notArrivedRalp,
            -- Хранение/ССК: cn_PrDocP при shShow (fn_2408 stg/cct), иначе mastering
            IIF(u.shShow = N'true', rfs_ipg.storageSum, u.storageSum) AS storageSum,
            IIF(u.shShow = N'true', rfc_ipg.cctSum,     u.cctSum) AS cctSum,
            -- ОПИ: из RA-источника (raFactMnrl) при shShow='true', как в fn_2408
            IIF(u.shShow = N'true', rm.MnrlSum, NULL) AS MnrlSum
        FROM allMonthsForIpg u  -- u.shShow уже вычислен в ipgSchemeCombo
        CROSS JOIN (SELECT @yKey AS yKey, @yyyy AS yyyy) ly
        INNER JOIN ags.ipg ipg ON ipg.ipgKey = u.ipgKey
        INNER JOIN ags.cstAgPn cap ON cap.cstapKey = u.ipgpCstAgPn
        LEFT JOIN #branchCache bc ON bc.cstapbCstAgPn = cap.cstapKey
        INNER JOIN ags.cstAg ca ON ca.cstaKey = cap.cstapCsta
        INNER JOIN ags.ogAg oa ON oa.ogaKey = ca.cstaAg
        INNER JOIN ags.og o ON o.ogKey = oa.ogaOg
        -- RA-факт (RRc/Ralp/Mnrl) — репликация по mNum на все ИПГ цепи, как fn_2408.
        LEFT JOIN #raFact2408 rf
            ON u.iShKey = 2
           AND rf.cstAgPnKey = u.ipgpCstAgPn
           AND rf.mNum = u.mNum
           AND rf.typeGr = u.typeGr
        LEFT JOIN #raFactRalp rr
            ON rr.cstAgPnKey = u.ipgpCstAgPn
           AND rr.yKey       = ly.yKey
           AND rr.mNum       = u.mNum
           AND rr.typeGr     = u.typeGr
        LEFT JOIN #raFactMnrl rm
            ON rm.cstAgPnKey = u.ipgpCstAgPn
           AND rm.yKey       = ly.yKey
           AND rm.mNum       = u.mNum
        LEFT JOIN #raFactPrDoc rfs_ipg
            ON rfs_ipg.cstAgPnKey = u.ipgpCstAgPn
           AND rfs_ipg.mNum       = u.mNum
        LEFT JOIN #raFactPrDoc rfc_ipg
            ON rfc_ipg.cstAgPnKey = u.ipgpCstAgPn
           AND rfc_ipg.mNum       = u.mNum
    ),
    -- Контракты из fnIpgChRsltCst (typeGr='1...'), которые НЕ в mastering (#schemeRows), но имеют
    -- cstaInvestor = ipg.ipgOg для какой-либо ИПГ цепи — ровно как fn_2408.
    -- Это ~288 контрактов (968 total - 680 mastering). Без lim, iShKey=NULL.
    -- Необходимо чтобы в PercentBrn для этих контрактов ipgCount > 0
    -- (null-IPG строки отфильтровываются), и @dt не получал записей с ipgKey=NULL.
    extraBase AS (
        SELECT
            ly.yKey, ly.yyyy, mm.mKey, mm.mNum, mm.mCs, mm.mNm, mm.mQ, mm.mHy,
            ip.ipgKey, ip.ipgNm, ip.ipgStr, ip.ipgEnd,
            ca.cstaInvestor, oa.ogaKey, o.ogNm,
            bc.branch,
            N'1. ОА и Изм.'             AS typeGr,
            CAST(NULL AS money)         AS lim,
            CAST(NULL AS int)           AS iShKey,
            CAST(NULL AS nvarchar(100)) AS iShNm,
            CAST(NULL AS nvarchar(255)) AS limPlan,
            cap.cstapIpgPnN             AS cstAgPnCode,
            cs.cstAgPnKey,
            rf.presentedAll, rf.presentedAllModul,
            rf.presented, rf.accepted, rf.returned, rf.inProcess, rf.notArrived,
            rf.presentedPrevYears, rf.acceptedPrevYears, rf.returnedPrevYears,
            rf.inProcessPrevYears, rf.notArrivedPrevYears,
            CAST(NULL AS money) AS agFeePresented,
            CAST(NULL AS money) AS agFeeAccepted,
            CAST(NULL AS money) AS agFeeReturned,
            CAST(NULL AS money) AS agFeeInProcess,
            CAST(NULL AS money) AS agFeeNotArrived,
            rrl_e.presentedRalp, rrl_e.acceptedRalp, rrl_e.returnedRalp, rrl_e.inProcessRalp, rrl_e.notArrivedRalp,
            rfs_e.storageSum,
            CAST(NULL AS money) AS cctSum,
            CAST(NULL AS money) AS MnrlSum
        FROM ipgChContracts cs
        CROSS JOIN (SELECT @yKey AS yKey, @yyyy AS yyyy) ly
        INNER JOIN ags.mmmm mm ON mm.mKey = cs.mKey
        INNER JOIN ags.cstAgPn cap ON cap.cstapKey = cs.cstAgPnKey
        LEFT JOIN #branchCache bc ON bc.cstapbCstAgPn = cap.cstapKey
        INNER JOIN ags.cstAg ca  ON ca.cstaKey     = cap.cstapCsta
        INNER JOIN ags.ogAg oa   ON oa.ogaKey       = ca.cstaAg
        INNER JOIN ags.og   o    ON o.ogKey          = oa.ogaOg
        -- назначаем ipgKey через cstaInvestor = ipg.ipgOg (как fn_2408)
        INNER JOIN ags.ipg    ip ON ip.ipgYy = ly.yKey AND ip.ipgOg = ca.cstaInvestor
        INNER JOIN ags.ipgChRl cr ON cr.ipgcrIpg = ip.ipgKey AND cr.ipgcrChain = @ipgChKey
        LEFT JOIN #raFact2408 rf
            ON  rf.cstAgPnKey = cs.cstAgPnKey
            AND rf.mNum       = mm.mNum
            AND rf.typeGr     = N'1. ОА и Изм.'
        LEFT JOIN #raFactRalp rrl_e
            ON  rrl_e.cstAgPnKey = cs.cstAgPnKey
            AND rrl_e.mNum       = mm.mNum
        LEFT JOIN #raFactPrDoc rfs_e
            ON  rfs_e.cstAgPnKey = cs.cstAgPnKey
            AND rfs_e.mNum       = mm.mNum
        WHERE cs.typeGr = N'1. ОА и Изм.'
          -- только не-mastering контракты (не входящие в #schemeRows / ipgPn)
          -- NOT EXISTS вместо NOT IN: NULL в #schemeRows.ipgpCstAgPn не ломает логику
          AND NOT EXISTS (SELECT 1 FROM #schemeRows sr WHERE sr.ipgpCstAgPn = cs.cstAgPnKey)
    ),
    -- masExtraBase: mastering-контракты для ИПГ, в которые они НЕ включены в ipgPn.
    -- fn_2408 генерирует такие строки через cstaInvestor = ipg.ipgOg JOIN.
    -- Для части mastering-контрактов это даёт строки с RA-данными (lim=NULL, iShKey=NULL,
    -- но presented IS NOT NULL и т.п.) — они выживают NOT all-NULL фильтр.
    -- Без masExtraBase эти строки отсутствуют в fn2_2606 → расхождение с proxy05.
    -- NOT all-NULL фильтр в финальном SELECT отсеивает все-NULL строки masExtraBase,
    -- что предотвращает лишние строки в PercentBrn (проблема v3 была в отсутствии этого фильтра).
    masExtraBase AS (
        SELECT
            ly.yKey, ly.yyyy, mm.mKey, mm.mNum, mm.mCs, mm.mNm, mm.mQ, mm.mHy,
            ip.ipgKey, ip.ipgNm, ip.ipgStr, ip.ipgEnd,
            ca.cstaInvestor, oa.ogaKey, o.ogNm,
            bc.branch,
            N'1. ОА и Изм.'             AS typeGr,
            CAST(NULL AS money)         AS lim,
            CAST(NULL AS int)           AS iShKey,
            CAST(NULL AS nvarchar(100)) AS iShNm,
            CAST(NULL AS nvarchar(255)) AS limPlan,
            cap.cstapIpgPnN             AS cstAgPnCode,
            cs.cstAgPnKey,
            rf.presentedAll, rf.presentedAllModul,
            rf.presented, rf.accepted, rf.returned, rf.inProcess, rf.notArrived,
            rf.presentedPrevYears, rf.acceptedPrevYears, rf.returnedPrevYears,
            rf.inProcessPrevYears, rf.notArrivedPrevYears,
            CAST(NULL AS money) AS agFeePresented,
            CAST(NULL AS money) AS agFeeAccepted,
            CAST(NULL AS money) AS agFeeReturned,
            CAST(NULL AS money) AS agFeeInProcess,
            CAST(NULL AS money) AS agFeeNotArrived,
            rrl_m.presentedRalp, rrl_m.acceptedRalp, rrl_m.returnedRalp, rrl_m.inProcessRalp, rrl_m.notArrivedRalp,
            rfs_m.storageSum,
            CAST(NULL AS money) AS cctSum,
            CAST(NULL AS money) AS MnrlSum
        FROM ipgChContracts cs
        CROSS JOIN (SELECT @yKey AS yKey, @yyyy AS yyyy) ly
        INNER JOIN ags.mmmm mm ON mm.mKey = cs.mKey
        INNER JOIN ags.cstAgPn cap ON cap.cstapKey = cs.cstAgPnKey
        LEFT JOIN #branchCache bc ON bc.cstapbCstAgPn = cap.cstapKey
        INNER JOIN ags.cstAg ca  ON ca.cstaKey     = cap.cstapCsta
        INNER JOIN ags.ogAg oa   ON oa.ogaKey       = ca.cstaAg
        INNER JOIN ags.og   o    ON o.ogKey          = oa.ogaOg
        INNER JOIN ags.ipg    ip ON ip.ipgYy = ly.yKey AND ip.ipgOg = ca.cstaInvestor
        INNER JOIN ags.ipgChRl cr ON cr.ipgcrIpg = ip.ipgKey AND cr.ipgcrChain = @ipgChKey
        LEFT JOIN #raFact2408 rf
            ON  rf.cstAgPnKey = cs.cstAgPnKey
            AND rf.mNum       = mm.mNum
            AND rf.typeGr     = N'1. ОА и Изм.'
        LEFT JOIN #raFactRalp rrl_m
            ON  rrl_m.cstAgPnKey = cs.cstAgPnKey
            AND rrl_m.mNum       = mm.mNum
        LEFT JOIN #raFactPrDoc rfs_m
            ON  rfs_m.cstAgPnKey = cs.cstAgPnKey
            AND rfs_m.mNum       = mm.mNum
        WHERE cs.typeGr = N'1. ОА и Изм.'
          -- ТОЛЬКО mastering контракты (входящие в #schemeRows)
          AND EXISTS (SELECT 1 FROM #schemeRows sr WHERE sr.ipgpCstAgPn = cs.cstAgPnKey)
          -- И НЕ-мастирующая ИПГ (ip.ipgKey ≠ той ИПГ, в которую контракт включён в ipgPn)
          AND NOT EXISTS (
              SELECT 1 FROM #schemeRows sr2
              WHERE sr2.ipgpCstAgPn = cs.cstAgPnKey AND sr2.ipgKey = ip.ipgKey
          )
    ),
    base AS (
        SELECT * FROM ipgBase
        UNION ALL
        SELECT * FROM masExtraBase
        UNION ALL
        SELECT * FROM extraBase
        UNION ALL
        SELECT * FROM nullIpgBase
    ),
    withAccum AS (
        SELECT b.*,
            SUM(b.presentedAll) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS presentedAllAccum,
            SUM(b.presented) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS presentedAccum,
            SUM(b.accepted) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS acceptedAccum,
            SUM(b.returned) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS returnedAccum,
            SUM(b.inProcess) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS inProcessAccum,
            SUM(b.notArrived) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS notArrivedAccum,
            SUM(b.presentedPrevYears) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS presentedPrevYearsAccum,
            SUM(b.acceptedPrevYears) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS acceptedPrevYearsAccum,
            SUM(b.returnedPrevYears) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS returnedPrevYearsAccum,
            SUM(b.inProcessPrevYears) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS inProcessPrevYearsAccum,
            SUM(b.notArrivedPrevYears) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS notArrivedPrevYearsAccum,
            SUM(b.agFeePresented) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS agFeePresentedAccum,
            SUM(b.agFeeAccepted) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS agFeeAcceptedAccum,
            SUM(b.agFeeReturned) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS agFeeReturnedAccum,
            SUM(b.agFeeInProcess) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS agFeeInProcessAccum,
            SUM(b.agFeeNotArrived) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS agFeeNotArrivedAccum,
            SUM(b.presentedRalp) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS presentedRalpAccum,
            SUM(b.acceptedRalp) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS acceptedRalpAccum,
            SUM(b.returnedRalp) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS returnedRalpAccum,
            SUM(b.inProcessRalp) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS inProcessRalpAccum,
            SUM(b.notArrivedRalp) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS notArrivedRalpAccum,
            SUM(b.storageSum) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS storageSumAccum,
            SUM(b.cctSum) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS cctSumAccum,
            SUM(b.MnrlSum) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS MnrlSumAccum,
            CAST(NULL AS money) AS presentedAllModulAccum
        FROM base b
    )
    SELECT
        asd.yKey, asd.yyyy, asd.mKey, asd.mNum, asd.mCs, asd.mNm, asd.mQ, asd.mHy,
        asd.ipgKey, asd.ipgNm, asd.ipgStr, asd.ipgEnd, asd.cstaInvestor, asd.ogaKey, asd.ogNm,
        ISNULL(asd.branch, 0) AS branch, asd.typeGr
    , IIF(asd.ipgKey IS NULL,
            IIF(asd.typeGr = N'2. ОА, прочие и Изм', N'4. Прочие',
                IIF(asd.typeGr = N'1. ОА и Изм.', N'2.2. Агентская, неплан', NULL)),
            IIF(asd.iShKey IS NULL, N'2.2. Агентская, неплан',
                IIF(asd.iShKey = 2,
                    IIF(asd.lim IS NULL, N'1.2. Инв. (Аг., неплан)', N'2. Агентская, план'),
                    IIF(asd.iShKey = 1, N'1. Инвестиционная', N'3. Неизвестная схема'))))
        AS typeGrTtl
    , asd.lim, asd.iShKey, asd.iShNm, asd.limPlan, asd.cstAgPnCode, asd.cstAgPnKey
    , asd.presentedAll, asd.presentedAllAccum, asd.presentedAllModul, asd.presentedAllModulAccum
    , asd.presented, asd.presentedAccum, asd.accepted, asd.acceptedAccum, asd.returned, asd.returnedAccum
    , asd.inProcess, asd.inProcessAccum, asd.notArrived, asd.notArrivedAccum
    , asd.presentedPrevYears, asd.presentedPrevYearsAccum, asd.acceptedPrevYears, asd.acceptedPrevYearsAccum
    , asd.returnedPrevYears, asd.returnedPrevYearsAccum, asd.inProcessPrevYears, asd.inProcessPrevYearsAccum
    , asd.notArrivedPrevYears, asd.notArrivedPrevYearsAccum
    , asd.agFeePresented, asd.agFeePresentedAccum, asd.agFeeAccepted, asd.agFeeAcceptedAccum
    , asd.agFeeReturned, asd.agFeeReturnedAccum, asd.agFeeInProcess, asd.agFeeInProcessAccum
    , asd.agFeeNotArrived, asd.agFeeNotArrivedAccum
    , asd.presentedRalp, asd.presentedRalpAccum, asd.acceptedRalp, asd.acceptedRalpAccum
    , asd.returnedRalp, asd.returnedRalpAccum, asd.inProcessRalp, asd.inProcessRalpAccum
    , asd.notArrivedRalp, asd.notArrivedRalpAccum
    , asd.storageSum, asd.storageSumAccum, asd.cctSum, asd.cctSumAccum, asd.MnrlSum, asd.MnrlSumAccum

    -- всего представлено за месяц из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
    -- Ну и ещё суммы хранения, строительного контроля и ОПИ, которые не делятся на представленные и принятые
    , iif 
        (
            asd.presented is null and asd.agFeePresented is null and asd.presentedRalp is null 
                and asd.storageSum is null and asd.cctSum is null and asd.MnrlSum is null,
            null,
            isnull(asd.presented, 0) + isnull(asd.agFeePresented, 0) + isnull(asd.presentedRalp, 0) 
                + isnull(asd.storageSum, 0) + isnull(asd.cctSum, 0) + isnull(asd.MnrlSum, 0) 
        ) as presentedTtl
    -- всего представлено нарастающим итогом с начала года из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
    -- Ну и ещё суммы хранения, строительного контроля и ОПИ, которые не делятся на представленные и принятые
    , iif
        (
            asd.presentedAccum is null and asd.agFeePresentedAccum is null and asd.presentedRalpAccum is null 
                and asd.storageSumAccum is null and asd.cctSumAccum is null and asd.MnrlSumAccum is null,
            null,
            isnull(asd.presentedAccum, 0) + isnull(asd.agFeePresentedAccum, 0) + isnull(asd.presentedRalpAccum, 0) 
                + isnull(asd.storageSumAccum, 0) + isnull(asd.cctSumAccum, 0) + isnull(asd.MnrlSumAccum, 0) 
        ) as presentedTtlAccum

    -- Но как же распределилось представленное? :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    -- принято с учётом находящегося *на рассмотрении* ..............................................................................................
    -- всего принято с учётом находящегося *на рассмотрении* за месяц из разных истчников. Это ОА, агентское вознаграждение, земельные участки. не делятся на представленные и принятые
    , iif
        (
            asd.accepted is null and asd.agFeeAccepted is null and asd.acceptedRalp is null 
                and asd.storageSum is null and asd.cctSum is null and asd.MnrlSum is null
                and asd.inProcess is null and asd.agFeeInProcess is null and asd.inProcessRalp is null,
            null,
            isnull(asd.accepted, 0) + isnull(asd.agFeeAccepted, 0) + isnull(asd.acceptedRalp, 0) 
                + isnull(asd.storageSum, 0) + isnull(asd.cctSum, 0) + isnull(asd.MnrlSum, 0)
                + isnull(asd.inProcess, 0) + isnull(asd.agFeeInProcess, 0) + isnull(asd.inProcessRalp, 0) 
        ) as acceptedAndInProcessTtl
    -- всего принято с учётом находящегося *на рассмотрении* нарастающим итогом с начала года из разных истчников. 
    -- Это ОА, агентское вознаграждение, земельные участки.
    -- Ну и ещё суммы хранения, строительного контроля и ОПИ, которые не делятся на представленные и принятые
    , iif
        (
            asd.acceptedAccum is null and asd.agFeeAcceptedAccum is null and asd.acceptedRalpAccum is null 
                and asd.storageSumAccum is null and asd.cctSumAccum is null and asd.MnrlSumAccum is null
                and asd.inProcessAccum is null and asd.agFeeInProcessAccum is null and asd.inProcessRalpAccum is null,
            null,
            isnull(asd.acceptedAccum, 0) + isnull(asd.agFeeAcceptedAccum, 0) + isnull(asd.acceptedRalpAccum, 0) 
                + isnull(asd.storageSumAccum, 0) + isnull(asd.cctSumAccum, 0) + isnull(asd.MnrlSumAccum, 0)
                + isnull(asd.inProcessAccum, 0) + isnull(asd.agFeeInProcessAccum, 0) + isnull(asd.inProcessRalpAccum, 0)
        ) as acceptedAndInProcessTtlAccum
    -- принято с учётом находящегося *на рассмотрении*. Окончание ...................................................................................

    -- принято ......................................................................................................................................
    -- всего принято за месяц из разных истчников. Это ОА, агентское вознаграждение, земельные участки.ния, строительного контроля и ОПИ, которые не делятся на представленные и принятые
    , iif
        (
            asd.accepted is null and asd.agFeeAccepted is null and asd.acceptedRalp is null 
                and asd.storageSum is null and asd.cctSum is null and asd.MnrlSum is null,
            null,
            isnull(asd.accepted, 0) + isnull(asd.agFeeAccepted, 0) + isnull(asd.acceptedRalp, 0) 
                + isnull(asd.storageSum, 0) + isnull(asd.cctSum, 0) + isnull(asd.MnrlSum, 0) 
        ) as acceptedTtl
    -- всего принято нарастающим итогом с начала года из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
    -- Ну и ещё суммы хранения, строительного контроля и ОПИ, которые не делятся на представленные и принятые
    , iif
        (
            asd.acceptedAccum is null and asd.agFeeAcceptedAccum is null and asd.acceptedRalpAccum is null 
                and asd.storageSumAccum is null and asd.cctSumAccum is null and asd.MnrlSumAccum is null,
            null,
            isnull(asd.acceptedAccum, 0) + isnull(asd.agFeeAcceptedAccum, 0) + isnull(asd.acceptedRalpAccum, 0) 
                + isnull(asd.storageSumAccum, 0) + isnull(asd.cctSumAccum, 0) + isnull(asd.MnrlSumAccum, 0) 
        ) as acceptedTtlAccum
    -- принято. Окончание ...........................................................................................................................

    -- возвращено ...................................................................................................................................
    -- всего возвращено за месяц из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
    , iif
        (
            asd.returned is null and asd.agFeeReturned is null and asd.returnedRalp is null,
            null,
            isnull(asd.returned, 0) + isnull(asd.agFeeReturned, 0) + isnull(asd.returnedRalp, 0) 
        ) as returnedTtl
    -- всего возвращено нарастающим итогом с начала года из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
    , iif
        (
            asd.returnedAccum is null and asd.agFeeReturnedAccum is null and asd.returnedRalpAccum is null,
            null,
            isnull(asd.returnedAccum, 0) + isnull(asd.agFeeReturnedAccum, 0) + isnull(asd.returnedRalpAccum, 0) 
        ) as returnedTtlAccum
    -- возвращено. Окончание ........................................................................................................................

    -- на рассмотрении ..............................................................................................................................
    -- всего *рассматривается* за месяц из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
    , iif
        (
            asd.inProcess is null and asd.agFeeInProcess is null and asd.inProcessRalp is null,
            null,
            isnull(asd.inProcess, 0) + isnull(asd.agFeeInProcess, 0) + isnull(asd.inProcessRalp, 0) 
        ) as inProcessTtl
    -- всего *рассматривается* нарастающим итогом с начала года из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
    , iif
        (
            asd.inProcessAccum is null and asd.agFeeInProcessAccum is null and asd.inProcessRalpAccum is null,
            null,
            isnull(asd.inProcessAccum, 0) + isnull(asd.agFeeInProcessAccum, 0) + isnull(asd.inProcessRalpAccum, 0) 
        ) as inProcessTtlAccum
    -- на рассмотрении. Окончание ...................................................................................................................

    -- не поступало .................................................................................................................................
    -- всего *не поступало* за месяц из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
    , iif
        (
            asd.notArrived is null and asd.agFeeNotArrived is null and asd.notArrivedRalp is null,
            null,
            isnull(asd.notArrived, 0) + isnull(asd.agFeeNotArrived, 0) + isnull(asd.notArrivedRalp, 0) 
        ) as notArrivedTtl
    -- всего *не поступало* нарастающим итогом с начала года из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
    , iif
        (
            asd.notArrivedAccum is null and asd.agFeeNotArrivedAccum is null and asd.notArrivedRalpAccum is null,
            null,
            isnull(asd.notArrivedAccum, 0) + isnull(asd.agFeeNotArrivedAccum, 0) + isnull(asd.notArrivedRalpAccum, 0) 
        ) as notArrivedTtlAccum
    -- не поступало. Окончание ......................................................................................................................

    -- Но как же распределилось представленное? Окончание :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    -- остаток лимита
    , IIF(asd.lim IS NOT NULL AND asd.lim > 0 AND asd.iShKey = 2,
            asd.lim - (isnull(asd.acceptedAccum, 0) + isnull(asd.agFeeAcceptedAccum, 0) + isnull(asd.acceptedRalpAccum, 0) 
                    + isnull(asd.storageSumAccum, 0) + isnull(asd.cctSumAccum, 0) + isnull(asd.MnrlSumAccum, 0)),
            null
        ) as restOfLimit
    -- остаток лимита с учётом находящегося *на рассмотрении*
    , IIF(asd.lim IS NOT NULL AND asd.lim > 0 AND asd.iShKey = 2,
            asd.lim - (isnull(asd.acceptedAccum, 0) + isnull(asd.agFeeAcceptedAccum, 0) + isnull(asd.acceptedRalpAccum, 0) 
                    + isnull(asd.storageSumAccum, 0) + isnull(asd.cctSumAccum, 0) + isnull(asd.MnrlSumAccum, 0)
                    + isnull(asd.inProcessAccum, 0) + isnull(asd.agFeeInProcessAccum, 0) + isnull(asd.inProcessRalpAccum, 0)
                    ),
            null
        ) as restOfLimitInProcess
    -- процент освоения лимита в целом
    , IIF(asd.lim IS NOT NULL AND asd.lim > 0 AND asd.iShKey = 2,
            (isnull(asd.acceptedAccum, 0) + isnull(asd.agFeeAcceptedAccum, 0) + isnull(asd.acceptedRalpAccum, 0) 
                    + isnull(asd.storageSumAccum, 0) + isnull(asd.cctSumAccum, 0) + isnull(asd.MnrlSumAccum, 0))/asd.lim * 100,
            null
        ) as percentDev
    -- процент освоения лимита в целом с учётом находящегося *на рассмотрении*
    , IIF(asd.lim IS NOT NULL AND asd.lim > 0 AND asd.iShKey = 2,
            (isnull(asd.acceptedAccum, 0) + isnull(asd.agFeeAcceptedAccum, 0) + isnull(asd.acceptedRalpAccum, 0) 
                + isnull(asd.storageSumAccum, 0) + isnull(asd.cctSumAccum, 0) + isnull(asd.MnrlSumAccum, 0)
                + isnull(asd.inProcessAccum, 0) + isnull(asd.agFeeInProcessAccum, 0) + isnull(asd.inProcessRalpAccum, 0)
                ) / asd.lim * 100,
            null
        ) as percentDevInProcess

    FROM withAccum AS asd
    -- MONTH-окно ИПГ: паритет fn2_2605 (строки 296–307 в 01_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2605.sql).
    -- Без него extraBase/masExtraBase дают все 12 мес × ИПГ → лишние записи в PercentBrn @dt (EOMONTH).
    WHERE (
        asd.ipgKey IS NULL
        OR (
            asd.mNum >= IIF(asd.ipgStr IS NULL, 1, IIF(YEAR(asd.ipgStr) <> asd.yyyy, 1, MONTH(asd.ipgStr)))
            AND asd.mNum <= IIF(asd.ipgEnd IS NULL, 12, IIF(YEAR(asd.ipgEnd) <> asd.yyyy, 12, MONTH(asd.ipgEnd)))
        )
    )
    -- Фильтр пустых строк: паритет fn_2408 / fn2_2605 для PercentBrn.
    -- fn_2408 сохраняет строки (ipgKey, iShKey) даже при lim=NULL и всех финансовых NULL
    -- (синтетическая агентская схема при ipgpSh=1).
    -- Тип строки: ipgBase (iShKey), extra/masExtra (iShKey NULL), null-ipg «4. Прочие».
    -- Все три класса — единый NOT all-NULL как fn2_2605 (включая agFee*).
    AND (
        (asd.ipgKey IS NOT NULL AND asd.iShKey IS NOT NULL)
        OR (asd.ipgKey IS NOT NULL AND asd.iShKey IS NULL)
        OR (asd.ipgKey IS NULL AND asd.typeGr = N'2. ОА, прочие и Изм')
    )
    AND NOT (
        asd.lim IS NULL
        AND asd.presentedAll IS NULL AND asd.presentedAllAccum IS NULL
        AND asd.presentedAllModul IS NULL AND asd.presentedAllModulAccum IS NULL
        AND asd.presented IS NULL AND asd.presentedAccum IS NULL
        AND asd.accepted IS NULL AND asd.acceptedAccum IS NULL
        AND asd.returned IS NULL AND asd.returnedAccum IS NULL
        AND asd.inProcess IS NULL AND asd.inProcessAccum IS NULL
        AND asd.notArrived IS NULL AND asd.notArrivedAccum IS NULL
        AND asd.presentedPrevYears IS NULL AND asd.presentedPrevYearsAccum IS NULL
        AND asd.acceptedPrevYears IS NULL AND asd.acceptedPrevYearsAccum IS NULL
        AND asd.returnedPrevYears IS NULL AND asd.returnedPrevYearsAccum IS NULL
        AND asd.inProcessPrevYears IS NULL AND asd.inProcessPrevYearsAccum IS NULL
        AND asd.notArrivedPrevYears IS NULL AND asd.notArrivedPrevYearsAccum IS NULL
        AND asd.agFeePresented IS NULL AND asd.agFeePresentedAccum IS NULL
        AND asd.agFeeAccepted IS NULL AND asd.agFeeAcceptedAccum IS NULL
        AND asd.agFeeReturned IS NULL AND asd.agFeeReturnedAccum IS NULL
        AND asd.agFeeInProcess IS NULL AND asd.agFeeInProcessAccum IS NULL
        AND asd.agFeeNotArrived IS NULL AND asd.agFeeNotArrivedAccum IS NULL
        AND asd.presentedRalp IS NULL AND asd.presentedRalpAccum IS NULL
        AND asd.acceptedRalp IS NULL AND asd.acceptedRalpAccum IS NULL
        AND asd.returnedRalp IS NULL AND asd.returnedRalpAccum IS NULL
        AND asd.inProcessRalp IS NULL AND asd.inProcessRalpAccum IS NULL
        AND asd.notArrivedRalp IS NULL AND asd.notArrivedRalpAccum IS NULL
        AND asd.storageSum IS NULL AND asd.storageSumAccum IS NULL
        AND asd.cctSum IS NULL AND asd.cctSumAccum IS NULL
        AND asd.MnrlSum IS NULL AND asd.MnrlSumAccum IS NULL
    );
END
GO

PRINT N'=== 04b: ags.spIpgChRsltCstUtl2_2606 создана ===';
GO
