Attribute VB_Name = "ClassFunc"
Option Compare Database

' ***************************************************************************************************************************************************
' читаем значение поля в переменную типа Variant. 20.07.2022
Public Function varReadField(ByVal strFieldName As String, ByVal strTblName As String, ByVal lngKey As Long, _
    ByVal strFieldKey As String, ByRef db As DAO.Database) As Variant
    
    Dim rs As DAO.Recordset, strSql As String
    
    strSql = "SELECT " & strFieldName & " FROM " & strTblName & " WHERE " & strFieldKey & " = " & lngKey & ";"
    Set rs = db.OpenRecordset(strSql, dbOpenSnapshot)
    If rs.RecordCount = 1 Then
        varReadField = rs.Fields(strFieldName)
    Else
        varReadField = Null
    End If
    rs.Close: Set rs = Nothing

End Function
' читаем значение поля в переменную типа Variant. 20.07.2022. Окончание
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' редактируем поле даты. 20.07.2022
Public Sub varEditFieldDate(ByVal dateFieldName As String, ByVal dateNew As Variant, ByVal tblName As String, ByVal lngKey As Long, _
    ByVal strFieldKey As String, ByRef db As DAO.Database)
    
    Dim ddd As Date
    
    If Not IsNull(dateNew) And dateNew <> 0 And IsDate(dateNew) Then
        ddd = CDate(dateNew)
        strSql = "UPDATE " & tblName & " SET " & dateFieldName & " = " & DateConvertToQuery(ddd) & " WHERE " & strFieldKey & " = " & lngKey & ";"
    Else
        strSql = "UPDATE " & tblName & " SET " & dateFieldName & " = null WHERE " & strFieldKey & " = " & lngKey & ";"
    End If
    db.Execute strSql, dbFailOnError + dbSeeChanges
    
End Sub
' редактируем поле даты. 20.07.2022. Окончание
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' редактируем числовое поле. 20.07.2022
Public Sub varEditFieldNum(ByVal numFieldName As String, ByVal numNew As Variant, ByVal tblName As String, ByVal lngKey As Long, _
    ByVal strFieldKey As String, ByRef db As DAO.Database)
    
    Dim strNum As String
    
    If Not IsNull(numNew) And IsNumeric(numNew) Then
        strNum = Replace(numNew, ",", ".")
        strSql = "UPDATE " & tblName & " SET " & numFieldName & " = " & strNum & " WHERE " & strFieldKey & " = " & lngKey & ";"
    Else
        strSql = "UPDATE " & tblName & " SET " & numFieldName & " = null WHERE " & strFieldKey & " = " & lngKey & ";"
    End If
    db.Execute strSql, dbFailOnError + dbSeeChanges

End Sub
' редактируем числовое поле. 20.07.2022. Окончание
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' редактируем строковое поле. 19.07.2022
Public Sub varEditFieldStr(ByVal strFieldName As String, ByVal strNew As Variant, ByVal tblName As String, ByVal lngKey As Long, _
    ByVal strFieldKey As String, ByRef db As DAO.Database)
    
    Dim rs As DAO.Recordset

    ' текст с кавычками не ест, нужно вставлять через рекордсет
    Set rs = db.OpenRecordset(tblName, dbOpenDynaset, dbFailOnError + dbSeeChanges)
    With rs
        If Not .NoMatch Then
            .FindFirst strFieldKey & " = " & lngKey
            .Edit
                If Not IsNull(strNew) And strNew <> "" Then
                    .Fields(strFieldName) = strNew
                Else
                    .Fields(strFieldName) = Null
                End If
            .Update
        End If
    End With

End Sub
' редактируем строковое поле. 19.07.2022. Окончание
' ***************************************************************************************************************************************************

