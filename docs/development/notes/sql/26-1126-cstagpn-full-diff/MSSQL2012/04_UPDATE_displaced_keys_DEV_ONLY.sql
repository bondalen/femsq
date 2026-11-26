/*
 * C2 §3.5.1.2 — UPDATE ключей 4577/4583–88 (csta + code) после 03.
 * Имена cstapCstName* / cstapOgName — computed, не обновляем.
 * Ожидает temp-code __REMAP_<key>. DEV noM6 ONLY.
 * lastUpdated: 2026-11-26
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRAN;
SET IDENTITY_INSERT ags.cst ON;
IF NOT EXISTS (SELECT 1 FROM ags.cst WHERE cstKey=5192) INSERT INTO ags.cst (cstKey, cstName, cstBusSgm, cstOidOld, cstMark) VALUES (5192, N'Газопровод-отвод и ГРС с.п. Калиновка муниципального района Сергиевский Самарской области', NULL, NULL, NULL);
IF NOT EXISTS (SELECT 1 FROM ags.cst WHERE cstKey=5196) INSERT INTO ags.cst (cstKey, cstName, cstBusSgm, cstOidOld, cstMark) VALUES (5196, N'Техническое перевооружение участка магистрального газопровода «Сахалин – Хабаровск – Владивосток» для подключения газопровода-отвода и ГРС Вознесенское', NULL, NULL, NULL);
IF NOT EXISTS (SELECT 1 FROM ags.cst WHERE cstKey=5197) INSERT INTO ags.cst (cstKey, cstName, cstBusSgm, cstOidOld, cstMark) VALUES (5197, N'Техническое перевооружение участка магистрального газопровода «Парабель – Кузбасс» для подключения газопровода-отвода и ГPC г. Прокопьевска Кемеровской области', NULL, NULL, NULL);
SET IDENTITY_INSERT ags.cst OFF;
SET IDENTITY_INSERT ags.cstAg ON;
IF NOT EXISTS (SELECT 1 FROM ags.cstAg WHERE cstaKey=3253) INSERT INTO ags.cstAg (cstaKey, cstaAg, cstaCst, cstaOidOld, cstaInvestor) VALUES (3253, 1, 5192, NULL, 7);
IF NOT EXISTS (SELECT 1 FROM ags.cstAg WHERE cstaKey=3257) INSERT INTO ags.cstAg (cstaKey, cstaAg, cstaCst, cstaOidOld, cstaInvestor) VALUES (3257, 1, 5196, NULL, 7);
IF NOT EXISTS (SELECT 1 FROM ags.cstAg WHERE cstaKey=3258) INSERT INTO ags.cstAg (cstaKey, cstaAg, cstaCst, cstaOidOld, cstaInvestor) VALUES (3258, 1, 5197, NULL, 7);
IF NOT EXISTS (SELECT 1 FROM ags.cstAg WHERE cstaKey=3259) INSERT INTO ags.cstAg (cstaKey, cstaAg, cstaCst, cstaOidOld, cstaInvestor) VALUES (3259, 1, 3332, NULL, 7);
SET IDENTITY_INSERT ags.cstAg OFF;
UPDATE ags.cstAgPn SET cstapCsta=3253, cstapIpgPnN=N'051-2007384', cstapOidOld=NULL WHERE cstapKey=4577 AND cstapIpgPnN=N'__REMAP_4577';
UPDATE ags.cstAgPn SET cstapCsta=3257, cstapIpgPnN=N'051-2007329', cstapOidOld=NULL WHERE cstapKey=4583 AND cstapIpgPnN=N'__REMAP_4583';
UPDATE ags.cstAgPn SET cstapCsta=3258, cstapIpgPnN=N'051-2007330', cstapOidOld=NULL WHERE cstapKey=4584 AND cstapIpgPnN=N'__REMAP_4584';
UPDATE ags.cstAgPn SET cstapCsta=2084, cstapIpgPnN=N'051-2006008', cstapOidOld=NULL WHERE cstapKey=4585 AND cstapIpgPnN=N'__REMAP_4585';
UPDATE ags.cstAgPn SET cstapCsta=2559, cstapIpgPnN=N'051-2005977', cstapOidOld=NULL WHERE cstapKey=4586 AND cstapIpgPnN=N'__REMAP_4586';
UPDATE ags.cstAgPn SET cstapCsta=3259, cstapIpgPnN=N'051-2000986', cstapOidOld=NULL WHERE cstapKey=4587 AND cstapIpgPnN=N'__REMAP_4587';
UPDATE ags.cstAgPn SET cstapCsta=71, cstapIpgPnN=N'051-2001510', cstapOidOld=NULL WHERE cstapKey=4588 AND cstapIpgPnN=N'__REMAP_4588';
COMMIT;
SELECT cstapKey, cstapIpgPnN FROM ags.cstAgPn WHERE cstapKey IN (4577,4583,4584,4585,4586,4587,4588) ORDER BY cstapKey;
GO
