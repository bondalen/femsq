USE [FishEye];
GO
-- =============================================================================
-- 07m_plan_limit_conformance_chain5.sql
-- К-12: накопленный план = лимит ipgPn по каждому stCost (212/195/172/187).
--
-- Фаза 0: данные ipgUtPlPnLmMn (sum месяцев ≈ лимит по stCost)
-- Фаза 1: fnMasteringCstAgPnSh_2606 — COALESCE(ag/in/dr SmmTtl) на последнем dAll ≤ @dt
--          сверка с накопленным UtPl (кумулятив по iuplpmMn × 1e6), уровень ipgPn
--
-- Только стройки (cstAgPn) с помесячной разбивкой UtPl.
-- Параметры: @ipgCh, @stIpg (NULL = вся цепь), @MounthEndDate
-- PERF: ≤ 480 с @ stIpg=NULL
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh           int   = 5;
DECLARE @stIpg           int   = NULL;   -- <<< 61, 46, NULL
DECLARE @MounthEndDate   date  = '2022-12-31';
DECLARE @epsilon         money = 0.01;

DECLARE @stNet   int = (SELECT ipgcStNetIpg FROM ags.ipgCh WHERE ipgcKey = @ipgCh);
DECLARE @ipgRoot int = ISNULL(@stIpg, 1);
DECLARE @t0      datetime2 = SYSDATETIME();

DECLARE @msg nvarchar(500);
SET @msg = N'=== 07m К-12 plan=limit  chain=' + CAST(@ipgCh AS nvarchar)
         + N'  stIpg=' + ISNULL(CAST(@stIpg AS nvarchar), N'NULL')
         + N'  dt=' + CONVERT(nvarchar(10), @MounthEndDate, 23) + N' ===';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- =========================================================================
-- Фаза 0: аудит данных UtPlMn
-- =========================================================================
RAISERROR(N'--- [0/2] DATA: sum(UtPlMn) vs ipgPnLim / ipgpSm* ---', 0, 1) WITH NOWAIT;

DECLARE @data_fail int = 0;

IF OBJECT_ID('tempdb..#pn_ut') IS NOT NULL DROP TABLE #pn_ut;
IF OBJECT_ID('tempdb..#lim_ref') IS NOT NULL DROP TABLE #lim_ref;
IF OBJECT_ID('tempdb..#sums') IS NOT NULL DROP TABLE #sums;
IF OBJECT_ID('tempdb..#pvt') IS NOT NULL DROP TABLE #pvt;
IF OBJECT_ID('tempdb..#chk') IS NOT NULL DROP TABLE #chk;

;WITH ch AS (
    SELECT DISTINCT p.ipgpKey, p.ipgpSmTtl, p.ipgpSmWrk, p.ipgpSmEqu, p.ipgpSmOth, p.ipgpCstAgPn
    FROM ags.ipgPn p
    INNER JOIN ags.ipgChRl_2606 v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
    WHERE @stIpg IS NULL
       OR EXISTS (SELECT 1 FROM ags.ipgStPn sp WHERE sp.ipgspSt = @stIpg AND sp.ipgspPn = p.ipgpKey)
)
SELECT DISTINCT c.ipgpKey, c.ipgpCstAgPn
INTO #pn_ut
FROM ch c
WHERE EXISTS (
    SELECT 1
    FROM ags.ipgUtPlPnLmMn m
    INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
    WHERE up.iuplpIpgPn = c.ipgpKey AND m.iuplpmStCost = 212
);

SELECT
    u.ipgpKey,
    u.ipgpCstAgPn,
    COALESCE(l212.ipgplLim, c.ipgpSmTtl) AS ref212,
    COALESCE(l195.ipgplLim, c.ipgpSmWrk, 0) AS ref195,
    COALESCE(l172.ipgplLim, c.ipgpSmEqu, 0) AS ref172,
    COALESCE(l187.ipgplLim, c.ipgpSmOth, 0) AS ref187
