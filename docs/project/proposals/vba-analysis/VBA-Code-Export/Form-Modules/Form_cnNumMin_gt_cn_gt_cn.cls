VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_cnNumMin>cn>cn"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub bnInvFormOpen_Click()

' cnNum>cn>cn>ciNum

If Not IsNull(Me![cnNum>cn>cn>ciNum].Form.iKey) Then
    DoCmd.OpenForm "Inv", _
        WhereCondition:="iKey=" & Me![cnNum>cn>cn>ciNum].Form.iKey
End If


End Sub

' добавляем новый счёт-фактуру cnAddNewInv
Private Sub btnInvNewAdd_Click()
Dim strA As String

strA = Me.parent!cn_key 'cn_key
DoCmd.OpenForm FormName:="cnAddNewInv", WindowMode:=acDialog, OpenArgs:=strA
'MsgBox ("InvNewAdd!!!")
Me![cnNum>cn>Inv].Requery
End Sub

Private Sub Form_Current()

'ошибки кидать не будем
On Error Resume Next

Dim InvKey As Integer

If IsNull(Me![cnNum>cn>cn>ciNum].Form.iKey) Then
    InvKey = 0
Else
    InvKey = Me![cnNum>cn>cn>ciNum].Form.iKey
End If

Me!Inv.Form.Form.Filter = "iKey = " & InvKey
Me!Inv.Form.Form.FilterOn = True

End Sub
