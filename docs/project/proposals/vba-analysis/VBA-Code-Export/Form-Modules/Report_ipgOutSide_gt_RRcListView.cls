VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Report_ipgOutSide>RRcListView"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub ОбластьДанных_Format(Cancel As Integer, FormatCount As Integer)
    If Me.txtCount = 0 Then
        Me.Section(0).Visible = False
        Me.Section(1).Visible = False
        Me.Section(2).Visible = False
    Else
        Me.Section(0).Visible = True
        Me.Section(1).Visible = True
        Me.Section(2).Visible = True
    End If
End Sub
