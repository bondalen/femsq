VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_yr"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Declare Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)

' получаем таблицу результатов варианта года 27.12.2021 09:59 ***************************************************************************************
Private Sub btnYrResult_Click()

    Dim dStart As Date, dFinish As Date
    Dim strSql As String
    Dim db As DAO.Database, qd As DAO.QueryDef, rs As DAO.Recordset, nnn As Integer, tb As DAO.TableDef, fl As DAO.Field
    Dim strDrop As String

    Const cstrTitle As String _
        = "Процедура *Получаем таблицу по результатам варианта года*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

' загружаем основную часть таблицы
' имеется ли ключ варианта года?
If IsNull(Me!yr_key) = False Then
    ' да, ключ варианта года имеется
    Me!yr_Progress = "": dStart = DateTime.Now
    
    Me!yr_Progress = "<P>Начало работы с вариантом года *<B><font color=""DarkGoldenrod"">" & Me!yr_variant & "</font></B>*." _
    & " <B>" & dStart & "</B> - Время начала работы.</P>"
    
    Sleep 1000
    
    Set db = CurrentDb 'открываем переменную базы данных --------------------------------------------------------------------------------------------
    
    ' заполняем постоянную часть таблицы
    ' очищаем таблицу результатов варианта года
    strSql = "DELETE * FROM ags_Yr_DbtTbl": Set qd = db.CreateQueryDef("", strSql): qd.Execute dbFailOnError
    qd.Close: Set qd = Nothing
    
    ' очищаем таблицу от временных полей
    Set tb = db.TableDefs("ags_Yr_DbtTbl")
    For Each fl In tb.Fields
        If Left(fl.name, 6) = "tmpFl_" Then
            'tb.Fields.Delete fl.name
            
            strDrop = "alter table ags_Yr_DbtTbl drop column [" & fl.name & "]"
            db.Execute strDrop, dbFailOnError
        End If
    Next
    Set tb = Nothing
    
    ' изменяем запрос к серверу
    strSql = "exec ags.Yr_Dbt " & Me!yr_key: Set qd = db.QueryDefs("ags_Yr_Dbt"): qd.SQL = strSql
    qd.Close: Set qd = Nothing

    ' заполняем постоянную часть таблицы результатов варианта года
    strSql = "insert into ags_Yr_DbtTbl select * from ags_Yr_Dbt"
    Set qd = db.CreateQueryDef("", strSql): qd.ODBCTimeout = 600: qd.Execute dbFailOnError
    qd.Close: Set qd = Nothing
    
    
    ' имеется ли ключ группы комментариев
    If IsNull(Me!yr_CmmGr) = False Then
        ' да, ключ группы комментариев имеется
        ' добавляем поля комментариев
        fieldsCmmAdd db, Me!yr_CmmGr, Me!yr_Progress
        ' добавляем поля агентов
        fieldsCmmAgAdd db, Me!yr_CmmGr, Me!yr_Progress
        ' добавляем поля строек
        fieldsCmmCstAdd db, Me!yr_CmmGr, Me!yr_Progress
        ' добавляем поля дат
        fieldsCmmDtAdd db, Me!yr_CmmGr, Me!yr_Progress
        ' добавляем поля денег
        fieldsCmmFnAdd db, Me!yr_CmmGr, Me!yr_Progress
        ' добавляем поля групп
        fieldsCmmGrAdd db, Me!yr_CmmGr, Me!yr_Progress
        
        Else
        ' нет, ключ группы комментариев отсутствует
        Me!yr_Progress = "<p><font color=""Salmon"">Отсутствует ключ группы комментариев.</font></p>" & Me!yr_Progress
    End If

    db.Close 'закрываем переменную базы данных ------------------------------------------------------------------------------------------------------

    dFinish = DateTime.Now: dDateDiff = DateDiff("s", dStart, dFinish)

    Me!yr_Progress = "<P>В " & dFinish & " - *<B><font color=""blue"">" & "работа с вариантом года завершена" _
    & "</font></B>*. C " & dStart & " в течении " & dDateDiff \ 60 & " мин. " & dDateDiff - ((dDateDiff \ 60) * 60) & " сек., (всего " _
    & dDateDiff & " сек.).</P>" & Me!yr_Progress
    
    'Me![ra_a>Ttl_t].Requery
    
    Else
    ' нет, ключ варианта года отсутствует
    MsgBox ("Отсутствует ключ варианта года")

