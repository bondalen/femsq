Attribute VB_Name = "modDumpTableDefRaImpNew"
' -----------------------------------------------------------------------------
' Extended TableDef dump (DAO) for ra_ImpNew and other local/linked tables.
'
' Install: File -> Import this .bas, or Insert -> Module and paste (you may drop Attribute VB_Name).
'
' !!! Immediate window: table name and file path MUST be in double quotes (String).
'     Wrong:  DumpTableDef_Extended ra_ImpNew, ..., C:\temp\file.txt   -> Err 424 Object required
'     Right:  DumpTableDef_Extended "ra_ImpNew", True, False, False, "C:\temp\ra_ImpNew.txt"
'     Or:     DumpTableDef_RaImpNew_ToUtf8 "C:\temp\ra_ImpNew.txt"
'
' Run:     Ctrl+G -> DumpTableDef_RaImpNew
'          or DumpTableDef_Extended "ra_ImpNew", True, False, True, "C:\temp\ra_ImpNew_dump.txt"
'               args: tableName, includeRecordCount, includeDatasheetUiProps,
'                     compactFieldProperties, utf8FilePath (vbNullString or "" = file off)
'
' Cyrillic Description/Caption: wrong in Immediate when copied; use utf8FilePath for correct UTF-8 file.
' Recordset-only Field properties are not read (no Russian Err.Description in output).
' TableDef GUID / NameMap: DAO Property.Type 9 (dbBinary) and 11 (dbLongBinary) — binary blobs;
'   printing as text looks like random CJK/mojibake; output is <binary/skipped>.
' ConflictTable / ReplicaFilter: skipped by name (often Err 3032 on local tables).
'
' lastUpdated: 2026-03-19
' -----------------------------------------------------------------------------

Option Compare Database
Option Explicit

Private mUtf8Stream As Object

Public Sub DumpTableDef_RaImpNew()
    DumpTableDef_Extended "ra_ImpNew", True, False, True, vbNullString
End Sub

' Shortcut: dump ra_ImpNew to UTF-8 file (Cyrillic OK in file).
Public Sub DumpTableDef_RaImpNew_ToUtf8(ByVal fullPath As String)
    DumpTableDef_Extended "ra_ImpNew", True, False, True, fullPath
End Sub

