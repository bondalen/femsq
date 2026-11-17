-- Access QueryDef: agsInvNumCount
-- Type: 0

SELECT z.inNumNull, Count(z.inInv) AS inNumCount
FROM (SELECT inum.inNumNull, inum.inInv FROM ags_invNum AS inum GROUP BY inum.inNumNull, inum.inInv)  AS z
GROUP BY z.inNumNull;
