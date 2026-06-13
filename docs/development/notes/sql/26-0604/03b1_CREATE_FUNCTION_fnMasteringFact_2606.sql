USE [FishEye];
GO

-- =============================================================================
-- Файл:    03b1_CREATE_FUNCTION_fnMasteringFact_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: П1 — замена LEGACY scalar UDF на _2606-версии через factDocCost.
--   Этап 8.1 (18 шт.): замена LEGACY Pres/Accp — fnStCost* → fnStCost*_2606.
--   Этап 8.2 (25 шт.): новые Ret/InProc/NotArr/PresAll/PrevYears (Вариант 6А).
--   Итого: 43 скалярные функции.
--   Ускорение: ×70–140 (см. 07-performance-analysis.md §3 УМ-1 и §4 П1).
-- Предусловия: 01b–01d (factDocCost заполнен), 03b0 (fnStCost*_2606 созданы).
-- Автор:   Александр
-- Дата:    2026-06-11
-- =============================================================================

PRINT '=== 03b1: CREATE fnMasteringFact*_2606 (43 функции) ===';
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- =============================================================================
-- РАЗДЕЛ 1: RA — Pres/Accp (4 функции)
-- Источник: ags.ra + ags.ra_change
-- fnStCostRa (LEGACY DAG) → fnStCostRa_2606 (factDocCost)
-- fnStCostRaCh (LEGACY DAG) → fnStCostRaCh_2606 (factDocCost)
-- =============================================================================

PRINT '--- 8.1 RA Pres/Accp ---';
GO

