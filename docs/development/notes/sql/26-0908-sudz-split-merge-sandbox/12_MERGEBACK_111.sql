-- =============================================================================
-- Обратное слияние долей 111 на срезе 210: снова одна Value 36000 на слоте 311.
-- 202–209 остаются 2×18000. Комментарии 209 (две) и 210 (одна).
-- =============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRAN;

DELETE FROM test_sudz_sm.cnInvGr
WHERE cnigDv IN (SELECT dvKey FROM test_sudz_sm.DbtValue WHERE dvUpl IN (209, 210) AND dvInvDbt IN (311, 322, 323));
DELETE FROM test_sudz_sm.cmm
WHERE cmmDv IN (SELECT dvKey FROM test_sudz_sm.DbtValue WHERE dvUpl IN (209, 210) AND dvInvDbt IN (311, 322, 323));

DELETE FROM test_sudz_sm.DbtValue
WHERE dvInvDbt IN (322, 323) AND dvUpl = 210;

IF NOT EXISTS (SELECT 1 FROM test_sudz_sm.DbtValue WHERE dvInvDbt = 311 AND dvUpl = 210)
    INSERT INTO test_sudz_sm.DbtValue (dvInvDbt, dvInvDbtVar, dvUpl, dvTtl, dvOverd, dvDocBase)
    VALUES (311, 411, 210, 36000, 36000, N'111-mergeback');

IF NOT EXISTS (SELECT 1 FROM test_sudz_sm.cmmGr WHERE cmmgKey = 209)
    INSERT INTO test_sudz_sm.cmmGr (cmmgKey, cmmgUpl, cmmgName)
    VALUES (209, 209, N'старые · свод 209 (ещё split)');
IF NOT EXISTS (SELECT 1 FROM test_sudz_sm.cmmGr WHERE cmmgKey = 210)
    INSERT INTO test_sudz_sm.cmmGr (cmmgKey, cmmgUpl, cmmgName)
    VALUES (210, 210, N'новые · свод 210 (снова целый)');

INSERT INTO test_sudz_sm.cmm (cmmDv, cmmGr, cmmKind, cmmText)
SELECT dv.dvKey, 209, N'mery',
       CASE dv.dvInvDbt
           WHEN 322 THEN N'111 доля A 18000 (ещё split на 209)'
           WHEN 323 THEN N'111 доля B 18000 (ещё split на 209)'
       END
FROM test_sudz_sm.DbtValue AS dv
INNER JOIN test_sudz_sm.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
WHERE idd.iddDbt = 111 AND dv.dvUpl = 209;

INSERT INTO test_sudz_sm.cnInvGr (cnigDv, cnigCmmGr, cnigGrName)
SELECT dv.dvKey, 209, 1
FROM test_sudz_sm.DbtValue AS dv
WHERE dv.dvInvDbt = 322 AND dv.dvUpl = 209;

INSERT INTO test_sudz_sm.cmm (cmmDv, cmmGr, cmmKind, cmmText)
SELECT dv.dvKey, 210, N'mery', N'111 снова целый 36000 (слияние долей)'
FROM test_sudz_sm.DbtValue AS dv
INNER JOIN test_sudz_sm.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
WHERE idd.iddDbt = 111 AND dv.dvUpl = 210;

INSERT INTO test_sudz_sm.cnInvGr (cnigDv, cnigCmmGr, cnigGrName)
SELECT dv.dvKey, 210, 1
FROM test_sudz_sm.DbtValue AS dv
INNER JOIN test_sudz_sm.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
WHERE idd.iddDbt = 111 AND dv.dvUpl = 210;

COMMIT TRAN;

INSERT INTO test_sudz_sm.lab_event (evScript, evOk, evMsg)
VALUES (N'12_MERGEBACK_111', 1, N'210: снова 36000@311; 209: 2×18000 + 2 cmm');
GO
