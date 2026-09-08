-- =============================================================================
-- Комментарии и cnInvGr на DbtValue (песочница). Не трогает sudz/ags.
-- =============================================================================

SET NOCOUNT ON;

IF OBJECT_ID(N'test_sudz_sm.cnInvGr', N'U') IS NOT NULL DROP TABLE test_sudz_sm.cnInvGr;
IF OBJECT_ID(N'test_sudz_sm.cmm', N'U') IS NOT NULL DROP TABLE test_sudz_sm.cmm;
IF OBJECT_ID(N'test_sudz_sm.cnInvGrNm', N'U') IS NOT NULL DROP TABLE test_sudz_sm.cnInvGrNm;
IF OBJECT_ID(N'test_sudz_sm.cmmGr', N'U') IS NOT NULL DROP TABLE test_sudz_sm.cmmGr;
GO

CREATE TABLE test_sudz_sm.cmmGr
(
    cmmgKey  int           NOT NULL,
    cmmgUpl  int           NOT NULL,
    cmmgName nvarchar(80)  NOT NULL,
    CONSTRAINT PK_sm_cmmGr PRIMARY KEY (cmmgKey),
    CONSTRAINT FK_sm_cmmGr_upl FOREIGN KEY (cmmgUpl) REFERENCES test_sudz_sm.upl (upl_key)
);

CREATE TABLE test_sudz_sm.cmm
(
    cmmKey   int            NOT NULL IDENTITY(1, 1),
    cmmDv    int            NOT NULL,
    cmmGr    int            NOT NULL,
    cmmKind  nvarchar(20)   NOT NULL,
    cmmText  nvarchar(400)  NOT NULL,
    CONSTRAINT PK_sm_cmm PRIMARY KEY (cmmKey),
    CONSTRAINT FK_sm_cmm_dv FOREIGN KEY (cmmDv) REFERENCES test_sudz_sm.DbtValue (dvKey),
    CONSTRAINT FK_sm_cmm_gr FOREIGN KEY (cmmGr) REFERENCES test_sudz_sm.cmmGr (cmmgKey)
);

CREATE TABLE test_sudz_sm.cnInvGrNm
(
    cnignKey  int           NOT NULL,
    cnignName nvarchar(120) NOT NULL,
    CONSTRAINT PK_sm_grnm PRIMARY KEY (cnignKey)
);

CREATE TABLE test_sudz_sm.cnInvGr
(
    cnigKey    int NOT NULL IDENTITY(1, 1),
    cnigDv     int NOT NULL,
    cnigCmmGr  int NOT NULL,
    cnigGrName int NOT NULL,
    CONSTRAINT PK_sm_cnig PRIMARY KEY (cnigKey),
    CONSTRAINT UX_sm_cnig UNIQUE (cnigDv, cnigCmmGr, cnigGrName),
    CONSTRAINT FK_sm_cnig_dv FOREIGN KEY (cnigDv) REFERENCES test_sudz_sm.DbtValue (dvKey),
    CONSTRAINT FK_sm_cnig_gr FOREIGN KEY (cnigCmmGr) REFERENCES test_sudz_sm.cmmGr (cmmgKey),
    CONSTRAINT FK_sm_cnig_nm FOREIGN KEY (cnigGrName) REFERENCES test_sudz_sm.cnInvGrNm (cnignKey)
);
GO