-- -----------------------------------------------------------------------------
-- fnMasteringRaCostSet_2606 — set-based ядро RA-группы (этап 9б).
-- @dateMode: 0=год≤dAll, 1=месяц года, 2=все≤dAll, 3=месяц≤dAll, 4=прошлые годы
-- @statusMode: 0=pres, 1=accp, 2=ret, 3=inproc, 4=notarr
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringRaCostSet_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @subAg      int,
    @dateMode   tinyint,
    @statusMode tinyint
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;

    DECLARE @docs TABLE
    (
        ty         nvarchar(20) NULL,
        carrierKey int          NOT NULL,
        isChange   bit          NOT NULL
    );

    INSERT INTO @docs (ty, carrierKey, isChange)
    SELECT NULL, r.ra_key, 0
    FROM ags.ra r
    WHERE r.ra_cac = @cstAgPn
      AND (@subAg = 0 OR r.ra_org_sender = @subAg)
      AND (
            (@dateMode = 0 AND YEAR(@dAll) = YEAR(r.ra_datePeriod) AND @dAll >= r.ra_datePeriod)
         OR (@dateMode = 1 AND YEAR(@dAll) = YEAR(r.ra_datePeriod) AND MONTH(@dAll) = MONTH(r.ra_datePeriod))
         OR (@dateMode = 2 AND @dAll >= r.ra_datePeriod)
         OR (@dateMode = 3 AND MONTH(@dAll) = MONTH(r.ra_datePeriod) AND @dAll >= r.ra_datePeriod)
         OR (@dateMode = 4 AND YEAR(r.ra_datePeriod) < YEAR(@dAll))
      )
      AND (
            (@statusMode = 0)
         OR (@statusMode = 1 AND r.ra_sent IS NOT NULL AND r.ra_sent <> N'')
         OR (@statusMode = 2 AND r.ra_returned IS NOT NULL
             AND (r.ra_sent IS NULL OR r.ra_sent_date < r.ra_returned_date))
         OR (@statusMode = 3 AND r.ra_returned IS NULL AND r.ra_sent IS NULL AND r.ra_arrived IS NOT NULL)
         OR (@statusMode = 4 AND r.ra_returned IS NULL AND r.ra_sent IS NULL AND r.ra_arrived IS NULL)
      )
    UNION ALL
    SELECT
        CASE
            WHEN @dateMode = 4 THEN N'ранние'
            ELSE IIF(YEAR(r.ra_datePeriod) = YEAR(c.rac_datePeriod), N'текущий', N'ранние')
        END,
        c.rac_key,
        1
    FROM ags.ra_change c
    INNER JOIN ags.ra r ON c.raс_ra = r.ra_key
    WHERE r.ra_cac = @cstAgPn
      AND (@subAg = 0 OR c.ra_org_sender = @subAg)
      AND (
            (@dateMode = 0 AND YEAR(@dAll) = YEAR(c.rac_datePeriod) AND @dAll >= c.rac_datePeriod)
         OR (@dateMode = 1 AND YEAR(@dAll) = YEAR(c.rac_datePeriod) AND MONTH(@dAll) = MONTH(c.rac_datePeriod))
         OR (@dateMode = 2 AND @dAll >= c.rac_datePeriod)
         OR (@dateMode = 3 AND MONTH(@dAll) = MONTH(c.rac_datePeriod) AND @dAll >= c.rac_datePeriod)
         OR (@dateMode = 4 AND YEAR(c.rac_datePeriod) < YEAR(@dAll))
      )
      AND (
            (@statusMode = 0)
         OR (@statusMode = 1 AND c.ra_sent IS NOT NULL AND c.ra_sent <> N'')
         OR (@statusMode = 2 AND c.ra_returned IS NOT NULL
             AND (c.ra_sent IS NULL OR c.ra_sent_date < c.ra_returned_date))
         OR (@statusMode = 3 AND c.ra_returned IS NULL AND c.ra_sent IS NULL AND c.ra_arrived IS NOT NULL)
         OR (@statusMode = 4 AND c.ra_returned IS NULL AND c.ra_sent IS NULL AND c.ra_arrived IS NULL)
      );

    DECLARE @withFd TABLE
    (
        ty         nvarchar(20) NULL,
        carrierKey int          NOT NULL,
        isChange   bit          NOT NULL,
        fdKey      int          NULL
    );

    INSERT INTO @withFd (ty, carrierKey, isChange, fdKey)
    SELECT
        d.ty,
        d.carrierKey,
        d.isChange,
        COALESCE(raLs.ras_fdKey, chLs.racs_fdKey)
    FROM @docs d
    LEFT JOIN
    (
        SELECT
            s.ras_ra,
            s.ras_fdKey,
            ROW_NUMBER() OVER (PARTITION BY s.ras_ra ORDER BY s.ras_date DESC, s.ras_key DESC) AS rn
        FROM ags.ra_summ s
        INNER JOIN (SELECT DISTINCT carrierKey FROM @docs WHERE isChange = 0) k ON k.carrierKey = s.ras_ra
    ) raLs ON d.isChange = 0 AND d.carrierKey = raLs.ras_ra AND raLs.rn = 1
    LEFT JOIN
    (
        SELECT
            s.raсs_raс,
            s.racs_fdKey,
            ROW_NUMBER() OVER (PARTITION BY s.raсs_raс ORDER BY s.raсs_date DESC, s.raсs_key DESC) AS rn
        FROM ags.ra_change_summ s
        INNER JOIN (SELECT DISTINCT carrierKey FROM @docs WHERE isChange = 1) k ON k.carrierKey = s.raсs_raс
    ) chLs ON d.isChange = 1 AND d.carrierKey = chLs.raсs_raс AND chLs.rn = 1;

    DECLARE @fdCost TABLE
    (
        fdKey  int   NOT NULL PRIMARY KEY,
        CostSm money NULL
    );

    INSERT INTO @fdCost (fdKey, CostSm)
    SELECT DISTINCT w.fdKey, NULL
    FROM @withFd w
    WHERE w.fdKey IS NOT NULL;

    UPDATE fc
    SET fc.CostSm = d.directSm
    FROM @fdCost fc
    INNER JOIN
    (
        SELECT c.fdcoFd AS fdKey, MAX(c.fdcoSumm) AS directSm
        FROM ags.factDocCost c
        INNER JOIN @fdCost f ON f.fdKey = c.fdcoFd
        WHERE c.fdcoStCost = @StCostKey
        GROUP BY c.fdcoFd
    ) d ON d.fdKey = fc.fdKey;

    UPDATE fc
    SET fc.CostSm = 0
    FROM @fdCost fc
    WHERE fc.CostSm IS NULL
      AND NOT EXISTS (SELECT 1 FROM ags.factDocCost c WHERE c.fdcoFd = fc.fdKey);

    UPDATE fc
    SET fc.CostSm = ags.fnStCostFromFd_2606(fc.fdKey, @StCostKey, @stNet)
    FROM @fdCost fc
    WHERE fc.CostSm IS NULL;

    SELECT @rslt = SUM(fc.CostSm)
    FROM @withFd w
    INNER JOIN @fdCost fc ON w.fdKey = fc.fdKey
    WHERE NOT (w.ty = N'ранние' AND fc.CostSm < 0);

    RETURN @rslt;
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringRaBundle_2606 — все 17 RA-колонок за один проход (этап 9б.2а / P6-RA).
-- Один скан ra/ra_change, batch fdKey, batch direct cost, общий rollup.
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringRaBundle_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @subAg      int
)
RETURNS @r TABLE
(
    MstrngPrsRa        money NULL,
    MstrngAcpRa        money NULL,
    MstrngPrsRaMn      money NULL,
    MstrngAcpRaMn      money NULL,
    MstrngRetRa        money NULL,
    MstrngRetRaMn      money NULL,
    MstrngInPrcRa      money NULL,
    MstrngInPrcRaMn    money NULL,
    MstrngNtArrRa      money NULL,
    MstrngNtArrRaMn    money NULL,
    MstrngPresAllRa    money NULL,
    MstrngPresAllRaMn  money NULL,
    MstrngPresPrvYRa   money NULL,
    MstrngAcpPrvYRa    money NULL,
    MstrngRetPrvYRa    money NULL,
    MstrngInPrcPrvYRa  money NULL,
    MstrngNtArrPrvYRa  money NULL
)
AS
BEGIN
    IF @cstAgPn IS NULL
        RETURN;

    DECLARE @docs TABLE
    (
        isChange       bit          NOT NULL,
        tyChange       nvarchar(20) NULL,
        datePeriod     date         NOT NULL,
        stAccp         bit          NOT NULL,
        stRet          bit          NOT NULL,
        stInProc       bit          NOT NULL,
        stNotArr       bit          NOT NULL,
        carrierKey     int          NOT NULL,
        fdKey          int          NULL,
        CostSm         money        NULL
    );

    INSERT INTO @docs
    (
        isChange, tyChange, datePeriod,
        stAccp, stRet, stInProc, stNotArr,
        carrierKey, fdKey
    )
    SELECT
        0,
        NULL,
        r.ra_datePeriod,
        CASE WHEN r.ra_sent IS NOT NULL AND r.ra_sent <> N'' THEN 1 ELSE 0 END,
        CASE WHEN r.ra_returned IS NOT NULL
                  AND (r.ra_sent IS NULL OR r.ra_sent_date < r.ra_returned_date) THEN 1 ELSE 0 END,
        CASE WHEN r.ra_returned IS NULL AND r.ra_sent IS NULL AND r.ra_arrived IS NOT NULL THEN 1 ELSE 0 END,
        CASE WHEN r.ra_returned IS NULL AND r.ra_sent IS NULL AND r.ra_arrived IS NULL THEN 1 ELSE 0 END,
        r.ra_key,
        NULL
    FROM ags.ra r
    WHERE r.ra_cac = @cstAgPn
      AND (@subAg = 0 OR r.ra_org_sender = @subAg)
    UNION ALL
    SELECT
        1,
        IIF(YEAR(r.ra_datePeriod) = YEAR(c.rac_datePeriod), N'текущий', N'ранние'),
        c.rac_datePeriod,
        CASE WHEN c.ra_sent IS NOT NULL AND c.ra_sent <> N'' THEN 1 ELSE 0 END,
        CASE WHEN c.ra_returned IS NOT NULL
                  AND (c.ra_sent IS NULL OR c.ra_sent_date < c.ra_returned_date) THEN 1 ELSE 0 END,
        CASE WHEN c.ra_returned IS NULL AND c.ra_sent IS NULL AND c.ra_arrived IS NOT NULL THEN 1 ELSE 0 END,
        CASE WHEN c.ra_returned IS NULL AND c.ra_sent IS NULL AND c.ra_arrived IS NULL THEN 1 ELSE 0 END,
        c.rac_key,
        NULL
    FROM ags.ra_change c
    INNER JOIN ags.ra r ON c.raс_ra = r.ra_key
    WHERE r.ra_cac = @cstAgPn
      AND (@subAg = 0 OR c.ra_org_sender = @subAg);

    UPDATE d
    SET fdKey = COALESCE(raLs.ras_fdKey, chLs.racs_fdKey)
    FROM @docs d
    LEFT JOIN
    (
        SELECT
            s.ras_ra,
            s.ras_fdKey,
            ROW_NUMBER() OVER (PARTITION BY s.ras_ra ORDER BY s.ras_date DESC, s.ras_key DESC) AS rn
        FROM ags.ra_summ s
        INNER JOIN (SELECT DISTINCT carrierKey FROM @docs WHERE isChange = 0) k ON k.carrierKey = s.ras_ra
    ) raLs ON d.isChange = 0 AND d.carrierKey = raLs.ras_ra AND raLs.rn = 1
    LEFT JOIN
    (
        SELECT
            s.raсs_raс,
            s.racs_fdKey,
            ROW_NUMBER() OVER (PARTITION BY s.raсs_raс ORDER BY s.raсs_date DESC, s.raсs_key DESC) AS rn
        FROM ags.ra_change_summ s
        INNER JOIN (SELECT DISTINCT carrierKey FROM @docs WHERE isChange = 1) k ON k.carrierKey = s.raсs_raс
    ) chLs ON d.isChange = 1 AND d.carrierKey = chLs.raсs_raс AND chLs.rn = 1;

    DECLARE @fdCost TABLE
    (
        fdKey  int   NOT NULL PRIMARY KEY,
        CostSm money NULL
    );

    INSERT INTO @fdCost (fdKey, CostSm)
    SELECT DISTINCT d.fdKey, NULL
    FROM @docs d
    WHERE d.fdKey IS NOT NULL;

    UPDATE fc
    SET fc.CostSm = x.directSm
    FROM @fdCost fc
    INNER JOIN
    (
        SELECT c.fdcoFd AS fdKey, MAX(c.fdcoSumm) AS directSm
        FROM ags.factDocCost c
        INNER JOIN @fdCost f ON f.fdKey = c.fdcoFd
        WHERE c.fdcoStCost = @StCostKey
        GROUP BY c.fdcoFd
    ) x ON x.fdKey = fc.fdKey;

    UPDATE fc
    SET fc.CostSm = 0
    FROM @fdCost fc
    WHERE fc.CostSm IS NULL
      AND NOT EXISTS (SELECT 1 FROM ags.factDocCost c WHERE c.fdcoFd = fc.fdKey);

    UPDATE fc
    SET fc.CostSm = ags.fnStCostFromFd_2606(fc.fdKey, @StCostKey, @stNet)
    FROM @fdCost fc
    WHERE fc.CostSm IS NULL;

    UPDATE d
    SET CostSm = fc.CostSm
    FROM @docs d
    INNER JOIN @fdCost fc ON d.fdKey = fc.fdKey;

    INSERT INTO @r
    (
        MstrngPrsRa, MstrngAcpRa, MstrngPrsRaMn, MstrngAcpRaMn,
        MstrngRetRa, MstrngRetRaMn, MstrngInPrcRa, MstrngInPrcRaMn,
        MstrngNtArrRa, MstrngNtArrRaMn, MstrngPresAllRa, MstrngPresAllRaMn,
        MstrngPresPrvYRa, MstrngAcpPrvYRa, MstrngRetPrvYRa, MstrngInPrcPrvYRa, MstrngNtArrPrvYRa
    )
    SELECT
        SUM(CASE WHEN z.dfYLe = 1 AND z.exclNorm = 0 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYLe = 1 AND z.stAccp = 1 AND z.exclNorm = 0 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYM = 1 AND z.exclNorm = 0 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYM = 1 AND z.stAccp = 1 AND z.exclNorm = 0 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYLe = 1 AND z.stRet = 1 AND z.exclNorm = 0 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYM = 1 AND z.stRet = 1 AND z.exclNorm = 0 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYLe = 1 AND z.stInProc = 1 AND z.exclNorm = 0 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYM = 1 AND z.stInProc = 1 AND z.exclNorm = 0 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYLe = 1 AND z.stNotArr = 1 AND z.exclNorm = 0 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYM = 1 AND z.stNotArr = 1 AND z.exclNorm = 0 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfLe = 1 AND z.exclNorm = 0 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfMLe = 1 AND z.exclNorm = 0 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfPrvY = 1 AND z.exclPrvY = 0 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfPrvY = 1 AND z.stAccp = 1 AND z.exclPrvY = 0 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfPrvY = 1 AND z.stRet = 1 AND z.exclPrvY = 0 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfPrvY = 1 AND z.stInProc = 1 AND z.exclPrvY = 0 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfPrvY = 1 AND z.stNotArr = 1 AND z.exclPrvY = 0 THEN z.CostSm ELSE 0 END)
    FROM
    (
        SELECT
            doc.*,
            CASE WHEN YEAR(@dAll) = YEAR(doc.datePeriod) AND @dAll >= doc.datePeriod THEN 1 ELSE 0 END AS dfYLe,
            CASE WHEN YEAR(@dAll) = YEAR(doc.datePeriod) AND MONTH(@dAll) = MONTH(doc.datePeriod) THEN 1 ELSE 0 END AS dfYM,
            CASE WHEN @dAll >= doc.datePeriod THEN 1 ELSE 0 END AS dfLe,
            CASE WHEN MONTH(@dAll) = MONTH(doc.datePeriod) AND @dAll >= doc.datePeriod THEN 1 ELSE 0 END AS dfMLe,
            CASE WHEN YEAR(doc.datePeriod) < YEAR(@dAll) THEN 1 ELSE 0 END AS dfPrvY,
            CASE WHEN doc.isChange = 1 AND doc.tyChange = N'ранние' AND doc.CostSm < 0 THEN 1 ELSE 0 END AS exclNorm,
            CASE WHEN doc.isChange = 1 AND doc.CostSm < 0 THEN 1 ELSE 0 END AS exclPrvY
        FROM @docs doc
        WHERE doc.CostSm IS NOT NULL
    ) z;

    RETURN;
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringRaCostBase_2606 — строки RA с CostSm (без @dAll); кэш на вызов CstAgPn.
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringRaCostBase_2606
(
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS @t TABLE
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
)
AS
BEGIN
    IF @cstAgPn IS NULL
        RETURN;

    DECLARE @docs TABLE
    (
        orgSender  int          NULL,
        isChange   bit          NOT NULL,
        tyChange   nvarchar(20) NULL,
        datePeriod date         NOT NULL,
        stAccp     bit          NOT NULL,
        stRet      bit          NOT NULL,
        stInProc   bit          NOT NULL,
        stNotArr   bit          NOT NULL,
        carrierKey int          NOT NULL,
        fdKey      int          NULL,
        CostSm     money        NULL
    );

    INSERT INTO @docs
    (
        orgSender, isChange, tyChange, datePeriod,
        stAccp, stRet, stInProc, stNotArr, carrierKey, fdKey
    )
    SELECT
        r.ra_org_sender, 0, NULL, r.ra_datePeriod,
        CASE WHEN r.ra_sent IS NOT NULL AND r.ra_sent <> N'' THEN 1 ELSE 0 END,
        CASE WHEN r.ra_returned IS NOT NULL
                  AND (r.ra_sent IS NULL OR r.ra_sent_date < r.ra_returned_date) THEN 1 ELSE 0 END,
        CASE WHEN r.ra_returned IS NULL AND r.ra_sent IS NULL AND r.ra_arrived IS NOT NULL THEN 1 ELSE 0 END,
        CASE WHEN r.ra_returned IS NULL AND r.ra_sent IS NULL AND r.ra_arrived IS NULL THEN 1 ELSE 0 END,
        r.ra_key, NULL
    FROM ags.ra r
    WHERE r.ra_cac = @cstAgPn
    UNION ALL
    SELECT
        c.ra_org_sender, 1,
        IIF(YEAR(r.ra_datePeriod) = YEAR(c.rac_datePeriod), N'текущий', N'ранние'),
        c.rac_datePeriod,
        CASE WHEN c.ra_sent IS NOT NULL AND c.ra_sent <> N'' THEN 1 ELSE 0 END,
        CASE WHEN c.ra_returned IS NOT NULL
                  AND (c.ra_sent IS NULL OR c.ra_sent_date < c.ra_returned_date) THEN 1 ELSE 0 END,
        CASE WHEN c.ra_returned IS NULL AND c.ra_sent IS NULL AND c.ra_arrived IS NOT NULL THEN 1 ELSE 0 END,
        CASE WHEN c.ra_returned IS NULL AND c.ra_sent IS NULL AND c.ra_arrived IS NULL THEN 1 ELSE 0 END,
        c.rac_key, NULL
    FROM ags.ra_change c
    INNER JOIN ags.ra r ON c.raс_ra = r.ra_key
    WHERE r.ra_cac = @cstAgPn;

    UPDATE d
    SET fdKey = COALESCE(raLs.ras_fdKey, chLs.racs_fdKey)
    FROM @docs d
    LEFT JOIN
    (
        SELECT s.ras_ra, s.ras_fdKey,
            ROW_NUMBER() OVER (PARTITION BY s.ras_ra ORDER BY s.ras_date DESC, s.ras_key DESC) AS rn
        FROM ags.ra_summ s
        INNER JOIN (SELECT DISTINCT carrierKey FROM @docs WHERE isChange = 0) k ON k.carrierKey = s.ras_ra
    ) raLs ON d.isChange = 0 AND d.carrierKey = raLs.ras_ra AND raLs.rn = 1
    LEFT JOIN
    (
        SELECT s.raсs_raс, s.racs_fdKey,
            ROW_NUMBER() OVER (PARTITION BY s.raсs_raс ORDER BY s.raсs_date DESC, s.raсs_key DESC) AS rn
        FROM ags.ra_change_summ s
        INNER JOIN (SELECT DISTINCT carrierKey FROM @docs WHERE isChange = 1) k ON k.carrierKey = s.raсs_raс
    ) chLs ON d.isChange = 1 AND d.carrierKey = chLs.raсs_raс AND chLs.rn = 1;

    DECLARE @fdCost TABLE (fdKey int NOT NULL PRIMARY KEY, CostSm money NULL);

    INSERT INTO @fdCost (fdKey, CostSm)
    SELECT DISTINCT d.fdKey, NULL FROM @docs d WHERE d.fdKey IS NOT NULL;

    UPDATE fc SET fc.CostSm = x.directSm
    FROM @fdCost fc
    INNER JOIN (
        SELECT c.fdcoFd AS fdKey, MAX(c.fdcoSumm) AS directSm
        FROM ags.factDocCost c
        INNER JOIN @fdCost f ON f.fdKey = c.fdcoFd
        WHERE c.fdcoStCost = @StCostKey
        GROUP BY c.fdcoFd
    ) x ON x.fdKey = fc.fdKey;

    UPDATE fc SET fc.CostSm = 0
    FROM @fdCost fc
    WHERE fc.CostSm IS NULL
      AND NOT EXISTS (SELECT 1 FROM ags.factDocCost c WHERE c.fdcoFd = fc.fdKey);

    UPDATE fc SET fc.CostSm = ags.fnStCostFromFd_2606(fc.fdKey, @StCostKey, @stNet)
    FROM @fdCost fc WHERE fc.CostSm IS NULL;

    UPDATE d SET CostSm = fc.CostSm
    FROM @docs d INNER JOIN @fdCost fc ON d.fdKey = fc.fdKey;

    INSERT INTO @t
    SELECT orgSender, isChange, tyChange, datePeriod, stAccp, stRet, stInProc, stNotArr, ISNULL(CostSm, 0)
    FROM @docs WHERE CostSm IS NOT NULL;

    RETURN;
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringAgFeeCostBase_2606 — строки АВ с CostSm (без @dAll).
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringAgFeeCostBase_2606
(
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS @t TABLE
(
    mEnd     date  NOT NULL,
    stAccp   bit   NOT NULL,
    stRet    bit   NOT NULL,
    stInProc bit   NOT NULL,
    stNotArr bit   NOT NULL,
    CostSm   money NOT NULL
)
AS
BEGIN
    IF @cstAgPn IS NULL
        RETURN;

    DECLARE @stCostOgAgFee int = 148;
    DECLARE @dagHit bit = 0;
    IF @StCostKey = @stCostOgAgFee SET @dagHit = 1;
    ELSE IF EXISTS (SELECT 1 FROM ags.fnStUpAll(@stNet, @stCostOgAgFee) u WHERE u.strParent = @StCostKey) SET @dagHit = 1;

    DECLARE @docs TABLE
    (
        oafpKey int NOT NULL, mEnd date NOT NULL,
        stAccp bit NOT NULL, stRet bit NOT NULL, stInProc bit NOT NULL, stNotArr bit NOT NULL,
        CostSm money NOT NULL
    );

    INSERT INTO @docs
    SELECT p.oafpKey, EOMONTH(DATEFROMPARTS(y.yyyy, m.mNum, 1)),
        CASE WHEN f.oafSent IS NOT NULL AND f.oafSent <> N'' THEN 1 ELSE 0 END,
        CASE WHEN f.oafReturned IS NOT NULL AND (f.oafSent IS NULL OR f.oafSentDate < f.oafReturnedDate) THEN 1 ELSE 0 END,
        CASE WHEN f.oafReturned IS NULL AND f.oafSent IS NULL AND f.oafArrived IS NOT NULL THEN 1 ELSE 0 END,
        CASE WHEN f.oafReturned IS NULL AND f.oafSent IS NULL AND f.oafArrived IS NULL THEN 1 ELSE 0 END,
        0
    FROM ags.ogAgFeeP p
    INNER JOIN ags.ogAgFee f ON p.oafpOaf = f.oafKey
    INNER JOIN ags.yyyy y ON f.oafY = y.yKey
    INNER JOIN ags.mmmm m ON f.oafM = m.mKey
    WHERE p.oafpCstAgPn = @cstAgPn AND p.oafpTotal IS NOT NULL AND p.oafpTotal <> 0;

    IF @dagHit = 1
        UPDATE d SET CostSm = ISNULL(s.simpleSum, 0)
        FROM @docs d
        INNER JOIN (
            SELECT p.oafpKey, MAX(c.fdcoSumm) AS simpleSum
            FROM ags.ogAgFeeP p
            INNER JOIN ags.factDocCost c ON c.fdcoFd = p.oafp_fdKey AND c.fdcoStCost = @stCostOgAgFee
            WHERE p.oafpCstAgPn = @cstAgPn
            GROUP BY p.oafpKey
        ) s ON s.oafpKey = d.oafpKey
        WHERE ISNULL(s.simpleSum, 0) <> 0;

    INSERT INTO @t SELECT mEnd, stAccp, stRet, stInProc, stNotArr, CostSm FROM @docs;
    RETURN;
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringAgFeeBundle_2606 — 10 колонок АВ за один проход (этап 9б.3).
-- Batch factDocCost (stc=148) + один fnStUpAll вместо fnStCostAgFee на каждую строку.
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringAgFeeBundle_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS @r TABLE
(
    MstrngPrsAgFee       money NULL,
    MstrngAcpAgFee       money NULL,
    MstrngPrsAgFeeMn     money NULL,
    MstrngAcpAgFeeMn     money NULL,
    MstrngRetAgFee       money NULL,
    MstrngRetAgFeeMn     money NULL,
    MstrngInPrcAgFee     money NULL,
    MstrngInPrcAgFeeMn   money NULL,
    MstrngNtArrAgFee     money NULL,
    MstrngNtArrAgFeeMn   money NULL
)
AS
BEGIN
    IF @cstAgPn IS NULL
        RETURN;

    DECLARE @stCostOgAgFee int = 148;
    DECLARE @dagHit          bit = 0;

    IF @StCostKey = @stCostOgAgFee
        SET @dagHit = 1;
    ELSE IF EXISTS (
        SELECT 1 FROM ags.fnStUpAll(@stNet, @stCostOgAgFee) u WHERE u.strParent = @StCostKey
    )
        SET @dagHit = 1;

    DECLARE @docs TABLE
    (
        oafpKey    int   NOT NULL,
        mEnd       date  NOT NULL,
        stAccp     bit   NOT NULL,
        stRet      bit   NOT NULL,
        stInProc   bit   NOT NULL,
        stNotArr   bit   NOT NULL,
        CostSm     money NOT NULL
    );

    INSERT INTO @docs
    (
        oafpKey, mEnd, stAccp, stRet, stInProc, stNotArr, CostSm
    )
    SELECT
        p.oafpKey,
        EOMONTH(DATEFROMPARTS(y.yyyy, m.mNum, 1)),
        CASE WHEN f.oafSent IS NOT NULL AND f.oafSent <> N'' THEN 1 ELSE 0 END,
        CASE WHEN f.oafReturned IS NOT NULL
                  AND (f.oafSent IS NULL OR f.oafSentDate < f.oafReturnedDate) THEN 1 ELSE 0 END,
        CASE WHEN f.oafReturned IS NULL AND f.oafSent IS NULL AND f.oafArrived IS NOT NULL THEN 1 ELSE 0 END,
        CASE WHEN f.oafReturned IS NULL AND f.oafSent IS NULL AND f.oafArrived IS NULL THEN 1 ELSE 0 END,
        0
    FROM ags.ogAgFeeP p
    INNER JOIN ags.ogAgFee f ON p.oafpOaf = f.oafKey
    INNER JOIN ags.yyyy y ON f.oafY = y.yKey
    INNER JOIN ags.mmmm m ON f.oafM = m.mKey
    WHERE p.oafpCstAgPn = @cstAgPn
      AND p.oafpTotal IS NOT NULL
      AND p.oafpTotal <> 0;

    IF @dagHit = 1
    BEGIN
        UPDATE d
        SET CostSm = ISNULL(s.simpleSum, 0)
        FROM @docs d
        INNER JOIN
        (
            SELECT p.oafpKey, MAX(c.fdcoSumm) AS simpleSum
            FROM ags.ogAgFeeP p
            INNER JOIN ags.factDocCost c ON c.fdcoFd = p.oafp_fdKey AND c.fdcoStCost = @stCostOgAgFee
            WHERE p.oafpCstAgPn = @cstAgPn
            GROUP BY p.oafpKey
        ) s ON s.oafpKey = d.oafpKey
        WHERE ISNULL(s.simpleSum, 0) <> 0;
    END

    INSERT INTO @r
    (
        MstrngPrsAgFee, MstrngAcpAgFee, MstrngPrsAgFeeMn, MstrngAcpAgFeeMn,
        MstrngRetAgFee, MstrngRetAgFeeMn, MstrngInPrcAgFee, MstrngInPrcAgFeeMn,
        MstrngNtArrAgFee, MstrngNtArrAgFeeMn
    )
    SELECT
        SUM(CASE WHEN z.dfYLe = 1 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYLe = 1 AND z.stAccp = 1 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYM = 1 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYM = 1 AND z.stAccp = 1 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYLe = 1 AND z.stRet = 1 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYM = 1 AND z.stRet = 1 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYLe = 1 AND z.stInProc = 1 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYM = 1 AND z.stInProc = 1 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYLe = 1 AND z.stNotArr = 1 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYM = 1 AND z.stNotArr = 1 THEN z.CostSm ELSE 0 END)
    FROM
    (
        SELECT
            doc.*,
            CASE WHEN YEAR(@dAll) = YEAR(doc.mEnd) AND @dAll >= doc.mEnd THEN 1 ELSE 0 END AS dfYLe,
            CASE WHEN YEAR(@dAll) = YEAR(doc.mEnd) AND MONTH(@dAll) = MONTH(doc.mEnd) THEN 1 ELSE 0 END AS dfYM
        FROM @docs doc
    ) z;

    RETURN;
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringRalpBundle_2606 — 8 колонок РАЛП за один проход (этап 9б.3).
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringRalpBundle_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS @r TABLE
(
    MstrngPrsRalp       money NULL,
    MstrngAcpRalp       money NULL,
    MstrngPrsRalpMn     money NULL,
    MstrngAcpRalpMn     money NULL,
    MstrngRetRalp       money NULL,
    MstrngRetRalpMn     money NULL,
    MstrngInPrcRalp     money NULL,
    MstrngInPrcRalpMn   money NULL,
    MstrngNtArrRalp     money NULL,
    MstrngNtArrRalpMn   money NULL
)
AS
BEGIN
    IF @cstAgPn IS NULL
        RETURN;

    DECLARE @stCostRalp int = 150;
    DECLARE @dagHit     bit = 0;

    IF @StCostKey = @stCostRalp
        SET @dagHit = 1;
    ELSE IF EXISTS (
        SELECT 1 FROM ags.fnStUpAll(@stNet, @stCostRalp) u WHERE u.strParent = @StCostKey
    )
        SET @dagHit = 1;

    DECLARE @docs TABLE
    (
        ralpraKey  int   NOT NULL,
        dEnd       date  NOT NULL,
        stAccp     bit   NOT NULL,
        stRet      bit   NOT NULL,
        stInProc   bit   NOT NULL,
        stNotArr   bit   NOT NULL,
        CostSm     money NOT NULL
    );

    INSERT INTO @docs
    (
        ralpraKey, dEnd, stAccp, stRet, stInProc, stNotArr, CostSm
    )
    SELECT
        r.ralpraKey,
        EOMONTH(DATEFROMPARTS(r.ralpY, r.ralpM, 1)),
        CASE WHEN r.ralpSent IS NOT NULL AND r.ralpSent <> N'' THEN 1 ELSE 0 END,
        CASE WHEN r.ralpReturned IS NOT NULL
                  AND (r.ralpSent IS NULL OR r.ralpSentDate < r.ralpReturnedDate) THEN 1 ELSE 0 END,
        CASE WHEN r.ralpReturned IS NULL AND r.ralpSent IS NULL AND r.ralpArrived IS NOT NULL THEN 1 ELSE 0 END,
        CASE WHEN r.ralpReturned IS NULL AND r.ralpSent IS NULL AND r.ralpArrived IS NULL THEN 1 ELSE 0 END,
        0
    FROM ags.ralp r
    WHERE r.ralpCstAgPn = @cstAgPn;

    IF @dagHit = 1
    BEGIN
        UPDATE d
        SET CostSm = ISNULL(s.simpleSum, 0)
        FROM @docs d
        INNER JOIN
        (
            SELECT r.ralpraKey, MAX(c.fdcoSumm) AS simpleSum
            FROM ags.ralp r
            INNER JOIN ags.ralpRaAu p ON p.ralpraKey = r.ralpraKey
            INNER JOIN ags.factDocCost c ON c.fdcoFd = p.ralpra_fdKey AND c.fdcoStCost = @stCostRalp
            WHERE r.ralpCstAgPn = @cstAgPn
            GROUP BY r.ralpraKey
        ) s ON s.ralpraKey = d.ralpraKey
        WHERE ISNULL(s.simpleSum, 0) <> 0;
    END

    INSERT INTO @r
    (
        MstrngPrsRalp, MstrngAcpRalp, MstrngPrsRalpMn, MstrngAcpRalpMn,
        MstrngRetRalp, MstrngRetRalpMn, MstrngInPrcRalp, MstrngInPrcRalpMn,
        MstrngNtArrRalp, MstrngNtArrRalpMn
    )
    SELECT
        SUM(CASE WHEN z.dfYLe = 1 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYLe = 1 AND z.stAccp = 1 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYM = 1 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYM = 1 AND z.stAccp = 1 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYLe = 1 AND z.stRet = 1 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYM = 1 AND z.stRet = 1 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYLe = 1 AND z.stInProc = 1 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYM = 1 AND z.stInProc = 1 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYLe = 1 AND z.stNotArr = 1 THEN z.CostSm ELSE 0 END),
        SUM(CASE WHEN z.dfYM = 1 AND z.stNotArr = 1 THEN z.CostSm ELSE 0 END)
    FROM
    (
        SELECT
            doc.*,
            CASE WHEN YEAR(@dAll) = YEAR(doc.dEnd) AND @dAll >= doc.dEnd THEN 1 ELSE 0 END AS dfYLe,
            CASE WHEN YEAR(@dAll) = YEAR(doc.dEnd) AND MONTH(@dAll) = MONTH(doc.dEnd) THEN 1 ELSE 0 END AS dfYM
        FROM @docs doc
    ) z;

    RETURN;
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringPrDocMnrlBundle_2606 — PrDoc + Mnrl (6 колонок) за один проход (9б.3).
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringPrDocMnrlBundle_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS @r TABLE
(
    MstrngAcpStor       money NULL,
    MstrngAcpStorMn     money NULL,
    MstrngAcpControl    money NULL,
    MstrngAcpControlMn  money NULL,
    MstrngAcpMnrl       money NULL,
    MstrngAcpMnrlMn     money NULL
)
AS
BEGIN
    IF @cstAgPn IS NULL
        RETURN;

    DECLARE @stCostMnr int = 169;
    DECLARE @hit205    bit = 0;
    DECLARE @hit197    bit = 0;
    DECLARE @hitMnr    bit = 0;

    IF @StCostKey = 205 SET @hit205 = 1;
    ELSE IF EXISTS (SELECT 1 FROM ags.fnStUpAll(@stNet, 205) u WHERE u.strParent = @StCostKey) SET @hit205 = 1;

    IF @StCostKey = 197 SET @hit197 = 1;
    ELSE IF EXISTS (SELECT 1 FROM ags.fnStUpAll(@stNet, 197) u WHERE u.strParent = @StCostKey) SET @hit197 = 1;

    IF @StCostKey = @stCostMnr SET @hitMnr = 1;
    ELSE IF EXISTS (SELECT 1 FROM ags.fnStUpAll(@stNet, @stCostMnr) u WHERE u.strParent = @StCostKey) SET @hitMnr = 1;

    DECLARE @prDoc TABLE
    (
        pdpKey     int   NOT NULL,
        dEnd       date  NOT NULL,
        isStor     bit   NOT NULL,
        isControl  bit   NOT NULL,
        CostSm     money NOT NULL
    );

    INSERT INTO @prDoc (pdpKey, dEnd, isStor, isControl, CostSm)
    SELECT
        p.pdpKey,
        EOMONTH(DATEFROMPARTS(YEAR(p.positingDate), MONTH(p.positingDate), 1)),
        CASE WHEN d.cnpdTpOrd IN (1, 2, 4) THEN 1 ELSE 0 END,
        CASE WHEN d.cnpdTpOrd = 3 AND i.ciasAccnt = 30 THEN 1 ELSE 0 END,
        0
    FROM ags.cn_PrDocP p
    INNER JOIN ags.cn_PrDoc d ON p.pdpPrDoc = d.cnpdKey
    LEFT JOIN ags.cnInvAccntSmpl i ON d.cnpdCnInvAccntSmpl = i.ciasKey
    WHERE p.pdpCstAgPn = @cstAgPn
      AND p.satstusOfOUKVtext = N'проведено';

    UPDATE pd
    SET CostSm =
        CASE
            WHEN fc.baseStCost = 205 AND @hit205 = 1 AND ISNULL(fc.simpleSum, 0) <> 0 THEN fc.simpleSum
            WHEN fc.baseStCost = 197 AND @hit197 = 1 AND ISNULL(fc.simpleSum, 0) <> 0 THEN fc.simpleSum
            ELSE 0
        END
    FROM @prDoc pd
    INNER JOIN
    (
        SELECT p.pdpKey, c.fdcoStCost AS baseStCost, MAX(c.fdcoSumm) AS simpleSum
        FROM ags.cn_PrDocP p
        INNER JOIN ags.factDocCost c ON c.fdcoFd = p.pdp_fdKey AND c.fdcoStCost IN (205, 197)
        WHERE p.pdpCstAgPn = @cstAgPn
        GROUP BY p.pdpKey, c.fdcoStCost
    ) fc ON fc.pdpKey = pd.pdpKey;

    DECLARE @mnrl TABLE
    (
        amKey  int   NOT NULL,
        dEnd   date  NOT NULL,
        CostSm money NOT NULL
    );

    INSERT INTO @mnrl (amKey, dEnd, CostSm)
    SELECT
        m.amKey,
        EOMONTH(DATEFROMPARTS(YEAR(m.amPositing), MONTH(m.amPositing), 1)),
        0
    FROM ags.cstAgPnMnrl m
    WHERE m.amCstAgPn = @cstAgPn;

    IF @hitMnr = 1
    BEGIN
        UPDATE mn
        SET CostSm = ISNULL(s.simpleSum, 0)
        FROM @mnrl mn
        INNER JOIN
        (
            SELECT m.amKey, MAX(c.fdcoSumm) AS simpleSum
            FROM ags.cstAgPnMnrl m
            INNER JOIN ags.factDocCost c ON c.fdcoFd = m.am_fdKey AND c.fdcoStCost = @stCostMnr
            WHERE m.amCstAgPn = @cstAgPn
            GROUP BY m.amKey
        ) s ON s.amKey = mn.amKey
        WHERE ISNULL(s.simpleSum, 0) <> 0;
    END

    INSERT INTO @r
    (
        MstrngAcpStor, MstrngAcpStorMn, MstrngAcpControl, MstrngAcpControlMn,
        MstrngAcpMnrl, MstrngAcpMnrlMn
    )
    SELECT
        ISNULL((
            SELECT SUM(z.CostSm)
            FROM (
                SELECT pd.CostSm,
                    CASE WHEN YEAR(@dAll) = YEAR(pd.dEnd) AND @dAll >= pd.dEnd THEN 1 ELSE 0 END AS dfYLe
                FROM @prDoc pd
                WHERE pd.isStor = 1
            ) z
            WHERE z.dfYLe = 1
        ), 0),
        ISNULL((
            SELECT SUM(z.CostSm)
            FROM (
                SELECT pd.CostSm,
                    CASE WHEN YEAR(@dAll) = YEAR(pd.dEnd) AND MONTH(@dAll) = MONTH(pd.dEnd) THEN 1 ELSE 0 END AS dfYM
                FROM @prDoc pd
                WHERE pd.isStor = 1
            ) z
            WHERE z.dfYM = 1
        ), 0),
        ISNULL((
            SELECT SUM(z.CostSm)
            FROM (
                SELECT pd.CostSm,
                    CASE WHEN YEAR(@dAll) = YEAR(pd.dEnd) AND @dAll >= pd.dEnd THEN 1 ELSE 0 END AS dfYLe
                FROM @prDoc pd
                WHERE pd.isControl = 1
            ) z
            WHERE z.dfYLe = 1
        ), 0),
        ISNULL((
            SELECT SUM(z.CostSm)
            FROM (
                SELECT pd.CostSm,
                    CASE WHEN YEAR(@dAll) = YEAR(pd.dEnd) AND MONTH(@dAll) = MONTH(pd.dEnd) THEN 1 ELSE 0 END AS dfYM
                FROM @prDoc pd
                WHERE pd.isControl = 1
            ) z
            WHERE z.dfYM = 1
        ), 0),
        ISNULL((
            SELECT SUM(z.CostSm)
            FROM (
                SELECT mn.CostSm,
                    CASE WHEN YEAR(@dAll) = YEAR(mn.dEnd) AND @dAll >= mn.dEnd THEN 1 ELSE 0 END AS dfYLe
                FROM @mnrl mn
            ) z
            WHERE z.dfYLe = 1
        ), 0),
        ISNULL((
            SELECT SUM(z.CostSm)
            FROM (
                SELECT mn.CostSm,
                    CASE WHEN YEAR(@dAll) = YEAR(mn.dEnd) AND MONTH(@dAll) = MONTH(mn.dEnd) THEN 1 ELSE 0 END AS dfYM
                FROM @mnrl mn
            ) z
            WHERE z.dfYM = 1
        ), 0);

    RETURN;
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringPresRa_2606 — RA представленные (все по году ≤ dAll)
-- Прототип: ags.fnMasteringPresRa (без фильтра ra_sent)
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringPresRa_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @subAg      int = 0
)
RETURNS money
AS
BEGIN
    RETURN ags.fnMasteringRaCostSet_2606(@dAll, @cstAgPn, @StCostKey, @stNet, @subAg, 0, 0);
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringAccpRa_2606 — RA принятые (ra_sent IS NOT NULL)
-- Прототип: ags.fnMasteringAccpRa
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringAccpRa_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @subAg      int = 0
)
RETURNS money
AS
BEGIN
    RETURN ags.fnMasteringRaCostSet_2606(@dAll, @cstAgPn, @StCostKey, @stNet, @subAg, 0, 1);
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringPresRaMn_2606 — RA представленные за текущий месяц
-- Прототип: ags.fnMasteringPresRaMn
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringPresRaMn_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @subAg      int = 0
)
RETURNS money
AS
BEGIN
    RETURN ags.fnMasteringRaCostSet_2606(@dAll, @cstAgPn, @StCostKey, @stNet, @subAg, 1, 0);
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringAccpRaMn_2606 — RA принятые за текущий месяц
-- Прототип: ags.fnMasteringAccpRaMn
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringAccpRaMn_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @subAg      int = 0
)
RETURNS money
AS
BEGIN
    RETURN ags.fnMasteringRaCostSet_2606(@dAll, @cstAgPn, @StCostKey, @stNet, @subAg, 1, 1);
