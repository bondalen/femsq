--liquibase formatted sql

--changeset femsq:2026-07-14-ra-stg-ralp-excel-row runOnChange:false
--comment: 0051 / §9.3.6.1 — номер Excel-строки в staging RALP (аналог rainRow)
IF COL_LENGTH(N'ags.ra_stg_ralp', N'ralprtRow') IS NULL
BEGIN
    ALTER TABLE ags.ra_stg_ralp
        ADD ralprtRow INT NULL;
END;

--changeset femsq:2026-07-14-ra-stg-ralp-sm-excel-row runOnChange:false
IF COL_LENGTH(N'ags.ra_stg_ralp_sm', N'ralprsRow') IS NULL
BEGIN
    ALTER TABLE ags.ra_stg_ralp_sm
        ADD ralprsRow INT NULL;
END;
