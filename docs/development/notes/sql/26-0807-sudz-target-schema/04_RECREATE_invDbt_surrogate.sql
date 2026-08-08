-- =============================================================================
-- Пересоздание sudz.invDbt / invDbtDbt: суррогатный PK на invDbt
-- DEV only. Таблицы пустые — безопасный DROP.
-- Спецификация: 08-target-schema.md §3.1 / §2.2 (S35)
-- =============================================================================

IF OBJECT_ID(N'sudz.invDbtDbt', N'U') IS NOT NULL
    DROP TABLE sudz.invDbtDbt;
GO

IF OBJECT_ID(N'sudz.invDbt', N'U') IS NOT NULL
    DROP TABLE sudz.invDbt;
GO

-- Слот «долг у СФ»: суррогат idKey + бизнес-UNIQUE (idInv, idNum)
CREATE TABLE sudz.invDbt
(
    idKey           int            NOT NULL IDENTITY(1, 1),
    idInv           int            NOT NULL,
    idNum           tinyint        NOT NULL
        CONSTRAINT DF_invDbt_idNum DEFAULT ((1)),
    idNote          nvarchar(255)  NULL,
    idTimeOfEntry   datetime       NOT NULL
        CONSTRAINT DF_invDbt_idTimeOfEntry DEFAULT (getdate()),

    CONSTRAINT PK_invDbt PRIMARY KEY CLUSTERED (idKey),
    CONSTRAINT UX_invDbt_InvNum UNIQUE (idInv, idNum),
    CONSTRAINT FK_invDbt_inv FOREIGN KEY (idInv)
        REFERENCES ags.inv (iKey)
);
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'СУДЗ песочница: слот долга у СФ. PK=idKey (суррогат); UNIQUE(idInv,idNum); FK→ags.inv.',
    @level0type = N'SCHEMA', @level0name = N'sudz',
    @level1type = N'TABLE',  @level1name = N'invDbt';
GO

-- Мост Inv↔Dbt: FK на слот — одна колонка iddInvDbt → invDbt.idKey
CREATE TABLE sudz.invDbtDbt
(
    iddKey          int         NOT NULL IDENTITY(1, 1),
    iddInv          int         NOT NULL,
    iddDbt          int         NOT NULL,
    iddInvDbt       int         NOT NULL,
    iddTimeOfEntry  datetime    NOT NULL
        CONSTRAINT DF_invDbtDbt_iddTimeOfEntry DEFAULT (getdate()),

    CONSTRAINT PK_invDbtDbt PRIMARY KEY CLUSTERED (iddKey),
    CONSTRAINT UX_invDbtDbt_InvDbt UNIQUE (iddInv, iddDbt),
    CONSTRAINT UX_invDbtDbt_Slot UNIQUE (iddInvDbt),

    CONSTRAINT FK_invDbtDbt_inv FOREIGN KEY (iddInv)
        REFERENCES ags.inv (iKey),
    CONSTRAINT FK_invDbtDbt_Dbt FOREIGN KEY (iddDbt)
        REFERENCES sudz.Dbt (dbtKey),
    CONSTRAINT FK_invDbtDbt_invDbt FOREIGN KEY (iddInvDbt)
        REFERENCES sudz.invDbt (idKey)
);
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'СУДЗ песочница: мост Inv↔Dbt. FK на invDbt.idKey; UNIQUE(inv,dbt); UNIQUE(слот). Согласованность iddInv↔invDbt.idInv — триггер.',
    @level0type = N'SCHEMA', @level0name = N'sudz',
    @level1type = N'TABLE',  @level1name = N'invDbtDbt';
GO

-- iddInv должен совпадать с invDbt.idInv для выбраннного слота
CREATE TRIGGER sudz.trg_invDbtDbt_InvMatchesSlot
ON sudz.invDbtDbt
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN sudz.invDbt s ON s.idKey = i.iddInvDbt
        WHERE s.idInv <> i.iddInv
    )
    BEGIN
        RAISERROR(N'invDbtDbt: iddInv must equal invDbt.idInv for iddInvDbt', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

SELECT N'invDbt' AS tbl, c.name AS col, ty.name AS typ, c.is_identity
FROM sys.columns c
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'sudz.invDbt')
UNION ALL
SELECT N'invDbtDbt', c.name, ty.name, c.is_identity
FROM sys.columns c
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'sudz.invDbtDbt')
ORDER BY tbl, col;
GO
