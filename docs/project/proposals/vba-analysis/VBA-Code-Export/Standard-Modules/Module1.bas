Attribute VB_Name = "Module1"
Option Compare Database

' определяем первый или последний дни месяца
Function GetDay(dat As Date, typ As String) As Date
    If typ = "First" Then
        GetDay = DateSerial(year(dat), Month(dat), 1)
    Else
        GetDay = DateSerial(year(dat), Month(dat) + 1, 0)
    End If
End Function

' ***********************************************************************************************************
' Для объектов "стройка-агент-код", имеющих освоение сверх лимита и вне Инвестпрограммы возвращаем отчёты
Sub RefreshFnCstapOverIpg(ByVal cstap As Integer, ByVal yearIpg As Integer)

    Const cstrTitle As String _
    = "Module1. Процедура RefreshFnCstapOverIpg *Для объектов стройка-агент-код, имеющих освоение сверх лимита и вне Инвестпрограммы возвращаем отчёты*"

    Dim db As DAO.Database
    Dim qdf As DAO.QueryDef

On Error GoTo ErrHandler
' ===========================================================================================================

    Set db = CurrentDb
    
        Set qdf = db.QueryDefs("ags_fnCstapOverIpg")
'            qdf.SQL = "select yyyy, mNum, p" & _
'                ", cstaKey, cstaAg, cstaCst" & _
'                ", ogaNm, cstapKey, cstapIpgPnN" & _
'                ", ra_key, ra_num, ra_date, ra_type, raChKey, raChNum, raChDate" & _
'                ", ra_org_sender, ogNm, ras_total, ras_work, ras_equip, ras_others" & _
'                ", ra_arrived, ra_arrived_date, ra_returned, ra_returned_date, ra_sent, ra_sent_date from ags.fnRRcList(" & cstKey & ")"
        
            qdf.SQL = "select " & _
                "ra_key, ra_num, ra_date, ra_cac, ra_type, ra_work_type, ra_period, ra_arrived" & _
                ", ra_arrived_date, ra_arrived_dateFact, ra_returned" & _
                ", ra_returned_date , ra_returnedReason, ra_sent, ra_sent_date, ra_note_t" & _
                ", ra_created, ra_org_sender, ra_note, ra_datePeriod" & _
                " from ags.fnCstapOverIpg(" & cstap & ", " & yearIpg & ")"
        
        qdf.Close
        Set qdf = Nothing
        
    db.Close
    Set db = Nothing

' ===========================================================================================================
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "№ ошибки: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' Для объектов "стройка-агент-код", имеющих освоение сверх лимита и вне Инвестпрограммы возвращаем отчёты. Окончание
' ***********************************************************************************************************


' обновляем источники данных для освоения по стройке и графиков
Sub RefreshCstChart(cstKey As Integer)

    Const cstrTitle As String _
    = "Module1. Процедура RefreshCstChart *Обновляем источники данных для освоения по стройке и графиков*"
    
    Dim db As DAO.Database
    Dim qdf As DAO.QueryDef
    Dim rs As DAO.Recordset
    Dim iii As Integer
    
