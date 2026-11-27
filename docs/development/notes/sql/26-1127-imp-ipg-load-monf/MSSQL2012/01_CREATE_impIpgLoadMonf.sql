/* C2 §6.3 — ags.impIpgLoadMonf (MSSQL 2012)
   Без CREATE OR ALTER / DROP IF EXISTS.
   Note: chats/chat-plan/notes/26-1127-c2-o6-ldm-monf.md
*/
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'ags.impIpgLoadMonf', N'U') IS NULL
BEGIN
    CREATE TABLE ags.impIpgLoadMonf (
        iilmKey        int IDENTITY(1, 1) NOT NULL,
        iilmLoad       int NOT NULL,
        iilmUtPl       int NULL,
        iilmNm         nvarchar(255) NOT NULL,
        iilmFilePath   nvarchar(1024) NULL,
        iilmSheet      nvarchar(128) NULL,
        iilmLimColumn  nvarchar(128) NULL,
        iilmQuarter    bit NOT NULL
            CONSTRAINT DF_impIpgLoadMonf_quarter DEFAULT (1),
        iilmSumFirst   int NULL,
        iilmNote       nvarchar(max) NULL,
        iilmCreated    datetime NOT NULL
            CONSTRAINT DF_impIpgLoadMonf_created DEFAULT (GETDATE()),
        iilmResults    nvarchar(max) NULL,
        CONSTRAINT PK_impIpgLoadMonf PRIMARY KEY CLUSTERED (iilmKey),
        CONSTRAINT FK_impIpgLoadMonf_load FOREIGN KEY (iilmLoad)
            REFERENCES ags.impIpgLoad (iilKey),
        CONSTRAINT FK_impIpgLoadMonf_utpl FOREIGN KEY (iilmUtPl)
            REFERENCES ags.ipgUtPl (iuplKey)
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_impIpgLoadMonf_load' AND object_id = OBJECT_ID(N'ags.impIpgLoadMonf')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_impIpgLoadMonf_load
        ON ags.impIpgLoadMonf (iilmLoad);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_impIpgLoadMonf_utpl' AND object_id = OBJECT_ID(N'ags.impIpgLoadMonf')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_impIpgLoadMonf_utpl
        ON ags.impIpgLoadMonf (iilmUtPl);
END
GO
