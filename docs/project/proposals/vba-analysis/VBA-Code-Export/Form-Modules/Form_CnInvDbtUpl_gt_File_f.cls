VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_CnInvDbtUpl>File_f"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

'****************************************************************************************************************************************************
' просматриваем или загружаем данные по дебиторской задолженности из выгрузки бухгалтерии Ф644 ******************************************************
Private Sub btnCidufLoad_Click()

    Dim dStart As Date, dFinish As Date
    Dim db As DAO.Database, rsF As DAO.Recordset, strSql As String, strFFF As String, qd As DAO.QueryDef, rsFindCst As DAO.Recordset
    Dim xlA As Excel.Application, xlW As Excel.Workbook, xlS As Excel.Worksheet
    Dim iii As Integer ' для нумераций
    Dim srtM As String
    Dim FindDbtNum As Integer
    Dim dbA As dbAccess ' для очистки
    Dim booDbA As Boolean ' для очистки

    Const cstrTitle As String _
        = "Процедура *Просматриваем или загружаем данные по дебиторской задолженности из выгрузки бухгалтерии Ф644"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

' имеется ли идентификатор выгрузки?
If IsNull(Me!cidufUpload) = False Then
    ' да, идентификатор выгрузки имеется
    Me!cidufLoadingProgress = "": dStart = DateTime.Now
    
    Me!cidufLoadingProgress = "<P>Начало работы с выгрузкой *<B><font color=""DarkGoldenrod"">" & Me!cidufPath & "</font></B>*." _
    & " <B>" & dStart & "</B> - Время начала работы.</P>"
    
    Set db = CurrentDb 'открываем переменную базы данных --------------------------------------------------------------------------------------------
    
    ' нужно ли обновлять промежуточную таблицу по данным источника?
    If Me!cidufFlTbl Then
        ' да, обновлять промежуточную таблицу по данным источника необходимо
        ' пройдём по листам
        strSql = "SELECT * FROM CnInvDbtUplFileSh WHERE cidufsFile = " & Me!cidufKey & " order by cidufsSheet;"
        ' открываем набор данных листов загрузки
        Set rsF = db.OpenRecordset(strSql, dbOpenSnapshot)
        ' имеются ли записи листов загрузки?
        If rsF.RecordCount > 0 Then
            ' да, записи листов загрузки имеются
            ' открываем приложение
            Set xlA = CreateObject("Excel.Application")
            
            Me!cidufLoadingProgress = "<P>" & DateTime.Now & " - *<b><font color=""green"">" & "Приложение Excel открыто" _
                & "</font>*</b></P>" & Me!cidufLoadingProgress
                
            ' существует ли файл в файловой системе?
            Set fsof = CreateObject("Scripting.FileSystemObject")
            If (fsof.FileExists(Me!cidufPath)) Then
                'да, файл существует
                Me!cidufLoadingProgress = "<P>" & DateTime.Now & " - Файл с именем *" & Me!cidufPath _
                    & "* в файловой системе обнаружен</P>" & Me!cidufLoadingProgress
                    
                    'открываем файл
                    Set xlW = xlA.Workbooks.Open(filename:=Me!cidufPath, ReadOnly:=True, UpdateLinks:=0)
                        
                    Me!cidufLoadingProgress = "<P>" & DateTime.Now & " - Файл с именем *<font color=""green"">" & Me!cidufPath _
                    & "</font>* в приложении открыт</P>" & Me!cidufLoadingProgress
            
                    ' очищаем таблицу найденных задолженностей
                    strSql = "DELETE * FROM CnInvDbtUplTbl": Set qd = db.CreateQueryDef("", strSql): qd.Execute dbFailOnError
                    qd.Close: Set qd = Nothing
                    
                    ' открываем таблицу найденных задолженностей для добавления
                    Set rsFindCst = db.OpenRecordset("CnInvDbtUplTbl", dbOpenDynaset)
                    
                    ' устанавливаем счётчик найденных задолженностей на 0
                    FindDbtNum = 0
            
                    ' проходим по каждой записи листа
                    rsF.MoveFirst
                    Do Until rsF.EOF = True
                        Me!cidufLoadingProgress = "<p><font color=""silver"">Рассматриваем лист <font color=""Brown""><b>" & rsF!cidufsSheet _
                            & "</b></font>.</font></p>" & Me!cidufLoadingProgress
                            
                        ' нужно ли проверять текущий лист?
                        If rsF!cidufsTest Then
                            ' да, текущий лист проверять нужно
                            ' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                            ' вызываем процедуру *рассматриваем лист отдельного счёта из выгрузки бухгалтерии Ф644*
                            AccountSheetTest db, xlW, rsF!cidufsSheet, Me!cidufUpload, rsF!cidufsAccount, rsF!cidufsKey, _
                                rsFindCst, Me!cidufLoadingProgress, FindDbtNum
                            ' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                            Else
                            ' нет, текущий лист проверять не нужно
                            Me!cidufLoadingProgress = "<p><font color=""silver"">Лист <font color=""Orchid"">" & rsF!cidufsSheet _
                                & "</font> <font color=""Goldenrod""><b>не рассматривается</b></font> по вашему выбору.</font></p>" _
                                & Me!cidufLoadingProgress
                        End If
            
                        ' переходим к следующему листу
                        rsF.MoveNext
                    Loop
                    
                    ' закрываем таблицу найденных строек для добавления
                    rsFindCst.Close: Set rsFindCst = Nothing
            
                    'закрываем файл
                    xlW.Close SaveChanges:=False: Set xlW = Nothing
                    
                    Me!cidufLoadingProgress = "<P>" & DateTime.Now & " - Файл с именем *<font color=""blue"">" & Me!cidufPath _
                    & "</font>* в приложении закрыт</P>" & Me!cidufLoadingProgress
                                
                Else
                'нет, файл не существует
                Me!cidufLoadingProgress = "<P>Файл с именем *<B><font color=""red"">" & Me!cidufPath _
                    & "</font></B>* в файловой системе не обнаружен</P>" & Me!cidufLoadingProgress
            End If
            
            
            'закрываем приложение без сохранения книг
            xlA.Quit: Set xlA = Nothing
            
            Me!cidufLoadingProgress = "<P>" & DateTime.Now & " - *<B><font color=""blue"">" & "Приложение Excel закрыто" & "</font></B>*</P>" _
            & Me!cidufLoadingProgress
            
            Else
            ' нет, записи листов загрузки отсутствуют
            Me!cidufLoadingProgress = "<p>В БД <font color=""Salmon"">записи файлов загрузки отсутствуют</font></p>" & Me!cidufLoadingProgress
        End If
        
        ' закрываем набор данных листов загрузки
        rsF.Close: Set rsF = Nothing
        Else
        ' нет, обновлять промежуточную таблицу по данным источника не нужно
        Me!cidufLoadingProgress = "<p>Обновлять промежуточную таблицу по данным источника <font color=""DarkBlue"">не нужно</font></p>" & Me!cidufLoadingProgress
    End If
    
    ' отображаем отсутствующих контрагентов =========================================================================================================
    strSql = ""
    strSql = strSql & "SELECT * "
    strSql = strSql & "FROM "
    strSql = strSql & " ( "
    strSql = strSql & "     SELECT z.cidutCntrPrtNum, z.cidutCntrPrtName, z.cidutCntrPrtITN, x.org_id_value_l, x.org, x.org_id_key "
    strSql = strSql & "     FROM "
    strSql = strSql & "         ( "
    strSql = strSql & "             SELECT t.cidutCntrPrtNum, t.cidutCntrPrtName, t.cidutCntrPrtITN "
    strSql = strSql & "             FROM CnInvDbtUplTbl as t "
    strSql = strSql & "             GROUP BY t.cidutCntrPrtNum, t.cidutCntrPrtName, t.cidutCntrPrtITN "
    strSql = strSql & "         ) AS z "
    strSql = strSql & "         Left Join "
    strSql = strSql & "             ( "
    strSql = strSql & "                 SELECT i.org_id_value_l, i.org, i.org_id_type, i.org_id_key "
    strSql = strSql & "                 FROM ags_org_id AS i "
    strSql = strSql & "                 WHERE (((i.org_id_type) = 1)) "
    strSql = strSql & "             ) AS x ON z.cidutCntrPrtNum = x.org_id_value_l "
    strSql = strSql & "     WHERE (((x.org_id_key) Is Null)) "
    strSql = strSql & " ) AS y "
    strSql = strSql & " LEFT JOIN "
    strSql = strSql & "     ("
    strSql = strSql & "         SELECT i.org_id_value_t, i.org, i.org_id_type, i.org_id_key, o.ogNm "
    strSql = strSql & "         FROM ags_org_id AS i "
    strSql = strSql & "         INNER Join "
    strSql = strSql & "             ags_og as o ON i.org = o.ogKey"
    strSql = strSql & "         WHERE (((i.org_id_type) = 2)) "
    strSql = strSql & "     ) AS w ON y.cidutCntrPrtITN = w.org_id_value_t "
    strSql = strSql & "ORDER BY y.cidutCntrPrtNum;"
        
    ' открываем набор данных отсутствующих контрагентов
    Set rsF = db.OpenRecordset(strSql, dbOpenSnapshot)
    ' имеются ли записи отсутствующих контрагентов?
    If rsF.RecordCount > 0 Then
        ' да, записи отсутствующих контрагентов имеются
        Me!cidufLoadingProgress = "<p>В источнике <font color=""CadetBlue"">имеются новые организации</font>, не обнаруженные по коду БУиРГ.</p><p></p>" _
            & Me!cidufLoadingProgress
        ' проходим по каждой записи
        rsF.MoveFirst: iii = 1
        Do Until rsF.EOF = True
            strSql = ""
            strSql = "<p><font color=""silver"">"
                strSql = strSql & "Новая: <font color=""DarkSlateBlue"">" & iii & "</font>"
                strSql = strSql & ". <font color=""CadetBlue"">" & rsF!cidutCntrPrtName & "</font>"
                strSql = strSql & ". БУиРГ: <font color=""DarkCyan"">" & rsF!cidutCntrPrtNum & "</font>"
                strSql = strSql & ". ИНН: <font color=""DarkSlateBlue"">" & rsF!cidutCntrPrtITN & "</font>"
            ' но имеется ли уже организация с таким ИНН?
            If IsNull(rsF!ogNm) = False Then
                ' да, организация с таким ИНН имеется
                strSql = strSql & ". <font color=""Salmon"">Уже имеется</font> организация: <font color=""Maroon""><b>" _
                    & rsF!ogNm & "</b></font></font>.</p>"
                Else
                ' нет, организация с таким ИНН отсутствует
                strSql = strSql & "</font>.</p>"
            End If
            Me!cidufLoadingProgress = strSql & Me!cidufLoadingProgress
            ' переходим к следующей записи
            rsF.MoveNext: iii = iii + 1
        Loop
        Else
        ' нет, записи отсутствующих контрагентов отсутствуют
        Me!cidufLoadingProgress = "<p>В источнике <font color=""Olive""><b>новые организации отсутствуют</font></b>.</p><p></p>" & Me!cidufLoadingProgress
    End If
    
    ' закрываем набор данных отсутствующих контрагентов
    rsF.Close: Set rsF = Nothing
    
    ' отображаем отсутствующих контрагентов, окончание ==============================================================================================
    
    ' отображаем отсутствующие в БД договоры с исполнителями либо добавляем их ======================================================================
    CnNotLoad db, Me!cidufLoadingProgress, Me!cidufFlLoad

    ' отображаем договора, имеющиеся в БД, в которых отсутствует обнаруженный в БД исполнитель ======================================================
    CnExistCtptNotLoad db, Me!cidufLoadingProgress, Me!cidufFlLoad

    ' отображаем новые счета-фактуры для существующих договоров =====================================================================================

    ' очищаем таблицу двоящих счётов-фактур
    Set dbA = ClassFactory.dbAccessByDB(db)
        booDbA = dbA.TableRecordsClear("CnInvDbtUplFileInvDouble")
        If booDbA = False Then
            MsgBox ("Не очищена CnInvDbtUplFileInvDouble... Странно...")
        End If
    Set dbA = Nothing

    CnCtptExistInvNotLoad db, Me!cidufLoadingProgress, Me!cidufFlLoad

    ' отображаем счета-фактуры не имеющие *Задолженностей простых* в БД либо добавляем их ===========================================================
    CnCtptInvExistAccSmplNotLoad db, Me!cidufLoadingProgress, Me!cidufFlLoad

    ' проверяем имеющиеся в БД задолженности, которые более чем одна у счёта-фактуры ================================================================
    invDbtDouble db, Me!cidufLoadingProgress, Me!cidufFlLoad

    ' отображаем счета-фактуры не имеющие *Задолженностей* в БД либо добавляем их ===================================================================
    CnCtptInvExistAccNotLoad db, Me!cidufLoadingProgress, Me!cidufFlLoad

    ' отображаем повторяющиеся *Задолженности* (с именами) имеющиеся в источнике ====================================================================
    ciduTblCnCtptInvAccNameCountOneNot db, Me!cidufLoadingProgress, Me!cidufFlLoad

    ' отображаем *Задолженности* имеющие более одной задолженности в выгрузке =======================================================================
