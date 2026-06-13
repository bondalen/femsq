USE [FishEye];
GO

-- =============================================================================
-- Файл:    MSSQL2012/03c_CREATE_FUNCTION_fnMasteringCstAgPnSh_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Совместимость: SQL Server 2012 SP4. Без CREATE OR ALTER.
-- =============================================================================

PRINT '=== 03c MSSQL2012: CREATE fnMasteringCstAgPn_2606 / fnMasteringCstAgPnSh_2606 ===';
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'ags.fnMasteringCstAgPn_2606', N'TF') IS NOT NULL
    DROP FUNCTION ags.fnMasteringCstAgPn_2606;
GO

CREATE FUNCTION ags.fnMasteringCstAgPn_2606 
(
	@ipgCh int			-- цепь инвестиционных программ
	, @cstAgPn int		-- стройка (стройка-агент-код)
	, @ipgSh int		-- схема реализации Инвестпроектов
	, @StCostKey int	-- пункт структуры стоимости
	, @stNet int		-- схема структуры стоимости
	, @ipgRoot int		-- пункт структуры инвестиционной программы, в контексте которого рассматривается стройка
)
RETURNS 
	-- объявляем возвращаемую табличку результата
	@TablRslt TABLE 
		(
			dAll date, ipgcrKey int, ipgcrChain int, ipgcrIpg int, ipgcrUtPlGr int, ipgpKey int, ipgpSh int, iuplgKey int, iuplgpPl int, iuplpKey int, ipgpCstAgPn int, cstaAg int, mKey int
			, smm money, smmTtl money, lim money, pct money
			, iuplpSubAg int -- 17.10.2023 добавил филиал
			, MstrngPrsRa money, MstrngAcpRa money, MstrngPrsRaMn money, MstrngAcpRaMn money
			, MstrngPrsAgFee money, MstrngAcpAgFee money, MstrngPrsAgFeeMn money, MstrngAcpAgFeeMn money
			, MstrngPrsRalp money, MstrngAcpRalp money, MstrngPrsRalpMn money, MstrngAcpRalpMn money
			, MstrngAcpStor money, MstrngAcpStorMn money, MstrngAcpControl money, MstrngAcpControlMn money
			, MstrngAcpMnrl money, MstrngAcpMnrlMn money
			, MasteringPres money, MasteringAccp money, MasteringPresMn money, MasteringAccpMn money
			, planCompleted money, planCompletedNot money, planCompletedOver money
			, limNot money, limOver money
		)