On Error GoTo ErrHandler
    
    Set db = CurrentDb
    
        Set qdf = db.QueryDefs("ags_fnRRcList")
            qdf.SQL = "select yyyy, mNum, p" & _
                ", cstaKey, cstaAg, cstaCst" & _
                ", ogaNm, cstapKey, cstapIpgPnN" & _
                ", ra_key, ra_num, ra_date, ra_type, raChKey, raChNum, raChDate" & _
                ", ra_org_sender, ogNm, ras_total, ras_work, ras_equip, ras_others" & _
                ", ra_arrived, ra_arrived_date, ra_returned, ra_returned_date, ra_sent, ra_sent_date from ags.fnRRcList(" & cstKey & ")"
        qdf.Close
        Set qdf = Nothing
        
        Set qdf = db.QueryDefs("ags_fnRRcListUtil")
            qdf.SQL = "select dateRslt, agent, cstapIpgPnN, ra_type, sender, costsType, " & _
                "costsSumm, costsSummAccum, sortAgent, sortType from  ags.fnRRcListUtil(" & cstKey & ")"
        qdf.Close
        Set qdf = Nothing
        
        ' проверяем наличие освоения
        Set qdf = db.QueryDefs("ags_fnRRcListUtil")
            Set rs = qdf.OpenRecordset()
            If rs.EOF = False Then
                rs.MoveLast
                iii = rs.RecordCount
            End If
            rs.Close
        qdf.Close
        Set qdf = Nothing
        
        ' имеется освоение?
        If iii > 0 Then
            ' да, освоение имеется
            ' тогда обновляем источник данных для графика
            Set qdf = db.QueryDefs("ags_fnRRcListUtil_Ch")
            qdf.SQL = "select dateRslt, agent, cstapIpgPnN, ra_type, sender, costsType, " & _
                "costsSumm, costsSummAccum, sortAgent, sortType, " & cstKey & "as cst from  ags.fnRRcListUtil(" & cstKey & ")"
            qdf.Close
            Set qdf = Nothing
        End If
        
    db.Close
    Set db = Nothing
    
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "№ ошибки: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

Function WorksheetIsExist(xlW As Excel.Workbook, WorkSheetName As String) As Boolean
On Error Resume Next
    WorksheetIsExist = (TypeOf xlW.Worksheets(WorkSheetName) Is Worksheet)
End Function

' отыскиваем на сервере ключи объектов и строковые величины для них
Function FindOneKey(ByRef db As DAO.Database, ByVal StringFindSv As String, ByVal KeyFieldName As String, ByRef key As Integer, _
    Optional ByVal KeyFieldName2 As String = "Empty", Optional ByVal KeyFieldName3 As String = "Empty", _
    Optional ByRef key2 As Variant, Optional ByRef key3 As Variant, _
    Optional ByRef strValueField As String = "Empty", Optional ByRef strValue2Field As String = "Empty", Optional ByRef strValue3Field As String = "Empty", _
    Optional ByRef strValue As String = "Empty", Optional ByRef strValue2 As String = "Empty", Optional ByRef strValue3 As String = "Empty", _
    Optional dbKind As String = "msSql" _
    ) As Boolean
    ' dbKind - указываем где искать. По умолчанию в msSql. Если любые другие строки - то в Access
    
    ' может вернуть из одной строки запроса от одного до трёх ключей и от одного до трёх полей

    Dim qdFindSv As DAO.QueryDef, rsFindSv As DAO.Recordset ' для поиска в SQL сервере

    Const cstrTitle As String _
        = "Процедура *Отыскиваем на сервере ключи объектов и строковые величины для них*"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    FindOneKey = False
    
    ' требуется искать в msSql?
    If dbKind = "msSql" Then
        ' да, требуется искать в msSql
        Set qdFindSv = db.QueryDefs("ags_PdSdRRcList")
        qdFindSv.SQL = StringFindSv
        Set rsFindSv = qdFindSv.OpenRecordset(dbOpenSnapshot)
        ' закрываем запрос
        qdFindSv.Close: Set qdFindSv = Nothing
        Else
        ' нет, не требуется искать в msSql
        ' тогда ищем в Access
        Set rsFindSv = db.OpenRecordset(StringFindSv, dbOpenSnapshot)
    End If

    If rsFindSv.RecordCount = 1 Then
        ' имеется ли значение ключевого поля?
        If IsNull(rsFindSv.Fields(KeyFieldName).value) = False Then
            ' да, значение ключевого поля имеется
            key = rsFindSv.Fields(KeyFieldName).value
            If Not KeyFieldName2 = "Empty" And IsMissing(key2) = False Then
                key2 = rsFindSv.Fields(KeyFieldName2).value
            End If
            If Not KeyFieldName3 = "Empty" And IsMissing(key3) = False Then
                key3 = rsFindSv.Fields(KeyFieldName3).value
            End If
            If Not strValueField = "Empty" And Not strValue = "Empty" Then
                strValue = rsFindSv.Fields(strValueField).value
            End If
            If Not strValue2Field = "Empty" And Not strValue2 = "Empty" Then
                strValue2 = rsFindSv.Fields(strValue2Field).value
            End If
            If Not strValue3Field = "Empty" And Not strValue3 = "Empty" Then
                strValue3 = rsFindSv.Fields(strValue3Field).value
            End If
            FindOneKey = True
        End If
    End If
    ' закрываем набор записей
    rsFindSv.Close: Set rsFindSv = Nothing:

