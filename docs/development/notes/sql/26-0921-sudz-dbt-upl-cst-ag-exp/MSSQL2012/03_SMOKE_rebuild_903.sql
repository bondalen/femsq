-- 03_SMOKE_rebuild_903.sql — EXEC Exp @903 после §3.2c
SET NOCOUNT ON;

EXEC sudz.usp_RebuildDbtUplCstAgExp @dbtUpl = 903;

SELECT
    (SELECT COUNT(*) FROM sudz.DbtUplCstAg WHERE ducaUpl = 903) AS canon_duca_903,
    (SELECT COUNT(*) FROM sudz.DbtUplCstAgExp WHERE duexUpl = 903 AND duexRule = 11) AS exp_11,
    (SELECT COUNT(*) FROM sudz.DbtUplCstAgExp WHERE duexUpl = 903 AND duexName = N'1.2 agent') AS exp_12_agent,
    (SELECT COUNT(*) FROM sudz.DbtUplCstAgExp WHERE duexUpl = 903 AND duexName = N'1.2 multi') AS exp_12_multi,
    (SELECT COUNT(*) FROM sudz.DbtUplCstAgExp WHERE duexUpl = 903 AND duexName = N'1.3 out-gp') AS exp_13_out,
    (SELECT COUNT(*) FROM sudz.DbtUplCstAgExp WHERE duexUpl = 903 AND duexName = N'1.3 agent') AS exp_13_agent,
    (SELECT COUNT(*) FROM sudz.DbtUplCstAgExp WHERE duexUpl = 903 AND duexName = N'1.3 multi') AS exp_13_multi,
    (SELECT COUNT(*) FROM sudz.DbtUplCstAgExp WHERE duexUpl = 903 AND duexRule = 14) AS exp_14,
    (SELECT COUNT(*) FROM sudz.DbtUplCstAgExp WHERE duexUpl = 903) AS exp_all;

SELECT TOP 20 duexDbt, duexCode, duexName, duexDetail, duexCstAgPn
FROM sudz.DbtUplCstAgExp
WHERE duexUpl = 903 AND duexRule = 13
ORDER BY duexName, duexDbt;

SELECT duexDetail, COUNT(*) AS n
FROM sudz.DbtUplCstAgExp
WHERE duexUpl = 903 AND duexRule = 13
GROUP BY duexDetail;
