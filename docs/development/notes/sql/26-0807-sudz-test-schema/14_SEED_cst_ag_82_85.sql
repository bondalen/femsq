-- =============================================================================
-- S42c/e: seed стройки/агента и кураторов для долгов 82/85
-- DEV only. Эталон Excel: ags_Yr_DbtChangesRslt_26-0505.xlsx стр. 82/85
-- cstapKey 1835 = 051-2001061; 2016 = 051-2000707; ogaKey 1 = Газпром инвест
-- =============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

---------------------------------------------------------------------
-- Периодная привязка стройки (замена fnCiasDbtUplCst на sandbox-upl)
---------------------------------------------------------------------
IF OBJECT_ID(N'test_sudz.DbtUplCstAg', N'U') IS NULL
BEGIN
    CREATE TABLE test_sudz.DbtUplCstAg
    (
        ducaKey      int NOT NULL IDENTITY(1, 1),
        ducaDbt      int NOT NULL,
        ducaUpl      int NOT NULL,
        ducaCstAgPn  int NOT NULL,
        CONSTRAINT PK_DbtUplCstAg PRIMARY KEY CLUSTERED (ducaKey),
        CONSTRAINT UX_DbtUplCstAg UNIQUE (ducaDbt, ducaUpl),
        CONSTRAINT FK_DbtUplCstAg_Dbt FOREIGN KEY (ducaDbt)
            REFERENCES test_sudz.Dbt (dbtKey),
        CONSTRAINT FK_DbtUplCstAg_Upl FOREIGN KEY (ducaUpl)
            REFERENCES test_sudz.cn_inv_dbt_upl (upl_key),
        CONSTRAINT FK_DbtUplCstAg_CstAgPn FOREIGN KEY (ducaCstAgPn)
            REFERENCES ags.cstAgPn (cstapKey)
    );
END
GO

BEGIN TRAN;

DELETE FROM test_sudz.DbtUplCstAg WHERE ducaDbt IN (82, 85);

INSERT INTO test_sudz.DbtUplCstAg (ducaDbt, ducaUpl, ducaCstAgPn) VALUES
 (82, 901, 1835), (82, 902, 1835), (82, 903, 1835),
 (85, 901, 2016), (85, 902, 2016), (85, 903, 2016);

DELETE FROM test_sudz.cnInvCmmCst WHERE ciccInvAccnt IN (82, 85);
DELETE FROM test_sudz.cnInvCmmAg  WHERE cicaInvAccnt IN (82, 85);

INSERT INTO test_sudz.cnInvCmmCst (ciccCmmGr, ciccType, ciccCstAgPn, ciccInvAccnt) VALUES
 (903, 2, 1835, 82),
 (903, 2, 2016, 85);

INSERT INTO test_sudz.cnInvCmmAg (cicaCmmGr, cicaType, cicaOgAg, cicaInvAccnt) VALUES
 (903, 2, 1, 82),
 (903, 2, 1, 85);

DELETE FROM test_sudz.cnInvCmm
WHERE cnicInvAccnt IN (82, 85) AND cnicType = 8 AND cnicGroup = 903;

INSERT INTO test_sudz.cnInvCmm (cnicType, cnicGroup, cnicText, cnicInvAccnt) VALUES
 (8, 903, N'Сербул А.С.', 82),
 (8, 903, N'Дедова И.В', 85);

COMMIT TRAN;
GO

SELECT ducaDbt, ducaUpl, ducaCstAgPn FROM test_sudz.DbtUplCstAg ORDER BY 1, 2;
SELECT cnicInvAccnt, cnicType, LEFT(cnicText, 40) AS txt
FROM test_sudz.cnInvCmm WHERE cnicInvAccnt IN (82, 85) ORDER BY 1, 2;
GO
