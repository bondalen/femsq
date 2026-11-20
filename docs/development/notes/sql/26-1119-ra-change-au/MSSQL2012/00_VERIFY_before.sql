-- =============================================================================
-- 00_VERIFY_before.sql — precheck перед CREATE ra_change_au
-- =============================================================================
SET NOCOUNT ON;
PRINT '=== 00_VERIFY_before ra_change_au ===';

IF OBJECT_ID(N'ags.ra_change', N'U') IS NULL
BEGIN
    RAISERROR(N'ags.ra_change отсутствует — пакет остановлен', 16, 1);
    RETURN;
END

IF OBJECT_ID(N'ags.ra_change_au', N'U') IS NOT NULL
    PRINT 'WARN: ags.ra_change_au уже существует — 01 будет skip CREATE';
ELSE
    PRINT 'OK: ags.ra_change_au отсутствует (ожидаемо для первого прогона)';

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'ags.ra_change')
      AND name = N'ЗаПериодЗаОтчётОдинНомер'
)
    PRINT 'OK: UX ЗаПериодЗаОтчётОдинНомер на месте';
ELSE
    PRINT 'WARN: UX ЗаПериодЗаОтчётОдинНомер не найден';

SELECT COUNT(*) AS ra_change_cnt FROM ags.ra_change;
GO
