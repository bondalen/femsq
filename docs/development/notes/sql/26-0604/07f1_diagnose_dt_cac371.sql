USE [FishEye];
GO
-- Диагностика @dt / EOMONTH UNION для cac=371 (цепь 5)
SET NOCOUNT ON;

DECLARE @ipgCh int = 5;
DECLARE @cac int = 371;
DECLARE @lsYy int = 2022;

IF OBJECT_ID('tempdb..#oneD') IS NOT NULL DROP TABLE #oneD;
SELECT t.yyyy, t.mNum, t.ipgKey, t.cstAgPnKey, t.cstAgPnCode, t.ipgCount
INTO #oneD
FROM (
    SELECT yKey, yyyy, mKey, mNum, ipgKey, cstAgPnKey, cstAgPnCode,
           COUNT(ipgKey) OVER (PARTITION BY yKey, mKey, ogaKey, cstAgPnCode) AS ipgCount
    FROM ags.fnIpgChRsltCstUtl2_2606(@ipgCh, NULL, NULL)
    WHERE cstAgPnKey = @cac AND typeGrTtl = N'2. Агентская, план'
) t;

DECLARE @dt TABLE (dateRslt date, ipgKey int);

INSERT @dt
SELECT x.dateRslt, x.ipgKey
FROM (
    SELECT
        IIF(
            MONTH(DATEFROMPARTS(s.yyyy, s.mNum, 1)) = MONTH(i.ipgStr),
            i.ipgStr,
            IIF(
                MONTH(DATEFROMPARTS(s.yyyy, s.mNum, 1)) = MONTH(i.ipgEnd),
                i.ipgEnd,
                EOMONTH(DATEFROMPARTS(s.yyyy, s.mNum, 1))
            )
        ) AS dateRslt,
        s.ipgKey
    FROM #oneD s
    LEFT JOIN ags.ipg i ON s.ipgKey = i.ipgKey
) x
GROUP BY x.dateRslt, x.ipgKey;

PRINT N'@dt from fn2_2606 oneD (cac=371):';
SELECT * FROM @dt ORDER BY dateRslt, ipgKey;

PRINT N'EOMONTH UNION rows (months 4,9):';
SELECT ddd AS dateRslt,
       IIF(ddd < DATEFROMPARTS(@lsYy, 1, 31), 0, MONTH(ddd)) AS mNum,
       q.ipgKey
FROM (
    SELECT EOMONTH(DATEFROMPARTS(@lsYy, m.mNum, 1)) AS ddd
    FROM ags.mmmm m
    WHERE m.mNum IN (4, 9)
    UNION
    SELECT DATEFROMPARTS(@lsYy, 1, 1)
) z
LEFT JOIN (
    SELECT x.m, u.dateRslt, u.ipgKey
    FROM (
        SELECT MONTH(t.dateRslt) AS m, MAX(t.dateRslt) AS d
        FROM @dt t
        WHERE t.ipgKey IS NOT NULL
        GROUP BY MONTH(t.dateRslt)
    ) x
    JOIN @dt u ON x.d = u.dateRslt AND u.ipgKey IS NOT NULL
) q ON MONTH(z.ddd) = q.m
ORDER BY ddd, q.ipgKey;

GO
