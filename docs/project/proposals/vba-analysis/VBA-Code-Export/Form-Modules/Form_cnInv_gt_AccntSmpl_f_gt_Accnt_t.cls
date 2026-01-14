VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_cnInv>AccntSmpl_f>Accnt_t"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

Dim ciaKey As Integer

'ошибки кидать не будем
On Error Resume Next

If IsNull(Me!ciaKey) Then
    ciaKey = 0
Else
    ciaKey = Me!ciaKey
End If

'If ciasKey <> 0 Then
'End If
    Me.parent![cnInv>AccntSmpl_f>Accnt_f].Form.Form.Filter _
        = "ciaKey = " & ciaKey
    Me.parent![cnInv>AccntSmpl_f>Accnt_f].Form.Form.FilterOn = True

End Sub
