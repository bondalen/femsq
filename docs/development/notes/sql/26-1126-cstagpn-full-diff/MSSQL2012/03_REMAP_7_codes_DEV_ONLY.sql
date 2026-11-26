/*
 * C2 §3.5.1.1 — Remap 7 кодов: temp-code на DEV_key → INSERT prod_key → FK DEV→prod.
 * DEV noM6 ONLY. Без DELETE DEV_key (их обновит 04). Требует 00b snapshot.
 * lastUpdated: 2026-11-26
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRAN;
SET IDENTITY_INSERT ags.cst ON;
IF NOT EXISTS (SELECT 1 FROM ags.cst WHERE cstKey=5156) INSERT INTO ags.cst (cstKey, cstName, cstBusSgm, cstOidOld, cstMark) VALUES (5156, N'Оснащение ИТСО Пунгинского ПХГ', NULL, NULL, NULL);
IF NOT EXISTS (SELECT 1 FROM ags.cst WHERE cstKey=5157) INSERT INTO ags.cst (cstKey, cstName, cstBusSgm, cstOidOld, cstMark) VALUES (5157, N'Оснащение ИТСО Кирюшкинского ПХГ', NULL, NULL, NULL);
IF NOT EXISTS (SELECT 1 FROM ags.cst WHERE cstKey=5160) INSERT INTO ags.cst (cstKey, cstName, cstBusSgm, cstOidOld, cstMark) VALUES (5160, N'Вычислительный комплекс ЦОД ПАО «Газпром». Этап 2', NULL, NULL, NULL);
IF NOT EXISTS (SELECT 1 FROM ags.cst WHERE cstKey=5161) INSERT INTO ags.cst (cstKey, cstName, cstBusSgm, cstOidOld, cstMark) VALUES (5161, N'Инженерный комплекс ЦОД ПАО «Газпром». Этап 1', NULL, NULL, NULL);
IF NOT EXISTS (SELECT 1 FROM ags.cst WHERE cstKey=5177) INSERT INTO ags.cst (cstKey, cstName, cstBusSgm, cstOidOld, cstMark) VALUES (5177, N'Техническое перевооружение установки огневого обезвреживания подтоварной воды «ФЗН-3600» Сургутского ЗСК', NULL, NULL, NULL);
SET IDENTITY_INSERT ags.cst OFF;
SET IDENTITY_INSERT ags.cstAg ON;
IF NOT EXISTS (SELECT 1 FROM ags.cstAg WHERE cstaKey=3179) INSERT INTO ags.cstAg (cstaKey, cstaAg, cstaCst, cstaOidOld, cstaInvestor) VALUES (3179, 1, 5156, NULL, 7);
IF NOT EXISTS (SELECT 1 FROM ags.cstAg WHERE cstaKey=3180) INSERT INTO ags.cstAg (cstaKey, cstaAg, cstaCst, cstaOidOld, cstaInvestor) VALUES (3180, 1, 5157, NULL, 7);
IF NOT EXISTS (SELECT 1 FROM ags.cstAg WHERE cstaKey=3184) INSERT INTO ags.cstAg (cstaKey, cstaAg, cstaCst, cstaOidOld, cstaInvestor) VALUES (3184, 55, 5160, NULL, 7);
IF NOT EXISTS (SELECT 1 FROM ags.cstAg WHERE cstaKey=3185) INSERT INTO ags.cstAg (cstaKey, cstaAg, cstaCst, cstaOidOld, cstaInvestor) VALUES (3185, 55, 5161, NULL, 7);
IF NOT EXISTS (SELECT 1 FROM ags.cstAg WHERE cstaKey=3202) INSERT INTO ags.cstAg (cstaKey, cstaAg, cstaCst, cstaOidOld, cstaInvestor) VALUES (3202, 1, 5177, NULL, 7);
SET IDENTITY_INSERT ags.cstAg OFF;
/* --- 014-2007423: 4583 → 4422 --- */
IF EXISTS (SELECT 1 FROM ags.cstAgPn WHERE cstapKey=4583 AND cstapIpgPnN=N'014-2007423')
 AND NOT EXISTS (SELECT 1 FROM ags.cstAgPn WHERE cstapKey=4422)
