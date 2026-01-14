VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_yyyy>ra_period"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

'ошибки кидать не будем
On Error Resume Next

Dim CodReport As Integer

If IsNull(Me!key) Then
    CodReport = 0
Else
    CodReport = Me!key
End If

Me.parent!yyyy_ra_period_f.Form.Form.Filter = "key = " & CodReport
Me.parent!yyyy_ra_period_f.Form.Form.FilterOn = True

End Sub
