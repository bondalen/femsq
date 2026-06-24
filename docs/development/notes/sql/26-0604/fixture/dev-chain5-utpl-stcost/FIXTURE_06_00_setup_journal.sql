USE [FishEye];
GO
-- =============================================================================
-- FIXTURE_06_00_setup_journal.sql
-- Dev-only: журнал FIXTURE_06 (изолированные ipgUtPlGr, подмена ipgcrvUtPlGr,
-- золотой UtPl cst 2102). Не входит в MSSQL2012/.
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @batchId uniqueidentifier = NEWID();

PRINT N'=== FIXTURE_06_00: setup journal + test ipgUtPlGr 18–20 ===';

IF OBJECT_ID(N'ags._fixture_utpl06_log', N'U') IS NULL
BEGIN
    CREATE TABLE ags._fixture_utpl06_log
    (
        logKey         int              IDENTITY(1, 1) NOT NULL PRIMARY KEY,
        batchId        uniqueidentifier NOT NULL,
        action         nvarchar(30)     NOT NULL,
        iuplgKey       int              NULL,
        iuplKey        int              NULL,
        iuplgpKey      int              NULL,
        ipgcrvKey      int              NULL,
        ipgcrvIpg      int              NULL,
        utPlGr_before  int              NULL,
        utPlGr_after   int              NULL,
        iuplpKey       int              NULL,
        ipgpKey        int              NULL,
        iuplpmKey      int              NULL,
        note           nvarchar(200)    NULL,
        createdAt      datetime2(0)     NOT NULL CONSTRAINT DF_fixture_utpl06_created DEFAULT (SYSDATETIME())
    );

    CREATE INDEX IX_fixture_utpl06_batch ON ags._fixture_utpl06_log (batchId, action);
    PRINT N'  created ags._fixture_utpl06_log';
END
ELSE
    PRINT N'  ags._fixture_utpl06_log already exists';

-- Тестовые типы планов (iuplKey 201–203) — только fixture
IF NOT EXISTS (SELECT 1 FROM ags.ipgUtPl WHERE iuplKey = 201)
BEGIN
    SET IDENTITY_INSERT ags.ipgUtPl ON;
    INSERT INTO ags.ipgUtPl (iuplKey, iuplNm, iuplDate, iuplAg, iuplIpg)
    VALUES
        (201, N'TEST_FIXTURE_06_IPG6',  '2022-01-01', 41, 6),
        (202, N'TEST_FIXTURE_06_IPG8',  '2022-05-01', 41, 8),
        (203, N'TEST_FIXTURE_06_IPG11', '2022-10-01',  1, 11);
    SET IDENTITY_INSERT ags.ipgUtPl OFF;

    INSERT INTO ags._fixture_utpl06_log (batchId, action, iuplKey, note)
    VALUES
        (@batchId, N'INSERT_UTPL', 201, N'TEST_FIXTURE_06_IPG6'),
        (@batchId, N'INSERT_UTPL', 202, N'TEST_FIXTURE_06_IPG8'),
        (@batchId, N'INSERT_UTPL', 203, N'TEST_FIXTURE_06_IPG11');
    PRINT N'  inserted ipgUtPl 201–203';
END
ELSE
    PRINT N'  ipgUtPl 201–203 already exist';

-- Группы планов 18–20 (следующие после max=17)
IF NOT EXISTS (SELECT 1 FROM ags.ipgUtPlGr WHERE iuplgKey = 18)
BEGIN
    SET IDENTITY_INSERT ags.ipgUtPlGr ON;
    INSERT INTO ags.ipgUtPlGr (iuplgKey, iuplgIpg, iuplgNm)
    VALUES
        (18, 6,  N'TEST_CH5_IPG6'),
        (19, 8,  N'TEST_CH5_IPG8'),
        (20, 11, N'TEST_CH5_IPG11');
    SET IDENTITY_INSERT ags.ipgUtPlGr OFF;

    INSERT INTO ags._fixture_utpl06_log (batchId, action, iuplgKey, note)
    VALUES
        (@batchId, N'INSERT_GR', 18, N'TEST_CH5_IPG6'),
        (@batchId, N'INSERT_GR', 19, N'TEST_CH5_IPG8'),
        (@batchId, N'INSERT_GR', 20, N'TEST_CH5_IPG11');
    PRINT N'  inserted ipgUtPlGr 18–20';
END
ELSE
    PRINT N'  ipgUtPlGr 18–20 already exist';

-- Связь типа плана и группы (эксклюзивно для fixture)
DECLARE @links TABLE (gr int, pl int);
INSERT INTO @links VALUES (18, 201), (19, 202), (20, 203);

INSERT INTO ags.ipgUtPlGrP (iuplgpGr, iuplgpPl)
SELECT l.gr, l.pl
FROM @links l
WHERE NOT EXISTS (
    SELECT 1 FROM ags.ipgUtPlGrP g
    WHERE g.iuplgpGr = l.gr AND g.iuplgpPl = l.pl
);

DECLARE @grp int = @@ROWCOUNT;

INSERT INTO ags._fixture_utpl06_log (batchId, action, iuplgKey, iuplKey, note)
SELECT @batchId, N'INSERT_GRP', g.iuplgpGr, g.iuplgpPl,
       N'gr=' + CAST(g.iuplgpGr AS nvarchar) + N' pl=' + CAST(g.iuplgpPl AS nvarchar)
FROM ags.ipgUtPlGrP g
INNER JOIN @links l ON l.gr = g.iuplgpGr AND l.pl = g.iuplgpPl
WHERE NOT EXISTS (
    SELECT 1 FROM ags._fixture_utpl06_log x
    WHERE x.action = N'INSERT_GRP' AND x.iuplgKey = g.iuplgpGr AND x.iuplKey = g.iuplgpPl
);

PRINT N'  ipgUtPlGrP links: ' + CAST(@grp AS nvarchar);
PRINT N'  batchId=' + CAST(@batchId AS nvarchar(36));
GO
