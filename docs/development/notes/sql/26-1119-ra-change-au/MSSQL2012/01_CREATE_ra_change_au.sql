-- =============================================================================
-- 01_CREATE_ra_change_au.sql — additive CREATE (SQL Server 2012)
-- Зерно UX: (racAu_rac, racAu_arrived) — аналог ralpRaAu (ralpraRa, ralpraArrived)
-- =============================================================================
SET NOCOUNT ON;
PRINT '=== 01_CREATE ra_change_au ===';

IF OBJECT_ID(N'ags.ra_change_au', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_change_au (
        racAu_key              INT NOT NULL IDENTITY(1, 1),
        racAu_rac              INT NOT NULL,
        racAu_arrived          NVARCHAR(255) NOT NULL
            CONSTRAINT DF_ra_change_au_arrived DEFAULT (N''),
        racAu_arrived_date     DATE NULL,
        racAu_arrived_dateFact DATE NULL,
        racAu_returned         NVARCHAR(255) NULL,
        racAu_returned_date    DATE NULL,
        racAu_returnedReason   NVARCHAR(255) NULL,
        racAu_sent             NVARCHAR(255) NULL,
        racAu_sent_date        DATE NULL,
        racAu_total            MONEY NULL,
        racAu_work             MONEY NULL,
        racAu_equip            MONEY NULL,
        racAu_others           MONEY NULL,
        racAu_created          DATETIME NOT NULL
            CONSTRAINT DF_ra_change_au_created DEFAULT (GETDATE()),
        racAu_fdKey            INT NULL,
        CONSTRAINT PK_ra_change_au PRIMARY KEY (racAu_key),
        CONSTRAINT FK_ra_change_au_ra_change FOREIGN KEY (racAu_rac)
            REFERENCES ags.ra_change (rac_key)
    );

    CREATE UNIQUE NONCLUSTERED INDEX UX_ra_change_au_rac_arrived
        ON ags.ra_change_au (racAu_rac, racAu_arrived);

    CREATE NONCLUSTERED INDEX IX_ra_change_au_rac
        ON ags.ra_change_au (racAu_rac);

    PRINT 'Created ags.ra_change_au + UX_ra_change_au_rac_arrived';
END
ELSE
    PRINT 'Skip: ags.ra_change_au exists';
GO

-- FK на factDoc — только если таблица есть (стек _2606)
IF OBJECT_ID(N'ags.ra_change_au', N'U') IS NOT NULL
   AND OBJECT_ID(N'ags.factDoc', N'U') IS NOT NULL
   AND NOT EXISTS (
        SELECT 1 FROM sys.foreign_keys
        WHERE name = N'FK_ra_change_au_factDoc'
          AND parent_object_id = OBJECT_ID(N'ags.ra_change_au')
   )
BEGIN
    ALTER TABLE ags.ra_change_au ADD CONSTRAINT FK_ra_change_au_factDoc
        FOREIGN KEY (racAu_fdKey) REFERENCES ags.factDoc (fdKey);
    PRINT 'Added FK_ra_change_au_factDoc';
END
GO
