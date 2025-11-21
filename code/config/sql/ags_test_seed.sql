-- Создание таблиц в тестовой схеме ags_test
-- Предназначено исключительно для окружения разработки / интеграционных тестов
-- Часть 1: Создание таблиц (без данных)

USE [FishEye];
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'ags_test')
BEGIN
    RAISERROR('Schema ags_test does not exist. Create it before running this script.', 16, 1);
    RETURN;
END;
GO

-- =============================================
-- Удаление внешних ключей и таблиц (в порядке зависимостей)
-- =============================================

-- Удаление внешних ключей
IF OBJECT_ID('FK_ags_test_ipgChRl_ipgCh', 'F') IS NOT NULL
    ALTER TABLE FishEye.ags_test.ipgChRl DROP CONSTRAINT FK_ags_test_ipgChRl_ipgCh;
GO

IF OBJECT_ID('FK_ags_test_ipgChRl_ipg', 'F') IS NOT NULL
    ALTER TABLE FishEye.ags_test.ipgChRl DROP CONSTRAINT FK_ags_test_ipgChRl_ipg;
GO

IF OBJECT_ID('FK_ags_test_ipgChRl_ipgUtPlGr', 'F') IS NOT NULL
    ALTER TABLE FishEye.ags_test.ipgChRl DROP CONSTRAINT FK_ags_test_ipgChRl_ipgUtPlGr;
GO

IF OBJECT_ID('FK_ags_test_ipgUtPlGr_ipg', 'F') IS NOT NULL
    ALTER TABLE FishEye.ags_test.ipgUtPlGr DROP CONSTRAINT FK_ags_test_ipgUtPlGr_ipg;
GO

IF OBJECT_ID('FK_ags_test_ipgCh_yyyy', 'F') IS NOT NULL
    ALTER TABLE FishEye.ags_test.ipgCh DROP CONSTRAINT FK_ags_test_ipgCh_yyyy;
GO

IF OBJECT_ID('FK_ags_test_ipg_stNet', 'F') IS NOT NULL
    ALTER TABLE FishEye.ags_test.ipg DROP CONSTRAINT FK_ags_test_ipg_stNet;
GO

IF OBJECT_ID('FK_ags_test_ipg_yyyy', 'F') IS NOT NULL
    ALTER TABLE FishEye.ags_test.ipg DROP CONSTRAINT FK_ags_test_ipg_yyyy;
GO

IF OBJECT_ID('FK_ags_test_ipg_og', 'F') IS NOT NULL
    ALTER TABLE FishEye.ags_test.ipg DROP CONSTRAINT FK_ags_test_ipg_og;
GO

IF OBJECT_ID('FK_ags_test_stNet_stType', 'F') IS NOT NULL
    ALTER TABLE FishEye.ags_test.stNet DROP CONSTRAINT FK_ags_test_stNet_stType;
GO

IF OBJECT_ID('FK_ogs_test_ogAg_og', 'F') IS NOT NULL
    ALTER TABLE FishEye.ags_test.ogAg DROP CONSTRAINT FK_ogs_test_ogAg_og;
GO

-- Зависимые таблицы (используем простой синтаксис с полным именем для замены в DaoIntegrationTestSupport)
IF OBJECT_ID('FishEye.ags_test.ipgChRl', 'U') IS NOT NULL
    DROP TABLE FishEye.ags_test.ipgChRl;
GO

IF OBJECT_ID('FishEye.ags_test.ipgUtPlGr', 'U') IS NOT NULL
    DROP TABLE FishEye.ags_test.ipgUtPlGr;
GO

IF OBJECT_ID('FishEye.ags_test.ipgCh', 'U') IS NOT NULL
    DROP TABLE FishEye.ags_test.ipgCh;
GO

IF OBJECT_ID('FishEye.ags_test.ipg', 'U') IS NOT NULL
    DROP TABLE FishEye.ags_test.ipg;
GO

