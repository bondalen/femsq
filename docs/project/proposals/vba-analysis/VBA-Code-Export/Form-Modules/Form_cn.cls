VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_cn"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

'ошибки кидать не будем
On Error Resume Next

Dim InvKey As Integer

If IsNull(Me.[cn>cnInv]!ciKey) Then
    InvKey = 0
Else
    InvKey = Me.[cn>cnInv]!ciKey
End If

If InvKey <> 0 Then
    Me![cn>cnInv_f].Form.Form.Filter _
        = "ciKey = " & InvKey
    Me![cn>cnInv_f].Form.Form.FilterOn = True
End If

End Sub
