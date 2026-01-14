VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_CnInvPmtUpl>File_f"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

'****************************************************************************************************************************************************
' создаём новую стройку по имени и коду. 26.07.2023
Private Sub btnCstNewCreate_Click()
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Dim cstAgPnNew As cstAgPn
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Const cstrTitle As String = "Процедура *Создаём новую стройку по имени и коду*"
' ---------------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler
' ---------------------------------------------------------------------------------------------------------------------------------------------------
    Set cstAgPnNew = ClassFactory.cstAgPnByNameAndCodeNew _
        (Me![CnInvPmtUpl>File_f>CstNew].Form.pirName, Me![CnInvPmtUpl>File_f>CstNew].Form.cacOrNull, CurrentDb)
    If Not cstAgPnNew Is Nothing Then
        Me![CnInvPmtUpl>File_f>CstNew].Requery
    Else
        MsgBox ("Почему-то стройка не создана... Увы!")
    End If
    
    Set cstAgPnNew = Nothing
' ---------------------------------------------------------------------------------------------------------------------------------------------------
NormalExit:
    Exit Sub
ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
' ---------------------------------------------------------------------------------------------------------------------------------------------------
End Sub
' создаём новую стройку по имени и коду. 26.07.2023. Окончание
'****************************************************************************************************************************************************

'****************************************************************************************************************************************************
' создаём счёт-фактуру для договора. 03.05.2023
Private Sub btnInvCreate_Click()
    Dim strInvNum As String, lngCnKey As Long, invNew As Inv, cnInvNew As cnInv
    Const cstrTitle As String = "Процедура *Создаём новый счёт-фактуру для найденного договора*"
    '**************************************************************************************************************************************
On Error GoTo ErrHandler
    
    ' проверяем наличие договора
    If Me![CnInvPmtUpl>File_f>InvDouble].Form.Recordset.RecordCount > 0 Then
        If Me![CnInvPmtUpl>File_f>InvDouble].Form![ciputciCn_key] <> 0 Then
            ' договор есть
            lngCnKey = Me![CnInvPmtUpl>File_f>InvDouble].Form![ciputciCn_key]
            ' имеется ли номер счёта-фактуры?
            If Me![CnInvPmtUpl>File_f>InvDouble].Form![ciputciCnInv] <> "NullИлиПусто" Then
                ' да, номер счёта-фактуры имеется
                ' создаём счёт фактуру по номеру и дате
                strInvNum = Me![CnInvPmtUpl>File_f>InvDouble].Form![ciputciCnInv]
                Set invNew = ClassFactory.invCreateNewNumDate(strInvNum, Null, CurrentDb, _
                    "вручную, по кнопке для " & strInvNum & ", дебиторка, платежи")
            Else
                ' нет, номер счёта-фактуры отсутствует
                ' создаём счёт фактуру по дате
                Set invNew = ClassFactory.invCreateNewNumDate(Null, Null, CurrentDb, _
                    "вручную, по кнопке для *NullИлиПусто*, дебиторка, платежи")
            End If
            ' создаём новую связь инвойса и договора
            Set cnInvNew = ClassFactory.cnInvCreateNewInvCn(invNew.iKey, lngCnKey, CurrentDb, _
                "вручную, по кнопке, дебиторка, платежи")
            
            ' освобождаем объекты счёта-фактуры и связи
            Set invNew = Nothing: Set cnInvNew = Nothing
            ' обновляем форму
            Me![CnInvPmtUpl>File_f>InvDouble].Form.Requery
        End If
    End If

NormalExit:
    Exit Sub
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
End Sub
' создаём счёт-фактуру для договора. Окончание. 03.05.2023
'****************************************************************************************************************************************************

'****************************************************************************************************************************************************
' проверяем наличие стройки по выделенной последовательности символов. 26.05.2023
Private Sub btnTestWord_Click()
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Dim cstColMy As cstCol, strFilter As String
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Const cstrTitle As String = "Процедура *Проверяем наличие стройки по выделенной последовательности символов*"
' ---------------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler
' ---------------------------------------------------------------------------------------------------------------------------------------------------
    
    strFilter = Me![CnInvPmtUpl>File_f>CstNew].Form.pirName.SelText
    
    Set cstColMy = New cstCol
        cstColMy.cstTestWord strFilter
    Set cstColMy = Nothing
    
' ---------------------------------------------------------------------------------------------------------------------------------------------------
NormalExit:
    Exit Sub
ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
' ---------------------------------------------------------------------------------------------------------------------------------------------------
End Sub
' проверяем наличие стройки по выделенной последовательности символов. Окончание. 26.05.2023
'****************************************************************************************************************************************************

'****************************************************************************************************************************************************
' просматриваем или загружаем данные по дебиторской задолженности из выгрузки платежей 24.11.2021 14:44 *********************************************
Private Sub btnUpload_Click()

    Dim dStart As Date, dFinish As Date
    Dim db As DAO.Database, rsF As DAO.Recordset, strSql As String, strFFF As String, qd As DAO.QueryDef, rsFindCst As DAO.Recordset
    Dim xlA As Excel.Application, xlW As Excel.Workbook, xlS As Excel.Worksheet
    Dim iii As Long ' для нумераций
    Dim srtM As String

    Const cstrTitle As String _
        = "Процедура *Просматриваем или загружаем данные по дебиторской задолженности из выгрузки платежей"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

' имеется ли идентификатор выгрузки?
If IsNull(Me!cipufUpload) = False Then
    ' да, идентификатор выгрузки имеется
    Me!cipufLoadingProgress = "": dStart = DateTime.Now
    
    Me!cipufLoadingProgress = "<P><font color=""DarkGreen"">Начало работы с выгрузкой *<B><font color=""DarkGoldenrod"">" & Me!cipufPath & "</font></B>*." _
    & " <B>" & dStart & "</B> - Время начала работы.</font></P>"
    
    Set db = CurrentDb 'открываем переменную базы данных --------------------------------------------------------------------------------------------
    ' нужно ли обновлять промежуточную таблицу по данным источника?
    If Me!cipufFlTbl Then
        ' да, обновлять промежуточную таблицу по данным источника необходимо
        ' имеется ли лист для загрузки?
        If Not (IsNull(Me!cipufSheet) Or IsEmpty(Me!cipufSheet)) Then
            ' да, лист для загрузки имеется
            Me!cipufLoadingProgress = "<p>Лист для загрузки <font color=""DarkBlue""><b>" & Me!cipufSheet & "</b></font>.</p>" _
                & Me!cipufLoadingProgress
                
                ' открываем приложение
                Set xlA = CreateObject("Excel.Application")
            
                Me!cipufLoadingProgress = "<P>" & DateTime.Now & " - *<b><font color=""green"">" & "Приложение Excel открыто" _
                    & "</font>*</b></P>" & Me!cipufLoadingProgress
                    
                ' существует ли файл в файловой системе?
                Set fsof = CreateObject("Scripting.FileSystemObject")
                If (fsof.FileExists(Me!cipufPath)) Then
                    'да, файл существует
                    Me!cipufLoadingProgress = "<P>" & DateTime.Now & " - Файл с именем *" & Me!cipufPath _
                        & "* в файловой системе обнаружен</P>" & Me!cipufLoadingProgress
                        
                        'открываем файл
                        Set xlW = xlA.Workbooks.Open(filename:=Me!cipufPath, ReadOnly:=True, UpdateLinks:=0)
                            
                        Me!cipufLoadingProgress = "<P>" & DateTime.Now & " - Файл с именем *<font color=""green"">" & Me!cipufPath _
                        & "</font>* в приложении открыт</P>" & Me!cipufLoadingProgress
                        
                        ' вызываем процедуру *рассматриваем лист отдельного счёта из выгрузки бухгалтерии Ф644*
                        SheetTest db, xlW, Me!cipufSheet, Me!cipufUpload, Me!cipufLoadingProgress

                        'закрываем файл
                        xlW.Close SaveChanges:=False: Set xlW = Nothing
                        
                        Me!cipufLoadingProgress = "<P>" & DateTime.Now & " - Файл с именем *<font color=""blue"">" & Me!cipufPath _
                        & "</font>* в приложении закрыт</P>" & Me!cipufLoadingProgress
                                    
                    Else
                    'нет, файл не существует
                    Me!cipufLoadingProgress = "<P>Файл с именем *<B><font color=""red"">" & Me!cipufPath _
                        & "</font></B>* в файловой системе не обнаружен</P>" & Me!cipufLoadingProgress
                End If
            
            'закрываем приложение без сохранения книг
            xlA.Quit: Set xlA = Nothing
            
            Me!cipufLoadingProgress = "<P>" & DateTime.Now & " - *<B><font color=""blue"">" & "Приложение Excel закрыто" & "</font></B>*</P>" _
            & Me!cipufLoadingProgress
            
            Else
            ' нет, лист для загрузки отсутствует
            Me!cipufLoadingProgress = "<p>Лист для загрузки <font color=""Salmon"">не определен</font>.</p>" _
                & Me!cipufLoadingProgress
        End If
        Else
        ' нет, обновлять промежуточную таблицу по данным источника не нужно
        Me!cipufLoadingProgress = "<p><font color=""Black"">Обновлять промежуточную таблицу по данным источника <font color=""DarkBlue"">не нужно</font>.</font></p>" _
            & Me!cipufLoadingProgress
    End If
    
    ' отображаем отсутствующих контрагентов =========================================================================================================
    cipuCtpt_All_OIdNot db, Me!cipufLoadingProgress

    ' отображаем отсутствующие стройки ==============================================================================================================
    cipuCacNot db, Me!cipufLoadingProgress

    ' отображаем отсутствующие договоры либо добавляем их ===========================================================================================
    cipuCn_CtptCnNotLoad db, Me!cipufLoadingProgress, Me!cipufFlLoad

    ' отображаем пары договор+исполнитель встречающиеся в БД более одного раза ======================================================================
    cipuCn_CtptCnTwo db, Me!cipufLoadingProgress

    ' отображаем договора, не имеющие агента в БД. Либо добавляем их ================================================================================
    cipuCn_AgNotLoad db, Me!cipufLoadingProgress, Me!cipufFlLoad

    ' отображаем договора, имеющие в БД одного агента более чем один раз ============================================================================
    cipuCn_AgTwo db, Me!cipufLoadingProgress

    ' отображаем новые счета-фактуры для существующих договоров =====================================================================================
    cipuCn_CtptCnOneInvNotLoad db, Me!cipufLoadingProgress, Me!cipufFlLoad

    ' отображаем счета-фактуры существующих договоров имеющиеся в БД более чем однократно либо добавляем их =========================================
    cipuCn_CtptCnOneInvTwoLoad db, Me!cipufLoadingProgress, Me!cipufFlLoad

    ' отображаем счета-фактуры не имеющие пар "счёт-фактура + счёт главной книги" в БД либо добавляем их ============================================
    cipuCn_CtptCnOneInvOneAcNotLoad db, Me!cipufLoadingProgress, Me!cipufFlLoad

    ' отображаем отстутствующие в БД платёжные документы либо добавляем их ==========================================================================
    cipuDocNotLoad db, Me!cipufLoadingProgress, Me!cipufFlLoad

    ' отображаем количество счётов-фактур, для которых отстутствуют в БД платёжные документы ========================================================
    cipuCn_CtptCnOneInvOneAcDcNot db, Me!cipufLoadingProgress

    ' отображаем платежи, готовые к внесению в БД либо вносим их ====================================================================================
    cipuInsPmNotLoad db, Me!cipufLoadingProgress, Me!cipufFlLoad

    ' отображаем платежи, готовые к внесению в БД, имеющиеся в БД ===================================================================================
    cipuInsPmExt db, Me!cipufLoadingProgress

    db.Close 'закрываем переменную базы данных ------------------------------------------------------------------------------------------------------

    dFinish = DateTime.Now: dDateDiff = DateDiff("s", dStart, dFinish)

    Me!cipufLoadingProgress = "<P>В " & dFinish & " - *<B><font color=""blue"">" & "работа с выгрузкой завершена" _
    & "</font></B>*. C " & dStart & " в течении " & dDateDiff \ 60 & " мин. " & dDateDiff - ((dDateDiff \ 60) * 60) & " сек., (всего " _
    & dDateDiff & " сек.).</P><p></p>" & Me!cipufLoadingProgress
    
    Else
    ' нет, идентификатор загрузки отсутствует
    MsgBox ("Отсутствует идентификатор выгрузки")

