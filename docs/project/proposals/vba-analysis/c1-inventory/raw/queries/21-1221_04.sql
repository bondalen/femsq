-- Access QueryDef: 21-1221_04
-- Type: 0

SELECT [21-1221_03].AccntNum, [21-1221_03].CtptNum, [21-1221_03].CnNum, [21-1221_03].CnDate, [21-1221_03].CnInvNum, ags_cnInvAccntFishing.ciaKey, IIf(IsNull([CnDate]),#1/1/1900#,[CnDate]) AS cnDateNull, IIf(IsNull([CnInvNum]),"NullИлиПусто",IIf([CnInvNum]="","NullИлиПусто",[CnInvNum])) AS cnInvNull
FROM [21-1221_03] LEFT JOIN ags_cnInvAccntFishing ON ([21-1221_03].cnInvNumNull = ags_cnInvAccntFishing.ciNumNull) AND ([21-1221_03].cnDateFishing = ags_cnInvAccntFishing.CnDateFishing) AND ([21-1221_03].CnNum = ags_cnInvAccntFishing.cn_number) AND ([21-1221_03].CtptNum = ags_cnInvAccntFishing.org_id_value_l) AND ([21-1221_03].AccntNum = ags_cnInvAccntFishing.account_num);
