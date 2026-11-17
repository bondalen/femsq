-- Access QueryDef: ags_Yr_DbtChangesRsltD644_24-0522
-- Type: 0

SELECT r.account_num AS [Счёт Главной книги], c.cstapOgName AS Агент, r.[2024-01-30_org_id_value_l] AS [№ контрагента], r.[2024-01-30_ITN] AS [ИНН контрагента], r.[2024-01-30_CtptOrg] AS Контрагент, r.[2024-01-30_cnNumEnum] AS Договор, r.[2024-01-30_csoCnDate] AS [Дата договора], r.invNumEnumN AS [счет-фактура], d.cn_inv_date_start AS [Дата образования], r.[2024-01-30_Maturity] AS [Срок погашения 31_12_23], r.[2024-01-30_Ttl] AS [Всего сумма задолженности в рублях 31_12_23], r.[2024-01-30_Overd] AS [Просроченная задолженность в рублях 31_12_23], r.[2024-04-19_Maturity] AS [Срок погашения 31_03_24], r.[2024-04-19_Overd] AS [Просроченная задолженность в рублях 31_03_24], r.[2024-04-19_погашено] AS [Погашено проср задолженности с начала года в рублях 31_03_24], r.[Код стройки], r.[Код стройкиN] AS [Наименование стройки], r.[Мероприятия по погашению дебиторской задолженности] AS [Комментарий Филиала 644]
FROM ([ags_Yr_DbtChangesRslt_24-0425] AS r LEFT JOIN ags_cstAgPn AS c ON r.[Код стройки] = c.cstapIpgPnN) LEFT JOIN ags_cn_inv_dbt AS d ON r.[2024-01-30_ciaKey] = d.cidCnInvAccntCtpt
WHERE (
		(
			(r.[2024-01-30_Overd])>0) AND ((d.cn_inv_dbt_upl)=21 Or (d.cn_inv_dbt_upl) Is Null
		)
	)
ORDER BY r.account_num, c.cstapOgName, r.[2024-01-30_CtptOrg], r.[2024-01-30_cnNumEnum], r.invNumEnumN;