NormalExit:
    Exit Function
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle _
        & " . Ищем: " & StringFindSv _
        , vbExclamation, cstrTitle
    Resume NormalExit

End Function

' отыскиваем стройку (объект САК) в базе данных. Имеется ли стройка в базе данных?
Function FindCstAP(ByVal cstCodeStr As String, ByRef cstapKey As Long, _
    ByRef db As DAO.Database, Optional ByRef rstC_A_C As Variant) As Boolean
    ' первичный ключ объекта стройка-агент-пункт *cstapKey* и набор записей, содержащий стройку *rstC_A_C* ВОЗВРАЩАЕМ
    ' ByRef rstC_A_C As DAO.Recordset
    
    Dim qdString As String, rsCstAgPn As DAO.Recordset
    Dim qdFindSv As DAO.QueryDef, StringFindSv As String, rsFindSv As DAO.Recordset ' для поиска в SQL сервере
        
    Const cstrTitle As String _
        = "Процедура *Отыскиваем стройку (объект САК) в базе данных*"

    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler
        
        cstapKey = 0
        
        ' пробуем отыскать стройку
        Set qdFindSv = db.QueryDefs("ags_PdSdRRcList")
        StringFindSv = "select * from ags.cstAgPn where  cstapIpgPnN = '" & cstCodeStr & "'"
        qdFindSv.SQL = StringFindSv
        Set rsFindSv = qdFindSv.OpenRecordset()
        ' имеется ли хотя бы одна запись стройки?
        If rsFindSv.RecordCount > 0 Then
            ' да, хотя бы одна запись агента стройки
            rsFindSv.MoveFirst
            cstapKey = rsFindSv!cstapKey
            FindCstAP = True
            Else
            ' нет, стройка в базе данных отсутствует
            FindCstAP = False
        End If
            
        ' нужен ли вызывающему функцию коду рекордсет со стройкой?
        If IsMissing(rstC_A_C) = False Then
            ' да, вызывающему функцию коду рекордсет со стройкой нужен
            Set rstC_A_C = rsFindSv
            Else
            ' нет, вызывающему функцию коду рекордсет со стройкой не нужен
            rsFindSv.Close: Set rsFindSv = Nothing
        End If
        
        ' закрываем всё, что было нужно для поиска стройку
        qdFindSv.Close: Set qdFindSv = Nothing
            
NormalExit:
    Exit Function
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
        
End Function

Function UserNameWindows() As String
    UserNameWindows = Environ("USERNAME")
End Function

' используем запросы к серверу
Sub PassThroughQuery(ByRef db As DAO.Database, ByVal strSql As String, Optional rs As Variant)

    Const cstrTitle As String _
        = "Процедура *Используем запросы к серверу*"

    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    Set qd = db.CreateQueryDef("", strSql)
    qd.Connect = "ODBC;DSN=FishEye;UID=" & UserNameWindows() & ";Trusted_Connection=Yes;DATABASE=FishEye;"
    
    ' необходимо вернуть набор записей?
    If IsMissing(rs) = False Then
        ' да, вернуть набор записей необходимо
        Set rs = db.OpenRecordset(dbOpenSnapshot)
        Else
        ' нет, возвращать набор записей не нужно
        qd.ReturnsRecords = False
        qd.Execute dbFailOnError
    End If
    
    qd.Close: Set qd = Nothing

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

