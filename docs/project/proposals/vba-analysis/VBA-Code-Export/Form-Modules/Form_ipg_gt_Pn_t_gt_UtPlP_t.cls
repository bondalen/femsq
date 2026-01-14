VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_ipg>Pn_t>UtPlP_t"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

    Dim pnKey As Long
    
    Const cstrTitle As String = "Функция *Текущая запись ~Пункт уточненного плана~*"

    ' ***************************************************************************************************************************

On Error GoTo ErrHandler

    If IsNull(Me!iuplpKey) Then
        pnKey = 0
    Else
        pnKey = Me!iuplpKey
    End If
    
    ' фильтруем год
    Me.parent.Form![ipg>Pn_f>UtPlPnLmYe].Form.Filter = "iuplpyPlPn = " & pnKey
    Me.parent.Form![ipg>Pn_f>UtPlPnLmYe].Form.FilterOn = True
    ' фильтруем квартал
    Me.parent.Form![ipg>Pn_f>UtPlPnLmQu].Form.Filter = "iuplpqPlPn = " & pnKey
    Me.parent.Form![ipg>Pn_f>UtPlPnLmQu].Form.FilterOn = True
    ' фильтруем месяц
    Me.parent.Form![ipg>Pn_f>UtPlPnLmMn].Form.Filter = "iuplpmPlPn = " & pnKey
    Me.parent.Form![ipg>Pn_f>UtPlPnLmMn].Form.FilterOn = True

    ' ***************************************************************************************************************************
NormalExit:
    Exit Sub

ErrHandler:
    
    If Err.Number <> 2455 Then
        MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number, vbExclamation, cstrTitle
        Resume NormalExit
    End If

End Sub
