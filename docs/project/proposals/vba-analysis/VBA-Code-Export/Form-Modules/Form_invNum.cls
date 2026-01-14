VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_invNum"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

'ошибки кидать не будем inv>cnInv
On Error Resume Next

Dim ciKey As Long

If IsNull(Me![invNum>inv].Form![inv>cnInv].Form!ciKey) Then
    ciKey = 0
Else
    ciKey = Me![invNum>inv].Form![inv>cnInv].Form!ciKey
End If

Me![invNum>inv].Form!cnInv.Form.Form.Filter = "ciKey = " & ciKey
Me![invNum>inv].Form!cnInv.Form.Form.FilterOn = True

End Sub
