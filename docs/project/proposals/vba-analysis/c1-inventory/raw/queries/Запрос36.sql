-- Access QueryDef: Запрос36
-- Type: 64

INSERT INTO ags_cstAgPnMnrl ( amCstAgPn, amPositing, amType, amBranch, amSum )
SELECT ags_cstAgPn.cstapKey, Запрос35.amPositing, Запрос35.amType, ags_ogNmF_allVariantsNoRepeat.ogKey, Запрос35.[Sum-amSum]
FROM (Запрос35 LEFT JOIN ags_cstAgPn ON Запрос35.cst = ags_cstAgPn.cstapIpgPnN) LEFT JOIN ags_ogNmF_allVariantsNoRepeat ON Запрос35.amBranch = ags_ogNmF_allVariantsNoRepeat.ogNm255;
