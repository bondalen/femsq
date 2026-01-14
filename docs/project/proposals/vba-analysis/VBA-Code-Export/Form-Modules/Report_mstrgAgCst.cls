VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Report_mstrgAgCst"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub ОбластьДанных_Format(Cancel As Integer, FormatCount As Integer)

'ошибки кидать не будем
On Error Resume Next

Select Case Me!sign
    Case "итого"
        ОбластьДанных.BackColor = 16777184
        ОбластьДанных.AlternateBackColor = 16777184
    Case "всего"
        ОбластьДанных.BackColor = 12713921
        ОбластьДанных.AlternateBackColor = 12713921
    Case "Заказчики"
        ОбластьДанных.BackColor = 14020607
        ОбластьДанных.AlternateBackColor = 14020607
    Case Else
        ОбластьДанных.BackColor = vbWhite
        ОбластьДанных.AlternateBackColor = RGB(242, 242, 242)
End Select

End Sub
