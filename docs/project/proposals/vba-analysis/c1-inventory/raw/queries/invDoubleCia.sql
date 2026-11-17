-- Access QueryDef: invDoubleCia
-- Type: 0

SELECT i.iKey
FROM ((ags_cnInvAccnt AS cia INNER JOIN ags_cnInvAccntSmpl AS cias ON cia.ciaCnInvAccntSmpl = cias.ciasKey) INNER JOIN ags_cnInv AS ci ON cias.ciasCnInv = ci.ciKey) INNER JOIN ags_inv AS i ON ci.ciInv = i.iKey
WHERE (((cia.ciaName) Is Not Null))
GROUP BY i.iKey;
