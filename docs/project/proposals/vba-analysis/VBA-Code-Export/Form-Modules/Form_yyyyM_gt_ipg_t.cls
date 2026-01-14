VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_yyyyM>ipg_t"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

'ошибки кидать не будем
On Error Resume Next

Dim ipgKey As Integer

If IsNull(Me!ipgKey) Then
    ipgKey = 0
Else
    ipgKey = Me!ipgKey
End If

If ipgKey <> 0 Then
    Me.parent![yyyyM>ipg_f]![yyyyM>ipg_f>rslt_b]![yyyyM>ipg_f>rslt_b>t].Form.Form.Filter _
        = "ipgKey = " & ipgKey & "or ipgKey is Null"
    Me.parent![yyyyM>ipg_f]![yyyyM>ipg_f>rslt_b]![yyyyM>ipg_f>rslt_b>t].Form.Form.FilterOn = True
    
    Me.parent![yyyyM>ipg_f]![yyyyM>ipg_f>rslt_a_t].Form.Form.Filter _
        = "ipgKey = " & ipgKey
    Me.parent![yyyyM>ipg_f]![yyyyM>ipg_f>rslt_a_t].Form.Form.FilterOn = True
    
    Me.parent![yyyyM>ipg_f]![yyyyM>ipg_f>TRsltM_rl_t].Form.Form.Filter _
        = "ipgKey = " & ipgKey '& "or ipgKey is Null "
    Me.parent![yyyyM>ipg_f]![yyyyM>ipg_f>TRsltM_rl_t].Form.Form.FilterOn = True
End If

End Sub
