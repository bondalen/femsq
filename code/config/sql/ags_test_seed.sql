-- Создание таблиц og и ogAg в тестовой схеме ags_test
-- Предназначено исключительно для окружения разработки / интеграционных тестов

USE [FishEye];
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'ags_test')
BEGIN
    RAISERROR('Schema ags_test does not exist. Create it before running this script.', 16, 1);
    RETURN;
END;
GO

-- Удаляем таблицы, если существуют (для повторного запуска скрипта)
IF OBJECT_ID('FishEye.ags_test.ogAg', 'U') IS NOT NULL
BEGIN
    DROP TABLE FishEye.ags_test.ogAg;
END;
GO

IF OBJECT_ID('FishEye.ags_test.og', 'U') IS NOT NULL
BEGIN
    DROP TABLE FishEye.ags_test.og;
END;
GO

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

-- Наполнение тестовыми данными
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

PRINT 'ags_test.og и ags_test.ogAg успешно созданы и заполнены тестовыми данными.';
GO
