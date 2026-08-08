-- =============================================================================
-- sudz.invDbt — слот «долг у СФ» (песочница СУДЗ)
-- DEV only. Спецификация: 08-target-schema.md §3.1 (S35: суррогатный PK)
-- PK = idKey; бизнес-уникальность слота = UNIQUE(idInv, idNum); FK → ags.inv
-- =============================================================================

IF OBJECT_ID(N'sudz.invDbt', N'U') IS NULL
BEGIN
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
END
GO