' utf8FilePath: e.g. "C:\temp\ra_ImpNew.txt" — BOM UTF-8, Cyrillic readable in VS Code / Notepad.
' compactFieldProperties: True = skip Field.Properties already printed above (Name, Type, Size, ...).
Public Sub DumpTableDef_Extended( _
    ByVal tableName As String, _
    Optional ByVal includeRecordCount As Boolean = True, _
    Optional ByVal includeDatasheetUiProps As Boolean = False, _
    Optional ByVal compactFieldProperties As Boolean = True, _
    Optional ByVal utf8FilePath As String = vbNullString)

    On Error GoTo ErrHandler

    Dim db As DAO.Database
    Dim td As DAO.TableDef
    Dim fld As DAO.Field
    Dim idx As DAO.Index
    Dim idxFld As DAO.Field
    Dim prp As DAO.Property
    Dim rel As DAO.Relation
    Dim relFld As DAO.Field
    Dim rs As DAO.Recordset
    Dim n As Long
    Dim pathUtf8 As String

    Set mUtf8Stream = Nothing
    pathUtf8 = Trim$(utf8FilePath)
    If Len(pathUtf8) > 0 Then
        On Error Resume Next
        Set mUtf8Stream = CreateObject("ADODB.Stream")
        mUtf8Stream.Type = 2              ' adTypeText
        mUtf8Stream.Charset = "UTF-8"
        mUtf8Stream.Open
        If Err.Number <> 0 Then
            Debug.Print "ERROR: ADODB.Stream open failed Err=" & Err.Number
            Set mUtf8Stream = Nothing
            Err.Clear
        End If
        On Error GoTo ErrHandler
    End If

    Set db = CurrentDb
    Set td = Nothing
    On Error Resume Next
    Set td = db.TableDefs(tableName)
    If Err.Number <> 0 Then
        OutLn "ERROR: TableDefs not found or failed: " & Quote(tableName) & " Err=" & Err.Number
        Err.Clear
        GoTo CleanStream
    End If
    On Error GoTo ErrHandler

    OutLn "========================================"
    OutLn "TABLE: " & td.Name
    SafeOutLn "SourceTableName", td.SourceTableName
    If Len(Nz(td.Connect, "")) > 0 Then
        OutLn "Connect: " & td.Connect
    Else
        OutLn "Connect: (local table)"
    End If
    OutLn "Attributes (TableDef): " & td.Attributes

    On Error Resume Next
    OutLn "DateCreated: " & td.DateCreated
    OutLn "LastUpdated: " & td.LastUpdated
    On Error GoTo ErrHandler

    If includeRecordCount Then
        On Error Resume Next
        Set rs = db.OpenRecordset("SELECT COUNT(*) AS n FROM [" & td.Name & "]", dbOpenSnapshot)
        If Not rs Is Nothing Then
            n = rs!n
            rs.Close
            Set rs = Nothing
            OutLn "RecordCount (SELECT COUNT): " & n
        Else
            OutLn "RecordCount: COUNT(*) failed Err=" & Err.Number
        End If
        On Error GoTo ErrHandler
    End If

    OutLn "--- TableDef.Properties ---"
    For Each prp In td.Properties
        If Not ShouldSkipTableDefTopLevelPropertyByName(prp.Name) Then
            PrintPropertySafe "  ", prp
        End If
    Next prp

    OutLn "--- FIELDS ---"
    For Each fld In td.Fields
        OutLn "FIELD: " & fld.Name
        OutLn "  OrdinalPosition: " & fld.OrdinalPosition
        OutLn "  Type: " & fld.Type & " (" & DaoTypeName(fld.Type) & ")"
        OutLn "  Size: " & fld.Size
        OutLn "  Required: " & fld.Required
        OutLn "  Attributes: " & fld.Attributes

        On Error Resume Next
        OutLn "  AllowZeroLength: " & fld.AllowZeroLength
        On Error GoTo ErrHandler

        SafeOutLnValue "  DefaultValue", fld.DefaultValue
        SafeOutLnValue "  ValidationRule", fld.ValidationRule
        SafeOutLnValue "  ValidationText", fld.ValidationText

        On Error Resume Next
        OutLn "  CollatingOrder: " & fld.CollatingOrder
        On Error GoTo ErrHandler

        If compactFieldProperties Then
            OutLn "  --- Field.Properties (extra only; compact) ---"
        Else
            OutLn "  --- Field.Properties (TableDef-safe, full) ---"
        End If
        For Each prp In fld.Properties
            If Not ShouldSkipTableDefFieldProperty(prp.Name, includeDatasheetUiProps) Then
                If Not ShouldSkipRedundantFieldProperty(prp.Name, compactFieldProperties) Then
                    PrintPropertySafe "    ", prp
                End If
            End If
        Next prp
        OutLn ""
    Next fld

    OutLn "--- INDEXES ---"
    On Error Resume Next
    For Each idx In td.Indexes
        OutLn "INDEX: " & idx.Name
        OutLn "  Primary: " & idx.Primary
        OutLn "  Unique: " & idx.Unique
        OutLn "  Required: " & idx.Required
        OutLn "  IgnoreNulls: " & idx.IgnoreNulls
        OutLn "  Foreign: " & idx.Foreign
        OutLn "  Clustered: " & IdxClusteredSafe(idx)
        OutLn "  Fields:"
        For Each idxFld In idx.Fields
            OutLn "    " & idxFld.Name
        Next idxFld
        OutLn ""
    Next idx
    On Error GoTo ErrHandler

    OutLn "--- RELATIONS (this table as Table or ForeignTable) ---"
    On Error Resume Next
    For Each rel In db.Relations
        If StrComp(rel.Table, td.Name, vbTextCompare) = 0 _
            Or StrComp(rel.ForeignTable, td.Name, vbTextCompare) = 0 Then
            OutLn "RELATION: " & rel.Name
            OutLn "  Table: " & rel.Table & "  ->  ForeignTable: " & rel.ForeignTable
            OutLn "  Attributes: " & rel.Attributes
            For Each relFld In rel.Fields
                OutLn "  Field: " & relFld.Name & "  ->  ForeignName: " & relFld.ForeignName
            Next relFld
            OutLn ""
        End If
    Next rel
    On Error GoTo ErrHandler

    OutLn "========================================"
    OutLn "END OF DUMP"

    If Len(pathUtf8) > 0 And Not mUtf8Stream Is Nothing Then
        On Error Resume Next
        mUtf8Stream.SaveToFile pathUtf8, 2
        If Err.Number = 0 Then
            Debug.Print "UTF-8 dump saved: " & pathUtf8
        Else
            Debug.Print "ERROR SaveToFile Err=" & Err.Number
            Err.Clear
        End If
        mUtf8Stream.Close
        Set mUtf8Stream = Nothing
        On Error GoTo 0
    End If

    Exit Sub

ErrHandler:
    OutLn "ERROR " & Err.Number & " (Description omitted — OEM mojibake)"
    GoTo CleanStream

CleanStream:
    On Error Resume Next
    If Not mUtf8Stream Is Nothing Then
        mUtf8Stream.Close
        Set mUtf8Stream = Nothing
    End If
    On Error GoTo 0
End Sub

Private Sub OutLn(ByVal s As String)
    Debug.Print s
    If Not mUtf8Stream Is Nothing Then
        On Error Resume Next
        mUtf8Stream.WriteText s & vbCrLf
        On Error GoTo 0
    End If
End Sub

