-- Access QueryDef: 24-1128_ipg25_q_delta
-- Type: 0

SELECT ags_ipgPn.ipgpSmTtl, ags_ipgPn.ipgpSmWrk, ags_ipgPn.ipgpSmEqu, ags_ipgPn.ipgpSmOth, [ipgpSmWrk]+[ipgpSmEqu]+[ipgpSmOth] AS sumSum, [ipgpSmTtl]-[sumSum] AS ddd, ags_ipgPn.ipgpIpg
FROM ags_ipgPn
WHERE (((ags_ipgPn.ipgpIpg)=25));
