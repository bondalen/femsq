VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_cnF>Num"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

Dim Cn As Long

'ошибки кидать не будем
On Error Resume Next

If IsNull(Me!cnnCn) Then
    Cn = 0
Else
    Cn = Me!cnnCn
End If

'If ciasKey <> 0 Then
'End If
    Me.parent![CnF>cn].Form.Form.Filter _
        = "cn_key = " & Cn
    Me.parent![CnF>cn].Form.Form.FilterOn = True
    
End Sub
