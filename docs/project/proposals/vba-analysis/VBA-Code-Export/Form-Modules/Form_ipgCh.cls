VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_ipgCh"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

' ***************************************************************************************************************************************************
' заполняем таблицу освоения по стройкам. 27.09.2022
' ---------------------------------------------------------------------------------------------------------------------------------------------------
Private Sub btnMasteringCst_Click()
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Dim db As DAO.Database, dbAccessTest As dbAccess, myArray(1 To 124, 1 To 2) As Variant, strSql As String
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Const cstrTitle As String = "Процедура *Заполняем таблицу освоения по стройкам. Кнопка btnMasteringCst*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler
    
    ' формируем массив по принципу поле № 1 - откуда, поле № 2 - куда
    myArray(1, 1) = "dateRslt": myArray(1, 2) = "dateRslt"
    myArray(2, 1) = "ogNm": myArray(2, 2) = "ogNm"
    myArray(3, 1) = "cstAgPnCode": myArray(3, 2) = "cstAgPnCode"
    myArray(4, 1) = "ag_presentedTtl": myArray(4, 2) = "ag_presentedTtl"
    myArray(5, 1) = "ag_presentedTtlAccum": myArray(5, 2) = "ag_presentedTtlAccum"
    myArray(6, 1) = "ag_acceptedTtl": myArray(6, 2) = "ag_acceptedTtl"
    myArray(7, 1) = "ag_acceptedTtlAccum": myArray(7, 2) = "ag_acceptedTtlAccum"
    myArray(8, 1) = "ag_restOfLimit": myArray(8, 2) = "ag_restOfLimit"
    myArray(9, 1) = "ag_PlFulfillment": myArray(9, 2) = "ag_PlFulfillment"
    myArray(10, 1) = "ag_PlNonFulfillment": myArray(10, 2) = "ag_PlNonFulfillment"
    myArray(11, 1) = "ag_PlOverFulfillment": myArray(11, 2) = "ag_PlOverFulfillment"
    myArray(12, 1) = "ag_PlRestLimit": myArray(12, 2) = "ag_PlRestLimit"
    myArray(13, 1) = "ag_PlOverLimit": myArray(13, 2) = "ag_PlOverLimit"
    myArray(14, 1) = "ag_PlAccum": myArray(14, 2) = "ag_PlAccum"
    myArray(15, 1) = "ag_lim": myArray(15, 2) = "ag_lim"
    myArray(16, 1) = "ag_presented": myArray(16, 2) = "ag_presented"
    myArray(17, 1) = "ag_presentedAccum": myArray(17, 2) = "ag_presentedAccum"
    myArray(18, 1) = "ag_accepted": myArray(18, 2) = "ag_accepted"
    myArray(19, 1) = "ag_acceptedAccum": myArray(19, 2) = "ag_acceptedAccum"
    myArray(20, 1) = "ag_agFeePresented": myArray(20, 2) = "ag_agFeePresented"
    myArray(21, 1) = "ag_agFeePresentedAccum": myArray(21, 2) = "ag_agFeePresentedAccum"
    myArray(22, 1) = "ag_agFeeAccepted": myArray(22, 2) = "ag_agFeeAccepted"
    myArray(23, 1) = "ag_agFeeAcceptedAccum": myArray(23, 2) = "ag_agFeeAcceptedAccum"
    myArray(24, 1) = "ag_presentedRalp": myArray(24, 2) = "ag_presentedRalp"
    myArray(25, 1) = "ag_presentedRalpAccum": myArray(25, 2) = "ag_presentedRalpAccum"
    myArray(26, 1) = "ag_acceptedRalp": myArray(26, 2) = "ag_acceptedRalp"
    myArray(27, 1) = "ag_acceptedRalpAccum": myArray(27, 2) = "ag_acceptedRalpAccum"
    myArray(28, 1) = "ag_storageSum": myArray(28, 2) = "ag_storageSum"
    myArray(29, 1) = "ag_storageSumAccum": myArray(29, 2) = "ag_storageSumAccum"
    myArray(30, 1) = "ag_cctSum": myArray(30, 2) = "ag_cctSum"
    myArray(31, 1) = "ag_cctSumAccum": myArray(31, 2) = "ag_cctSumAccum"
    myArray(32, 1) = "ag_MnrlSum": myArray(32, 2) = "ag_MnrlSum"
    myArray(33, 1) = "ag_MnrlSumAccum": myArray(33, 2) = "ag_MnrlSumAccum"
    myArray(34, 1) = "ia_presentedTtl": myArray(34, 2) = "ia_presentedTtl"
    myArray(35, 1) = "ia_presentedTtlAccum": myArray(35, 2) = "ia_presentedTtlAccum"
    myArray(36, 1) = "ia_acceptedTtl": myArray(36, 2) = "ia_acceptedTtl"
    myArray(37, 1) = "ia_acceptedTtlAccum": myArray(37, 2) = "ia_acceptedTtlAccum"
    myArray(38, 1) = "ia_restOfLimit": myArray(38, 2) = "ia_restOfLimit"
    myArray(39, 1) = "iv_PlFulfillment": myArray(39, 2) = "iv_PlFulfillment"
    myArray(40, 1) = "iv_PlNonFulfillment": myArray(40, 2) = "iv_PlNonFulfillment"
    myArray(41, 1) = "iv_PlOverFulfillment": myArray(41, 2) = "iv_PlOverFulfillment"
    myArray(42, 1) = "iv_PlRestLimit": myArray(42, 2) = "iv_PlRestLimit"
    myArray(43, 1) = "iv_PlOverLimit": myArray(43, 2) = "iv_PlOverLimit"
    myArray(44, 1) = "iv_PlAccum": myArray(44, 2) = "iv_PlAccum"
    myArray(45, 1) = "iv_lim": myArray(45, 2) = "iv_lim"
    myArray(46, 1) = "ia_presented": myArray(46, 2) = "ia_presented"
    myArray(47, 1) = "ia_presentedAccum": myArray(47, 2) = "ia_presentedAccum"
    myArray(48, 1) = "ia_accepted": myArray(48, 2) = "ia_accepted"
    myArray(49, 1) = "ia_acceptedAccum": myArray(49, 2) = "ia_acceptedAccum"
    myArray(50, 1) = "ia_agFeePresented": myArray(50, 2) = "ia_agFeePresented"
    myArray(51, 1) = "ia_agFeePresentedAccum": myArray(51, 2) = "ia_agFeePresentedAccum"
    myArray(52, 1) = "ia_agFeeAccepted": myArray(52, 2) = "ia_agFeeAccepted"
    myArray(53, 1) = "ia_agFeeAcceptedAccum": myArray(53, 2) = "ia_agFeeAcceptedAccum"
    myArray(54, 1) = "ia_presentedRalp": myArray(54, 2) = "ia_presentedRalp"
    myArray(55, 1) = "ia_presentedRalpAccum": myArray(55, 2) = "ia_presentedRalpAccum"
    myArray(56, 1) = "ia_acceptedRalp": myArray(56, 2) = "ia_acceptedRalp"
    myArray(57, 1) = "ia_acceptedRalpAccum": myArray(57, 2) = "ia_acceptedRalpAccum"
    myArray(58, 1) = "ia_storageSum": myArray(58, 2) = "ia_storageSum"
    myArray(59, 1) = "ia_storageSumAccum": myArray(59, 2) = "ia_storageSumAccum"
    myArray(60, 1) = "ia_cctSum": myArray(60, 2) = "ia_cctSum"
    myArray(61, 1) = "ia_cctSumAccum": myArray(61, 2) = "ia_cctSumAccum"
    myArray(62, 1) = "ia_MnrlSum": myArray(62, 2) = "ia_MnrlSum"
    myArray(63, 1) = "ia_MnrlSumAccum": myArray(63, 2) = "ia_MnrlSumAccum"
    myArray(64, 1) = "uk_presentedTtl": myArray(64, 2) = "uk_presentedTtl"
    myArray(65, 1) = "uk_presentedTtlAccum": myArray(65, 2) = "uk_presentedTtlAccum"
    myArray(66, 1) = "uk_acceptedTtl": myArray(66, 2) = "uk_acceptedTtl"
    myArray(67, 1) = "uk_acceptedTtlAccum": myArray(67, 2) = "uk_acceptedTtlAccum"
    myArray(68, 1) = "uk_restOfLimit": myArray(68, 2) = "uk_restOfLimit"
    myArray(69, 1) = "uk_PlFulfillment": myArray(69, 2) = "uk_PlFulfillment"
    myArray(70, 1) = "uk_PlNonFulfillment": myArray(70, 2) = "uk_PlNonFulfillment"
    myArray(71, 1) = "uk_PlOverFulfillment": myArray(71, 2) = "uk_PlOverFulfillment"
    myArray(72, 1) = "uk_PlRestLimit": myArray(72, 2) = "uk_PlRestLimit"
    myArray(73, 1) = "uk_PlOverLimit": myArray(73, 2) = "uk_PlOverLimit"
    myArray(74, 1) = "uk_PlAccum": myArray(74, 2) = "uk_PlAccum"
    myArray(75, 1) = "uk_lim": myArray(75, 2) = "uk_lim"
    myArray(76, 1) = "uk_presented": myArray(76, 2) = "uk_presented"
    myArray(77, 1) = "uk_presentedAccum": myArray(77, 2) = "uk_presentedAccum"
    myArray(78, 1) = "uk_accepted": myArray(78, 2) = "uk_accepted"
    myArray(79, 1) = "uk_acceptedAccum": myArray(79, 2) = "uk_acceptedAccum"
    myArray(80, 1) = "uk_agFeePresented": myArray(80, 2) = "uk_agFeePresented"
    myArray(81, 1) = "uk_agFeePresentedAccum": myArray(81, 2) = "uk_agFeePresentedAccum"
    myArray(82, 1) = "uk_agFeeAccepted": myArray(82, 2) = "uk_agFeeAccepted"
    myArray(83, 1) = "uk_agFeeAcceptedAccum": myArray(83, 2) = "uk_agFeeAcceptedAccum"
    myArray(84, 1) = "uk_presentedRalp": myArray(84, 2) = "uk_presentedRalp"
    myArray(85, 1) = "uk_presentedRalpAccum": myArray(85, 2) = "uk_presentedRalpAccum"
    myArray(86, 1) = "uk_acceptedRalp": myArray(86, 2) = "uk_acceptedRalp"
    myArray(87, 1) = "uk_acceptedRalpAccum": myArray(87, 2) = "uk_acceptedRalpAccum"
    myArray(88, 1) = "uk_storageSum": myArray(88, 2) = "uk_storageSum"
    myArray(89, 1) = "uk_storageSumAccum": myArray(89, 2) = "uk_storageSumAccum"
    myArray(90, 1) = "uk_cctSum": myArray(90, 2) = "uk_cctSum"
    myArray(91, 1) = "uk_cctSumAccum": myArray(91, 2) = "uk_cctSumAccum"
    myArray(92, 1) = "uk_MnrlSum": myArray(92, 2) = "uk_MnrlSum"
    myArray(93, 1) = "uk_MnrlSumAccum": myArray(93, 2) = "uk_MnrlSumAccum"
    myArray(94, 1) = "np_presentedTtl": myArray(94, 2) = "np_presentedTtl"
    myArray(95, 1) = "np_presentedTtlAccum": myArray(95, 2) = "np_presentedTtlAccum"
    myArray(96, 1) = "np_acceptedTtl": myArray(96, 2) = "np_acceptedTtl"
    myArray(97, 1) = "np_acceptedTtlAccum": myArray(97, 2) = "np_acceptedTtlAccum"
    myArray(98, 1) = "np_presented": myArray(98, 2) = "np_presented"
    myArray(99, 1) = "np_presentedAccum": myArray(99, 2) = "np_presentedAccum"
    myArray(100, 1) = "np_accepted": myArray(100, 2) = "np_accepted"
    myArray(101, 1) = "np_acceptedAccum": myArray(101, 2) = "np_acceptedAccum"
    myArray(102, 1) = "np_agFeePresented": myArray(102, 2) = "np_agFeePresented"
    myArray(103, 1) = "np_agFeePresentedAccum": myArray(103, 2) = "np_agFeePresentedAccum"
    myArray(104, 1) = "np_agFeeAccepted": myArray(104, 2) = "np_agFeeAccepted"
    myArray(105, 1) = "np_agFeeAcceptedAccum": myArray(105, 2) = "np_agFeeAcceptedAccum"
    myArray(106, 1) = "np_presentedRalp": myArray(106, 2) = "np_presentedRalp"
    myArray(107, 1) = "np_presentedRalpAccum": myArray(107, 2) = "np_presentedRalpAccum"
    myArray(108, 1) = "np_acceptedRalp": myArray(108, 2) = "np_acceptedRalp"
    myArray(109, 1) = "np_acceptedRalpAccum": myArray(109, 2) = "np_acceptedRalpAccum"
    myArray(110, 1) = "np_storageSum": myArray(110, 2) = "np_storageSum"
    myArray(111, 1) = "np_storageSumAccum": myArray(111, 2) = "np_storageSumAccum"
    myArray(112, 1) = "np_cctSum": myArray(112, 2) = "np_cctSum"
    myArray(113, 1) = "np_cctSumAccum": myArray(113, 2) = "np_cctSumAccum"
    myArray(114, 1) = "np_MnrlSum": myArray(114, 2) = "np_MnrlSum"
    myArray(115, 1) = "np_MnrlSumAccum": myArray(115, 2) = "np_MnrlSumAccum"
    myArray(116, 1) = "oh_presented": myArray(116, 2) = "oh_presented"
    myArray(117, 1) = "oh_presentedAccum": myArray(117, 2) = "oh_presentedAccum"
    myArray(118, 1) = "oh_accepted": myArray(118, 2) = "oh_accepted"
    myArray(119, 1) = "oh_acceptedAccum": myArray(119, 2) = "oh_acceptedAccum"
    myArray(120, 1) = "oh_presentedTtl": myArray(120, 2) = "oh_presentedTtl"
    myArray(121, 1) = "oh_presentedTtlAccum": myArray(121, 2) = "oh_presentedTtlAccum"
    myArray(122, 1) = "oh_acceptedTtl": myArray(122, 2) = "oh_acceptedTtl"
    myArray(123, 1) = "oh_acceptedTtlAccum": myArray(123, 2) = "oh_acceptedTtlAccum"
    myArray(124, 1) = "ipgChKey": myArray(124, 2) = "ipgChKey"
    
    ' переносим данные с сервера используя класс работы с базой данных
    Set db = CurrentDb
    Set dbAccessTest = ClassFactory.dbAccessByDB(db)
    strSql = "ags.spIpgChRsltCstUtl3_GP_3 " & Me![ipgcKey].value
    If dbAccessTest.SqlSrvRecordsetToTable(strSql, "ipgChRsltPlCstSum", myArray()) Then
        MsgBox ("Перенесено в ipgChRsltPlCstSum")
    End If
    Set dbAccessTest = Nothing

