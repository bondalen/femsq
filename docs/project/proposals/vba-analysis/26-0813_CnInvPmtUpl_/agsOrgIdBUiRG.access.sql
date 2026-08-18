-- Access QueryDef: agsOrgIdBUiRG
-- Коды БУиРГ: ags_org_id WHERE org_id_type = 1.
-- Linked-таблица Access ags_org_id = ags.org_id (FishEye).
-- org_id_type=1 — код БУиРГ (org_id_value_l); type=2 — ИНН.
-- Потребитель: cipuCtpt_All_OId (INNER JOIN ON CntrPrtNum = org_id_value_l).
-- Следствие шага 1: org_id_key в ags.org_id NOT NULL, JOIN внутренний →
-- cipuCtpt_All_OIdNot (WHERE org_id_key is null) структурно пуст.
-- Аналог долгов ciduCtptNot использует LEFT JOIN к тому же срезу type=1.
-- Снято 2026-08-17 (режим SQL).

SELECT a.org_id_value_l, a.org_id_key
FROM ags_org_id AS a
WHERE (((a.org_id_type)=1));
