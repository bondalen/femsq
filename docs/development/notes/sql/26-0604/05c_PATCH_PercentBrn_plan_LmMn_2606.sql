USE [FishEye];
GO

-- =============================================================================
-- Файл:    05c_PATCH_PercentBrn_plan_LmMn_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Этап 21.4.3 — plan-колонки ag_Pl/iv_Pl из ipgUtPlPnLmMn @ stCost 212 (Решение 22).
--   Кумулятивно: 20.2 (fnIpgChDats_2606), 21.2 (ipgChRl_2606), div-by-zero. Применять после 05b или вместо 05b.
-- Деплой (multi-statement TVF): DROP отдельно, затем CREATE из строк 24–2807:
--   sqlcmd … -Q "DROP FUNCTION ags.fnIpgChRsltCstUtlPercentBrn_2606;"
--   sed -n '24,2807p' 05a_PATCH…sql | sqlcmd … -i /dev/stdin
-- Полный -i файла может дать Msg 2714, если объект уже есть в той же сессии.
-- Автор:   Александр | Дата: 2026-06-30
-- =============================================================================

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'=== 05c: PATCH PercentBrn_2606 plan from LmMn @212 ===';
GO

IF OBJECT_ID(N'ags.fnIpgChRsltCstUtlPercentBrn_2606', N'TF') IS NOT NULL
    DROP FUNCTION ags.fnIpgChRsltCstUtlPercentBrn_2606;
ELSE IF OBJECT_ID(N'ags.fnIpgChRsltCstUtlPercentBrn_2606', N'IF') IS NOT NULL
    DROP FUNCTION ags.fnIpgChRsltCstUtlPercentBrn_2606;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE   FUNCTION [ags].[fnIpgChRsltCstUtlPercentBrn_2606] 
(
	-- Параметры
	@ipgChKey int,         -- цепочка инвестпрограмм
	@ipgStKey   int = NULL,  -- узел stIpg (NULL = все разделы)
	@stCostKey int = NULL   -- пункт stCost (NULL = все статьи)
)
RETURNS @TableRslt TABLE 
		(
				-- столбцы общие для схем реализации инвестиционных проектов ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
				rowNum int, ogNm nvarchar(255), branch int, branchName nvarchar(255), cstAgPnCode nvarchar(255), dateRslt date, ipgChKey int, cstapKey int
				, yKey int, yyyy int, mKey int, mNum int, mCs nvarchar(255), mNm nvarchar(255), mQ nvarchar(255), mHy int -- годы, полугодия, месяцы
				, cstaInvestor int, ogaKey int, ipgKey int, ipgCount int
				-- столбцы общие для схем реализации инвестиционных проектов. Окончание :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

				-- агентская схема ======================================================================================================================================
				, ag_ipgpKey int, ag_iShKey int, ag_ipgpSmTtl money, ag_lim money, ag_Pl money, ag_PlAccum money
				-- состояние выполнения +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- ниже плана
				, ag_PlFulfillment money, ag_PlNonFulfillment_review money , ag_PlNonFulfillment money
				-- выше плана ниже лимта
				, ag_PlOverFulfillment money, ag_PlRestLimit_review money, ag_PlRestLimit money
				-- выше лимта
				, ag_PlOverLimit money, ag_PlOverLimit_review money
				-- проценты освоения лимита
				, ag_LimPercent float, ag_LimPercentInProcess float -- *процент освоения*, исключая *освоенное сверх лимита*
				, ag_percentDev float, ag_percentDevInProcess float -- *процент освоения*, включая *освоенное сверх лимита*
				-- проценты освоения плана
				, ag_PlPercentMinusOverFulf float, ag_PlPercentMinusOverFulfInProcess float -- *процент выполнения плана* без *перевыполнения*
				, ag_PlPercent float, ag_PlPercentInProcess float -- *процент выполнения плана* включая *перевыполнение*
				, ag_percentPlDev float, ag_percentPlDevInProcess float -- *процент выполнения плана* включая всё, даже и *сверхлимит*
				-- состояние выполнения. Окончание ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				
				-- освоение, виды и итоговое ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- отчёты агентов ---------------------------------------------------------------------------------------------------------------------------------------
				-- относящиеся к любым годам ............................................................................................................................
				, ag_presentedAll money, ag_presentedAllAccum money -- сумма всех, без исключения, отчётов представленных по стройке
				, ag_presentedAllModul money, ag_presentedAllModulAccum money -- сумма всех, без исключения, отчётов представленных по стройке, взятая по модулю
				-- относящиеся к текущему году ..........................................................................................................................
				, ag_presented money, ag_presentedAccum money -- сумма *представленных* отчётов, исключая изменения к отчётам прошлых лет
				, ag_accepted money, ag_acceptedAccum money -- сумма *принятых* отчётов, исключая изменения к отчётам прошлых лет
				, ag_inProcess money, ag_inProcessAccum money -- сумма *рассматриваемых* отчётов, исключая изменения к отчётам прошлых лет
				, ag_returned money, ag_returnedAccum money -- сумма *возвращенных* отчётов, исключая изменения к отчётам прошлых лет
				, ag_notArrived money, ag_notArrivedAccum money -- сумма *не поступивших* отчётов, исключая изменения к отчётам прошлых лет
				-- относящиеся к прошлым годам. Формируются за счёт изменений к отчётам прошлых лет .....................................................................
				, ag_presentedPrevYears money, ag_presentedPrevYearsAccum money
				, ag_acceptedPrevYears money, ag_acceptedPrevYearsAccum money
				, ag_inProcessPrevYears money, ag_inProcessPrevYearsAccum money
				, ag_returnedPrevYears money, ag_returnedPrevYearsAccum money
				, ag_notArrivedPrevYears money, ag_notArrivedPrevYearsAccum money
				-- отчёты агентов. Окончание ----------------------------------------------------------------------------------------------------------------------------
				-- агентское вознаграждение -----------------------------------------------------------------------------------------------------------------------------
				, ag_agFeePresented money, ag_agFeePresentedAccum money, ag_agFeeAccepted money, ag_agFeeAcceptedAccum money -- *представленные* и *принятые* акты
				, ag_agFeeInProcess money, ag_agFeeInProcessAccum money, ag_agFeeReturned money, ag_agFeeReturnedAccum money -- *рассматриваемые* и *возвращённые* акты
				, ag_agFeeNotArrived money, ag_agFeeNotArrivedAccum money -- *не поступившие* акты
				-- земельные участки ------------------------------------------------------------------------------------------------------------------------------------
				, ag_presentedRalp money, ag_presentedRalpAccum money, ag_acceptedRalp money, ag_acceptedRalpAccum money -- *представленные* и *принятые* отчёты ЗУ
				, ag_inProcessRalp money, ag_inProcessRalpAccum money, ag_returnedRalp money, ag_returnedRalpAccum money -- *рассматриваемые* и *возвращённые* отчёты ЗУ
				, ag_notArrivedRalp money, ag_notArrivedRalpAccum money  -- *не поступившие* отчёты ЗУ
				-- хранение, стройконтроль, ОПИ -------------------------------------------------------------------------------------------------------------------------
				, ag_storageSum money, ag_storageSumAccum money, ag_cctSum money, ag_cctSumAccum money, ag_MnrlSum money, ag_MnrlSumAccum money -- *принятые* по этим
				-- общее ------------------------------------------------------------------------------------------------------------------------------------------------
				, ag_presentedTtl money, ag_presentedTtlAccum money -- *представлено* по всем видам освоения
				, ag_acceptedTtl money, ag_acceptedTtlAccum money -- *принято* по всем видам освоения
				, ag_restOfLimit money -- остаток лимита, если от него отнять *принято* по всем видам освоения
				, ag_restOfLimitInProcess money -- остаток лимита, если от него отнять *принято* по всем видам освоения и ещё отнять *рассматриваемое*
				, ag_inProcessTtl money, ag_inProcessTtlAccum money -- *рассматривается* по всем видам освоения
				, ag_acceptedAndInProcessTtl money, ag_acceptedAndInProcessTtlAccum money -- сумма *принято* и *рассматривается* по всем видам освоения
				, ag_returnedTtl money, ag_returnedTtlAccum money -- *возвращено* по всем видам освоения
				, ag_notArrivedTtl money, ag_notArrivedTtlAccum money -- *не поступило* по всем видам освоения
				-- освоение, виды и итоговое. Окончание +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- агентская схема. Окончание ===========================================================================================================================

				-- инвестиционная схема (агентская, неплан) =============================================================================================================
				, iv_ipgpKey int, iv_iShKey int, ia_iShKey int, iv_ipgpSmTtl money, iv_lim money, ia_lim money, iv_Pl money, iv_PlAccum money
				-- состояние выполнения +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- ниже плана
				, iv_PlFulfillment money, iv_PlNonFulfillment_review money, iv_PlNonFulfillment money
				-- выше плана ниже лимита
				, iv_PlOverFulfillment money, iv_PlRestLimit_review money, iv_PlRestLimit money
				-- выше лимита
				, iv_PlOverLimit money, iv_PlOverLimit_review money
				-- проценты освоения лимита
				, iv_LimPercent float, iv_LimPercentInProcess float -- *процент освоения*, исключая *освоенное сверх лимита*
				, ia_percentDev float, ia_percentDevInProcess float -- *процент освоения*, включая *освоенное сверх лимита*
				-- проценты освоения плана
				, iv_PlPercentMinusOverFulf float, iv_PlPercentMinusOverFulfInProcess float -- *процент выполнения плана* без *перевыполнения*
				, iv_PlPercent float, iv_PlPercentInProcess float -- *процент выполнения плана* включая *перевыполнение*
				, ia_percentPlDev float, ia_percentPlDevInProcess float -- *процент выполнения плана* включая всё, даже и *сверхлимит*
				-- состояние выполнения. Окончание ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- инвестиционная схема. Окончание ======================================================================================================================

				-- инвестиционная схема (агентская, неплан) =============================================================================================================
				-- освоение, виды и итоговое ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- отчёты агентов ---------------------------------------------------------------------------------------------------------------------------------------
				-- относящиеся к любым годам ............................................................................................................................
				, ia_presentedAll money, ia_presentedAllAccum money -- сумма всех, без исключения, отчётов представленных по стройке
				, ia_presentedAllModul money, ia_presentedAllModulAccum money -- сумма всех, без исключения, отчётов представленных по стройке, взятая по модулю
				-- относящиеся к текущему году ..........................................................................................................................
				, ia_presented money, ia_presentedAccum money -- сумма *представленных* отчётов, исключая изменения к отчётам прошлых лет
				, ia_accepted money, ia_acceptedAccum money -- сумма *принятых* отчётов, исключая изменения к отчётам прошлых лет
				, ia_inProcess money, ia_inProcessAccum money -- сумма *рассматриваемых* отчётов, исключая изменения к отчётам прошлых лет
				, ia_returned money, ia_returnedAccum money -- сумма *возвращенных* отчётов, исключая изменения к отчётам прошлых лет
				, ia_notArrived money, ia_notArrivedAccum money -- сумма *не поступивших* отчётов, исключая изменения к отчётам прошлых лет
				-- относящиеся к прошлым годам. Формируются за счёт изменений к отчётам прошлых лет .....................................................................
				, ia_presentedPrevYears money, ia_presentedPrevYearsAccum money
				, ia_acceptedPrevYears money, ia_acceptedPrevYearsAccum money
				, ia_inProcessPrevYears money, ia_inProcessPrevYearsAccum money
				, ia_returnedPrevYears money, ia_returnedPrevYearsAccum money
				, ia_notArrivedPrevYears money, ia_notArrivedPrevYearsAccum money
				-- отчёты агентов. Окончание ----------------------------------------------------------------------------------------------------------------------------

				-- агентское вознаграждение -----------------------------------------------------------------------------------------------------------------------------
				, ia_agFeePresented money, ia_agFeePresentedAccum money, ia_agFeeAccepted money, ia_agFeeAcceptedAccum money
				, ia_agFeeInProcess money, ia_agFeeInProcessAccum money
				, ia_agFeeReturned money, ia_agFeeReturnedAccum money
				, ia_agFeeNotArrived money, ia_agFeeNotArrivedAccum money
				-- земельные участки ------------------------------------------------------------------------------------------------------------------------------------
				, ia_presentedRalp money, ia_presentedRalpAccum money, ia_acceptedRalp money, ia_acceptedRalpAccum money
				, ia_inProcessRalp money, ia_inProcessRalpAccum money
				, ia_returnedRalp money, ia_returnedRalpAccum money
				, ia_notArrivedRalp money, ia_notArrivedRalpAccum money
				-- хранение, стройконтроль, ОПИ -------------------------------------------------------------------------------------------------------------------------
				, ia_storageSum money, ia_storageSumAccum money, ia_cctSum money, ia_cctSumAccum money, ia_MnrlSum money, ia_MnrlSumAccum money
				-- общее ------------------------------------------------------------------------------------------------------------------------------------------------
				, ia_presentedTtl money, ia_presentedTtlAccum money -- *представлено* по всем видам освоения
				, ia_acceptedTtl money, ia_acceptedTtlAccum money -- *принято* по всем видам освоения
				, ia_restOfLimit money -- остаток лимита, если от него отнять *принято* по всем видам освоения
				, ia_restOfLimitInProcess money -- остаток лимита, если от него отнять *принято* по всем видам освоения и ещё отнять *рассматриваемое*
				, ia_inProcessTtl money, ia_inProcessTtlAccum money -- *рассматривается* по всем видам освоения
				, ia_acceptedAndInProcessTtl money, ia_acceptedAndInProcessTtlAccum money -- сумма *принято* и *рассматривается* по всем видам освоения
				, ia_returnedTtl money, ia_returnedTtlAccum money -- *возвращено* по всем видам освоения
				, ia_notArrivedTtl money, ia_notArrivedTtlAccum money -- *не поступило* по всем видам освоения
				-- освоение, виды и итоговое. Окончание +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- инвестиционная схема (агентская, неплан). Окончание ==================================================================================================

				-- неизвестная схема ====================================================================================================================================
				, uk_ipgpKey int, uk_iShKey int, uk_ipgpSmTtl money, uk_lim  money, uk_Pl money, uk_PlAccum money
				-- состояние выполнения +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- ниже плана
				, uk_PlFulfillment money, uk_PlNonFulfillment_review money, uk_PlNonFulfillment money
				-- выше плана ниже лимита
				, uk_PlOverFulfillment money, uk_PlRestLimit_review money, uk_PlRestLimit money
				-- выше лимита
				, uk_PlOverLimit money, uk_PlOverLimit_review money
				-- проценты освоения лимита
				, uk_LimPercent float, uk_LimPercentInProcess float -- *процент освоения*, исключая *освоенное сверх лимита*
				, uk_percentDev float, uk_percentDevInProcess float -- *процент освоения*, включая *освоенное сверх лимита*
				-- проценты освоения плана
				, uk_PlPercentMinusOverFulf float, uk_PlPercentMinusOverFulfInProcess float -- *процент выполнения плана* без *перевыполнения*
				, uk_PlPercent float, uk_PlPercentInProcess float -- *процент выполнения плана* включая *перевыполнение*
				, uk_percentPlDev float, uk_percentPlDevInProcess float -- *процент выполнения плана* включая всё, даже и *сверхлимит*
				-- состояние выполнения. Окончание ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

				-- освоение, виды и итоговое ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- отчёты агентов ---------------------------------------------------------------------------------------------------------------------------------------
				-- относящиеся к любым годам ............................................................................................................................
				, uk_presentedAll money, uk_presentedAllAccum money -- сумма всех, без исключения, отчётов представленных по стройке
				, uk_presentedAllModul money, uk_presentedAllModulAccum money -- сумма всех, без исключения, отчётов представленных по стройке, взятая по модулю
				-- относящиеся к текущему году ..........................................................................................................................
				, uk_presented money, uk_presentedAccum money -- сумма *представленных* отчётов, исключая изменения к отчётам прошлых лет
				, uk_accepted money, uk_acceptedAccum money -- сумма *принятых* отчётов, исключая изменения к отчётам прошлых лет
				, uk_inProcess money, uk_inProcessAccum money -- сумма *рассматриваемых* отчётов, исключая изменения к отчётам прошлых лет
				, uk_returned money, uk_returnedAccum money -- сумма *возвращенных* отчётов, исключая изменения к отчётам прошлых лет
				, uk_notArrived money, uk_notArrivedAccum money -- сумма *не поступивших* отчётов, исключая изменения к отчётам прошлых лет
				-- относящиеся к прошлым годам. Формируются за счёт изменений к отчётам прошлых лет .....................................................................
				, uk_presentedPrevYears money, uk_presentedPrevYearsAccum money
				, uk_acceptedPrevYears money, uk_acceptedPrevYearsAccum money
				, uk_returnedPrevYears money, uk_returnedPrevYearsAccum money
				, uk_inProcessPrevYears money, uk_inProcessPrevYearsAccum money
				, uk_notArrivedPrevYears money, uk_notArrivedPrevYearsAccum money
				-- отчёты агентов. Окончание ----------------------------------------------------------------------------------------------------------------------------
				
				-- агентское вознаграждение -----------------------------------------------------------------------------------------------------------------------------
				, uk_agFeePresented money, uk_agFeePresentedAccum money, uk_agFeeAccepted money, uk_agFeeAcceptedAccum money
				, uk_agFeeInProcess money, uk_agFeeInProcessAccum money
				, uk_agFeeReturned money, uk_agFeeReturnedAccum money
				, uk_agFeeNotArrived money, uk_agFeeNotArrivedAccum money
				-- земельные участки ------------------------------------------------------------------------------------------------------------------------------------
				, uk_presentedRalp money, uk_presentedRalpAccum money, uk_acceptedRalp money, uk_acceptedRalpAccum money
				, uk_inProcessRalp money, uk_inProcessRalpAccum money
				, uk_returnedRalp money, uk_returnedRalpAccum money
				, uk_notArrivedRalp money, uk_notArrivedRalpAccum money
				-- хранение, стройконтроль, ОПИ -------------------------------------------------------------------------------------------------------------------------
				, uk_storageSum money, uk_storageSumAccum money, uk_cctSum money, uk_cctSumAccum money, uk_MnrlSum money, uk_MnrlSumAccum money
				-- общее ------------------------------------------------------------------------------------------------------------------------------------------------
				, uk_presentedTtl money, uk_presentedTtlAccum money -- *представлено* по всем видам освоения
				, uk_acceptedTtl money, uk_acceptedTtlAccum money -- *принято* по всем видам освоения
				, uk_restOfLimit money -- остаток лимита, если от него отнять *принято* по всем видам освоения
				, uk_restOfLimitInProcess money -- остаток лимита, если от него отнять *принято* по всем видам освоения и ещё отнять *рассматриваемое*
				, uk_inProcessTtl money, uk_inProcessTtlAccum money -- *рассматривается* по всем видам освоения
				, uk_acceptedAndInProcessTtl money, uk_acceptedAndInProcessTtlAccum money -- сумма *принято* и *рассматривается* по всем видам освоения
				, uk_returnedTtl money, uk_returnedTtlAccum money -- *возвращено* по всем видам освоения
				, uk_notArrivedTtl money, uk_notArrivedTtlAccum money -- *не поступило* по всем видам освоения
				-- освоение, виды и итоговое. Окончание +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- неизвестная схема. Окончание =========================================================================================================================

				-- агентская схема (неплан) =============================================================================================================================
				, np_lim money, np_iShKey int -- 14.10.2024 странно очень, какой у неплана может быть лимит... Но испорически так сложилось. 
				-- И в Access, в ipgChRsltPlCstPercent есть такая колонка есть. Оставим для обратной совместимости

				-- освоение, виды и итоговое ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- отчёты агентов ---------------------------------------------------------------------------------------------------------------------------------------
				-- относящиеся к любым годам ............................................................................................................................
				, np_presentedAll money, np_presentedAllAccum money -- сумма всех, без исключения, отчётов представленных по стройке
				, np_presentedAllModul money, np_presentedAllModulAccum money -- сумма всех, без исключения, отчётов представленных по стройке, взятая по модулю
				-- относящиеся к текущему году ..........................................................................................................................
				, np_presented money, np_presentedAccum money -- сумма *представленных* отчётов, исключая изменения к отчётам прошлых лет
				, np_accepted money, np_acceptedAccum money -- сумма *принятых* отчётов, исключая изменения к отчётам прошлых лет
				, np_inProcess money, np_inProcessAccum money -- сумма *рассматриваемых* отчётов, исключая изменения к отчётам прошлых лет
				, np_returned money, np_returnedAccum money -- сумма *возвращенных* отчётов, исключая изменения к отчётам прошлых лет
				, np_notArrived money, np_notArrivedAccum money -- сумма *не поступивших* отчётов, исключая изменения к отчётам прошлых лет
				-- относящиеся к прошлым годам. Формируются за счёт изменений к отчётам прошлых лет .....................................................................
				, np_presentedPrevYears money, np_presentedPrevYearsAccum money
				, np_acceptedPrevYears money, np_acceptedPrevYearsAccum money
				, np_returnedPrevYears money, np_returnedPrevYearsAccum money
				, np_inProcessPrevYears money, np_inProcessPrevYearsAccum money
				, np_notArrivedPrevYears money, np_notArrivedPrevYearsAccum money
				-- отчёты агентов. Окончание ----------------------------------------------------------------------------------------------------------------------------
				
				-- агентское вознаграждение -----------------------------------------------------------------------------------------------------------------------------
				, np_agFeePresented money, np_agFeePresentedAccum money, np_agFeeAccepted money, np_agFeeAcceptedAccum money
				, np_agFeeInProcess money, np_agFeeInProcessAccum money
				, np_agFeeReturned money, np_agFeeReturnedAccum money
				, np_agFeeNotArrived money, np_agFeeNotArrivedAccum money
				-- земельные участки ------------------------------------------------------------------------------------------------------------------------------------
				, np_presentedRalp money, np_presentedRalpAccum money, np_acceptedRalp money, np_acceptedRalpAccum money
				, np_inProcessRalp money, np_inProcessRalpAccum money
				, np_returnedRalp money, np_returnedRalpAccum money
				, np_notArrivedRalp money, np_notArrivedRalpAccum money
				-- хранение, стройконтроль, ОПИ -------------------------------------------------------------------------------------------------------------------------
				, np_storageSum money, np_storageSumAccum money, np_cctSum money, np_cctSumAccum money, np_MnrlSum money, np_MnrlSumAccum money
				-- общее ------------------------------------------------------------------------------------------------------------------------------------------------
				, np_presentedTtl money, np_presentedTtlAccum money -- *представлено* по всем видам освоения
				, np_acceptedTtl money, np_acceptedTtlAccum money -- *принято* по всем видам освоения
				, np_restOfLimit money -- остаток лимита, если от него отнять *принято* по всем видам освоения
				, np_restOfLimitInProcess money -- остаток лимита, если от него отнять *принято* по всем видам освоения и ещё отнять *рассматриваемое*
				, np_inProcessTtl money, np_inProcessTtlAccum money -- *рассматривается* по всем видам освоения
				, np_acceptedAndInProcessTtl money, np_acceptedAndInProcessTtlAccum money -- сумма *принято* и *рассматривается* по всем видам освоения
				, np_returnedTtl money, np_returnedTtlAccum money -- *возвращено* по всем видам освоения
				, np_notArrivedTtl money, np_notArrivedTtlAccum money -- *не поступило* по всем видам освоения
				-- освоение, виды и итоговое. Окончание +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- агентская схема (неплан). Окончание ==================================================================================================================

				-- прочие затраты =======================================================================================================================================
				-- отчёты агентов ---------------------------------------------------------------------------------------------------------------------------------------
				-- относящиеся к любым годам ............................................................................................................................
				, oh_presentedAll money, oh_presentedAllAccum money  -- сумма всех, без исключения, отчётов представленных по стройке
				, oh_presentedAllModul money, oh_presentedAllModulAccum money -- сумма всех, без исключения, отчётов представленных по стройке, взятая по модулю
				-- относящиеся к текущему году ..........................................................................................................................
				, oh_presented money, oh_presentedAccum money -- сумма *представленных* отчётов, исключая изменения к отчётам прошлых лет
				, oh_accepted money, oh_acceptedAccum money -- сумма *принятых* отчётов, исключая изменения к отчётам прошлых лет
				, oh_inProcess money, oh_inProcessAccum money -- сумма *рассматриваемых* отчётов, исключая изменения к отчётам прошлых лет
				, oh_returned money, oh_returnedAccum money -- сумма *возвращенных* отчётов, исключая изменения к отчётам прошлых лет
				, oh_notArrived money, oh_notArrivedAccum money -- сумма *не поступивших* отчётов, исключая изменения к отчётам прошлых лет
				-- относящиеся к прошлым годам. Формируются за счёт изменений к отчётам прошлых лет .....................................................................
				, oh_presentedPrevYears money, oh_presentedPrevYearsAccum money
				, oh_acceptedPrevYears money, oh_acceptedPrevYearsAccum money
				, oh_returnedPrevYears money, oh_returnedPrevYearsAccum money
				, oh_inProcessPrevYears money, oh_inProcessPrevYearsAccum money
				, oh_notArrivedPrevYears money, oh_notArrivedPrevYearsAccum money
				-- агентское вознаграждение -----------------------------------------------------------------------------------------------------------------------------
				-- 14.07.2023 добавил прочие отчёты для агентского вознаграждения
				, oh_agFeePresented money, oh_agFeePresentedAccum money, oh_agFeeAccepted money, oh_agFeeAcceptedAccum money
				, oh_agFeeReturned money, oh_agFeeReturnedAccum money
				, oh_agFeeInProcess money, oh_agFeeInProcessAccum money
				, oh_agFeeNotArrived money, oh_agFeeNotArrivedAccum money
				-- общее ------------------------------------------------------------------------------------------------------------------------------------------------
				, oh_presentedTtl money, oh_presentedTtlAccum money -- *представлено* по всем видам освоения
				, oh_acceptedTtl money, oh_acceptedTtlAccum money -- *принято* по всем видам освоения
				, oh_inProcessTtl money, oh_inProcessTtlAccum money
				, oh_acceptedAndInProcessTtl money, oh_acceptedAndInProcessTtlAccum money
				, oh_returnedTtl money, oh_returnedTtlAccum money
				, oh_notArrivedTtl money, oh_notArrivedTtlAccum money
				-- прочие затраты. Окончание ============================================================================================================================
		)
