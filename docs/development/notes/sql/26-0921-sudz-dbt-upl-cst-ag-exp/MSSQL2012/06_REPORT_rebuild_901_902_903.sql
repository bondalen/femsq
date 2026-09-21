-- 06_REPORT_rebuild_901_902_903.sql — §3: прогон Exp на все upl года + сводка
SET NOCOUNT ON;

EXEC sudz.usp_RebuildDbtUplCstAgExp @dbtUpl = 901;
EXEC sudz.usp_RebuildDbtUplCstAgExp @dbtUpl = 902;
EXEC sudz.usp_RebuildDbtUplCstAgExp @dbtUpl = 903;

SELECT
    e.duexUpl,
    (SELECT COUNT(*) FROM sudz.DbtUplCstAg c WHERE c.ducaUpl = e.duexUpl) AS canon_n,
    SUM(CASE WHEN e.duexRule = 11 THEN 1 ELSE 0 END) AS n_11,
    SUM(CASE WHEN e.duexName = N'1.2 agent' THEN 1 ELSE 0 END) AS n_12_agent,
    SUM(CASE WHEN e.duexName = N'1.2 multi' THEN 1 ELSE 0 END) AS n_12_multi,
    SUM(CASE WHEN e.duexName = N'1.3 out-gp' THEN 1 ELSE 0 END) AS n_13_out,
    SUM(CASE WHEN e.duexName = N'1.3 agent' THEN 1 ELSE 0 END) AS n_13_agent,
    SUM(CASE WHEN e.duexName = N'1.3 multi' THEN 1 ELSE 0 END) AS n_13_multi,
    SUM(CASE WHEN e.duexRule = 14 THEN 1 ELSE 0 END) AS n_14,
    COUNT(*) AS n_all
FROM sudz.DbtUplCstAgExp AS e
WHERE e.duexUpl IN (901, 902, 903)
GROUP BY e.duexUpl
ORDER BY e.duexUpl;

-- 1.1 vs канон: расхождения ключей (ожидание 0 на каждом upl)
SELECT c.ducaUpl, COUNT(*) AS canon_not_in_11
FROM sudz.DbtUplCstAg AS c
WHERE c.ducaUpl IN (901, 902, 903)
  AND NOT EXISTS (
      SELECT 1 FROM sudz.DbtUplCstAgExp AS e
      WHERE e.duexUpl = c.ducaUpl
        AND e.duexDbt = c.ducaDbt
        AND e.duexRule = 11
        AND e.duexCstAgPn = c.ducaCstAgPn
  )
GROUP BY c.ducaUpl
ORDER BY c.ducaUpl;

SELECT TOP 30 duexUpl, duexDbt, duexCode, duexName, duexDetail
FROM sudz.DbtUplCstAgExp
WHERE duexUpl IN (901, 902, 903)
  AND duexRule IN (12, 13)
ORDER BY duexUpl, duexRule, duexDbt;
