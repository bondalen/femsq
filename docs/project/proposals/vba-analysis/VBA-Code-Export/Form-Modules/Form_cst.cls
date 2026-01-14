VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_cst"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

    Dim raKey As Integer

    Const cstrTitle As String _
    = "Процедура *Смена текущей записи формы СТРОЙКИ*"
    ' ***************************************************************************************************************************

On Error GoTo ErrHandler
    
    If IsNull(Me!cstKey) Then
        RefreshCstChart (0)
        Else
        RefreshCstChart (Me!cstKey)
    End If
    
    'RefreshCstChart (cstKey)
    
    Me![cst>ra_t].Requery
    Me![cst>raUtil_t].Requery
    
    If IsNull(Me.Form![cst>ra_t].Form![ra_key]) Or IsEmpty(Me.Form![cst>ra_t].Form![ra_key]) Then
        raKey = 0
    Else
        raKey = Me.Form![cst>ra_t].Form![ra_key]
    End If
    
    ' фильтруем отчёт
    Me.Form![cst>ra_f].Form.Filter = "ra_key = " & raKey
    Me.Form![cst>ra_f].Form.FilterOn = True

    ' ***************************************************************************************************************************
NormalExit:
    Exit Sub
    
ErrHandler:

    If Err.Number = 2427 Then
        raKey = 0
        Resume Next
    Else
        MsgBox Err.Description & vbCrLf & "№ ошибки: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
        Resume NormalExit
    End If

End Sub
