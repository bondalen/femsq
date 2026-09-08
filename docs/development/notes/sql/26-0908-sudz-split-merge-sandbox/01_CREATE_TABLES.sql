-- =============================================================================
-- Ядро как sudz M2 + запреты S16 / Consistency п.4–5.
-- Словари — заглушки схемы (не ags): эксперимент не зависит от живых СФ.
-- =============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF SCHEMA_ID(N'test_sudz_sm') IS NULL
BEGIN
    RAISERROR(N'Сначала 00_CREATE_SCHEMA.sql', 16, 1);
    RETURN;
END
GO

/* снести объекты в порядке FK */
IF OBJECT_ID(N'test_sudz_sm.DbtValue', N'U') IS NOT NULL DROP TABLE test_sudz_sm.DbtValue;
IF OBJECT_ID(N'test_sudz_sm.invDbtDbtVar', N'U') IS NOT NULL DROP TABLE test_sudz_sm.invDbtDbtVar;
IF OBJECT_ID(N'test_sudz_sm.invDbtDbt', N'U') IS NOT NULL DROP TABLE test_sudz_sm.invDbtDbt;
IF OBJECT_ID(N'test_sudz_sm.invDbtVar', N'U') IS NOT NULL DROP TABLE test_sudz_sm.invDbtVar;
IF OBJECT_ID(N'test_sudz_sm.invDbt', N'U') IS NOT NULL DROP TABLE test_sudz_sm.invDbt;
IF OBJECT_ID(N'test_sudz_sm.Dbt', N'U') IS NOT NULL DROP TABLE test_sudz_sm.Dbt;
IF OBJECT_ID(N'test_sudz_sm.cnInv', N'U') IS NOT NULL DROP TABLE test_sudz_sm.cnInv;
IF OBJECT_ID(N'test_sudz_sm.invNum', N'U') IS NOT NULL DROP TABLE test_sudz_sm.invNum;
IF OBJECT_ID(N'test_sudz_sm.cnNum', N'U') IS NOT NULL DROP TABLE test_sudz_sm.cnNum;
IF OBJECT_ID(N'test_sudz_sm.cn_s_org', N'U') IS NOT NULL DROP TABLE test_sudz_sm.cn_s_org;
IF OBJECT_ID(N'test_sudz_sm.accnt', N'U') IS NOT NULL DROP TABLE test_sudz_sm.accnt;
IF OBJECT_ID(N'test_sudz_sm.inv', N'U') IS NOT NULL DROP TABLE test_sudz_sm.inv;
IF OBJECT_ID(N'test_sudz_sm.cn', N'U') IS NOT NULL DROP TABLE test_sudz_sm.cn;
IF OBJECT_ID(N'test_sudz_sm.upl', N'U') IS NOT NULL DROP TABLE test_sudz_sm.upl;
IF OBJECT_ID(N'test_sudz_sm.lab_event', N'U') IS NOT NULL DROP TABLE test_sudz_sm.lab_event;
IF OBJECT_ID(N'test_sudz_sm.lab_state', N'U') IS NOT NULL DROP TABLE test_sudz_sm.lab_state;
GO

CREATE TABLE test_sudz_sm.lab_state
(
    labKey   int           NOT NULL CONSTRAINT PK_sm_lab_state PRIMARY KEY,
    labMode  nvarchar(20)  NOT NULL,
    labNote  nvarchar(400) NULL
);

CREATE TABLE test_sudz_sm.lab_event
(
    evKey     int            NOT NULL IDENTITY(1, 1)
        CONSTRAINT PK_sm_lab_event PRIMARY KEY,
    evAt      datetime       NOT NULL CONSTRAINT DF_sm_lab_event_at DEFAULT (getdate()),
    evScript  nvarchar(40)   NOT NULL,
    evOk      bit            NOT NULL,
    evMsg     nvarchar(500)  NOT NULL
);

