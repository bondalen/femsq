VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_cnNum>cn>cn>ciNum"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

'ошибки кидать не будем
On Error Resume Next

Dim InvKey As Integer

If IsNull(Me!iKey) Then
    InvKey = 0
Else
    InvKey = Me!iKey
End If

'Me.Parent!inv.Form.Form.Filter = "iKey = " & invKey
'Me.Parent!inv.Form.Form.FilterOn = True

End Sub


