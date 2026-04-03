--liquibase formatted sql

--changeset femsq:2026-04-02-ra-sheet-conf-sign-whitelist-col runOnChange:false
IF COL_LENGTH('ags.ra_sheet_conf', 'rsc_sign_whitelist') IS NULL
BEGIN
    ALTER TABLE ags.ra_sheet_conf
        ADD rsc_sign_whitelist NVARCHAR(500) NULL;
END;

--changeset femsq:2026-04-02-ra-sheet-conf-sign-whitelist-seed runOnChange:false
UPDATE ags.ra_sheet_conf
SET rsc_sign_whitelist = N'ОА;ОА изм;ОА прочие'
WHERE rsc_key = 1
  AND (rsc_sign_whitelist IS NULL OR LTRIM(RTRIM(rsc_sign_whitelist)) = N'');
