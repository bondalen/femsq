VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_ipg>Pn_t"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

'ошибки кидать не будем
On Error Resume Next

Dim ipgpKey As Integer

If IsNull(Me!ipgpKey) Then
    ipgpKey = 0
Else
    ipgpKey = Me!ipgpKey
End If

Me.parent![ipg>Pn_f].Form.Form.Filter _
    = "ipgpKey = " & ipgpKey
Me.parent![ipg>Pn_f].Form.Form.FilterOn = True


End Sub