NormalExit:
    Exit Sub
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
End Sub
' ---------------------------------------------------------------------------------------------------------------------------------------------------
' заполняем таблицу освоения по стройкам. 27.09.2022. Окончание
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' заполняем таблицу освоения по стройкам с процентом. 30.09.2022
' ---------------------------------------------------------------------------------------------------------------------------------------------------
Private Sub btnMasteringPercent_Click()
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Dim db As DAO.Database, dbAccessTest As dbAccess, myArray(1 To 170, 1 To 2) As Variant, strSql As String
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Const cstrTitle As String = "Процедура *Заполняем таблицу освоения по стройкам с процентом. Кнопка btnMasteringPercent*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler
    
    ' формируем массив по принципу поле № 1 - откуда, поле № 2 - куда
    myArray(1, 1) = "ogNm": myArray(1, 2) = "ogNm"
    myArray(2, 1) = "cstAgPnCode": myArray(2, 2) = "cstAgPnCode"
    myArray(3, 1) = "dateRslt": myArray(3, 2) = "dateRslt"
    myArray(4, 1) = "ipgChKey": myArray(4, 2) = "ipgChKey"
    myArray(5, 1) = "cstapKey": myArray(5, 2) = "cstapKey"
    myArray(6, 1) = "yKey": myArray(6, 2) = "yKey"
    myArray(7, 1) = "yyyy": myArray(7, 2) = "yyyy"
    myArray(8, 1) = "mKey": myArray(8, 2) = "mKey"
    myArray(9, 1) = "mNum": myArray(9, 2) = "mNum"
    myArray(10, 1) = "mCs": myArray(10, 2) = "mCs"
    myArray(11, 1) = "mNm": myArray(11, 2) = "mNm"
    myArray(12, 1) = "mQ": myArray(12, 2) = "mQ"
    myArray(13, 1) = "mHy": myArray(13, 2) = "mHy"
    myArray(14, 1) = "cstaInvestor": myArray(14, 2) = "cstaInvestor"
    myArray(15, 1) = "ogaKey": myArray(15, 2) = "ogaKey"
    myArray(16, 1) = "ipgKey": myArray(16, 2) = "ipgKey"
    myArray(17, 1) = "ipgCount": myArray(17, 2) = "ipgCount"
    myArray(18, 1) = "ag_ipgpKey": myArray(18, 2) = "ag_ipgpKey"
    myArray(19, 1) = "ag_ipgpSmTtl": myArray(19, 2) = "ag_ipgpSmTtl"
    myArray(20, 1) = "ag_PlAccum": myArray(20, 2) = "ag_PlAccum"
    myArray(21, 1) = "ag_PlFulfillment": myArray(21, 2) = "ag_PlFulfillment"
    myArray(22, 1) = "ag_PlNonFulfillment": myArray(22, 2) = "ag_PlNonFulfillment"
    myArray(23, 1) = "ag_PlOverFulfillment": myArray(23, 2) = "ag_PlOverFulfillment"
    myArray(24, 1) = "ag_PlRestLimit": myArray(24, 2) = "ag_PlRestLimit"
    myArray(25, 1) = "ag_PlOverLimit": myArray(25, 2) = "ag_PlOverLimit"
    myArray(26, 1) = "ag_LimPercent": myArray(26, 2) = "ag_LimPercent"
    myArray(27, 1) = "ag_PlPercent": myArray(27, 2) = "ag_PlPercent"
    myArray(28, 1) = "ag_lim": myArray(28, 2) = "ag_lim"
    myArray(29, 1) = "ag_iShKey": myArray(29, 2) = "ag_iShKey"
    myArray(30, 1) = "ag_presented": myArray(30, 2) = "ag_presented"
    myArray(31, 1) = "ag_presentedAccum": myArray(31, 2) = "ag_presentedAccum"
    myArray(32, 1) = "ag_accepted": myArray(32, 2) = "ag_accepted"
    myArray(33, 1) = "ag_acceptedAccum": myArray(33, 2) = "ag_acceptedAccum"
    myArray(34, 1) = "ag_agFeePresented": myArray(34, 2) = "ag_agFeePresented"
    myArray(35, 1) = "ag_agFeePresentedAccum": myArray(35, 2) = "ag_agFeePresentedAccum"
    myArray(36, 1) = "ag_agFeeAccepted": myArray(36, 2) = "ag_agFeeAccepted"
    myArray(37, 1) = "ag_agFeeAcceptedAccum": myArray(37, 2) = "ag_agFeeAcceptedAccum"
    myArray(38, 1) = "ag_presentedRalp": myArray(38, 2) = "ag_presentedRalp"
    myArray(39, 1) = "ag_presentedRalpAccum": myArray(39, 2) = "ag_presentedRalpAccum"
    myArray(40, 1) = "ag_acceptedRalp": myArray(40, 2) = "ag_acceptedRalp"
    myArray(41, 1) = "ag_acceptedRalpAccum": myArray(41, 2) = "ag_acceptedRalpAccum"
    myArray(42, 1) = "ag_storageSum": myArray(42, 2) = "ag_storageSum"
    myArray(43, 1) = "ag_storageSumAccum": myArray(43, 2) = "ag_storageSumAccum"
    myArray(44, 1) = "ag_cctSum": myArray(44, 2) = "ag_cctSum"
    myArray(45, 1) = "ag_cctSumAccum": myArray(45, 2) = "ag_cctSumAccum"
    myArray(46, 1) = "ag_MnrlSum": myArray(46, 2) = "ag_MnrlSum"
    myArray(47, 1) = "ag_MnrlSumAccum": myArray(47, 2) = "ag_MnrlSumAccum"
    myArray(48, 1) = "ag_presentedTtl": myArray(48, 2) = "ag_presentedTtl"
    myArray(49, 1) = "ag_presentedTtlAccum": myArray(49, 2) = "ag_presentedTtlAccum"
    myArray(50, 1) = "ag_acceptedTtl": myArray(50, 2) = "ag_acceptedTtl"
    myArray(51, 1) = "ag_acceptedTtlAccum": myArray(51, 2) = "ag_acceptedTtlAccum"
    myArray(52, 1) = "ag_restOfLimit": myArray(52, 2) = "ag_restOfLimit"
    myArray(53, 1) = "ag_percentDev": myArray(53, 2) = "ag_percentDev"
    myArray(54, 1) = "iv_ipgpKey": myArray(54, 2) = "iv_ipgpKey"
    myArray(55, 1) = "iv_ipgpSmTtl": myArray(55, 2) = "iv_ipgpSmTtl"
    myArray(56, 1) = "iv_PlAccum": myArray(56, 2) = "iv_PlAccum"
    myArray(57, 1) = "iv_PlFulfillment": myArray(57, 2) = "iv_PlFulfillment"
    myArray(58, 1) = "iv_PlNonFulfillment": myArray(58, 2) = "iv_PlNonFulfillment"
    myArray(59, 1) = "iv_PlOverFulfillment": myArray(59, 2) = "iv_PlOverFulfillment"
    myArray(60, 1) = "iv_PlRestLimit": myArray(60, 2) = "iv_PlRestLimit"
    myArray(61, 1) = "iv_PlOverLimit": myArray(61, 2) = "iv_PlOverLimit"
    myArray(62, 1) = "iv_LimPercent": myArray(62, 2) = "iv_LimPercent"
    myArray(63, 1) = "iv_PlPercent": myArray(63, 2) = "iv_PlPercent"
    myArray(64, 1) = "iv_lim": myArray(64, 2) = "iv_lim"
    myArray(65, 1) = "iv_iShKey": myArray(65, 2) = "iv_iShKey"
    myArray(66, 1) = "ia_lim": myArray(66, 2) = "ia_lim"
    myArray(67, 1) = "ia_iShKey": myArray(67, 2) = "ia_iShKey"
    myArray(68, 1) = "ia_presented": myArray(68, 2) = "ia_presented"
    myArray(69, 1) = "ia_presentedAccum": myArray(69, 2) = "ia_presentedAccum"
    myArray(70, 1) = "ia_accepted": myArray(70, 2) = "ia_accepted"
    myArray(71, 1) = "ia_acceptedAccum": myArray(71, 2) = "ia_acceptedAccum"
    myArray(72, 1) = "ia_agFeePresented": myArray(72, 2) = "ia_agFeePresented"
    myArray(73, 1) = "ia_agFeePresentedAccum": myArray(73, 2) = "ia_agFeePresentedAccum"
    myArray(74, 1) = "ia_agFeeAccepted": myArray(74, 2) = "ia_agFeeAccepted"
    myArray(75, 1) = "ia_agFeeAcceptedAccum": myArray(75, 2) = "ia_agFeeAcceptedAccum"
    myArray(76, 1) = "ia_presentedRalp": myArray(76, 2) = "ia_presentedRalp"
    myArray(77, 1) = "ia_presentedRalpAccum": myArray(77, 2) = "ia_presentedRalpAccum"
    myArray(78, 1) = "ia_acceptedRalp": myArray(78, 2) = "ia_acceptedRalp"
    myArray(79, 1) = "ia_acceptedRalpAccum": myArray(79, 2) = "ia_acceptedRalpAccum"
    myArray(80, 1) = "ia_storageSum": myArray(80, 2) = "ia_storageSum"
    myArray(81, 1) = "ia_storageSumAccum": myArray(81, 2) = "ia_storageSumAccum"
    myArray(82, 1) = "ia_cctSum": myArray(82, 2) = "ia_cctSum"
    myArray(83, 1) = "ia_cctSumAccum": myArray(83, 2) = "ia_cctSumAccum"
    myArray(84, 1) = "ia_MnrlSum": myArray(84, 2) = "ia_MnrlSum"
    myArray(85, 1) = "ia_MnrlSumAccum": myArray(85, 2) = "ia_MnrlSumAccum"
    myArray(86, 1) = "ia_presentedTtl": myArray(86, 2) = "ia_presentedTtl"
    myArray(87, 1) = "ia_presentedTtlAccum": myArray(87, 2) = "ia_presentedTtlAccum"
    myArray(88, 1) = "ia_acceptedTtl": myArray(88, 2) = "ia_acceptedTtl"
    myArray(89, 1) = "ia_acceptedTtlAccum": myArray(89, 2) = "ia_acceptedTtlAccum"
    myArray(90, 1) = "ia_restOfLimit": myArray(90, 2) = "ia_restOfLimit"
    myArray(91, 1) = "ia_percentDev": myArray(91, 2) = "ia_percentDev"
    myArray(92, 1) = "uk_lim": myArray(92, 2) = "uk_lim"
    myArray(93, 1) = "uk_iShKey": myArray(93, 2) = "uk_iShKey"
    myArray(94, 1) = "uk_ipgpKey": myArray(94, 2) = "uk_ipgpKey"
    myArray(95, 1) = "uk_ipgpSmTtl": myArray(95, 2) = "uk_ipgpSmTtl"
    myArray(96, 1) = "uk_PlAccum": myArray(96, 2) = "uk_PlAccum"
    myArray(97, 1) = "uk_PlFulfillment": myArray(97, 2) = "uk_PlFulfillment"
    myArray(98, 1) = "uk_PlNonFulfillment": myArray(98, 2) = "uk_PlNonFulfillment"
    myArray(99, 1) = "uk_PlOverFulfillment": myArray(99, 2) = "uk_PlOverFulfillment"
    myArray(100, 1) = "uk_PlRestLimit": myArray(100, 2) = "uk_PlRestLimit"
    myArray(101, 1) = "uk_PlOverLimit": myArray(101, 2) = "uk_PlOverLimit"
    myArray(102, 1) = "uk_LimPercent": myArray(102, 2) = "uk_LimPercent"
    myArray(103, 1) = "uk_PlPercent": myArray(103, 2) = "uk_PlPercent"
    myArray(104, 1) = "uk_presented": myArray(104, 2) = "uk_presented"
    myArray(105, 1) = "uk_presentedAccum": myArray(105, 2) = "uk_presentedAccum"
    myArray(106, 1) = "uk_accepted": myArray(106, 2) = "uk_accepted"
    myArray(107, 1) = "uk_acceptedAccum": myArray(107, 2) = "uk_acceptedAccum"
    myArray(108, 1) = "uk_agFeePresented": myArray(108, 2) = "uk_agFeePresented"
    myArray(109, 1) = "uk_agFeePresentedAccum": myArray(109, 2) = "uk_agFeePresentedAccum"
    myArray(110, 1) = "uk_agFeeAccepted": myArray(110, 2) = "uk_agFeeAccepted"
    myArray(111, 1) = "uk_agFeeAcceptedAccum": myArray(111, 2) = "uk_agFeeAcceptedAccum"
    myArray(112, 1) = "uk_presentedRalp": myArray(112, 2) = "uk_presentedRalp"
    myArray(113, 1) = "uk_presentedRalpAccum": myArray(113, 2) = "uk_presentedRalpAccum"
    myArray(114, 1) = "uk_acceptedRalp": myArray(114, 2) = "uk_acceptedRalp"
    myArray(115, 1) = "uk_acceptedRalpAccum": myArray(115, 2) = "uk_acceptedRalpAccum"
    myArray(116, 1) = "uk_storageSum": myArray(116, 2) = "uk_storageSum"
    myArray(117, 1) = "uk_storageSumAccum": myArray(117, 2) = "uk_storageSumAccum"
    myArray(118, 1) = "uk_cctSum": myArray(118, 2) = "uk_cctSum"
    myArray(119, 1) = "uk_cctSumAccum": myArray(119, 2) = "uk_cctSumAccum"
    myArray(120, 1) = "uk_MnrlSum": myArray(120, 2) = "uk_MnrlSum"
    myArray(121, 1) = "uk_MnrlSumAccum": myArray(121, 2) = "uk_MnrlSumAccum"
    myArray(122, 1) = "uk_presentedTtl": myArray(122, 2) = "uk_presentedTtl"
    myArray(123, 1) = "uk_presentedTtlAccum": myArray(123, 2) = "uk_presentedTtlAccum"
    myArray(124, 1) = "uk_acceptedTtl": myArray(124, 2) = "uk_acceptedTtl"
    myArray(125, 1) = "uk_acceptedTtlAccum": myArray(125, 2) = "uk_acceptedTtlAccum"
    myArray(126, 1) = "uk_restOfLimit": myArray(126, 2) = "uk_restOfLimit"
    myArray(127, 1) = "uk_percentDev": myArray(127, 2) = "uk_percentDev"
    myArray(128, 1) = "np_lim": myArray(128, 2) = "np_lim"
    myArray(129, 1) = "np_iShKey": myArray(129, 2) = "np_iShKey"
    myArray(130, 1) = "np_presented": myArray(130, 2) = "np_presented"
    myArray(131, 1) = "np_presentedAccum": myArray(131, 2) = "np_presentedAccum"
    myArray(132, 1) = "np_accepted": myArray(132, 2) = "np_accepted"
    myArray(133, 1) = "np_acceptedAccum": myArray(133, 2) = "np_acceptedAccum"
    myArray(134, 1) = "np_agFeePresented": myArray(134, 2) = "np_agFeePresented"
    myArray(135, 1) = "np_agFeePresentedAccum": myArray(135, 2) = "np_agFeePresentedAccum"
    myArray(136, 1) = "np_agFeeAccepted": myArray(136, 2) = "np_agFeeAccepted"
    myArray(137, 1) = "np_agFeeAcceptedAccum": myArray(137, 2) = "np_agFeeAcceptedAccum"
    myArray(138, 1) = "np_presentedRalp": myArray(138, 2) = "np_presentedRalp"
    myArray(139, 1) = "np_presentedRalpAccum": myArray(139, 2) = "np_presentedRalpAccum"
    myArray(140, 1) = "np_acceptedRalp": myArray(140, 2) = "np_acceptedRalp"
    myArray(141, 1) = "np_acceptedRalpAccum": myArray(141, 2) = "np_acceptedRalpAccum"
    myArray(142, 1) = "np_storageSum": myArray(142, 2) = "np_storageSum"
    myArray(143, 1) = "np_storageSumAccum": myArray(143, 2) = "np_storageSumAccum"
    myArray(144, 1) = "np_cctSum": myArray(144, 2) = "np_cctSum"
    myArray(145, 1) = "np_cctSumAccum": myArray(145, 2) = "np_cctSumAccum"
    myArray(146, 1) = "np_MnrlSum": myArray(146, 2) = "np_MnrlSum"
    myArray(147, 1) = "np_MnrlSumAccum": myArray(147, 2) = "np_MnrlSumAccum"
    myArray(148, 1) = "np_presentedTtl": myArray(148, 2) = "np_presentedTtl"
    myArray(149, 1) = "np_presentedTtlAccum": myArray(149, 2) = "np_presentedTtlAccum"
    myArray(150, 1) = "np_acceptedTtl": myArray(150, 2) = "np_acceptedTtl"
    myArray(151, 1) = "np_acceptedTtlAccum": myArray(151, 2) = "np_acceptedTtlAccum"
    myArray(152, 1) = "np_restOfLimit": myArray(152, 2) = "np_restOfLimit"
    myArray(153, 1) = "np_percentDev": myArray(153, 2) = "np_percentDev"
    myArray(154, 1) = "oh_presented": myArray(154, 2) = "oh_presented"
    myArray(155, 1) = "oh_presentedAccum": myArray(155, 2) = "oh_presentedAccum"
    myArray(156, 1) = "oh_accepted": myArray(156, 2) = "oh_accepted"
    myArray(157, 1) = "oh_acceptedAccum": myArray(157, 2) = "oh_acceptedAccum"
    myArray(158, 1) = "oh_presentedTtl": myArray(158, 2) = "oh_presentedTtl"
    myArray(159, 1) = "oh_presentedTtlAccum": myArray(159, 2) = "oh_presentedTtlAccum"
    myArray(160, 1) = "oh_acceptedTtl": myArray(160, 2) = "oh_acceptedTtl"
    myArray(161, 1) = "oh_acceptedTtlAccum": myArray(161, 2) = "oh_acceptedTtlAccum"
    myArray(162, 1) = "ag_Pl": myArray(162, 2) = "ag_Pl"
    myArray(163, 1) = "iv_Pl": myArray(163, 2) = "iv_Pl"
    myArray(164, 1) = "uk_Pl": myArray(164, 2) = "uk_Pl"
    myArray(165, 1) = "branch": myArray(165, 2) = "branch"
    myArray(166, 1) = "branchName": myArray(166, 2) = "branchName"
    '
    myArray(167, 1) = "oh_agFeePresented": myArray(167, 2) = "oh_agFeePresented"
    myArray(168, 1) = "oh_agFeePresentedAccum": myArray(168, 2) = "oh_agFeePresentedAccum"
    myArray(169, 1) = "oh_agFeeAccepted": myArray(169, 2) = "oh_agFeeAccepted"
    myArray(170, 1) = "oh_agFeeAcceptedAccum": myArray(170, 2) = "oh_agFeeAcceptedAccum"

    ' branch, ogBrn.ogNm as branchName
    
    ' переносим данные с сервера используя класс работы с базой данных
    Set db = CurrentDb
    Set dbAccessTest = ClassFactory.dbAccessByDB(db)
    strSql = "select * from ags.fnIpgChRsltCstUtlPercentBrn (" & Me![ipgcKey].value & ")"
    If dbAccessTest.SqlSrvRecordsetToTable(strSql, "ipgChRsltPlCstPercent", myArray()) Then
        MsgBox ("Перенесено в ipgChRsltPlCstPercent")
    End If
    Set dbAccessTest = Nothing

