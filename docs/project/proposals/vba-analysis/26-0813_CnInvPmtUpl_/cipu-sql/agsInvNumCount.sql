-- Access QueryDef: agsInvNumCount
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:58

SELECT z.inNumNull, Count(z.inInv) AS inNumCount
FROM (SELECT inum.inNumNull, inum.inInv FROM ags_invNum AS inum GROUP BY inum.inNumNull, inum.inInv)  AS z
GROUP BY z.inNumNull;