' отыскиваем ячейку по содержимому. 08.07.2022 ******************************************************************************************************
Public Function CellFind( _
    ByRef xlS As Excel.Worksheet, ByVal findStr As String, ByVal findAtXlLookAt As XlLookAt, ByRef findTextBox As TextBox, _
    ByRef findedCell As Range, _
    Optional ByRef findedColumn As Integer = -1, Optional ByVal startCellColumn As Integer = -1, Optional ByRef findedOffset As Integer = 0 _
    ) As Boolean
    ' здесь:
    ' xlS - лист, с которым работаем, findTextBox - объект отображающий записи о ходе ревизии
    ' -------------------------------------------------------------------------------------------------------------------------------------
    
    Dim c As Range
    
    Const cstrTitle As String _
        = "Процедура *Отыскиваем ячейку по содержимому*"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' отыскиваем колонку номеров отчётов
    Set c = xlS.UsedRange.Find(what:=findStr, LookAt:=findAtXlLookAt)
    If Not c Is Nothing Then
        'присваиваем возвращаемой переменной ячейки найденную ячейку
        Set findedCell = c:
        
        ' присваиваем возвращаемой переменной номер колонки найденной ячейки
        If findedColumn <> -1 Then
            findedColumn = c.Column
        End If
        
        If startCellColumn <> -1 Then
            'определяем смещение от начальной ячейки до найденой
            findedOffset = c.Column - startCellColumn
        End If
        
        findTextBox.value = "<P> <font color=""MediumSeaGreen"">Найдена</font> ячейка <b>" & findStr & "</b> колонка - " & c.Column & ", строка - " & c.Row & "." _
            & " Содержание: <font color=""blue"">" & c & "</font>.</P>" & findTextBox.value
        CellFind = True
    Else
        findTextBox.value = _
        "<P> <font color=""silver"">Ячейка</font> <b>" & findStr & "</b> <B><font color=""red"">не найдена</font></B></P>" & findTextBox.value
        CellFind = False
    End If

NormalExit:
    Exit Function
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Function
' отыскиваем ячейку по содержимому. 08.07.2022. Окончание *******************************************************************************************


' test stCost
Private Sub testStCost()
Dim db As DAO.Database, stCostTest As stCost

Set db = CurrentDb

Set stCostTest = ClassFactory.stCostByKey(212, db)

Set stCostTest = Nothing
End Sub

' test DB 22-0915_tblTest
Private Sub testDB()
    Dim db As DAO.Database, dbAccessTest As dbAccess, rs As DAO.Recordset, strVar As String
    Dim myArray(1 To 124, 1 To 2) As Variant
    Dim myTab As TableDef
    Dim myF As Field
    Dim fso As Object, oFile As Object, strPath As String
    
    ' 1 - откуда, 2 - куда
'    myArray(1, 1) = "cstKey": myArray(1, 2) = "testNumder"
'    myArray(2, 1) = "cstName": myArray(2, 2) = "testText"
'    myArray(3, 1) = "cstBusSgm": myArray(3, 2) = "testTextSecond"
    
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
    
'    strPath = "D:\db\Ф644Д_20-1207\sql.txt"
'    Set fso = CreateObject("Scripting.FileSystemObject")
'    Set oFile = fso.CreateTextFile(strPath)
    
'    oFile.WriteLine "test1"
'    oFile.WriteLine "test2"
'    oFile.WriteLine "test3"
    
    Set db = CurrentDb

    Set dbAccessTest = ClassFactory.dbAccessByDB(db)
    
    If dbAccessTest.SqlSrvRecordsetToTable("ags.spIpgChRsltCstUtl3_GP_3 4", "ipgChRsltPlCstSum", myArray()) Then
        
        MsgBox ("Перенесено в ipgChRsltPlCstSum")

'        Set myTab = db.CreateTableDef("ipgChRsltPlCst_2")

'        For i = 0 To rs.Fields.Count - 1
'            strVar = rs.Fields(i).name
'
'            oFile.WriteLine "myArray(" & i + 1 & ", 1) = """ & strVar & """: myArray(" & i + 1 & ", 2) = """ & strVar & """"
'
''            Set myF = myTab.CreateField(rs.Fields(i).name, rs.Fields(i).type)
''            myTab.Fields.Append myF
'
'        Next i

'        db.TableDefs.Append myTab

    End If
    
'    oFile.Close
'    Set fso = Nothing
'    Set oFile = Nothing
    
'    rs.Close: Set rs = Nothing
    Set dbAccessTest = Nothing
End Sub