BEGIN
  UPDATE ags.cstAgPn SET cstapIpgPnN=N'__REMAP_4583' WHERE cstapKey=4583;
  SET IDENTITY_INSERT ags.cstAgPn ON;
  INSERT INTO ags.cstAgPn (cstapKey, cstapCsta, cstapIpgPnN, cstapOidOld) VALUES (4422, 3184, N'014-2007423', NULL);
  SET IDENTITY_INSERT ags.cstAgPn OFF;
  UPDATE ags.ipgPn SET ipgpCstAgPn=4422 WHERE ipgpCstAgPn=4583;
  UPDATE ags.ra SET ra_cac=4422 WHERE ra_cac=4583;
  UPDATE ags.ralp SET ralpCstAgPn=4422 WHERE ralpCstAgPn=4583;
  UPDATE ags.ralpRa SET ralprCstAgPn=4422 WHERE ralprCstAgPn=4583;
  UPDATE ags.ogAgFeeP SET oafpCstAgPn=4422 WHERE oafpCstAgPn=4583;
  UPDATE ags.cn_inv_pm SET cnipCstAgPn=4422 WHERE cnipCstAgPn=4583;
  UPDATE ags.cn_PrDocP SET pdpCstAgPn=4422 WHERE pdpCstAgPn=4583;
  UPDATE ags.cnInvCmmCst SET ciccCstAgPn=4422 WHERE ciccCstAgPn=4583;
  UPDATE ags.cstAgPnBranch SET cstapbCstAgPn=4422 WHERE cstapbCstAgPn=4583;
  UPDATE ags.cstAgPnMnrl SET amCstAgPn=4422 WHERE amCstAgPn=4583;
END;
/* --- 014-2007424: 4584 → 4423 --- */
IF EXISTS (SELECT 1 FROM ags.cstAgPn WHERE cstapKey=4584 AND cstapIpgPnN=N'014-2007424')
 AND NOT EXISTS (SELECT 1 FROM ags.cstAgPn WHERE cstapKey=4423)
BEGIN
  UPDATE ags.cstAgPn SET cstapIpgPnN=N'__REMAP_4584' WHERE cstapKey=4584;
  SET IDENTITY_INSERT ags.cstAgPn ON;
  INSERT INTO ags.cstAgPn (cstapKey, cstapCsta, cstapIpgPnN, cstapOidOld) VALUES (4423, 3185, N'014-2007424', NULL);
  SET IDENTITY_INSERT ags.cstAgPn OFF;
  UPDATE ags.ipgPn SET ipgpCstAgPn=4423 WHERE ipgpCstAgPn=4584;
  UPDATE ags.ra SET ra_cac=4423 WHERE ra_cac=4584;
  UPDATE ags.ralp SET ralpCstAgPn=4423 WHERE ralpCstAgPn=4584;
  UPDATE ags.ralpRa SET ralprCstAgPn=4423 WHERE ralprCstAgPn=4584;
  UPDATE ags.ogAgFeeP SET oafpCstAgPn=4423 WHERE oafpCstAgPn=4584;
  UPDATE ags.cn_inv_pm SET cnipCstAgPn=4423 WHERE cnipCstAgPn=4584;
  UPDATE ags.cn_PrDocP SET pdpCstAgPn=4423 WHERE pdpCstAgPn=4584;
  UPDATE ags.cnInvCmmCst SET ciccCstAgPn=4423 WHERE ciccCstAgPn=4584;
  UPDATE ags.cstAgPnBranch SET cstapbCstAgPn=4423 WHERE cstapbCstAgPn=4584;
  UPDATE ags.cstAgPnMnrl SET amCstAgPn=4423 WHERE amCstAgPn=4584;
END;
/* --- 051-1006267: 4587 → 4448 --- */
IF EXISTS (SELECT 1 FROM ags.cstAgPn WHERE cstapKey=4587 AND cstapIpgPnN=N'051-1006267')
 AND NOT EXISTS (SELECT 1 FROM ags.cstAgPn WHERE cstapKey=4448)
BEGIN
  UPDATE ags.cstAgPn SET cstapIpgPnN=N'__REMAP_4587' WHERE cstapKey=4587;
  SET IDENTITY_INSERT ags.cstAgPn ON;
  INSERT INTO ags.cstAgPn (cstapKey, cstapCsta, cstapIpgPnN, cstapOidOld) VALUES (4448, 3202, N'051-1006267', NULL);
  SET IDENTITY_INSERT ags.cstAgPn OFF;
  UPDATE ags.ipgPn SET ipgpCstAgPn=4448 WHERE ipgpCstAgPn=4587;
  UPDATE ags.ra SET ra_cac=4448 WHERE ra_cac=4587;
  UPDATE ags.ralp SET ralpCstAgPn=4448 WHERE ralpCstAgPn=4587;
  UPDATE ags.ralpRa SET ralprCstAgPn=4448 WHERE ralprCstAgPn=4587;
  UPDATE ags.ogAgFeeP SET oafpCstAgPn=4448 WHERE oafpCstAgPn=4587;
  UPDATE ags.cn_inv_pm SET cnipCstAgPn=4448 WHERE cnipCstAgPn=4587;
  UPDATE ags.cn_PrDocP SET pdpCstAgPn=4448 WHERE pdpCstAgPn=4587;
  UPDATE ags.cnInvCmmCst SET ciccCstAgPn=4448 WHERE ciccCstAgPn=4587;
  UPDATE ags.cstAgPnBranch SET cstapbCstAgPn=4448 WHERE cstapbCstAgPn=4587;
  UPDATE ags.cstAgPnMnrl SET amCstAgPn=4448 WHERE amCstAgPn=4587;
