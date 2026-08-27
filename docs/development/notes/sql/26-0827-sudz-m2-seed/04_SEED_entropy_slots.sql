/*
 * M2 — энтропия D5: доп. слоты для 9 сплитов + 4480 (→ N≈11907)
 * idNum=254 S73-split; idNum=253 S73-quarter
 * lastUpdated: 2026-08-27
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @splits TABLE (iKey int PRIMARY KEY, note nvarchar(32));
INSERT INTO @splits (iKey, note) VALUES
 (336, N'S73-split'), (4786, N'S73-split'), (6766, N'S73-split'),
 (6770, N'S73-split'), (6776, N'S73-split'), (6798, N'S73-split'),
 (6801, N'S73-split'), (6812, N'S73-split'), (6814, N'S73-split'),
 (4480, N'S73-quarter');

INSERT INTO sudz.invDbt (idInv, idNum, idNote, idTimeOfEntry)
SELECT
    s.iKey,
    CASE WHEN s.note = N'S73-quarter' THEN CAST(253 AS tinyint) ELSE CAST(254 AS tinyint) END,
    s.note,
    GETDATE()
FROM @splits AS s
WHERE NOT EXISTS (
    SELECT 1 FROM sudz.invDbt d
    WHERE d.idInv = s.iKey
      AND d.idNum = CASE WHEN s.note = N'S73-quarter' THEN 253 ELSE 254 END
);

DECLARE @n int = (SELECT COUNT(*) FROM sudz.invDbt);
PRINT CONCAT(N'invDbt after entropy: ', @n);
IF @n <> 11907
    RAISERROR(N'Expected 11907 slots after entropy, got %d', 16, 1, @n);
GO
