/*
 * B1 — ALTER sudz.DbtValue → M2 (S71 / S72)
 *
 * Порядок пакета:
 *   00_VERIFY_before.sql → 01 (этот) → 02_test_sudz → 03_TRIGGER → 04_VIEW → 99_VERIFY_after
 *
 * Шаги:
 *   1) DROP trigger (старый, требует dvDbt)
 *   2) ADD dvInvDbt NULL  — отдельный batch (иначе Msg 207 на UPDATE)
 *   3) backfill → NOT NULL + UNIQUE(dvInvDbt,dvUpl) + FK → invDbt
 *   4) DROP FK/UNIQUE/COLUMN dvDbt
 *
 * lastUpdated: 2026-08-26
 */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF COL_LENGTH(N'sudz.DbtValue', N'dvInvDbt') IS NOT NULL
   AND COL_LENGTH(N'sudz.DbtValue', N'dvDbt') IS NULL
BEGIN
    PRINT N'sudz.DbtValue already M2 — skip 01.';
    RETURN;
END
GO

BEGIN TRANSACTION;

IF OBJECT_ID(N'sudz.trg_DbtValue_Consistency', N'TR') IS NOT NULL
    DROP TRIGGER sudz.trg_DbtValue_Consistency;

IF COL_LENGTH(N'sudz.DbtValue', N'dvInvDbt') IS NULL
    ALTER TABLE sudz.DbtValue ADD dvInvDbt int NULL;
GO

UPDATE dv
SET dv.dvInvDbt = b.iddvInvDbt
FROM sudz.DbtValue AS dv
INNER JOIN sudz.invDbtDbtVar AS b ON b.iddvInvDbtVar = dv.dvInvDbtVar;

IF EXISTS (SELECT 1 FROM sudz.DbtValue WHERE dvInvDbt IS NULL)
BEGIN
    RAISERROR(N'sudz.DbtValue: backfill dvInvDbt left NULLs — abort', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;
END

ALTER TABLE sudz.DbtValue ALTER COLUMN dvInvDbt int NOT NULL;

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_DbtValue_invDbt' AND parent_object_id = OBJECT_ID(N'sudz.DbtValue')
)
BEGIN
    ALTER TABLE sudz.DbtValue
        ADD CONSTRAINT FK_DbtValue_invDbt FOREIGN KEY (dvInvDbt)
            REFERENCES sudz.invDbt (idKey);
END

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UX_DbtValue_InvDbtUpl' AND object_id = OBJECT_ID(N'sudz.DbtValue')
)
BEGIN
    ALTER TABLE sudz.DbtValue
        ADD CONSTRAINT UX_DbtValue_InvDbtUpl UNIQUE (dvInvDbt, dvUpl);
END

IF EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_DbtValue_Dbt' AND parent_object_id = OBJECT_ID(N'sudz.DbtValue')
)
    ALTER TABLE sudz.DbtValue DROP CONSTRAINT FK_DbtValue_Dbt;

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UX_DbtValue_DbtUpl' AND object_id = OBJECT_ID(N'sudz.DbtValue')
)
    ALTER TABLE sudz.DbtValue DROP CONSTRAINT UX_DbtValue_DbtUpl;

IF COL_LENGTH(N'sudz.DbtValue', N'dvDbt') IS NOT NULL
    ALTER TABLE sudz.DbtValue DROP COLUMN dvDbt;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_DbtValue_Var' AND object_id = OBJECT_ID(N'sudz.DbtValue')
)
    CREATE NONCLUSTERED INDEX IX_DbtValue_Var ON sudz.DbtValue (dvInvDbtVar);

COMMIT TRANSACTION;
PRINT N'sudz.DbtValue M2 DDL done — next: 02_test_sudz, 03_TRIGGER, 04_VIEW';
GO

SELECT c.name AS column_name, ty.name AS type_name, c.is_nullable
FROM sys.columns c
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'sudz.DbtValue')
ORDER BY c.column_id;
GO
