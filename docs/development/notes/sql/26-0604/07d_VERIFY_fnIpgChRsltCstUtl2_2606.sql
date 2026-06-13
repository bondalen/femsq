USE [FishEye];
GO

-- =============================================================================
-- Файл:    07d_VERIFY_fnIpgChRsltCstUtl2_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Приёмка этапа 4 — fnIpgChRsltCstUtl2_2606 на цепи 5 (быстрые тесты).
--   @ipgStKey=21, @stCostKey=212: COUNT, отсутствие задвоения ИПГ, spot-check presented.
--   Полный (NULL,NULL,NULL) и сравнение всех сумм с _2605 — отдельно, ~15–30 мин.
-- Предусловия: 04.
-- Автор:   Александр
-- Дата:    2026-06-09
-- =============================================================================

SET NOCOUNT ON;
GO

PRINT '=== 07d: VERIFY fnIpgChRsltCstUtl2_2606 (цепь 5, ipgStKey=21) ===';

DECLARE @fail int = 0;

DECLARE @cnt2606 int = (SELECT COUNT(*) FROM ags.fnIpgChRsltCstUtl2_2606(5, 21, 212));

PRINT N'Test 1 COUNT(5,21,212): ' + CAST(@cnt2606 AS nvarchar(10)) + N' (expected > 0)';

IF @cnt2606 <= 0
BEGIN
    SET @fail = @fail + 1;
    PRINT N'  FAIL';
END
ELSE
    PRINT N'  OK';

DECLARE @dupCnt int = (
    SELECT COUNT(*)
    FROM (
        SELECT mNum, cstAgPnKey, iShKey
        FROM ags.fnIpgChRsltCstUtl2_2606(5, 21, NULL)
        WHERE mNum = 9 AND iShKey = 2 AND presented IS NOT NULL
        GROUP BY mNum, cstAgPnKey, iShKey
        HAVING COUNT(DISTINCT ipgKey) > 1
    ) d
);

PRINT N'Test 2 IPG dup month 9 st21 (expect 0): ' + CAST(@dupCnt AS nvarchar(10));

IF @dupCnt <> 0
BEGIN
    SET @fail = @fail + 1;
    PRINT N'  FAIL';
END
ELSE
    PRINT N'  OK';

DECLARE @pres2606 money = (
    SELECT presented FROM ags.fnIpgChRsltCstUtl2_2606(5, 21, 212)
    WHERE cstAgPnKey = 453 AND mNum = 3 AND iShKey = 2 AND presented IS NOT NULL
);

DECLARE @pres2605 money = (
    SELECT f.presented FROM ags.fnIpgChRsltCstUtl2_2605(5, NULL) f
    WHERE f.cstAgPnKey = 453 AND f.mNum = 3 AND f.iShKey = 2 AND f.presented IS NOT NULL
      AND EXISTS (
          SELECT 1 FROM ags.ipgStPn s
          INNER JOIN ags.ipgPn p ON p.ipgpKey = s.ipgspPn
          WHERE s.ipgspSt = 21 AND p.ipgpCstAgPn = f.cstAgPnKey
      )
);

PRINT N'Test 3 spot cstAgPnKey=453 mNum=3 presented: _2606='
    + CAST(@pres2606 AS nvarchar(30)) + N' _2605=' + CAST(@pres2605 AS nvarchar(30));

IF ISNULL(@pres2606, -1) <> ISNULL(@pres2605, -1)
BEGIN
    SET @fail = @fail + 1;
    PRINT N'  FAIL';
END
ELSE
    PRINT N'  OK';

DECLARE @ipg2606 int = (
    SELECT ipgKey FROM ags.fnIpgChRsltCstUtl2_2606(5, NULL, NULL)
    WHERE cstAgPnKey = 16 AND mNum = 9 AND iShKey = 2 AND presented IS NOT NULL
);

DECLARE @ipgDup2605 int = (
    SELECT COUNT(DISTINCT ipgKey) FROM ags.fnIpgChRsltCstUtl2_2605(5, NULL)
    WHERE cstAgPnKey = 16 AND mNum = 9 AND iShKey = 2 AND presented IS NOT NULL
);

PRINT N'Test 4 defect B cstAgPnKey=16 mNum=9: _2606 ipgKey='
    + ISNULL(CAST(@ipg2606 AS nvarchar(10)), N'NULL')
    + N', _2605 distinct ipg count=' + CAST(@ipgDup2605 AS nvarchar(10))
    + N' (expect single ipg in _2606, _2605 may have 2)';

IF @ipgDup2605 > 1 AND @ipg2606 IS NOT NULL AND (
    SELECT COUNT(DISTINCT ipgKey) FROM ags.fnIpgChRsltCstUtl2_2606(5, NULL, NULL)
    WHERE cstAgPnKey = 16 AND mNum = 9 AND iShKey = 2 AND presented IS NOT NULL
) = 1
    PRINT N'  OK (defect B fixed: no IPG duplication in _2606)';
ELSE IF @ipgDup2605 <= 1
    PRINT N'  OK (no duplication in _2605 either)';
ELSE
BEGIN
    SET @fail = @fail + 1;
    PRINT N'  FAIL';
END

IF @fail = 0
    PRINT N'=== 07d: PASS ===';
ELSE
    PRINT N'=== 07d: FAIL (' + CAST(@fail AS nvarchar(10)) + N' test(s)) ===';
GO