AS
BEGIN
	declare @masteringTrue bit

	/* 
	1. Определяем потребность отображения освоения для стройки данной схемы исходя из наличия 
	в цепи инвестпрограмм этой стройки со схемой более высокого приоритета
	*/

	-- это агентская схема?
	if @ipgSh = 2
		-- да, это агентская схема
		set @masteringTrue = 'true'
	else
		-- нет, это не агентская схема
		-- это инвестиционная схема?
		if @ipgSh = 1
			-- да, это инвестиционная схема
			begin
				-- иемеются ли в цепи инвестпрограмм пункты этой стройки агентской схемы?
				if 
					(
						select count(*)
						from ags.ipgChRlV v
						join ags.ipgPn p on v.ipgcrvIpg = p.ipgpIpg
						where v.ipgcrvChain = @ipgCh and p.ipgpCstAgPn = @cstAgPn and p.ipgpSh = 2
					) > 0
					-- да, в цепи инвестпрограмм пункты этой стройки агентской схемы иемеются
					set @masteringTrue = 'false'
				else
					-- нет, в цепи инвестпрограмм пункты этой стройки агентской схемы отсутствуют
					set @masteringTrue = 'true'
			end
		else
			-- нет, это не инвестиционная схема, следовательно иная схема реализации
			begin
				-- иемеются ли в цепи инвестпрограмм пункты этой стройки агентской и инвестиционной схемы?
				if 
					(
						select count(*)
						from ags.ipgChRlV v
						join ags.ipgPn p on v.ipgcrvIpg = p.ipgpIpg
						where v.ipgcrvChain = @ipgCh and p.ipgpCstAgPn = @cstAgPn and p.ipgpSh in (1, 2)
					) > 0
					-- да, в цепи инвестпрограмм пункты этой стройки агентской и инвестиционной схемы иемеются
					set @masteringTrue = 'false'
				else
					-- нет, в цепи инвестпрограмм пункты этой стройки агентской и инвестиционной схемы отсутствуют
					set @masteringTrue = 'true'
			end

	/* 
	2. нужно ли отображать освоение для стройки данной схемы исходя из наличия 
	в цепи инвестпрограмм этой стройки со схемой более высокого приоритета?
	*/
	if @masteringTrue = 'true'
		-- да, отображать освоение для стройки данной схемы нужно
		insert into @TablRslt 
			(
				dAll, ipgcrKey, ipgcrChain, ipgcrIpg, ipgcrUtPlGr, ipgpKey, ipgpSh, iuplgKey, iuplgpPl, iuplpKey, ipgpCstAgPn, cstaAg, mKey
				, smm, smmTtl, lim, pct
				, iuplpSubAg -- 17.10.2023 добавил филиал
				, MstrngPrsRa, MstrngAcpRa, MstrngPrsRaMn, MstrngAcpRaMn
				, MstrngPrsAgFee, MstrngAcpAgFee, MstrngPrsAgFeeMn, MstrngAcpAgFeeMn
				, MstrngPrsRalp, MstrngAcpRalp, MstrngPrsRalpMn, MstrngAcpRalpMn
				, MstrngAcpStor, MstrngAcpStorMn, MstrngAcpControl, MstrngAcpControlMn
				, MstrngAcpMnrl, MstrngAcpMnrlMn
				, MasteringPres, MasteringAccp, MasteringPresMn, MasteringAccpMn
				, planCompleted, planCompletedNot, planCompletedOver
				, limNot, limOver
			)
		select
			x.dAll, x.ipgcrKey, x.ipgcrChain, x.ipgcrIpg, x.ipgcrUtPlGr, x.ipgpKey, x.ipgpSh, x.iuplgKey, x.iuplgpPl, x.iuplpKey, x.ipgpCstAgPn, x.cstaAg, x.mKey
			, x.smm, x.smmTtl, x.lim, x.pct
			, x.iuplpSubAg -- 17.10.2023 добавил филиал
			, x.MstrngPrsRa, x.MstrngAcpRa, x.MstrngPrsRaMn, x.MstrngAcpRaMn
			, x.MstrngPrsAgFee, x.MstrngAcpAgFee, x.MstrngPrsAgFeeMn, x.MstrngAcpAgFeeMn
			, x.MstrngPrsRalp, x.MstrngAcpRalp, x.MstrngPrsRalpMn, x.MstrngAcpRalpMn
			, x.MstrngAcpStor, x.MstrngAcpStorMn, x.MstrngAcpControl, x.MstrngAcpControlMn
			, x.MstrngAcpMnrl, x.MstrngAcpMnrlMn
			, x.MasteringPres, x.MasteringAccp, x.MasteringPresMn, x.MasteringAccpMn
			, iif (x.MasteringAccp < isnull(x.smmTtl, 0), x.MasteringAccp, isnull(x.smmTtl, 0)) as planCompleted -- выполнено из плана
			, iif (x.MasteringAccp < isnull(x.smmTtl, 0), isnull(x.smmTtl, 0) - x.MasteringAccp, 0) as planCompletedNot -- не выполнено из плана
			, iif
				(
					isnull(x.lim, 0) < x.MasteringAccp,
					isnull(x.lim, 0) - isnull(x.smmTtl, 0),
					iif (x.MasteringAccp < isnull(x.smmTtl, 0), 0, x.MasteringAccp - isnull(x.smmTtl, 0))
				) as planCompletedOver -- перевыполнено из плана
			, iif
				(
					x.MasteringAccp < isnull(x.smmTtl, 0),
					iif (isnull(x.lim, 0) < isnull(x.smmTtl, 0), 0, isnull(x.lim, 0) - isnull(x.smmTtl, 0)),
					iif (x.MasteringAccp < isnull(x.lim, 0), isnull(x.lim, 0) - x.MasteringAccp, 0)
				) as limNot -- остаток лимита
			, iif (x.MasteringAccp < isnull(x.lim, 0), 0, x.MasteringAccp - isnull(x.lim, 0)) as limOver -- превышение лимита
		from
			(
				select
					y.*
					, isnull(MstrngPrsRa, 0) + isnull(MstrngPrsAgFee, 0) + isnull(MstrngPrsRalp, 0) + isnull(MstrngAcpStor, 0) + isnull(MstrngAcpControl, 0) + isnull(MstrngAcpMnrl, 0) as MasteringPres
					, isnull(MstrngAcpRa, 0) + isnull(MstrngAcpAgFee, 0) + isnull(MstrngAcpRalp, 0) + isnull(MstrngAcpStor, 0) + isnull(MstrngAcpControl, 0) + isnull(MstrngAcpMnrl, 0) as MasteringAccp
					, isnull(MstrngPrsRaMn, 0) + isnull(MstrngPrsAgFeeMn, 0) + isnull(MstrngPrsRalpMn, 0) + isnull(MstrngAcpStorMn, 0) + isnull(MstrngAcpControlMn, 0) + isnull(MstrngAcpMnrlMn, 0) as MasteringPresMn
					, isnull(MstrngAcpRaMn, 0) + isnull(MstrngAcpAgFeeMn, 0) + isnull(MstrngAcpRalpMn, 0) + isnull(MstrngAcpStorMn, 0) + isnull(MstrngAcpControlMn, 0) + isnull(MstrngAcpMnrlMn, 0) as MasteringAccpMn
				from
					(
						select 
							d.dAll
							, z.ipgcrKey, z.ipgcrChain, z.ipgcrIpg, z.ipgcrUtPlGr, z.ipgpKey, z.ipgpSh, z.iuplgKey, z.iuplgpPl, z.iuplpKey
							, z.ipgpCstAgPn, a.cstaAg, z.mKey, z.smm, z.smmTtl, z.lim, z.pct
							, z.iuplpSubAg -- 17.10.2023 добавил филиал
							, iif (z.ipgpCstAgPn is null, null, ags.fnMasteringPresRa(d.dAll, @cstAgPn, @StCostKey, @stNet, isnull(z.iuplpSubAg, 0))) as MstrngPrsRa -- функция с филиалом 01.11.2023
							, iif (z.ipgpCstAgPn is null, null, ags.fnMasteringAccpRa(d.dAll, @cstAgPn, @StCostKey, @stNet, isnull(z.iuplpSubAg, 0))) as MstrngAcpRa -- функция с филиалом 01.11.2023
							, iif (z.ipgpCstAgPn is null, null, ags.fnMasteringPresRaMn(d.dAll, @cstAgPn, @StCostKey, @stNet, isnull(z.iuplpSubAg, 0))) as MstrngPrsRaMn -- функция с филиалом 10.11.2023
							, iif (z.ipgpCstAgPn is null, null, ags.fnMasteringAccpRaMn(d.dAll, @cstAgPn, @StCostKey, @stNet, isnull(z.iuplpSubAg, 0))) as MstrngAcpRaMn -- функция с филиалом 13.11.2023
							, iif (z.ipgpCstAgPn is null, null, ags.fnMasteringPresAgFee(d.dAll, @cstAgPn, @StCostKey, @stNet)) as MstrngPrsAgFee
							, iif (z.ipgpCstAgPn is null, null, ags.fnMasteringAccpAgFee(d.dAll, @cstAgPn, @StCostKey, @stNet)) as MstrngAcpAgFee
							, iif (z.ipgpCstAgPn is null, null, ags.fnMasteringPresAgFeeMn(d.dAll, @cstAgPn, @StCostKey, @stNet)) as MstrngPrsAgFeeMn
							, iif (z.ipgpCstAgPn is null, null, ags.fnMasteringAccpAgFeeMn(d.dAll, @cstAgPn, @StCostKey, @stNet)) as MstrngAcpAgFeeMn
							, iif (z.ipgpCstAgPn is null, null, ags.fnMasteringPresRalp(d.dAll, @cstAgPn, @StCostKey, @stNet)) as MstrngPrsRalp
							, iif (z.ipgpCstAgPn is null, null, ags.fnMasteringAccpRalp(d.dAll, @cstAgPn, @StCostKey, @stNet)) as MstrngAcpRalp
							, iif (z.ipgpCstAgPn is null, null, ags.fnMasteringPresRalpMn(d.dAll, @cstAgPn, @StCostKey, @stNet)) as MstrngPrsRalpMn
							, iif (z.ipgpCstAgPn is null, null, ags.fnMasteringAccpRalpMn(d.dAll, @cstAgPn, @StCostKey, @stNet)) as MstrngAcpRalpMn
							, iif (z.ipgpCstAgPn is null, null, ags.fnMasteringAccpStor(d.dAll, @cstAgPn, @StCostKey, @stNet)) as MstrngAcpStor
							, iif (z.ipgpCstAgPn is null, null, ags.fnMasteringAccpStorMn(d.dAll, @cstAgPn, @StCostKey, @stNet)) as MstrngAcpStorMn
							, iif (z.ipgpCstAgPn is null, null, ags.fnMasteringAccpControl(d.dAll, @cstAgPn, @StCostKey, @stNet)) as MstrngAcpControl
							, iif (z.ipgpCstAgPn is null, null, ags.fnMasteringAccpControlMn(d.dAll, @cstAgPn, @StCostKey, @stNet)) as MstrngAcpControlMn
							, iif (z.ipgpCstAgPn is null, null, ags.fnMasteringAccpMnrl(d.dAll, @cstAgPn, @StCostKey, @stNet)) as MstrngAcpMnrl
							, iif (z.ipgpCstAgPn is null, null, ags.fnMasteringAccpMnrlMn(d.dAll, @cstAgPn, @StCostKey, @stNet)) as MstrngAcpMnrlMn
						from 
							ags.fnIpgChDatsV(@ipgCh) d
								left join
									(
										select *
										from ags.fnStCostRsCstAgPn_2606(@ipgCh, @cstAgPn, @ipgSh, @StCostKey, @stNet, @ipgRoot) f
									) as z on d.dAll = z.dd
									left join ags.cstAgPn c on z.ipgpCstAgPn = c.cstapKey
										left join ags.cstAg a on c.cstapCsta = a.cstaKey
					) as y
			) as x
	else
		-- нет, отображать освоение для стройки данной схемы не нужно
		insert into @TablRslt 
			(
				dAll, ipgcrKey, ipgcrChain, ipgcrIpg, ipgcrUtPlGr, ipgpKey, ipgpSh, iuplgKey, iuplgpPl, iuplpKey, ipgpCstAgPn, cstaAg, mKey
				, smm, smmTtl, lim, pct
				, iuplpSubAg -- 17.10.2023 добавил филиал
				, MstrngPrsRa, MstrngAcpRa, MstrngPrsRaMn, MstrngAcpRaMn
				, MstrngPrsAgFee, MstrngAcpAgFee, MstrngPrsAgFeeMn, MstrngAcpAgFeeMn
				, MstrngPrsRalp, MstrngAcpRalp, MstrngPrsRalpMn, MstrngAcpRalpMn
				, MstrngAcpStor, MstrngAcpStorMn, MstrngAcpControl, MstrngAcpControlMn
				, MstrngAcpMnrl, MstrngAcpMnrlMn
				, MasteringPres, MasteringAccp, MasteringPresMn, MasteringAccpMn
				, planCompleted, planCompletedNot, planCompletedOver
				, limNot, limOver
			)
		select
			x.dAll, x.ipgcrKey, x.ipgcrChain, x.ipgcrIpg, x.ipgcrUtPlGr, x.ipgpKey, x.ipgpSh, x.iuplgKey, x.iuplgpPl, x.iuplpKey, x.ipgpCstAgPn, x.cstaAg, x.mKey
			, x.smm, x.smmTtl, x.lim, x.pct
			, x.iuplpSubAg -- 17.10.2023 добавил филиал
			, x.MstrngPrsRa, x.MstrngAcpRa, x.MstrngPrsRaMn, x.MstrngAcpRaMn
			, x.MstrngPrsAgFee, x.MstrngAcpAgFee, x.MstrngPrsAgFeeMn, x.MstrngAcpAgFeeMn
			, x.MstrngPrsRalp, x.MstrngAcpRalp, x.MstrngPrsRalpMn, x.MstrngAcpRalpMn
			, x.MstrngAcpStor, x.MstrngAcpStorMn, x.MstrngAcpControl, x.MstrngAcpControlMn
			, x.MstrngAcpMnrl, x.MstrngAcpMnrlMn
			, x.MasteringPres, x.MasteringAccp, x.MasteringPresMn, x.MasteringAccpMn
			, 0 as planCompleted -- выполнено из плана
			, 0 as planCompletedNot -- не выполнено из плана
			, 0 as planCompletedOver -- перевыполнено из плана
			, isnull(x.lim, 0) as limNot -- остаток лимита
			, 0 as limOver -- превышение лимита
		from
			(
				select
					y.*
					, null as MasteringPres , null as MasteringAccp , null as MasteringPresMn , null as MasteringAccpMn
				from
					(
						select 
							d.dAll
							, z.ipgcrKey, z.ipgcrChain, z.ipgcrIpg, z.ipgcrUtPlGr, z.ipgpKey, z.ipgpSh, z.iuplgKey, z.iuplgpPl, z.iuplpKey
							, z.ipgpCstAgPn, a.cstaAg, z.mKey, z.smm, z.smmTtl, z.lim, z.pct
							, z.iuplpSubAg -- 17.10.2023 добавил филиал
							, null as MstrngPrsRa, null as MstrngAcpRa, null as MstrngPrsRaMn, null as MstrngAcpRaMn
							, null as MstrngPrsAgFee, null as MstrngAcpAgFee, null as MstrngPrsAgFeeMn, null as MstrngAcpAgFeeMn
							, null as MstrngPrsRalp, null as MstrngAcpRalp, null as MstrngPrsRalpMn, null as MstrngAcpRalpMn
							, null as MstrngAcpStor, null as MstrngAcpStorMn, null as MstrngAcpControl, null as MstrngAcpControlMn
							, null as MstrngAcpMnrl, null as MstrngAcpMnrlMn
						from 
							ags.fnIpgChDatsV(@ipgCh) d
								left join
									(
										select *
										from ags.fnStCostRsCstAgPn_2606(@ipgCh, @cstAgPn, @ipgSh, @StCostKey, @stNet, @ipgRoot) f
									) as z on d.dAll = z.dd
									left join ags.cstAgPn c on z.ipgpCstAgPn = c.cstapKey
										left join ags.cstAg a on c.cstapCsta = a.cstaKey
					) as y
			) as x
	
	RETURN 
