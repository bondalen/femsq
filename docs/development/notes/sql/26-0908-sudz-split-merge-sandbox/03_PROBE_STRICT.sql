-- =============================================================================
-- Зонды режима strict: ожидаемые ОТКАЗЫ (модель 111 и 2×18000).
-- Каждый зонд — своя транзакция; результат в lab_event.
-- =============================================================================

SET NOCOUNT ON;

/* A: второй слот того же Dbt на том же inv */
BEGIN TRY
    BEGIN TRAN;
    SET IDENTITY_INSERT test_sudz_sm.invDbt ON;
    INSERT INTO test_sudz_sm.invDbt (idKey, idInv, idNum, idNote)
    VALUES (322, 300, 2, N'probe A');
    SET IDENTITY_INSERT test_sudz_sm.invDbt OFF;
    INSERT INTO test_sudz_sm.invDbtDbt (iddInv, iddDbt, iddInvDbt)
    VALUES (300, 111, 322);
    COMMIT TRAN;
    INSERT INTO test_sudz_sm.lab_event (evScript, evOk, evMsg)
    VALUES (N'03A_second_slot_same_inv', 1, N'UNEXPECTED success');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    INSERT INTO test_sudz_sm.lab_event (evScript, evOk, evMsg)
    VALUES (N'03A_second_slot_same_inv', 0, LEFT(ERROR_MESSAGE(), 500));
    SET IDENTITY_INSERT test_sudz_sm.invDbt OFF;
    DELETE FROM test_sudz_sm.invDbt WHERE idKey = 322;
END CATCH
GO

/* B: два sibling Value 18000 без общего Dbt — сначала слот+var без моста к 111 */
BEGIN TRY
    BEGIN TRAN;
    IF NOT EXISTS (SELECT 1 FROM test_sudz_sm.invDbt WHERE idKey = 322)
    BEGIN
        SET IDENTITY_INSERT test_sudz_sm.invDbt ON;
        INSERT INTO test_sudz_sm.invDbt (idKey, idInv, idNum, idNote)
        VALUES (322, 300, 2, N'probe B slot');
        SET IDENTITY_INSERT test_sudz_sm.invDbt OFF;
    END
    IF NOT EXISTS (SELECT 1 FROM test_sudz_sm.invDbtVar WHERE idvvKey = 422)
    BEGIN
        SET IDENTITY_INSERT test_sudz_sm.invDbtVar ON;
        INSERT INTO test_sudz_sm.invDbtVar (idvvKey, idvvCnNum, idvvInvNum, idvvAccnt, idvvCn_s_org)
        VALUES (422, 301, 300, 24, 301);
        SET IDENTITY_INSERT test_sudz_sm.invDbtVar OFF;
    END
    IF NOT EXISTS (
        SELECT 1 FROM test_sudz_sm.invDbtDbtVar
        WHERE iddvInvDbt = 322 AND iddvInvDbtVar = 422
    )
        INSERT INTO test_sudz_sm.invDbtDbtVar (iddvInvDbt, iddvInvDbtVar) VALUES (322, 422);

    /* Value 18000 на 322 @202 рядом с 36000 на 311 — разные ttl, п.4 молчит */
    INSERT INTO test_sudz_sm.DbtValue (dvInvDbt, dvInvDbtVar, dvUpl, dvTtl, dvOverd, dvDocBase)
    VALUES (322, 422, 202, 18000, 18000, N'probe B half');
    COMMIT TRAN;
    INSERT INTO test_sudz_sm.lab_event (evScript, evOk, evMsg)
    VALUES (N'03B_half_on_sibling_diff_ttl', 1, N'18000 рядом с 36000 на другом слоте — ttl разный, п.4 не бьёт');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    INSERT INTO test_sudz_sm.lab_event (evScript, evOk, evMsg)
    VALUES (N'03B_half_on_sibling_diff_ttl', 0, LEFT(ERROR_MESSAGE(), 500));
END CATCH
GO

/* C: вторая половина 18000 на слоте 323 — same ttl sibling */
BEGIN TRY
    BEGIN TRAN;
    SET IDENTITY_INSERT test_sudz_sm.invDbt ON;
    INSERT INTO test_sudz_sm.invDbt (idKey, idInv, idNum, idNote)
    VALUES (323, 300, 3, N'probe C');
    SET IDENTITY_INSERT test_sudz_sm.invDbt OFF;
    SET IDENTITY_INSERT test_sudz_sm.invDbtVar ON;
    INSERT INTO test_sudz_sm.invDbtVar (idvvKey, idvvCnNum, idvvInvNum, idvvAccnt, idvvCn_s_org)
    VALUES (423, 302, 300, 24, 302);
    SET IDENTITY_INSERT test_sudz_sm.invDbtVar OFF;
    INSERT INTO test_sudz_sm.invDbtDbtVar (iddvInvDbt, iddvInvDbtVar) VALUES (323, 423);
    INSERT INTO test_sudz_sm.DbtValue (dvInvDbt, dvInvDbtVar, dvUpl, dvTtl, dvOverd, dvDocBase)
    VALUES (323, 423, 202, 18000, 18000, N'probe C');
    COMMIT TRAN;
    INSERT INTO test_sudz_sm.lab_event (evScript, evOk, evMsg)
    VALUES (N'03C_second_18000_same_ttl', 1, N'UNEXPECTED success');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    INSERT INTO test_sudz_sm.lab_event (evScript, evOk, evMsg)
    VALUES (N'03C_second_18000_same_ttl', 0, LEFT(ERROR_MESSAGE(), 500));
END CATCH
GO

/* подчистить хвосты зонда B/C, оставить базу 02 */
DELETE FROM test_sudz_sm.DbtValue WHERE dvDocBase LIKE N'probe%';
DELETE FROM test_sudz_sm.invDbtDbtVar WHERE iddvInvDbt IN (322, 323);
DELETE FROM test_sudz_sm.invDbtDbt WHERE iddInvDbt IN (322, 323);
DELETE FROM test_sudz_sm.invDbtVar WHERE idvvKey IN (422, 423);
DELETE FROM test_sudz_sm.invDbt WHERE idKey IN (322, 323);
GO
