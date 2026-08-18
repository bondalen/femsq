Attribute VB_Name = "modDumpCipuQueryDefs"
'
' Dump SQL of live cipu* QueryDefs (CnInvPmtUpl passport).
' Immediate truncates long SQL and mangles Cyrillic — write UTF-8 files instead.
' Immediate:
'   DumpCipuQueryDefs "C:\temp\cipu-sql"
'
' Module name MUST differ from Sub name (else: Expected variable or procedure, not module).
' Skips names with legacy "Old"/"Old2". Does not skip OId / OIdNot (org_id).
' Extra (not cipu*): agsCnCtpt*SmplBuirg* , agsOrgIdBUiRG, agsInvNumCount.
' After editing this file: re-import into Access (VBA still has the old extra list
' until the module is replaced). Immediate Cyrillic will look like mojibake — ignore it.
'
' created: 2026-08-17
' lastUpdated: 2026-08-17
'
Option Compare Database
Option Explicit

''' <summary>
''' Пишет SQL каждого живого QueryDef cipu* в UTF-8 файлы папки folderPath.
''' В Immediate — только каталог имён (без тел SQL).
''' </summary>
Public Sub DumpCipuQueryDefs(Optional ByVal folderPath As String = "C:\temp\cipu-sql")
    Dim db As DAO.Database
    Dim qdf As DAO.QueryDef
    Dim fso As Object
    Dim nOk As Long, nSkip As Long
    Dim extra As Variant, i As Long

    Set db = CurrentDb
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FolderExists(folderPath) Then fso.CreateFolder folderPath

    Debug.Print "=== DumpCipuQueryDefs → " & folderPath & " ==="

    For Each qdf In db.QueryDefs
        If Left$(qdf.Name, 1) = "~" Then
            ' временные QueryDef Access — пропуск
        ElseIf DumpCipu_IsLegacyOld(qdf.Name) Then
            nSkip = nSkip + 1
        ElseIf Left$(qdf.Name, 4) = "cipu" Then
            DumpCipu_WriteQdf folderPath, qdf
            nOk = nOk + 1
        End If
    Next qdf

    extra = Array("agsCnCtptExequtorSmplBuirg", "agsOrgIdBUiRG", _
                  "agsCnCtptExequtorSmplBuirgOne", "agsCnCtptAgentSmplBuirg", _
                  "agsCnCtptAgentSmplBuirgOne", "agsInvNumCount")
    Debug.Print "--- extra (" & CStr(UBound(extra) - LBound(extra) + 1) & ") ---"
    For i = LBound(extra) To UBound(extra)
        DumpCipu_TryName db, folderPath, CStr(extra(i)), nOk, nSkip
    Next i

    Debug.Print "OK files=" & nOk & "  skipped Old=" & nSkip
    Debug.Print "Copy folder to chat (UTF-8 files). Immediate Cyrillic is expected garbage."
End Sub

''' <summary>True, если имя — архивный суффикс Old / Old2, а не OId (org_id).</summary>
Private Function DumpCipu_IsLegacyOld(ByVal qName As String) As Boolean
    Dim p As Long
    p = InStr(1, qName, "Old", vbTextCompare)
    If p = 0 Then
        DumpCipu_IsLegacyOld = False
        Exit Function
    End If
    ' OId / OIdNot: буква после O — I, не l
    If p >= 2 Then
        If UCase$(Mid$(qName, p - 1, 3)) = "OID" Then
            DumpCipu_IsLegacyOld = False
            Exit Function
        End If
    End If
    DumpCipu_IsLegacyOld = True
End Function

Private Sub DumpCipu_TryName(ByVal db As DAO.Database, ByVal folderPath As String, _
        ByVal objName As String, ByRef nOk As Long, ByRef nSkip As Long)
    Dim qdf As DAO.QueryDef
    Dim tdf As DAO.TableDef
    On Error Resume Next
    Set qdf = db.QueryDefs(objName)
    If Err.Number = 0 Then
        On Error GoTo 0
        If DumpCipu_IsLegacyOld(objName) Then
            nSkip = nSkip + 1
        Else
            DumpCipu_WriteQdf folderPath, qdf
            nOk = nOk + 1
        End If
        Exit Sub
    End If
    Err.Clear
    Set tdf = db.TableDefs(objName)
    If Err.Number = 0 Then
        Debug.Print "TABLE (not QueryDef): " & objName
    Else
        Debug.Print "MISSING: " & objName
    End If
    On Error GoTo 0
End Sub

Private Sub DumpCipu_WriteQdf(ByVal folderPath As String, ByVal qdf As DAO.QueryDef)
    Dim path As String, body As String, typ As String
    path = folderPath & "\" & qdf.Name & ".sql"
    typ = DumpCipu_TypeLabel(qdf.Type)
    body = "-- Access QueryDef: " & qdf.Name & vbCrLf & _
           "-- Type: " & typ & " (" & CStr(qdf.Type) & ")" & vbCrLf & _
           "-- dumped: " & Format$(Now, "yyyy-mm-dd Hh:Nn") & vbCrLf & vbCrLf & _
           qdf.SQL
    DumpCipu_WriteUtf8 path, body
    Debug.Print qdf.Name & vbTab & typ & vbTab & Len(qdf.SQL) & "c"
End Sub

Private Function DumpCipu_TypeLabel(ByVal t As Long) As String
    Select Case t
        Case 0: DumpCipu_TypeLabel = "SELECT"
        Case 16: DumpCipu_TypeLabel = "CROSSTAB"
        Case 32: DumpCipu_TypeLabel = "DELETE"
        Case 48: DumpCipu_TypeLabel = "UPDATE"
        Case 64: DumpCipu_TypeLabel = "APPEND"
        Case 80: DumpCipu_TypeLabel = "MAKETABLE"
        Case 96: DumpCipu_TypeLabel = "DDL"
        Case 112: DumpCipu_TypeLabel = "PASSTHROUGH"
        Case 128: DumpCipu_TypeLabel = "UNION"
        Case Else: DumpCipu_TypeLabel = "TYPE" & CStr(t)
    End Select
End Function

Private Sub DumpCipu_WriteUtf8(ByVal filePath As String, ByVal text As String)
    Dim stm As Object
    Set stm = CreateObject("ADODB.Stream")
    stm.Type = 2
    stm.Charset = "utf-8"
    stm.Open
    stm.WriteText text
    stm.SaveToFile filePath, 2
    stm.Close
End Sub
