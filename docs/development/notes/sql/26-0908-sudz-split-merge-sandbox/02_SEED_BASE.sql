-- =============================================================================
-- База: 10 выгрузок (201–210) × 10 долгов (111–120). Режим strict.
-- 111 — кандидат split (пока 1 слот / 36 000 на всех срезах).
-- 112 / 113 — кандидаты merge (разные inv, 10 000 и 20 000).
-- 116 — L* (осцилляция СФ 316↔317, одна Value на upl).
-- =============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

DELETE FROM test_sudz_sm.DbtValue;
DELETE FROM test_sudz_sm.invDbtDbtVar;
DELETE FROM test_sudz_sm.invDbtDbt;
DELETE FROM test_sudz_sm.invDbtVar;
DELETE FROM test_sudz_sm.invDbt;
DELETE FROM test_sudz_sm.Dbt;
DELETE FROM test_sudz_sm.cnInv;
DELETE FROM test_sudz_sm.invNum;
DELETE FROM test_sudz_sm.cnNum;
DELETE FROM test_sudz_sm.cn_s_org;
DELETE FROM test_sudz_sm.accnt;
DELETE FROM test_sudz_sm.inv;
DELETE FROM test_sudz_sm.cn;
DELETE FROM test_sudz_sm.upl;
DELETE FROM test_sudz_sm.lab_event;
GO

INSERT INTO test_sudz_sm.upl (upl_key, uplStatusOnDate, upl_name) VALUES
 (201, '2024-12-31', N'sm Q4.2024'),
 (202, '2025-03-31', N'sm Q1.2025'),
 (203, '2025-06-30', N'sm Q2.2025'),
 (204, '2025-09-30', N'sm Q3.2025'),
 (205, '2025-12-31', N'sm Q4.2025'),
 (206, '2026-03-31', N'sm Q1.2026'),
 (207, '2026-06-30', N'sm Q2.2026'),
 (208, '2026-09-30', N'sm Q3.2026'),
 (209, '2026-12-31', N'sm Q4.2026'),
 (210, '2027-03-31', N'sm Q1.2027');

INSERT INTO test_sudz_sm.cn (cn_key)
SELECT n FROM (VALUES (300),(301),(302),(303),(304),(305),(306),(307),(308),(309),(316),(317)) x(n);

INSERT INTO test_sudz_sm.inv (iKey, iNum)
SELECT n, N'SF-' + CAST(n AS nvarchar(10))
FROM (VALUES (300),(301),(302),(303),(304),(305),(306),(307),(308),(309),(316),(317)) x(n);

INSERT INTO test_sudz_sm.cnNum (cnnKey, cnnCn, cnnNum)
SELECT n, n, N'CN-' + CAST(n AS nvarchar(10))
FROM (VALUES (300),(301),(302),(303),(304),(305),(306),(307),(308),(309),(316),(317)) x(n);

INSERT INTO test_sudz_sm.invNum (inKey, inInv, inNum)
SELECT n, n, N'SF-' + CAST(n AS nvarchar(10))
FROM (VALUES (300),(301),(302),(303),(304),(305),(306),(307),(308),(309),(316),(317)) x(n);

INSERT INTO test_sudz_sm.cnInv (ciCn, ciInv)
SELECT n, n
FROM (VALUES (300),(301),(302),(303),(304),(305),(306),(307),(308),(309),(316),(317)) x(n);

-- один СФ 300 — два договора (как 32-425 / 32-426 на А45-19974)
INSERT INTO test_sudz_sm.cnInv (ciCn, ciInv) VALUES (301, 300), (302, 300);

INSERT INTO test_sudz_sm.accnt (account_key) VALUES (24);
INSERT INTO test_sudz_sm.cn_s_org (cn_s_org_key)
SELECT n FROM (VALUES (300),(301),(302),(303),(304),(305),(306),(307),(308),(309),(316),(317)) x(n);
GO

SET IDENTITY_INSERT test_sudz_sm.Dbt ON;
INSERT INTO test_sudz_sm.Dbt (dbtKey, dbtNote) VALUES
 (111, N'split-lab: 36000 → 2×18000 (модель владельца)'),
 (112, N'merge-A: 10000 на inv 301'),
 (113, N'merge-B: 20000 на inv 302'),
 (114, N'1:1 stable 5000'),
 (115, N'1:1 paydown 10000…1000 (контраст «погашено»)'),
 (116, N'L*/P1: осцилляция inv 316↔317 сумма 4000'),
 (117, N'1:1 700'),
 (118, N'1:1 800'),
 (119, N'1:1 900'),
 (120, N'1:1 1000');
