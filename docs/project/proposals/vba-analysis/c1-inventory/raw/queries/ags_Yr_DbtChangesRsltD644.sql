-- Access QueryDef: ags_Yr_DbtChangesRsltD644
-- Type: 0

SELECT r.account_num AS [Счёт Главной книги], c.cstapOgName AS Агент, r.[2022-02-10_org_id_value_l] AS [№ контрагента], r.[2022-02-10_CtptOrg] AS Контрагент, r.[2022-02-10_cnNumEnum] AS Договор, r.[2022-02-10_csoCnDate] AS [Дата договора], r.invNumEnumN AS [счет-фактура], d.cn_inv_date_start AS [Дата образования], r.[2022-02-10_Maturity] AS [Срок погашения 31_12_21], r.[2022-02-10_Ttl] AS [Всего сумма задолженности в рублях 31_12_21], r.[2022-02-10_Overd] AS [Просроченная задолженность в рублях 31_12_21], r.[2022-07-21_Maturity] AS [Срок погашения 30_06_22], r.[2022-07-21_Overd] AS [Просроченная задолженность в рублях 30_06_22], r.[2022-07-21_погашено] AS [Погашено просроченной задолженности с начала года в рублях 30_06_22], r.[Код стройки], r.[Код стройкиN] AS [Наименование стройки], r.[Мероприятия по погашению дебиторской задолженности] AS [Комментарий Филиала 644]
FROM (ags_Yr_DbtChangesRslt AS r LEFT JOIN ags_cstAgPn AS c ON r.[Код стройки] = c.cstapIpgPnN) LEFT JOIN ags_cn_inv_dbt AS d ON r.[2022-02-10_ciaKey] = d.cidCnInvAccntCtpt
WHERE (((r.[2022-02-10_Overd])>0) AND ((d.cn_inv_dbt_upl)=10 Or (d.cn_inv_dbt_upl) Is Null))
ORDER BY r.account_num, c.cstapOgName, r.[2022-02-10_CtptOrg], r.[2022-02-10_cnNumEnum], r.invNumEnumN;
