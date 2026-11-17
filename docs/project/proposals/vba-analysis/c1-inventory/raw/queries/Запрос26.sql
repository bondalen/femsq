-- Access QueryDef: Запрос26
-- Type: 0

SELECT Запрос24.cacOrNull, Запрос24.sh, Запрос25.ipCode, tblPIR.pirIDnew, tblPIR.pirName
FROM (Запрос24 LEFT JOIN Запрос25 ON Запрос24.sh = Запрос25.ipCode) LEFT JOIN tblPIR ON Запрос24.cccD = tblPIR.pirIDnew
ORDER BY Запрос24.sh;