End If

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' получаем таблицу результатов варианта года, окончание *********************************************************************************************


' обрезаем имя поля до 64-х знаков 28.12.2021 09:49 *************************************************************************************************
Private Function FieldName60(strName As String, intOffset As Integer) As String

Dim halfff As Integer, strRslt As String

' длина строки более 64-х знаков минус смещение?
If Len(strName) > (60 - intOffset) Then
    ' да, длина строки более 64-х знаков минус смещение
    ' берем половину строки целочисленным делением
    halfff = (60 - intOffset) \ 2
    strRslt = Left(strName, halfff) & "~" & Right(strName, halfff)
    If Len(strRslt) < (60 - intOffset) Then
        FieldName60 = strRslt
        Else
        FieldName60 = Left(strRslt, 60 - intOffset)
    End If
    Else
    ' нет, длина строки не болееболее 64-х знаков минус смещение
    FieldName60 = strName
End If

End Function
' обрезаем имя поля до 64-х знаков, окончание *******************************************************************************************************


' добавляем поля групп 28.12.2021 11:03 *************************************************************************************************************
Private Sub fieldsCmmGrAdd(ByRef db As DAO.Database, ByVal yr_CmmGr As Long, ByRef yr_Progress As Object)

    Dim strSql As String
    Dim qd As DAO.QueryDef, rs As DAO.Recordset, nnn As Integer, tb As DAO.TableDef, fl As DAO.Field
    Dim r2 As DAO.Recordset, strValue As String, r3 As DAO.Recordset, longValue As Long

    Const cstrTitle As String _
        = "Процедура *Добавляем поля групп*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' добавляем поля групп
    ' открываем перекрестный запрос групп
    Set qd = db.QueryDefs("ags_Yr_DbtGr")
    qd.Parameters("gr") = yr_CmmGr
    Set rs = qd.OpenRecordset
    nnn = rs.Fields.count
    ' имеются поля для добавления в таблицу?
    If nnn > 1 Then
        ' да, поля для добавления в таблицу имеются
        yr_Progress = "<p><font color=""CadetBlue"">Имеются поля групп для добавления в таблицу.</font> (" & nnn - 1 & ").</p>" & yr_Progress
        Set tb = db.TableDefs("ags_Yr_DbtTbl")
        ' проходим по полям, кроме первого
        For i = 1 To nnn - 1
            Set fl = tb.CreateField("tmpFl_" & FieldName60(rs.Fields(i).name, 6), dbText)
            'fl.Properties.Append fl.CreateProperty("Description", dbText, rs.Fields(i).name)
            'fl.Properties("description") = rs.Fields(i).name
            tb.Fields.Append fl
            Set fl = Nothing
            yr_Progress = "<p><font color=""Silver"">" & i & ". Поле: <font color=""DarkGreen"">" & rs.Fields(i).name _
                & "</font> добавлено в таблицу.</font></p>" & yr_Progress
        Next
        Set tb = Nothing
        
        ' добавляем данные
        ' имеются записи в наборе?
        If rs.RecordCount > 0 Then
            ' да, записи в наборе имеются
            ' открываем таблицу для обновления
            Set r3 = db.OpenRecordset("ags_Yr_DbtTbl", dbOpenDynaset)
            ' переходим к первой записи
            rs.MoveFirst
            Do Until rs.EOF = True
                ' проходим по полям записи набора
                For i = 1 To nnn - 1
                    ' имеется ли значение в поле?
                    If IsNull(rs.Fields(i).value) = False Then
                        ' да, значение в поле имеется
                        
                        ' обновляем значение даты в итоговой таблице
                        r3.FindFirst "dsCia = " & rs!cnigInvAccnt
                        ' имеются совпадения по ключу задолженности?
                        If r3.NoMatch = False Then
                            ' да, совпадения по ключу задолженности имеются
                            r3.Edit
                                r3.Fields("tmpFl_" & FieldName60(rs.Fields(i).name, 6)).value = rs.Fields(i).value
                            r3.Update
                            Else
                            ' нет, совпадения по ключу задолженности отсутствуют
                        End If
                    End If
                Next
                ' переходим к следующей записи
                rs.MoveNext
            Loop
            r3.Close: Set r3 = Nothing
        End If
        Else
        ' поля для добавления в таблицу отсутствуют
        yr_Progress = "<p><font color=""Salmon"">Отсутствует поля групп для добавления в таблицу.</font></p>" & yr_Progress
    End If
    rs.Close: Set rs = Nothing
    qd.Close: Set qd = Nothing

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' добавляем поля групп, окончание *******************************************************************************************************************



