-- Verify shadow load counts (run after rewritten 01..08 on Docker)
SELECT N'i_ra_at' AS tbl, COUNT(*) AS cnt FROM ags.i_ra_at
UNION ALL SELECT N'i_ra_dir', COUNT(*) FROM ags.i_ra_dir
UNION ALL SELECT N'i_ra_ft', COUNT(*) FROM ags.i_ra_ft
UNION ALL SELECT N'i_ra_ft_st', COUNT(*) FROM ags.i_ra_ft_st
UNION ALL SELECT N'i_ra_ft_s', COUNT(*) FROM ags.i_ra_ft_s
UNION ALL SELECT N'i_ra_ft_sn', COUNT(*) FROM ags.i_ra_ft_sn
UNION ALL SELECT N'i_ra_a', COUNT(*) FROM ags.i_ra_a
UNION ALL SELECT N'i_ra_f', COUNT(*) FROM ags.i_ra_f
ORDER BY tbl;

-- Orphan checks (should be 0)
SELECT N'ra_a bad adt_type' AS chk, COUNT(*) AS bad
FROM ags.i_ra_a a LEFT JOIN ags.i_ra_at t ON a.adt_type = t.at_key WHERE t.at_key IS NULL
UNION ALL
SELECT N'ra_a bad adt_dir', COUNT(*)
FROM ags.i_ra_a a LEFT JOIN ags.i_ra_dir d ON a.adt_dir = d.[key] WHERE d.[key] IS NULL
UNION ALL
SELECT N'ra_f bad af_dir', COUNT(*)
FROM ags.i_ra_f f LEFT JOIN ags.i_ra_dir d ON f.af_dir = d.[key] WHERE d.[key] IS NULL
UNION ALL
SELECT N'ra_f bad af_type', COUNT(*)
FROM ags.i_ra_f f LEFT JOIN ags.i_ra_ft t ON f.af_type = t.ft_key WHERE t.ft_key IS NULL
UNION ALL
SELECT N'ra_ft_sn bad ftsn_ft_s', COUNT(*)
FROM ags.i_ra_ft_sn n LEFT JOIN ags.i_ra_ft_s s ON n.ftsn_ft_s = s.ft_s_key WHERE s.ft_s_key IS NULL;
