VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_CnInvPmtUpl>File_f>InvDouble>invNum>cnInv"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub cnName_DblClick(Cancel As Integer)

    'MsgBox ("*** +++ ***")
    
    DoCmd.OpenForm "invNum"
    Forms("invNum").Recordset.FindFirst "inKey = " & Me.parent!inKey

End Sub