' Concatenate values from related records. http://allenbrowne.com/func-concat.html
'The Arguments
'   Inside the brackets for ConcatRelated(), place this information:
'
'   First is the name of the field to look in. Include square brackets if the field contains non-alphanumeric characters such as a space, e.g. "[Order Date]"
'   Second is the name of the table or query to look in. Again, use square brackets around the name if it contains spaces.
'   Thirdly, supply the filter to limit the function to the desired values. This will normally be of the form:
'    "[ForeignKeyFieldName] = " & [PrimaryKeyFieldName]
'   If the foreign key field is Text (not Number), include quote marks as delimiters, e.g.:
'    "[ForeignKeyFieldName] = """ & [PrimaryKeyFieldName]   & """"
'   For an explanation of the quotes, see Quotation marks within quotes.
'   Any valid WHERE clause is permitted.
'   If you omit this argument, ALL related records will be returned.
'   Leave the fourth argument blank if you don't care how the return values are sorted.
'   Specify the field name(s) to sort by those fields.
'   Any valid ORDER BY clause is permitted.
'   For example, to sort by [Order Date] with a secondary sort by [Order ID], use:
'    "[Order Date], [Order ID]"
'   You cannot sort by a multi-valued field.
'   Use the fifth argument to specify the separator to use between items in the string.
'   The default separator is a comma and space.
Public Function ConcatRelated(strField As String, _
    strTable As String, _
    Optional strWhere As String, _
    Optional strOrderBy As String, _
    Optional strSeparator = ", ") As Variant
On Error GoTo Err_Handler
    'Purpose:   Generate a concatenated string of related records.
    'Return:    String variant, or Null if no matches.
    'Arguments: strField = name of field to get results from and concatenate.
    '           strTable = name of a table or query.
    '           strWhere = WHERE clause to choose the right values.
    '           strOrderBy = ORDER BY clause, for sorting the values.
    '           strSeparator = characters to use between the concatenated values.
    'Notes:     1. Use square brackets around field/table names with spaces or odd characters.
    '           2. strField can be a Multi-valued field (A2007 and later), but strOrderBy cannot.
    '           3. Nulls are omitted, zero-length strings (ZLSs) are returned as ZLSs.
    '           4. Returning more than 255 characters to a recordset triggers this Access bug:
    '               http://allenbrowne.com/bug-16.html
    Dim rs As DAO.Recordset         'Related records
    Dim rsMV As DAO.Recordset       'Multi-valued field recordset
    Dim strSql As String            'SQL statement
    Dim strOut As String            'Output string to concatenate to.
    Dim lngLen As Long              'Length of string.
    Dim bIsMultiValue As Boolean    'Flag if strField is a multi-valued field.
    
    'Initialize to Null
    ConcatRelated = Null
    
    'Build SQL string, and get the records.
    strSql = "SELECT " & strField & " FROM " & strTable
    If strWhere <> vbNullString Then
        strSql = strSql & " WHERE " & strWhere
    End If
    If strOrderBy <> vbNullString Then
        strSql = strSql & " ORDER BY " & strOrderBy
    End If
    Set rs = DBEngine(0)(0).OpenRecordset(strSql, dbOpenDynaset)
    'Determine if the requested field is multi-valued (Type is above 100.)
    bIsMultiValue = (rs(0).type > 100)
    
    'Loop through the matching records
    Do While Not rs.EOF
        If bIsMultiValue Then
            'For multi-valued field, loop through the values
            Set rsMV = rs(0).value
            Do While Not rsMV.EOF
                If Not IsNull(rsMV(0)) Then
                    strOut = strOut & StringClean(rsMV(0).value) & strSeparator
                End If
                rsMV.MoveNext
            Loop
            Set rsMV = Nothing
        ElseIf Not IsNull(rs(0)) Then
            strOut = strOut & StringClean(rs(0).value) & strSeparator
        End If
        rs.MoveNext
    Loop
    rs.Close
    
    'Return the string without the trailing separator.
    lngLen = Len(strOut) - Len(strSeparator)
    If lngLen > 0 Then
        ConcatRelated = Left(strOut, lngLen)
    End If

Exit_Handler:
    'Clean up
    Set rsMV = Nothing
    Set rs = Nothing
    Exit Function

