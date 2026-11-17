-- Access QueryDef: ags_Yr_DbtTbl_RsltCstRslt_22-0331
-- Type: 0

SELECT r.accountNum, r.ogNm, r.ctptCode, r.ctptName, r.cnNum, r.cnDate, r.ciNum, d20.cn_inv_date_start AS StartDate, r.[01-Maturity], r.[01-Ttl], r.[01-Overd], r.[02-Maturity], r.[02-Overd], r.[02-Repaid], r.стройка_код, r.cstName, r.[tmpFl_Мероприятия по погашению дебиторской задолженности] AS Выражение4
FROM ags_Yr_DbtTbl_RsltCst AS r LEFT JOIN (SELECT d20.cn_inv_date_start, d20.cn_inv_dbt_upl, d20.cidCnInvAccntCtpt FROM ags_cn_inv_dbt AS d20 WHERE (((d20.cn_inv_dbt_upl)=10)))  AS d20 ON r.dsCia = d20.cidCnInvAccntCtpt
ORDER BY r.accountNum, r.ogNm, r.ctptCode, r.cnNum, r.ciNum;
