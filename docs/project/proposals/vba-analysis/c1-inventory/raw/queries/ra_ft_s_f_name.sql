-- Access QueryDef: ra_ft_s_f_name
-- Type: 0

SELECT ra_ft_sn.ftsn_ft_s, First(ra_ft_sn.ftsn_name) AS [First-ftsn_name]
FROM ra_ft_sn
GROUP BY ra_ft_sn.ftsn_ft_s;
