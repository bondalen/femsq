USE [FishEye];
GO
-- =============================================================================
-- 09a_utpl_audit_zero_negative.sql
-- Пакет: spMstrg_2606 (Решение 15, этап 18.8.4 / deploy-day 17.3.1)
-- Назначение: READ ONLY аудит строк UtPl с lim <= 0 перед 09b/09c.
-- При нарушениях — отчёт и RAISERROR (прервать цепочку до очистки).
-- SQL Server 2012 SP4+.
-- =============================================================================
SET NOCOUNT ON;
GO

PRINT N'=== 09a: audit UtPl lim<=0 ===';
PRINT N'Дата: ' + CONVERT(nvarchar(30), GETDATE(), 121);

DECLARE @mn0 int, @mnNeg int, @qu0 int, @quNeg int, @ye0 int, @yeNeg int;
DECLARE @total int;

SELECT @mn0 = SUM(CASE WHEN iuplpmLim = 0 THEN 1 ELSE 0 END),
       @mnNeg = SUM(CASE WHEN iuplpmLim < 0 THEN 1 ELSE 0 END)
FROM ags.ipgUtPlPnLmMn;

SELECT @qu0 = SUM(CASE WHEN iuplpqLim = 0 THEN 1 ELSE 0 END),
       @quNeg = SUM(CASE WHEN iuplpqLim < 0 THEN 1 ELSE 0 END)
FROM ags.ipgUtPlPnLmQu;

SELECT @ye0 = SUM(CASE WHEN iuplpyLim = 0 THEN 1 ELSE 0 END),
       @yeNeg = SUM(CASE WHEN iuplpyLim < 0 THEN 1 ELSE 0 END)
FROM ags.ipgUtPlPnLmYe;

SET @total = ISNULL(@mn0, 0) + ISNULL(@mnNeg, 0)
           + ISNULL(@qu0, 0) + ISNULL(@quNeg, 0)
           + ISNULL(@ye0, 0) + ISNULL(@yeNeg, 0);

PRINT N'  ipgUtPlPnLmMn: lim=0 ' + CAST(ISNULL(@mn0, 0) AS nvarchar(10))
    + N', lim<0 ' + CAST(ISNULL(@mnNeg, 0) AS nvarchar(10));
PRINT N'  ipgUtPlPnLmQu: lim=0 ' + CAST(ISNULL(@qu0, 0) AS nvarchar(10))
    + N', lim<0 ' + CAST(ISNULL(@quNeg, 0) AS nvarchar(10));
PRINT N'  ipgUtPlPnLmYe: lim=0 ' + CAST(ISNULL(@ye0, 0) AS nvarchar(10))
    + N', lim<0 ' + CAST(ISNULL(@yeNeg, 0) AS nvarchar(10));
PRINT N'  TOTAL violations: ' + CAST(@total AS nvarchar(10));

IF @total > 0
BEGIN
    IF ISNULL(@mn0, 0) + ISNULL(@mnNeg, 0) > 0
    BEGIN
        PRINT N'--- sample LmMn (TOP 20) ---';
        SELECT TOP 20 iuplpmKey, iuplpmPlPn, iuplpmMn, iuplpmStCost, iuplpmLim
        FROM ags.ipgUtPlPnLmMn
        WHERE iuplpmLim <= 0
        ORDER BY iuplpmKey;
    END;

    IF ISNULL(@qu0, 0) + ISNULL(@quNeg, 0) > 0
    BEGIN
        PRINT N'--- sample LmQu (TOP 20) ---';
        SELECT TOP 20 iuplpqKey, iuplpqPlPn, iuplpqQu, iuplpqStCost, iuplpqLim
        FROM ags.ipgUtPlPnLmQu
        WHERE iuplpqLim <= 0
        ORDER BY iuplpqKey;
    END;

    IF ISNULL(@ye0, 0) + ISNULL(@yeNeg, 0) > 0
    BEGIN
        PRINT N'--- sample LmYe (TOP 20) ---';
        SELECT TOP 20 iuplpyKey, iuplpyPlPn, iuplpyStCost, iuplpyLim
        FROM ags.ipgUtPlPnLmYe
        WHERE iuplpyLim <= 0
        ORDER BY iuplpyKey;
    END;

    RAISERROR(N'09a FAIL: %d rows with lim<=0. Run 09b before 09c.', 16, 1, @total);
    RETURN;
END;

PRINT N'09a audit | PASS (0 violations)';
GO
