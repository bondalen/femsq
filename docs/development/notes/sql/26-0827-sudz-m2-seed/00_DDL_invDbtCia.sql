/*
 * M2 — постоянный мост cia ↔ слот invDbt (cutover D4)
 * UNIQUE(ciaKey): одна карточка → один слот; зерно 1:N cia на слот допустимо.
 * lastUpdated: 2026-08-27
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'sudz.invDbtCia', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.invDbtCia
    (
        idcKey          int       NOT NULL IDENTITY(1, 1),
        idcInvDbt       int       NOT NULL,
        idcCia          int       NOT NULL,
        idcTimeOfEntry  datetime  NOT NULL
            CONSTRAINT DF_invDbtCia_TimeOfEntry DEFAULT (GETDATE()),

        CONSTRAINT PK_invDbtCia PRIMARY KEY CLUSTERED (idcKey),
        CONSTRAINT UX_invDbtCia_Cia UNIQUE (idcCia),
        CONSTRAINT FK_invDbtCia_invDbt FOREIGN KEY (idcInvDbt)
            REFERENCES sudz.invDbt (idKey),
        CONSTRAINT FK_invDbtCia_cia FOREIGN KEY (idcCia)
            REFERENCES ags.cnInvAccnt (ciaKey)
    );

    CREATE NONCLUSTERED INDEX IX_invDbtCia_InvDbt
        ON sudz.invDbtCia (idcInvDbt);

    PRINT N'Created sudz.invDbtCia';
END
ELSE
    PRINT N'sudz.invDbtCia already exists — skip';
GO
