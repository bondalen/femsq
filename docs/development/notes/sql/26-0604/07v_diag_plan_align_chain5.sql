USE [FishEye];
GO

-- =============================================================================
-- Файл:    07v_diag_plan_align_chain5.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Диагностика plan-align (этап 21.4.2) — по слоям:
--   L1 ipgPn → L2 ipgChRl_2606/UtPlGr → L3 UtPlP (212) → L4 JOIN gap/gip
--   → L5 PercentBrn (iv_Pl/ag_Pl) → вердикт точки обрыва.
-- Стройки: invest 2102 @ stIpg=42; agency 849/1862 @ stIpg=4.
-- Автор:   Александр | Дата: 2026-07-06
-- =============================================================================

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

RAISERROR(N'=== 07v plan-align chain diag (21.4.2) ===', 0, 1) WITH NOWAIT;

DECLARE @ipgCh   int  = 5;
DECLARE @dt      date = '2022-12-31';
DECLARE @mNum    int  = MONTH(@dt);   -- 12 @ yearend
DECLARE @msg     nvarchar(600);

RAISERROR(N'--- Context: ipgCh=5, dt=2022-12-31, mNum=12 ---', 0, 1) WITH NOWAIT;

-- =========================================================================
-- L1: ipgPn — схема и пункты на ИП 6/8/11
-- =========================================================================
RAISERROR(N'--- L1 ipgPn (scheme per cst × ipg) ---', 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#l1') IS NOT NULL DROP TABLE #l1;
SELECT
    p.ipgpCstAgPn,
    p.ipgpIpg,
    p.ipgpKey,
    p.ipgpSh,
    CASE p.ipgpSh WHEN 1 THEN N'invest' WHEN 2 THEN N'agency' WHEN 3 THEN N'other' ELSE N'?' END AS scheme_nm,
    v.ipgcrvStr,
    v.ipgcrvEnd,
    v.ipgcrvUtPlGr,
    CASE WHEN v.ipgcrvStr <= @dt AND (v.ipgcrvEnd IS NULL OR v.ipgcrvEnd >= @dt) THEN 1 ELSE 0 END AS active_on_dt
INTO #l1
FROM ags.ipgPn p
INNER JOIN ags.ipgChRl_2606 v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
WHERE p.ipgpCstAgPn IN (2102, 849, 1862)
  AND p.ipgpIpg IN (6, 8, 11)
ORDER BY p.ipgpCstAgPn, p.ipgpIpg;

SELECT * FROM #l1 ORDER BY ipgpCstAgPn, ipgpIpg;

-- =========================================================================
-- L3: UtPl @212 в тестовой группе ipgcrvUtPlGr (как 07t К-12)
-- =========================================================================
RAISERROR(N'--- L3 UtPl sum@212 + iuplpM12 (test UtPlGr) ---', 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#l3') IS NOT NULL DROP TABLE #l3;
SELECT
    p.ipgpCstAgPn,
    p.ipgpIpg,
    p.ipgpKey,
    p.ipgpSh,
    v.ipgcrvUtPlGr,
    up.iuplpKey,
    up.iuplpSubAg,
    CAST(up.iuplpM12 AS float) AS iuplpM12_mm,
    CAST(up.iuplpM12Accum AS float) AS iuplpM12Accum_mm,
    CAST(up.iuplpM12 * 1000000 AS money) AS plan_m12_rub,
    CAST(up.iuplpM12Accum * 1000000 AS money) AS plan_accum_rub,
    SUM(CASE WHEN m.iuplpmStCost = 212 THEN m.iuplpmLim ELSE 0 END) AS sum_utplmn_212
INTO #l3
FROM ags.ipgPn p
INNER JOIN ags.ipgChRl_2606 v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
INNER JOIN ags.ipgUtPlP up ON up.iuplpIpgPn = p.ipgpKey
INNER JOIN ags.ipgUtPlGrP gp ON gp.iuplgpPl = up.iuplpPl AND gp.iuplgpGr = v.ipgcrvUtPlGr
LEFT JOIN ags.ipgUtPlPnLmMn m ON m.iuplpmPlPn = up.iuplpKey
WHERE p.ipgpCstAgPn IN (2102, 849, 1862)
  AND p.ipgpIpg IN (6, 8, 11)
  AND v.ipgcrvStr <= @dt AND (v.ipgcrvEnd IS NULL OR v.ipgcrvEnd >= @dt)
GROUP BY p.ipgpCstAgPn, p.ipgpIpg, p.ipgpKey, p.ipgpSh, v.ipgcrvUtPlGr,
         up.iuplpKey, up.iuplpSubAg, up.iuplpM12, up.iuplpM12Accum;

SELECT ipgpCstAgPn, ipgpIpg, ipgpSh, ipgcrvUtPlGr, iuplpSubAg, iuplpM12_mm, plan_m12_rub, sum_utplmn_212
FROM #l3
ORDER BY ipgpCstAgPn, ipgpIpg, iuplpSubAg;

-- =========================================================================
-- L4: Симуляция JOIN gap/gip (как в PercentBrn 05b, без фильтра stCost)
-- =========================================================================
RAISERROR(N'--- L4 simulated gap/gip rows per ipgpKey (PercentBrn JOIN path) ---', 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#gap_src') IS NOT NULL DROP TABLE #gap_src;
SELECT
    r.ipgcrvChain AS ipgcrChain,
    r.ipgcrvIpg   AS ipgcrIpg,
    n.iuplpIpgPn,
    n.iuplpSubAg,
    n.iuplpM12,
    n.iuplpM12Accum,
    r.ipgcrvUtPlGr
INTO #gap_src
FROM ags.ipgChRl_2606 r
INNER JOIN ags.ipgUtPlGr g ON r.ipgcrvUtPlGr = g.iuplgKey
INNER JOIN ags.ipgUtPlGrP p ON g.iuplgKey = p.iuplgpGr
INNER JOIN ags.ipgUtPlP n ON p.iuplgpPl = n.iuplpPl
WHERE r.ipgcrvChain = @ipgCh;

IF OBJECT_ID('tempdb..#l4') IS NOT NULL DROP TABLE #l4;
SELECT
    pn.ipgpCstAgPn,
    pn.ipgpIpg,
    pn.ipgpKey,
    pn.ipgpSh,
    N'agency-gap' AS join_path,
    g.iuplpIpgPn,
    g.iuplpSubAg,
    g.iuplpM12,
    CAST(g.iuplpM12 * 1000000 AS money) AS ag_Pl_sim
INTO #l4
FROM ags.ipgPn pn
INNER JOIN #gap_src g ON g.ipgcrChain = @ipgCh AND pn.ipgpKey = g.iuplpIpgPn
WHERE pn.ipgpCstAgPn IN (2102, 849, 1862)
  AND pn.ipgpIpg IN (6, 8, 11)
  AND pn.ipgpSh = 2;

INSERT INTO #l4
SELECT
    pn.ipgpCstAgPn,
    pn.ipgpIpg,
    pn.ipgpKey,
    pn.ipgpSh,
    N'invest-gip' AS join_path,
    g.iuplpIpgPn,
    g.iuplpSubAg,
    g.iuplpM12,
    CAST(g.iuplpM12 * 1000000 AS money) AS ag_Pl_sim
FROM ags.ipgPn pn
INNER JOIN #gap_src g ON g.ipgcrChain = @ipgCh AND pn.ipgpKey = g.iuplpIpgPn
WHERE pn.ipgpCstAgPn IN (2102, 849, 1862)
  AND pn.ipgpIpg IN (6, 8, 11)
  AND pn.ipgpSh = 1;

SELECT ipgpCstAgPn, ipgpIpg, ipgpSh, join_path, iuplpSubAg, iuplpM12, ag_Pl_sim
FROM #l4
ORDER BY ipgpCstAgPn, ipgpIpg, join_path, iuplpSubAg;

-- Сводка: сколько строк gap/gip на ipgpKey (мульти-stCost?)
RAISERROR(N'--- L4b row counts per ipgpKey (multi-row JOIN risk) ---', 0, 1) WITH NOWAIT;
SELECT ipgpCstAgPn, ipgpIpg, ipgpKey, join_path, COUNT(*) AS gap_rows,
       SUM(CASE WHEN ISNULL(iuplpM12, 0) <> 0 THEN 1 ELSE 0 END) AS rows_m12_nonzero
FROM #l4
GROUP BY ipgpCstAgPn, ipgpIpg, ipgpKey, join_path
ORDER BY ipgpCstAgPn, ipgpIpg;

-- =========================================================================
-- L5: PercentBrn — фактические plan-колонки + ключи JOIN (iShKey, ipgpKey)
-- =========================================================================
RAISERROR(N'--- L5 PercentBrn @dt (detail rows, cst 2102 stIpg=42) ---', 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#pb_inv') IS NOT NULL DROP TABLE #pb_inv;
SELECT
    p.ipgKey,
    p.cstapKey,
    p.iv_iShKey,
    p.iv_ipgpKey,
    p.iv_Pl,
    p.iv_PlAccum,
    p.ag_iShKey,
    p.ag_ipgpKey,
    p.ag_Pl,
    p.ag_PlAccum,
    p.iv_lim,
    p.ag_lim
INTO #pb_inv
FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, 42, NULL) p
WHERE p.cstapKey = 2102
  AND p.dateRslt = @dt
  AND p.ipgKey IN (6, 8, 11);

SELECT * FROM #pb_inv ORDER BY ipgKey;

RAISERROR(N'--- L5b PercentBrn @dt (agency 849/1862 stIpg=4) ---', 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#pb_ag') IS NOT NULL DROP TABLE #pb_ag;
SELECT
    p.cstapKey,
    p.ipgKey,
    p.ag_iShKey,
    p.ag_ipgpKey,
    p.ag_Pl,
    p.ag_PlAccum,
    p.ag_lim,
    p.ag_accepted
INTO #pb_ag
FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, 4, NULL) p
WHERE p.cstapKey IN (849, 1862)
  AND p.dateRslt = @dt
  AND p.ipgKey IN (6, 8, 11);

SELECT * FROM #pb_ag ORDER BY cstapKey, ipgKey;

-- =========================================================================
-- L5c: Сопоставление L4 (stCost=212) vs L5
-- =========================================================================
RAISERROR(N'--- L5c align matrix: UtPl@212 vs PercentBrn plan ---', 0, 1) WITH NOWAIT;

SELECT
    l3.ipgpCstAgPn,
    l3.ipgpIpg,
    l3.ipgpSh,
    l3.plan_m12_rub AS utpl_212_m12,
    l4.ag_Pl_sim AS gap_join_m12_212,
    CASE l3.ipgpSh WHEN 1 THEN pb.iv_Pl ELSE pb2.ag_Pl END AS pb_plan_col,
    CASE l3.ipgpSh WHEN 1 THEN pb.iv_iShKey ELSE pb2.ag_iShKey END AS pb_iShKey,
    CASE l3.ipgpSh WHEN 1 THEN pb.iv_ipgpKey ELSE pb2.ag_ipgpKey END AS pb_ipgpKey
FROM #l3 l3
LEFT JOIN #l4 l4 ON l4.ipgpKey = l3.ipgpKey
    AND l4.join_path = CASE l3.ipgpSh WHEN 1 THEN N'invest-gip' WHEN 2 THEN N'agency-gap' ELSE N'?' END
    AND ISNULL(l4.iuplpM12, 0) = ISNULL(l3.iuplpM12_mm, -1)
LEFT JOIN #pb_inv pb ON pb.ipgKey = l3.ipgpIpg AND l3.ipgpCstAgPn = 2102
LEFT JOIN #pb_ag pb2 ON pb2.ipgKey = l3.ipgpIpg AND pb2.cstapKey = l3.ipgpCstAgPn
ORDER BY l3.ipgpCstAgPn, l3.ipgpIpg;

-- =========================================================================
-- L6: Проверка условия JOIN PercentBrn: i.ag_iShKey = ga.ipgpSh
--     (нужны iShKey из промежуточного слоя — через деталь PercentBrn)
-- =========================================================================
RAISERROR(N'--- L6 iShKey vs ipgpSh mismatch ---', 0, 1) WITH NOWAIT;

SELECT
    l1.ipgpCstAgPn,
    l1.ipgpIpg,
    l1.ipgpSh AS ipgpSh_expected,
    CASE l1.ipgpCstAgPn WHEN 2102 THEN pb.iv_iShKey ELSE pba.ag_iShKey END AS pb_iShKey_actual,
    CASE WHEN l1.ipgpSh = CASE l1.ipgpCstAgPn WHEN 2102 THEN pb.iv_iShKey ELSE pba.ag_iShKey END
         THEN N'OK' ELSE N'MISMATCH' END AS sh_join_status,
    l1.ipgpKey AS ipgpKey_l1,
    CASE l1.ipgpCstAgPn WHEN 2102 THEN pb.iv_ipgpKey ELSE pba.ag_ipgpKey END AS ipgpKey_pb
FROM #l1 l1
LEFT JOIN #pb_inv pb ON pb.ipgKey = l1.ipgpIpg AND l1.ipgpCstAgPn = 2102
LEFT JOIN #pb_ag pba ON pba.ipgKey = l1.ipgpIpg AND pba.cstapKey = l1.ipgpCstAgPn
WHERE l1.active_on_dt = 1
ORDER BY l1.ipgpCstAgPn, l1.ipgpIpg;

-- =========================================================================
-- Вердикт
-- =========================================================================
RAISERROR(N'--- VERDICT (21.4.2) ---', 0, 1) WITH NOWAIT;

DECLARE @utpl_ok int, @utplmn_ok int, @gap_ok int, @pb_inv_ok int, @pb_ag_ok int, @sh_mis int;

SELECT @utpl_ok = COUNT(*)
FROM #l3
WHERE ipgpCstAgPn IN (2102, 849)
  AND ISNULL(plan_m12_rub, 0) <> 0;

SELECT @utplmn_ok = COUNT(*)
FROM #l3
WHERE ipgpCstAgPn IN (2102, 849)
  AND ISNULL(sum_utplmn_212, 0) <> 0;

SELECT @gap_ok = COUNT(DISTINCT ipgpKey)
FROM #l4
WHERE ISNULL(ag_Pl_sim, 0) <> 0;

SELECT @pb_inv_ok = COUNT(*)
FROM #pb_inv
WHERE ISNULL(iv_Pl, 0) <> 0;

SELECT @pb_ag_ok = COUNT(*)
FROM #pb_ag
WHERE ISNULL(ag_Pl, 0) <> 0;

SELECT @sh_mis = COUNT(*)
FROM #l1 l1
LEFT JOIN #pb_inv pb ON pb.ipgKey = l1.ipgpIpg AND l1.ipgpCstAgPn = 2102
LEFT JOIN #pb_ag pba ON pba.ipgKey = l1.ipgpIpg AND pba.cstapKey = l1.ipgpCstAgPn
WHERE l1.active_on_dt = 1
  AND l1.ipgpCstAgPn IN (2102, 849)
  AND l1.ipgpSh <> CASE l1.ipgpCstAgPn WHEN 2102 THEN pb.iv_iShKey ELSE pba.ag_iShKey END;

SET @msg = N'  L3 ipgUtPlP.iuplpM12 non-zero rows: ' + CAST(@utpl_ok AS nvarchar(10));
RAISERROR(@msg, 0, 1) WITH NOWAIT;
SET @msg = N'  L3 UtPlMn sum@212 non-zero rows: ' + CAST(@utplmn_ok AS nvarchar(10));
RAISERROR(@msg, 0, 1) WITH NOWAIT;
SET @msg = N'  L4 gap/gip @212 non-zero ipgpKeys: ' + CAST(@gap_ok AS nvarchar(10));
RAISERROR(@msg, 0, 1) WITH NOWAIT;
SET @msg = N'  L5 invest iv_Pl non-zero (2102 @ ipg 6/8/11): ' + CAST(@pb_inv_ok AS nvarchar(10));
RAISERROR(@msg, 0, 1) WITH NOWAIT;
SET @msg = N'  L5 agency ag_Pl non-zero (849/1862): ' + CAST(@pb_ag_ok AS nvarchar(10));
RAISERROR(@msg, 0, 1) WITH NOWAIT;
SET @msg = N'  L6 iShKey mismatches: ' + CAST(@sh_mis AS nvarchar(10));
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @utplmn_ok > 0 AND @utpl_ok = 0 AND (@pb_inv_ok = 0 OR @pb_ag_ok = 0)
    RAISERROR(N'  BREAKPOINT: ipgUtPlP.iuplpM* empty; PercentBrn reads M-columns, not UtPlMn (fix 21.4.3)', 0, 1) WITH NOWAIT;
ELSE IF @utpl_ok > 0 AND @gap_ok > 0 AND (@pb_inv_ok = 0 OR @pb_ag_ok = 0)
    RAISERROR(N'  BREAKPOINT: PercentBrn plan JOIN / iShKey / GROUPING (data OK through L4)', 0, 1) WITH NOWAIT;
ELSE IF @utplmn_ok = 0
    RAISERROR(N'  BREAKPOINT: UtPlMn/fixture layer (L3) — re-apply FIXTURE_06', 0, 1) WITH NOWAIT;
ELSE IF @gap_ok = 0 AND @utpl_ok > 0
    RAISERROR(N'  BREAKPOINT: ipgChRl_2606 → UtPlGr path (L4)', 0, 1) WITH NOWAIT;
ELSE
    RAISERROR(N'  BREAKPOINT: none obvious — review L5c matrix', 0, 1) WITH NOWAIT;

RAISERROR(N'=== 07v plan-align chain diag: DONE ===', 0, 1) WITH NOWAIT;
GO
