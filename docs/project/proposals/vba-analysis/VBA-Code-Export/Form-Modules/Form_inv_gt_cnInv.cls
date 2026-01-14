VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_inv>cnInv"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

'ошибки кидать не будем
On Error Resume Next

Dim ciKey As Long

If IsNull(Me!ciKey) Then
    ciKey = 0
Else
    ciKey = Me!ciKey
End If

Me.parent!cnInv.Form.Form.Filter = "ciKey = " & ciKey
Me.parent!cnInv.Form.Form.FilterOn = True

End Sub
