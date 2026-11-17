-- Access QueryDef: 25-1030_polikarpov_2_q_7
-- Type: 0

SELECT [25-1029_polikarpov_2_q_3].ag_lim, [25-1029_polikarpov_2_q_3].iv_lim, IIf([ag_lim] Is Null,0,[ag_lim])+IIf([iv_lim] Is Null,0,[iv_lim]) AS lim, [25-1029_polikarpov_2_q_3].uk_lim, [25-1029_polikarpov_2_q_3].cstAgPn, [25-1029_polikarpov_2_q_3].pl_01_10, [25-1029_polikarpov_2_q_3].iuplpM10AccumD, [25-1029_polikarpov_2_q_3].iuplpM11AccumD, [25-1029_polikarpov_2_q_3].iuplpM12AccumD, IIf([pl_01_10] Is Null Or [pl_01_10]=0 Or [iuplpM10AccumD] Is Null Or [iuplpM10AccumD]=0,Null,Abs([pl_01_10]-[iuplpM10AccumD])/[pl_01_10]) AS ddd
FROM [25-1029_polikarpov_2_q_3]
WHERE ((([25-1029_polikarpov_2_q_3].lim) Is Not Null) AND (([25-1029_polikarpov_2_q_3].ipgpSmTtl) Is Not Null));