END;
/* --- 051-1007114: 4588 → 4443 --- */
IF EXISTS (SELECT 1 FROM ags.cstAgPn WHERE cstapKey=4588 AND cstapIpgPnN=N'051-1007114')
 AND NOT EXISTS (SELECT 1 FROM ags.cstAgPn WHERE cstapKey=4443)
BEGIN
  UPDATE ags.cstAgPn SET cstapIpgPnN=N'__REMAP_4588' WHERE cstapKey=4588;
  SET IDENTITY_INSERT ags.cstAgPn ON;
  INSERT INTO ags.cstAgPn (cstapKey, cstapCsta, cstapIpgPnN, cstapOidOld) VALUES (4443, 3197, N'051-1007114', NULL);
  SET IDENTITY_INSERT ags.cstAgPn OFF;
  UPDATE ags.ipgPn SET ipgpCstAgPn=4443 WHERE ipgpCstAgPn=4588;
  UPDATE ags.ra SET ra_cac=4443 WHERE ra_cac=4588;
  UPDATE ags.ralp SET ralpCstAgPn=4443 WHERE ralpCstAgPn=4588;
  UPDATE ags.ralpRa SET ralprCstAgPn=4443 WHERE ralprCstAgPn=4588;
  UPDATE ags.ogAgFeeP SET oafpCstAgPn=4443 WHERE oafpCstAgPn=4588;
  UPDATE ags.cn_inv_pm SET cnipCstAgPn=4443 WHERE cnipCstAgPn=4588;
  UPDATE ags.cn_PrDocP SET pdpCstAgPn=4443 WHERE pdpCstAgPn=4588;
  UPDATE ags.cnInvCmmCst SET ciccCstAgPn=4443 WHERE ciccCstAgPn=4588;
  UPDATE ags.cstAgPnBranch SET cstapbCstAgPn=4443 WHERE cstapbCstAgPn=4588;
  UPDATE ags.cstAgPnMnrl SET amCstAgPn=4443 WHERE amCstAgPn=4588;
END;
/* --- 051-2006707: 4577 → 4555 --- */
IF EXISTS (SELECT 1 FROM ags.cstAgPn WHERE cstapKey=4577 AND cstapIpgPnN=N'051-2006707')
 AND NOT EXISTS (SELECT 1 FROM ags.cstAgPn WHERE cstapKey=4555)
BEGIN
  UPDATE ags.cstAgPn SET cstapIpgPnN=N'__REMAP_4577' WHERE cstapKey=4577;
  SET IDENTITY_INSERT ags.cstAgPn ON;
  INSERT INTO ags.cstAgPn (cstapKey, cstapCsta, cstapIpgPnN, cstapOidOld) VALUES (4555, 2974, N'051-2006707', NULL);
  SET IDENTITY_INSERT ags.cstAgPn OFF;
  UPDATE ags.ipgPn SET ipgpCstAgPn=4555 WHERE ipgpCstAgPn=4577;
  UPDATE ags.ra SET ra_cac=4555 WHERE ra_cac=4577;
  UPDATE ags.ralp SET ralpCstAgPn=4555 WHERE ralpCstAgPn=4577;
  UPDATE ags.ralpRa SET ralprCstAgPn=4555 WHERE ralprCstAgPn=4577;
  UPDATE ags.ogAgFeeP SET oafpCstAgPn=4555 WHERE oafpCstAgPn=4577;
  UPDATE ags.cn_inv_pm SET cnipCstAgPn=4555 WHERE cnipCstAgPn=4577;
  UPDATE ags.cn_PrDocP SET pdpCstAgPn=4555 WHERE pdpCstAgPn=4577;
  UPDATE ags.cnInvCmmCst SET ciccCstAgPn=4555 WHERE ciccCstAgPn=4577;
  UPDATE ags.cstAgPnBranch SET cstapbCstAgPn=4555 WHERE cstapbCstAgPn=4577;
  UPDATE ags.cstAgPnMnrl SET amCstAgPn=4555 WHERE amCstAgPn=4577;
