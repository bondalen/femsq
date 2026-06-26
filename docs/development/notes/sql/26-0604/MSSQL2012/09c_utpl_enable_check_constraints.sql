USE [FishEye];
GO
-- =============================================================================
-- 09c_utpl_enable_check_constraints.sql
-- Пакет: spMstrg_2606 (Решение 15, этап 18.8.4 / deploy-day 17.3.1)
-- Назначение: заменить legacy CHECK (iuplp*Lim <> 0) на sparse-правило (lim > 0)
--   и включить с проверкой существующих данных (WITH CHECK).
-- Предусловие: 09a PASS, 09b выполнен (lim<=0 = 0).
-- SQL Server 2012 SP4+.
-- =============================================================================
SET NOCOUNT ON;
GO

PRINT N'=== 09c: enable UtPl CHECK (lim > 0) ===';
PRINT N'Дата: ' + CONVERT(nvarchar(30), GETDATE(), 121);

DECLARE @viol int;
SELECT @viol = COUNT(*) FROM ags.ipgUtPlPnLmMn WHERE iuplpmLim <= 0;
SELECT @viol = @viol + (SELECT COUNT(*) FROM ags.ipgUtPlPnLmQu WHERE iuplpqLim <= 0);
SELECT @viol = @viol + (SELECT COUNT(*) FROM ags.ipgUtPlPnLmYe WHERE iuplpyLim <= 0);

IF @viol > 0
BEGIN
    RAISERROR(N'09c FAIL: %d rows lim<=0 remain. Run 09b first.', 16, 1, @viol);
    RETURN;
END;

BEGIN TRANSACTION;

-- LmMn: снять legacy <>0, добавить >0
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_ipgUtPlPnLmMn<>0' AND parent_object_id = OBJECT_ID(N'ags.ipgUtPlPnLmMn'))
    ALTER TABLE ags.ipgUtPlPnLmMn DROP CONSTRAINT [CK_ipgUtPlPnLmMn<>0];

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_ipgUtPlPnLmMn_gt0' AND parent_object_id = OBJECT_ID(N'ags.ipgUtPlPnLmMn'))
    ALTER TABLE ags.ipgUtPlPnLmMn DROP CONSTRAINT [CK_ipgUtPlPnLmMn_gt0];

ALTER TABLE ags.ipgUtPlPnLmMn WITH CHECK
    ADD CONSTRAINT [CK_ipgUtPlPnLmMn_gt0] CHECK ([iuplpmLim] > (0));

-- LmQu
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_ipgUtPlPnLmQu<>0' AND parent_object_id = OBJECT_ID(N'ags.ipgUtPlPnLmQu'))
    ALTER TABLE ags.ipgUtPlPnLmQu DROP CONSTRAINT [CK_ipgUtPlPnLmQu<>0];

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_ipgUtPlPnLmQu_gt0' AND parent_object_id = OBJECT_ID(N'ags.ipgUtPlPnLmQu'))
    ALTER TABLE ags.ipgUtPlPnLmQu DROP CONSTRAINT [CK_ipgUtPlPnLmQu_gt0];

ALTER TABLE ags.ipgUtPlPnLmQu WITH CHECK
    ADD CONSTRAINT [CK_ipgUtPlPnLmQu_gt0] CHECK ([iuplpqLim] > (0));

-- LmYe
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_ipgUtPlPnLmYe<>0' AND parent_object_id = OBJECT_ID(N'ags.ipgUtPlPnLmYe'))
    ALTER TABLE ags.ipgUtPlPnLmYe DROP CONSTRAINT [CK_ipgUtPlPnLmYe<>0];

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_ipgUtPlPnLmYe_gt0' AND parent_object_id = OBJECT_ID(N'ags.ipgUtPlPnLmYe'))
    ALTER TABLE ags.ipgUtPlPnLmYe DROP CONSTRAINT [CK_ipgUtPlPnLmYe_gt0];

ALTER TABLE ags.ipgUtPlPnLmYe WITH CHECK
    ADD CONSTRAINT [CK_ipgUtPlPnLmYe_gt0] CHECK ([iuplpyLim] > (0));

COMMIT TRANSACTION;

-- верификация
DECLARE @bad int = 0;
SELECT @bad = COUNT(*)
FROM sys.check_constraints c
WHERE c.parent_object_id IN (
    OBJECT_ID(N'ags.ipgUtPlPnLmMn'),
    OBJECT_ID(N'ags.ipgUtPlPnLmQu'),
    OBJECT_ID(N'ags.ipgUtPlPnLmYe')
)
AND (c.is_disabled = 1 OR c.is_not_trusted = 1);

IF @bad > 0
BEGIN
    RAISERROR(N'09c FAIL: %d CHECK constraints disabled or not trusted.', 16, 1, @bad);
    RETURN;
END;

PRINT N'--- CHECK status ---';
SELECT o.name AS tbl, c.name AS ck_name, c.is_disabled, c.is_not_trusted, c.definition
FROM sys.check_constraints c
INNER JOIN sys.objects o ON o.object_id = c.parent_object_id
WHERE o.name IN (N'ipgUtPlPnLmMn', N'ipgUtPlPnLmQu', N'ipgUtPlPnLmYe')
ORDER BY o.name, c.name;

PRINT N'09c enable CHECK | PASS';
GO
