USE [FishEye];
GO

-- =============================================================================
-- Файл:    07o_plan_align_spot_2102.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Gate plan-align (этап 21.2) — spot golden cstAgPn=2102, stIpg=42.
--   iv_Pl / iv_PlAccum ненулевые на ИП 6, 8, 11 (FIXTURE_06, группы UtPl 18–20).
-- Предусловия: 05b (plan-JOIN → ipgChRl_2606), FIXTURE_06.
-- Автор:   Александр | Дата: 2026-06-30
-- =============================================================================

SET NOCOUNT ON;
GO

RAISERROR(N'=== 07o plan-align spot: cst 2102, stIpg=42, yearend 2022-12-31 ===', 0, 1) WITH NOWAIT;

DECLARE @ipgCh   int  = 5;
DECLARE @stIpg   int  = 42;
DECLARE @cstAgPn int  = 2102;
DECLARE @dt      date = '2022-12-31';
DECLARE @fail    int  = 0;
DECLARE @msg     nvarchar(500);

IF OBJECT_ID('tempdb..#plan') IS NOT NULL DROP TABLE #plan;

SELECT
    p.ipgKey,
    MAX(p.iv_Pl)       AS iv_Pl,
    MAX(p.iv_PlAccum)  AS iv_PlAccum
INTO #plan
FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, @stIpg, NULL) p
WHERE p.cstapKey = @cstAgPn
  AND p.dateRslt = @dt
  AND p.ipgKey IN (6, 8, 11)
GROUP BY p.ipgKey;

SELECT ipgKey, iv_Pl, iv_PlAccum FROM #plan ORDER BY ipgKey;

DECLARE @ipg int = 6;
WHILE @ipg <= 11
BEGIN
    IF @ipg IN (6, 8, 11)
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM #plan t
            WHERE t.ipgKey = @ipg
              AND ISNULL(t.iv_Pl, 0) <> 0
              AND ISNULL(t.iv_PlAccum, 0) <> 0
        )
        BEGIN
            SET @fail = @fail + 1;
            SET @msg = N'  FAIL: ipgKey=' + CAST(@ipg AS nvarchar(10))
                + N' — iv_Pl/iv_PlAccum expected non-zero';
            RAISERROR(@msg, 0, 1) WITH NOWAIT;
        END
        ELSE
        BEGIN
            SET @msg = N'  OK ipgKey=' + CAST(@ipg AS nvarchar(10));
            RAISERROR(@msg, 0, 1) WITH NOWAIT;
        END
    END
    SET @ipg = @ipg + 1;
END

IF @fail = 0
    RAISERROR(N'=== 07o plan-align spot: PASS ===', 0, 1) WITH NOWAIT;
ELSE
    RAISERROR(N'=== 07o plan-align spot: FAIL ===', 0, 1) WITH NOWAIT;
GO
