VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_stNetCost"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

Private Sub Form_Activate()

    Dim db As DAO.Database, qd As DAO.QueryDef, strSql As String

    Const cstrTitle As String = "Функция *Активация ~Схемы структуры стоимостей~*"

    ' ***************************************************************************************************************************

On Error GoTo ErrHandler

    Set db = CurrentDb 'открываем переменную базы данных ---------------------------------------------------

    Set qd = db.QueryDefs("ags_fnSt")
    strSql = "select * from ags.fnSt(" & Me!stnKey & ", " & Me!stnRoot & ") f Order by f.stNum"
    qd.SQL = strSql
    
    Me![stNet>fnSt_t].Form.Requery
    
    qd.Close: Set qd = Nothing

    db.Close 'закрываем переменную базы данных -------------------------------------------------------------
    Set db = Nothing

NormalExit:
    Exit Sub

ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

Private Sub Form_Current()

    Dim db As DAO.Database, qd As DAO.QueryDef, strSql As String

    Const cstrTitle As String = "Функция *Текущая запись ~Схемы структуры стоимостей~*"

    ' ***************************************************************************************************************************

On Error GoTo ErrHandler

    Set db = CurrentDb 'открываем переменную базы данных ---------------------------------------------------

    Set qd = db.QueryDefs("ags_fnSt")
    strSql = "select * from ags.fnSt(" & Me!stnKey & ", " & Me!stnRoot & ") f Order by f.stNum"
    qd.SQL = strSql
    
    Me![stNet>fnSt_t].Form.Requery
    
    qd.Close: Set qd = Nothing

    db.Close 'закрываем переменную базы данных -------------------------------------------------------------
    Set db = Nothing

NormalExit:
    Exit Sub

ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
