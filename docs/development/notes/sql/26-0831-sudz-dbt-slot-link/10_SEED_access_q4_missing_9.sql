/*
 * DEPRECATED 2026-09-01 — do not apply. Use real Excel export X or tiered gate + p3_data_gap_manifest.json.
 * Stage2 / variant B: 9 Access Q4 Rslt rows absent from Excel свод 31.12.2025
 * (upload Access 2026-01-30 vs FEMSQ upl 901 2026-01-15).
 *
 * Inserts inv / invNum / invDbt / Dbt / bridges / DbtValue@901.
 * Mark: B-seed-access-q4-missing
 * lastUpdated: 2026-08-31
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @now datetime = SYSUTCDATETIME();
DECLARE @upl int = 901;
DECLARE @accnt int = 24; /* 762210 */
DECLARE @note nvarchar(100) = N'B-seed-access-q4-missing';

/* cnNum / cn_s_org already in DEV */
DECLARE @cnnKs51 int = 305;
DECLARE @csoInvest int = 307;
DECLARE @cnnZap int = 854;
DECLARE @csoZap int = 1720;
/* Gazstroyprom: contract 15-ЗБС/21-АС missing in cnNum — use any existing side+num for org */
DECLARE @cnnGsp int;
DECLARE @csoGsp int;
SELECT TOP 1 @csoGsp = so.cn_s_org_key, @cnnGsp = v.idvvCnNum
FROM sudz.invDbtVar v
JOIN ags.cn_s_org so ON so.cn_s_org_key = v.idvvCn_s_org
JOIN ags.cn_s_org_smpl os ON os.csosKey = so.csoCn_s_org_smpl
JOIN ags.org_id oi ON oi.org_id_key = os.csosOrgId AND oi.org_id_type = 1
WHERE oi.org_id_value_l = 1255867
ORDER BY v.idvvKey;

IF @cnnGsp IS NULL OR @csoGsp IS NULL
BEGIN
    RAISERROR(N'No invDbtVar context for org 1255867', 16, 1);
    RETURN;
END;

IF OBJECT_ID('tempdb..#seed9') IS NOT NULL DROP TABLE #seed9;
CREATE TABLE #seed9 (
    ord int NOT NULL PRIMARY KEY,
    inv nvarchar(100) NOT NULL,
    ttl decimal(28,2) NOT NULL,
    overd decimal(28,2) NOT NULL,
    maturity date NULL,
    cnn int NOT NULL,
    cso int NOT NULL,
    org_l bigint NOT NULL
);

INSERT INTO #seed9 (ord, inv, ttl, overd, maturity, cnn, cso, org_l) VALUES
 (1, N'б/н',        89633019.16, 0,            '2025-12-31', @cnnKs51, @csoInvest, 1009345),
 (2, N'б/н',          110642.38, 0,            '2025-12-31', @cnnGsp,  @csoGsp,    1255867),
 (3, N'б/н',         2247973.63, 0,            '2025-12-31', @cnnZap,  @csoZap,    1143509),
 (4, N'06/44-3185',150551722.96, 150551722.96, '2024-07-02', @cnnKs51, @csoInvest, 1009345),
 (5, N'06/44-4194',253324136.00, 253324136.00, '2025-08-01', @cnnKs51, @csoInvest, 1009345),
 (6, N'06/44-4562', 18021646.00,  18021646.00, '2024-09-09', @cnnKs51, @csoInvest, 1009345),
 (7, N'06/44-5561', 54250324.36,  54250324.36, '2025-10-10', @cnnKs51, @csoInvest, 1009345),
 (8, N'06/44-5788', 11857862.74,  11857862.74, '2025-10-23', @cnnKs51, @csoInvest, 1009345),
 (9, N'Б/С',        12892753.24, 0,            '2025-12-31', @cnnKs51, @csoInvest, 1009345);

BEGIN TRAN;

DECLARE @ord int, @inv nvarchar(100), @ttl decimal(28,2), @overd decimal(28,2),
        @mat date, @cnn int, @cso int, @org bigint;
