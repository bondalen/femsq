-- Access QueryDef: cipuCtpt_All_OId
-- Родитель шага 1 btnUpload: контрагенты Excel ⋈ код БУиРГ.
-- INNER JOIN cipuCtpt_All ↔ agsOrgIdBUiRG ON CntrPrtNum = org_id_value_l.
-- agsOrgIdBUiRG — QueryDef Access: SELECT org_id_value_l, org_id_key
-- FROM ags_org_id WHERE org_id_type = 1 (см. agsOrgIdBUiRG.access.sql).
-- Потребитель: cipuCtpt_All_OIdNot (WHERE org_id_key is null).
-- Источник: cipuCtpt_All (UNION контрагент ∪ агент из CnInvPmtUplTbl).
-- Наблюдение: JOIN внутренний, org_id_key NOT NULL → OIdNot структурно пуст
-- (в отличие от dbt ciduCtptNot = LEFT JOIN).
-- Снято 2026-08-17 (режим SQL; Nav-фильтр cipuCtpt_All_OId: два объекта — OId и OidNot).

SELECT c.CntrPrtNum, c.CntrPrtName, d.org_id_key
FROM cipuCtpt_All AS c INNER JOIN agsOrgIdBUiRG AS d ON c.CntrPrtNum = d.org_id_value_l
ORDER BY c.CntrPrtNum;
