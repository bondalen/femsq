-- =============================================================================
-- sudz.invDbtDbtVar — мост invDbt ↔ invDbtVar (песочница СУДЗ)
-- DEV only. Спецификация: 08-target-schema.md §2.4 / §4.2
-- =============================================================================

IF OBJECT_ID(N'sudz.invDbtDbtVar', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.invDbtDbtVar
    (
        iddvKey         int         NOT NULL IDENTITY(1, 1),
        iddvInvDbt      int         NOT NULL,
        iddvInvDbtVar   int         NOT NULL,
        iddvTimeOfEntry datetime    NOT NULL
            CONSTRAINT DF_invDbtDbtVar_iddvTimeOfEntry DEFAULT (getdate()),

        CONSTRAINT PK_invDbtDbtVar PRIMARY KEY CLUSTERED (iddvKey),
        CONSTRAINT UX_invDbtDbtVar_Pair UNIQUE (iddvInvDbt, iddvInvDbtVar),

        CONSTRAINT FK_invDbtDbtVar_invDbt FOREIGN KEY (iddvInvDbt)
            REFERENCES sudz.invDbt (idKey),
        CONSTRAINT FK_invDbtDbtVar_invDbtVar FOREIGN KEY (iddvInvDbtVar)
            REFERENCES sudz.invDbtVar (idvvKey)
    );
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.extended_properties ep
    WHERE ep.major_id = OBJECT_ID(N'sudz.invDbtDbtVar')
      AND ep.minor_id = 0
      AND ep.name = N'MS_Description'
)
BEGIN
    EXEC sys.sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'СУДЗ песочница: мост invDbt↔invDbtVar. Триггер запрещает чужой cnNum/invNum относительно слота.',
        @level0type = N'SCHEMA', @level0name = N'sudz',
        @level1type = N'TABLE',  @level1name = N'invDbtDbtVar';
END
GO

IF OBJECT_ID(N'sudz.trg_invDbtDbtVar_NoForeignContext', N'TR') IS NOT NULL
    DROP TRIGGER sudz.trg_invDbtDbtVar_NoForeignContext;
GO

CREATE TRIGGER sudz.trg_invDbtDbtVar_NoForeignContext
ON sudz.invDbtDbtVar
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) invNum.inInv слота контекста должен совпадать с invDbt.idInv
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN sudz.invDbt s ON s.idKey = i.iddvInvDbt
        INNER JOIN sudz.invDbtVar v ON v.idvvKey = i.iddvInvDbtVar
        INNER JOIN ags.invNum n ON n.inKey = v.idvvInvNum
        WHERE n.inInv <> s.idInv
    )
    BEGIN
        RAISERROR(N'invDbtDbtVar: invDbtVar.invNum.inInv must equal invDbt.idInv', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- 2) cnNum.cnnCn должен быть среди договоров cnInv для этого Inv
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN sudz.invDbt s ON s.idKey = i.iddvInvDbt
        INNER JOIN sudz.invDbtVar v ON v.idvvKey = i.iddvInvDbtVar
        INNER JOIN ags.cnNum c ON c.cnnKey = v.idvvCnNum
        WHERE NOT EXISTS (
            SELECT 1
            FROM ags.cnInv ci
            WHERE ci.ciInv = s.idInv
              AND ci.ciCn = c.cnnCn
        )
    )
    BEGIN
        RAISERROR(N'invDbtDbtVar: invDbtVar.cnNum.cnnCn must belong to cnInv for invDbt.idInv', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

SELECT c.name AS column_name, ty.name AS type_name, c.is_identity
FROM sys.columns c
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'sudz.invDbtDbtVar')
ORDER BY c.column_id;

SELECT tr.name AS trigger_name
FROM sys.triggers tr
WHERE tr.parent_id = OBJECT_ID(N'sudz.invDbtDbtVar');
GO
