USE [FishEye];
GO

-- =============================================================================
-- Файл:    01_CREATE_TABLE_ipgChRlV.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Таблица сроков актуальности ИПГ в цепи (Дефект Б).
--   Хранится только ipgcrvStr (атрибут связи «цепь — ИПГ»).
--   ipgcrvEnd — вычисляемый столбец через ags.fnIpgChRlVEnd (MIN следующего
--   ipgcrvStr в той же цепи − 1 день); NULL = «по сей день».
-- Автор:   Александр
-- Дата:    2026-06-04
-- =============================================================================

PRINT '=== 01: CREATE TABLE ags.ipgChRlV + FUNCTION ags.fnIpgChRlVEnd ===';

-- Убираем старые объекты при перепрогоне
IF OBJECT_ID(N'ags.vIpgChRlV', N'V') IS NOT NULL
BEGIN
    PRINT 'DROP устаревшего ags.vIpgChRlV...';
    DROP VIEW ags.vIpgChRlV;
END;
GO

IF OBJECT_ID(N'ags.ipgChRlV', N'U') IS NOT NULL
BEGIN
    PRINT 'DROP существующей ags.ipgChRlV...';
    DROP TABLE ags.ipgChRlV;
END;
GO

IF OBJECT_ID(N'ags.fnIpgChRlVEnd', N'FN') IS NOT NULL
BEGIN
    PRINT 'DROP существующей ags.fnIpgChRlVEnd...';
    DROP FUNCTION ags.fnIpgChRlVEnd;
END;
GO

-- -----------------------------------------------------------------------------
-- Шаг 1: таблица (без вычисляемого столбца — он добавляется после функции)
-- -----------------------------------------------------------------------------
CREATE TABLE ags.ipgChRlV
(
    ipgcrvKey     int           NOT NULL IDENTITY(1, 1),
    ipgcrvChain   int           NOT NULL,
    ipgcrvIpg     int           NOT NULL,
    ipgcrvStr     date          NOT NULL,
    ipgcrvUtPlGr  int           NULL,
    CONSTRAINT PK_ipgChRlV      PRIMARY KEY CLUSTERED (ipgcrvKey),
    CONSTRAINT UQ_ipgChRlV_chain_ipg UNIQUE (ipgcrvChain, ipgcrvIpg),
    CONSTRAINT UQ_ipgChRlV_chain_str UNIQUE (ipgcrvChain, ipgcrvStr),
    CONSTRAINT FK_ipgChRlV_ipgCh FOREIGN KEY (ipgcrvChain)
        REFERENCES ags.ipgCh (ipgcKey),
    CONSTRAINT FK_ipgChRlV_ipg  FOREIGN KEY (ipgcrvIpg)
        REFERENCES ags.ipg (ipgKey),
    CONSTRAINT FK_ipgChRlV_ipgUtPlGr FOREIGN KEY (ipgcrvUtPlGr)
        REFERENCES ags.ipgUtPlGr (iuplgKey)
);
GO

PRINT 'Таблица ags.ipgChRlV создана.';
GO

-- -----------------------------------------------------------------------------
-- Шаг 2: скалярная функция для вычисляемого столбца ipgcrvEnd
-- Возвращает MIN(ipgcrvStr) последующих строк той же цепи − 1 день.
-- NULL = текущая/последняя ИПГ в цепи.
-- -----------------------------------------------------------------------------
CREATE FUNCTION ags.fnIpgChRlVEnd(@chain int, @str date)
RETURNS date
AS
BEGIN
    RETURN DATEADD(day, -1, (
        SELECT MIN(t.ipgcrvStr)
        FROM ags.ipgChRlV t
        WHERE t.ipgcrvChain = @chain
          AND t.ipgcrvStr > @str
    ))
END;
GO

PRINT 'Функция ags.fnIpgChRlVEnd создана.';
GO

-- -----------------------------------------------------------------------------
-- Шаг 3: добавляем вычисляемый столбец ipgcrvEnd в таблицу
-- -----------------------------------------------------------------------------
ALTER TABLE ags.ipgChRlV
    ADD ipgcrvEnd AS (ags.fnIpgChRlVEnd(ipgcrvChain, ipgcrvStr));
GO

PRINT 'Столбец ipgcrvEnd (computed) добавлен в ags.ipgChRlV.';
GO

-- -----------------------------------------------------------------------------
-- Шаг 4: заполнение данными — только ipgcrvStr из ipg.ipgStr
-- -----------------------------------------------------------------------------
PRINT 'INSERT цепи 5 и 15...';

INSERT INTO ags.ipgChRlV (ipgcrvChain, ipgcrvIpg, ipgcrvStr, ipgcrvUtPlGr)
SELECT
    r.ipgcrChain,
    r.ipgcrIpg,
    CAST(i.ipgStr AS date),
    r.ipgcrUtPlGr
FROM ags.ipgChRl r
INNER JOIN ags.ipg i ON i.ipgKey = r.ipgcrIpg
WHERE r.ipgcrChain IN (5, 15)
  AND i.ipgStr IS NOT NULL;

PRINT 'INSERT: ' + CAST(@@ROWCOUNT AS varchar(10)) + ' строк.';
GO

-- -----------------------------------------------------------------------------
-- Проверка 1.1: структура таблицы — все 6 колонок (5 физ. + 1 вычисл.)
-- -----------------------------------------------------------------------------
PRINT '--- Проверка структуры ipgChRlV ---';
SELECT c.name, c.is_computed, c.is_nullable
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
WHERE t.name = 'ipgChRlV' AND SCHEMA_NAME(t.schema_id) = 'ags'
ORDER BY c.column_id;
GO

-- -----------------------------------------------------------------------------
-- Проверка 1.2: нет перекрытий (ipgcrvEnd вычисляется прямо из таблицы)
-- -----------------------------------------------------------------------------
PRINT '--- Проверка перекрытий ---';

SELECT
    a.ipgcrvChain,
    a.ipgcrvIpg AS ipg_a,
    b.ipgcrvIpg AS ipg_b,
    a.ipgcrvStr AS str_a,
    a.ipgcrvEnd AS end_a,
    b.ipgcrvStr AS str_b,
    b.ipgcrvEnd AS end_b
FROM ags.ipgChRlV a
INNER JOIN ags.ipgChRlV b
    ON a.ipgcrvChain = b.ipgcrvChain
   AND a.ipgcrvKey < b.ipgcrvKey
WHERE a.ipgcrvChain IN (5, 15)
  AND a.ipgcrvStr <= ISNULL(b.ipgcrvEnd, '9999-12-31')
  AND b.ipgcrvStr <= ISNULL(a.ipgcrvEnd, '9999-12-31');

IF @@ROWCOUNT = 0
    PRINT 'OK: перекрытий нет.';
ELSE
    PRINT 'ОШИБКА: обнаружены перекрывающиеся периоды!';
GO

-- -----------------------------------------------------------------------------
-- Проверка 1.3: итоговые данные (ipgcrvEnd вычисляется автоматически)
-- -----------------------------------------------------------------------------
PRINT '--- Содержимое ipgChRlV ---';
SELECT
    v.ipgcrvChain,
    v.ipgcrvIpg,
    i.ipgNm,
    v.ipgcrvStr,
    v.ipgcrvEnd,
    v.ipgcrvUtPlGr
FROM ags.ipgChRlV v
JOIN ags.ipg i ON i.ipgKey = v.ipgcrvIpg
WHERE v.ipgcrvChain IN (5, 15)
ORDER BY v.ipgcrvChain, v.ipgcrvStr;
GO

PRINT '=== 01: завершено ===';
GO