INTO #lim_ref
FROM #pn_ut u
INNER JOIN ags.ipgPn c ON c.ipgpKey = u.ipgpKey
LEFT JOIN ags.ipgPnLim l212 ON l212.ipgplPn = u.ipgpKey AND l212.ipgplStCost = 212
LEFT JOIN ags.ipgPnLim l195 ON l195.ipgplPn = u.ipgpKey AND l195.ipgplStCost = 195
LEFT JOIN ags.ipgPnLim l172 ON l172.ipgplPn = u.ipgpKey AND l172.ipgplStCost = 172
LEFT JOIN ags.ipgPnLim l187 ON l187.ipgplPn = u.ipgpKey AND l187.ipgplStCost = 187;

SELECT
    up.iuplpIpgPn AS ipgpKey,
    m.iuplpmStCost,
    SUM(m.iuplpmLim) AS sum_mn
INTO #sums
FROM ags.ipgUtPlPnLmMn m
INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
INNER JOIN #pn_ut u ON u.ipgpKey = up.iuplpIpgPn
WHERE m.iuplpmStCost IN (212, 195, 172, 187)
GROUP BY up.iuplpIpgPn, m.iuplpmStCost;

SELECT
    ipgpKey,
    MAX(CASE WHEN iuplpmStCost = 212 THEN sum_mn END) AS sum212,
    MAX(CASE WHEN iuplpmStCost = 195 THEN sum_mn END) AS sum195,
    MAX(CASE WHEN iuplpmStCost = 172 THEN sum_mn END) AS sum172,
    MAX(CASE WHEN iuplpmStCost = 187 THEN sum_mn END) AS sum187
INTO #pvt
FROM #sums
GROUP BY ipgpKey;

SELECT
    r.ipgpKey,
    r.ipgpCstAgPn,
    ABS(ISNULL(p.sum212, 0) - r.ref212) AS d212,
    ABS(ISNULL(p.sum195, 0) - r.ref195) AS d195,
    ABS(ISNULL(p.sum172, 0) - r.ref172) AS d172,
    ABS(ISNULL(p.sum187, 0) - r.ref187) AS d187
INTO #chk
FROM #lim_ref r
LEFT JOIN #pvt p ON p.ipgpKey = r.ipgpKey;

SELECT @data_fail = SUM(CASE WHEN d212 > @epsilon OR d195 > @epsilon OR d172 > @epsilon OR d187 > @epsilon THEN 1 ELSE 0 END)
FROM #chk;

SELECT
    COUNT(DISTINCT ipgpCstAgPn) AS contracts_with_utplmn,
    SUM(CASE WHEN d212 <= @epsilon THEN 1 ELSE 0 END) AS data_ok212,
    SUM(CASE WHEN d195 <= @epsilon THEN 1 ELSE 0 END) AS data_ok195,
    SUM(CASE WHEN d172 <= @epsilon THEN 1 ELSE 0 END) AS data_ok172,
    SUM(CASE WHEN d187 <= @epsilon THEN 1 ELSE 0 END) AS data_ok187,
    @data_fail AS data_fail_pn
FROM #chk;

SET @msg = N'  DATA fail_pn=' + CAST(ISNULL(@data_fail, 0) AS nvarchar)
         + CASE WHEN ISNULL(@data_fail, 0) = 0 THEN N'  PASS' ELSE N'  *** FAIL ***' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF ISNULL(@data_fail, 0) > 0
BEGIN
    RAISERROR(N'К-12 DATA phase failed — fix fixture before STACK phase.', 16, 1);
    RETURN;
END;