' добавляем поля денег 27.12.2021 17:24 *************************************************************************************************************
Private Sub fieldsCmmFnAdd(ByRef db As DAO.Database, ByVal yr_CmmGr As Long, ByRef yr_Progress As Object)

    Dim strSql As String
    Dim qd As DAO.QueryDef, rs As DAO.Recordset, nnn As Integer, tb As DAO.TableDef, fl As DAO.Field
    Dim r2 As DAO.Recordset, strValue As String, r3 As DAO.Recordset, longValue As Long

    Const cstrTitle As String _
        = "Процедура *Добавляем поля денег*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' добавляем поля денег
    ' открываем перекрестный запрос денег
    Set qd = db.QueryDefs("ags_Yr_DbtFn")
    qd.Parameters("gr") = yr_CmmGr
    Set rs = qd.OpenRecordset
    nnn = rs.Fields.count
    ' имеются поля для добавления в таблицу?
    If nnn > 1 Then
        ' да, поля для добавления в таблицу имеются
        yr_Progress = "<p><font color=""CadetBlue"">Имеются поля денег для добавления в таблицу.</font> (" & nnn - 1 & ").</p>" & yr_Progress
        Set tb = db.TableDefs("ags_Yr_DbtTbl")
        ' проходим по полям, кроме первого FieldName64(rs.Fields(i).name, 6)
        For i = 1 To nnn - 1
            Set fl = tb.CreateField("tmpFl_" & FieldName60(rs.Fields(i).name, 6), dbCurrency)
            'fl.Properties.Append fl.CreateProperty("Description", dbText, rs.Fields(i).name)
            'fl.Properties("description") = rs.Fields(i).name
            tb.Fields.Append fl
            Set fl = Nothing
            yr_Progress = "<p><font color=""Silver"">" & i & ". Поле: <font color=""DarkGreen"">" & rs.Fields(i).name _
                & "</font> добавлено в таблицу.</font></p>" & yr_Progress
        Next
        Set tb = Nothing
        
        ' добавляем данные
        ' имеются записи в наборе?
        If rs.RecordCount > 0 Then
            ' да, записи в наборе имеются
            ' открываем таблицу для обновления
            Set r3 = db.OpenRecordset("ags_Yr_DbtTbl", dbOpenDynaset)
            ' переходим к первой записи
            rs.MoveFirst
            Do Until rs.EOF = True
                ' проходим по полям записи набора
                For i = 1 To nnn - 1
                    ' имеется ли значение в поле?
                    If IsNull(rs.Fields(i).value) = False Then
                        ' да, значение в поле имеется
                        
                        ' обновляем значение даты в итоговой таблице
                        r3.FindFirst "dsCia = " & rs!cnicfInvAccnt
                        ' имеются совпадения по ключу задолженности?
                        If r3.NoMatch = False Then
                            ' да, совпадения по ключу задолженности имеются
                            r3.Edit
                                r3.Fields("tmpFl_" & FieldName60(rs.Fields(i).name, 6)).value = rs.Fields(i).value
                            r3.Update
                            Else
                            ' нет, совпадения по ключу задолженности отсутствуют
                        End If
                    End If
                Next
                ' переходим к следующей записи
                rs.MoveNext
            Loop
            r3.Close: Set r3 = Nothing
        End If
        Else
        ' поля для добавления в таблицу отсутствуют
        yr_Progress = "<p><font color=""Salmon"">Отсутствует поля денег для добавления в таблицу.</font></p>" & yr_Progress
    End If
    rs.Close: Set rs = Nothing
    qd.Close: Set qd = Nothing

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' добавляем поля денег, окончание *******************************************************************************************************************



