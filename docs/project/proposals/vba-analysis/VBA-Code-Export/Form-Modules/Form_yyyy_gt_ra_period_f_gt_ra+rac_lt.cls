VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_yyyy>ra_period_f>ra+rac_lt"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

'ошибки кидать не будем
On Error Resume Next

Me.parent![yyyy>ra_period_f>ra_f].Form.Form.Filter = "ra_key = " & Me!ra_key
Me.parent![yyyy>ra_period_f>ra_f].Form.Form.FilterOn = True

End Sub
