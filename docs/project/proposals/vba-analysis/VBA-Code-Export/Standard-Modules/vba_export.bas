Attribute VB_Name = "vba_export"
Option Compare Database

Sub ExportAllModules()
    Dim obj As Object
    Dim path As String
    Dim subPath As String
    Dim filename As String
    
    ' Укажите путь для экспорта
    path = "D:\db\jre\vba_export\"
    
    ' Создайте основную папку если не существует
    If Dir(path, vbDirectory) = "" Then
        MkDir path
    End If
    
    ' Создайте подпапки
    If Dir(path & "Standard-Modules\", vbDirectory) = "" Then
        MkDir path & "Standard-Modules\"
    End If
    
    If Dir(path & "Class-Modules\", vbDirectory) = "" Then
        MkDir path & "Class-Modules\"
    End If
    
    If Dir(path & "Form-Modules\", vbDirectory) = "" Then
        MkDir path & "Form-Modules\"
    End If
    
    ' Счётчик файлов
    Dim count As Integer
    count = 0
    
    ' Экспорт всех модулей
    For Each obj In Application.VBE.ActiveVBProject.VBComponents
    
        filename = Replace(obj.name, ">", "_gt_")
    
        Select Case obj.type
            Case 1 ' Standard Module
                obj.Export path & "Standard-Modules\" & filename & ".bas"
                count = count + 1
                
            Case 2 ' Class Module
                obj.Export path & "Class-Modules\" & filename & ".cls"
                count = count + 1
                
            Case 100 ' Document Module (Form/Report)
                obj.Export path & "Form-Modules\" & filename & ".cls"
                count = count + 1
        End Select
    Next obj
    
    MsgBox "Экспорт завершен!" & vbCrLf & _
           "Всего файлов: " & count & vbCrLf & _
           "Путь: " & path, vbInformation
End Sub

