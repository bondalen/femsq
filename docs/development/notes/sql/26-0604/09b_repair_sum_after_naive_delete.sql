USE [FishEye];
GO
-- =============================================================================
-- 09b_repair_sum_after_naive_delete.sql
-- Dev-only (2026-06-26): восстановить SUM после первого прогона 09b без компенсации.
-- Идемпотентно: вычитает (sum - ref) из mn=11 / квартала 3 @212 для известных overshoot.
-- =============================================================================
SET NOCOUNT ON;
GO

PRINT N'=== 09b_repair: restore UtPl sums after naive delete ===';

BEGIN TRANSACTION;

DECLARE @eps decimal(23, 8) = 0.00000001;
DECLARE @plPn int, @stCost int, @ref decimal(23, 8), @sum decimal(23, 8), @delta decimal(23, 8);
DECLARE @tgtKey int, @tgtLim decimal(23, 8);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT up.iuplpKey, 212,
           COALESCE(l212.ipgplLim, p.ipgpSmTtl),
           SUM(m.iuplpmLim)
    FROM ags.ipgUtPlP up
    INNER JOIN ags.ipgPn p ON p.ipgpKey = up.iuplpIpgPn
    INNER JOIN ags.ipgUtPlPnLmMn m ON m.iuplpmPlPn = up.iuplpKey AND m.iuplpmStCost = 212
    LEFT JOIN ags.ipgPnLim l212 ON l212.ipgplPn = p.ipgpKey AND l212.ipgplStCost = 212
    WHERE up.iuplpKey IN (480, 982, 1018, 1019, 1020, 1024, 1025, 1026, 1029)
    GROUP BY up.iuplpKey, l212.ipgplLim, p.ipgpSmTtl
    HAVING SUM(m.iuplpmLim) - COALESCE(l212.ipgplLim, p.ipgpSmTtl) > @eps;

OPEN cur;
FETCH NEXT FROM cur INTO @plPn, @stCost, @ref, @sum;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @delta = @sum - @ref;

    WHILE @delta > @eps
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
            RAISERROR(N'09b_repair FAIL: no target LmMn plPn=%d', 16, 1, @plPn);
            RETURN;
        END;

        IF @tgtLim <= @delta + @eps
        BEGIN
            DELETE FROM ags.ipgUtPlPnLmMn WHERE iuplpmKey = @tgtKey;
            SET @delta = @delta - @tgtLim;
        END
        ELSE
        BEGIN
            UPDATE ags.ipgUtPlPnLmMn
            SET iuplpmLim = CAST(@tgtLim - @delta AS decimal(23, 8))
            WHERE iuplpmKey = @tgtKey;
            SET @delta = 0;
        END;
    END;

    PRINT N'  LmMn plPn=' + CAST(@plPn AS nvarchar) + N' repaired';
    FETCH NEXT FROM cur INTO @plPn, @stCost, @ref, @sum;
END;
CLOSE cur; DEALLOCATE cur;

-- LmQu 982 Q3: компенсация удалённого Q4 negative
DECLARE @qSum decimal(23, 8), @yRef decimal(23, 8);
SELECT @qSum = SUM(iuplpqLim), @yRef = MAX(y.iuplpyLim)
FROM ags.ipgUtPlPnLmQu q
INNER JOIN ags.ipgUtPlPnLmYe y ON y.iuplpyPlPn = q.iuplpqPlPn AND y.iuplpyStCost = q.iuplpqStCost
WHERE q.iuplpqPlPn = 982 AND q.iuplpqStCost = 212
GROUP BY y.iuplpyLim;

IF @qSum - @yRef > @eps
BEGIN
    SET @delta = @qSum - @yRef;
    SELECT @tgtKey = iuplpqKey, @tgtLim = iuplpqLim
    FROM ags.ipgUtPlPnLmQu
    WHERE iuplpqPlPn = 982 AND iuplpqStCost = 212 AND iuplpqQu = 3;

    UPDATE ags.ipgUtPlPnLmQu
    SET iuplpqLim = CAST(@tgtLim - @delta AS decimal(23, 8))
    WHERE iuplpqKey = @tgtKey;
    PRINT N'  LmQu plPn=982 Q3 delta=' + CAST(@delta AS nvarchar(20));
END;

COMMIT TRANSACTION;
PRINT N'09b_repair | PASS';
GO