IF OBJECT_ID('FishEye.ags_test.stNet', 'U') IS NOT NULL
    DROP TABLE FishEye.ags_test.stNet;
GO

IF OBJECT_ID('FishEye.ags_test.stType', 'U') IS NOT NULL
    DROP TABLE FishEye.ags_test.stType;
GO

IF OBJECT_ID('FishEye.ags_test.yyyy', 'U') IS NOT NULL
    DROP TABLE FishEye.ags_test.yyyy;
GO

IF OBJECT_ID('FishEye.ags_test.ogAg', 'U') IS NOT NULL
    DROP TABLE FishEye.ags_test.ogAg;
GO

IF OBJECT_ID('FishEye.ags_test.og', 'U') IS NOT NULL
    DROP TABLE FishEye.ags_test.og;
GO

-- =============================================
-- Создание таблиц (в порядке зависимостей)
-- =============================================

-- Таблица организаций
CREATE TABLE FishEye.ags_test.og (
    ogKey        INT IDENTITY(1,1) NOT NULL,
    ogNm         NVARCHAR(255) COLLATE Cyrillic_General_CI_AS NOT NULL,
    ogNmOf       NVARCHAR(255) COLLATE Cyrillic_General_CI_AS NOT NULL,
    ogNmFl       NVARCHAR(MAX) COLLATE Cyrillic_General_CI_AS NULL,
    ogTxt        NVARCHAR(MAX) COLLATE Cyrillic_General_CI_AS NULL,
    ogINN        FLOAT NULL,
    ogKPP        FLOAT NULL,
    ogOGRN       FLOAT NULL,
    ogOKPO       FLOAT NULL,
    ogOE         INT NULL,
    ogRgTaxType  CHAR(2) COLLATE Cyrillic_General_CI_AS NOT NULL,
    CONSTRAINT PK_ogs_test_og PRIMARY KEY (ogKey),
    CONSTRAINT UQ_ogs_test_og_TaxType UNIQUE (ogKey, ogRgTaxType)
);
GO

ALTER TABLE FishEye.ags_test.og WITH NOCHECK ADD CONSTRAINT CK_ogs_test_og_rgTaxType
CHECK (ogRgTaxType IN ('og', 'sd', 'ie'));
GO

-- Таблица организаций-агентов
CREATE TABLE FishEye.ags_test.ogAg (
    ogaKey    INT IDENTITY(1,1) NOT NULL,
    ogaCode   NVARCHAR(255) COLLATE Cyrillic_General_CI_AS NOT NULL,
    ogaOg     INT NOT NULL,
    ogaOidOld UNIQUEIDENTIFIER NULL,
    CONSTRAINT PK_ogs_test_ogAg PRIMARY KEY (ogaKey)
);
GO

ALTER TABLE FishEye.ags_test.ogAg WITH CHECK ADD CONSTRAINT FK_ogs_test_ogAg_og
FOREIGN KEY (ogaOg) REFERENCES FishEye.ags_test.og (ogKey) ON DELETE CASCADE ON UPDATE CASCADE;
GO

-- Таблица типов структур (справочник)
CREATE TABLE FishEye.ags_test.stType (
    sttKey  INT NOT NULL,
    sttName NVARCHAR(30) COLLATE Cyrillic_General_CI_AS NULL,
    CONSTRAINT PK_ags_test_stType PRIMARY KEY (sttKey)
);
GO

-- Таблица годов (справочник)
CREATE TABLE FishEye.ags_test.yyyy (
    yKey  INT IDENTITY(1,1) NOT NULL,
    yyyy  INT NOT NULL,
    CONSTRAINT PK_ags_test_yyyy PRIMARY KEY (yKey)
);
GO

-- Таблица структур сетей
CREATE TABLE FishEye.ags_test.stNet (
    stnKey  INT IDENTITY(1,1) NOT NULL,
    stnType INT NOT NULL,
    stnName NVARCHAR(255) COLLATE Cyrillic_General_CI_AS NOT NULL,
    stnRoot INT NOT NULL,
    CONSTRAINT PK_ags_test_stNet PRIMARY KEY (stnKey)
);
GO

