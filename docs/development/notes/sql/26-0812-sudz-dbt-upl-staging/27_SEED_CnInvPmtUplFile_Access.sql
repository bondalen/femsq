-- Seed CnInvPmtUplFile (30) from Access slim CSV
SET NOCOUNT ON;
GO

SET IDENTITY_INSERT sudz.CnInvPmtUplFile ON;
GO
MERGE sudz.CnInvPmtUplFile AS t
USING (VALUES
    (1, 7, N'X:\GRP\F644\PTU\Отдел сводно-аналитической информации\Дебиторка\2021\3 квартал\21-1027_БУиРГ_export_17-06.XLSX', 0, NULL, 0, N'Sheet1'),
    (2, 8, N'X:\GRP\F644\PTU\Отдел сводно-аналитической информации\Дебиторка\2021\4 квартал\22-0211_export.XLSX', 0, NULL, 0, N'Sheet1'),
    (3, 9, N'X:\GRP\F644\PTU\Отдел сводно-аналитической информации\Дебиторка\2022\1 квартал\1_выгрузки\export_22-0422.XLSX', 0, NULL, 0, N'Sheet1'),
    (4, 10, N'X:\GRP\F644\PTU\Отдел сводно-аналитической информации\Дебиторка\2022\2 квартал\export_22-0726.XLSX', 0, NULL, 0, N'Sheet1'),
    (5, 11, N'X:\GRP\F644\PTU\Отдел сводно-аналитической информации\Дебиторка\2022\3 квартал\Отчет по Дебиторке краткий\22-1024_export_BUIRG.XLSX', 0, NULL, 0, N'Sheet1'),
    (6, 12, N'X:\GRP\F644\PTU\Отдел сводно-аналитической информации\Дебиторка\2022\4 квартал\export_23-0207.xlsx', 0, NULL, 0, N'Лист1'),
    (7, 13, N'X:\GRP\F644\Отдел сводно-аналитической информации\Дебиторка\2023\1_квартал\1_выгрузки\export_23-0420.XLSX', 0, NULL, 0, N'Sheet1'),
    (8, 14, N'X:\GRP\F644\Отдел сводно-аналитической информации\Дебиторка\2023\2_квартал\1_выгрузки\export_23-0721.XLSX', 0, NULL, 0, N'Sheet1'),
    (9, 15, N'X:\GRP\F644\Отдел сводно-аналитической информации\Дебиторка\2023\3_квартал\1_выгрузки\export_23-1019.XLSX', 0, NULL, 0, N'Sheet1'),
    (10, 16, N'X:\GRP\F644\Отдел сводно-аналитической информации\Дебиторка\2023\4_квартал\1_выгрузки\export_24-0130.XLSX', 0, NULL, 0, N'Sheet1'),
    (11, 17, N'X:\GRP\F644\Отдел сводно-аналитической информации\Дебиторка\2024\1_квартал\1_выгрузки\export_24-0423_606012.XLSX', 0, NULL, 0, N'Sheet1'),
    (12, 18, N'X:\GRP\F644\Отдел сводно-аналитической информации\Дебиторка\2024\1_квартал\1_выгрузки\export_24-0423_606022.XLSX', 0, NULL, 0, N'Sheet1'),
    (13, 19, N'X:\GRP\F644\Отдел сводно-аналитической информации\Дебиторка\2024\1_квартал\1_выгрузки\export_24-0423_761010.XLSX', 0, NULL, 0, N'Sheet1'),
    (14, 20, N'X:\GRP\F644\Отдел сводно-аналитической информации\Дебиторка\2024\1_квартал\1_выгрузки\export_24-0423_767501.XLSX', 0, NULL, 0, N'Sheet1'),
    (15, 21, N'X:\GRP\F644\Отдел сводно-аналитической информации\Дебиторка\2024\1_квартал\1_выгрузки\export_24-0423_767502.XLSX', 0, NULL, 0, N'Sheet1'),
    (16, 22, N'X:\grp\F644\Отдел сводно-аналитической информации\Дебиторка\2024\2_квартал\1_выгрузки\export_24-0722_606012.XLSX', 0, NULL, 0, N'Sheet1'),
    (17, 23, N'X:\grp\F644\Отдел сводно-аналитической информации\Дебиторка\2024\2_квартал\1_выгрузки\export_24-0722_606022.XLSX', 0, NULL, 0, N'Sheet1'),
    (18, 24, N'X:\grp\F644\Отдел сводно-аналитической информации\Дебиторка\2024\2_квартал\1_выгрузки\export_24-0723_761010.XLSX', 0, NULL, 0, N'Sheet1'),
    (19, 25, N'X:\grp\F644\Отдел сводно-аналитической информации\Дебиторка\2024\2_квартал\1_выгрузки\export_24-0723_767501.XLSX', 0, NULL, 0, N'Sheet1'),
    (20, 26, N'X:\grp\F644\Отдел сводно-аналитической информации\Дебиторка\2024\2_квартал\1_выгрузки\export_24-0723_767502.XLSX', 0, NULL, 0, N'Sheet1'),
    (21, 27, N'X:\grp\F644\Отдел сводно-аналитической информации\Дебиторка\2024\3_квартал\1_выгрузки\export_24-1021_606012.XLSX', 0, NULL, 0, N'Sheet1'),
    (22, 28, N'X:\grp\F644\Отдел сводно-аналитической информации\Дебиторка\2024\3_квартал\1_выгрузки\export_24-1021_606022.XLSX', 0, NULL, 0, N'Sheet1'),
    (23, 29, N'X:\grp\F644\Отдел сводно-аналитической информации\Дебиторка\2024\3_квартал\1_выгрузки\export_24-1021_761010.XLSX', 0, NULL, 0, N'Sheet1'),
    (24, 30, N'X:\grp\F644\Отдел сводно-аналитической информации\Дебиторка\2024\3_квартал\1_выгрузки\export_24-1021_767501.XLSX', 0, NULL, 0, N'Sheet1'),
    (25, 31, N'X:\grp\F644\Отдел сводно-аналитической информации\Дебиторка\2024\3_квартал\1_выгрузки\export_24-1022_767502.XLSX', 0, NULL, 0, N'Sheet1'),
    (26, 32, N'X:\grp\F644\Отдел сводно-аналитической информации\Дебиторка\2024\4_квартал\1_выгрузки\export_606012_25-0124.XLSX', 0, NULL, 0, N'Sheet1'),
    (27, 33, N'X:\grp\F644\Отдел сводно-аналитической информации\Дебиторка\2024\4_квартал\1_выгрузки\export_606022_25-0124.XLSX', 0, NULL, 0, N'Sheet1'),
    (28, 34, N'X:\grp\F644\Отдел сводно-аналитической информации\Дебиторка\2024\4_квартал\1_выгрузки\export_761010_25-0124.XLSX', 0, NULL, 0, N'Sheet1'),
    (29, 35, N'X:\grp\F644\Отдел сводно-аналитической информации\Дебиторка\2024\4_квартал\1_выгрузки\export_767501_25-0124.XLSX', 0, NULL, 0, N'Sheet1'),
    (30, 36, N'X:\grp\F644\Отдел сводно-аналитической информации\Дебиторка\2024\4_квартал\1_выгрузки\export_767502_25-0124.XLSX', 0, NULL, 0, N'Sheet1')
) AS s (cipufKey, cipufUpload, cipufPath, cipufFlLoad, cipufLoadingProgress, cipufFlTbl, cipufSheet)
ON t.cipufKey = s.cipufKey
WHEN MATCHED THEN UPDATE SET
    cipufUpload = s.cipufUpload, cipufPath = s.cipufPath,
    cipufFlLoad = s.cipufFlLoad, cipufFlTbl = s.cipufFlTbl, cipufSheet = s.cipufSheet
WHEN NOT MATCHED THEN
    INSERT (cipufKey, cipufUpload, cipufPath, cipufFlLoad, cipufLoadingProgress, cipufFlTbl, cipufSheet)
    VALUES (s.cipufKey, s.cipufUpload, s.cipufPath, s.cipufFlLoad, s.cipufLoadingProgress, s.cipufFlTbl, s.cipufSheet);
GO
SET IDENTITY_INSERT sudz.CnInvPmtUplFile OFF;
GO
DBCC CHECKIDENT ('sudz.CnInvPmtUplFile', RESEED, 30);
GO
SELECT COUNT(*) AS pmt_file_cnt FROM sudz.CnInvPmtUplFile;
GO
