-- =============================================================================
-- Merge 113 → 112 с upl 206: слот 402 (inv 302) переписывает iddDbt.
-- История Value 113 остаётся на слоте; канон становится 112.
-- Dbt 113 не удаляем (как живой trg_Dbt_NoDeleteIfCanonical — оставляем «осиротевшим»).
-- =============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRAN;

UPDATE test_sudz_sm.invDbtDbt
SET iddDbt = 112
WHERE iddDbt = 113 AND iddInvDbt = 402;

COMMIT TRAN;

INSERT INTO test_sudz_sm.lab_event (evScript, evOk, evMsg)
VALUES (
    N'06_MERGE_113_into_112',
    1,
    N'iddDbt слота 402: 113→112; на срезах у 112 теперь две Value (разные inv)'
);
GO
