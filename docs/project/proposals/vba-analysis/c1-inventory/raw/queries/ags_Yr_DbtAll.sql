-- Access QueryDef: ags_Yr_DbtAll
-- Type: 0

SELECT ags_Yr_Dbt.*, ags_Yr_DbtCmmT.*, ags_Yr_DbtAgT.*, ags_Yr_DbtCstT.*, ags_Yr_DbtDtT.*
FROM (((ags_Yr_Dbt LEFT JOIN ags_Yr_DbtCmmT ON ags_Yr_Dbt.dsCia = ags_Yr_DbtCmmT.cnicInvAccnt) LEFT JOIN ags_Yr_DbtAgT ON ags_Yr_Dbt.dsCia = ags_Yr_DbtAgT.cicaInvAccnt) LEFT JOIN ags_Yr_DbtCstT ON ags_Yr_Dbt.dsCia = ags_Yr_DbtCstT.ciccInvAccnt) LEFT JOIN ags_Yr_DbtDtT ON ags_Yr_Dbt.dsCia = ags_Yr_DbtDtT.cnicdInvAccnt;