' добавляем поля дат 27.12.2021 16:48 ***************************************************************************************************************
Private Sub fieldsCmmDtAdd(ByRef db As DAO.Database, ByVal yr_CmmGr As Long, ByRef yr_Progress As Object)

    Dim strSql As String
    Dim qd As DAO.QueryDef, rs As DAO.Recordset, nnn As Integer, tb As DAO.TableDef, fl As DAO.Field
    Dim r2 As DAO.Recordset, strValue As String, r3 As DAO.Recordset, longValue As Long

    Const cstrTitle As String _
        = "Процедура *Добавляем поля дат"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' добавляем поля комментариев
    ' открываем перекрестный запрос дат
    Set qd = db.QueryDefs("ags_Yr_DbtDtT")
    qd.Parameters("gr") = yr_CmmGr
    Set rs = qd.OpenRecordset
    nnn = rs.Fields.count
    ' имеются поля для добавления в таблицу?
    If nnn > 1 Then
        ' да, поля для добавления в таблицу имеются
        yr_Progress = "<p><font color=""CadetBlue"">Имеются поля дат для добавления в таблицу.</font> (" & nnn - 1 & ").</p>" & yr_Progress
        Set tb = db.TableDefs("ags_Yr_DbtTbl")
        ' проходим по полям, кроме первого
        For i = 1 To nnn - 1
            ' имя поля - не более 64 знаков
            Set fl = tb.CreateField("tmpFl_" & rs.Fields(i).name, dbDate)
            'fl.CreateProperty ("description")
            'fl.Properties("description") = rs.Fields(i).name
            tb.Fields.Append fl
            Set fl = Nothing
            yr_Progress = "<p><font color=""Silver"">" & i & ". Поле: <font color=""DarkGreen"">" & rs.Fields(i).name _
                & "</font> добавлено в таблицу.</font></p>" & yr_Progress
        Next
        Set tb = Nothing
        
        ' добавляем данные
        ' имеются записи в наборе?
        If rs.RecordCount > 0 Then
            ' да, записи в наборе имеются
            ' открываем таблицу для обновления
            Set r3 = db.OpenRecordset("ags_Yr_DbtTbl", dbOpenDynaset)
            ' переходим к первой записи
            rs.MoveFirst
            Do Until rs.EOF = True
                ' проходим по полям записи набора
                For i = 1 To nnn - 1
                    ' имеется ли значение в поле?
                    If IsNull(rs.Fields(i).value) = False Then
                        ' да, значение в поле имеется
                        
                        ' обновляем значение даты в итоговой таблице
                        r3.FindFirst "dsCia = " & rs!cnicdInvAccnt
                        ' имеются совпадения по ключу задолженности?
                        If r3.NoMatch = False Then
                            ' да, совпадения по ключу задолженности имеются
                            r3.Edit
                                r3.Fields("tmpFl_" & rs.Fields(i).name).value = rs.Fields(i).value
                            r3.Update
                            Else
                            ' нет, совпадения по ключу задолженности отсутствуют
                        End If
                    End If
                Next
                ' переходим к следующей записи
                rs.MoveNext
            Loop
            r3.Close: Set r3 = Nothing
        End If
        Else
        ' поля для добавления в таблицу отсутствуют
        yr_Progress = "<p><font color=""Salmon"">Отсутствует поля дат для добавления в таблицу.</font></p>" & yr_Progress
    End If
    rs.Close: Set rs = Nothing
    qd.Close: Set qd = Nothing

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' добавляем поля дат, окончание *********************************************************************************************************************



