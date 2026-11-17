-- Access QueryDef: agsCnCtptAgent
-- Type: 0

SELECT c.cn_key, IIf(IsNull([c].[cn_number]),"NullИлиПусто",IIf([c].[cn_number]="","NullИлиПусто",Trim([c].[cn_number]))) AS cn_number, ags_cn_s.cn_s_key, ags_cn_s.cn_s_type, ags_cn_s_org.cn_s_org_key, ags_cn_s_org.org_id, c.cn_date, ags_org_id.org_id_type, ags_cn_s_org.date_beg, ags_cn_s_org.date_end, ags_cn_s_org.csoAsbuID, ags_cn_s_org.csoCnDate, ags_org_id.org_id_value_l, ags_og.ogNm
FROM ags_og INNER JOIN (((ags_cn AS c INNER JOIN ags_cn_s ON c.cn_key = ags_cn_s.cn_key) INNER JOIN ags_cn_s_org ON ags_cn_s.cn_s_key = ags_cn_s_org.cn_s_key) INNER JOIN ags_org_id ON ags_cn_s_org.org_id = ags_org_id.org_id_key) ON ags_og.ogKey = ags_org_id.org
WHERE (((ags_cn_s.cn_s_type)=1) AND ((ags_org_id.org_id_type)=1));