-- =========================================================================
-- Фаза 1: mastering plan vs накопленный UtPl (ipgPn, последний dAll ≤ @dt)
-- =========================================================================
RAISERROR(N'--- [1/2] STACK: plan vs UtPl cumulative ---', 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#contracts') IS NOT NULL DROP TABLE #contracts;
IF OBJECT_ID('tempdb..#utpl_cum') IS NOT NULL DROP TABLE #utpl_cum;
IF OBJECT_ID('tempdb..#stack212') IS NOT NULL DROP TABLE #stack212;
IF OBJECT_ID('tempdb..#stack195') IS NOT NULL DROP TABLE #stack195;
IF OBJECT_ID('tempdb..#stack172') IS NOT NULL DROP TABLE #stack172;
IF OBJECT_ID('tempdb..#stack187') IS NOT NULL DROP TABLE #stack187;
IF OBJECT_ID('tempdb..#stack_chk') IS NOT NULL DROP TABLE #stack_chk;

SELECT DISTINCT c.ipgpCstAgPn AS cstAgPnKey
INTO #contracts
FROM ags.ipgPn c
INNER JOIN ags.ipgChRl_2606 cr ON cr.ipgcrvIpg = c.ipgpIpg AND cr.ipgcrvChain = @ipgCh
WHERE c.ipgpCstAgPn IS NOT NULL
  AND EXISTS (
      SELECT 1
      FROM ags.ipgUtPlPnLmMn m
      INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
      INNER JOIN ags.ipgPn p2 ON p2.ipgpKey = up.iuplpIpgPn
      WHERE p2.ipgpCstAgPn = c.ipgpCstAgPn
        AND m.iuplpmStCost = 212
        AND (@stIpg IS NULL OR EXISTS (
            SELECT 1 FROM ags.ipgStPn sp WHERE sp.ipgspSt = @stIpg AND sp.ipgspPn = p2.ipgpKey
        ))
  )
  AND (@stIpg IS NULL OR EXISTS (
      SELECT 1 FROM ags.ipgStPn sp WHERE sp.ipgspSt = @stIpg AND sp.ipgspPn = c.ipgpKey
  ));

DECLARE @nc int = (SELECT COUNT(*) FROM #contracts);
DECLARE @npn int = (SELECT COUNT(*) FROM #pn_ut);
RAISERROR(N'  contracts=%d  ipgPn(UtPlMn)=%d', 0, 1, @nc, @npn) WITH NOWAIT;

;WITH cum AS (
    SELECT
        up.iuplpIpgPn AS ipgpKey,
        m.iuplpmStCost,
        m.iuplpmMn,
        SUM(m.iuplpmLim) OVER (
            PARTITION BY up.iuplpIpgPn, m.iuplpmStCost
            ORDER BY m.iuplpmMn
            ROWS UNBOUNDED PRECEDING
        ) AS cum_lim
    FROM ags.ipgUtPlPnLmMn m
    INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
    INNER JOIN #pn_ut u ON u.ipgpKey = up.iuplpIpgPn
    WHERE m.iuplpmStCost IN (212, 195, 172, 187)
)
SELECT ipgpKey, iuplpmStCost, iuplpmMn, CAST(cum_lim * 1000000 AS money) AS cum_money
INTO #utpl_cum
FROM cum;

;WITH raw AS (
    SELECT
        u.ipgpKey,
        u.ipgpCstAgPn,
        m.dAll,
        SUM(COALESCE(m.agSmmTtl, m.inSmmTtl, m.drSmmTtl, 0)) AS plan_val
    FROM #pn_ut u
    INNER JOIN #contracts c ON c.cstAgPnKey = u.ipgpCstAgPn
    CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, u.ipgpCstAgPn, 212, @stNet, @ipgRoot) m
    WHERE m.ipgpKey = u.ipgpKey
      AND m.dAll <= @MounthEndDate
    GROUP BY u.ipgpKey, u.ipgpCstAgPn, m.dAll
),
ranked AS (
    SELECT
        ipgpKey,
        ipgpCstAgPn,
        plan_val,
        dAll AS plan_dAll,
        ROW_NUMBER() OVER (PARTITION BY ipgpKey ORDER BY dAll DESC) AS rn
    FROM raw
    WHERE plan_val <> 0
)
SELECT ipgpKey, ipgpCstAgPn, plan_val, plan_dAll
INTO #stack212
FROM ranked
WHERE rn = 1;

;WITH raw AS (
    SELECT
        u.ipgpKey,
        u.ipgpCstAgPn,
        m.dAll,
        SUM(COALESCE(m.agSmmTtl, m.inSmmTtl, m.drSmmTtl, 0)) AS plan_val
    FROM #pn_ut u
    INNER JOIN #contracts c ON c.cstAgPnKey = u.ipgpCstAgPn
    CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, u.ipgpCstAgPn, 195, @stNet, @ipgRoot) m
    WHERE m.ipgpKey = u.ipgpKey
      AND m.dAll <= @MounthEndDate
    GROUP BY u.ipgpKey, u.ipgpCstAgPn, m.dAll
),
ranked AS (
    SELECT ipgpKey, ipgpCstAgPn, plan_val, dAll AS plan_dAll,
        ROW_NUMBER() OVER (PARTITION BY ipgpKey ORDER BY dAll DESC) AS rn
    FROM raw
    WHERE plan_val <> 0
)
SELECT ipgpKey, ipgpCstAgPn, plan_val, plan_dAll
INTO #stack195
FROM ranked
WHERE rn = 1;

;WITH raw AS (
    SELECT
        u.ipgpKey,
        u.ipgpCstAgPn,
        m.dAll,
        SUM(COALESCE(m.agSmmTtl, m.inSmmTtl, m.drSmmTtl, 0)) AS plan_val
    FROM #pn_ut u
    INNER JOIN #contracts c ON c.cstAgPnKey = u.ipgpCstAgPn
    CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, u.ipgpCstAgPn, 172, @stNet, @ipgRoot) m
    WHERE m.ipgpKey = u.ipgpKey
      AND m.dAll <= @MounthEndDate
    GROUP BY u.ipgpKey, u.ipgpCstAgPn, m.dAll
),
ranked AS (
    SELECT ipgpKey, ipgpCstAgPn, plan_val, dAll AS plan_dAll,
        ROW_NUMBER() OVER (PARTITION BY ipgpKey ORDER BY dAll DESC) AS rn
    FROM raw
    WHERE plan_val <> 0
)
SELECT ipgpKey, ipgpCstAgPn, plan_val, plan_dAll
INTO #stack172
FROM ranked
WHERE rn = 1;

