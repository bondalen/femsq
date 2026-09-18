-- 05_ROLLBACK.sql
SET NOCOUNT ON;

IF OBJECT_ID(N'ags.v_fioDictWord', N'V') IS NOT NULL
  DROP VIEW ags.v_fioDictWord;
GO

IF OBJECT_ID(N'ags.fioDict', N'U') IS NOT NULL
  DROP TABLE ags.fioDict;
GO
