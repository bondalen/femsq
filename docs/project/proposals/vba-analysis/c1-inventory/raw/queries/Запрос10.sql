-- Access QueryDef: Запрос10
-- Type: 0

SELECT Sum(ags_ipgPn.ipgpSmTtl) AS [Sum-ipgpSmTtl], Sum(ags_ipgPn.ipgpSmWrk) AS [Sum-ipgpSmWrk], Sum(ags_ipgPn.ipgpSmEqu) AS [Sum-ipgpSmEqu], Sum(ags_ipgPn.ipgpSmOth) AS [Sum-ipgpSmOth], Sum(ags_ipgPn.ipgpSmAgFee) AS [Sum-ipgpSmAgFee], Sum(ags_ipgPn.ipgpSmReserv) AS [Sum-ipgpSmReserv]
FROM ags_ipgPn
GROUP BY ags_ipgPn.ipgpIpg
HAVING (((ags_ipgPn.ipgpIpg)=12));