;WITH raw AS (
    SELECT
        u.ipgpKey,
        u.ipgpCstAgPn,
        m.dAll,
        SUM(COALESCE(m.agSmmTtl, m.inSmmTtl, m.drSmmTtl, 0)) AS plan_val
    FROM #pn_ut u
    INNER JOIN #contracts c ON c.cstAgPnKey = u.ipgpCstAgPn
    CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, u.ipgpCstAgPn, 187, @stNet, @ipgRoot) m
    WHERE m.ipgpKey = u.ipgpKey
      AND m.dAll <= @MounthEndDate
    GROUP BY u.ipgpKey, u.ipgpCstAgPn, m.dAll
),
ranked AS (
    SELECT ipgpKey, ipgpCstAgPn, plan_val, dAll AS plan_dAll,
        ROW_NUMBER() OVER (PARTITION BY ipgpKey ORDER BY dAll DESC) AS rn
    FROM raw
    WHERE plan_val <> 0
)
SELECT ipgpKey, ipgpCstAgPn, plan_val, plan_dAll
INTO #stack187
FROM ranked
WHERE rn = 1;

SELECT
    u.ipgpKey,
    u.ipgpCstAgPn,
    s212.plan_val AS plan212,
    s212.plan_dAll AS plan_dAll212,
    s195.plan_val AS plan195,
    s172.plan_val AS plan172,
    s187.plan_val AS plan187,
    CASE
        WHEN s212.plan_val IS NULL THEN N'SKIP'
        WHEN EXISTS (
            SELECT 1
            FROM #utpl_cum c
            WHERE c.ipgpKey = u.ipgpKey
              AND c.iuplpmStCost = 212
              AND ABS(c.cum_money - s212.plan_val) <= @epsilon
        ) THEN N'OK'
        ELSE N'FAIL'
    END AS st212,
    CASE
        WHEN s195.plan_val IS NULL THEN N'SKIP'
        WHEN EXISTS (
            SELECT 1
            FROM #utpl_cum c
            WHERE c.ipgpKey = u.ipgpKey
              AND c.iuplpmStCost = 195
              AND ABS(c.cum_money - s195.plan_val) <= @epsilon
        ) THEN N'OK'
        ELSE N'FAIL'
    END AS st195,
    CASE
        WHEN s172.plan_val IS NULL THEN N'SKIP'
        WHEN EXISTS (
            SELECT 1
            FROM #utpl_cum c
            WHERE c.ipgpKey = u.ipgpKey
              AND c.iuplpmStCost = 172
              AND ABS(c.cum_money - s172.plan_val) <= @epsilon
        ) THEN N'OK'
        ELSE N'FAIL'
    END AS st172,
    CASE
        WHEN s187.plan_val IS NULL THEN N'SKIP'
        WHEN EXISTS (
            SELECT 1
            FROM #utpl_cum c
            WHERE c.ipgpKey = u.ipgpKey
              AND c.iuplpmStCost = 187
              AND ABS(c.cum_money - s187.plan_val) <= @epsilon
        ) THEN N'OK'
        ELSE N'FAIL'
    END AS st187
