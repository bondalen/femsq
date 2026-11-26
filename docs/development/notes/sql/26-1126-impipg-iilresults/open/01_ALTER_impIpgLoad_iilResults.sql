/*
 * C2 §3.5.4 — структурированный лог загрузки ИП: HTML на сессии ags.impIpgLoad.
 * MSSQL 2012 SP4: без CREATE OR ALTER и DROP IF EXISTS. Идемпотентно.
 * lastUpdated: 2026-11-26
 */
SET NOCOUNT ON;

IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.tables t ON t.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE s.name = N'ags' AND t.name = N'impIpgLoad' AND c.name = N'iilResults'
)
BEGIN
    ALTER TABLE ags.impIpgLoad ADD iilResults nvarchar(max) NULL;
END
GO

SELECT c.name, ty.name AS typeName, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE s.name = N'ags' AND t.name = N'impIpgLoad' AND c.name = N'iilResults';
GO