Err_Handler:
    MsgBox "Error " & Err.Number & ": " & Err.Description, vbExclamation, "ConcatRelated()"
    Resume Exit_Handler
End Function

' очищаем строку
Public Function StringClean(ByVal Text As String) As String

    Dim strTemp As String

    If Text = "" Then
        StringClean = ""
    Else
        ' очистим строку
        strTemp = Replace(Text, vbCr, " ")
        strTemp = Replace(strTemp, vbLf, " ")
        strTemp = Replace(strTemp, vbTab, " ")
        strTemp = Replace(strTemp, vbVerticalTab, " ")
        strTemp = Replace(strTemp, vbBack, " ")
        strTemp = Replace(strTemp, vbNullChar, " ")
        ' здесь заменяем неразрывный пробел на обычный пробел
        strTemp = Replace(strTemp, ChrW(&HA0), " ")
        While InStr(strTemp, "  ") > 0
            strTemp = Replace(strTemp, "  ", " ")
        Wend
        strTemp = Trim(strTemp)
        If strTemp = " " Then
            strTemp = ""
        End If
        StringClean = strTemp
    End If
    
End Function


' конвертируем дату в строку для вставки в строку запроса Target = 'sql'
Public Function DateConvertToQuery(ByVal DateToConv As Date, Optional ByVal Target As String = "access") As String

    Select Case Target
        Case "sql"
            DateConvertToQuery = year(DateToConv) & "-" & Month(DateToConv) & "-" & Day(DateToConv)
        Case Else
            DateConvertToQuery = "#" & Month(DateToConv) & "/" & Day(DateToConv) & "/" & year(DateToConv) & "#"
    End Select

End Function

' Пребразование строки к дате
Public Function StrToDate(str_date As String) As Date
    Dim str_date_10 As String
    
    Const cstrTitle As String = "Функция *Пребразование строки к дате*"
    
On Error GoTo ErrHandler
    
    If IsDate(str_date) Then
            StrToDate = CDate(str_date)
        Else
            If Len(str_date) > 10 Then
                str_date_10 = Left(str_date, 10)
                If IsDate(str_date_10) Then
                    StrToDate = CDate(str_date_10)
                    Else
                    StrToDate = 0
                End If
                Else
                StrToDate = 0
            End If
    End If
    
NormalExit:
    Exit Function
    
ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
    
End Function

' получаем номер изменения из строки. 12.07.2022 ****************************************************************************************************
Public Function RcStringNum(ByVal strValue As String) As Variant

    Dim StrArray() As String ' массив для найденных слов
    Dim li As Integer, ssss As String, iii As Integer, stSm As String
    Dim Rddd As Date, RdddV As Variant, RdddS As String, Rnum As String, isChange As Boolean, ChNum As Integer, stst As String
    
    Dim Match As Object, RegExp As Object, strReg As String
    Dim MatchD As Object, RegExpD As Object, strRegD As String
    
    Dim nummStr As String

    Const cstrTitle As String _
        = "Module1. Функция *Получаем номер изменения из строки*"
        
    '------------------------------------------------------------------------------------------------------------------------------------------------

