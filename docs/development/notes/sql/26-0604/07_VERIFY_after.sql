USE [FishEye];
GO
-- =============================================================================
-- 07_VERIFY_after.sql
-- Проверки после полного применения пакета spMstrg_2606.
-- Эталон приёмки (dev, цепь 5): ipgCh=5, MounthEndDate='2022-12-31'
-- =============================================================================

SET NOCOUNT ON;
GO

PRINT N'=== 07_VERIFY_after: пакет spMstrg_2606 ===';
PRINT N'Дата: ' + CONVERT(nvarchar(30), GETDATE(), 121);
GO

-- -----------------------------------------------------------------------------
-- 1. Ключевые объекты _2606
-- -----------------------------------------------------------------------------
PRINT N'--- 1. Объекты _2606 ---';
SELECT
    t.obj_name,
    t.obj_type,
    CASE WHEN o.object_id IS NOT NULL THEN N'OK' ELSE N'MISSING!' END AS status
FROM (VALUES
    (N'ipgChRl_2606',                    N'U'),
    (N'fnIpgChRlEnd_2606',               N'FN'),
    (N'factDoc',                     N'U'),
    (N'factDocCost',                 N'U'),
    (N'fnIpgChDats_2606',                N'IF'),
    (N'stIpgOutLimPn_2606',              N'U'),
    (N'fnIpgChRsltCstUtl2_2606',     N'TF'),
    (N'fnIpgChRsltCstUtlPercentBrn_2606', N'IF'),
    (N'fnMasteringStIpgStCost_2606', N'IF'),
    (N'spMstrg_2606',                N'P'),
    (N'spMstrg_2606_ResultSet1',     N'U'),
    (N'spMstrg_2606_ResultSet7',     N'U')
) AS t(obj_name, obj_type)
LEFT JOIN sys.objects o
    ON o.name = t.obj_name
   AND o.schema_id = SCHEMA_ID(N'ags')
   AND (
        (t.obj_type = N'U'  AND o.type = N'U')
     OR (t.obj_type = N'P'  AND o.type = N'P')
     OR (t.obj_type = N'FN' AND o.type = N'FN')
     OR (t.obj_type = N'IF' AND o.type IN (N'IF', N'TF', N'FN'))
     OR (t.obj_type = N'TF' AND o.type IN (N'TF', N'IF'))
   );
GO

-- -----------------------------------------------------------------------------
-- 2. _2605 / _2408 не затронуты
-- -----------------------------------------------------------------------------
PRINT N'--- 2. Параллельность: _2408/_2605 на месте ---';
SELECT name, type_desc
FROM sys.objects
WHERE schema_id = SCHEMA_ID(N'ags')
  AND name IN (
    N'spMstrg_2605', N'spMstrg_2408_SaveToTables',
    N'fnIpgChRsltCstUtlPercentBrn_2605', N'fnIpgChRsltCstUtlPercentBrn_2408'
  )
ORDER BY name;
GO

-- -----------------------------------------------------------------------------
-- 3. factDocCost наполнен
-- -----------------------------------------------------------------------------
PRINT N'--- 3. factDocCost ---';
SELECT COUNT(*) AS factDocCost_rows FROM ags.factDocCost;
GO

-- -----------------------------------------------------------------------------
-- 4. PercentBrn / fn2 — COUNT (цепь 5, dev-эталон)
-- -----------------------------------------------------------------------------
PRINT N'--- 4. fn2 / PercentBrn chain 5 (эталон dev post-calendar: PBrn_2606=15262/17 дат, _2605=14447/16) ---';
DECLARE @ipgCh int = 5;

SELECT N'fn2_2606' AS test_name,
       (SELECT COUNT(*) FROM ags.fnIpgChRsltCstUtl2_2606(@ipgCh, NULL, NULL) f WHERE f.ipgKey IS NOT NULL) AS cnt,
       11587 AS expected_dev
UNION ALL
SELECT N'PercentBrn_2606',
       (SELECT COUNT(*) FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, NULL, NULL)),
       15262
UNION ALL
SELECT N'PercentBrn_2605',
       (SELECT COUNT(*) FROM ags.fnIpgChRsltCstUtlPercentBrn_2605(@ipgCh, NULL)),
       14447
UNION ALL
SELECT N'dateRslt_2606',
       (SELECT COUNT(DISTINCT dateRslt) FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, NULL, NULL)),
       17;
GO

-- -----------------------------------------------------------------------------
-- 5. spMstrg_2606 ResultSet (после saveToTables=1)
--     Запустите 07_VERIFY_spMstrg_2606_chain5.sql для полного прогона.
-- -----------------------------------------------------------------------------
PRINT N'--- 5. spMstrg_2606_ResultSet* (текущее наполнение) ---';
SELECT N'RS1' AS rs, COUNT(*) AS cnt FROM ags.spMstrg_2606_ResultSet1
UNION ALL SELECT N'RS4', COUNT(*) FROM ags.spMstrg_2606_ResultSet4
UNION ALL SELECT N'RS7', COUNT(*) FROM ags.spMstrg_2606_ResultSet7;
GO

-- -----------------------------------------------------------------------------
-- 6. Изоляция ResultSet: _2606 ≠ перезапись _2408
-- -----------------------------------------------------------------------------
PRINT N'--- 6. ResultSet _2408 vs _2606 (разные таблицы) ---';
SELECT
    (SELECT COUNT(*) FROM sys.tables WHERE schema_id = SCHEMA_ID(N'ags') AND name LIKE N'spMstrg_2408_ResultSet%') AS rs_2408_tables,
    (SELECT COUNT(*) FROM sys.tables WHERE schema_id = SCHEMA_ID(N'ags') AND name LIKE N'spMstrg_2606_ResultSet%') AS rs_2606_tables;
GO

PRINT N'=== 07_VERIFY_after: завершено ===';
GO
