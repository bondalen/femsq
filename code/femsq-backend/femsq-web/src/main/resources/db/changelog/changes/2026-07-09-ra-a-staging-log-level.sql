--liquibase formatted sql

--changeset femsq:2026-07-09-ra-a-staging-log-level-col runOnChange:false
IF COL_LENGTH('ags.ra_a', 'adt_staging_log_level') IS NULL
BEGIN
    ALTER TABLE ags.ra_a
        ADD adt_staging_log_level NVARCHAR(16) NULL;
END;
