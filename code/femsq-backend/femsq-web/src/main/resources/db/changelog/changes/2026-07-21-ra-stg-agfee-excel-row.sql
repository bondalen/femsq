--liquibase formatted sql

--changeset femsq:2026-07-21-ra-stg-agfee-excel-row runOnChange:false
--comment: 0056 — номер Excel-строки в staging AgFee (аналог rainRow / ralprtRow)
IF COL_LENGTH(N'ags.ra_stg_agfee', N'oafptRow') IS NULL
BEGIN
    ALTER TABLE ags.ra_stg_agfee
        ADD oafptRow INT NULL;
END;
