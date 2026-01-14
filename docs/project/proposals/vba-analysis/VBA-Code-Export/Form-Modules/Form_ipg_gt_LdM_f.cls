VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_ipg>LdM_f"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

'ошибки кидать не будем
On Error Resume Next

Dim ldmKey As Integer

If IsNull(Me!ldmKey) Then
    ldmKey = 0
Else
    ldmKey = Me!ldmKey
End If

If ldmKey <> 0 Then
    Me.parent![ipg>LdM_t].Form.Form.Filter _
        = "ldmKey = " & ldmKey
    Me.parent![ipg>LdM_t].Form.Form.FilterOn = True
End If

End Sub
