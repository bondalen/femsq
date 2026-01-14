VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_Msrn"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

'ошибки кидать не будем
On Error Resume Next

Dim key As Long

If IsNull(Me![Msrv>SubDivs].Form.rsdKey) Then
    key = 0
Else
    key = Me![Msrv>SubDivs].Form.rsdKey
End If

If key = 0 Then
    Me![Msrv>SubDivs_f].Form.Form.Filter = "rsdKey = " & key
    Me![Msrv>SubDivs_f].Form.Form.FilterOn = True
    Me![Msrv>SubDivs_f].Form.Visible = False
Else
    Me![Msrv>SubDivs_f].Form.Form.Filter = "rsdKey = " & key
    Me![Msrv>SubDivs_f].Form.Form.FilterOn = True
    Me![Msrv>SubDivs_f].Form.Visible = True
End If

End Sub