'     CnCtptInvAccExistDbl db, Me!cidufLoadingProgress не раскомментировать! 03.02.2023

    ' отображаем *Задолженности* не имеющие задолженности в БД либо добавляем их туда ===============================================================
    CnCtptInvAccExistDbtNotLoad db, Me!cidufLoadingProgress, Me!cidufFlLoad

    ' отображаем пары СФ+СГК имеющие задолженности в БД =============================================================================================
    CnCtptInvAccDbtExist db, Me!cidufLoadingProgress
    
    db.Close 'закрываем переменную базы данных ------------------------------------------------------------------------------------------------------

    dFinish = DateTime.Now: dDateDiff = DateDiff("s", dStart, dFinish)

    Me!cidufLoadingProgress = "<P>В " & dFinish & " - *<B><font color=""blue"">" & "работа с выгрузкой завершена" _
    & "</font></B>*. C " & dStart & " в течении " & dDateDiff \ 60 & " мин. " & dDateDiff - ((dDateDiff \ 60) * 60) & " сек., (всего " _
    & dDateDiff & " сек.).</P>" & Me!cidufLoadingProgress
    
    'Me![ra_a>Ttl_t].Requery
    
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
' просматриваем или загружаем данные по дебиторской задолженности из выгрузки бухгалтерии Ф644, окончание *******************************************
'****************************************************************************************************************************************************


'****************************************************************************************************************************************************
' проверяем имеющиеся в БД задолженности, которые более чем одна у счёта-фактуры. 17.01.2022 16:58 **************************************************
Private Sub invDbtDouble(ByRef db As DAO.Database, ByRef rslt As Object, ByRef RcdCount As Integer)

    Dim strSql As String, rsF As DAO.Recordset, Inv As Inv, rsNumDbtUpl As DAO.Recordset
    Dim CiaNm As CiaNm, Accnt As Accnt, maxDate As Date

    Const cstrTitle As String _
        = "Процедура *Проверяем имеющиеся в БД задолженности, которые более чем одна у счёта-фактуры*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    'strSql = "SELECT cia.* FROM ags_cnInvAccnt AS cia WHERE (((cia.ciaName) Is Not Null));"
    strSql = "invDoubleCia"
    Set rsF = db.OpenRecordset(strSql, dbOpenSnapshot)
    ' имеются ли записи?
    If rsF.RecordCount > 0 Then
        ' да, записи имеются
        rsF.MoveLast
        RcdCount = rsF.RecordCount
        rslt = "<p>В БД <font color=""CadetBlue"">имеются </font>, " _
            & "<font color=""Salmon""> Счёта-фактуры у которые более чем одна *Задолженность*</font>, в количестве " _
            & RcdCount & ". Нужно <font color=""Salmon""><b>проверить</b></font> наличие таких в источнике...</p><p></p>" _
            & rslt
        ' проходим по каждой записи
        rsF.MoveFirst: iii = 1
        Do Until rsF.EOF = True
            ' создаём объект класса *Задолженность*
            Set Inv = ClassFactory.invByKey(rsF!iKey, db)
            strSql = ""
            If Not Inv Is Nothing Then
                strSql = "<p>" & iii & ". <font color=""silver"">"
                    strSql = strSql & "Ключ: <font color=""DarkSlateBlue"">" & Inv.iKey & "</font>"
                ' имеются ли в источнике счёты-фактуры со сходными номерами?
                If Inv.invNumbersInDebtUpl(db, rsNumDbtUpl) Then
                    ' да, в источнике счёты-фактуры со сходными номерами имеются
                    strSql = strSql & ". Совпадения номеров СФ <font color=""DarkOrange""><b>" & _
                    Inv.strInvName & "</b></font> в истонике : <font color=""DarkOrange"">есть</font>, всего: " & rsNumDbtUpl.RecordCount
                    ' проходим по каждой задолженности
                    ' ... 06.02.2023 17:51 завтра отсюда
                    rsNumDbtUpl.MoveFirst: zzz = 1
                    Do Until rsNumDbtUpl.EOF = True
                        ' имеется ли имя задолженности?
                        If IsNull(rsNumDbtUpl!cidutCnInvName) = False Then
                            ' да, имя задолженности имеется
                            strSql = strSql & ".</p><p>  <font color=""Orange"">" & iii & "." & zzz _
                                & ".</font> Имя: <font color=""CadetBlue"">" & rsNumDbtUpl!cidutCnInvName & "</font>"
                            Set CiaNm = ClassFactory.ciaNmByInvAndCiaName(Inv.iKey, rsNumDbtUpl!cidutCnInvName, db)
                            ' имеется ли задолженность?
                            If Not CiaNm Is Nothing Then
                                Set Accnt = ClassFactory.accntByKey(rsNumDbtUpl!cidutAccount, db)
                                strSql = strSql & ". ciaKey: " & CiaNm.ciaKey _
                                    & ", дг(ист): <font color=""DarkOrange"">" _
                                    & rsNumDbtUpl!cidutCnNameNull _
                                    & "</font>, дг(бд): <font color=""CadetBlue"">" _
                                    & CiaNm.ciaParentObj.ciasParentObj.cnInvParentObj.cnParentObj.strCnName _
                                    & "</font>, сгк(ист): <font color=""DarkOrange"">" _
                                    & Accnt.lngAccntNum _
                                    & "</font>, сгк(бд): <font color=""CadetBlue"">" _
                                    & CiaNm.ciaParentObj.ciasParentObj.accntParentObj.lngAccntNum _
                                    & "</font> всего: " _
                                    & rsNumDbtUpl!cidutDebt _
                                    & ", совпало: " _
                                    & CiaNm.SumMatch(rsNumDbtUpl!cidutDebt, maxDate) _
                                    & " раз(а)"
                                    If Not maxDate = CDate("01.01.1900") Then
                                        strSql = strSql & ", поздний раз: " & maxDate
                                    End If
                                Set Accnt = Nothing
                            Else
                                strSql = strSql & ". Имени нет..."
                            End If
                            Set CiaNm = Nothing
                        Else
                            ' нет, имя задолженности отсутствует
                        End If
                        zzz = zzz + 1: rsNumDbtUpl.MoveNext
                    Loop
                Else
                    ' нет, в источнике счёты-фактуры со сходными номерами отсутствуют
                    strSql = strSql & ". Совпадений номеров СФ <font color=""DarkGreen""><b>" & _
                    Inv.strInvName & "</b></font> в истонике : <font color=""DarkGreen"">нет</font>"
                End If
                rsNumDbtUpl.Close: Set rsNumDbtUpl = Nothing
            Else
                strSql = "<p>" & iii & ". <font color=""silver"">"
                    strSql = strSql & "Объект с ключом: <font color=""DarkSlateBlue"">" & rsF!iKey & "</font> отсутствует в БД!"
            End If
            ' удаляем объект класса *Задолженность*
            Set Inv = Nothing
            strSql = strSql & "</font>.</p>"
            rslt = strSql & rslt
            ' переходим к следующей записи
            rsF.MoveNext: iii = iii + 1
        Loop
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p>В источнике <font color=""Goldenrod"">отсутствуют " _
            & "Счёта-фактуры у которые более чем одна *Задолженность*</font>.</p><p></p>" & rslt
    End If
    
    ' закрываем набор данных
    rsF.Close: Set rsF = Nothing

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' проверяем имеющиеся в БД задолженности, которые более чем одна у счёта-фактуры, окончание *********************************************************
'****************************************************************************************************************************************************




'****************************************************************************************************************************************************
' отображаем повторяющиеся *Задолженности* (с именами) имеющиеся в источнике. 17.01.2022 16:58 ******************************************************
Private Sub ciduTblCnCtptInvAccNameCountOneNot(ByRef db As DAO.Database, ByRef rslt As Object, ByRef RcdCount As Integer)

    Dim strSql As String, rsF As DAO.Recordset

    Const cstrTitle As String _
        = "Процедура *Отображаем повторяющиеся *Задолженности* (с именами) имеющиеся в источнике*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0
    
    strSql = "SELECT q.cidutCntrPrtNum, q.cidutCnNameNull, q.cidutCnDateNull, q.cidutCnInvNull, q.cidutCnInvNameNull, q.cidutAccount, q.DbtCount "
    strSql = strSql & "FROM ciduTblCnCtptInvAccNameCount AS q "
    strSql = strSql & "WHERE (((q.DbtCount)<>1));"


    Set rsF = db.OpenRecordset(strSql, dbOpenSnapshot)
    ' имеются ли записи?
    If rsF.RecordCount > 0 Then
        ' да, записи имеются
        rsF.MoveLast
        RcdCount = rsF.RecordCount
        rslt = "<p>В источнике <font color=""CadetBlue"">имеются </font>, " _
            & "<font color=""Salmon"">повторяющиеся</font> *Задолженности* (с именами) в количестве " _
            & RcdCount & ". Их бы <font color=""Salmon""><b>разнести</b></font> по именам задолженностей...</p><p></p>" _
            & rslt
        ' проходим по каждой записи
        rsF.MoveFirst: iii = 1
        Do Until rsF.EOF = True
            strSql = ""
            strSql = "<p><font color=""silver"">"
                strSql = strSql & "Договор: <font color=""DarkSlateBlue"">" & iii & "</font>"
                strSql = strSql & ". БУиРГ: <font color=""DarkCyan"">" & rsF!cidutCntrPrtNum & "</font>"
                strSql = strSql & ". № договора: <font color=""CadetBlue""><b>" & rsF!cidutCnNameNull & "</b></font>"
                ' отсутствует ли дата договора? ciKey
                If IsNull(rsF!cidutCnDateNull) Then
                    ' да, дата договора отсутствует
                    strSql = strSql & " , <font color=""DarkGoldenrod"">дата отсутствует</font>"
                    Else
                    ' нет, дата договора имеется
                    strSql = strSql & " от <font color=""DarkSlateBlue"">" & rsF!cidutCnDateNull & "</font>"
                End If
                strSql = strSql & ". Счета-фактура: <font color=""DarkSlateBlue"">" & rsF!cidutCnInvNull & "</font>"
                strSql = strSql & ". Имя задолженности: <font color=""DarkSlateBlue"">" & rsF!cidutCnInvNameNull & "</font>"
                strSql = strSql & ". AccountKey: <font color=""DarkViolet"">" & rsF!cidutAccount & "</font>"
                strSql = strSql & ". Количество: <font color=""DarkViolet"">" & rsF!DbtCount & "</font>"
                strSql = strSql & "</font>.</p>"
            rslt = strSql & rslt
            ' переходим к следующей записи
            rsF.MoveNext: iii = iii + 1
        Loop
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p>В источнике <font color=""Goldenrod"">отсутствуют " _
            & "повторяющиеся *Задолженности* (с именами)</font>.</p><p></p>" & rslt
    End If
    
    ' закрываем набор данных
    rsF.Close: Set rsF = Nothing
    
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем повторяющиеся *Задолженности* (с именами) имеющиеся в источнике, окончание *************************************************************
'****************************************************************************************************************************************************