END
GO

-- =============================================================================
-- РАЗДЕЛ 2: АВ (AgFee) — Pres/Accp (4 функции)
-- Источник: ags.ogAgFeeP JOIN ags.ogAgFee JOIN ags.yyyy JOIN ags.mmmm
-- fnStCostAgFee → fnStCostAgFee_2606
-- =============================================================================

PRINT '--- 8.1 AgFee Pres/Accp ---';
GO

-- -----------------------------------------------------------------------------
-- fnMasteringPresAgFee_2606 — АВ представленные (без фильтра oafSent)
-- Прототип: ags.fnMasteringPresAgFee
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringPresAgFee_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostAgFee_2606(z.oafpKey, @StCostKey, @stNet))
        FROM
        (
            SELECT p.oafpKey
                , EOMONTH(DATEFROMPARTS(y.yyyy, m.mNum, 1)) mEnd
            FROM ags.ogAgFeeP p
                JOIN ags.ogAgFee f ON p.oafpOaf = f.oafKey
                    JOIN ags.yyyy y ON f.oafY = y.yKey
                    JOIN ags.mmmm m ON f.oafM = m.mKey
            WHERE p.oafpCstAgPn = @cstAgPn
              AND p.oafpTotal IS NOT NULL AND p.oafpTotal <> 0
        ) AS z
        WHERE year(z.mEnd) = year(@dAll) AND z.mEnd <= @dAll
    );
    RETURN @rslt;
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringAccpAgFee_2606 — АВ принятые (oafSent IS NOT NULL)
-- Прототип: ags.fnMasteringAccpAgFee
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringAccpAgFee_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostAgFee_2606(z.oafpKey, @StCostKey, @stNet))
        FROM
        (
            SELECT p.oafpKey
                , EOMONTH(DATEFROMPARTS(y.yyyy, m.mNum, 1)) mEnd
            FROM ags.ogAgFeeP p
                JOIN ags.ogAgFee f ON p.oafpOaf = f.oafKey
                    JOIN ags.yyyy y ON f.oafY = y.yKey
                    JOIN ags.mmmm m ON f.oafM = m.mKey
            WHERE p.oafpCstAgPn = @cstAgPn
              AND f.oafSent IS NOT NULL AND f.oafSent <> N''
              AND p.oafpTotal IS NOT NULL AND p.oafpTotal <> 0
        ) AS z
        WHERE year(z.mEnd) = year(@dAll) AND z.mEnd <= @dAll
    );
    RETURN @rslt;
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringPresAgFeeMn_2606 — АВ представленные за месяц
-- Прототип: ags.fnMasteringPresAgFeeMn
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringPresAgFeeMn_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostAgFee_2606(z.oafpKey, @StCostKey, @stNet))
        FROM
        (
            SELECT p.oafpKey
                , EOMONTH(DATEFROMPARTS(y.yyyy, m.mNum, 1)) mEnd
            FROM ags.ogAgFeeP p
                JOIN ags.ogAgFee f ON p.oafpOaf = f.oafKey
                    JOIN ags.yyyy y ON f.oafY = y.yKey
                    JOIN ags.mmmm m ON f.oafM = m.mKey
            WHERE p.oafpCstAgPn = @cstAgPn
              AND p.oafpTotal IS NOT NULL AND p.oafpTotal <> 0
        ) AS z
        WHERE year(z.mEnd) = year(@dAll) AND month(z.mEnd) = month(@dAll)
    );
    RETURN @rslt;
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringAccpAgFeeMn_2606 — АВ принятые за месяц
-- Прототип: ags.fnMasteringAccpAgFeeMn
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringAccpAgFeeMn_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostAgFee_2606(z.oafpKey, @StCostKey, @stNet))
        FROM
        (
            SELECT p.oafpKey
                , EOMONTH(DATEFROMPARTS(y.yyyy, m.mNum, 1)) mEnd
            FROM ags.ogAgFeeP p
                JOIN ags.ogAgFee f ON p.oafpOaf = f.oafKey
                    JOIN ags.yyyy y ON f.oafY = y.yKey
                    JOIN ags.mmmm m ON f.oafM = m.mKey
            WHERE p.oafpCstAgPn = @cstAgPn
              AND f.oafSent IS NOT NULL AND f.oafSent <> N''
              AND p.oafpTotal IS NOT NULL AND p.oafpTotal <> 0
        ) AS z
        WHERE year(z.mEnd) = year(@dAll) AND month(z.mEnd) = month(@dAll)
    );
    RETURN @rslt;
