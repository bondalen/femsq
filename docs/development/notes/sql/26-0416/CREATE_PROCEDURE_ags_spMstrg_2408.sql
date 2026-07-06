USE [FishEye]
GO

/****** Object:  StoredProcedure [ags].[spMstrg_2408]    Script Date: 16.04.2026 11:56:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ags].[spMstrg_2408] 
	-- ���������
	@ipgCh int,				-- ������������� ���� �������������� ��������
	@MounthEndDate date		-- ������� ���� ������ ��� �������� �������� �����
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- 1.1 ������� ��� ���������� ������� Access ����������� *ipgChRsltPlCstPercent*

	-- ��������� �������� ��� ����� ���������� ������������� �������� *fnIpgChRsltCstUtlPercentBrn_2408*
	declare @TableFnIpgChRsltCstUtlPercentBrn_2408 table
		(
			-- ������� ����� ��� ���� ���������� �������������� �������� ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
			rowNum int, ogNm nvarchar(255), branch int, branchName nvarchar(255), cstAgPnCode nvarchar(255), dateRslt date, ipgChKey int, cstapKey int
			, yKey int, yyyy int, mKey int, mNum int, mCs nvarchar(255), mNm nvarchar(255), mQ nvarchar(255), mHy int -- ����, ���������, ������
			, cstaInvestor int, ogaKey int, ipgKey int, ipgCount int
			-- ������� ����� ��� ���� ���������� �������������� ��������. ��������� :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

			-- ��������� ����� ================================================================================================================================
			, ag_ipgpKey int, ag_iShKey int, ag_ipgpSmTtl money, ag_lim money, ag_Pl money, ag_PlAccum money
			-- ��������� ���������� +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			-- ���� �����
			, ag_PlFulfillment money, ag_PlNonFulfillment_review money , ag_PlNonFulfillment money
			-- ���� ����� ���� �����
			, ag_PlOverFulfillment money, ag_PlRestLimit_review money, ag_PlRestLimit money
			-- ���� �����
			, ag_PlOverLimit money, ag_PlOverLimit_review money
			-- �������� �������� ������
			, ag_LimPercent float, ag_LimPercentInProcess float -- *������� ��������*, �������� *��������� ����� ������*
			, ag_percentDev float, ag_percentDevInProcess float -- *������� ��������*, ������� *��������� ����� ������*
			-- �������� �������� �����
			, ag_PlPercentMinusOverFulf float, ag_PlPercentMinusOverFulfInProcess float -- *������� ���������� �����* ��� *��������������*
			, ag_PlPercent float, ag_PlPercentInProcess float -- *������� ���������� �����* ������� *��������������*
			, ag_percentPlDev float, ag_percentPlDevInProcess float -- *������� ���������� �����* ������� ��, ���� � *����������*
			-- ��������� ����������. ��������� ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				
			-- ��������, ���� � �������� ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			-- ������ ������� ---------------------------------------------------------------------------------------------------------------------------------
			-- ����������� � ����� ����� ......................................................................................................................
			, ag_presentedAll money, ag_presentedAllAccum money -- ����� ����, ��� ����������, ������� �������������� �� �������
			, ag_presentedAllModul money, ag_presentedAllModulAccum money -- ����� ����, ��� ����������, ������� �������������� �� �������, ������ �� ������
			-- ����������� � �������� ���� ....................................................................................................................
			, ag_presented money, ag_presentedAccum money -- ����� *��������������* �������, �������� ��������� � ������� ������� ���
			, ag_accepted money, ag_acceptedAccum money -- ����� *��������* �������, �������� ��������� � ������� ������� ���
			, ag_inProcess money, ag_inProcessAccum money -- ����� *���������������* �������, �������� ��������� � ������� ������� ���
			, ag_returned money, ag_returnedAccum money -- ����� *������������* �������, �������� ��������� � ������� ������� ���
			, ag_notArrived money, ag_notArrivedAccum money -- ����� *�� �����������* �������, �������� ��������� � ������� ������� ���
			-- ����������� � ������� �����. ����������� �� ���� ��������� � ������� ������� ��� ...............................................................
			, ag_presentedPrevYears money, ag_presentedPrevYearsAccum money
			, ag_acceptedPrevYears money, ag_acceptedPrevYearsAccum money
			, ag_inProcessPrevYears money, ag_inProcessPrevYearsAccum money
			, ag_returnedPrevYears money, ag_returnedPrevYearsAccum money
			, ag_notArrivedPrevYears money, ag_notArrivedPrevYearsAccum money
			-- ������ �������. ��������� ---------------------------------------------------------------------------------------------------------------------
			-- ��������� �������������� ----------------------------------------------------------------------------------------------------------------------
			, ag_agFeePresented money, ag_agFeePresentedAccum money, ag_agFeeAccepted money, ag_agFeeAcceptedAccum money -- *��������������* � *��������* ����
			, ag_agFeeInProcess money, ag_agFeeInProcessAccum money, ag_agFeeReturned money, ag_agFeeReturnedAccum money -- *���������������* � *������������* ����
			, ag_agFeeNotArrived money, ag_agFeeNotArrivedAccum money -- *�� �����������* ����
			-- ��������� ������� -----------------------------------------------------------------------------------------------------------------------------
			, ag_presentedRalp money, ag_presentedRalpAccum money, ag_acceptedRalp money, ag_acceptedRalpAccum money -- *��������������* � *��������* ������ ��
			, ag_inProcessRalp money, ag_inProcessRalpAccum money, ag_returnedRalp money, ag_returnedRalpAccum money -- *���������������* � *������������* ������ ��
			, ag_notArrivedRalp money, ag_notArrivedRalpAccum money  -- *�� �����������* ������ ��
			-- ��������, �������������, ��� ------------------------------------------------------------------------------------------------------------------
			, ag_storageSum money, ag_storageSumAccum money, ag_cctSum money, ag_cctSumAccum money, ag_MnrlSum money, ag_MnrlSumAccum money -- *��������* �� ����
			-- ����� -----------------------------------------------------------------------------------------------------------------------------------------
			, ag_presentedTtl money, ag_presentedTtlAccum money -- *������������* �� ���� ����� ��������
			, ag_acceptedTtl money, ag_acceptedTtlAccum money -- *�������* �� ���� ����� ��������
			, ag_restOfLimit money -- ������� ������, ���� �� ���� ������ *�������* �� ���� ����� ��������
			, ag_restOfLimitInProcess money -- ������� ������, ���� �� ���� ������ *�������* �� ���� ����� �������� � ��� ������ *���������������*
			, ag_inProcessTtl money, ag_inProcessTtlAccum money -- *���������������* �� ���� ����� ��������
			, ag_acceptedAndInProcessTtl money, ag_acceptedAndInProcessTtlAccum money -- ����� *�������* � *���������������* �� ���� ����� ��������
			, ag_returnedTtl money, ag_returnedTtlAccum money -- *����������* �� ���� ����� ��������
			, ag_notArrivedTtl money, ag_notArrivedTtlAccum money -- *�� ���������* �� ���� ����� ��������
			-- ��������, ���� � ��������. ��������� +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			-- ��������� �����. ��������� =====================================================================================================================

			-- �������������� ����� (���������, ������) =======================================================================================================
			, iv_ipgpKey int, iv_iShKey int, ia_iShKey int, iv_ipgpSmTtl money, iv_lim money, ia_lim money, iv_Pl money, iv_PlAccum money
			-- ��������� ���������� +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			-- ���� �����
			, iv_PlFulfillment money, iv_PlNonFulfillment_review money, iv_PlNonFulfillment money
			-- ���� ����� ���� ������
			, iv_PlOverFulfillment money, iv_PlRestLimit_review money, iv_PlRestLimit money
			-- ���� ������
			, iv_PlOverLimit money, iv_PlOverLimit_review money
			-- �������� �������� ������
			, iv_LimPercent float, iv_LimPercentInProcess float -- *������� ��������*, �������� *��������� ����� ������*
			, ia_percentDev float, ia_percentDevInProcess float -- *������� ��������*, ������� *��������� ����� ������*
			-- �������� �������� �����
			, iv_PlPercentMinusOverFulf float, iv_PlPercentMinusOverFulfInProcess float -- *������� ���������� �����* ��� *��������������*
			, iv_PlPercent float, iv_PlPercentInProcess float -- *������� ���������� �����* ������� *��������������*
			, ia_percentPlDev float, ia_percentPlDevInProcess float -- *������� ���������� �����* ������� ��, ���� � *����������*
			-- ��������� ����������. ��������� ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			-- �������������� �����. ��������� ================================================================================================================

			-- �������������� ����� (���������, ������) =======================================================================================================
			-- ��������, ���� � �������� ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			-- ������ ������� ---------------------------------------------------------------------------------------------------------------------------------
			-- ����������� � ����� ����� ......................................................................................................................
			, ia_presentedAll money, ia_presentedAllAccum money -- ����� ����, ��� ����������, ������� �������������� �� �������
			, ia_presentedAllModul money, ia_presentedAllModulAccum money -- ����� ����, ��� ����������, ������� �������������� �� �������, ������ �� ������
			-- ����������� � �������� ���� ....................................................................................................................
			, ia_presented money, ia_presentedAccum money -- ����� *��������������* �������, �������� ��������� � ������� ������� ���
			, ia_accepted money, ia_acceptedAccum money -- ����� *��������* �������, �������� ��������� � ������� ������� ���
			, ia_inProcess money, ia_inProcessAccum money -- ����� *���������������* �������, �������� ��������� � ������� ������� ���
			, ia_returned money, ia_returnedAccum money -- ����� *������������* �������, �������� ��������� � ������� ������� ���
			, ia_notArrived money, ia_notArrivedAccum money -- ����� *�� �����������* �������, �������� ��������� � ������� ������� ���
			-- ����������� � ������� �����. ����������� �� ���� ��������� � ������� ������� ��� ...............................................................
			, ia_presentedPrevYears money, ia_presentedPrevYearsAccum money
			, ia_acceptedPrevYears money, ia_acceptedPrevYearsAccum money
			, ia_inProcessPrevYears money, ia_inProcessPrevYearsAccum money
			, ia_returnedPrevYears money, ia_returnedPrevYearsAccum money
			, ia_notArrivedPrevYears money, ia_notArrivedPrevYearsAccum money
			-- ������ �������. ��������� ----------------------------------------------------------------------------------------------------------------------

			-- ��������� �������������� -----------------------------------------------------------------------------------------------------------------------
			, ia_agFeePresented money, ia_agFeePresentedAccum money, ia_agFeeAccepted money, ia_agFeeAcceptedAccum money
			, ia_agFeeInProcess money, ia_agFeeInProcessAccum money
			, ia_agFeeReturned money, ia_agFeeReturnedAccum money
			, ia_agFeeNotArrived money, ia_agFeeNotArrivedAccum money
			-- ��������� ������� ------------------------------------------------------------------------------------------------------------------------------
			, ia_presentedRalp money, ia_presentedRalpAccum money, ia_acceptedRalp money, ia_acceptedRalpAccum money
			, ia_inProcessRalp money, ia_inProcessRalpAccum money
			, ia_returnedRalp money, ia_returnedRalpAccum money
			, ia_notArrivedRalp money, ia_notArrivedRalpAccum money
			-- ��������, �������������, ��� -------------------------------------------------------------------------------------------------------------------
			, ia_storageSum money, ia_storageSumAccum money, ia_cctSum money, ia_cctSumAccum money, ia_MnrlSum money, ia_MnrlSumAccum money
			-- ����� ------------------------------------------------------------------------------------------------------------------------------------------
			, ia_presentedTtl money, ia_presentedTtlAccum money -- *������������* �� ���� ����� ��������
			, ia_acceptedTtl money, ia_acceptedTtlAccum money -- *�������* �� ���� ����� ��������
			, ia_restOfLimit money -- ������� ������, ���� �� ���� ������ *�������* �� ���� ����� ��������
			, ia_restOfLimitInProcess money -- ������� ������, ���� �� ���� ������ *�������* �� ���� ����� �������� � ��� ������ *���������������*
			, ia_inProcessTtl money, ia_inProcessTtlAccum money -- *���������������* �� ���� ����� ��������
			, ia_acceptedAndInProcessTtl money, ia_acceptedAndInProcessTtlAccum money -- ����� *�������* � *���������������* �� ���� ����� ��������
			, ia_returnedTtl money, ia_returnedTtlAccum money -- *����������* �� ���� ����� ��������
			, ia_notArrivedTtl money, ia_notArrivedTtlAccum money -- *�� ���������* �� ���� ����� ��������
			-- ��������, ���� � ��������. ��������� +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			-- �������������� ����� (���������, ������). ��������� ============================================================================================

			-- ����������� ����� ==============================================================================================================================
			, uk_ipgpKey int, uk_iShKey int, uk_ipgpSmTtl money, uk_lim  money, uk_Pl money, uk_PlAccum money
			-- ��������� ���������� +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			-- ���� �����
			, uk_PlFulfillment money, uk_PlNonFulfillment_review money, uk_PlNonFulfillment money
			-- ���� ����� ���� ������
			, uk_PlOverFulfillment money, uk_PlRestLimit_review money, uk_PlRestLimit money
			-- ���� ������
			, uk_PlOverLimit money, uk_PlOverLimit_review money
			-- �������� �������� ������
			, uk_LimPercent float, uk_LimPercentInProcess float -- *������� ��������*, �������� *��������� ����� ������*
			, uk_percentDev float, uk_percentDevInProcess float -- *������� ��������*, ������� *��������� ����� ������*
			-- �������� �������� �����
			, uk_PlPercentMinusOverFulf float, uk_PlPercentMinusOverFulfInProcess float -- *������� ���������� �����* ��� *��������������*
			, uk_PlPercent float, uk_PlPercentInProcess float -- *������� ���������� �����* ������� *��������������*
			, uk_percentPlDev float, uk_percentPlDevInProcess float -- *������� ���������� �����* ������� ��, ���� � *����������*
			-- ��������� ����������. ��������� ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

			-- ��������, ���� � �������� ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			-- ������ ������� ---------------------------------------------------------------------------------------------------------------------------------
			-- ����������� � ����� ����� ......................................................................................................................
			, uk_presentedAll money, uk_presentedAllAccum money -- ����� ����, ��� ����������, ������� �������������� �� �������
			, uk_presentedAllModul money, uk_presentedAllModulAccum money -- ����� ����, ��� ����������, ������� �������������� �� �������, ������ �� ������
			-- ����������� � �������� ���� ....................................................................................................................
			, uk_presented money, uk_presentedAccum money -- ����� *��������������* �������, �������� ��������� � ������� ������� ���
			, uk_accepted money, uk_acceptedAccum money -- ����� *��������* �������, �������� ��������� � ������� ������� ���
			, uk_inProcess money, uk_inProcessAccum money -- ����� *���������������* �������, �������� ��������� � ������� ������� ���
			, uk_returned money, uk_returnedAccum money -- ����� *������������* �������, �������� ��������� � ������� ������� ���
			, uk_notArrived money, uk_notArrivedAccum money -- ����� *�� �����������* �������, �������� ��������� � ������� ������� ���
			-- ����������� � ������� �����. ����������� �� ���� ��������� � ������� ������� ��� ...............................................................
			, uk_presentedPrevYears money, uk_presentedPrevYearsAccum money
			, uk_acceptedPrevYears money, uk_acceptedPrevYearsAccum money
			, uk_returnedPrevYears money, uk_returnedPrevYearsAccum money
			, uk_inProcessPrevYears money, uk_inProcessPrevYearsAccum money
			, uk_notArrivedPrevYears money, uk_notArrivedPrevYearsAccum money
			-- ������ �������. ��������� ----------------------------------------------------------------------------------------------------------------------
				
			-- ��������� �������������� -----------------------------------------------------------------------------------------------------------------------
			, uk_agFeePresented money, uk_agFeePresentedAccum money, uk_agFeeAccepted money, uk_agFeeAcceptedAccum money
			, uk_agFeeInProcess money, uk_agFeeInProcessAccum money
			, uk_agFeeReturned money, uk_agFeeReturnedAccum money
			, uk_agFeeNotArrived money, uk_agFeeNotArrivedAccum money
			-- ��������� ������� ------------------------------------------------------------------------------------------------------------------------------
			, uk_presentedRalp money, uk_presentedRalpAccum money, uk_acceptedRalp money, uk_acceptedRalpAccum money
			, uk_inProcessRalp money, uk_inProcessRalpAccum money
			, uk_returnedRalp money, uk_returnedRalpAccum money
			, uk_notArrivedRalp money, uk_notArrivedRalpAccum money
			-- ��������, �������������, ��� -------------------------------------------------------------------------------------------------------------------
			, uk_storageSum money, uk_storageSumAccum money, uk_cctSum money, uk_cctSumAccum money, uk_MnrlSum money, uk_MnrlSumAccum money
			-- ����� ------------------------------------------------------------------------------------------------------------------------------------------
			, uk_presentedTtl money, uk_presentedTtlAccum money -- *������������* �� ���� ����� ��������
			, uk_acceptedTtl money, uk_acceptedTtlAccum money -- *�������* �� ���� ����� ��������
			, uk_restOfLimit money -- ������� ������, ���� �� ���� ������ *�������* �� ���� ����� ��������
			, uk_restOfLimitInProcess money -- ������� ������, ���� �� ���� ������ *�������* �� ���� ����� �������� � ��� ������ *���������������*
			, uk_inProcessTtl money, uk_inProcessTtlAccum money -- *���������������* �� ���� ����� ��������
			, uk_acceptedAndInProcessTtl money, uk_acceptedAndInProcessTtlAccum money -- ����� *�������* � *���������������* �� ���� ����� ��������
			, uk_returnedTtl money, uk_returnedTtlAccum money -- *����������* �� ���� ����� ��������
			, uk_notArrivedTtl money, uk_notArrivedTtlAccum money -- *�� ���������* �� ���� ����� ��������
			-- ��������, ���� � ��������. ��������� +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			-- ����������� �����. ��������� ===================================================================================================================

			-- ��������� ����� (������) =======================================================================================================================
			, np_lim money, np_iShKey int -- 14.10.2024 ������� �����, ����� � ������� ����� ���� �����... �� ����������� ��� ���������. 
			-- � � Access, � ipgChRsltPlCstPercent ���� ����� ������� ����. ������� ��� �������� �������������

			-- ��������, ���� � �������� ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			-- ������ ������� ---------------------------------------------------------------------------------------------------------------------------------
			-- ����������� � ����� ����� ......................................................................................................................
			, np_presentedAll money, np_presentedAllAccum money -- ����� ����, ��� ����������, ������� �������������� �� �������
			, np_presentedAllModul money, np_presentedAllModulAccum money -- ����� ����, ��� ����������, ������� �������������� �� �������, ������ �� ������
			-- ����������� � �������� ���� ....................................................................................................................
			, np_presented money, np_presentedAccum money -- ����� *��������������* �������, �������� ��������� � ������� ������� ���
			, np_accepted money, np_acceptedAccum money -- ����� *��������* �������, �������� ��������� � ������� ������� ���
			, np_inProcess money, np_inProcessAccum money -- ����� *���������������* �������, �������� ��������� � ������� ������� ���
			, np_returned money, np_returnedAccum money -- ����� *������������* �������, �������� ��������� � ������� ������� ���
			, np_notArrived money, np_notArrivedAccum money -- ����� *�� �����������* �������, �������� ��������� � ������� ������� ���
			-- ����������� � ������� �����. ����������� �� ���� ��������� � ������� ������� ��� ...............................................................
			, np_presentedPrevYears money, np_presentedPrevYearsAccum money
			, np_acceptedPrevYears money, np_acceptedPrevYearsAccum money
			, np_returnedPrevYears money, np_returnedPrevYearsAccum money
			, np_inProcessPrevYears money, np_inProcessPrevYearsAccum money
			, np_notArrivedPrevYears money, np_notArrivedPrevYearsAccum money
			-- ������ �������. ��������� ----------------------------------------------------------------------------------------------------------------------
				
			-- ��������� �������������� -----------------------------------------------------------------------------------------------------------------------
			, np_agFeePresented money, np_agFeePresentedAccum money, np_agFeeAccepted money, np_agFeeAcceptedAccum money
			, np_agFeeInProcess money, np_agFeeInProcessAccum money
			, np_agFeeReturned money, np_agFeeReturnedAccum money
			, np_agFeeNotArrived money, np_agFeeNotArrivedAccum money
			-- ��������� ������� ------------------------------------------------------------------------------------------------------------------------------
			, np_presentedRalp money, np_presentedRalpAccum money, np_acceptedRalp money, np_acceptedRalpAccum money
			, np_inProcessRalp money, np_inProcessRalpAccum money
			, np_returnedRalp money, np_returnedRalpAccum money
			, np_notArrivedRalp money, np_notArrivedRalpAccum money
			-- ��������, �������������, ��� -------------------------------------------------------------------------------------------------------------------
			, np_storageSum money, np_storageSumAccum money, np_cctSum money, np_cctSumAccum money, np_MnrlSum money, np_MnrlSumAccum money
			-- ����� ------------------------------------------------------------------------------------------------------------------------------------------
			, np_presentedTtl money, np_presentedTtlAccum money -- *������������* �� ���� ����� ��������
			, np_acceptedTtl money, np_acceptedTtlAccum money -- *�������* �� ���� ����� ��������
			, np_restOfLimit money -- ������� ������, ���� �� ���� ������ *�������* �� ���� ����� ��������
			, np_restOfLimitInProcess money -- ������� ������, ���� �� ���� ������ *�������* �� ���� ����� �������� � ��� ������ *���������������*
			, np_inProcessTtl money, np_inProcessTtlAccum money -- *���������������* �� ���� ����� ��������
			, np_acceptedAndInProcessTtl money, np_acceptedAndInProcessTtlAccum money -- ����� *�������* � *���������������* �� ���� ����� ��������
			, np_returnedTtl money, np_returnedTtlAccum money -- *����������* �� ���� ����� ��������
			, np_notArrivedTtl money, np_notArrivedTtlAccum money -- *�� ���������* �� ���� ����� ��������
			-- ��������, ���� � ��������. ��������� +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			-- ��������� ����� (������). ��������� ============================================================================================================

			-- ������ ������� =================================================================================================================================
			-- ������ ������� ---------------------------------------------------------------------------------------------------------------------------------
			-- ����������� � ����� ����� ......................................................................................................................
			, oh_presentedAll money, oh_presentedAllAccum money  -- ����� ����, ��� ����������, ������� �������������� �� �������
			, oh_presentedAllModul money, oh_presentedAllModulAccum money -- ����� ����, ��� ����������, ������� �������������� �� �������, ������ �� ������
			-- ����������� � �������� ���� ....................................................................................................................
			, oh_presented money, oh_presentedAccum money -- ����� *��������������* �������, �������� ��������� � ������� ������� ���
			, oh_accepted money, oh_acceptedAccum money -- ����� *��������* �������, �������� ��������� � ������� ������� ���
			, oh_inProcess money, oh_inProcessAccum money -- ����� *���������������* �������, �������� ��������� � ������� ������� ���
			, oh_returned money, oh_returnedAccum money -- ����� *������������* �������, �������� ��������� � ������� ������� ���
			, oh_notArrived money, oh_notArrivedAccum money -- ����� *�� �����������* �������, �������� ��������� � ������� ������� ���
			-- ����������� � ������� �����. ����������� �� ���� ��������� � ������� ������� ��� ...............................................................
			, oh_presentedPrevYears money, oh_presentedPrevYearsAccum money
			, oh_acceptedPrevYears money, oh_acceptedPrevYearsAccum money
			, oh_returnedPrevYears money, oh_returnedPrevYearsAccum money
			, oh_inProcessPrevYears money, oh_inProcessPrevYearsAccum money
			, oh_notArrivedPrevYears money, oh_notArrivedPrevYearsAccum money
			-- ��������� �������������� -----------------------------------------------------------------------------------------------------------------------
			-- 14.07.2023 ������� ������ ������ ��� ���������� ��������������
			, oh_agFeePresented money, oh_agFeePresentedAccum money, oh_agFeeAccepted money, oh_agFeeAcceptedAccum money
			, oh_agFeeReturned money, oh_agFeeReturnedAccum money
			, oh_agFeeInProcess money, oh_agFeeInProcessAccum money
			, oh_agFeeNotArrived money, oh_agFeeNotArrivedAccum money
			-- ����� ------------------------------------------------------------------------------------------------------------------------------------------
			, oh_presentedTtl money, oh_presentedTtlAccum money -- *������������* �� ���� ����� ��������
			, oh_acceptedTtl money, oh_acceptedTtlAccum money -- *�������* �� ���� ����� ��������
			, oh_inProcessTtl money, oh_inProcessTtlAccum money
			, oh_acceptedAndInProcessTtl money, oh_acceptedAndInProcessTtlAccum money
			, oh_returnedTtl money, oh_returnedTtlAccum money
			, oh_notArrivedTtl money, oh_notArrivedTtlAccum money
			-- ������ �������. ��������� ======================================================================================================================
		)

	-- ��������� �������� ��� ����� ���������� ������������� �������� *fnIpgChRsltCstUtlPercentBrn_2408* ����� ����� � ��� ���������� ������
	insert into @TableFnIpgChRsltCstUtlPercentBrn_2408
		(
			rowNum, ogNm, branch, branchName, cstAgPnCode, dateRslt, ipgChKey, cstapKey
			, yKey, yyyy, mKey, mNum, mCs, mNm, mQ, mHy, cstaInvestor, ogaKey
			, ipgKey
			, ipgCount
			, ag_ipgpKey
			, ag_iShKey
			, ag_ipgpSmTtl
			, ag_lim
			, ag_Pl
			, ag_PlAccum
			, ag_PlFulfillment
			, ag_PlNonFulfillment_review
			, ag_PlNonFulfillment
			, ag_PlOverFulfillment
			, ag_PlRestLimit_review
			, ag_PlRestLimit
			, ag_PlOverLimit
			, ag_PlOverLimit_review
			, ag_LimPercent
			, ag_LimPercentInProcess
			, ag_percentDev
			, ag_percentDevInProcess
			, ag_PlPercentMinusOverFulf
			, ag_PlPercentMinusOverFulfInProcess
			, ag_PlPercent
			, ag_PlPercentInProcess
			, ag_percentPlDev
			, ag_percentPlDevInProcess
			, ag_presentedAll
			, ag_presentedAllAccum
			, ag_presentedAllModul
			, ag_presentedAllModulAccum
			, ag_presented
			, ag_presentedAccum
			, ag_accepted
			, ag_acceptedAccum
			, ag_inProcess
			, ag_inProcessAccum
			, ag_returned
			, ag_returnedAccum
			, ag_notArrived
			, ag_notArrivedAccum
			, ag_presentedPrevYears
			, ag_presentedPrevYearsAccum
			, ag_acceptedPrevYears
			, ag_acceptedPrevYearsAccum
			, ag_inProcessPrevYears
			, ag_inProcessPrevYearsAccum
			, ag_returnedPrevYears
			, ag_returnedPrevYearsAccum
			, ag_notArrivedPrevYears
			, ag_notArrivedPrevYearsAccum
			, ag_agFeePresented
			, ag_agFeePresentedAccum
			, ag_agFeeAccepted
			, ag_agFeeAcceptedAccum
			, ag_agFeeInProcess
			, ag_agFeeInProcessAccum
			, ag_agFeeReturned
			, ag_agFeeReturnedAccum
			, ag_agFeeNotArrived
			, ag_agFeeNotArrivedAccum
			, ag_presentedRalp
			, ag_presentedRalpAccum
			, ag_acceptedRalp
			, ag_acceptedRalpAccum
			, ag_inProcessRalp
			, ag_inProcessRalpAccum
			, ag_returnedRalp
			, ag_returnedRalpAccum
			, ag_notArrivedRalp
			, ag_notArrivedRalpAccum
			, ag_storageSum
			, ag_storageSumAccum
			, ag_cctSum
			, ag_cctSumAccum
			, ag_MnrlSum
			, ag_MnrlSumAccum
			, ag_presentedTtl
			, ag_presentedTtlAccum
			, ag_acceptedTtl
			, ag_acceptedTtlAccum
			, ag_restOfLimit
			, ag_restOfLimitInProcess
			, ag_inProcessTtl
			, ag_inProcessTtlAccum
			, ag_acceptedAndInProcessTtl
			, ag_acceptedAndInProcessTtlAccum
			, ag_returnedTtl
			, ag_returnedTtlAccum
			, ag_notArrivedTtl
			, ag_notArrivedTtlAccum
			, iv_ipgpKey
			, iv_iShKey
			, ia_iShKey
			, iv_ipgpSmTtl
			, iv_lim
			, ia_lim
			, iv_Pl
			, iv_PlAccum
			, iv_PlFulfillment
			, iv_PlNonFulfillment_review
			, iv_PlNonFulfillment
			, iv_PlOverFulfillment
			, iv_PlRestLimit_review
			, iv_PlRestLimit
			, iv_PlOverLimit
			, iv_PlOverLimit_review
			, iv_LimPercent
			, iv_LimPercentInProcess
			, ia_percentDev
			, ia_percentDevInProcess
			, iv_PlPercentMinusOverFulf
			, iv_PlPercentMinusOverFulfInProcess
			, iv_PlPercent
			, iv_PlPercentInProcess
			, ia_percentPlDev
			, ia_percentPlDevInProcess
			, ia_presentedAll
			, ia_presentedAllAccum
			, ia_presentedAllModul
			, ia_presentedAllModulAccum
			, ia_presented
			, ia_presentedAccum
			, ia_accepted
			, ia_acceptedAccum
			, ia_inProcess
			, ia_inProcessAccum
			, ia_returned
			, ia_returnedAccum
			, ia_notArrived
			, ia_notArrivedAccum
			, ia_presentedPrevYears
			, ia_presentedPrevYearsAccum
			, ia_acceptedPrevYears
			, ia_acceptedPrevYearsAccum
			, ia_inProcessPrevYears
			, ia_inProcessPrevYearsAccum
			, ia_returnedPrevYears
			, ia_returnedPrevYearsAccum
			, ia_notArrivedPrevYears
			, ia_notArrivedPrevYearsAccum
			, ia_agFeePresented
			, ia_agFeePresentedAccum
			, ia_agFeeAccepted
			, ia_agFeeAcceptedAccum
			, ia_agFeeInProcess
			, ia_agFeeInProcessAccum
			, ia_agFeeReturned
			, ia_agFeeReturnedAccum
			, ia_agFeeNotArrived
			, ia_agFeeNotArrivedAccum
			, ia_presentedRalp
			, ia_presentedRalpAccum
			, ia_acceptedRalp
			, ia_acceptedRalpAccum
			, ia_inProcessRalp
			, ia_inProcessRalpAccum
			, ia_returnedRalp
			, ia_returnedRalpAccum
			, ia_notArrivedRalp
			, ia_notArrivedRalpAccum
			, ia_storageSum
			, ia_storageSumAccum
			, ia_cctSum
			, ia_cctSumAccum
			, ia_MnrlSum
			, ia_MnrlSumAccum
			, ia_presentedTtl
			, ia_presentedTtlAccum
			, ia_acceptedTtl
			, ia_acceptedTtlAccum
			, ia_restOfLimit
			, ia_restOfLimitInProcess
			, ia_inProcessTtl
			, ia_inProcessTtlAccum
			, ia_acceptedAndInProcessTtl
			, ia_acceptedAndInProcessTtlAccum
			, ia_returnedTtl
			, ia_returnedTtlAccum
			, ia_notArrivedTtl
			, ia_notArrivedTtlAccum
			, uk_ipgpKey
			, uk_iShKey
			, uk_ipgpSmTtl
			, uk_lim
			, uk_Pl
			, uk_PlAccum
			, uk_PlFulfillment
			, uk_PlNonFulfillment_review
			, uk_PlNonFulfillment
			, uk_PlOverFulfillment
			, uk_PlRestLimit_review
			, uk_PlRestLimit
			, uk_PlOverLimit
			, uk_PlOverLimit_review
			, uk_LimPercent
			, uk_LimPercentInProcess
			, uk_percentDev
			, uk_percentDevInProcess
			, uk_PlPercentMinusOverFulf
			, uk_PlPercentMinusOverFulfInProcess
			, uk_PlPercent
			, uk_PlPercentInProcess
			, uk_percentPlDev
			, uk_percentPlDevInProcess
			, uk_presentedAll
			, uk_presentedAllAccum
			, uk_presentedAllModul
			, uk_presentedAllModulAccum
			, uk_presented
			, uk_presentedAccum
			, uk_accepted
			, uk_acceptedAccum
			, uk_inProcess
			, uk_inProcessAccum
			, uk_returned
			, uk_returnedAccum
			, uk_notArrived
			, uk_notArrivedAccum
			, uk_presentedPrevYears
			, uk_presentedPrevYearsAccum
			, uk_acceptedPrevYears
			, uk_acceptedPrevYearsAccum
			, uk_returnedPrevYears
			, uk_returnedPrevYearsAccum
			, uk_inProcessPrevYears
			, uk_inProcessPrevYearsAccum
			, uk_notArrivedPrevYears
			, uk_notArrivedPrevYearsAccum
			, uk_agFeePresented
			, uk_agFeePresentedAccum
			, uk_agFeeAccepted
			, uk_agFeeAcceptedAccum
			, uk_agFeeInProcess
			, uk_agFeeInProcessAccum
			, uk_agFeeReturned
			, uk_agFeeReturnedAccum
			, uk_agFeeNotArrived
			, uk_agFeeNotArrivedAccum
			, uk_presentedRalp
			, uk_presentedRalpAccum
			, uk_acceptedRalp
			, uk_acceptedRalpAccum
			, uk_inProcessRalp
			, uk_inProcessRalpAccum
			, uk_returnedRalp
			, uk_returnedRalpAccum
			, uk_notArrivedRalp
			, uk_notArrivedRalpAccum
			, uk_storageSum
			, uk_storageSumAccum
			, uk_cctSum
			, uk_cctSumAccum
			, uk_MnrlSum
			, uk_MnrlSumAccum
			, uk_presentedTtl
			, uk_presentedTtlAccum
			, uk_acceptedTtl
			, uk_acceptedTtlAccum
			, uk_restOfLimit
			, uk_restOfLimitInProcess
			, uk_inProcessTtl
			, uk_inProcessTtlAccum
			, uk_acceptedAndInProcessTtl
			, uk_acceptedAndInProcessTtlAccum
			, uk_returnedTtl
			, uk_returnedTtlAccum
			, uk_notArrivedTtl
			, uk_notArrivedTtlAccum
			, np_lim
			, np_iShKey
			, np_presentedAll
			, np_presentedAllAccum
			, np_presentedAllModul
			, np_presentedAllModulAccum
			, np_presented
			, np_presentedAccum
			, np_accepted
			, np_acceptedAccum
			, np_inProcess
			, np_inProcessAccum
			, np_returned
			, np_returnedAccum
			, np_notArrived
			, np_notArrivedAccum
			, np_presentedPrevYears
			, np_presentedPrevYearsAccum
			, np_acceptedPrevYears
			, np_acceptedPrevYearsAccum
			, np_returnedPrevYears
			, np_returnedPrevYearsAccum
			, np_inProcessPrevYears
			, np_inProcessPrevYearsAccum
			, np_notArrivedPrevYears
			, np_notArrivedPrevYearsAccum
			, np_agFeePresented
			, np_agFeePresentedAccum
			, np_agFeeAccepted
			, np_agFeeAcceptedAccum
			, np_agFeeInProcess
			, np_agFeeInProcessAccum
			, np_agFeeReturned
			, np_agFeeReturnedAccum
			, np_agFeeNotArrived
			, np_agFeeNotArrivedAccum
			, np_presentedRalp
			, np_presentedRalpAccum
			, np_acceptedRalp
			, np_acceptedRalpAccum
			, np_inProcessRalp
			, np_inProcessRalpAccum
			, np_returnedRalp
			, np_returnedRalpAccum
			, np_notArrivedRalp
			, np_notArrivedRalpAccum
			, np_storageSum
			, np_storageSumAccum
			, np_cctSum
			, np_cctSumAccum
			, np_MnrlSum
			, np_MnrlSumAccum
			, np_presentedTtl
			, np_presentedTtlAccum
			, np_acceptedTtl
			, np_acceptedTtlAccum
			, np_restOfLimit
			, np_restOfLimitInProcess
			, np_inProcessTtl
			, np_inProcessTtlAccum
			, np_acceptedAndInProcessTtl
			, np_acceptedAndInProcessTtlAccum
			, np_returnedTtl
			, np_returnedTtlAccum
			, np_notArrivedTtl
			, np_notArrivedTtlAccum
			, oh_presentedAll, oh_presentedAllAccum, oh_presentedAllModul, oh_presentedAllModulAccum
			, oh_presented, oh_presentedAccum, oh_accepted, oh_acceptedAccum, oh_inProcess, oh_inProcessAccum, oh_returned, oh_returnedAccum
			, oh_notArrived
			, oh_notArrivedAccum
			, oh_presentedPrevYears
			, oh_presentedPrevYearsAccum
			, oh_acceptedPrevYears
			, oh_acceptedPrevYearsAccum
			, oh_returnedPrevYears
			, oh_returnedPrevYearsAccum
			, oh_inProcessPrevYears
			, oh_inProcessPrevYearsAccum
			, oh_notArrivedPrevYears
			, oh_notArrivedPrevYearsAccum
			, oh_agFeePresented
			, oh_agFeePresentedAccum
			, oh_agFeeAccepted
			, oh_agFeeAcceptedAccum
			, oh_agFeeReturned
			, oh_agFeeReturnedAccum
			, oh_agFeeInProcess
			, oh_agFeeInProcessAccum
			, oh_agFeeNotArrived
			, oh_agFeeNotArrivedAccum
			, oh_presentedTtl
			, oh_presentedTtlAccum
			, oh_acceptedTtl
			, oh_acceptedTtlAccum
			, oh_inProcessTtl
			, oh_inProcessTtlAccum
			, oh_acceptedAndInProcessTtl, oh_acceptedAndInProcessTtlAccum, oh_returnedTtl, oh_returnedTtlAccum, oh_notArrivedTtl, oh_notArrivedTtlAccum
		)
	select 
		rowNum, ogNm, branch, branchName, cstAgPnCode, dateRslt, ipgChKey, cstapKey
		, yKey, yyyy, mKey, mNum, mCs, mNm, mQ, mHy, cstaInvestor, ogaKey, ipgKey, ipgCount
		, ag_ipgpKey
		, ag_iShKey
		, ag_ipgpSmTtl
		, ag_lim
		, ag_Pl
		, ag_PlAccum
		, ag_PlFulfillment
		, ag_PlNonFulfillment_review
		, ag_PlNonFulfillment
		, ag_PlOverFulfillment
		, ag_PlRestLimit_review
		, ag_PlRestLimit
		, ag_PlOverLimit
		, ag_PlOverLimit_review
		, ag_LimPercent
		, ag_LimPercentInProcess
		, ag_percentDev
		, ag_percentDevInProcess
		, ag_PlPercentMinusOverFulf
		, ag_PlPercentMinusOverFulfInProcess
		, ag_PlPercent
		, ag_PlPercentInProcess
		, ag_percentPlDev
		, ag_percentPlDevInProcess
		, ag_presentedAll
		, ag_presentedAllAccum
		, ag_presentedAllModul
		, ag_presentedAllModulAccum
		, ag_presented
		, ag_presentedAccum
		, ag_accepted
		, ag_acceptedAccum
		, ag_inProcess
		, ag_inProcessAccum
		, ag_returned
		, ag_returnedAccum
		, ag_notArrived
		, ag_notArrivedAccum
		, ag_presentedPrevYears
		, ag_presentedPrevYearsAccum
		, ag_acceptedPrevYears
		, ag_acceptedPrevYearsAccum
		, ag_inProcessPrevYears
		, ag_inProcessPrevYearsAccum
		, ag_returnedPrevYears
		, ag_returnedPrevYearsAccum
		, ag_notArrivedPrevYears
		, ag_notArrivedPrevYearsAccum
		, ag_agFeePresented
		, ag_agFeePresentedAccum
		, ag_agFeeAccepted
		, ag_agFeeAcceptedAccum
		, ag_agFeeInProcess
		, ag_agFeeInProcessAccum
		, ag_agFeeReturned
		, ag_agFeeReturnedAccum
		, ag_agFeeNotArrived
		, ag_agFeeNotArrivedAccum
		, ag_presentedRalp
		, ag_presentedRalpAccum
		, ag_acceptedRalp
		, ag_acceptedRalpAccum
		, ag_inProcessRalp
		, ag_inProcessRalpAccum
		, ag_returnedRalp
		, ag_returnedRalpAccum
		, ag_notArrivedRalp
		, ag_notArrivedRalpAccum
		, ag_storageSum
		, ag_storageSumAccum
		, ag_cctSum
		, ag_cctSumAccum
		, ag_MnrlSum
		, ag_MnrlSumAccum
		, ag_presentedTtl
		, ag_presentedTtlAccum
		, ag_acceptedTtl
		, ag_acceptedTtlAccum
		, ag_restOfLimit
		, ag_restOfLimitInProcess
		, ag_inProcessTtl
		, ag_inProcessTtlAccum
		, ag_acceptedAndInProcessTtl
		, ag_acceptedAndInProcessTtlAccum
		, ag_returnedTtl
		, ag_returnedTtlAccum
		, ag_notArrivedTtl
		, ag_notArrivedTtlAccum
		, iv_ipgpKey
		, iv_iShKey
		, ia_iShKey
		, iv_ipgpSmTtl
		, iv_lim
		, ia_lim
		, iv_Pl
		, iv_PlAccum
		, iv_PlFulfillment
		, iv_PlNonFulfillment_review
		, iv_PlNonFulfillment
		, iv_PlOverFulfillment
		, iv_PlRestLimit_review
		, iv_PlRestLimit
		, iv_PlOverLimit
		, iv_PlOverLimit_review
		, iv_LimPercent
		, iv_LimPercentInProcess
		, ia_percentDev
		, ia_percentDevInProcess
		, iv_PlPercentMinusOverFulf
		, iv_PlPercentMinusOverFulfInProcess
		, iv_PlPercent
		, iv_PlPercentInProcess
		, ia_percentPlDev
		, ia_percentPlDevInProcess
		, ia_presentedAll
		, ia_presentedAllAccum
		, ia_presentedAllModul
		, ia_presentedAllModulAccum
		, ia_presented
		, ia_presentedAccum
		, ia_accepted
		, ia_acceptedAccum
		, ia_inProcess
		, ia_inProcessAccum
		, ia_returned
		, ia_returnedAccum
		, ia_notArrived
		, ia_notArrivedAccum
		, ia_presentedPrevYears
		, ia_presentedPrevYearsAccum
		, ia_acceptedPrevYears
		, ia_acceptedPrevYearsAccum
		, ia_inProcessPrevYears
		, ia_inProcessPrevYearsAccum
		, ia_returnedPrevYears
		, ia_returnedPrevYearsAccum
		, ia_notArrivedPrevYears
		, ia_notArrivedPrevYearsAccum
		, ia_agFeePresented
		, ia_agFeePresentedAccum
		, ia_agFeeAccepted
		, ia_agFeeAcceptedAccum
		, ia_agFeeInProcess
		, ia_agFeeInProcessAccum
		, ia_agFeeReturned
		, ia_agFeeReturnedAccum
		, ia_agFeeNotArrived
		, ia_agFeeNotArrivedAccum
		, ia_presentedRalp
		, ia_presentedRalpAccum
		, ia_acceptedRalp
		, ia_acceptedRalpAccum
		, ia_inProcessRalp
		, ia_inProcessRalpAccum
		, ia_returnedRalp
		, ia_returnedRalpAccum
		, ia_notArrivedRalp
		, ia_notArrivedRalpAccum
		, ia_storageSum
		, ia_storageSumAccum
		, ia_cctSum
		, ia_cctSumAccum
		, ia_MnrlSum
		, ia_MnrlSumAccum
		, ia_presentedTtl
		, ia_presentedTtlAccum
		, ia_acceptedTtl
		, ia_acceptedTtlAccum
		, ia_restOfLimit
		, ia_restOfLimitInProcess
		, ia_inProcessTtl
		, ia_inProcessTtlAccum
		, ia_acceptedAndInProcessTtl
		, ia_acceptedAndInProcessTtlAccum
		, ia_returnedTtl
		, ia_returnedTtlAccum
		, ia_notArrivedTtl
		, ia_notArrivedTtlAccum
		, uk_ipgpKey
		, uk_iShKey
		, uk_ipgpSmTtl
		, uk_lim
		, uk_Pl
		, uk_PlAccum
		, uk_PlFulfillment
		, uk_PlNonFulfillment_review
		, uk_PlNonFulfillment
		, uk_PlOverFulfillment
		, uk_PlRestLimit_review
		, uk_PlRestLimit
		, uk_PlOverLimit
		, uk_PlOverLimit_review
		, uk_LimPercent
		, uk_LimPercentInProcess
		, uk_percentDev
		, uk_percentDevInProcess
		, uk_PlPercentMinusOverFulf
		, uk_PlPercentMinusOverFulfInProcess
		, uk_PlPercent
		, uk_PlPercentInProcess
		, uk_percentPlDev
		, uk_percentPlDevInProcess
		, uk_presentedAll
		, uk_presentedAllAccum
		, uk_presentedAllModul
		, uk_presentedAllModulAccum
		, uk_presented
		, uk_presentedAccum
		, uk_accepted
		, uk_acceptedAccum
		, uk_inProcess
		, uk_inProcessAccum
		, uk_returned
		, uk_returnedAccum
		, uk_notArrived
		, uk_notArrivedAccum
		, uk_presentedPrevYears
		, uk_presentedPrevYearsAccum
		, uk_acceptedPrevYears
		, uk_acceptedPrevYearsAccum
		, uk_returnedPrevYears
		, uk_returnedPrevYearsAccum
		, uk_inProcessPrevYears
		, uk_inProcessPrevYearsAccum
		, uk_notArrivedPrevYears
		, uk_notArrivedPrevYearsAccum
		, uk_agFeePresented
		, uk_agFeePresentedAccum
		, uk_agFeeAccepted
		, uk_agFeeAcceptedAccum
		, uk_agFeeInProcess
		, uk_agFeeInProcessAccum
		, uk_agFeeReturned
		, uk_agFeeReturnedAccum
		, uk_agFeeNotArrived
		, uk_agFeeNotArrivedAccum
		, uk_presentedRalp
		, uk_presentedRalpAccum
		, uk_acceptedRalp
		, uk_acceptedRalpAccum
		, uk_inProcessRalp
		, uk_inProcessRalpAccum
		, uk_returnedRalp
		, uk_returnedRalpAccum
		, uk_notArrivedRalp
		, uk_notArrivedRalpAccum
		, uk_storageSum
		, uk_storageSumAccum
		, uk_cctSum
		, uk_cctSumAccum
		, uk_MnrlSum
		, uk_MnrlSumAccum
		, uk_presentedTtl
		, uk_presentedTtlAccum
		, uk_acceptedTtl
		, uk_acceptedTtlAccum
		, uk_restOfLimit
		, uk_restOfLimitInProcess
		, uk_inProcessTtl
		, uk_inProcessTtlAccum
		, uk_acceptedAndInProcessTtl
		, uk_acceptedAndInProcessTtlAccum
		, uk_returnedTtl
		, uk_returnedTtlAccum
		, uk_notArrivedTtl
		, uk_notArrivedTtlAccum
		, np_lim
		, np_iShKey
		, np_presentedAll
		, np_presentedAllAccum
		, np_presentedAllModul
		, np_presentedAllModulAccum
		, np_presented
		, np_presentedAccum
		, np_accepted
		, np_acceptedAccum
		, np_inProcess
		, np_inProcessAccum
		, np_returned
		, np_returnedAccum
		, np_notArrived
		, np_notArrivedAccum
		, np_presentedPrevYears
		, np_presentedPrevYearsAccum
		, np_acceptedPrevYears
		, np_acceptedPrevYearsAccum
		, np_returnedPrevYears
		, np_returnedPrevYearsAccum
		, np_inProcessPrevYears
		, np_inProcessPrevYearsAccum
		, np_notArrivedPrevYears
		, np_notArrivedPrevYearsAccum
		, np_agFeePresented
		, np_agFeePresentedAccum
		, np_agFeeAccepted
		, np_agFeeAcceptedAccum
		, np_agFeeInProcess
		, np_agFeeInProcessAccum
		, np_agFeeReturned
		, np_agFeeReturnedAccum
		, np_agFeeNotArrived
		, np_agFeeNotArrivedAccum
		, np_presentedRalp
		, np_presentedRalpAccum
		, np_acceptedRalp
		, np_acceptedRalpAccum
		, np_inProcessRalp
		, np_inProcessRalpAccum
		, np_returnedRalp
		, np_returnedRalpAccum
		, np_notArrivedRalp
		, np_notArrivedRalpAccum
		, np_storageSum
		, np_storageSumAccum
		, np_cctSum
		, np_cctSumAccum
		, np_MnrlSum
		, np_MnrlSumAccum
		, np_presentedTtl
		, np_presentedTtlAccum
		, np_acceptedTtl
		, np_acceptedTtlAccum
		, np_restOfLimit
		, np_restOfLimitInProcess
		, np_inProcessTtl
		, np_inProcessTtlAccum
		, np_acceptedAndInProcessTtl
		, np_acceptedAndInProcessTtlAccum
		, np_returnedTtl
		, np_returnedTtlAccum
		, np_notArrivedTtl
		, np_notArrivedTtlAccum
		, oh_presentedAll
		, oh_presentedAllAccum
		, oh_presentedAllModul
		, oh_presentedAllModulAccum
		, oh_presented
		, oh_presentedAccum
		, oh_accepted
		, oh_acceptedAccum
		, oh_inProcess
		, oh_inProcessAccum
		, oh_returned
		, oh_returnedAccum
		, oh_notArrived
		, oh_notArrivedAccum
		, oh_presentedPrevYears
		, oh_presentedPrevYearsAccum
		, oh_acceptedPrevYears
		, oh_acceptedPrevYearsAccum
		, oh_returnedPrevYears
		, oh_returnedPrevYearsAccum
		, oh_inProcessPrevYears
		, oh_inProcessPrevYearsAccum
		, oh_notArrivedPrevYears
		, oh_notArrivedPrevYearsAccum
		, oh_agFeePresented
		, oh_agFeePresentedAccum
		, oh_agFeeAccepted
		, oh_agFeeAcceptedAccum
		, oh_agFeeReturned
		, oh_agFeeReturnedAccum
		, oh_agFeeInProcess
		, oh_agFeeInProcessAccum
		, oh_agFeeNotArrived
		, oh_agFeeNotArrivedAccum
		, oh_presentedTtl
		, oh_presentedTtlAccum
		, oh_acceptedTtl
		, oh_acceptedTtlAccum
		, oh_inProcessTtl
		, oh_inProcessTtlAccum
		, oh_acceptedAndInProcessTtl
		, oh_acceptedAndInProcessTtlAccum
		, oh_returnedTtl
		, oh_returnedTtlAccum
		, oh_notArrivedTtl
		, oh_notArrivedTtlAccum 
	from ags.fnIpgChRsltCstUtlPercentBrn_2408(@ipgCh)-- f where f.dateRslt = @MounthEndDate �������, ����������� ����� � 53 ������ �� 1 ������ 26...

	-- ************************************************************************************************************************
	-- ���������� ����������, ����� 6-�� ���� *********************************************************************************

	-- ����� ������� ��������, ����������� �� ��� �����, ����� ��� ������ � �������� Accdess ==================================

	-- 1-� ���������. ���������� �������� � ������� ������ � ������ ������������� � 'ag', 'iv', 'ia'. ��� ������ ����� ������� �������, ����� � "ags_fnIpgChRsltCstUtlPercentBrn_2408_tbl_part_1".

	select 
		rowNum, ag_accepted
		, ag_acceptedAccum
		, ag_acceptedAndInProcessTtl
		, ag_acceptedAndInProcessTtlAccum
		, ag_acceptedPrevYears
		, ag_acceptedPrevYearsAccum
		, ag_acceptedRalp
		, ag_acceptedRalpAccum
		, ag_acceptedTtl
		, ag_acceptedTtlAccum
		, ag_agFeeAccepted
		, ag_agFeeAcceptedAccum
		, ag_agFeeInProcess
		, ag_agFeeInProcessAccum
		, ag_agFeeNotArrived
		, ag_agFeeNotArrivedAccum
		, ag_agFeePresented
		, ag_agFeePresentedAccum
		, ag_agFeeReturned
		, ag_agFeeReturnedAccum
		, ag_cctSum
		, ag_cctSumAccum
		, ag_inProcess
		, ag_inProcessAccum
		, ag_inProcessPrevYears
		, ag_inProcessPrevYearsAccum
		, ag_inProcessRalp
		, ag_inProcessRalpAccum
		, ag_inProcessTtl
		, ag_inProcessTtlAccum
		, ag_ipgpKey
		, ag_ipgpSmTtl
		, ag_iShKey
		, ag_lim
		, ag_LimPercent
		, ag_LimPercentInProcess
		, ag_MnrlSum
		, ag_MnrlSumAccum
		, ag_notArrived
		, ag_notArrivedAccum
		, ag_notArrivedPrevYears
		, ag_notArrivedPrevYearsAccum
		, ag_notArrivedRalp
		, ag_notArrivedRalpAccum
		, ag_notArrivedTtl
		, ag_notArrivedTtlAccum
		, ag_percentDev
		, ag_percentDevInProcess
		, ag_percentPlDev
		, ag_percentPlDevInProcess
		, ag_Pl
		, ag_PlAccum
		, ag_PlFulfillment
		, ag_PlNonFulfillment
		, ag_PlNonFulfillment_review
		, ag_PlOverFulfillment
		, ag_PlOverLimit
		, ag_PlOverLimit_review
		, ag_PlPercent
		, ag_PlPercentInProcess
		, ag_PlPercentMinusOverFulf
		, ag_PlPercentMinusOverFulfInProcess
		, ag_PlRestLimit
		, ag_PlRestLimit_review
		, ag_presented
		, ag_presentedAccum
		, ag_presentedAll
		, ag_presentedAllAccum
		, ag_presentedAllModul
		, ag_presentedAllModulAccum
		, ag_presentedPrevYears
		, ag_presentedPrevYearsAccum
		, ag_presentedRalp
		, ag_presentedRalpAccum
		, ag_presentedTtl
		, ag_presentedTtlAccum
		, ag_restOfLimit
		, ag_restOfLimitInProcess
		, ag_returned
		, ag_returnedAccum
		, ag_returnedPrevYears
		, ag_returnedPrevYearsAccum
		, ag_returnedRalp
		, ag_returnedRalpAccum
		, ag_returnedTtl
		, ag_returnedTtlAccum
		, ag_storageSum
		, ag_storageSumAccum
		, ia_accepted
		, ia_acceptedAccum
		, ia_acceptedAndInProcessTtl
		, ia_acceptedAndInProcessTtlAccum
		, ia_acceptedPrevYears
		, ia_acceptedPrevYearsAccum
		, ia_acceptedRalp
		, ia_acceptedRalpAccum
		, ia_acceptedTtl
		, ia_acceptedTtlAccum
		, ia_agFeeAccepted
		, ia_agFeeAcceptedAccum
		, ia_agFeeInProcess
		, ia_agFeeInProcessAccum
		, ia_agFeeNotArrived
		, ia_agFeeNotArrivedAccum
		, ia_agFeePresented
		, ia_agFeePresentedAccum
		, ia_agFeeReturned
		, ia_agFeeReturnedAccum
		, ia_cctSum
		, ia_cctSumAccum
		, ia_inProcess
		, ia_inProcessAccum
		, ia_inProcessPrevYears
		, ia_inProcessPrevYearsAccum
		, ia_inProcessRalp
		, ia_inProcessRalpAccum
		, ia_inProcessTtl
		, ia_inProcessTtlAccum
		, ia_iShKey
		, ia_lim
		, ia_MnrlSum
		, ia_MnrlSumAccum
		, ia_notArrived
		, ia_notArrivedAccum
		, ia_notArrivedPrevYears
		, ia_notArrivedPrevYearsAccum
		, ia_notArrivedRalp
		, ia_notArrivedRalpAccum
		, ia_notArrivedTtl
		, ia_notArrivedTtlAccum
		, ia_percentDev
		, ia_percentDevInProcess
		, ia_percentPlDev
		, ia_percentPlDevInProcess
		, ia_presented
		, ia_presentedAccum
		, ia_presentedAll
		, ia_presentedAllAccum
		, ia_presentedAllModul
		, ia_presentedAllModulAccum
		, ia_presentedPrevYears
		, ia_presentedPrevYearsAccum
		, ia_presentedRalp
		, ia_presentedRalpAccum
		, ia_presentedTtl
		, ia_presentedTtlAccum
		, ia_restOfLimit
		, ia_restOfLimitInProcess
		, ia_returned
		, ia_returnedAccum
		, ia_returnedPrevYears
		, ia_returnedPrevYearsAccum
		, ia_returnedRalp
		, ia_returnedRalpAccum
		, ia_returnedTtl
		, ia_returnedTtlAccum
		, ia_storageSum
		, ia_storageSumAccum
		, iv_ipgpKey
		, iv_ipgpSmTtl
		, iv_iShKey
		, iv_lim
		, iv_LimPercent
		, iv_LimPercentInProcess
		, iv_Pl
		, iv_PlAccum
		, iv_PlFulfillment
		, iv_PlNonFulfillment
		, iv_PlNonFulfillment_review
		, iv_PlOverFulfillment
		, iv_PlOverLimit
		, iv_PlOverLimit_review
		, iv_PlPercent
		, iv_PlPercentInProcess
		, iv_PlPercentMinusOverFulf
		, iv_PlPercentMinusOverFulfInProcess
		, iv_PlRestLimit
		, iv_PlRestLimit_review
	from @TableFnIpgChRsltCstUtlPercentBrn_2408

	-- 2-� ���������. ���������� �������� � ������� ������ � ������ �� ������������� � 'ag', 'iv', 'ia'. ��� ������ ����� ������� �������, ����� � "ags_fnIpgChRsltCstUtlPercentBrn_2408_tbl_part_2".

	select
		rowNum
		, branch
		, branchName
		, cstAgPnCode
		, cstaInvestor
		, cstapKey
		, dateRslt
		, ipgChKey
		, ipgCount
		, ipgKey
		, mCs
		, mHy
		, mKey
		, mNm
		, mNum
		, mQ
		, np_accepted
		, np_acceptedAccum
		, np_acceptedAndInProcessTtl
		, np_acceptedAndInProcessTtlAccum
		, np_acceptedPrevYears
		, np_acceptedPrevYearsAccum
		, np_acceptedRalp
		, np_acceptedRalpAccum
		, np_acceptedTtl
		, np_acceptedTtlAccum
		, np_agFeeAccepted
		, np_agFeeAcceptedAccum
		, np_agFeeInProcess
		, np_agFeeInProcessAccum
		, np_agFeeNotArrived
		, np_agFeeNotArrivedAccum
		, np_agFeePresented
		, np_agFeePresentedAccum
		, np_agFeeReturned
		, np_agFeeReturnedAccum
		, np_cctSum
		, np_cctSumAccum
		, np_inProcess
		, np_inProcessAccum
		, np_inProcessPrevYears
		, np_inProcessPrevYearsAccum
		, np_inProcessRalp
		, np_inProcessRalpAccum
		, np_inProcessTtl
		, np_inProcessTtlAccum
		, np_iShKey
		, np_lim
		, np_MnrlSum
		, np_MnrlSumAccum
		, np_notArrived
		, np_notArrivedAccum
		, np_notArrivedPrevYears
		, np_notArrivedPrevYearsAccum
		, np_notArrivedRalp
		, np_notArrivedRalpAccum
		, np_notArrivedTtl
		, np_notArrivedTtlAccum
		, np_presented
		, np_presentedAccum
		, np_presentedAll
		, np_presentedAllAccum
		, np_presentedAllModul
		, np_presentedAllModulAccum
		, np_presentedPrevYears
		, np_presentedPrevYearsAccum
		, np_presentedRalp
		, np_presentedRalpAccum
		, np_presentedTtl
		, np_presentedTtlAccum
		, np_restOfLimit
		, np_restOfLimitInProcess
		, np_returned
		, np_returnedAccum
		, np_returnedPrevYears
		, np_returnedPrevYearsAccum
		, np_returnedRalp
		, np_returnedRalpAccum
		, np_returnedTtl
		, np_returnedTtlAccum
		, np_storageSum
		, np_storageSumAccum
		, ogaKey
		, ogNm
		, oh_accepted
		, oh_acceptedAccum
		, oh_acceptedAndInProcessTtl
		, oh_acceptedAndInProcessTtlAccum
		, oh_acceptedPrevYears
		, oh_acceptedPrevYearsAccum
		, oh_acceptedTtl
		, oh_acceptedTtlAccum
		, oh_agFeeAccepted
		, oh_agFeeAcceptedAccum
		, oh_agFeeInProcess
		, oh_agFeeInProcessAccum
		, oh_agFeeNotArrived
		, oh_agFeeNotArrivedAccum
		, oh_agFeePresented
		, oh_agFeePresentedAccum
		, oh_agFeeReturned
		, oh_agFeeReturnedAccum
		, oh_inProcess
		, oh_inProcessAccum
		, oh_inProcessPrevYears
		, oh_inProcessPrevYearsAccum
		, oh_inProcessTtl
		, oh_inProcessTtlAccum
		, oh_notArrived
		, oh_notArrivedAccum
		, oh_notArrivedPrevYears
		, oh_notArrivedPrevYearsAccum
		, oh_notArrivedTtl
		, oh_notArrivedTtlAccum
		, oh_presented
		, oh_presentedAccum
		, oh_presentedAll
		, oh_presentedAllAccum
		, oh_presentedAllModul
		, oh_presentedAllModulAccum
		, oh_presentedPrevYears
		, oh_presentedPrevYearsAccum
		, oh_presentedTtl
		, oh_presentedTtlAccum
		, oh_returned
		, oh_returnedAccum
		, oh_returnedPrevYears
		, oh_returnedPrevYearsAccum
		, oh_returnedTtl
		, oh_returnedTtlAccum
		, uk_accepted
		, uk_acceptedAccum
		, uk_acceptedAndInProcessTtl
		, uk_acceptedAndInProcessTtlAccum
		, uk_acceptedPrevYears
		, uk_acceptedPrevYearsAccum
		, uk_acceptedRalp
		, uk_acceptedRalpAccum
		, uk_acceptedTtl
		, uk_acceptedTtlAccum
		, uk_agFeeAccepted
		, uk_agFeeAcceptedAccum
		, uk_agFeeInProcess
		, uk_agFeeInProcessAccum
		, uk_agFeeNotArrived
		, uk_agFeeNotArrivedAccum
		, uk_agFeePresented
		, uk_agFeePresentedAccum
		, uk_agFeeReturned
		, uk_agFeeReturnedAccum
		, uk_cctSum
		, uk_cctSumAccum
		, uk_inProcess
		, uk_inProcessAccum
		, uk_inProcessPrevYears
		, uk_inProcessPrevYearsAccum
		, uk_inProcessRalp
		, uk_inProcessRalpAccum
		, uk_inProcessTtl
		, uk_inProcessTtlAccum
		, uk_ipgpKey
		, uk_ipgpSmTtl
		, uk_iShKey
		, uk_lim
		, uk_LimPercent
		, uk_LimPercentInProcess
		, uk_MnrlSum
		, uk_MnrlSumAccum
		, uk_notArrived
		, uk_notArrivedAccum
		, uk_notArrivedPrevYears
		, uk_notArrivedPrevYearsAccum
		, uk_notArrivedRalp
		, uk_notArrivedRalpAccum
		, uk_notArrivedTtl
		, uk_notArrivedTtlAccum
		, uk_percentDev
		, uk_percentDevInProcess
		, uk_percentPlDev
		, uk_percentPlDevInProcess
		, uk_Pl
		, uk_PlAccum
		, uk_PlFulfillment
		, uk_PlNonFulfillment
		, uk_PlNonFulfillment_review
		, uk_PlOverFulfillment
		, uk_PlOverLimit
		, uk_PlOverLimit_review
		, uk_PlPercent
		, uk_PlPercentInProcess
		, uk_PlPercentMinusOverFulf
		, uk_PlPercentMinusOverFulfInProcess
		, uk_PlRestLimit
		, uk_PlRestLimit_review
		, uk_presented
		, uk_presentedAccum
		, uk_presentedAll
		, uk_presentedAllAccum
		, uk_presentedAllModul
		, uk_presentedAllModulAccum
		, uk_presentedPrevYears
		, uk_presentedPrevYearsAccum
		, uk_presentedRalp
		, uk_presentedRalpAccum
		, uk_presentedTtl
		, uk_presentedTtlAccum
		, uk_restOfLimit
		, uk_restOfLimitInProcess
		, uk_returned
		, uk_returnedAccum
		, uk_returnedPrevYears
		, uk_returnedPrevYearsAccum
		, uk_returnedRalp
		, uk_returnedRalpAccum
		, uk_returnedTtl
		, uk_returnedTtlAccum
		, uk_storageSum
		, uk_storageSumAccum
		, yKey
		, yyyy
	from @TableFnIpgChRsltCstUtlPercentBrn_2408
	
	-- ����� ������� ��������, ����������� �� ��� �����, ����� ��� ������ � �������� Accdess. ��������� =======================

	---- 2...

	-- �������� ��� ������� ��� ���������� �������� ===========================================================================
	
	declare @TableFnIpgChRsltCstUtlPercentBrnRep01_2408 TABLE 
		(
			-- ������������ ����:
			-- ����� ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
			rowNum int, ogNm nvarchar(255), branchName nvarchar(255), cstAgPnCode nvarchar(255), cstapCstName nvarchar(max)
			, lim money, ag_lim money, ag_Ful_OverFul money, ag_LimPc money, ag_PlOverLimit_  money
			, iv_lim money, uk_lim money
			, ipgSh nvarchar(50)
			-- ������� ����� ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
			-- ���� � ���������� ����������� ������ ---------------------------------------------------------------------------------------------------------------
			, ag_PlAccum money, ag_PlFulfillment money, ag_PlPz float, ag_PlOverFulfillment money, ag_PlPercent float, ag_PlFulfillmentAll money
			-- ���� � ���������� �� ����� -------------------------------------------------------------------------------------------------------------------------
			, ag_Pl_M money, ag_acceptedTtl_M money, ag_acceptedNot money, ag_PlPz_M float, mn nvarchar(50)
			-- �������������� ����� :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
			-- ���� � ���������� ����������� ������ ---------------------------------------------------------------------------------------------------------------
			, PrM_ag_PlAccum money, PrM_ag_PlFulfillment money
			, PrM_ag_PlPz float
			, PrM_ag_PlOverFulfillment money, PrM_ag_PlPercent float, PrM_ag_PlFulfillmentAll money
			-- ���� � ���������� �� ����� -------------------------------------------------------------------------------------------------------------------------
			, PrM_ag_Pl_M money, PrM_ag_acceptedTtl_M money, PrM_ag_PlPz_M float, PrM_mnPrevious nvarchar(50)
			-- �����, �������������� ��������������� (��� ������ �����) :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
			-- ���� � ���������� ����������� ������ ---------------------------------------------------------------------------------------------------------------
			, PrM_ag_PlAccum2 money, PrM_ag_PlFulfillment2 money
			, PrM_ag_PlPz2 float
			, PrM_ag_PlOverFulfillment2 money, PrM_ag_PlPercent2 float, PrM_ag_PlFulfillment2All money
			-- ���� � ���������� �� ����� -------------------------------------------------------------------------------------------------------------------------
			, PrM_ag_Pl_M2 money, PrM_ag_acceptedTtl_M2 money, PrM_ag_PlPz_M2 float, PrM_mnPrevious2 nvarchar(50)
			-- ������� ��� �������������� ��������� :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
			, np_acceptedTtlAccum money
		)

	-- ��������� �������������� ��������
	insert into @TableFnIpgChRsltCstUtlPercentBrnRep01_2408  
		(
			-- ������������ ����:
			-- ����� ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
			rowNum, ogNm, branchName, cstAgPnCode, cstapCstName
			, lim, ag_lim, ag_Ful_OverFul, ag_LimPc, ag_PlOverLimit_ 
			, iv_lim, uk_lim
			, ipgSh
			-- ������� ����� ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
			-- ���� � ���������� ����������� ������ -----------------------------------------------------------------------------------------------------------
			, ag_PlAccum, ag_PlFulfillment, ag_PlPz, ag_PlOverFulfillment, ag_PlPercent, ag_PlFulfillmentAll
			-- ���� � ���������� �� ����� ---------------------------------------------------------------------------------------------------------------------
			, ag_Pl_M, ag_acceptedTtl_M, ag_acceptedNot, ag_PlPz_M, mn
			-- �������������� ����� :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
			-- ���� � ���������� ����������� ������ -----------------------------------------------------------------------------------------------------------
			, PrM_ag_PlAccum, PrM_ag_PlFulfillment
			, PrM_ag_PlPz
			, PrM_ag_PlOverFulfillment, PrM_ag_PlPercent, PrM_ag_PlFulfillmentAll
			-- ���� � ���������� �� ����� ---------------------------------------------------------------------------------------------------------------------
			, PrM_ag_Pl_M, PrM_ag_acceptedTtl_M, PrM_ag_PlPz_M, PrM_mnPrevious
			-- �����, �������������� ��������������� (��� ������ �����) :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
			-- ���� � ���������� ����������� ������ -----------------------------------------------------------------------------------------------------------
			, PrM_ag_PlAccum2, PrM_ag_PlFulfillment2
			, PrM_ag_PlPz2
			, PrM_ag_PlOverFulfillment2, PrM_ag_PlPercent2, PrM_ag_PlFulfillment2All
			-- ���� � ���������� �� ����� ---------------------------------------------------------------------------------------------------------------------
			, PrM_ag_Pl_M2, PrM_ag_acceptedTtl_M2, PrM_ag_PlPz_M2, PrM_mnPrevious2
			-- ������� ��� �������������� ��������� :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
			, np_acceptedTtlAccum
		)
	select 
		z.rowNum, z.ogNm, z.branchName, z.cstAgPnCode, z.cstapCstName
		, z.lim, z.ag_lim, z.ag_Ful_OverFul, z.ag_LimPc, z.ag_PlOverLimit_
		, z.iv_lim, z.uk_lim
		, IIf(ag_lim > 0, '���������', IIf(iv_lim > 0,'������.', '������')) AS ipgSh
		-- ������� ����� ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		, z.ag_PlAccum, z.ag_PlFulfillment, z.ag_PlPz, z.ag_PlOverFulfillment, z.ag_PlPercent
		, isnull(z.ag_PlFulfillment, 0) + isnull(z.ag_PlOverFulfillment, 0) AS ag_PlFulfillmentAll -- !!! ����������, ���� ��� �� ����� ��������
		, z.ag_Pl_M, z.ag_acceptedTtl_M, z.ag_acceptedNot, z.ag_PlPz_M, z.mn
		-- �������������� ����� :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		, y.ag_PlAccum AS PrM_ag_PlAccum, y.ag_PlFulfillment AS PrM_ag_PlFulfillment
		, y.ag_PlPz AS PrM_ag_PlPz
		, y.ag_PlOverFulfillment AS PrM_ag_PlOverFulfillment, y.ag_PlPercent AS PrM_ag_PlPercent
		, isnull(y.ag_PlFulfillment, 0) + isnull(y.ag_PlOverFulfillment, 0) AS PrM_ag_PlFulfillmentAll -- !!! ����������, ���� ��� �� ����� ��������
		, y.ag_Pl_M AS PrM_ag_Pl_M, y.ag_acceptedTtl_M AS PrM_ag_acceptedTtl_M, y.ag_PlPz_M AS PrM_ag_PlPz_M, y.mnPrevious AS PrM_mnPrevious
		-- �����, �������������� ��������������� (��� ������ �����) :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		, x.ag_PlAccum AS PrM_ag_PlAccum2, x.ag_PlFulfillment AS PrM_ag_PlFulfillment2
		, x.ag_PlPz AS PrM_ag_PlPz2
		, x.ag_PlOverFulfillment AS PrM_ag_PlOverFulfillment2, x.ag_PlPercent AS PrM_ag_PlPercent2
		, isnull(x.ag_PlFulfillment, 0) + isnull(x.ag_PlOverFulfillment, 0) AS PrM_ag_PlFulfillment2All -- !!! ����������, ���� ��� �� ����� ��������
		, x.ag_Pl_M AS PrM_ag_Pl_M2, x.ag_acceptedTtl_M AS PrM_ag_acceptedTtl_M2, x.ag_PlPz_M AS PrM_ag_PlPz_M2, x.mnPrevious AS PrM_mnPrevious2
		, z.np_acceptedTtlAccum
	from
		(
			-- ������� ����� ==================================================================================================================================
			SELECT 
				za.rowNum, za.ogNm, 
				isnull(za.branch, -1) as branch, 
				za.branchName, za.cstAgPnCode, za.cstapCstName, za.lim, za.ag_lim, za.ag_Ful_OverFul, 
				za.ag_LimPc, za.ag_PlOverLimit_, za.iv_lim, 
				za.uk_lim, 
				za.ag_PlAccum, za.ag_PlFulfillment, za.ag_PlPz, za.ag_PlOverFulfillment, za.ag_PlPercent, 
				za.ag_Pl_M, za.ag_acceptedTtl_M, za.ag_acceptedNot,
				za.ag_PlPz_M, za.mn, za.ogNmSort, za.cstAgPnCodeSort, 
				IIf(za.cstAgPnCode = '�����' And za.branch = 0, 1, 0) AS wr,
				za.np_acceptedTtlAccum
			FROM 
				(
					SELECT 
						p.rowNum, IsNull(p.ogNm,'�����') AS ogNm, p.branch, p.branchName
						, IsNull(p.cstAgPnCode, '�����') AS cstAgPnCode, c.cstapCstName
						, IsNull(p.ag_lim, 0) + IsNull(p.iv_lim, 0) + IsNull(p.uk_lim, 0) AS lim
						, p.ag_lim 
						, IIf(p.ag_PlFulfillment + p.ag_PlOverFulfillment = 0, Null, p.ag_PlFulfillment + p.ag_PlOverFulfillment) AS ag_Ful_OverFul
						, CASE WHEN p.ag_lim IS NULL OR p.ag_lim = 0 THEN NULL ELSE (ISNULL(p.ag_PlFulfillment,0)+ISNULL(p.ag_PlOverFulfillment,0))/NULLIF(p.ag_lim,0) END AS ag_LimPc
						, IIf(ag_PlOverLimit = 0, Null, ag_PlOverLimit) AS ag_PlOverLimit_, p.iv_lim, p.uk_lim
						, IIf(p.ag_PlAccum = 0, Null, p.ag_PlAccum) AS ag_PlAccum
						, IIf(p.ag_PlFulfillment = 0, Null, p.ag_PlFulfillment) AS ag_PlFulfillment
						, p.ag_PlPercentMinusOverFulf AS ag_PlPz -- ����� ����� ��������� ���������� �������
						, IIf(p.ag_PlOverFulfillment = 0, Null, p.ag_PlOverFulfillment) AS ag_PlOverFulfillment, p.ag_PlPercent
						, p.ag_Pl AS ag_Pl_M, p.ag_acceptedTtl AS ag_acceptedTtl_M
						, p.ag_inProcessTtlAccum as ag_acceptedNot -- ��� �� ����� *���������������*, ����� ��������. �� ��� ���� "�� ������������"
						, CASE WHEN p.ag_Pl IS NULL OR p.ag_Pl = 0 THEN NULL ELSE p.ag_acceptedTtl/NULLIF(p.ag_Pl,0) END AS ag_PlPz_M
						, choose(month(dateRslt), '������', '�������', '����', '������', '���', '����', '����', '������', '��������', '�������', '������', '�������') mn
						, p.ogNm AS ogNmSort, p.cstAgPnCode AS cstAgPnCodeSort, p.np_acceptedTtlAccum
					FROM @TableFnIpgChRsltCstUtlPercentBrn_2408 AS p 
						LEFT JOIN ags.cstAgPn AS c ON p.cstAgPnCode = c.cstapIpgPnN
					WHERE 
						-- 06.02.2025 ���� ��� :
						-- p.dateRslt = @MounthEndDate AND IsNull(p.ag_lim, 0) + IsNull(p.iv_lim, 0) + IsNull(p.uk_lim, 0) > 0
						-- 06.02.2025 ��� ����� �������� ��, ��� ���� �����-�� �����. �� � ��� �������� ������� ��� �������...
						p.dateRslt = @MounthEndDate AND 
							(
								IsNull(p.ag_lim, 0) + IsNull(p.iv_lim, 0) + IsNull(p.uk_lim, 0) > 0
								or 
								not(p.np_acceptedTtlAccum is null)
							)
				)  AS za
			WHERE IIf(za.cstAgPnCode = '�����' And za.branch = 0, 1, 0) = 0
			-- ������� ����� ==================================================================================================================================
		) as z
			LEFT JOIN 
				( 
					-- �������������� ����� ===================================================================================================================
					Select 
						zb.ogNm, 
						isnull(zb.branch, -1) as branch, zb.branchName, 
						zb.cstAgPnCode, zb.ag_PlAccum, zb.ag_PlFulfillment, zb.ag_PlPz, 
						zb.ag_PlOverFulfillment, zb.ag_PlPercent, 
						zb.ag_Pl_M, zb.ag_acceptedTtl_M, zb.ag_PlPz_M, zb.mnPrevious
					From
						(
							SELECT 
								IsNull(p.ogNm, '�����') AS ogNm, p.branch, p.branchName, 
								IsNull(p.cstAgPnCode, '�����') AS cstAgPnCode, IIf(p.ag_PlAccum = 0, Null, p.ag_PlAccum) AS ag_PlAccum, 
								IIf(p.ag_PlFulfillment = 0, Null, p.ag_PlFulfillment) AS ag_PlFulfillment, 
								p.ag_PlPercentMinusOverFulf AS ag_PlPz,  -- ����� ����� ��������� ���������� �������
								IIf(p.ag_PlOverFulfillment = 0, Null, p.ag_PlOverFulfillment) AS ag_PlOverFulfillment, p.ag_PlPercent, 
								p.ag_Pl AS ag_Pl_M, p.ag_acceptedTtl AS ag_acceptedTtl_M, 
								CASE WHEN p.ag_Pl IS NULL OR p.ag_Pl = 0 THEN NULL ELSE p.ag_acceptedTtl/NULLIF(p.ag_Pl,0) END AS ag_PlPz_M, 
								IIf(
										dateRslt is null, 
										Null, 
										choose(month(dateRslt), 
											'������', '�������', '����', '������', '���', '����', '����', '������', '��������', '�������', '������', '�������')
									) AS mnPrevious 
							FROM @TableFnIpgChRsltCstUtlPercentBrn_2408 AS p 
								LEFT JOIN ags.cstAgPn AS c ON p.cstAgPnCode = c.cstapIpgPnN 
							WHERE
								p.dateRslt = IIf
									(
										Month(@MounthEndDate) = 1, 
										'0001-01-01', 
										EOMONTH(DATEFROMPARTS(Year(@MounthEndDate), Month(@MounthEndDate)-1, 1)) -- ������� ���� ��������������� ������
									) 
									And 
									(IsNull(p.ag_lim, 0) + IsNull(p.iv_lim, 0) + IsNull(p.uk_lim, 0)) > 0
						) as zb
					WHERE IIf(zb.cstAgPnCode = '�����' And zb.branch = 0, 1, 0) = 0
					-- �������������� �����. ��������� ========================================================================================================
				)  AS y ON z.branch = y.branch AND z.ogNm = y.ogNm AND z.cstAgPnCode = y.cstAgPnCode
			LEFT JOIN 
				(
					-- ��� ������ ����� =======================================================================================================================
					SELECT 
						zc.ogNm, 
						isnull(zc.branch, -1) as branch, zc.branchName,  
						zc.cstAgPnCode, zc.ag_PlAccum, zc.ag_PlFulfillment, zc.ag_PlPz, zc.ag_PlOverFulfillment, zc.ag_PlPercent, zc.ag_Pl_M, 
						zc.ag_acceptedTtl_M, zc.ag_PlPz_M, zc.mnPrevious 
					FROM 
						(
							SELECT 
								IsNull(p.ogNm, '�����') AS ogNm, p.branch, p.branchName
								, IsNull(p.cstAgPnCode, '�����') AS cstAgPnCode, IIf(p.ag_PlAccum = 0, Null, p.ag_PlAccum) AS ag_PlAccum, 
								IIf(p.ag_PlFulfillment = 0, Null, p.ag_PlFulfillment) AS ag_PlFulfillment, 
								p.ag_PlPercentMinusOverFulf AS ag_PlPz, -- ����� ����� ��������� ���������� �������
								IIf(p.ag_PlOverFulfillment = 0, Null, p.ag_PlOverFulfillment) AS ag_PlOverFulfillment, 
								p.ag_PlPercent, p.ag_Pl AS ag_Pl_M, p.ag_acceptedTtl AS ag_acceptedTtl_M, 
								CASE WHEN p.ag_Pl IS NULL OR p.ag_Pl = 0 THEN NULL ELSE p.ag_acceptedTtl/NULLIF(p.ag_Pl,0) END AS ag_PlPz_M, 
								IIf(
										dateRslt is null,
										Null,
										choose(month(dateRslt), 
											'������', '�������', '����', '������', '���', '����', '����', '������', '��������', '�������', '������', '�������')
									) AS mnPrevious 
							FROM 
								@TableFnIpgChRsltCstUtlPercentBrn_2408 AS p 
									LEFT JOIN ags.cstAgPn AS c ON p.cstAgPnCode = c.cstapIpgPnN 
							WHERE 
								p.dateRslt = IIf
									(
										Month(@MounthEndDate) < 3, 
										'0001-01-01', 
										EOMONTH(DATEFROMPARTS(Year(@MounthEndDate), Month(@MounthEndDate) - 2, 1)) -- ������� ���� ������, ��� ������ �����
									)
								And (IsNull(p.ag_lim, 0) + IsNull(p.iv_lim, 0 ) + IsNull(p.uk_lim, 0)) > 0
						) AS zc
					WHERE IIf(zc.cstAgPnCode = '�����' And zc.branch = 0, 1, 0) = 0
					-- ��� ������ �����. ��������� ============================================================================================================
				) AS x ON (z.branch = x.branch) AND (z.ogNm = x.ogNm) AND (z.cstAgPnCode = x.cstAgPnCode)
	ORDER BY z.ogNmSort, z.branchName, z.cstAgPnCodeSort;

	-- 3-� ���������. ��� ����� � "ags_fnIpgChRsltCstUtlPercentBrnRep01_2408_tbl". ��� ��� ���������� �������� �� �� ���������.

	select * from @TableFnIpgChRsltCstUtlPercentBrnRep01_2408

	---- 3...

	-- 4-� ���������. ��� ����� � "ags_fnIpgChRsltCstUtlPercentBrnRep02_2408_tbl". ��� ��� ���������� �������� � ��� ������.

	SELECT  
		-- ����� ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		o.rowNum, iif(o.ogNm = '�����', '�', o.ipgSh) as ipgSh, lmm.lim as limSort
		, iif(o.branchName is null, o.ogNm, null) as ogNm, iif(o.branchName=o.ogNm, '����������� ����',o.branchName ) as branchName,  o.lim, o.ag_lim
		, o.cstAgPnCode -- �������� ��, ����� ����� �������, �� � ���� ���� ����� �������� "�����" ��� Null
		-- ������� ����� ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		-- ���� � ���������� ����������� ������ ---------------------------------------------------------------------------------------------------------------
		, o.ag_Ful_OverFul, o.ag_LimPc, o.ag_PlOverLimit_, o.iv_lim, o.uk_lim 
		, o.ag_PlAccum, o.ag_PlFulfillment, o.ag_PlPz, o.ag_PlOverFulfillment, o.ag_PlPercent
		, iif(o.ag_PlFulfillmentAll=0, null, o.ag_PlFulfillmentAll) as ag_PlFulfillmentAll, iif(o.ag_acceptedNot=0, null, o.ag_acceptedNot) as ag_acceptedNot
		-- ���� � ���������� �� ����� -------------------------------------------------------------------------------------------------------------------------
		, o.ag_Pl_M, o.ag_acceptedTtl_M, o.ag_PlPz_M, o.mn
		-- �������������� ����� :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		-- ���� � ���������� ����������� ������ ---------------------------------------------------------------------------------------------------------------
		, o.PrM_ag_PlAccum, o.PrM_ag_PlFulfillment, o.PrM_ag_PlPz, o.PrM_ag_PlOverFulfillment, o.PrM_ag_PlPercent
		, iif(o.PrM_ag_PlFulfillmentAll=0, null, o.PrM_ag_PlFulfillmentAll) as PrM_ag_PlFulfillmentAll
		-- ���� � ���������� �� ����� -------------------------------------------------------------------------------------------------------------------------
		, o.PrM_ag_Pl_M, o.PrM_ag_acceptedTtl_M, o.PrM_ag_PlPz_M, o.PrM_mnPrevious
		-- �����, �������������� ��������������� (��� ������ �����) :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		-- ���� � ���������� ����������� ������ ---------------------------------------------------------------------------------------------------------------
		, o.PrM_ag_PlAccum2, o.PrM_ag_PlFulfillment2, o.PrM_ag_PlPz2, o.PrM_ag_PlOverFulfillment2, o.PrM_ag_PlPercent2
		, iif(o.PrM_ag_PlFulfillment2All=0, null, o.PrM_ag_PlFulfillment2All) as PrM_ag_PlFulfillment2All
		-- ���� � ���������� �� ����� -------------------------------------------------------------------------------------------------------------------------
		, o.PrM_ag_Pl_M2, o.PrM_ag_acceptedTtl_M2, o.PrM_ag_PlPz_M2, o.PrM_mnPrevious2
		-- ������� ��� �������������� ��������� :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		, o.np_acceptedTtlAccum   
	FROM  
		@TableFnIpgChRsltCstUtlPercentBrnRep01_2408 AS o  
			left join 
				( 
					SELECT ob.ogNm, ob.lim, ob.branchName 
					FROM @TableFnIpgChRsltCstUtlPercentBrnRep01_2408 AS ob 
					WHERE ob.cstAgPnCode = '�����' AND ob.branchName Is Null 
				) as lmm on o.ogNm = lmm.ogNm 
	WHERE o.cstAgPnCode = '�����'   
	UNION 
	select  
		null, '���������_', 0, '���������', null, null, null, null, null, null, null, null, null, null, null, null, null, null
		, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null
		, null, null, null, null, null, null, null, null, null  
	ORDER BY ipgSh, limSort DESC , lim DESC;

	-- �������� ��� ������� ��� ���������� ��������. ��������� ================================================================

	-- �������� ��� ������� � ����������� �������� ============================================================================

	-- 4. �������� ��� ������ � ����������� ��������, ������ ������� �� ���������

	declare @TableFnIpgChRsltCstUtlPercentBrnRepSrc01_2408 table
		(
			rowNum int, ogNm nvarchar(255), branchName nvarchar(255), cstAgPnCode nvarchar(255), cstapCstName nvarchar(max)
			, lim money, ag_lim money, ag_Ful_OverFul money, ag_LimPc money, ag_PlOverLimit_ money, iv_lim money, uk_lim money
			, ag_PlAccum money, ag_PlFulfillment money, ag_PlPz float, ag_PlOverFulfillment money, ag_PlPercent float
			, ag_PlFulfillmentAll  money
			, ag_Pl_M money, ag_acceptedTtl_M money, ag_acceptedNot money, ag_PlPz_M float, mn nvarchar(50)
			, ipgSh nvarchar(50)
			, ag_accepted money, ag_acceptedAccum money, ag_agFeeAccepted money, ag_agFeeAcceptedAccum money, ag_acceptedRalp money, ag_acceptedRalpAccum money
			, ag_storageSum money, ag_storageSumAccum money, ag_cctSum money, ag_cctSumAccum money, ag_MnrlSum money, ag_MnrlSumAccum money, np_lim money
			, np_iShKey int, np_accepted money, np_acceptedAccum money, np_agFeeAccepted money, np_agFeeAcceptedAccum money, np_acceptedRalp money, np_acceptedRalpAccum money
			, np_storageSum money, np_storageSumAccum money, np_cctSum money, np_cctSumAccum money, np_MnrlSum money, np_MnrlSumAccum money, np_acceptedTtl money, np_acceptedTtlAccum money
		)

	insert into @TableFnIpgChRsltCstUtlPercentBrnRepSrc01_2408
		(
			rowNum, ogNm, branchName, cstAgPnCode, cstapCstName
			, lim, ag_lim, ag_Ful_OverFul, ag_LimPc, ag_PlOverLimit_, iv_lim, uk_lim
			, ag_PlAccum, ag_PlFulfillment, ag_PlPz, ag_PlOverFulfillment, ag_PlPercent
			, ag_PlFulfillmentAll 
			, ag_Pl_M, ag_acceptedTtl_M, ag_acceptedNot, ag_PlPz_M, mn
			, ipgSh
			, ag_accepted, ag_acceptedAccum, ag_agFeeAccepted, ag_agFeeAcceptedAccum, ag_acceptedRalp, ag_acceptedRalpAccum
			, ag_storageSum, ag_storageSumAccum, ag_cctSum, ag_cctSumAccum, ag_MnrlSum, ag_MnrlSumAccum, np_lim
			, np_iShKey, np_accepted, np_acceptedAccum, np_agFeeAccepted, np_agFeeAcceptedAccum, np_acceptedRalp, np_acceptedRalpAccum
			, np_storageSum, np_storageSumAccum, np_cctSum, np_cctSumAccum, np_MnrlSum, np_MnrlSumAccum, np_acceptedTtl, np_acceptedTtlAccum
		)
	SELECT 
		z.rowNum, z.ogNm, z.branchName, z.cstAgPnCode, z.cstapCstName
		, z.lim, z.ag_lim, z.ag_Ful_OverFul, z.ag_LimPc, z.ag_PlOverLimit_, z.iv_lim, z.uk_lim
		, z.ag_PlAccum, z.ag_PlFulfillment, z.ag_PlPz, z.ag_PlOverFulfillment, z.ag_PlPercent
		, isnull(z.ag_PlFulfillment, 0) + isnull(z.ag_PlOverFulfillment, 0) AS ag_PlFulfillmentAll
		, z.ag_Pl_M, z.ag_acceptedTtl_M, z.ag_acceptedNot, z.ag_PlPz_M, z.mn
		, IIf(z.ag_lim > 0, '���������', IIf(z.iv_lim > 0, '������.', '������')) AS ipgSh
		, z.ag_accepted, z.ag_acceptedAccum, z.ag_agFeeAccepted, z.ag_agFeeAcceptedAccum, z.ag_acceptedRalp, z.ag_acceptedRalpAccum
		, z.ag_storageSum, z.ag_storageSumAccum, z.ag_cctSum, z.ag_cctSumAccum, z.ag_MnrlSum, z.ag_MnrlSumAccum, z.np_lim
		, z.np_iShKey, z.np_accepted, z.np_acceptedAccum, z.np_agFeeAccepted, z.np_agFeeAcceptedAccum, z.np_acceptedRalp, z.np_acceptedRalpAccum
		, z.np_storageSum, z.np_storageSumAccum, z.np_cctSum, z.np_cctSumAccum, z.np_MnrlSum, z.np_MnrlSumAccum, z.np_acceptedTtl, z.np_acceptedTtlAccum
	FROM 
		(
			SELECT 
				za.rowNum, za.ogNm, isnull(za.branch, -1) as branch, 
				za.branchName, za.cstAgPnCode, za.cstapCstName, za.lim, za.ag_lim, za.ag_Ful_OverFul, 
				za.ag_LimPc, za.ag_PlOverLimit_, za.iv_lim, 
				za.uk_lim, 
				za.ag_PlAccum, za.ag_PlFulfillment, za.ag_PlPz, za.ag_PlOverFulfillment, za.ag_PlPercent, 
				za.ag_Pl_M, za.ag_acceptedTtl_M, za.ag_acceptedNot,
				za.ag_PlPz_M, za.mn, za.ogNmSort, za.cstAgPnCodeSort, 
				IIf(za.cstAgPnCode = '�����' And za.branch = 0, 1, 0) AS wr,
				za.ag_accepted, za.ag_acceptedAccum, za.ag_agFeeAccepted, za.ag_agFeeAcceptedAccum, 
				za.ag_acceptedRalp, za.ag_acceptedRalpAccum, 
				za.ag_storageSum, za.ag_storageSumAccum, za.ag_cctSum, za.ag_cctSumAccum, za.ag_MnrlSum, za.ag_MnrlSumAccum, 
				za.np_lim, za.np_iShKey, za.np_accepted, za.np_acceptedAccum, za.np_agFeeAccepted, 
				za.np_agFeeAcceptedAccum, za.np_acceptedRalp, za.np_acceptedRalpAccum, 
				za.np_storageSum, za.np_storageSumAccum, za.np_cctSum, za.np_cctSumAccum, za.np_MnrlSum, 
				za.np_MnrlSumAccum, za.np_acceptedTtl, za.np_acceptedTtlAccum
			FROM 
				(
					SELECT --*
						p.rowNum, IsNull(p.ogNm, '�����') AS ogNm, p.branch, p.branchName
						, IsNull(p.cstAgPnCode, '�����') AS cstAgPnCode, c.cstapCstName
						, IsNull(p.ag_lim, 0) + IsNull(p.iv_lim, 0) + IsNull(p.uk_lim, 0) AS lim, p.ag_lim
						, IIf(p.ag_PlFulfillment + p.ag_PlOverFulfillment = 0, Null, p.ag_PlFulfillment + p.ag_PlOverFulfillment) AS ag_Ful_OverFul
						, CASE WHEN p.ag_lim IS NULL OR p.ag_lim = 0 THEN NULL ELSE (ISNULL(p.ag_PlFulfillment,0)+ISNULL(p.ag_PlOverFulfillment,0))/NULLIF(p.ag_lim,0) END AS ag_LimPc
						, IIf(p.ag_PlOverLimit = 0, Null, p.ag_PlOverLimit) AS ag_PlOverLimit_
						, p.iv_lim, p.uk_lim, IIf(p.ag_PlAccum = 0, Null, p.ag_PlAccum) AS ag_PlAccum
						, IIf(p.ag_PlFulfillment = 0, Null, p.ag_PlFulfillment) AS ag_PlFulfillment
						, CASE WHEN p.ag_PlAccum IS NULL OR p.ag_PlAccum = 0 THEN NULL ELSE p.ag_PlFulfillment/NULLIF(p.ag_PlAccum,0) END AS ag_PlPz
						, IIf(p.ag_PlOverFulfillment = 0, Null, p.ag_PlOverFulfillment) AS ag_PlOverFulfillment
						, p.ag_PlPercent
						, p.ag_Pl AS ag_Pl_M
						, p.ag_acceptedTtl AS ag_acceptedTtl_M
						-- �� ��������, ������, �� �����...
						, (IsNull(p.ag_presentedAccum, 0) + IsNull(p.ag_presentedRalpAccum, 0)) - (IsNull(p.ag_acceptedAccum, 0) + IsNull(p.ag_acceptedRalpAccum, 0)) AS ag_acceptedNot, 
						CASE WHEN p.ag_Pl IS NULL OR p.ag_Pl = 0 THEN NULL ELSE p.ag_acceptedTtl/NULLIF(p.ag_Pl,0) END AS ag_PlPz_M
						, choose(month(dateRslt), '������', '�������', '����', '������', '���', '����', '����', '������', '��������', '�������', '������', '�������') mn
						--, MonthName(Month([dateRslt])) AS mn, 
						, p.ogNm AS ogNmSort, p.cstAgPnCode AS cstAgPnCodeSort
						, p.ag_accepted, p.ag_acceptedAccum, p.ag_agFeeAccepted, p.ag_agFeeAcceptedAccum, p.ag_acceptedRalp, p.ag_acceptedRalpAccum
						, p.ag_storageSum, p.ag_storageSumAccum, p.ag_cctSum, p.ag_cctSumAccum, p.ag_MnrlSum, p.ag_MnrlSumAccum
						, p.np_lim, p.np_iShKey, p.np_accepted, p.np_acceptedAccum, p.np_agFeeAccepted, p.np_agFeeAcceptedAccum, p.np_acceptedRalp, p.np_acceptedRalpAccum
						, p.np_storageSum, p.np_storageSumAccum, p.np_cctSum, p.np_cctSumAccum, p.np_MnrlSum, p.np_MnrlSumAccum, p.np_acceptedTtl, p.np_acceptedTtlAccum
					FROM @TableFnIpgChRsltCstUtlPercentBrn_2408 as p --ipgChRsltPlCstPercent AS p @ipgCh @MounthEndDate
						LEFT JOIN ags.cstAgPn AS c ON p.cstAgPnCode = c.cstapIpgPnN
					WHERE 
						-- �����, �� ��������� �� ��������� ����,
						p.dateRslt = @MounthEndDate AND IsNull(p.ag_lim, 0) + IsNull(p.iv_lim, 0) + IsNull(p.uk_lim, 0) + IsNull(p.np_acceptedTtlAccum, 0) > 0
						--((IIf(IsNull([p]![ag_lim]), 0,[p]![ag_lim])+IIf(IsNull([p]![iv_lim]), 0,[p]![iv_lim])+IIf(IsNull([p]![uk_lim]), 0,[p]![uk_lim])+IIf(IsNull([p]![np_acceptedTtlAccum]), 0, [p]![np_acceptedTtlAccum]))>0))
						--(IsNull(p.ag_lim, 0) + IsNull(p.iv_lim, 0) + IsNull(p.uk_lim, 0) + IsNull(p.np_acceptedTtlAccum, 0)) > 0
				)  AS za
			WHERE IIf(za.cstAgPnCode = '�����' And za.branch = 0, 1, 0) = 0
			-- ORDER BY za.ogNm, za.branchName, za.cstAgPnCode
		)  AS z
	ORDER BY z.ogNmSort, z.branchName, z.cstAgPnCodeSort;

	-- 5-� ���������. ��� ����� � "ags_fnIpgChRsltCstUtlPercentBrnRepSrc01_2408".

	select * from @TableFnIpgChRsltCstUtlPercentBrnRepSrc01_2408

	-- 5. �������� ��� ������ � ����������� ��������, ������ ������� ��� ������

	-- 6-� ���������. ��� ����� � "ags_fnIpgChRsltCstUtlPercentBrnRepSrc02_2408".

	SELECT  
		o.rowNum, iif(o.ogNm = '�����', '�', o.ipgSh) as ipgSh, lmm.lim as limSort, 
		iif(o.branchName is null, o.ogNm, null) as ogNm,
		iif(o.branchName = o.ogNm, '����������� ����', o.branchName ) as branchName,  o.lim, o.ag_lim, 
		o.ag_Ful_OverFul, o.ag_LimPc, o.ag_PlOverLimit_, o.iv_lim, o.uk_lim,  
		o.ag_PlAccum, o.ag_PlFulfillment, o.ag_PlPz, o.ag_PlOverFulfillment, o.ag_PlPercent, 
		iif(o.ag_PlFulfillmentAll = 0, null, o.ag_PlFulfillmentAll) as ag_PlFulfillmentAll,
		o.ag_Pl_M, o.ag_acceptedTtl_M, 
		iif(o.ag_acceptedNot = 0, null, o.ag_acceptedNot) as ag_acceptedNot, 
		o.ag_PlPz_M, o.mn,  
		o.cstAgPnCode,
		o.ag_accepted, o.ag_acceptedAccum, o.ag_agFeeAccepted, o.ag_agFeeAcceptedAccum, 
		o.ag_acceptedRalp, o.ag_acceptedRalpAccum, 
		o.ag_storageSum, o.ag_storageSumAccum, o.ag_cctSum, o.ag_cctSumAccum, o.ag_MnrlSum, o.ag_MnrlSumAccum, 
		o.np_lim, o.np_iShKey, o.np_accepted, o.np_acceptedAccum, o.np_agFeeAccepted, 
		o.np_agFeeAcceptedAccum, o.np_acceptedRalp, o.np_acceptedRalpAccum, 
		o.np_storageSum, o.np_storageSumAccum, o.np_cctSum, o.np_cctSumAccum, o.np_MnrlSum, 
		o.np_MnrlSumAccum, o.np_acceptedTtl, o.np_acceptedTtlAccum
	FROM  
		@TableFnIpgChRsltCstUtlPercentBrnRepSrc01_2408 AS o  
			left join 
				( 
					SELECT ob.ogNm, ob.lim, ob.branchName 
					FROM @TableFnIpgChRsltCstUtlPercentBrnRepSrc01_2408 AS ob 
					WHERE ob.cstAgPnCode = '�����' AND ob.branchName Is Null 
				) as lmm on o.ogNm = lmm.ogNm 
	WHERE o.cstAgPnCode = '�����'
	UNION select  
		null, '���������_', 0, '���������', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 
		null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null    
	--from (select top 1 ipgKey from ags_ipg)
	ORDER BY ipgSh, limSort DESC , lim DESC;

	-- �������� ��� ������� � ����������� ��������. ��������� =================================================================

	-- ���������� ����������, ����� 6-�� ����. ��������� **********************************************************************
	-- ************************************************************************************************************************

	--SELECT * FROM ags.accnt;
	--SELECT * FROM ags.cn_inv_dbt_upl;
	--SELECT * FROM ags.cn_s_type;
END
GO


