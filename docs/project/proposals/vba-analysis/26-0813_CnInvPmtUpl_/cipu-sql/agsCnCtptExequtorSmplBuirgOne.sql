-- Access QueryDef: agsCnCtptExequtorSmplBuirgOne
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:58

SELECT q.cn_key, q.org_id_value_l, r.csosKey
FROM (SELECT e.cn_key, e.org_id_value_l, Count(e.csosKey) AS [Count-csosKey] FROM (SELECT cn_key, org_id_value_l, csosKey FROM agsCnCtptExequtorSmplBuirg GROUP BY cn_key, org_id_value_l, csosKey)  AS e GROUP BY e.cn_key, e.org_id_value_l HAVING (((e.org_id_value_l) Is Not Null) AND ((Count(e.csosKey))=1)))  AS q INNER JOIN agsCnCtptExequtorSmplBuirg AS r ON (q.cn_key = r.cn_key) AND (q.org_id_value_l = r.org_id_value_l)
GROUP BY q.cn_key, q.org_id_value_l, r.csosKey;
