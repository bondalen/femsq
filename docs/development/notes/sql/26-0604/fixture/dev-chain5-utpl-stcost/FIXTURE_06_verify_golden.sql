USE [FishEye];
GO
-- =============================================================================
-- FIXTURE_06_verify_golden.sql
-- Dev-only: инварианты golden UtPl cst 2102 после FIXTURE_06 (sparse, Решение 15).
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @cstAgPn int = 2102;
DECLARE @fail int = 0;

PRINT N'=== FIXTURE_06 verify golden cstAgPn=' + CAST(@cstAgPn AS nvarchar) + N' ===';

SELECT @fail = @fail + CASE WHEN ipgcrvUtPlGr NOT IN (18, 19, 20) THEN 1 ELSE 0 END
FROM ags.ipgChRl_2606 WHERE ipgcrvChain = 5;

IF @fail > 0
BEGIN
    RAISERROR(N'ipgcrvUtPlGr not swapped to 18/19/20.', 16, 1);
    RETURN;
END;

IF (SELECT COUNT(DISTINCT up.iuplpIpgPn)
    FROM ags.ipgUtPlP up
    INNER JOIN ags.ipgUtPlGrP gp ON gp.iuplgpPl = up.iuplpPl AND gp.iuplgpGr IN (18, 19, 20)
    INNER JOIN ags.ipgPn p ON p.ipgpKey = up.iuplpIpgPn
    WHERE p.ipgpCstAgPn = @cstAgPn AND p.ipgpKey IN (2037, 3290, 5271)) <> 3
BEGIN
    RAISERROR(N'Expected 3 golden ipgUtPlP in test groups.', 16, 1);
    RETURN;
END;

DECLARE @zero_mn int;
SELECT @zero_mn = COUNT(*)
FROM ags.ipgUtPlPnLmMn m
INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
INNER JOIN ags.ipgUtPlGrP gp ON gp.iuplgpPl = up.iuplpPl AND gp.iuplgpGr IN (18, 19, 20)
INNER JOIN ags.ipgPn p ON p.ipgpKey = up.iuplpIpgPn
WHERE p.ipgpKey IN (2037, 3290, 5271) AND m.iuplpmLim <= 0;

IF @zero_mn > 0
BEGIN
    RAISERROR(N'SPARSE: %d rows with iuplpmLim<=0 in golden UtPl (expect 0).', 16, 1, @zero_mn);
    RETURN;
END;

DECLARE @data_fail int = 0;
SELECT @data_fail = COUNT(*)
FROM (
    SELECT p.ipgpKey,
        ABS(ISNULL(SUM(CASE WHEN m.iuplpmStCost = 212 THEN m.iuplpmLim END), 0)
            - COALESCE(l212.ipgplLim, p.ipgpSmTtl, 0)) AS d212
    FROM ags.ipgPn p
    INNER JOIN ags.ipgUtPlP up ON up.iuplpIpgPn = p.ipgpKey
    INNER JOIN ags.ipgUtPlGrP gp ON gp.iuplgpPl = up.iuplpPl AND gp.iuplgpGr IN (18, 19, 20)
    INNER JOIN ags.ipgUtPlPnLmMn m ON m.iuplpmPlPn = up.iuplpKey
    LEFT JOIN ags.ipgPnLim l212 ON l212.ipgplPn = p.ipgpKey AND l212.ipgplStCost = 212
    WHERE p.ipgpKey IN (2037, 3290, 5271)
    GROUP BY p.ipgpKey, l212.ipgplLim, p.ipgpSmTtl
) x WHERE d212 > 0.01;

IF @data_fail > 0
BEGIN
    RAISERROR(N'DATA sum(UtPlMn@212) != limit for %d ipgPn.', 16, 1, @data_fail);
    RETURN;
END;

PRINT N'FIXTURE_06 verify | cstAgPn=' + CAST(@cstAgPn AS nvarchar) + N' | PASS';
GO