END
GO

-- =============================================================================
-- РАЗДЕЛ 3: РАЛП — Pres/Accp (4 функции)
-- Источник: ags.ralp
-- fnStCostRalp → fnStCostRalp_2606
-- =============================================================================

PRINT '--- 8.1 Ralp Pres/Accp ---';
GO

-- -----------------------------------------------------------------------------
-- fnMasteringPresRalp_2606 — РАЛП представленные (без ralpSent)
-- Прототип: ags.fnMasteringPresRalp
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringPresRalp_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostRalp_2606(z.ralpraKey, @StCostKey, @stNet))
        FROM
        (
            SELECT r.ralpraKey
                , EOMONTH(DATEFROMPARTS(r.ralpY, r.ralpM, 1)) dEnd
            FROM ags.ralp r
            WHERE r.ralpCstAgPn = @cstAgPn
        ) AS z
        WHERE year(z.dEnd) = year(@dAll) AND z.dEnd <= @dAll
    );
    RETURN @rslt;
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringAccpRalp_2606 — РАЛП принятые (ralpSent IS NOT NULL)
-- Прототип: ags.fnMasteringAccpRalp
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringAccpRalp_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostRalp_2606(z.ralpraKey, @StCostKey, @stNet))
        FROM
        (
            SELECT r.ralpraKey
                , EOMONTH(DATEFROMPARTS(r.ralpY, r.ralpM, 1)) dEnd
            FROM ags.ralp r
            WHERE r.ralpCstAgPn = @cstAgPn
              AND r.ralpSent IS NOT NULL AND r.ralpSent <> N''
        ) AS z
        WHERE year(z.dEnd) = year(@dAll) AND z.dEnd <= @dAll
    );
    RETURN @rslt;
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringPresRalpMn_2606 — РАЛП представленные за месяц
-- Прототип: ags.fnMasteringPresRalpMn
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringPresRalpMn_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostRalp_2606(z.ralpraKey, @StCostKey, @stNet))
        FROM
        (
            SELECT r.ralpraKey
                , EOMONTH(DATEFROMPARTS(r.ralpY, r.ralpM, 1)) dEnd
            FROM ags.ralp r
            WHERE r.ralpCstAgPn = @cstAgPn
        ) AS z
        WHERE year(z.dEnd) = year(@dAll) AND month(z.dEnd) = month(@dAll)
    );
    RETURN @rslt;
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringAccpRalpMn_2606 — РАЛП принятые за месяц
-- Прототип: ags.fnMasteringAccpRalpMn
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringAccpRalpMn_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostRalp_2606(z.ralpraKey, @StCostKey, @stNet))
        FROM
        (
            SELECT r.ralpraKey
                , EOMONTH(DATEFROMPARTS(r.ralpY, r.ralpM, 1)) dEnd
            FROM ags.ralp r
            WHERE r.ralpCstAgPn = @cstAgPn
              AND r.ralpSent IS NOT NULL AND r.ralpSent <> N''
        ) AS z
        WHERE year(z.dEnd) = year(@dAll) AND month(z.dEnd) = month(@dAll)
    );
    RETURN @rslt;
