-- Access QueryDef: ags_Yr_DbtChangesRsltD644_24-0226
-- Type: 0

SELECT r.account_num AS [Счёт Главной книги], c.cstapOgName AS Агент, r.[2023-02-02_org_id_value_l] AS [№ контрагента], r.[2023-02-02_ITN] AS [ИНН контрагента], r.[2023-02-02_CtptOrg] AS Контрагент, r.[2023-02-02_cnNumEnum] AS Договор, r.[2023-02-02_csoCnDate] AS [Дата договора], r.invNumEnumN AS [счет-фактура], d.cn_inv_date_start AS [Дата образования], r.[2023-02-02_Maturity] AS [Срок погашения 31_12_22], r.[2023-02-02_Ttl] AS [Всего сумма задолженности в рублях 31_12_22], r.[2023-02-02_Overd] AS [Просроченная задолженность в рублях 31_12_22], r.[2024-01-30_Maturity] AS [Срок погашения 31_12_23], r.[2024-01-30_Overd] AS [Просроченная задолженность в рублях 31_12_23], r.[2024-01-30_погашено] AS [Погашено проср задолженности с начала года в рублях 31_12_23], r.[Код стройки], r.[Код стройкиN] AS [Наименование стройки], r.[Мероприятия по погашению дебиторской задолженности] AS [Комментарий Филиала 644]
FROM ([ags_Yr_DbtChangesRslt_24-0207] AS r LEFT JOIN ags_cstAgPn AS c ON r.[Код стройки] = c.cstapIpgPnN) LEFT JOIN ags_cn_inv_dbt AS d ON r.[2023-02-02_ciaKey] = d.cidCnInvAccntCtpt
WHERE (((r.[2023-02-02_Overd])>0) AND ((d.cn_inv_dbt_upl)=16 Or (d.cn_inv_dbt_upl) Is Null))
ORDER BY r.account_num, c.cstapOgName, r.[2023-02-02_CtptOrg], r.[2023-02-02_cnNumEnum], r.invNumEnumN;
