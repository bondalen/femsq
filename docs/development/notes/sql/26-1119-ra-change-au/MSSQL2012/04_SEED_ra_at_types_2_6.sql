-- =============================================================================
-- 04_SEED_ra_at_types_2_6.sql — типы ревизии 2..6 для FK ags.ra_a.adt_type
-- На DEV-гейте без этих ключей updateAudit(type=5) падал на FK_ra_a_type.
-- Идемпотентно. SQL Server 2012.
-- =============================================================================
SET NOCOUNT ON;
PRINT '=== 04_SEED ra_at types 2..6 ===';

IF OBJECT_ID(N'ags.ra_at', N'U') IS NULL
BEGIN
    RAISERROR(N'ags.ra_at отсутствует', 16, 1);
    RETURN;
END

SET IDENTITY_INSERT ags.ra_at ON;

IF NOT EXISTS (SELECT 1 FROM ags.ra_at WHERE at_key = 2)
    INSERT INTO ags.ra_at (at_key, at_name) VALUES (2, N'хранение / стройконтроль');
IF NOT EXISTS (SELECT 1 FROM ags.ra_at WHERE at_key = 3)
    INSERT INTO ags.ra_at (at_key, at_name) VALUES (3, N'аренда земли');
IF NOT EXISTS (SELECT 1 FROM ags.ra_at WHERE at_key = 4)
    INSERT INTO ags.ra_at (at_key, at_name) VALUES (4, N'агентское вознаграждение');
IF NOT EXISTS (SELECT 1 FROM ags.ra_at WHERE at_key = 5)
    INSERT INTO ags.ra_at (at_key, at_name) VALUES (5, N'отчёты всех агентов');
IF NOT EXISTS (SELECT 1 FROM ags.ra_at WHERE at_key = 6)
    INSERT INTO ags.ra_at (at_key, at_name) VALUES (6, N'агентское вознаграждение (акты)');

SET IDENTITY_INSERT ags.ra_at OFF;

SELECT at_key, at_name FROM ags.ra_at ORDER BY at_key;
PRINT '=== 04_SEED: готово ===';
GO