END
GO

-- =============================================================================
-- РАЗДЕЛ 4: Хранение / ССК (PrDoc) — Accp (4 функции)
-- Источник: ags.cn_PrDocP JOIN ags.cn_PrDoc
-- fnStCostPrDoc → fnStCostPrDoc_2606
-- Stor: cnpdTpOrd IN (1,2,4); Control: cnpdTpOrd = 3 AND ciasAccnt = 30
-- =============================================================================

PRINT '--- 8.1 PrDoc Accp (Stor/Control) ---';
GO

-- -----------------------------------------------------------------------------
-- fnMasteringAccpStor_2606 — Хранение принятое (cnpdTpOrd IN (1,2,4))
-- Прототип: ags.fnMasteringAccpStor
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringAccpStor_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostPrDoc_2606(z.pdpKey, @StCostKey, @stNet))
        FROM
        (
            SELECT p.pdpKey
                , EOMONTH(DATEFROMPARTS(year(p.positingDate), month(p.positingDate), 1)) dEnd
            FROM ags.cn_PrDocP p
                JOIN ags.cn_PrDoc d ON p.pdpPrDoc = d.cnpdKey
            WHERE p.pdpCstAgPn = @cstAgPn
              AND d.cnpdTpOrd IN (1, 2, 4)
              AND p.satstusOfOUKVtext = N'проведено'
        ) AS z
        WHERE year(z.dEnd) = year(@dAll) AND z.dEnd <= @dAll
    );
    RETURN @rslt;
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringAccpStorMn_2606 — Хранение принятое за месяц
-- Прототип: ags.fnMasteringAccpStorMn
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringAccpStorMn_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostPrDoc_2606(z.pdpKey, @StCostKey, @stNet))
        FROM
        (
            SELECT p.pdpKey
                , EOMONTH(DATEFROMPARTS(year(p.positingDate), month(p.positingDate), 1)) dEnd
            FROM ags.cn_PrDocP p
                JOIN ags.cn_PrDoc d ON p.pdpPrDoc = d.cnpdKey
            WHERE p.pdpCstAgPn = @cstAgPn
              AND d.cnpdTpOrd IN (1, 2, 4)
              AND p.satstusOfOUKVtext = N'проведено'
        ) AS z
        WHERE year(z.dEnd) = year(@dAll) AND month(z.dEnd) = month(@dAll)
    );
    RETURN @rslt;
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringAccpControl_2606 — ССК принятый (cnpdTpOrd=3, ciasAccnt=30)
-- Прототип: ags.fnMasteringAccpControl
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringAccpControl_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostPrDoc_2606(z.pdpKey, @StCostKey, @stNet))
        FROM
        (
            SELECT p.pdpKey
                , EOMONTH(DATEFROMPARTS(year(p.positingDate), month(p.positingDate), 1)) dEnd
            FROM ags.cn_PrDocP p
                JOIN ags.cn_PrDoc d ON p.pdpPrDoc = d.cnpdKey
                    JOIN ags.cnInvAccntSmpl i ON d.cnpdCnInvAccntSmpl = i.ciasKey
            WHERE p.pdpCstAgPn = @cstAgPn
              AND d.cnpdTpOrd = 3
              AND i.ciasAccnt = 30
              AND p.satstusOfOUKVtext = N'проведено'
        ) AS z
        WHERE year(z.dEnd) = year(@dAll) AND z.dEnd <= @dAll
    );
    RETURN @rslt;
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringAccpControlMn_2606 — ССК принятый за месяц
-- Прототип: ags.fnMasteringAccpControlMn
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringAccpControlMn_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostPrDoc_2606(z.pdpKey, @StCostKey, @stNet))
        FROM
        (
            SELECT p.pdpKey
                , EOMONTH(DATEFROMPARTS(year(p.positingDate), month(p.positingDate), 1)) dEnd
            FROM ags.cn_PrDocP p
                JOIN ags.cn_PrDoc d ON p.pdpPrDoc = d.cnpdKey
                    JOIN ags.cnInvAccntSmpl i ON d.cnpdCnInvAccntSmpl = i.ciasKey
            WHERE p.pdpCstAgPn = @cstAgPn
              AND d.cnpdTpOrd = 3
              AND i.ciasAccnt = 30
              AND p.satstusOfOUKVtext = N'проведено'
        ) AS z
        WHERE year(z.dEnd) = year(@dAll) AND month(z.dEnd) = month(@dAll)
    );
    RETURN @rslt;
