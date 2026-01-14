VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_cnInv>GrCmm_t"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

'ошибки кидать не будем
On Error Resume Next

Dim InvKey As Integer

If IsNull(Me!cnicKey) Then
    InvKey = 0
Else
    InvKey = Me!cnicKey
End If

'If invKey <> 0 Then
    Me.parent![cnInv>GrCmm_f].Form.Form.Filter _
        = "cnicKey = " & InvKey
    Me.parent![cnInv>GrCmm_f].Form.Form.FilterOn = True
'End If

End Sub