END

GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'ags.fnMasteringCstAgPnSh_2606', N'TF') IS NOT NULL
    DROP FUNCTION ags.fnMasteringCstAgPnSh_2606;
GO

CREATE FUNCTION ags.fnMasteringCstAgPnSh_2606 
(
	@ipgCh int			-- цепь инвестиционных программ
	, @cstAgPn int		-- стройка (стройка-агент-код)
	, @StCostKey int	-- пункт структуры стоимости
	, @stNet int		-- схема структуры стоимости
	, @ipgRoot int		-- пункт структуры инвестиционной программы, в контексте которого рассматривается стройка
)
RETURNS 
	-- объявляем возвращаемую табличку результата
	@TablRslt TABLE 
		(
			dAll date, ipgcrKey int, ipgcrChain int, ipgcrIpg int, ipgcrUtPlGr int, ipgpKey int, ipgpSh int, iuplgKey int, iuplgpPl int, iuplpKey int, ipgpCstAgPn int, cstaAg int, mKey int
			, iuplpSubAg int -- 17.10.2023 добавил филиал агента
			-- агентская схема
			, agSmm money, agSmmTtl money, agLim money, agPct money
			, agMstrngPrsRa money, agMstrngAcpRa money, agMstrngPrsRaMn money, agMstrngAcpRaMn money
			, agMstrngPrsAgFee money, agMstrngAcpAgFee money, agMstrngPrsAgFeeMn money, agMstrngAcpAgFeeMn money
			, agMstrngPrsRalp money, agMstrngAcpRalp money, agMstrngPrsRalpMn money, agMstrngAcpRalpMn money
			, agMstrngAcpStor money, agMstrngAcpStorMn money, agMstrngAcpControl money, agMstrngAcpControlMn money
			, agMstrngAcpMnrl money, agMstrngAcpMnrlMn money
			, agMasteringPres money, agMasteringAccp money, agMasteringPresMn money, agMasteringAccpMn money
			, agPlanCompleted money, agPlanCompletedNot money, agPlanCompletedOver money
			, aglimNot money, aglimOver money
			-- инвестиционная схема
			, inSmm money, inSmmTtl money, inLim money, inPct money
			, inMstrngPrsRa money, inMstrngAcpRa money, inMstrngPrsRaMn money, inMstrngAcpRaMn money
			, inMstrngPrsAgFee money, inMstrngAcpAgFee money, inMstrngPrsAgFeeMn money, inMstrngAcpAgFeeMn money
			, inMstrngPrsRalp money, inMstrngAcpRalp money, inMstrngPrsRalpMn money, inMstrngAcpRalpMn money
			, inMstrngAcpStor money, inMstrngAcpStorMn money, inMstrngAcpControl money, inMstrngAcpControlMn money
			, inMstrngAcpMnrl money, inMstrngAcpMnrlMn money
			, inMasteringPres money, inMasteringAccp money, inMasteringPresMn money, inMasteringAccpMn money
			, inPlanCompleted money, inPlanCompletedNot money, inPlanCompletedOver money
			, inlimNot money, inlimOver money
			-- другая схема
			, drSmm money, drSmmTtl money, drLim money, drPct money
			, drMstrngPrsRa money, drMstrngAcpRa money, drMstrngPrsRaMn money, drMstrngAcpRaMn money
			, drMstrngPrsAgFee money, drMstrngAcpAgFee money, drMstrngPrsAgFeeMn money, drMstrngAcpAgFeeMn money
			, drMstrngPrsRalp money, drMstrngAcpRalp money, drMstrngPrsRalpMn money, drMstrngAcpRalpMn money
			, drMstrngAcpStor money, drMstrngAcpStorMn money, drMstrngAcpControl money, drMstrngAcpControlMn money
			, drMstrngAcpMnrl money, drMstrngAcpMnrlMn money
			, drMasteringPres money, drMasteringAccp money, drMasteringPresMn money, drMasteringAccpMn money
			, drPlanCompleted money, drPlanCompletedNot money, drPlanCompletedOver money
			, drlimNot money, drlimOver money
		)