CREATE TABLE test_sudz_sm.upl
(
    upl_key          int            NOT NULL,
    uplStatusOnDate  date           NOT NULL,
    upl_name         nvarchar(255)  NOT NULL,
    CONSTRAINT PK_sm_upl PRIMARY KEY (upl_key)
);

CREATE TABLE test_sudz_sm.cn
(
    cn_key int NOT NULL,
    CONSTRAINT PK_sm_cn PRIMARY KEY (cn_key)
);

CREATE TABLE test_sudz_sm.inv
(
    iKey int NOT NULL,
    iNum nvarchar(50) NOT NULL,
    CONSTRAINT PK_sm_inv PRIMARY KEY (iKey)
);

CREATE TABLE test_sudz_sm.cnNum
(
    cnnKey int NOT NULL,
    cnnCn  int NOT NULL,
    cnnNum nvarchar(50) NOT NULL,
    CONSTRAINT PK_sm_cnNum PRIMARY KEY (cnnKey),
    CONSTRAINT FK_sm_cnNum_cn FOREIGN KEY (cnnCn) REFERENCES test_sudz_sm.cn (cn_key)
);

CREATE TABLE test_sudz_sm.invNum
(
    inKey int NOT NULL,
    inInv int NOT NULL,
    inNum nvarchar(50) NOT NULL,
    CONSTRAINT PK_sm_invNum PRIMARY KEY (inKey),
    CONSTRAINT FK_sm_invNum_inv FOREIGN KEY (inInv) REFERENCES test_sudz_sm.inv (iKey)
);

CREATE TABLE test_sudz_sm.cnInv
(
    ciKey int NOT NULL IDENTITY(1, 1),
    ciCn  int NOT NULL,
    ciInv int NOT NULL,
    CONSTRAINT PK_sm_cnInv PRIMARY KEY (ciKey),
    CONSTRAINT UX_sm_cnInv UNIQUE (ciCn, ciInv),
    CONSTRAINT FK_sm_cnInv_cn FOREIGN KEY (ciCn) REFERENCES test_sudz_sm.cn (cn_key),
    CONSTRAINT FK_sm_cnInv_inv FOREIGN KEY (ciInv) REFERENCES test_sudz_sm.inv (iKey)
);

CREATE TABLE test_sudz_sm.accnt
(
    account_key int NOT NULL,
    CONSTRAINT PK_sm_accnt PRIMARY KEY (account_key)
);

CREATE TABLE test_sudz_sm.cn_s_org
(
    cn_s_org_key int NOT NULL,
    CONSTRAINT PK_sm_cso PRIMARY KEY (cn_s_org_key)
);

CREATE TABLE test_sudz_sm.Dbt
(
    dbtKey         int            NOT NULL IDENTITY(1, 1),
    dbtNote        nvarchar(255)  NULL,
    dbtTimeOfEntry datetime       NOT NULL CONSTRAINT DF_sm_Dbt_toe DEFAULT (getdate()),
    CONSTRAINT PK_sm_Dbt PRIMARY KEY (dbtKey)
);

CREATE TABLE test_sudz_sm.invDbt
(
    idKey         int            NOT NULL IDENTITY(1, 1),
    idInv         int            NOT NULL,
    idNum         tinyint        NOT NULL CONSTRAINT DF_sm_invDbt_idNum DEFAULT ((1)),
    idNote        nvarchar(255)  NULL,
    idTimeOfEntry datetime       NOT NULL CONSTRAINT DF_sm_invDbt_toe DEFAULT (getdate()),
    CONSTRAINT PK_sm_invDbt PRIMARY KEY (idKey),
    CONSTRAINT UX_sm_invDbt_InvNum UNIQUE (idInv, idNum),
    CONSTRAINT FK_sm_invDbt_inv FOREIGN KEY (idInv) REFERENCES test_sudz_sm.inv (iKey)
);

