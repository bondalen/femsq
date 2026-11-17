-- Access QueryDef: Запрос41
-- Type: 0

SELECT CStr(Left(iNote,100)) AS iNote100, ags_inv.iKey, *
FROM ags_inv
WHERE (((ags_inv.iKey)>107820));
