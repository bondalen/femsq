-- Access QueryDef: ИмпортРабота_с_ДЗ_220303_insert
-- Type: 0

SELECT a.account, a.cnNum, a.cnDateNull, a.CtptNum, a.InvNum, ags_cnInvAccntFishing.ciaKey, 3 AS gr, 8 AS type, a.comment, "УпрПИР" AS cm
FROM (SELECT i.account, i.cnNum, IIf(IsNull([cnDate]),#1/1/1900#,[cnDate]) AS cnDateNull, i.CtptNum, i.InvNum, i.comment FROM ИмпортРабота_с_ДЗ_220303 AS i)  AS a LEFT JOIN ags_cnInvAccntFishing ON (a.CtptNum = ags_cnInvAccntFishing.org_id_value_l) AND (a.InvNum = ags_cnInvAccntFishing.inNumNull) AND (a.cnDateNull = ags_cnInvAccntFishing.cnDate) AND (a.cnNum = ags_cnInvAccntFishing.cnnNumNull) AND (a.account = ags_cnInvAccntFishing.account_num);
