-- 01_CREATE_DbtUplCstAgExp.sql — экспериментальная привязка стройки за период
-- План: chat-plan-26-0921-dbt-upl-cst-ag-exp.md §2
-- Канон sudz.DbtUplCstAg НЕ изменяется.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'sudz.DbtUplCstAgExp', N'U') IS NOT NULL
    DROP TABLE sudz.DbtUplCstAgExp;
GO

CREATE TABLE sudz.DbtUplCstAgExp
(
    duexKey      int NOT NULL IDENTITY(1, 1),
    duexDbt      int NOT NULL,
    duexUpl      int NOT NULL,
    duexRule     tinyint NOT NULL,          -- 11=1.1, 12=1.2*, 13=1.3*, 14=1.4
    duexCstAgPn  int NULL,                 -- только при однозначном выборе
    duexCode     nvarchar(200) NOT NULL,   -- отображаемый код / склейка / 1.4-текст
    duexName     nvarchar(100) NOT NULL,   -- на эксперимент: метка правила
    duexDetail   nvarchar(500) NULL,       -- опц. аудит
    CONSTRAINT PK_DbtUplCstAgExp PRIMARY KEY CLUSTERED (duexKey),
    CONSTRAINT UX_DbtUplCstAgExp UNIQUE (duexDbt, duexUpl),
    CONSTRAINT FK_DbtUplCstAgExp_Dbt FOREIGN KEY (duexDbt)
        REFERENCES sudz.Dbt (dbtKey),
    CONSTRAINT FK_DbtUplCstAgExp_Upl FOREIGN KEY (duexUpl)
        REFERENCES sudz.cn_inv_dbt_upl (upl_key),
    CONSTRAINT FK_DbtUplCstAgExp_CstAgPn FOREIGN KEY (duexCstAgPn)
        REFERENCES ags.cstAgPn (cstapKey),
    CONSTRAINT CK_DbtUplCstAgExp_Rule CHECK (duexRule IN (11, 12, 13, 14))
);
GO

EXEC sys.sp_addextendedproperty
  @name = N'MS_Description',
  @value = N'Эксперимент резолва стройки за период (каскад 1.1–1.4); не канон DbtUplCstAg',
  @level0type = N'SCHEMA', @level0name = N'sudz',
  @level1type = N'TABLE',  @level1name = N'DbtUplCstAgExp';
GO
