/*
 * M2 — разведение concurrent multi-cia на отдельные invDbt
 *
 * Проблема: зерно S73 (iKey, ciaNameNull) склеивает несколько cia в один слот;
 * UNIQUE(dvInvDbt,dvUpl) тогда теряет вторую сумму в той же выгрузке → битый итог свода/СГК.
 *
 * Правило: если через мост ≥2 строк cn_inv_dbt на одну пару (slot, upl),
 * оставить cia с min(ciaKey) на исходном слоте; остальным — новый invDbt
 * (idNum = 240+), новый Dbt + invDbtDbt, перенос invDbtCia.
 *
 * Классы (DEV 2026-08-27):
 *   A — один cn+СФ, две dated cia / одно юрлицо (недоразмеченный P2)
 *   B — один inv на два cn одной орг. (переезд; iKey 40665) — тот же механизм слотов
 *
 * Вызывать после 05+06, до 07 E1. Идемпотентно при отсутствии коллизий.
 * lastUpdated: 2026-08-27
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'tempdb..#secondary') IS NOT NULL DROP TABLE #secondary;

;WITH cid_slot AS (
    SELECT
        cid.cn_inv_dbt_upl AS upl,
        br.idcInvDbt AS slot,
        br.idcCia AS ciaKey
    FROM ags.cn_inv_dbt AS cid
    INNER JOIN sudz.invDbtCia AS br ON br.idcCia = cid.cidCnInvAccntCtpt
),
colliding AS (
    SELECT slot, upl
    FROM cid_slot
    GROUP BY slot, upl
    HAVING COUNT(*) > 1
),
cias AS (
    SELECT DISTINCT cs.slot, cs.ciaKey
    FROM cid_slot AS cs
    INNER JOIN colliding AS c ON c.slot = cs.slot AND c.upl = cs.upl
),
ranked AS (
    SELECT
        c.slot,
        c.ciaKey,
        d.idInv,
        ROW_NUMBER() OVER (PARTITION BY c.slot ORDER BY c.ciaKey) AS rn
    FROM cias AS c
    INNER JOIN sudz.invDbt AS d ON d.idKey = c.slot
)
SELECT
    r.slot AS oldSlot,
    r.ciaKey,
    r.idInv,
    r.rn,
    CAST(239 + r.rn AS tinyint) AS newIdNum, /* rn≥2 → 241, 242, … (240 зарезервирован) */
    CASE
        WHEN (
            SELECT COUNT(DISTINCT ci.ciCn)
            FROM ags.cnInv AS ci
            WHERE ci.ciInv = r.idInv
        ) > 1 THEN N'M2-cn-migrate'
        ELSE N'M2-concurrent-cia'
    END AS note
INTO #secondary
FROM ranked AS r
WHERE r.rn > 1;

DECLARE @n int = (SELECT COUNT(*) FROM #secondary);
PRINT CONCAT(N'concurrent secondary cias to split: ', @n);

IF @n = 0
BEGIN
    PRINT N'No concurrent collisions — skip split';
    RETURN;
END

/* idNum must be free */
IF EXISTS (
    SELECT 1
    FROM #secondary AS s
    INNER JOIN sudz.invDbt AS d ON d.idInv = s.idInv AND d.idNum = s.newIdNum
)
BEGIN
    RAISERROR(N'M2 split: target idNum already occupied — adjust allocator', 16, 1);
    RETURN;
END

BEGIN TRANSACTION;

DECLARE @ciaKey int, @idInv int, @newIdNum tinyint, @note nvarchar(32);
DECLARE @newSlot int, @newDbt int;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT ciaKey, idInv, newIdNum, note FROM #secondary ORDER BY idInv, ciaKey;

OPEN cur;
FETCH NEXT FROM cur INTO @ciaKey, @idInv, @newIdNum, @note;

WHILE @@FETCH_STATUS = 0
BEGIN
    INSERT INTO sudz.invDbt (idInv, idNum, idNote, idTimeOfEntry)
    VALUES (@idInv, @newIdNum, @note, GETDATE());
    SET @newSlot = SCOPE_IDENTITY();

    INSERT INTO sudz.Dbt (dbtNote, dbtTimeOfEntry)
    VALUES (@note, GETDATE());
    SET @newDbt = SCOPE_IDENTITY();

    INSERT INTO sudz.invDbtDbt (iddInv, iddDbt, iddInvDbt, iddTimeOfEntry)
    VALUES (@idInv, @newDbt, @newSlot, GETDATE());

    UPDATE sudz.invDbtCia
    SET idcInvDbt = @newSlot
    WHERE idcCia = @ciaKey;

    FETCH NEXT FROM cur INTO @ciaKey, @idInv, @newIdNum, @note;
END

CLOSE cur;
DEALLOCATE cur;

COMMIT TRANSACTION;

/* post-check: no concurrent collisions left */
;WITH cid_slot AS (
    SELECT cid.cn_inv_dbt_upl AS upl, br.idcInvDbt AS slot
    FROM ags.cn_inv_dbt AS cid
    INNER JOIN sudz.invDbtCia AS br ON br.idcCia = cid.cidCnInvAccntCtpt
)
SELECT @n = COUNT(*) FROM (
    SELECT slot, upl FROM cid_slot GROUP BY slot, upl HAVING COUNT(*) > 1
) x;

PRINT CONCAT(N'remaining concurrent (slot,upl) collisions: ', @n);
IF @n > 0
    RAISERROR(N'M2 split incomplete: %d collisions remain', 16, 1, @n);

SELECT N'invDbt' AS t, COUNT(*) AS n FROM sudz.invDbt
UNION ALL SELECT N'Dbt', COUNT(*) FROM sudz.Dbt
UNION ALL SELECT N'split_notes', COUNT(*) FROM sudz.Dbt
    WHERE dbtNote IN (N'M2-concurrent-cia', N'M2-cn-migrate');
GO