On Error GoTo ErrHandler

    ' для начала пометим, что это не изменение, что номер его 0, номера отчёта нет, даты отчёта нет
    isChange = False: ChNum = 0: Rnum = "Нет номера отчёта" ': Rddd = Null
    
    ' попробуем найти номер изменения сразу
    Set RegExp = CreateObject("VBScript.RegExp")
    ' определяем шаблон регулярного выражения
    strReg = "(Изм|изм|Изменение|изменение)(\.| \.)*(№| №)*( )*([0-9]{1,3})"
    ' присваиваем шаблон регулярного выражения
    RegExp.Pattern = strReg
    ' устанавливаем вместо поиска всех совпадений в строке поиск первого совпадения
    RegExp.Global = False
    Set Match = RegExp.Execute(StringClean(strValue))
    If Match.count > 0 Then
        ' ищем номер
        nummStr = StringClean(Match(0).value)
        
        Set RegExpD = CreateObject("VBScript.RegExp")
        strRegD = "([0-9]{1,3})"
        RegExpD.Pattern = strRegD
        RegExpD.Global = False
        Set MatchD = RegExpD.Execute(nummStr)
        If MatchD.count > 0 Then
            If IsNumeric(MatchD(0).value) = True Then
                ChNum = CInt(MatchD(0).value)
            End If
        End If
        
    End If
    
    ' разобьём строку на отдельные слова, сначала почистив
    StrArray() = Split(StringClean(strValue))
    
    ' пройдём по всем словам
    ssss = "": iii = 1
    For li = LBound(StrArray) To UBound(StrArray)
        If iii = 1 Then
            ssss = iii & ". " & StrArray(li)
            Else
            ssss = ssss & ", " & iii & ". " & StrArray(li)
        End If
        
        ' проверяем, что это изменение
        If StrArray(li) Like "*Изм*" Then
            isChange = True
            ssss = ssss & ", это действительно изм."
        End If

        ' пробуем перевести в номер изменения
        If Left(StrArray(li), 1) = "№" And Len(StrArray(li)) > 1 Then
            stst = Right(StrArray(li), Len(StrArray(li)) - 1)
            Else
            stst = StrArray(li)
        End If
        
        If IsNumeric(stst) Then
            If ChNum = 0 Then
                ChNum = CInt(stst)
                ssss = ssss & ", это номер изм."
                Else
                ssss = ssss & ", это ВТОРОЙ номер изм.? Плохо. Оставим номером первый."
            End If
        End If
        
        ' отыскиваем номер отчёта
        If StrArray(li) Like "*-???????-*" Then
            If Left(StrArray(li), 1) = "№" Then
                Rnum = Right(StrArray(li), Len(StrArray(li)) - 1)
                Else
                Rnum = StrArray(li)
            End If
            ssss = ssss & ", № отч."
        End If
        
        iii = iii + 1
    Next li
    
    ' отыскиваем самую раннюю дату как дату отчёта
    RdddV = ParseDate(RTrim(LTrim(strValue)), True, RdddS)
    If IsNull(RdddV) = False Then
        Rddd = RdddV
        ssss = ssss & ", " & Rddd & " - дата отч."
        Else
        ssss = ssss & ", <font color=""DarkRed"">дата отч. не найдена, " & RdddS & "</font>"
    End If
    
    ' посмотрим, что у нас вышло после анализа отдельных слов
    ' вообще это изменение?
    If isChange Then
        ' да, это изменение
        ' имеется ли номер изменения?
        If ChNum > 0 Then
            RcStringNum = ChNum
        Else
            ' нет, номер изменения отсутствует
            RcStringNum = Null
        End If
    Else
        ' нет, это не изменение
        RcStringNum = Null
    End If


NormalExit:
    Exit Function
    
ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Function
' получаем номер изменения из строки. 12.07.2022. Окончание *****************************************************************************************

