-- Access QueryDef: 24-1225_cstAgPnDB
-- Type: 0

SELECT ags_cstAgPn.cstapKey, ags_cstAgPn.cstapIpgPnN, Right([cstapIpgPnN],7) AS r7, Right([cstapIpgPnN],4) AS r4, Mid([cstapIpgPnN],5,1) AS m5, ags_cstAg.cstaKey, ags_cstAg.cstaAg, ags_cstAg.cstaCst
FROM ags_cstAgPn INNER JOIN ags_cstAg ON ags_cstAgPn.cstapCsta = ags_cstAg.cstaKey;
