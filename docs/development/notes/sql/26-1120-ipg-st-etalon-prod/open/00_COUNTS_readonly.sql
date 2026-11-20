/*
 * C2 / D1.1 — эталон структуры ИПГ с прода (только чтение).
 * Счётчики и наличие объектов перед выгрузкой BCP.
 * Прод: SSMS, SPB-05-NV-SQL1 / FishEye, Windows auth.
 * Синтаксис SQL Server 2012. lastUpdated: 2026-11-20
 * Задача 0081 / план chat-plan-26-1120-c2-d11-ipg-plans.md §2.0d
 */
SET NOCOUNT ON;

SELECT
    N'identity' AS section,
    CAST(@@SERVERNAME AS nvarchar(128)) AS server_name,
    CAST(DB_NAME() AS nvarchar(128)) AS db_name,
    CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(32)) AS product_version,
    CAST(SERVERPROPERTY('ProductLevel') AS nvarchar(32)) AS product_level,
    GETDATE() AS run_at;

SELECT
    N'object' AS section,
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    CASE WHEN o.object_id IS NULL THEN N'MISSING' ELSE N'OK' END AS status
FROM (VALUES
    (N'stType'), (N'st'), (N'stIpg'), (N'stIpgNm'),
    (N'stCost'), (N'stCostNm'), (N'stRel'), (N'stNet'), (N'stNetPn'),
    (N'ipg'), (N'ipgCh'), (N'ipgPn'), (N'ipgStPn'), (N'ipgSh'),
    (N'stIpgOutLimPn_2606'), (N'stIpgOutLimPn')
) AS want(name)
LEFT JOIN sys.objects AS o
    ON o.name = want.name AND o.type = N'U'
LEFT JOIN sys.schemas AS s
    ON s.schema_id = o.schema_id AND s.name = N'ags'
ORDER BY want.name;

SELECT N'counts' AS section, N'stType' AS tbl, COUNT(*) AS n FROM ags.stType
UNION ALL SELECT N'counts', N'st', COUNT(*) FROM ags.st
UNION ALL SELECT N'counts', N'stIpg', COUNT(*) FROM ags.stIpg
UNION ALL SELECT N'counts', N'stIpgNm', COUNT(*) FROM ags.stIpgNm
UNION ALL SELECT N'counts', N'stCost', COUNT(*) FROM ags.stCost
UNION ALL SELECT N'counts', N'stCostNm', COUNT(*) FROM ags.stCostNm
UNION ALL SELECT N'counts', N'stRel', COUNT(*) FROM ags.stRel
UNION ALL SELECT N'counts', N'stNet', COUNT(*) FROM ags.stNet
UNION ALL SELECT N'counts', N'stNetPn', COUNT(*) FROM ags.stNetPn
UNION ALL SELECT N'counts', N'ipg', COUNT(*) FROM ags.ipg
UNION ALL SELECT N'counts', N'ipgCh', COUNT(*) FROM ags.ipgCh
UNION ALL SELECT N'counts', N'ipgPn', COUNT(*) FROM ags.ipgPn
UNION ALL SELECT N'counts', N'ipgStPn', COUNT(*) FROM ags.ipgStPn
UNION ALL SELECT N'counts', N'ipgSh', COUNT(*) FROM ags.ipgSh
ORDER BY tbl;

/* stIpgOutLimPn_2606 — после трека A; если MISSING — в RETURN отметить */
IF OBJECT_ID(N'ags.stIpgOutLimPn_2606', N'U') IS NOT NULL
    SELECT N'counts' AS section, N'stIpgOutLimPn_2606' AS tbl, COUNT(*) AS n FROM ags.stIpgOutLimPn_2606;

SELECT N'stNet' AS section, stnKey, stnType, stnName, stnRoot FROM ags.stNet ORDER BY stnKey;

SELECT N'ipg_stNet' AS section, ipgKey, ipgNum, ipgNm, ipgStRlSh, ipgYy, ipgOg
FROM ags.ipg
ORDER BY ipgKey;

SELECT N'ipgCh_stNet' AS section, ipgcKey, ipgcName, ipgcYyyy, ipgcStNetIpg, ipgcIpgLate
FROM ags.ipgCh
ORDER BY ipgcKey;

SELECT N'ipgSh' AS section, * FROM ags.ipgSh ORDER BY 1;
