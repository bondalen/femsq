-- Access QueryDef: ags_PdSdRRcList
-- Type: 112

select i.org_id_key, i.org, o.ogNm from ags.org_id i left join ags.og o on i.org = o.ogKey where i.org_id_value_t = '7017005289' and i.org_id_value_t_ext = '997250001' group by i.org_id_key, i.org, o.ogNm