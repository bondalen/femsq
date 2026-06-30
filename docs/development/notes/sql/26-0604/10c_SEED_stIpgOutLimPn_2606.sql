USE [FishEye];
GO

-- =============================================================================
-- Файл:    10c_SEED_stIpgOutLimPn_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Начальные правила OUT_GROUP для узлов stIpg (Решение 16, этап 19.1).
--   Узлы 1, 2 → типы 1,2,3; 51 → 2,3; 45 → 1; листья (42, 61, …) — без строк.
-- Предусловия: 10a, 10b.
-- Автор:   Александр
-- Дата:    2026-06-29
-- =============================================================================

SET NOCOUNT ON;
GO

PRINT N'=== 10c: SEED ags.stIpgOutLimPn_2606 ===';
PRINT N'Дата: ' + CONVERT(nvarchar(30), GETDATE(), 121);
GO

-- Идемпотентно: пересоздаём seed только для известных узлов
DELETE FROM ags.stIpgOutLimPn_2606
WHERE siolpStIpg IN (1, 2, 45, 51);
GO

INSERT INTO ags.stIpgOutLimPn_2606 (siolpStIpg, siolpCstType)
VALUES
    (1, '1'), (1, '2'), (1, '3'),
    (2, '1'), (2, '2'), (2, '3'),
    (51, '2'), (51, '3'),
    (45, '1');
GO

DECLARE @cnt int;
DECLARE @leaf int;
DECLARE @fnFail int;

SELECT @cnt = COUNT(*) FROM ags.stIpgOutLimPn_2606;
SELECT @leaf = COUNT(*) FROM ags.stIpgOutLimPn_2606 WHERE siolpStIpg IN (42, 61);

IF @cnt <> 9
BEGIN
    RAISERROR(N'10c FAIL: expected 9 seed rows, got %d.', 16, 1, @cnt);
    RETURN;
END;

IF @leaf > 0
BEGIN
    RAISERROR(N'10c FAIL: leaf nodes 42/61 must have no OUT_GROUP rows (got %d).', 16, 1, @leaf);
    RETURN;
END;

-- Узлы seed должны существовать в stIpg
IF NOT EXISTS (SELECT 1 FROM ags.stIpg WHERE stiKey IN (1, 2, 45, 51))
BEGIN
    RAISERROR(N'10c FAIL: seed stIpg nodes missing in ags.stIpg.', 16, 1);
    RETURN;
END;

-- Smoke fnCstAgPnTypeChar
SELECT @fnFail = COUNT(*)
FROM (VALUES
    (N'051-1001234', N'1'),
    (N'051-2001234', N'2'),
    (N'051-3001234', N'3')
) AS t(code, expected)
WHERE ags.fnCstAgPnTypeChar(t.code) <> t.expected;

IF @fnFail > 0
BEGIN
    RAISERROR(N'10c FAIL: fnCstAgPnTypeChar smoke test (%d mismatches).', 16, 1, @fnFail);
    RETURN;
END;

PRINT N'  seed rows: ' + CAST(@cnt AS nvarchar(10));

SELECT siolpStIpg, siolpCstType
FROM ags.stIpgOutLimPn_2606
ORDER BY siolpStIpg, siolpCstType;

PRINT N'10c seed | PASS';
GO
