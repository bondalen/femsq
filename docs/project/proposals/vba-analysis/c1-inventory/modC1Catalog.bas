Attribute VB_Name = "modC1Catalog"
'
' C1 LITE ONLY — no SaveAsText, no Design, no VBE form/report load.
' (SaveAsText fails with locale dialog if Windows system locale != object language.)
'
' Immediate (after Remove + Import this module):
'   DumpC1Catalog "D:\wire-guard-share-nb-win\femsq\access\26-1117\femsq-c1\c1-inventory"
' Or step by step:
'   DumpC1FormsLite "D:\...\c1-inventory"
'   DumpC1ReportsLite "D:\...\c1-inventory"
'   DumpC1Queries "D:\...\c1-inventory"
'   DumpC1Macros "D:\...\c1-inventory"
'   DumpC1LinkedTables "D:\...\c1-inventory"
'
' created: 2026-11-17
' lastUpdated: 2026-11-17
'
Option Compare Database
Option Explicit

Public Sub DumpC1Catalog(Optional ByVal folderPath As String = "C:\temp\c1-inventory")
    Dim t0 As Double
    t0 = Timer
    C1_EnsureFolder folderPath

    Debug.Print "=== DumpC1Catalog LITE-ONLY -> " & folderPath & " ==="
    Debug.Print "db=" & CurrentDb.Name
    Debug.Print "started=" & Format$(Now, "yyyy-mm-dd Hh:Nn:Ss")
    Debug.Print "mode=lite-only (NO SaveAsText)"

    DumpC1FormsLite folderPath
    DumpC1ReportsLite folderPath
    DumpC1Queries folderPath
    DumpC1Macros folderPath
    DumpC1LinkedTables folderPath

    Debug.Print "=== DumpC1Catalog DONE elapsed~" & Format$(Timer - t0, "0.0") & "s ==="
End Sub

Public Sub DumpC1FormsLite(Optional ByVal folderPath As String = "C:\temp\c1-inventory")
    Dim ao As AccessObject
    Dim lines As String
    Dim nOk As Long

    C1_EnsureFolder folderPath
    Debug.Print "--- forms lite ---"
    lines = "name" & vbTab & "dateModified" & vbCrLf

    For Each ao In CurrentProject.AllForms
        lines = lines & ao.Name & vbTab & Format$(ao.DateModified, "yyyy-mm-dd Hh:Nn:Ss") & vbCrLf
        nOk = nOk + 1
        If (nOk Mod 50) = 0 Then Debug.Print "forms progress=" & nOk
        DoEvents
    Next ao

    C1_WriteUtf8 folderPath & "\forms.tsv", lines
    Debug.Print "forms ok=" & nOk
End Sub

Public Sub DumpC1ReportsLite(Optional ByVal folderPath As String = "C:\temp\c1-inventory")
    Dim ao As AccessObject
    Dim lines As String
    Dim nOk As Long

    C1_EnsureFolder folderPath
    Debug.Print "--- reports lite ---"
    lines = "name" & vbTab & "dateModified" & vbCrLf

    For Each ao In CurrentProject.AllReports
        lines = lines & ao.Name & vbTab & Format$(ao.DateModified, "yyyy-mm-dd Hh:Nn:Ss") & vbCrLf
        nOk = nOk + 1
        If (nOk Mod 50) = 0 Then Debug.Print "reports progress=" & nOk
        DoEvents
    Next ao

    C1_WriteUtf8 folderPath & "\reports.tsv", lines
    Debug.Print "reports ok=" & nOk
End Sub

Public Sub DumpC1Queries(Optional ByVal folderPath As String = "C:\temp\c1-inventory")
    Dim db As DAO.Database
    Dim qdf As DAO.QueryDef
    Dim index As String
    Dim nOk As Long, nSkip As Long
    Dim qFolder As String
    Dim fso As Object
    Dim body As String

    C1_EnsureFolder folderPath
    Debug.Print "--- queries ---"
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
            C1_WriteUtf8 qFolder & "\" & C1_SafeFileName(qdf.Name) & ".sql", body
            index = index & qdf.Name & vbTab & CStr(qdf.Type) & vbTab & _
                    CStr(Len(qdf.SQL)) & vbTab & C1_SafeFileName(qdf.Name) & ".sql" & vbCrLf
            nOk = nOk + 1
        End If
    Next qdf

    C1_WriteUtf8 folderPath & "\queries.tsv", index
    Debug.Print "queries ok=" & nOk & " skipTemp=" & nSkip
End Sub

Public Sub DumpC1Macros(Optional ByVal folderPath As String = "C:\temp\c1-inventory")
    Dim ao As AccessObject
    Dim lines As String
    Dim nOk As Long

    C1_EnsureFolder folderPath
    Debug.Print "--- macros ---"
    lines = "name" & vbTab & "dateModified" & vbCrLf
    For Each ao In CurrentProject.AllMacros
        lines = lines & ao.Name & vbTab & Format$(ao.DateModified, "yyyy-mm-dd Hh:Nn:Ss") & vbCrLf
        nOk = nOk + 1
    Next ao
    C1_WriteUtf8 folderPath & "\macros.tsv", lines
    Debug.Print "macros ok=" & nOk
End Sub

Public Sub DumpC1LinkedTables(Optional ByVal folderPath As String = "C:\temp\c1-inventory")
    Dim db As DAO.Database
    Dim tdf As DAO.TableDef
    Dim lines As String
    Dim nOk As Long, nLocal As Long

    C1_EnsureFolder folderPath
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

    C1_WriteUtf8 folderPath & "\linked-tables.tsv", lines
    Debug.Print "linked=" & nOk & " localSkipped=" & nLocal
End Sub

Private Sub C1_EnsureFolder(ByVal folderPath As String)
    Dim fso As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FolderExists(folderPath) Then fso.CreateFolder folderPath
End Sub

Private Function C1_SafeFileName(ByVal s As String) As String
    Dim bad As Variant, i As Long
    bad = Array("\", "/", ":", "*", "?", """", "<", ">", "|")
    C1_SafeFileName = s
    For i = LBound(bad) To UBound(bad)
        C1_SafeFileName = Replace(C1_SafeFileName, CStr(bad(i)), "_")
    Next i
End Function

Private Sub C1_WriteUtf8(ByVal filePath As String, ByVal text As String)
    Dim stm As Object
    Set stm = CreateObject("ADODB.Stream")
    stm.Type = 2
    stm.Charset = "utf-8"
    stm.Open
    stm.WriteText text
    stm.SaveToFile filePath, 2
    stm.Close
End Sub
