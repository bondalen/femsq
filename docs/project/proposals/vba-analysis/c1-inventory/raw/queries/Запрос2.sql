-- Access QueryDef: Запрос2
-- Type: 128

SELECT 
o.ipgSh, o.ogNm, o.lim, o.ag_lim, o.ag_Ful_OverFul, o.ag_LimPc, o.ag_PlOverLimit_, o.iv_lim, o.uk_lim, o.ag_PlAccum, o.ag_PlFulfillment, o.ag_PlPz, o.ag_PlOverFulfillment, o.ag_PlPercent, o.ag_Pl_M, o.ag_acceptedTtl_M, o.ag_PlPz_M, o.mn, o.PrM_ag_PlAccum, o.PrM_ag_PlFulfillment, o.PrM_ag_PlPz, o.PrM_ag_PlOverFulfillment, o.PrM_ag_PlPercent, o.PrM_ag_Pl_M, o.PrM_ag_acceptedTtl_M, o.PrM_ag_PlPz_M, o.PrM_mnPrevious, o.cstAgPnCode
FROM [Справка_22-11_Осв] AS o
WHERE (((o.cstAgPnCode)="всего"))
UNION select 
"агентская_", "Заказчики", null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null 
from (select top 1 ipgKey from ags_ipg)
ORDER BY o.ipgSh, o.lim DESC;
