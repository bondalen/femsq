-- Access QueryDef: ags_Yr_DbtCmmT
-- Type: 0

SELECT ags_Yr_DbtCmm.cnicInvAccnt, ags_cnInvCmm_1.cnicText AS УПВР, ags_cnInvCmm.cnicText AS Мероприятия, ags_cnInvCmm_2.cnicText AS ГИ, ags_cnInvCmm_3.cnicText AS Агенты, ags_cnInvCmm_4.cnicText AS Работа
FROM ((((ags_Yr_DbtCmm LEFT JOIN ags_cnInvCmm AS ags_cnInvCmm_1 ON ags_Yr_DbtCmm.[Комментарии Кураторов УПВР] = ags_cnInvCmm_1.cnicKey) LEFT JOIN ags_cnInvCmm ON ags_Yr_DbtCmm.[Мероприятия по погашению дебиторской задолженности] = ags_cnInvCmm.cnicKey) LEFT JOIN ags_cnInvCmm AS ags_cnInvCmm_2 ON ags_Yr_DbtCmm.[Отчёт Газпром инвест, ООО] = ags_cnInvCmm_2.cnicKey) LEFT JOIN ags_cnInvCmm AS ags_cnInvCmm_3 ON ags_Yr_DbtCmm.[Примечания Агентов] = ags_cnInvCmm_3.cnicKey) LEFT JOIN ags_cnInvCmm AS ags_cnInvCmm_4 ON ags_Yr_DbtCmm.[Работа с просроченной ДЗ] = ags_cnInvCmm_4.cnicKey;
