Attribute VB_Name = "mod_0054_4_ExportRaSql"
' FEMSQ 0054.4 — Export local Access ra_* tables to MSSQL2012 INSERT *.sql
' Fix: use one Database object (not CurrentDb per call) to avoid error 3420.
'
' Usage (Immediate):
'   ExportAllRaSql "C:\Temp\femsq_0054_import"
' Creates folder + numbered *.sql files. Zip and return for Docker dry-run.
'
Option Compare Database
Option Explicit

Private Const DAO_BOOLEAN As Integer = 1
Private Const DAO_BYTE As Integer = 2
Private Const DAO_INTEGER As Integer = 3
Private Const DAO_LONG As Integer = 4
Private Const DAO_CURRENCY As Integer = 5
Private Const DAO_SINGLE As Integer = 6
Private Const DAO_DOUBLE As Integer = 7
Private Const DAO_DATE As Integer = 8
Private Const DAO_TEXT As Integer = 10
Private Const DAO_LONGBINARY As Integer = 11
Private Const DAO_MEMO As Integer = 12
Private Const DAO_GUID As Integer = 15
Private Const DAO_BIGINT As Integer = 16
Private Const DAO_NUMERIC As Integer = 19
Private Const DAO_DECIMAL As Integer = 20

''' Export all revision tables in FK-safe order into folderPath.
Public Sub ExportAllRaSql(ByVal folderPath As String)
    Dim db As DAO.Database
    Set db = CurrentDb

    EnsureFolder folderPath

    ' Lookups first
    ExportTableSql db, folderPath, "01_ra_at.sql", "ra_at", "ags.ra_at", "at_key", True, _
        Array("at_key", "at_name")
    ExportTableSql db, folderPath, "02_ra_dir.sql", "ra_dir", "ags.ra_dir", "[key]", False, _
        Array("key", "dir_name", "dir")
    ExportTableSql db, folderPath, "03_ra_ft.sql", "ra_ft", "ags.ra_ft", "ft_key", True, _
        Array("ft_key", "ft_name")
    ExportTableSql db, folderPath, "04_ra_ft_st.sql", "ra_ft_st", "ags.ra_ft_st", "st_key", False, _
        Array("st_key", "st_name")
    ExportTableSql db, folderPath, "05_ra_ft_s.sql", "ra_ft_s", "ags.ra_ft_s", "ft_s_key", False, _
        Array("ft_s_key", "ft_s_type", "ft_s_num", "ft_s_sheet_type", "ft_s_period")
    ExportTableSql db, folderPath, "06_ra_ft_sn.sql", "ra_ft_sn", "ags.ra_ft_sn", "ftsn_key", False, _
        Array("ftsn_key", "ftsn_ft_s", "ftsn_name")
    ExportTableSql db, folderPath, "07_ra_a.sql", "ra_a", "ags.ra_a", "adt_key", False, _
        Array("adt_key", "adt_name", "adt_date", "adt_results", "adt_dir", "adt_type", "adt_AddRA")
    ExportTableSql db, folderPath, "08_ra_f.sql", "ra_f", "ags.ra_f", "af_key", False, _
        Array("af_key", "af_num", "af_name", "af_dir", "af_type", "ra_org_sender", "af_execute", "af_source")

    WriteTextFile folderPath & "\00_RUN_ORDER.txt", _
        "FEMSQ 0054.4 Access→MSSQL INSERT export" & vbCrLf & _
        "Apply on prod AFTER CREATE package (already done)." & vbCrLf & _
        "Dry-run first on Docker shadow tables (agent will provide)." & vbCrLf & vbCrLf & _
        "Order:" & vbCrLf & _
        "01_ra_at.sql (upsert)" & vbCrLf & _
        "02_ra_dir.sql" & vbCrLf & _
        "03_ra_ft.sql (upsert)" & vbCrLf & _
        "04_ra_ft_st.sql" & vbCrLf & _
        "05_ra_ft_s.sql" & vbCrLf & _
        "06_ra_ft_sn.sql" & vbCrLf & _
        "07_ra_a.sql" & vbCrLf & _
        "08_ra_f.sql" & vbCrLf

    Debug.Print "=== ExportAllRaSql DONE → " & folderPath & " ==="
End Sub

Private Sub ExportTableSql( _
    ByVal db As DAO.Database, _
    ByVal folderPath As String, _
    ByVal fileName As String, _
    ByVal accessTable As String, _
    ByVal sqlTable As String, _
    ByVal identityCol As String, _
    ByVal upsertMode As Boolean, _
    ByVal fieldNames As Variant _

)
    Dim td As DAO.TableDef
    Dim rs As DAO.Recordset
    Dim f As Variant
    Dim cols As String
    Dim line As String
    Dim vals As String
    Dim i As Long
    Dim n As Long
    Dim out As String
    Dim colSql As String
    Dim pkName As String

    On Error GoTo Fail

    Set td = db.TableDefs(accessTable)
    If Len(Nz(td.Connect, "")) > 0 Then
        out = "-- SKIP " & accessTable & ": LINKED (" & td.Connect & ")" & vbCrLf
        WriteTextFile folderPath & "\" & fileName, out
        Debug.Print accessTable & vbTab & "LINKED — skipped"
        Exit Sub
    End If

    cols = ""
    For i = LBound(fieldNames) To UBound(fieldNames)
        colSql = CStr(fieldNames(i))
        If cols <> "" Then cols = cols & ", "
        If StrComp(colSql, "key", vbTextCompare) = 0 Then
            cols = cols & "[key]"
        Else
            cols = cols & colSql
        End If
    Next i

    pkName = identityCol
    If Left$(pkName, 1) = "[" Then pkName = Mid$(pkName, 2, Len(pkName) - 2)

    out = "-- =============================================================================" & vbCrLf
    out = out & "-- Source: Access LOCAL table " & accessTable & vbCrLf
    out = out & "-- Target: " & sqlTable & vbCrLf
    out = out & "-- Generated: " & Format$(Now, "yyyy-mm-dd hh:nn:ss") & vbCrLf
    out = out & "-- =============================================================================" & vbCrLf
    out = out & "SET NOCOUNT ON;" & vbCrLf
    out = out & "PRINT '=== import " & sqlTable & " ===';" & vbCrLf
    out = out & "SET IDENTITY_INSERT " & sqlTable & " ON;" & vbCrLf
    out = out & "GO" & vbCrLf & vbCrLf

    Set rs = db.OpenRecordset("SELECT * FROM [" & accessTable & "]", dbOpenSnapshot)
    n = 0
    Do Until rs.EOF
        vals = ""
        For i = LBound(fieldNames) To UBound(fieldNames)
            If vals <> "" Then vals = vals & ", "
            vals = vals & SqlLiteral(rs.Fields(CStr(fieldNames(i))), CStr(fieldNames(i)))
        Next i

        If upsertMode Then
            line = "IF NOT EXISTS (SELECT 1 FROM " & sqlTable & " WHERE " & identityCol & " = " & _
                   SqlLiteral(rs.Fields(pkName), pkName) & ")" & vbCrLf & _
                   "    INSERT INTO " & sqlTable & " (" & cols & ") VALUES (" & vals & ");" & vbCrLf & _
                   "ELSE" & vbCrLf & _
                   "    UPDATE " & sqlTable & " SET " & BuildUpdateSet(rs, fieldNames, pkName) & _
                   " WHERE " & identityCol & " = " & SqlLiteral(rs.Fields(pkName), pkName) & ";" & vbCrLf
        Else
            line = "INSERT INTO " & sqlTable & " (" & cols & ") VALUES (" & vals & ");" & vbCrLf
        End If

        out = out & line
        n = n + 1
        ' Chunk GO every 200 rows for SSMS comfort
        If (n Mod 200) = 0 Then
            out = out & "GO" & vbCrLf
            out = out & "SET IDENTITY_INSERT " & sqlTable & " ON;" & vbCrLf
        End If
        rs.MoveNext
    Loop
    rs.Close

    out = out & vbCrLf & "SET IDENTITY_INSERT " & sqlTable & " OFF;" & vbCrLf
    out = out & "PRINT 'imported rows (source count): " & CStr(n) & "';" & vbCrLf
    out = out & "GO" & vbCrLf

    WriteTextFile folderPath & "\" & fileName, out
    Debug.Print accessTable & vbTab & "LOCAL" & vbTab & n & " rows → " & fileName
    Exit Sub

Fail:
    Debug.Print "ERROR ExportTableSql " & accessTable & ": " & Err.Number & " " & Err.Description
    WriteTextFile folderPath & "\" & fileName, "-- ERROR " & accessTable & ": " & Err.Number & " " & Err.Description & vbCrLf
End Sub

Private Function BuildUpdateSet(ByVal rs As DAO.Recordset, ByVal fieldNames As Variant, ByVal pkName As String) As String
    Dim i As Long
    Dim fn As String
    Dim s As String
    For i = LBound(fieldNames) To UBound(fieldNames)
        fn = CStr(fieldNames(i))
        If StrComp(fn, pkName, vbTextCompare) <> 0 Then
            If s <> "" Then s = s & ", "
            If StrComp(fn, "key", vbTextCompare) = 0 Then
                s = s & "[key] = " & SqlLiteral(rs.Fields(fn), fn)
            Else
                s = s & fn & " = " & SqlLiteral(rs.Fields(fn), fn)
            End If
        End If
    Next i
    BuildUpdateSet = s
End Function

''' Convert DAO field value to T-SQL literal.
Private Function SqlLiteral(ByVal fld As DAO.Field, ByVal fieldName As String) As String
    Dim v As Variant
    Dim t As Integer
    Dim s As String

    If IsNull(fld.Value) Then
        SqlLiteral = "NULL"
        Exit Function
    End If

    v = fld.Value
    t = fld.Type

    ' FEMSQ: ft_s_period is NVARCHAR on SQL; Access may be Number
    If StrComp(fieldName, "ft_s_period", vbTextCompare) = 0 Then
        SqlLiteral = "N'" & SqlEscape(CStr(v)) & "'"
        Exit Function
    End If

    Select Case t
        Case DAO_BOOLEAN
            If CBool(v) Then SqlLiteral = "1" Else SqlLiteral = "0"
        Case DAO_BYTE, DAO_INTEGER, DAO_LONG, DAO_BIGINT, DAO_SINGLE, DAO_DOUBLE, DAO_CURRENCY, DAO_NUMERIC, DAO_DECIMAL
            SqlLiteral = Replace(CStr(v), ",", ".")
        Case DAO_DATE
            SqlLiteral = "'" & Format$(CDate(v), "yyyy-mm-dd HH:nn:ss") & "'"
        Case DAO_TEXT, DAO_MEMO, DAO_GUID
            s = CStr(v)
            ' Guard extremely large memos in one line (SSMS); keep as NVARCHAR literal
            SqlLiteral = "N'" & SqlEscape(s) & "'"
        Case Else
            SqlLiteral = "N'" & SqlEscape(CStr(v)) & "'"
    End Select
End Function

Private Function SqlEscape(ByVal s As String) As String
    SqlEscape = Replace(s, "'", "''")
End Function

Private Sub EnsureFolder(ByVal folderPath As String)
    Dim fso As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FolderExists(folderPath) Then
        fso.CreateFolder folderPath
    End If
End Sub

Private Sub WriteTextFile(ByVal fullPath As String, ByVal content As String)
    Dim fso As Object
    Dim ts As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    ' UTF-16 LE (TristateTrue) — safest for Cyrillic in Access VBA
    Set ts = fso.CreateTextFile(fullPath, True, True)
    ts.Write content
    ts.Close
End Sub