' получаем дату из строки, Start - давать самую раннюю дату, иначе - самую позднюю
' CountDates - показывает сколько дат в строке
Function ParseDate(ByVal Text As String, Start As Boolean, _
    Optional ByRef ErrDescr As String, Optional ByRef CountDates As Integer) As Variant

    ' для разных дат
    Dim Match As Object, RegExp As Object, d As Date, di As Date, strReg As String, strTemp As String
    
    Const cstrTitle As String _
        = "Процедура *Получаем дату из строки*"
    '------------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    ' для начала установим возвращаемую величину в Null
    ParseDate = Null: ErrDescr = "": CountDates = 0
    
    ' очистим строку
    strTemp = StringClean(Text)
    
    ' ищем разные даты
    Set RegExp = CreateObject("VBScript.RegExp")
    ' определяем шаблон регулярного выражения
    RealQ = Chr(34)
    strReg = "((\d{2}\.\d{2}\.(\d{2}(\D|$)|\d{4}))" & _
        "|(\d{2}|" & RealQ & "\d{2}" & RealQ & ") " & _
        "((я|Я)нваря|(ф|Ф)евраля|(м|М)арта|(а|А)преля|(м|М)ая|(и|И)юня|(и|И)юля|(а|А)вгуста|(с|С)ентября|(о|О)ктября|(н|Н)оября|(д|Д)екабря) \d{4})"
    ' присваиваем шаблон регулярного выражения
    RegExp.Pattern = strReg
    ' устанавливаем поиск всех совпадений в строке вместо поиска первого совпадения
    RegExp.Global = True
    Set Match = RegExp.Execute(strTemp)
    If Match.count > 0 Then
        CountDates = Match.count
        If Start Then
            ' самая ранняя
            For i = 0 To Match.count - 1
                ' убираем кавычки, если они есть
                strTemp = Replace(Match(i).value, RealQ, "")
                ' дата вида 02.02.20 будет иметь на хвосте лишний знак. Ну пробел, конец строки, запятую или ещё чего. Нужно убрать
                If Len(strTemp) = 9 Then
                    strTemp = Left(strTemp, 8)
                End If
                di = CDate(strTemp)
                If di < d Or d = 0 Then
                    d = di
                End If
            Next
            Else
            'самая поздняя
            For i = 0 To Match.count - 1
                ' убираем кавычки, если они есть
                strTemp = Replace(Match(i).value, RealQ, "")
                ' дата вида 02.02.20 будет иметь на хвосте лишний знак. Ну пробел, конец строки, запятую или ещё чего. Нужно убрать
                If Len(strTemp) = 9 Then
                    strTemp = Left(strTemp, 8)
                End If
                di = CDate(strTemp)
                If di > d Then
                    d = di
                End If
            Next
        End If
    End If
    
    'ну и возвращаем величину
    If d > 0 Then
        ParseDate = d
    End If
        
NormalExit:
    Exit Function
    
ErrHandler:
    ErrDescr = strTemp & ", " & "№ ошибки: " & Err.Number & ", " & Err.Description
    'MsgBox Err.Description & vbCrLf & "№ ошибки: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
    
End Function

' получаем номер отчёта агента изменения из строки. 13.07.2022 **************************************************************************************
Public Function RcStringRaNum(ByVal strValue As String) As Variant

    Dim StrArray() As String ' массив для найденных слов
    Dim li As Integer, ssss As String, iii As Integer, stSm As String
    Dim Rddd As Date, RdddV As Variant, RdddS As String, Rnum As String, isChange As Boolean, ChNum As Integer, stst As String
    
    Dim Match As Object, RegExp As Object, strReg As String
    Dim MatchD As Object, RegExpD As Object, strRegD As String
    
    Dim nummStr As String

    Const cstrTitle As String _
        = "Module1. Функция *Получаем номер отчёта агента изменения из строки*"
        
    '------------------------------------------------------------------------------------------------------------------------------------------------

On Error GoTo ErrHandler

    ' для начала пометим, что это не изменение, что номер его 0, номера отчёта нет, даты отчёта нет
    isChange = False: ChNum = 0: Rnum = "Нет номера отчёта" ': Rddd = Null
    
    ' разобьём строку на отдельные слова, сначала почистив
    StrArray() = Split(StringClean(strValue))
    
    ' пройдём по всем словам
    ssss = "": iii = 1
    For li = LBound(StrArray) To UBound(StrArray)
        If iii = 1 Then
            ssss = iii & ". " & StrArray(li)
            Else
            ssss = ssss & ", " & iii & ". " & StrArray(li)
        End If
        
        ' проверяем, что это изменение
        If StrArray(li) Like "*Изм*" Then
            isChange = True
            ssss = ssss & ", это действительно изм."
        End If

        ' отыскиваем номер отчёта
        ' вот здесь 17.04.2025 стали попадаться номера всего лишь с одним дефисом...
        ' If StrArray(li) Like "*-???????-*" Then - так было до 17.04.2025
        If StrArray(li) Like "*-*" Then ' так с 17.04.2025
            If Left(StrArray(li), 1) = "№" Then
                Rnum = Right(StrArray(li), Len(StrArray(li)) - 1)
                Else
                Rnum = StrArray(li)
            End If
            ssss = ssss & ", № отч."
        End If
        
        iii = iii + 1
    Next li
    
    ' посмотрим, что у нас вышло после анализа отдельных слов
    ' вообще это изменение?
    If isChange Then
        ' да, это изменение
        ' найден номер отчёта?
        If Rnum <> "Нет номера отчёта" Then
            RcStringRaNum = Rnum
        Else
            ' нет, номер отчёта отсутствует
            RcStringRaNum = Null
        End If
    Else
        ' нет, это не изменение
        RcStringRaNum = Null
    End If