'****************************************************************************************************************************************************
' отображаем счета-фактуры не имеющие *Задолженностей простых* в БД либо добавляем их. 13.01.2022 17:43 *********************************************
Private Sub CnCtptInvExistAccSmplNotLoad(ByRef db As DAO.Database, ByRef rslt As Object, ByVal cidufFlLoad As Boolean)

    Dim strSql As String, rsF As DAO.Recordset, qd As DAO.QueryDef, RcdCount As Integer, RcdCount2 As Integer

    Const cstrTitle As String _
        = "Процедура *Отображаем счета-фактуры не имеющие *Задолженностей простых* в БД либо добавляем их*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0

    ' отображаем счета-фактуры не имеющие пар "счёт-фактура + счёт главной книги" в БД
    CnCtptInvExistAccSmplNot db, rslt, RcdCount
    
    ' есть ли необходимость обновлять БД?
    If cidufFlLoad And RcdCount > 0 Then
        ' да, необходимость обновлять БД имеется
        ' добавляем счета-фактуры
        
        db.Execute "ciduCnCtptInvAccSmplNotIns", dbFailOnError: RcdCount2 = db.RecordsAffected
        
        
'        Set qd = db.CreateQueryDef("", SqlCnCtptInvExistAccNotLoad()): qd.Execute dbFailOnError
        rslt = "<p>Внесено пар СФ+СГК (строк) в БД: <b><font color=""DarkGreen"">" & RcdCount2 & "</font></b> Для " _
            & RcdCount & " задолженностей.</p>" & rslt
'        qd.Close: Set qd = Nothing
        
        ' ещё раз отображаем счета-фактуры, не имеющие пар "счёт-фактура + счёт главной книги" в БД
        CnCtptInvExistAccSmplNot db, rslt, RcdCount
        Else
        ' нет, необходимость обновлять БД отсутствует
    End If
    
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем счета-фактуры не имеющие *Задолженностей простых* в БД либо добавляем их, окончание ****************************************************
'****************************************************************************************************************************************************


'****************************************************************************************************************************************************
' отображаем счета-фактуры не имеющие *Задолженностей простых* в БД. 13.31.2022 17:44 ***************************************************************
Private Sub CnCtptInvExistAccSmplNot(ByRef db As DAO.Database, ByRef rslt As Object, ByRef RcdCount As Integer)

    Dim strSql As String, rsF As DAO.Recordset

    Const cstrTitle As String _
        = "Процедура *Отображаем счета-фактуры не имеющие *Задолженностей простых* в БД*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0

    Set rsF = db.OpenRecordset("ciduCnCtptInvAccSmplNot", dbOpenSnapshot)
    ' имеются ли записи?
    If rsF.RecordCount > 0 Then
        ' да, записи имеются
        rsF.MoveLast
        RcdCount = rsF.RecordCount
        rslt = "<p>В источнике <font color=""CadetBlue"">имеются счета-фактуры</font>, " _
            & " для которых в БД <font color=""Goldenrod"">отсутствуют *Задолженности простые*</font>. Для задолженностей в количестве " _
            & RcdCount & ".</p><p></p>" _
            & rslt
        ' проходим по каждой записи
        rsF.MoveFirst: iii = 1
        Do Until rsF.EOF = True
            strSql = ""
            strSql = "<p><font color=""silver"">"
                strSql = strSql & "Договор: <font color=""DarkSlateBlue"">" & iii & "</font>"
                strSql = strSql & ". <font color=""CadetBlue"">" & rsF!cidutCntrPrtName & "</font>"
                strSql = strSql & ". БУиРГ: <font color=""DarkCyan"">" & rsF!cidutCntrPrtNum & "</font>"
                strSql = strSql & ". № договора: <font color=""CadetBlue""><b>" & rsF!cidutCnName & "</b></font>"
                ' отсутствует ли дата договора? ciKey
                If IsNull(rsF!cidutCnDate) Then
                    ' да, дата договора отсутствует
                    strSql = strSql & " , <font color=""DarkGoldenrod"">дата отсутствует</font>"
                    Else
                    ' нет, дата договора имеется
                    strSql = strSql & " от <font color=""DarkSlateBlue"">" & rsF!cidutCnDate & "</font>"
                End If
                strSql = strSql & ". CnId: <font color=""DarkViolet"">" & rsF!cn_key & "</font>"
                strSql = strSql & ". Счета-фактура: <font color=""DarkSlateBlue"">" & rsF!cidutCnInv & "</font>"
                strSql = strSql & ". iKey: <font color=""DarkViolet"">" & rsF!iKey & "</font>"
                strSql = strSql & ". ciKey: <font color=""DarkViolet"">" & rsF!ciKey & "</font>"
                strSql = strSql & ". Счета главной книги: <font color=""DarkGoldenrod""><b>" & rsF!account_num & "</b></font>"
                strSql = strSql & ". AccountKey: <font color=""DarkViolet"">" & rsF!account_key & "</font>"
                strSql = strSql & "</font>.</p>"
            rslt = strSql & rslt
            ' переходим к следующей записи
            rsF.MoveNext: iii = iii + 1
        Loop
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p>В источнике <font color=""Goldenrod"">отсутствуют счета-фактуры с " _
            & "отсутствующими в БД *Задолженностями простыми*</font>.</p><p></p>" & rslt
    End If
    
    ' закрываем набор данных
    rsF.Close: Set rsF = Nothing
    
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем счета-фактуры не имеющие *Задолженностей простых* в БД, окончание **********************************************************************
'****************************************************************************************************************************************************




'****************************************************************************************************************************************************
' отображаем договора, имеющиеся в БД, в которых отсутствует обнаруженный в БД исполнитель. 22.11.2021 09:57 ****************************************
' поправил 28.12.2021 16:45 *************************************************************************************************************************
Private Sub CnExistCtptNotLoad(ByRef db As DAO.Database, ByRef rslt As Object, ByVal cidufFlLoad As Boolean)

    Dim strSql As String, rsF As DAO.Recordset, qd As DAO.QueryDef, RcdCount As Integer
    Dim rsCnAdd As DAO.Recordset, rsCnS_Add As DAO.Recordset, rsCnS_OrgAdd As DAO.Recordset
    Dim rsAddId As Integer
    Dim markInt As Long, noteStr As String

    Const cstrTitle As String _
        = "Процедура *Отображаем договора, в которых отсутствует обнаруженный в БД исполнитель либо добавляем их*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler
    
    Set rsF = db.OpenRecordset("ciduCnExistCtptNot", dbOpenSnapshot)
    ' имеются ли записи отсутствующих договоров? ciduCnCtptExistNot SqlCnExistCtptNotLoad()
    If rsF.RecordCount > 0 Then
        ' да, записи отсутствующих договоров имеются
        rslt = "<p>В источнике <font color=""CadetBlue"">имеются договора</font>, " _
            & "исполнитель по которым <font color=""Goldenrod"">не соответствует</font> имеющимся в БД.</p><p></p>" _
            & rslt
        ' проходим по каждой записи
        rsF.MoveFirst: iii = 1
        Do Until rsF.EOF = True
            strSql = ""
            strSql = "<p><font color=""silver"">"
                strSql = strSql & "Новый: <font color=""DarkSlateBlue"">" & iii & "</font>"
                strSql = strSql & ". <font color=""CadetBlue"">" & rsF!cidutCntrPrtName & "</font>"
                strSql = strSql & ". БУиРГ: <font color=""DarkCyan"">" & rsF!cidutCntrPrtNum & "</font>"
                strSql = strSql & ". ИНН: <font color=""DarkSlateBlue"">" & rsF!cidutCntrPrtITN & "</font>"
                strSql = strSql & ". № договора: <font color=""CadetBlue""><b>" & rsF!cidutCnName & "</b></font>"
                ' отсутствует ли дата договора?
                If IsNull(rsF!cidutCnDate) Then
                    ' да, дата договора отсутствует
                    strSql = strSql & " , <font color=""DarkGoldenrod"">дата отсутствует</font>"
                    Else
                    ' нет, дата договора имеется
                    strSql = strSql & " от <font color=""DarkSlateBlue"">" & rsF!cidutCnDate & "</font>"
                End If
                strSql = strSql & "</font>.</p>"
            rslt = strSql & rslt
            ' переходим к следующей записи
            rsF.MoveNext: iii = iii + 1
        Loop
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p>В источнике отсутствуют договора <font color=""Goldenrod"">исполнитель по которым не соответствует</font> имеющимся в БД.</p><p></p>" & rslt
    End If
    
    ' закрываем набор данных
    rsF.Close: Set rsF = Nothing

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем договора, в которых отсутствует обнаруженный в БД исполнитель либо добавляем их, окончание *********************************************
'****************************************************************************************************************************************************