End If

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' просматриваем или загружаем данные по дебиторской задолженности из выгрузки платежей, окончание ***************************************************
'****************************************************************************************************************************************************



'****************************************************************************************************************************************************
' отображаем счета-фактуры существующих договоров имеющиеся в БД более чем однократно либо добавляем их. 06.12.2021 12:59 ***************************
Private Sub cipuCn_CtptCnOneInvTwoLoad(ByRef db As DAO.Database, ByRef rslt As Object, ByVal cipufFlLoad As Boolean)

    Dim strSql As String, rsF As DAO.Recordset, qd As DAO.QueryDef, RcdCount As Long

    Const cstrTitle As String _
        = "Процедура *Отображаем счета-фактуры существующих договоров имеющиеся в БД более чем однократно либо добавляем их*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0

    ' отображаем договора, имеющие новые счета-фактуры
    cipuCn_CtptCnOneInvTwo db, rslt, RcdCount
    
    ' есть ли необходимость обновлять БД?
    If cipufFlLoad And RcdCount > 0 Then
        ' да, необходимость обновлять БД имеется
        ' добавляем счета-фактуры
'        Set qd = db.CreateQueryDef("", SqlCnCtptExistInvNotLoad()): qd.Execute dbFailOnError
 '       Rslt = "<p>Внесено счетов-фактур (строк) в БД: <b><font color=""DarkGreen"">" & qd.RecordsAffected & "</font></b></p>" & Rslt
  '      qd.Close: Set qd = Nothing
        
        ' ещё раз отображаем договора, имеющие новые счета-фактуры
        cipuCn_CtptCnOneInvTwo db, rslt, RcdCount
        Else
        ' нет, необходимость обновлять БД отсутствует
    End If
    
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем счета-фактуры существующих договоров имеющиеся в БД более чем однократно либо добавляем их, окончание **********************************
'****************************************************************************************************************************************************


'****************************************************************************************************************************************************
' отображаем счета-фактуры существующих договоров имеющиеся в БД более чем однократно 06.12.2021 13:01 **********************************************
Private Sub cipuCn_CtptCnOneInvTwo(ByRef db As DAO.Database, ByRef rslt As Object, ByRef RcdCount As Long)

    Dim strSql As String, rsF As DAO.Recordset, qd As DAO.QueryDef

    Const cstrTitle As String _
        = "Процедура *Отображаем счета-фактуры существующих договоров имеющиеся в БД более чем однократно*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0

    ' очищаем табличку новых счётов-фактур
    strSql = "DELETE * FROM CnInvPmtUplTblCnInv": Set qd = db.CreateQueryDef("", strSql): qd.Execute dbFailOnError
    qd.Close: Set qd = Nothing
    
    ' вновь заполняем табличку счётов-фактур
    db.Execute "cipuCn_CtptCnOneInvTwoIns", dbFailOnError: RcdCount = db.RecordsAffected
    
    ' отображаем договора, имеющие новые счета-фактуры
    Set rsF = db.OpenRecordset("cipuCn_CtptCnOneInvTwoCn", dbOpenSnapshot)
    ' имеются ли записи договоров?
    If rsF.RecordCount > 0 Then
        rsF.MoveLast
        ' да, записи договоров имеются
        rslt = "<p>В источнике <font color=""CadetBlue"">имеются договора</font>, (" _
            & rsF.RecordCount _
            & ") к которым <font color=""Goldenrod"">имеются счета-фактуры двоящие в БД</font> (" _
            & RcdCount & ").</p><p></p>" _
            & rslt
        ' проходим по каждой записи
        rsF.MoveFirst: iii = 1
        Do Until rsF.EOF = True
            strSql = ""
            strSql = "<p><font color=""silver"">"
                strSql = strSql & "Договор: <font color=""DarkSlateBlue"">" & iii & "</font>"
                strSql = strSql & ". <font color=""CadetBlue"">" & rsF!ciputciCntrPrtName & "</font>"
                strSql = strSql & ". БУиРГ: <font color=""DarkCyan"">" & rsF!ciputciCntrPrtNum & "</font>"
                strSql = strSql & ". № договора: <font color=""CadetBlue""><b>" & rsF!ciputciCnName & "</b></font>"
                ' отсутствует ли дата договора?
'                If IsNull(rsF!cidutciCnDate) Then
'                    ' да, дата договора отсутствует
'                    strSQL = strSQL & " , <font color=""DarkGoldenrod"">дата отсутствует</font>"
                    srtM = CnInvConcatPm(db, rsF!ciputciCntrPrtNum, rsF!ciputciCnName)
'                    Else
'                    ' нет, дата договора имеется
'                    strSQL = strSQL & " от <font color=""DarkSlateBlue"">" & rsF!cidutciCnDate & "</font>"
'                    srtM = CnInvConcatPm(db, rsF!cidutciCntrPrtNum, rsF!cidutciCnName, rsF!cidutciCnDate)
'                End If
                strSql = strSql & ". CnId: <font color=""DarkViolet"">" & rsF!ciputciCn_key & "</font>"
                strSql = strSql & ". Всего: <b><font color=""DarkGoldenrod"">" & rsF!ciputciCnInvCount & "</font></b>"
                strSql = strSql & ". Счета-фактуры: <font color=""DarkGray"">" & srtM & "</font>"
                strSql = strSql & "</font>.</p>"
            rslt = strSql & rslt
            ' переходим к следующей записи
            rsF.MoveNext: iii = iii + 1
        Loop
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p>В источнике <font color=""Olive""><b>отсутствуют договора, имеющие счета-фактуры двоящие в БД</b></font>.</p><p></p>" & rslt
    End If

    ' закрываем набор данных
    rsF.Close: Set rsF = Nothing

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем счета-фактуры существующих договоров имеющиеся в БД более чем однократно, окончание ****************************************************
'****************************************************************************************************************************************************







'****************************************************************************************************************************************************
' отображаем платежи, готовые к внесению в БД, имеющиеся в БД. 02.12.2021 17:34 **************************************************************
Private Sub cipuInsPmExt(ByRef db As DAO.Database, ByRef rslt As Object)

    Dim strSql As String, rsF As DAO.Recordset, RcdCount As Long, qd As DAO.QueryDef

    Const cstrTitle As String _
        = "Процедура *Отображаем платежи, готовые к внесению в БД либо вносим их*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0

    ' отображаем количество имеющихся в БД
    Set rsF = db.OpenRecordset("cipuInsPmExt", dbOpenSnapshot)
    ' имеются ли записи?
    If rsF.RecordCount > 0 Then
        ' да, записи имеются
        rsF.MoveLast
        RcdCount = rsF.RecordCount
        rslt = "<p><font color=""Black"">В источнике <font color=""CadetBlue"">имеются платежи</font>" _
            & " <font color=""DarkGreen""><b>уже внесенные в БД</b></font>. В количестве " _
            & RcdCount & ".</font>.</p><p></p>" _
            & rslt
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p><font color=""Black"">В источнике <font color=""Olive"">отсутствуют платежи, " _
            & "<b>уже внесенные в БД</b></font>.</font> " _
            & ".</p><p></p>" & rslt
    End If
    
    ' закрываем набор данных
    rsF.Close: Set rsF = Nothing
    
    ' отображаем имеющие расхождения в значениях
    ' пока нет смысла их здесь раскрывать из-за отстутствия времени.
    ' Если есть расхождения то можно залезть в запрос и увидеть в нём, что нужно. 03.12.2021
    Set rsF = db.OpenRecordset("cipuInsPmExtFalse", dbOpenSnapshot)
    ' имеются ли записи?
    If rsF.RecordCount > 0 Then
        ' да, записи имеются
        rsF.MoveLast
        RcdCount = rsF.RecordCount
        rslt = "<p><font color=""Black"">В источнике <font color=""CadetBlue"">имеются платежи</font>" _
            & " <font color=""DarkGreen""><b>уже внесенные в БД, с разночтениями в значениях</b></font>. В количестве " _
            & RcdCount & ".</font>.</p><p></p>" _
            & rslt
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p><font color=""Black"">В источнике <font color=""Olive"">отсутствуют платежи, " _
            & "<b>уже внесенные в БД, с разночтениями в значениях</b></font>.</font> " _
            & ".</p><p></p>" & rslt
    End If
    
    ' закрываем набор данных
    rsF.Close: Set rsF = Nothing


NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем платежи, готовые к внесению в БД либо вносим их, окончание *****************************************************************************
'****************************************************************************************************************************************************

'****************************************************************************************************************************************************
' отображаем платежи, готовые к внесению в БД либо вносим их. 02.12.2021 12:53 **************************************************************
Private Sub cipuInsPmNotLoad(ByRef db As DAO.Database, ByRef rslt As Object, ByVal cipufFlLoad As Boolean)

    Dim strSql As String, rsF As DAO.Recordset, RcdCount As Long, qd As DAO.QueryDef

    Const cstrTitle As String _
        = "Процедура *Отображаем платежи, готовые к внесению в БД либо вносим их*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0

    ' получаем готовые платежи и отображаем их количество в промежуточной табличке
    ' очищаем табличку готовых платежей
    strSql = "DELETE * FROM cipuCn_CtptCnOneInvOneAcDcExtPmTbl": Set qd = db.CreateQueryDef("", strSql): qd.Execute dbFailOnError
    qd.Close: Set qd = Nothing
    
    ' вновь заполняем табличку готовых платежей
    db.Execute "cipuCn_CtptCnOneInvOneAcDcExtPmIns", dbFailOnError ': RcdCount = db.RecordsAffected

    ' получаем в запросе платежи отсутствующие в БД. Если обновлять БД не нужно, то отображаем их количество.
    ' Если нужно то вносим. И после этого снова проверяем их наличие.
    Set rsF = db.OpenRecordset("cipuInsPmNot", dbOpenSnapshot)
    ' имеются ли записи?
    If rsF.RecordCount > 0 Then
        ' да, записи имеются
        rsF.MoveLast
        RcdCount = rsF.RecordCount
        rslt = "<p><font color=""Black"">В источнике <font color=""CadetBlue"">имеются платежи</font>" _
            & " , отстутствующие в БД <font color=""DarkGreen""><b>готовые к внесению</b></font>. В количестве " _
            & RcdCount & ".</font>.</p><p></p>" _
            & rslt
        ' нужно ли обновлять БД
        If cipufFlLoad Then
            ' да, обновлять БД нужно
            db.Execute "cipuInsPmNotIns", dbFailOnError + dbSeeChanges: RcdCount = db.RecordsAffected
            rslt = "<p>Внесено платежи в количестве: <font color=""DarkGreen""><b>" & RcdCount & "</b></font> записей.</p>" & rslt
            Else
            ' нет, обновлять БД не нужно
        End If
        ' проходим по каждой записи
'        rsF.MoveFirst: iii = 1
'        Do Until rsF.EOF = True
'            strSQL = ""
'            strSQL = "<p><font color=""silver"">"
'                strSQL = strSQL & "Договор: <font color=""DarkSlateBlue"">" & iii & "</font>"
'                strSQL = strSQL & ". № *<font color=""Salmon"">" & rsF!CnName & "</font>*"
'                strSQL = strSQL & ". *<font color=""Salmon"">" & rsF!ciputAgentNum & "</font>*"
'                strSQL = strSQL & ". БУиРГ *<font color=""Salmon"">" & rsF!ciputAgentName & "</font>*"
'                strSQL = strSQL & ". Количество: *<font color=""Salmon"">" & rsF!countCn_s_org_key & "</font>*"
'                strSQL = strSQL & ". cn_key: *<font color=""Salmon"">" & rsF!cn_key & "</font>*"
'                strSQL = strSQL & "</font>.</p>"
'            Rslt = strSQL & Rslt
'            ' переходим к следующей записи
'            rsF.MoveNext: iii = iii + 1
'        Loop
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p><font color=""Black"">В источнике <font color=""Olive"">отсутствуют платежи, отстутствующие в БД, " _
            & "<b>готовые к внесению</b></font>.</font> " _
            & ".</p><p></p>" & rslt
    End If
    
    ' закрываем набор данных
    rsF.Close: Set rsF = Nothing

    ' получаем в запросе платежи имеющиеся в БД. Если обновлять БД не нужно, то проверяем соответствие значений. Если нужно то обновляем.
    ' Это наверное лучше в отдельной процедуре.

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем платежи, готовые к внесению в БД либо вносим их, окончание *****************************************************************************
'****************************************************************************************************************************************************


'****************************************************************************************************************************************************
' отображаем договора, имеющие в БД одного агента более чем один раз. 01.12.2021 17:02 **************************************************************
Private Sub cipuCn_AgTwo(ByRef db As DAO.Database, ByRef rslt As Object)

    Dim strSql As String, rsF As DAO.Recordset, RcdCount As Long

    Const cstrTitle As String _
        = "Процедура *Отображаем отсутствующие стройки*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0

    Set rsF = db.OpenRecordset("cipuCn_AgTwo", dbOpenSnapshot)
    ' имеются ли записи?
    If rsF.RecordCount > 0 Then
        ' да, записи имеются
        rsF.MoveLast
        RcdCount = rsF.RecordCount
        rslt = "<p><font color=""Black"">В источнике <font color=""CadetBlue"">имеются договора</font>, " _
            & " для которых в БД <font color=""Goldenrod"">один Агент имеется более чем один раз</font>. В количестве " _
            & RcdCount & ".</font> Их не можем идентифицировать из за отсутствия даты или ключа договора.</p><p></p>" _
            & rslt
        ' проходим по каждой записи
        rsF.MoveFirst: iii = 1
        Do Until rsF.EOF = True
            strSql = ""
            strSql = "<p><font color=""silver"">"
                strSql = strSql & "Договор: <font color=""DarkSlateBlue"">" & iii & "</font>"
                strSql = strSql & ". № *<font color=""Salmon"">" & rsF!cnName & "</font>*"
                strSql = strSql & ". *<font color=""Salmon"">" & rsF!ciputAgentNum & "</font>*"
                strSql = strSql & ". БУиРГ *<font color=""Salmon"">" & rsF!ciputAgentName & "</font>*"
                strSql = strSql & ". Количество: *<font color=""Salmon"">" & rsF!CountCsosKey & "</font>*"
                strSql = strSql & ". cn_key: *<font color=""Salmon"">" & rsF!cn_key & "</font>*"
                strSql = strSql & "</font>.</p>"
            rslt = strSql & rslt
            ' переходим к следующей записи
            rsF.MoveNext: iii = iii + 1
        Loop
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p><font color=""Black"">В источнике <font color=""Olive"">отсутствуют договоры с " _
            & "<b>имеющимие</b> в БД одного Агента более чем один раз</font>.</font> " _
            & "Их не можем идентифицировать из за отсутствия даты или ключа договора.</p><p></p>" & rslt
    End If
    
    ' закрываем набор данных
    rsF.Close: Set rsF = Nothing
    
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем договора, имеющие в БД одного агента более чем один раз, окончание *********************************************************************
'****************************************************************************************************************************************************



'****************************************************************************************************************************************************
' отображаем договора, не имеющие агента в БД. Либо добавляем их. 01.12.2021 15:19 ******************************************************************
Private Sub cipuCn_AgNotLoad(ByRef db As DAO.Database, ByRef rslt As Object, ByVal cipufFlLoad As Boolean)

    Dim strSql As String, rsF As DAO.Recordset, qd As DAO.QueryDef, RcdCount As Long

    Const cstrTitle As String _
        = "Процедура *Отображаем договора, не имеющие агента в БД. Либо добавляем их*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0

    ' отображаем договора, не имеющие агента в БД
    cipuCn_AgNot db, rslt, RcdCount, cipufFlLoad
    
    ' есть ли необходимость обновлять БД?
    If cipufFlLoad And RcdCount > 0 Then
        ' да, необходимость обновлять БД имеется
        
        ' ещё раз отображаем договора, не имеющие агента в БД
        cipuCn_AgNot db, rslt, RcdCount, False
        Else
        ' нет, необходимость обновлять БД отсутствует
    End If
    
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем договора, не имеющие агента в БД. Либо добавляем их, окончание *************************************************************************
'****************************************************************************************************************************************************