NormalExit:
    Exit Sub
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
End Sub
' ---------------------------------------------------------------------------------------------------------------------------------------------------
' заполняем таблицу освоения по стройкам с процентом. 30.09.2022. Окончание
' ***************************************************************************************************************************************************

Private Sub Form_Current()

    Dim qd As DAO.QueryDef
    Dim db As DAO.Database
    Dim strSql As String
    
    'me.lblText.Caption = '```'
    
    Set db = CurrentDb
    
    'очищаем таблицу
    strSql = "DELETE * FROM ipgChRslt"
    Set qd = db.CreateQueryDef("", strSql)
    qd.Execute dbFailOnError
    qd.Close
    Set qd = Nothing

    db.Close: Set db = Nothing
    
    'Me![ipgCh>Rslt_d_t].Requery

End Sub

Private Sub Кнопка11_Click()

    Dim qd As DAO.QueryDef
    Dim db As DAO.Database
    Dim rstD As DAO.Recordset, rstP As DAO.Recordset
    Dim strSql As String
    
    'me.lblText.Caption = '```'
    
    Set db = CurrentDb
    
    'очищаем таблицу
    strSql = "DELETE * FROM ipgChRslt"
    Set qd = db.CreateQueryDef("", strSql)
    qd.Execute dbFailOnError
    qd.Close
    Set qd = Nothing
    
    'получаем набор записей от сервера
    'strSQL = "EXEC [ags].[ipgChRslt] " & Me.ipgcKey
    Set qd = db.CreateQueryDef("")
    qd.Connect = db.TableDefs("ags_yyyy").Connect
    qd.SQL = "EXEC [ags].[ipgChRslt] " & Me.ipgcKey
    qd.ReturnsRecords = True
    qd.ODBCTimeout = 300
    
    Set rstD = qd.OpenRecordset(dbOpenSnapshot)
    rstD.MoveLast
    'MsgBox ("записей " & rs.RecordCount)
    
    'Set Me![ipgCh>qqq].Form.Recordset = rs
    
    'переносим набор записей в таблицу
    If rstD.RecordCount > 0 Then
    
        rstD.MoveFirst
    
        'открываем на редактирование рекордсет формируемой таблицы
        Set rstP = db.OpenRecordset("ipgChRslt", dbOpenDynaset)
        
        With rstD
            Do Until .EOF = True
            
                'собственно присваиваем
                rstP.AddNew
                    rstP!dateRslt = !dateRslt
                    rstP!ipgcrChain = !ipgcrChain
                    rstP!yyyy = !yyyy
                    rstP!mNum = !mNum
                    rstP!typeGrTtl = !typeGrTtl
                    rstP!ipgKey = !ipgKey
                    rstP!ipgStr = !ipgStr
                    rstP!ipgEnd = !ipgEnd
                    rstP!yKey = !yKey
                    rstP!mKey = !mKey
                    rstP!ag_lim = !ag_lim
                    rstP!ag_acceptedTtl = !ag_acceptedTtl
                    rstP!ag_acceptedTtlAccum = !ag_acceptedTtlAccum
                    rstP!ag_restOfLimit = !ag_restOfLimit
                    rstP!Ag_percentDev = !Ag_percentDev
                    rstP!Inv_lim = !Inv_lim
                    rstP!Inv_acceptedTtl = !Inv_acceptedTtl
                    rstP!Inv_acceptedTtlAccum = !Inv_acceptedTtlAccum
                    rstP!Inv_restOfLimit = !Inv_restOfLimit
                    rstP!unc_lim = !unc_lim
                    rstP!unc_acceptedTtl = !unc_acceptedTtl
                    rstP!unc_acceptedTtlAccum = !unc_acceptedTtlAccum
                    rstP!unc_restOfLimit = !unc_restOfLimit
                    rstP!unc_percentDev = !unc_percentDev
                    rstP!anp_acceptedTtl = !anp_acceptedTtl
                    rstP!anp_acceptedTtlAccum = !anp_acceptedTtlAccum
                    rstP!oth_acceptedTtl = !oth_acceptedTtl
                    rstP!oth_acceptedTtlAccum = !oth_acceptedTtlAccum
                rstP.Update
                rstP.Bookmark = rstP.LastModified
                'идем к следующей записи
                .MoveNext
            Loop
        End With
        rstP.Close: Set rstP = Nothing
    End If
    
    'закрываем рекордсет
    rstD.Close: Set rstD = Nothing
    
    db.Close: Set db = Nothing
    
    Me![ipgCh>Rslt_d_t].Requery