'****************************************************************************************************************************************************
' отображаем отсутствующие в БД договоры с исполнителями либо добавляем их. 19.11.2021 12:30 ********************************************************
Private Sub CnNotLoad(ByRef db As DAO.Database, ByRef rslt As Object, ByVal cidufFlLoad As Boolean)

    Dim strSql As String, rsF As DAO.Recordset, qd As DAO.QueryDef, RcdCount As Integer
    Dim rsCnAdd As DAO.Recordset, rsCnNum_Add As DAO.Recordset, rsCnS_Add As DAO.Recordset, rsCnS_OrgAdd As DAO.Recordset
    Dim rsCnS_OrgSmplAdd As DAO.Recordset
    Dim rsAddId As Integer, rsAddIdNum As Integer
    Dim markInt As Long, noteStr As String

    Const cstrTitle As String _
        = "Процедура *Отображаем отсутствующие в БД договоры с исполнителями либо добавляем их*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    markInt = CLng(strMark(Now()))
    noteStr = "Добавлено " & Now()

    Set rsF = db.OpenRecordset("ciduCnNotLoad", dbOpenSnapshot)
    ' имеются ли записи отсутствующих договоров?
    If rsF.RecordCount > 0 Then
        ' да, записи отсутствующих договоров имеются
        rslt = "<p>В источнике <font color=""CadetBlue"">имеются новые договора</font>, не обнаруженные по номеру, дате и исполнителю</p><p></p>" _
            & rslt
            
        ' при необходимости обновления БД открываем таблицы для добавления
        If cidufFlLoad Then
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
                strSql = strSql & ". <font color=""CadetBlue"">" & rsF!cidutCntrPrtName & "</font>"
                strSql = strSql & ". БУиРГ: <font color=""DarkCyan"">" & rsF!cidutCntrPrtNum & "</font>"
                strSql = strSql & ". OrgId: <font color=""DarkViolet"">" & rsF!org_id_key & "</font>"
                strSql = strSql & ". ИНН: <font color=""DarkSlateBlue"">" & rsF!cidutCntrPrtITN & "</font>"
                strSql = strSql & ". № договора: <font color=""CadetBlue""><b>" & rsF!cidutCnName & "</b></font>"
                ' отсутствует ли дата договора?
                If IsNull(rsF!cidutCnDate) Or rsF!cidutCnDate = CDate("01.01.1900") Then
                    ' да, дата договора отсутствует
                    strSql = strSql & " , <font color=""DarkGoldenrod"">дата отсутствует</font>"
                    Else
                    ' нет, дата договора имеется
                    strSql = strSql & " от <font color=""DarkSlateBlue"">" & rsF!cidutCnDate & "</font>"
                End If
                ' имеются ли повторения номера договора среди новых договоров?
                If rsF!countCnName > 1 Then
                    ' да, повторения номера договора среди новых договоров имеются
                    strSql = strSql & " Среди новых договоров имеются повторы этого № в количестве: <font color=""Salmon"">" & rsF!countCnName & "</font>"
                    Else
                    ' нет, повторения номера договора среди новых договоров отсутствуют
                    strSql = strSql & ". Повторы № среди новых <font color=""DarkGreen"">отсутствуют</font>"
                    ' имеется ли необходимость в обновлении БД?
                    If cidufFlLoad Then
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
                        strSql = strSql & ". <font color=""DarkGreen"">Добавлено</font>. CnId: <font color=""CadetBlue"">" & rsAddId & "</font>"
                        ' добавляем номер договора
                        With rsCnNum_Add
                            .AddNew
                                !cnnNum = rsF!cidutCnName
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
                        With rsCnS_OrgAdd
                            .AddNew
                                !csoCn_s_org_smpl = rsAddId
                                !csoTimeOfEntry = Now()
                                ' отсутствует ли дата договора?
                                If IsNull(rsF!cidutCnDate) Then
                                    ' да, дата договора отсутствует
                                    Else
                                    ' нет, дата договора имеется
                                    !csoCnDate = rsF!cidutCnDate
                                End If
                            .Update
                            .Bookmark = .LastModified
                            rsAddId = !cn_s_org_key
                        End With
                        strSql = strSql & ". CnS_OrgId: <font color=""Teal"">" & rsAddId & "</font>"
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
        If cidufFlLoad Then
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
' отображаем отсутствующие в БД договоры с исполнителями либо добавляем их, окончание ***************************************************************
'****************************************************************************************************************************************************


'****************************************************************************************************************************************************
' отображаем счета-фактуры не имеющие *Задолженностей* в БД либо добавляем их. 18.11.2021 14:33 *****************************************************
Private Sub CnCtptInvExistAccNotLoad(ByRef db As DAO.Database, ByRef rslt As Object, ByVal cidufFlLoad As Boolean)

    Dim strSql As String, rsF As DAO.Recordset, qd As DAO.QueryDef, RcdCount As Integer
    Dim RcdCount2 As Integer

    Const cstrTitle As String _
        = "Процедура *Отображаем счета-фактуры не имеющие *Задолженностей* в БД либо добавляем их*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0

    ' отображаем счета-фактуры не имеющие пар "счёт-фактура + счёт главной книги" в БД
    CnCtptInvExistAccNot db, rslt, RcdCount
    
    ' есть ли необходимость обновлять БД?
    If cidufFlLoad And RcdCount > 0 Then
        ' да, необходимость обновлять БД имеется
        ' добавляем счета-фактуры
        
        db.Execute "ciduCnCtptInvAccSmplExtAccNotIns", dbFailOnError: RcdCount2 = db.RecordsAffected
        
'        Set qd = db.CreateQueryDef("", SqlCnCtptInvExistAccNotLoad()): qd.Execute dbFailOnError
        rslt = "<p>Внесено *Задолженностей* (строк) в БД: <b><font color=""DarkGreen"">" & RcdCount2 & "</font></b> Для " _
            & RcdCount & " задолженностей.</p>" & rslt
'        qd.Close: Set qd = Nothing
        
        ' ещё раз отображаем счета-фактуры, не имеющие пар "счёт-фактура + счёт главной книги" в БД
        CnCtptInvExistAccNot db, rslt, RcdCount
        Else
        ' нет, необходимость обновлять БД отсутствует
    End If
    
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем счета-фактуры не имеющие *Задолженностей* в БД либо добавляем их, окончание ************************************************************
'****************************************************************************************************************************************************


'****************************************************************************************************************************************************
' отображаем счета-фактуры не имеющие *Задолженностей* в БД. 18.11.2021 14:35 ***********************************************************************
Private Sub CnCtptInvExistAccNot(ByRef db As DAO.Database, ByRef rslt As Object, ByRef RcdCount As Integer)

    Dim strSql As String, rsF As DAO.Recordset

    Const cstrTitle As String _
        = "Процедура *Отображаем счета-фактуры не имеющие *Задолженностей* в БД*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0

    Set rsF = db.OpenRecordset("ciduCnCtptInvAccSmplExtAccNot", dbOpenSnapshot)
    ' имеются ли записи?
    If rsF.RecordCount > 0 Then
        ' да, записи имеются
        rsF.MoveLast
        RcdCount = rsF.RecordCount
        rslt = "<p>В источнике <font color=""CadetBlue"">имеются счета-фактуры</font>, " _
            & " для которых в БД <font color=""Goldenrod"">отсутствуют *Задолженности*</font>. Для задолженностей в количестве " _
            & RcdCount & ".</p><p></p>" _
            & rslt
        ' проходим по каждой записи
        rsF.MoveFirst: iii = 1
        Do Until rsF.EOF = True
            strSql = ""
            strSql = "<p><font color=""silver"">"
                strSql = strSql & "Дг.: <font color=""DarkSlateBlue"">" & iii & "</font>"
                strSql = strSql & ". <font color=""CadetBlue"">" & rsF!cidutCntrPrtName & "</font>"
                strSql = strSql & ". БУиРГ: <font color=""DarkCyan"">" & rsF!cidutCntrPrtNum & "</font>"
                strSql = strSql & ". № дг.: <font color=""CadetBlue""><b>" & rsF!cidutCnName & "</b></font>"
                ' отсутствует ли дата договора? ciKey
                If IsNull(rsF!cidutCnDate) Then
                    ' да, дата договора отсутствует
                    strSql = strSql & " , <font color=""DarkGoldenrod"">дата отсутствует</font>"
                    Else
                    ' нет, дата договора имеется
                    strSql = strSql & " от <font color=""DarkSlateBlue"">" & rsF!cidutCnDate & "</font>"
                End If
                strSql = strSql & ". CnId: <font color=""DarkViolet"">" & rsF!cn_key & "</font>"
                strSql = strSql & ". СФ: <font color=""DarkSlateBlue"">" & rsF!cidutCnInv & "</font>"
                strSql = strSql & ". iKey: <font color=""DarkViolet"">" & rsF!iKey & "</font>"
                strSql = strSql & ". ciKey: <font color=""DarkViolet"">" & rsF!ciKey & "</font>"
                strSql = strSql & ". СГК: <font color=""DarkGoldenrod""><b>" & rsF!account_num & "</b></font>"
                strSql = strSql & ". AccntKey: <font color=""DarkViolet"">" & rsF!account_key & "</font>"
                ' отсутствует ли имя задолженности? ciKey
                If rsF!cidutCnInvNameNull = "NullИлиПусто" Then
                    ' да, имя задолженности отсутствует
                    strSql = strSql & " , <font color=""DarkGoldenrod"">имени *Задолженности* нет</font>"
                    Else
                    ' нет, имя задолженности имеется
                    strSql = strSql & " имя: <font color=""DarkSlateBlue"">" & rsF!cidutCnInvNameNull & "</font>"
                End If
                strSql = strSql & "</font>.</p>"
            rslt = strSql & rslt
            ' переходим к следующей записи
            rsF.MoveNext: iii = iii + 1
        Loop
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p>В источнике <font color=""Goldenrod"">отсутствуют счета-фактуры с " _
            & "отсутствующими в БД *Задолженностями*</font>.</p><p></p>" & rslt
    End If
    
    ' закрываем набор данных
    rsF.Close: Set rsF = Nothing
    
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем счета-фактуры не имеющие *Задолженностей* в БД, окончание ******************************************************************************
'****************************************************************************************************************************************************




'****************************************************************************************************************************************************
' отображаем новые счета-фактуры для существующих договоров либо добавляем их в БД. 18.11.2021 12:35 ************************************************
Private Sub CnCtptExistInvNotLoad(ByRef db As DAO.Database, ByRef rslt As Object, ByVal cidufFlLoad As Boolean)

    Dim strSql As String, rsF As DAO.Recordset, qd As DAO.QueryDef, RcdCount As Integer
    Dim rsInv As DAO.Recordset, rsInvNum As DAO.Recordset, rsCnInv As DAO.Recordset
    Dim InvKey As Long, invNumKey As Long, CnInvNumKey As Long

    Const cstrTitle As String _
        = "Процедура *Отображаем новые счета-фактуры для существующих договоров либо добавляем их в БД*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0

    ' отображаем договора, имеющие новые счета-фактуры
    CnCtptExistInvNot db, rslt, RcdCount
    
    ' есть ли необходимость обновлять БД?
    If cidufFlLoad And RcdCount > 0 Then
        ' да, необходимость обновлять БД имеется
        ' добавляем счета-фактуры
'        Set qd = db.CreateQueryDef("", SqlCnCtptExistInvNotLoad()): qd.Execute dbFailOnError
'        qd.Close: Set qd = Nothing

        ' открываем таблицы для добавления
        Set rsInv = db.OpenRecordset("ags_inv", dbOpenDynaset, dbSeeChanges)
        Set rsInvNum = db.OpenRecordset("ags_invNum", dbOpenDynaset, dbSeeChanges)
        Set rsCnInv = db.OpenRecordset("ags_cnInv", dbOpenDynaset, dbSeeChanges)

        ' проходим по записям счётов-фактур, подлежащих внесению
        eee = 0
        Set rsF = db.OpenRecordset("CnInvDbtUplTblCnInv", dbOpenSnapshot)
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
                    !inNum = rsF!cidutciCnInv
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
                    !ciCn = rsF!cidutciCn_key
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
        
        ' ещё раз отображаем договора, имеющие новые счета-фактуры
        CnCtptExistInvNot db, rslt, RcdCount
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
' отображаем новые счета-фактуры для существующих договоров *****************************************************************************************
Private Sub CnCtptExistInvNot(ByRef db As DAO.Database, ByRef rslt As Object, ByRef RcdCount As Integer)

    Dim strSql As String, rsF As DAO.Recordset, qd As DAO.QueryDef

    Const cstrTitle As String _
        = "Процедура *Отображаем новые счета-фактуры для существующих договоров*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    RcdCount = 0

    ' очищаем табличку новых счётов-фактур
    strSql = "DELETE * FROM CnInvDbtUplTblCnInv": Set qd = db.CreateQueryDef("", strSql): qd.Execute dbFailOnError
    qd.Close: Set qd = Nothing
    
    ' вновь заполняем табличку счётов-фактур
    Set qd = db.CreateQueryDef("", SqlCnCtptExistInvNot()): qd.Execute dbFailOnError
    RcdCount = qd.RecordsAffected
    qd.Close: Set qd = Nothing
    
    ' отображаем договора, имеющие новые счета-фактуры
    Set rsF = db.OpenRecordset(SqlCnCtptExistInvNotRead(), dbOpenSnapshot)
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
                strSql = strSql & "Договор: <font color=""DarkSlateBlue"">" & iii & "</font>"
'                strSQL = strSQL & ". <font color=""CadetBlue"">" & rsF!cidutciCntrPrtName & "</font>"
'                strSQL = strSQL & ". БУиРГ: <font color=""DarkCyan"">" & rsF!cidutciCntrPrtNum & "</font>"
                strSql = strSql & ". № договора: <font color=""CadetBlue""><b>" & rsF!cidutciCnName & "</b></font>"
                ' отсутствует ли дата договора?
