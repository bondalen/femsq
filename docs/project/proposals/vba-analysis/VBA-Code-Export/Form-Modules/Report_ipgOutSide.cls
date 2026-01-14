VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Report_ipgOutSide"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'Option Compare Database
'
'Private Sub Report_Current()
'
'    Dim raKey As Integer
'
'    Const cstrTitle As String _
'    = "Процедура *Смена текущей записи отчёта ВнеИнвестпрограммы*"
'    ' ***************************************************************************************************************************
'
'On Error GoTo ErrHandler
'
''    If IsNull(Me!cstapKey) Then
''        'RefreshCstChart (0)
''        Me!FieldTest.Text = "net net"
''        Else
''        'RefreshCstChart (Me!cstapKey)
''        Me!FieldTest.Text = "est " & Me!cstapKey
''    End If
'
'    'RefreshCstChart (cstKey)
'
''    Me![cst>ra_t].Requery
''    Me![cst>raUtil_t].Requery
'
''    If IsNull(Me.Form![cst>ra_t].Form![ra_key]) Or IsEmpty(Me.Form![cst>ra_t].Form![ra_key]) Then
''        raKey = 0
''    Else
''        raKey = Me.Form![cst>ra_t].Form![ra_key]
''    End If
'
'    ' фильтруем отчёт
''    Me.Form![cst>ra_f].Form.Filter = "ra_key = " & raKey
''    Me.Form![cst>ra_f].Form.FilterOn = True
'
'    ' ***************************************************************************************************************************
'NormalExit:
'    Exit Sub
'
'ErrHandler:
'
'    If Err.Number = 2427 Then
'        raKey = 0
'        Resume Next
'    Else
'        MsgBox Err.Description & vbCrLf & "№ ошибки: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
'        Resume NormalExit
'    End If
'
'
'End Sub
'
'Private Sub Report_Load()
'
''    If IsNull(Me!cstapKey) Then
''        'RefreshCstChart (0)
''        Me!FieldTest.Text = "net net"
''        Else
''        'RefreshCstChart (Me!cstapKey)
''        Me!FieldTest.Text = "est " & Me!cstapKey
''    End If
'
'End Sub
'
'Private Sub Report_Open(Cancel As Integer)
'
''    If IsNull(Me!cstapKey) Then
''        'RefreshCstChart (0)
''        Me!FieldTest.Text = "net net"
''        Else
''        'RefreshCstChart (Me!cstapKey)
'''        Me!FieldTest.Text = "est " & Me!cstapKey
'''        MsgBox ("est " & Me!cstapKey)
''    End If
'
'End Sub
'
'Private Sub ОбластьДанных_Format(Cancel As Integer, FormatCount As Integer)
'
''    'Установить переменную базы данных на текущую базу данных.
''    Set db = CurrentDb
''
''    If IsNull(Me!cstapKey) Then
'''        'RefreshCstChart (0)
'''        MsgBox ("область данных " & "net net")
''
''            DoCmd.SetWarnings False
''            DoCmd.Close acTable, "ags_fnCstapOverIpg_tmp"
''            DoCmd.RunSQL "Delete * from ags_fnCstapOverIpg_tmp"
''            DoCmd.SetWarnings True
''
''        Else
'''        'RefreshCstChart (Me!cstapKey)
'''        Me!FieldTest.Text = "est " & Me!cstapKey
'''        MsgBox ("область данных " & Me!cstapKey & " " & Me!nameAll)
'''        RefreshFnCstapOverIpg Me!cstapKey.value, Me!yearOfDate.value
''
''            'Открыть объект QueryDef.
''            Set qdf = db.QueryDefs("ags_fnCstapOverIpg")
''
''            'Создание строки SQL для передачи в sp_GetWorklistAMI на основе введенных пользователем параметров.
''
''            ' strSQLString = "EXEC sp_GenerateVarianceReportData_AMI10 " & "'" & strFYQtrYr & "'"
''
''            cstapStr = CStr(Me!cstapKey.value)
''            yearStr = CStr(Me!yearOfDate.value)
''
''            strSQLString = "select " & _
''                "ra_key, ra_num, ra_date, ra_cac, ra_type, ra_work_type, ra_period, ra_arrived" & _
''                ", ra_arrived_date, ra_arrived_dateFact, ra_returned" & _
''                ", ra_returned_date , ra_returnedReason, ra_sent, ra_sent_date, ra_note_t" & _
''                ", ra_created, ra_org_sender, ra_note, ra_datePeriod" & _
''                " from ags.fnCstapOverIpg(" & cstapStr & ", " & yearStr & ")"
''
''            qdf.ReturnsRecords = True
''            'Назначение команды query def sql для строки SQL, созданной из выбранных пользователем данных.
''            qdf.SQL = strSQLString
''
''            qdf.Close: Set qdf = Nothing
''
''            DoCmd.SetWarnings False
''            DoCmd.Close acTable, "ags_fnCstapOverIpg_tmp"
''            DoCmd.RunSQL "Delete * from ags_fnCstapOverIpg_tmp"
''            'Создание временной таблицы для хранения данных AMI10 VarianceReport.
''            strSQLMakeTable = "insert into ags_fnCstapOverIpg_tmp (ra_key, ra_num, ra_date) " & _
''            "select ra_key, ra_num, ra_date " & _
''            "FROM ags_fnCstapOverIpg;"
''
''            'Выполнить оператор создания таблицы.
''            db.Execute strSQLMakeTable, dbFailOnError
''            DoCmd.SetWarnings True
''
''    End If
''
''        db.Close: Set db = Nothing
'
'End Sub
'
'Private Sub ОбластьДанных_Print(Cancel As Integer, PrintCount As Integer)
'    'Установить переменную базы данных на текущую базу данных.
'    Set db = CurrentDb
'
'    If IsNull(Me!cstapKey) Then
''        'RefreshCstChart (0)
''        MsgBox ("область данных " & "net net")
'
'            DoCmd.SetWarnings False
'            DoCmd.Close acTable, "ags_fnCstapOverIpg_tmp"
'            DoCmd.RunSQL "Delete * from ags_fnCstapOverIpg_tmp"
'            DoCmd.SetWarnings True
'
'        Else
''        'RefreshCstChart (Me!cstapKey)
''        Me!FieldTest.Text = "est " & Me!cstapKey
''        MsgBox ("область данных " & Me!cstapKey & " " & Me!nameAll)
''        RefreshFnCstapOverIpg Me!cstapKey.value, Me!yearOfDate.value
'
'            'Открыть объект QueryDef.
'            Set qdf = db.QueryDefs("ags_fnCstapOverIpg")
'
'            'Создание строки SQL для передачи в sp_GetWorklistAMI на основе введенных пользователем параметров.
'
'            ' strSQLString = "EXEC sp_GenerateVarianceReportData_AMI10 " & "'" & strFYQtrYr & "'"
'
'            cstapStr = CStr(Me!cstapKey.value)
'            yearStr = CStr(Me!yearOfDate.value)
'
'            strSQLString = "select " & _
'                "ra_key, ra_num, ra_date, ra_cac, ra_type, ra_work_type, ra_period, ra_arrived" & _
'                ", ra_arrived_date, ra_arrived_dateFact, ra_returned" & _
'                ", ra_returned_date , ra_returnedReason, ra_sent, ra_sent_date, ra_note_t" & _
'                ", ra_created, ra_org_sender, ra_note, ra_datePeriod" & _
'                " from ags.fnCstapOverIpg(" & cstapStr & ", " & yearStr & ")"
'
'            qdf.ReturnsRecords = True
'            'Назначение команды query def sql для строки SQL, созданной из выбранных пользователем данных.
'            qdf.SQL = strSQLString
'
'            qdf.Close: Set qdf = Nothing
'
'            DoCmd.SetWarnings False
'            DoCmd.Close acTable, "ags_fnCstapOverIpg_tmp"
'            DoCmd.RunSQL "Delete * from ags_fnCstapOverIpg_tmp"
'            'Создание временной таблицы для хранения данных AMI10 VarianceReport.
'            strSQLMakeTable = "insert into ags_fnCstapOverIpg_tmp (ra_key, ra_num, ra_date) " & _
'            "select ra_key, ra_num, ra_date " & _
'            "FROM ags_fnCstapOverIpg;"

'Private Sub Report_Load()
'
'    Dim qdf As DAO.QueryDef, db As DAO.Database
'
'    MsgBox ("Load")
'
'    Set db = CurrentDb
'
'        Set qdf = db.QueryDefs(Me.RecordSource)
'
'        qdf.Close: Set qdf = Nothing
'
'    db.Close: Set db = Nothing
'
'End Sub
'
''
''            'Выполнить оператор создания таблицы.
''            db.Execute strSQLMakeTable, dbFailOnError
''            DoCmd.SetWarnings True
''
''    End If
''
''        db.Close: Set db = Nothing
''
''End Sub
'Private Sub Report_Open(Cancel As Integer)
' MsgBox ("open")
'End Sub
