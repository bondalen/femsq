/*
 * M2 — Dbt 1:1 на слот, invDbtDbt, затем L001–L010 merge (один Dbt на пару)
 * dbtNote: S73-* с энтропийных слотов; Rslt-Lnnn на якоре после merge
 * lastUpdated: 2026-08-27
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF EXISTS (SELECT 1 FROM sudz.Dbt)
BEGIN
    RAISERROR(N'sudz.Dbt not empty — run 02_CLEAR first', 16, 1);
    RETURN;
END
GO

BEGIN TRANSACTION;

/* 1) Dbt 1:1 — порядок = idKey слота для детерминизма */
INSERT INTO sudz.Dbt (dbtNote, dbtTimeOfEntry)
SELECT
    CASE
        WHEN d.idNote IN (N'S73-split', N'S73-quarter') THEN d.idNote
        ELSE NULL
    END,
    GETDATE()
FROM sudz.invDbt AS d
ORDER BY d.idKey;

/* 2) invDbtDbt: слот i ↔ Dbt i (одинаковый порядковый номер после RESEED) */
;WITH slots AS (
    SELECT idKey, idInv, ROW_NUMBER() OVER (ORDER BY idKey) AS rn
    FROM sudz.invDbt
),
dbts AS (
    SELECT dbtKey, ROW_NUMBER() OVER (ORDER BY dbtKey) AS rn
    FROM sudz.Dbt
)
INSERT INTO sudz.invDbtDbt (iddInv, iddDbt, iddInvDbt, iddTimeOfEntry)
SELECT s.idInv, b.dbtKey, s.idKey, GETDATE()
FROM slots AS s
INNER JOIN dbts AS b ON b.rn = s.rn;

/* 3) L* merge: правый слот → Dbt левого; удалить осиротевший Dbt */
DECLARE @L TABLE (
    lid nvarchar(8) NOT NULL,
    leftInv int NOT NULL,
    leftNum tinyint NOT NULL,
    rightInv int NOT NULL,
    rightNum tinyint NOT NULL
);
INSERT INTO @L (lid, leftInv, leftNum, rightInv, rightNum) VALUES
 (N'L001', 12032, 3, 20505, 0),
 (N'L002', 12032, 4, 20504, 0),
 (N'L003', 12032, 5, 20503, 0),
 (N'L004', 12032, 6, 20502, 0),
 (N'L005', 12032, 7, 20501, 0),
 (N'L006', 12032, 8, 20500, 0),
 (N'L007', 12033, 2, 19691, 0),
 (N'L008', 12033, 3, 19690, 0),
 (N'L009', 12033, 4, 19689, 0),
 (N'L010', 12033, 5, 19688, 0);

DECLARE @orphans TABLE (dbtKey int PRIMARY KEY);

;WITH pair AS (
    SELECT
        L.lid,
        leftSlot.idKey AS leftIdKey,
        leftBr.iddDbt AS leftDbt,
        rightSlot.idKey AS rightIdKey,
        rightBr.iddDbt AS rightDbt
    FROM @L AS L
    INNER JOIN sudz.invDbt AS leftSlot
        ON leftSlot.idInv = L.leftInv AND leftSlot.idNum = L.leftNum
    INNER JOIN sudz.invDbt AS rightSlot
        ON rightSlot.idInv = L.rightInv AND rightSlot.idNum = L.rightNum
    INNER JOIN sudz.invDbtDbt AS leftBr ON leftBr.iddInvDbt = leftSlot.idKey
    INNER JOIN sudz.invDbtDbt AS rightBr ON rightBr.iddInvDbt = rightSlot.idKey
)
UPDATE br
SET br.iddDbt = p.leftDbt
OUTPUT deleted.iddDbt INTO @orphans(dbtKey)
FROM sudz.invDbtDbt AS br
INNER JOIN pair AS p ON br.iddInvDbt = p.rightIdKey
WHERE br.iddDbt <> p.leftDbt;

UPDATE d
SET d.dbtNote = CONCAT(N'Rslt-', p.lid)
FROM sudz.Dbt AS d
INNER JOIN (
    SELECT DISTINCT leftDbt AS dbtKey, lid
    FROM (
        SELECT
            L.lid,
            leftBr.iddDbt AS leftDbt
        FROM @L AS L
        INNER JOIN sudz.invDbt AS leftSlot
            ON leftSlot.idInv = L.leftInv AND leftSlot.idNum = L.leftNum
        INNER JOIN sudz.invDbtDbt AS leftBr ON leftBr.iddInvDbt = leftSlot.idKey
    ) x
) p ON p.dbtKey = d.dbtKey;

DELETE FROM sudz.Dbt
WHERE dbtKey IN (SELECT dbtKey FROM @orphans)
  AND dbtKey NOT IN (SELECT iddDbt FROM sudz.invDbtDbt);

COMMIT TRANSACTION;
GO

SELECT N'invDbt' AS t, COUNT(*) AS n FROM sudz.invDbt
UNION ALL SELECT N'Dbt', COUNT(*) FROM sudz.Dbt
UNION ALL SELECT N'invDbtDbt', COUNT(*) FROM sudz.invDbtDbt
UNION ALL SELECT N'L_notes', COUNT(*) FROM sudz.Dbt WHERE dbtNote LIKE N'Rslt-L%';
GO