'****************************************************************************************************************************************************
' отображаем договора, не имеющие агента в БД. 01.12.2021 15:22 *************************************************************************************
Private Sub cipuCn_AgNot(ByRef db As DAO.Database, ByRef rslt As Object, ByRef RcdCount As Long, ByVal cipufFlLoad As Boolean)

    Dim strSql As String, rsF As DAO.Recordset
    Dim rsCnS_Add As DAO.Recordset, rsCnS_OrgAdd As DAO.Recordset
    Dim rsAddId As Long

    Const cstrTitle As String _
        = "Процедура *Отображаем договора, не имеющие агента в БД*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0: rsAddId = 0

    Set rsF = db.OpenRecordset("cipuCn_AgNot", dbOpenSnapshot)
    ' имеются ли записи?
    If rsF.RecordCount > 0 Then
        ' да, записи имеются
        rsF.MoveLast
        RcdCount = rsF.RecordCount
        rslt = "<p>В источнике <font color=""CadetBlue"">имеются договора</font>, " _
            & " для которых в БД <font color=""Goldenrod"">отсутствуют агенты (заказчики)</font>. В количестве " _
            & RcdCount & ".</p><p></p>" _
            & rslt
            
        ' при необходимости обновления БД открываем таблицы для добавления
        If cipufFlLoad Then
            Set rsCnS_Add = db.OpenRecordset("ags_cn_s", dbOpenDynaset, dbFailOnError + dbSeeChanges)
            Set rsCnS_OrgAdd = db.OpenRecordset("ags_cn_s_org", dbOpenDynaset, dbFailOnError + dbSeeChanges)
        End If
            
        ' проходим по каждой записи
        rsF.MoveFirst: iii = 1
        Do Until rsF.EOF = True
            strSql = ""
            strSql = "<p><font color=""silver"">"
                strSql = strSql & "Договор: <font color=""DarkSlateBlue"">" & iii & "</font>"
                strSql = strSql & ". <font color=""CadetBlue"">" & rsF!ciputAgentName & "</font>"
                strSql = strSql & ". БУиРГ: <font color=""DarkCyan"">" & rsF!ciputAgentNum & "</font>"
                strSql = strSql & ". № договора: <font color=""CadetBlue""><b>" & rsF!cnName & "</b></font>"
                strSql = strSql & ". cn_key: <font color=""DarkViolet"">" & rsF!cn_key & "</font>"
                ' имеется ли у договора сторона заказчика?
                If IsNull(rsF!cn_s_key) Then
                    ' нет, сторона заказчика у договора отсутствует
                    strSql = strSql & ". cn_s_key: <font color=""Salmon"">пусто</font>"
                    ' добавляем сторону договора
                    ' нужно ли обновлять БД?
                    If cipufFlLoad Then
                        ' да, обновлять БД нужно
                        With rsCnS_Add
                            .AddNew
                                !cn_key = rsF!cn_key
                                !cn_s_type = 1
                            .Update
                            .Bookmark = .LastModified
                            rsAddId = !cn_s_key
                        End With
                        strSql = strSql & ". Создана: cn_s_key: <font color=""Teal"">" & rsAddId & "</font>"
                    End If
                    Else
                    ' да, сторона заказчика у договора имеется
                    rsAddId = rsF!cn_s_key
                    strSql = strSql & ". cn_s_key: <font color=""DarkViolet"">" & rsF!cn_s_key & "</font>"
                End If
                ' нужно ли обновлять БД?
                If cipufFlLoad Then
                    ' да, обновлять БД нужно
                    ' добавляем сторону договора - организацию
                    With rsCnS_OrgAdd
                        .AddNew
                            !cn_s_key = rsAddId
                            !org_id = rsF!org_id_key
                        .Update
                        .Bookmark = .LastModified
                        rsAddId = !cn_s_org_key
                    End With
                    strSql = strSql & ". Добавлено: CnS_OrgId: <font color=""Teal"">" & rsAddId & "</font>"
                    Else
                    ' нет, обновлять БД не нужно
                    strSql = strSql & ". org_id_key: <font color=""DarkViolet"">" & rsF!org_id_key & "</font>"
                End If
                strSql = strSql & "</font>.</p>"
            rslt = strSql & rslt
            ' переходим к следующей записи
            rsF.MoveNext: iii = iii + 1
        Loop
        
        ' при необходимости обновления БД закрываем таблицы для добавления
        If cipufFlLoad Then
            rsCnS_Add.Close:        Set rsCnS_Add = Nothing
            rsCnS_OrgAdd.Close:     Set rsCnS_OrgAdd = Nothing
        End If
        
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p>В источнике <font color=""Olive"">отсутствуют договора с " _
            & "<b>отсутствующими</b> в БД агентами (заказчиками)</font>.</p><p></p>" & rslt
    End If
    
    ' закрываем набор данных
    rsF.Close: Set rsF = Nothing
    
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем договора, не имеющие агента в БД, окончание *******************************************************
'****************************************************************************************************************************************************






'****************************************************************************************************************************************************
' отображаем отсутствующие стройки. 01.12.2021 10:50 ************************************************************************************************
Private Sub cipuCacNot(ByRef db As DAO.Database, ByRef rslt As Object)

    Dim strSql As String, rsF As DAO.Recordset, RcdCount As Long

    Const cstrTitle As String _
        = "Процедура *Отображаем отсутствующие стройки*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0

    Set rsF = db.OpenRecordset("cipuCacNot", dbOpenSnapshot)
    ' имеются ли записи?
    If rsF.RecordCount > 0 Then
        ' да, записи имеются
        rsF.MoveLast
        RcdCount = rsF.RecordCount
        rslt = "<p><font color=""Black"">В источнике <font color=""CadetBlue"">имеются стройки</font>, " _
            & " для которых в БД <font color=""Goldenrod"">отсутствуют объекты *стройка-заказчик-код*</font>. В количестве " _
            & RcdCount & ".</font></p><p></p>" _
            & rslt
        ' проходим по каждой записи
        rsF.MoveFirst: iii = 1
        Do Until rsF.EOF = True
            strSql = ""
            strSql = "<p><font color=""silver"">"
                strSql = strSql & "Стройка: <font color=""DarkSlateBlue"">" & iii & "</font>"
                strSql = strSql & ". *<font color=""Salmon"">" & rsF!cacOrNull & "</font>*"
                strSql = strSql & "</font>.</p>"
            rslt = strSql & rslt
            ' переходим к следующей записи
            rsF.MoveNext: iii = iii + 1
        Loop
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p><font color=""Black"">В источнике <font color=""Olive"">отсутствуют стройки с " _
            & "<b>отсутствующими</b> в БД объектами *стройка-заказчик-код*</font>.</font></p><p></p>" & rslt
    End If
    
    ' закрываем набор данных
    rsF.Close: Set rsF = Nothing
    
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем счета-фактуры не имеющие пар "счёт-фактура + счёт главной книги" в БД, окончание *******************************************************
'****************************************************************************************************************************************************



'****************************************************************************************************************************************************
' отображаем отстутствующие в БД платёжные документы либо добавляем их. 30.11.2021 17:11 ************************************************************
Private Sub cipuDocNotLoad(ByRef db As DAO.Database, ByRef rslt As Object, ByVal cipufFlLoad As Boolean)

    Dim strSql As String, rsF As DAO.Recordset, qd As DAO.QueryDef, RcdCount As Long

    Const cstrTitle As String _
        = "Процедура *Отображаем отстутствующие в БД платёжные документы либо добавляем их*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0
    
    ' отображаем счета-фактуры не имеющие пар "счёт-фактура + счёт главной книги" в БД
    cipuDocNot db, rslt, RcdCount
    
    ' есть ли необходимость обновлять БД?
    If cipufFlLoad And RcdCount > 0 Then
        ' да, необходимость обновлять БД имеется
        ' добавляем счета-фактуры
        'Set qd = db.CreateQueryDef("", SqlCnCtptInvExistAccNotLoad())
        db.Execute "cipuDocNotIns", dbFailOnError
        rslt = "<p>Внесено документов (строк) в БД: <b><font color=""DarkGreen"">" & db.RecordsAffected & "</font></b> Для " _
            & RcdCount & ".</p>" & rslt
        'qd.Close: Set qd = Nothing
        
        ' ещё раз отображаем счета-фактуры, не имеющие пар "счёт-фактура + счёт главной книги" в БД
        cipuDocNot db, rslt, RcdCount
        Else
        ' нет, необходимость обновлять БД отсутствует
    End If

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем отстутствующие в БД платёжные документы либо добавляем их, окончание *******************************************************************
'****************************************************************************************************************************************************


'****************************************************************************************************************************************************
' отображаем количество счётов-фактур, для которых отстутствуют в БД платёжные документы. 30.11.2021 17:46 ******************************************
Private Sub cipuCn_CtptCnOneInvOneAcDcNot(ByRef db As DAO.Database, ByRef rslt As Object)

    Dim strSql As String, rsF As DAO.Recordset, qd As DAO.QueryDef, RcdCount As Long

    Const cstrTitle As String _
        = "Процедура *Отображаем отстутствующие в БД платёжные документы*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0
    
    Set rsF = db.OpenRecordset("cipuCn_CtptCnOneInvOneAcDcNot", dbOpenSnapshot)
    ' имеются ли записи?
    If rsF.RecordCount > 0 Then
        ' да, записи имеются
        rsF.MoveLast
        RcdCount = rsF.RecordCount
        rslt = "<p>В источнике <font color=""CadetBlue"">имеются счета-фактуры</font>, " _
            & " <font color=""Salmon""><b> платёжные документы которых отсутствуют в БД</b></font>. В количестве <b>" _
            & RcdCount & "</b>.</p><p></p>" _
            & rslt
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p>В источнике <font color=""Olive"">отсутствуют счета-фактуры " _
            & "<b>платёжные документы которых отсутствуют в БД</b></font>.</p><p></p>" & rslt
    End If
    
    ' закрываем набор данных
    rsF.Close: Set rsF = Nothing

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем количество счётов-фактур, для которых отстутствуют в БД платёжные документы, окончание *************************************************
'****************************************************************************************************************************************************


