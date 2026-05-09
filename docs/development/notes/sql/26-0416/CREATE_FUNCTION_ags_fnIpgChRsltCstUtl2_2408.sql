USE [FishEye]
GO

/****** Object:  UserDefinedFunction [ags].[fnIpgChRsltCstUtl2_2408]    Script Date: 16.04.2026 12:21:04 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		ANB
-- Create date: 08.06.2021
-- Description:	результаты по стройкам (разные схемы - каждая в своей строке), подготовленные для свертывания 
-- =============================================
CREATE FUNCTION [ags].[fnIpgChRsltCstUtl2_2408] 
(	
	@ipgChKey int -- цепь инвестиционных программ
)
RETURNS TABLE 
AS
RETURN 
(
	-- Доработана, чтобы распределяла *представленное* на *принято*, *возвращено*, *в работе* и *не поступало* 08.08.2024

	select
	yKey, yyyy, mKey, mNum, mCs, mNm, mQ, mHy, ipgKey, ipgNm, ipgStr, ipgEnd, cstaInvestor, ogaKey, ogNm, isnull(branch, 0) as branch, typeGr
	, iif ( ipgKey is null,
			iif ( typeGr = '2. ОА, прочие и Изм',
					'4. Прочие',
					iif (typeGr = '1. ОА и Изм.', '2.2. Агентская, неплан', null)
				),
			iif ( iShKey is null,
					'2.2. Агентская, неплан',
					iif ( iShKey = 2,
							iif (lim is null, '1.2. Инв. (Аг., неплан)', '2. Агентская, план'),
							iif (iShKey = 1, '1. Инвестиционная', '3. Неизвестная схема')
						)
				)
		) as typeGrTtl
	, lim, iShKey, iShNm, limPlan, cstAgPnCode, cstAgPnKey
	-- отчёты агентов
	, presentedAll, presentedAllAccum, presentedAllModul, presentedAllModulAccum
	, presented, presentedAccum, accepted, acceptedAccum, returned, returnedAccum
	, inProcess, inProcessAccum, notArrived, notArrivedAccum
	, presentedPrevYears, presentedPrevYearsAccum, acceptedPrevYears, acceptedPrevYearsAccum
	, returnedPrevYears, returnedPrevYearsAccum, inProcessPrevYears, inProcessPrevYearsAccum
	, notArrivedPrevYears, notArrivedPrevYearsAccum
	-- агентское вознаграждение
	, agFeePresented, agFeePresentedAccum, agFeeAccepted, agFeeAcceptedAccum, agFeeReturned, agFeeReturnedAccum
	, agFeeInProcess, agFeeInProcessAccum, agFeeNotArrived, agFeeNotArrivedAccum
	-- земельные участки
	, presentedRalp, presentedRalpAccum, acceptedRalp, acceptedRalpAccum, returnedRalp, returnedRalpAccum
	, inProcessRalp, inProcessRalpAccum, notArrivedRalp, notArrivedRalpAccum
	-- хранение
	, storageSum, storageSumAccum
	-- стройконтроль
	, cctSum, cctSumAccum
	-- общедоступные полезные ископаемые
	, MnrlSum, MnrlSumAccum

	-- всего представлено за месяц из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
	-- Ну и ещё суммы хранения, строительного контроля и ОПИ, которые не делятся на представленные и принятые
	, iif 
		(
			asd.presented is null and asd.agFeePresented is null and asd.presentedRalp is null 
				and asd.storageSum is null and asd.cctSum is null and asd.MnrlSum is null,
			null,
			isnull(asd.presented, 0) + isnull(asd.agFeePresented, 0) + isnull(asd.presentedRalp, 0) 
				+ isnull(asd.storageSum, 0) + isnull(asd.cctSum, 0) + isnull(asd.MnrlSum, 0) 
		) as presentedTtl
	-- всего представлено нарастающим итогом с начала года из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
	-- Ну и ещё суммы хранения, строительного контроля и ОПИ, которые не делятся на представленные и принятые
	, iif
		(
			asd.presentedAccum is null and asd.agFeePresentedAccum is null and asd.presentedRalpAccum is null 
				and asd.storageSumAccum is null and asd.cctSumAccum is null and asd.MnrlSumAccum is null,
			null,
			isnull(asd.presentedAccum, 0) + isnull(asd.agFeePresentedAccum, 0) + isnull(asd.presentedRalpAccum, 0) 
				+ isnull(asd.storageSumAccum, 0) + isnull(asd.cctSumAccum, 0) + isnull(asd.MnrlSumAccum, 0) 
		) as presentedTtlAccum

	-- Но как же распределилось представленное? :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	-- принято с учётом находящегося *на рассмотрении* ..............................................................................................
	-- всего принято с учётом находящегося *на рассмотрении* за месяц из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
	-- Ну и ещё суммы хранения, строительного контроля и ОПИ, которые не делятся на представленные и принятые
	, iif
		(
			asd.accepted is null and asd.agFeeAccepted is null and asd.acceptedRalp is null 
				and asd.storageSum is null and asd.cctSum is null and asd.MnrlSum is null
				and asd.inProcess is null and asd.agFeeInProcess is null and asd.inProcessRalp is null,
			null,
			isnull(asd.accepted, 0) + isnull(asd.agFeeAccepted, 0) + isnull(asd.acceptedRalp, 0) 
				+ isnull(asd.storageSum, 0) + isnull(asd.cctSum, 0) + isnull(asd.MnrlSum, 0)
				+ isnull(asd.inProcess, 0) + isnull(asd.agFeeInProcess, 0) + isnull(asd.inProcessRalp, 0) 
		) as acceptedAndInProcessTtl
	-- всего принято с учётом находящегося *на рассмотрении* нарастающим итогом с начала года из разных истчников. 
	-- Это ОА, агентское вознаграждение, земельные участки.
	-- Ну и ещё суммы хранения, строительного контроля и ОПИ, которые не делятся на представленные и принятые
	, iif
		(
			asd.acceptedAccum is null and asd.agFeeAcceptedAccum is null and asd.acceptedRalpAccum is null 
				and asd.storageSumAccum is null and asd.cctSumAccum is null and asd.MnrlSumAccum is null
				and asd.inProcessAccum is null and asd.agFeeInProcessAccum is null and asd.inProcessRalpAccum is null,
			null,
			isnull(asd.acceptedAccum, 0) + isnull(asd.agFeeAcceptedAccum, 0) + isnull(asd.acceptedRalpAccum, 0) 
				+ isnull(asd.storageSumAccum, 0) + isnull(asd.cctSumAccum, 0) + isnull(asd.MnrlSumAccum, 0)
				+ isnull(asd.inProcessAccum, 0) + isnull(asd.agFeeInProcessAccum, 0) + isnull(asd.inProcessRalpAccum, 0)
		) as acceptedAndInProcessTtlAccum
	-- принято с учётом находящегося *на рассмотрении*. Окончание ...................................................................................

	-- принято ......................................................................................................................................
	-- всего принято за месяц из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
	-- Ну и ещё суммы хранения, строительного контроля и ОПИ, которые не делятся на представленные и принятые
	, iif
		(
			asd.accepted is null and asd.agFeeAccepted is null and asd.acceptedRalp is null 
				and asd.storageSum is null and asd.cctSum is null and asd.MnrlSum is null,
			null,
			isnull(asd.accepted, 0) + isnull(asd.agFeeAccepted, 0) + isnull(asd.acceptedRalp, 0) 
				+ isnull(asd.storageSum, 0) + isnull(asd.cctSum, 0) + isnull(asd.MnrlSum, 0) 
		) as acceptedTtl
	-- всего принято нарастающим итогом с начала года из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
	-- Ну и ещё суммы хранения, строительного контроля и ОПИ, которые не делятся на представленные и принятые
	, iif
		(
			asd.acceptedAccum is null and asd.agFeeAcceptedAccum is null and asd.acceptedRalpAccum is null 
				and asd.storageSumAccum is null and asd.cctSumAccum is null and asd.MnrlSumAccum is null,
			null,
			isnull(asd.acceptedAccum, 0) + isnull(asd.agFeeAcceptedAccum, 0) + isnull(asd.acceptedRalpAccum, 0) 
				+ isnull(asd.storageSumAccum, 0) + isnull(asd.cctSumAccum, 0) + isnull(asd.MnrlSumAccum, 0) 
		) as acceptedTtlAccum
	-- принято. Окончание ...........................................................................................................................

	-- возвращено ...................................................................................................................................
	-- всего возвращено за месяц из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
	, iif
		(
			asd.returned is null and asd.agFeeReturned is null and asd.returnedRalp is null,
			null,
			isnull(asd.returned, 0) + isnull(asd.agFeeReturned, 0) + isnull(asd.returnedRalp, 0) 
		) as returnedTtl
	-- всего возвращено нарастающим итогом с начала года из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
	, iif
		(
			asd.returnedAccum is null and asd.agFeeReturnedAccum is null and asd.returnedRalpAccum is null,
			null,
			isnull(asd.returnedAccum, 0) + isnull(asd.agFeeReturnedAccum, 0) + isnull(asd.returnedRalpAccum, 0) 
		) as returnedTtlAccum
	-- возвращено. Окончание ........................................................................................................................

	-- на рассмотрении ..............................................................................................................................
	-- всего *рассматривается* за месяц из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
	, iif
		(
			asd.inProcess is null and asd.agFeeInProcess is null and asd.inProcessRalp is null,
			null,
			isnull(asd.inProcess, 0) + isnull(asd.agFeeInProcess, 0) + isnull(asd.inProcessRalp, 0) 
		) as inProcessTtl
	-- всего *рассматривается* нарастающим итогом с начала года из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
	, iif
		(
			asd.inProcessAccum is null and asd.agFeeInProcessAccum is null and asd.inProcessRalpAccum is null,
			null,
			isnull(asd.inProcessAccum, 0) + isnull(asd.agFeeInProcessAccum, 0) + isnull(asd.inProcessRalpAccum, 0) 
		) as inProcessTtlAccum
	-- на рассмотрении. Окончание ...................................................................................................................

	-- не поступало .................................................................................................................................
	-- всего *не поступало* за месяц из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
	, iif
		(
			asd.notArrived is null and asd.agFeeNotArrived is null and asd.notArrivedRalp is null,
			null,
			isnull(asd.notArrived, 0) + isnull(asd.agFeeNotArrived, 0) + isnull(asd.notArrivedRalp, 0) 
		) as notArrivedTtl
	-- всего *не поступало* нарастающим итогом с начала года из разных истчников. Это ОА, агентское вознаграждение, земельные участки.
	, iif
		(
			asd.notArrivedAccum is null and asd.agFeeNotArrivedAccum is null and asd.notArrivedRalpAccum is null,
			null,
			isnull(asd.notArrivedAccum, 0) + isnull(asd.agFeeNotArrivedAccum, 0) + isnull(asd.notArrivedRalpAccum, 0) 
		) as notArrivedTtlAccum
	-- не поступало. Окончание ......................................................................................................................

	-- Но как же распределилось представленное? Окончание :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	-- остаток лимита
	, iif (lim is not null and lim > 0 and iShKey = 2,
			lim - (isnull(asd.acceptedAccum, 0) + isnull(asd.agFeeAcceptedAccum, 0) + isnull(asd.acceptedRalpAccum, 0) 
					+ isnull(asd.storageSumAccum, 0) + isnull(asd.cctSumAccum, 0) + isnull(asd.MnrlSumAccum, 0)),
			null
		) as restOfLimit
	-- остаток лимита с учётом находящегося *на рассмотрении*
	, iif (lim is not null and lim > 0 and iShKey = 2,
			lim - (isnull(asd.acceptedAccum, 0) + isnull(asd.agFeeAcceptedAccum, 0) + isnull(asd.acceptedRalpAccum, 0) 
					+ isnull(asd.storageSumAccum, 0) + isnull(asd.cctSumAccum, 0) + isnull(asd.MnrlSumAccum, 0)
					+ isnull(asd.inProcessAccum, 0) + isnull(asd.agFeeInProcessAccum, 0) + isnull(asd.inProcessRalpAccum, 0)
					),
			null
		) as restOfLimitInProcess
	-- процент освоения лимита в целом
	, iif (lim is not null and lim > 0 and iShKey = 2,
			(isnull(asd.acceptedAccum, 0) + isnull(asd.agFeeAcceptedAccum, 0) + isnull(asd.acceptedRalpAccum, 0) 
					+ isnull(asd.storageSumAccum, 0) + isnull(asd.cctSumAccum, 0) + isnull(asd.MnrlSumAccum, 0))/lim * 100,
			null
		) as percentDev
	-- процент освоения лимита в целом с учётом находящегося *на рассмотрении*
	, iif (lim is not null and lim > 0 and iShKey = 2,
			(isnull(asd.acceptedAccum, 0) + isnull(asd.agFeeAcceptedAccum, 0) + isnull(asd.acceptedRalpAccum, 0) 
				+ isnull(asd.storageSumAccum, 0) + isnull(asd.cctSumAccum, 0) + isnull(asd.MnrlSumAccum, 0)
				+ isnull(asd.inProcessAccum, 0) + isnull(asd.agFeeInProcessAccum, 0) + isnull(asd.inProcessRalpAccum, 0)
				)/lim * 100,
			null
		) as percentDevInProcess
from
	(
		select
			yKey, yyyy, mKey, mNum, mCs, mNm, mQ, mHy, ipgKey, ipgNm, ipgStr, ipgEnd, cstaInvestor, ogaKey, ogNm, branch, typeGr
			, sum(lim) as lim
			, iShKey, iShNm, limPlan, cstAgPnCode, cstAgPnKey
			, sum(presentedAll) as presentedAll, sum(presentedAllAccum) as presentedAllAccum, sum(presentedAllModul) as presentedAllModul, sum(presentedAllModulAccum) as presentedAllModulAccum
			, sum(presented) as presented, sum(presentedAccum) as presentedAccum, sum(accepted) as accepted, sum(acceptedAccum) as acceptedAccum
			, sum(returned) as returned, sum(returnedAccum) as returnedAccum
			, sum(inProcess) as inProcess, sum(inProcessAccum) as inProcessAccum, sum(notArrived) as notArrived, sum(notArrivedAccum) as notArrivedAccum
			, sum(presentedPrevYears) as presentedPrevYears, sum(presentedPrevYearsAccum) as presentedPrevYearsAccum, sum(acceptedPrevYears) as acceptedPrevYears
			, sum(acceptedPrevYearsAccum) as acceptedPrevYearsAccum
			, sum(returnedPrevYears) as returnedPrevYears, sum(returnedPrevYearsAccum) as returnedPrevYearsAccum, sum(inProcessPrevYears) as inProcessPrevYears
			, sum(inProcessPrevYearsAccum) as inProcessPrevYearsAccum
			, sum(notArrivedPrevYears) as notArrivedPrevYears, sum(notArrivedPrevYearsAccum) as notArrivedPrevYearsAccum
			, sum(agFeePresented) as agFeePresented, sum(agFeePresentedAccum) as agFeePresentedAccum, sum(agFeeAccepted) as agFeeAccepted, sum(agFeeAcceptedAccum) as agFeeAcceptedAccum
			, sum(agFeeReturned) as agFeeReturned, sum(agFeeReturnedAccum) as agFeeReturnedAccum
			, sum(agFeeInProcess) as agFeeInProcess, sum(agFeeInProcessAccum) as agFeeInProcessAccum, sum(agFeeNotArrived) as agFeeNotArrived, sum(agFeeNotArrivedAccum) as agFeeNotArrivedAccum
			, sum(presentedRalp) as presentedRalp, sum(presentedRalpAccum) as presentedRalpAccum, sum(acceptedRalp) as acceptedRalp, sum(acceptedRalpAccum) as acceptedRalpAccum
			, sum(returnedRalp) as returnedRalp, sum(returnedRalpAccum) as returnedRalpAccum
			, sum(inProcessRalp) as inProcessRalp, sum(inProcessRalpAccum) as inProcessRalpAccum, sum(notArrivedRalp) as notArrivedRalp, sum(notArrivedRalpAccum) as notArrivedRalpAccum
			, sum(storageSum) as storageSum, sum(storageSumAccum) as storageSumAccum
			, sum(cctSum) as cctSum, sum(cctSumAccum) as cctSumAccum
			, sum(MnrlSum) as MnrlSum, sum(MnrlSumAccum) as MnrlSumAccum
 

		from
			-- ================================================================================== получаем освоение по стройкам для года
			(
				select *
				from ags.fnIpgChRsltCstUtl_2408(@ipgChKey) r
				where
					not (
							r.lim is null
								and r.presentedAll is null and r.presentedAllAccum is null and r.presentedAllModul is null and r.presentedAllModulAccum is null 
								and r.presented is null and r.presentedAccum is null and r.accepted is null and r.acceptedAccum is null and r.returned is null and r.returnedAccum is null 
								and r.inProcess is null and r.inProcessAccum is null and r.notArrived is null and r.notArrivedAccum is null 
								and r.presentedPrevYears is null and r.presentedPrevYearsAccum is null and r.acceptedPrevYears is null and r.acceptedPrevYearsAccum is null 
								and r.returnedPrevYears is null and r.returnedPrevYearsAccum is null and r.inProcessPrevYears is null and r.inProcessPrevYearsAccum is null 
								and r.notArrivedPrevYears is null and r.notArrivedPrevYearsAccum is null 
								and r.agFeePresented is null and r.agFeePresentedAccum is null and r.agFeeAccepted is null and r.agFeeAcceptedAccum is null 
								and r.agFeeReturned is null and r.agFeeReturnedAccum is null 
								and r.agFeeInProcess is null and r.agFeeInProcessAccum is null and r.agFeeNotArrived is null and r.agFeeNotArrivedAccum is null 
								and r.presentedRalp is null and r.presentedRalpAccum is null and r.acceptedRalp is null and r.acceptedRalpAccum is null 
								and r.returnedRalp is null and r.returnedRalpAccum is null 
								and r.inProcessRalp is null and r.inProcessRalpAccum is null and r.notArrivedRalp is null and r.notArrivedRalpAccum is null 
								and r.storageSum is null and r.storageSumAccum is null 
								and r.cctSum is null and r.cctSumAccum is null 
								and r.MnrlSum is null and r.MnrlSumAccum is null 
						)
					and
						(
							r.ipgKey is null
							or
								(
									r.mNum >= 
											iif (r.ipgStr is null, 
													1, 
													iif (year(r.ipgStr) <> r.yyyy, 1, MONTH(r.ipgStr)) -- если год отличается от текущего берем январь
												) 
									and 
									r.mNum <= 
										iif (r.ipgEnd is null, 
												12, 
												iif (year(r.ipgEnd) <> r.yyyy, 12, MONTH(r.ipgEnd)) -- если год отличается от текущего берем декабрь
											)
								)
						)
			) t
			-- ================================================================================== здесь получили освоение по стройкам для года
		group by yKey, yyyy, mKey, mNum, mCs, mNm, mQ, mHy, ipgKey, ipgNm, ipgStr, ipgEnd, cstaInvestor, ogaKey, ogNm, branch, typeGr
			, iShKey, iShNm, limPlan, cstAgPnCode, cstAgPnKey
	) asd
)
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'результаты по стройкам (разные схемы - каждая в своей строке), подготовленные для свртывания' , @level0type=N'SCHEMA',@level0name=N'ags', @level1type=N'FUNCTION',@level1name=N'fnIpgChRsltCstUtl2_2408'
GO