' Same names already printed in FIELD block — skip in compact mode.
Private Function ShouldSkipRedundantFieldProperty(ByVal propName As String, ByVal compact As Boolean) As Boolean
    If Not compact Then
        ShouldSkipRedundantFieldProperty = False
        Exit Function
    End If
    Select Case propName
        Case "Name", "Type", "OrdinalPosition", "Size", "SourceField", "SourceTable", _
             "Attributes", "CollatingOrder", "DefaultValue", "ValidationRule", "ValidationText", _
             "Required", "AllowZeroLength", "AppendOnly", "DataUpdatable", "Expression"
            ShouldSkipRedundantFieldProperty = True
        Case Else
            ShouldSkipRedundantFieldProperty = False
    End Select
End Function

Private Function ShouldSkipTableDefFieldProperty(ByVal propName As String, ByVal includeUi As Boolean) As Boolean
    Select Case propName
        Case "Value", "ValidateOnSet", "ForeignName", "FieldSize", "OriginalValue", "VisibleValue"
            ShouldSkipTableDefFieldProperty = True
            Exit Function
        Case "GUID"
            ShouldSkipTableDefFieldProperty = True
            Exit Function
    End Select
    If Not includeUi Then
        Select Case propName
            Case "ColumnWidth", "ColumnOrder", "ColumnHidden", _
                 "IMEMode", "IMESentenceMode", "TextAlign", "ShowDatePicker", _
                 "AggregateType", "ResultType", "CurrencyLCID"
                ShouldSkipTableDefFieldProperty = True
                Exit Function
        End Select
    End If
    ShouldSkipTableDefFieldProperty = False
End Function

' Replica-related TableDef properties: often raise Err 3032 on non-replica local tables.
Private Function ShouldSkipTableDefTopLevelPropertyByName(ByVal propName As String) As Boolean
    Select Case propName
        Case "ConflictTable", "ReplicaFilter"
            ShouldSkipTableDefTopLevelPropertyByName = True
        Case Else
            ShouldSkipTableDefTopLevelPropertyByName = False
    End Select
End Function

Private Sub PrintPropertySafe(ByVal indent As String, ByVal prp As DAO.Property)
    Dim v As Variant
    ' Type 9 = dbBinary (e.g. TableDef GUID), 11 = dbLongBinary (NameMap). Not human text.
    Select Case prp.Type
        Case 9, 11
            OutLn indent & prp.Name & " = <binary/skipped>  (Property.Type=" & prp.Type & ")"
            Exit Sub
    End Select

    On Error Resume Next
    v = prp.Value
    If Err.Number <> 0 Then
        OutLn indent & prp.Name & " = <read Err " & Err.Number & ">"
        Err.Clear
        On Error GoTo 0
        Exit Sub
    End If
    On Error GoTo 0
    If IsNull(v) Then
        OutLn indent & prp.Name & " = (Null)  (Property.Type=" & prp.Type & ")"
    ElseIf IsEmpty(v) Then
        OutLn indent & prp.Name & " = (Empty)  (Property.Type=" & prp.Type & ")"
    ElseIf VarType(v) = vbString Then
        If Len(v) = 0 Then
            OutLn indent & prp.Name & " = (empty string)  (Property.Type=" & prp.Type & ")"
        Else
            OutLn indent & prp.Name & " = " & v & "  (Property.Type=" & prp.Type & ")"
        End If
    Else
        OutLn indent & prp.Name & " = " & CStr(v) & "  (Property.Type=" & prp.Type & ")"
    End If
End Sub

Private Sub SafeOutLn(ByVal label As String, ByVal v As Variant)
    On Error Resume Next
    OutLn label & ": " & v
    If Err.Number <> 0 Then
        OutLn label & ": <read Err " & Err.Number & ">"
        Err.Clear
    End If
    On Error GoTo 0
End Sub

Private Sub SafeOutLnValue(ByVal label As String, ByVal v As Variant)
    If IsNull(v) Or IsEmpty(v) Then
        OutLn label & ": (null)"
    Else
        SafeOutLn label, v
    End If
End Sub

Private Function DaoTypeName(ByVal t As Integer) As String
    Select Case t
        Case 1: DaoTypeName = "dbBoolean"
        Case 2: DaoTypeName = "dbByte"
        Case 3: DaoTypeName = "dbInteger"
        Case 4: DaoTypeName = "dbLong"
        Case 5: DaoTypeName = "dbCurrency"
        Case 6: DaoTypeName = "dbSingle"
        Case 7: DaoTypeName = "dbDouble"
        Case 8: DaoTypeName = "dbDate"
        Case 9: DaoTypeName = "dbBinary"
        Case 10: DaoTypeName = "dbText"
        Case 11: DaoTypeName = "dbLongBinary"
        Case 12: DaoTypeName = "dbMemo"
        Case 15: DaoTypeName = "dbGUID"
        Case Else: DaoTypeName = "Type_" & t
    End Select
End Function

Private Function Quote(ByVal s As String) As String
    Quote = """" & s & """"
End Function

Private Function IdxClusteredSafe(ByVal idx As DAO.Index) As String
    On Error Resume Next
    IdxClusteredSafe = CStr(idx.Clustered)
    If Err.Number <> 0 Then
        IdxClusteredSafe = "<n/a>"
        Err.Clear
    End If
    On Error GoTo 0
End Function