'****************************************************************************************************************************************************
' отображаем отстутствующие в БД платёжные документы. 30.11.2021 17:14 ******************************************************************************
Private Sub cipuDocNot(ByRef db As DAO.Database, ByRef rslt As Object, ByRef RcdCount As Long)

    Dim strSql As String, rsF As DAO.Recordset, qd As DAO.QueryDef

    Const cstrTitle As String _
        = "Процедура *Отображаем отстутствующие в БД платёжные документы*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0
    
    Set rsF = db.OpenRecordset("cipuDocNot", dbOpenSnapshot)
    ' имеются ли записи?
    If rsF.RecordCount > 0 Then
        ' да, записи имеются
        rsF.MoveLast
        RcdCount = rsF.RecordCount
        rslt = "<p>В источнике <font color=""CadetBlue"">имеются документы</font>, " _
            & " <font color=""Salmon""><b>отсутствующие в БД</b></font>. В количестве <b>" _
            & RcdCount & "</b>.</p><p></p>" _
            & rslt
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p>В источнике <font color=""Olive"">отсутствуют документы " _
            & "<b>отсутствующие</b> в БД</font>.</p><p></p>" & rslt
    End If
    
    ' закрываем набор данных
    rsF.Close: Set rsF = Nothing

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем отстутствующие в БД платёжные документы, окончание *************************************************************************************
'****************************************************************************************************************************************************

'****************************************************************************************************************************************************
' отображаем счета-фактуры не имеющие пар "счёт-фактура + счёт главной книги" в БД либо добавляем их. 30.11.2021 11:46 ******************************
Private Sub cipuCn_CtptCnOneInvOneAcNotLoad(ByRef db As DAO.Database, ByRef rslt As Object, ByVal cidufFlLoad As Boolean)

    Dim strSql As String, rsF As DAO.Recordset, qd As DAO.QueryDef, RcdCount As Long

    Const cstrTitle As String _
        = "Процедура *Отображаем счета-фактуры не имеющие пар #счёт-фактура + счёт главной книги# в БД либо добавляем их*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0

    ' отображаем счета-фактуры не имеющие пар "счёт-фактура + счёт главной книги" в БД
    cipuCn_CtptCnOneInvOneAcNot db, rslt, RcdCount
    
    ' есть ли необходимость обновлять БД?
    If cidufFlLoad And RcdCount > 0 Then
        ' да, необходимость обновлять БД имеется
        ' добавляем счета-фактуры
        'Set qd = db.CreateQueryDef("", SqlCnCtptInvExistAccNotLoad())
        db.Execute "cipuCn_CtptCnOneInvOneAcNotIns", dbFailOnError
        rslt = "<p>Внесено пар СФ+СГК (строк) в БД: <b><font color=""DarkGreen"">" & db.RecordsAffected & "</font></b> Для " _
            & RcdCount & " задолженностей.</p>" & rslt
        'qd.Close: Set qd = Nothing
        
        ' ещё раз отображаем счета-фактуры, не имеющие пар "счёт-фактура + счёт главной книги" в БД
        cipuCn_CtptCnOneInvOneAcNot db, rslt, RcdCount
        Else
        ' нет, необходимость обновлять БД отсутствует
    End If
    
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем счета-фактуры не имеющие пар "счёт-фактура + счёт главной книги" в БД либо добавляем их, окончание *************************************
'****************************************************************************************************************************************************


'****************************************************************************************************************************************************
' отображаем счета-фактуры не имеющие пар "счёт-фактура + счёт главной книги" в БД. 30.11.2021 11:47 ************************************************
Private Sub cipuCn_CtptCnOneInvOneAcNot(ByRef db As DAO.Database, ByRef rslt As Object, ByRef RcdCount As Long)

    Dim strSql As String, rsF As DAO.Recordset

    Const cstrTitle As String _
        = "Процедура *Отображаем счета-фактуры не имеющие пар #счёт-фактура + счёт главной книги# в БД*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0

    Set rsF = db.OpenRecordset("cipuCn_CtptCnOneInvOneAcNot", dbOpenSnapshot)
    ' имеются ли записи?
    If rsF.RecordCount > 0 Then
        ' да, записи имеются
        rsF.MoveLast
        RcdCount = rsF.RecordCount
        rslt = "<p>В источнике <font color=""CadetBlue"">имеются счета-фактуры</font>, " _
            & " для которых в БД <font color=""Goldenrod"">отсутствуют пары *счёт-фактура + счёт главной книги*</font>. Для задолженностей в количестве " _
            & RcdCount & ".</p><p></p>" _
            & rslt
        ' проходим по каждой записи
        rsF.MoveFirst: iii = 1
        Do Until rsF.EOF = True
            strSql = ""
            strSql = "<p><font color=""silver"">"
                strSql = strSql & "Договор: <font color=""DarkSlateBlue"">" & iii & "</font>"
                strSql = strSql & ". <font color=""CadetBlue"">" & rsF!CntrPrtName & "</font>"
                strSql = strSql & ". БУиРГ: <font color=""DarkCyan"">" & rsF!CntrPrtNum & "</font>"
                strSql = strSql & ". № договора: <font color=""CadetBlue""><b>" & rsF!cnName & "</b></font>"
                strSql = strSql & ". CnId: <font color=""DarkViolet"">" & rsF!cn_key & "</font>"
                strSql = strSql & ". Счета-фактура: <font color=""DarkSlateBlue"">" & rsF!ciputCnInv & "</font>"
                strSql = strSql & ". ciKey: <font color=""DarkViolet"">" & rsF!ciKey & "</font>"
                strSql = strSql & ". Счета главной книги: <font color=""DarkGoldenrod""><b>" & rsF!ciputAccount & "</b></font>"
                strSql = strSql & ". AccountKey: <font color=""DarkViolet"">" & rsF!account_key & "</font>"
                strSql = strSql & "</font>.</p>"
            rslt = strSql & rslt
            ' переходим к следующей записи
            rsF.MoveNext: iii = iii + 1
        Loop
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p>В источнике <font color=""Olive"">отсутствуют счета-фактуры с " _
            & "<b>отсутствующими</b> в БД парами *счёт-фактура + счёт главной книги*</font>.</p><p></p>" & rslt
    End If
    
    ' закрываем набор данных
    rsF.Close: Set rsF = Nothing
    
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем счета-фактуры не имеющие пар "счёт-фактура + счёт главной книги" в БД, окончание *******************************************************
'****************************************************************************************************************************************************




'****************************************************************************************************************************************************
' отображаем новые счета-фактуры для существующих договоров либо добавляем их в БД. 30.11.2021 10:16 ************************************************
Private Sub cipuCn_CtptCnOneInvNotLoad(ByRef db As DAO.Database, ByRef rslt As Object, ByVal cipufFlLoad As Boolean)

    Dim strSql As String, rsF As DAO.Recordset, qd As DAO.QueryDef, RcdCount As Long
    Dim rsInv As DAO.Recordset, rsInvNum As DAO.Recordset, rsCnInv As DAO.Recordset
    Dim InvKey As Long, invNumKey As Long, CnInvNumKey As Long

    Const cstrTitle As String _
        = "Процедура *Отображаем новые счета-фактуры для существующих договоров либо добавляем их в БД*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0

    ' отображаем договора, имеющие новые счета-фактуры
    cipuCn_CtptCnOneInvNot db, rslt, RcdCount
    
    ' есть ли необходимость обновлять БД?
    If cipufFlLoad And RcdCount > 0 Then
        ' да, необходимость обновлять БД имеется
        ' добавляем счета-фактуры
'        Set qd = db.CreateQueryDef("", SqlCnCtptExistInvNotLoad()): qd.Execute dbFailOnError
'        Rslt = "<p>Внесено счетов-фактур (строк) в БД: <b><font color=""DarkGreen"">" & qd.RecordsAffected & "</font></b></p>" & Rslt
'        qd.Close: Set qd = Nothing
        
        ' добавил 01.03.2022
        
        ' открываем таблицы для добавления
        Set rsInv = db.OpenRecordset("ags_inv", dbOpenDynaset, dbSeeChanges)
        Set rsInvNum = db.OpenRecordset("ags_invNum", dbOpenDynaset, dbSeeChanges)
        Set rsCnInv = db.OpenRecordset("ags_cnInv", dbOpenDynaset, dbSeeChanges)

        ' проходим по записям счётов-фактур, подлежащих внесению
        eee = 0
        Set rsF = db.OpenRecordset("CnInvPmtUplTblCnInv", dbOpenSnapshot)
        rsF.MoveFirst
        Do Until rsF.EOF = True
            ' добавляем счёт-фактуру
            With rsInv
                .AddNew
                    !iTimeOfEntry = Now()
                .Update
                .Bookmark = .LastModified
                InvKey = !iKey
            End With
            ' добавляем номер счёта-фактуры
            With rsInvNum
                .AddNew
                    !inNum = rsF!ciputciCnInv
                    !inInv = InvKey
                    !inTimeOfEntry = Now()
                .Update
                .Bookmark = .LastModified
                invNumKey = !inKey
            End With
            ' добавляем связь счёта-фактуры и договора
            With rsCnInv
                .AddNew
                    !ciInv = InvKey
                    !ciCn = rsF!ciputciCn_key
                    !ciTimeOfEntry = Now()
                .Update
                .Bookmark = .LastModified
                CnInvNumKey = !ciKey
            End With
            ' переходим к следующей записи
            rsF.MoveNext: eee = eee + 1
        Loop
        ' закрываем набор данных
        rsF.Close: Set rsF = Nothing
        
        ' закрываем наборы данных таблицы для добавления
        rsInv.Close: Set rsInv = Nothing: rsInvNum.Close: Set rsInvNum = Nothing: rsCnInv.Close: Set rsCnInv = Nothing
        rslt = "<p>Внесено счетов-фактур (строк) в БД: <b><font color=""DarkGreen"">" & eee & "</font></b></p>" & rslt
        
        ' добавил 01.03.2022, окончание
        
        
        
        ' ещё раз отображаем договора, имеющие новые счета-фактуры
        cipuCn_CtptCnOneInvNot db, rslt, RcdCount
        Else
        ' нет, необходимость обновлять БД отсутствует
    End If
    
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем новые счета-фактуры для существующих договоров либо добавляем их в БД, окончание *******************************************************
'****************************************************************************************************************************************************