END
GO

-- =============================================================================
-- РАЗДЕЛ 5: ОПИ / Минералы — Accp (2 функции)
-- Источник: ags.cstAgPnMnrl
-- fnStCostMnrl → fnStCostMnrl_2606
-- =============================================================================

PRINT '--- 8.1 Mnrl Accp ---';
GO

-- -----------------------------------------------------------------------------
-- fnMasteringAccpMnrl_2606 — ОПИ принятое
-- Прототип: ags.fnMasteringAccpMnrl
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringAccpMnrl_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostMnrl_2606(z.amKey, @StCostKey, @stNet))
        FROM
        (
            SELECT m.amKey
                , EOMONTH(DATEFROMPARTS(year(m.amPositing), month(m.amPositing), 1)) dEnd
            FROM ags.cstAgPnMnrl m
            WHERE m.amCstAgPn = @cstAgPn
        ) AS z
        WHERE year(z.dEnd) = year(@dAll) AND z.dEnd <= @dAll
    );
    RETURN @rslt;
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringAccpMnrlMn_2606 — ОПИ принятое за месяц
-- Прототип: ags.fnMasteringAccpMnrlMn
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringAccpMnrlMn_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostMnrl_2606(z.amKey, @StCostKey, @stNet))
        FROM
        (
            SELECT m.amKey
                , EOMONTH(DATEFROMPARTS(year(m.amPositing), month(m.amPositing), 1)) dEnd
            FROM ags.cstAgPnMnrl m
            WHERE m.amCstAgPn = @cstAgPn
        ) AS z
        WHERE year(z.dEnd) = year(@dAll) AND month(z.dEnd) = month(@dAll)
    );
    RETURN @rslt;