SET IDENTITY_INSERT test_sudz_sm.Dbt OFF;

SET IDENTITY_INSERT test_sudz_sm.invDbt ON;
INSERT INTO test_sudz_sm.invDbt (idKey, idInv, idNum, idNote) VALUES
 (311, 300, 1, N'111 слот до split'),
 (401, 301, 1, N'112'),
 (402, 302, 1, N'113'),
 (403, 303, 1, N'114'),
 (404, 304, 1, N'115'),
 (405, 305, 1, N'запас'),
 (406, 306, 1, N'117'),
 (407, 307, 1, N'118'),
 (408, 308, 1, N'119'),
 (409, 309, 1, N'120'),
 (416, 316, 1, N'116 СФ-316'),
 (417, 317, 1, N'116 СФ-317');
SET IDENTITY_INSERT test_sudz_sm.invDbt OFF;

INSERT INTO test_sudz_sm.invDbtDbt (iddInv, iddDbt, iddInvDbt) VALUES
 (300, 111, 311),
 (301, 112, 401),
 (302, 113, 402),
 (303, 114, 403),
 (304, 115, 404),
 (306, 117, 406),
 (307, 118, 407),
 (308, 119, 408),
 (309, 120, 409),
 (316, 116, 416),
 (317, 116, 417);

SET IDENTITY_INSERT test_sudz_sm.invDbtVar ON;
INSERT INTO test_sudz_sm.invDbtVar (idvvKey, idvvCnNum, idvvInvNum, idvvAccnt, idvvCn_s_org) VALUES
 (411, 300, 300, 24, 300),
 (501, 301, 301, 24, 301),
 (502, 302, 302, 24, 302),
 (503, 303, 303, 24, 303),
 (504, 304, 304, 24, 304),
 (506, 306, 306, 24, 306),
 (507, 307, 307, 24, 307),
 (508, 308, 308, 24, 308),
 (509, 309, 309, 24, 309),
 (516, 316, 316, 24, 316),
 (517, 317, 317, 24, 317);
SET IDENTITY_INSERT test_sudz_sm.invDbtVar OFF;

INSERT INTO test_sudz_sm.invDbtDbtVar (iddvInvDbt, iddvInvDbtVar) VALUES
 (311, 411),
 (401, 501),
 (402, 502),
 (403, 503),
 (404, 504),
 (406, 506),
 (407, 507),
 (408, 508),
 (409, 509),
 (416, 516),
 (417, 517);
GO

DECLARE @u int;
SET @u = 201;
WHILE @u <= 210
BEGIN
    INSERT INTO test_sudz_sm.DbtValue
        (dvInvDbt, dvInvDbtVar, dvUpl, dvTtl, dvOverd, dvDocBase)
    VALUES
        (311, 411, @u, 36000, 36000, N'111'),
        (401, 501, @u, 10000, 10000, N'112'),
        (402, 502, @u, 20000, 20000, N'113'),
        (403, 503, @u, 5000,  5000,  N'114'),
        (404, 504, @u, 10000 - 1000 * (@u - 201), 10000 - 1000 * (@u - 201), N'115'),
        (406, 506, @u, 700,   700,   N'117'),
        (407, 507, @u, 800,   800,   N'118'),
        (408, 508, @u, 900,   900,   N'119'),
        (409, 509, @u, 1000,  1000,  N'120');

    IF (@u % 2) = 1
        INSERT INTO test_sudz_sm.DbtValue
            (dvInvDbt, dvInvDbtVar, dvUpl, dvTtl, dvOverd, dvDocBase)
        VALUES (416, 516, @u, 4000, 4000, N'116-316');
    ELSE
        INSERT INTO test_sudz_sm.DbtValue
            (dvInvDbt, dvInvDbtVar, dvUpl, dvTtl, dvOverd, dvDocBase)
        VALUES (417, 517, @u, 4000, 4000, N'116-317');

    SET @u = @u + 1;
END
GO

INSERT INTO test_sudz_sm.lab_event (evScript, evOk, evMsg)
VALUES (N'02_SEED', 1, N'10 upl × 10 Dbt, mode=strict');

UPDATE test_sudz_sm.lab_state
SET labMode = N'strict', labNote = N'база 10×10 загружена'
WHERE labKey = 1;
GO
