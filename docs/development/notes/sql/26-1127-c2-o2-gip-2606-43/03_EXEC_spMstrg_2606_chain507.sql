-- =============================================================================
-- §4.3: remaster _2606 @507 после UtPl seed; проверка ненулевого плана.
-- =============================================================================
SET NOCOUNT ON;

DECLARE @t0 datetime2 = SYSDATETIME();

EXEC ags.spMstrg_2606
  @ipgCh = 507,
  @MounthEndDate = '20261130',
  @ipgStKey = NULL,
  @stCostKey = 212,
  @saveToTables = 1;

SELECT
    DATEDIFF(millisecond, @t0, SYSDATETIME()) AS elapsed_ms,
    COUNT(*) AS rs1_rows,
    SUM(CASE WHEN ag_ipgpKey IS NOT NULL THEN 1 ELSE 0 END) AS ag_ipgp_nn,
    SUM(CASE WHEN ag_lim IS NOT NULL THEN 1 ELSE 0 END) AS ag_lim_nn,
    SUM(CASE WHEN ag_Pl IS NOT NULL AND ag_Pl <> 0 THEN 1 ELSE 0 END) AS ag_Pl_nz,
    SUM(CASE WHEN ag_PlAccum IS NOT NULL AND ag_PlAccum <> 0 THEN 1 ELSE 0 END) AS ag_PlAccum_nz
FROM ags.spMstrg_2606_ResultSet1
WHERE dateRslt = '2026-11-30';

-- пилоты: план на их cstAgPn
SELECT TOP 10
    r.cstapKey,
    r.ag_ipgpKey,
    r.ag_lim,
    r.ag_Pl,
    r.ag_PlAccum
FROM ags.spMstrg_2606_ResultSet1 r
WHERE r.dateRslt = '2026-11-30'
  AND r.ag_Pl IS NOT NULL AND r.ag_Pl <> 0
ORDER BY ABS(r.ag_Pl) DESC;
GO
