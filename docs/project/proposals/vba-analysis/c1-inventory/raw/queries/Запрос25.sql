-- Access QueryDef: Запрос25
-- Type: 0

SELECT Right([cstapIpgPnN],6) AS ipCode
FROM ags_cstAgPn
GROUP BY Right([cstapIpgPnN],6);
