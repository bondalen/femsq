/*
 * DEV only (Docker femsq-mssql / SQL Server 2022): клон FishEye → FishEye_prod_noM6.
 * Не выполнять на проде. lastUpdated: 2026-11-19
 *
 * Перед запуском: свободное место ≥ размера data+log FishEye (см. sys.master_files).
 * Рабочий FishEye не изменяется (COPY_ONLY backup).
 */
SET NOCOUNT ON;

IF DB_NAME() <> N'master'
BEGIN
    RAISERROR(N'Подключитесь к master.', 16, 1);
    RETURN;
END;

IF DB_ID(N'FishEye') IS NULL
BEGIN
    RAISERROR(N'БД FishEye не найдена.', 16, 1);
    RETURN;
END;

IF DB_ID(N'FishEye_prod_noM6') IS NOT NULL
BEGIN
    RAISERROR(N'FishEye_prod_noM6 уже существует. Сначала DROP DATABASE при необходимости.', 16, 1);
    RETURN;
END;

DECLARE @bak nvarchar(400) = N'/var/opt/mssql/backup/FishEye_clone_for_noM6.bak';

BACKUP DATABASE [FishEye]
TO DISK = @bak
WITH COPY_ONLY, INIT, COMPRESSION, STATS = 10;

RESTORE DATABASE [FishEye_prod_noM6]
FROM DISK = @bak
WITH
    MOVE N'FishEye' TO N'/var/opt/mssql/data/FishEye_prod_noM6.mdf',
    MOVE N'FishEye_log' TO N'/var/opt/mssql/data/FishEye_prod_noM6_log.ldf',
    REPLACE,
    STATS = 10;

SELECT name, state_desc, create_date
FROM sys.databases
WHERE name IN (N'FishEye', N'FishEye_prod_noM6')
ORDER BY name;
