/*
 * Seed L001–L010 (pending groups + equal members). ApplyDbtSlotLinks sets canonicalDbtKey.
 * lastUpdated: 2026-08-31
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;

MERGE sudz.DbtSlotLinkGroup AS t
USING (
    VALUES
        (N'L001', CAST(9527.42 AS decimal(19, 4)), N'32-425/05-18', N'26-0212 / 26-0505'),
        (N'L002', CAST(286438.32 AS decimal(19, 4)), N'32-425/05-18', N'26-0212 / 26-0505'),
        (N'L003', CAST(413717.39 AS decimal(19, 4)), N'32-425/05-18', N'26-0212 / 26-0505'),
        (N'L004', CAST(81204874.08 AS decimal(19, 4)), N'32-425/05-18', N'26-0212 / 26-0505'),
        (N'L005', CAST(21811226.52 AS decimal(19, 4)), N'32-425/05-18', N'26-0212 / 26-0505'),
        (N'L006', CAST(186961.48 AS decimal(19, 4)), N'32-425/05-18', N'26-0212 / 26-0505'),
        (N'L007', CAST(9970.81 AS decimal(19, 4)), N'32-426/05-18', N'26-0212 / 26-0505'),
        (N'L008', CAST(31686529.60 AS decimal(19, 4)), N'32-426/05-18', N'26-0212 / 26-0505'),
        (N'L009', CAST(41904384.49 AS decimal(19, 4)), N'32-426/05-18', N'26-0212 / 26-0505'),
        (N'L010', CAST(355581.67 AS decimal(19, 4)), N'32-426/05-18', N'26-0212 / 26-0505')
) AS s (lid, matchSum, cnContract, sourceRslt)
ON t.lid = s.lid
WHEN NOT MATCHED THEN
    INSERT (lid, dslgStatus, matchSum, sourceRslt, note)
    VALUES (s.lid, N'pending', s.matchSum, s.sourceRslt, s.cnContract)
WHEN MATCHED AND t.dslgStatus = N'superseded' THEN
    UPDATE SET
        dslgStatus = N'pending',
        matchSum = s.matchSum,
        sourceRslt = s.sourceRslt,
        note = s.cnContract,
        canonicalDbtKey = NULL,
        canonicalRule = NULL,
        canonicalSetAt = NULL;

DELETE FROM sudz.DbtSlotLinkMember
WHERE lid IN (N'L001', N'L002', N'L003', N'L004', N'L005', N'L006', N'L007', N'L008', N'L009', N'L010');

INSERT INTO sudz.DbtSlotLinkMember (lid, iKey, idNum) VALUES
 (N'L001', 12032, 3), (N'L001', 20505, 0),
 (N'L002', 12032, 4), (N'L002', 20504, 0),
 (N'L003', 12032, 5), (N'L003', 20503, 0),
 (N'L004', 12032, 6), (N'L004', 20502, 0),
 (N'L005', 12032, 7), (N'L005', 20501, 0),
 (N'L006', 12032, 8), (N'L006', 20500, 0),
 (N'L007', 12033, 2), (N'L007', 19691, 0),
 (N'L008', 12033, 3), (N'L008', 19690, 0),
 (N'L009', 12033, 4), (N'L009', 19689, 0),
 (N'L010', 12033, 5), (N'L010', 19688, 0);

COMMIT TRANSACTION;
GO

SELECT g.lid, g.dslgStatus, COUNT(m.lid) AS members
FROM sudz.DbtSlotLinkGroup AS g
LEFT JOIN sudz.DbtSlotLinkMember AS m ON m.lid = g.lid
WHERE g.lid LIKE N'L%'
GROUP BY g.lid, g.dslgStatus
ORDER BY g.lid;
GO