CREATE TABLE test_sudz_sm.invDbtDbt
(
    iddKey         int      NOT NULL IDENTITY(1, 1),
    iddInv         int      NOT NULL,
    iddDbt         int      NOT NULL,
    iddInvDbt      int      NOT NULL,
    iddTimeOfEntry datetime NOT NULL CONSTRAINT DF_sm_idd_toe DEFAULT (getdate()),
    CONSTRAINT PK_sm_idd PRIMARY KEY (iddKey),
    CONSTRAINT UX_sm_idd_InvDbt UNIQUE (iddInv, iddDbt),
    CONSTRAINT UX_sm_idd_Slot UNIQUE (iddInvDbt),
    CONSTRAINT FK_sm_idd_inv FOREIGN KEY (iddInv) REFERENCES test_sudz_sm.inv (iKey),
    CONSTRAINT FK_sm_idd_Dbt FOREIGN KEY (iddDbt) REFERENCES test_sudz_sm.Dbt (dbtKey),
    CONSTRAINT FK_sm_idd_slot FOREIGN KEY (iddInvDbt) REFERENCES test_sudz_sm.invDbt (idKey)
);

CREATE TABLE test_sudz_sm.invDbtVar
(
    idvvKey         int      NOT NULL IDENTITY(1, 1),
    idvvCnNum       int      NOT NULL,
    idvvInvNum      int      NOT NULL,
    idvvAccnt       int      NOT NULL,
    idvvCn_s_org    int      NOT NULL,
    idvvTimeOfEntry datetime NOT NULL CONSTRAINT DF_sm_idvv_toe DEFAULT (getdate()),
    CONSTRAINT PK_sm_idvv PRIMARY KEY (idvvKey),
    CONSTRAINT UX_sm_idvv_Ctx UNIQUE (idvvCnNum, idvvInvNum, idvvAccnt, idvvCn_s_org),
    CONSTRAINT FK_sm_idvv_cnn FOREIGN KEY (idvvCnNum) REFERENCES test_sudz_sm.cnNum (cnnKey),
    CONSTRAINT FK_sm_idvv_in FOREIGN KEY (idvvInvNum) REFERENCES test_sudz_sm.invNum (inKey),
    CONSTRAINT FK_sm_idvv_acc FOREIGN KEY (idvvAccnt) REFERENCES test_sudz_sm.accnt (account_key),
    CONSTRAINT FK_sm_idvv_cso FOREIGN KEY (idvvCn_s_org) REFERENCES test_sudz_sm.cn_s_org (cn_s_org_key)
);

CREATE TABLE test_sudz_sm.invDbtDbtVar
(
    iddvKey         int      NOT NULL IDENTITY(1, 1),
    iddvInvDbt      int      NOT NULL,
    iddvInvDbtVar   int      NOT NULL,
    iddvTimeOfEntry datetime NOT NULL CONSTRAINT DF_sm_iddv_toe DEFAULT (getdate()),
    CONSTRAINT PK_sm_iddv PRIMARY KEY (iddvKey),
    CONSTRAINT UX_sm_iddv_Pair UNIQUE (iddvInvDbt, iddvInvDbtVar),
    CONSTRAINT FK_sm_iddv_slot FOREIGN KEY (iddvInvDbt) REFERENCES test_sudz_sm.invDbt (idKey),
    CONSTRAINT FK_sm_iddv_var FOREIGN KEY (iddvInvDbtVar) REFERENCES test_sudz_sm.invDbtVar (idvvKey)
);