ALTER TABLE FishEye.ags_test.stNet WITH CHECK ADD CONSTRAINT FK_ags_test_stNet_stType
FOREIGN KEY (stnType) REFERENCES FishEye.ags_test.stType (sttKey);
GO

-- Таблица инвестиционных программ
CREATE TABLE FishEye.ags_test.ipg (
    ipgKey     INT IDENTITY(1,1) NOT NULL,
    ipgOg      INT NOT NULL,
    ipgNm      NVARCHAR(150) COLLATE Cyrillic_General_CI_AS NOT NULL,
    ipgYy      INT NOT NULL,
    ipgNum     SMALLINT NOT NULL,
    ipgStr     DATE NOT NULL,
    ipgEnd     DATE NULL,
    ipgRepl    INT NULL,
    ipgStRlSh  INT NOT NULL,
    ipgYyYear  INT NULL,
    CONSTRAINT PK_ags_test_ipg PRIMARY KEY (ipgKey)
);
GO

ALTER TABLE FishEye.ags_test.ipg WITH CHECK ADD CONSTRAINT FK_ags_test_ipg_og
FOREIGN KEY (ipgOg) REFERENCES FishEye.ags_test.og (ogKey);
GO

ALTER TABLE FishEye.ags_test.ipg WITH CHECK ADD CONSTRAINT FK_ags_test_ipg_yyyy
FOREIGN KEY (ipgYy) REFERENCES FishEye.ags_test.yyyy (yKey);
GO

ALTER TABLE FishEye.ags_test.ipg WITH CHECK ADD CONSTRAINT FK_ags_test_ipg_stNet
FOREIGN KEY (ipgStRlSh) REFERENCES FishEye.ags_test.stNet (stnKey);
GO

-- Таблица цепочек инвестиционных программ
CREATE TABLE FishEye.ags_test.ipgCh (
    ipgcKey      INT IDENTITY(1,1) NOT NULL,
    ipgcName     NVARCHAR(255) COLLATE Cyrillic_General_CI_AS NOT NULL,
    ipgcStNetIpg INT NULL,
    ipgcIpgLate  INT NULL,
    ipgcYyyy     INT NULL,
    CONSTRAINT PK_ags_test_ipgCh PRIMARY KEY (ipgcKey)
);
GO

ALTER TABLE FishEye.ags_test.ipgCh WITH CHECK ADD CONSTRAINT FK_ags_test_ipgCh_yyyy
FOREIGN KEY (ipgcYyyy) REFERENCES FishEye.ags_test.yyyy (yKey);
GO

-- Таблица групп планов инвестиционных программ
CREATE TABLE FishEye.ags_test.ipgUtPlGr (
    iuplgKey INT IDENTITY(1,1) NOT NULL,
    iuplgIpg INT NOT NULL,
    iuplgNm  NVARCHAR(255) COLLATE Cyrillic_General_CI_AS NOT NULL,
    CONSTRAINT PK_ags_test_ipgUtPlGr PRIMARY KEY (iuplgKey)
);
GO

ALTER TABLE FishEye.ags_test.ipgUtPlGr WITH CHECK ADD CONSTRAINT FK_ags_test_ipgUtPlGr_ipg
FOREIGN KEY (iuplgIpg) REFERENCES FishEye.ags_test.ipg (ipgKey);
GO

-- Таблица связей цепочек с инвестиционными программами
CREATE TABLE FishEye.ags_test.ipgChRl (
    ipgcrKey      INT IDENTITY(1,1) NOT NULL,
    ipgcrChain    INT NOT NULL,
    ipgcrIpg      INT NOT NULL,
    ipgcrUtPlGr   INT NULL,
    CONSTRAINT PK_ags_test_ipgChRl PRIMARY KEY (ipgcrKey)
);
GO

