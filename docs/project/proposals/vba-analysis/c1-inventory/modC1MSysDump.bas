Attribute VB_Name = "modC1MSysDump"
'
' C1 inventory via MSysObjects ONLY.
' Does NOT touch CurrentProject.AllForms / AllReports (those can trigger
' Access "system language" save dialogs on this locale).
'
' Before run: close Access without saving, reopen ACCDB, import this module,
' do not open any form/report/table. Then Immediate:
'   DumpC1MSys "D:\wire-guard-share-nb-win\femsq\access\26-1117\femsq-c1\c1-inventory"
'
' MSysObjects.Type: Form=-32768 Report=-32764 Macro=-32766 Module=-32761 Query=5 Table=1
'
' created: 2026-11-17
'
Option Compare Database
Option Explicit

Public Sub DumpC1MSys(Optional ByVal folderPath As String = "C:\temp\c1-inventory")
    Dim t0 As Double
    t0 = Timer
    C1M_EnsureFolder folderPath

    Debug.Print "=== DumpC1MSys -> " & folderPath & " ==="
    Debug.Print "module=modC1MSysDump"
    Debug.Print "db=" & CurrentDb.Name
    Debug.Print "started=" & Format$(Now, "yyyy-mm-dd Hh:Nn:Ss")

    C1M_DumpByType folderPath, "forms.tsv", -32768, "forms"
    C1M_DumpByType folderPath, "reports.tsv", -32764, "reports"
    C1M_DumpByType folderPath, "macros.tsv", -32766, "macros"
    C1M_DumpByType folderPath, "modules.tsv", -32761, "modules"
    C1M_DumpQueries folderPath
    C1M_DumpLinkedTables folderPath

    Debug.Print "=== DumpC1MSys DONE elapsed~" & Format$(Timer - t0, "0.0") & "s ==="
End Sub

''' <summary>Only forms list (smoke test).</summary>
Public Sub DumpC1MSysForms(Optional ByVal folderPath As String = "C:\temp\c1-inventory")
    C1M_EnsureFolder folderPath
    Debug.Print "--- DumpC1MSysForms ---"
    C1M_DumpByType folderPath, "forms.tsv", -32768, "forms"
End Sub

''' <summary>Only reports list (smoke test).</summary>
Public Sub DumpC1MSysReports(Optional ByVal folderPath As String = "C:\temp\c1-inventory")
    C1M_EnsureFolder folderPath
    Debug.Print "--- DumpC1MSysReports ---"
    C1M_DumpByType folderPath, "reports.tsv", -32764, "reports"
End Sub

Private Sub C1M_DumpByType(ByVal folderPath As String, ByVal fileName As String, _
        ByVal objType As Long, ByVal label As String)
    Dim db As DAO.Database
    Dim rs As DAO.Recordset
    Dim sql As String
    Dim lines As String
    Dim nOk As Long
    Dim nm As String
    Dim dt As String

    Debug.Print "--- " & label & " (MSysObjects type=" & objType & ") ---"
    Set db = CurrentDb
    sql = "SELECT Name, DateUpdate FROM MSysObjects WHERE Type=" & objType & _
          " AND Left([Name],1)<>'~' ORDER BY Name"
    Set rs = db.OpenRecordset(sql, dbOpenSnapshot)

    lines = "name" & vbTab & "dateUpdate" & vbCrLf
    Do Until rs.EOF
        nm = rs!Name & ""
        If IsNull(rs!DateUpdate) Then
            dt = ""
        Else
            dt = Format$(rs!DateUpdate, "yyyy-mm-dd Hh:Nn:Ss")
        End If
        lines = lines & nm & vbTab & dt & vbCrLf
        nOk = nOk + 1
        rs.MoveNext
    Loop
    rs.Close

    C1M_WriteUtf8 folderPath & "\" & fileName, lines
    Debug.Print label & " ok=" & nOk
End Sub

Private Sub C1M_DumpQueries(ByVal folderPath As String)
    Dim db As DAO.Database
    Dim qdf As DAO.QueryDef
    Dim index As String
    Dim nOk As Long, nSkip As Long
    Dim qFolder As String
    Dim fso As Object
    Dim body As String

    Debug.Print "--- queries (QueryDefs) ---"
    Set db = CurrentDb
    Set fso = CreateObject("Scripting.FileSystemObject")
    qFolder = folderPath & "\queries"
    If Not fso.FolderExists(qFolder) Then fso.CreateFolder qFolder

    index = "name" & vbTab & "type" & vbTab & "sqlChars" & vbTab & "file" & vbCrLf
    For Each qdf In db.QueryDefs
        If Left$(qdf.Name, 1) = "~" Then
            nSkip = nSkip + 1
        Else
            body = "-- Access QueryDef: " & qdf.Name & vbCrLf & _
                   "-- Type: " & CStr(qdf.Type) & vbCrLf & vbCrLf & qdf.SQL
            C1M_WriteUtf8 qFolder & "\" & C1M_SafeFileName(qdf.Name) & ".sql", body
            index = index & qdf.Name & vbTab & CStr(qdf.Type) & vbTab & _
                    CStr(Len(qdf.SQL)) & vbTab & C1M_SafeFileName(qdf.Name) & ".sql" & vbCrLf
            nOk = nOk + 1
        End If
    Next qdf

    C1M_WriteUtf8 folderPath & "\queries.tsv", index
    Debug.Print "queries ok=" & nOk & " skipTemp=" & nSkip
End Sub

Private Sub C1M_DumpLinkedTables(ByVal folderPath As String)
    Dim db As DAO.Database
    Dim tdf As DAO.TableDef
    Dim lines As String
    Dim nOk As Long, nLocal As Long

    Debug.Print "--- linked tables ---"
    Set db = CurrentDb
    lines = "name" & vbTab & "connect" & vbTab & "sourceTableName" & vbCrLf
    For Each tdf In db.TableDefs
        If Left$(tdf.Name, 4) = "MSys" Then
            ' skip
        ElseIf Len(tdf.Connect) = 0 Then
            nLocal = nLocal + 1
        Else
            lines = lines & tdf.Name & vbTab & _
                    Replace(Replace(tdf.Connect, vbTab, " "), vbCrLf, " | ") & vbTab & _
                    tdf.SourceTableName & vbCrLf
            nOk = nOk + 1
        End If
    Next tdf
    C1M_WriteUtf8 folderPath & "\linked-tables.tsv", lines
    Debug.Print "linked=" & nOk & " localSkipped=" & nLocal
End Sub

Private Sub C1M_EnsureFolder(ByVal folderPath As String)
    Dim fso As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FolderExists(folderPath) Then fso.CreateFolder folderPath
End Sub

Private Function C1M_SafeFileName(ByVal s As String) As String
    Dim bad As Variant, i As Long
    bad = Array("\", "/", ":", "*", "?", """", "<", ">", "|")
    C1M_SafeFileName = s
    For i = LBound(bad) To UBound(bad)
        C1M_SafeFileName = Replace(C1M_SafeFileName, CStr(bad(i)), "_")
    Next i
End Function

Private Sub C1M_WriteUtf8(ByVal filePath As String, ByVal text As String)
    Dim stm As Object
    Set stm = CreateObject("ADODB.Stream")
    stm.Type = 2
    stm.Charset = "utf-8"
    stm.Open
    stm.WriteText text
    stm.SaveToFile filePath, 2
    stm.Close
End Sub
