-- Access QueryDef: cipuCtpt_All
-- Уникальные пары (номер, имя) из staging CnInvPmtUplTbl:
--   1) контрагент ciputCntrPrtNum / ciputCntrPrtName
--   2) агент     ciputAgentNum    / ciputAgentName
-- UNION (не UNION ALL) = без дублей; обёртки a/b — стиль конструктора Access.
-- Внешний WHERE отсекает Null номера и имени.
-- Потребитель: cipuCtpt_All_OId (INNER JOIN agsOrgIdBUiRG).
-- Следствие шага 1: лог «новые организации» смотрит и контрагентов, и агентов.
-- Nav, фильтр cipuCtpt_All (2026-08-17): видны All, All_Old (legacy), All_OidNot;
-- All_OId подтверждён отдельным съёмом — это не All_Old.
-- Снято 2026-08-17 (режим SQL).

SELECT CntrPrtNum, CntrPrtName
FROM (SELECT ciputCntrPrtNum AS CntrPrtNum, ciputCntrPrtName AS CntrPrtName FROM (SELECT ciputCntrPrtNum, ciputCntrPrtName FROM CnInvPmtUplTbl GROUP BY ciputCntrPrtNum, ciputCntrPrtName union SELECT ciputAgentNum, ciputAgentName FROM CnInvPmtUplTbl GROUP BY ciputAgentNum, ciputAgentName )  AS a)  AS b
WHERE CntrPrtNum is not null and CntrPrtName is not null;