' добавляем поля строек 27.12.2021 16:07 ************************************************************************************************************
Private Sub fieldsCmmCstAdd(ByRef db As DAO.Database, ByVal yr_CmmGr As Long, ByRef yr_Progress As Object)

    Dim strSql As String
    Dim qd As DAO.QueryDef, rs As DAO.Recordset, nnn As Integer, tb As DAO.TableDef, fl As DAO.Field
    Dim r2 As DAO.Recordset, strValue As String, r3 As DAO.Recordset, longValue As Long

    Const cstrTitle As String _
        = "Процедура *Добавляем поля строек"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' добавляем поля комментариев
    ' открываем перекрестный запрос строек
    Set qd = db.QueryDefs("ags_Yr_DbtCst")
    qd.Parameters("gr") = yr_CmmGr
    Set rs = qd.OpenRecordset
    nnn = rs.Fields.count
    ' имеются поля для добавления в таблицу?
    If nnn > 1 Then
        ' да, поля для добавления в таблицу имеются
        yr_Progress = "<p><font color=""CadetBlue"">Имеются поля строек для добавления в таблицу.</font> (" & nnn - 1 & ").</p>" & yr_Progress
        Set tb = db.TableDefs("ags_Yr_DbtTbl")
        ' проходим по полям, кроме первого
        For i = 1 To nnn - 1
            Set fl = tb.CreateField("tmpFl_" & rs.Fields(i).name, dbText)
            'fl.CreateProperty ("description")
            'fl.Properties("description") = rs.Fields(i).name
            tb.Fields.Append fl
            Set fl = Nothing
            yr_Progress = "<p><font color=""Silver"">" & i & ". Поле: <font color=""DarkGreen"">" & rs.Fields(i).name _
                & "</font> добавлено в таблицу.</font></p>" & yr_Progress
        Next
        Set tb = Nothing
        
        ' добавляем данные
        ' имеются записи в наборе?
        If rs.RecordCount > 0 Then
            ' да, записи в наборе имеются
            ' открываем таблицу для обновления
            Set r3 = db.OpenRecordset("ags_Yr_DbtTbl", dbOpenDynaset)
            ' переходим к первой записи
            rs.MoveFirst
            Do Until rs.EOF = True
                ' проходим по полям записи набора
                For i = 1 To nnn - 1
                    ' имеется ли значение в поле?
                    If IsNull(rs.Fields(i).value) = False Then
                        ' да, значение в поле имеется
                        ' получаем значение стройки
                        strSql = "select ciccCstAgPn from ags_cnInvCmmCst where ciccKey = " & rs.Fields(i).value
                        Set r2 = db.OpenRecordset(strSql, dbOpenSnapshot)
                        longValue = r2.Fields("ciccCstAgPn").value
                        r2.Close: Set r2 = Nothing
                        
                        strSql = "select cstAgPnNm from ags_cstAgPnCs where cstapKey = " & longValue
                        Set r2 = db.OpenRecordset(strSql, dbOpenSnapshot)
                        strValue = r2.Fields("cstAgPnNm").value
                        r2.Close: Set r2 = Nothing
                        
                        ' обновляем значение стройки в итоговой таблице
                        r3.FindFirst "dsCia = " & rs!ciccInvAccnt
                        ' имеются совпадения по ключу задолженности?
                        If r3.NoMatch = False Then
                            ' да, совпадения по ключу задолженности имеются
                            r3.Edit
                                r3.Fields("tmpFl_" & rs.Fields(i).name).value = strValue
                            r3.Update
                            Else
                            ' нет, совпадения по ключу задолженности отсутствуют
                        End If
                    End If
                Next
                ' переходим к следующей записи
                rs.MoveNext
            Loop
            r3.Close: Set r3 = Nothing
        End If
        Else
        ' поля для добавления в таблицу отсутствуют
        yr_Progress = "<p><font color=""Salmon"">Отсутствует поля строек для добавления в таблицу.</font></p>" & yr_Progress
    End If
    rs.Close: Set rs = Nothing
    qd.Close: Set qd = Nothing

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' добавляем поля строек, окончание *****************************************************************************************************************



