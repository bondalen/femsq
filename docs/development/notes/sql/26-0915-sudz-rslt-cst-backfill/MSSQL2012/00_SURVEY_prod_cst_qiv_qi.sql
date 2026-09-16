/*
 * 00 — READ ONLY survey: стройка для QIV/QI на проде (и DEV).
 * lastUpdated: 2026-09-15
 *
 * Цель: понять, хватит ли ags (g_p + fnCiasDbtUplCst + cn_inv_pm) и есть ли
 * целевая таблица FEMSQ DbtUplCstAg для бэкфилла квартальных колонок Rslt.
 *
 * Параметры ниже — подставить под среду (DEV: yr/upl 901/902; на prod — свои ключи).
 */
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ===== параметры ===== */
DECLARE @YrKey   int = 901;   /* FEMSQ yr_key */
DECLARE @UplQiv  int = 901;   /* FEMSQ upl QIV / база */
DECLARE @UplQi   int = 902;   /* FEMSQ upl QI */
/* схема новой модели: на DEV обычно sudz; на prod после cutover — уточнить */
DECLARE @SudzSchema sysname = N'sudz';

DECLARE @sql nvarchar(max);

PRINT N'=== 0. Параметры ===';
SELECT @YrKey AS YrKey, @UplQiv AS UplQiv, @UplQi AS UplQi, @SudzSchema AS SudzSchema;

PRINT N'=== 1. Объекты ===';
SELECT
    OBJECT_ID(QUOTENAME(@SudzSchema) + N'.DbtUplCstAg') AS DbtUplCstAg,
    OBJECT_ID(QUOTENAME(@SudzSchema) + N'.vw_Yr_DbtFact') AS vw_Yr_DbtFact,
    OBJECT_ID(QUOTENAME(@SudzSchema) + N'.invDbtCia') AS invDbtCia,
    OBJECT_ID(QUOTENAME(@SudzSchema) + N'.DbtValue') AS DbtValue,
    OBJECT_ID(QUOTENAME(@SudzSchema) + N'.cn_inv_dbt_upl_g_p') AS sudz_g_p,
    OBJECT_ID(N'ags.cn_inv_dbt_upl_g_p') AS ags_g_p,
    OBJECT_ID(N'ags.fnCiasDbtUplCst') AS fnCiasDbtUplCst,
    OBJECT_ID(N'ags.cn_inv_pm') AS cn_inv_pm;

PRINT N'=== 2. FEMSQ upl QIV/QI ===';
SET @sql = N'
SELECT u.upl_key, u.upl_date, u.uplStatusOnDate,
       (SELECT COUNT(*) FROM ' + QUOTENAME(@SudzSchema) + N'.DbtValue dv WHERE dv.dvUpl = u.upl_key) AS dvN
FROM ' + QUOTENAME(@SudzSchema) + N'.cn_inv_dbt_upl u
WHERE u.upl_key IN (@UplQiv, @UplQi)
ORDER BY u.upl_key;';
EXEC sp_executesql @sql, N'@UplQiv int, @UplQi int', @UplQiv, @UplQi;

PRINT N'=== 3. Сопоставление FEMSQ upl → ags upl по uplStatusOnDate ===';
SET @sql = N'
SELECT f.upl_key AS femsqUpl, f.uplStatusOnDate AS statusOn,
       a.upl_key AS agsUpl, a.upl_date AS agsUplDate, a.uplStatusOnDate AS agsStatusOn,
       (SELECT COUNT(*) FROM ags.cn_inv_dbt d WHERE d.cn_inv_dbt_upl = a.upl_key) AS agsDbtN,
       (SELECT COUNT(*) FROM ags.cn_inv_dbt_upl_g_p gp WHERE gp.cn_inv_dbt_upl = a.upl_key) AS agsGpN
FROM ' + QUOTENAME(@SudzSchema) + N'.cn_inv_dbt_upl f
LEFT JOIN ags.cn_inv_dbt_upl a
  ON a.uplStatusOnDate = f.uplStatusOnDate
WHERE f.upl_key IN (@UplQiv, @UplQi)
ORDER BY f.upl_key, a.upl_key;';
EXEC sp_executesql @sql, N'@UplQiv int, @UplQi int', @UplQiv, @UplQi;