'                If IsNull(rsF!cidutciCnDate) Then
'                    ' да, дата договора отсутствует
'                    strSQL = strSQL & " , <font color=""DarkGoldenrod"">дата отсутствует</font>"
                    srtM = CnInvConcat(db, rsF!cidutciCn_key, Me!cidufKey, iii)
'                    Else
'                    ' нет, дата договора имеется
'                    strSQL = strSQL & " от <font color=""DarkSlateBlue"">" & rsF!cidutciCnDate & "</font>"
'                    srtM = CnInvConcat(db, rsF!cidutciCntrPrtNum, rsF!cidutciCnName, rsF!cidutciCnDate)
'                End If
                strSql = strSql & ". CnId: <font color=""DarkViolet"">" & rsF!cidutciCn_key & "</font>"
                strSql = strSql & ". Всего: <b><font color=""DarkGoldenrod"">" & rsF!cidutciCnInvCount & "</font></b>"
                strSql = strSql & ". Счета-фактуры: <font color=""DarkGray"">" & srtM & "</font>"
                strSql = strSql & "</font>.</p>"
            rslt = strSql & rslt
            ' переходим к следующей записи
            rsF.MoveNext: iii = iii + 1
        Loop
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p>В источнике <font color=""Goldenrod"">отсутствуют договора, имеющие счета-фактуры отстутствующие в БД</font>.</p><p></p>" & rslt
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


'****************************************************************************************************************************************************
' отображаем пары СФ+СГК имеющие более одной задолженности в выгрузке
Private Sub CnCtptInvAccExistDbl(ByRef db As DAO.Database, ByRef rslt As Object)

    Dim strSql As String, rsF As DAO.Recordset

    Const cstrTitle As String _
        = "Процедура *Отображаем пары СФ+СГК имеющие более одной задолженности в выгрузке*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    Set rsF = db.OpenRecordset(SqlCnCtptInvAccExistDbl(), dbOpenSnapshot)
    ' имеются ли записи? Rslt
    If rsF.RecordCount > 0 Then
        ' да, записи имеются
        rslt = "<p>Имеются <font color=""CadetBlue"">*Задолженности* </font>, " _
            & "<font color=""Goldenrod"">количество задолженностей по которым, в источнике, отличается от одной</font>.</p><p></p>" _
            & rslt
        ' проходим по каждой записи
        rsF.MoveFirst: iii = 1
        Do Until rsF.EOF = True
            strSql = ""
            strSql = "<p><font color=""silver"">"
                strSql = strSql & "Договор: <font color=""DarkSlateBlue"">" & iii & "</font>"
                strSql = strSql & ". <font color=""CadetBlue"">" & rsF!cidutCntrPrtName & "</font>"
                strSql = strSql & ". БУиРГ: <font color=""DarkCyan"">" & rsF!cidutCntrPrtNum & "</font>"
                strSql = strSql & ". № договора: <font color=""CadetBlue""><b>" & rsF!cidutCnName & "</b></font>"
                ' отсутствует ли дата договора?
                If IsNull(rsF!cidutCnDate) Then
                    ' да, дата договора отсутствует
                    strSql = strSql & " , <font color=""DarkGoldenrod"">дата отсутствует</font>"
                    Else
                    ' нет, дата договора имеется
                    strSql = strSql & " от <font color=""DarkSlateBlue"">" & rsF!cidutCnDate & "</font>"
                End If
                strSql = strSql & ". CnId: <font color=""DarkViolet"">" & rsF!cn_key & "</font>"
                strSql = strSql & ". Счета-фактура: <font color=""DarkSlateBlue"">" & rsF!cidutCnInv & "</font>"
                strSql = strSql & ". Счета главной книги: <font color=""Indigo""><b>" & rsF!account_num & "</b></font>"
                strSql = strSql & ". Количество: <font color=""Teal""><b>" & rsF!cidutUnloadKeyCount & "</b></font>"
                strSql = strSql & "</font>.</p>"
            rslt = strSql & rslt
            ' переходим к следующей записи
            rsF.MoveNext: iii = iii + 1
        Loop
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p>Отсутствуют <b><font color=""DarkGreen"">*Задолженности* " _
            & "количество задолженностей по которым, в источнике, отличается от одной</font></b>.</p><p></p>" & rslt
    End If
    
    ' закрываем набор данных
    rsF.Close: Set rsF = Nothing

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем пары СФ+СГК имеющие более одной задолженности в рассматриваемой выгрузке, окончание
'****************************************************************************************************************************************************


'****************************************************************************************************************************************************
' отображаем *Задолженности* не имеющие задолженности в БД либо добавляем их туда 14.01.2022 12:27
Private Sub CnCtptInvAccExistDbtNotLoad(ByRef db As DAO.Database, ByRef rslt As Object, ByVal cidufFlLoad As Boolean)

    Dim sQ As String ', rsF As DAO.Recordset,
    Dim dbtNotRecordCount As Integer, qd As DAO.QueryDef
    Dim RcdCount As Integer

    Const cstrTitle As String _
        = "Процедура *Отображаем *Задолженности* не имеющие задолженности в БД либо добавляем их туда*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler
    
    dbtNotRecordCount = 0

    ' отображаем пары СФ+СГК не имеющие задолженности в БД и определяем их количество
    CnCtptInvAccExistDbtNot db, rslt, dbtNotRecordCount
    
    ' имеется ли необходимость внесения задолженностей в БД и имеются ли задолженности подлежащие внесению?
    If cidufFlLoad And dbtNotRecordCount > 0 Then
        ' да, необходимость внесения задолженностей в БД и задолженности подлежащие внесению имеются
        ' добавляем задолженности
        db.Execute "ciduCnCtptInvAccSmplExtAccExtDbtNotIns", dbFailOnError: RcdCount = db.RecordsAffected
        
'        Set qd = db.CreateQueryDef("", "ciduCnCtptInvAccSmplExtAccExtDbtNotIns"): qd.Execute dbFailOnError
        rslt = "<p>Внесено задолженностей (строк) в БД: <b><font color=""DarkGreen"">" & RcdCount & "</font></b></p>" & rslt
'        qd.Close: Set qd = Nothing

        ' отображаем пары СФ+СГК не имеющие задолженности в БД и определяем их количество
        CnCtptInvAccExistDbtNot db, rslt, dbtNotRecordCount
        
        Else
        ' нет, необходимость внесения задолженностей в БД отсутствует либо задолженности подлежащие внесению отсутствуют
    End If

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем *Задолженности* не имеющие задолженности в БД либо добавляем их туда, окончание
'****************************************************************************************************************************************************


'****************************************************************************************************************************************************
' отображаем *Задолженности* не имеющие задолженности в БД 14.01.2022 12:27
Private Sub CnCtptInvAccExistDbtNot(ByRef db As DAO.Database, ByRef rslt As Object, ByRef dbtNotRecordCount As Integer)

    Dim strSql As String, rsF As DAO.Recordset

    Const cstrTitle As String _
        = "Процедура *Отображаем *Задолженности* не имеющие задолженности в БД*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' изначально определим, что количество таких пар равно 0 (записи отсутствуют)
    dbtNotRecordCount = 0

    Set rsF = db.OpenRecordset("ciduCnCtptInvAccSmplExtAccExtDbtNot", dbOpenSnapshot)
    ' имеются ли записи? Rslt
    If rsF.RecordCount > 0 Then
        ' да, записи имеются
        ' определим, сколько их всего
        rsF.MoveLast
        dbtNotRecordCount = rsF.RecordCount
        rsF.MoveFirst: iii = 1
        rslt = "<p>В источнике <font color=""CadetBlue""><b>имеются *Задолженности*</b></font>, " _
            & " <font color=""Goldenrod""><b>задолженности по которым не отражены</b></font> в БД. Всего их: <font color=""Indigo""><b>" _
            & dbtNotRecordCount & "</b></font>. --------------------------------------------------------</b></p><p></p>" _
            & rslt
        ' проходим по каждой записи
        Do Until rsF.EOF = True
            strSql = ""
            strSql = "<p><font color=""silver"">"
                strSql = strSql & "Договор: <font color=""DarkSlateBlue"">" & iii & "</font>"
                strSql = strSql & ". <font color=""CadetBlue"">" & rsF!cidutCntrPrtName & "</font>"
                strSql = strSql & ". БУиРГ: <font color=""DarkCyan"">" & rsF!cidutCntrPrtNum & "</font>"
                ' имеется ли номер у договора?
                If IsNull(rsF!cidutCnName) Then
                    strSql = strSql & ". № договора: <font color=""DarkGoldenrod""><b>Null или пустая строка</b></font>"
                    Else
                    strSql = strSql & ". № договора: <font color=""CadetBlue""><b>" & rsF!cidutCnName & "</b></font>"
                End If
                ' отсутствует ли дата договора?
                If IsNull(rsF!cidutCnDate) Then
                    ' да, дата договора отсутствует
                    strSql = strSql & " , <font color=""DarkGoldenrod"">дата отсутствует</font>"
                    Else
                    ' нет, дата договора имеется
                    strSql = strSql & " от <font color=""DarkSlateBlue"">" & rsF!cidutCnDate & "</font>"
                End If
                strSql = strSql & ". CnId: <font color=""DarkViolet"">" & rsF!cn_key & "</font>"
                ' имеется ли номер у счёта-фактуры? n.ciKey
                If IsNull(rsF!cidutCnInv) Then
                    strSql = strSql & ". Счет-фактура: <font color=""DarkGoldenrod""><b>Null или пустая строка</b></font>"
                    Else
                    strSql = strSql & ". Счет-фактура: <font color=""CadetBlue""><b>" & rsF!cidutCnInv & "</b></font>"
                End If
                ' имеется ли имя у задолженности? n.ciKey
                If rsF!cidutCnInvNameNull = "NullИлиПусто" Then
                    strSql = strSql & ". Имя задолженности: <font color=""DarkGoldenrod""><b>отсутствует</b></font>"
                    Else
                    strSql = strSql & ". Имя задолженности: <font color=""CadetBlue""><b>" & rsF!cidutCnInvNameNull & "</b></font>"
                End If
                strSql = strSql & ". ciKey: <font color=""DarkViolet"">" & rsF!ciKey & "</font>"
                strSql = strSql & ". Счет главной книги: <font color=""Indigo"">" & rsF!account_num & "</font>"
                strSql = strSql & ". ciaKey: <font color=""DarkViolet"">" & rsF!ciaKey & "</font>"
'                strSQL = strSQL & ". Количество: <font color=""Teal""><b>" & rsF!cidutUnloadKeyCount & "</b></font>"
                strSql = strSql & "</font>.</p>"
            rslt = strSql & rslt
            ' переходим к следующей записи
            rsF.MoveNext: iii = iii + 1
        Loop
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p>В источнике <b><font color=""DarkGoldenrod"">отсутствуют *Задолженности* " _
            & "задолженности по которым не отражены</font></b> в БД.</p><p></p>" & rslt
    End If
    
    ' закрываем набор данных
    rsF.Close: Set rsF = Nothing
    
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем *Задолженности* не имеющие задолженности в БД, окончание
'****************************************************************************************************************************************************

