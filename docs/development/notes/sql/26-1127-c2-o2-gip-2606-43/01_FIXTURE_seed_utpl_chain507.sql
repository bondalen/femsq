-- =============================================================================
-- DEV-only §4.3: seed UtPl + UtPlGr на цепи 507 / ipg 27 (3 пилота).
-- Профиль E: равные месяцы, остаток δ → M12 (ось T AUTHOR / G-ip).
-- Стенд: FishEye_prod_noM6. Откат: 99_ROLLBACK_*.sql
-- =============================================================================
SET NOCOUNT ON;

DECLARE @ipgCh int = 507;
DECLARE @ipg int = 27;
DECLARE @agKey int = 24; -- ogAg of ipg.og
DECLARE @tag nvarchar(40) = N'FEMSQ_O2_43_' + CONVERT(nvarchar(8), GETDATE(), 112);
DECLARE @grKey int;
DECLARE @plKey int;
DECLARE @ipgcrKey int = (SELECT ipgcrKey FROM ags.ipgChRl WHERE ipgcrChain = @ipgCh AND ipgcrIpg = @ipg);
DECLARE @ipgcrvKey int = (SELECT ipgcrvKey FROM ags.ipgChRl_2606 WHERE ipgcrvChain = @ipgCh AND ipgcrvIpg = @ipg);

IF @ipgcrKey IS NULL OR @ipgcrvKey IS NULL
BEGIN
    RAISERROR(N'ipgChRl / ipgChRl_2606 missing for chain 507 / ipg 27', 16, 1);
    RETURN;
END;

IF EXISTS (SELECT 1 FROM ags.ipgUtPl WHERE iuplIpg = @ipg AND iuplNm LIKE N'FEMSQ_O2_43_%')
BEGIN
    RAISERROR(N'Fixture already present (ipgUtPl FEMSQ_O2_43_*). Run rollback first.', 16, 1);
    RETURN;
END;

BEGIN TRAN;

INSERT INTO ags.ipgUtPl (iuplNm, iuplDate, iuplAg, iuplIpg)
VALUES (@tag, CAST(GETDATE() AS date), @agKey, @ipg);
SET @plKey = SCOPE_IDENTITY();

INSERT INTO ags.ipgUtPlGr (iuplgIpg, iuplgNm)
VALUES (@ipg, @tag + N'_GR');
SET @grKey = SCOPE_IDENTITY();

INSERT INTO ags.ipgUtPlGrP (iuplgpGr, iuplgpPl) VALUES (@grKey, @plKey);

UPDATE ags.ipgChRl SET ipgcrUtPlGr = @grKey WHERE ipgcrKey = @ipgcrKey;
UPDATE ags.ipgChRl_2606 SET ipgcrvUtPlGr = @grKey WHERE ipgcrvKey = @ipgcrvKey;

-- 3 пилота с наибольшим lim212
IF OBJECT_ID('tempdb..#pilots') IS NOT NULL DROP TABLE #pilots;
SELECT TOP 3
    p.ipgpKey,
    COALESCE(l212.ipgplLim, 0) AS lim212,
    COALESCE(l195.ipgplLim, 0) AS lim195,
    COALESCE(l172.ipgplLim, 0) AS lim172,
    COALESCE(l187.ipgplLim, 0) AS lim187
INTO #pilots
FROM ags.ipgPn p
INNER JOIN ags.ipgPnLim l212 ON l212.ipgplPn = p.ipgpKey AND l212.ipgplStCost = 212 AND l212.ipgplLim > 0
LEFT JOIN ags.ipgPnLim l195 ON l195.ipgplPn = p.ipgpKey AND l195.ipgplStCost = 195
LEFT JOIN ags.ipgPnLim l172 ON l172.ipgplPn = p.ipgpKey AND l172.ipgplStCost = 172
LEFT JOIN ags.ipgPnLim l187 ON l187.ipgplPn = p.ipgpKey AND l187.ipgplStCost = 187
WHERE p.ipgpIpg = @ipg
ORDER BY l212.ipgplLim DESC;