END
GO

-- =============================================================================
-- РАЗДЕЛ 6: RA — Returned (2 функции, Вариант 6А)
-- Фильтр rsltOfConsider = 'returned':
--   ra_returned IS NOT NULL AND (ra_sent IS NULL OR ra_sent_date < ra_returned_date)
-- =============================================================================

PRINT '--- 8.2 RA Returned ---';
GO

-- -----------------------------------------------------------------------------
-- fnMasteringRetRa_2606 — RA возвращённые (по году ≤ dAll)
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringRetRa_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @subAg      int = 0
)
RETURNS money
AS
BEGIN
    RETURN ags.fnMasteringRaCostSet_2606(@dAll, @cstAgPn, @StCostKey, @stNet, @subAg, 0, 2);
END
GO

-- -----------------------------------------------------------------------------
-- fnMasteringRetRaMn_2606 — RA возвращённые за месяц
-- -----------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ags.fnMasteringRetRaMn_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @subAg      int = 0
)
RETURNS money
AS
BEGIN
    RETURN ags.fnMasteringRaCostSet_2606(@dAll, @cstAgPn, @StCostKey, @stNet, @subAg, 1, 2);
END
GO

-- =============================================================================
-- РАЗДЕЛ 7: RA — InProcess (2 функции, Вариант 6А)
-- Фильтр: ra_returned IS NULL AND ra_sent IS NULL AND ra_arrived IS NOT NULL
-- =============================================================================

PRINT '--- 8.2 RA InProcess ---';
GO

CREATE OR ALTER FUNCTION ags.fnMasteringInProcRa_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @subAg      int = 0
)
RETURNS money
AS
BEGIN
    RETURN ags.fnMasteringRaCostSet_2606(@dAll, @cstAgPn, @StCostKey, @stNet, @subAg, 0, 3);
END
GO

CREATE OR ALTER FUNCTION ags.fnMasteringInProcRaMn_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @subAg      int = 0
)
RETURNS money
AS
BEGIN
    RETURN ags.fnMasteringRaCostSet_2606(@dAll, @cstAgPn, @StCostKey, @stNet, @subAg, 1, 3);
END
GO

-- =============================================================================
-- РАЗДЕЛ 8: RA — NotArrived (2 функции, Вариант 6А)
-- Фильтр: ra_returned IS NULL AND ra_sent IS NULL AND ra_arrived IS NULL
-- =============================================================================

PRINT '--- 8.2 RA NotArrived ---';
GO

CREATE OR ALTER FUNCTION ags.fnMasteringNotArrRa_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @subAg      int = 0
)
RETURNS money
AS
BEGIN
    RETURN ags.fnMasteringRaCostSet_2606(@dAll, @cstAgPn, @StCostKey, @stNet, @subAg, 0, 4);
END
GO

CREATE OR ALTER FUNCTION ags.fnMasteringNotArrRaMn_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @subAg      int = 0
)
RETURNS money
AS
BEGIN
    RETURN ags.fnMasteringRaCostSet_2606(@dAll, @cstAgPn, @StCostKey, @stNet, @subAg, 1, 4);
END
GO

-- =============================================================================
-- РАЗДЕЛ 9: RA — PresAll (2 функции, Вариант 6А)
-- Все RA ≤ dAll без фильтра по году (любые годы)
-- =============================================================================

PRINT '--- 8.2 RA PresAll ---';
GO

CREATE OR ALTER FUNCTION ags.fnMasteringPresAllRa_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @subAg      int = 0
)
RETURNS money
AS
BEGIN
    RETURN ags.fnMasteringRaCostSet_2606(@dAll, @cstAgPn, @StCostKey, @stNet, @subAg, 2, 0);
END
GO

-- PresAll за текущий месяц (все годы, тот же номер месяца ≤ dAll)
CREATE OR ALTER FUNCTION ags.fnMasteringPresAllRaMn_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @subAg      int = 0
)
RETURNS money
AS
BEGIN
    RETURN ags.fnMasteringRaCostSet_2606(@dAll, @cstAgPn, @StCostKey, @stNet, @subAg, 3, 0);
END
GO

-- =============================================================================
-- РАЗДЕЛ 10: RA — PrevYears (5 функций, Вариант 6А)
-- Фильтр: year(ra_datePeriod) < year(@dAll) — только прошлые годы
-- =============================================================================

PRINT '--- 8.2 RA PrevYears (5 шт.) ---';
GO

-- fnMasteringPresPrvYRa_2606 — все RA прошлых лет
CREATE OR ALTER FUNCTION ags.fnMasteringPresPrvYRa_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @subAg      int = 0
)
RETURNS money
AS
BEGIN
    RETURN ags.fnMasteringRaCostSet_2606(@dAll, @cstAgPn, @StCostKey, @stNet, @subAg, 4, 0);
END
GO

-- fnMasteringAccpPrvYRa_2606 — принятые RA прошлых лет
CREATE OR ALTER FUNCTION ags.fnMasteringAccpPrvYRa_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @subAg      int = 0
)
RETURNS money
AS
BEGIN
    RETURN ags.fnMasteringRaCostSet_2606(@dAll, @cstAgPn, @StCostKey, @stNet, @subAg, 4, 1);
END
GO

-- fnMasteringRetPrvYRa_2606 — возвращённые RA прошлых лет
CREATE OR ALTER FUNCTION ags.fnMasteringRetPrvYRa_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @subAg      int = 0
)
RETURNS money
AS
BEGIN
    RETURN ags.fnMasteringRaCostSet_2606(@dAll, @cstAgPn, @StCostKey, @stNet, @subAg, 4, 2);
END
GO

-- fnMasteringInProcPrvYRa_2606 — в обработке RA прошлых лет
CREATE OR ALTER FUNCTION ags.fnMasteringInProcPrvYRa_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @subAg      int = 0
)
RETURNS money
AS
BEGIN
    RETURN ags.fnMasteringRaCostSet_2606(@dAll, @cstAgPn, @StCostKey, @stNet, @subAg, 4, 3);
END
GO

-- fnMasteringNotArrPrvYRa_2606 — не поступившие RA прошлых лет
CREATE OR ALTER FUNCTION ags.fnMasteringNotArrPrvYRa_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int,
    @subAg      int = 0
)
RETURNS money
AS
BEGIN
    RETURN ags.fnMasteringRaCostSet_2606(@dAll, @cstAgPn, @StCostKey, @stNet, @subAg, 4, 4);
END
GO

-- =============================================================================
-- РАЗДЕЛ 11: АВ (AgFee) — Ret/InProc/NotArr (6 функций, Вариант 6А)
-- Источник: ags.ogAgFeeP JOIN ags.ogAgFee JOIN ags.yyyy JOIN ags.mmmm
-- Статусные поля: oafReturned, oafSent, oafArrived, oafSentDate, oafReturnedDate
-- =============================================================================

PRINT '--- 8.2 AgFee Ret/InProc/NotArr ---';
GO

-- fnMasteringRetAgFee_2606
CREATE OR ALTER FUNCTION ags.fnMasteringRetAgFee_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostAgFee_2606(z.oafpKey, @StCostKey, @stNet))
        FROM
        (
            SELECT p.oafpKey
                , EOMONTH(DATEFROMPARTS(y.yyyy, m.mNum, 1)) mEnd
                , f.oafReturned, f.oafSent, f.oafSentDate, f.oafReturnedDate
            FROM ags.ogAgFeeP p
                JOIN ags.ogAgFee f ON p.oafpOaf = f.oafKey
                    JOIN ags.yyyy y ON f.oafY = y.yKey
                    JOIN ags.mmmm m ON f.oafM = m.mKey
            WHERE p.oafpCstAgPn = @cstAgPn
              AND p.oafpTotal IS NOT NULL AND p.oafpTotal <> 0
              AND f.oafReturned IS NOT NULL
              AND (f.oafSent IS NULL OR f.oafSentDate < f.oafReturnedDate)
        ) AS z
        WHERE year(z.mEnd) = year(@dAll) AND z.mEnd <= @dAll
    );
    RETURN @rslt;
END
GO

-- fnMasteringRetAgFeeMn_2606
CREATE OR ALTER FUNCTION ags.fnMasteringRetAgFeeMn_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostAgFee_2606(z.oafpKey, @StCostKey, @stNet))
        FROM
        (
            SELECT p.oafpKey
                , EOMONTH(DATEFROMPARTS(y.yyyy, m.mNum, 1)) mEnd
                , f.oafReturned, f.oafSent, f.oafSentDate, f.oafReturnedDate
            FROM ags.ogAgFeeP p
                JOIN ags.ogAgFee f ON p.oafpOaf = f.oafKey
                    JOIN ags.yyyy y ON f.oafY = y.yKey
                    JOIN ags.mmmm m ON f.oafM = m.mKey
            WHERE p.oafpCstAgPn = @cstAgPn
              AND p.oafpTotal IS NOT NULL AND p.oafpTotal <> 0
              AND f.oafReturned IS NOT NULL
              AND (f.oafSent IS NULL OR f.oafSentDate < f.oafReturnedDate)
        ) AS z
        WHERE year(z.mEnd) = year(@dAll) AND month(z.mEnd) = month(@dAll)
    );
    RETURN @rslt;