'****************************************************************************************************************************************************
' отображаем пары СФ+СГК имеющие задолженности в БД
Private Sub CnCtptInvAccDbtExist(ByRef db As DAO.Database, ByRef rslt As Object)

    Dim sQ As String, rsF As DAO.Recordset, dbtNotRecordCount As Integer

    Const cstrTitle As String _
        = "Процедура *Отображаем пары СФ+СГК имеющие задолженности в БД*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    Set rsF = db.OpenRecordset("ciduCnCtptInvAccSmplExtAccExtDbtExtD", dbOpenSnapshot)
    ' имеются ли записи? Rslt
    If rsF.RecordCount > 0 Then
        ' да, записи имеются
        ' определим, сколько их всего
        rsF.MoveLast
        dbtNotRecordCount = rsF.RecordCount
        rsF.MoveFirst: iii = 1
        rslt = "<p>В источнике <font color=""CadetBlue""><b>имеются *пары СФ+СГК*</b></font>, " _
            & " <font color=""Goldenrod""><b>задолженности по которым отражены</b></font> в БД. Всего их: <font color=""Indigo""><b>" _
            & dbtNotRecordCount & "</b></font>. --------------------------------------------------------</b></p><p></p>" _
            & rslt
        ' проходим по каждой записи
        rsF.MoveFirst: iii = 1
        Do Until rsF.EOF = True
            strSql = ""
            strSql = "<p><font color=""silver"">"
                strSql = strSql & "Договор: <font color=""DarkSlateBlue"">" & iii & "</font>"
                strSql = strSql & ". <font color=""CadetBlue"">" & rsF!cidutCntrPrtName & "</font>"
                strSql = strSql & ". БУиРГ: <font color=""DarkCyan"">" & rsF!cidutCntrPrtNum & "</font>"
                strSql = strSql & ". № договора: <font color=""CadetBlue""><b>" & rsF!cidutCnName & "</b></font>"
                ' отсутствует ли дата договора?
                If IsNull(rsF!cidutCnDate) Then
                    ' да, дата договора отсутствует
                    strSql = strSql & " , <font color=""DarkGoldenrod"">дата отсутствует</font>"
                    Else
                    ' нет, дата договора имеется
                    strSql = strSql & " от <font color=""DarkSlateBlue"">" & rsF!cidutCnDate & "</font>"
                End If
'                strSQL = strSQL & ". CnId: <font color=""DarkViolet"">" & rsF!cn_key & "</font>"
                strSql = strSql & ". Счет-фактура: <font color=""DarkSlateBlue""><b>" & rsF!cidutCnInv & "</b></font>"
                strSql = strSql & ". Счет главной книги: <font color=""Indigo"">" & rsF!account_num & "</font>"
'                strSQL = strSQL & ". Количество: <font color=""Teal""><b>" & rsF!cidutUnloadKeyCount & "</b></font>"
                If rsF!FormtnDateDiff Then
                    strSql = strSql & ". Образование: <font color=""Teal""><b>+</b></font>"
                    Else
                    strSql = strSql & ". <font color=""Red"">Образование</font>, БД:<font color=""Salmon"">" & rsF!cn_inv_date_start & "</font>"
                    strSql = strSql & ", ист.:<font color=""DarkOrange""><b>" & rsF!cidutFormtnDate & "</b></font>"
                End If
                If rsF!MatrtyDateDiff Then
                    strSql = strSql & ". Погашение: <font color=""Teal""><b>+</b></font>"
                    Else
                    strSql = strSql & ". <font color=""Red"">Погашение</font>, БД:<font color=""Salmon"">" & rsF!cn_inv_date_maturity & "</font>"
                    strSql = strSql & ", ист.:<font color=""DarkOrange""><b>" & rsF!cidutMatrtyDate & "</b></font>"
                End If
                If rsF!DebtDiff Then
                    strSql = strSql & ". Общая: <font color=""Teal""><b>+</b></font>"
                    Else
                    strSql = strSql & ". <font color=""Red"">Общая</font>, БД:<font color=""Salmon"">" & FormatCurrency(rsF!dbt_ttl) & "</font>"
                    strSql = strSql & ", ист.:<font color=""DarkOrange""><b>" & FormatCurrency(rsF!cidutDebt) & "</b></font>"
                End If
                If rsF!DebtOverdueDiff Then
                    strSql = strSql & ". Просроченная: <font color=""Teal""><b>+</b></font>"
                    Else
                    strSql = strSql & ". <font color=""Red"">Просроченная</font>, БД:<font color=""Salmon"">" & FormatCurrency(rsF!dbt_overd) & "</font>"
                    strSql = strSql & ", ист.:<font color=""DarkOrange""><b>" & FormatCurrency(rsF!cidutDebtOverdue) & "</b></font>"
                End If
                If rsF!DocDiff Then
                    strSql = strSql & ". Документ: <font color=""Teal""><b>+</b></font>"
                    Else
                    strSql = strSql & ". <font color=""Red"">Документ</font>, БД:<font color=""Salmon"">" & rsF!doc_base & "</font>"
                    strSql = strSql & ", ист.:<font color=""DarkOrange""><b>" & rsF!cidutDoc & "</b></font>"
                End If
                If rsF!LinkDiff Then
                    strSql = strSql & ". Ссылка: <font color=""Teal""><b>+</b></font>"
                    Else
                    strSql = strSql & ". <font color=""Red"">Ссылка</font>, БД:<font color=""Salmon"">" & rsF!link & "</font>"
                    strSql = strSql & ", ист.:<font color=""DarkOrange""><b>" & rsF!cidutLink & "</b></font>"
                End If
                If rsF!NumDiff Then
                    strSql = strSql & ". № п/п: <font color=""Teal""><b>+</b></font>"
                    Else
                    strSql = strSql & ". <font color=""Red"">№ п/п</font>, БД:<font color=""Salmon"">" & rsF!Number & "</font>"
                    strSql = strSql & ", ист.:<font color=""DarkOrange""><b>" & rsF!cidutSheetNum & "</b></font>"
                End If
                strSql = strSql & "</font>.</p>"
            rslt = strSql & rslt
            ' переходим к следующей записи
            rsF.MoveNext: iii = iii + 1
        Loop
        Else
        ' нет, записи отсутствующих договоров отсутствуют
        rslt = "<p>В источнике <b><font color=""DarkGoldenrod"">отсутствуют пары *СФ+СГК*" _
            & " задолженности по которым отражены</font></b> в БД.</p><p></p>" & rslt
    End If
    
    ' закрываем набор данных
    rsF.Close: Set rsF = Nothing

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' отображаем пары СФ+СГК имеющие задолженности в БД, окончание
'****************************************************************************************************************************************************

''****************************************************************************************************************************************************
'' формируем склейку номеров счетов-фактур ***********************************************************************************************************
'Function CnInvConcat(db As DAO.Database, CntrPrtNum As Long, CnName As String, _
'    Optional CnDate As Date = #1/1/1900#) As String
'
'    Dim strSQL As String, strDate As String, rs As DAO.Recordset, iii As Integer, strRslt As String, strNull As String
'
'    Const cstrTitle As String _
'        = "Процедура *Формируем склейку номеров счетов-фактур*"
'
'    '************************************************************************************************************************************************
'
'On Error GoTo ErrHandler
'
'    strSQL = ""
'
'    If CnDate = #1/1/1900# Then
'        strSQL = strSQL & "SELECT cidutciCntrPrtNum, cidutciCnName, cidutciCnDate, cidutciCnInv "
'        strSQL = strSQL & "FROM CnInvDbtUplTblCnInv "
'        strSQL = strSQL & "WHERE (((cidutciCntrPrtNum) = " & CntrPrtNum & ") And ((cidutciCnName) = """ & CnName & """) And ((cidutciCnDate) is Null)) "
'        strSQL = strSQL & "GROUP BY cidutciCntrPrtNum, cidutciCnName, cidutciCnDate, cidutciCnInv"
'        Else
'        strDate = DateConvertToQuery(CnDate)
'        strSQL = strSQL & "SELECT cidutciCntrPrtNum, cidutciCnName, cidutciCnDate, cidutciCnInv "
'        strSQL = strSQL & "FROM CnInvDbtUplTblCnInv "
'        strSQL = strSQL & "WHERE (((cidutciCntrPrtNum) = " & CntrPrtNum & ") And ((cidutciCnName) = """ & CnName & """) And ((cidutciCnDate) = " & strDate & ")) "
'        strSQL = strSQL & "GROUP BY cidutciCntrPrtNum, cidutciCnName, cidutciCnDate, cidutciCnInv"
'    End If
'
'    Set rs = db.OpenRecordset(strSQL, dbOpenSnapshot)
'
'    ' имеются ли записи?
'    If rs.RecordCount > 0 Then
'        ' да, записи имеются
'        ' проходим по каждой записи
'        rs.MoveFirst: iii = 1: strRslt = ""
'        Do Until rs.EOF = True
'            ' проверяем на пустоту
'            If IsNull(rs!cidutciCnInv) Or rs!cidutciCnInv = "" Then
'                strNull = "*<font color=""DarkOrange"">пустая строка</font>*"
'                Else
'                strNull = rs!cidutciCnInv
'            End If
'            ' формируем результат
'            If iii = 1 Then
'                strRslt = "<font color=""MediumOrchid"">" & iii & "</font>. " & strNull
'                Else
'                strRslt = strRslt & "; <font color=""MediumOrchid"">" & iii & "</font>. " & strNull
'            End If
'            ' переходим к следующей записи
'            rs.MoveNext: iii = iii + 1
'        Loop
'        CnInvConcat = strRslt
'        Else
'        ' нет, записи отсутствуют
'        CnInvConcat = "*нет записей*"
'    End If
'
'    rs.Close: Set rs = Nothing
'
'NormalExit:
'    Exit Function
'
'ErrHandler:
'    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
'    Resume NormalExit
'
'End Function
'' формируем склейку номеров счетов-фактур, окончание ************************************************************************************************
''****************************************************************************************************************************************************