AS
BEGIN
	declare @ShType int -- пременная, для определения к какой схеме присоединять освоение

	set @ShType = 
		( -- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			select
				min(x.toShNum) as toShNumGr
			from
				(
					select
						y.*
						, case
							when y.rslt = 'агентская, инвестиционная и другая' then '1. К агентской'
							when y.rslt = 'агентская и инвестиционная' then '1. К агентской'
							when y.rslt = 'агентская и другая' then '1. К агентской'
							when y.rslt = 'агентская' then '1. К агентской'
							when y.rslt = 'инвестиционная и другая' then '2. К инвестиционной'
							when y.rslt = 'инвестиционная' then '2. К инвестиционной'
							when y.rslt = 'другая' then '3. К другой'
							end as toSh -- определяем к какой схеме присоединяем освоение
						, case
							when y.rslt = 'агентская, инвестиционная и другая' then 1
							when y.rslt = 'агентская и инвестиционная' then 1
							when y.rslt = 'агентская и другая' then 1
							when y.rslt = 'агентская' then 1
							when y.rslt = 'инвестиционная и другая' then 2
							when y.rslt = 'инвестиционная' then 2
							when y.rslt = 'другая' then 3
							end as toShNum -- определяем к какой схеме присоединяем освоение, число
					from
						(
							select
								pvt.*
								, iif
									(
										pvt.[1] = 1,
										iif
											(
												pvt.[2] = 1 ,
												iif(pvt.[3] = 1, 'агентская, инвестиционная и другая', 'агентская и инвестиционная'),
												iif(pvt.[3] = 1, 'инвестиционная и другая', 'инвестиционная')
											),
										iif
											(
												pvt.[2] = 1 ,
												iif(pvt.[3] = 1, 'агентская и другая', 'агентская'),
												iif(pvt.[3] = 1, 'другая', 'не может быть, чтобы схем не было')
											)
									) rslt
							from
								(
									select
										v.ipgcrvChain AS ipgcrChain, p.ipgpIpg, p.ipgpCstAgPn, p.ipgpSh, 1 AS ccc
									from
										ags.ipgPn p
											INNER JOIN ags.ipgChRlV v ON p.ipgpIpg = v.ipgcrvIpg
									where
										p.ipgpCstAgPn = @cstAgPn AND v.ipgcrvChain = @ipgCh
									group by
										v.ipgcrvChain, p.ipgpIpg, p.ipgpCstAgPn, p.ipgpSh
								) as z
								PIVOT (SUM(z.ccc) FOR z.ipgpSh IN ([1],[2],[3])) AS PVT
						) as y
				) as x
			group by
				x.ipgcrChain, x.ipgpCstAgPn
		) -- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	--select * from ags.fnMasteringCstAgPn_2606(@ipgCh, @cstAgPn, 1, @StCostKey, @stNet) f

	if @ShType = 1 -- это к агентской схеме
			insert into @TablRslt
				(
					dAll, ipgcrKey, ipgcrChain, ipgcrIpg, ipgcrUtPlGr, ipgpKey, ipgpSh, iuplgKey, iuplgpPl, iuplpKey, ipgpCstAgPn, cstaAg, mKey
					, iuplpSubAg -- 17.10.2023 добавил филиал агента
					, agSmm, agSmmTtl, agLim, agPct
					, agMstrngPrsRa, agMstrngAcpRa, agMstrngPrsRaMn, agMstrngAcpRaMn
					, agMstrngPrsAgFee, agMstrngAcpAgFee, agMstrngPrsAgFeeMn, agMstrngAcpAgFeeMn
					, agMstrngPrsRalp, agMstrngAcpRalp, agMstrngPrsRalpMn, agMstrngAcpRalpMn
					, agMstrngAcpStor, agMstrngAcpStorMn, agMstrngAcpControl, agMstrngAcpControlMn
					, agMstrngAcpMnrl, agMstrngAcpMnrlMn
					, agMasteringPres, agMasteringAccp, agMasteringPresMn, agMasteringAccpMn
					, agPlanCompleted, agPlanCompletedNot, agPlanCompletedOver
					, aglimNot, aglimOver
					-- инвестиционная схема
					, inSmm, inSmmTtl, inLim, inPct
					, inMstrngPrsRa, inMstrngAcpRa, inMstrngPrsRaMn, inMstrngAcpRaMn
					, inMstrngPrsAgFee, inMstrngAcpAgFee, inMstrngPrsAgFeeMn, inMstrngAcpAgFeeMn
					, inMstrngPrsRalp, inMstrngAcpRalp, inMstrngPrsRalpMn, inMstrngAcpRalpMn
					, inMstrngAcpStor, inMstrngAcpStorMn, inMstrngAcpControl, inMstrngAcpControlMn
					, inMstrngAcpMnrl, inMstrngAcpMnrlMn
					, inMasteringPres, inMasteringAccp, inMasteringPresMn, inMasteringAccpMn
					, inPlanCompleted, inPlanCompletedNot, inPlanCompletedOver
					, inlimNot, inlimOver
					-- другая схема
					, drSmm, drSmmTtl, drLim, drPct
					, drMstrngPrsRa, drMstrngAcpRa, drMstrngPrsRaMn, drMstrngAcpRaMn
					, drMstrngPrsAgFee, drMstrngAcpAgFee, drMstrngPrsAgFeeMn, drMstrngAcpAgFeeMn
					, drMstrngPrsRalp, drMstrngAcpRalp, drMstrngPrsRalpMn, drMstrngAcpRalpMn
					, drMstrngAcpStor, drMstrngAcpStorMn, drMstrngAcpControl, drMstrngAcpControlMn
					, drMstrngAcpMnrl, drMstrngAcpMnrlMn
					, drMasteringPres, drMasteringAccp, drMasteringPresMn, drMasteringAccpMn
					, drPlanCompleted, drPlanCompletedNot, drPlanCompletedOver
					, drlimNot, drlimOver
				)
			select 
				a.dAll, a.ipgcrKey, a.ipgcrChain, a.ipgcrIpg, a.ipgcrUtPlGr, a.ipgpKey, a.ipgpSh, a.iuplgKey, a.iuplgpPl, a.iuplpKey, a.ipgpCstAgPn, a.cstaAg, a.mKey
				, a.iuplpSubAg -- 17.10.2023 добавил филиал агента
				-- агентская схема
				, a.smm as agSmm, a.smmTtl as agSmmTtl, a.lim as agLim, a.pct as agPct
				, a.MstrngPrsRa as agMstrngPrsRa, a.MstrngAcpRa as agMstrngAcpRa, a.MstrngPrsRaMn as agMstrngPrsRaMn, a.MstrngAcpRaMn as agMstrngAcpRaMn
				, a.MstrngPrsAgFee as agMstrngPrsAgFee, a.MstrngAcpAgFee as agMstrngAcpAgFee, a.MstrngPrsAgFeeMn as agMstrngPrsAgFeeMn, a.MstrngAcpAgFeeMn as agMstrngAcpAgFeeMn
				, a.MstrngPrsRalp as agMstrngPrsRalp, a.MstrngAcpRalp as agMstrngAcpRalp, a.MstrngPrsRalpMn as agMstrngPrsRalpMn, a.MstrngAcpRalpMn as agMstrngAcpRalpMn
				, a.MstrngAcpStor as agMstrngAcpStor, a.MstrngAcpStorMn as agMstrngAcpStorMn, a.MstrngAcpControl as agMstrngAcpControl, a.MstrngAcpControlMn as agMstrngAcpControlMn
				, a.MstrngAcpMnrl as agMstrngAcpMnrl, a.MstrngAcpMnrlMn as agMstrngAcpMnrlMn
				, a.MasteringPres as agMasteringPres, a.MasteringAccp as agMasteringAccp, a.MasteringPresMn as agMasteringPresMn, a.MasteringAccpMn as agMasteringAccpMn
				, a.planCompleted as agPlanCompleted, a.planCompletedNot as agPlanCompletedNot, a.planCompletedOver as agPlanCompletedOver
				, a.limNot as aglimNot, a.limOver as aglimOver
				-- инвестиционная схема
				, i.smm as inSmm, i.smmTtl as inSmmTtl, i.lim as inLim, i.pct as inPct
				, null as inMstrngPrsRa, null as inMstrngAcpRa, null as inMstrngPrsRaMn, null as inMstrngAcpRaMn
				, null as inMstrngPrsAgFee, null as inMstrngAcpAgFee, null as inMstrngPrsAgFeeMn, null as inMstrngAcpAgFeeMn
				, null as inMstrngPrsRalp, null as inMstrngAcpRalp, null as inMstrngPrsRalpMn, null as inMstrngAcpRalpMn
				, null as inMstrngAcpStor, null as inMstrngAcpStorMn, null as inMstrngAcpControl, null as inMstrngAcpControlMn
				, null as inMstrngAcpMnrl, null as inMstrngAcpMnrlMn
				, null as inMasteringPres, null as inMasteringAccp, null as inMasteringPresMn, null as inMasteringAccpMn
				, 0 as inPlanCompleted, 0 as inPlanCompletedNot, 0 as inPlanCompletedOver
				, isnull(i.lim, 0) as inlimNot, 0 as inlimOver
				-- другая схема
				, d.smm as drSmm, d.smmTtl as drSmmTtl, d.lim as drLim, d.pct as drPct
				, null as drMstrngPrsRa, null as drMstrngAcpRa, null as drMstrngPrsRaMn, null as drMstrngAcpRaMn
				, null as drMstrngPrsAgFee, null as drMstrngAcpAgFee, null as drMstrngPrsAgFeeMn, null as drMstrngAcpAgFeeMn
				, null as drMstrngPrsRalp, null as drMstrngAcpRalp, null as drMstrngPrsRalpMn, null as drMstrngAcpRalpMn
				, null as drMstrngAcpStor, null as drMstrngAcpStorMn, null as drMstrngAcpControl, null as drMstrngAcpControlMn
				, null as drMstrngAcpMnrl, null as drMstrngAcpMnrlMn
				, null as drMasteringPres, null as drMasteringAccp, null as drMasteringPresMn, null as drMasteringAccpMn
				, 0 as drPlanCompleted, 0 as drPlanCompletedNot, 0 as drPlanCompletedOver
				, isnull(d.lim, 0) as drlimNot, 0 as drlimOver
			from ags.fnMasteringCstAgPn_2606(@ipgCh, @cstAgPn, 2, @StCostKey, @stNet, @ipgRoot) a
				left join
					ags.fnMasteringCstAgPn_2606(@ipgCh, @cstAgPn, 1, @StCostKey, @stNet, @ipgRoot) i on a.dAll = i.dAll and (a.iuplpSubAg = i.iuplpSubAg or (a.iuplpSubAg is null and i.iuplpSubAg is null))
				left join
					ags.fnMasteringCstAgPn_2606(@ipgCh, @cstAgPn, 3, @StCostKey, @stNet, @ipgRoot) d on a.dAll = d.dAll and (a.iuplpSubAg = d.iuplpSubAg or (a.iuplpSubAg is null and d.iuplpSubAg is null))
		else
			begin
				if @ShType = 2 -- это к инвестиционной схеме. Берем только инвестиционную (с освоением, если есть) и другую (только лимиты)
					insert into @TablRslt
						(
							dAll, ipgcrKey, ipgcrChain, ipgcrIpg, ipgcrUtPlGr, ipgpKey, ipgpSh, iuplgKey, iuplgpPl, iuplpKey, ipgpCstAgPn, cstaAg, mKey
							, a.iuplpSubAg -- 17.10.2023 добавил филиал агента
							, agSmm, agSmmTtl, agLim, agPct
							, agMstrngPrsRa, agMstrngAcpRa, agMstrngPrsRaMn, agMstrngAcpRaMn
							, agMstrngPrsAgFee, agMstrngAcpAgFee, agMstrngPrsAgFeeMn, agMstrngAcpAgFeeMn
							, agMstrngPrsRalp, agMstrngAcpRalp, agMstrngPrsRalpMn, agMstrngAcpRalpMn
							, agMstrngAcpStor, agMstrngAcpStorMn, agMstrngAcpControl, agMstrngAcpControlMn
							, agMstrngAcpMnrl, agMstrngAcpMnrlMn
							, agMasteringPres, agMasteringAccp, agMasteringPresMn, agMasteringAccpMn
							, agPlanCompleted, agPlanCompletedNot, agPlanCompletedOver
							, aglimNot, aglimOver
							-- инвестиционная схема
							, inSmm, inSmmTtl, inLim, inPct
							, inMstrngPrsRa, inMstrngAcpRa, inMstrngPrsRaMn, inMstrngAcpRaMn
							, inMstrngPrsAgFee, inMstrngAcpAgFee, inMstrngPrsAgFeeMn, inMstrngAcpAgFeeMn
							, inMstrngPrsRalp, inMstrngAcpRalp, inMstrngPrsRalpMn, inMstrngAcpRalpMn
							, inMstrngAcpStor, inMstrngAcpStorMn, inMstrngAcpControl, inMstrngAcpControlMn
							, inMstrngAcpMnrl, inMstrngAcpMnrlMn
							, inMasteringPres, inMasteringAccp, inMasteringPresMn, inMasteringAccpMn
							, inPlanCompleted, inPlanCompletedNot, inPlanCompletedOver
							, inlimNot, inlimOver
							-- другая схема
							, drSmm, drSmmTtl, drLim, drPct
							, drMstrngPrsRa, drMstrngAcpRa, drMstrngPrsRaMn, drMstrngAcpRaMn
							, drMstrngPrsAgFee, drMstrngAcpAgFee, drMstrngPrsAgFeeMn, drMstrngAcpAgFeeMn
							, drMstrngPrsRalp, drMstrngAcpRalp, drMstrngPrsRalpMn, drMstrngAcpRalpMn
							, drMstrngAcpStor, drMstrngAcpStorMn, drMstrngAcpControl, drMstrngAcpControlMn
							, drMstrngAcpMnrl, drMstrngAcpMnrlMn
							, drMasteringPres, drMasteringAccp, drMasteringPresMn, drMasteringAccpMn
							, drPlanCompleted, drPlanCompletedNot, drPlanCompletedOver
							, drlimNot, drlimOver
						)
					select 
						i.dAll, i.ipgcrKey, i.ipgcrChain, i.ipgcrIpg, i.ipgcrUtPlGr, i.ipgpKey, i.ipgpSh, i.iuplgKey, i.iuplgpPl, i.iuplpKey, i.ipgpCstAgPn, i.cstaAg, i.mKey
						, i.iuplpSubAg -- 17.10.2023 добавил филиал агента
						-- агентская схема
						, null as agSmm, null as agSmmTtl, null as agLim, null as agPct
						, null as agMstrngPrsRa, null as agMstrngAcpRa, null as agMstrngPrsRaMn, null as agMstrngAcpRaMn
						, null as agMstrngPrsAgFee, null as agMstrngAcpAgFee, null as agMstrngPrsAgFeeMn, null as agMstrngAcpAgFeeMn
						, null as agMstrngPrsRalp, null as agMstrngAcpRalp, null as agMstrngPrsRalpMn, null as agMstrngAcpRalpMn
						, null as agMstrngAcpStor, null as agMstrngAcpStorMn, null as agMstrngAcpControl, null as agMstrngAcpControlMn
						, null as agMstrngAcpMnrl, null as agMstrngAcpMnrlMn
						, null as agMasteringPres, null as agMasteringAccp, null as agMasteringPresMn, null as agMasteringAccpMn
						, 0 as agPlanCompleted, 0 as agPlanCompletedNot, 0 as agPlanCompletedOver
						, 0 as aglimNot, 0 as aglimOver
						-- инвестиционная схема
						, i.smm as inSmm, i.smmTtl as inSmmTtl, i.lim as agLim, i.pct as inPct
						, i.MstrngPrsRa as inMstrngPrsRa, i.MstrngAcpRa as inMstrngAcpRa, i.MstrngPrsRaMn as inMstrngPrsRaMn, i.MstrngAcpRaMn as inMstrngAcpRaMn
						, i.MstrngPrsAgFee as inMstrngPrsAgFee, i.MstrngAcpAgFee as inMstrngAcpAgFee, i.MstrngPrsAgFeeMn as inMstrngPrsAgFeeMn, i.MstrngAcpAgFeeMn as inMstrngAcpAgFeeMn
						, i.MstrngPrsRalp as inMstrngPrsRalp, i.MstrngAcpRalp as inMstrngAcpRalp, i.MstrngPrsRalpMn as inMstrngPrsRalpMn, i.MstrngAcpRalpMn as inMstrngAcpRalpMn
						, i.MstrngAcpStor as inMstrngAcpStor, i.MstrngAcpStorMn as inMstrngAcpStorMn, i.MstrngAcpControl as inMstrngAcpControl, i.MstrngAcpControlMn as inMstrngAcpControlMn
						, i.MstrngAcpMnrl as inMstrngAcpMnrl, i.MstrngAcpMnrlMn as inMstrngAcpMnrlMn
						, i.MasteringPres as inMasteringPres, i.MasteringAccp as inMasteringAccp, i.MasteringPresMn as inMasteringPresMn, i.MasteringAccpMn as inMasteringAccpMn
						, i.planCompleted as inPlanCompleted, i.planCompletedNot as inPlanCompletedNot, i.planCompletedOver as inPlanCompletedOver
						, i.limNot as inlimNot, i.limOver as inlimOver
						-- другая схема
						, d.smm as drSmm, d.smmTtl as drSmmTtl, d.lim as drLim, d.pct as drPct
						, null as drMstrngPrsRa, null as drMstrngAcpRa, null as drMstrngPrsRaMn, null as drMstrngAcpRaMn
						, null as drMstrngPrsAgFee, null as drMstrngAcpAgFee, null as drMstrngPrsAgFeeMn, null as drMstrngAcpAgFeeMn
						, null as drMstrngPrsRalp, null as drMstrngAcpRalp, null as drMstrngPrsRalpMn, null as drMstrngAcpRalpMn
						, null as drMstrngAcpStor, null as drMstrngAcpStorMn, null as drMstrngAcpControl, null as drMstrngAcpControlMn
						, null as drMstrngAcpMnrl, null as drMstrngAcpMnrlMn
						, null as drMasteringPres, null as drMasteringAccp, null as drMasteringPresMn, null as drMasteringAccpMn
						, 0 as drPlanCompleted, 0 as drPlanCompletedNot, 0 as drPlanCompletedOver
						, isnull(d.lim, 0) as drlimNot, 0 as drlimOver
					from ags.fnMasteringCstAgPn_2606(@ipgCh, @cstAgPn, 1, @StCostKey, @stNet, @ipgRoot) i
						left join
							ags.fnMasteringCstAgPn_2606(@ipgCh, @cstAgPn, 3, @StCostKey, @stNet, @ipgRoot) d on i.dAll = d.dAll and (i.iuplpSubAg = d.iuplpSubAg or (i.iuplpSubAg is null and d.iuplpSubAg is null))
					else
					-- это к другой схеме. Берем только другую (с освоением, если есть)
					insert into @TablRslt
						(
							dAll, ipgcrKey, ipgcrChain, ipgcrIpg, ipgcrUtPlGr, ipgpKey, ipgpSh, iuplgKey, iuplgpPl, iuplpKey, ipgpCstAgPn, cstaAg, mKey
							, iuplpSubAg -- 17.10.2023 добавил филиал агента
							-- агентская схема
							, agSmm, agSmmTtl, agLim, agPct
							, agMstrngPrsRa, agMstrngAcpRa, agMstrngPrsRaMn, agMstrngAcpRaMn
							, agMstrngPrsAgFee, agMstrngAcpAgFee, agMstrngPrsAgFeeMn, agMstrngAcpAgFeeMn
							, agMstrngPrsRalp, agMstrngAcpRalp, agMstrngPrsRalpMn, agMstrngAcpRalpMn
							, agMstrngAcpStor, agMstrngAcpStorMn, agMstrngAcpControl, agMstrngAcpControlMn
							, agMstrngAcpMnrl, agMstrngAcpMnrlMn
							, agMasteringPres, agMasteringAccp, agMasteringPresMn, agMasteringAccpMn
							, agPlanCompleted, agPlanCompletedNot, agPlanCompletedOver
							, aglimNot, aglimOver
							-- инвестиционная схема
							, inSmm, inSmmTtl, inLim, inPct
							, inMstrngPrsRa, inMstrngAcpRa, inMstrngPrsRaMn, inMstrngAcpRaMn
							, inMstrngPrsAgFee, inMstrngAcpAgFee, inMstrngPrsAgFeeMn, inMstrngAcpAgFeeMn
							, inMstrngPrsRalp, inMstrngAcpRalp, inMstrngPrsRalpMn, inMstrngAcpRalpMn
							, inMstrngAcpStor, inMstrngAcpStorMn, inMstrngAcpControl, inMstrngAcpControlMn
							, inMstrngAcpMnrl, inMstrngAcpMnrlMn
							, inMasteringPres, inMasteringAccp, inMasteringPresMn, inMasteringAccpMn
							, inPlanCompleted, inPlanCompletedNot, inPlanCompletedOver
							, inlimNot, inlimOver
							-- другая схема
							, drSmm, drSmmTtl, drLim, drPct
							, drMstrngPrsRa, drMstrngAcpRa, drMstrngPrsRaMn, drMstrngAcpRaMn
							, drMstrngPrsAgFee, drMstrngAcpAgFee, drMstrngPrsAgFeeMn, drMstrngAcpAgFeeMn
							, drMstrngPrsRalp, drMstrngAcpRalp, drMstrngPrsRalpMn, drMstrngAcpRalpMn
							, drMstrngAcpStor, drMstrngAcpStorMn, drMstrngAcpControl, drMstrngAcpControlMn
							, drMstrngAcpMnrl, drMstrngAcpMnrlMn
							, drMasteringPres, drMasteringAccp, drMasteringPresMn, drMasteringAccpMn
							, drPlanCompleted, drPlanCompletedNot, drPlanCompletedOver
							, drlimNot, drlimOver
						)
					select 
						d.dAll, d.ipgcrKey, d.ipgcrChain, d.ipgcrIpg, d.ipgcrUtPlGr, d.ipgpKey, d.ipgpSh, d.iuplgKey, d.iuplgpPl, d.iuplpKey, d.ipgpCstAgPn, d.cstaAg, d.mKey
						, d.iuplpSubAg -- 17.10.2023 добавил филиал агента
						-- агентская схема
						, null as agSmm, null as agSmmTtl, null as agLim, null as agPct
						, null as agMstrngPrsRa, null as agMstrngAcpRa, null as agMstrngPrsRaMn, null as agMstrngAcpRaMn
						, null as agMstrngPrsAgFee, null as agMstrngAcpAgFee, null as agMstrngPrsAgFeeMn, null as agMstrngAcpAgFeeMn
						, null as agMstrngPrsRalp, null as agMstrngAcpRalp, null as agMstrngPrsRalpMn, null as agMstrngAcpRalpMn
						, null as agMstrngAcpStor, null as agMstrngAcpStorMn, null as agMstrngAcpControl, null as agMstrngAcpControlMn
						, null as agMstrngAcpMnrl, null as agMstrngAcpMnrlMn
						, null as agMasteringPres, null as agMasteringAccp, null as agMasteringPresMn, null as agMasteringAccpMn
						, 0 as agPlanCompleted, 0 as agPlanCompletedNot, 0 as agPlanCompletedOver
						, 0 as aglimNot, 0 as aglimOver
						-- инвестиционная схема
						, null as inSmm, null as inSmmTtl, null as agLim, null as inPct
						, null as inMstrngPrsRa, null as inMstrngAcpRa, null as inMstrngPrsRaMn, null as inMstrngAcpRaMn
						, null as inMstrngPrsAgFee, null as inMstrngAcpAgFee, null as inMstrngPrsAgFeeMn, null as inMstrngAcpAgFeeMn
						, null as inMstrngPrsRalp, null as inMstrngAcpRalp, null as inMstrngPrsRalpMn, null as inMstrngAcpRalpMn
						, null as inMstrngAcpStor, null as inMstrngAcpStorMn, null as inMstrngAcpControl, null as inMstrngAcpControlMn
						, null as inMstrngAcpMnrl, null as inMstrngAcpMnrlMn
						, null as inMasteringPres, null as inMasteringAccp, null as inMasteringPresMn, null as inMasteringAccpMn
						, 0 as inPlanCompleted, 0 as inPlanCompletedNot, 0 as inPlanCompletedOver
						, 0 as inlimNot, 0 as inlimOver
						-- другая схема
						, d.smm as drSmm, d.smmTtl as drSmmTtl, d.lim as drLim, d.pct as drPct
						, d.MstrngPrsRa as drMstrngPrsRa, d.MstrngAcpRa as drMstrngAcpRa, d.MstrngPrsRaMn as drMstrngPrsRaMn, d.MstrngAcpRaMn as drMstrngAcpRaMn
						, d.MstrngPrsAgFee as drMstrngPrsAgFee, d.MstrngAcpAgFee as drMstrngAcpAgFee, d.MstrngPrsAgFeeMn as drMstrngPrsAgFeeMn, d.MstrngAcpAgFeeMn as drMstrngAcpAgFeeMn
						, d.MstrngPrsRalp as drMstrngPrsRalp, d.MstrngAcpRalp as drMstrngAcpRalp, d.MstrngPrsRalpMn as drMstrngPrsRalpMn, d.MstrngAcpRalpMn as drMstrngAcpRalpMn
						, d.MstrngAcpStor as drMstrngAcpStor, d.MstrngAcpStorMn as drMstrngAcpStorMn, d.MstrngAcpControl as drMstrngAcpControl, d.MstrngAcpControlMn as drMstrngAcpControlMn
						, d.MstrngAcpMnrl as drMstrngAcpMnrl, d.MstrngAcpMnrlMn as drMstrngAcpMnrlMn
						, d.MasteringPres as drMasteringPres, d.MasteringAccp as drMasteringAccp, d.MasteringPresMn as drMasteringPresMn, d.MasteringAccpMn as drMasteringAccpMn
						, d.planCompleted as drPlanCompleted, d.planCompletedNot as drPlanCompletedNot, d.planCompletedOver as drPlanCompletedOver
						, d.limNot as drlimNot, d.limOver as inlimOver
					from ags.fnMasteringCstAgPn_2606(@ipgCh, @cstAgPn, 3, @StCostKey, @stNet, @ipgRoot) d
			end	
	RETURN 
END

GO

PRINT '=== 03c MSSQL2012: fnMasteringCstAgPn_2606 / fnMasteringCstAgPnSh_2606 созданы ===';
GO
