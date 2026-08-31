/*
 * DbtSlotLinkGroup + DbtSlotLinkMember — реестр P1 (L*).
 * canonicalDbtKey заполняется ApplyDbtSlotLinks (NOT NULL при status=active).
 * lastUpdated: 2026-08-31
 */
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'sudz.DbtSlotLinkMember', N'U') IS NOT NULL
    DROP TABLE sudz.DbtSlotLinkMember;
GO

IF OBJECT_ID(N'sudz.DbtSlotLinkGroup', N'U') IS NOT NULL
    DROP TABLE sudz.DbtSlotLinkGroup;
GO

CREATE TABLE sudz.DbtSlotLinkGroup
(
    lid              nvarchar(16)  NOT NULL,
    dslgStatus       nvarchar(16)  NOT NULL
        CONSTRAINT DF_DbtSlotLinkGroup_status DEFAULT (N'pending'),
    canonicalDbtKey  int           NULL,
    canonicalRule    nvarchar(32)  NULL,
    canonicalSetAt   datetime      NULL,
    matchSum         decimal(19, 4) NULL,
    sourceRslt       nvarchar(128) NULL,
    note             nvarchar(512) NULL,
    dslgTimeOfEntry  datetime      NOT NULL
        CONSTRAINT DF_DbtSlotLinkGroup_entry DEFAULT (GETDATE()),

    CONSTRAINT PK_DbtSlotLinkGroup PRIMARY KEY CLUSTERED (lid),
    CONSTRAINT CK_DbtSlotLinkGroup_status CHECK (dslgStatus IN (N'pending', N'active', N'superseded')),
    CONSTRAINT CK_DbtSlotLinkGroup_canonical CHECK (
        (dslgStatus = N'pending' AND canonicalDbtKey IS NULL)
        OR (dslgStatus = N'superseded')
        OR (dslgStatus = N'active' AND canonicalDbtKey IS NOT NULL)
    ),
    CONSTRAINT FK_DbtSlotLinkGroup_Dbt FOREIGN KEY (canonicalDbtKey)
        REFERENCES sudz.Dbt (dbtKey)
);
GO

CREATE TABLE sudz.DbtSlotLinkMember
(
    lid     nvarchar(16) NOT NULL,
    iKey    int          NOT NULL,
    idNum   tinyint      NOT NULL,

    CONSTRAINT PK_DbtSlotLinkMember PRIMARY KEY CLUSTERED (lid, iKey, idNum),
    CONSTRAINT FK_DbtSlotLinkMember_Group FOREIGN KEY (lid)
        REFERENCES sudz.DbtSlotLinkGroup (lid),
    CONSTRAINT FK_DbtSlotLinkMember_inv FOREIGN KEY (iKey)
        REFERENCES ags.inv (iKey)
);
GO

CREATE NONCLUSTERED INDEX IX_DbtSlotLinkMember_slot
    ON sudz.DbtSlotLinkMember (iKey, idNum);
GO
