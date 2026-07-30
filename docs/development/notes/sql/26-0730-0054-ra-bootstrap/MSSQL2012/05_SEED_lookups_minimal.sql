-- =============================================================================
-- 05_SEED_lookups_minimal.sql — минимальные справочники для FK mapping
-- Access ra_ft 1..6; ra_at type=1 (ревизия отчётов агента)
-- Идемпотентно: вставка только отсутствующих ключей
-- =============================================================================

PRINT '=== 05_SEED_lookups_minimal ===';

IF OBJECT_ID(N'ags.ra_at', N'U') IS NOT NULL
BEGIN
    SET IDENTITY_INSERT ags.ra_at ON;
    IF NOT EXISTS (SELECT 1 FROM ags.ra_at WHERE at_key = 1)
        INSERT INTO ags.ra_at (at_key, at_name) VALUES (1, N'ревизия отчётов агента');
    SET IDENTITY_INSERT ags.ra_at OFF;
    PRINT 'ra_at seed checked';
END
GO

IF OBJECT_ID(N'ags.ra_ft', N'U') IS NOT NULL
BEGIN
    SET IDENTITY_INSERT ags.ra_ft ON;
    IF NOT EXISTS (SELECT 1 FROM ags.ra_ft WHERE ft_key = 1)
        INSERT INTO ags.ra_ft (ft_key, ft_name) VALUES (1, N'отчёты агента');
    IF NOT EXISTS (SELECT 1 FROM ags.ra_ft WHERE ft_key = 2)
        INSERT INTO ags.ra_ft (ft_key, ft_name) VALUES (2, N'хранение оборудования и стройконтроль');
    IF NOT EXISTS (SELECT 1 FROM ags.ra_ft WHERE ft_key = 3)
        INSERT INTO ags.ra_ft (ft_key, ft_name) VALUES (3, N'аренда земли');
    IF NOT EXISTS (SELECT 1 FROM ags.ra_ft WHERE ft_key = 4)
        INSERT INTO ags.ra_ft (ft_key, ft_name) VALUES (4, N'агентское вознаграждение');
    IF NOT EXISTS (SELECT 1 FROM ags.ra_ft WHERE ft_key = 5)
        INSERT INTO ags.ra_ft (ft_key, ft_name) VALUES (5, N'отчёты всех агентов');
    IF NOT EXISTS (SELECT 1 FROM ags.ra_ft WHERE ft_key = 6)
        INSERT INTO ags.ra_ft (ft_key, ft_name) VALUES (6, N'23-0627_агентское вознаграждение');
    SET IDENTITY_INSERT ags.ra_ft OFF;
    PRINT 'ra_ft seed checked (1..6)';
END
GO

PRINT '=== 05_SEED_lookups_minimal: готово ===';
GO
