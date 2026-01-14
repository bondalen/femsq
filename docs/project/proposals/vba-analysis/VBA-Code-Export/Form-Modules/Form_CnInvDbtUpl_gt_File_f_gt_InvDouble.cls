VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_CnInvDbtUpl>File_f>InvDouble"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

Dim invNum As String
Dim cnKey As Long

'ошибки кидать не будем
On Error Resume Next

' определяем номер, строчный, счёта-фактуры
If IsNull(Me!cidufiInvNum) Then
    invNum = "Nulll"
Else
    invNum = Me!cidufiInvNum
End If

' определяем идентификатор, длтнное целое, договора
If IsNull(Me!cidufiCnKey) Then
    cnKey = 0
Else
    cnKey = Me!cidufiCnKey
End If

' фильтруем форму старых счётов-фактур
If invNum = "Nulll" Then
    Me.parent![CnInvDbtUpl>File_f>InvDouble_f].Form.Filter _
        = "IsNull([inNum]) = true"
    Me.parent![CnInvDbtUpl>File_f>InvDouble_f].Form.FilterOn = True
Else
    'fff = "[inNum] = '" & invNum
    Me.parent![CnInvDbtUpl>File_f>InvDouble_f].Form.Filter _
        = "[inNum] = '" & invNum & "'"
    Me.parent![CnInvDbtUpl>File_f>InvDouble_f].Form.FilterOn = True
End If

' фильтруем форму исполнителей по новому договору
    Me.parent![CnInvDbtUpl>File_f>cns].Form.Filter _
        = "[cn_key] = " & cnKey
    Me.parent![CnInvDbtUpl>File_f>cns].Form.FilterOn = True

End Sub
