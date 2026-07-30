-- 0054.6.5 smoke prep (FishEye / MSSQL2012 / SSMS)
-- Prod JVM Linux: X: = /mnt/Общий_(X)
-- Files confirmed 2026-07-30 on 23121PC05780077 (18-54/result.txt).
-- Does NOT touch Access.

USE FishEye;
GO

-- 1) BEFORE
SELECT af_key, af_num, af_name, af_dir, af_type, af_execute, af_source
FROM ags.ra_f
WHERE af_key IN (304, 305);

-- 2) APPLY (run once)
UPDATE ags.ra_f
SET af_name = N'/mnt/Общий_(X)/grp/F644/All/УКПиУВРпоСО/2026 Свод инф-ции по ОА.xlsm',
    af_execute = 1,
    af_source = 1
WHERE af_key = 305; -- type=5, 2026 свод

UPDATE ags.ra_f
SET af_name = N'/mnt/Общий_(X)/grp/F644/All/ОСАИ/(2026)_Аренда_рабочий.xlsx',
    af_execute = 1,
    af_source = 1
WHERE af_key = 304; -- type=3, 2026 аренда

-- 3) AFTER
SELECT af_key, af_num, af_name, af_dir, af_type, af_execute, af_source
FROM ags.ra_f
WHERE af_key IN (304, 305);
GO
