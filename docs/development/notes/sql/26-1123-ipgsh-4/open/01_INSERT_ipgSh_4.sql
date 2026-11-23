-- C2 O1: ags.ipgSh key 4 «Не определена» (DEV / SQL 2022+)
-- Идемпотентно.

SET NOCOUNT ON;

IF NOT EXISTS (SELECT 1 FROM ags.ipgSh WHERE ipgsKey = 4)
BEGIN
    SET IDENTITY_INSERT ags.ipgSh ON;
    INSERT INTO ags.ipgSh (ipgsKey, ipgsNm) VALUES (4, N'Не определена');
    SET IDENTITY_INSERT ags.ipgSh OFF;
    PRINT 'Inserted ipgSh=4';
END
ELSE
    PRINT 'ipgSh=4 already present';

SELECT ipgsKey, ipgsNm FROM ags.ipgSh ORDER BY ipgsKey;
