VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_stNet>fnSt_t"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

'ошибки кидать не будем
On Error Resume Next

Dim InvKey As Integer

If IsNull(Me.[strChild]) Then
    InvKey = 0
Else
    InvKey = Me.[strChild]
End If

If InvKey <> 0 Then
    Me.parent![stNetCost>stCost].Form.Form.Filter = "stcKey = " & InvKey
    Me.parent![stNetCost>stCost].Form.Form.FilterOn = True
End If

End Sub
