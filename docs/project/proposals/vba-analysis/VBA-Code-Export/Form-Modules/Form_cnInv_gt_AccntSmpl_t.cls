VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_cnInv>AccntSmpl_t"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Dim fff As String

Private Sub Form_Current()

Dim ciasKey As Long

'ошибки кидать не будем
On Error Resume Next

If IsNull(Me!ciasKey) Then
    ciasKey = 0
Else
    ciasKey = Me!ciasKey
End If

'If ciasKey <> 0 Then
'End If
    fff = "ciasKey = " & ciasKey
    Me.parent![cnInv>AccntSmpl_f].Form.Filter _
        = "ciasKey = " & ciasKey
    Me.parent![cnInv>AccntSmpl_f].Form.FilterOn = True
    
    If Me.parent![cnInv>AccntSmpl_f].Form.Filter <> fff Then
        Me.parent![cnInv>AccntSmpl_f].Form.Filter = fff
        Me.parent![cnInv>AccntSmpl_f].Form.FilterOn = False
        Me.parent![cnInv>AccntSmpl_f].Form.FilterOn = True
    End If

'    Me.Parent![cnInv>AccntSmpl_f].Form.Form.Filter _
'        = "ciasKey = " & ciasKey
'    Me.Parent![cnInv>AccntSmpl_f].Form.Form.FilterOn = True



End Sub
