VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_ipgStRlSh>ipg_t"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

    Dim db As DAO.Database, qd As DAO.QueryDef, strSql As String

    Const cstrTitle As String = "Функция *Текущая запись ~Инвестпрограммы в схеме структуры инвестпрограмм~*"

    ' ***************************************************************************************************************************

On Error GoTo ErrHandler

    Set db = CurrentDb 'открываем переменную базы данных ---------------------------------------------------

    Set qd = db.QueryDefs("ags_fnIpgStNumSm")
    strSql = "select * from ags.fnIpgStNumSm(" & Me!ipgKey & ", " & Me.parent!ipgstrshRoot & ") f Order by f.stNum"
    qd.SQL = strSql
    'qd.Execute dbFailOnError
    
    'If Me.Parent![ipgStRlSh>fnIpgStNumSm].Form.IsLoaded Then
        Me.parent![ipgStRlSh>fnIpgStNumSm].Form.Requery
    'End If
    
    qd.Close: Set qd = Nothing

    db.Close 'закрываем переменную базы данных -------------------------------------------------------------
    Set db = Nothing

NormalExit:
    Exit Sub

ErrHandler:

    If Err.Number = 2455 Then
        Exit Sub
        Else
        MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number, vbExclamation, cstrTitle
        Resume NormalExit
    End If

End Sub
