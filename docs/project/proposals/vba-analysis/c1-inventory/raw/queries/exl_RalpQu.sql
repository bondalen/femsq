-- Access QueryDef: exl_RalpQu
-- Type: 0

SELECT exl_Ralp.[Поступило в Ф644], exl_Ralp.[№ отчета] AS ralpNum, [Дата] AS ralpDate, exl_Ralp.[Принято затрат, руб#] AS ralpCostAndVat, exl_Ralp.[Письмо Агента о направлении отчетов] AS ralpArrived, exl_Ralp.[Письмо Ф644 о замечаниях] AS ralpReturned, exl_Ralp.[СЗ о направлении отчета в Службу бухгалтерского учета Филиала 64] AS ralpSent, exl_Ralp.[Ответ ДО на замечании, направленные к ОА] AS ralpRespons, exl_Ralp.[КОММЕНТАРИЙ_(предварительно)] AS ralpNote, exl_Ralp.[Код проекта], ags_cstAgPn.cstapIpgPnN, ags_cstAgPn.cstapKey
FROM exl_Ralp LEFT JOIN ags_cstAgPn ON exl_Ralp.[Код проекта] = ags_cstAgPn.cstapIpgPnN
WHERE (((exl_Ralp.[Поступило в Ф644])=1));
