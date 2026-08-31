/*
 * VERIFY DbtSlotLink after ApplyDbtSlotLinks.
 * lastUpdated: 2026-08-31
 */
SET NOCOUNT ON;

SELECT N'groups_active' AS chk, COUNT(*) AS n
FROM sudz.DbtSlotLinkGroup WHERE dslgStatus = N'active';

SELECT N'members' AS chk, COUNT(*) AS n
FROM sudz.DbtSlotLinkMember;

SELECT g.lid, g.canonicalDbtKey, g.canonicalRule, COUNT(m.iKey) AS members
FROM sudz.DbtSlotLinkGroup AS g
LEFT JOIN sudz.DbtSlotLinkMember AS m ON m.lid = g.lid
WHERE g.dslgStatus = N'active'
GROUP BY g.lid, g.canonicalDbtKey, g.canonicalRule
ORDER BY g.lid;

SELECT N'bridge_mismatch' AS chk, COUNT(*) AS n
FROM sudz.DbtSlotLinkGroup AS g
INNER JOIN sudz.DbtSlotLinkMember AS m ON m.lid = g.lid
INNER JOIN sudz.invDbt AS s ON s.idInv = m.iKey AND s.idNum = m.idNum
INNER JOIN sudz.invDbtDbt AS b ON b.iddInvDbt = s.idKey
WHERE g.dslgStatus = N'active'
  AND b.iddDbt <> g.canonicalDbtKey;

SELECT d.dbtKey, d.dbtNote, COUNT(DISTINCT b.iddInvDbt) AS slots
FROM sudz.Dbt AS d
INNER JOIN sudz.invDbtDbt AS b ON b.iddDbt = d.dbtKey
WHERE d.dbtNote LIKE N'Rslt-L%'
GROUP BY d.dbtKey, d.dbtNote
ORDER BY d.dbtNote;

GO