Private Sub TabCreateArray()

    Dim db As DAO.Database, dbAccessTest As dbAccess, rs As DAO.Recordset, strVar As String
    Dim myTab As TableDef
    Dim myF As Field
    Dim fso As Object, oFile As Object, strPath As String

    strPath = "D:\db\Ф644Д_20-1207\sql.txt"
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set oFile = fso.CreateTextFile(strPath)
    
    Set db = CurrentDb
    Set rs = db.OpenRecordset("ipgChRsltPlCstPercent", dbOpenSnapshot)

    For i = 0 To rs.Fields.count - 1
        strVar = rs.Fields(i).name

        oFile.WriteLine "myArray(" & i + 1 & ", 1) = """ & strVar & """: myArray(" & i + 1 & ", 2) = """ & strVar & """"

'        Set myF = myTab.CreateField(rs.Fields(i).name, rs.Fields(i).type)
'        myTab.Fields.Append myF

    Next i

    oFile.Close
    Set fso = Nothing
    Set oFile = Nothing
    rs.Close: Set rs = Nothing
    

End Sub

' инвойс с пустой датой
Private Sub testInvDateNull()
Dim db As DAO.Database, invTest As Inv

Set db = CurrentDb

Set invTest = ClassFactory.invCreateNewNumDate("test", Null, db, "убрать потом")

Set invTest = Nothing
End Sub





' test ra_AgFee23_06
Private Sub testRa_AgFee23_06()
    Dim db As DAO.Database, ra_AgFee23_06Obj As ra_aAgFee23_06, strStr As String, ra_aObj As ra_a
    
    Set db = CurrentDb
    
    Set ra_aObj = ClassFactory.Ra_aReadKey(8, db)
    
    ra_aObj.ra_aAgFee23_06ChildAdd 290, db
    
    Set ra_aObj = Nothing

End Sub


' test ogAgFeePn
Private Sub testCstAg()

    Dim db As DAO.Database, cstAgPnObj As cstAgPn, strAccDoc As String
    
    Set db = CurrentDb
    
    Set cstAgPnObj = ClassFactory.cstAgPnByNameAndCodeNew("Техническое перевооружение ГРС ст. Новолабинская", "051-1006060", db)
'    ogAgFeeObj.strArrived = "08/023-5134"
    
    Set cstAgPnObj = Nothing

End Sub



' test prDocPn 5400029830 193
Private Sub testPrDocPn()

    Dim db As DAO.Database, prDocPnObj As prDocPn, strAccDoc As String
    
    Set db = CurrentDb
    
    Set prDocPnObj = ClassFactory.prDocPnByKey(70, db)
    
'    strAccDoc = prDocPnObj.strAccountingDoc

    prDocPnObj.strObject = Null
    
    Set prDocPnObj = Nothing

End Sub

' test CstAgPn
Private Sub testCstAgPn()
Dim db As DAO.Database, cstAgPnTest As cstAgPn

Set db = CurrentDb

Set cstAgPnTest = ClassFactory.cstAgPnByCode("014-2000186", db)

Set cstAgPnTest = Nothing
End Sub

' test ipgPnLim
Private Sub testipgPnLim()
Dim db As DAO.Database, ipgPnLimObj As ipgPnLim

Set db = CurrentDb

Set ipgPnLimObj = ClassFactory.ipgPnLimByKey(3938, db)

Set ipgPnLimObj = Nothing
End Sub

' test testIpgCh
Private Sub testIpgCh()
Dim db As DAO.Database, ipgChObj As ipgCh

Set db = CurrentDb

Set ipgChObj = ClassFactory.ipgChByKey(4, db)

Set ipgChObj = Nothing
End Sub

'Function ldm() As Date
'    Dim ddd As Date, ddl As Date
'
'    ddd = #12/12/2022#
'    ddl = ddLastDayInMonth(ddd)
'    ldm = ddl
'
'End Function

Function ddLastDayInMonth(Optional dtmDate As Date = 0) As Date
    ' Return the last day in the specified month.
    If dtmDate = 0 Then
        ' Did the caller pass in a date? If not, use
        ' the current date.
        dtmDate = Date
    End If
    ddLastDayInMonth = DateSerial(year(dtmDate), _
     Month(dtmDate) + 1, 0)
End Function

' test some
Private Sub testSome()
Dim db As DAO.Database, ipgPnIpg As ipgPn

Set db = CurrentDb

Set ipgPnIpg = ClassFactory.ipgPnByKey(39, db)

Set ipgPnIpg = Nothing
End Sub