'****************************************************************************************************************************************************
' отображаем новые счета-фактуры для существующих договоров 30.11.2021 10:21 ************************************************************************
Private Sub cipuCn_CtptCnOneInvNot(ByRef db As DAO.Database, ByRef rslt As Object, ByRef RcdCount As Long)

    Dim strSql As String, rsF As DAO.Recordset, qd As DAO.QueryDef

    Const cstrTitle As String _
        = "Процедура *Отображаем новые счета-фактуры для существующих договоров*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0

    ' очищаем табличку новых счётов-фактур
    strSql = "DELETE * FROM CnInvPmtUplTblCnInv": Set qd = db.CreateQueryDef("", strSql): qd.Execute dbFailOnError
    qd.Close: Set qd = Nothing
    
    ' вновь заполняем табличку счётов-фактур
    db.Execute "cipuCn_CtptCnOneInvNotIns", dbFailOnError: RcdCount = db.RecordsAffected
    
    ' отображаем договора, имеющие новые счета-фактуры
    Set rsF = db.OpenRecordset("cipuCn_CtptCnOneInvNotCn", dbOpenSnapshot)
    ' имеются ли записи договоров?
    If rsF.RecordCount > 0 Then
        rsF.MoveLast
        ' да, записи договоров имеются
        rslt = "<p>В источнике <font color=""CadetBlue"">имеются договора</font>, (" _
            & rsF.RecordCount _
            & ") к которым <font color=""Goldenrod"">имеются счета-фактуры отсутствующие в БД</font> (" _
            & RcdCount & ").</p><p></p>" _
            & rslt
        ' проходим по каждой записи
        rsF.MoveFirst: iii = 1
        Do Until rsF.EOF = True
            strSql = ""
            strSql = "<p><font color=""silver"">"
                strSql = strSql & "<font color=""DarkSlateBlue"">" & iii & "</font>"
                strSql = strSql & ". <font color=""CadetBlue"">" & rsF!ciputciCntrPrtName & "</font>"
                strSql = strSql & ". БУиРГ: <font color=""DarkCyan"">" & rsF!ciputciCntrPrtNum & "</font>"
                strSql = strSql & ". № дг.: <font color=""CadetBlue""><b>" & rsF!ciputciCnName & "</b></font>"
                ' отсутствует ли дата договора?
'                If IsNull(rsF!cidutciCnDate) Then
'                    ' да, дата договора отсутствует
'                    strSQL = strSQL & " , <font color=""DarkGoldenrod"">дата отсутствует</font>"
                    srtM = CnInvConcatPm(db, rsF!ciputciCntrPrtNum, rsF!ciputciCnName)
'                    Else
'                    ' нет, дата договора имеется
'                    strSQL = strSQL & " от <font color=""DarkSlateBlue"">" & rsF!cidutciCnDate & "</font>"
'                    srtM = CnInvConcatPm(db, rsF!cidutciCntrPrtNum, rsF!cidutciCnName, rsF!cidutciCnDate)
'                End If
                strSql = strSql & ". CnId: <font color=""DarkViolet"">" & rsF!ciputciCn_key & "</font>"
                strSql = strSql & ". Всего: <b><font color=""DarkGoldenrod"">" & rsF!ciputciCnInvCount & "</font></b>"
                strSql = strSql & ". Счета-фактуры: <font color=""DarkGray"">" & srtM & "</font>"
                strSql = strSql & "</font>.</p>"
            rslt = strSql & rslt
            ' переходим к следующей записи
            rsF.MoveNext: iii = iii + 1
        Loop
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p>В источнике <font color=""Olive""><b>отсутствуют договора, имеющие счета-фактуры отстутствующие в БД</b></font>.</p><p></p>" & rslt
    End If

    ' закрываем набор данных
    rsF.Close: Set rsF = Nothing

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем новые счета-фактуры для существующих договоров, окончание ******************************************************************************
'****************************************************************************************************************************************************



' отображаем отсутствующие договоры либо добавляем их 29.11.2021 09:53 ******************************************************************************
Private Sub cipuCn_CtptCnNotLoad(ByRef db As DAO.Database, ByRef rslt As Object, ByVal cipufFlLoad As Boolean)
    
    'Dim strSQL As String, rsF As DAO.Recordset, iii As long
    
    Dim strSql As String, rsF As DAO.Recordset, qd As DAO.QueryDef, RcdCount As Long
    Dim rsCnAdd As DAO.Recordset, rsCnNum_Add As DAO.Recordset, rsCnS_Add As DAO.Recordset, rsCnS_OrgAdd As DAO.Recordset
    Dim rsCnS_OrgSmplAdd As DAO.Recordset
    Dim rsAddId As Long
    Dim markInt As Long, noteStr As String

    
    Const cstrTitle As String _
        = "Процедура *Отображаем отсутствующие договоры (по выгрузке платежей) либо добавляем их"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    markInt = CLng(strMark(Now()))
    noteStr = "Добавлено " & Now()

    Set rsF = db.OpenRecordset(SqlCipuCn_CtptCnNot(), dbOpenSnapshot)
    ' имеются ли записи отсутствующих договоров?
    If rsF.RecordCount > 0 Then
        ' да, записи отсутствующих договоров имеются
        rslt = "<p><font color=""Silver"">В источнике <font color=""DarkGoldenrod""><b>имеются договора, не обнаруженные по номеру и исполнителю</b></font></font></p><p></p>" _
            & rslt
            
        ' при необходимости обновления БД открываем таблицы для добавления
        If cipufFlLoad Then
            Set rsCnAdd = db.OpenRecordset("ags_cn", dbOpenDynaset, dbFailOnError + dbSeeChanges)
            Set rsCnNum_Add = db.OpenRecordset("ags_cnNum", dbOpenDynaset, dbFailOnError + dbSeeChanges)
            Set rsCnS_Add = db.OpenRecordset("ags_cn_s", dbOpenDynaset, dbFailOnError + dbSeeChanges)
            Set rsCnS_OrgSmplAdd = db.OpenRecordset("ags_cn_s_org_smpl", dbOpenDynaset, dbFailOnError + dbSeeChanges)
            Set rsCnS_OrgAdd = db.OpenRecordset("ags_cn_s_org", dbOpenDynaset, dbFailOnError + dbSeeChanges)
        End If
        
        ' проходим по каждой записи
        rsF.MoveFirst: iii = 1
        Do Until rsF.EOF = True
            strSql = ""
            strSql = "<p><font color=""silver"">"
                strSql = strSql & "Новый: <font color=""DarkSlateBlue"">" & iii & "</font>"
                strSql = strSql & ". <font color=""CadetBlue"">" & rsF!CntrPrtNum & "</font>"
                strSql = strSql & ". <font color=""CadetBlue"">" & rsF!CntrPrtName & "</font>"
                strSql = strSql & ". № договора: <font color=""DarkCyan"">" & rsF!cnName & "</font>"
                ' встречаются ли договора со схожим номером в БД?
                If rsF!countCn > 0 Then
                    ' да, договора со схожим номером в БД уже встречаются
                    strSql = strSql & ". Схожий номер договора уже встречается в БД <font color=""Salmon""><b>" & rsF!countCn & "</b></font> раз(а)"
                    Else
                    ' нет, договора со схожим номером в БД отсутствуют
                    ' имеется ли необходимость в обновлении БД?
                    If cipufFlLoad Then
                        ' да, необходимость в обновлении БД имеется
                        ' добавляем собственно договор
                        
                        With rsCnAdd
                            .AddNew
                                !cnTimeOfEntry = Now()
                                !cn_note = noteStr
                                !cnMark = markInt
                            .Update
                            .Bookmark = .LastModified
                            rsAddId = !cn_key
                        End With
                        
'                        With rsCnAdd
'                            .AddNew
'                                !cn_number = rsF!CnName
'                                !cn_note = noteStr
'                                !cnMark = markInt
'                            .Update
'                            .Bookmark = .LastModified
'                            rsAddId = !cn_key
'                        End With
                        strSql = strSql & ". <font color=""DarkGreen"">Добавлено</font>. CnId: <font color=""CadetBlue"">" & rsAddId & "</font>"
                        
                        ' добавляем номер договора
                        With rsCnNum_Add
                            .AddNew
                                !cnnNum = rsF!cnName
                                !cnnCn = rsAddId
                                !cnnType = 1
                                !cnnNote = noteStr
                                !cnnTimeOfEntry = Now()
                            .Update
                            .Bookmark = .LastModified
                            rsAddIdNum = !cnnKey
                        End With
                        strSql = strSql & ". <font color=""DarkGreen"">Доб. №</font>. cnnCn: <font color=""CadetBlue"">" & rsAddIdNum & "</font>"
                        
                        ' добавляем сторону договора
                        With rsCnS_Add
                            .AddNew
                                !cn_key = rsAddId
                                !cn_s_type = 2
                            .Update
                            .Bookmark = .LastModified
                            rsAddId = !cn_s_key
                        End With
                        strSql = strSql & ". CnS_Id: <font color=""Teal"">" & rsAddId & "</font>"
                        
                        ' добавляем сторону договора - организацию простую
                        With rsCnS_OrgSmplAdd
                            .AddNew
                                !csosCn_s = rsAddId
                                !csosOrgId = rsF!org_id_key
                                !csosTimeOfEntry = Now()
                            .Update
                            .Bookmark = .LastModified
                            rsAddId = !csosKey
                        End With
                        strSql = strSql & ". CnS_OrgIdSmpl: <font color=""Teal"">" & rsAddId & "</font>"
                        
                        
                        ' добавляем сторону договора - организацию
