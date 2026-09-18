-- 01_CREATE_fioDict.sql — ags.fioDict + v_fioDictWord (dev may use CREATE OR ALTER for view)
-- Alias business name: «Словарь» (лист Справочник / named range Словарь in 1_process.xlsm)
-- WBS: 1.1.1.0.3.1
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'ags.v_fioDictWord', N'V') IS NOT NULL
  DROP VIEW ags.v_fioDictWord;
GO

IF OBJECT_ID(N'ags.fioDict', N'U') IS NOT NULL
  DROP TABLE ags.fioDict;
GO

CREATE TABLE ags.fioDict (
  fioDictKey int IDENTITY(1, 1) NOT NULL,
  fdName     nvarchar(50) NULL,  -- col A: имя (осн.)
  fdNameF    nvarchar(50) NULL,  -- col B: парное/жен. имя
  fdPatrM    nvarchar(50) NULL,  -- col C: отчество муж.
  fdPatrM2   nvarchar(50) NULL,  -- col D: вариант отчества муж.
  fdPatrF2   nvarchar(50) NULL,  -- col E: вариант отчества жен.
  fdPatrF    nvarchar(50) NULL,  -- col F: отчество жен.
  CONSTRAINT PK_ags_fioDict PRIMARY KEY CLUSTERED (fioDictKey)
);
GO

EXEC sys.sp_addextendedproperty
  @name = N'MS_Description',
  @value = N'Словарь имён/отчеств для краткого отчёта СУДЗ (БП 1.1.1.0; экран подготовки; порт FioByDictionary)',
  @level0type = N'SCHEMA', @level0name = N'ags',
  @level1type = N'TABLE',  @level1name = N'fioDict';
GO

CREATE VIEW ags.v_fioDictWord
AS
  SELECT DISTINCT LTRIM(RTRIM(w.word)) AS word
  FROM (
    SELECT fdName AS word FROM ags.fioDict
    UNION ALL SELECT fdNameF FROM ags.fioDict
    UNION ALL SELECT fdPatrM FROM ags.fioDict
    UNION ALL SELECT fdPatrM2 FROM ags.fioDict
    UNION ALL SELECT fdPatrF2 FROM ags.fioDict
    UNION ALL SELECT fdPatrF FROM ags.fioDict
  ) w
  WHERE w.word IS NOT NULL
    AND LTRIM(RTRIM(w.word)) <> N'';
GO

EXEC sys.sp_addextendedproperty
  @name = N'MS_Description',
  @value = N'Уникальные слова словаря FIO (для regex-замены инициалов)',
  @level0type = N'SCHEMA', @level0name = N'ags',
  @level1type = N'VIEW',   @level1name = N'v_fioDictWord';
GO
