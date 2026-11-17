Attribute VB_Name = "modC1VbaExport"
'
' ExportAllModules for C1 — writes next to the working ACCDB copy on the share.
' Original template: docs/project/proposals/vba-analysis/VBA-Code-Export/Standard-Modules/vba_export.bas
'
' Immediate:
'   ExportAllModulesC1
' Or with path:
'   ExportAllModulesC1 "D:\wire-guard-share-nb-win\femsq\access\26-1117\femsq-c1\VBA-Code-Export\"
'
' created: 2026-11-17
'
Option Compare Database
Option Explicit

Public Sub ExportAllModulesC1(Optional ByVal path As String = "")
    Dim obj As Object
    Dim filename As String
    Dim count As Long

    If Len(path) = 0 Then
        path = "D:\wire-guard-share-nb-win\femsq\access\26-1117\femsq-c1\VBA-Code-Export\"
    End If
    If Right$(path, 1) <> "\" Then path = path & "\"

    If Dir(path, vbDirectory) = "" Then MkDir path
    If Dir(path & "Standard-Modules\", vbDirectory) = "" Then MkDir path & "Standard-Modules\"
    If Dir(path & "Class-Modules\", vbDirectory) = "" Then MkDir path & "Class-Modules\"
    If Dir(path & "Form-Modules\", vbDirectory) = "" Then MkDir path & "Form-Modules\"

    count = 0
    For Each obj In Application.VBE.ActiveVBProject.VBComponents
        filename = Replace(obj.Name, ">", "_gt_")
        Select Case obj.Type
            Case 1
                obj.Export path & "Standard-Modules\" & filename & ".bas"
                count = count + 1
            Case 2
                obj.Export path & "Class-Modules\" & filename & ".cls"
                count = count + 1
            Case 100
                obj.Export path & "Form-Modules\" & filename & ".cls"
                count = count + 1
        End Select
    Next obj

    Debug.Print "ExportAllModulesC1 done count=" & count & " path=" & path
    MsgBox "Export done. Files: " & count & vbCrLf & path, vbInformation
End Sub
