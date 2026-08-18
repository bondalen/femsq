-- Access QueryDef: cipuCtpt_All_OIdNot
-- Шаг 1 btnUpload: контрагенты Excel без org_id (код БУиРГ не найден в БД).
-- Имя объекта: VBA / QueryDef = cipuCtpt_All_OIdNot; Nav может показать OidNot
-- (Access не различает регистр идентификаторов). Это OId = org_id, НЕ суффикс Old.
-- Источник: cipuCtpt_All_OId (INNER JOIN cipuCtpt_All ↔ agsOrgIdBUiRG).
-- VBA OpenRecordset этого QueryDef, только лог.
-- Родитель INNER JOIN + agsOrgIdBUiRG (org_id type=1, key NOT NULL) →
-- этот WHERE структурно пуст. Аналог dbt ciduCtptNot = LEFT JOIN.
-- Снято 2026-08-17 (режим SQL; фильтр Nav cipuCtpt_All_OidNot — один объект).

SELECT CntrPrtNum, CntrPrtName, org_id_key
FROM cipuCtpt_All_OId
WHERE org_id_key is null
ORDER BY CntrPrtNum;
