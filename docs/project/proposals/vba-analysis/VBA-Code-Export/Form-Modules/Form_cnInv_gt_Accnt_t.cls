VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_cnInv>Accnt_t"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

'ошибки кидать не будем
On Error Resume Next

Dim key As Integer

If IsNull(Me!ciaKey) Then
    key = 0
Else
    key = Me!ciaKey
End If

If key <> 0 Then
    Me.parent![cnInv>Accnt_f].Form.Form.Filter _
        = "ciaKey = " & key
    Me.parent![cnInv>Accnt_f].Form.Form.FilterOn = True
End If

End Sub