INTO #stack_chk
FROM #pn_ut u
INNER JOIN #contracts c ON c.cstAgPnKey = u.ipgpCstAgPn
LEFT JOIN #stack212 s212 ON s212.ipgpKey = u.ipgpKey
LEFT JOIN #stack195 s195 ON s195.ipgpKey = u.ipgpKey
LEFT JOIN #stack172 s172 ON s172.ipgpKey = u.ipgpKey
LEFT JOIN #stack187 s187 ON s187.ipgpKey = u.ipgpKey;

DECLARE @fail212 int, @fail195 int, @fail172 int, @fail187 int, @fail_total int;
DECLARE @skip212 int, @skip195 int, @skip172 int, @skip187 int;
DECLARE @yearend212 int;

SELECT
    @fail212 = SUM(CASE WHEN st212 = N'FAIL' THEN 1 ELSE 0 END),
    @fail195 = SUM(CASE WHEN st195 = N'FAIL' THEN 1 ELSE 0 END),
    @fail172 = SUM(CASE WHEN st172 = N'FAIL' THEN 1 ELSE 0 END),
    @fail187 = SUM(CASE WHEN st187 = N'FAIL' THEN 1 ELSE 0 END),
    @skip212 = SUM(CASE WHEN st212 = N'SKIP' THEN 1 ELSE 0 END),
    @skip195 = SUM(CASE WHEN st195 = N'SKIP' THEN 1 ELSE 0 END),
    @skip172 = SUM(CASE WHEN st172 = N'SKIP' THEN 1 ELSE 0 END),
    @skip187 = SUM(CASE WHEN st187 = N'SKIP' THEN 1 ELSE 0 END),
    @yearend212 = SUM(CASE WHEN st212 = N'OK' AND plan_dAll212 = @MounthEndDate THEN 1 ELSE 0 END)
FROM #stack_chk;

SET @fail_total = ISNULL(@fail212, 0) + ISNULL(@fail195, 0) + ISNULL(@fail172, 0) + ISNULL(@fail187, 0);

DECLARE @ms int = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'К-12 | chain=' + CAST(@ipgCh AS nvarchar)
         + N' | dt=' + CONVERT(nvarchar(10), @MounthEndDate, 23)
         + N' | ipgPn=' + CAST(@npn AS nvarchar)
         + N' | STACK fail 212/195/172/187='
         + CAST(ISNULL(@fail212, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@fail195, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@fail172, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@fail187, 0) AS nvarchar)
         + N' | SKIP='
         + CAST(ISNULL(@skip212, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@skip195, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@skip172, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@skip187, 0) AS nvarchar)
         + N' | plan@dt(212)=' + CAST(ISNULL(@yearend212, 0) AS nvarchar)
         + N' | ms=' + CAST(@ms AS nvarchar)
         + CASE WHEN @fail_total = 0 THEN N' | PASS' ELSE N' | *** FAIL ***' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @fail_total > 0
BEGIN
    RAISERROR(N'  TOP STACK failures (ipgPn):', 0, 1) WITH NOWAIT;
    SELECT TOP 20
        ipgpKey, ipgpCstAgPn, plan212, plan_dAll212, st212,
        plan195, st195, plan172, st172, plan187, st187
    FROM #stack_chk
    WHERE st212 = N'FAIL' OR st195 = N'FAIL' OR st172 = N'FAIL' OR st187 = N'FAIL'
    ORDER BY ipgpKey;

    RAISERROR(N'К-12 STACK phase failed.', 16, 1);
END;

RAISERROR(N'=== 07m К-12 завершено ===', 0, 1) WITH NOWAIT;
GO
