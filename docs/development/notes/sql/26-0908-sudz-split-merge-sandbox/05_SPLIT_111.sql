-- =============================================================================
-- Split Dbt 111 с upl 202: слоты 322/323, Value 18000+18000; 201 остаётся 36000@311.
-- Требует 04_RELAX.
-- =============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRAN;

IF NOT EXISTS (SELECT 1 FROM test_sudz_sm.invDbt WHERE idKey = 322)
BEGIN
    SET IDENTITY_INSERT test_sudz_sm.invDbt ON;
    INSERT INTO test_sudz_sm.invDbt (idKey, idInv, idNum, idNote)
    VALUES (322, 300, 2, N'111 доля CN-301-like'),
           (323, 300, 3, N'111 доля CN-302-like');
    SET IDENTITY_INSERT test_sudz_sm.invDbt OFF;
END

IF NOT EXISTS (SELECT 1 FROM test_sudz_sm.invDbtDbt WHERE iddInvDbt = 322)
    INSERT INTO test_sudz_sm.invDbtDbt (iddInv, iddDbt, iddInvDbt) VALUES (300, 111, 322);
IF NOT EXISTS (SELECT 1 FROM test_sudz_sm.invDbtDbt WHERE iddInvDbt = 323)
    INSERT INTO test_sudz_sm.invDbtDbt (iddInv, iddDbt, iddInvDbt) VALUES (300, 111, 323);

IF NOT EXISTS (SELECT 1 FROM test_sudz_sm.invDbtVar WHERE idvvKey = 422)
BEGIN
    SET IDENTITY_INSERT test_sudz_sm.invDbtVar ON;
    INSERT INTO test_sudz_sm.invDbtVar (idvvKey, idvvCnNum, idvvInvNum, idvvAccnt, idvvCn_s_org)
    VALUES (422, 301, 300, 24, 301),
           (423, 302, 300, 24, 302);
    SET IDENTITY_INSERT test_sudz_sm.invDbtVar OFF;
END

IF NOT EXISTS (SELECT 1 FROM test_sudz_sm.invDbtDbtVar WHERE iddvInvDbt = 322)
    INSERT INTO test_sudz_sm.invDbtDbtVar (iddvInvDbt, iddvInvDbtVar) VALUES (322, 422);
IF NOT EXISTS (SELECT 1 FROM test_sudz_sm.invDbtDbtVar WHERE iddvInvDbt = 323)
    INSERT INTO test_sudz_sm.invDbtDbtVar (iddvInvDbt, iddvInvDbtVar) VALUES (323, 423);

DELETE FROM test_sudz_sm.DbtValue
WHERE dvInvDbt = 311 AND dvUpl >= 202;

DECLARE @u int;
SET @u = 202;
WHILE @u <= 210
BEGIN
    INSERT INTO test_sudz_sm.DbtValue (dvInvDbt, dvInvDbtVar, dvUpl, dvTtl, dvOverd, dvDocBase)
    VALUES
        (322, 422, @u, 18000, 18000, N'111-split-a'),
        (323, 423, @u, 18000, 18000, N'111-split-b');
    SET @u = @u + 1;
END

COMMIT TRAN;

INSERT INTO test_sudz_sm.lab_event (evScript, evOk, evMsg)
VALUES (N'05_SPLIT_111', 1, N'111: upl201=36000@311; 202–210 = 2×18000');
GO
