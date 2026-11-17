-- Access QueryDef: Запрос30
-- Type: 0

SELECT ags_cstAgPn.cstapKey AS cstapKey30, Right([cstapIpgPnN],4) AS cst30, Mid([cstapIpgPnN],5,3) AS cstType30, Left([cstapIpgPnN],3) AS ag30, ags_cstAgPn.cstapCsta AS cstapCsta30, ags_cstAgPn.cstapIpgPnN AS cstapIpgPnN30, ags_cstAgPn.cstapCstName
FROM ags_cstAgPn;