' добавляем поля агентов 27.12.2021 15:55 ***********************************************************************************************************
Private Sub fieldsCmmAgAdd(ByRef db As DAO.Database, ByVal yr_CmmGr As Long, ByRef yr_Progress As Object)

    Dim strSql As String
    Dim qd As DAO.QueryDef, rs As DAO.Recordset, nnn As Integer, tb As DAO.TableDef, fl As DAO.Field
    Dim r2 As DAO.Recordset, strValue As String, r3 As DAO.Recordset, longValue As Long

    Const cstrTitle As String _
        = "Процедура *Добавляем поля агентов"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' добавляем поля комментариев
    ' открываем перекрестный запрос комментариев
    Set qd = db.QueryDefs("ags_Yr_DbtAg")
    qd.Parameters("gr") = yr_CmmGr
    Set rs = qd.OpenRecordset
    nnn = rs.Fields.count
    ' имеются поля для добавления в таблицу?
    If nnn > 1 Then
        ' да, поля для добавления в таблицу имеются
        yr_Progress = "<p><font color=""CadetBlue"">Имеются поля агентов для добавления в таблицу.</font> (" & nnn - 1 & ").</p>" & yr_Progress
        Set tb = db.TableDefs("ags_Yr_DbtTbl")
        ' проходим по полям, кроме первого
        For i = 1 To nnn - 1
            Set fl = tb.CreateField("tmpFl_" & rs.Fields(i).name, dbText)
            'fl.CreateProperty ("description")
            'fl.Properties("description") = rs.Fields(i).name
            tb.Fields.Append fl
            Set fl = Nothing
            yr_Progress = "<p><font color=""Silver"">" & i & ". Поле: <font color=""DarkGreen"">" & rs.Fields(i).name _
                & "</font> добавлено в таблицу.</font></p>" & yr_Progress
        Next
        Set tb = Nothing
        
        ' добавляем данные
        ' имеются записи в наборе?
        If rs.RecordCount > 0 Then
            ' да, записи в наборе имеются
            ' открываем таблицу для обновления
            Set r3 = db.OpenRecordset("ags_Yr_DbtTbl", dbOpenDynaset)
            ' переходим к первой записи
            rs.MoveFirst
            Do Until rs.EOF = True
                ' проходим по полям записи набора
                For i = 1 To nnn - 1
                    ' имеется ли значение в поле?
                    If IsNull(rs.Fields(i).value) = False Then
                        ' да, значение в поле имеется
                        ' получаем значение комментария
                        strSql = "select cicaOgAg from ags_cnInvCmmAg where cicaKey = " & rs.Fields(i).value
                        Set r2 = db.OpenRecordset(strSql, dbOpenSnapshot)
                        longValue = r2.Fields("cicaOgAg").value
                        r2.Close: Set r2 = Nothing
                        
                        strSql = "select ogaNm from ags_ogAgCs where ogaKey = " & longValue
                        Set r2 = db.OpenRecordset(strSql, dbOpenSnapshot)
                        strValue = r2.Fields("ogaNm").value
                        r2.Close: Set r2 = Nothing
                        
                        ' обновляем значение комментария в итоговой таблице
                        r3.FindFirst "dsCia = " & rs!cicaInvAccnt
                        ' имеются совпадения по ключу задолженности?
                        If r3.NoMatch = False Then
                            ' да, совпадения по ключу задолженности имеются
                            r3.Edit
                                r3.Fields("tmpFl_" & rs.Fields(i).name).value = strValue
                            r3.Update
                            Else
                            ' нет, совпадения по ключу задолженности отсутствуют
                        End If
                    End If
                Next
                ' переходим к следующей записи
                rs.MoveNext
            Loop
            r3.Close: Set r3 = Nothing
        End If
        Else
        ' поля для добавления в таблицу отсутствуют
        yr_Progress = "<p><font color=""Salmon"">Отсутствует поля агентов для добавления в таблицу.</font></p>" & yr_Progress
    End If
    rs.Close: Set rs = Nothing
    qd.Close: Set qd = Nothing

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' добавляем поля агентов, окончание *****************************************************************************************************************


