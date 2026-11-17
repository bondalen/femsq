-- Access QueryDef: Запрос31
-- Type: 0

SELECT Запрос29.Num, Запрос29.cst, Запрос29.cstType, Запрос29.cstAg, Запрос29.CstAgPnStr, Запрос29.CstName, Запрос29.cstapKey, Запрос30.cst30, Запрос30.cstType30, Запрос30.ag30, Запрос30.cstapCsta30, Запрос30.cstapCstName
FROM Запрос29 LEFT JOIN Запрос30 ON Запрос29.cst = Запрос30.cst30
ORDER BY Запрос29.cst, Запрос29.cstType, Запрос29.cstAg;