'                        With rsCnS_OrgAdd
'                            .AddNew
'                                !cn_s_key = rsAddId
'                                !org_id = rsF!org_id_key
'                            .Update
'                            .Bookmark = .LastModified
'                            rsAddId = !cn_s_org_key
'                        End With
'                        strSql = strSql & ". CnS_OrgId: <font color=""Teal"">" & rsAddId & "</font>"
                        Else
                        ' нет, необходимость в обновлении БД отсутствует
                    End If
                End If
                strSql = strSql & "</font>.</p>"
            rslt = strSql & rslt
            ' переходим к следующей записи
            rsF.MoveNext: iii = iii + 1
        Loop
        
        ' при необходимости обновления БД закрываем таблицы для добавления
        If cipufFlLoad Then
            rsCnAdd.Close:          Set rsCnAdd = Nothing
            rsCnNum_Add.Close:      Set rsCnNum_Add = Nothing
            rsCnS_Add.Close:        Set rsCnS_Add = Nothing
            rsCnS_OrgSmplAdd.Close: Set rsCnS_OrgSmplAdd = Nothing
            rsCnS_OrgAdd.Close:     Set rsCnS_OrgAdd = Nothing
        End If
        
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p>В источнике <font color=""Goldenrod"">новые договора отсутствуют</font> (не обнаруженные по номеру, дате и исполнителю)</p><p></p>" & rslt
    End If
    
    ' закрываем набор данных листов загрузки
    rsF.Close: Set rsF = Nothing
    
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем отсутствующие договоры либо добавляем их, окончание ************************************************************************************

' отображаем пары договор+исполнитель встречающиеся в БД более одного раза 29.11.2021 12:37 *********************************************************
Private Sub cipuCn_CtptCnTwo(ByRef db As DAO.Database, ByRef rslt As Object)
    
    Dim strSql As String, rsF As DAO.Recordset, iii As Long
    
    Const cstrTitle As String _
        = "Процедура *Отображаем пары договор+исполнитель встречающиеся в БД более одного раза (по выгрузке платежей)"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    strSql = ""
    strSql = strSql & "SELECT * FROM cipuCn_CtptCnTwo ORDER BY CntrPrtNum"

    Set rsF = db.OpenRecordset(strSql, dbOpenSnapshot)
    ' имеются ли записи отсутствующих контрагентов?
    If rsF.RecordCount > 0 Then
        ' да, записи отсутствующих контрагентов имеются
        rslt = "<p>В источнике <font color=""DarkGoldenrod""><b>имеются пары договор+исполнитель встречающиеся в БД более одного раза.</b></p><p></p>" _
            & rslt
        ' проходим по каждой записи
        rsF.MoveFirst: iii = 1
        Do Until rsF.EOF = True
            strSql = ""
            strSql = "<p><font color=""silver"">"
                strSql = strSql & "Договор: <font color=""DarkSlateBlue"">" & iii & "</font>"
                strSql = strSql & ". <font color=""CadetBlue"">" & rsF!CntrPrtNum & "</font>"
                strSql = strSql & ". <font color=""CadetBlue"">" & rsF!CntrPrtName & "</font>"
                strSql = strSql & ". № договора: <font color=""DarkCyan"">" & rsF!cnName & "</font>"
            rslt = strSql & rslt
            ' переходим к следующей записи
            rsF.MoveNext: iii = iii + 1
        Loop
        Else
        ' нет, записи отсутствующих контрагентов отсутствуют
        rslt = "<p>В источнике <font color=""Olive""><b>пары договор+исполнитель встречающиеся в БД более одного раза отсутствуют</font></b>.</p><p></p>" & rslt
    End If
    
    ' закрываем набор данных листов загрузки
    rsF.Close: Set rsF = Nothing

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем пары договор+исполнитель встречающиеся в БД более одного раза, окончание ***************************************************************

' отображаем отсутствующих контрагентов 29.11.2021 09:43 ********************************************************************************************
Private Sub cipuCtpt_All_OIdNot(ByRef db As DAO.Database, ByRef rslt As Object)
    
    Dim strSql As String, rsF As DAO.Recordset, iii As Long
    
    Const cstrTitle As String _
        = "Процедура *Отображаем отсутствующих контрагентов по выгрузке платежей"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    strSql = ""
    strSql = strSql & "SELECT CntrPrtNum, CntrPrtName, org_id_key FROM cipuCtpt_All_OIdNot ORDER BY CntrPrtNum"
            
    Set rsF = db.OpenRecordset(strSql, dbOpenSnapshot)
    ' имеются ли записи отсутствующих контрагентов?
    If rsF.RecordCount > 0 Then
        ' да, записи отсутствующих контрагентов имеются
        rslt = "<p>В источнике <font color=""CadetBlue"">имеются новые организации</font>, не обнаруженные по коду БУиРГ.</p><p></p>" _
            & rslt
        ' проходим по каждой записи
        rsF.MoveFirst: iii = 1
        Do Until rsF.EOF = True
            strSql = ""
            strSql = "<p><font color=""silver"">"
                strSql = strSql & "Новая: <font color=""DarkSlateBlue"">" & iii & "</font>"
                strSql = strSql & ". <font color=""CadetBlue"">" & rsF!CntrPrtName & "</font>"
                strSql = strSql & ". БУиРГ: <font color=""DarkCyan"">" & rsF!CntrPrtNum & "</font>"
            rslt = strSql & rslt
            ' переходим к следующей записи
            rsF.MoveNext: iii = iii + 1
        Loop
        Else
        ' нет, записи отсутствующих контрагентов отсутствуют
        rslt = "<p>В источнике <font color=""Olive""><b>новые организации отсутствуют</font></b>.</p><p></p>" & rslt
    End If
    
    ' закрываем набор данных листов загрузки
    rsF.Close: Set rsF = Nothing

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем отсутствующих контрагентов, окончание **************************************************************************************************

'****************************************************************************************************************************************************
' рассматриваем лист отдельного счёта из выгрузки платежей 24.11.2021 15:34 *************************************************************************
Private Sub SheetTest(ByRef db As DAO.Database, ByRef xlW As Excel.Workbook, ByVal WorkSheetName As String, _
    ByVal UnloadKey As Long, ByRef rslt As Object)

    Dim xlS As Excel.Worksheet
    Dim c As Range, loadRange As Range, iR As Range, strF As String, strRow As String
    Dim rsTblPm As DAO.Recordset, qd As QueryDef
    Dim iii As Long

    Const cstrTitle As String _
        = "Процедура *Рассматриваем отдельный лист выгрузки платежей*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' имеется ли требуемый лист? ====================================================================================================================
    If WorksheetIsExist(xlW, WorkSheetName) Then
        ' да, требуемый лист имеется
        ' открываем существующий лист
        Set xlS = xlW.Worksheets(WorkSheetName)
        
        rslt = "<P> <font color=""silver"">Лист <font color=""Teal"">" & WorkSheetName & " <b>обнаружен</b></font> в книге</font></P>" & rslt
        
        ' снимаем фильтры листа, если есть
        If (xlS.AutoFilterMode And xlS.FilterMode) Or xlS.FilterMode Then
            xlS.ShowAllData
        End If
        
        ' отыскиваем ячейку "№ докум."
        Set c = xlS.UsedRange.Find(what:="№ докум.", LookAt:=xlWhole)
        
        ' итог поисков ячейки "№ докум."
        If Not c Is Nothing Then
            ' ячейка "№ докум." найдена
            rslt = "<P> <font color=""silver"">Найдена ячейка *<b>№ докум.</b>* - " & c.Column & ", строка - " & c.Row & "." _
                & " Содержание: <font color=""RoyalBlue"">" & c & "</font>.</font></P>" & rslt
                
                ' определяем диапазон листа выгрузки в виде колонки для поиска *№ докум.*
                Set loadRange = xlS.Range _
                    ( _
                        xlS.Cells(c.Row + 1, c.Column), _
                        xlS.Cells( _
                            xlS.Cells.SpecialCells(xlCellTypeLastCell).Row, _
                            c.Column _
                            ) _
                    )
                    
                ' проходим по колонке для поиска *№ докум.* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                ' имется ли диапазон листа выгрузки в виде колонки для поиска *№ докум.*?
                If Not loadRange Is Nothing Then
                    ' да, диапазон листа выгрузки в виде колонки для поиска *№ докум.* имеется
                    With loadRange
                        ' количество ячеек в диапазоне больше одной?
                        If .count > 1 Then
                            ' да, количество ячеек в диапазоне больше одной
                            iii = 0: jjj = 0: strF = ""
                            
                            ' очищаем таблицу найденных платежей
                            strSql = "DELETE * FROM CnInvPmtUplTbl": Set qd = db.CreateQueryDef("", strSql): qd.Execute dbFailOnError
                            qd.Close: Set qd = Nothing
                    
                            ' открываем таблицу найденных платежей для добавления
                            Set rsTblPm = db.OpenRecordset("CnInvPmtUplTbl", dbOpenDynaset)

                            ' проходим по каждой ячейке диапазона
                            For Each iR In loadRange.Cells

                                ' имеется ли задолженнось в текущей ячейке?
                                If (IsEmpty(iR) = False And Not iR = "") Then
                                    ' да, задолженнось в текущей ячейке имеется
                                    iii = iii + 1: jjj = jjj + 1
                                    
                                    strRow = ""
                                    strRow = "<P> <font color=""silver"">" & iii & ". *№ докум.* <font color=""Teal"">" & iR.value _
                                        & " <b>обнаружен</b></font> в книге</font>"
                                    
                                    PaymentUnloadTest iR, UnloadKey, iii, rsTblPm, strRow
                                    
                                    strF = strRow & strF
                                    
                                    ' отображаем пакетами
                                    If jjj = 250 Then
                                        rslt = strF & rslt: jjj = 0: strF = ""
                                    End If
                                    
                                    ' после завершения разработки это уберем