' добавляем поля комментариев 27.12.2021 14:53 ******************************************************************************************************
Private Sub fieldsCmmAdd(ByRef db As DAO.Database, ByVal yr_CmmGr As Long, ByRef yr_Progress As Object)

    Dim strSql As String
    Dim qd As DAO.QueryDef, rs As DAO.Recordset, nnn As Integer, tb As DAO.TableDef, fl As DAO.Field
    Dim r2 As DAO.Recordset, strValue As String, r3 As DAO.Recordset

    Const cstrTitle As String _
        = "Процедура *Добавляем поля комментариев"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' добавляем поля комментариев
    ' открываем перекрестный запрос комментариев
    Set qd = db.QueryDefs("ags_Yr_DbtCmm")
    qd.Parameters("gr") = yr_CmmGr
    Set rs = qd.OpenRecordset
    nnn = rs.Fields.count
    ' имеются поля для добавления в таблицу?
    If nnn > 1 Then
        ' да, поля для добавления в таблицу имеются
        yr_Progress = "<p><font color=""CadetBlue"">Имеются поля комментариев для добавления в таблицу.</font> (" & nnn - 1 & ").</p>" & yr_Progress
        Set tb = db.TableDefs("ags_Yr_DbtTbl")
        ' проходим по полям, кроме первого
        For i = 1 To nnn - 1
            'MsgBox (rs.Fields(i).name)
            Set fl = tb.CreateField("tmpFl_" & rs.Fields(i).name, dbMemo)
            'fl.CreateProperty ("description")
            'fl.Properties("description") = rs.Fields(i).name
            tb.Fields.Append fl
            Set fl = Nothing
            yr_Progress = "<p><font color=""Silver"">" & i & ". Поле: <font color=""DarkGreen"">" & rs.Fields(i).name _
                & "</font> добавлено в таблицу.</font></p>" & yr_Progress
        Next
        Set tb = Nothing
        
        ' добавляем данные
        ' имеются записи в наборе?
        If rs.RecordCount > 0 Then
            ' да, записи в наборе имеются
            ' открываем таблицу для обновления
            Set r3 = db.OpenRecordset("ags_Yr_DbtTbl", dbOpenDynaset)
            ' переходим к первой записи
            rs.MoveFirst
            Do Until rs.EOF = True
                ' проходим по полям записи набора
                For i = 1 To nnn - 1
                    ' имеется ли значение в поле?
                    If IsNull(rs.Fields(i).value) = False Then
                        ' да, значение в поле имеется
                        ' получаем значение комментария
                        strSql = "select cnicText from ags_cnInvCmm where cnicKey = " & rs.Fields(i).value
                        Set r2 = db.OpenRecordset(strSql, dbOpenSnapshot)
                        strValue = r2.Fields("cnicText").value
                        r2.Close: Set r2 = Nothing
                        ' обновляем значение комментария в итоговой таблице
                        r3.FindFirst "dsCia = " & rs!cnicInvAccnt
                        ' имеются совпадения по ключу задолженности?
                        If r3.NoMatch = False Then
                            ' да, совпадения по ключу задолженности имеются
                            r3.Edit
                                r3.Fields("tmpFl_" & rs.Fields(i).name).value = strValue
                            r3.Update
                            Else
                            ' нет, совпадения по ключу задолженности отсутствуют
                        End If
                    End If
                Next
                ' переходим к следующей записи
                rs.MoveNext
            Loop
            r3.Close: Set r3 = Nothing
        End If
        Else
        ' поля для добавления в таблицу отсутствуют
        yr_Progress = "<p><font color=""Salmon"">Отсутствует поля комментариев для добавления в таблицу.</font></p>" & yr_Progress
    End If
    rs.Close: Set rs = Nothing
    qd.Close: Set qd = Nothing

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' добавляем поля комментариев, окончание ************************************************************************************************************

