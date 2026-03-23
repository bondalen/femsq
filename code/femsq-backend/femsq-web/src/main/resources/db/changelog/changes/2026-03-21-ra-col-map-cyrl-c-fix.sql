--liquibase formatted sql

--changeset femsq:2026-03-21-ra-col-map-normalize-returned-sum runOnChange:false
--comment: Existing DBs: fix Latin C in Excel header seeds for rainRaReturnedSum / oafptReturnedSum; remove duplicate rcm_key 28 and 48 from older ra_col_map seed.

IF OBJECT_ID(N'ags.ra_col_map', N'U') IS NOT NULL
BEGIN
    UPDATE ags.ra_col_map
    SET rcm_xl_hdr = N'Сумма возвращенных ОА'
    WHERE rcm_key = 27
      AND rcm_rsc_key = 1
      AND rcm_tbl_col = N'rainRaReturnedSum';

    DELETE FROM ags.ra_col_map WHERE rcm_key = 28;

    UPDATE ags.ra_col_map
    SET rcm_xl_hdr = N'Сумма возвращенных АВ'
    WHERE rcm_key = 47
      AND rcm_rsc_key = 2
      AND rcm_tbl_col = N'oafptReturnedSum';

    DELETE FROM ags.ra_col_map WHERE rcm_key = 48;
END;
