-- Access QueryDef: ralpRaAuTestQuRa
-- Type: 0

SELECT x.adt_key, x.adt_name, x.[First-yyyy], ags_ralpRa.ralprKey, ags_ralpRa.ralprNum, ags_ralpRa.ralprDate, ags_ralpRa.ralprCstAgPn, ags_ralpRa.ralprOgSender, ralpRaAuTest.ralprtKeySQL
FROM ((SELECT ra_a.adt_key, ra_a.adt_name, First(ags_yyyy.yyyy) AS [First-yyyy] FROM ags_yyyy INNER JOIN (((ra_dir INNER JOIN ra_a ON ra_dir.key = ra_a.adt_dir) INNER JOIN ra_dir_s_p ON ra_dir.key = ra_dir_s_p.rdsp_dir) INNER JOIN ags_ra_period ON ra_dir_s_p.rdsp_period = ags_ra_period.key) ON ags_yyyy.yKey = ags_ra_period.y GROUP BY ra_a.adt_key, ra_a.adt_name)  AS x INNER JOIN ags_ralpRa ON x.[First-yyyy] = ags_ralpRa.ralprY) LEFT JOIN ralpRaAuTest ON ags_ralpRa.ralprKey = ralpRaAuTest.ralprtKeySQL
GROUP BY x.adt_key, x.adt_name, x.[First-yyyy], ags_ralpRa.ralprKey, ags_ralpRa.ralprNum, ags_ralpRa.ralprDate, ags_ralpRa.ralprCstAgPn, ags_ralpRa.ralprOgSender, ralpRaAuTest.ralprtKeySQL;
