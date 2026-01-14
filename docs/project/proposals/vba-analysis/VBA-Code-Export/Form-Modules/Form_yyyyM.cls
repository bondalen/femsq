VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_yyyyM"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

' получаем освоение вместе со стройками
Private Sub btn_obtainUtl_Click()

    Dim qd As DAO.QueryDef
    Dim db As DAO.Database
    Dim rstD As DAO.Recordset, rstP As DAO.Recordset
    Dim strSql As String
    
    'me.lblText.Caption = '```'
    
    Set db = CurrentDb
    
    'очищаем таблицу
    strSql = "DELETE * FROM ipgChRsltPlCst"
    Set qd = db.CreateQueryDef("", strSql)
    qd.Execute dbFailOnError
    qd.Close
    Set qd = Nothing
    
    'получаем набор записей от сервера
    Set qd = db.CreateQueryDef("")
    qd.Connect = db.TableDefs("ags_yyyy").Connect
    qd.SQL = "[ags].[spIpgChRsltCstUtl3_GP_cst] " & Me![yyyyM>ipgCh_t].Form!ipgcKey & ", '" _
        & year(Me!lastDayM) & "-" & Month(Me!lastDayM) & "-" & Day(Me!lastDayM) & "'"
    qd.ReturnsRecords = True
    
    Set rstD = qd.OpenRecordset(dbOpenSnapshot)
    rstD.MoveLast
    'MsgBox ("записей " & rs.RecordCount)
    
    'Set Me![ipgCh>qqq].Form.Recordset = rs
    
    'переносим набор записей в таблицу
    If rstD.RecordCount > 0 Then
    
        rstD.MoveFirst
    
        'открываем на редактирование рекордсет формируемой таблицы
        Set rstP = db.OpenRecordset("ipgChRsltPlCst", dbOpenDynaset)
        
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
                    rstP!cstAgPnCode = !cstAgPnCode
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
                    'rstP!ipgCh = Me.ipgcKey
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
