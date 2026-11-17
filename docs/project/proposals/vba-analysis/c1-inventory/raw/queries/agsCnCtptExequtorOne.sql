-- Access QueryDef: agsCnCtptExequtorOne
-- Type: 0

SELECT q.cn_key, q.org_id_value_l, e.cn_s_org_key
FROM (SELECT e.cn_key, e.org_id_value_l, Count(e.cn_s_org_key) AS [Count-cn_s_org_key] FROM agsCnCtptExequtor AS e GROUP BY e.cn_key, e.org_id_value_l, e.org_id_value_l HAVING (((Count(e.cn_s_org_key))=1) AND ((e.org_id_value_l) Is Not Null)))  AS q INNER JOIN agsCnCtptExequtor AS e ON (q.org_id_value_l = e.org_id_value_l) AND (q.cn_key = e.cn_key);