NormalExit:
    Exit Function
    
ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Function
' получаем номер отчёта агента изменения из строки. 13.07.2022. Окончание ***************************************************************************

' получаем дату окончания отчётного периода по дате. 07.12.2023 *************************************************************************************
Public Function PeriodDateOfDate(ByVal ofDate As Variant) As Variant

Dim dateResult As Date, dateMonthPlus As Date

If IsDate(ofDate) Then
    If Day(ofDate) < 16 Then
        dateResult = DateSerial(year(ofDate), Month(ofDate), 15)
    Else
        dateMonthPlus = DateAdd("m", 1, ofDate)
        dateMonthPlus = DateSerial(year(dateMonthPlus), Month(dateMonthPlus), 1)
        dateResult = DateAdd("d", -1, dateMonthPlus)
    End If
    PeriodDateOfDate = dateResult
Else
    PeriodDateOfDate = Null
End If

End Function
' получаем номер отчёта агента изменения из строки. 13.07.2022. Окончание ***************************************************************************

' получаем дату отчёта агента для изменения из строки. 13.07.2022 ***********************************************************************************
Public Function RcStringRaDate(ByVal strValue As String) As Variant

    Dim StrArray() As String ' массив для найденных слов
    Dim li As Integer, ssss As String, iii As Integer, stSm As String
    Dim Rddd As Date, RdddV As Variant, RdddS As String, isChange As Boolean, stst As String
    
    Dim nummStr As String

    Const cstrTitle As String _
        = "Module1. Функция *Получаем дату отчёта агента для изменения из строки*"
        
    '------------------------------------------------------------------------------------------------------------------------------------------------

On Error GoTo ErrHandler

    ' для начала пометим, что это не изменение, что номер его 0, номера отчёта нет, даты отчёта нет
    isChange = False
    
    ' разобьём строку на отдельные слова, сначала почистив
    StrArray() = Split(StringClean(strValue))
    
    ' пройдём по всем словам
    ssss = "": iii = 1
    For li = LBound(StrArray) To UBound(StrArray)
        If iii = 1 Then
            ssss = iii & ". " & StrArray(li)
            Else
            ssss = ssss & ", " & iii & ". " & StrArray(li)
        End If
        
        ' проверяем, что это изменение
        If StrArray(li) Like "*Изм*" Then
            isChange = True
            ssss = ssss & ", это действительно изм."
        End If

        iii = iii + 1
    Next li
    
    ' отыскиваем самую раннюю дату как дату отчёта
    RdddV = ParseDate(RTrim(LTrim(strValue)), True, RdddS)
    If IsNull(RdddV) = False Then
        Rddd = RdddV
        ssss = ssss & ", " & Rddd & " - дата отч."
        Else
        ssss = ssss & ", <font color=""DarkRed"">дата отч. не найдена, " & RdddS & "</font>"
    End If
    
    ' посмотрим, что у нас вышло после анализа отдельных слов
    ' вообще это изменение?
    If isChange Then
        ' да, это изменение
        ' дата отчёта отлична от ноля?
        If Rddd <> 0 Then
            RcStringRaDate = Rddd
        Else
            ' нет, дата отчёта не отлична от ноля
            RcStringRaDate = Null
        End If
    Else
        ' нет, это не изменение
        RcStringRaDate = Null
    End If


NormalExit:
    Exit Function
    
ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Function
' получаем дату отчёта агента для изменения из строки. 13.07.2022. Окончание ************************************************************************

