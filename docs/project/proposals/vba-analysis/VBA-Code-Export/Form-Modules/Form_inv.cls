VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_inv"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()
    Dim ciKey As Long
    Const cstrTitle As String = "Процедура *текущая запись формы Счёт-Фактура*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler


    If IsNull(Me![inv>cnInv].Form!ciKey) Then
        ciKey = 0
    Else
        ciKey = Me![inv>cnInv].Form!ciKey
    End If
    
    Me!cnInv.Form.Form.Filter = "ciKey = " & ciKey
    Me!cnInv.Form.Form.FilterOn = True

NormalExit:
    Exit Sub
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
End Sub