'****************************************************************************************************************************************************
' рассматриваем лист отдельного счёта из выгрузки бухгалтерии Ф644
Private Sub AccountSheetTest(ByRef db As DAO.Database, ByRef xlW As Excel.Workbook, ByVal WorkSheetName As String, _
    ByVal UnloadKey As Integer, ByVal AccountKey As Integer, ByVal cidufsKey As Integer, ByRef rsFindCst As DAO.Recordset _
    , ByRef LoadingProgress As Object, ByRef FindDbtNum As Integer)

    Dim xlS As Excel.Worksheet
    Dim c As Range, loadRange As Range, iR As Range, strF As String
    
    ' ячейки колонок, необходимых для внесения свойств задолженности
    Dim cidutCntrPrtNum_r As Range, cidutCntrPrtName_r As Range, cidutCntrPrtITN_r As Range, cidutCnName_r As Range, cidutCnDate_r As Range
    Dim cidutFormtnDate_r As Range, cidutMatrtyDate_r As Range, cidutDebt_r As Range, cidutDebtOverdue_r As Range, cidutDoc_r As Range
    Dim cidutLink_r As Range

    Const cstrTitle As String _
        = "Процедура *Рассматриваем лист отдельного счёта из выгрузки бухгалтерии Ф644"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' имеется ли требуемый лист? ====================================================================================================================
    If WorksheetIsExist(xlW, WorkSheetName) Then
        ' да, требуемый лист имеется
        ' открываем существующий лист
        Set xlS = xlW.Worksheets(WorkSheetName)
        
        LoadingProgress = "<P> <font color=""silver"">Лист <font color=""Teal"">" _
            & WorkSheetName & " <b>обнаружен</b></font> в книге</font></P>" & LoadingProgress
        
        ' снимаем фильтры листа, если есть
        If (xlS.AutoFilterMode And xlS.FilterMode) Or xlS.FilterMode Then
            xlS.ShowAllData
        End If
        
        ' отыскиваем ячейки колонок, необходимых для внесения свойств задолженности -----------------------------------------------------------------
        ' отыскиваем ячейку "Документ основания (счет-фактура)" .....................................................................................
        Set c = xlS.UsedRange.Find(what:="Документ основания (счет-фактура)", LookAt:=xlWhole)
        
        ' итог поисков ячейки "счет-фактура"
        If Not c Is Nothing Then
            ' ячейка "счет-фактура" найдена
            LoadingProgress = "<P> <font color=""silver"">Найдена ячейка <b>*Документ основания (счет-фактура)</b> - " _
                & c.Column & ", строка - " & c.Row & "." _
                & " Содержание: <font color=""RoyalBlue"">" & c & "</font>.</font></P>" & LoadingProgress
            Else
            ' ячейка "счет-фактура" не найдена
            LoadingProgress = _
                "<P> <font color=""silver"">Ячейка <b>*Документ основания (счет-фактура)*</b> <font color=""red"">не найдена</font></font></P>" _
                & LoadingProgress
        End If
        ' отыскиваем ячейку "Документ основания (счет-фактура)", окончание ..........................................................................

        ' отыскиваем ячейку "№ контрагента" .........................................................................................................
        Set cidutCntrPrtNum_r = xlS.UsedRange.Find(what:="№ контрагента", LookAt:=xlWhole)
        
        ' итог поисков ячейки "№ контрагента"
        If Not cidutCntrPrtNum_r Is Nothing Then
            ' ячейка "№ контрагента" найдена
            LoadingProgress = "<P> <font color=""silver"">Найдена ячейка <b>*№ контрагента</b> - " _
                & cidutCntrPrtNum_r.Column & ", строка - " & cidutCntrPrtNum_r.Row & "." _
                & " Содержание: <font color=""RoyalBlue"">" & c & "</font>.</font></P>" & LoadingProgress
            Else
            ' ячейка "№ контрагента" не найдена
            LoadingProgress = _
                "<P> <font color=""silver"">Ячейка <b>*№ контрагента*</b> <font color=""red"">не найдена</font></font></P>" _
                & LoadingProgress
        End If
        ' отыскиваем ячейку "№ контрагента", окончание ..............................................................................................

        ' отыскиваем ячейку "Контрагент" ............................................................................................................
        Set cidutCntrPrtName_r = xlS.UsedRange.Find(what:="Контрагент", LookAt:=xlWhole)
        
        ' итог поисков ячейки "Контрагент"
        If Not cidutCntrPrtName_r Is Nothing Then
            ' ячейка "Контрагент" найдена
            LoadingProgress = "<P> <font color=""silver"">Найдена ячейка <b>*Контрагент</b> - " _
                & cidutCntrPrtName_r.Column & ", строка - " & cidutCntrPrtName_r.Row & "." _
                & " Содержание: <font color=""RoyalBlue"">" & c & "</font>.</font></P>" & LoadingProgress
            Else
            ' ячейка "Контрагент" не найдена
            LoadingProgress = _
                "<P> <font color=""silver"">Ячейка <b>*Контрагент*</b> <font color=""red"">не найдена</font></font></P>" _
                & LoadingProgress
        End If
        ' отыскиваем ячейку "Контрагент", окончание .................................................................................................

        ' отыскиваем ячейку "ИНН" ...................................................................................................................
        Set cidutCntrPrtITN_r = xlS.UsedRange.Find(what:="ИНН", LookAt:=xlWhole)
        
        ' итог поисков ячейки "ИНН"
        If Not cidutCntrPrtITN_r Is Nothing Then
            ' ячейка "ИНН" найдена
            LoadingProgress = "<P> <font color=""silver"">Найдена ячейка <b>*ИНН</b> - " _
                & cidutCntrPrtITN_r.Column & ", строка - " & cidutCntrPrtITN_r.Row & "." _
                & " Содержание: <font color=""RoyalBlue"">" & c & "</font>.</font></P>" & LoadingProgress
            Else
            ' ячейка "ИНН" не найдена
            LoadingProgress = _
                "<P> <font color=""silver"">Ячейка <b>*ИНН*</b> <font color=""red"">не найдена</font></font></P>" _
                & LoadingProgress
        End If
        ' отыскиваем ячейку "ИНН", окончание ........................................................................................................

        ' отыскиваем ячейку "Договор" ...............................................................................................................
        Set cidutCnName_r = xlS.UsedRange.Find(what:="Договор", LookAt:=xlWhole)
        
        ' итог поисков ячейки "Договор"
        If Not cidutCnName_r Is Nothing Then
            ' ячейка "Договор" найдена
            LoadingProgress = "<P> <font color=""silver"">Найдена ячейка <b>*Договор</b> - " _
                & cidutCnName_r.Column & ", строка - " & cidutCnName_r.Row & "." _
                & " Содержание: <font color=""RoyalBlue"">" & c & "</font>.</font></P>" & LoadingProgress
            Else
            ' ячейка "Договор" не найдена
            LoadingProgress = _
                "<P> <font color=""silver"">Ячейка <b>*Договор*</b> <font color=""red"">не найдена</font></font></P>" _
                & LoadingProgress
        End If
        ' отыскиваем ячейку "Договор", окончание ....................................................................................................

        ' отыскиваем ячейку "Дата договора" .........................................................................................................
        Set cidutCnDate_r = xlS.UsedRange.Find(what:="Дата договора", LookAt:=xlWhole)
        
        ' итог поисков ячейки "Дата договора"
        If Not cidutCnDate_r Is Nothing Then
            ' ячейка "Дата договора" найдена
            LoadingProgress = "<P> <font color=""silver"">Найдена ячейка <b>*Дата договора</b> - " _
                & cidutCnDate_r.Column & ", строка - " & cidutCnDate_r.Row & "." _
                & " Содержание: <font color=""RoyalBlue"">" & c & "</font>.</font></P>" & LoadingProgress
            Else
            ' ячейка "Дата договора" не найдена
            LoadingProgress = _
                "<P> <font color=""silver"">Ячейка <b>*Дата договора*</b> <font color=""red"">не найдена</font></font></P>" _
                & LoadingProgress
        End If
        ' отыскиваем ячейку "Дата договора", окончание ..............................................................................................

        ' отыскиваем ячейку "Дата образования" ......................................................................................................
        Set cidutFormtnDate_r = xlS.UsedRange.Find(what:="Дата образования", LookAt:=xlWhole)
        
        ' итог поисков ячейки "Дата образования"
        If Not cidutFormtnDate_r Is Nothing Then
            ' ячейка "Дата образования" найдена
            LoadingProgress = "<P> <font color=""silver"">Найдена ячейка <b>*Дата образования</b> - " _
                & cidutFormtnDate_r.Column & ", строка - " & cidutFormtnDate_r.Row & "." _
                & " Содержание: <font color=""RoyalBlue"">" & c & "</font>.</font></P>" & LoadingProgress
            Else
            ' ячейка "Дата образования" не найдена
            LoadingProgress = _
                "<P> <font color=""silver"">Ячейка <b>*Дата образования*</b> <font color=""red"">не найдена</font></font></P>" _
                & LoadingProgress
        End If
        ' отыскиваем ячейку "Дата образования", окончание ...........................................................................................

        ' отыскиваем ячейку "Срок погашения" ........................................................................................................
        Set cidutMatrtyDate_r = xlS.UsedRange.Find(what:="Срок погашения", LookAt:=xlWhole)
        
        ' итог поисков ячейки "Срок погашения"
        If Not cidutMatrtyDate_r Is Nothing Then
            ' ячейка "Срок погашения" найдена
            LoadingProgress = "<P> <font color=""silver"">Найдена ячейка <b>*Срок погашения</b> - " _
                & cidutMatrtyDate_r.Column & ", строка - " & cidutMatrtyDate_r.Row & "." _
                & " Содержание: <font color=""RoyalBlue"">" & c & "</font>.</font></P>" & LoadingProgress
            Else
            ' ячейка "Срок погашения" не найдена
            LoadingProgress = _
                "<P> <font color=""silver"">Ячейка <b>*Срок погашения*</b> <font color=""red"">не найдена</font></font></P>" _
                & LoadingProgress
        End If
        ' отыскиваем ячейку "Срок погашения", окончание .............................................................................................

        ' отыскиваем ячейку "Всего сумма задолженности в рублях" ....................................................................................
        Set cidutDebt_r = xlS.UsedRange.Find(what:="Всего сумма задолженности в рублях", LookAt:=xlWhole)
        
        ' итог поисков ячейки "Всего сумма задолженности в рублях"
        If Not cidutDebt_r Is Nothing Then
            ' ячейка "Всего сумма задолженности в рублях" найдена
            LoadingProgress = "<P> <font color=""silver"">Найдена ячейка <b>*Всего сумма задолженности в рублях</b> - " _
                & cidutDebt_r.Column & ", строка - " & cidutDebt_r.Row & "." _
                & " Содержание: <font color=""RoyalBlue"">" & c & "</font>.</font></P>" & LoadingProgress
            Else
            ' ячейка "Всего сумма задолженности в рублях" не найдена
            LoadingProgress = _
                "<P> <font color=""silver"">Ячейка <b>*Всего сумма задолженности в рублях*</b> <font color=""red"">не найдена</font></font></P>" _
                & LoadingProgress
        End If
        ' отыскиваем ячейку "Всего сумма задолженности в рублях", окончание .........................................................................

        ' отыскиваем ячейку "Просроченная задолженность в рублях" ...................................................................................
        Set cidutDebtOverdue_r = xlS.UsedRange.Find(what:="Просроченная задолженность в рублях", LookAt:=xlWhole)
        
        ' итог поисков ячейки "Просроченная задолженность в рублях"
        If Not cidutDebtOverdue_r Is Nothing Then
            ' ячейка "Просроченная задолженность в рублях" найдена
            LoadingProgress = "<P> <font color=""silver"">Найдена ячейка <b>*Просроченная задолженность в рублях</b> - " _
                & cidutDebtOverdue_r.Column & ", строка - " & cidutDebtOverdue_r.Row & "." _
                & " Содержание: <font color=""RoyalBlue"">" & c & "</font>.</font></P>" & LoadingProgress
            Else
            ' ячейка "Просроченная задолженность в рублях" не найдена
            LoadingProgress = _
                "<P> <font color=""silver"">Ячейка <b>*Просроченная задолженность в рублях*</b> <font color=""red"">не найдена</font></font></P>" _
                & LoadingProgress
        End If
        ' отыскиваем ячейку "Просроченная задолженность в рублях", окончание ........................................................................

        ' отыскиваем ячейку "Документ основания (присвоение ГК)" ....................................................................................
        Set cidutDoc_r = xlS.UsedRange.Find(what:="Документ основания (присвоение ГК)", LookAt:=xlWhole)
        
        ' итог поисков ячейки "Документ основания (присвоение ГК)"
        If Not cidutDoc_r Is Nothing Then
            ' ячейка "Документ основания (присвоение ГК)" найдена
            LoadingProgress = "<P> <font color=""silver"">Найдена ячейка <b>*Документ основания (присвоение ГК)</b> - " _
                & cidutDoc_r.Column & ", строка - " & cidutDoc_r.Row & "." _
                & " Содержание: <font color=""RoyalBlue"">" & c & "</font>.</font></P>" & LoadingProgress
            Else
            ' ячейка "Документ основания (присвоение ГК)" не найдена
            LoadingProgress = _
                "<P> <font color=""silver"">Ячейка <b>*Документ основания (присвоение ГК)*</b> <font color=""red"">не найдена</font></font></P>" _
                & LoadingProgress
        End If
        ' отыскиваем ячейку "Документ основания (присвоение ГК)", окончание .........................................................................

        ' отыскиваем ячейку "Ссылка" ....................................................................................
        Set cidutLink_r = xlS.UsedRange.Find(what:="Ссылка", LookAt:=xlWhole)
        
        ' итог поисков ячейки "Ссылка"
        If Not cidutLink_r Is Nothing Then
            ' ячейка "Ссылка" найдена
            LoadingProgress = "<P> <font color=""silver"">Найдена ячейка <b>*Ссылка</b> - " _
                & cidutLink_r.Column & ", строка - " & cidutLink_r.Row & "." _
                & " Содержание: <font color=""RoyalBlue"">" & c & "</font>.</font></P>" & LoadingProgress
            Else
            ' ячейка "Ссылка" не найдена
            LoadingProgress = _
                "<P> <font color=""silver"">Ячейка <b>*Ссылка*</b> <font color=""red"">не найдена</font></font></P>" _
                & LoadingProgress
        End If
        ' отыскиваем ячейку "Ссылка", окончание .........................................................................
        ' отыскиваем ячейки колонок, необходимых для внесения свойств задолженности, окончание ------------------------------------------------------
        
        
        ' итог поисков ячеек
        If Not c Is Nothing And Not cidutCntrPrtNum_r Is Nothing And Not cidutCntrPrtName_r Is Nothing _
            And Not cidutCnName_r Is Nothing _
            And Not cidutCnDate_r Is Nothing And Not cidutFormtnDate_r Is Nothing _
            And Not cidutMatrtyDate_r Is Nothing And Not cidutDebt_r Is Nothing _
            And Not cidutDebtOverdue_r Is Nothing _
            Then
            ' ячейки найдены
            LoadingProgress = "<P> <font color=""silver"">Найдены ячейки <b>*необходимые для внесения задолженности</b>" _
                & ".</font></P>" & LoadingProgress
                
                ' определяем диапазон листа выгрузки в виде колонки для поиска счет-фактур
                Set loadRange = xlS.Range _
                    ( _
                        xlS.Cells(c.Row + 1, c.Column), _
                        xlS.Cells( _
                            xlS.Cells.SpecialCells(xlCellTypeLastCell).Row, _
                            c.Column _
                            ) _
                    )
                    
                ' проходим по колонке для поиска счет-фактур ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                ' имется ли диапазон листа выгрузки в виде колонки для поиска счет-фактур?
                If Not loadRange Is Nothing Then
                    ' да, диапазон листа выгрузки в виде колонки для поиска счет-фактур имеется
                    With loadRange
                        ' количество ячеек в диапазоне больше одной?
                        If .count > 1 Then
                            ' да, количество ячеек в диапазоне больше одной
                            iii = 0
                            For Each iR In loadRange.Cells
                            
                                ' имеется ли задолженнось в текущей ячейке?
                                If (IsEmpty(iR) = False And Not iR = "") _
                                    Or (IsEmpty(iR.Offset(0, -1)) = False And Not iR.Offset(0, -1) = "") _
                                    Or (IsEmpty(iR.Offset(0, -2)) = False And Not iR.Offset(0, -2) = "") _
                                    Or (IsEmpty(iR.Offset(0, -5)) = False And Not iR.Offset(0, -5) = "") _
                                    Then
                                    ' да, задолженнось в текущей ячейке имеется
                                    iii = iii + 1
                                    strF = "<P> <font color=""silver"">счет-фактура <font color=""Teal"">" & iR.value _
                                        & " <b>обнаружен</b></font> в книге</font>"
                                    
                                    ' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                    ' рассматриваем строку отдельной задолженности из выгрузки бухгалтерии Ф644
                                    ReceivablesTest iR, UnloadKey, AccountKey, cidufsKey, iii, rsFindCst, strF, FindDbtNum, _
                                        cidutCntrPrtNum_r, cidutCntrPrtName_r, cidutCntrPrtITN_r, cidutCnName_r, cidutCnDate_r, _
                                        cidutFormtnDate_r, cidutMatrtyDate_r, cidutDebt_r, cidutDebtOverdue_r, cidutDoc_r, _
                                        cidutLink_r
                                    ' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                    
                                    LoadingProgress = strF & LoadingProgress
                                    
                                    Else
                                    ' нет, задолженнось в текущей ячейке отсутствует
                                End If
                            Next
                            
                            Else
                            ' нет, количество ячеек в диапазоне не больше одной
                        End If ' здесь проверка на количество ячеек в диапазоне
                    End With
                    Else
                    ' нет, диапазон листа выгрузки в виде колонки для поиска счет-фактур отсутствует
                    LoadingProgress = "<P>  <font color=""silver"">Диапазон</font> *колонка для поиска счет-фактур* <font color=""red"">не найден</font>.</P>" _
                        & LoadingProgress
                End If ' проходим по колонке для поиска счет-фактур, окончание ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

            Else
            ' ячейка не найдены
            LoadingProgress = _
                "<P> <font color=""silver"">Все ячейки <b>необходимые для внесения задолженности</b> <font color=""red"">не найдены</font></font></P>" _
                & LoadingProgress
        End If

        
        ' освобождаем переменную листа
        Set xlS = Nothing
        Else
        ' нет, требуемый лист отсутствует
        LoadingProgress = "<P> Лист <font color=""Salmon"">" & WorkSheetName & " <b>не обнаружен</b>" & "</font> в книге*</P>" & LoadingProgress
    End If ' имеется ли требуемый лист, окончание ===================================================================================================

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

