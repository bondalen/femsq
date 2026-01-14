Attribute VB_Name = "Test"
Option Compare Database

' Dim MyArrayBrnPart1(1 To 179, 1 To 2)

' проверим существование объекта форма у контроля. 19.09.2022
Public Function controlFormNoError(controlTest As Control) As Boolean
    Dim testForm As Form
On Error GoTo noErrorFalse
    
    Set testForm = controlTest.Form: controlFormNoError = True: Exit Function
    
noErrorFalse:
    controlFormNoError = False
End Function




