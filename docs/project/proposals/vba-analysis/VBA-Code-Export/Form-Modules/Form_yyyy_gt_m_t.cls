VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_yyyy>m_t"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

'ошибки кидать не будем
On Error Resume Next

Dim CodReport As Integer

If IsNull(Me!mKey) Then
    CodReport = 0
Else
    CodReport = Me!mKey
End If

Me.parent!yyyyM.Form.Form.Filter = "mKey = " & CodReport & "And yKey = " & Me.parent!yKey
Me.parent!yyyyM.Form.Form.FilterOn = True

End Sub
