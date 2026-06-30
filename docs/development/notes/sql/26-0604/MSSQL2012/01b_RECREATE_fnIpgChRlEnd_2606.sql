USE [FishEye];
GO

-- Зеркало ../01b_RECREATE_fnIpgChRlEnd_2606.sql (SQL Server 2012 SP4)

PRINT N'=== 01b_RECREATE MSSQL2012: fnIpgChRlEnd_2606 ===';
GO

IF COL_LENGTH(N'ags.ipgChRl_2606', N'ipgcrvEnd') IS NOT NULL
    ALTER TABLE ags.ipgChRl_2606 DROP COLUMN ipgcrvEnd;
GO

IF OBJECT_ID(N'ags.fnIpgChRlEnd_2606', N'FN') IS NOT NULL
    DROP FUNCTION ags.fnIpgChRlEnd_2606;
GO

CREATE FUNCTION ags.fnIpgChRlEnd_2606(@chain int, @str date)
RETURNS date
AS
BEGIN
    RETURN DATEADD(day, -1, (
        SELECT MIN(t.ipgcrvStr)
        FROM ags.ipgChRl_2606 t
        WHERE t.ipgcrvChain = @chain
          AND t.ipgcrvStr > @str
    ))
END
GO

ALTER TABLE ags.ipgChRl_2606
    ADD ipgcrvEnd AS (ags.fnIpgChRlEnd_2606(ipgcrvChain, ipgcrvStr));
GO
