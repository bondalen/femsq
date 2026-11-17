-- Access QueryDef: ags_Yr_DbtTbl_RsltCstRslt
-- Type: 0

SELECT r.accountNum, r.ogNm, r.ctptCode, r.ctptName, r.cnNum, r.cnDate, r.ciNum, d20.cn_inv_date_start AS StartDate, r.[01-Maturity], r.[01-Ttl], r.[01-Overd], r.[05-Maturity], r.[05-Overd], r.[05-Repaid], r.стройка_код, r.cstName, r.[tmpFl_Мероприятия по погашению дебиторской задолженности]
FROM ags_Yr_DbtTbl_RsltCst AS r LEFT JOIN (SELECT d20.cn_inv_date_start, d20.cn_inv_dbt_upl, d20.cidCnInvAccntCtpt FROM ags_cn_inv_dbt AS d20 WHERE (((d20.cn_inv_dbt_upl)=6)))  AS d20 ON r.dsCia = d20.cidCnInvAccntCtpt
WHERE (((r.[01-Overd])>0))
ORDER BY r.accountNum, r.ogNm, r.ctptCode, r.cnNum, r.ciNum;
