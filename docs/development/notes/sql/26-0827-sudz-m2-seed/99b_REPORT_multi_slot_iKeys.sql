/*
 * S77.9 M5 — post-seed / post-cutover отчёт: iKey с N>1 слотами invDbt.
 * Инфо только: не удалять зёрна, не auto-merge первая/вторая.
 *
 * Цель: видеть пары вроде 28469 (первая/вторая) до/после seed и при UAT непрерывности.
 * lastUpdated: 2026-09-15
 */
SET NOCOUNT ON;
GO

/* Сводка */
SELECT
    COUNT(*) AS iKeysWithMultiSlots,
    SUM(slotCnt) AS slotsInThoseIKeys,
    MAX(slotCnt) AS maxSlotsPerIKey
FROM (
    SELECT idInv AS iKey, COUNT(*) AS slotCnt
    FROM sudz.invDbt
    GROUP BY idInv
    HAVING COUNT(*) > 1
) AS m;
GO

/* Деталь: слоты + note + канон Dbt */
SELECT
    d.idInv AS iKey,
    i.iNum AS invNum,
    d.idKey AS slotKey,
    d.idNum,
    d.idNote,
    idd.iddDbt AS dbtKey,
    (
        SELECT COUNT(*)
        FROM sudz.invDbt AS x
        WHERE x.idInv = d.idInv
    ) AS slotCntOnIKey,
    CASE
        WHEN d.idNote LIKE N'%первая%' OR d.idNote LIKE N'%вторая%'
            THEN N'first_second_pair_candidate'
        ELSE N'other_multi'
    END AS kindHint
FROM sudz.invDbt AS d
INNER JOIN (
    SELECT idInv
    FROM sudz.invDbt
    GROUP BY idInv
    HAVING COUNT(*) > 1
) AS m ON m.idInv = d.idInv
LEFT JOIN ags.inv AS i ON i.iKey = d.idInv
LEFT JOIN sudz.invDbtDbt AS idd ON idd.iddInvDbt = d.idKey
ORDER BY slotCntOnIKey DESC, d.idInv, d.idNum, d.idKey;
GO

/* Подсчёт кандидатов первая/вторая на одном iKey */
;WITH named AS (
    SELECT
        d.idInv AS iKey,
        MAX(CASE WHEN d.idNote LIKE N'%ciaName=первая%' OR d.idNote = N'ciaName=первая' THEN 1 ELSE 0 END) AS hasPervaya,
        MAX(CASE WHEN d.idNote LIKE N'%ciaName=вторая%' OR d.idNote = N'ciaName=вторая' THEN 1 ELSE 0 END) AS hasVtoraya,
        COUNT(*) AS slotCnt
    FROM sudz.invDbt AS d
    GROUP BY d.idInv
)
SELECT
    COUNT(*) AS iKeysWithPervayaAndVtoraya
FROM named
WHERE hasPervaya = 1 AND hasVtoraya = 1;
GO
