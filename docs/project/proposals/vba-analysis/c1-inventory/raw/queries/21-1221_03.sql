-- Access QueryDef: 21-1221_03
-- Type: 0

SELECT a.AccntNum AS Выражение1, a.CtptNum AS Выражение2, a.CnNum AS Выражение3, a.CnDate AS Выражение4, a.CnInvNum AS Выражение5, IIf(IsNull([CnDate]),#1/1/1900#,[CnDate]) AS cnDateFishing, IIf(IsNull([CnInvNum]),"NullИлиПусто",IIf([CnInvNum]="","NullИлиПусто",[CnInvNum])) AS cnInvNumNull
FROM (SELECT r.[Счет Главной книги] AS AccntNum, r.[№ контрагента] AS CtptNum, r.Договор AS CnNum, r.[Дата договора] AS CnDate, r.[Реквизиты документа основания (счет-фактура, N и дата первичного] AS CnInvNum FROM [Работа с ДЗ в 2021 году] AS r GROUP BY r.[Счет Главной книги], r.[№ контрагента], r.Договор, r.[Дата договора], r.[Реквизиты документа основания (счет-фактура, N и дата первичного])  AS a;
