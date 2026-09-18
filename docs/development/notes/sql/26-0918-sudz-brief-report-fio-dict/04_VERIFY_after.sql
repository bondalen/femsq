-- 04_VERIFY_after.sql
SET NOCOUNT ON;

SELECT COUNT(*) AS fioDict_rows FROM ags.fioDict;
SELECT COUNT(*) AS fioDict_words FROM ags.v_fioDictWord;

-- smoke: Александр / Александрович must be present
SELECT CASE WHEN EXISTS (
  SELECT 1 FROM ags.v_fioDictWord WHERE word IN (N'Александр', N'Александрович', N'Александровна')
) THEN N'PASS' ELSE N'FAIL' END AS smoke_alexander;

SELECT TOP 5 * FROM ags.fioDict ORDER BY fioDictKey;