DECLARE @iKey int, @inKey int, @slot int, @dbt int, @var int, @cn int;

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT ord, inv, ttl, overd, maturity, cnn, cso, org_l FROM #seed9 ORDER BY ord;
OPEN c;
FETCH NEXT FROM c INTO @ord, @inv, @ttl, @overd, @mat, @cnn, @cso, @org;
WHILE @@FETCH_STATUS = 0
BEGIN
    /* skip if Value with this ttl already on 901 for account 762210 */
    IF EXISTS (
        SELECT 1
        FROM sudz.DbtValue dv
        JOIN sudz.invDbtVar v ON v.idvvKey = dv.dvInvDbtVar
        WHERE dv.dvUpl = @upl AND v.idvvAccnt = @accnt
          AND ABS(CAST(dv.dvTtl AS decimal(28,2)) - @ttl) < 0.02
    )
    BEGIN
        FETCH NEXT FROM c INTO @ord, @inv, @ttl, @overd, @mat, @cnn, @cso, @org;
        CONTINUE;
    END;

    SELECT @cn = cnnCn FROM ags.cnNum WHERE cnnKey = @cnn;
    IF @cn IS NULL
    BEGIN
        RAISERROR(N'Missing cnnCn for cnnKey=%d', 16, 1, @cnn);
        ROLLBACK TRAN;
        RETURN;
    END;

    INSERT INTO ags.inv (iNote, iTimeOfEntry)
    VALUES (@note, @now);
    SET @iKey = SCOPE_IDENTITY();

    INSERT INTO ags.invNum (inNum, inNote, inInv, inTimeOfEntry)
    VALUES (@inv, @note, @iKey, @now);
    SET @inKey = SCOPE_IDENTITY();

    INSERT INTO ags.cnInv (ciCn, ciNote, ciInv, ciTimeOfEntry)
    VALUES (@cn, @note, @iKey, @now);

    INSERT INTO sudz.invDbt (idInv, idNum, idNote, idTimeOfEntry)
    VALUES (@iKey, 1, @note, @now);
    SET @slot = SCOPE_IDENTITY();

    INSERT INTO sudz.Dbt (dbtNote, dbtTimeOfEntry)
    VALUES (@note, @now);
    SET @dbt = SCOPE_IDENTITY();

    INSERT INTO sudz.invDbtDbt (iddInv, iddDbt, iddInvDbt, iddTimeOfEntry)
    VALUES (@iKey, @dbt, @slot, @now);

    /* reuse var if same context exists */
    SET @var = NULL;
    SELECT @var = idvvKey FROM sudz.invDbtVar
    WHERE idvvCnNum = @cnn AND idvvInvNum = @inKey AND idvvAccnt = @accnt AND idvvCn_s_org = @cso;

    IF @var IS NULL
    BEGIN
        INSERT INTO sudz.invDbtVar (idvvCnNum, idvvInvNum, idvvAccnt, idvvCn_s_org, idvvTimeOfEntry)
        VALUES (@cnn, @inKey, @accnt, @cso, @now);
        SET @var = SCOPE_IDENTITY();
    END;

    IF NOT EXISTS (
        SELECT 1 FROM sudz.invDbtDbtVar
        WHERE iddvInvDbt = @slot AND iddvInvDbtVar = @var
    )
        INSERT INTO sudz.invDbtDbtVar (iddvInvDbt, iddvInvDbtVar, iddvTimeOfEntry)
        VALUES (@slot, @var, @now);

    INSERT INTO sudz.DbtValue (
        dvInvDbt, dvInvDbtVar, dvUpl, dvTtl, dvOverd,
        dvDateStart, dvDateMaturity, dvDocBase, dvTimeOfEntry
    )
    VALUES (
        @slot, @var, @upl, @ttl, @overd,
        NULL, @mat, @inv, @now
    );

    /* staging mirror for audit */
    INSERT INTO sudz.CnInvDbtUplTbl (
        FindDbtNum, cidutAccount, cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN,
        cidutCnName, cidutCnDate, cidutCnInv, cidutFormtnDate, cidutMatrtyDate,
        cidutDebt, cidutDebtOverdue, cidutDoc, cidutSheet, cidutSheetNum, cidutUnloadKey
    )
    SELECT
        0, @accnt, @org,
        CASE @org
            WHEN 1009345 THEN N'ООО ГАЗПРОМ ИНВЕСТ'
            WHEN 1255867 THEN N'АО ГАЗСТРОЙПРОМ'
            WHEN 1143509 THEN N'ООО ГАЗПРОМНЕФТЬ-ЗАПОЛЯРЬЕ'
        END,
        CASE @org WHEN 1009345 THEN N'7810483334' WHEN 1255867 THEN N'7842155505' ELSE NULL END,
        (SELECT cnnNum FROM ags.cnNum WHERE cnnKey = @cnn),
        (SELECT csoCnDate FROM ags.cn_s_org WHERE cn_s_org_key = @cso),
        @inv, NULL, @mat, @ttl, @overd, @inv, N'762210', 0, @upl;

    FETCH NEXT FROM c INTO @ord, @inv, @ttl, @overd, @mat, @cnn, @cso, @org;
END
CLOSE c; DEALLOCATE c;

COMMIT;

SELECT COUNT(*) AS val901, SUM(CAST(dvTtl AS decimal(28,2))) AS sum901
FROM sudz.DbtValue WHERE dvUpl = 901;

SELECT CAST(dv.dvTtl AS decimal(28,2)) ttl, n.inNum, c.cnnNum
FROM sudz.DbtValue dv
JOIN sudz.invDbtVar v ON v.idvvKey = dv.dvInvDbtVar
JOIN ags.invNum n ON n.inKey = v.idvvInvNum
JOIN ags.cnNum c ON c.cnnKey = v.idvvCnNum
WHERE dv.dvUpl = 901 AND n.inNote = @note
ORDER BY ttl DESC;
GO
