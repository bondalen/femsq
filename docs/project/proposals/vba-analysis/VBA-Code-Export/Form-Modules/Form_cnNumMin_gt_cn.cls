VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_cnNumMin>cn"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

'ошибки кидать не будем
On Error Resume Next

Dim InvKey As Long

If IsNull(Me![cnNum>cn>cn].Form![cnNum>cn>cn>ciNum].Form.iKey) Then
    InvKey = 0
Else
    InvKey = Me![cnNum>cn>cn].Form![cnNum>cn>cn>ciNum].Form.iKey
End If

Me![cnNum>cn>cn].Form!Inv.Form.Form.Filter = "iKey = " & InvKey
Me![cnNum>cn>cn].Form!Inv.Form.Form.FilterOn = True

End Sub
