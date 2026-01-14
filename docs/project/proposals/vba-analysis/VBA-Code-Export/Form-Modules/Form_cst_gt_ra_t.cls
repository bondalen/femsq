VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_cst>ra_t"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()
    
    Dim raKey As Double
    
    Const cstrTitle As String = "Функция *Текущая запись ~Перечня отчётов стройки~*"

    ' ***************************************************************************************************************************

On Error GoTo ErrHandler

    If IsNull(Me!ra_key) Then
        raKey = 0
    Else
        raKey = Me!ra_key
    End If
    
    ' фильтруем отчёт
    Me.parent.Form![cst>ra_f].Form.FilterOn = False
    Me.parent.Form![cst>ra_f].Form.Filter = "ra_key = " & raKey
    Me.parent.Form![cst>ra_f].Form.FilterOn = True

    ' ***************************************************************************************************************************
NormalExit:
    Exit Sub

ErrHandler:
    
    If Err.Number <> 2455 Then
        MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number, vbExclamation, cstrTitle
        Resume NormalExit
    End If

End Sub