END
GO

-- fnMasteringInProcAgFee_2606
CREATE OR ALTER FUNCTION ags.fnMasteringInProcAgFee_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostAgFee_2606(z.oafpKey, @StCostKey, @stNet))
        FROM
        (
            SELECT p.oafpKey
                , EOMONTH(DATEFROMPARTS(y.yyyy, m.mNum, 1)) mEnd
                , f.oafReturned, f.oafSent, f.oafArrived
            FROM ags.ogAgFeeP p
                JOIN ags.ogAgFee f ON p.oafpOaf = f.oafKey
                    JOIN ags.yyyy y ON f.oafY = y.yKey
                    JOIN ags.mmmm m ON f.oafM = m.mKey
            WHERE p.oafpCstAgPn = @cstAgPn
              AND p.oafpTotal IS NOT NULL AND p.oafpTotal <> 0
              AND f.oafReturned IS NULL AND f.oafSent IS NULL AND f.oafArrived IS NOT NULL
        ) AS z
        WHERE year(z.mEnd) = year(@dAll) AND z.mEnd <= @dAll
    );
    RETURN @rslt;
END
GO

-- fnMasteringInProcAgFeeMn_2606
CREATE OR ALTER FUNCTION ags.fnMasteringInProcAgFeeMn_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostAgFee_2606(z.oafpKey, @StCostKey, @stNet))
        FROM
        (
            SELECT p.oafpKey
                , EOMONTH(DATEFROMPARTS(y.yyyy, m.mNum, 1)) mEnd
                , f.oafReturned, f.oafSent, f.oafArrived
            FROM ags.ogAgFeeP p
                JOIN ags.ogAgFee f ON p.oafpOaf = f.oafKey
                    JOIN ags.yyyy y ON f.oafY = y.yKey
                    JOIN ags.mmmm m ON f.oafM = m.mKey
            WHERE p.oafpCstAgPn = @cstAgPn
              AND p.oafpTotal IS NOT NULL AND p.oafpTotal <> 0
              AND f.oafReturned IS NULL AND f.oafSent IS NULL AND f.oafArrived IS NOT NULL
        ) AS z
        WHERE year(z.mEnd) = year(@dAll) AND month(z.mEnd) = month(@dAll)
    );
    RETURN @rslt;
END
GO

-- fnMasteringNotArrAgFee_2606
CREATE OR ALTER FUNCTION ags.fnMasteringNotArrAgFee_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostAgFee_2606(z.oafpKey, @StCostKey, @stNet))
        FROM
        (
            SELECT p.oafpKey
                , EOMONTH(DATEFROMPARTS(y.yyyy, m.mNum, 1)) mEnd
                , f.oafReturned, f.oafSent, f.oafArrived
            FROM ags.ogAgFeeP p
                JOIN ags.ogAgFee f ON p.oafpOaf = f.oafKey
                    JOIN ags.yyyy y ON f.oafY = y.yKey
                    JOIN ags.mmmm m ON f.oafM = m.mKey
            WHERE p.oafpCstAgPn = @cstAgPn
              AND p.oafpTotal IS NOT NULL AND p.oafpTotal <> 0
              AND f.oafReturned IS NULL AND f.oafSent IS NULL AND f.oafArrived IS NULL
        ) AS z
        WHERE year(z.mEnd) = year(@dAll) AND z.mEnd <= @dAll
    );
    RETURN @rslt;
END
GO

-- fnMasteringNotArrAgFeeMn_2606
CREATE OR ALTER FUNCTION ags.fnMasteringNotArrAgFeeMn_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostAgFee_2606(z.oafpKey, @StCostKey, @stNet))
        FROM
        (
            SELECT p.oafpKey
                , EOMONTH(DATEFROMPARTS(y.yyyy, m.mNum, 1)) mEnd
                , f.oafReturned, f.oafSent, f.oafArrived
            FROM ags.ogAgFeeP p
                JOIN ags.ogAgFee f ON p.oafpOaf = f.oafKey
                    JOIN ags.yyyy y ON f.oafY = y.yKey
                    JOIN ags.mmmm m ON f.oafM = m.mKey
            WHERE p.oafpCstAgPn = @cstAgPn
              AND p.oafpTotal IS NOT NULL AND p.oafpTotal <> 0
              AND f.oafReturned IS NULL AND f.oafSent IS NULL AND f.oafArrived IS NULL
        ) AS z
        WHERE year(z.mEnd) = year(@dAll) AND month(z.mEnd) = month(@dAll)
    );
    RETURN @rslt;
END
GO

-- =============================================================================
-- РАЗДЕЛ 12: РАЛП — Ret/InProc/NotArr (6 функций, Вариант 6А)
-- Источник: ags.ralp
-- Статусные поля: ralpReturned, ralpSent, ralpArrived, ralpSentDate, ralpReturnedDate
-- =============================================================================

PRINT '--- 8.2 Ralp Ret/InProc/NotArr ---';
GO

-- fnMasteringRetRalp_2606
CREATE OR ALTER FUNCTION ags.fnMasteringRetRalp_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostRalp_2606(z.ralpraKey, @StCostKey, @stNet))
        FROM
        (
            SELECT r.ralpraKey
                , EOMONTH(DATEFROMPARTS(r.ralpY, r.ralpM, 1)) dEnd
            FROM ags.ralp r
            WHERE r.ralpCstAgPn = @cstAgPn
              AND r.ralpReturned IS NOT NULL
              AND (r.ralpSent IS NULL OR r.ralpSentDate < r.ralpReturnedDate)
        ) AS z
        WHERE year(z.dEnd) = year(@dAll) AND z.dEnd <= @dAll
    );
    RETURN @rslt;
END
GO

-- fnMasteringRetRalpMn_2606
CREATE OR ALTER FUNCTION ags.fnMasteringRetRalpMn_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostRalp_2606(z.ralpraKey, @StCostKey, @stNet))
        FROM
        (
            SELECT r.ralpraKey
                , EOMONTH(DATEFROMPARTS(r.ralpY, r.ralpM, 1)) dEnd
            FROM ags.ralp r
            WHERE r.ralpCstAgPn = @cstAgPn
              AND r.ralpReturned IS NOT NULL
              AND (r.ralpSent IS NULL OR r.ralpSentDate < r.ralpReturnedDate)
        ) AS z
        WHERE year(z.dEnd) = year(@dAll) AND month(z.dEnd) = month(@dAll)
    );
    RETURN @rslt;
END
GO

-- fnMasteringInProcRalp_2606
CREATE OR ALTER FUNCTION ags.fnMasteringInProcRalp_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostRalp_2606(z.ralpraKey, @StCostKey, @stNet))
        FROM
        (
            SELECT r.ralpraKey
                , EOMONTH(DATEFROMPARTS(r.ralpY, r.ralpM, 1)) dEnd
            FROM ags.ralp r
            WHERE r.ralpCstAgPn = @cstAgPn
              AND r.ralpReturned IS NULL AND r.ralpSent IS NULL AND r.ralpArrived IS NOT NULL
        ) AS z
        WHERE year(z.dEnd) = year(@dAll) AND z.dEnd <= @dAll
    );
    RETURN @rslt;
END
GO

-- fnMasteringInProcRalpMn_2606
CREATE OR ALTER FUNCTION ags.fnMasteringInProcRalpMn_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostRalp_2606(z.ralpraKey, @StCostKey, @stNet))
        FROM
        (
            SELECT r.ralpraKey
                , EOMONTH(DATEFROMPARTS(r.ralpY, r.ralpM, 1)) dEnd
            FROM ags.ralp r
            WHERE r.ralpCstAgPn = @cstAgPn
              AND r.ralpReturned IS NULL AND r.ralpSent IS NULL AND r.ralpArrived IS NOT NULL
        ) AS z
        WHERE year(z.dEnd) = year(@dAll) AND month(z.dEnd) = month(@dAll)
    );
    RETURN @rslt;
END
GO

-- fnMasteringNotArrRalp_2606
CREATE OR ALTER FUNCTION ags.fnMasteringNotArrRalp_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostRalp_2606(z.ralpraKey, @StCostKey, @stNet))
        FROM
        (
            SELECT r.ralpraKey
                , EOMONTH(DATEFROMPARTS(r.ralpY, r.ralpM, 1)) dEnd
            FROM ags.ralp r
            WHERE r.ralpCstAgPn = @cstAgPn
              AND r.ralpReturned IS NULL AND r.ralpSent IS NULL AND r.ralpArrived IS NULL
        ) AS z
        WHERE year(z.dEnd) = year(@dAll) AND z.dEnd <= @dAll
    );
    RETURN @rslt;
END
GO

-- fnMasteringNotArrRalpMn_2606
CREATE OR ALTER FUNCTION ags.fnMasteringNotArrRalpMn_2606
(
    @dAll       date,
    @cstAgPn    int,
    @StCostKey  int,
    @stNet      int
)
RETURNS money
AS
BEGIN
    DECLARE @rslt money;
    SET @rslt =
    (
        SELECT SUM(ags.fnStCostRalp_2606(z.ralpraKey, @StCostKey, @stNet))
        FROM
        (
            SELECT r.ralpraKey
                , EOMONTH(DATEFROMPARTS(r.ralpY, r.ralpM, 1)) dEnd
            FROM ags.ralp r
            WHERE r.ralpCstAgPn = @cstAgPn
              AND r.ralpReturned IS NULL AND r.ralpSent IS NULL AND r.ralpArrived IS NULL
        ) AS z
        WHERE year(z.dEnd) = year(@dAll) AND month(z.dEnd) = month(@dAll)
    );
    RETURN @rslt;
END
GO

-- =============================================================================
PRINT '=== 03b1: все 43 функции fnMasteringFact*_2606 созданы ===';
GO
