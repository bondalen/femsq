-- Access QueryDef: ra_period_choice
-- Type: 0

SELECT ags_ra_period.key, [ags_yyyy]![yyyy] & ", " & [ags_mmmm]![mCs] & ", " & [ags_ra_period]![p] AS name
FROM (ags_ra_period INNER JOIN ags_yyyy ON ags_ra_period.y = ags_yyyy.yKey) INNER JOIN ags_mmmm ON ags_ra_period.m = ags_mmmm.mKey
ORDER BY [ags_yyyy]![yyyy] & ", " & [ags_mmmm]![mCs] & ", " & [ags_ra_period]![p];
