-- Access QueryDef: 25-1030_polikarpov_2_q_9
-- Type: 0

SELECT q_7.lim, q_7.ag_lim, q_7.iv_lim, q_7.ddd, Switch([ddd]<0.1,10,[ddd]<0.2,20,[ddd]<0.3,30,[ddd]<0.4,40,[ddd]<0.5,50,[ddd]<0.6,60,[ddd]<0.7,70,[ddd]<0.8,80,[ddd]<0.9,90,[ddd]<=1,100,[ddd]>1,999) AS iii
FROM [25-1030_polikarpov_2_q_7] AS q_7;