'                                    If iii > 1000 Then
'                                        Exit For
'                                    End If
                                    
                                    Else
                                    ' нет, задолженнось в текущей ячейке отсутствует
                                End If

                            Next
                            ' отображаем хвостик, оставшийся от пакетов
                            rslt = strF & rslt
                            
                            ' закрываем таблицу найденных строек для добавления
                            rsTblPm.Close: Set rsTblPm = Nothing
                            
                            Else
                            ' нет, количество ячеек в диапазоне не больше одной
                        End If ' здесь проверка на количество ячеек в диапазоне
                    End With
                    Else
                    ' нет, диапазон листа выгрузки в виде колонки для поиска *№ докум.* отсутствует
                    rslt = "<P>  <font color=""silver"">Диапазон</font> *№ докум.* <font color=""red"">не найден</font>.</P>" _
                        & rslt
                End If ' проходим по колонке для поиска *№ докум.*, окончание ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

            Else
            ' ячейка "*№ докум.*" не найдена
            rslt = "<P> <font color=""silver"">Ячейка <b>*№ докум.*</b> <font color=""red"">не найдена</font></font></P>" _
                & rslt
        End If

        ' освобождаем переменную листа
        Set xlS = Nothing
        Else
        ' нет, требуемый лист отсутствует
        rslt = "<P> Лист <font color=""Salmon"">" & WorkSheetName & " <b>не обнаружен</b>" & "</font> в книге*</P>" & rslt
    End If ' имеется ли требуемый лист, окончание ===================================================================================================

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' рассматриваем лист отдельного счёта из выгрузки платежей, окончание *******************************************************************************
'****************************************************************************************************************************************************


' рассматриваем строку отдельной задолженности из выгрузки платежей
Private Sub PaymentUnloadTest(ByRef cnInvRange As Range, _
    ByVal UnloadKey As Long, ByVal cidutSheetNum As Long, _
    ByRef rsFindCst As DAO.Recordset, ByRef strF As String)

    Const cstrTitle As String _
        = "Процедура *Рассматриваем строку отдельной задолженности из выгрузки платежей"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    With rsFindCst
        .AddNew
'            InsertFieldValue !ciputBE, cnInvRange.offset(0, -20), strF ' -5 -20
'            InsertFieldValue !ciputAccount, cnInvRange.offset(0, -19), strF ' -4 -19
'            InsertFieldValue !ciputCntrPrtNum, cnInvRange.offset(0, -18), strF ' -3 -18
'            InsertFieldValue !ciputCntrPrtName, cnInvRange.offset(0, -17), strF ' -2 -17
'            InsertFieldValue !ciputCAC, cnInvRange.offset(0, -16), strF ' 13 -16
'            InsertFieldValue !ciputAgentNum, cnInvRange.offset(0, -15), strF ' 33 -15
'            InsertFieldValue !ciputAgentName, cnInvRange.offset(0, -14), strF ' 34 -14
'            InsertFieldValue !ciputCnName, cnInvRange.offset(0, -13), strF ' -1 -13
'            InsertFieldValue !ciputLink, cnInvRange.offset(0, -12), strF ' 4 -12
'            InsertFieldValue !ciputCnInv, cnInvRange.offset(0, -11), strF ' 5 -11
'            InsertFieldValue !ciputEntryDate, cnInvRange.offset(0, 1), strF ' 1 -10
'            InsertFieldValue !ciputDocDate, cnInvRange.offset(0, 2), strF ' -9
'
'            InsertFieldValue !ciputDueDate, cnInvRange.offset(0, 48), strF ' -8 Срок оплаты
'            InsertFieldValue !ciputDbtBlns, cnInvRange.offset(0, 24), strF ' -7
'            InsertFieldValue !ciputDbtBlnsOverd, cnInvRange.offset(0, 44), strF ' -6
'            InsertFieldValue !ciputDbtBlnsOverdNot, cnInvRange.offset(0, 46), strF ' -5
'            InsertFieldValue !ciputCdtBlns, cnInvRange.offset(0, 25), strF ' -4
'            InsertFieldValue !ciputCdtBlnsOverd, cnInvRange.offset(0, 45), strF ' -3
'            InsertFieldValue !ciputCdtBlnsOverdNot, cnInvRange.offset(0, 47), strF ' -2
'            InsertFieldValue !ciputBlns, cnInvRange.offset(0, 26), strF ' -1
'            InsertFieldValue !ciputCnInvDocCode, cnInvRange, strF '
'            InsertFieldValue !ciputAlligmentDate, cnInvRange.offset(0, 3), strF ' 1
'            InsertFieldValue !ciputBaseDate, cnInvRange.offset(0, 43), strF ' 2
'            InsertFieldValue !ciputCnInvDocSum, cnInvRange.offset(0, 8), strF ' 3
'            InsertFieldValue !ciputStornoReason, cnInvRange.offset(0, 41), strF ' 4
'            InsertFieldValue !ciputStornoDocCode, cnInvRange.offset(0, 42), strF ' 5
            
            InsertFieldValue !ciputBE, cnInvRange.Offset(0, -20), strF ' -5 -20
            InsertFieldValue !ciputAccount, cnInvRange.Offset(0, -19), strF ' -4 -19
            InsertFieldValue !ciputCntrPrtNum, cnInvRange.Offset(0, -18), strF ' -3 -18
            InsertFieldValue !ciputCntrPrtName, cnInvRange.Offset(0, -17), strF ' -2 -17
            InsertFieldValue !ciputCAC, cnInvRange.Offset(0, -16), strF ' 13 -16
            InsertFieldValue !ciputAgentNum, cnInvRange.Offset(0, -15), strF ' 33 -15
            InsertFieldValue !ciputAgentName, cnInvRange.Offset(0, -14), strF ' 34 -14
            InsertFieldValue !ciputCnName, cnInvRange.Offset(0, -13), strF ' -1 -13
            InsertFieldValue !ciputLink, cnInvRange.Offset(0, -12), strF ' 4 -12
            InsertFieldValue !ciputCnInv, cnInvRange.Offset(0, -11), strF ' 5 -11
            InsertFieldValue !ciputEntryDate, cnInvRange.Offset(0, -10), strF ' 1 -10
            InsertFieldValue !ciputDocDate, cnInvRange.Offset(0, -9), strF ' -9
            
            InsertFieldValue !ciputDueDate, cnInvRange.Offset(0, -8), strF ' -8 Срок оплаты
            InsertFieldValue !ciputDbtBlns, cnInvRange.Offset(0, -7), strF ' -7
            InsertFieldValue !ciputDbtBlnsOverd, cnInvRange.Offset(0, -6), strF ' -6
            InsertFieldValue !ciputDbtBlnsOverdNot, cnInvRange.Offset(0, -5), strF ' -5
            InsertFieldValue !ciputCdtBlns, cnInvRange.Offset(0, -4), strF ' -4
            InsertFieldValue !ciputCdtBlnsOverd, cnInvRange.Offset(0, -3), strF ' -3
            InsertFieldValue !ciputCdtBlnsOverdNot, cnInvRange.Offset(0, -2), strF ' -2
            InsertFieldValue !ciputBlns, cnInvRange.Offset(0, -1), strF ' -1
            InsertFieldValue !ciputCnInvDocCode, cnInvRange, strF '
            InsertFieldValue !ciputAlligmentDate, cnInvRange.Offset(0, 1), strF ' 1
            InsertFieldValue !ciputBaseDate, cnInvRange.Offset(0, 2), strF ' 2
            InsertFieldValue !ciputCnInvDocSum, cnInvRange.Offset(0, 3), strF ' 3
            InsertFieldValue !ciputStornoReason, cnInvRange.Offset(0, 4), strF ' 4
            InsertFieldValue !ciputStornoDocCode, cnInvRange.Offset(0, 5), strF ' 5
           
            !ciputSheetNum = cidutSheetNum
            !ciputUnloadKey = UnloadKey
        .Update
        .Bookmark = .LastModified
        'RaAuKey = !ralpraKey
        strF = strF & ". <font color=""DarkGreen"">Добавлено.</font></P>"
        'strFFF = strFFF & ", ид. пункта ИП по УП: <font color=""Gray"">" & rsIuplpEdit!iuplpKey & "</font>"
    End With

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

' вносим значение в поле
Private Sub InsertFieldValue(ByRef FieldIns As DAO.Field, ByRef CellOut As Range, ByRef strF As String)

    Dim ddLimTtl As Variant
    
    Const cstrTitle As String _
        = "Процедура *Вносим значение в поле*"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    If IsNull(CellOut) = False And IsEmpty(CellOut) = False _
        And Not CellOut = "" Then
        'If Not FieldOut = 0 Then
            'ddLimTtl = CDec(WorksheetFunction.Round(FieldOut, 8))
            'FieldIns = Trim(CellOut)
        'End If
        ' поле является полем даты?
        If FieldIns.type = 8 Then
            ' да, поле является полем даты
            ' значение ячейки является датой?
            If IsDate(CellOut) Then
                ' да, значение ячейки является датой
                FieldIns = Trim(CellOut)
                Else
                ' нет, значение ячейки не является датой
                strF = strF & ". <font color=""Goldenrod"">Ошибка внесения <font color=""Salmon""><b>даты</b></font>. В поле: <font color=""Olive"">" _
                    & FieldIns.name & "</font> вносится " & CellOut.value & "</font>"
            End If
            Else
            ' да, поле не является полем даты
            FieldIns = Trim(CellOut)
        End If
    End If
                            
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf _
        & "Номер ошибки: " & Err.Number & ". Поле: " & FieldIns.name & ". Тип поля: " & FieldIns.type _
        & ". В ячеёке: " & CellOut.value & "." & vbCrLf _
        & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
                            
End Sub


