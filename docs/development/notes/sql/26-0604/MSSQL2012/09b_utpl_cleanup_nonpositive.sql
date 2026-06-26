USE [FishEye];
GO
-- =============================================================================
-- 09b_utpl_cleanup_nonpositive.sql
-- Пакет: spMstrg_2606 (Решение 15, этап 18.8.3 / deploy-day 17.3.1)
-- Назначение: sparse-очистка UtPl (lim <= 0) с сохранением сумм:
--   lim = 0  → DELETE (суммы не меняются);
--   lim < 0  → DELETE + компенсация: вычесть |lim| из другой строки того же
--              (iuplp*PlPn, stCost) — типично mn=11 / предыдущий квартал;
--              строка-компенсатор с lim <= 0 после UPDATE тоже удаляется (sparse).
-- Отрицательные значения — legacy-округление (mn=12 / Q4 @212), ранее уравнивали SUM.
-- Порядок: после 09a, перед 09c. SQL Server 2012 SP4+.
-- =============================================================================
SET NOCOUNT ON;
GO

PRINT N'=== 09b: cleanup UtPl lim<=0 (sparse + sum preserve) ===';
PRINT N'Дата: ' + CONVERT(nvarchar(30), GETDATE(), 121);

DECLARE @mn0 int, @mnNeg int, @qu0 int, @quNeg int, @ye0 int, @yeNeg int;

SELECT @mn0 = SUM(CASE WHEN iuplpmLim = 0 THEN 1 ELSE 0 END),
       @mnNeg = SUM(CASE WHEN iuplpmLim < 0 THEN 1 ELSE 0 END)
FROM ags.ipgUtPlPnLmMn;

SELECT @qu0 = SUM(CASE WHEN iuplpqLim = 0 THEN 1 ELSE 0 END),
       @quNeg = SUM(CASE WHEN iuplpqLim < 0 THEN 1 ELSE 0 END)
FROM ags.ipgUtPlPnLmQu;

SELECT @ye0 = SUM(CASE WHEN iuplpyLim = 0 THEN 1 ELSE 0 END),
       @yeNeg = SUM(CASE WHEN iuplpyLim < 0 THEN 1 ELSE 0 END)
FROM ags.ipgUtPlPnLmYe;

PRINT N'  BEFORE LmMn: lim=0 ' + CAST(ISNULL(@mn0, 0) AS nvarchar(10))
    + N', lim<0 ' + CAST(ISNULL(@mnNeg, 0) AS nvarchar(10));
PRINT N'  BEFORE LmQu: lim=0 ' + CAST(ISNULL(@qu0, 0) AS nvarchar(10))
    + N', lim<0 ' + CAST(ISNULL(@quNeg, 0) AS nvarchar(10));
PRINT N'  BEFORE LmYe: lim=0 ' + CAST(ISNULL(@ye0, 0) AS nvarchar(10))
    + N', lim<0 ' + CAST(ISNULL(@yeNeg, 0) AS nvarchar(10));

BEGIN TRANSACTION;

DECLARE @delMn0 int, @delQu0 int, @delYe0 int;
DECLARE @normMn int, @normQu int, @normYe int;
SET @normMn = 0; SET @normQu = 0; SET @normYe = 0;

DELETE FROM ags.ipgUtPlPnLmMn WHERE iuplpmLim = 0;
SET @delMn0 = @@ROWCOUNT;
DELETE FROM ags.ipgUtPlPnLmQu WHERE iuplpqLim = 0;
SET @delQu0 = @@ROWCOUNT;
DELETE FROM ags.ipgUtPlPnLmYe WHERE iuplpyLim = 0;
SET @delYe0 = @@ROWCOUNT;

-- LmMn: нормализация отрицательных
DECLARE @k int, @plPn int, @stCost int, @adj decimal(23, 8);
DECLARE @tgtKey int, @tgtLim decimal(23, 8);

WHILE EXISTS (SELECT 1 FROM ags.ipgUtPlPnLmMn WHERE iuplpmLim < 0)
BEGIN
    SELECT TOP 1 @k = iuplpmKey, @plPn = iuplpmPlPn, @stCost = iuplpmStCost,
           @adj = -iuplpmLim
    FROM ags.ipgUtPlPnLmMn
    WHERE iuplpmLim < 0
    ORDER BY iuplpmKey;

    DELETE FROM ags.ipgUtPlPnLmMn WHERE iuplpmKey = @k;
    SET @normMn = @normMn + 1;

    WHILE @adj > 0.00000001
    BEGIN
        SET @tgtKey = NULL;
        SELECT TOP 1 @tgtKey = iuplpmKey, @tgtLim = iuplpmLim
        FROM ags.ipgUtPlPnLmMn
        WHERE iuplpmPlPn = @plPn AND iuplpmStCost = @stCost AND iuplpmLim > 0
        ORDER BY CASE WHEN iuplpmMn = 11 THEN 0 WHEN iuplpmMn = 10 THEN 1 ELSE 2 END,
                 iuplpmLim DESC, iuplpmMn DESC;

        IF @tgtKey IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR(N'09b FAIL: no positive LmMn row to absorb remainder plPn=%d stCost=%d.', 16, 1, @plPn, @stCost);
            RETURN;
        END;

        IF @tgtLim <= @adj + 0.00000001
        BEGIN
            DELETE FROM ags.ipgUtPlPnLmMn WHERE iuplpmKey = @tgtKey;
            SET @adj = @adj - @tgtLim;
        END
        ELSE
        BEGIN
            UPDATE ags.ipgUtPlPnLmMn
            SET iuplpmLim = CAST(@tgtLim - @adj AS decimal(23, 8))
            WHERE iuplpmKey = @tgtKey;
            SET @adj = 0;
        END;
    END;
