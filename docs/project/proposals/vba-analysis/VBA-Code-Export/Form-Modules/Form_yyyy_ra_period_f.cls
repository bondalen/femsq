VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_yyyy_ra_period_f"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

'ошибки кидать не будем
On Error Resume Next

Dim sender As Integer, period As Integer

If Me.[yyyy>ra_period>sender].Form.RecordsetClone.RecordCount > 0 Then
    sender = Me.[yyyy>ra_period>sender]!ra_org_sender: period = Me.[yyyy>ra_period>sender]!ra_period
    Else
    sender = 0: period = 0
End If

'Me.Parent![yyyy>ra_period_f>ra+rac_lt].Form.Form.Filter = "ra_org_sender = " & Me!ra_org_sender
'Me.Parent![yyyy>ra_period_f>ra+rac_lt].Form.Form.FilterOn = True

Me![yyyy>ra_period>ra+rac_lt_rslt].Form.Form.Filter _
    = "ra_org_sender = " & sender & " And ra_period = " & period
Me![yyyy>ra_period>ra+rac_lt_rslt].Form.Form.FilterOn = True

End Sub
