USE [FishEye]
GO

/****** Object:  UserDefinedFunction [ags].[fnIpgChRsltCstUtlPercentBrn]    Script Date: 16.04.2026 12:17:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		bondale1
-- Create date: 27.09.2022
-- Description:	Получаем освоение лимитов по каждой *Стройке* для *Цепи инвестпрограмм*
-- =============================================
CREATE FUNCTION [ags].[fnIpgChRsltCstUtlPercentBrn] 
(
	-- Параметры
	@ipgChKey int -- цепочка инвестпрограмм
)
RETURNS 
@TableRslt TABLE 
(
		ogNm nvarchar(255), branch int, branchName nvarchar(255), cstAgPnCode nvarchar(255), dateRslt date, ipgChKey int, cstapKey int
		, yKey int, yyyy int, mKey int, mNum int, mCs nvarchar(255), mNm nvarchar(255), mQ nvarchar(255), mHy int
		, cstaInvestor int, ogaKey int, ipgKey int, ipgCount int
		-- по агентской схеме
		, ag_ipgpKey int, ag_ipgpSmTtl money, ag_PlAccum money, ag_Pl money
		, ag_PlFulfillment money, ag_PlNonFulfillment money, ag_PlOverFulfillment money, ag_PlRestLimit money, ag_PlOverLimit money
		, ag_LimPercent float, ag_PlPercent float
		, ag_lim money, ag_iShKey int
		, ag_presented money, ag_presentedAccum money, ag_accepted money, ag_acceptedAccum money
		, ag_agFeePresented money, ag_agFeePresentedAccum money, ag_agFeeAccepted money, ag_agFeeAcceptedAccum money
		, ag_presentedRalp money, ag_presentedRalpAccum money, ag_acceptedRalp money, ag_acceptedRalpAccum money
		, ag_storageSum money, ag_storageSumAccum money, ag_cctSum money, ag_cctSumAccum money, ag_MnrlSum money, ag_MnrlSumAccum money
		, ag_presentedTtl money, ag_presentedTtlAccum money, ag_acceptedTtl money, ag_acceptedTtlAccum money, ag_restOfLimit money, ag_percentDev float
		-- по инвестиционной схеме
		, iv_ipgpKey int, iv_ipgpSmTtl money, iv_PlAccum money, iv_Pl money
		, iv_PlFulfillment money, iv_PlNonFulfillment money, iv_PlOverFulfillment money, iv_PlRestLimit money, iv_PlOverLimit money
		, iv_LimPercent float, iv_PlPercent float
		, iv_lim money, iv_iShKey int
		, ia_lim money, ia_iShKey int
		, ia_presented money, ia_presentedAccum money, ia_accepted money, ia_acceptedAccum money
		, ia_agFeePresented money, ia_agFeePresentedAccum money, ia_agFeeAccepted money, ia_agFeeAcceptedAccum money
		, ia_presentedRalp money, ia_presentedRalpAccum money, ia_acceptedRalp money, ia_acceptedRalpAccum money
		, ia_storageSum money, ia_storageSumAccum money, ia_cctSum money, ia_cctSumAccum money, ia_MnrlSum money, ia_MnrlSumAccum money
		, ia_presentedTtl money, ia_presentedTtlAccum money, ia_acceptedTtl money, ia_acceptedTtlAccum money, ia_restOfLimit money, ia_percentDev float
		, uk_lim money, uk_iShKey int
		-- по неизвестной схеме
		, uk_ipgpKey int, uk_ipgpSmTtl money, uk_PlAccum money, uk_Pl money
		, uk_PlFulfillment money, uk_PlNonFulfillment money, uk_PlOverFulfillment money, uk_PlRestLimit money, uk_PlOverLimit money
		, uk_LimPercent float, uk_PlPercent float
		, uk_presented money, uk_presentedAccum money, uk_accepted money, uk_acceptedAccum money
		, uk_agFeePresented money, uk_agFeePresentedAccum money, uk_agFeeAccepted money, uk_agFeeAcceptedAccum money
		, uk_presentedRalp money, uk_presentedRalpAccum money, uk_acceptedRalp money, uk_acceptedRalpAccum money
		, uk_storageSum money, uk_storageSumAccum money, uk_cctSum money, uk_cctSumAccum money, uk_MnrlSum money, uk_MnrlSumAccum money
		, uk_presentedTtl money, uk_presentedTtlAccum money, uk_acceptedTtl money, uk_acceptedTtlAccum money, uk_restOfLimit money, uk_percentDev float
		-- неплан
		, np_lim money, np_iShKey int
		, np_presented money, np_presentedAccum money, np_accepted money, np_acceptedAccum money
		, np_agFeePresented money, np_agFeePresentedAccum money, np_agFeeAccepted money, np_agFeeAcceptedAccum money
		, np_presentedRalp money, np_presentedRalpAccum money, np_acceptedRalp money, np_acceptedRalpAccum money
		, np_storageSum money, np_storageSumAccum money, np_cctSum money, np_cctSumAccum money, np_MnrlSum money, np_MnrlSumAccum money
		, np_presentedTtl money, np_presentedTtlAccum money, np_acceptedTtl money, np_acceptedTtlAccum money, np_restOfLimit money, np_percentDev float
		-- прочее
		, oh_presented money, oh_presentedAccum money, oh_accepted money, oh_acceptedAccum money
		-- 14.07.2023 добавил прочие отчёты для агентского вознаграждения
		, oh_agFeePresented money, oh_agFeePresentedAccum money, oh_agFeeAccepted money, oh_agFeeAcceptedAccum money
		, oh_presentedTtl money, oh_presentedTtlAccum money, oh_acceptedTtl money, oh_acceptedTtlAccum money
)
AS
BEGIN
	-- объявляем переменные
	declare @lsYyKey int -- ключ года цепочки инвестпрограмм
	declare @lsYy int -- год цепочки инвестпрограмм

	declare @fnIpgChRsltCstUtl2_ table -- промежуточная табличка
		(
			yKey int, yyyy int, mKey int, mNum int, mCs nvarchar(255), mNm nvarchar(255), mQ nvarchar(255), mHy int
			, ipgKey int, ipgNm nvarchar(255), ipgStr date, ipgEnd date
			, cstaInvestor int, ogaKey int, ogNm nvarchar(255), branch int, typeGr nvarchar(255)
			, typeGrTtl nvarchar(255)
			, lim money, iShKey int, iShNm nvarchar(255), limPlan nvarchar(255), cstAgPnCode nvarchar(20)
			, presented money, presentedAccum money, accepted money, acceptedAccum money
			, agFeePresented money, agFeePresentedAccum money, agFeeAccepted money, agFeeAcceptedAccum money
			, presentedRalp money, presentedRalpAccum money, acceptedRalp money, acceptedRalpAccum money
			, storageSum money, storageSumAccum money, cctSum money, cctSumAccum money, MnrlSum money, MnrlSumAccum money
			, presentedTtl money, presentedTtlAccum money, acceptedTtl money, acceptedTtlAccum money, restOfLimit money, percentDev float
			UNIQUE nonclustered(yKey, mKey, ogaKey, cstAgPnCode, ipgKey, typeGrTtl)
		)

	declare @fnIpgChRsltCstUtl2_g table -- промежуточная табличка для группировки
		(
			yKey int, yyyy int, mKey int, mNum int, mCs nvarchar(255), mNm nvarchar(255), mQ nvarchar(255), mHy int
			, cstaInvestor int, ogaKey int, ogNm nvarchar(255), branch int, cstAgPnCode nvarchar(255), ipgKey int
		)

	declare @spIpgChRsltCstUtl3_oneD table
		(
			yKey int, yyyy int, mKey int, mNum int, mCs nvarchar(255), mNm nvarchar(255), mQ nvarchar(255), mHy int
			, cstaInvestor int, ogaKey int, ogNm nvarchar(255), branch int, cstAgPnCode nvarchar(255), ipgKey int, ipgCount int
			, ag_lim money, ag_iShKey int
			, ag_presented money, ag_presentedAccum money, ag_accepted money, ag_acceptedAccum money
			, ag_agFeePresented money, ag_agFeePresentedAccum money, ag_agFeeAccepted money, ag_agFeeAcceptedAccum money
			, ag_presentedRalp money, ag_presentedRalpAccum money, ag_acceptedRalp money, ag_acceptedRalpAccum money
			, ag_storageSum money, ag_storageSumAccum money, ag_cctSum money, ag_cctSumAccum money, ag_MnrlSum money, ag_MnrlSumAccum money
			, ag_presentedTtl money, ag_presentedTtlAccum money, ag_acceptedTtl money, ag_acceptedTtlAccum money, ag_restOfLimit money, ag_percentDev float
			, iv_lim money, iv_iShKey int
			, ia_lim money, ia_iShKey int
			, ia_presented money, ia_presentedAccum money, ia_accepted money, ia_acceptedAccum money
			, ia_agFeePresented money, ia_agFeePresentedAccum money, ia_agFeeAccepted money, ia_agFeeAcceptedAccum money
			, ia_presentedRalp money, ia_presentedRalpAccum money, ia_acceptedRalp money, ia_acceptedRalpAccum money
			, ia_storageSum money, ia_storageSumAccum money, ia_cctSum money, ia_cctSumAccum money, ia_MnrlSum money, ia_MnrlSumAccum money
			, ia_presentedTtl money, ia_presentedTtlAccum money, ia_acceptedTtl money, ia_acceptedTtlAccum money, ia_restOfLimit money, ia_percentDev float
			, uk_lim money, uk_iShKey int
			, uk_presented money, uk_presentedAccum money, uk_accepted money, uk_acceptedAccum money
			, uk_agFeePresented money, uk_agFeePresentedAccum money, uk_agFeeAccepted money, uk_agFeeAcceptedAccum money
			, uk_presentedRalp money, uk_presentedRalpAccum money, uk_acceptedRalp money, uk_acceptedRalpAccum money
			, uk_storageSum money, uk_storageSumAccum money, uk_cctSum money, uk_cctSumAccum money, uk_MnrlSum money, uk_MnrlSumAccum money
			, uk_presentedTtl money, uk_presentedTtlAccum money, uk_acceptedTtl money, uk_acceptedTtlAccum money, uk_restOfLimit money, uk_percentDev float
			, np_lim money, np_iShKey int
			, np_presented money, np_presentedAccum money, np_accepted money, np_acceptedAccum money
			, np_agFeePresented money, np_agFeePresentedAccum money, np_agFeeAccepted money, np_agFeeAcceptedAccum money
			, np_presentedRalp money, np_presentedRalpAccum money, np_acceptedRalp money, np_acceptedRalpAccum money
			, np_storageSum money, np_storageSumAccum money, np_cctSum money, np_cctSumAccum money, np_MnrlSum money, np_MnrlSumAccum money
			, np_presentedTtl money, np_presentedTtlAccum money, np_acceptedTtl money, np_acceptedTtlAccum money, np_restOfLimit money, np_percentDev float
			, oh_presented money, oh_presentedAccum money, oh_accepted money, oh_acceptedAccum money
			-- 14.07.2023 добавил прочие отчёты для агентского вознаграждения
			, oh_agFeePresented money, oh_agFeePresentedAccum money, oh_agFeeAccepted money, oh_agFeeAcceptedAccum money
			, oh_presentedTtl money, oh_presentedTtlAccum money, oh_acceptedTtl money, oh_acceptedTtlAccum money
		)

	declare @dt table
		(
			dateRslt date
			, ipgKey int
		)

	-- собственно вычисления

    -- Определяем ключ года для цепи инвестпрограмм
	set @lsYyKey = 
		(
			select min(y.yKey) lastYyKey
			from
				(
					select max(y.yyyy) mxY
					from ags.ipgChRl c
						join ags.ipg i on c.ipgcrIpg = i.ipgKey
							join ags.yyyy y on i.ipgYy = y.yKey
					where c.ipgcrChain = @ipgChKey
				) x
					join ags.yyyy y on x.mxY = y.yyyy
		);

	-- Определяем год для цепи инвестпрограмм
		set @lsYy = 
			(
			select
				min(y.yyyy) lastYy
			from
				(
					select
						max(y.yyyy) mxY
					from
						ags.ipgChRl c
						join
							ags.ipg i
							on c.ipgcrIpg = i.ipgKey
							join
								ags.yyyy y
								on i.ipgYy = y.yKey
					where
						c.ipgcrChain = @ipgChKey
				) x
				join
					ags.yyyy y
					on x.mxY = y.yyyy
			);

	-- получаем освоение для разных схем реализации инвестпрограмм
	with yYy as
		(
			SELECT * FROM [ags].[fnIpgChRsltCstUtl2] (@ipgChKey, @lsYyKey)
		)

		insert into @fnIpgChRsltCstUtl2_
			(
				yKey, yyyy, mKey, mNum, mCs, mNm, mQ, mHy
				, ipgKey, ipgNm, ipgStr, ipgEnd
				, cstaInvestor, ogaKey, ogNm, branch, typeGr
				, typeGrTtl
				, lim, iShKey, iShNm, limPlan, cstAgPnCode
				, presented, presentedAccum, accepted, acceptedAccum
				, agFeePresented, agFeePresentedAccum, agFeeAccepted, agFeeAcceptedAccum
				, presentedRalp, presentedRalpAccum, acceptedRalp, acceptedRalpAccum
				, storageSum, storageSumAccum, cctSum, cctSumAccum, MnrlSum, MnrlSumAccum
				, presentedTtl, presentedTtlAccum, acceptedTtl, acceptedTtlAccum, restOfLimit, percentDev
			)
		select
				yKey, yyyy, mKey, mNum, mCs, mNm, mQ, mHy
				, ipgKey, ipgNm, ipgStr, ipgEnd
				, cstaInvestor, ogaKey, ogNm, branch, typeGr
				, typeGrTtl
				, lim, iShKey, iShNm, limPlan, cstAgPnCode
				, presented, presentedAccum, accepted, acceptedAccum
				, agFeePresented, agFeePresentedAccum, agFeeAccepted, agFeeAcceptedAccum
				, presentedRalp, presentedRalpAccum, acceptedRalp, acceptedRalpAccum
				, storageSum, storageSumAccum, cctSum, cctSumAccum, MnrlSum, MnrlSumAccum
				, presentedTtl, presentedTtlAccum, acceptedTtl, acceptedTtlAccum, restOfLimit, percentDev
		from
			yYy t

	-- заполняем промежуточную табличку для группировки
	insert @fnIpgChRsltCstUtl2_g
	select
		yKey, yyyy, mKey, mNum, mCs, mNm, mQ, mHy, cstaInvestor, ogaKey, ogNm, branch, cstAgPnCode, ipgKey
	from
		@fnIpgChRsltCstUtl2_
	group by
		yKey, yyyy, mKey, mNum, mCs, mNm, mQ, mHy, cstaInvestor, ogaKey, ogNm, branch, cstAgPnCode, ipgKey

	-- заполняем табличку
	insert
		@spIpgChRsltCstUtl3_oneD
	select
		x.*
		, ag.lim ag_lim, ag.iShKey ag_iShKey
		, ag.presented ag_presented, ag.presentedAccum ag_presentedAccum, ag.accepted ag_accepted, ag.acceptedAccum ag_acceptedAccum
		, ag.agFeePresented ag_agFeePresented, ag.agFeePresentedAccum ag_agFeePresentedAccum, ag.agFeeAccepted ag_agFeeAccepted, ag.agFeeAcceptedAccum ag_agFeeAcceptedAccum
		, ag.presentedRalp ag_presentedRalp, ag.presentedRalpAccum ag_presentedRalpAccum, ag.acceptedRalp ag_acceptedRalp, ag.acceptedRalpAccum ag_acceptedRalpAccum
		, ag.storageSum ag_storageSum, ag.storageSumAccum ag_storageSumAccum, ag.cctSum ag_cctSum, ag.cctSumAccum ag_cctSumAccum, ag.MnrlSum ag_MnrlSum, ag.MnrlSumAccum ag_MnrlSumAccum
		, ag.presentedTtl ag_presentedTtl, ag.presentedTtlAccum ag_presentedTtlAccum, ag.acceptedTtl ag_acceptedTtl, ag.acceptedTtlAccum ag_acceptedTtlAccum, ag.restOfLimit ag_restOfLimit, ag.percentDev ag_percentDev
		, iv.lim iv_lim, iv.iShKey iv_iShKey
		, ia.lim ia_lim, ia.iShKey ia_iShKey
		, ia.presented ia_presented, ia.presentedAccum ia_presentedAccum, ia.accepted ia_accepted, ia.acceptedAccum ia_acceptedAccum
		, ia.agFeePresented ia_agFeePresented, ia.agFeePresentedAccum ia_agFeePresentedAccum, ia.agFeeAccepted ia_agFeeAccepted, ia.agFeeAcceptedAccum ia_agFeeAcceptedAccum
		, ia.presentedRalp ia_presentedRalp, ia.presentedRalpAccum ia_presentedRalpAccum, ia.acceptedRalp ia_acceptedRalp, ia.acceptedRalpAccum ia_acceptedRalpAccum
		, ia.storageSum ia_storageSum, ia.storageSumAccum ia_storageSumAccum, ia.cctSum ia_cctSum, ia.cctSumAccum ia_cctSumAccum, ia.MnrlSum ia_MnrlSum, ia.MnrlSumAccum ia_MnrlSumAccum
		, ia.presentedTtl ia_presentedTtl, ia.presentedTtlAccum ia_presentedTtlAccum, ia.acceptedTtl ia_acceptedTtl, ia.acceptedTtlAccum ia_acceptedTtlAccum, ia.restOfLimit ia_restOfLimit, ia.percentDev ia_percentDev
		, uk.lim uk_lim, uk.iShKey uk_iShKey
		, uk.presented uk_presented, uk.presentedAccum uk_presentedAccum, uk.accepted uk_accepted, uk.acceptedAccum uk_acceptedAccum
		, uk.agFeePresented uk_agFeePresented, uk.agFeePresentedAccum uk_agFeePresentedAccum, uk.agFeeAccepted uk_agFeeAccepted, uk.agFeeAcceptedAccum uk_agFeeAcceptedAccum
		, uk.presentedRalp uk_presentedRalp, uk.presentedRalpAccum uk_presentedRalpAccum, uk.acceptedRalp uk_acceptedRalp, uk.acceptedRalpAccum uk_acceptedRalpAccum
		, uk.storageSum uk_storageSum, uk.storageSumAccum uk_storageSumAccum, uk.cctSum uk_cctSum, uk.cctSumAccum uk_cctSumAccum, uk.MnrlSum uk_MnrlSum, uk.MnrlSumAccum uk_MnrlSumAccum
		, uk.presentedTtl uk_presentedTtl, uk.presentedTtlAccum uk_presentedTtlAccum, uk.acceptedTtl uk_acceptedTtl, uk.acceptedTtlAccum uk_acceptedTtlAccum, uk.restOfLimit uk_restOfLimit, uk.percentDev uk_percentDev
		, np.lim np_lim, np.iShKey np_iShKey
		, np.presented np_presented, np.presentedAccum np_presentedAccum, np.accepted np_accepted, np.acceptedAccum np_acceptedAccum
		, np.agFeePresented np_agFeePresented, np.agFeePresentedAccum np_agFeePresentedAccum, np.agFeeAccepted np_agFeeAccepted, np.agFeeAcceptedAccum np_agFeeAcceptedAccum
		, np.presentedRalp np_presentedRalp, np.presentedRalpAccum np_presentedRalpAccum, np.acceptedRalp np_acceptedRalp, np.acceptedRalpAccum np_acceptedRalpAccum
		, np.storageSum np_storageSum, np.storageSumAccum np_storageSumAccum, np.cctSum np_cctSum, np.cctSumAccum np_cctSumAccum, np.MnrlSum np_MnrlSum, np.MnrlSumAccum np_MnrlSumAccum
		, np.presentedTtl np_presentedTtl, np.presentedTtlAccum np_presentedTtlAccum, np.acceptedTtl np_acceptedTtl, np.acceptedTtlAccum np_acceptedTtlAccum, np.restOfLimit np_restOfLimit, np.percentDev np_percentDev
		, oh.presented oh_presented, oh.presentedAccum oh_presentedAccum, oh.accepted oh_accepted, oh.acceptedAccum oh_acceptedAccum
		-- 14.07.2023 добавил прочие отчёты для агентского вознаграждения
		, oh.agFeePresented oh_agFeePresented, oh.agFeePresentedAccum oh_agFeePresentedAccum, oh.agFeeAccepted oh_agFeeAccepted, oh.agFeeAcceptedAccum oh_agFeeAcceptedAccum
		, oh.presentedTtl oh_presentedTtl, oh.presentedTtlAccum oh_presentedTtlAccum, oh.acceptedTtl oh_acceptedTtl, oh.acceptedTtlAccum oh_acceptedTtlAccum
	from
		(
			select
				xx.*, ipgCount
			from
				@fnIpgChRsltCstUtl2_g xx
				left join
					(
						select
							yKey, mKey, ogaKey, cstAgPnCode, count(ipgKey) ipgCount
						from
							@fnIpgChRsltCstUtl2_g 
						group by
							yKey, mKey, ogaKey, cstAgPnCode
					) ic
					on xx.yKey = ic.yKey and xx.mKey = ic.mKey and xx.ogaKey = ic.ogaKey and xx.cstAgPnCode = ic.cstAgPnCode
			where
				not (xx.ipgKey is null and ic.ipgCount > 0)
		) x
		left join
			@fnIpgChRsltCstUtl2_ ag
			on x.yKey = ag.yKey and x.mKey = ag.mKey and x.ogaKey = ag.ogaKey and x.cstAgPnCode = ag.cstAgPnCode and x.ipgKey = ag.ipgKey and ag.typeGrTtl = '2. Агентская, план'
		left join
			@fnIpgChRsltCstUtl2_ iv
			on x.yKey = iv.yKey and x.mKey = iv.mKey and x.ogaKey = iv.ogaKey and x.cstAgPnCode = iv.cstAgPnCode and x.ipgKey = iv.ipgKey and iv.typeGrTtl = '1. Инвестиционная'
		left join
			@fnIpgChRsltCstUtl2_ ia
			on x.yKey = ia.yKey and x.mKey = ia.mKey and x.ogaKey = ia.ogaKey and x.cstAgPnCode = ia.cstAgPnCode and x.ipgKey = ia.ipgKey and ia.typeGrTtl = '1.2. Инв. (Аг., неплан)'
		left join
			@fnIpgChRsltCstUtl2_ uk
			on x.yKey = uk.yKey and x.mKey = uk.mKey and x.ogaKey = uk.ogaKey and x.cstAgPnCode = uk.cstAgPnCode and x.ipgKey = uk.ipgKey and uk.typeGrTtl = '3. Неизвестная схема'
		left join
			@fnIpgChRsltCstUtl2_ np
			on x.yKey = np.yKey and x.mKey = np.mKey and x.ogaKey = np.ogaKey and x.cstAgPnCode = np.cstAgPnCode and x.ipgKey = np.ipgKey and np.typeGrTtl = '2.2. Агентская, неплан'
		left join
			@fnIpgChRsltCstUtl2_ oh
			on x.yKey = oh.yKey and x.mKey = oh.mKey and x.ogaKey = oh.ogaKey and x.cstAgPnCode = oh.cstAgPnCode and oh.typeGrTtl = '4. Прочие'

	insert @dt
	select x.dateRslt, x.ipgKey
	from
		(
			select
				iif
				(
					-- дата начала ИПг входит в текущий месяц?
					month(datefromparts(s.yyyy, s.mNum, 1)) = month(i.ipgStr), 
					-- да, дата начала ИПг входит в текущий месяц
					i.ipgStr,
					-- нет, дата начала ИПг не входит в текущий месяц
					iif
						(
							-- дата окончания ИПг входит в текущий месяц?
							month(datefromparts(s.yyyy, s.mNum, 1)) = month(i.ipgEnd), 
							-- да, дата окончания ИПг входит в текущий месяц
							i.ipgEnd,
							-- нет, дата окончания ИПг не входит в текущий месяц
							eomonth(datefromparts(s.yyyy, s.mNum, 1))
						)
				) dateRslt
				, s.ipgKey, s.ipgCount
			from
				@spIpgChRsltCstUtl3_oneD s
				left join ags.ipg i on s.ipgKey = i.ipgKey
		) x
	group by x.dateRslt, x.ipgKey
	order by x.dateRslt, x.ipgKey

	-- заполняем возвращаемую табличку
	insert into @TableRslt
		(
				ipgChKey, iv_PlFulfillment, iv_PlNonFulfillment, iv_PlOverFulfillment, iv_PlRestLimit, iv_PlOverLimit
				, iv_LimPercent, iv_PlPercent
				-- по неизвестной схеме
				, uk_PlFulfillment, uk_PlNonFulfillment, uk_PlOverFulfillment, uk_PlRestLimit, uk_PlOverLimit
				, uk_LimPercent, uk_PlPercent
				-- по агентской схеме
				, ag_PlFulfillment, ag_PlNonFulfillment, ag_PlOverFulfillment, ag_PlRestLimit, ag_PlOverLimit
				, ag_LimPercent, ag_PlPercent

				, cstapKey
				, ag_ipgpKey, ag_ipgpSmTtl, ag_PlAccum, ag_Pl
				, iv_ipgpKey, iv_ipgpSmTtl, iv_PlAccum, iv_Pl
				, uk_ipgpKey, uk_ipgpSmTtl, uk_PlAccum, uk_Pl

				, dateRslt

				, yKey, yyyy, mKey, mNum, mCs, mNm, mQ, mHy
				, cstaInvestor, ogaKey, ogNm, branch, branchName, cstAgPnCode, ipgKey, ipgCount
				, ag_lim, ag_iShKey
				, ag_presented, ag_presentedAccum, ag_accepted, ag_acceptedAccum
				, ag_agFeePresented, ag_agFeePresentedAccum, ag_agFeeAccepted, ag_agFeeAcceptedAccum
				, ag_presentedRalp, ag_presentedRalpAccum, ag_acceptedRalp, ag_acceptedRalpAccum
				, ag_storageSum, ag_storageSumAccum, ag_cctSum, ag_cctSumAccum, ag_MnrlSum, ag_MnrlSumAccum
				, ag_presentedTtl, ag_presentedTtlAccum, ag_acceptedTtl, ag_acceptedTtlAccum, ag_restOfLimit, ag_percentDev
				, iv_lim, iv_iShKey
				, ia_lim, ia_iShKey
				, ia_presented, ia_presentedAccum, ia_accepted, ia_acceptedAccum
				, ia_agFeePresented, ia_agFeePresentedAccum, ia_agFeeAccepted, ia_agFeeAcceptedAccum
				, ia_presentedRalp, ia_presentedRalpAccum, ia_acceptedRalp, ia_acceptedRalpAccum
				, ia_storageSum, ia_storageSumAccum, ia_cctSum, ia_cctSumAccum, ia_MnrlSum, ia_MnrlSumAccum
				, ia_presentedTtl, ia_presentedTtlAccum, ia_acceptedTtl, ia_acceptedTtlAccum, ia_restOfLimit, ia_percentDev
				, uk_lim, uk_iShKey
				, uk_presented, uk_presentedAccum, uk_accepted, uk_acceptedAccum
				, uk_agFeePresented, uk_agFeePresentedAccum, uk_agFeeAccepted, uk_agFeeAcceptedAccum
				, uk_presentedRalp, uk_presentedRalpAccum, uk_acceptedRalp, uk_acceptedRalpAccum
				, uk_storageSum, uk_storageSumAccum, uk_cctSum, uk_cctSumAccum, uk_MnrlSum, uk_MnrlSumAccum
				, uk_presentedTtl, uk_presentedTtlAccum, uk_acceptedTtl, uk_acceptedTtlAccum, uk_restOfLimit, uk_percentDev
				, np_lim, np_iShKey
				, np_presented, np_presentedAccum, np_accepted, np_acceptedAccum
				, np_agFeePresented, np_agFeePresentedAccum, np_agFeeAccepted, np_agFeeAcceptedAccum
				, np_presentedRalp, np_presentedRalpAccum, np_acceptedRalp, np_acceptedRalpAccum
				, np_storageSum, np_storageSumAccum, np_cctSum, np_cctSumAccum, np_MnrlSum, np_MnrlSumAccum
				, np_presentedTtl, np_presentedTtlAccum, np_acceptedTtl, np_acceptedTtlAccum, np_restOfLimit, np_percentDev
				, oh_presented, oh_presentedAccum, oh_accepted, oh_acceptedAccum
				-- 14.07.2023 добавил прочие отчёты для агентского вознаграждения
				, oh_agFeePresented, oh_agFeePresentedAccum, oh_agFeeAccepted, oh_agFeeAcceptedAccum
				, oh_presentedTtl, oh_presentedTtlAccum, oh_acceptedTtl, oh_acceptedTtlAccum
		)
	select
		@ipgChKey as ipgChKey, iv_PlFulfillment, iv_PlNonFulfillment, iv_PlOverFulfillment, iv_PlRestLimit, iv_PlOverLimit
		, iv_LimPercent, iv_PlPercent
		-- по неизвестной схеме
		, uk_PlFulfillment, uk_PlNonFulfillment, uk_PlOverFulfillment, uk_PlRestLimit, uk_PlOverLimit
		, uk_LimPercent, uk_PlPercent
		-- по агентской схеме
		, ag_PlFulfillment, ag_PlNonFulfillment, ag_PlOverFulfillment, ag_PlRestLimit, ag_PlOverLimit
		, ag_LimPercent, ag_PlPercent

		, cstapKey
		, ag_ipgpKey, ag_ipgpSmTtl, ag_PlAccum, ag_Pl
		, iv_ipgpKey, iv_ipgpSmTtl, iv_PlAccum, iv_Pl
		, uk_ipgpKey, uk_ipgpSmTtl, uk_PlAccum, uk_Pl

		, dateRslt

		, yKey, yyyy, mKey, mNum, mCs, mNm, mQ, mHy
		, cstaInvestor, ogaKey, v.ogNm, branch, ogBrn.ogNm as branchName, cstAgPnCode, ipgKey, ipgCount
		, ag_lim, ag_iShKey
		, ag_presented, ag_presentedAccum, ag_accepted, ag_acceptedAccum
		, ag_agFeePresented, ag_agFeePresentedAccum, ag_agFeeAccepted, ag_agFeeAcceptedAccum
		, ag_presentedRalp, ag_presentedRalpAccum, ag_acceptedRalp, ag_acceptedRalpAccum
		, ag_storageSum, ag_storageSumAccum, ag_cctSum, ag_cctSumAccum, ag_MnrlSum, ag_MnrlSumAccum
		, ag_presentedTtl, ag_presentedTtlAccum, ag_acceptedTtl, ag_acceptedTtlAccum, ag_restOfLimit, ag_percentDev
		, iv_lim, iv_iShKey
		, ia_lim, ia_iShKey
		, ia_presented, ia_presentedAccum, ia_accepted, ia_acceptedAccum
		, ia_agFeePresented, ia_agFeePresentedAccum, ia_agFeeAccepted, ia_agFeeAcceptedAccum
		, ia_presentedRalp, ia_presentedRalpAccum, ia_acceptedRalp, ia_acceptedRalpAccum
		, ia_storageSum, ia_storageSumAccum, ia_cctSum, ia_cctSumAccum, ia_MnrlSum, ia_MnrlSumAccum
		, ia_presentedTtl, ia_presentedTtlAccum, ia_acceptedTtl, ia_acceptedTtlAccum, ia_restOfLimit, ia_percentDev
		, uk_lim, uk_iShKey
		, uk_presented, uk_presentedAccum, uk_accepted, uk_acceptedAccum
		, uk_agFeePresented, uk_agFeePresentedAccum, uk_agFeeAccepted, uk_agFeeAcceptedAccum
		, uk_presentedRalp, uk_presentedRalpAccum, uk_acceptedRalp, uk_acceptedRalpAccum
		, uk_storageSum, uk_storageSumAccum, uk_cctSum, uk_cctSumAccum, uk_MnrlSum, uk_MnrlSumAccum
		, uk_presentedTtl, uk_presentedTtlAccum, uk_acceptedTtl, uk_acceptedTtlAccum, uk_restOfLimit, uk_percentDev
		, np_lim, np_iShKey
		, np_presented, np_presentedAccum, np_accepted, np_acceptedAccum
		, np_agFeePresented, np_agFeePresentedAccum, np_agFeeAccepted, np_agFeeAcceptedAccum
		, np_presentedRalp, np_presentedRalpAccum, np_acceptedRalp, np_acceptedRalpAccum
		, np_storageSum, np_storageSumAccum, np_cctSum, np_cctSumAccum, np_MnrlSum, np_MnrlSumAccum
		, np_presentedTtl, np_presentedTtlAccum, np_acceptedTtl, np_acceptedTtlAccum, np_restOfLimit, np_percentDev
		, oh_presented, oh_presentedAccum, oh_accepted, oh_acceptedAccum
		-- 14.07.2023 добавил прочие отчёты для агентского вознаграждения
		, oh_agFeePresented, oh_agFeePresentedAccum, oh_agFeeAccepted, oh_agFeeAcceptedAccum
		, oh_presentedTtl, oh_presentedTtlAccum, oh_acceptedTtl, oh_acceptedTtlAccum
	from
		(
			select 
				-- --------------------------------------------------------------------------- по инвестиционной схеме --------------------------------------------------
				iif
					(	-- процент освоения ---------------------------------------------------------------------------------------------------------
						-- лимит отсутствует?
						w.iv_lim is null or w.iv_lim = 0,
						null,	-- да, лимит отсутствует
						iif		-- нет, лимит имеется
							(
								-- сумма выполнения и перевыполнения плана больше лимита?
								w.iv_lim < isnull(w.iv_PlFulfillment, 0) + isnull(w.iv_PlOverFulfillment, 0),
								1, -- да, тогда процент освоения равен 100%
								(isnull(w.iv_PlFulfillment, 0) + isnull(w.iv_PlOverFulfillment, 0))/w.iv_lim -- нет, тогда процент освоения равен частному суммы выполнения и перевыполнения плана и лимита
							)
					) iv_LimPercent -- процент освоения ---------------------------------------------------------------------------------------------
				, iif
					(	-- процент выполнения плана -------------------------------------------------------------------------------------------------
						-- план отсутствует?
						w.iv_PlAccum is null or w.iv_PlAccum = 0,
						null,	-- да, план отсутствует
						(isnull(w.iv_PlFulfillment, 0) + isnull(w.iv_PlOverFulfillment, 0))/w.iv_PlAccum -- нет, тогда процент выполнения плана равен частному суммы выполнения и перевыполнения плана и плана
					) iv_PlPercent -- процент выполнения плана --------------------------------------------------------------------------------------
				-- --------------------------------------------------------------------------- по инвестиционной схеме --------------------------------------------------
				-- --------------------------------------------------------------------------- по неизвестной схеме -----------------------------------------------------
				, iif
					(	-- процент освоения ---------------------------------------------------------------------------------------------------------
						-- лимит отсутствует?
						w.uk_lim is null or w.uk_lim = 0,
						null,	-- да, лимит отсутствует
						iif		-- нет, лимит имеется
							(
								-- сумма выполнения и перевыполнения плана больше лимита?
								w.uk_lim < isnull(w.uk_PlFulfillment, 0) + isnull(w.uk_PlOverFulfillment, 0),
								1, -- да, тогда процент освоения равен 100%
								(isnull(w.uk_PlFulfillment, 0) + isnull(w.uk_PlOverFulfillment, 0))/w.uk_lim -- нет, тогда процент освоения равен частному суммы выполнения и перевыполнения плана и лимита
							)
					) uk_LimPercent -- процент освоения ---------------------------------------------------------------------------------------------
				, iif
					(	-- процент выполнения плана -------------------------------------------------------------------------------------------------
						-- план отсутствует?
						w.uk_PlAccum is null or w.uk_PlAccum = 0,
						null,	-- да, план отсутствует
						(isnull(w.uk_PlFulfillment, 0) + isnull(w.uk_PlOverFulfillment, 0))/w.uk_PlAccum -- нет, тогда процент выполнения плана равен частному суммы выполнения и перевыполнения плана и плана
					) uk_PlPercent -- процент выполнения плана --------------------------------------------------------------------------------------

				-- --------------------------------------------------------------------------- по неизвестной схеме -----------------------------------------------------
				-- --------------------------------------------------------------------------- по агентской схеме -------------------------------------------------------
				, iif
					(	-- процент освоения ---------------------------------------------------------------------------------------------------------
						-- лимит отсутствует?
						w.ag_lim is null or w.ag_lim = 0,
						null,	-- да, лимит отсутствует
						iif		-- нет, лимит имеется
							(
								-- сумма выполнения и перевыполнения плана больше лимита?
								w.ag_lim < isnull(w.ag_PlFulfillment, 0) + isnull(w.ag_PlOverFulfillment, 0),
								1, -- да, тогда процент освоения равен 100%
								(isnull(w.ag_PlFulfillment, 0) + isnull(w.ag_PlOverFulfillment, 0))/w.ag_lim -- нет, тогда процент освоения равен частному суммы выполнения и перевыполнения плана и лимита
							)
					) ag_LimPercent -- процент освоения ---------------------------------------------------------------------------------------------
				, iif
					(	-- процент выполнения плана -------------------------------------------------------------------------------------------------
						-- план отсутствует?
						w.ag_PlAccum is null or w.ag_PlAccum = 0,
						null,	-- да, план отсутствует
						(isnull(w.ag_PlFulfillment, 0) + isnull(w.ag_PlOverFulfillment, 0))/w.ag_PlAccum -- нет, тогда процент выполнения плана равен частному суммы выполнения и перевыполнения плана и плана
					) ag_PlPercent -- процент выполнения плана --------------------------------------------------------------------------------------
				-- --------------------------------------------------------------------------- по агентской схеме -------------------------------------------------------
				, w.*
			from
				(
					-- группируем результаты по каждой стройке до уровня всего, заказчик
					select 
						 u.ogNm, u.branch, u.cstapKey, u.dateRslt
						, u.yKey, u.yyyy, u.mKey, u.mNum, u.mCs, u.mNm, u.mQ, u.mHy
						, u.cstaInvestor, u.ogaKey, u.cstAgPnCode, u.ipgKey, u.ipgCount
						-- по агентской схеме
						, u.ag_ipgpKey, sum(u.ag_ipgpSmTtl) ag_ipgpSmTtl, sum(u.ag_PlAccum) ag_PlAccum, sum(u.ag_Pl) ag_Pl
						, sum(u.ag_lim) ag_lim, u.ag_iShKey
						, sum(u.ag_PlFulfillment) ag_PlFulfillment, sum(u.ag_PlNonFulfillment) ag_PlNonFulfillment, sum(u.ag_PlOverFulfillment) ag_PlOverFulfillment
						, sum(u.ag_PlRestLimit) ag_PlRestLimit, sum(u.ag_PlOverLimit) ag_PlOverLimit
						, sum(u.ag_presented) ag_presented, sum(u.ag_presentedAccum) ag_presentedAccum, sum(u.ag_accepted) ag_accepted, sum(u.ag_acceptedAccum) ag_acceptedAccum
						, sum(u.ag_agFeePresented) ag_agFeePresented, sum(u.ag_agFeePresentedAccum) ag_agFeePresentedAccum, sum(u.ag_agFeeAccepted) ag_agFeeAccepted, sum(u.ag_agFeeAcceptedAccum) ag_agFeeAcceptedAccum
						, sum(u.ag_presentedRalp) ag_presentedRalp, sum(u.ag_presentedRalpAccum) ag_presentedRalpAccum, sum(u.ag_acceptedRalp) ag_acceptedRalp, sum(u.ag_acceptedRalpAccum) ag_acceptedRalpAccum
						, sum(u.ag_storageSum) ag_storageSum, sum(u.ag_storageSumAccum) ag_storageSumAccum, sum(u.ag_cctSum) ag_cctSum, sum(u.ag_cctSumAccum) ag_cctSumAccum
						, sum(u.ag_MnrlSum) ag_MnrlSum, sum(u.ag_MnrlSumAccum) ag_MnrlSumAccum
						, sum(u.ag_presentedTtl) ag_presentedTtl, sum(u.ag_presentedTtlAccum) ag_presentedTtlAccum, sum(u.ag_acceptedTtl) ag_acceptedTtl
						, sum(u.ag_acceptedTtlAccum) ag_acceptedTtlAccum, sum(u.ag_restOfLimit) ag_restOfLimit, ag_percentDev
						-- по инвестиционной схеме
						, u.iv_ipgpKey, sum(u.iv_ipgpSmTtl) iv_ipgpSmTtl, sum(u.iv_PlAccum) iv_PlAccum, sum(u.iv_Pl) iv_Pl
						, sum(u.iv_lim) iv_lim, u.iv_iShKey
						, sum(u.ia_lim) ia_lim, u.ia_iShKey
						, sum(u.iv_PlFulfillment) iv_PlFulfillment, sum(u.iv_PlNonFulfillment) iv_PlNonFulfillment, sum(u.iv_PlOverFulfillment) iv_PlOverFulfillment
						, sum(u.iv_PlRestLimit) iv_PlRestLimit, sum(u.iv_PlOverLimit) iv_PlOverLimit
						, sum(u.ia_presented) ia_presented, sum(u.ia_presentedAccum) ia_presentedAccum, sum(u.ia_accepted) ia_accepted, sum(u.ia_acceptedAccum) ia_acceptedAccum
						, sum(u.ia_agFeePresented) ia_agFeePresented, sum(u.ia_agFeePresentedAccum) ia_agFeePresentedAccum, sum(u.ia_agFeeAccepted) ia_agFeeAccepted, sum(u.ia_agFeeAcceptedAccum) ia_agFeeAcceptedAccum
						, sum(u.ia_presentedRalp) ia_presentedRalp, sum(u.ia_presentedRalpAccum) ia_presentedRalpAccum, sum(u.ia_acceptedRalp) ia_acceptedRalp, sum(u.ia_acceptedRalpAccum) ia_acceptedRalpAccum
						, sum(u.ia_storageSum) ia_storageSum, sum(u.ia_storageSumAccum) ia_storageSumAccum, sum(u.ia_cctSum) ia_cctSum, sum(u.ia_cctSumAccum) ia_cctSumAccum
						, sum(u.ia_MnrlSum) ia_MnrlSum, sum(u.ia_MnrlSumAccum) ia_MnrlSumAccum
						, sum(u.ia_presentedTtl) ia_presentedTtl, sum(u.ia_presentedTtlAccum) ia_presentedTtlAccum, sum(u.ia_acceptedTtl) ia_acceptedTtl
						, sum(u.ia_acceptedTtlAccum) ia_acceptedTtlAccum, sum(u.ia_restOfLimit) ia_restOfLimit, ia_percentDev
						-- по неизвестной схеме
						, u.uk_ipgpKey, sum(u.uk_ipgpSmTtl) uk_ipgpSmTtl, sum(u.uk_PlAccum) uk_PlAccum, sum(u.uk_Pl) uk_Pl
						, sum(u.uk_lim) uk_lim, u.uk_iShKey
						, sum(u.uk_PlFulfillment) uk_PlFulfillment, sum(u.uk_PlNonFulfillment) uk_PlNonFulfillment, sum(u.uk_PlOverFulfillment) uk_PlOverFulfillment
						, sum(u.uk_PlRestLimit) uk_PlRestLimit, sum(u.uk_PlOverLimit) uk_PlOverLimit
						, sum(u.uk_presented) uk_presented, sum(u.uk_presentedAccum) uk_presentedAccum, sum(u.uk_accepted) uk_accepted, sum(u.uk_acceptedAccum) uk_acceptedAccum
						, sum(u.uk_agFeePresented) uk_agFeePresented, sum(u.uk_agFeePresentedAccum) uk_agFeePresentedAccum, sum(u.uk_agFeeAccepted) uk_agFeeAccepted, sum(u.uk_agFeeAcceptedAccum) uk_agFeeAcceptedAccum
						, sum(u.uk_presentedRalp) uk_presentedRalp, sum(u.uk_presentedRalpAccum) uk_presentedRalpAccum, sum(u.uk_acceptedRalp) uk_acceptedRalp, sum(u.uk_acceptedRalpAccum) uk_acceptedRalpAccum
						, sum(u.uk_storageSum) uk_storageSum, sum(u.uk_storageSumAccum) uk_storageSumAccum, sum(u.uk_cctSum) uk_cctSum, sum(u.uk_cctSumAccum) uk_cctSumAccum
						, sum(u.uk_MnrlSum) uk_MnrlSum, sum(u.uk_MnrlSumAccum) uk_MnrlSumAccum
						, sum(u.uk_presentedTtl) uk_presentedTtl, sum(u.uk_presentedTtlAccum) uk_presentedTtlAccum, sum(u.uk_acceptedTtl) uk_acceptedTtl
						, sum(u.uk_acceptedTtlAccum) uk_acceptedTtlAccum, sum(u.uk_restOfLimit) uk_restOfLimit, uk_percentDev
						-- неплан
						, sum(u.np_lim) np_lim, u.np_iShKey
						, sum(u.np_presented) np_presented, sum(u.np_presentedAccum) np_presentedAccum, sum(u.np_accepted) np_accepted, sum(u.np_acceptedAccum) np_acceptedAccum
						, sum(u.np_agFeePresented) np_agFeePresented, sum(u.np_agFeePresentedAccum) np_agFeePresentedAccum, sum(u.np_agFeeAccepted) np_agFeeAccepted, sum(u.np_agFeeAcceptedAccum) np_agFeeAcceptedAccum
						, sum(u.np_presentedRalp) np_presentedRalp, sum(u.np_presentedRalpAccum) np_presentedRalpAccum, sum(u.np_acceptedRalp) np_acceptedRalp, sum(u.np_acceptedRalpAccum) np_acceptedRalpAccum
						, sum(u.np_storageSum) np_storageSum, sum(u.np_storageSumAccum) np_storageSumAccum, sum(u.np_cctSum) np_cctSum, sum(u.np_cctSumAccum) np_cctSumAccum
						, sum(u.np_MnrlSum) np_MnrlSum, sum(u.np_MnrlSumAccum) np_MnrlSumAccum
						, sum(u.np_presentedTtl) np_presentedTtl, sum(u.np_presentedTtlAccum) np_presentedTtlAccum, sum(u.np_acceptedTtl) np_acceptedTtl
						, sum(u.np_acceptedTtlAccum) np_acceptedTtlAccum, sum(u.np_restOfLimit) np_restOfLimit, np_percentDev
						-- прочее
						, sum(u.oh_presented) oh_presented, sum(u.oh_presentedAccum) oh_presentedAccum, sum(u.oh_accepted) oh_accepted, sum(u.oh_acceptedAccum) oh_acceptedAccum
						-- 14.07.2023 добавил прочие отчёты для агентского вознаграждения
						, sum(u.oh_agFeePresented) oh_agFeePresented, sum(u.oh_agFeePresentedAccum) oh_agFeePresentedAccum, sum(u.oh_agFeeAccepted) oh_agFeeAccepted, sum(u.oh_agFeeAcceptedAccum) oh_agFeeAcceptedAccum
						, sum(u.oh_presentedTtl) oh_presentedTtl, sum(u.oh_presentedTtlAccum) oh_presentedTtlAccum, sum(u.oh_acceptedTtl) oh_acceptedTtl, sum(u.oh_acceptedTtlAccum) oh_acceptedTtlAccum
					from
						(
							-- получаем результата вычислений подлежащие, вполследствии, группировке
							select
								-- --------------------------------------------------------------------------- по инвестиционной схеме ------------------------------------------
								iif
									(	-- выполнение -----------------------------------------------------------------------------------------------------------------
										-- общее принятое больше лимита?
										z.iv_lim < z.ia_acceptedTtlAccum,
										-- да, общее принятое больше лимита
										iif
											(
												-- план меньше лимита?
												isnull(z.iv_PlAccum, 0) - isnull(z.iv_lim, 0) < 0,
												isnull(z.iv_PlAccum, 0),	-- да, тогда выполнение равно плану
												isnull(z.iv_lim, 0)			-- нет, тогда выполнение равно лимиту
											),
										-- нет, общее принятое не больше лимита
										iif
											(
												-- план меньше общего принятого?
												isnull(z.iv_PlAccum, 0) - isnull(z.ia_acceptedTtlAccum, 0) < 0,
												isnull(z.iv_PlAccum, 0),			-- да, тогда выполнение равно плану
												isnull(z.ia_acceptedTtlAccum, 0)	-- нет, тогда выполнение равно общему принятому
											)
									) iv_PlFulfillment -- выполнение ------------------------------------------------------------------------------------------------
								, iif
									(	-- недовыполнение -----------------------------------------------------------------------------------------------------------
										-- общее принятое больше лимита?
										z.iv_lim < z.ia_acceptedTtlAccum,
										0, -- да, общее принятое больше лимита, тогда недовыполнение рано 0
										-- нет, общее принятое не больше лимита
										iif
											(
												-- план меньше общего принятого?
												isnull(z.iv_PlAccum, 0) - isnull(z.ia_acceptedTtlAccum, 0) < 0,
												0, -- да, тогда недовыполнение равно 0
												isnull(z.iv_PlAccum, 0) - isnull(z.ia_acceptedTtlAccum, 0) -- нет, тогда недовыполнение равно разнице между планом и общим принятым
											)
									) iv_PlNonFulfillment -- недовыполнение -----------------------------------------------------------------------------------------
								, iif
									(	-- перевыполнение -----------------------------------------------------------------------------------------------------------
										-- общее принятое больше лимита?
										z.iv_lim < z.ia_acceptedTtlAccum,
										-- да, общее принятое больше лимита
										iif
											(
												-- план меньше лимита?
												isnull(z.iv_PlAccum, 0) - isnull(z.iv_lim, 0) < 0,
												(isnull(z.iv_PlAccum, 0) - isnull(z.iv_lim, 0)) * -1, -- да, тогда перевыполнение равно разнице между планом и лимитом
												0 -- нет, тогда перевыполнение равно 0
											),
										-- нет, общее принятое не больше лимита
										iif
											(
												-- общее принятое больше плана?
												isnull(z.iv_PlAccum, 0) - isnull(z.ia_acceptedTtlAccum, 0) < 0,
												(isnull(z.iv_PlAccum, 0) - isnull(z.ia_acceptedTtlAccum, 0)) * -1, -- да, тогда перевыполнение равно разнице между общим принятым и планом
												0 -- нет, тогда перевыполнение равно 0
											)
									) iv_PlOverFulfillment -- перевыполнение ----------------------------------------------------------------------------------------
								, iif
									(	-- остаток лимита -----------------------------------------------------------------------------------------------------------
										-- общее принятое больше лимита?
										z.iv_lim < z.ia_acceptedTtlAccum,
										-- да, общее принятое больше лимита
										0,
										-- нет, общее принятое не больше лимита
										iif
											(
												-- план больше общего принятого?
												isnull(z.iv_PlAccum, 0) > isnull(z.ia_acceptedTtlAccum, 0),
												z.iv_lim - isnull(z.iv_PlAccum, 0), -- да, тогда остаток лимита равен разнице между лимитом и планом
												z.iv_lim - isnull(z.ia_acceptedTtlAccum, 0) -- нет, тогда остаток лимита равен разнице между лимитом и общим принятым
											)
									) iv_PlRestLimit -- остаток лимита ----------------------------------------------------------------------------------------------
								, iif
									(	-- превышение лимита --------------------------------------------------------------------------------------------------------
										-- общее принятое больше лимита?
										z.iv_lim < z.ia_acceptedTtlAccum,
										z.ia_acceptedTtlAccum - z.iv_lim, -- да, тогда превышение лимита равно разнице между общим принятым и лимитом
										0 -- нет, тогда превышение лимита равно 0
									) iv_PlOverLimit -- превышение лимита -------------------------------------------------------------------------------------------
								-- --------------------------------------------------------------------------- по инвестиционной схеме ----------------------------------------
								-- --------------------------------------------------------------------------- по неизвестной схеме -------------------------------------------
								, iif
									(
										-- общее принятое больше лимита?
										z.uk_lim < z.uk_acceptedTtlAccum,
										-- да, общее принятое больше лимита
										iif
											(
												isnull(z.uk_PlAccum, 0) - isnull(z.uk_lim, 0) < 0,
												isnull(z.uk_PlAccum, 0),
												isnull(z.uk_lim, 0)
											),
										-- нет, общее принятое не больше лимита
										iif
											(
												isnull(z.uk_PlAccum, 0) - isnull(z.uk_acceptedTtlAccum, 0) < 0,
												isnull(z.uk_PlAccum, 0),
												isnull(z.uk_acceptedTtlAccum, 0)
											)
									) uk_PlFulfillment -- выполнение
								, iif
									(
										-- общее принятое больше лимита?
										z.uk_lim < z.uk_acceptedTtlAccum,
										-- да, общее принятое больше лимита
										0, 
										-- нет, общее принятое не больше лимита
										iif
											(
												isnull(z.uk_PlAccum, 0) - isnull(z.uk_acceptedTtlAccum, 0) < 0,
												0,
												isnull(z.uk_PlAccum, 0) - isnull(z.uk_acceptedTtlAccum, 0)
											)
									) uk_PlNonFulfillment
								, iif
									(
										-- общее принятое больше лимита?
										z.uk_lim < z.uk_acceptedTtlAccum,
										-- да, общее принятое больше лимита
										iif
											(
												isnull(z.uk_PlAccum, 0) - isnull(z.uk_lim, 0) < 0,
												(isnull(z.uk_PlAccum, 0) - isnull(z.uk_lim, 0)) * -1,
												0
											),
										-- нет, общее принятое не больше лимита
										iif
											(
												isnull(z.uk_PlAccum, 0) - isnull(z.uk_acceptedTtlAccum, 0) < 0,
												(isnull(z.uk_PlAccum, 0) - isnull(z.uk_acceptedTtlAccum, 0)) * -1,
												0
											)
									) uk_PlOverFulfillment -- перевыполнение
								, iif
									(
										-- общее принятое больше лимита?
										z.uk_lim < z.uk_acceptedTtlAccum,
										-- да, общее принятое больше лимита
										0,
										-- нет, общее принятое не больше лимита
										-- план больше общего принятого?
										iif
											(
												isnull(z.uk_PlAccum, 0) > isnull(z.uk_acceptedTtlAccum, 0),
												z.uk_lim - isnull(z.uk_PlAccum, 0),
												z.uk_lim - isnull(z.uk_acceptedTtlAccum, 0)
											)
									) uk_PlRestLimit -- остаток лимита
								, iif
									(
										z.uk_lim < z.uk_acceptedTtlAccum,
										z.uk_acceptedTtlAccum - z.uk_lim,
										0
									) uk_PlOverLimit -- превышение лимита
								-- --------------------------------------------------------------------------- по неизвестной схеме -------------------------------------------
								-- --------------------------------------------------------------------------- по агентской схеме ---------------------------------------------
								, iif
									(
										-- общее принятое больше лимита?
										z.ag_lim < z.ag_acceptedTtlAccum,
										-- да, общее принятое больше лимита
										iif
											(
												isnull(z.ag_PlAccum, 0) - isnull(z.ag_lim, 0) < 0,
												isnull(z.ag_PlAccum, 0),
												isnull(z.ag_lim, 0)
											),
										-- нет, общее принятое не больше лимита
										iif
											(
												isnull(z.ag_PlAccum, 0) - isnull(z.ag_acceptedTtlAccum, 0) < 0,
												isnull(z.ag_PlAccum, 0),
												isnull(z.ag_acceptedTtlAccum, 0)
											)
									) ag_PlFulfillment -- выполнение
								, iif
									(
										-- общее принятое больше лимита?
										z.ag_lim < z.ag_acceptedTtlAccum,
										-- да, общее принятое больше лимита
										0, 
										-- нет, общее принятое не больше лимита
										iif
											(
												isnull(z.ag_PlAccum, 0) - isnull(z.ag_acceptedTtlAccum, 0) < 0,
												0,
												isnull(z.ag_PlAccum, 0) - isnull(z.ag_acceptedTtlAccum, 0)
											)
									) ag_PlNonFulfillment
								, iif
									(
										-- общее принятое больше лимита?
										z.ag_lim < z.ag_acceptedTtlAccum,
										-- да, общее принятое больше лимита
										iif
											(
												isnull(z.ag_PlAccum, 0) - isnull(z.ag_lim, 0) < 0,
												(isnull(z.ag_PlAccum, 0) - isnull(z.ag_lim, 0)) * -1,
												0
											),
										-- нет, общее принятое не больше лимита
										iif
											(
												isnull(z.ag_PlAccum, 0) - isnull(z.ag_acceptedTtlAccum, 0) < 0,
												(isnull(z.ag_PlAccum, 0) - isnull(z.ag_acceptedTtlAccum, 0)) * -1,
												0
											)
									) ag_PlOverFulfillment -- перевыполнение
								, iif
									(
										-- общее принятое больше лимита?
										z.ag_lim < z.ag_acceptedTtlAccum,
										-- да, общее принятое больше лимита
										0,
										-- нет, общее принятое не больше лимита
										-- план больше общего принятого?
										iif
											(
												isnull(z.ag_PlAccum, 0) > isnull(z.ag_acceptedTtlAccum, 0),
												z.ag_lim - isnull(z.ag_PlAccum, 0),
												z.ag_lim - isnull(z.ag_acceptedTtlAccum, 0)
											)
									) ag_PlRestLimit -- остаток лимита
								, iif
									(
										z.ag_lim < z.ag_acceptedTtlAccum,
										z.ag_acceptedTtlAccum - z.ag_lim,
										0
									) ag_PlOverLimit
								-- --------------------------------------------------------------------------- по агентской схеме -----------------------------------------
								, z.*
							from
								(
									select
										p.cstapKey
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
										, x.dateRslt, 
										i.*
									from
										(
											-- формируем перечень дат
											select
												u.dateRslt, 
												iif
													(
														-- если дата меньше последнего дня января, то считаем номер месяца нулевым
														u.dateRslt < datefromparts(@lsYy, 1, 31),
														0,
														month(u.dateRslt) 
													) mNum, 
												u.ipgKey
											from
												@dt u
											where 
												u.ipgKey is not null
											union
											select
												ddd,
												iif
													(
														-- если дата меньше последнего дня января, то считаем номер месяца нулевым
														ddd < datefromparts(@lsYy, 1, 31),
														0,
														month(ddd) 
													) mNum, 
												ipgKey
											from
												(
													select
														-- поменял 22-0204
														eomonth(datefromparts(@lsYy, m.mNum, 1)) ddd
														-- eomonth(datefromparts(year((select top 1 t.dateRslt from @dt t)), m.mNum, 1)) ddd
													from
														ags.mmmm m
													union
														select datefromparts(@lsYy, 1, 1)
												) z
												left join
													(
														select
															*
														from
															(
																select 
																	month(t.dateRslt) m, max(t.dateRslt) d
																from 
																	@dt t
																where
																	t.ipgKey is not null
																group by
																	month(t.dateRslt)
															) x
															join
																@dt u
																on x.d = u.dateRslt and u.ipgKey is not null
													) q
													on month(z.ddd) = q.m
											-- формируем перечень дат, окончание
										) x	
										left join
											@spIpgChRsltCstUtl3_oneD i
											on x.mNum = i.mNum and (x.ipgKey = i.ipgKey or i.ipgKey is null)
											join
											ags.cstAgPn p
											on i.cstAgPnCode = p.cstapIpgPnN
											left join
												-- для агентской схемы
												ags.ipgPn ga
												on p.cstapKey = ga.ipgpCstAgPn and i.ag_iShKey = ga.ipgpSh and i.ipgKey = ga.ipgpIpg
												left join
													(
														select
															ipgcrChain, ipgcrIpg, iuplpIpgPn, iuplpSubAg
															, iuplpM01
															, iuplpM02, iuplpM03
															, iuplpM04, iuplpM05, iuplpM06
															, iuplpM07, iuplpM08, iuplpM09
															, iuplpM10, iuplpM11, iuplpM12
															, iuplpM02Accum, iuplpM03Accum
															, iuplpM04Accum, iuplpM05Accum, iuplpM06Accum
															, iuplpM07Accum, iuplpM08Accum, iuplpM09Accum
															, iuplpM10Accum, iuplpM11Accum, iuplpM12Accum
														from
															ags.ipgChRl r
															join
																ags.ipgUtPlGr g
																on r.ipgcrUtPlGr = g.iuplgKey
																join
																	ags.ipgUtPlGrP p
																	on g.iuplgKey = p.iuplgpGr
																	join
																		ags.ipgUtPlP n
																		on p.iuplgpPl = n.iuplpPl
													) gap
													on gap.ipgcrChain = @ipgChKey and ga.ipgpKey = gap.iuplpIpgPn
											left join
												-- для инвестиционной схемы
												ags.ipgPn gi
												on p.cstapKey = gi.ipgpCstAgPn and i.iv_iShKey = gi.ipgpSh and i.ipgKey = gi.ipgpIpg
												left join
													(
														select
															ipgcrChain, ipgcrIpg, iuplpIpgPn, iuplpSubAg
															, iuplpM01
															, iuplpM02, iuplpM03
															, iuplpM04, iuplpM05, iuplpM06
															, iuplpM07, iuplpM08, iuplpM09
															, iuplpM10, iuplpM11, iuplpM12
															, iuplpM02Accum, iuplpM03Accum
															, iuplpM04Accum, iuplpM05Accum, iuplpM06Accum
															, iuplpM07Accum, iuplpM08Accum, iuplpM09Accum
															, iuplpM10Accum, iuplpM11Accum, iuplpM12Accum
														from
															ags.ipgChRl r
															join
																ags.ipgUtPlGr g
																on r.ipgcrUtPlGr = g.iuplgKey
																join
																	ags.ipgUtPlGrP p
																	on g.iuplgKey = p.iuplgpGr
																	join
																		ags.ipgUtPlP n
																		on p.iuplgpPl = n.iuplpPl
													) gip
													on gip.ipgcrChain = @ipgChKey and gi.ipgpKey = gip.iuplpIpgPn
											left join
												-- для неизвестной схемы
												ags.ipgPn gu
												on p.cstapKey = gu.ipgpCstAgPn and i.uk_iShKey = gu.ipgpSh and i.ipgKey = gu.ipgpIpg
																left join
													(
														select
															ipgcrChain, ipgcrIpg, iuplpIpgPn, iuplpSubAg
															, iuplpM01
															, iuplpM02, iuplpM03
															, iuplpM04, iuplpM05, iuplpM06
															, iuplpM07, iuplpM08, iuplpM09
															, iuplpM10, iuplpM11, iuplpM12
															, iuplpM02Accum, iuplpM03Accum
															, iuplpM04Accum, iuplpM05Accum, iuplpM06Accum
															, iuplpM07Accum, iuplpM08Accum, iuplpM09Accum
															, iuplpM10Accum, iuplpM11Accum, iuplpM12Accum
														from
															ags.ipgChRl r
															join
																ags.ipgUtPlGr g
																on r.ipgcrUtPlGr = g.iuplgKey
																join
																	ags.ipgUtPlGrP p
																	on g.iuplgKey = p.iuplgpGr
																	join
																		ags.ipgUtPlP n
																		on p.iuplgpPl = n.iuplpPl
													) gup
													on gup.ipgcrChain = @ipgChKey and gu.ipgpKey = gup.iuplpIpgPn
								) z
							-- получаем результата вычислений подлежащие, вполследствии, группировке. Окончание
						) u
					GROUP BY GROUPING SETS
						--(u.dateRslt, u.ogNm, u.cstAgPnCode)
						 ((u.dateRslt), (u.ogNm, u.dateRslt), (u.ogNm, u.branch, u.dateRslt), (u.ogNm, u.branch, u.cstAgPnCode, u.dateRslt
						, u.cstapKey
						, u.yKey, u.yyyy, u.mKey, u.mNum, u.mCs, u.mNm, u.mQ, u.mHy
						, u.cstaInvestor, u.ogaKey, u.cstAgPnCode, u.ipgKey, u.ipgCount
						, u.ag_ipgpKey, u.ag_iShKey, ag_percentDev
						, u.iv_ipgpKey, u.iv_iShKey, u.ia_iShKey, ia_percentDev
						, u.uk_ipgpKey, u.uk_iShKey, uk_percentDev
						, u.np_iShKey, np_percentDev))
					-- группируем результаты по каждой стройке до уровня всего, заказчик. Окончание
				) w

		) v
		left join ags.og ogBrn on v.branch = ogBrn.ogKey

	RETURN 
END
GO


