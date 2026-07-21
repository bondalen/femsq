--liquibase formatted sql

--changeset femsq:2026-07-20-ra-stg-agfee-sender-key runOnChange:false
--comment: 0055 / Phase B — ключ агента (ogaKey) в staging type=6; порт oafptOafSenderKey
IF COL_LENGTH(N'ags.ra_stg_agfee', N'oafptOafSenderKey') IS NULL
BEGIN
    ALTER TABLE ags.ra_stg_agfee
        ADD oafptOafSenderKey INT NULL;
END;

--changeset femsq:2026-07-20-ra-stg-agfee-cst-key runOnChange:false
--comment: 0055 / Phase B — ключ стройки (cstapKey) в staging type=6; порт oafptPnCstAgPnKey
IF COL_LENGTH(N'ags.ra_stg_agfee', N'oafptPnCstAgPnKey') IS NULL
BEGIN
    ALTER TABLE ags.ra_stg_agfee
        ADD oafptPnCstAgPnKey INT NULL;
END;