ALTER TABLE FishEye.ags_test.ipgChRl WITH CHECK ADD CONSTRAINT FK_ags_test_ipgChRl_ipgCh
FOREIGN KEY (ipgcrChain) REFERENCES FishEye.ags_test.ipgCh (ipgcKey);
GO

ALTER TABLE FishEye.ags_test.ipgChRl WITH CHECK ADD CONSTRAINT FK_ags_test_ipgChRl_ipg
FOREIGN KEY (ipgcrIpg) REFERENCES FishEye.ags_test.ipg (ipgKey);
GO

ALTER TABLE FishEye.ags_test.ipgChRl WITH CHECK ADD CONSTRAINT FK_ags_test_ipgChRl_ipgUtPlGr
FOREIGN KEY (ipgcrUtPlGr) REFERENCES FishEye.ags_test.ipgUtPlGr (iuplgKey);
GO

-- =============================================
-- Наполнение тестовыми данными (Часть 2)
-- =============================================

-- Наполнение тестовыми данными для og и ogAg
INSERT INTO FishEye.ags_test.og (ogNm, ogNmOf, ogNmFl, ogTxt, ogINN, ogKPP, ogOGRN, ogOKPO, ogOE, ogRgTaxType)
VALUES
    (N'Рога, ООО', N'Общество с ограниченной ответственностью «Рога»', NULL, N'Тестовая организация 1', 7701000000, 770101001, 1027700000000, 12345678, NULL, 'og'),
    (N'Рога и копыта, АО', N'Акционерное общество «Рога и копыта»', NULL, N'Тестовая организация 2', 7702000000, 770201001, 1027700000001, 22345678, NULL, 'og'),
    (N'Копыта и хвосты, ИП', N'Индивидуальный предприниматель «Копыта и хвосты»', NULL, N'Тестовая организация 3', 7703000000, NULL, NULL, NULL, NULL, 'ie');
GO

INSERT INTO FishEye.ags_test.ogAg (ogaCode, ogaOg)
SELECT FORMAT(ROW_NUMBER() OVER (ORDER BY ogKey), '000'), ogKey
FROM FishEye.ags_test.og;
GO

-- Наполнение тестовыми данными для stType
INSERT INTO FishEye.ags_test.stType (sttKey, sttName)
VALUES
    (1, N'Тип 1'),
    (2, N'Тип 2'),
    (3, N'Тип 3');
GO

-- Наполнение тестовыми данными для yyyy
INSERT INTO FishEye.ags_test.yyyy (yyyy)
VALUES
    (2020),
    (2021),
    (2022),
    (2023),
    (2024),
    (2025);
GO

-- Наполнение тестовыми данными для stNet
INSERT INTO FishEye.ags_test.stNet (stnType, stnName, stnRoot)
VALUES
    (1, N'Структура сети 1', 0),
    (1, N'Структура сети 2', 0),
    (2, N'Структура сети 3', 0);
GO

-- Наполнение тестовыми данными для ipg, ipgCh, ipgUtPlGr, ipgChRl
-- Используем один блок для сохранения переменных между вставками
DECLARE @ipg1 INT, @ipg2 INT, @ipg3 INT, @ipg4 INT;
DECLARE @ipgCh1 INT, @ipgCh2 INT, @ipgCh3 INT;
DECLARE @ipgUtPlGr1 INT, @ipgUtPlGr2 INT, @ipgUtPlGr3 INT, @ipgUtPlGr4 INT;

-- Вставка ipg
INSERT INTO FishEye.ags_test.ipg (ipgOg, ipgNm, ipgYy, ipgNum, ipgStr, ipgEnd, ipgRepl, ipgStRlSh, ipgYyYear)
VALUES
    (1, N'Инвестиционная программа 1', 1, 1, '2020-01-01', '2020-12-31', NULL, 1, 2020);