END;
/* --- 051-2007134: 4585 → 4417 --- */
IF EXISTS (SELECT 1 FROM ags.cstAgPn WHERE cstapKey=4585 AND cstapIpgPnN=N'051-2007134')
 AND NOT EXISTS (SELECT 1 FROM ags.cstAgPn WHERE cstapKey=4417)
BEGIN
  UPDATE ags.cstAgPn SET cstapIpgPnN=N'__REMAP_4585' WHERE cstapKey=4585;
  SET IDENTITY_INSERT ags.cstAgPn ON;
  INSERT INTO ags.cstAgPn (cstapKey, cstapCsta, cstapIpgPnN, cstapOidOld) VALUES (4417, 3179, N'051-2007134', NULL);
  SET IDENTITY_INSERT ags.cstAgPn OFF;
  UPDATE ags.ipgPn SET ipgpCstAgPn=4417 WHERE ipgpCstAgPn=4585;
  UPDATE ags.ra SET ra_cac=4417 WHERE ra_cac=4585;
  UPDATE ags.ralp SET ralpCstAgPn=4417 WHERE ralpCstAgPn=4585;
  UPDATE ags.ralpRa SET ralprCstAgPn=4417 WHERE ralprCstAgPn=4585;
  UPDATE ags.ogAgFeeP SET oafpCstAgPn=4417 WHERE oafpCstAgPn=4585;
  UPDATE ags.cn_inv_pm SET cnipCstAgPn=4417 WHERE cnipCstAgPn=4585;
  UPDATE ags.cn_PrDocP SET pdpCstAgPn=4417 WHERE pdpCstAgPn=4585;
  UPDATE ags.cnInvCmmCst SET ciccCstAgPn=4417 WHERE ciccCstAgPn=4585;
  UPDATE ags.cstAgPnBranch SET cstapbCstAgPn=4417 WHERE cstapbCstAgPn=4585;
  UPDATE ags.cstAgPnMnrl SET amCstAgPn=4417 WHERE amCstAgPn=4585;
END;
/* --- 051-2007135: 4586 → 4418 --- */
IF EXISTS (SELECT 1 FROM ags.cstAgPn WHERE cstapKey=4586 AND cstapIpgPnN=N'051-2007135')
 AND NOT EXISTS (SELECT 1 FROM ags.cstAgPn WHERE cstapKey=4418)
BEGIN
  UPDATE ags.cstAgPn SET cstapIpgPnN=N'__REMAP_4586' WHERE cstapKey=4586;
  SET IDENTITY_INSERT ags.cstAgPn ON;
  INSERT INTO ags.cstAgPn (cstapKey, cstapCsta, cstapIpgPnN, cstapOidOld) VALUES (4418, 3180, N'051-2007135', NULL);
  SET IDENTITY_INSERT ags.cstAgPn OFF;
  UPDATE ags.ipgPn SET ipgpCstAgPn=4418 WHERE ipgpCstAgPn=4586;
  UPDATE ags.ra SET ra_cac=4418 WHERE ra_cac=4586;
  UPDATE ags.ralp SET ralpCstAgPn=4418 WHERE ralpCstAgPn=4586;
  UPDATE ags.ralpRa SET ralprCstAgPn=4418 WHERE ralprCstAgPn=4586;
  UPDATE ags.ogAgFeeP SET oafpCstAgPn=4418 WHERE oafpCstAgPn=4586;
  UPDATE ags.cn_inv_pm SET cnipCstAgPn=4418 WHERE cnipCstAgPn=4586;
  UPDATE ags.cn_PrDocP SET pdpCstAgPn=4418 WHERE pdpCstAgPn=4586;
  UPDATE ags.cnInvCmmCst SET ciccCstAgPn=4418 WHERE ciccCstAgPn=4586;
  UPDATE ags.cstAgPnBranch SET cstapbCstAgPn=4418 WHERE cstapbCstAgPn=4586;
  UPDATE ags.cstAgPnMnrl SET amCstAgPn=4418 WHERE amCstAgPn=4586;
END;
COMMIT;
SELECT cstapKey, cstapIpgPnN FROM ags.cstAgPn WHERE cstapKey IN (4583,4422,4584,4423,4587,4448,4588,4443,4577,4555,4585,4417,4586,4418) ORDER BY cstapKey;
GO
