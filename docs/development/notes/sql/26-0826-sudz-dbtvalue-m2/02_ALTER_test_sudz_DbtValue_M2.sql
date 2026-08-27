/*
 * B1 — ALTER test_sudz.DbtValue → M2 (зеркало sudz)
 *
 * lastUpdated: 2026-08-26
 */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF COL_LENGTH(N'test_sudz.DbtValue', N'dvInvDbt') IS NOT NULL
   AND COL_LENGTH(N'test_sudz.DbtValue', N'dvDbt') IS NULL
BEGIN
    PRINT N'test_sudz.DbtValue already M2 — skip 02.';
    RETURN;
END
GO

BEGIN TRANSACTION;

IF OBJECT_ID(N'test_sudz.trg_DbtValue_Consistency', N'TR') IS NOT NULL
    DROP TRIGGER test_sudz.trg_DbtValue_Consistency;

IF COL_LENGTH(N'test_sudz.DbtValue', N'dvInvDbt') IS NULL
    ALTER TABLE test_sudz.DbtValue ADD dvInvDbt int NULL;
GO

UPDATE dv
SET dv.dvInvDbt = b.iddvInvDbt
FROM test_sudz.DbtValue AS dv
INNER JOIN test_sudz.invDbtDbtVar AS b ON b.iddvInvDbtVar = dv.dvInvDbtVar;

IF EXISTS (SELECT 1 FROM test_sudz.DbtValue WHERE dvInvDbt IS NULL)
BEGIN
    RAISERROR(N'test_sudz.DbtValue: backfill dvInvDbt left NULLs — abort', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;
END

ALTER TABLE test_sudz.DbtValue ALTER COLUMN dvInvDbt int NOT NULL;

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_DbtValue_invDbt' AND parent_object_id = OBJECT_ID(N'test_sudz.DbtValue')
)
BEGIN
    ALTER TABLE test_sudz.DbtValue
        ADD CONSTRAINT FK_DbtValue_invDbt FOREIGN KEY (dvInvDbt)
            REFERENCES test_sudz.invDbt (idKey);
END

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UX_DbtValue_InvDbtUpl' AND object_id = OBJECT_ID(N'test_sudz.DbtValue')
)
BEGIN
    ALTER TABLE test_sudz.DbtValue
        ADD CONSTRAINT UX_DbtValue_InvDbtUpl UNIQUE (dvInvDbt, dvUpl);
END

IF EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_DbtValue_Dbt' AND parent_object_id = OBJECT_ID(N'test_sudz.DbtValue')
)
    ALTER TABLE test_sudz.DbtValue DROP CONSTRAINT FK_DbtValue_Dbt;

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UX_DbtValue_DbtUpl' AND object_id = OBJECT_ID(N'test_sudz.DbtValue')
)
    ALTER TABLE test_sudz.DbtValue DROP CONSTRAINT UX_DbtValue_DbtUpl;

IF COL_LENGTH(N'test_sudz.DbtValue', N'dvDbt') IS NOT NULL
    ALTER TABLE test_sudz.DbtValue DROP COLUMN dvDbt;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_DbtValue_Var' AND object_id = OBJECT_ID(N'test_sudz.DbtValue')
)
    CREATE NONCLUSTERED INDEX IX_DbtValue_Var ON test_sudz.DbtValue (dvInvDbtVar);

COMMIT TRANSACTION;
PRINT N'test_sudz.DbtValue M2 DDL done';
GO

SELECT c.name AS column_name, ty.name AS type_name, c.is_nullable
FROM sys.columns c
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'test_sudz.DbtValue')
ORDER BY c.column_id;
GO
