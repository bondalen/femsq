/* C2 §3.1.6.1 — ags.impIpgLoad + ags.impIpg (DEV / open)
   Контракт: notes/26-1124-c2-o1-excel-load-contract.md
*/
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'ags.impIpgLoad', N'U') IS NULL
BEGIN
    CREATE TABLE ags.impIpgLoad (
        iilKey       int IDENTITY(1, 1) NOT NULL,
        iilIpg       int NOT NULL,
        iilNm        nvarchar(255) NOT NULL,
        iilFilePath  nvarchar(1024) NULL,
        iilNote      nvarchar(max) NULL,
        iilCreated   datetime NOT NULL CONSTRAINT DF_impIpgLoad_iilCreated DEFAULT (GETDATE()),
        CONSTRAINT PK_impIpgLoad PRIMARY KEY CLUSTERED (iilKey),
        CONSTRAINT FK_impIpgLoad_ipg FOREIGN KEY (iilIpg) REFERENCES ags.ipg (ipgKey)
    );
END
GO

IF OBJECT_ID(N'ags.impIpg', N'U') IS NULL
BEGIN
    CREATE TABLE ags.impIpg (
        iiKey        int IDENTITY(1, 1) NOT NULL,
        iiLoad       int NOT NULL,
        iiRowNo      int NOT NULL,
        iiRowKind    char(1) NOT NULL,
        iiText       nvarchar(500) NULL,
        iiParent     int NULL,
        iiStiKey     int NULL,
        iiCtx        nvarchar(max) NULL,
        CONSTRAINT PK_impIpg PRIMARY KEY CLUSTERED (iiKey),
        CONSTRAINT FK_impIpg_load FOREIGN KEY (iiLoad) REFERENCES ags.impIpgLoad (iilKey),
        CONSTRAINT FK_impIpg_parent FOREIGN KEY (iiParent) REFERENCES ags.impIpg (iiKey),
        CONSTRAINT FK_impIpg_sti FOREIGN KEY (iiStiKey) REFERENCES ags.stIpg (stiKey),
        CONSTRAINT CK_impIpg_rowKind CHECK (iiRowKind IN ('S', 'L'))
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_impIpg_load_row' AND object_id = OBJECT_ID(N'ags.impIpg')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_impIpg_load_row ON ags.impIpg (iiLoad, iiRowNo);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_impIpgLoad_ipg' AND object_id = OBJECT_ID(N'ags.impIpgLoad')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_impIpgLoad_ipg ON ags.impIpgLoad (iilIpg);
END
GO