' рассматриваем строку отдельной задолженности из выгрузки бухгалтерии Ф644
Private Sub ReceivablesTest(ByRef cnInvRange As Range, _
    ByVal UnloadKey As Integer, ByVal AccountKey As Integer, ByVal cidufsKey As Integer, ByVal cidutSheetNum As Integer, _
    ByRef rsFindCst As DAO.Recordset, ByRef strF As String, ByRef FindDbtNum As Integer, _
    cidutCntrPrtNum_r As Range, cidutCntrPrtName_r As Range, cidutCntrPrtITN_r As Range, cidutCnName_r As Range, cidutCnDate_r As Range, _
    cidutFormtnDate_r As Range, cidutMatrtyDate_r As Range, cidutDebt_r As Range, cidutDebtOverdue_r As Range, cidutDoc_r As Range, _
    cidutLink_r As Range _
    )

    Const cstrTitle As String _
        = "Процедура *Рассматриваем строку отдельной задолженности из выгрузки бухгалтерии Ф644"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    FindDbtNum = FindDbtNum + 1

    With rsFindCst
        .AddNew
            !FindDbtNum = FindDbtNum
            !cidutAccount = AccountKey
            FieldInsertValue !cidutCntrPrtNum, cnInvRange.Offset(0, cidutCntrPrtNum_r.Column - cnInvRange.Column) 'cnInvRange.Offset(0, -3)
            FieldInsertValue !cidutCntrPrtName, cnInvRange.Offset(0, cidutCntrPrtName_r.Column - cnInvRange.Column) 'cnInvRange.Offset(0, -5)
            If Not cidutCntrPrtITN_r Is Nothing Then
                FieldInsertValue !cidutCntrPrtITN, cnInvRange.Offset(0, cidutCntrPrtITN_r.Column - cnInvRange.Column) 'cnInvRange.Offset(0, -4)
            End If
            FieldInsertValue !cidutCnName, cnInvRange.Offset(0, cidutCnName_r.Column - cnInvRange.Column) 'cnInvRange.Offset(0, -2)
            FieldInsertValue !cidutCnDate, cnInvRange.Offset(0, cidutCnDate_r.Column - cnInvRange.Column) 'cnInvRange.Offset(0, -1)
            FieldInsertValue !cidutCnInv, cnInvRange
            FieldInsertValue !cidutFormtnDate, cnInvRange.Offset(0, cidutFormtnDate_r.Column - cnInvRange.Column) 'cnInvRange.Offset(0, 1)
            FieldInsertValue !cidutMatrtyDate, cnInvRange.Offset(0, cidutMatrtyDate_r.Column - cnInvRange.Column) 'cnInvRange.Offset(0, 2)
            FieldInsertValue !cidutDebt, cnInvRange.Offset(0, cidutDebt_r.Column - cnInvRange.Column) 'cnInvRange.Offset(0, 3)
            FieldInsertValue !cidutDebtOverdue, cnInvRange.Offset(0, cidutDebtOverdue_r.Column - cnInvRange.Column) 'cnInvRange.Offset(0, 4)
            If Not cidutDoc_r Is Nothing Then
                FieldInsertValue !cidutDoc, cnInvRange.Offset(0, cidutDoc_r.Column - cnInvRange.Column) 'cnInvRange.Offset(0, 5)
            End If
            If Not cidutLink_r Is Nothing Then
                FieldInsertValue !cidutLink, cnInvRange.Offset(0, cidutLink_r.Column - cnInvRange.Column) 'cnInvRange.Offset(0, 6)
            End If
            !cidutSheet = cidufsKey
            !cidutSheetNum = cidutSheetNum
            !cidutUnloadKey = UnloadKey
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

'****************************************************************************************************************************************************
' создаём новый счёт-фактуру для найденного договора. 25.10.2022 ************************************************************************************
Private Sub btnInvAdd_Click()
    Dim strInvNum As String, lngCnKey As Long, invNew As Inv, cnInvNew As cnInv
    Const cstrTitle As String = "Процедура *Создаём новый счёт-фактуру для найденного договора*"
    '**************************************************************************************************************************************
On Error GoTo ErrHandler
    
    ' проверяем наличие договора
    If Me![CnInvDbtUpl>File_f>InvDouble].Form.Recordset.RecordCount > 0 Then
        If Me![CnInvDbtUpl>File_f>InvDouble].Form![cidufiCnKey] <> 0 Then
            ' договор есть
            lngCnKey = Me![CnInvDbtUpl>File_f>InvDouble].Form![cidufiCnKey]
            ' имеется ли номер счёта-фактуры?
            If Me![CnInvDbtUpl>File_f>InvDouble].Form![cidufiInvNum] <> "NullИлиПусто" Then
                ' да, номер счёта-фактуры имеется
                ' создаём счёт фактуру по номеру и дате
                strInvNum = Me![CnInvDbtUpl>File_f>InvDouble].Form![cidufiInvNum]
                Set invNew = ClassFactory.invCreateNewNumDate(strInvNum, Null, CurrentDb, "вручную, по кнопке для " & strInvNum & ", дебиторка")
            Else
                ' нет, номер счёта-фактуры отсутствует
                ' создаём счёт фактуру по дате
                Set invNew = ClassFactory.invCreateNewNumDate(Null, Null, CurrentDb, "вручную, по кнопке для *NullИлиПусто*")
            End If
            ' создаём новую связь инвойса и договора
            Set cnInvNew = ClassFactory.cnInvCreateNewInvCn(invNew.iKey, lngCnKey, CurrentDb, "вручную, по кнопке, дебиторка")
            
            ' освобождаем объекты счёта-фактуры и связи
            Set invNew = Nothing: Set cnInvNew = Nothing
            ' обновляем форму
            Me![CnInvDbtUpl>File_f>InvDouble].Form.Requery
        End If
    End If

NormalExit:
    Exit Sub
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
End Sub
' создаём новый счёт-фактуру для найденного договора. 25.10.2022. Окончание *************************************************************************
'****************************************************************************************************************************************************

' вносим значение в поле
Private Sub FieldInsertValue(ByRef FieldIns As DAO.Field, ByRef CellOut As Range)
    Dim ddLimTtl As Variant
    Const cstrTitle As String = "Процедура *Вносим значение в поле*"
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    If IsNull(CellOut) = False And IsEmpty(CellOut) = False _
        And Not CellOut = "" Then
        'If Not FieldOut = 0 Then
            'ddLimTtl = CDec(WorksheetFunction.Round(FieldOut, 8))
            FieldIns = CellOut
        'End If
    End If
                            
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
                            
End Sub


Private Sub btnCidufLoad1_Click()
MsgBox ("vvv")
End Sub

