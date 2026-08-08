-- S57: yr_CmmGr_New + рабочая группа новых комментариев для Rslt повтор (yr=901).
-- DEV: схема sudz. Содержимое *_new — из тестовых «возвратов» Excel (долги 82 и 85).
-- Файлы: excel/.../test/ags_Yr_DbtChangesRslt_901_903_return_dbt82_S57.xlsx
--         excel/.../test/ags_Yr_DbtChangesRslt_901_903_return_dbt85_S57.xlsx

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF COL_LENGTH('sudz.yr', 'yr_CmmGr_New') IS NULL
BEGIN
    ALTER TABLE sudz.yr ADD yr_CmmGr_New int NULL;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_yr_cnInvCmmGr_New' AND parent_object_id = OBJECT_ID(N'sudz.yr')
)
BEGIN
    ALTER TABLE sudz.yr WITH CHECK
        ADD CONSTRAINT FK_yr_cnInvCmmGr_New FOREIGN KEY (yr_CmmGr_New)
            REFERENCES sudz.cnInvCmmGr (cnicgKey);
END
GO

BEGIN TRAN;

DECLARE @gr int;
SELECT @gr = yr_CmmGr_New FROM sudz.yr WHERE yr_key = 901;

IF @gr IS NOT NULL
BEGIN
    DELETE FROM sudz.cnInvCmmCst WHERE ciccCmmGr = @gr;
    DELETE FROM sudz.cnInvCmm WHERE cnicGroup = @gr;
    UPDATE sudz.yr SET yr_CmmGr_New = NULL WHERE yr_key = 901;
    DELETE FROM sudz.cnInvCmmGr WHERE cnicgKey = @gr;
END

INSERT INTO sudz.cnInvCmmGr (cnicgNmCs, cnicgDate, cnicgName)
VALUES (
    N'S57',
    '2026-08-08',
    N'[sudz] Rslt повтор / новые (S57) — возвраты dbt 82+85'
);

DECLARE @newGr int = SCOPE_IDENTITY();

-- dbt 82 из return_dbt82
INSERT INTO sudz.cnInvCmm (cnicType, cnicGroup, cnicInv, cnicText, cnicInvAccnt)
VALUES
    (8, @newGr, NULL, N'Сербул А.С. (уточн. авг.2026)', 82),
    (1, @newGr, NULL,
     N'S57 возврат спец.: получено ДС №38 от 01.08.2026; график погашения аванса актуализирован. По состоянию на 08.08.2026 просрочки нет.',
     82);

INSERT INTO sudz.cnInvCmmCst (ciccCmmGr, ciccType, ciccCstAgPn, ciccInvAccnt)
VALUES (@newGr, 2, 1835, 82);

-- dbt 85 из return_dbt85
INSERT INTO sudz.cnInvCmm (cnicType, cnicGroup, cnicInv, cnicText, cnicInvAccnt)
VALUES
    (8, @newGr, NULL, N'Дедова И.В. (уточн. авг.2026)', 85),
    (1, @newGr, NULL,
     N'S57 возврат спец.: конкурсное производство продлено; запрошен отчёт конкурсного управляющего на 15.08.2026.',
     85);

INSERT INTO sudz.cnInvCmmCst (ciccCmmGr, ciccType, ciccCstAgPn, ciccInvAccnt)
VALUES (@newGr, 2, 2016, 85);

UPDATE sudz.yr
SET yr_CmmGr_New = @newGr
WHERE yr_key = 901;

COMMIT;

SELECT y.yr_key, y.yr_CmmGr, y.yr_CmmGr_New, g.cnicgName
FROM sudz.yr y
LEFT JOIN sudz.cnInvCmmGr g ON g.cnicgKey = y.yr_CmmGr_New
WHERE y.yr_key = 901;

SELECT cnicInvAccnt, cnicType, LEFT(cnicText, 80) AS txt
FROM sudz.cnInvCmm
WHERE cnicGroup = (SELECT yr_CmmGr_New FROM sudz.yr WHERE yr_key = 901)
ORDER BY cnicInvAccnt, cnicType;
