-- =============================================================================
-- Seed cmm/gr на dvKey. Группа 201 = «старые» к срезу 201; 202 = раунд крайней QI.
-- =============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

DELETE FROM test_sudz_sm.cnInvGr;
DELETE FROM test_sudz_sm.cmm;
DELETE FROM test_sudz_sm.cnInvGrNm;
DELETE FROM test_sudz_sm.cmmGr;
GO

INSERT INTO test_sudz_sm.cmmGr (cmmgKey, cmmgUpl, cmmgName) VALUES
 (201, 201, N'старые · свод 201'),
 (202, 202, N'новые · свод 202');

INSERT INTO test_sudz_sm.cnInvGrNm (cnignKey, cnignName) VALUES
 (1, N'Рассмотреть углубленно в сентябре');

-- 111 @201: одна Value → один текст и одно вхождение в группу
INSERT INTO test_sudz_sm.cmm (cmmDv, cmmGr, cmmKind, cmmText)
SELECT dv.dvKey, 201, N'mery', N'111 ещё целый 36000 (до split)'
FROM test_sudz_sm.DbtValue AS dv
INNER JOIN test_sudz_sm.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
WHERE idd.iddDbt = 111 AND dv.dvUpl = 201;

INSERT INTO test_sudz_sm.cnInvGr (cnigDv, cnigCmmGr, cnigGrName)
SELECT dv.dvKey, 201, 1
FROM test_sudz_sm.DbtValue AS dv
INNER JOIN test_sudz_sm.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
WHERE idd.iddDbt = 111 AND dv.dvUpl = 201;

-- 111 @202: две доли → два текста; группа только на первой доле (слот 322)
INSERT INTO test_sudz_sm.cmm (cmmDv, cmmGr, cmmKind, cmmText)
SELECT dv.dvKey, 202, N'mery',
       CASE dv.dvInvDbt
           WHEN 322 THEN N'111 доля A 18000 (CN-301)'
           WHEN 323 THEN N'111 доля B 18000 (CN-302)'
       END
FROM test_sudz_sm.DbtValue AS dv
INNER JOIN test_sudz_sm.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
WHERE idd.iddDbt = 111 AND dv.dvUpl = 202;

INSERT INTO test_sudz_sm.cnInvGr (cnigDv, cnigCmmGr, cnigGrName)
SELECT dv.dvKey, 202, 1
FROM test_sudz_sm.DbtValue AS dv
WHERE dv.dvInvDbt = 322 AND dv.dvUpl = 202;

-- 112 после merge: две Value на каждом срезе — по тексту на каждую (как бы от 112 и 113)
INSERT INTO test_sudz_sm.cmm (cmmDv, cmmGr, cmmKind, cmmText)
SELECT dv.dvKey, 201, N'mery',
       CASE dv.dvInvDbt
           WHEN 401 THEN N'112 исходные 10000'
           WHEN 402 THEN N'113 исходные 20000 (после merge на каноне 112)'
       END
FROM test_sudz_sm.DbtValue AS dv
INNER JOIN test_sudz_sm.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
WHERE idd.iddDbt = 112 AND dv.dvUpl = 201;

INSERT INTO test_sudz_sm.cnInvGr (cnigDv, cnigCmmGr, cnigGrName)
SELECT dv.dvKey, 201, 1
FROM test_sudz_sm.DbtValue AS dv
INNER JOIN test_sudz_sm.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
WHERE idd.iddDbt = 112 AND dv.dvUpl = 201;

INSERT INTO test_sudz_sm.lab_event (evScript, evOk, evMsg)
VALUES (N'10_SEED_CMM', 1, N'cmm+cnInvGr на dvKey: 111 и 112');
GO
