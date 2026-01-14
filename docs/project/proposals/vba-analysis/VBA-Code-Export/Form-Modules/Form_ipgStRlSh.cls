VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_ipgStRlSh"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Current()

    Dim db As DAO.Database, qd As DAO.QueryDef, strSql As String

    Const cstrTitle As String = "Функция *Текущая запись ~Схемы структуры инвестпрограммы~*"

    ' ***************************************************************************************************************************

On Error GoTo ErrHandler

    Set db = CurrentDb 'открываем переменную базы данных ---------------------------------------------------

    Set qd = db.QueryDefs("ags_fnIpgStNumSm")
    strSql = "select * from ags.fnIpgStNumSm(" & Me![ipgStRlSh>ipg_t].Form.ipgKey & ", " & Me!ipgstrshRoot & ") f Order by f.stNum"
    qd.SQL = strSql
    'qd.Execute dbFailOnError
    
    Me![ipgStRlSh>fnIpgStNumSm].Form.Requery
    
    qd.Close: Set qd = Nothing

    db.Close 'закрываем переменную базы данных -------------------------------------------------------------
    Set db = Nothing

NormalExit:
    Exit Sub

ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