AS
BEGIN
	-- ******************************************************************************************************************************************************************
	-- область объявлений ***********************************************************************************************************************************************
	-- объявляем переменные
	declare @lsYyKey int -- ключ года цепочки инвестпрограмм
	declare @lsYy int -- год цепочки инвестпрограмм

	declare @spIpgChRsltCstUtl3_oneD table
		(
			yKey int, yyyy int, mKey int, mNum int, mCs nvarchar(255), mNm nvarchar(255), mQ nvarchar(255), mHy int
			, cstaInvestor int, ogaKey int, ogNm nvarchar(255), branch int, cstAgPnCode nvarchar(255), ipgKey int, ipgCount int
			-- агентская схема ======================================================================================================================
			, ag_lim money, ag_iShKey int
			-- отчёты агентов -----------------------------------------------------------------------------------------------------------------------
			, ag_presentedAll money, ag_presentedAllAccum money, ag_presentedAllModul money, ag_presentedAllModulAccum money
			, ag_presented money, ag_presentedAccum money, ag_accepted money, ag_acceptedAccum money
			, ag_returned money, ag_returnedAccum money
			, ag_inProcess money, ag_inProcessAccum money, ag_notArrived money, ag_notArrivedAccum money
			, ag_presentedPrevYears money, ag_presentedPrevYearsAccum money, ag_acceptedPrevYears money, ag_acceptedPrevYearsAccum money
			, ag_returnedPrevYears money, ag_returnedPrevYearsAccum money, ag_inProcessPrevYears money, ag_inProcessPrevYearsAccum money
			, ag_notArrivedPrevYears money, ag_notArrivedPrevYearsAccum money
			-- агентское вознаграждение -------------------------------------------------------------------------------------------------------------
			, ag_agFeePresented money, ag_agFeePresentedAccum money, ag_agFeeAccepted money, ag_agFeeAcceptedAccum money
			, ag_agFeeReturned money, ag_agFeeReturnedAccum money
			, ag_agFeeInProcess money, ag_agFeeInProcessAccum money, ag_agFeeNotArrived money, ag_agFeeNotArrivedAccum money
			-- земельные участки --------------------------------------------------------------------------------------------------------------------
			, ag_presentedRalp money, ag_presentedRalpAccum money, ag_acceptedRalp money, ag_acceptedRalpAccum money
			, ag_returnedRalp money, ag_returnedRalpAccum money
			, ag_inProcessRalp money, ag_inProcessRalpAccum money, ag_notArrivedRalp money, ag_notArrivedRalpAccum money
			-- хранение -----------------------------------------------------------------------------------------------------------------------------
			, ag_storageSum money, ag_storageSumAccum money, ag_cctSum money, ag_cctSumAccum money, ag_MnrlSum money, ag_MnrlSumAccum money
			-- общее --------------------------------------------------------------------------------------------------------------------------------
			, ag_presentedTtl money, ag_presentedTtlAccum money, ag_acceptedAndInProcessTtl money, ag_acceptedAndInProcessTtlAccum money
			, ag_acceptedTtl money, ag_acceptedTtlAccum money, ag_returnedTtl money, ag_returnedTtlAccum money
			, ag_inProcessTtl money, ag_inProcessTtlAccum money
			, ag_notArrivedTtl money, ag_notArrivedTtlAccum money
			, ag_restOfLimit money, ag_restOfLimitInProcess money
			-- агентская схема. Окончание ===========================================================================================================
			-- инвестиционная схема =================================================================================================================
			, iv_lim money, iv_iShKey int
			-- инвестиционная схема. Окончание ======================================================================================================
			-- инвестиционная схема (агентская, неплан) =============================================================================================
			, ia_lim money, ia_iShKey int
			-- отчёты агентов -----------------------------------------------------------------------------------------------------------------------
			, ia_presentedAll money, ia_presentedAllAccum money, ia_presentedAllModul money, ia_presentedAllModulAccum money
			, ia_presented money, ia_presentedAccum money, ia_accepted money, ia_acceptedAccum money
			, ia_returned money, ia_returnedAccum money
			, ia_inProcess money, ia_inProcessAccum money, ia_notArrived money, ia_notArrivedAccum money
			, ia_presentedPrevYears money, ia_presentedPrevYearsAccum money, ia_acceptedPrevYears money, ia_acceptedPrevYearsAccum money
			, ia_returnedPrevYears money, ia_returnedPrevYearsAccum money, ia_inProcessPrevYears money, ia_inProcessPrevYearsAccum money
			, ia_notArrivedPrevYears money, ia_notArrivedPrevYearsAccum money
			-- агентское вознаграждение -------------------------------------------------------------------------------------------------------------
			, ia_agFeePresented money, ia_agFeePresentedAccum money, ia_agFeeAccepted money, ia_agFeeAcceptedAccum money
			, ia_agFeeReturned money, ia_agFeeReturnedAccum money
			, ia_agFeeInProcess money, ia_agFeeInProcessAccum money, ia_agFeeNotArrived money, ia_agFeeNotArrivedAccum money
			-- земельные участки --------------------------------------------------------------------------------------------------------------------
			, ia_presentedRalp money, ia_presentedRalpAccum money, ia_acceptedRalp money, ia_acceptedRalpAccum money
			, ia_returnedRalp money, ia_returnedRalpAccum money
			, ia_inProcessRalp money, ia_inProcessRalpAccum money, ia_notArrivedRalp money, ia_notArrivedRalpAccum money
			-- хранение -----------------------------------------------------------------------------------------------------------------------------
			, ia_storageSum money, ia_storageSumAccum money, ia_cctSum money, ia_cctSumAccum money, ia_MnrlSum money, ia_MnrlSumAccum money
			-- общее --------------------------------------------------------------------------------------------------------------------------------
			, ia_presentedTtl money, ia_presentedTtlAccum money, ia_acceptedAndInProcessTtl money, ia_acceptedAndInProcessTtlAccum money
			, ia_acceptedTtl money, ia_acceptedTtlAccum money, ia_returnedTtl money, ia_returnedTtlAccum money
			, ia_inProcessTtl money, ia_inProcessTtlAccum money
			, ia_notArrivedTtl money, ia_notArrivedTtlAccum money
			, ia_restOfLimit money, ia_restOfLimitInProcess money
			-- инвестиционная схема (агентская, неплан). Окончание ==================================================================================
			-- неизвестная схема ====================================================================================================================
			, uk_lim money, uk_iShKey int
			-- отчёты агентов -----------------------------------------------------------------------------------------------------------------------
			, uk_presentedAll money, uk_presentedAllAccum money, uk_presentedAllModul money, uk_presentedAllModulAccum money
			, uk_presented money, uk_presentedAccum money, uk_accepted money, uk_acceptedAccum money
			, uk_returned money, uk_returnedAccum money
			, uk_inProcess money, uk_inProcessAccum money, uk_notArrived money, uk_notArrivedAccum money
			, uk_presentedPrevYears money, uk_presentedPrevYearsAccum money, uk_acceptedPrevYears money, uk_acceptedPrevYearsAccum money
			, uk_returnedPrevYears money, uk_returnedPrevYearsAccum money, uk_inProcessPrevYears money, uk_inProcessPrevYearsAccum money
			, uk_notArrivedPrevYears money, uk_notArrivedPrevYearsAccum money
			-- агентское вознаграждение -------------------------------------------------------------------------------------------------------------
			, uk_agFeePresented money, uk_agFeePresentedAccum money, uk_agFeeAccepted money, uk_agFeeAcceptedAccum money
			, uk_agFeeReturned money, uk_agFeeReturnedAccum money
			, uk_agFeeInProcess money, uk_agFeeInProcessAccum money, uk_agFeeNotArrived money, uk_agFeeNotArrivedAccum money
			-- земельные участки --------------------------------------------------------------------------------------------------------------------
			, uk_presentedRalp money, uk_presentedRalpAccum money, uk_acceptedRalp money, uk_acceptedRalpAccum money
			, uk_returnedRalp money, uk_returnedRalpAccum money
			, uk_inProcessRalp money, uk_inProcessRalpAccum money, uk_notArrivedRalp money, uk_notArrivedRalpAccum money
			-- хранение -----------------------------------------------------------------------------------------------------------------------------
			, uk_storageSum money, uk_storageSumAccum money, uk_cctSum money, uk_cctSumAccum money, uk_MnrlSum money, uk_MnrlSumAccum money
			-- общее --------------------------------------------------------------------------------------------------------------------------------
			, uk_presentedTtl money, uk_presentedTtlAccum money, uk_acceptedAndInProcessTtl money, uk_acceptedAndInProcessTtlAccum money
			, uk_acceptedTtl money, uk_acceptedTtlAccum money, uk_returnedTtl money, uk_returnedTtlAccum money
			, uk_inProcessTtl money, uk_inProcessTtlAccum money
			, uk_notArrivedTtl money, uk_notArrivedTtlAccum money
			, uk_restOfLimit money, uk_restOfLimitInProcess money
			-- неизвестная схема. Окончание =========================================================================================================
			-- агентская схема (неплан) =============================================================================================================
			, np_lim money, np_iShKey int
			-- отчёты агентов -----------------------------------------------------------------------------------------------------------------------
			, np_presentedAll money, np_presentedAllAccum money, np_presentedAllModul money, np_presentedAllModulAccum money
			, np_presented money, np_presentedAccum money, np_accepted money, np_acceptedAccum money
			, np_returned money, np_returnedAccum money
			, np_inProcess money, np_inProcessAccum money, np_notArrived money, np_notArrivedAccum money
			, np_presentedPrevYears money, np_presentedPrevYearsAccum money, np_acceptedPrevYears money, np_acceptedPrevYearsAccum money
			, np_returnedPrevYears money, np_returnedPrevYearsAccum money, np_inProcessPrevYears money, np_inProcessPrevYearsAccum money
			, np_notArrivedPrevYears money, np_notArrivedPrevYearsAccum money
			-- агентское вознаграждение -------------------------------------------------------------------------------------------------------------
			, np_agFeePresented money, np_agFeePresentedAccum money, np_agFeeAccepted money, np_agFeeAcceptedAccum money
			, np_agFeeReturned money, np_agFeeReturnedAccum money
			, np_agFeeInProcess money, np_agFeeInProcessAccum money, np_agFeeNotArrived money, np_agFeeNotArrivedAccum money
			-- земельные участки --------------------------------------------------------------------------------------------------------------------
			, np_presentedRalp money, np_presentedRalpAccum money, np_acceptedRalp money, np_acceptedRalpAccum money
			, np_returnedRalp money, np_returnedRalpAccum money
			, np_inProcessRalp money, np_inProcessRalpAccum money, np_notArrivedRalp money, np_notArrivedRalpAccum money
			-- хранение -----------------------------------------------------------------------------------------------------------------------------
			, np_storageSum money, np_storageSumAccum money, np_cctSum money, np_cctSumAccum money, np_MnrlSum money, np_MnrlSumAccum money
			-- общее --------------------------------------------------------------------------------------------------------------------------------
			, np_presentedTtl money, np_presentedTtlAccum money, np_acceptedAndInProcessTtl money, np_acceptedAndInProcessTtlAccum money
			, np_acceptedTtl money, np_acceptedTtlAccum money, np_returnedTtl money, np_returnedTtlAccum money
			, np_inProcessTtl money, np_inProcessTtlAccum money
			, np_notArrivedTtl money, np_notArrivedTtlAccum money
			, np_restOfLimit money, np_restOfLimitInProcess money
			-- агентская схема (неплан). Окончание ==================================================================================================
			-- прочие затраты =======================================================================================================================
			-- отчёты агентов -----------------------------------------------------------------------------------------------------------------------
			, oh_presentedAll money, oh_presentedAllAccum money, oh_presentedAllModul money, oh_presentedAllModulAccum money
			, oh_presented money, oh_presentedAccum money, oh_accepted money, oh_acceptedAccum money
			, oh_returned money, oh_returnedAccum money
			, oh_inProcess money, oh_inProcessAccum money, oh_notArrived money, oh_notArrivedAccum money
			, oh_presentedPrevYears money, oh_presentedPrevYearsAccum money, oh_acceptedPrevYears money, oh_acceptedPrevYearsAccum money
			, oh_returnedPrevYears money, oh_returnedPrevYearsAccum money, oh_inProcessPrevYears money, oh_inProcessPrevYearsAccum money
			, oh_notArrivedPrevYears money, oh_notArrivedPrevYearsAccum money
			-- 14.07.2023 добавил прочие отчёты для агентского вознаграждения
			-- агентское вознаграждение -------------------------------------------------------------------------------------------------------------
			, oh_agFeePresented money, oh_agFeePresentedAccum money, oh_agFeeAccepted money, oh_agFeeAcceptedAccum money
			, oh_agFeeReturned money, oh_agFeeReturnedAccum money
			, oh_agFeeInProcess money, oh_agFeeInProcessAccum money, oh_agFeeNotArrived money, oh_agFeeNotArrivedAccum money
			-- общее --------------------------------------------------------------------------------------------------------------------------------
			, oh_presentedTtl money, oh_presentedTtlAccum money, oh_acceptedAndInProcessTtl money, oh_acceptedAndInProcessTtlAccum money
			, oh_acceptedTtl money, oh_acceptedTtlAccum money, oh_returnedTtl money, oh_returnedTtlAccum money
			, oh_inProcessTtl money, oh_inProcessTtlAccum money
			, oh_notArrivedTtl money, oh_notArrivedTtlAccum money
			, oh_restOfLimit money, oh_restOfLimitInProcess money
			--, oh_percentDev float, oh_percentDevInProcess float
			-- прочие затраты. Окончание ============================================================================================================
		)

	declare @dt table (dateRslt date, ipgKey int)

	-- область объявлений. Окончание ***************************************************************************************************************************************
	-- *********************************************************************************************************************************************************************

	-- *********************************************************************************************************************************************************************
	-- область вычислений **************************************************************************************************************************************************

	insert into @spIpgChRsltCstUtl3_oneD 
		(
			yKey, yyyy, mKey, mNum, mCs, mNm, mQ, mHy
			, cstaInvestor, ogaKey, ogNm, branch, cstAgPnCode, ipgKey, ipgCount
			-- агентская схема ======================================================================================================================
			, ag_lim, ag_iShKey
			-- отчёты агентов -----------------------------------------------------------------------------------------------------------------------
			, ag_presentedAll, ag_presentedAllAccum, ag_presentedAllModul, ag_presentedAllModulAccum
			, ag_presented, ag_presentedAccum, ag_accepted, ag_acceptedAccum
			, ag_returned, ag_returnedAccum
			, ag_inProcess, ag_inProcessAccum, ag_notArrived, ag_notArrivedAccum
			, ag_presentedPrevYears, ag_presentedPrevYearsAccum, ag_acceptedPrevYears, ag_acceptedPrevYearsAccum
			, ag_returnedPrevYears, ag_returnedPrevYearsAccum, ag_inProcessPrevYears, ag_inProcessPrevYearsAccum
			, ag_notArrivedPrevYears, ag_notArrivedPrevYearsAccum
			-- агентское вознаграждение -------------------------------------------------------------------------------------------------------------
			, ag_agFeePresented, ag_agFeePresentedAccum, ag_agFeeAccepted, ag_agFeeAcceptedAccum
			, ag_agFeeReturned, ag_agFeeReturnedAccum
			, ag_agFeeInProcess, ag_agFeeInProcessAccum, ag_agFeeNotArrived, ag_agFeeNotArrivedAccum
			-- земельные участки --------------------------------------------------------------------------------------------------------------------
			, ag_presentedRalp, ag_presentedRalpAccum, ag_acceptedRalp, ag_acceptedRalpAccum
			, ag_returnedRalp, ag_returnedRalpAccum
			, ag_inProcessRalp, ag_inProcessRalpAccum, ag_notArrivedRalp, ag_notArrivedRalpAccum
			-- хранение -----------------------------------------------------------------------------------------------------------------------------
			, ag_storageSum, ag_storageSumAccum, ag_cctSum, ag_cctSumAccum, ag_MnrlSum, ag_MnrlSumAccum
			-- общее --------------------------------------------------------------------------------------------------------------------------------
			, ag_presentedTtl, ag_presentedTtlAccum, ag_acceptedAndInProcessTtl, ag_acceptedAndInProcessTtlAccum
			, ag_acceptedTtl, ag_acceptedTtlAccum, ag_returnedTtl, ag_returnedTtlAccum
			, ag_inProcessTtl, ag_inProcessTtlAccum
			, ag_notArrivedTtl, ag_notArrivedTtlAccum
			, ag_restOfLimit, ag_restOfLimitInProcess
			--, ag_percentDev, ag_percentDevInProcess
			-- агентская схема. Окончание ===========================================================================================================
			-- инвестиционная схема =================================================================================================================
			, iv_lim, iv_iShKey
			-- инвестиционная схема. Окончание ======================================================================================================
			-- инвестиционная схема (агентская, неплан) =============================================================================================
			, ia_lim, ia_iShKey
			-- отчёты агентов -----------------------------------------------------------------------------------------------------------------------
			, ia_presentedAll, ia_presentedAllAccum, ia_presentedAllModul, ia_presentedAllModulAccum
			, ia_presented, ia_presentedAccum, ia_accepted, ia_acceptedAccum
			, ia_returned, ia_returnedAccum
			, ia_inProcess, ia_inProcessAccum, ia_notArrived, ia_notArrivedAccum
			, ia_presentedPrevYears, ia_presentedPrevYearsAccum, ia_acceptedPrevYears, ia_acceptedPrevYearsAccum
			, ia_returnedPrevYears, ia_returnedPrevYearsAccum, ia_inProcessPrevYears, ia_inProcessPrevYearsAccum
			, ia_notArrivedPrevYears, ia_notArrivedPrevYearsAccum
			-- агентское вознаграждение -------------------------------------------------------------------------------------------------------------
			, ia_agFeePresented, ia_agFeePresentedAccum, ia_agFeeAccepted, ia_agFeeAcceptedAccum
			, ia_agFeeReturned, ia_agFeeReturnedAccum
			, ia_agFeeInProcess, ia_agFeeInProcessAccum, ia_agFeeNotArrived, ia_agFeeNotArrivedAccum
			-- земельные участки --------------------------------------------------------------------------------------------------------------------
			, ia_presentedRalp, ia_presentedRalpAccum, ia_acceptedRalp, ia_acceptedRalpAccum
			, ia_returnedRalp, ia_returnedRalpAccum
			, ia_inProcessRalp, ia_inProcessRalpAccum, ia_notArrivedRalp, ia_notArrivedRalpAccum
			-- хранение -----------------------------------------------------------------------------------------------------------------------------
			, ia_storageSum, ia_storageSumAccum, ia_cctSum, ia_cctSumAccum, ia_MnrlSum, ia_MnrlSumAccum
			-- общее --------------------------------------------------------------------------------------------------------------------------------
			, ia_presentedTtl, ia_presentedTtlAccum, ia_acceptedAndInProcessTtl, ia_acceptedAndInProcessTtlAccum
			, ia_acceptedTtl, ia_acceptedTtlAccum, ia_returnedTtl, ia_returnedTtlAccum
			, ia_inProcessTtl, ia_inProcessTtlAccum
			, ia_notArrivedTtl, ia_notArrivedTtlAccum
			, ia_restOfLimit, ia_restOfLimitInProcess
			--, ia_percentDev, ia_percentDevInProcess
			-- инвестиционная схема (агентская, неплан). Окончание ==================================================================================
			-- неизвестная схема ====================================================================================================================
			, uk_lim, uk_iShKey
			-- отчёты агентов -----------------------------------------------------------------------------------------------------------------------
			, uk_presentedAll, uk_presentedAllAccum, uk_presentedAllModul, uk_presentedAllModulAccum
			, uk_presented, uk_presentedAccum, uk_accepted, uk_acceptedAccum
			, uk_returned, uk_returnedAccum
			, uk_inProcess, uk_inProcessAccum, uk_notArrived, uk_notArrivedAccum
			, uk_presentedPrevYears, uk_presentedPrevYearsAccum, uk_acceptedPrevYears, uk_acceptedPrevYearsAccum
			, uk_returnedPrevYears, uk_returnedPrevYearsAccum, uk_inProcessPrevYears, uk_inProcessPrevYearsAccum
			, uk_notArrivedPrevYears, uk_notArrivedPrevYearsAccum
			-- агентское вознаграждение -------------------------------------------------------------------------------------------------------------
			, uk_agFeePresented, uk_agFeePresentedAccum, uk_agFeeAccepted, uk_agFeeAcceptedAccum
			, uk_agFeeReturned, uk_agFeeReturnedAccum
			, uk_agFeeInProcess, uk_agFeeInProcessAccum, uk_agFeeNotArrived, uk_agFeeNotArrivedAccum
			-- земельные участки --------------------------------------------------------------------------------------------------------------------
			, uk_presentedRalp, uk_presentedRalpAccum, uk_acceptedRalp, uk_acceptedRalpAccum
			, uk_returnedRalp, uk_returnedRalpAccum
			, uk_inProcessRalp, uk_inProcessRalpAccum, uk_notArrivedRalp, uk_notArrivedRalpAccum
			-- хранение -----------------------------------------------------------------------------------------------------------------------------
			, uk_storageSum, uk_storageSumAccum, uk_cctSum, uk_cctSumAccum, uk_MnrlSum, uk_MnrlSumAccum
			-- общее --------------------------------------------------------------------------------------------------------------------------------
			, uk_presentedTtl, uk_presentedTtlAccum, uk_acceptedAndInProcessTtl, uk_acceptedAndInProcessTtlAccum
			, uk_acceptedTtl, uk_acceptedTtlAccum, uk_returnedTtl, uk_returnedTtlAccum
			, uk_inProcessTtl, uk_inProcessTtlAccum
			, uk_notArrivedTtl, uk_notArrivedTtlAccum
			, uk_restOfLimit, uk_restOfLimitInProcess
			--, uk_percentDev, uk_percentDevInProcess
			-- неизвестная схема. Окончание =========================================================================================================
			-- агентская схема (неплан) =============================================================================================================
			, np_lim, np_iShKey
			-- отчёты агентов -----------------------------------------------------------------------------------------------------------------------
			, np_presentedAll, np_presentedAllAccum, np_presentedAllModul, np_presentedAllModulAccum
			, np_presented, np_presentedAccum, np_accepted, np_acceptedAccum
			, np_returned, np_returnedAccum
			, np_inProcess, np_inProcessAccum, np_notArrived, np_notArrivedAccum
			, np_presentedPrevYears, np_presentedPrevYearsAccum, np_acceptedPrevYears, np_acceptedPrevYearsAccum
			, np_returnedPrevYears, np_returnedPrevYearsAccum, np_inProcessPrevYears, np_inProcessPrevYearsAccum
			, np_notArrivedPrevYears, np_notArrivedPrevYearsAccum
			-- агентское вознаграждение -------------------------------------------------------------------------------------------------------------
			, np_agFeePresented, np_agFeePresentedAccum, np_agFeeAccepted, np_agFeeAcceptedAccum
			, np_agFeeReturned, np_agFeeReturnedAccum
			, np_agFeeInProcess, np_agFeeInProcessAccum, np_agFeeNotArrived, np_agFeeNotArrivedAccum
			-- земельные участки --------------------------------------------------------------------------------------------------------------------
			, np_presentedRalp, np_presentedRalpAccum, np_acceptedRalp, np_acceptedRalpAccum
			, np_returnedRalp, np_returnedRalpAccum
			, np_inProcessRalp, np_inProcessRalpAccum, np_notArrivedRalp, np_notArrivedRalpAccum
			-- хранение -----------------------------------------------------------------------------------------------------------------------------
			, np_storageSum, np_storageSumAccum, np_cctSum, np_cctSumAccum, np_MnrlSum, np_MnrlSumAccum
			-- общее --------------------------------------------------------------------------------------------------------------------------------
			, np_presentedTtl, np_presentedTtlAccum, np_acceptedAndInProcessTtl, np_acceptedAndInProcessTtlAccum
			, np_acceptedTtl, np_acceptedTtlAccum, np_returnedTtl, np_returnedTtlAccum
			, np_inProcessTtl, np_inProcessTtlAccum
			, np_notArrivedTtl, np_notArrivedTtlAccum
			, np_restOfLimit, np_restOfLimitInProcess
			--, np_percentDev, np_percentDevInProcess
			-- агентская схема (неплан). Окончание ==================================================================================================
			-- прочие затраты =======================================================================================================================
			-- отчёты агентов -----------------------------------------------------------------------------------------------------------------------
			, oh_presentedAll, oh_presentedAllAccum, oh_presentedAllModul, oh_presentedAllModulAccum
			, oh_presented, oh_presentedAccum, oh_accepted, oh_acceptedAccum
			, oh_returned, oh_returnedAccum
			, oh_inProcess, oh_inProcessAccum, oh_notArrived, oh_notArrivedAccum
			, oh_presentedPrevYears, oh_presentedPrevYearsAccum, oh_acceptedPrevYears, oh_acceptedPrevYearsAccum
			, oh_returnedPrevYears, oh_returnedPrevYearsAccum, oh_inProcessPrevYears, oh_inProcessPrevYearsAccum
			, oh_notArrivedPrevYears, oh_notArrivedPrevYearsAccum
			-- 14.07.2023 добавил прочие отчёты для агентского вознаграждения
			-- агентское вознаграждение -------------------------------------------------------------------------------------------------------------
			, oh_agFeePresented, oh_agFeePresentedAccum, oh_agFeeAccepted, oh_agFeeAcceptedAccum
			, oh_agFeeReturned, oh_agFeeReturnedAccum
			, oh_agFeeInProcess, oh_agFeeInProcessAccum, oh_agFeeNotArrived, oh_agFeeNotArrivedAccum
			-- общее --------------------------------------------------------------------------------------------------------------------------------
			, oh_presentedTtl, oh_presentedTtlAccum, oh_acceptedAndInProcessTtl, oh_acceptedAndInProcessTtlAccum
			, oh_acceptedTtl, oh_acceptedTtlAccum, oh_returnedTtl, oh_returnedTtlAccum
			, oh_inProcessTtl, oh_inProcessTtlAccum
			, oh_notArrivedTtl, oh_notArrivedTtlAccum
			, oh_restOfLimit, oh_restOfLimitInProcess
			--, oh_percentDev, oh_percentDevInProcess
			-- прочие затраты. Окончание ============================================================================================================
		)
	select 
		t.yKey, t.yyyy, t.mKey, t.mNum, t.mCs, t.mNm, t.mQ, t.mHy, t.cstaInvestor, t.ogaKey, t.ogNm, t.branch, t.cstAgPnCode, t.ipgKey 
		, t.ipgCount
		--, count(t.yKey) as ccc -- эта штука показывает сколько раз в инвестпрограмме имеется стройка. 18.09.2024, например, два раза здесь Л ах та
		-- агентская схема ======================================================================================================================
		, sum(case when typeGrTtl = '2. Агентская, план' then lim end) as ag_lim
		, avg(case when typeGrTtl = '2. Агентская, план' then iShKey end) as ag_iShKey
		-- отчёты агентов -----------------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '2. Агентская, план' then presentedAll end) as ag_presentedAll
		, sum(case when typeGrTtl = '2. Агентская, план' then presentedAllAccum end) as ag_presentedAllAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then presentedAllModul end) as ag_presentedAllModul
		, sum(case when typeGrTtl = '2. Агентская, план' then presentedAllModulAccum end) as ag_presentedAllModulAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then presented end) as ag_presented
		, sum(case when typeGrTtl = '2. Агентская, план' then presentedAccum end) as ag_presentedAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then accepted end) as ag_accepted
		, sum(case when typeGrTtl = '2. Агентская, план' then acceptedAccum end) as ag_acceptedAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then returned end) as ag_returned
		, sum(case when typeGrTtl = '2. Агентская, план' then returnedAccum end) as ag_returnedAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then inProcess end) as ag_inProcess
		, sum(case when typeGrTtl = '2. Агентская, план' then inProcessAccum end) as ag_inProcessAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then notArrived end) as ag_notArrived
		, sum(case when typeGrTtl = '2. Агентская, план' then notArrivedAccum end) as ag_notArrivedAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then presentedPrevYears end) as ag_presentedPrevYears
		, sum(case when typeGrTtl = '2. Агентская, план' then presentedPrevYearsAccum end) as ag_presentedPrevYearsAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then acceptedPrevYears end) as ag_acceptedPrevYears
		, sum(case when typeGrTtl = '2. Агентская, план' then acceptedPrevYearsAccum end) as ag_acceptedPrevYearsAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then returnedPrevYears end) as ag_returnedPrevYears
		, sum(case when typeGrTtl = '2. Агентская, план' then returnedPrevYearsAccum end) as ag_returnedPrevYearsAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then inProcessPrevYears end) as ag_inProcessPrevYears
		, sum(case when typeGrTtl = '2. Агентская, план' then inProcessPrevYearsAccum end) as ag_inProcessPrevYearsAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then notArrivedPrevYears end) as ag_notArrivedPrevYears
		, sum(case when typeGrTtl = '2. Агентская, план' then notArrivedPrevYearsAccum end) as ag_notArrivedPrevYearsAccum
		-- агентское вознаграждение -------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '2. Агентская, план' then agFeePresented end) as ag_agFeePresented
		, sum(case when typeGrTtl = '2. Агентская, план' then agFeePresentedAccum end) as ag_agFeePresentedAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then agFeeAccepted end) as ag_agFeeAccepted
		, sum(case when typeGrTtl = '2. Агентская, план' then agFeeAcceptedAccum end) as ag_agFeeAcceptedAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then agFeeReturned end) as ag_agFeeReturned
		, sum(case when typeGrTtl = '2. Агентская, план' then agFeeReturnedAccum end) as ag_agFeeReturnedAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then agFeeInProcess end) as ag_agFeeInProcess
		, sum(case when typeGrTtl = '2. Агентская, план' then agFeeInProcessAccum end) as ag_agFeeInProcessAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then agFeeNotArrived end) as ag_agFeeNotArrived
		, sum(case when typeGrTtl = '2. Агентская, план' then agFeeNotArrivedAccum end) as ag_agFeeNotArrivedAccum
		-- земельные участки --------------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '2. Агентская, план' then presentedRalp end) as ag_presentedRalp
		, sum(case when typeGrTtl = '2. Агентская, план' then presentedRalpAccum end) as ag_presentedRalpAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then acceptedRalp end) as ag_acceptedRalp
		, sum(case when typeGrTtl = '2. Агентская, план' then acceptedRalpAccum end) as ag_acceptedRalpAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then returnedRalp end) as ag_returnedRalp
		, sum(case when typeGrTtl = '2. Агентская, план' then returnedRalpAccum end) as ag_returnedRalpAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then inProcessRalp end) as ag_inProcessRalp
		, sum(case when typeGrTtl = '2. Агентская, план' then inProcessRalpAccum end) as ag_inProcessRalpAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then notArrivedRalp end) as ag_notArrivedRalp
		, sum(case when typeGrTtl = '2. Агентская, план' then notArrivedRalpAccum end) as ag_notArrivedRalpAccum
		-- хранение -----------------------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '2. Агентская, план' then storageSum end) as ag_storageSum
		, sum(case when typeGrTtl = '2. Агентская, план' then storageSumAccum end) as ag_storageSumAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then cctSum end) as ag_cctSum
		, sum(case when typeGrTtl = '2. Агентская, план' then cctSumAccum end) as ag_cctSumAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then MnrlSum end) as ag_MnrlSum
		, sum(case when typeGrTtl = '2. Агентская, план' then MnrlSumAccum end) as ag_MnrlSumAccum
		-- общее --------------------------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '2. Агентская, план' then presentedTtl end) as ag_presentedTtl
		, sum(case when typeGrTtl = '2. Агентская, план' then presentedTtlAccum end) as ag_presentedTtlAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then acceptedAndInProcessTtl end) as ag_acceptedAndInProcessTtl
		, sum(case when typeGrTtl = '2. Агентская, план' then acceptedAndInProcessTtlAccum end) as ag_acceptedAndInProcessTtlAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then acceptedTtl end) as ag_acceptedTtl
		, sum(case when typeGrTtl = '2. Агентская, план' then acceptedTtlAccum end) as ag_acceptedTtlAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then returnedTtl end) as ag_returnedTtl
		, sum(case when typeGrTtl = '2. Агентская, план' then returnedTtlAccum end) as ag_returnedTtlAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then inProcessTtl end) as ag_inProcessTtl
		, sum(case when typeGrTtl = '2. Агентская, план' then inProcessTtlAccum end) as ag_inProcessTtlAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then notArrivedTtl end) as ag_notArrivedTtl
		, sum(case when typeGrTtl = '2. Агентская, план' then notArrivedTtlAccum end) as ag_notArrivedTtlAccum
		, sum(case when typeGrTtl = '2. Агентская, план' then restOfLimit end) as ag_restOfLimit
		, sum(case when typeGrTtl = '2. Агентская, план' then restOfLimitInProcess end) as ag_restOfLimitInProcess
		--, sum(case when typeGrTtl = '2. Агентская, план' then percentDev end) as ag_percentDev
		--, sum(case when typeGrTtl = '2. Агентская, план' then percentDevInProcess end) as ag_percentDevInProcess
		-- агентская схема. Окончание ===========================================================================================================
		-- инвестиционная схема =================================================================================================================
		, sum(case when typeGrTtl = '1. Инвестиционная' then lim end) as iv_lim
		, avg(case when typeGrTtl = '1. Инвестиционная' then iShKey end) as iv_iShKey
		-- инвестиционная схема. Окончание ======================================================================================================
		-- инвестиционная схема (агентская, неплан) =============================================================================================
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then lim end) as ia_lim
		, avg(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then iShKey end) as ia_iShKey
		-- отчёты агентов -----------------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then presentedAll end) as ia_presentedAll
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then presentedAllAccum end) as ia_presentedAllAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then presentedAllModul end) as ia_presentedAllModul
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then presentedAllModulAccum end) as ia_presentedAllModulAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then presented end) as ia_presented
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then presentedAccum end) as ia_presentedAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then accepted end) as ia_accepted
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then acceptedAccum end) as ia_acceptedAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then returned end) as ia_returned
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then returnedAccum end) as ia_returnedAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then inProcess end) as ia_inProcess
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then inProcessAccum end) as ia_inProcessAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then notArrived end) as ia_notArrived
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then notArrivedAccum end) as ia_notArrivedAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then presentedPrevYears end) as ia_presentedPrevYears
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then presentedPrevYearsAccum end) as ia_presentedPrevYearsAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then acceptedPrevYears end) as ia_acceptedPrevYears
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then acceptedPrevYearsAccum end) as ia_acceptedPrevYearsAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then returnedPrevYears end) as ia_returnedPrevYears
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then returnedPrevYearsAccum end) as ia_returnedPrevYearsAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then inProcessPrevYears end) as ia_inProcessPrevYears
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then inProcessPrevYearsAccum end) as ia_inProcessPrevYearsAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then notArrivedPrevYears end) as ia_notArrivedPrevYears
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then notArrivedPrevYearsAccum end) as ia_notArrivedPrevYearsAccum
		-- агентское вознаграждение -------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then agFeePresented end) as ia_agFeePresented
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then agFeePresentedAccum end) as ia_agFeePresentedAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then agFeeAccepted end) as ia_agFeeAccepted
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then agFeeAcceptedAccum end) as ia_agFeeAcceptedAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then agFeeReturned end) as ia_agFeeReturned
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then agFeeReturnedAccum end) as ia_agFeeReturnedAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then agFeeInProcess end) as ia_agFeeInProcess
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then agFeeInProcessAccum end) as ia_agFeeInProcessAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then agFeeNotArrived end) as ia_agFeeNotArrived
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then agFeeNotArrivedAccum end) as ia_agFeeNotArrivedAccum
		-- земельные участки --------------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then presentedRalp end) as ia_presentedRalp
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then presentedRalpAccum end) as ia_presentedRalpAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then acceptedRalp end) as ia_acceptedRalp
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then acceptedRalpAccum end) as ia_acceptedRalpAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then returnedRalp end) as ia_returnedRalp
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then returnedRalpAccum end) as ia_returnedRalpAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then inProcessRalp end) as ia_inProcessRalp
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then inProcessRalpAccum end) as ia_inProcessRalpAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then notArrivedRalp end) as ia_notArrivedRalp
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then notArrivedRalpAccum end) as ia_notArrivedRalpAccum
		-- хранение -----------------------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then storageSum end) as ia_storageSum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then storageSumAccum end) as ia_storageSumAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then cctSum end) as ia_cctSum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then cctSumAccum end) as ia_cctSumAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then MnrlSum end) as ia_MnrlSum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then MnrlSumAccum end) as ia_MnrlSumAccum
		-- общее --------------------------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then presentedTtl end) as ia_presentedTtl
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then presentedTtlAccum end) as ia_presentedTtlAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then acceptedAndInProcessTtl end) as ia_acceptedAndInProcessTtl
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then acceptedAndInProcessTtlAccum end) as ia_acceptedAndInProcessTtlAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then acceptedTtl end) as ia_acceptedTtl
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then acceptedTtlAccum end) as ia_acceptedTtlAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then returnedTtl end) as ia_returnedTtl
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then returnedTtlAccum end) as ia_returnedTtlAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then inProcessTtl end) as ia_inProcessTtl
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then inProcessTtlAccum end) as ia_inProcessTtlAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then notArrivedTtl end) as ia_notArrivedTtl
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then notArrivedTtlAccum end) as ia_notArrivedTtlAccum
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then restOfLimit end) as ia_restOfLimit
		, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then restOfLimitInProcess end) as ia_restOfLimitInProcess
		--, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then percentDev end) as ia_percentDev
		--, sum(case when typeGrTtl = '1.2. Инв. (Аг., неплан)' then percentDevInProcess end) as ia_percentDevInProcess
		-- инвестиционная схема (агентская, неплан). Окончание ==================================================================================
		-- неизвестная схема ====================================================================================================================
		, sum(case when typeGrTtl = '3. Неизвестная схема' then lim end) as uk_lim
		, avg(case when typeGrTtl = '3. Неизвестная схема' then iShKey end) as uk_iShKey
		-- отчёты агентов -----------------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '3. Неизвестная схема' then presentedAll end) as uk_presentedAll
		, sum(case when typeGrTtl = '3. Неизвестная схема' then presentedAllAccum end) as uk_presentedAllAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then presentedAllModul end) as uk_presentedAllModul
		, sum(case when typeGrTtl = '3. Неизвестная схема' then presentedAllModulAccum end) as uk_presentedAllModulAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then presented end) as uk_presented
		, sum(case when typeGrTtl = '3. Неизвестная схема' then presentedAccum end) as uk_presentedAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then accepted end) as uk_accepted
		, sum(case when typeGrTtl = '3. Неизвестная схема' then acceptedAccum end) as uk_acceptedAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then returned end) as uk_returned
		, sum(case when typeGrTtl = '3. Неизвестная схема' then returnedAccum end) as uk_returnedAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then inProcess end) as uk_inProcess
		, sum(case when typeGrTtl = '3. Неизвестная схема' then inProcessAccum end) as uk_inProcessAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then notArrived end) as uk_notArrived
		, sum(case when typeGrTtl = '3. Неизвестная схема' then notArrivedAccum end) as uk_notArrivedAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then presentedPrevYears end) as uk_presentedPrevYears
		, sum(case when typeGrTtl = '3. Неизвестная схема' then presentedPrevYearsAccum end) as uk_presentedPrevYearsAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then acceptedPrevYears end) as uk_acceptedPrevYears
		, sum(case when typeGrTtl = '3. Неизвестная схема' then acceptedPrevYearsAccum end) as uk_acceptedPrevYearsAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then returnedPrevYears end) as uk_returnedPrevYears
		, sum(case when typeGrTtl = '3. Неизвестная схема' then returnedPrevYearsAccum end) as uk_returnedPrevYearsAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then inProcessPrevYears end) as uk_inProcessPrevYears
		, sum(case when typeGrTtl = '3. Неизвестная схема' then inProcessPrevYearsAccum end) as uk_inProcessPrevYearsAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then notArrivedPrevYears end) as uk_notArrivedPrevYears
		, sum(case when typeGrTtl = '3. Неизвестная схема' then notArrivedPrevYearsAccum end) as uk_notArrivedPrevYearsAccum
		-- агентское вознаграждение -------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '3. Неизвестная схема' then agFeePresented end) as uk_agFeePresented
		, sum(case when typeGrTtl = '3. Неизвестная схема' then agFeePresentedAccum end) as uk_agFeePresentedAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then agFeeAccepted end) as uk_agFeeAccepted
		, sum(case when typeGrTtl = '3. Неизвестная схема' then agFeeAcceptedAccum end) as uk_agFeeAcceptedAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then agFeeReturned end) as uk_agFeeReturned
		, sum(case when typeGrTtl = '3. Неизвестная схема' then agFeeReturnedAccum end) as uk_agFeeReturnedAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then agFeeInProcess end) as uk_agFeeInProcess
		, sum(case when typeGrTtl = '3. Неизвестная схема' then agFeeInProcessAccum end) as uk_agFeeInProcessAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then agFeeNotArrived end) as uk_agFeeNotArrived
		, sum(case when typeGrTtl = '3. Неизвестная схема' then agFeeNotArrivedAccum end) as uk_agFeeNotArrivedAccum
		-- земельные участки --------------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '3. Неизвестная схема' then presentedRalp end) as uk_presentedRalp
		, sum(case when typeGrTtl = '3. Неизвестная схема' then presentedRalpAccum end) as uk_presentedRalpAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then acceptedRalp end) as uk_acceptedRalp
		, sum(case when typeGrTtl = '3. Неизвестная схема' then acceptedRalpAccum end) as uk_acceptedRalpAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then returnedRalp end) as uk_returnedRalp
		, sum(case when typeGrTtl = '3. Неизвестная схема' then returnedRalpAccum end) as uk_returnedRalpAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then inProcessRalp end) as uk_inProcessRalp
		, sum(case when typeGrTtl = '3. Неизвестная схема' then inProcessRalpAccum end) as uk_inProcessRalpAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then notArrivedRalp end) as uk_notArrivedRalp
		, sum(case when typeGrTtl = '3. Неизвестная схема' then notArrivedRalpAccum end) as uk_notArrivedRalpAccum
		-- хранение -----------------------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '3. Неизвестная схема' then storageSum end) as uk_storageSum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then storageSumAccum end) as uk_storageSumAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then cctSum end) as uk_cctSum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then cctSumAccum end) as uk_cctSumAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then MnrlSum end) as uk_MnrlSum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then MnrlSumAccum end) as uk_MnrlSumAccum
		-- общее --------------------------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '3. Неизвестная схема' then presentedTtl end) as uk_presentedTtl
		, sum(case when typeGrTtl = '3. Неизвестная схема' then presentedTtlAccum end) as uk_presentedTtlAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then acceptedAndInProcessTtl end) as uk_acceptedAndInProcessTtl
		, sum(case when typeGrTtl = '3. Неизвестная схема' then acceptedAndInProcessTtlAccum end) as uk_acceptedAndInProcessTtlAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then acceptedTtl end) as uk_acceptedTtl
		, sum(case when typeGrTtl = '3. Неизвестная схема' then acceptedTtlAccum end) as uk_acceptedTtlAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then returnedTtl end) as uk_returnedTtl
		, sum(case when typeGrTtl = '3. Неизвестная схема' then returnedTtlAccum end) as uk_returnedTtlAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then inProcessTtl end) as uk_inProcessTtl
		, sum(case when typeGrTtl = '3. Неизвестная схема' then inProcessTtlAccum end) as uk_inProcessTtlAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then notArrivedTtl end) as uk_notArrivedTtl
		, sum(case when typeGrTtl = '3. Неизвестная схема' then notArrivedTtlAccum end) as uk_notArrivedTtlAccum
		, sum(case when typeGrTtl = '3. Неизвестная схема' then restOfLimit end) as uk_restOfLimit
		, sum(case when typeGrTtl = '3. Неизвестная схема' then restOfLimitInProcess end) as uk_restOfLimitInProcess
		--, sum(case when typeGrTtl = '3. Неизвестная схема' then percentDev end) as uk_percentDev
		--, sum(case when typeGrTtl = '3. Неизвестная схема' then percentDevInProcess end) as uk_percentDevInProcess
		-- неизвестная схема. Окончание =========================================================================================================
		-- агентская схема (неплан) =============================================================================================================
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then lim end) as np_lim
		, avg(case when typeGrTtl = '2.2. Агентская, неплан' then iShKey end) as np_iShKey
		-- отчёты агентов -----------------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then presentedAll end) as np_presentedAll
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then presentedAllAccum end) as np_presentedAllAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then presentedAllModul end) as np_presentedAllModul
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then presentedAllModulAccum end) as np_presentedAllModulAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then presented end) as np_presented
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then presentedAccum end) as np_presentedAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then accepted end) as np_accepted
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then acceptedAccum end) as np_acceptedAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then returned end) as np_returned
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then returnedAccum end) as np_returnedAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then inProcess end) as np_inProcess
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then inProcessAccum end) as np_inProcessAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then notArrived end) as np_notArrived
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then notArrivedAccum end) as np_notArrivedAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then presentedPrevYears end) as np_presentedPrevYears
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then presentedPrevYearsAccum end) as np_presentedPrevYearsAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then acceptedPrevYears end) as np_acceptedPrevYears
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then acceptedPrevYearsAccum end) as np_acceptedPrevYearsAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then returnedPrevYears end) as np_returnedPrevYears
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then returnedPrevYearsAccum end) as np_returnedPrevYearsAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then inProcessPrevYears end) as np_inProcessPrevYears
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then inProcessPrevYearsAccum end) as np_inProcessPrevYearsAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then notArrivedPrevYears end) as np_notArrivedPrevYears
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then notArrivedPrevYearsAccum end) as np_notArrivedPrevYearsAccum
		-- агентское вознаграждение -------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then agFeePresented end) as np_agFeePresented
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then agFeePresentedAccum end) as np_agFeePresentedAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then agFeeAccepted end) as np_agFeeAccepted
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then agFeeAcceptedAccum end) as np_agFeeAcceptedAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then agFeeReturned end) as np_agFeeReturned
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then agFeeReturnedAccum end) as np_agFeeReturnedAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then agFeeInProcess end) as np_agFeeInProcess
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then agFeeInProcessAccum end) as np_agFeeInProcessAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then agFeeNotArrived end) as np_agFeeNotArrived
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then agFeeNotArrivedAccum end) as np_agFeeNotArrivedAccum
		-- земельные участки --------------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then presentedRalp end) as np_presentedRalp
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then presentedRalpAccum end) as np_presentedRalpAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then acceptedRalp end) as np_acceptedRalp
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then acceptedRalpAccum end) as np_acceptedRalpAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then returnedRalp end) as np_returnedRalp
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then returnedRalpAccum end) as np_returnedRalpAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then inProcessRalp end) as np_inProcessRalp
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then inProcessRalpAccum end) as np_inProcessRalpAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then notArrivedRalp end) as np_notArrivedRalp
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then notArrivedRalpAccum end) as np_notArrivedRalpAccum
		-- хранение -----------------------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then storageSum end) as np_storageSum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then storageSumAccum end) as np_storageSumAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then cctSum end) as np_cctSum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then cctSumAccum end) as np_cctSumAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then MnrlSum end) as np_MnrlSum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then MnrlSumAccum end) as np_MnrlSumAccum
		-- общее --------------------------------------------------------------------------------------------------------------------------------
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then presentedTtl end) as np_presentedTtl
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then presentedTtlAccum end) as np_presentedTtlAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then acceptedAndInProcessTtl end) as np_acceptedAndInProcessTtl
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then acceptedAndInProcessTtlAccum end) as np_acceptedAndInProcessTtlAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then acceptedTtl end) as np_acceptedTtl
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then acceptedTtlAccum end) as np_acceptedTtlAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then returnedTtl end) as np_returnedTtl
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then returnedTtlAccum end) as np_returnedTtlAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then inProcessTtl end) as np_inProcessTtl
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then inProcessTtlAccum end) as np_inProcessTtlAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then notArrivedTtl end) as np_notArrivedTtl
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then notArrivedTtlAccum end) as np_notArrivedTtlAccum
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then restOfLimit end) as np_restOfLimit
		, sum(case when typeGrTtl = '2.2. Агентская, неплан' then restOfLimitInProcess end) as np_restOfLimitInProcess
		--, sum(case when typeGrTtl = '2.2. Агентская, неплан' then percentDev end) as np_percentDev
		--, sum(case when typeGrTtl = '2.2. Агентская, неплан' then percentDevInProcess end) as np_percentDevInProcess
		-- агентская схема (неплан). Окончание ==================================================================================================
		-- прочие затраты =======================================================================================================================
		-- отчёты агентов -----------------------------------------------------------------------------------------------------------------------
		, oh_presentedAll, oh_presentedAllAccum, oh_presentedAllModul, oh_presentedAllModulAccum
		, oh_presented, oh_presentedAccum, oh_accepted, oh_acceptedAccum
		, oh_returned, oh_returnedAccum
		, oh_inProcess, oh_inProcessAccum, oh_notArrived, oh_notArrivedAccum
		, oh_presentedPrevYears, oh_presentedPrevYearsAccum, oh_acceptedPrevYears, oh_acceptedPrevYearsAccum
		, oh_returnedPrevYears, oh_returnedPrevYearsAccum, oh_inProcessPrevYears, oh_inProcessPrevYearsAccum
		, oh_notArrivedPrevYears, oh_notArrivedPrevYearsAccum
		-- 14.07.2023 добавил прочие отчёты для агентского вознаграждения
		-- агентское вознаграждение -------------------------------------------------------------------------------------------------------------
		, oh_agFeePresented, oh_agFeePresentedAccum, oh_agFeeAccepted, oh_agFeeAcceptedAccum
		, oh_agFeeReturned, oh_agFeeReturnedAccum
		, oh_agFeeInProcess, oh_agFeeInProcessAccum, oh_agFeeNotArrived, oh_agFeeNotArrivedAccum
		-- общее --------------------------------------------------------------------------------------------------------------------------------
		, oh_presentedTtl, oh_presentedTtlAccum, oh_acceptedAndInProcessTtl, oh_acceptedAndInProcessTtlAccum
		, oh_acceptedTtl, oh_acceptedTtlAccum, oh_returnedTtl, oh_returnedTtlAccum
		, oh_inProcessTtl, oh_inProcessTtlAccum
		, oh_notArrivedTtl, oh_notArrivedTtlAccum
		, oh_restOfLimit, oh_restOfLimitInProcess
		--, oh_percentDev, oh_percentDevInProcess
		-- прочие затраты. Окончание ============================================================================================================
	from
		(
			-- 19.09.2024 вот здесь получилось так, что данные по прочим затратам нужно привинтить к строкам всех инвестпрограмм, включая и саму фиктивную
			-- инвестпрограмму прочих затрат. Для этого мы здесь, в отдельном запросе используя оконные функции привинтим эти прочие затраты,
			-- чтобы они были у всех. А в вышестоящем запросе просуммируем через граппировку все остальные направления освоения.
			-- потом нужно будет скрыть отдельные строки прочих затрат во всех случаях когда есть другие затраты. А если других нет, то оставить прочие.
			select *
				, count(t.ipgKey) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as ipgCount
				-- прочие затраты =======================================================================================================================
				-- отчёты агентов -----------------------------------------------------------------------------------------------------------------------
				, sum(case when t.typeGrTtl = '4. Прочие' then presentedAll end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_presentedAll
				, sum(case when t.typeGrTtl = '4. Прочие' then presentedAllAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_presentedAllAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then presentedAllModul end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_presentedAllModul
				, sum(case when t.typeGrTtl = '4. Прочие' then presentedAllModulAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_presentedAllModulAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then presented end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_presented
				, sum(case when t.typeGrTtl = '4. Прочие' then presentedAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_presentedAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then accepted end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_accepted
				, sum(case when t.typeGrTtl = '4. Прочие' then acceptedAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_acceptedAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then returned end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_returned
				, sum(case when t.typeGrTtl = '4. Прочие' then returnedAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_returnedAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then inProcess end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_inProcess
				, sum(case when t.typeGrTtl = '4. Прочие' then inProcessAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_inProcessAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then notArrived end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_notArrived
				, sum(case when t.typeGrTtl = '4. Прочие' then notArrivedAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_notArrivedAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then presentedPrevYears end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_presentedPrevYears
				, sum(case when t.typeGrTtl = '4. Прочие' then presentedPrevYearsAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_presentedPrevYearsAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then acceptedPrevYears end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_acceptedPrevYears
				, sum(case when t.typeGrTtl = '4. Прочие' then acceptedPrevYearsAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_acceptedPrevYearsAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then returnedPrevYears end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_returnedPrevYears
				, sum(case when t.typeGrTtl = '4. Прочие' then returnedPrevYearsAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_returnedPrevYearsAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then inProcessPrevYears end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_inProcessPrevYears
				, sum(case when t.typeGrTtl = '4. Прочие' then inProcessPrevYearsAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_inProcessPrevYearsAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then notArrivedPrevYears end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_notArrivedPrevYears
				, sum(case when t.typeGrTtl = '4. Прочие' then notArrivedPrevYearsAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_notArrivedPrevYearsAccum
				-- агентское вознаграждение -------------------------------------------------------------------------------------------------------------
				, sum(case when t.typeGrTtl = '4. Прочие' then agFeePresented end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_agFeePresented
				, sum(case when t.typeGrTtl = '4. Прочие' then agFeePresentedAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_agFeePresentedAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then agFeeAccepted end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_agFeeAccepted
				, sum(case when t.typeGrTtl = '4. Прочие' then agFeeAcceptedAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_agFeeAcceptedAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then agFeeReturned end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_agFeeReturned
				, sum(case when t.typeGrTtl = '4. Прочие' then agFeeReturnedAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_agFeeReturnedAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then agFeeInProcess end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_agFeeInProcess
				, sum(case when t.typeGrTtl = '4. Прочие' then agFeeInProcessAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_agFeeInProcessAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then agFeeNotArrived end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_agFeeNotArrived
				, sum(case when t.typeGrTtl = '4. Прочие' then agFeeNotArrivedAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_agFeeNotArrivedAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then presentedTtl end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_presentedTtl
				, sum(case when t.typeGrTtl = '4. Прочие' then presentedTtlAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_presentedTtlAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then acceptedAndInProcessTtl end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_acceptedAndInProcessTtl
				, sum(case when t.typeGrTtl = '4. Прочие' then acceptedAndInProcessTtlAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_acceptedAndInProcessTtlAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then acceptedTtl end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_acceptedTtl
				, sum(case when t.typeGrTtl = '4. Прочие' then acceptedTtlAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_acceptedTtlAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then returnedTtl end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_returnedTtl
				, sum(case when t.typeGrTtl = '4. Прочие' then returnedTtlAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_returnedTtlAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then inProcessTtl end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_inProcessTtl
				, sum(case when t.typeGrTtl = '4. Прочие' then inProcessTtlAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_inProcessTtlAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then notArrivedTtl end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_notArrivedTtl
				, sum(case when t.typeGrTtl = '4. Прочие' then notArrivedTtlAccum end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_notArrivedTtlAccum
				, sum(case when t.typeGrTtl = '4. Прочие' then restOfLimit end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_restOfLimit
				, sum(case when t.typeGrTtl = '4. Прочие' then restOfLimitInProcess end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_restOfLimitInProcess
				--, sum(case when t.typeGrTtl = '4. Прочие' then percentDev end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_percentDev
				--, sum(case when t.typeGrTtl = '4. Прочие' then percentDevInProcess end) OVER(PARTITION BY t.yKey, t.mKey, t.ogaKey, t.cstAgPnCode) as oh_percentDevInProcess
				-- 19.09.2024 нельзя на моём сервере 2012 (11-я версия) поставить 160-й уровень совместимости, чтобы задать оконо для оконных функций один раз, используя функцию WINDOW.
				-- Для этого нужен сервер 2022...
				-- прочие затраты. Окончание ============================================================================================================

			from ags.fnIpgChRsltCstUtl2_2606(@ipgChKey, @ipgStKey, @stCostKey) t --@fnIpgChRsltCstUtl2_ t
			--where cstAgPnCode = '014-2000156'
		) as t
	-- 19.09.2024 до группировки уберем строки не имеющие ключа инвестпрограммы но имеющие количество инвестпрограмм.
	-- это уберет строки прочих расходов для месяцев где имеется освоение по другим направлениям, например отчётам агентов. Не смотря на то что лимиты есть или нет.
	where not (ipgKey is null and ipgCount > 0)
	group by t.yKey, t.yyyy, t.mKey, t.mNum, t.mCs, t.mNm, t.mQ, t.mHy, t.cstaInvestor, t.ogaKey, t.ogNm, t.branch, t.cstAgPnCode, t.ipgKey--, t.typeGrTtl_Oh
		, t.ipgCount --, ic.ipgCount
		-- прочие затраты =======================================================================================================================
		-- отчёты агентов -----------------------------------------------------------------------------------------------------------------------
		, oh_presentedAll, oh_presentedAllAccum, oh_presentedAllModul, oh_presentedAllModulAccum
		, oh_presented, oh_presentedAccum, oh_accepted, oh_acceptedAccum
		, oh_returned, oh_returnedAccum
		, oh_inProcess, oh_inProcessAccum, oh_notArrived, oh_notArrivedAccum
		, oh_presentedPrevYears, oh_presentedPrevYearsAccum, oh_acceptedPrevYears, oh_acceptedPrevYearsAccum
		, oh_returnedPrevYears, oh_returnedPrevYearsAccum, oh_inProcessPrevYears, oh_inProcessPrevYearsAccum
		, oh_notArrivedPrevYears, oh_notArrivedPrevYearsAccum
		-- 14.07.2023 добавил прочие отчёты для агентского вознаграждения
		-- агентское вознаграждение -------------------------------------------------------------------------------------------------------------
		, oh_agFeePresented, oh_agFeePresentedAccum, oh_agFeeAccepted, oh_agFeeAcceptedAccum
		, oh_agFeeReturned, oh_agFeeReturnedAccum
		, oh_agFeeInProcess, oh_agFeeInProcessAccum, oh_agFeeNotArrived, oh_agFeeNotArrivedAccum
		-- общее --------------------------------------------------------------------------------------------------------------------------------
		, oh_presentedTtl, oh_presentedTtlAccum, oh_acceptedAndInProcessTtl, oh_acceptedAndInProcessTtlAccum
		, oh_acceptedTtl, oh_acceptedTtlAccum, oh_returnedTtl, oh_returnedTtlAccum
		, oh_inProcessTtl, oh_inProcessTtlAccum
		, oh_notArrivedTtl, oh_notArrivedTtlAccum
		, oh_restOfLimit, oh_restOfLimitInProcess
		--, oh_percentDev, oh_percentDevInProcess
		-- прочие затраты. Окончание ============================================================================================================
	order by t.cstAgPnCode, t.mNum, t.ipgKey

	--select * from @spIpgChRsltCstUtl3_oneD d order by d.cstAgPnCode, d.mNum, d.ipgKey

	insert @dt
	-- Решение 17 / этап 20.2: календарь fnIpgChDats_2606 + актуальность ipgChRl_2606
	select d.dAll, v.ipgcrvIpg
	from ags.fnIpgChDats_2606(@ipgChKey) d
		inner join ags.ipgChRl_2606 v
			on v.ipgcrvChain = @ipgChKey
			and d.dAll >= v.ipgcrvStr
			and d.dAll <= isnull(v.ipgcrvEnd, datefromparts(year(d.dAll), 12, 31))
	group by d.dAll, v.ipgcrvIpg
	order by d.dAll, v.ipgcrvIpg

--	select * from @dt

	-- собственно вычисления

    -- Определяем ключ года для цепи инвестпрограмм
	set @lsYyKey = (	select min(y.yKey) lastYyKey
						from (	select max(y.yyyy) mxY
								from ags.ipgChRl_2606 c
									join ags.ipg i on c.ipgcrvIpg = i.ipgKey
										join ags.yyyy y on i.ipgYy = y.yKey
								where c.ipgcrvChain = @ipgChKey
							) x join ags.yyyy y on x.mxY = y.yyyy
		);

	-- Определяем год для цепи инвестпрограмм
	set @lsYy = (	select min(y.yyyy) lastYy
					from	(	select max(y.yyyy) mxY
								from ags.ipgChRl_2606 c
									join ags.ipg i on c.ipgcrvIpg = i.ipgKey
									join ags.yyyy y on i.ipgYy = y.yKey
								where c.ipgcrvChain = @ipgChKey
							) x join ags.yyyy y on x.mxY = y.yyyy
		);

--	select @ipgChKey as ipgChKey, @lsYyKey as lsYyKey, @lsYy as lsYy


	insert into @TableRslt 
		(
				-- столбцы общие для схем реализации инвестиционных проектов ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
				rowNum
				, ogNm, branch, branchName, cstAgPnCode, dateRslt, ipgChKey, cstapKey
				, yKey, yyyy, mKey, mNum, mCs, mNm, mQ, mHy -- годы, полугодия, месяцы
				, cstaInvestor, ogaKey, ipgKey, ipgCount
				-- столбцы общие для схем реализации инвестиционных проектов. Окончание :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

				-- агентская схема ======================================================================================================================================
				, ag_ipgpKey, ag_iShKey, ag_ipgpSmTtl, ag_lim, ag_Pl, ag_PlAccum
				-- состояние выполнения +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- ниже плана
				, ag_PlFulfillment, ag_PlNonFulfillment_review , ag_PlNonFulfillment
				-- выше плана ниже лимта
				, ag_PlOverFulfillment, ag_PlRestLimit_review, ag_PlRestLimit
				-- выше лимта
				, ag_PlOverLimit, ag_PlOverLimit_review
				-- проценты освоения лимита
				, ag_LimPercent, ag_LimPercentInProcess -- *процент освоения*, исключая *освоенное сверх лимита*
				, ag_percentDev, ag_percentDevInProcess -- *процент освоения*, включая *освоенное сверх лимита*
				-- проценты освоения плана
				, ag_PlPercentMinusOverFulf, ag_PlPercentMinusOverFulfInProcess -- *процент выполнения плана* без *перевыполнения*
				, ag_PlPercent, ag_PlPercentInProcess -- *процент выполнения плана* включая *перевыполнение*
				, ag_percentPlDev, ag_percentPlDevInProcess -- *процент выполнения плана* включая всё, даже и *сверхлимит*
				-- состояние выполнения. Окончание ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				
				-- освоение, виды и итоговое ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- отчёты агентов ---------------------------------------------------------------------------------------------------------------------------------------
				-- относящиеся к любым годам ............................................................................................................................
				, ag_presentedAll, ag_presentedAllAccum -- сумма всех, без исключения, отчётов представленных по стройке
				, ag_presentedAllModul, ag_presentedAllModulAccum -- сумма всех, без исключения, отчётов представленных по стройке, взятая по модулю
				-- относящиеся к текущему году ..........................................................................................................................
				, ag_presented, ag_presentedAccum -- сумма *представленных* отчётов, исключая изменения к отчётам прошлых лет
				, ag_accepted, ag_acceptedAccum -- сумма *принятых* отчётов, исключая изменения к отчётам прошлых лет
				, ag_inProcess, ag_inProcessAccum -- сумма *рассматриваемых* отчётов, исключая изменения к отчётам прошлых лет
				, ag_returned, ag_returnedAccum -- сумма *возвращенных* отчётов, исключая изменения к отчётам прошлых лет
				, ag_notArrived, ag_notArrivedAccum -- сумма *не поступивших* отчётов, исключая изменения к отчётам прошлых лет
				-- относящиеся к прошлым годам. Формируются за счёт изменений к отчётам прошлых лет .....................................................................
				, ag_presentedPrevYears, ag_presentedPrevYearsAccum
				, ag_acceptedPrevYears, ag_acceptedPrevYearsAccum
				, ag_inProcessPrevYears, ag_inProcessPrevYearsAccum
				, ag_returnedPrevYears, ag_returnedPrevYearsAccum
				, ag_notArrivedPrevYears, ag_notArrivedPrevYearsAccum
				-- отчёты агентов. Окончание ----------------------------------------------------------------------------------------------------------------------------
				-- агентское вознаграждение -----------------------------------------------------------------------------------------------------------------------------
				, ag_agFeePresented, ag_agFeePresentedAccum, ag_agFeeAccepted, ag_agFeeAcceptedAccum -- *представленные* и *принятые* акты
				, ag_agFeeInProcess, ag_agFeeInProcessAccum, ag_agFeeReturned, ag_agFeeReturnedAccum -- *рассматриваемые* и *возвращённые* акты
				, ag_agFeeNotArrived, ag_agFeeNotArrivedAccum -- *не поступившие* акты
				-- земельные участки ------------------------------------------------------------------------------------------------------------------------------------
				, ag_presentedRalp, ag_presentedRalpAccum, ag_acceptedRalp, ag_acceptedRalpAccum -- *представленные* и *принятые* отчёты ЗУ
				, ag_inProcessRalp, ag_inProcessRalpAccum, ag_returnedRalp, ag_returnedRalpAccum -- *рассматриваемые* и *возвращённые* отчёты ЗУ
				, ag_notArrivedRalp, ag_notArrivedRalpAccum  -- *не поступившие* отчёты ЗУ
				-- хранение, стройконтроль, ОПИ -------------------------------------------------------------------------------------------------------------------------
				, ag_storageSum, ag_storageSumAccum, ag_cctSum, ag_cctSumAccum, ag_MnrlSum, ag_MnrlSumAccum -- *принятые* по этим
				-- общее ------------------------------------------------------------------------------------------------------------------------------------------------
				, ag_presentedTtl, ag_presentedTtlAccum -- *представлено* по всем видам освоения
				, ag_acceptedTtl, ag_acceptedTtlAccum -- *принято* по всем видам освоения
				, ag_restOfLimit -- остаток лимита, если от него отнять *принято* по всем видам освоения
				, ag_restOfLimitInProcess -- остаток лимита, если от него отнять *принято* по всем видам освоения и ещё отнять *рассматриваемое*
				, ag_inProcessTtl, ag_inProcessTtlAccum -- *рассматривается* по всем видам освоения
				, ag_acceptedAndInProcessTtl, ag_acceptedAndInProcessTtlAccum -- сумма *принято* и *рассматривается* по всем видам освоения
				, ag_returnedTtl, ag_returnedTtlAccum -- *возвращено* по всем видам освоения
				, ag_notArrivedTtl, ag_notArrivedTtlAccum -- *не поступило* по всем видам освоения
				-- освоение, виды и итоговое. Окончание +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- агентская схема. Окончание ===========================================================================================================================

				-- инвестиционная схема (агентская, неплан) =============================================================================================================
				, iv_ipgpKey, iv_iShKey, ia_iShKey, iv_ipgpSmTtl, iv_lim, ia_lim, iv_Pl, iv_PlAccum
				-- состояние выполнения +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- ниже плана
				, iv_PlFulfillment, iv_PlNonFulfillment_review, iv_PlNonFulfillment
				-- выше плана ниже лимита
				, iv_PlOverFulfillment, iv_PlRestLimit_review, iv_PlRestLimit
				-- выше лимита
				, iv_PlOverLimit, iv_PlOverLimit_review
				-- проценты освоения лимита
				, iv_LimPercent, iv_LimPercentInProcess -- *процент освоения*, исключая *освоенное сверх лимита*
				, ia_percentDev, ia_percentDevInProcess -- *процент освоения*, включая *освоенное сверх лимита*
				-- проценты освоения плана
				, iv_PlPercentMinusOverFulf, iv_PlPercentMinusOverFulfInProcess -- *процент выполнения плана* без *перевыполнения*
				, iv_PlPercent, iv_PlPercentInProcess -- *процент выполнения плана* включая *перевыполнение*
				, ia_percentPlDev, ia_percentPlDevInProcess -- *процент выполнения плана* включая всё, даже и *сверхлимит*
				-- состояние выполнения. Окончание ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- инвестиционная схема. Окончание ======================================================================================================================

				-- инвестиционная схема (агентская, неплан) =============================================================================================================
				-- освоение, виды и итоговое ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- отчёты агентов ---------------------------------------------------------------------------------------------------------------------------------------
				-- относящиеся к любым годам ............................................................................................................................
				, ia_presentedAll, ia_presentedAllAccum -- сумма всех, без исключения, отчётов представленных по стройке
				, ia_presentedAllModul, ia_presentedAllModulAccum -- сумма всех, без исключения, отчётов представленных по стройке, взятая по модулю
				-- относящиеся к текущему году ..........................................................................................................................
				, ia_presented, ia_presentedAccum -- сумма *представленных* отчётов, исключая изменения к отчётам прошлых лет
				, ia_accepted, ia_acceptedAccum -- сумма *принятых* отчётов, исключая изменения к отчётам прошлых лет
				, ia_inProcess, ia_inProcessAccum -- сумма *рассматриваемых* отчётов, исключая изменения к отчётам прошлых лет
				, ia_returned, ia_returnedAccum -- сумма *возвращенных* отчётов, исключая изменения к отчётам прошлых лет
				, ia_notArrived, ia_notArrivedAccum -- сумма *не поступивших* отчётов, исключая изменения к отчётам прошлых лет
				-- относящиеся к прошлым годам. Формируются за счёт изменений к отчётам прошлых лет .....................................................................
				, ia_presentedPrevYears, ia_presentedPrevYearsAccum
				, ia_acceptedPrevYears, ia_acceptedPrevYearsAccum
				, ia_inProcessPrevYears, ia_inProcessPrevYearsAccum
				, ia_returnedPrevYears, ia_returnedPrevYearsAccum
				, ia_notArrivedPrevYears, ia_notArrivedPrevYearsAccum
				-- отчёты агентов. Окончание ----------------------------------------------------------------------------------------------------------------------------

				-- агентское вознаграждение -----------------------------------------------------------------------------------------------------------------------------
				, ia_agFeePresented, ia_agFeePresentedAccum, ia_agFeeAccepted, ia_agFeeAcceptedAccum
				, ia_agFeeInProcess, ia_agFeeInProcessAccum
				, ia_agFeeReturned, ia_agFeeReturnedAccum
				, ia_agFeeNotArrived, ia_agFeeNotArrivedAccum
				-- земельные участки ------------------------------------------------------------------------------------------------------------------------------------
				, ia_presentedRalp, ia_presentedRalpAccum, ia_acceptedRalp, ia_acceptedRalpAccum
				, ia_inProcessRalp, ia_inProcessRalpAccum
				, ia_returnedRalp, ia_returnedRalpAccum
				, ia_notArrivedRalp, ia_notArrivedRalpAccum
				-- хранение, стройконтроль, ОПИ -------------------------------------------------------------------------------------------------------------------------
				, ia_storageSum, ia_storageSumAccum, ia_cctSum, ia_cctSumAccum, ia_MnrlSum, ia_MnrlSumAccum
				-- общее ------------------------------------------------------------------------------------------------------------------------------------------------
				, ia_presentedTtl, ia_presentedTtlAccum -- *представлено* по всем видам освоения
				, ia_acceptedTtl, ia_acceptedTtlAccum -- *принято* по всем видам освоения
				, ia_restOfLimit -- остаток лимита, если от него отнять *принято* по всем видам освоения
				, ia_restOfLimitInProcess -- остаток лимита, если от него отнять *принято* по всем видам освоения и ещё отнять *рассматриваемое*
				, ia_inProcessTtl, ia_inProcessTtlAccum -- *рассматривается* по всем видам освоения
				, ia_acceptedAndInProcessTtl, ia_acceptedAndInProcessTtlAccum -- сумма *принято* и *рассматривается* по всем видам освоения
				, ia_returnedTtl, ia_returnedTtlAccum -- *возвращено* по всем видам освоения
				, ia_notArrivedTtl, ia_notArrivedTtlAccum -- *не поступило* по всем видам освоения
				-- освоение, виды и итоговое. Окончание +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- инвестиционная схема (агентская, неплан). Окончание ==================================================================================================

				-- неизвестная схема ====================================================================================================================================
				, uk_ipgpKey, uk_iShKey, uk_ipgpSmTtl, uk_lim , uk_Pl, uk_PlAccum
				-- состояние выполнения +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- ниже плана
				, uk_PlFulfillment, uk_PlNonFulfillment_review, uk_PlNonFulfillment
				-- выше плана ниже лимита
				, uk_PlOverFulfillment, uk_PlRestLimit_review, uk_PlRestLimit
				-- выше лимита
				, uk_PlOverLimit, uk_PlOverLimit_review
				-- проценты освоения лимита
				, uk_LimPercent, uk_LimPercentInProcess -- *процент освоения*, исключая *освоенное сверх лимита*
				, uk_percentDev, uk_percentDevInProcess -- *процент освоения*, включая *освоенное сверх лимита*
				-- проценты освоения плана
				, uk_PlPercentMinusOverFulf, uk_PlPercentMinusOverFulfInProcess -- *процент выполнения плана* без *перевыполнения*
				, uk_PlPercent, uk_PlPercentInProcess -- *процент выполнения плана* включая *перевыполнение*
				, uk_percentPlDev, uk_percentPlDevInProcess -- *процент выполнения плана* включая всё, даже и *сверхлимит*
				-- состояние выполнения. Окончание ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

				-- освоение, виды и итоговое ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- отчёты агентов ---------------------------------------------------------------------------------------------------------------------------------------
				-- относящиеся к любым годам ............................................................................................................................
				, uk_presentedAll, uk_presentedAllAccum -- сумма всех, без исключения, отчётов представленных по стройке
				, uk_presentedAllModul, uk_presentedAllModulAccum -- сумма всех, без исключения, отчётов представленных по стройке, взятая по модулю
				-- относящиеся к текущему году ..........................................................................................................................
				, uk_presented, uk_presentedAccum -- сумма *представленных* отчётов, исключая изменения к отчётам прошлых лет
				, uk_accepted, uk_acceptedAccum -- сумма *принятых* отчётов, исключая изменения к отчётам прошлых лет
				, uk_inProcess, uk_inProcessAccum -- сумма *рассматриваемых* отчётов, исключая изменения к отчётам прошлых лет
				, uk_returned, uk_returnedAccum -- сумма *возвращенных* отчётов, исключая изменения к отчётам прошлых лет
				, uk_notArrived, uk_notArrivedAccum -- сумма *не поступивших* отчётов, исключая изменения к отчётам прошлых лет
				-- относящиеся к прошлым годам. Формируются за счёт изменений к отчётам прошлых лет .....................................................................
				, uk_presentedPrevYears, uk_presentedPrevYearsAccum
				, uk_acceptedPrevYears, uk_acceptedPrevYearsAccum
				, uk_returnedPrevYears, uk_returnedPrevYearsAccum
				, uk_inProcessPrevYears, uk_inProcessPrevYearsAccum
				, uk_notArrivedPrevYears, uk_notArrivedPrevYearsAccum
				-- отчёты агентов. Окончание ----------------------------------------------------------------------------------------------------------------------------
				
				-- агентское вознаграждение -----------------------------------------------------------------------------------------------------------------------------
				, uk_agFeePresented, uk_agFeePresentedAccum, uk_agFeeAccepted, uk_agFeeAcceptedAccum
				, uk_agFeeInProcess, uk_agFeeInProcessAccum
				, uk_agFeeReturned, uk_agFeeReturnedAccum
				, uk_agFeeNotArrived, uk_agFeeNotArrivedAccum
				-- земельные участки ------------------------------------------------------------------------------------------------------------------------------------
				, uk_presentedRalp, uk_presentedRalpAccum, uk_acceptedRalp, uk_acceptedRalpAccum
				, uk_inProcessRalp, uk_inProcessRalpAccum
				, uk_returnedRalp, uk_returnedRalpAccum
				, uk_notArrivedRalp, uk_notArrivedRalpAccum
				-- хранение, стройконтроль, ОПИ -------------------------------------------------------------------------------------------------------------------------
				, uk_storageSum, uk_storageSumAccum, uk_cctSum, uk_cctSumAccum, uk_MnrlSum, uk_MnrlSumAccum
				-- общее ------------------------------------------------------------------------------------------------------------------------------------------------
				, uk_presentedTtl, uk_presentedTtlAccum -- *представлено* по всем видам освоения
				, uk_acceptedTtl, uk_acceptedTtlAccum -- *принято* по всем видам освоения
				, uk_restOfLimit -- остаток лимита, если от него отнять *принято* по всем видам освоения
				, uk_restOfLimitInProcess -- остаток лимита, если от него отнять *принято* по всем видам освоения и ещё отнять *рассматриваемое*
				, uk_inProcessTtl, uk_inProcessTtlAccum -- *рассматривается* по всем видам освоения
				, uk_acceptedAndInProcessTtl, uk_acceptedAndInProcessTtlAccum -- сумма *принято* и *рассматривается* по всем видам освоения
				, uk_returnedTtl, uk_returnedTtlAccum -- *возвращено* по всем видам освоения
				, uk_notArrivedTtl, uk_notArrivedTtlAccum -- *не поступило* по всем видам освоения
				-- освоение, виды и итоговое. Окончание +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- неизвестная схема. Окончание =========================================================================================================================

				-- агентская схема (неплан) =============================================================================================================================
				, np_lim, np_iShKey -- 14.10.2024 странно очень, какой у неплана может быть лимит... Но испорически так сложилось. 
				-- И в Access, в ipgChRsltPlCstPercent есть такая колонка есть. Оставим для обратной совместимости

				-- освоение, виды и итоговое ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- отчёты агентов ---------------------------------------------------------------------------------------------------------------------------------------
				-- относящиеся к любым годам ............................................................................................................................
				, np_presentedAll, np_presentedAllAccum -- сумма всех, без исключения, отчётов представленных по стройке
				, np_presentedAllModul, np_presentedAllModulAccum -- сумма всех, без исключения, отчётов представленных по стройке, взятая по модулю
				-- относящиеся к текущему году ..........................................................................................................................
				, np_presented, np_presentedAccum -- сумма *представленных* отчётов, исключая изменения к отчётам прошлых лет
				, np_accepted, np_acceptedAccum -- сумма *принятых* отчётов, исключая изменения к отчётам прошлых лет
				, np_inProcess, np_inProcessAccum -- сумма *рассматриваемых* отчётов, исключая изменения к отчётам прошлых лет
				, np_returned, np_returnedAccum -- сумма *возвращенных* отчётов, исключая изменения к отчётам прошлых лет
				, np_notArrived, np_notArrivedAccum -- сумма *не поступивших* отчётов, исключая изменения к отчётам прошлых лет
				-- относящиеся к прошлым годам. Формируются за счёт изменений к отчётам прошлых лет .....................................................................
				, np_presentedPrevYears, np_presentedPrevYearsAccum
				, np_acceptedPrevYears, np_acceptedPrevYearsAccum
				, np_returnedPrevYears, np_returnedPrevYearsAccum
				, np_inProcessPrevYears, np_inProcessPrevYearsAccum
				, np_notArrivedPrevYears, np_notArrivedPrevYearsAccum
				-- отчёты агентов. Окончание ----------------------------------------------------------------------------------------------------------------------------
				
				-- агентское вознаграждение -----------------------------------------------------------------------------------------------------------------------------
				, np_agFeePresented, np_agFeePresentedAccum, np_agFeeAccepted, np_agFeeAcceptedAccum
				, np_agFeeInProcess, np_agFeeInProcessAccum
				, np_agFeeReturned, np_agFeeReturnedAccum
				, np_agFeeNotArrived, np_agFeeNotArrivedAccum
				-- земельные участки ------------------------------------------------------------------------------------------------------------------------------------
				, np_presentedRalp, np_presentedRalpAccum, np_acceptedRalp, np_acceptedRalpAccum
				, np_inProcessRalp, np_inProcessRalpAccum
				, np_returnedRalp, np_returnedRalpAccum
				, np_notArrivedRalp, np_notArrivedRalpAccum
				-- хранение, стройконтроль, ОПИ -------------------------------------------------------------------------------------------------------------------------
				, np_storageSum, np_storageSumAccum, np_cctSum, np_cctSumAccum, np_MnrlSum, np_MnrlSumAccum
				-- общее ------------------------------------------------------------------------------------------------------------------------------------------------
				, np_presentedTtl, np_presentedTtlAccum -- *представлено* по всем видам освоения
				, np_acceptedTtl, np_acceptedTtlAccum -- *принято* по всем видам освоения
				, np_restOfLimit -- остаток лимита, если от него отнять *принято* по всем видам освоения
				, np_restOfLimitInProcess -- остаток лимита, если от него отнять *принято* по всем видам освоения и ещё отнять *рассматриваемое*
				, np_inProcessTtl, np_inProcessTtlAccum -- *рассматривается* по всем видам освоения
				, np_acceptedAndInProcessTtl, np_acceptedAndInProcessTtlAccum -- сумма *принято* и *рассматривается* по всем видам освоения
				, np_returnedTtl, np_returnedTtlAccum -- *возвращено* по всем видам освоения
				, np_notArrivedTtl, np_notArrivedTtlAccum -- *не поступило* по всем видам освоения
				-- освоение, виды и итоговое. Окончание +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- агентская схема (неплан). Окончание ==================================================================================================================

				-- прочие затраты =======================================================================================================================================
				-- отчёты агентов ---------------------------------------------------------------------------------------------------------------------------------------
				-- относящиеся к любым годам ............................................................................................................................
				, oh_presentedAll, oh_presentedAllAccum  -- сумма всех, без исключения, отчётов представленных по стройке
				, oh_presentedAllModul, oh_presentedAllModulAccum -- сумма всех, без исключения, отчётов представленных по стройке, взятая по модулю
				-- относящиеся к текущему году ..........................................................................................................................
				, oh_presented, oh_presentedAccum -- сумма *представленных* отчётов, исключая изменения к отчётам прошлых лет
				, oh_accepted, oh_acceptedAccum -- сумма *принятых* отчётов, исключая изменения к отчётам прошлых лет
				, oh_inProcess, oh_inProcessAccum -- сумма *рассматриваемых* отчётов, исключая изменения к отчётам прошлых лет
				, oh_returned, oh_returnedAccum -- сумма *возвращенных* отчётов, исключая изменения к отчётам прошлых лет
				, oh_notArrived, oh_notArrivedAccum -- сумма *не поступивших* отчётов, исключая изменения к отчётам прошлых лет
				-- относящиеся к прошлым годам. Формируются за счёт изменений к отчётам прошлых лет .....................................................................
				, oh_presentedPrevYears, oh_presentedPrevYearsAccum
				, oh_acceptedPrevYears, oh_acceptedPrevYearsAccum
				, oh_returnedPrevYears, oh_returnedPrevYearsAccum
				, oh_inProcessPrevYears, oh_inProcessPrevYearsAccum
				, oh_notArrivedPrevYears, oh_notArrivedPrevYearsAccum
				-- агентское вознаграждение -----------------------------------------------------------------------------------------------------------------------------
				-- 14.07.2023 добавил прочие отчёты для агентского вознаграждения
				, oh_agFeePresented, oh_agFeePresentedAccum, oh_agFeeAccepted, oh_agFeeAcceptedAccum
				, oh_agFeeReturned, oh_agFeeReturnedAccum
				, oh_agFeeInProcess, oh_agFeeInProcessAccum
				, oh_agFeeNotArrived, oh_agFeeNotArrivedAccum
				-- общее ------------------------------------------------------------------------------------------------------------------------------------------------
				, oh_presentedTtl, oh_presentedTtlAccum -- *представлено* по всем видам освоения
				, oh_acceptedTtl, oh_acceptedTtlAccum -- *принято* по всем видам освоения
				, oh_inProcessTtl, oh_inProcessTtlAccum
				, oh_acceptedAndInProcessTtl, oh_acceptedAndInProcessTtlAccum
				, oh_returnedTtl, oh_returnedTtlAccum
				, oh_notArrivedTtl, oh_notArrivedTtlAccum
				-- прочие затраты. Окончание ============================================================================================================================
		)

	select --*
				-- столбцы общие для схем реализации инвестиционных проектов ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
				-- v.ogNm, v.branch, v.cstAgPnCode, v.dateRslt
				ROW_NUMBER() OVER(ORDER BY v.ogNm, v.branch, v.cstAgPnCode, v.dateRslt) AS RowNum
				, v.ogNm, branch, o.ogNm as branchName, cstAgPnCode, dateRslt, @ipgChKey, cstapKey
				, yKey, yyyy, mKey, mNum, mCs, mNm, mQ, mHy -- годы, полугодия, месяцы
				, cstaInvestor, ogaKey, ipgKey, ipgCount
				-- столбцы общие для схем реализации инвестиционных проектов. Окончание :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

				-- агентская схема ======================================================================================================================================
				, ag_ipgpKey, ag_iShKey, ag_ipgpSmTtl, ag_lim, ag_Pl, ag_PlAccum
				-- состояние выполнения +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- ниже плана
				, ag_PlFulfillment, ag_PlNonFulfillment_review , ag_PlNonFulfillment
				-- выше плана ниже лимта
				, ag_PlOverFulfillment, ag_PlRestLimit_review, ag_PlRestLimit
				-- выше лимта
				, ag_PlOverLimit, ag_PlOverLimit_review
				-- проценты освоения лимита
				, ag_LimPercent, ag_LimPercentInProcess -- *процент освоения*, исключая *освоенное сверх лимита*
				, ag_percentDev, ag_percentDevInProcess -- *процент освоения*, включая *освоенное сверх лимита*
				-- проценты освоения плана
				, ag_PlPercentMinusOverFulf, ag_PlPercentMinusOverFulfInProcess -- *процент выполнения плана* без *перевыполнения*
				, ag_PlPercent, ag_PlPercentInProcess -- *процент выполнения плана* включая *перевыполнение*
				, ag_percentPlDev, ag_percentPlDevInProcess -- *процент выполнения плана* включая всё, даже и *сверхлимит*
				-- состояние выполнения. Окончание ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				
				-- освоение, виды и итоговое ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- отчёты агентов ---------------------------------------------------------------------------------------------------------------------------------------
				-- относящиеся к любым годам ............................................................................................................................
				, ag_presentedAll, ag_presentedAllAccum -- сумма всех, без исключения, отчётов представленных по стройке
				, ag_presentedAllModul, ag_presentedAllModulAccum -- сумма всех, без исключения, отчётов представленных по стройке, взятая по модулю
				-- относящиеся к текущему году ..........................................................................................................................
				, ag_presented, ag_presentedAccum -- сумма *представленных* отчётов, исключая изменения к отчётам прошлых лет
				, ag_accepted, ag_acceptedAccum -- сумма *принятых* отчётов, исключая изменения к отчётам прошлых лет
				, ag_inProcess, ag_inProcessAccum -- сумма *рассматриваемых* отчётов, исключая изменения к отчётам прошлых лет
				, ag_returned, ag_returnedAccum -- сумма *возвращенных* отчётов, исключая изменения к отчётам прошлых лет
				, ag_notArrived, ag_notArrivedAccum -- сумма *не поступивших* отчётов, исключая изменения к отчётам прошлых лет
				-- относящиеся к прошлым годам. Формируются за счёт изменений к отчётам прошлых лет .....................................................................
				, ag_presentedPrevYears, ag_presentedPrevYearsAccum
				, ag_acceptedPrevYears, ag_acceptedPrevYearsAccum
				, ag_inProcessPrevYears, ag_inProcessPrevYearsAccum
				, ag_returnedPrevYears, ag_returnedPrevYearsAccum
				, ag_notArrivedPrevYears, ag_notArrivedPrevYearsAccum
				-- отчёты агентов. Окончание ----------------------------------------------------------------------------------------------------------------------------
				-- агентское вознаграждение -----------------------------------------------------------------------------------------------------------------------------
				, ag_agFeePresented, ag_agFeePresentedAccum, ag_agFeeAccepted, ag_agFeeAcceptedAccum -- *представленные* и *принятые* акты
				, ag_agFeeInProcess, ag_agFeeInProcessAccum, ag_agFeeReturned, ag_agFeeReturnedAccum -- *рассматриваемые* и *возвращённые* акты
				, ag_agFeeNotArrived, ag_agFeeNotArrivedAccum -- *не поступившие* акты
				-- земельные участки ------------------------------------------------------------------------------------------------------------------------------------
				, ag_presentedRalp, ag_presentedRalpAccum, ag_acceptedRalp, ag_acceptedRalpAccum -- *представленные* и *принятые* отчёты ЗУ
				, ag_inProcessRalp, ag_inProcessRalpAccum, ag_returnedRalp, ag_returnedRalpAccum -- *рассматриваемые* и *возвращённые* отчёты ЗУ
				, ag_notArrivedRalp, ag_notArrivedRalpAccum  -- *не поступившие* отчёты ЗУ
				-- хранение, стройконтроль, ОПИ -------------------------------------------------------------------------------------------------------------------------
				, ag_storageSum, ag_storageSumAccum, ag_cctSum, ag_cctSumAccum, ag_MnrlSum, ag_MnrlSumAccum -- *принятые* по этим
				-- общее ------------------------------------------------------------------------------------------------------------------------------------------------
				, ag_presentedTtl, ag_presentedTtlAccum -- *представлено* по всем видам освоения
				, ag_acceptedTtl, ag_acceptedTtlAccum -- *принято* по всем видам освоения
				, ag_restOfLimit -- остаток лимита, если от него отнять *принято* по всем видам освоения
				, ag_restOfLimitInProcess -- остаток лимита, если от него отнять *принято* по всем видам освоения и ещё отнять *рассматриваемое*
				, ag_inProcessTtl, ag_inProcessTtlAccum -- *рассматривается* по всем видам освоения
				, ag_acceptedAndInProcessTtl, ag_acceptedAndInProcessTtlAccum -- сумма *принято* и *рассматривается* по всем видам освоения
				, ag_returnedTtl, ag_returnedTtlAccum -- *возвращено* по всем видам освоения
				, ag_notArrivedTtl, ag_notArrivedTtlAccum -- *не поступило* по всем видам освоения
				-- освоение, виды и итоговое. Окончание +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- агентская схема. Окончание ===========================================================================================================================

				-- инвестиционная схема (агентская, неплан) =============================================================================================================
				, iv_ipgpKey, iv_iShKey, ia_iShKey, iv_ipgpSmTtl, iv_lim, ia_lim, iv_Pl, iv_PlAccum
				-- состояние выполнения +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- ниже плана
				, iv_PlFulfillment, iv_PlNonFulfillment_review, iv_PlNonFulfillment
				-- выше плана ниже лимита
				, iv_PlOverFulfillment, iv_PlRestLimit_review, iv_PlRestLimit
				-- выше лимита
				, iv_PlOverLimit, iv_PlOverLimit_review
				-- проценты освоения лимита
				, iv_LimPercent, iv_LimPercentInProcess -- *процент освоения*, исключая *освоенное сверх лимита*
				, ia_percentDev, ia_percentDevInProcess -- *процент освоения*, включая *освоенное сверх лимита*
				-- проценты освоения плана
				, iv_PlPercentMinusOverFulf, iv_PlPercentMinusOverFulfInProcess -- *процент выполнения плана* без *перевыполнения*
				, iv_PlPercent, iv_PlPercentInProcess -- *процент выполнения плана* включая *перевыполнение*
				, ia_percentPlDev, ia_percentPlDevInProcess -- *процент выполнения плана* включая всё, даже и *сверхлимит*
				-- состояние выполнения. Окончание ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- инвестиционная схема. Окончание ======================================================================================================================

				-- инвестиционная схема (агентская, неплан) =============================================================================================================
				-- освоение, виды и итоговое ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- отчёты агентов ---------------------------------------------------------------------------------------------------------------------------------------
				-- относящиеся к любым годам ............................................................................................................................
				, ia_presentedAll, ia_presentedAllAccum -- сумма всех, без исключения, отчётов представленных по стройке
				, ia_presentedAllModul, ia_presentedAllModulAccum -- сумма всех, без исключения, отчётов представленных по стройке, взятая по модулю
				-- относящиеся к текущему году ..........................................................................................................................
				, ia_presented, ia_presentedAccum -- сумма *представленных* отчётов, исключая изменения к отчётам прошлых лет
				, ia_accepted, ia_acceptedAccum -- сумма *принятых* отчётов, исключая изменения к отчётам прошлых лет
				, ia_inProcess, ia_inProcessAccum -- сумма *рассматриваемых* отчётов, исключая изменения к отчётам прошлых лет
				, ia_returned, ia_returnedAccum -- сумма *возвращенных* отчётов, исключая изменения к отчётам прошлых лет
				, ia_notArrived, ia_notArrivedAccum -- сумма *не поступивших* отчётов, исключая изменения к отчётам прошлых лет
				-- относящиеся к прошлым годам. Формируются за счёт изменений к отчётам прошлых лет .....................................................................
				, ia_presentedPrevYears, ia_presentedPrevYearsAccum
				, ia_acceptedPrevYears, ia_acceptedPrevYearsAccum
				, ia_inProcessPrevYears, ia_inProcessPrevYearsAccum
				, ia_returnedPrevYears, ia_returnedPrevYearsAccum
				, ia_notArrivedPrevYears, ia_notArrivedPrevYearsAccum
				-- отчёты агентов. Окончание ----------------------------------------------------------------------------------------------------------------------------

				-- агентское вознаграждение -----------------------------------------------------------------------------------------------------------------------------
				, ia_agFeePresented, ia_agFeePresentedAccum, ia_agFeeAccepted, ia_agFeeAcceptedAccum
				, ia_agFeeInProcess, ia_agFeeInProcessAccum
				, ia_agFeeReturned, ia_agFeeReturnedAccum
				, ia_agFeeNotArrived, ia_agFeeNotArrivedAccum
				-- земельные участки ------------------------------------------------------------------------------------------------------------------------------------
				, ia_presentedRalp, ia_presentedRalpAccum, ia_acceptedRalp, ia_acceptedRalpAccum
				, ia_inProcessRalp, ia_inProcessRalpAccum
				, ia_returnedRalp, ia_returnedRalpAccum
				, ia_notArrivedRalp, ia_notArrivedRalpAccum
				-- хранение, стройконтроль, ОПИ -------------------------------------------------------------------------------------------------------------------------
				, ia_storageSum, ia_storageSumAccum, ia_cctSum, ia_cctSumAccum, ia_MnrlSum, ia_MnrlSumAccum
				-- общее ------------------------------------------------------------------------------------------------------------------------------------------------
				, ia_presentedTtl, ia_presentedTtlAccum -- *представлено* по всем видам освоения
				, ia_acceptedTtl, ia_acceptedTtlAccum -- *принято* по всем видам освоения
				, ia_restOfLimit -- остаток лимита, если от него отнять *принято* по всем видам освоения
				, ia_restOfLimitInProcess -- остаток лимита, если от него отнять *принято* по всем видам освоения и ещё отнять *рассматриваемое*
				, ia_inProcessTtl, ia_inProcessTtlAccum -- *рассматривается* по всем видам освоения
				, ia_acceptedAndInProcessTtl, ia_acceptedAndInProcessTtlAccum -- сумма *принято* и *рассматривается* по всем видам освоения
				, ia_returnedTtl, ia_returnedTtlAccum -- *возвращено* по всем видам освоения
				, ia_notArrivedTtl, ia_notArrivedTtlAccum -- *не поступило* по всем видам освоения
				-- освоение, виды и итоговое. Окончание +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- инвестиционная схема (агентская, неплан). Окончание ==================================================================================================

				-- неизвестная схема ====================================================================================================================================
				, uk_ipgpKey, uk_iShKey, uk_ipgpSmTtl, uk_lim , uk_Pl, uk_PlAccum
				-- состояние выполнения +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- ниже плана
				, uk_PlFulfillment, uk_PlNonFulfillment_review, uk_PlNonFulfillment
				-- выше плана ниже лимита
				, uk_PlOverFulfillment, uk_PlRestLimit_review, uk_PlRestLimit
				-- выше лимита
				, uk_PlOverLimit, uk_PlOverLimit_review
				-- проценты освоения лимита
				, uk_LimPercent, uk_LimPercentInProcess -- *процент освоения*, исключая *освоенное сверх лимита*
				, uk_percentDev, uk_percentDevInProcess -- *процент освоения*, включая *освоенное сверх лимита*
				-- проценты освоения плана
				, uk_PlPercentMinusOverFulf, uk_PlPercentMinusOverFulfInProcess -- *процент выполнения плана* без *перевыполнения*
				, uk_PlPercent, uk_PlPercentInProcess -- *процент выполнения плана* включая *перевыполнение*
				, uk_percentPlDev, uk_percentPlDevInProcess -- *процент выполнения плана* включая всё, даже и *сверхлимит*
				-- состояние выполнения. Окончание ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

				-- освоение, виды и итоговое ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- отчёты агентов ---------------------------------------------------------------------------------------------------------------------------------------
				-- относящиеся к любым годам ............................................................................................................................
				, uk_presentedAll, uk_presentedAllAccum -- сумма всех, без исключения, отчётов представленных по стройке
				, uk_presentedAllModul, uk_presentedAllModulAccum -- сумма всех, без исключения, отчётов представленных по стройке, взятая по модулю
				-- относящиеся к текущему году ..........................................................................................................................
				, uk_presented, uk_presentedAccum -- сумма *представленных* отчётов, исключая изменения к отчётам прошлых лет
				, uk_accepted, uk_acceptedAccum -- сумма *принятых* отчётов, исключая изменения к отчётам прошлых лет
				, uk_inProcess, uk_inProcessAccum -- сумма *рассматриваемых* отчётов, исключая изменения к отчётам прошлых лет
				, uk_returned, uk_returnedAccum -- сумма *возвращенных* отчётов, исключая изменения к отчётам прошлых лет
				, uk_notArrived, uk_notArrivedAccum -- сумма *не поступивших* отчётов, исключая изменения к отчётам прошлых лет
				-- относящиеся к прошлым годам. Формируются за счёт изменений к отчётам прошлых лет .....................................................................
				, uk_presentedPrevYears, uk_presentedPrevYearsAccum
				, uk_acceptedPrevYears, uk_acceptedPrevYearsAccum
				, uk_returnedPrevYears, uk_returnedPrevYearsAccum
				, uk_inProcessPrevYears, uk_inProcessPrevYearsAccum
				, uk_notArrivedPrevYears, uk_notArrivedPrevYearsAccum
				-- отчёты агентов. Окончание ----------------------------------------------------------------------------------------------------------------------------
				
				-- агентское вознаграждение -----------------------------------------------------------------------------------------------------------------------------
				, uk_agFeePresented, uk_agFeePresentedAccum, uk_agFeeAccepted, uk_agFeeAcceptedAccum
				, uk_agFeeInProcess, uk_agFeeInProcessAccum
				, uk_agFeeReturned, uk_agFeeReturnedAccum
				, uk_agFeeNotArrived, uk_agFeeNotArrivedAccum
				-- земельные участки ------------------------------------------------------------------------------------------------------------------------------------
				, uk_presentedRalp, uk_presentedRalpAccum, uk_acceptedRalp, uk_acceptedRalpAccum
				, uk_inProcessRalp, uk_inProcessRalpAccum
				, uk_returnedRalp, uk_returnedRalpAccum
				, uk_notArrivedRalp, uk_notArrivedRalpAccum
				-- хранение, стройконтроль, ОПИ -------------------------------------------------------------------------------------------------------------------------
				, uk_storageSum, uk_storageSumAccum, uk_cctSum, uk_cctSumAccum, uk_MnrlSum, uk_MnrlSumAccum
				-- общее ------------------------------------------------------------------------------------------------------------------------------------------------
				, uk_presentedTtl, uk_presentedTtlAccum -- *представлено* по всем видам освоения
				, uk_acceptedTtl, uk_acceptedTtlAccum -- *принято* по всем видам освоения
				, uk_restOfLimit -- остаток лимита, если от него отнять *принято* по всем видам освоения
				, uk_restOfLimitInProcess -- остаток лимита, если от него отнять *принято* по всем видам освоения и ещё отнять *рассматриваемое*
				, uk_inProcessTtl, uk_inProcessTtlAccum -- *рассматривается* по всем видам освоения
				, uk_acceptedAndInProcessTtl, uk_acceptedAndInProcessTtlAccum -- сумма *принято* и *рассматривается* по всем видам освоения
				, uk_returnedTtl, uk_returnedTtlAccum -- *возвращено* по всем видам освоения
				, uk_notArrivedTtl, uk_notArrivedTtlAccum -- *не поступило* по всем видам освоения
				-- освоение, виды и итоговое. Окончание +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- неизвестная схема. Окончание =========================================================================================================================

				-- агентская схема (неплан) =============================================================================================================================
				, np_lim, np_iShKey -- 14.10.2024 странно очень, какой у неплана может быть лимит... Но испорически так сложилось. 
				-- И в Access, в ipgChRsltPlCstPercent есть такая колонка есть. Оставим для обратной совместимости

				-- освоение, виды и итоговое ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- отчёты агентов ---------------------------------------------------------------------------------------------------------------------------------------
				-- относящиеся к любым годам ............................................................................................................................
				, np_presentedAll, np_presentedAllAccum -- сумма всех, без исключения, отчётов представленных по стройке
				, np_presentedAllModul, np_presentedAllModulAccum -- сумма всех, без исключения, отчётов представленных по стройке, взятая по модулю
				-- относящиеся к текущему году ..........................................................................................................................
				, np_presented, np_presentedAccum -- сумма *представленных* отчётов, исключая изменения к отчётам прошлых лет
				, np_accepted, np_acceptedAccum -- сумма *принятых* отчётов, исключая изменения к отчётам прошлых лет
				, np_inProcess, np_inProcessAccum -- сумма *рассматриваемых* отчётов, исключая изменения к отчётам прошлых лет
				, np_returned, np_returnedAccum -- сумма *возвращенных* отчётов, исключая изменения к отчётам прошлых лет
				, np_notArrived, np_notArrivedAccum -- сумма *не поступивших* отчётов, исключая изменения к отчётам прошлых лет
				-- относящиеся к прошлым годам. Формируются за счёт изменений к отчётам прошлых лет .....................................................................
				, np_presentedPrevYears, np_presentedPrevYearsAccum
				, np_acceptedPrevYears, np_acceptedPrevYearsAccum
				, np_returnedPrevYears, np_returnedPrevYearsAccum
				, np_inProcessPrevYears, np_inProcessPrevYearsAccum
				, np_notArrivedPrevYears, np_notArrivedPrevYearsAccum
				-- отчёты агентов. Окончание ----------------------------------------------------------------------------------------------------------------------------
				
				-- агентское вознаграждение -----------------------------------------------------------------------------------------------------------------------------
				, np_agFeePresented, np_agFeePresentedAccum, np_agFeeAccepted, np_agFeeAcceptedAccum
				, np_agFeeInProcess, np_agFeeInProcessAccum
				, np_agFeeReturned, np_agFeeReturnedAccum
				, np_agFeeNotArrived, np_agFeeNotArrivedAccum
				-- земельные участки ------------------------------------------------------------------------------------------------------------------------------------
				, np_presentedRalp, np_presentedRalpAccum, np_acceptedRalp, np_acceptedRalpAccum
				, np_inProcessRalp, np_inProcessRalpAccum
				, np_returnedRalp, np_returnedRalpAccum
				, np_notArrivedRalp, np_notArrivedRalpAccum
				-- хранение, стройконтроль, ОПИ -------------------------------------------------------------------------------------------------------------------------
				, np_storageSum, np_storageSumAccum, np_cctSum, np_cctSumAccum, np_MnrlSum, np_MnrlSumAccum
				-- общее ------------------------------------------------------------------------------------------------------------------------------------------------
				, np_presentedTtl, np_presentedTtlAccum -- *представлено* по всем видам освоения
				, np_acceptedTtl, np_acceptedTtlAccum -- *принято* по всем видам освоения
				, np_restOfLimit -- остаток лимита, если от него отнять *принято* по всем видам освоения
				, np_restOfLimitInProcess -- остаток лимита, если от него отнять *принято* по всем видам освоения и ещё отнять *рассматриваемое*
				, np_inProcessTtl, np_inProcessTtlAccum -- *рассматривается* по всем видам освоения
				, np_acceptedAndInProcessTtl, np_acceptedAndInProcessTtlAccum -- сумма *принято* и *рассматривается* по всем видам освоения
				, np_returnedTtl, np_returnedTtlAccum -- *возвращено* по всем видам освоения
				, np_notArrivedTtl, np_notArrivedTtlAccum -- *не поступило* по всем видам освоения
				-- освоение, виды и итоговое. Окончание +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- агентская схема (неплан). Окончание ==================================================================================================================

				-- прочие затраты =======================================================================================================================================
				-- отчёты агентов ---------------------------------------------------------------------------------------------------------------------------------------
				-- относящиеся к любым годам ............................................................................................................................
				, oh_presentedAll, oh_presentedAllAccum  -- сумма всех, без исключения, отчётов представленных по стройке
				, oh_presentedAllModul, oh_presentedAllModulAccum -- сумма всех, без исключения, отчётов представленных по стройке, взятая по модулю
				-- относящиеся к текущему году ..........................................................................................................................
				, oh_presented, oh_presentedAccum -- сумма *представленных* отчётов, исключая изменения к отчётам прошлых лет
				, oh_accepted, oh_acceptedAccum -- сумма *принятых* отчётов, исключая изменения к отчётам прошлых лет
				, oh_inProcess, oh_inProcessAccum -- сумма *рассматриваемых* отчётов, исключая изменения к отчётам прошлых лет
				, oh_returned, oh_returnedAccum -- сумма *возвращенных* отчётов, исключая изменения к отчётам прошлых лет
				, oh_notArrived, oh_notArrivedAccum -- сумма *не поступивших* отчётов, исключая изменения к отчётам прошлых лет
				-- относящиеся к прошлым годам. Формируются за счёт изменений к отчётам прошлых лет .....................................................................
				, oh_presentedPrevYears, oh_presentedPrevYearsAccum
				, oh_acceptedPrevYears, oh_acceptedPrevYearsAccum
				, oh_returnedPrevYears, oh_returnedPrevYearsAccum
				, oh_inProcessPrevYears, oh_inProcessPrevYearsAccum
				, oh_notArrivedPrevYears, oh_notArrivedPrevYearsAccum
				-- агентское вознаграждение -----------------------------------------------------------------------------------------------------------------------------
				-- 14.07.2023 добавил прочие отчёты для агентского вознаграждения
				, oh_agFeePresented, oh_agFeePresentedAccum, oh_agFeeAccepted, oh_agFeeAcceptedAccum
				, oh_agFeeReturned, oh_agFeeReturnedAccum
				, oh_agFeeInProcess, oh_agFeeInProcessAccum
				, oh_agFeeNotArrived, oh_agFeeNotArrivedAccum
				-- общее ------------------------------------------------------------------------------------------------------------------------------------------------
				, oh_presentedTtl, oh_presentedTtlAccum -- *представлено* по всем видам освоения
				, oh_acceptedTtl, oh_acceptedTtlAccum -- *принято* по всем видам освоения
				, oh_inProcessTtl, oh_inProcessTtlAccum
				, oh_acceptedAndInProcessTtl, oh_acceptedAndInProcessTtlAccum
				, oh_returnedTtl, oh_returnedTtlAccum
				, oh_notArrivedTtl, oh_notArrivedTtlAccum
				-- прочие затраты. Окончание ============================================================================================================================
	from
		(
			-- рассчитываем % освоения лимитов и исполнения помесячных планов и присоединяем к результатам уровней всего, заказчик, филиал, стройка #####################
			select 
				-- по агентской схеме ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
				-- лимит, проценты освоения +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				iif ( -- процент освоения -------------------------------------------------------------------------------------------------------------------------------
						w.ag_lim is null or w.ag_lim = 0, -- лимит отсутствует?
						null,	-- да, лимит отсутствует
						iif ( -- нет, лимит имеется
								w.ag_lim < isnull(w.ag_PlFulfillment, 0) + isnull(w.ag_PlOverFulfillment, 0), -- сумма выполнения и перевыполнения плана больше лимита?
								1, -- да, тогда процент освоения равен 100%
								-- нет, тогда процент освоения равен частному суммы выполнения и перевыполнения плана и лимита
								(isnull(w.ag_PlFulfillment, 0) + isnull(w.ag_PlOverFulfillment, 0))/NULLIF(w.ag_lim, 0) 
							)
					) ag_LimPercent -- процент освоения. Окончание ------------------------------------------------------------------------------------------------------
				, iif ( -- *процент освоения*, включая *рассматриваемое* ------------------------------------------------------------------------------------------------
						w.ag_lim is null or w.ag_lim = 0, -- лимит отсутствует?
						null, -- да, лимит отсутствует
						iif ( -- нет, лимит имеется
								-- сумма *выполнения*, *перевыполнения* и *рассматриваемого* больше *лимита*?
								w.ag_lim < isnull(w.ag_PlFulfillment, 0) + isnull(w.ag_PlOverFulfillment, 0) + isnull(w.ag_inProcessTtlAccum, 0), 
								1, -- да, тогда процент освоения равен 100%
								-- нет, тогда процент освоения равен частному суммы *выполнения*, *перевыполнения* и *рассматриваемого* и *лимита*
								(isnull(w.ag_PlFulfillment, 0) + isnull(w.ag_PlOverFulfillment, 0) + isnull(w.ag_inProcessTtlAccum, 0))/NULLIF(w.ag_lim, 0) 
							)
					) ag_LimPercentInProcess -- *процент освоения*, включая *рассматриваемое*. Окончание ----------------------------------------------------------------
				, iif ( -- процент освоения, включая освоенное сверх лимита ---------------------------------------------------------------------------------------------
						w.ag_lim is null or w.ag_lim = 0, -- лимит отсутствует?
						null,	-- да, лимит отсутствует
						-- нет, лимит имеется, тогда процент освоения равен частному *принятого общего* и *лимита*
						isnull(w.ag_acceptedTtlAccum, 0)/NULLIF(w.ag_lim, 0) 
					) ag_percentDev -- процент освоения, включая освоенное сверх лимита. Окончание ----------------------------------------------------------------------
				, iif ( -- *процент освоения*, включая *освоенное сверх лимита* и *рассматриваемое* ---------------------------------------------------------------------
						w.ag_lim is null or w.ag_lim = 0, -- лимит отсутствует?
						null,	-- да, лимит отсутствует
						-- нет, лимит имеется, тогда процент освоения равен частному *принятого общего* и *лимита*
						(isnull(w.ag_acceptedTtlAccum, 0) + isnull(w.ag_inProcessTtlAccum, 0))/NULLIF(w.ag_lim, 0) 
					) ag_percentDevInProcess -- *процент освоения*, включая *освоенное сверх лимита* и *рассматриваемое*. Окончание -------------------------------------
				-- лимит, проценты освоения. Окончание ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

				-- план, проценты выполнения ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				, iif (	-- процент выполнения плана без перевыполнения --------------------------------------------------------------------------------------------------
						w.ag_PlAccum is null or w.ag_PlAccum = 0, -- план отсутствует?
						null,	-- да, план отсутствует
						-- нет, тогда *процент выполнения плана* равен частному суммы *выполнения плана* и *плана*
						isnull(w.ag_PlFulfillment, 0)/NULLIF(w.ag_PlAccum, 0) 
					) ag_PlPercentMinusOverFulf -- процент выполнения плана без перевыполнения. Окончание ---------------------------------------------------------------
				, iif (	-- *процент выполнения плана* без *перевыполнения* включая *рассматриваемое* --------------------------------------------------------------------
						w.ag_PlAccum is null or w.ag_PlAccum = 0, -- план отсутствует?
						null, -- да, план отсутствует
						iif (
								-- сумма *выполнения* и *рассматриваемого* больше плана?
								w.ag_PlAccum < isnull(w.ag_PlFulfillment, 0) + isnull(w.ag_inProcessTtlAccum, 0),
								1, -- да, сумма *выполнения* и *рассматриваемого* больше плана, тогда 100%
								-- нет, тогда *процент выполнения плана* равен частному суммы *выполнения плана* и *рассматриваемого* и *плана*
								(isnull(w.ag_PlFulfillment, 0) + isnull(w.ag_inProcessTtlAccum, 0))/NULLIF(w.ag_PlAccum, 0)
							)
					) ag_PlPercentMinusOverFulfInProcess -- *процент выполнения плана* без *перевыполнения* включая *рассматриваемое*. Окончание ------------------------
				, iif (	-- процент выполнения плана ---------------------------------------------------------------------------------------------------------------------
						w.ag_PlAccum is null or w.ag_PlAccum = 0, -- план отсутствует?
						null,	-- да, план отсутствует
						-- нет, тогда процент выполнения плана равен частному суммы выполнения и перевыполнения плана и плана
						(isnull(w.ag_PlFulfillment, 0) + isnull(w.ag_PlOverFulfillment, 0))/NULLIF(w.ag_PlAccum, 0) 
					) ag_PlPercent -- процент выполнения плана. Окончание -----------------------------------------------------------------------------------------------
				, iif (	-- *процент выполнения плана* включая *рассматриваемое* -----------------------------------------------------------------------------------------
						w.ag_PlAccum is null or w.ag_PlAccum = 0, -- план отсутствует?
						null,	-- да, план отсутствует
						-- нет, тогда *процент выполнения плана* равен частному суммы *выполнения*, *перевыполнения* и *рассматриваемого*  и плана
						(isnull(w.ag_PlFulfillment, 0) + isnull(w.ag_PlOverFulfillment, 0) + isnull(w.ag_inProcessTtlAccum, 0))/NULLIF(w.ag_PlAccum, 0) 
					) ag_PlPercentInProcess -- *процент выполнения плана* включая *рассматриваемое*. Окончание ----------------------------------------------------------
				, iif (	-- *процент выполнения плана* включая всё, даже и *сверхлимит* ----------------------------------------------------------------------------------
						w.ag_PlAccum is null or w.ag_PlAccum = 0, -- план отсутствует?
						null,	-- да, план отсутствует
						-- нет, тогда *процент выполнения плана* равен частному *принятого общего* и *плана*
						isnull(w.ag_acceptedTtlAccum, 0)/NULLIF(w.ag_PlAccum, 0) 
					) ag_percentPlDev -- *процент выполнения плана* включая всё, даже и *сверхлимит*. Окончание ---------------------------------------------------------
				, iif (	-- *процент выполнения плана* включая всё, даже и *сверхлимит* и включая *рассматриваемое* ------------------------------------------------------
						w.ag_PlAccum is null or w.ag_PlAccum = 0, -- план отсутствует?
						null,	-- да, план отсутствует
						-- нет, тогда *процент выполнения плана* равен частному суммы *принятого общего* и *рассматриваемого*  и плана
						(isnull(w.ag_acceptedTtlAccum, 0) + isnull(w.ag_inProcessTtlAccum, 0))/NULLIF(w.ag_PlAccum, 0) 
					) ag_percentPlDevInProcess -- *процент выполнения плана* включая всё, даже и *сверхлимит* и включая *рассматриваемое*. Окончание --------------------
				-- план, проценты выполнения. Окончание +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- по агентской схеме. Окончание ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

				-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

				-- по инвестиционной схеме ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
				-- лимит, проценты освоения +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				, iif (	-- процент освоения -----------------------------------------------------------------------------------------------------------------------------
						w.iv_lim is null or w.iv_lim = 0, -- лимит отсутствует?
						null,	-- да, лимит отсутствует
						iif ( -- нет, лимит имеется
								w.iv_lim < isnull(w.iv_PlFulfillment, 0) + isnull(w.iv_PlOverFulfillment, 0), -- сумма выполнения и перевыполнения плана больше лимита?
								1, -- да, тогда процент освоения равен 100%
								-- нет, тогда процент освоения равен частному суммы выполнения и перевыполнения плана и лимита
								(isnull(w.iv_PlFulfillment, 0) + isnull(w.iv_PlOverFulfillment, 0))/NULLIF(w.iv_lim, 0) 
							)
					) iv_LimPercent -- процент освоения. Окончание ------------------------------------------------------------------------------------------------------
				, iif ( -- *процент освоения*, включая *рассматриваемое* ------------------------------------------------------------------------------------------------
						w.iv_lim is null or w.iv_lim = 0, -- лимит отсутствует?
						null, -- да, лимит отсутствует
						iif ( -- нет, лимит имеется
								-- сумма *выполнения*, *перевыполнения* и *рассматриваемого* больше *лимита*?
								w.iv_lim < isnull(w.iv_PlFulfillment, 0) + isnull(w.iv_PlOverFulfillment, 0) + isnull(w.ia_inProcessTtlAccum, 0), 
								1, -- да, тогда процент освоения равен 100%
								-- нет, тогда процент освоения равен частному суммы *выполнения*, *перевыполнения* и *рассматриваемого* и *лимита*
								(isnull(w.iv_PlFulfillment, 0) + isnull(w.iv_PlOverFulfillment, 0) + isnull(w.ia_inProcessTtlAccum, 0))/NULLIF(w.iv_lim, 0) 
							)
					) iv_LimPercentInProcess -- *процент освоения*, включая *рассматриваемое*. Окончание ----------------------------------------------------------------
				, iif ( -- процент освоения, включая освоенное сверх лимита ---------------------------------------------------------------------------------------------
						w.iv_lim is null or w.iv_lim = 0, -- лимит отсутствует?
						null,	-- да, лимит отсутствует
						-- нет, лимит имеется, тогда процент освоения равен частному *принятого общего* и *лимита*
						isnull(w.ia_acceptedTtlAccum, 0)/NULLIF(w.iv_lim, 0) 
					) ia_percentDev -- процент освоения, включая освоенное сверх лимита. Окончание ----------------------------------------------------------------------
				, iif ( -- *процент освоения*, включая *освоенное сверх лимита* и *рассматриваемое* ---------------------------------------------------------------------
						w.iv_lim is null or w.iv_lim = 0, -- лимит отсутствует?
						null,	-- да, лимит отсутствует
						-- нет, лимит имеется, тогда процент освоения равен частному *принятого общего* и *лимита*
						(isnull(w.ia_acceptedTtlAccum, 0) + isnull(w.ia_inProcessTtlAccum, 0))/NULLIF(w.iv_lim, 0) 
					) ia_percentDevInProcess -- *процент освоения*, включая *освоенное сверх лимита* и *рассматриваемое*. Окончание -------------------------------------
				-- лимит, проценты освоения. Окончание ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

				-- план, проценты выполнения ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				, iif (	-- процент выполнения плана без перевыполнения --------------------------------------------------------------------------------------------------
						w.iv_PlAccum is null or w.iv_PlAccum = 0, -- план отсутствует?
						null,	-- да, план отсутствует
						-- нет, тогда *процент выполнения плана* равен частному суммы *выполнения плана* и *плана*
						isnull(w.iv_PlFulfillment, 0)/NULLIF(w.iv_PlAccum, 0) 
					) iv_PlPercentMinusOverFulf -- процент выполнения плана без перевыполнения. Окончание ---------------------------------------------------------------
				, iif (	-- *процент выполнения плана* без *перевыполнения* включая *рассматриваемое* --------------------------------------------------------------------
						w.iv_PlAccum is null or w.iv_PlAccum = 0, -- план отсутствует?
						null, -- да, план отсутствует
						iif (
								-- сумма *выполнения* и *рассматриваемого* больше плана?
								w.iv_PlAccum < isnull(w.iv_PlFulfillment, 0) + isnull(w.ia_inProcessTtlAccum, 0),
								1, -- да, сумма *выполнения* и *рассматриваемого* больше плана, тогда 100%
								-- нет, тогда *процент выполнения плана* равен частному суммы *выполнения плана* и *рассматриваемого* и *плана*
								(isnull(w.iv_PlFulfillment, 0) + isnull(w.ia_inProcessTtlAccum, 0))/NULLIF(w.iv_PlAccum, 0)
							)
					) iv_PlPercentMinusOverFulfInProcess -- *процент выполнения плана* без *перевыполнения* включая *рассматриваемое*. Окончание ------------------------
				, iif (	-- процент выполнения плана ---------------------------------------------------------------------------------------------------------------------
						w.iv_PlAccum is null or w.iv_PlAccum = 0, -- план отсутствует?
						null,	-- да, план отсутствует
						-- нет, тогда процент выполнения плана равен частному суммы выполнения и перевыполнения плана и плана
						(isnull(w.iv_PlFulfillment, 0) + isnull(w.iv_PlOverFulfillment, 0))/NULLIF(w.iv_PlAccum, 0) 
					) iv_PlPercent -- процент выполнения плана. Окончание -----------------------------------------------------------------------------------------------
				, iif (	-- *процент выполнения плана* включая *рассматриваемое* -----------------------------------------------------------------------------------------
						w.iv_PlAccum is null or w.iv_PlAccum = 0, -- план отсутствует?
						null,	-- да, план отсутствует
						-- нет, тогда *процент выполнения плана* равен частному суммы *выполнения*, *перевыполнения* и *рассматриваемого*  и плана
						(isnull(w.iv_PlFulfillment, 0) + isnull(w.iv_PlOverFulfillment, 0) + isnull(w.ia_inProcessTtlAccum, 0))/NULLIF(w.iv_PlAccum, 0) 
					) iv_PlPercentInProcess -- *процент выполнения плана* включая *рассматриваемое*. Окончание ----------------------------------------------------------
				, iif (	-- *процент выполнения плана* включая всё, даже и *сверхлимит* ----------------------------------------------------------------------------------
						w.iv_PlAccum is null or w.iv_PlAccum = 0, -- план отсутствует?
						null,	-- да, план отсутствует
						-- нет, тогда *процент выполнения плана* равен частному *принятого общего* и *плана*
						isnull(w.ia_acceptedTtlAccum, 0)/NULLIF(w.iv_PlAccum, 0) 
					) ia_percentPlDev -- *процент выполнения плана* включая всё, даже и *сверхлимит*. Окончание ---------------------------------------------------------
				, iif (	-- *процент выполнения плана* включая всё, даже и *сверхлимит* и включая *рассматриваемое* ------------------------------------------------------
						w.iv_PlAccum is null or w.iv_PlAccum = 0, -- план отсутствует?
						null,	-- да, план отсутствует
						-- нет, тогда *процент выполнения плана* равен частному суммы *принятого общего* и *рассматриваемого*  и плана
						(isnull(w.ia_acceptedTtlAccum, 0) + isnull(w.ia_inProcessTtlAccum, 0))/NULLIF(w.iv_PlAccum, 0) 
					) ia_percentPlDevInProcess -- *процент выполнения плана* включая всё, даже и *сверхлимит* и включая *рассматриваемое*. Окончание --------------------
				-- план, проценты выполнения. Окончание +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- по инвестиционной схеме. Окончание ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

				-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

				-- по неизвестной схеме ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
				-- лимит, проценты освоения +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				, iif (	-- процент освоения -----------------------------------------------------------------------------------------------------------------------------
						w.uk_lim is null or w.uk_lim = 0, -- лимит отсутствует?
						null,	-- да, лимит отсутствует
						iif ( -- нет, лимит имеется
								w.uk_lim < isnull(w.uk_PlFulfillment, 0) + isnull(w.uk_PlOverFulfillment, 0), -- сумма выполнения и перевыполнения плана больше лимита?
								1, -- да, тогда процент освоения равен 100%
								-- нет, тогда процент освоения равен частному суммы выполнения и перевыполнения плана и лимита
								(isnull(w.uk_PlFulfillment, 0) + isnull(w.uk_PlOverFulfillment, 0))/NULLIF(w.uk_lim, 0) 
							)
					) uk_LimPercent -- процент освоения. Окончание ------------------------------------------------------------------------------------------------------
				, iif ( -- *процент освоения*, включая *рассматриваемое* ------------------------------------------------------------------------------------------------
						w.uk_lim is null or w.uk_lim = 0, -- лимит отсутствует?
						null, -- да, лимит отсутствует
						iif ( -- нет, лимит имеется
								-- сумма *выполнения*, *перевыполнения* и *рассматриваемого* больше *лимита*?
								w.uk_lim < isnull(w.uk_PlFulfillment, 0) + isnull(w.uk_PlOverFulfillment, 0) + isnull(w.uk_inProcessTtlAccum, 0), 
								1, -- да, тогда процент освоения равен 100%
								-- нет, тогда процент освоения равен частному суммы *выполнения*, *перевыполнения* и *рассматриваемого* и *лимита*
								(isnull(w.uk_PlFulfillment, 0) + isnull(w.uk_PlOverFulfillment, 0) + isnull(w.uk_inProcessTtlAccum, 0))/NULLIF(w.uk_lim, 0) 
							)
					) uk_LimPercentInProcess -- *процент освоения*, включая *рассматриваемое*. Окончание ----------------------------------------------------------------
				, iif ( -- процент освоения, включая освоенное сверх лимита ---------------------------------------------------------------------------------------------
						w.uk_lim is null or w.uk_lim = 0, -- лимит отсутствует?
						null,	-- да, лимит отсутствует
						-- нет, лимит имеется, тогда процент освоения равен частному *принятого общего* и *лимита*
						isnull(w.uk_acceptedTtlAccum, 0)/NULLIF(w.uk_lim, 0) 
					) uk_percentDev -- процент освоения, включая освоенное сверх лимита. Окончание ----------------------------------------------------------------------
				, iif ( -- *процент освоения*, включая *освоенное сверх лимита* и *рассматриваемое* ---------------------------------------------------------------------
						w.uk_lim is null or w.uk_lim = 0, -- лимит отсутствует?
						null,	-- да, лимит отсутствует
						-- нет, лимит имеется, тогда процент освоения равен частному *принятого общего* и *лимита*
						(isnull(w.uk_acceptedTtlAccum, 0) + isnull(w.uk_inProcessTtlAccum, 0))/NULLIF(w.uk_lim, 0) 
					) uk_percentDevInProcess -- *процент освоения*, включая *освоенное сверх лимита* и *рассматриваемое*. Окончание -------------------------------------
				-- лимит, проценты освоения. Окончание ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

				-- план, проценты выполнения ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				, iif (	-- процент выполнения плана без перевыполнения --------------------------------------------------------------------------------------------------
						w.uk_PlAccum is null or w.uk_PlAccum = 0, -- план отсутствует?
						null,	-- да, план отсутствует
						-- нет, тогда *процент выполнения плана* равен частному суммы *выполнения плана* и *плана*
						isnull(w.uk_PlFulfillment, 0)/NULLIF(w.uk_PlAccum, 0) 
					) uk_PlPercentMinusOverFulf -- процент выполнения плана без перевыполнения. Окончание ---------------------------------------------------------------
				, iif (	-- *процент выполнения плана* без *перевыполнения* включая *рассматриваемое* --------------------------------------------------------------------
						w.uk_PlAccum is null or w.uk_PlAccum = 0, -- план отсутствует?
						null, -- да, план отсутствует
						iif (
								-- сумма *выполнения* и *рассматриваемого* больше плана?
								w.uk_PlAccum < isnull(w.uk_PlFulfillment, 0) + isnull(w.uk_inProcessTtlAccum, 0),
								1, -- да, сумма *выполнения* и *рассматриваемого* больше плана, тогда 100%
								-- нет, тогда *процент выполнения плана* равен частному суммы *выполнения плана* и *рассматриваемого* и *плана*
								(isnull(w.uk_PlFulfillment, 0) + isnull(w.uk_inProcessTtlAccum, 0))/NULLIF(w.uk_PlAccum, 0)
							)
					) uk_PlPercentMinusOverFulfInProcess -- *процент выполнения плана* без *перевыполнения* включая *рассматриваемое*. Окончание ------------------------
				, iif (	-- процент выполнения плана ---------------------------------------------------------------------------------------------------------------------
						w.uk_PlAccum is null or w.uk_PlAccum = 0, -- план отсутствует?
						null,	-- да, план отсутствует
						-- нет, тогда процент выполнения плана равен частному суммы выполнения и перевыполнения плана и плана
						(isnull(w.uk_PlFulfillment, 0) + isnull(w.uk_PlOverFulfillment, 0))/NULLIF(w.uk_PlAccum, 0) 
					) uk_PlPercent -- процент выполнения плана. Окончание -----------------------------------------------------------------------------------------------
				, iif (	-- *процент выполнения плана* включая *рассматриваемое* -----------------------------------------------------------------------------------------
						w.uk_PlAccum is null or w.uk_PlAccum = 0, -- план отсутствует?
						null,	-- да, план отсутствует
						-- нет, тогда *процент выполнения плана* равен частному суммы *выполнения*, *перевыполнения* и *рассматриваемого*  и плана
						(isnull(w.uk_PlFulfillment, 0) + isnull(w.uk_PlOverFulfillment, 0) + isnull(w.uk_inProcessTtlAccum, 0))/NULLIF(w.uk_PlAccum, 0) 
					) uk_PlPercentInProcess -- *процент выполнения плана* включая *рассматриваемое*. Окончание ----------------------------------------------------------
				, iif (	-- *процент выполнения плана* включая всё, даже и *сверхлимит* ----------------------------------------------------------------------------------
						w.uk_PlAccum is null or w.uk_PlAccum = 0, -- план отсутствует?
						null,	-- да, план отсутствует
						-- нет, тогда *процент выполнения плана* равен частному *принятого общего* и *плана*
						isnull(w.uk_acceptedTtlAccum, 0)/NULLIF(w.uk_PlAccum, 0) 
					) uk_percentPlDev -- *процент выполнения плана* включая всё, даже и *сверхлимит*. Окончание ---------------------------------------------------------
				, iif (	-- *процент выполнения плана* включая всё, даже и *сверхлимит* и включая *рассматриваемое* ------------------------------------------------------
						w.uk_PlAccum is null or w.uk_PlAccum = 0, -- план отсутствует?
						null,	-- да, план отсутствует
						-- нет, тогда *процент выполнения плана* равен частному суммы *принятого общего* и *рассматриваемого*  и плана
						(isnull(w.uk_acceptedTtlAccum, 0) + isnull(w.uk_inProcessTtlAccum, 0))/NULLIF(w.uk_PlAccum, 0) 
					) uk_percentPlDevInProcess -- *процент выполнения плана* включая всё, даже и *сверхлимит* и включая *рассматриваемое*. Окончание --------------------
				-- план, проценты выполнения. Окончание +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				-- по неизвестной схеме. Окончание ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
				, w.* -- ну и здесь, всё что сделано раньше - *группируем результаты по каждой стройке до уровня всего, заказчик, филиал заказчика*
			from
				(
					-- группируем результаты по каждой стройке до уровня всего, заказчик, филиал заказчика ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
					-- это нужно сделать до рассчёта процентов выполнения, так как проценты рассчитываются одинаково для строек
					-- и для вышестоящих уровней группировки... 27.09.2024
					select 
						 u.ogNm, u.branch, u.cstapKey, u.dateRslt
						, u.yKey, u.yyyy, u.mKey, u.mNum, u.mCs, u.mNm, u.mQ, u.mHy
						, u.cstaInvestor, u.ogaKey, u.cstAgPnCode, u.ipgKey, u.ipgCount
						-- агентская схема ==============================================================================================================================
						, u.ag_ipgpKey, sum(u.ag_ipgpSmTtl) ag_ipgpSmTtl, sum(u.ag_PlAccum) ag_PlAccum, sum(u.ag_Pl) ag_Pl
						, sum(u.ag_lim) ag_lim, u.ag_iShKey
						-- состояние выполнения +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
						-- ниже плана
						, sum(u.ag_PlFulfillment) as ag_PlFulfillment, sum(u.ag_PlNonFulfillment_review)as ag_PlNonFulfillment_review
						, sum(u.ag_PlNonFulfillment) as ag_PlNonFulfillment
						-- выше плана ниже лимта
						, sum(u.ag_PlOverFulfillment) as ag_PlOverFulfillment, sum(u.ag_PlRestLimit_review) as ag_PlRestLimit_review
						, sum(u.ag_PlRestLimit) as ag_PlRestLimit
						-- выше лимта
						, sum(u.ag_PlOverLimit) as ag_PlOverLimit, sum(u.ag_PlOverLimit_review) as ag_PlOverLimit_review
						-- освоение, виды и итоговое ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
						-- отчёты агентов -------------------------------------------------------------------------------------------------------------------------------
						, sum(u.ag_presentedAll) as ag_presentedAll, sum(u.ag_presentedAllAccum) as ag_presentedAllAccum
						, sum(u.ag_presentedAllModul) as ag_presentedAllModul, sum(u.ag_presentedAllModulAccum) as ag_presentedAllModulAccum
						, sum(u.ag_presented) ag_presented, sum(u.ag_presentedAccum) ag_presentedAccum
						, sum(u.ag_accepted) ag_accepted, sum(u.ag_acceptedAccum) ag_acceptedAccum
						, sum(u.ag_returned) as ag_returned, sum(u.ag_returnedAccum) as ag_returnedAccum
						, sum(u.ag_inProcess) as ag_inProcess, sum(u.ag_inProcessAccum) as ag_inProcessAccum
						, sum(u.ag_notArrived) as ag_notArrived, sum(u.ag_notArrivedAccum) as ag_notArrivedAccum
						, sum(u.ag_presentedPrevYears) as ag_presentedPrevYears, sum(u.ag_presentedPrevYearsAccum) as ag_presentedPrevYearsAccum
						, sum(u.ag_acceptedPrevYears) as ag_acceptedPrevYears, sum(u.ag_acceptedPrevYearsAccum) as ag_acceptedPrevYearsAccum
						, sum(u.ag_returnedPrevYears) as ag_returnedPrevYears, sum(u.ag_returnedPrevYearsAccum) as ag_returnedPrevYearsAccum
						, sum(u.ag_inProcessPrevYears) as ag_inProcessPrevYears, sum(u.ag_inProcessPrevYearsAccum) as ag_inProcessPrevYearsAccum
						, sum(u.ag_notArrivedPrevYears) as ag_notArrivedPrevYears, sum(u.ag_notArrivedPrevYearsAccum) as ag_notArrivedPrevYearsAccum
						-- агентское вознаграждение ---------------------------------------------------------------------------------------------------------------------
						, sum(u.ag_agFeePresented) as ag_agFeePresented, sum(u.ag_agFeePresentedAccum) as ag_agFeePresentedAccum
						, sum(u.ag_agFeeAccepted) as ag_agFeeAccepted, sum(u.ag_agFeeAcceptedAccum) as ag_agFeeAcceptedAccum
						, sum(u.ag_agFeeReturned) as ag_agFeeReturned, sum(u.ag_agFeeReturnedAccum) as ag_agFeeReturnedAccum
						, sum(u.ag_agFeeInProcess) as ag_agFeeInProcess, sum(u.ag_agFeeInProcessAccum) as ag_agFeeInProcessAccum
						, sum(u.ag_agFeeNotArrived) as ag_agFeeNotArrived, sum(u.ag_agFeeNotArrivedAccum) as ag_agFeeNotArrivedAccum
						-- земельные участки ----------------------------------------------------------------------------------------------------------------------------
						, sum(u.ag_presentedRalp) as ag_presentedRalp, sum(u.ag_presentedRalpAccum) as ag_presentedRalpAccum
						, sum(u.ag_acceptedRalp) as ag_acceptedRalp, sum(u.ag_acceptedRalpAccum) as ag_acceptedRalpAccum
						, sum(u.ag_returnedRalp) as ag_returnedRalp, sum(u.ag_returnedRalpAccum) as ag_returnedRalpAccum
						, sum(u.ag_inProcessRalp) as ag_inProcessRalp, sum(u.ag_inProcessRalpAccum) as ag_inProcessRalpAccum
						, sum(u.ag_notArrivedRalp) as ag_notArrivedRalp, sum(u.ag_notArrivedRalpAccum) as ag_notArrivedRalpAccum
						-- хранение, стройконтроль, ОПИ -----------------------------------------------------------------------------------------------------------------
						, sum(u.ag_storageSum) as ag_storageSum, sum(u.ag_storageSumAccum) as ag_storageSumAccum
						, sum(u.ag_cctSum) as ag_cctSum, sum(u.ag_cctSumAccum) as ag_cctSumAccum
						, sum(u.ag_MnrlSum) as ag_MnrlSum, sum(u.ag_MnrlSumAccum) as ag_MnrlSumAccum
						-- общее ----------------------------------------------------------------------------------------------------------------------------------------
						, sum(u.ag_presentedTtl) ag_presentedTtl, sum(u.ag_presentedTtlAccum) ag_presentedTtlAccum
						, sum(u.ag_acceptedAndInProcessTtl) as ag_acceptedAndInProcessTtl, sum(u.ag_acceptedAndInProcessTtlAccum) as ag_acceptedAndInProcessTtlAccum
						, sum(u.ag_acceptedTtl) ag_acceptedTtl, sum(u.ag_acceptedTtlAccum) ag_acceptedTtlAccum
						, sum(u.ag_returnedTtl) as ag_returnedTtl, sum(u.ag_returnedTtlAccum) as ag_returnedTtlAccum
						, sum(u.ag_inProcessTtl) as ag_inProcessTtl, sum(u.ag_inProcessTtlAccum) as ag_inProcessTtlAccum
						, sum(u.ag_notArrivedTtl) as ag_notArrivedTtl, sum(u.ag_notArrivedTtlAccum) as ag_notArrivedTtlAccum
						, sum(u.ag_restOfLimit) ag_restOfLimit, sum(u.ag_restOfLimitInProcess) as ag_restOfLimitInProcess
						--, ag_percentDev , ag_percentDevInProcess -- они идут из @spIpgChRsltCstUtl3_oneD
						-- агентская схема. Окончание ===================================================================================================================

						-- инвестиционная схема =========================================================================================================================
						, u.iv_ipgpKey, sum(u.iv_ipgpSmTtl) iv_ipgpSmTtl, sum(u.iv_PlAccum) iv_PlAccum, sum(u.iv_Pl) iv_Pl
						, sum(u.iv_lim) iv_lim, u.iv_iShKey
						, sum(u.ia_lim) ia_lim, u.ia_iShKey
						-- состояние выполнения +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
						-- ниже плана
						, sum(u.iv_PlFulfillment) as iv_PlFulfillment, sum(iv_PlNonFulfillment_review) as iv_PlNonFulfillment_review
						, sum(u.iv_PlNonFulfillment) as iv_PlNonFulfillment
						-- выше плана ниже лимта
						, sum(u.iv_PlOverFulfillment) as iv_PlOverFulfillment, sum(iv_PlRestLimit_review) as iv_PlRestLimit_review
						, sum(u.iv_PlRestLimit) as iv_PlRestLimit
						-- выше лимта
						, sum(u.iv_PlOverLimit) as iv_PlOverLimit, sum(iv_PlOverLimit_review) as iv_PlOverLimit_review
						-- инвестиционная схема. Окончание ==============================================================================================================
						-- инвестиционная схема (агентская, неплан) =====================================================================================================
						-- освоение, виды и итоговое ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
						-- отчёты агентов -------------------------------------------------------------------------------------------------------------------------------
						, sum(u.ia_presentedAll) as ia_presentedAll, sum(u.ia_presentedAllAccum) as ia_presentedAllAccum
						, sum(u.ia_presentedAllModul) as ia_presentedAllModul, sum(u.ia_presentedAllModulAccum) as ia_presentedAllModulAccum
						, sum(u.ia_presented) ia_presented, sum(u.ia_presentedAccum) ia_presentedAccum
						, sum(u.ia_accepted) ia_accepted, sum(u.ia_acceptedAccum) ia_acceptedAccum
						, sum(u.ia_returned) as ia_returned, sum(u.ia_returnedAccum) as ia_returnedAccum
						, sum(u.ia_inProcess) as ia_inProcess, sum(u.ia_inProcessAccum) as ia_inProcessAccum
						, sum(u.ia_notArrived) as ia_notArrived, sum(u.ia_notArrivedAccum) as ia_notArrivedAccum
						, sum(u.ia_presentedPrevYears) as ia_presentedPrevYears, sum(u.ia_presentedPrevYearsAccum) as ia_presentedPrevYearsAccum
						, sum(u.ia_acceptedPrevYears) as ia_acceptedPrevYears, sum(u.ia_acceptedPrevYearsAccum) as ia_acceptedPrevYearsAccum
						, sum(u.ia_returnedPrevYears) as ia_returnedPrevYears, sum(u.ia_returnedPrevYearsAccum) as ia_returnedPrevYearsAccum
						, sum(u.ia_inProcessPrevYears) as ia_inProcessPrevYears, sum(u.ia_inProcessPrevYearsAccum) as ia_inProcessPrevYearsAccum
						, sum(u.ia_notArrivedPrevYears) as ia_notArrivedPrevYears, sum(u.ia_notArrivedPrevYearsAccum) as ia_notArrivedPrevYearsAccum
						-- агентское вознаграждение ---------------------------------------------------------------------------------------------------------------------
						, sum(u.ia_agFeePresented) as ia_agFeePresented, sum(u.ia_agFeePresentedAccum) as ia_agFeePresentedAccum
						, sum(u.ia_agFeeAccepted) as ia_agFeeAccepted, sum(u.ia_agFeeAcceptedAccum) as ia_agFeeAcceptedAccum
						, sum(u.ia_agFeeReturned) as ia_agFeeReturned, sum(u.ia_agFeeReturnedAccum) as ia_agFeeReturnedAccum
						, sum(u.ia_agFeeInProcess) as ia_agFeeInProcess, sum(u.ia_agFeeInProcessAccum) as ia_agFeeInProcessAccum
						, sum(u.ia_agFeeNotArrived) as ia_agFeeNotArrived, sum(u.ia_agFeeNotArrivedAccum) as ia_agFeeNotArrivedAccum
						-- земельные участки ----------------------------------------------------------------------------------------------------------------------------
						, sum(u.ia_presentedRalp) as ia_presentedRalp, sum(u.ia_presentedRalpAccum) as ia_presentedRalpAccum
						, sum(u.ia_acceptedRalp) as ia_acceptedRalp, sum(u.ia_acceptedRalpAccum) as ia_acceptedRalpAccum
						, sum(u.ia_returnedRalp) as ia_returnedRalp, sum(u.ia_returnedRalpAccum) as ia_returnedRalpAccum
						, sum(u.ia_inProcessRalp) as ia_inProcessRalp, sum(u.ia_inProcessRalpAccum) as ia_inProcessRalpAccum
						, sum(u.ia_notArrivedRalp) as ia_notArrivedRalp, sum(u.ia_notArrivedRalpAccum) as ia_notArrivedRalpAccum
						-- хранение, стройконтроль, ОПИ -----------------------------------------------------------------------------------------------------------------
						, sum(u.ia_storageSum) as ia_storageSum, sum(u.ia_storageSumAccum) as ia_storageSumAccum
						, sum(u.ia_cctSum) as ia_cctSum, sum(u.ia_cctSumAccum) as ia_cctSumAccum
						, sum(u.ia_MnrlSum) as ia_MnrlSum, sum(u.ia_MnrlSumAccum) as ia_MnrlSumAccum
						-- общее ----------------------------------------------------------------------------------------------------------------------------------------
						, sum(u.ia_presentedTtl) as ia_presentedTtl, sum(u.ia_presentedTtlAccum) as ia_presentedTtlAccum
						, sum(u.ia_acceptedAndInProcessTtl) as ia_acceptedAndInProcessTtl, sum(u.ia_acceptedAndInProcessTtlAccum) as ia_acceptedAndInProcessTtlAccum
						, sum(u.ia_acceptedTtl) as ia_acceptedTtl, sum(u.ia_acceptedTtlAccum) as ia_acceptedTtlAccum
						, sum(u.ia_returnedTtl) as ia_returnedTtl, sum(u.ia_returnedTtlAccum) as ia_returnedTtlAccum
						, sum(u.ia_inProcessTtl) as ia_inProcessTtl, sum(u.ia_inProcessTtlAccum) as ia_inProcessTtlAccum
						, sum(u.ia_notArrivedTtl) as ia_notArrivedTtl, sum(u.ia_notArrivedTtlAccum) as ia_notArrivedTtlAccum
						, sum(u.ia_restOfLimit) as ia_restOfLimit, sum(u.ia_restOfLimitInProcess) as ia_restOfLimitInProcess
						--, ia_percentDev, ia_percentDevInProcess
						-- инвестиционная схема (агентская, неплан). Окончание ==========================================================================================

						-- неизвестная схема ============================================================================================================================
						-- по неизвестной схеме
						, u.uk_ipgpKey, sum(u.uk_ipgpSmTtl) uk_ipgpSmTtl, sum(u.uk_PlAccum) uk_PlAccum, sum(u.uk_Pl) uk_Pl
						, sum(u.uk_lim) uk_lim, u.uk_iShKey
						-- состояние выполнения +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
						-- ниже плана
						, sum(u.uk_PlFulfillment) as uk_PlFulfillment, sum(u.uk_PlNonFulfillment_review) as uk_PlNonFulfillment_review
						, sum(u.uk_PlNonFulfillment) as uk_PlNonFulfillment
						-- выше плана ниже лимта
						, sum(u.uk_PlOverFulfillment) as uk_PlOverFulfillment, sum(u.uk_PlRestLimit_review) as uk_PlRestLimit_review
						, sum(u.uk_PlRestLimit) as uk_PlRestLimit
						-- выше лимта
						, sum(u.uk_PlOverLimit) as uk_PlOverLimit, sum(u.uk_PlOverLimit_review) as uk_PlOverLimit_review
						-- освоение, виды и итоговое ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
						-- отчёты агентов -------------------------------------------------------------------------------------------------------------------------------
						, sum(u.uk_presentedAll) as uk_presentedAll, sum(u.uk_presentedAllAccum) as uk_presentedAllAccum
						, sum(u.uk_presentedAllModul) as uk_presentedAllModul, sum(u.uk_presentedAllModulAccum) as uk_presentedAllModulAccum
						, sum(u.uk_presented) as uk_presented, sum(u.uk_presentedAccum) as uk_presentedAccum
						, sum(u.uk_accepted) as uk_accepted, sum(u.uk_acceptedAccum) as uk_acceptedAccum
						, sum(u.uk_returned) as uk_returned, sum(u.uk_returnedAccum) as uk_returnedAccum
						, sum(u.uk_inProcess) as uk_inProcess, sum(u.uk_inProcessAccum) as uk_inProcessAccum
						, sum(u.uk_notArrived) as uk_notArrived, sum(u.uk_notArrivedAccum) as uk_notArrivedAccum
						, sum(u.uk_presentedPrevYears) as uk_presentedPrevYears, sum(u.uk_presentedPrevYearsAccum) as uk_presentedPrevYearsAccum
						, sum(u.uk_acceptedPrevYears) as uk_acceptedPrevYears, sum(u.uk_acceptedPrevYearsAccum) as uk_acceptedPrevYearsAccum
						, sum(u.uk_returnedPrevYears) as uk_returnedPrevYears, sum(u.uk_returnedPrevYearsAccum) as uk_returnedPrevYearsAccum
						, sum(u.uk_inProcessPrevYears) as uk_inProcessPrevYears, sum(u.uk_inProcessPrevYearsAccum) as uk_inProcessPrevYearsAccum
						, sum(u.uk_notArrivedPrevYears) as uk_notArrivedPrevYears, sum(u.uk_notArrivedPrevYearsAccum) as uk_notArrivedPrevYearsAccum
						-- агентское вознаграждение ---------------------------------------------------------------------------------------------------------------------
						, sum(u.uk_agFeePresented) as uk_agFeePresented, sum(u.uk_agFeePresentedAccum) as uk_agFeePresentedAccum
						, sum(u.uk_agFeeAccepted) as uk_agFeeAccepted, sum(u.uk_agFeeAcceptedAccum) as uk_agFeeAcceptedAccum
						, sum(u.uk_agFeeReturned) as uk_agFeeReturned, sum(u.uk_agFeeReturnedAccum) as uk_agFeeReturnedAccum
						, sum(u.uk_agFeeInProcess) as uk_agFeeInProcess, sum(u.uk_agFeeInProcessAccum) as uk_agFeeInProcessAccum
						, sum(u.uk_agFeeNotArrived) as uk_agFeeNotArrived, sum(u.uk_agFeeNotArrivedAccum) as uk_agFeeNotArrivedAccum
						-- земельные участки ----------------------------------------------------------------------------------------------------------------------------
						, sum(u.uk_presentedRalp) as uk_presentedRalp, sum(u.uk_presentedRalpAccum) as uk_presentedRalpAccum
						, sum(u.uk_acceptedRalp) as uk_acceptedRalp, sum(u.uk_acceptedRalpAccum) as uk_acceptedRalpAccum
						, sum(u.uk_returnedRalp) as uk_returnedRalp, sum(u.uk_returnedRalpAccum) as uk_returnedRalpAccum
						, sum(u.uk_inProcessRalp) as uk_inProcessRalp, sum(u.uk_inProcessRalpAccum) as uk_inProcessRalpAccum
						, sum(u.uk_notArrivedRalp) as uk_notArrivedRalp, sum(u.uk_notArrivedRalpAccum) as uk_notArrivedRalpAccum
						-- хранение, стройконтроль, ОПИ -----------------------------------------------------------------------------------------------------------------
						, sum(u.uk_storageSum) uk_storageSum, sum(u.uk_storageSumAccum) uk_storageSumAccum
						, sum(u.uk_cctSum) uk_cctSum, sum(u.uk_cctSumAccum) uk_cctSumAccum
						, sum(u.uk_MnrlSum) uk_MnrlSum, sum(u.uk_MnrlSumAccum) uk_MnrlSumAccum
						-- общее ----------------------------------------------------------------------------------------------------------------------------------------
						, sum(u.uk_presentedTtl) as uk_presentedTtl, sum(u.uk_presentedTtlAccum) as uk_presentedTtlAccum
						, sum(u.uk_acceptedAndInProcessTtl) as uk_acceptedAndInProcessTtl, sum(u.uk_acceptedAndInProcessTtlAccum) as uk_acceptedAndInProcessTtlAccum
						, sum(u.uk_acceptedTtl) as uk_acceptedTtl, sum(u.uk_acceptedTtlAccum) as uk_acceptedTtlAccum
						, sum(u.uk_returnedTtl) as uk_returnedTtl, sum(u.uk_returnedTtlAccum) as uk_returnedTtlAccum
						, sum(u.uk_inProcessTtl) as uk_inProcessTtl, sum(u.uk_inProcessTtlAccum) as uk_inProcessTtlAccum
						, sum(u.uk_notArrivedTtl) as uk_notArrivedTtl, sum(u.uk_notArrivedTtlAccum) as uk_notArrivedTtlAccum
						, sum(u.uk_restOfLimit) as uk_restOfLimit, sum(u.uk_restOfLimitInProcess) as uk_restOfLimitInProcess
						--, uk_percentDev, uk_percentDevInProcess
						-- неизвестная схема. Окончание =================================================================================================================

						-- агентская схема (неплан) =====================================================================================================================
						, sum(u.np_lim) np_lim, u.np_iShKey -- 14.10.2024 странно очень, какой у неплана может быть лимит... Но испорически так сложилось. 
						-- И в Access, в ipgChRsltPlCstPercent есть такая колонка есть
						-- отчёты агентов -------------------------------------------------------------------------------------------------------------------------------
						, sum(u.np_presentedAll) as np_presentedAll, sum(u.np_presentedAllAccum) as np_presentedAllAccum
						, sum(u.np_presentedAllModul) as np_presentedAllModul, sum(u.np_presentedAllModulAccum) as np_presentedAllModulAccum
						, sum(u.np_presented) as np_presented, sum(u.np_presentedAccum) as np_presentedAccum
						, sum(u.np_accepted) as np_accepted, sum(u.np_acceptedAccum) as np_acceptedAccum
						, sum(u.np_returned) as np_returned, sum(u.np_returnedAccum) as np_returnedAccum
						, sum(u.np_inProcess) as np_inProcess, sum(u.np_inProcessAccum) as np_inProcessAccum
						, sum(u.np_notArrived) as np_notArrived, sum(u.np_notArrivedAccum) as np_notArrivedAccum
						, sum(u.np_presentedPrevYears) as np_presentedPrevYears, sum(u.np_presentedPrevYearsAccum) as np_presentedPrevYearsAccum
						, sum(u.np_acceptedPrevYears) as np_acceptedPrevYears, sum(u.np_acceptedPrevYearsAccum) as np_acceptedPrevYearsAccum
						, sum(u.np_returnedPrevYears) as np_returnedPrevYears, sum(u.np_returnedPrevYearsAccum) as np_returnedPrevYearsAccum
						, sum(u.np_inProcessPrevYears) as np_inProcessPrevYears, sum(u.np_inProcessPrevYearsAccum) as np_inProcessPrevYearsAccum
						, sum(u.np_notArrivedPrevYears) as np_notArrivedPrevYears, sum(u.np_notArrivedPrevYearsAccum) as np_notArrivedPrevYearsAccum
						-- агентское вознаграждение ---------------------------------------------------------------------------------------------------------------------
						, sum(u.np_agFeePresented) as np_agFeePresented, sum(u.np_agFeePresentedAccum) as np_agFeePresentedAccum
						, sum(u.np_agFeeAccepted) as np_agFeeAccepted, sum(u.np_agFeeAcceptedAccum) as np_agFeeAcceptedAccum
						, sum(u.np_agFeeReturned) as np_agFeeReturned, sum(u.np_agFeeReturnedAccum) as np_agFeeReturnedAccum
						, sum(u.np_agFeeInProcess) as np_agFeeInProcess, sum(u.np_agFeeInProcessAccum) as np_agFeeInProcessAccum
						, sum(u.np_agFeeNotArrived) as np_agFeeNotArrived, sum(u.np_agFeeNotArrivedAccum) as np_agFeeNotArrivedAccum
						-- земельные участки ----------------------------------------------------------------------------------------------------------------------------
						, sum(u.np_presentedRalp) as np_presentedRalp, sum(u.np_presentedRalpAccum) as np_presentedRalpAccum
						, sum(u.np_acceptedRalp) as np_acceptedRalp, sum(u.np_acceptedRalpAccum) as np_acceptedRalpAccum
						, sum(u.np_returnedRalp) as np_returnedRalp, sum(u.np_returnedRalpAccum) as np_returnedRalpAccum
						, sum(u.np_inProcessRalp) as np_inProcessRalp, sum(u.np_inProcessRalpAccum) as np_inProcessRalpAccum
						, sum(u.np_notArrivedRalp) as np_notArrivedRalp, sum(u.np_notArrivedRalpAccum) as np_notArrivedRalpAccum
						-- хранение, стройконтроль, ОПИ -----------------------------------------------------------------------------------------------------------------
						, sum(u.np_storageSum) np_storageSum, sum(u.np_storageSumAccum) np_storageSumAccum
						, sum(u.np_cctSum) np_cctSum, sum(u.np_cctSumAccum) np_cctSumAccum
						, sum(u.np_MnrlSum) np_MnrlSum, sum(u.np_MnrlSumAccum) np_MnrlSumAccum
						-- общее ----------------------------------------------------------------------------------------------------------------------------------------
						, sum(u.np_presentedTtl) np_presentedTtl, sum(u.np_presentedTtlAccum) np_presentedTtlAccum
						, sum(u.np_acceptedAndInProcessTtl) as np_acceptedAndInProcessTtl, sum(u.np_acceptedAndInProcessTtlAccum) as np_acceptedAndInProcessTtlAccum
						, sum(u.np_acceptedTtl) np_acceptedTtl, sum(u.np_acceptedTtlAccum) np_acceptedTtlAccum
						, sum(u.np_returnedTtl) as np_returnedTtl, sum(u.np_returnedTtlAccum) as np_returnedTtlAccum
						, sum(u.np_inProcessTtl) as np_inProcessTtl, sum(u.np_inProcessTtlAccum) as np_inProcessTtlAccum
						, sum(u.np_notArrivedTtl) as np_notArrivedTtl, sum(u.np_notArrivedTtlAccum) as np_notArrivedTtlAccum
						, sum(u.np_restOfLimit) np_restOfLimit, sum(u.np_restOfLimitInProcess) as np_restOfLimitInProcess
						--, np_percentDev--, np_percentDevInProcess
						-- агентская схема (неплан). Окончание ==========================================================================================================

						-- прочие затраты ===============================================================================================================================
						-- отчёты агентов -------------------------------------------------------------------------------------------------------------------------------
						, sum(u.oh_presentedAll) as oh_presentedAll, sum(u.oh_presentedAllAccum) as oh_presentedAllAccum
						, sum(u.oh_presentedAllModul) as oh_presentedAllModul, sum(u.oh_presentedAllModulAccum) as oh_presentedAllModulAccum
						, sum(u.oh_presented) as oh_presented, sum(u.oh_presentedAccum) as oh_presentedAccum
						, sum(u.oh_accepted) as oh_accepted, sum(u.oh_acceptedAccum) as oh_acceptedAccum
						, sum(u.oh_returned) as oh_returned, sum(u.oh_returnedAccum) as oh_returnedAccum
						, sum(u.oh_inProcess) as oh_inProcess, sum(u.oh_inProcessAccum) as oh_inProcessAccum
						, sum(u.oh_notArrived) as oh_notArrived, sum(u.oh_notArrivedAccum) as oh_notArrivedAccum
						, sum(u.oh_presentedPrevYears) as oh_presentedPrevYears, sum(u.oh_presentedPrevYearsAccum) as oh_presentedPrevYearsAccum
						, sum(u.oh_acceptedPrevYears) as oh_acceptedPrevYears, sum(u.oh_acceptedPrevYearsAccum) as oh_acceptedPrevYearsAccum
						, sum(u.oh_returnedPrevYears) as oh_returnedPrevYears, sum(u.oh_returnedPrevYearsAccum) as oh_returnedPrevYearsAccum
						, sum(u.oh_inProcessPrevYears) as oh_inProcessPrevYears, sum(u.oh_inProcessPrevYearsAccum) as oh_inProcessPrevYearsAccum
						, sum(u.oh_notArrivedPrevYears) as oh_notArrivedPrevYears, sum(u.oh_notArrivedPrevYearsAccum) as oh_notArrivedPrevYearsAccum
						-- агентское вознаграждение ---------------------------------------------------------------------------------------------------------------------
						-- 14.07.2023 добавил прочие отчёты для агентского вознаграждения
						, sum(u.oh_agFeePresented) as oh_agFeePresented, sum(u.oh_agFeePresentedAccum) as oh_agFeePresentedAccum
						, sum(u.oh_agFeeAccepted) as oh_agFeeAccepted, sum(u.oh_agFeeAcceptedAccum) as oh_agFeeAcceptedAccum
						, sum(u.oh_agFeeReturned) as oh_agFeeReturned, sum(u.oh_agFeeReturnedAccum) as oh_agFeeReturnedAccum
						, sum(u.oh_agFeeInProcess) as oh_agFeeInProcess, sum(u.oh_agFeeInProcessAccum) as oh_agFeeInProcessAccum
						, sum(u.oh_agFeeNotArrived) as oh_agFeeNotArrived, sum(u.oh_agFeeNotArrivedAccum) as oh_agFeeNotArrivedAccum
						-- общее ----------------------------------------------------------------------------------------------------------------------------------------
						, sum(u.oh_presentedTtl) as oh_presentedTtl, sum(u.oh_presentedTtlAccum) as oh_presentedTtlAccum
						, sum(u.oh_acceptedAndInProcessTtl) as oh_acceptedAndInProcessTtl, sum(u.oh_acceptedAndInProcessTtlAccum) as oh_acceptedAndInProcessTtlAccum
						, sum(u.oh_acceptedTtl) as oh_acceptedTtl, sum(u.oh_acceptedTtlAccum) as oh_acceptedTtlAccum
						, sum(u.oh_returnedTtl) as oh_returnedTtl, sum(u.oh_returnedTtlAccum) as oh_returnedTtlAccum
						, sum(u.oh_inProcessTtl) as oh_inProcessTtl, sum(u.oh_inProcessTtlAccum) as oh_inProcessTtlAccum
						, sum(u.oh_notArrivedTtl) as oh_notArrivedTtl, sum(u.oh_notArrivedTtlAccum) as oh_notArrivedTtlAccum
						-- прочие затраты. Окончание ====================================================================================================================

					from
						(
							-- получаем результата вычислений подлежащие, вполследствии, группировке
							select
								-- по агентской схеме ===================================================================================================================
								-- ниже плана ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
								iif ( -- выполнение .....................................................................................................................
										z.ag_lim < z.ag_acceptedTtlAccum, -- *общее принятое* больше *лимита*?
										iif ( -- да, *общее принятое* больше *лимита*
												isnull(z.ag_PlAccum, 0) - isnull(z.ag_lim, 0) < 0, -- *план* меньше *лимита*?
												isnull(z.ag_PlAccum, 0), -- да, тогда выполнение равно *плану*
												isnull(z.ag_lim, 0) -- нет, тогда выполнение равно *лимиту*
											),
										iif ( -- нет, *общее принятое* не больше *лимита*
												isnull(z.ag_PlAccum, 0) - isnull(z.ag_acceptedTtlAccum, 0) < 0,  -- *план* меньше *общего принятого*?
												isnull(z.ag_PlAccum, 0), -- да, тогда выполнение равно *плану*
												isnull(z.ag_acceptedTtlAccum, 0) -- нет, тогда выполнение равно *общему принятому*
											)
									) as ag_PlFulfillment -- выполнение. Окончание ......................................................................................
								, iif ( -- на рассмотрении из недовыполненного ..........................................................................................
										z.ag_lim < z.ag_acceptedTtlAccum, -- *общее принятое* больше *лимита*?
										0, -- да, *общее принятое* больше *лимита*, следовательно *недовыполненного* нет и рассматривать там нечего
										iif ( -- нет, *общее принятое* не больше *лимита*
												isnull(z.ag_PlAccum, 0) - isnull(z.ag_acceptedTtlAccum, 0) < 0,  -- *план* меньше *общего принятого*?
												0, -- да, *план* меньше *общего принятого*, следовательно *недовыполненног*о нет и рассматривать там нечего
												iif ( -- нет, *план* не меньше *общего принятого*, тогда есть *недовыполнение*
														-- *недовыполнение* меньше *рассматриваемого*?
														(isnull(z.ag_PlAccum, 0) - isnull(z.ag_acceptedTtlAccum, 0)) - isnull(ag_inProcessTtlAccum, 0) < 0, 
														-- да, *недовыполненое* меньше *рассматриваемого*. 
														-- Тогда *рассматриваемое из недовыплненного* равно *недовыполненному*
														isnull(z.ag_PlAccum, 0) - isnull(z.ag_acceptedTtlAccum, 0), 
														-- нет, *недовыполненое* не меньше *рассматриваемого*. 
														-- Тогда *рассматриваемое из недовыплненного* равно *рассматриваемому*
														isnull(ag_inProcessTtlAccum, 0) 
													)
											)
									) as ag_PlNonFulfillment_review -- на рассмотрении из недовыполненного. Окончание ...................................................
								, iif ( -- недовыполнение до плана ......................................................................................................
										z.ag_lim < z.ag_acceptedTtlAccum, -- *общее принятое* больше *лимита*?
										0, -- да, *общее принятое* больше *лимита*, следовательно *недовыполненного* нет
										iif ( -- нет, *общее принятое* не больше *лимита*
												isnull(z.ag_PlAccum, 0) - isnull(z.ag_acceptedTtlAccum, 0) < 0,  -- *план* меньше *общего принятого*?
												0, -- да, *план* меньше *общего принятого*, следовательно *недовыполненного* нет
												iif (
														-- *разница между *планом* и *общим принятым** меньше *рассматриваемого*?
														(isnull(z.ag_PlAccum, 0) - isnull(z.ag_acceptedTtlAccum, 0)) - isnull(ag_inProcessTtlAccum, 0) < 0, 
														-- да, *разница между *планом* и *общим принятым** меньше *рассматриваемого*. 
														-- Тогда *недовыполненного* нет, всё *рассматриваемое из недовыплненного*
														0,
														-- нет, *разница между *планом* и *общим принятым** не меньше *рассматриваемого*. 
														-- Тогда *недовыполненное* равно разности между *рассматриваемым* и *разницей между *планом* и *общим принятым**
														(isnull(z.ag_PlAccum, 0) - isnull(z.ag_acceptedTtlAccum, 0)) - isnull(ag_inProcessTtlAccum, 0)
													)
											)
									) as ag_PlNonFulfillment -- недовыполнение до плана. Окончание ......................................................................
								-- ниже плана. Окончание ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
								-- выше плана, ниже лимита ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
								, iif ( -- перевыполнение ...............................................................................................................
										z.ag_lim < z.ag_acceptedTtlAccum, -- *общее принятое* больше *лимита*?
										iif ( -- да, *общее принятое* больше *лимита*. Перевыполнен не только *план* но и *лимит*
												isnull(z.ag_PlAccum, 0) - isnull(z.ag_lim, 0) < 0, -- *план* меньше *лимита*?
												-- да, *план* меньше *лимита*. *Перевыполнение* включает всю разницу между *планом* и *лимитом*
												(isnull(z.ag_PlAccum, 0) - isnull(z.ag_lim, 0)) * -1, 
												0 -- нет, *план* не меньше *лимита*. Видимо он ему равен. Это специфично для декабря. *Перевыполнения* нет
											),
										iif (-- нет, общее принятое не больше лимита
												isnull(z.ag_PlAccum, 0) - isnull(z.ag_acceptedTtlAccum, 0) < 0, -- *план* меньше *общего принятого*?
												-- да, *план* меньше *общего принятого*. Тогда *перевыполнение* это разница между *планом* и *общим принятым*
												(isnull(z.ag_PlAccum, 0) - isnull(z.ag_acceptedTtlAccum, 0)) * -1, 
												0 -- нет, *план* не меньше *общего принятого*. *Перевыполнения* нет
											)
									) as ag_PlOverFulfillment -- перевыполнение. Окончание ..............................................................................
								, iif ( -- рассмотрение остатка лимита ..................................................................................................
										isnull(z.ag_lim, 0) < isnull(z.ag_acceptedTtlAccum, 0), -- *общее принятое* больше *лимита*?
										0, -- 1-я картинка. да, *общее принятое* больше *лимита*. Не может быть *рассмотрения остатка лимита*, он весь перервыполнен
										iif (-- нет, *общее принятое* не больше *лимита*
												isnull(z.ag_PlAccum, 0) - isnull(z.ag_acceptedTtlAccum, 0) < 0, -- *общее принятое* больше *плана*?
												-- да, *общее принятое* больше *плана*
												iif ( -- **общее принятое* + *рассматриваемое** больше *лимита*?
														isnull(z.ag_acceptedAndInProcessTtlAccum, 0) > isnull(z.ag_lim, 0),
														-- 2-я картинка. да, **общее принятое* + *рассматриваемое** больше *лимита*. 
														-- Тогда *рассмотрение остатка лимита* равно разности *лимита* и *общего принятого*
														isnull(z.ag_lim, 0) - isnull(z.ag_acceptedTtlAccum, 0),
														-- 3-я картинка. нет, *общее принятое* + *рассматриваемое* не больше *лимита*. 
														-- Тогда *рассмотрение остатка лимита* равно *рассматриваемому*
														ag_inProcessTtlAccum
													), 
												iif ( -- нет, *общее принятое* не больше *плана*. *Перевыполнения* нет
														-- **общее принятое* + *рассматриваемое** больше *лимита*?
														isnull(z.ag_acceptedAndInProcessTtlAccum, 0) > isnull(z.ag_lim, 0),
														-- да, **общее принятое* + *рассматриваемое** больше *лимита*. Тогда, 4-я картинка, *рассмотрение остатка лимита*
														-- будет равно разности между *лимитом* и *планом*
														isnull(z.ag_lim, 0) - isnull(z.ag_PlAccum, 0),  
														iif ( -- *общее принятое* + *рассматриваемое* больше *плана*?
																isnull(z.ag_acceptedAndInProcessTtlAccum, 0) > isnull(z.ag_PlAccum, 0),
																-- 5-я картинка. да, **общее принятое* + *рассматриваемое** больше *плана*.
																-- Тогда *рассмотрение остатка лимита* 
																-- равно разности **общего принятого* плюс *рассматриваемого** и *плана*
																isnull(z.ag_acceptedAndInProcessTtlAccum, 0) - isnull(z.ag_PlAccum, 0),
																-- 6-я картинка. нет, **общее принятое* плюс *рассматриваемое** не больше *плана*
																0 -- Тогда *рассмотрение остатка лимита* отсутствует
															)
													)
											)
									) as ag_PlRestLimit_review -- рассмотрение остатка лимита. Окончание ................................................................
								, iif ( -- остаток лимита ...............................................................................................................
										isnull(z.ag_lim, 0) < isnull(z.ag_acceptedTtlAccum, 0), -- *общее принятое* больше *лимита*?
										0, -- 1-я картинка. да, *общее принятое* больше *лимита*. *Остатка лимита* нет
										iif (-- нет, *общее принятое* не больше *лимита*
												isnull(z.ag_PlAccum, 0) - isnull(z.ag_acceptedTtlAccum, 0) < 0, -- *общее принятое* больше *плана*? !!! был лимит?
												iif ( -- да, *общее принятое* больше *плана*
														-- **общее принятое* + *рассматриваемое** больше *лимита*?
														isnull(z.ag_acceptedAndInProcessTtlAccum, 0) > isnull(z.ag_lim, 0), 
														-- 2-я картинка. да, *общее принятое* + *рассматриваемое* больше *лимита*. 
														0, -- Тогда *Остатка лимита* нет
														-- 3-я картинка. нет, *общее принятое* не больше *плана*. 
														-- Тогда *Остаток лимита* равен разнице *лимита* и **общего принятого* + *рассматриваемого**
														isnull(z.ag_lim, 0) - isnull(z.ag_acceptedAndInProcessTtlAccum, 0)
													), 
												iif ( -- нет, *общее принятое* не больше *плана*. *Перевыполнения* нет
														-- **общее принятое* + *рассматриваемое** больше *лимита*?
														isnull(z.ag_acceptedAndInProcessTtlAccum, 0) > isnull(z.ag_lim, 0), 
														0, -- да, **общее принятое* + *рассматриваемое** больше *лимита*. 
														-- Тогда, 4-я картинка, *остаток лимита* отсутствует
														iif ( -- нет, **общее принятое* + *рассматриваемое** не больше *лимита*. 
																-- **общее принятое* + *рассматриваемое** больше *плана*?
																isnull(z.ag_acceptedAndInProcessTtlAccum, 0) > isnull(z.ag_PlAccum, 0), 
																-- да, **общее принятое* плюс *рассматриваемое** больше *плана*
																-- Тогда, 5-я картинка, 
																-- *Остаток лимита* равен разнице *лимита* и **общего принятого* + *рассматриваемого**
																isnull(z.ag_lim, 0) - isnull(z.ag_acceptedAndInProcessTtlAccum, 0),
																-- нет, **общее принятое* + *рассматриваемое** не больше *плана*
																-- Тогда, 6-я картинка, *Остаток лимита* равен разнице *лимита* и *плана*
																isnull(z.ag_lim, 0) - isnull(z.ag_PlAccum, 0)
															)
													)
											)
									) as ag_PlRestLimit -- остаток лимита. Окончание ....................................................................................
								-- выше плана, ниже лимита. Окончание ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
								-- выше лимита ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
								, iif ( -- превышение лимита ............................................................................................................
										isnull(z.ag_lim, 0) < isnull(z.ag_acceptedTtlAccum, 0), -- *общее принятое* больше *лимита*?
										-- да, *общее принятое* больше *лимита*. Тогда *превышение лимита* равно разности *общего принятого* и *лимита*
										isnull(z.ag_acceptedTtlAccum, 0) - isnull(z.ag_lim, 0), 
										0 -- нет, *общее принятое* не больше *лимита*. Тогда *превышения лимита* нет
									) as ag_PlOverLimit -- превышение лимита. Окончание .................................................................................
								, iif ( -- рассмотрение превышения лимита ...............................................................................................
										isnull(z.ag_lim, 0) < isnull(z.ag_acceptedTtlAccum, 0), -- *общее принятое* больше *лимита*?
										-- да, *общее принятое* больше *лимита*. Тогда *рассмотрение превышения лимита* равно *рассматриваемому*
										isnull(z.ag_inProcessTtlAccum, 0), 
										-- нет, *общее принятое* не больше *лимита*
										iif ( -- **общее принятое* плюс *рассматриваемое** больше лимита?
												isnull(z.ag_acceptedAndInProcessTtlAccum, 0) > isnull(z.ag_lim, 0),
												-- да, **общее принятое* плюс *рассматриваемое** больше лимита. 
												-- Тогда *рассмотрение превышения лимита* равно разности **общего принятого* плюс *рассматриваемого** и *лимита*
												isnull(z.ag_acceptedAndInProcessTtlAccum, 0) - isnull(z.ag_lim, 0),
												0 -- нет, **общее принятое* плюс *рассматриваемое** не больше лимита. Тогда *рассмотрения превышения лимита* нет
											)
									) as ag_PlOverLimit_review -- рассмотрение превышения лимита. Окончание .............................................................
								-- выше лимита. Окончание ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
								-- по агентской схеме. Окончание ========================================================================================================

								-- по инвестиционной схеме ==============================================================================================================
								-- ниже плана ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
								, iif ( -- выполнение ...................................................................................................................
										isnull(z.iv_lim, 0) < isnull(z.ia_acceptedTtlAccum, 0), -- *общее принятое* больше *лимита*?
										iif ( -- да, *общее принятое* больше *лимита*
												isnull(z.iv_PlAccum, 0) - isnull(z.iv_lim, 0) < 0, -- *план* меньше *лимита*?
												isnull(z.iv_PlAccum, 0), -- да, тогда выполнение равно *плану*
												isnull(z.iv_lim, 0) -- нет, тогда выполнение равно *лимиту*
											),
										iif ( -- нет, *общее принятое* не больше *лимита*
												isnull(z.iv_PlAccum, 0) - isnull(z.ia_acceptedTtlAccum, 0) < 0,  -- *план* меньше *общего принятого*?
												isnull(z.iv_PlAccum, 0), -- да, тогда выполнение равно *плану*
												isnull(z.ia_acceptedTtlAccum, 0) -- нет, тогда выполнение равно *общему принятому*
											)
									) as iv_PlFulfillment -- выполнение. Окончание ......................................................................................
								, iif ( -- на рассмотрении из недовыполненного ..........................................................................................
										isnull(z.iv_lim, 0) < isnull(z.ia_acceptedTtlAccum, 0), -- *общее принятое* больше *лимита*?
										0, -- да, *общее принятое* больше *лимита*, следовательно *недовыполненного* нет и рассматривать там нечего
										iif ( -- нет, *общее принятое* не больше *лимита*
												isnull(z.iv_PlAccum, 0) - isnull(z.ia_acceptedTtlAccum, 0) < 0,  -- *план* меньше *общего принятого*?
												0, -- да, *план* меньше *общего принятого*, следовательно *недовыполненного* нет и рассматривать там нечего
												iif ( -- нет, *план* не меньше *общего принятого*, тогда есть *недовыполнение*
														-- *недовыполнение* меньше *рассматриваемого*?
														(isnull(z.iv_PlAccum, 0) - isnull(z.ia_acceptedTtlAccum, 0)) - isnull(ia_inProcessTtlAccum, 0) < 0, 
														-- да, *недовыполненое* меньше *рассматриваемого*. 
														-- Тогда *рассматриваемое из *недовыплненного* равно *недовыполненному*
														isnull(z.iv_PlAccum, 0) - isnull(z.ia_acceptedTtlAccum, 0), 
														-- нет, *недовыполненое* не меньше *рассматриваемого*. 
														-- Тогда *рассматриваемое из недовыплненного* равно *рассматриваемому*
														isnull(ia_acceptedTtlAccum, 0) 
													)
											)
									) as iv_PlNonFulfillment_review -- на рассмотрении из недовыполненного. Окончание ...................................................
								, iif ( -- недовыполнение до плана ......................................................................................................
										isnull(z.iv_lim, 0) < isnull(z.ia_acceptedTtlAccum, 0), -- *общее принятое* больше *лимита*?
										0, -- да, *общее принятое* больше *лимита*, следовательно *недовыполненного* нет
										iif ( -- нет, *общее принятое* не больше *лимита*
												isnull(z.iv_PlAccum, 0) - isnull(z.ia_acceptedTtlAccum, 0) < 0,  -- *план* меньше *общего принятого*?
												0, -- да, *план* меньше *общего принятого*, следовательно *недовыполненного* нет
												iif ( -- нет, *план* не меньше *общего принятого*, тогда есть *недовыполнение*
														-- *разница между *планом* и *общим принятым** меньше *рассматриваемого*?
														(isnull(z.iv_PlAccum, 0) - isnull(z.ia_acceptedTtlAccum, 0)) - isnull(z.ia_inProcessTtlAccum, 0) < 0, 
														-- да, *разница между *планом* и *общим принятым** меньше *рассматриваемого*. 
														-- Тогда *недовыполненного* нет, всё *рассматриваемое из недовыплненного*
														0,
														-- нет, *разница между *планом* и *общим принятым** не меньше *рассматриваемого*. 
														-- Тогда *недовыполненное* равно разности между *рассматриваемым* и *разницей между *планом* и *общим принятым**
														(isnull(z.iv_PlAccum, 0) - isnull(z.ia_acceptedTtlAccum, 0)) - isnull(z.ia_inProcessTtlAccum, 0)
													)
											)
									) as iv_PlNonFulfillment -- недовыполнение до плана. Окончание ......................................................................
								-- ниже плана. Окончание ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
								-- выше плана, ниже лимита ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
								, iif ( -- перевыполнение ...............................................................................................................
										isnull(z.iv_lim, 0) < isnull(z.ia_acceptedTtlAccum, 0), -- *общее принятое* больше *лимита*?
										iif ( -- да, *общее принятое* больше *лимита*. Перевыполнен не только *план* но и *лимит*
												isnull(z.iv_PlAccum, 0) - isnull(z.iv_lim, 0) < 0, -- *план* меньше *лимита*?
												-- да, *план* меньше *лимита*. *Перевыполнение* включает всю разницу между *планом* и *лимитом*
												(isnull(z.iv_PlAccum, 0) - isnull(z.iv_lim, 0)) * -1, 
												0 -- нет, *план* не меньше *лимита*. Видимо он ему равен. Это специфично для декабря. *Перевыполнения* нет
											),
										iif (-- нет, *общее принятое* не больше *лимита*
												isnull(z.iv_PlAccum, 0) - isnull(z.ia_acceptedTtlAccum, 0) < 0, -- *план* меньше *общего принятого*?
												-- да, *план* меньше *общего принятого*. Тогда *перевыполнение* это разница между *планом* и *общим принятым*
												(isnull(z.iv_PlAccum, 0) - isnull(z.ia_acceptedTtlAccum, 0)) * -1, 
												0 -- нет, *план* не меньше *общего принятого*. *Перевыполнения* нет
											)
									) as iv_PlOverFulfillment -- перевыполнение. Окончание ..............................................................................
								, iif ( -- рассмотрение остатка лимита ..................................................................................................
										isnull(z.iv_lim, 0) < isnull(z.ia_acceptedTtlAccum, 0), -- *общее принятое* больше *лимита*?
										0, -- 1-я картинка. да, *общее принятое* больше *лимита*. Не может быть *рассмотрения остатка лимита*, он весь перервыполнен
										iif (-- нет, *общее принятое* не больше *лимита*
												isnull(z.iv_PlAccum, 0) - isnull(z.ia_acceptedTtlAccum, 0) < 0, -- *общее принятое* больше *плана*?
												-- да, *общее принятое* больше *плана*
												iif ( -- **общее принятое* + *рассматриваемое** больше *лимита*?
														isnull(z.ia_acceptedAndInProcessTtlAccum, 0) > isnull(z.iv_lim, 0),
														-- 2-я картинка. да, **общее принятое* + *рассматриваемое** больше *лимита*. 
														-- Тогда *рассмотрение остатка лимита* равно разности *лимита* и *общего принятого*
														isnull(z.iv_lim, 0) - isnull(z.ia_acceptedTtlAccum, 0),
														-- 3-я картинка. нет, *общее принятое* + *рассматриваемое* не больше *лимита*. 
														-- Тогда *рассмотрение остатка лимита* равно *рассматриваемому*
														ia_inProcessTtlAccum
													), 
												iif ( -- нет, *общее принятое* не больше *плана*. *Перевыполнения* нет
														-- **общее принятое* + *рассматриваемое** больше *лимита*?
														isnull(z.ia_acceptedAndInProcessTtlAccum, 0) > isnull(z.iv_lim, 0),
														-- да, **общее принятое* + *рассматриваемое** больше *лимита*. Тогда, 4-я картинка, *рассмотрение остатка лимита*
														-- будет равно разности между *лимитом* и *планом*
														isnull(z.iv_lim, 0) - isnull(z.iv_PlAccum, 0),  
														iif ( -- *общее принятое* + *рассматриваемое* больше *плана*?
																isnull(z.ia_acceptedAndInProcessTtlAccum, 0) > isnull(z.iv_PlAccum, 0),
																-- 5-я картинка. да, **общее принятое* + *рассматриваемое** больше *плана*.
																-- Тогда *рассмотрение остатка лимита* 
																-- равно разности **общего принятого* плюс *рассматриваемого** и *плана*
																isnull(z.ia_acceptedAndInProcessTtlAccum, 0) - isnull(z.iv_PlAccum, 0),
																-- 6-я картинка. нет, **общее принятое* плюс *рассматриваемое** не больше *плана*
																0 -- Тогда *рассмотрение остатка лимита* отсутствует
															)
													)
											)
									) as iv_PlRestLimit_review -- рассмотрение остатка лимита. Окончание ................................................................
								, iif ( -- остаток лимита ...............................................................................................................
										isnull(z.iv_lim, 0) < isnull(z.ia_acceptedTtlAccum, 0), -- *общее принятое* больше *лимита*?
										0, -- 1-я картинка. да, *общее принятое* больше *лимита*. *Остатка лимита* нет
										iif (-- нет, *общее принятое* не больше *лимита*
												isnull(z.iv_PlAccum, 0) - isnull(z.ia_acceptedTtlAccum, 0) < 0, -- *общее принятое* больше *плана*?
												iif ( -- да, *общее принятое* больше *плана*
														-- **общее принятое* + *рассматриваемое** больше *лимита*?
														isnull(z.ia_acceptedAndInProcessTtlAccum, 0) > isnull(z.iv_lim, 0), 
														-- 2-я картинка. да, *общее принятое* + *рассматриваемое* больше *лимита*. 
														0, -- Тогда *Остатка лимита* нет
														-- 3-я картинка. нет, *общее принятое* не больше *плана*. 
														-- Тогда *Остаток лимита* равен разнице *лимита* и **общего принятого* + *рассматриваемого**
														isnull(z.iv_lim, 0) - isnull(z.ia_acceptedAndInProcessTtlAccum, 0)
													), 
												iif ( -- нет, *общее принятое* не больше *плана*. *Перевыполнения* нет
														-- **общее принятое* + *рассматриваемое** больше *лимита*?
														isnull(z.ia_acceptedAndInProcessTtlAccum, 0) > isnull(z.iv_lim, 0), 
														0, -- да, **общее принятое* + *рассматриваемое** больше *лимита*. 
														-- Тогда, 4-я картинка, *остаток лимита* отсутствует
														iif ( -- нет, **общее принятое* + *рассматриваемое** не больше *лимита*. 
																-- **общее принятое* + *рассматриваемое** больше *плана*?
																isnull(z.ia_acceptedAndInProcessTtlAccum, 0) > isnull(z.iv_PlAccum, 0), 
																-- да, **общее принятое* плюс *рассматриваемое** больше *плана*
																-- Тогда, 5-я картинка, 
																-- *Остаток лимита* равен разнице *лимита* и **общего принятого* + *рассматриваемого**
																isnull(z.iv_lim, 0) - isnull(z.ia_acceptedAndInProcessTtlAccum, 0),
																-- нет, **общее принятое* + *рассматриваемое** не больше *плана*
																-- Тогда, 6-я картинка, *Остаток лимита* равен разнице *лимита* и *плана*
																isnull(z.iv_lim, 0) - isnull(z.iv_PlAccum, 0)
															)
													)
											)
									) as iv_PlRestLimit -- остаток лимита. Окончание ....................................................................................
								-- выше плана, ниже лимита. Окончание ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
								-- выше лимита ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
								, iif ( -- превышение лимита ............................................................................................................
										isnull(z.iv_lim, 0) < isnull(z.ia_acceptedTtlAccum, 0), -- *общее принятое* больше *лимита*?
										-- да, *общее принятое* больше *лимита*. Тогда *превышение лимита* равно разности *общего принятого* и *лимита*
										isnull(z.ia_acceptedTtlAccum, 0) - isnull(z.iv_lim, 0), 
										0 -- нет, *общее принятое* не больше *лимита*. Тогда *превышения лимита* нет
									) as iv_PlOverLimit -- превышение лимита. Окончание .................................................................................
								, iif ( -- рассмотрение превышения лимита ...............................................................................................
										isnull(z.iv_lim, 0) < isnull(z.ia_acceptedTtlAccum, 0), -- *общее принятое* больше *лимита*?
										-- да, *общее принятое* больше *лимита*. Тогда *рассмотрение превышения лимита* равно *рассматриваемому*
										isnull(z.ia_inProcessTtlAccum, 0), 
										-- нет, *общее принятое* не больше *лимита*
										iif ( -- **общее принятое* плюс *рассматриваемое** больше лимита?
												isnull(z.ia_acceptedAndInProcessTtlAccum, 0) > isnull(z.iv_lim, 0),
												-- да, **общее принятое* плюс *рассматриваемое** больше лимита. 
												-- Тогда *рассмотрение превышения лимита* равно разности **общего принятого* плюс *рассматриваемого** и *лимита*
												isnull(z.ia_acceptedAndInProcessTtlAccum, 0) - isnull(z.iv_lim, 0),
												0 -- нет, **общее принятое* плюс *рассматриваемое** не больше лимита. Тогда *рассмотрения превышения лимита* нет
											)
									) as iv_PlOverLimit_review -- рассмотрение превышения лимита. Окончание .............................................................
								-- выше лимита. Окончание ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
								-- по инвестиционной схеме. Окончание ===================================================================================================

								-- по неизвестной схеме =================================================================================================================
								-- ниже плана ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
								, iif ( -- выполнение ...................................................................................................................
										z.uk_lim < z.uk_acceptedTtlAccum, -- *общее принятое* больше *лимита*?
										iif ( -- да, *общее принятое* больше *лимита*
												isnull(z.uk_PlAccum, 0) - isnull(z.uk_lim, 0) < 0, -- *план* меньше *лимита*?
												isnull(z.uk_PlAccum, 0), -- да, тогда выполнение равно *плану*
												isnull(z.uk_lim, 0) -- нет, тогда выполнение равно *лимиту*
											),
										iif ( -- нет, *общее принятое* не больше *лимита*
												isnull(z.uk_PlAccum, 0) - isnull(z.uk_acceptedTtlAccum, 0) < 0,  -- *план* меньше *общего принятого*?
												isnull(z.uk_PlAccum, 0), -- да, тогда выполнение равно *плану*
												isnull(z.uk_acceptedTtlAccum, 0) -- нет, тогда выполнение равно *общему принятому*
											)
									) as uk_PlFulfillment -- выполнение. Окончание ......................................................................................
								, iif ( -- на рассмотрении из недовыполненного ..........................................................................................
										z.uk_lim < z.uk_acceptedTtlAccum, -- *общее принятое* больше *лимита*?
										0, -- да, *общее принятое* больше *лимита*, следовательно *недовыполненного* нет и рассматривать там нечего
										iif ( -- нет, *общее принятое* не больше *лимита*
												isnull(z.uk_PlAccum, 0) - isnull(z.uk_acceptedTtlAccum, 0) < 0,  -- *план* меньше *общего принятого*?
												0, -- да, *план* меньше *общего принятого*, следовательно *недовыполненног*о нет и рассматривать там нечего
												iif ( -- нет, *план* не меньше *общего принятого*, тогда есть *недовыполнение*
														-- *недовыполнение* меньше *рассматриваемого*?
														(isnull(z.uk_PlAccum, 0) - isnull(z.uk_acceptedTtlAccum, 0)) - isnull(uk_inProcessTtlAccum, 0) < 0, 
														-- да, *недовыполненое* меньше *рассматриваемого*. Тогда *рассматриваемое из недовыплненного* равно *недовыполненному*
														isnull(z.uk_PlAccum, 0) - isnull(z.uk_acceptedTtlAccum, 0), 
														-- нет, *недовыполненое* не меньше *рассматриваемого*. Тогда *рассматриваемое из недовыплненного* равно *рассматриваемому*
														isnull(uk_inProcessTtlAccum, 0) 
													)
											)
									) as uk_PlNonFulfillment_review -- на рассмотрении из недовыполненного. Окончание ...................................................
								, iif ( -- недовыполнение до плана ......................................................................................................
										z.uk_lim < z.uk_acceptedTtlAccum, -- *общее принятое* больше *лимита*?
										0, -- да, *общее принятое* больше *лимита*, следовательно *недовыполненного* нет
										iif ( -- нет, *общее принятое* не больше *лимита*
												isnull(z.uk_PlAccum, 0) - isnull(z.uk_acceptedTtlAccum, 0) < 0,  -- *план* меньше *общего принятого*?
												0, -- да, *план* меньше *общего принятого*, следовательно *недовыполненного* нет
												iif (
														-- *разница между *планом* и *общим принятым** меньше *рассматриваемого*?
														(isnull(z.uk_PlAccum, 0) - isnull(z.uk_acceptedTtlAccum, 0)) - isnull(uk_inProcessTtlAccum, 0) < 0, 
														-- да, *разница между *планом* и *общим принятым** меньше *рассматриваемого*. 
														-- Тогда *недовыполненного* нет, всё *рассматриваемое из недовыплненного*
														0,
														-- нет, *разница между *планом* и *общим принятым** не меньше *рассматриваемого*. 
														-- Тогда *недовыполненное* равно разности между *рассматриваемым* и *разницей между *планом* и *общим принятым**
														(isnull(z.uk_PlAccum, 0) - isnull(z.uk_acceptedTtlAccum, 0)) - isnull(uk_inProcessTtlAccum, 0)
													)
											)
									) as uk_PlNonFulfillment -- недовыполнение до плана. Окончание ......................................................................
								-- ниже плана. Окончание ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
								-- выше плана, ниже лимита ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
								, iif ( -- перевыполнение ...............................................................................................................
										z.uk_lim < z.uk_acceptedTtlAccum, -- *общее принятое* больше *лимита*?
										iif ( -- да, *общее принятое* больше *лимита*. Перевыполнен не только *план* но и *лимит*
												isnull(z.uk_PlAccum, 0) - isnull(z.uk_lim, 0) < 0, -- *план* меньше *лимита*?
												-- да, *план* меньше *лимита*. *Перевыполнение* включает всю разницу между *планом* и *лимитом*
												(isnull(z.uk_PlAccum, 0) - isnull(z.uk_lim, 0)) * -1, 
												0 -- нет, *план* не меньше *лимита*. Видимо он ему равен. Это специфично для декабря. *Перевыполнения* нет
											),
										iif (-- нет, общее принятое не больше лимита
												isnull(z.uk_PlAccum, 0) - isnull(z.uk_acceptedTtlAccum, 0) < 0, -- *план* меньше *общего принятого*?
												-- да, *план* меньше *общего принятого*. Тогда *перевыполнение* это разница между *планом* и *общим принятым*
												(isnull(z.uk_PlAccum, 0) - isnull(z.uk_acceptedTtlAccum, 0)) * -1, 
												0 -- нет, *план* не меньше *общего принятого*. *Перевыполнения* нет
											)
									) as uk_PlOverFulfillment -- перевыполнение. Окончание ..............................................................................
								, iif ( -- рассмотрение остатка лимита ..................................................................................................
										isnull(z.uk_lim, 0) < isnull(z.uk_acceptedTtlAccum, 0), -- *общее принятое* больше *лимита*?
										0, -- 1-я картинка. да, *общее принятое* больше *лимита*. Не может быть *рассмотрения остатка лимита*, он весь перервыполнен
										iif (-- нет, *общее принятое* не больше *лимита*
												isnull(z.uk_PlAccum, 0) - isnull(z.uk_acceptedTtlAccum, 0) < 0, -- *общее принятое* больше *плана*?
												-- да, *общее принятое* больше *плана*
												iif ( -- **общее принятое* + *рассматриваемое** больше *лимита*?
														isnull(z.uk_acceptedAndInProcessTtlAccum, 0) > isnull(z.uk_lim, 0),
														-- 2-я картинка. да, **общее принятое* + *рассматриваемое** больше *лимита*. 
														-- Тогда *рассмотрение остатка лимита* равно разности *лимита* и *общего принятого*
														isnull(z.uk_lim, 0) - isnull(z.uk_acceptedTtlAccum, 0),
														-- 3-я картинка. нет, *общее принятое* + *рассматриваемое* не больше *лимита*. 
														-- Тогда *рассмотрение остатка лимита* равно *рассматриваемому*
														uk_inProcessTtlAccum
													), 
												iif ( -- нет, *общее принятое* не больше *плана*. *Перевыполнения* нет
														-- **общее принятое* + *рассматриваемое** больше *лимита*?
														isnull(z.uk_acceptedAndInProcessTtlAccum, 0) > isnull(z.uk_lim, 0),
														-- да, **общее принятое* + *рассматриваемое** больше *лимита*. Тогда, 4-я картинка, *рассмотрение остатка лимита*
														-- будет равно разности между *лимитом* и *планом*
														isnull(z.uk_lim, 0) - isnull(z.uk_PlAccum, 0),  
														iif ( -- *общее принятое* + *рассматриваемое* больше *плана*?
																isnull(z.uk_acceptedAndInProcessTtlAccum, 0) > isnull(z.uk_PlAccum, 0),
																-- 5-я картинка. да, **общее принятое* + *рассматриваемое** больше *плана*.
																-- Тогда *рассмотрение остатка лимита* равно разности **общего принятого* плюс *рассматриваемого** и *плана*
																isnull(z.uk_acceptedAndInProcessTtlAccum, 0) - isnull(z.uk_PlAccum, 0),
																-- 6-я картинка. нет, **общее принятое* плюс *рассматриваемое** не больше *плана*
																0 -- Тогда *рассмотрение остатка лимита* отсутствует
															)
													)
											)
									) as uk_PlRestLimit_review -- рассмотрение остатка лимита. Окончание ................................................................
								, iif ( -- остаток лимита ...............................................................................................................
										isnull(z.uk_lim, 0) < isnull(z.uk_acceptedTtlAccum, 0), -- *общее принятое* больше *лимита*?
										0, -- 1-я картинка. да, *общее принятое* больше *лимита*. *Остатка лимита* нет
										iif (-- нет, *общее принятое* не больше *лимита*
												isnull(z.uk_PlAccum, 0) - isnull(z.uk_acceptedTtlAccum, 0) < 0, -- *общее принятое* больше *плана*? !!! был лимит?
												iif ( -- да, *общее принятое* больше *плана*
														-- **общее принятое* + *рассматриваемое** больше *лимита*?
														isnull(z.uk_acceptedAndInProcessTtlAccum, 0) > isnull(z.uk_lim, 0), 
														-- 2-я картинка. да, *общее принятое* + *рассматриваемое* больше *лимита*. 
														0, -- Тогда *Остатка лимита* нет
														-- 3-я картинка. нет, *общее принятое* не больше *плана*. 
														-- Тогда *Остаток лимита* равен разнице *лимита* и **общего принятого* + *рассматриваемого**
														isnull(z.uk_lim, 0) - isnull(z.uk_acceptedAndInProcessTtlAccum, 0)
													), 
												iif ( -- нет, *общее принятое* не больше *плана*. *Перевыполнения* нет
														-- **общее принятое* + *рассматриваемое** больше *лимита*?
														isnull(z.uk_acceptedAndInProcessTtlAccum, 0) > isnull(z.uk_lim, 0), 
														0, -- да, **общее принятое* + *рассматриваемое** больше *лимита*. Тогда, 4-я картинка, *остаток лимита* отсутствует
														iif ( -- нет, **общее принятое* + *рассматриваемое** не больше *лимита*. 
																-- **общее принятое* + *рассматриваемое** больше *плана*?
																isnull(z.uk_acceptedAndInProcessTtlAccum, 0) > isnull(z.uk_PlAccum, 0), 
																-- да, **общее принятое* плюс *рассматриваемое** больше *плана*
																-- Тогда, 5-я картинка, *Остаток лимита* равен разнице *лимита* и **общего принятого* + *рассматриваемого**
																isnull(z.uk_lim, 0) - isnull(z.uk_acceptedAndInProcessTtlAccum, 0),
																-- нет, **общее принятое* + *рассматриваемое** не больше *плана*
																-- Тогда, 6-я картинка, *Остаток лимита* равен разнице *лимита* и *плана*
																isnull(z.uk_lim, 0) - isnull(z.uk_PlAccum, 0)
															)
													)
											)
									) as uk_PlRestLimit -- остаток лимита. Окончание ....................................................................................
								-- выше плана, ниже лимита. Окончание ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
								-- выше лимита ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
								, iif ( -- превышение лимита ............................................................................................................
										isnull(z.uk_lim, 0) < isnull(z.uk_acceptedTtlAccum, 0), -- *общее принятое* больше *лимита*?
										-- да, *общее принятое* больше *лимита*. Тогда *превышение лимита* равно разности *общего принятого* и *лимита*
										isnull(z.uk_acceptedTtlAccum, 0) - isnull(z.uk_lim, 0), 
										0 -- нет, *общее принятое* не больше *лимита*. Тогда *превышения лимита* нет
									) as uk_PlOverLimit -- превышение лимита. Окончание .................................................................................
								, iif ( -- рассмотрение превышения лимита ...............................................................................................
										isnull(z.uk_lim, 0) < isnull(z.uk_acceptedTtlAccum, 0), -- *общее принятое* больше *лимита*?
										-- да, *общее принятое* больше *лимита*. Тогда *рассмотрение превышения лимита* равно *рассматриваемому*
										isnull(z.uk_inProcessTtlAccum, 0), 
										-- нет, *общее принятое* не больше *лимита*
										iif ( -- **общее принятое* плюс *рассматриваемое** больше лимита?
												isnull(z.uk_acceptedAndInProcessTtlAccum, 0) > isnull(z.uk_lim, 0),
												-- да, **общее принятое* плюс *рассматриваемое** больше лимита. 
												-- Тогда *рассмотрение превышения лимита* равно разности **общего принятого* плюс *рассматриваемого** и *лимита*
												isnull(z.uk_acceptedAndInProcessTtlAccum, 0) - isnull(z.uk_lim, 0),
												0 -- нет, **общее принятое* плюс *рассматриваемое** не больше лимита. Тогда *рассмотрения превышения лимита* нет
											)
									) as uk_PlOverLimit_review -- рассмотрение превышения лимита. Окончание .............................................................
								-- выше лимита. Окончание ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
								-- по неизвестной схеме. Окончание ======================================================================================================
								, z.*
							from
								(
									select
										p.cstapKey
										-- переводим помесячные планы (накопленным итогом за предшествующие месяцы) из миллионов в рубли ................................
										-- для агентской схемы
										, ga.ipgpKey ag_ipgpKey, ga.ipgpSmTtl ag_ipgpSmTtl
										, ag_PlAccum = 
											case
												when x.mNum = 0		then 0
												when x.mNum = 1		then gap.iuplpM01 * 1000000
												when x.mNum = 2		then gap.iuplpM02Accum * 1000000
												when x.mNum = 3		then gap.iuplpM03Accum * 1000000
												when x.mNum = 4		then gap.iuplpM04Accum * 1000000
												when x.mNum = 5		then gap.iuplpM05Accum * 1000000
												when x.mNum = 6		then gap.iuplpM06Accum * 1000000
												when x.mNum = 7		then gap.iuplpM07Accum * 1000000
												when x.mNum = 8		then gap.iuplpM08Accum * 1000000
												when x.mNum = 9		then gap.iuplpM09Accum * 1000000
												when x.mNum = 10	then gap.iuplpM10Accum * 1000000
												when x.mNum = 11	then gap.iuplpM11Accum * 1000000
												when x.mNum = 12	then gap.iuplpM12Accum * 1000000
												else 0
											end
										, ag_Pl = 
											case
												when x.mNum = 0		then 0
												when x.mNum = 1		then gap.iuplpM01 * 1000000
												when x.mNum = 2		then gap.iuplpM02 * 1000000
												when x.mNum = 3		then gap.iuplpM03 * 1000000
												when x.mNum = 4		then gap.iuplpM04 * 1000000
												when x.mNum = 5		then gap.iuplpM05 * 1000000
												when x.mNum = 6		then gap.iuplpM06 * 1000000
												when x.mNum = 7		then gap.iuplpM07 * 1000000
												when x.mNum = 8		then gap.iuplpM08 * 1000000
												when x.mNum = 9		then gap.iuplpM09 * 1000000
												when x.mNum = 10	then gap.iuplpM10 * 1000000
												when x.mNum = 11	then gap.iuplpM11 * 1000000
												when x.mNum = 12	then gap.iuplpM12 * 1000000
												else 0
											end
										-- для инвестиционной схемы
										, gi.ipgpKey iv_ipgpKey, gi.ipgpSmTtl iv_ipgpSmTtl
										, iv_PlAccum = 
											case
												when x.mNum = 0		then 0
												when x.mNum = 1		then gip.iuplpM01 * 1000000
												when x.mNum = 2		then gip.iuplpM02Accum * 1000000
												when x.mNum = 3		then gip.iuplpM03Accum * 1000000
												when x.mNum = 4		then gip.iuplpM04Accum * 1000000
												when x.mNum = 5		then gip.iuplpM05Accum * 1000000
												when x.mNum = 6		then gip.iuplpM06Accum * 1000000
												when x.mNum = 7		then gip.iuplpM07Accum * 1000000
												when x.mNum = 8		then gip.iuplpM08Accum * 1000000
												when x.mNum = 9		then gip.iuplpM09Accum * 1000000
												when x.mNum = 10	then gip.iuplpM10Accum * 1000000
												when x.mNum = 11	then gip.iuplpM11Accum * 1000000
												when x.mNum = 12	then gip.iuplpM12Accum * 1000000
												else 0
											end
										, iv_Pl = 
											case
												when x.mNum = 0		then 0
												when x.mNum = 1		then gip.iuplpM01 * 1000000
												when x.mNum = 2		then gip.iuplpM02 * 1000000
												when x.mNum = 3		then gip.iuplpM03 * 1000000
												when x.mNum = 4		then gip.iuplpM04 * 1000000
												when x.mNum = 5		then gip.iuplpM05 * 1000000
												when x.mNum = 6		then gip.iuplpM06 * 1000000
												when x.mNum = 7		then gip.iuplpM07 * 1000000
												when x.mNum = 8		then gip.iuplpM08 * 1000000
												when x.mNum = 9		then gip.iuplpM09 * 1000000
												when x.mNum = 10	then gip.iuplpM10 * 1000000
												when x.mNum = 11	then gip.iuplpM11 * 1000000
												when x.mNum = 12	then gip.iuplpM12 * 1000000
												else 0
											end
										-- для неизвестной схемы
										, gu.ipgpKey uk_ipgpKey, gu.ipgpSmTtl uk_ipgpSmTtl
										, uk_PlAccum = 
											case
												when x.mNum = 0		then 0
												when x.mNum = 1		then gup.iuplpM01 * 1000000
												when x.mNum = 2		then gup.iuplpM02Accum * 1000000
												when x.mNum = 3		then gup.iuplpM03Accum * 1000000
												when x.mNum = 4		then gup.iuplpM04Accum * 1000000
												when x.mNum = 5		then gup.iuplpM05Accum * 1000000
												when x.mNum = 6		then gup.iuplpM06Accum * 1000000
												when x.mNum = 7		then gup.iuplpM07Accum * 1000000
												when x.mNum = 8		then gup.iuplpM08Accum * 1000000
												when x.mNum = 9		then gup.iuplpM09Accum * 1000000
												when x.mNum = 10	then gup.iuplpM10Accum * 1000000
												when x.mNum = 11	then gup.iuplpM11Accum * 1000000
												when x.mNum = 12	then gup.iuplpM12Accum * 1000000
												else 0
											end
										, uk_Pl = 
											case
												when x.mNum = 0		then 0
												when x.mNum = 1		then gup.iuplpM01 * 1000000
												when x.mNum = 2		then gup.iuplpM02 * 1000000
												when x.mNum = 3		then gup.iuplpM03 * 1000000
												when x.mNum = 4		then gup.iuplpM04 * 1000000
												when x.mNum = 5		then gup.iuplpM05 * 1000000
												when x.mNum = 6		then gup.iuplpM06 * 1000000
												when x.mNum = 7		then gup.iuplpM07 * 1000000
												when x.mNum = 8		then gup.iuplpM08 * 1000000
												when x.mNum = 9		then gup.iuplpM09 * 1000000
												when x.mNum = 10	then gup.iuplpM10 * 1000000
												when x.mNum = 11	then gup.iuplpM11 * 1000000
												when x.mNum = 12	then gup.iuplpM12 * 1000000
												else 0
											end
										-- переводим помесячные планы (накопленным итогом за предшествующие месяцы) из миллионов в рубли. Окончание .....................
										, x.dateRslt, 
										i.* -- здесь всё из заполененной выше таблички "@spIpgChRsltCstUtl3_oneD"
									from
										(
											-- формируем перечень дат (fnIpgChDats_2606 @dt, без legacy UNION 01.01/EOMONTH)
											select u.dateRslt,
												iif (
														u.dateRslt < datefromparts(@lsYy, 1, 31), 0, month(u.dateRslt)
													) mNum, u.ipgKey
											from @dt u
											where u.ipgKey is not null
											-- формируем перечень дат, окончание
										) x	
										left join
											@spIpgChRsltCstUtl3_oneD i on
												(x.mNum = i.mNum or (x.mNum = 0 and i.mNum = 1))
												and (x.ipgKey = i.ipgKey or i.ipgKey is null)
											join ags.cstAgPn p on i.cstAgPnCode = p.cstapIpgPnN
											left join -- для агентской схемы
												ags.ipgPn ga on p.cstapKey = ga.ipgpCstAgPn and i.ag_iShKey = ga.ipgpSh and i.ipgKey = ga.ipgpIpg
												left join
													(
												SELECT
													pn.ipgpKey AS iuplpIpgPn,
													@ipgChKey AS ipgcrChain,
													MAX(up.iuplpSubAg) AS iuplpSubAg,
													SUM(CASE WHEN mn.iuplpmMn = 1  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM01,
													SUM(CASE WHEN mn.iuplpmMn = 2  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM02,
													SUM(CASE WHEN mn.iuplpmMn = 3  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM03,
													SUM(CASE WHEN mn.iuplpmMn = 4  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM04,
													SUM(CASE WHEN mn.iuplpmMn = 5  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM05,
													SUM(CASE WHEN mn.iuplpmMn = 6  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM06,
													SUM(CASE WHEN mn.iuplpmMn = 7  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM07,
													SUM(CASE WHEN mn.iuplpmMn = 8  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM08,
													SUM(CASE WHEN mn.iuplpmMn = 9  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM09,
													SUM(CASE WHEN mn.iuplpmMn = 10 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM10,
													SUM(CASE WHEN mn.iuplpmMn = 11 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM11,
													SUM(CASE WHEN mn.iuplpmMn = 12 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM12,
													SUM(CASE WHEN mn.iuplpmMn <= 2  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM02Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 3  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM03Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 4  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM04Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 5  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM05Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 6  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM06Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 7  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM07Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 8  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM08Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 9  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM09Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 10 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM10Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 11 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM11Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 12 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM12Accum
												FROM ags.ipgPn pn
													INNER JOIN ags.ipgUtPlP up ON up.iuplpIpgPn = pn.ipgpKey
													INNER JOIN ags.ipgChRl_2606 v
														ON v.ipgcrvIpg = pn.ipgpIpg AND v.ipgcrvChain = @ipgChKey
													INNER JOIN ags.ipgUtPlGrP gp
														ON gp.iuplgpPl = up.iuplpPl AND gp.iuplgpGr = v.ipgcrvUtPlGr
													INNER JOIN ags.ipgUtPlPnLmMn mn
														ON mn.iuplpmPlPn = up.iuplpKey AND mn.iuplpmStCost = 212
												GROUP BY pn.ipgpKey
												) gap on gap.ipgcrChain = @ipgChKey and ga.ipgpKey = gap.iuplpIpgPn
											left join -- для инвестиционной схемы
												ags.ipgPn gi on p.cstapKey = gi.ipgpCstAgPn and i.iv_iShKey = gi.ipgpSh and i.ipgKey = gi.ipgpIpg
												left join
													(
												SELECT
													pn.ipgpKey AS iuplpIpgPn,
													@ipgChKey AS ipgcrChain,
													MAX(up.iuplpSubAg) AS iuplpSubAg,
													SUM(CASE WHEN mn.iuplpmMn = 1  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM01,
													SUM(CASE WHEN mn.iuplpmMn = 2  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM02,
													SUM(CASE WHEN mn.iuplpmMn = 3  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM03,
													SUM(CASE WHEN mn.iuplpmMn = 4  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM04,
													SUM(CASE WHEN mn.iuplpmMn = 5  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM05,
													SUM(CASE WHEN mn.iuplpmMn = 6  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM06,
													SUM(CASE WHEN mn.iuplpmMn = 7  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM07,
													SUM(CASE WHEN mn.iuplpmMn = 8  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM08,
													SUM(CASE WHEN mn.iuplpmMn = 9  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM09,
													SUM(CASE WHEN mn.iuplpmMn = 10 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM10,
													SUM(CASE WHEN mn.iuplpmMn = 11 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM11,
													SUM(CASE WHEN mn.iuplpmMn = 12 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM12,
													SUM(CASE WHEN mn.iuplpmMn <= 2  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM02Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 3  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM03Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 4  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM04Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 5  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM05Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 6  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM06Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 7  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM07Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 8  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM08Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 9  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM09Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 10 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM10Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 11 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM11Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 12 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM12Accum
												FROM ags.ipgPn pn
													INNER JOIN ags.ipgUtPlP up ON up.iuplpIpgPn = pn.ipgpKey
													INNER JOIN ags.ipgChRl_2606 v
														ON v.ipgcrvIpg = pn.ipgpIpg AND v.ipgcrvChain = @ipgChKey
													INNER JOIN ags.ipgUtPlGrP gp
														ON gp.iuplgpPl = up.iuplpPl AND gp.iuplgpGr = v.ipgcrvUtPlGr
													INNER JOIN ags.ipgUtPlPnLmMn mn
														ON mn.iuplpmPlPn = up.iuplpKey AND mn.iuplpmStCost = 212
												GROUP BY pn.ipgpKey
												) gip on gip.ipgcrChain = @ipgChKey and gi.ipgpKey = gip.iuplpIpgPn
											left join -- для неизвестной схемы
												ags.ipgPn gu on p.cstapKey = gu.ipgpCstAgPn and i.uk_iShKey = gu.ipgpSh and i.ipgKey = gu.ipgpIpg
												left join
													(
												SELECT
													pn.ipgpKey AS iuplpIpgPn,
													@ipgChKey AS ipgcrChain,
													MAX(up.iuplpSubAg) AS iuplpSubAg,
													SUM(CASE WHEN mn.iuplpmMn = 1  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM01,
													SUM(CASE WHEN mn.iuplpmMn = 2  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM02,
													SUM(CASE WHEN mn.iuplpmMn = 3  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM03,
													SUM(CASE WHEN mn.iuplpmMn = 4  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM04,
													SUM(CASE WHEN mn.iuplpmMn = 5  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM05,
													SUM(CASE WHEN mn.iuplpmMn = 6  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM06,
													SUM(CASE WHEN mn.iuplpmMn = 7  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM07,
													SUM(CASE WHEN mn.iuplpmMn = 8  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM08,
													SUM(CASE WHEN mn.iuplpmMn = 9  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM09,
													SUM(CASE WHEN mn.iuplpmMn = 10 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM10,
													SUM(CASE WHEN mn.iuplpmMn = 11 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM11,
													SUM(CASE WHEN mn.iuplpmMn = 12 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM12,
													SUM(CASE WHEN mn.iuplpmMn <= 2  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM02Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 3  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM03Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 4  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM04Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 5  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM05Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 6  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM06Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 7  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM07Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 8  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM08Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 9  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM09Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 10 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM10Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 11 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM11Accum,
													SUM(CASE WHEN mn.iuplpmMn <= 12 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM12Accum
												FROM ags.ipgPn pn
													INNER JOIN ags.ipgUtPlP up ON up.iuplpIpgPn = pn.ipgpKey
													INNER JOIN ags.ipgChRl_2606 v
														ON v.ipgcrvIpg = pn.ipgpIpg AND v.ipgcrvChain = @ipgChKey
													INNER JOIN ags.ipgUtPlGrP gp
														ON gp.iuplgpPl = up.iuplpPl AND gp.iuplgpGr = v.ipgcrvUtPlGr
													INNER JOIN ags.ipgUtPlPnLmMn mn
														ON mn.iuplpmPlPn = up.iuplpKey AND mn.iuplpmStCost = 212
												GROUP BY pn.ipgpKey
												) gup on gup.ipgcrChain = @ipgChKey and gu.ipgpKey = gup.iuplpIpgPn
								) as z 
							--where not z.ia_inProcessTtlAccum is null
							--where --not z.ag_lim is null and 
							--	not z.uk_lim is null --z.cstAgPnCode = '051-2002975'
							--and isnull(z.ag_PlAccum, 0) - isnull(z.ag_acceptedTtlAccum, 0) < 0
						) as u
					GROUP BY GROUPING SETS
						 (
							(u.dateRslt) -- уровень всего
							, (u.ogNm, u.dateRslt) -- уровень агент (заказчик)
							, (u.ogNm, u.branch, u.dateRslt) -- уровень филиал агента
							, 
								( -- ну и здесь всё остальное
									u.ogNm, u.branch, u.cstAgPnCode, u.dateRslt
									, u.cstapKey
									, u.yKey, u.yyyy, u.mKey, u.mNum, u.mCs, u.mNm, u.mQ, u.mHy
									, u.cstaInvestor, u.ogaKey, u.cstAgPnCode, u.ipgKey, u.ipgCount
									, u.ag_ipgpKey, u.ag_iShKey
									--, ag_percentDev, u.ag_percentDevInProcess -- 27.09.2024
									, u.iv_ipgpKey, u.iv_iShKey, u.ia_iShKey
									--, ia_percentDev, u.ia_percentDevInProcess -- 02.10.2024
									, u.uk_ipgpKey, u.uk_iShKey
									--, uk_percentDev, u.uk_percentDevInProcess -- 03.10.2024
									, u.np_iShKey
									--, np_percentDev
									-- , u.np_percentDevInProcess -- 03.10.2024 ой ой слишком много группировок, можно только 32 штуки
								) -- ну и здесь всё остальное. Окончание
						)
					-- группируем результаты по каждой стройке до уровня всего, заказчик. Окончание :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
				) as w
			-- рассчитываем % освоения лимитов и исполнения помесячных планов и присоединяем к результатам уровней всего, заказчик, филиал, стройка. Окончание ##########
			) as v
				left join ags.og o on v.branch = o.ogKey
		--where v.ag_percentDev = v.ag_LimPercent
		order by v.ogNm, v.branch, v.cstAgPnCode, v.dateRslt -- потом убрать 20.09.2024 ...

	-- область вычислений. Окончание ************************************************************************************************************************************
	-- ******************************************************************************************************************************************************************

	RETURN 
END
GO

PRINT N'=== 05c: fnIpgChRsltCstUtlPercentBrn_2606 patched (plan from LmMn @212) ===';
GO
