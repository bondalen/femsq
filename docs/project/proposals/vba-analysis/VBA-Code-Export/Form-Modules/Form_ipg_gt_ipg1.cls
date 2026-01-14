VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_ipg>ipg1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

'ошибки кидать не будем
On Error Resume Next

Dim ldmKey As Integer

If IsNull(Me.[ipg>LdM_f]!ldmKey) Then
    ldmKey = 0
Else
    ldmKey = Me.[ipg>LdM_f]!ldmKey
End If

If ldmKey <> 0 Then
    Me![ipg>LdM_t].Form.Form.Filter _
        = "ldmKey = " & ldmKey
    Me![ipg>LdM_t].Form.Form.FilterOn = True
End If

End Sub