END;

-- LmQu: нормализация отрицательных
DECLARE @qu int;
WHILE EXISTS (SELECT 1 FROM ags.ipgUtPlPnLmQu WHERE iuplpqLim < 0)
BEGIN
    SELECT TOP 1 @k = iuplpqKey, @plPn = iuplpqPlPn, @stCost = iuplpqStCost, @qu = iuplpqQu,
           @adj = -iuplpqLim
    FROM ags.ipgUtPlPnLmQu
    WHERE iuplpqLim < 0
    ORDER BY iuplpqKey;

    DELETE FROM ags.ipgUtPlPnLmQu WHERE iuplpqKey = @k;
    SET @normQu = @normQu + 1;

    WHILE @adj > 0.00000001
    BEGIN
        SET @tgtKey = NULL;
        SELECT TOP 1 @tgtKey = iuplpqKey, @tgtLim = iuplpqLim
        FROM ags.ipgUtPlPnLmQu
        WHERE iuplpqPlPn = @plPn AND iuplpqStCost = @stCost AND iuplpqLim > 0
        ORDER BY CASE WHEN iuplpqQu = @qu - 1 THEN 0 WHEN iuplpqQu = 3 THEN 1 ELSE 2 END,
                 iuplpqLim DESC, iuplpqQu DESC;

        IF @tgtKey IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR(N'09b FAIL: no positive LmQu row to absorb remainder plPn=%d stCost=%d.', 16, 1, @plPn, @stCost);
            RETURN;
        END;

        IF @tgtLim <= @adj + 0.00000001
        BEGIN
            DELETE FROM ags.ipgUtPlPnLmQu WHERE iuplpqKey = @tgtKey;
            SET @adj = @adj - @tgtLim;
        END
        ELSE
        BEGIN
            UPDATE ags.ipgUtPlPnLmQu
            SET iuplpqLim = CAST(@tgtLim - @adj AS decimal(23, 8))
            WHERE iuplpqKey = @tgtKey;
            SET @adj = 0;
        END;
    END;
END;

-- LmYe: нормализация отрицательных
WHILE EXISTS (SELECT 1 FROM ags.ipgUtPlPnLmYe WHERE iuplpyLim < 0)
BEGIN
    SELECT TOP 1 @k = iuplpyKey, @plPn = iuplpyPlPn, @stCost = iuplpyStCost,
           @adj = -iuplpyLim
    FROM ags.ipgUtPlPnLmYe
    WHERE iuplpyLim < 0
    ORDER BY iuplpyKey;

    DELETE FROM ags.ipgUtPlPnLmYe WHERE iuplpyKey = @k;
    SET @normYe = @normYe + 1;

    WHILE @adj > 0.00000001
    BEGIN
        SET @tgtKey = NULL;
        SELECT TOP 1 @tgtKey = iuplpyKey, @tgtLim = iuplpyLim
        FROM ags.ipgUtPlPnLmYe
        WHERE iuplpyPlPn = @plPn AND iuplpyStCost = @stCost AND iuplpyLim > 0
        ORDER BY iuplpyLim DESC, iuplpyKey DESC;

        IF @tgtKey IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR(N'09b FAIL: no positive LmYe row to absorb remainder plPn=%d stCost=%d.', 16, 1, @plPn, @stCost);
            RETURN;
        END;

        IF @tgtLim <= @adj + 0.00000001
        BEGIN
            DELETE FROM ags.ipgUtPlPnLmYe WHERE iuplpyKey = @tgtKey;
            SET @adj = @adj - @tgtLim;
        END
        ELSE
        BEGIN
            UPDATE ags.ipgUtPlPnLmYe
            SET iuplpyLim = CAST(@tgtLim - @adj AS decimal(23, 8))
            WHERE iuplpyKey = @tgtKey;
            SET @adj = 0;
        END;
    END;
END;

DECLARE @left int;
SELECT @left = COUNT(*) FROM ags.ipgUtPlPnLmMn WHERE iuplpmLim <= 0;
IF @left > 0 BEGIN ROLLBACK TRANSACTION; RAISERROR(N'09b FAIL: %d LmMn lim<=0 remain.', 16, 1, @left); RETURN; END;
SELECT @left = COUNT(*) FROM ags.ipgUtPlPnLmQu WHERE iuplpqLim <= 0;
IF @left > 0 BEGIN ROLLBACK TRANSACTION; RAISERROR(N'09b FAIL: %d LmQu lim<=0 remain.', 16, 1, @left); RETURN; END;
SELECT @left = COUNT(*) FROM ags.ipgUtPlPnLmYe WHERE iuplpyLim <= 0;
IF @left > 0 BEGIN ROLLBACK TRANSACTION; RAISERROR(N'09b FAIL: %d LmYe lim<=0 remain.', 16, 1, @left); RETURN; END;

COMMIT TRANSACTION;

PRINT N'  DELETE lim=0: LmMn=' + CAST(@delMn0 AS nvarchar(10))
    + N' LmQu=' + CAST(@delQu0 AS nvarchar(10))
    + N' LmYe=' + CAST(@delYe0 AS nvarchar(10));
PRINT N'  NORMALIZE lim<0: LmMn=' + CAST(@normMn AS nvarchar(10))
    + N' LmQu=' + CAST(@normQu AS nvarchar(10))
    + N' LmYe=' + CAST(@normYe AS nvarchar(10));
PRINT N'09b cleanup | PASS';
GO
