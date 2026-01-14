VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_ipgMin"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

    Dim ipgpKey As Integer
    
    Const cstrTitle As String = "Функция *Текущая запись ~Инвестпрограммы~*"

    ' ***************************************************************************************************************************

On Error GoTo ErrHandler


If IsNull(Me![ipg>Pn_t].Form.ipgpKey) Then
    ipgpKey = 0
Else
    ipgpKey = Me![ipg>Pn_t].Form.ipgpKey
End If

Me![ipg>Pn_f].Form.Form.Filter = "ipgpKey = " & ipgpKey
Me![ipg>Pn_f].Form.Form.FilterOn = True


NormalExit:
    Exit Sub

ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number, vbExclamation, cstrTitle
    Resume NormalExit


End Sub
