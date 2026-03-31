/*
 * DBHub-check SQL: 1.6.3 — сверка reconcile-счётчиков с фактическими count в БД.
 *
 * Важно:
 * - Доменные таблицы (ags.ra/ra_summ/ra_change/ra_change_summ) не содержат exec_key.
 * - Поэтому “факт” для одного exec_key сверяется через baseline max ключей ДО прогона и сравнение прироста ПОСЛЕ.
 *
 * Инструкция:
 * 1) До запуска apply (addRa=true) зафиксируйте baseline max ключей:
 *    - SELECT ISNULL(MAX(ra_key),0)   FROM ags.ra;
 *    - SELECT ISNULL(MAX(ras_key),0)  FROM ags.ra_summ;
 *    - SELECT ISNULL(MAX(rac_key),0)  FROM ags.ra_change;
 *    - SELECT ISNULL(MAX([raсs_key]),0) FROM ags.ra_change_summ;
 * 2) После прогона установите @exec_key и baseline переменные ниже и выполните скрипт.
 *
 * lastUpdated: 2026-03-25
 */

DECLARE @exec_key BIGINT = 17;
DECLARE @baseline_max_ra_key   BIGINT = NULL;
DECLARE @baseline_max_ras_key  BIGINT = NULL;
DECLARE @baseline_max_rac_key  BIGINT = NULL;
DECLARE @baseline_max_racs_key BIGINT = NULL;

/* ------------------------------
 * A) Read adt_results text for this execution
 * ------------------------------ */
DECLARE @adt_key INT =
    (SELECT TOP 1 exec_adt_key FROM ags.ra_execution WHERE exec_key = @exec_key);

DECLARE @results NVARCHAR(MAX) =
    (SELECT CAST(adt_results AS NVARCHAR(MAX)) FROM ags.ra_a WHERE adt_key = @adt_key);

SELECT @adt_key AS adt_key, @exec_key AS exec_key, CAST(@results AS NVARCHAR(MAX)) AS adt_results;

/* ------------------------------
 * B) Helper: extract integer counter from adt_results (key like 'inserted=')
 * ------------------------------ */
;WITH keys AS (
    SELECT * FROM (VALUES
        (N'inserted=',               N'inserted'),
        (N'updated=',                N'updated'),
        (N'summInserted=',           N'summInserted'),
        (N'summUnchangedSkipped=',   N'summUnchangedSkipped'),
        (N'rcChangesInserted=',      N'rcChangesInserted'),
        (N'rcSumsInserted=',         N'rcSumsInserted'),
        (N'rcChangesUpdated=',       N'rcChangesUpdated'),
        (N'rcSumsInsertedChanged=',  N'rcSumsInsertedChanged'),
        (N'rcSumsUnchangedSkipped=', N'rcSumsUnchangedSkipped'),
        (N'raDeleteApplied=',        N'raDeleteApplied'),
        (N'rcDeleteApplied=',        N'rcDeleteApplied')
    ) v(keyToken, keyName)
),
extracted AS (
    SELECT
        k.keyName,
        k.keyToken,
        CHARINDEX(k.keyToken, @results) AS pos
    FROM keys k
),
parsed AS (
    SELECT
        e.keyName,
        CASE WHEN e.pos > 0 THEN
            TRY_CONVERT(INT,
                SUBSTRING(
                    @results,
                    e.pos + LEN(e.keyToken),
                    NULLIF(PATINDEX(N'%[^0-9]%', SUBSTRING(@results, e.pos + LEN(e.keyToken), 50)) - 1, -1)
                )
            )
        ELSE NULL END AS expectedValue
    FROM extracted e
)
SELECT
    keyName,
    expectedValue
INTO #expected
FROM parsed;

SELECT * FROM #expected ORDER BY keyName;

/* ------------------------------
 * C) Actual deltas from DB (requires baselines)
 * ------------------------------ */
IF @baseline_max_ra_key IS NULL OR @baseline_max_ras_key IS NULL OR @baseline_max_rac_key IS NULL OR @baseline_max_racs_key IS NULL
BEGIN
    SELECT CAST(N'Set all @baseline_max_* variables to compute actual deltas.' AS NVARCHAR(200)) AS hint;
END
ELSE
BEGIN
    SELECT
        CAST(N'actualInsertedRa' AS NVARCHAR(64)) AS metric,
        CAST(COUNT(*) AS BIGINT) AS actualValue
    INTO #actual
    FROM ags.ra
    WHERE ra_key > @baseline_max_ra_key;

    INSERT INTO #actual(metric, actualValue)
    SELECT N'actualInsertedRaSumm', COUNT(*)
    FROM ags.ra_summ
    WHERE ras_key > @baseline_max_ras_key;

    INSERT INTO #actual(metric, actualValue)
    SELECT N'actualInsertedRcChange', COUNT(*)
    FROM ags.ra_change
    WHERE rac_key > @baseline_max_rac_key;

    INSERT INTO #actual(metric, actualValue)
    SELECT N'actualInsertedRcSumm', COUNT(*)
    FROM ags.ra_change_summ
    WHERE [raсs_key] > @baseline_max_racs_key;

    SELECT * FROM #actual ORDER BY metric;

    /* ------------------------------
     * D) Compare (expected vs actual)
     * ------------------------------ */
    SELECT
        e.keyName AS expectedKey,
        e.expectedValue,
        a.metric AS actualMetric,
        a.actualValue
    FROM #expected e
    FULL JOIN #actual a
        ON 1 = 0
    ORDER BY expectedKey, actualMetric;

    SELECT
        (SELECT expectedValue FROM #expected WHERE keyName = N'inserted') AS expectedInsertedRa,
        (SELECT actualValue FROM #actual WHERE metric = N'actualInsertedRa') AS actualInsertedRa,
        (SELECT expectedValue FROM #expected WHERE keyName = N'summInserted') AS expectedInsertedRaSumm,
        (SELECT actualValue FROM #actual WHERE metric = N'actualInsertedRaSumm') AS actualInsertedRaSumm,
        (SELECT expectedValue FROM #expected WHERE keyName = N'rcChangesInserted') AS expectedInsertedRcChange,
        (SELECT actualValue FROM #actual WHERE metric = N'actualInsertedRcChange') AS actualInsertedRcChange,
        (SELECT expectedValue FROM #expected WHERE keyName = N'rcSumsInserted') AS expectedInsertedRcSumm,
        (SELECT actualValue FROM #actual WHERE metric = N'actualInsertedRcSumm') AS actualInsertedRcSumm;
END

