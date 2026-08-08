-- =============================================================================
-- Зеркала комментариев / групп / года в sudz
-- FK на долг → sudz.Dbt (колонки *InvAccnt сохранены по имени ags-зеркала)
-- Справочники типов: cross-schema FK на ags.cnInvCmmTp / *N / yyyy
-- DEV only. Спецификация: 08-target-schema.md §3.4 (S40)
-- =============================================================================

SET NOCOUNT ON;

---------------------------------------------------------------------
-- cnInvCmmGr
---------------------------------------------------------------------
IF OBJECT_ID(N'sudz.cnInvCmmGr', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.cnInvCmmGr
    (
        cnicgKey   int            NOT NULL IDENTITY(1, 1),
        cnicgNmCs  nvarchar(266)  NULL,
        cnicgDate  date           NOT NULL,
        cnicgName  nvarchar(255)  NOT NULL,
        CONSTRAINT PK_cnInvCmmGr PRIMARY KEY CLUSTERED (cnicgKey)
    );
END
GO

---------------------------------------------------------------------
-- cnInvGrNm (sandbox; плюс тестовые имена сверх ags)
---------------------------------------------------------------------
IF OBJECT_ID(N'sudz.cnInvGrNm', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.cnInvGrNm
    (
        cnignKey   int            NOT NULL IDENTITY(1, 1),
        cnignName  nvarchar(255)  NOT NULL,
        CONSTRAINT PK_cnInvGrNm PRIMARY KEY CLUSTERED (cnignKey)
    );
END
GO

---------------------------------------------------------------------
-- cnInvCmm — текст; *InvAccnt → Dbt
---------------------------------------------------------------------
IF OBJECT_ID(N'sudz.cnInvCmm', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.cnInvCmm
    (
        cnicKey      int            NOT NULL IDENTITY(1, 1),
        cnicType     int            NOT NULL,
        cnicGroup    int            NOT NULL,
        cnicInv      int            NULL,
        cnicText     nvarchar(max)  NOT NULL,
        cnicInvAccnt int            NOT NULL,
        CONSTRAINT PK_cnInvCmm PRIMARY KEY CLUSTERED (cnicKey),
        CONSTRAINT FK_cnInvCmm_cnInvCmmGr FOREIGN KEY (cnicGroup)
            REFERENCES sudz.cnInvCmmGr (cnicgKey),
        CONSTRAINT FK_cnInvCmm_cnInvCmmTp FOREIGN KEY (cnicType)
            REFERENCES ags.cnInvCmmTp (cnictKey),
        CONSTRAINT FK_cnInvCmm_Dbt FOREIGN KEY (cnicInvAccnt)
            REFERENCES sudz.Dbt (dbtKey)
    );
END
GO

---------------------------------------------------------------------
-- cnInvCmmAg — без декл. FK на группу в ags; здесь объявляем
---------------------------------------------------------------------
IF OBJECT_ID(N'sudz.cnInvCmmAg', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.cnInvCmmAg
    (
        cicaKey      int NOT NULL IDENTITY(1, 1),
        cicaCmmGr    int NOT NULL,
        cicaType     int NOT NULL,
        cicaOgAg     int NOT NULL,
        cicaInvAccnt int NOT NULL,
        CONSTRAINT PK_cnInvCmmAg PRIMARY KEY CLUSTERED (cicaKey),
        CONSTRAINT FK_cnInvCmmAg_cnInvCmmGr FOREIGN KEY (cicaCmmGr)
            REFERENCES sudz.cnInvCmmGr (cnicgKey),
        CONSTRAINT FK_cnInvCmmAg_cnInvCmmAgN FOREIGN KEY (cicaType)
            REFERENCES ags.cnInvCmmAgN (cicanKey),
        CONSTRAINT FK_cnInvCmmAg_ogAg FOREIGN KEY (cicaOgAg)
            REFERENCES ags.ogAg (ogaKey),
        CONSTRAINT FK_cnInvCmmAg_Dbt FOREIGN KEY (cicaInvAccnt)
            REFERENCES sudz.Dbt (dbtKey)
    );
END
GO

---------------------------------------------------------------------
-- cnInvCmmCst
---------------------------------------------------------------------
IF OBJECT_ID(N'sudz.cnInvCmmCst', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.cnInvCmmCst
    (
        ciccKey      int NOT NULL IDENTITY(1, 1),
        ciccCmmGr    int NOT NULL,
        ciccType     int NOT NULL,
        ciccCstAgPn  int NOT NULL,
        ciccInvAccnt int NOT NULL,
        CONSTRAINT PK_cnInvCmmCst PRIMARY KEY CLUSTERED (ciccKey),
        CONSTRAINT FK_cnInvCmmCst_cnInvCmmGr FOREIGN KEY (ciccCmmGr)
            REFERENCES sudz.cnInvCmmGr (cnicgKey),
        CONSTRAINT FK_cnInvCmmCst_cnInvCmmCstN FOREIGN KEY (ciccType)
            REFERENCES ags.cnInvCmmCstN (ciccnKey),
        CONSTRAINT FK_cnInvCmmCst_cstAgPn FOREIGN KEY (ciccCstAgPn)
            REFERENCES ags.cstAgPn (cstapKey),
        CONSTRAINT FK_cnInvCmmCst_Dbt FOREIGN KEY (ciccInvAccnt)
            REFERENCES sudz.Dbt (dbtKey)
    );
END
GO

---------------------------------------------------------------------
-- cnInvCmmDt
---------------------------------------------------------------------
IF OBJECT_ID(N'sudz.cnInvCmmDt', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.cnInvCmmDt
    (
        cnicdKey      int  NOT NULL IDENTITY(1, 1),
        cnicdName     int  NOT NULL,
        cnicdCmmGr    int  NOT NULL,
        cnicdInv      int  NULL,
        cnicdDate     date NOT NULL,
        cnicdInvAccnt int  NOT NULL,
        CONSTRAINT PK_cnInvCmmDt PRIMARY KEY CLUSTERED (cnicdKey),
        CONSTRAINT FK_cnInvCmmDt_cnInvCmmGr FOREIGN KEY (cnicdCmmGr)
            REFERENCES sudz.cnInvCmmGr (cnicgKey),
        CONSTRAINT FK_cnInvCmmDt_cnInvCmmDtN FOREIGN KEY (cnicdName)
            REFERENCES ags.cnInvCmmDtN (cnicdnKey),
        CONSTRAINT FK_cnInvCmmDt_Dbt FOREIGN KEY (cnicdInvAccnt)
            REFERENCES sudz.Dbt (dbtKey)
    );
END
GO

---------------------------------------------------------------------
-- cnInvCmmFn
---------------------------------------------------------------------
IF OBJECT_ID(N'sudz.cnInvCmmFn', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.cnInvCmmFn
    (
        cnicfKey      int   NOT NULL IDENTITY(1, 1),
        cnicfName     int   NOT NULL,
        cnicfCmmGr    int   NOT NULL,
        cnicfInv      int   NULL,
        cnicfValue    money NOT NULL,
        cnicfInvAccnt int   NOT NULL,
        CONSTRAINT PK_cnInvCmmFn PRIMARY KEY CLUSTERED (cnicfKey),
        CONSTRAINT FK_cnInvCmmFn_cnInvCmmGr FOREIGN KEY (cnicfCmmGr)
            REFERENCES sudz.cnInvCmmGr (cnicgKey),
        CONSTRAINT FK_cnInvCmmFn_cnInvCmmFnN FOREIGN KEY (cnicfName)
            REFERENCES ags.cnInvCmmFnN (cnicfnKey),
        CONSTRAINT FK_cnInvCmmFn_Dbt FOREIGN KEY (cnicfInvAccnt)
            REFERENCES sudz.Dbt (dbtKey)
    );
END
GO

---------------------------------------------------------------------
-- cnInvGr — произвольные группы долгов внутри группы комментариев
---------------------------------------------------------------------
IF OBJECT_ID(N'sudz.cnInvGr', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.cnInvGr
    (
        cnigKey      int NOT NULL IDENTITY(1, 1),
        cnigInv      int NULL,
        cnigCmmGr    int NOT NULL,
        cnigGrName   int NOT NULL,
        cnigInvAccnt int NOT NULL,
        CONSTRAINT PK_cnInvGr PRIMARY KEY CLUSTERED (cnigKey),
        CONSTRAINT FK_cnInvGr_cnInvCmmGr FOREIGN KEY (cnigCmmGr)
            REFERENCES sudz.cnInvCmmGr (cnicgKey),
        CONSTRAINT FK_cnInvGr_cnInvGrNm FOREIGN KEY (cnigGrName)
            REFERENCES sudz.cnInvGrNm (cnignKey),
        CONSTRAINT FK_cnInvGr_Dbt FOREIGN KEY (cnigInvAccnt)
            REFERENCES sudz.Dbt (dbtKey)
    );
END
GO

---------------------------------------------------------------------
-- yr / yr_upl_p — годовой цикл на sandbox-выгрузках
---------------------------------------------------------------------
IF OBJECT_ID(N'sudz.yr', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.yr
    (
        yr_key         int            NOT NULL IDENTITY(1, 1),
        yr_variant     nvarchar(255)  NOT NULL,
        cn_inv_dbt_upl int            NOT NULL,
        yyyy           int            NOT NULL,
        yr_CmmGr       int            NULL,
        yr_Progress    nvarchar(max)  NULL,
        CONSTRAINT PK_yr PRIMARY KEY CLUSTERED (yr_key),
        CONSTRAINT FK_yr_cn_inv_dbt_upl FOREIGN KEY (cn_inv_dbt_upl)
            REFERENCES sudz.cn_inv_dbt_upl (upl_key),
        CONSTRAINT FK_yr_yyyy FOREIGN KEY (yyyy)
            REFERENCES ags.yyyy (yKey),
        CONSTRAINT FK_yr_cnInvCmmGr FOREIGN KEY (yr_CmmGr)
            REFERENCES sudz.cnInvCmmGr (cnicgKey)
    );
END
GO

IF OBJECT_ID(N'sudz.yr_upl_p', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.yr_upl_p
    (
        yr_upl_p_key   int NOT NULL IDENTITY(1, 1),
        yr_upl_p_yr    int NOT NULL,
        cn_inv_dbt_upl int NOT NULL,
        CONSTRAINT PK_yr_upl_p PRIMARY KEY CLUSTERED (yr_upl_p_key),
        CONSTRAINT UX_yr_upl_p_YrUpl UNIQUE (yr_upl_p_yr, cn_inv_dbt_upl),
        CONSTRAINT FK_yr_upl_p_yr FOREIGN KEY (yr_upl_p_yr)
            REFERENCES sudz.yr (yr_key),
        CONSTRAINT FK_yr_upl_p_cn_inv_dbt_upl FOREIGN KEY (cn_inv_dbt_upl)
            REFERENCES sudz.cn_inv_dbt_upl (upl_key)
    );
END
GO

SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = N'sudz'
  AND t.name IN (
      N'cnInvCmmGr', N'cnInvGrNm', N'cnInvCmm', N'cnInvCmmAg', N'cnInvCmmCst',
      N'cnInvCmmDt', N'cnInvCmmFn', N'cnInvGr', N'yr', N'yr_upl_p'
  )
ORDER BY t.name;
GO