PRINT N'=== 4. ags g_p: горизонт statusOn (есть ли QIV/QI) ===';
SELECT TOP 30
    CONVERT(varchar(10), du.uplStatusOnDate, 23) AS statusOn,
    COUNT(*) AS gpN,
    MIN(gp.cn_inv_dbt_upl) AS minDbtUpl,
    MAX(gp.cn_inv_dbt_upl) AS maxDbtUpl
FROM ags.cn_inv_dbt_upl_g_p gp
JOIN ags.cn_inv_dbt_upl du ON du.upl_key = gp.cn_inv_dbt_upl
GROUP BY du.uplStatusOnDate
ORDER BY du.uplStatusOnDate DESC;

PRINT N'=== 5. DbtUplCstAg: уже заполнено для QIV/QI? ===';
IF OBJECT_ID(QUOTENAME(@SudzSchema) + N'.DbtUplCstAg') IS NOT NULL
BEGIN
    SET @sql = N'
    SELECT ducaUpl, COUNT(*) AS n
    FROM ' + QUOTENAME(@SudzSchema) + N'.DbtUplCstAg
    WHERE ducaUpl IN (@UplQiv, @UplQi)
    GROUP BY ducaUpl
    ORDER BY ducaUpl;
    SELECT COUNT(*) AS totalAll FROM ' + QUOTENAME(@SudzSchema) + N'.DbtUplCstAg;';
    EXEC sp_executesql @sql, N'@UplQiv int, @UplQi int', @UplQiv, @UplQi;
END
ELSE
    PRINT N'DbtUplCstAg отсутствует в схеме ' + @SudzSchema;

PRINT N'=== 6. vw_Yr_DbtFact: сколько строк с кодом стройки (если view есть) ===';
IF OBJECT_ID(QUOTENAME(@SudzSchema) + N'.vw_Yr_DbtFact') IS NOT NULL
BEGIN
    SET @sql = N'
    SELECT f.upl_key,
           COUNT(*) AS rowsN,
           SUM(CASE WHEN f.CstAgPnKey IS NOT NULL THEN 1 ELSE 0 END) AS withKey,
           SUM(CASE WHEN f.CstAgPnCode IS NOT NULL AND LTRIM(RTRIM(CONVERT(nvarchar(200), f.CstAgPnCode))) <> N'''' THEN 1 ELSE 0 END) AS withCode
    FROM ' + QUOTENAME(@SudzSchema) + N'.vw_Yr_DbtFact f
    WHERE f.yr_key = @YrKey AND f.upl_key IN (@UplQiv, @UplQi)
    GROUP BY f.upl_key
    ORDER BY f.upl_key;';
    EXEC sp_executesql @sql, N'@YrKey int, @UplQiv int, @UplQi int', @YrKey, @UplQiv, @UplQi;
END
ELSE
    PRINT N'vw_Yr_DbtFact отсутствует';

PRINT N'=== 7. Сырой pm: объём с cnipCstAgPn ===';
SELECT
    COUNT(*) AS pmN,
    SUM(CASE WHEN cnipCstAgPn IS NOT NULL THEN 1 ELSE 0 END) AS pmWithCst
FROM ags.cn_inv_pm;

PRINT N'=== 8. ags g_p на сопоставленных upl (критично для fn) ===';
;WITH femsq AS (
    SELECT u.upl_key AS femsqUpl, u.uplStatusOnDate
    FROM sudz.cn_inv_dbt_upl u
    WHERE u.upl_key IN (@UplQiv, @UplQi)
)
SELECT
    f.femsqUpl,
    CONVERT(varchar(10), f.uplStatusOnDate, 23) AS statusOn,
    a.upl_key AS agsUpl,
    (SELECT COUNT(*) FROM ags.cn_inv_dbt_upl_g_p gp WHERE gp.cn_inv_dbt_upl = a.upl_key) AS gpN,
    (SELECT COUNT(*) FROM ags.cn_inv_dbt d WHERE d.cn_inv_dbt_upl = a.upl_key) AS agsDbtN
FROM femsq f
LEFT JOIN ags.cn_inv_dbt_upl a ON a.uplStatusOnDate = f.uplStatusOnDate
ORDER BY f.femsqUpl, a.upl_key;

PRINT N'Если gpN=0 для QIV/QI — fnCiasDbtUplCst на этом upl пуст; бэкфилл через 01/02 нечем питаться, пока нет g_p (1.1.1.2).';
PRINT N'Покрытие fn по FEMSQ-слотам — скрипт 01_CANDIDATES (через invDbtCia).';
PRINT N'=== survey done ===';
GO