SET @ipg1 = SCOPE_IDENTITY();

INSERT INTO FishEye.ags_test.ipg (ipgOg, ipgNm, ipgYy, ipgNum, ipgStr, ipgEnd, ipgRepl, ipgStRlSh, ipgYyYear)
VALUES
    (1, N'Инвестиционная программа 2', 2, 2, '2021-01-01', '2021-12-31', NULL, 1, 2021);
SET @ipg2 = SCOPE_IDENTITY();

INSERT INTO FishEye.ags_test.ipg (ipgOg, ipgNm, ipgYy, ipgNum, ipgStr, ipgEnd, ipgRepl, ipgStRlSh, ipgYyYear)
VALUES
    (2, N'Инвестиционная программа 3', 3, 3, '2022-01-01', '2022-12-31', NULL, 2, 2022);
SET @ipg3 = SCOPE_IDENTITY();

INSERT INTO FishEye.ags_test.ipg (ipgOg, ipgNm, ipgYy, ipgNum, ipgStr, ipgEnd, ipgRepl, ipgStRlSh, ipgYyYear)
VALUES
    (2, N'Инвестиционная программа 4', 4, 4, '2023-01-01', '2023-12-31', NULL, 2, 2023);
SET @ipg4 = SCOPE_IDENTITY();

-- Вставка ipgCh
INSERT INTO FishEye.ags_test.ipgCh (ipgcName, ipgcStNetIpg, ipgcIpgLate, ipgcYyyy)
VALUES
    (N'Цепочка инвестиционных программ 1', 1, @ipg2, 2);
SET @ipgCh1 = SCOPE_IDENTITY();

INSERT INTO FishEye.ags_test.ipgCh (ipgcName, ipgcStNetIpg, ipgcIpgLate, ipgcYyyy)
VALUES
    (N'Цепочка инвестиционных программ 2', 2, @ipg4, 4);
SET @ipgCh2 = SCOPE_IDENTITY();

INSERT INTO FishEye.ags_test.ipgCh (ipgcName, ipgcStNetIpg, ipgcIpgLate, ipgcYyyy)
VALUES
    (N'Цепочка инвестиционных программ 3', 1, @ipg1, 1);
SET @ipgCh3 = SCOPE_IDENTITY();

-- Вставка ipgUtPlGr
INSERT INTO FishEye.ags_test.ipgUtPlGr (iuplgIpg, iuplgNm)
VALUES
    (@ipg1, N'Группа планов 1');
SET @ipgUtPlGr1 = SCOPE_IDENTITY();

INSERT INTO FishEye.ags_test.ipgUtPlGr (iuplgIpg, iuplgNm)
VALUES
    (@ipg2, N'Группа планов 2');
SET @ipgUtPlGr2 = SCOPE_IDENTITY();

INSERT INTO FishEye.ags_test.ipgUtPlGr (iuplgIpg, iuplgNm)
VALUES
    (@ipg3, N'Группа планов 3');
SET @ipgUtPlGr3 = SCOPE_IDENTITY();

INSERT INTO FishEye.ags_test.ipgUtPlGr (iuplgIpg, iuplgNm)
VALUES
    (@ipg4, N'Группа планов 4');
SET @ipgUtPlGr4 = SCOPE_IDENTITY();

-- Вставка ipgChRl
INSERT INTO FishEye.ags_test.ipgChRl (ipgcrChain, ipgcrIpg, ipgcrUtPlGr)
VALUES
    (@ipgCh1, @ipg1, @ipgUtPlGr1),
    (@ipgCh1, @ipg2, @ipgUtPlGr2),
    (@ipgCh2, @ipg3, @ipgUtPlGr3),
    (@ipgCh2, @ipg4, @ipgUtPlGr4),
    (@ipgCh3, @ipg1, @ipgUtPlGr1);
GO

PRINT 'ags_test: все таблицы успешно созданы и заполнены тестовыми данными.';
GO
