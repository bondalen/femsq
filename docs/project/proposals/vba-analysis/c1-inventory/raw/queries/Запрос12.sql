-- Access QueryDef: Запрос12
-- Type: 0

SELECT ags_ipgPn.ipgpIpg, ags_ipgPn.ipgpKey, ags_ipgPn.ipgpSmTtl, ags_ipgPn.ipgpSmWrk, ags_ipgPn.ipgpSmEqu, ags_ipgPn.ipgpSmOth, [ipgpSmTtl]-IIf(IsNull([ipgpSmWrk]),0,[ipgpSmWrk])-IIf(IsNull([ipgpSmEqu]),0,[ipgpSmEqu])-IIf(IsNull([ipgpSmOth]),0,[ipgpSmOth]) AS d
FROM ags_ipgPn
WHERE ((([ipgpSmTtl]-IIf(IsNull([ipgpSmWrk]),0,[ipgpSmWrk])-IIf(IsNull([ipgpSmEqu]),0,[ipgpSmEqu])-IIf(IsNull([ipgpSmOth]),0,[ipgpSmOth]))<>0));
