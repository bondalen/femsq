-- 1019 §1.8.2: dvDocBase = COALESCE(CnInv, Doc) из Tbl текущей upl
-- Согласовано с JdbcSudzDao INSERT DbtValue (CnInv ≻ Doc).
-- Охват: @901/@902/@903. Не трогает Tbl / Excel.
SET NOCOUNT ON;
SET XACT_ABORT ON;

;WITH preferred AS (
    SELECT
        dv.dvKey,
        COALESCE(
            NULLIF(LTRIM(RTRIM(t.cidutCnInv)), N''),
            NULLIF(LTRIM(RTRIM(t.cidutDoc)), N'')
        ) AS newDoc,
        ROW_NUMBER() OVER (
            PARTITION BY dv.dvKey
            ORDER BY t.cidutKey
        ) AS rn
    FROM sudz.DbtValue AS dv
    INNER JOIN sudz.invDbt AS id ON id.idKey = dv.dvInvDbt
    INNER JOIN ags.invNum AS n ON n.inInv = id.idInv
    INNER JOIN sudz.CnInvDbtUplTbl AS t
        ON t.cidutUnloadKey = dv.dvUpl
       AND LTRIM(RTRIM(ISNULL(t.cidutCnInv, N''))) = n.inNumNull
       AND CAST(COALESCE(t.cidutDebt, CAST(0 AS money)) AS decimal(19, 4))
         = CAST(COALESCE(dv.dvTtl, CAST(0 AS money)) AS decimal(19, 4))
    WHERE dv.dvUpl IN (901, 902, 903)
)
SELECT
    COUNT(*) AS matchedKeys,
    SUM(CASE WHEN ISNULL(dv.dvDocBase, N'') <> ISNULL(p.newDoc, N'') THEN 1 ELSE 0 END) AS wouldChange
FROM preferred AS p
INNER JOIN sudz.DbtValue AS dv ON dv.dvKey = p.dvKey
WHERE p.rn = 1;

BEGIN TRAN;

;WITH preferred AS (
    SELECT
        dv.dvKey,
        COALESCE(
            NULLIF(LTRIM(RTRIM(t.cidutCnInv)), N''),
            NULLIF(LTRIM(RTRIM(t.cidutDoc)), N'')
        ) AS newDoc,
        ROW_NUMBER() OVER (
            PARTITION BY dv.dvKey
            ORDER BY t.cidutKey
        ) AS rn
    FROM sudz.DbtValue AS dv
    INNER JOIN sudz.invDbt AS id ON id.idKey = dv.dvInvDbt
    INNER JOIN ags.invNum AS n ON n.inInv = id.idInv
    INNER JOIN sudz.CnInvDbtUplTbl AS t
        ON t.cidutUnloadKey = dv.dvUpl
       AND LTRIM(RTRIM(ISNULL(t.cidutCnInv, N''))) = n.inNumNull
       AND CAST(COALESCE(t.cidutDebt, CAST(0 AS money)) AS decimal(19, 4))
         = CAST(COALESCE(dv.dvTtl, CAST(0 AS money)) AS decimal(19, 4))
    WHERE dv.dvUpl IN (901, 902, 903)
)
UPDATE dv
SET dv.dvDocBase = p.newDoc
FROM sudz.DbtValue AS dv
INNER JOIN preferred AS p ON p.dvKey = dv.dvKey AND p.rn = 1
WHERE ISNULL(dv.dvDocBase, N'') <> ISNULL(p.newDoc, N'');

SELECT @@ROWCOUNT AS updatedRows;

-- контроль трёх кейсов QI
SELECT idd.iddDbt, dv.dvUpl, dv.dvDocBase
FROM sudz.DbtValue AS dv
INNER JOIN sudz.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
WHERE idd.iddDbt IN (11925, 11932, 12407)
  AND dv.dvUpl IN (901, 902)
ORDER BY 1, 2;

COMMIT TRAN;
GO
