/*
=============================================================================
Файл:    05b_CREATE_PROCEDURE_spIpgChRsltCstUtlPercentBrn_2606.sql
Объект:  ags.spIpgChRsltCstUtlPercentBrn_2606
Дата:    2026-06-15
Этап:    14.3 (Ступень 3) — PercentBrn MSTVF → SP, fn2 через spIpgChRsltCstUtl2_2606
=============================================================================
НАЗНАЧЕНИЕ:
  Трансформация OBJECT_DEFINITION(fnIpgChRsltCstUtlPercentBrn_2606):
  - MSTVF → PROCEDURE (финальный SELECT вместо INSERT @TableRslt)
  - fn2_2606 → #fn2 + EXEC spIpgChRsltCstUtl2_2606
ПРЕДУСЛОВИЯ: 04 (fn2), 04b (spFn2), 05 (fn PercentBrn_2606)
=============================================================================*/
USE [FishEye];
GO
SET NOCOUNT ON;
PRINT N'=== 05b: CREATE PROCEDURE ags.spIpgChRsltCstUtlPercentBrn_2606 ===';
GO

DECLARE @def  nvarchar(max);
DECLARE @pc   int;
DECLARE @beg  int;
DECLARE @fn2From nvarchar(200) = N'from ags.fnIpgChRsltCstUtl2_2606(@ipgChKey, @ipgStKey, @stCostKey) t';
DECLARE @fn2Hash nvarchar(200) = N'from #fn2 t';

SET @def = OBJECT_DEFINITION(OBJECT_ID(N'ags.fnIpgChRsltCstUtlPercentBrn_2606'));
IF @def IS NULL
BEGIN
    RAISERROR(N'ОШИБКА: ags.fnIpgChRsltCstUtlPercentBrn_2606 не найдена. Сначала выполните 05.', 16, 1);
    RETURN;
END

-- Имя и тип объекта
SET @def = REPLACE(@def, N'fnIpgChRsltCstUtlPercentBrn_2606', N'spIpgChRsltCstUtlPercentBrn_2606');
SET @def = REPLACE(@def, N'CREATE   FUNCTION', N'CREATE OR ALTER PROCEDURE');
SET @def = REPLACE(@def, N'CREATE FUNCTION', N'CREATE OR ALTER PROCEDURE');

-- Удалить RETURNS @TableRslt TABLE ( ... ) — оставить AS BEGIN
SET @pc = CHARINDEX(N'@stCostKey', @def);
IF @pc = 0 BEGIN RAISERROR(N'@stCostKey не найден в PercentBrn', 16, 1); RETURN; END
-- Закрывающая ) параметров — после строки @stCostKey (не внутри комментария «(NULL = …)»)
DECLARE @lineEnd int = CHARINDEX(CHAR(10), @def, @pc);
IF @lineEnd = 0 SET @lineEnd = @pc + 80;
SET @pc = CHARINDEX(N')', @def, @lineEnd);
IF @pc = 0 BEGIN RAISERROR(N'Закрывающая ) параметров не найдена', 16, 1); RETURN; END
SET @beg = CHARINDEX(N'BEGIN', @def, @pc);
IF @beg = 0 BEGIN RAISERROR(N'BEGIN не найден', 16, 1); RETURN; END
SET @def = LEFT(@def, @pc) + N' AS ' + SUBSTRING(@def, @beg, LEN(@def) - @beg + 1);

-- fn2 TVF → #fn2 + EXEC sp (схема #fn2 через TOP 0 — мгновенно)
IF CHARINDEX(@fn2From, @def) = 0
BEGIN
    RAISERROR(N'ОШИБКА: шаблон from fn2_2606 не найден в PercentBrn', 16, 1);
    RETURN;
END
SET @def = REPLACE(@def, @fn2From, @fn2Hash);

DECLARE @insPos int = CHARINDEX(N'AS BEGIN', @def);
IF @insPos = 0 BEGIN RAISERROR(N'AS BEGIN не найден', 16, 1); RETURN; END
SET @insPos = @insPos + LEN(N'AS BEGIN');
SET @def = STUFF(@def, @insPos, 0,
    N'
    SET NOCOUNT ON;
    IF OBJECT_ID(N''tempdb..#fn2'') IS NOT NULL DROP TABLE #fn2;
    SELECT TOP 0 * INTO #fn2 FROM ags.fnIpgChRsltCstUtl2_2606(@ipgChKey, @ipgStKey, @stCostKey);
    INSERT INTO #fn2 EXEC ags.spIpgChRsltCstUtl2_2606 @ipgChKey, @ipgStKey, @stCostKey;
');

-- Финальный набор — INSERT в #TableFn... (создаётся в spMstrg_2606 до EXEC)
DECLARE @lastIns int = 0, @pos int = 0;
WHILE 1 = 1
BEGIN
    SET @pos = CHARINDEX(N'INSERT INTO @TableRslt', @def, @pos + 1);
    IF @pos = 0 BREAK;
    SET @lastIns = @pos;
END
IF @lastIns = 0
BEGIN
    RAISERROR(N'INSERT INTO @TableRslt не найден в PercentBrn', 16, 1);
    RETURN;
END
DECLARE @sel int = CHARINDEX(N'SELECT', @def, @lastIns);
IF @sel = 0
BEGIN
    RAISERROR(N'SELECT после @TableRslt не найден', 16, 1);
    RETURN;
END
SET @def = STUFF(@def, @lastIns, @sel - @lastIns, N'INSERT INTO #TableFnIpgChRsltCstUtlPercentBrn_2606 ');
SET @def = REPLACE(@def, N'RETURN;', N'');

IF @def NOT LIKE N'%spIpgChRsltCstUtlPercentBrn_2606%'
   OR @def NOT LIKE N'%#fn2%'
   OR @def NOT LIKE N'%fnIpgChRsltCstUtl2_2606%'
BEGIN
    RAISERROR(N'ОШИБКА: замены в spPercentBrn_2606 не применились.', 16, 1);
    RETURN;
END

EXEC sp_executesql @def;
GO

PRINT N'=== 05b: ags.spIpgChRsltCstUtlPercentBrn_2606 создана ===';
GO