End Sub

Private Sub Кнопка53_Click()

    Dim qd As DAO.QueryDef
    Dim db As DAO.Database
    Dim rstD As DAO.Recordset, rstP As DAO.Recordset
    Dim strSql As String
    
    'me.lblText.Caption = '```'
    
    Set db = CurrentDb
    
    'очищаем таблицу
    strSql = "DELETE * FROM ipgChRsltFull"
    Set qd = db.CreateQueryDef("", strSql)
    qd.Execute dbFailOnError
    qd.Close
    Set qd = Nothing
    
    'получаем набор записей от сервера
    Set qd = db.CreateQueryDef("")
    qd.Connect = db.TableDefs("ags_yyyy").Connect
    qd.SQL = "EXEC [ags].[ipgChRsltFull] " & Me.ipgcKey
    qd.ReturnsRecords = True
    
    Set rstD = qd.OpenRecordset(dbOpenSnapshot)
    rstD.MoveLast
    'MsgBox ("записей " & rs.RecordCount)
    
    'Set Me![ipgCh>qqq].Form.Recordset = rs
    
    'переносим набор записей в таблицу
    If rstD.RecordCount > 0 Then
    
        rstD.MoveFirst
    
        'открываем на редактирование рекордсет формируемой таблицы
        Set rstP = db.OpenRecordset("ipgChRsltFull", dbOpenDynaset)
        
        With rstD
            Do Until .EOF = True
            
                'собственно присваиваем
                rstP.AddNew
                    rstP!dateRslt = !dateRslt
                    rstP!ipgcrChain = !ipgcrChain
                    rstP!yyyy = !yyyy
                    rstP!mNum = !mNum
                    rstP!ogNm = !ogNm
                    rstP!cstAgPnCode = !cstAgPnCode
                    rstP!typeGrTtl = !typeGrTtl
                    rstP!ipgKey = !ipgKey
                    rstP!ipgStr = !ipgStr
                    rstP!ipgEnd = !ipgEnd
                    rstP!yKey = !yKey
                    rstP!mKey = !mKey
                    rstP!ag_lim = !ag_lim
                    rstP!ag_presentedTtl = !ag_presentedTtl
                    rstP!ag_presentedTtlAccum = !ag_presentedTtlAccum
                    rstP!ag_acceptedTtl = !ag_acceptedTtl
                    rstP!ag_acceptedTtlAccum = !ag_acceptedTtlAccum
                    rstP!ag_restOfLimit = !ag_restOfLimit
                    rstP!Ag_percentDev = !Ag_percentDev
                    rstP!Inv_lim = !Inv_lim
                    rstP!Inv_presentedTtl = !Inv_presentedTtl
                    rstP!Inv_presentedTtlAccum = !Inv_presentedTtlAccum
                    rstP!Inv_acceptedTtl = !Inv_acceptedTtl
                    rstP!Inv_acceptedTtlAccum = !Inv_acceptedTtlAccum
                    rstP!Inv_restOfLimit = !Inv_restOfLimit
                    rstP!unc_lim = !unc_lim
                    rstP!unc_presentedTtl = !unc_presentedTtl
                    rstP!unc_presentedTtlAccum = !unc_presentedTtlAccum
                    rstP!unc_acceptedTtl = !unc_acceptedTtl
                    rstP!unc_acceptedTtlAccum = !unc_acceptedTtlAccum
                    rstP!unc_restOfLimit = !unc_restOfLimit
                    rstP!unc_percentDev = !unc_percentDev
                    rstP!anp_presentedTtl = !anp_presentedTtl
                    rstP!anp_presentedTtlAccum = !anp_presentedTtlAccum
                    rstP!anp_acceptedTtl = !anp_acceptedTtl
                    rstP!anp_acceptedTtlAccum = !anp_acceptedTtlAccum
                    rstP!oth_presentedTtl = !oth_presentedTtl
                    rstP!oth_presentedTtlAccum = !oth_presentedTtlAccum
                    rstP!oth_acceptedTtl = !oth_acceptedTtl
                    rstP!oth_acceptedTtlAccum = !oth_acceptedTtlAccum
                rstP.Update
                rstP.Bookmark = rstP.LastModified
                'идем к следующей записи
                .MoveNext
            Loop
        End With
        rstP.Close: Set rstP = Nothing
    End If
    
    'закрываем рекордсет
    rstD.Close: Set rstD = Nothing
    
    db.Close: Set db = Nothing
    
    Me![ipgChRslt>Full].Requery

End Sub

Private Sub Кнопка57_Click()

    Dim qd As DAO.QueryDef
    Dim db As DAO.Database
    Dim rstD As DAO.Recordset, rstP As DAO.Recordset
    Dim strSql As String
    
    'me.lblText.Caption = '```'
    
    Set db = CurrentDb
    
    'очищаем таблицу
    strSql = "DELETE * FROM ipgChRsltPl"
    Set qd = db.CreateQueryDef("", strSql)
    qd.Execute dbFailOnError
    qd.Close
    Set qd = Nothing
    
    'получаем набор записей от сервера
    Set qd = db.CreateQueryDef("")
    qd.Connect = db.TableDefs("ags_yyyy").Connect
    qd.SQL = "EXEC [ags].[spIpgChRsltCstUtl3_GP_2] " & Me.ipgcKey
    qd.ReturnsRecords = True
    qd.ODBCTimeout = 300
    
    Set rstD = qd.OpenRecordset(dbOpenSnapshot)
    rstD.MoveLast
    'MsgBox ("записей " & rs.RecordCount)
    
    'Set Me![ipgCh>qqq].Form.Recordset = rs
    
    'переносим набор записей в таблицу
    If rstD.RecordCount > 0 Then
    
        rstD.MoveFirst
    
        'открываем на редактирование рекордсет формируемой таблицы
        Set rstP = db.OpenRecordset("ipgChRsltPl", dbOpenDynaset)
        
        With rstD
            Do Until .EOF = True
            
                'собственно присваиваем
                rstP.AddNew
                    rstP!dateRslt = !dateRslt
                    If IsNull(!ogNm) = True Then
                        rstP!ogNm = "а. Всего"
                    Else
                        rstP!ogNm = !ogNm
                    End If
                    rstP!ag_presentedTtl = !ag_presentedTtl
                    rstP!ag_presentedTtlAccum = !ag_presentedTtlAccum
                    rstP!ag_acceptedTtl = !ag_acceptedTtl
                    rstP!ag_acceptedTtlAccum = !ag_acceptedTtlAccum
                    rstP!ag_restOfLimit = !ag_restOfLimit
                    rstP!ag_PlFulfillment = !ag_PlFulfillment
                    rstP!ag_PlNonFulfillment = !ag_PlNonFulfillment
                    rstP!ag_PlOverFulfillment = !ag_PlOverFulfillment
                    rstP!ag_PlRestLimit = !ag_PlRestLimit
                    rstP!ag_PlOverLimit = !ag_PlOverLimit
                    rstP!ag_PlAccum = !ag_PlAccum
                    rstP!ag_lim = !ag_lim
                    rstP!ag_presented = !ag_presented
                    rstP!ag_presentedAccum = !ag_presentedAccum
                    rstP!ag_accepted = !ag_accepted
                    rstP!ag_acceptedAccum = !ag_acceptedAccum
                    rstP!ag_agFeePresented = !ag_agFeePresented
                    rstP!ag_agFeePresentedAccum = !ag_agFeePresentedAccum
                    rstP!ag_agFeeAccepted = !ag_agFeeAccepted
                    rstP!ag_agFeeAcceptedAccum = !ag_agFeeAcceptedAccum
                    rstP!ag_presentedRalp = !ag_presentedRalp
                    rstP!ag_presentedRalpAccum = !ag_presentedRalpAccum
                    rstP!ag_acceptedRalp = !ag_acceptedRalp
                    rstP!ag_acceptedRalpAccum = !ag_acceptedRalpAccum
                    rstP!ag_storageSum = !ag_storageSum
                    rstP!ag_storageSumAccum = !ag_storageSumAccum
                    rstP!ag_cctSum = !ag_cctSum
                    rstP!ag_cctSumAccum = !ag_cctSumAccum
                    rstP!ag_MnrlSum = !ag_MnrlSum
                    rstP!ag_MnrlSumAccum = !ag_MnrlSumAccum
                    rstP!ia_presentedTtl = !ia_presentedTtl
                    rstP!ia_presentedTtlAccum = !ia_presentedTtlAccum
                    rstP!ia_acceptedTtl = !ia_acceptedTtl
                    rstP!ia_acceptedTtlAccum = !ia_acceptedTtlAccum
                    rstP!ia_restOfLimit = !ia_restOfLimit
                    rstP!iv_PlFulfillment = !iv_PlFulfillment
                    rstP!iv_PlNonFulfillment = !iv_PlNonFulfillment
                    rstP!iv_PlOverFulfillment = !iv_PlOverFulfillment
                    rstP!iv_PlRestLimit = !iv_PlRestLimit
                    rstP!iv_PlOverLimit = !iv_PlOverLimit
                    rstP!iv_PlAccum = !iv_PlAccum
                    rstP!iv_lim = !iv_lim
                    rstP!ia_presented = !ia_presented
                    rstP!ia_presentedAccum = !ia_presentedAccum
                    rstP!ia_accepted = !ia_accepted
                    rstP!ia_acceptedAccum = !ia_acceptedAccum
                    rstP!ia_agFeePresented = !ia_agFeePresented
                    rstP!ia_agFeePresentedAccum = !ia_agFeePresentedAccum
                    rstP!ia_agFeeAccepted = !ia_agFeeAccepted
                    rstP!ia_agFeeAcceptedAccum = !ia_agFeeAcceptedAccum
                    rstP!ia_presentedRalp = !ia_presentedRalp
                    rstP!ia_presentedRalpAccum = !ia_presentedRalpAccum
                    rstP!ia_acceptedRalp = !ia_acceptedRalp
                    rstP!ia_acceptedRalpAccum = !ia_acceptedRalpAccum
                    rstP!ia_storageSum = !ia_storageSum
                    rstP!ia_storageSumAccum = !ia_storageSumAccum
                    rstP!ia_cctSum = !ia_cctSum
                    rstP!ia_cctSumAccum = !ia_cctSumAccum
                    rstP!ia_MnrlSum = !ia_MnrlSum
                    rstP!ia_MnrlSumAccum = !ia_MnrlSumAccum
                    rstP!uk_presentedTtl = !uk_presentedTtl
                    rstP!uk_presentedTtlAccum = !uk_presentedTtlAccum
                    rstP!uk_acceptedTtl = !uk_acceptedTtl
                    rstP!uk_acceptedTtlAccum = !uk_acceptedTtlAccum
                    rstP!uk_restOfLimit = !uk_restOfLimit
                    rstP!uk_PlFulfillment = !uk_PlFulfillment
                    rstP!uk_PlNonFulfillment = !uk_PlNonFulfillment
                    rstP!uk_PlOverFulfillment = !uk_PlOverFulfillment
                    rstP!uk_PlRestLimit = !uk_PlRestLimit
                    rstP!uk_PlOverLimit = !uk_PlOverLimit
                    rstP!uk_PlAccum = !uk_PlAccum
                    rstP!uk_lim = !uk_lim
                    rstP!uk_presented = !uk_presented
                    rstP!uk_presentedAccum = !uk_presentedAccum
                    rstP!uk_accepted = !uk_accepted
                    rstP!uk_acceptedAccum = !uk_acceptedAccum
                    rstP!uk_agFeePresented = !uk_agFeePresented
                    rstP!uk_agFeePresentedAccum = !uk_agFeePresentedAccum
                    rstP!uk_agFeeAccepted = !uk_agFeeAccepted
                    rstP!uk_agFeeAcceptedAccum = !uk_agFeeAcceptedAccum
                    rstP!uk_presentedRalp = !uk_presentedRalp
                    rstP!uk_presentedRalpAccum = !uk_presentedRalpAccum
                    rstP!uk_acceptedRalp = !uk_acceptedRalp
                    rstP!uk_acceptedRalpAccum = !uk_acceptedRalpAccum
                    rstP!uk_storageSum = !uk_storageSum
                    rstP!uk_storageSumAccum = !uk_storageSumAccum
                    rstP!uk_cctSum = !uk_cctSum
                    rstP!uk_cctSumAccum = !uk_cctSumAccum
                    rstP!uk_MnrlSum = !uk_MnrlSum
                    rstP!uk_MnrlSumAccum = !uk_MnrlSumAccum
                    rstP!np_presentedTtl = !np_presentedTtl
                    rstP!np_presentedTtlAccum = !np_presentedTtlAccum
                    rstP!np_acceptedTtl = !np_acceptedTtl
                    rstP!np_acceptedTtlAccum = !np_acceptedTtlAccum
                    rstP!np_presented = !np_presented
                    rstP!np_presentedAccum = !np_presentedAccum
                    rstP!np_accepted = !np_accepted
                    rstP!np_acceptedAccum = !np_acceptedAccum
                    rstP!np_agFeePresented = !np_agFeePresented
                    rstP!np_agFeePresentedAccum = !np_agFeePresentedAccum
                    rstP!np_agFeeAccepted = !np_agFeeAccepted
                    rstP!np_agFeeAcceptedAccum = !np_agFeeAcceptedAccum
                    rstP!np_presentedRalp = !np_presentedRalp
                    rstP!np_presentedRalpAccum = !np_presentedRalpAccum
                    rstP!np_acceptedRalp = !np_acceptedRalp
                    rstP!np_acceptedRalpAccum = !np_acceptedRalpAccum
                    rstP!np_storageSum = !np_storageSum
                    rstP!np_storageSumAccum = !np_storageSumAccum
                    rstP!np_cctSum = !np_cctSum
                    rstP!np_cctSumAccum = !np_cctSumAccum
                    rstP!np_MnrlSum = !np_MnrlSum
                    rstP!np_MnrlSumAccum = !np_MnrlSumAccum
                    rstP!oh_presented = !oh_presented
                    rstP!oh_presentedAccum = !oh_presentedAccum
                    rstP!oh_accepted = !oh_accepted
                    rstP!oh_acceptedAccum = !oh_acceptedAccum
                    rstP!oh_presentedTtl = !oh_presentedTtl
                    rstP!oh_presentedTtlAccum = !oh_presentedTtlAccum
                    rstP!oh_acceptedTtl = !oh_acceptedTtl
                    rstP!oh_acceptedTtlAccum = !oh_acceptedTtlAccum
                    rstP!ipgCh = Me.ipgcKey
                rstP.Update
                rstP.Bookmark = rstP.LastModified
                'идем к следующей записи
                .MoveNext
            Loop
        End With
        rstP.Close: Set rstP = Nothing
    End If
    
    'закрываем рекордсет
    rstD.Close: Set rstD = Nothing
    
    db.Close: Set db = Nothing
    
    'Me![ipgChRslt>Full].Requery

End Sub

