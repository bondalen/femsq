VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Report_mstrgAg_23_Branch_q2m_2408"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub ОбластьДанных_Format(Cancel As Integer, FormatCount As Integer)

'ошибки кидать не будем
On Error Resume Next

Select Case Me!ogNm
    Case "итого"
        ОбластьДанных.BackColor = 14020607
        ОбластьДанных.AlternateBackColor = 14020607
    Case "Заказчики"
        ОбластьДанных.BackColor = 14020607
        ОбластьДанных.AlternateBackColor = 14020607
    Case Else
        ОбластьДанных.BackColor = vbWhite
        ОбластьДанных.AlternateBackColor = RGB(242, 242, 242)
End Select

End Sub