DECLARE @ipgpKey int, @lim212 decimal(23,8), @lim195 decimal(23,8), @lim172 decimal(23,8), @lim187 decimal(23,8);
DECLARE @iuplpKey int;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT ipgpKey, lim212, lim195, lim172, lim187 FROM #pilots ORDER BY ipgpKey;
OPEN cur;
FETCH NEXT FROM cur INTO @ipgpKey, @lim212, @lim195, @lim172, @lim187;

WHILE @@FETCH_STATUS = 0
BEGIN
    INSERT INTO ags.ipgUtPlP (iuplpPl, iuplpLim, iuplpIpgPn)
    VALUES (@plKey, @lim212, @ipgpKey);
    SET @iuplpKey = SCOPE_IDENTITY();

    ;WITH mn AS (
        SELECT n AS iuplpmMn FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) v(n)
    ),
    st AS (
        SELECT s AS stc, l AS lim_val
        FROM (VALUES (212, @lim212), (195, @lim195), (172, @lim172), (187, @lim187)) x(s, l)
    ),
    calc AS (
        SELECT
            mn.iuplpmMn,
            st.stc AS iuplpmStCost,
            CAST(
                CASE
                    WHEN st.lim_val IS NULL OR st.lim_val = 0 THEN 0
                    WHEN mn.iuplpmMn < 12 THEN CAST(st.lim_val / 12.0 AS decimal(23, 8))
                    ELSE st.lim_val - 11 * CAST(st.lim_val / 12.0 AS decimal(23, 8))
                END AS decimal(23, 8)
            ) AS iuplpmLim
        FROM mn CROSS JOIN st
    )
    INSERT INTO ags.ipgUtPlPnLmMn (iuplpmPlPn, iuplpmStCost, iuplpmMn, iuplpmLim)
    SELECT @iuplpKey, iuplpmStCost, iuplpmMn, iuplpmLim
    FROM calc
    WHERE iuplpmLim > 0;

    -- wide M*/Q*/Lim (семантика 212)
    UPDATE ags.ipgUtPlP SET
        iuplpLim = @lim212,
        iuplpM01 = CAST(@lim212 / 12.0 AS decimal(23,8)),
        iuplpM02 = CAST(@lim212 / 12.0 AS decimal(23,8)),
        iuplpM03 = CAST(@lim212 / 12.0 AS decimal(23,8)),
        iuplpM04 = CAST(@lim212 / 12.0 AS decimal(23,8)),
        iuplpM05 = CAST(@lim212 / 12.0 AS decimal(23,8)),
        iuplpM06 = CAST(@lim212 / 12.0 AS decimal(23,8)),
        iuplpM07 = CAST(@lim212 / 12.0 AS decimal(23,8)),
        iuplpM08 = CAST(@lim212 / 12.0 AS decimal(23,8)),
        iuplpM09 = CAST(@lim212 / 12.0 AS decimal(23,8)),
        iuplpM10 = CAST(@lim212 / 12.0 AS decimal(23,8)),
        iuplpM11 = CAST(@lim212 / 12.0 AS decimal(23,8)),
        iuplpM12 = @lim212 - 11 * CAST(@lim212 / 12.0 AS decimal(23,8)),
        iuplpQ1 = 3 * CAST(@lim212 / 12.0 AS decimal(23,8)),
        iuplpQ2 = 3 * CAST(@lim212 / 12.0 AS decimal(23,8)),
        iuplpQ3 = 3 * CAST(@lim212 / 12.0 AS decimal(23,8)),
        iuplpQ4 = @lim212 - 9 * CAST(@lim212 / 12.0 AS decimal(23,8))
    WHERE iuplpKey = @iuplpKey;

    FETCH NEXT FROM cur INTO @ipgpKey, @lim212, @lim195, @lim172, @lim187;
END;
CLOSE cur; DEALLOCATE cur;

COMMIT;

SELECT @plKey AS plKey, @grKey AS grKey, @tag AS tag,
       (SELECT COUNT(*) FROM #pilots) AS pilots,
       (SELECT COUNT(*) FROM ags.ipgUtPlPnLmMn m
        JOIN ags.ipgUtPlP p ON p.iuplpKey = m.iuplpmPlPn WHERE p.iuplpPl = @plKey) AS lmmnRows;
GO
