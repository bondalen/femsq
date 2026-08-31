/*
 * Stage 1: комментарии yr_CmmGr=805 для Rslt (стр. 129, 134).
 * cnicInvAccnt = dbtKey (canonical L001 → 4400, эталон 7947 → lookup).
 * lastUpdated: 2026-08-31
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @dbtStable int = (
    SELECT TOP 1 idd.iddDbt
    FROM sudz.DbtValue AS dv
    INNER JOIN sudz.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
    INNER JOIN sudz.invDbtVar AS v ON v.idvvKey = dv.dvInvDbtVar
    INNER JOIN ags.invNum AS n ON n.inKey = v.idvvInvNum
    WHERE dv.dvUpl = 801
      AND n.inNum = N'7947'
      AND ABS(CAST(dv.dvTtl AS decimal(19, 4)) - CAST(70525000.01 AS decimal(19, 4))) < 0.02
    ORDER BY idd.iddDbt
);

DECLARE @dbtL001 int = (
    SELECT TOP 1 g.canonicalDbtKey
    FROM sudz.DbtSlotLinkGroup AS g
    WHERE g.lid = N'L001' AND g.dslgStatus = N'active'
);

IF @dbtStable IS NULL OR @dbtL001 IS NULL
BEGIN
    RAISERROR(N'08_SEED: cannot resolve dbtKey for 7947 or L001', 16, 1);
    RETURN;
END

BEGIN TRANSACTION;

DELETE FROM sudz.DbtUplCstAg WHERE ducaUpl IN (801, 802, 803) AND ducaDbt = @dbtStable;
INSERT INTO sudz.DbtUplCstAg (ducaDbt, ducaUpl, ducaCstAgPn) VALUES
 (@dbtStable, 801, 1835), (@dbtStable, 802, 1835), (@dbtStable, 803, 1835);

DELETE FROM sudz.cnInvCmm    WHERE cnicGroup = 805;
DELETE FROM sudz.cnInvCmmCst WHERE ciccCmmGr = 805;
DELETE FROM sudz.cnInvCmmAg  WHERE cicaCmmGr = 805;

INSERT INTO sudz.cnInvCmm (cnicType, cnicGroup, cnicText, cnicInvAccnt) VALUES
 (8, 805, N'Сербул А.С.', @dbtStable),
 (1, 805, N'[stage1] 7947: см. Excel 26-0212 стр.129 — полный текст мероприятий отложен.', @dbtStable),
 (8, 805, N'Дедова И.В', @dbtL001),
 (1, 805, N'[stage1] L001: см. Excel 26-0212 стр.134 — полный текст мероприятий отложен.', @dbtL001);

INSERT INTO sudz.cnInvCmmCst (ciccCmmGr, ciccType, ciccCstAgPn, ciccInvAccnt) VALUES
 (805, 2, 1835, @dbtStable),
 (805, 2, 2016, @dbtL001);

INSERT INTO sudz.cnInvCmmAg (cicaCmmGr, cicaType, cicaOgAg, cicaInvAccnt) VALUES
 (805, 2, 1, @dbtStable),
 (805, 2, 1, @dbtL001);

COMMIT TRANSACTION;

SELECT N'dbtStable' AS lbl, @dbtStable AS dbtKey
UNION ALL SELECT N'dbtL001', @dbtL001;
GO
