VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_cstAgPn"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

    If IsNull(Me![cstAgPn>cst_f].Form!cstKey) Then
        RefreshCstChart (0)
        Else
        RefreshCstChart (Me![cstAgPn>cst_f].Form!cstKey)
    End If
    
    Me![cstAgPn>cst_f].Form![cst>ra_t].Requery
    Me![cstAgPn>cst_f].Form![cst>raUtil_t].Requery

End Sub