CREATE TABLE test_sudz_sm.DbtValue
(
    dvKey          int      NOT NULL IDENTITY(1, 1),
    dvInvDbt       int      NOT NULL,
    dvInvDbtVar    int      NOT NULL,
    dvUpl          int      NOT NULL,
    dvTtl          money    NOT NULL,
    dvOverd        money    NOT NULL,
    dvDateStart    date     NULL,
    dvDateMaturity date     NULL,
    dvDocBase      nvarchar(80) NULL,
    dvTimeOfEntry  datetime NOT NULL CONSTRAINT DF_sm_dv_toe DEFAULT (getdate()),
    CONSTRAINT PK_sm_dv PRIMARY KEY (dvKey),
    CONSTRAINT UX_sm_dv_SlotUpl UNIQUE (dvInvDbt, dvUpl),
    CONSTRAINT FK_sm_dv_slot FOREIGN KEY (dvInvDbt) REFERENCES test_sudz_sm.invDbt (idKey),
    CONSTRAINT FK_sm_dv_var FOREIGN KEY (dvInvDbtVar) REFERENCES test_sudz_sm.invDbtVar (idvvKey),
    CONSTRAINT FK_sm_dv_upl FOREIGN KEY (dvUpl) REFERENCES test_sudz_sm.upl (upl_key)
);
GO

CREATE TRIGGER test_sudz_sm.trg_invDbtDbt_InvMatchesSlot
ON test_sudz_sm.invDbtDbt
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN test_sudz_sm.invDbt AS s ON s.idKey = i.iddInvDbt
        WHERE s.idInv <> i.iddInv
    )
    BEGIN
        RAISERROR(N'invDbtDbt: iddInv must equal invDbt.idInv', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

CREATE TRIGGER test_sudz_sm.trg_DbtValue_Consistency
ON test_sudz_sm.DbtValue
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN test_sudz_sm.invDbt AS slot ON slot.idKey = i.dvInvDbt
        INNER JOIN test_sudz_sm.invDbtVar AS v ON v.idvvKey = i.dvInvDbtVar
        INNER JOIN test_sudz_sm.invNum AS n ON n.inKey = v.idvvInvNum
        WHERE slot.idInv <> n.inInv
    )
    BEGIN
        RAISERROR(N'DbtValue: invDbt.idInv must equal invNum.inInv', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        WHERE NOT EXISTS (
            SELECT 1
            FROM test_sudz_sm.invDbtDbtVar AS bv
            WHERE bv.iddvInvDbt = i.dvInvDbt
              AND bv.iddvInvDbtVar = i.dvInvDbtVar
        )
    )
    BEGIN
        RAISERROR(N'DbtValue: missing invDbtDbtVar', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- п.4 sibling same-ttl (как sudz)
    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN test_sudz_sm.invDbt AS slot ON slot.idKey = i.dvInvDbt
        INNER JOIN test_sudz_sm.invDbt AS sib ON sib.idInv = slot.idInv AND sib.idKey <> slot.idKey
        INNER JOIN test_sudz_sm.DbtValue AS dv2
            ON dv2.dvInvDbt = sib.idKey
           AND dv2.dvUpl = i.dvUpl
           AND dv2.dvKey <> i.dvKey
        WHERE ABS(CAST(i.dvTtl AS decimal(19, 4)) - CAST(dv2.dvTtl AS decimal(19, 4)))
              <= CAST(0.01 AS decimal(19, 4))
    )
    BEGIN
        RAISERROR(N'DbtValue: sibling slot already has same ttl on this upl', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- п.5 one Value per Dbt@upl
    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        INNER JOIN test_sudz_sm.invDbtDbt AS idd ON idd.iddInvDbt = i.dvInvDbt
        INNER JOIN test_sudz_sm.DbtValue AS dv2
            ON dv2.dvUpl = i.dvUpl
           AND dv2.dvKey <> i.dvKey
        INNER JOIN test_sudz_sm.invDbtDbt AS idd2 ON idd2.iddInvDbt = dv2.dvInvDbt
        WHERE idd2.iddDbt = idd.iddDbt
    )
    BEGIN
        RAISERROR(N'DbtValue: another slot already has Value for this Dbt on upl', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

INSERT INTO test_sudz_sm.lab_state (labKey, labMode, labNote)
VALUES (1, N'strict', N'S16 UNIQUE(inv,dbt) + Consistency п.4–5 включены');
GO
