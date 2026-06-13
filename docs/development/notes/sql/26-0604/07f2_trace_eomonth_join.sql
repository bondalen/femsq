USE [FishEye];
GO
-- Трассировка EOMONTH: x → join oneD → z (cac=371, цепь 5)
SET NOCOUNT ON;

DECLARE @ipgCh int = 5;
DECLARE @cac int = 371;
DECLARE @lsYy int = 2022;

-- Минимальная oneD как в PercentBrn (только агентская схема, после фильтра ipgCount)
IF OBJECT_ID('tempdb..#oneD06') IS NOT NULL DROP TABLE #oneD06;
SELECT t.yyyy, t.mNum, t.mKey, t.ipgKey, t.cstAgPnCode, t.ogNm, t.branch,
       AVG(CASE WHEN t.typeGrTtl = N'2. Агентская, план' THEN t.iShKey END) AS ag_iShKey
INTO #oneD06
FROM (
    SELECT *,
           COUNT(ipgKey) OVER (PARTITION BY yKey, mKey, ogaKey, cstAgPnCode) AS ipgCount
    FROM ags.fnIpgChRsltCstUtl2_2606(@ipgCh, NULL, NULL)
    WHERE cstAgPnKey = @cac
) t
WHERE NOT (t.ipgKey IS NULL AND t.ipgCount > 0)
GROUP BY t.yyyy, t.mNum, t.mKey, t.ipgKey, t.cstAgPnCode, t.ogNm, t.branch;

DECLARE @dt TABLE (dateRslt date, ipgKey int);
INSERT @dt
SELECT x.dateRslt, x.ipgKey
FROM (
    SELECT
        IIF(
            MONTH(DATEFROMPARTS(s.yyyy, s.mNum, 1)) = MONTH(i.ipgStr), i.ipgStr,
            IIF(
                MONTH(DATEFROMPARTS(s.yyyy, s.mNum, 1)) = MONTH(i.ipgEnd), i.ipgEnd,
                EOMONTH(DATEFROMPARTS(s.yyyy, s.mNum, 1))
            )
        ) AS dateRslt,
        s.ipgKey
    FROM #oneD06 s
    LEFT JOIN ags.ipg i ON s.ipgKey = i.ipgKey
) x
GROUP BY x.dateRslt, x.ipgKey;

PRINT N'=== x (full date list) months 4,9 ===';
SELECT x.dateRslt, x.mNum, x.ipgKey, x.src
FROM (
    SELECT u.dateRslt,
           IIF(u.dateRslt < DATEFROMPARTS(@lsYy, 1, 31), 0, MONTH(u.dateRslt)) AS mNum,
           u.ipgKey, N'@dt' AS src
    FROM @dt u
    WHERE u.ipgKey IS NOT NULL
    UNION
    SELECT z.ddd,
           IIF(z.ddd < DATEFROMPARTS(@lsYy, 1, 31), 0, MONTH(z.ddd)) AS mNum,
           q.ipgKey,
           N'EOM' AS src
    FROM (
        SELECT EOMONTH(DATEFROMPARTS(@lsYy, m.mNum, 1)) AS ddd
        FROM ags.mmmm m
        UNION
        SELECT DATEFROMPARTS(@lsYy, 1, 1)
    ) z
    LEFT JOIN (
        SELECT x.m, u.ipgKey
        FROM (
            SELECT MONTH(t.dateRslt) AS m, MAX(t.dateRslt) AS d
            FROM @dt t
            WHERE t.ipgKey IS NOT NULL
            GROUP BY MONTH(t.dateRslt)
        ) x
        JOIN @dt u ON x.d = u.dateRslt AND u.ipgKey IS NOT NULL
    ) q ON MONTH(z.ddd) = q.m
) x
WHERE MONTH(x.dateRslt) IN (4, 9)
ORDER BY x.dateRslt, x.ipgKey, x.src;

PRINT N'=== z after join (ipgKey=8/11, EOM dates) ===';
SELECT x.dateRslt, x.mNum, x.ipgKey AS x_ipgKey, i.ipgKey AS i_ipgKey, i.cstAgPnCode, p.cstapKey
FROM (
    SELECT u.dateRslt,
           IIF(u.dateRslt < DATEFROMPARTS(@lsYy, 1, 31), 0, MONTH(u.dateRslt)) AS mNum,
           u.ipgKey
    FROM @dt u
    WHERE u.ipgKey IS NOT NULL
    UNION
    SELECT z.ddd,
           IIF(z.ddd < DATEFROMPARTS(@lsYy, 1, 31), 0, MONTH(z.ddd)) AS mNum,
           q.ipgKey
    FROM (
        SELECT EOMONTH(DATEFROMPARTS(@lsYy, m.mNum, 1)) AS ddd
        FROM ags.mmmm m
        UNION
        SELECT DATEFROMPARTS(@lsYy, 1, 1)
    ) z
    LEFT JOIN (
        SELECT x.m, u.ipgKey
        FROM (
            SELECT MONTH(t.dateRslt) AS m, MAX(t.dateRslt) AS d
            FROM @dt t
            WHERE t.ipgKey IS NOT NULL
            GROUP BY MONTH(t.dateRslt)
        ) x
        JOIN @dt u ON x.d = u.dateRslt AND u.ipgKey IS NOT NULL
    ) q ON MONTH(z.ddd) = q.m
) x
LEFT JOIN #oneD06 i
    ON x.mNum = i.mNum AND (x.ipgKey = i.ipgKey OR i.ipgKey IS NULL)
JOIN ags.cstAgPn p ON i.cstAgPnCode = p.cstapIpgPnN
WHERE x.dateRslt IN ('2022-04-30', '2022-09-30')
ORDER BY x.dateRslt, x.ipgKey, i.ipgKey;

GO
