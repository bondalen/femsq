-- Access QueryDef: cipuCn_Ctpt
-- Пары (контрагент Excel + № договора + org_id_key) для шага 3.
-- Источник: CnInvPmtUplTbl (только ciputCntrPrt*, не агенты).
-- LEFT JOIN cipuCtpt_All_OIdNot WHERE b.CntrPrtNum Is Null — задумано как
-- «контрагенты, которых нет в списке без org_id» (= уже есть БУиРГ).
-- Следствие вопроса 8: OIdNot структурно пуст → этот анти-join никого не отсекает.
-- LEFT JOIN agsOrgIdBUiRG даёт org_id_key (может быть Null, если кода БУиРГ нет).
-- CnName: пустой/Null → «NullИлиПусто»; cipuCn_CtptCnNot нормализует имя ещё раз.
-- GROUP BY по сырому ciputCnName — стиль конструктора Access.
-- Потребитель: cipuCn_CtptCnNot.
-- Снято 2026-08-17 (режим SQL; Nav-фильтр cipuCn_Ctpt).
-- На том же Nav таблицы буфера: cipuCn_CtptCnOneInvOneAcDcExtPmTbl (+ Old) —
-- имя совпадает с VBA (ExtPmTbl), не ExtPmtTbl.

SELECT a.ciputCntrPrtNum AS CntrPrtNum, a.ciputCntrPrtName AS CntrPrtName, IIf(IsNull([a].[ciputCnName]),"NullИлиПусто",IIf([a].[ciputCnName]="","NullИлиПусто",[a].[ciputCnName])) AS CnName, agsOrgIdBUiRG.org_id_key
FROM (CnInvPmtUplTbl AS a LEFT JOIN cipuCtpt_All_OIdNot AS b ON a.ciputCntrPrtNum = b.CntrPrtNum) LEFT JOIN agsOrgIdBUiRG ON a.ciputCntrPrtNum = agsOrgIdBUiRG.org_id_value_l
WHERE (((b.CntrPrtNum) Is Null))
GROUP BY a.ciputCntrPrtNum, a.ciputCntrPrtName, agsOrgIdBUiRG.org_id_key, a.ciputCnName;
