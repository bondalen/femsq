-- 08_ALTER_DbtUplCstAg_P1.sql
-- Политика P1 (план 0921 §5a): nullable FK + denorm code/name для корзин A/B/C.
-- DEV (SQL 2016+). Канон Exp не трогает.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---- sudz.DbtUplCstAg ---- */
IF COL_LENGTH(N'sudz.DbtUplCstAg', N'ducaCode') IS NULL
BEGIN
    ALTER TABLE sudz.DbtUplCstAg ADD ducaCode nvarchar(500) NULL;
END
GO

IF COL_LENGTH(N'sudz.DbtUplCstAg', N'ducaName') IS NULL
BEGIN
    ALTER TABLE sudz.DbtUplCstAg ADD ducaName nvarchar(500) NULL;
END
GO

IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'sudz.DbtUplCstAg')
      AND name = N'ducaCstAgPn'
      AND is_nullable = 0
)
BEGIN
    IF OBJECT_ID(N'sudz.FK_DbtUplCstAg_CstAgPn', N'F') IS NOT NULL
        ALTER TABLE sudz.DbtUplCstAg DROP CONSTRAINT FK_DbtUplCstAg_CstAgPn;

    ALTER TABLE sudz.DbtUplCstAg ALTER COLUMN ducaCstAgPn int NULL;

    ALTER TABLE sudz.DbtUplCstAg ADD CONSTRAINT FK_DbtUplCstAg_CstAgPn
        FOREIGN KEY (ducaCstAgPn) REFERENCES ags.cstAgPn (cstapKey);
END
GO

/* Backfill denorm для уже существующих строк A */
UPDATE d
SET
    d.ducaCode = CAST(pn.cstapIpgPnN AS nvarchar(500)),
    d.ducaName = CAST(ISNULL(cst.cstName, N'') AS nvarchar(500))
FROM sudz.DbtUplCstAg AS d
JOIN ags.cstAgPn AS pn ON pn.cstapKey = d.ducaCstAgPn
LEFT JOIN ags.cstAg AS ca ON ca.cstaKey = pn.cstapCsta
LEFT JOIN ags.cst AS cst ON cst.cstKey = ca.cstaCst
WHERE d.ducaCstAgPn IS NOT NULL
  AND (d.ducaCode IS NULL OR d.ducaName IS NULL);
GO

/* ---- test_sudz (если есть) ---- */
IF OBJECT_ID(N'test_sudz.DbtUplCstAg', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'test_sudz.DbtUplCstAg', N'ducaCode') IS NULL
        ALTER TABLE test_sudz.DbtUplCstAg ADD ducaCode nvarchar(500) NULL;

    IF COL_LENGTH(N'test_sudz.DbtUplCstAg', N'ducaName') IS NULL
        ALTER TABLE test_sudz.DbtUplCstAg ADD ducaName nvarchar(500) NULL;
END
GO

IF OBJECT_ID(N'test_sudz.DbtUplCstAg', N'U') IS NOT NULL
AND EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'test_sudz.DbtUplCstAg')
      AND name = N'ducaCstAgPn'
      AND is_nullable = 0
)
BEGIN
    IF OBJECT_ID(N'test_sudz.FK_DbtUplCstAg_CstAgPn', N'F') IS NOT NULL
        ALTER TABLE test_sudz.DbtUplCstAg DROP CONSTRAINT FK_DbtUplCstAg_CstAgPn;

    ALTER TABLE test_sudz.DbtUplCstAg ALTER COLUMN ducaCstAgPn int NULL;

    IF OBJECT_ID(N'test_sudz.FK_DbtUplCstAg_CstAgPn', N'F') IS NULL
        ALTER TABLE test_sudz.DbtUplCstAg ADD CONSTRAINT FK_DbtUplCstAg_CstAgPn
            FOREIGN KEY (ducaCstAgPn) REFERENCES ags.cstAgPn (cstapKey);
END
GO

PRINT N'08 ALTER DbtUplCstAg P1 done';
GO
